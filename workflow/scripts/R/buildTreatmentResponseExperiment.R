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
    file.path("resources", "buildTreatmentResponseExperiment.RData") |>
        load()
}
# ####################################################################################

raw_dt <- data.table::fread(
    INPUT$preprocessed_raw,
    header = TRUE,
    sep = ",",
    na.strings = c("NA", "NaN", "NULL", "")
)
profiles_dt <- data.table::fread(
    INPUT$preprocessed_profiles,
    header = TRUE,
    sep = ",",
    na.strings = c("NA", "NaN", "NULL", "")
)

raw_dt
message(paste0("Loading TREDataMapper"))
treDataMapper <- CoreGx::TREDataMapper(rawdata = raw_dt)
# https://bioconductor.org/packages/release/bioc/vignettes/CoreGx/inst/doc/TreatmentResponseExperiment.html#metaconstruct-method
groups <- list(
    justDrugs = c("treatmentid"),
    drugsAndDoses = c("treatmentid", "dose"),
    justCells = c("sampleid"),
    cellsAndBatches = c("sampleid", "ExperimentNumber"),
    assays1 = c("treatmentid", "dose", "sampleid", "ExperimentNumber")
)
subsets <- c(FALSE, TRUE, FALSE, TRUE, FALSE)

guess <- CoreGx::guessMapping(
    treDataMapper,
    groups = groups,
    subset = subsets
)

assays <- list(
    sensitivity = list(
        id_columns = guess$assay$id_columns,
        mapped_columns = guess$assay$mapped_columns
    )
)

# im gonna force add the duration to the mapped columns of the drugs
CoreGx::rowDataMap(treDataMapper) <- list(
    id_columns = guess$drugsAndDoses$id_columns,
    mapped_columns = c(guess$drugsAndDoses$mapped_columns, "TrtDuration")
)

CoreGx::colDataMap(treDataMapper) <- guess$cellsAndBatches

CoreGx::assayMap(treDataMapper) <- assays

show(treDataMapper)

message("Running CoreGx::metaConstruct")
tre <- CoreGx::metaConstruct(treDataMapper)

###################################################################
# Add the published profiles
message("Adding the published profiles...")
CoreGx::assay(tre, "published_profiles") <- profiles_dt
tre

tre_fit <- tre |> CoreGx::endoaggregate(
    { # the entire code block is evaluated for each group in our group by
        # 1. fit a log logistic curve over the dose range
        fit <- PharmacoGx::logLogisticRegression(dose, viability,
            viability_as_pct = FALSE
        )
        # 2. compute curve summary metrics
        ic50 <- PharmacoGx::computeIC50(dose, Hill_fit = fit)
        aac <- PharmacoGx::computeAUC(dose, Hill_fit = fit)
        # 3. assemble the results into a list, each item will become a
        #   column in the target assay.
        list(
            HS = fit[["HS"]],
            E_inf = fit[["E_inf"]],
            EC50 = fit[["EC50"]],
            Rsq = as.numeric(unlist(attributes(fit))),
            aac_recomputed = aac,
            ic50_recomputed = ic50
        )
    },
    assay = "sensitivity", # the assay we are aggregating
    target = "recomputed_profiles",
    enlist = FALSE, # this option enables the use of a code block for aggregation
    by = c("treatmentid", "sampleid"),
    nthread = THREADS # parallelize over multiple cores to speed up the computation
)

CoreGx::metadata(tre_fit) <- list(
    data_source = snakemake@config$treatmentResponse,
    annotation = "treatmentResponse",
    date = Sys.Date(),
    sessionInfo = capture.output(sessionInfo())
)
show(tre_fit)
###############################################################################
# Save OUTPUT
###############################################################################
message("Saving the treatment response experiment object...")
saveRDS(
    tre_fit,
    file = OUTPUT$tre
)
