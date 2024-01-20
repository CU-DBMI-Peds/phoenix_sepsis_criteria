library(data.table)
source("utilities.R")

library(bigrquery)
project_id <- "**REDACTED**"
project_number <- "**REDACTED**"

training_strata <- read_training_strata()
sensitivity_strata <- read_sensitivity_strata()
predictors <- read_predictors()
high_value_list <- read_high_value_list()

if (!("R01_data" %in% ls(envir = .GlobalEnv))) {
  R01_data <- read_R01_data()
}

sets <-
  pbapply::pblapply( high_value_list[["assessment_hashes"]], function(hash) {
    ss <- sensitivity_strata[["strata"]] [
            sensitivity_strata[["strata_hash"]] == hash
            ]
    name <- sensitivity_strata[["strata_name"]] [
            sensitivity_strata[["strata_hash"]] == hash
            ]
    DT <-subset(R01_data, subset = eval(parse(text = ss)), select = c("site", "sa_subset", "enc_id"))
    data.table::set(DT, j = "strata_name", value = name)
    data.table::set(DT, j = "strata_hash", value = hash)
    DT
  })

sets <- data.table::rbindlist(sets)
tmp <- tempfile()
data.table::fwrite(sets, file = tmp)

paste(
"bq load"
, "--replace"
, "--skip_leading_rows=1"
, "--source_format=CSV"
, "**REDACTED**:sa.strata"
, tmp
, "'site:string, sa_subset:string, enc_id:string, strata_name:string, strata_hash:string'"
) |>
system()
