## ------------------- Parse Snakemake Object ------------------- ##
# Check if the "snakemake" object exists
# This snippet is run at the beginning of a snakemake run to setup the env
# Helps to load the workspace if the script is run independently or debugging
if (exists("snakemake")) {
    INPUT <- snakemake@input
    OUTPUT <- snakemake@output
    WILDCARDS <- snakemake@wildcards
    THREADS <- snakemake@threads

    # setup logger if log file is provided
    if (length(snakemake@log) > 0) {
        sink(
            file = snakemake@log[[1]],
            append = FALSE,
            type = c("output", "message"),
            split = TRUE
        )
    }

    # Assuming that this script is named after the rule
    # Saves the workspace to "resources/"buildTreatmentResponseExperiment"
    file.path("resources", paste0(snakemake@rule, ".RData")) |>
        save.image()
} else {
    # If the snakemake object does not exist, load the workspace
    file.path("resources", "preprocessTreatmentResponse.RData") |>
        load()
}
print(INPUT)


tsv_path <- INPUT$tsv_path
unzip_dir <- snakemake@resources$tmpdir

# ------------------- Extract TSV ------------------- #
if (!dir.exists(unzip_dir)) dir.create(unzip_dir)

message("Extracting TSV")
system(paste("tar -xzf", tsv_path, "--strip-components 1 -C", unzip_dir))
tsv_files <- list.files(unzip_dir, pattern = "*.tsv", full.names = TRUE)
input_dt_list <- lapply(tsv_files, data.table::fread)
names(input_dt_list) <- basename(tsv_files)

message("Found TSV files:", paste(names(input_dt_list), collapse = ", "))

GRValues <- input_dt_list[["gCSI_GRvalues_v1.3.tsv"]]

# names(GRValues)
#  [1] "DrugName"            "CellLineName"        "PrimaryTissue"
#  [4] "ExperimentNumber"    "TrtDuration"         "doublingtime"
#  [7] "log10Concentration"  "GR"                  "relative_cell_count"
# [10] "activities.mean"     "activities.std"      "Norm_CellLineName"
# [13] "Norm_DrugName"

raw_dt <- GRValues[
    ,
    .(
        treatmentid = Norm_DrugName,
        sampleid = Norm_CellLineName,
        tissue = PrimaryTissue,
        ExperimentNumber,
        TrtDuration,
        doublingtime,
        dose = ((10^log10Concentration) / 1e-6),
        viability = relative_cell_count * 100,
        # expid = paste(Norm_CellLineName, Norm_DrugName, ExperimentNumber, sep = "_"),
        GR,
        activities.mean,
        activities.std
    )
]


GRMetrics <- input_dt_list[["gCSI_GRmetrics_v1.3.tsv"]]

# names(GRMetrics)
#  [1] "DrugName"              "CellLineName"          "PrimaryTissue"
#  [4] "ExperimentNumber"      "TrtDuration"           "doublingtime"
#  [7] "maxlog10Concentration" "GR_AOC"                "meanviability"
# [10] "GRmax"                 "Emax"                  "GRinf"
# [13] "GEC50"                 "GR50"                  "R_square_GR"
# [16] "pval_GR"               "flat_fit_GR"           "h_GR"
# [19] "N_conc"                "log10_conc_step"       "Norm_CellLineName"
# [22] "Norm_DrugName"         "GR_05uM_fit"


profiles <- GRMetrics[
    ,
    .(
        treatmentid = Norm_DrugName,
        sampleid = Norm_CellLineName,
        ExperimentNumber,
        meanviability = meanviability * 100,
        # expid = paste(Norm_CellLineName, Norm_DrugName, ExperimentNumber, sep = "_"),
        GR_AOC,
        GRmax,
        Emax,
        GRinf,
        GEC50,
        GR50,
        R_square_GR,
        pval_GR,
        flat_fit_GR,
        h_GR
    )
]

# drop empty rows across both
raw_dt <- raw_dt[!is.na(treatmentid) & !is.na(sampleid)]
profiles <- profiles[!is.na(treatmentid) & !is.na(sampleid)]

rawfile <- OUTPUT$preprocessed_raw
message("Saving raw data to", rawfile)
data.table::fwrite(
    raw_dt,
    file = rawfile,
    sep = ",",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE
)

profilesfile <- OUTPUT$preprocessed_profiles
message("Saving profiles data to", profilesfile)
data.table::fwrite(
    profiles,
    file = profilesfile,
    sep = ",",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE
)