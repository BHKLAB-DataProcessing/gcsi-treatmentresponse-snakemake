## ------------------- Parse Snakemake Object ------------------- ##
# Check if the "snakemake" object exists
if (exists("snakemake")) {
    INPUT <- snakemake@input
    OUTPUT <- snakemake@output
    WILDCARDS <- snakemake@wildcards
    THREADS <- snakemake@threads

    # setup logger if log file is provided
    if (length(snakemake@log) > 0) {
        sink(snakemake@log[[1]], FALSE, c("output", "message"), TRUE)
    }

    save.image(
        file.path("resources", paste0(snakemake@rule, ".RData"))
    )
}

#############################################################################
# Load INPUT
#############################################################################
tarGZ_file <- INPUT$rawData

message("Untar the file and list files")
# untar the file and list files
tmp_dir <- tempdir()
untar(tarGZ_file, exdir = tmp_dir)


# list files
files <- list.files(tmp_dir, full.names = TRUE, recursive = TRUE)
message("Files in the tarGZ file:", paste(files, collapse = "\n"))
metricsFile <- grep("GRmetrics", files, value = TRUE)
rawData <- data.table::fread(metricsFile, header = TRUE, sep = "\t")

message(names(rawData))

#############################################################################
# Main Script
# Subset the metadata

sampleMetadata <- rawData[, c(
    "CellLineName", "PrimaryTissue", "Norm_CellLineName"
)]

treatmentMetadata <- rawData[, c(
    "DrugName", "Norm_DrugName"
)]

# Remove duplicates
sampleMetadata <- unique(sampleMetadata)
treatmentMetadata <- unique(treatmentMetadata)
# Remove empty rows
sampleMetadata <- sampleMetadata[!is.na(sampleMetadata$CellLineName) & sampleMetadata$CellLineName != ""]
treatmentMetadata <- treatmentMetadata[!is.na(treatmentMetadata$DrugName) & treatmentMetadata$DrugName != ""]

# add 'gCSI.' prefix to all columns in both
# sampleMetadata and treatmentMetadata
data.table::setnames(sampleMetadata, old = colnames(sampleMetadata), new = paste0("gCSI.", colnames(sampleMetadata)))
data.table::setnames(treatmentMetadata, old = colnames(treatmentMetadata), new = paste0("gCSI.", colnames(treatmentMetadata)))

# duplicate Norm_CellLineName and Norm_DrugName columns to 'sampleid' and 'treatmentid'
sampleMetadata[, sampleid := gCSI.CellLineName]
treatmentMetadata[, treatmentid := gCSI.DrugName]

#############################################################################
# SAVE OUTPUT
#############################################################################

rawSampleMetadata <- OUTPUT$sampleMetadata
message("Saving raw sample metadata to ", rawSampleMetadata)
data.table::fwrite(sampleMetadata, rawSampleMetadata, sep = "\t", quote = FALSE)

rawTreatmentMetadata <- OUTPUT$treatmentMetadata
message("Saving raw treatment metadata to ", rawTreatmentMetadata)
data.table::fwrite(treatmentMetadata, rawTreatmentMetadata, sep = "\t", quote = FALSE)
