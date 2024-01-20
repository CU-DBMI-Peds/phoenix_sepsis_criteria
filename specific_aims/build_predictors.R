#!/bin/R

options(warn = 2) # turn warnings into errors
options(qwraps2_markup = "markdown")
stopifnot(packageVersion("base") >= "4.1.1")
library(data.table)
library(parallel)
source("utilities.R")

#/* ------------------------------------------------------------------------- */
                               ## Data Import ##
tictoc::tic("importing csvs")
files <- list.files(base_path, pattern = "0\\d*.csv", full.name = TRUE)

SA <-
  files |>
  lapply(data.table::fread) |>
  data.table::rbindlist()

data.table::setkey(SA, sa_subset, site, pat_id, enc_id)
tictoc::toc()

#/* ------------------------------------------------------------------------- */
                      ## Create PELOD-2 Age Categories ##
tictoc::tic("setting pelod-2 age categories")
SA[, age_category := cut(admit_age_months
                         , breaks = c(0, 1, 12, 24, 60, 144, 20 * 12)
                         , right = FALSE
                         )]
tictoc::toc()

#/* ------------------------------------------------------------------------- */
                      ## Predictors and Predictor Types ##

tictoc::tic("defining predictors")
predictors <- c(
    grep("^ipscc", names(SA), value = TRUE)
  , grep("^integer_lasso_sepsis_", names(SA), value = TRUE)
  , grep("^integer_ridge_sepsis_", names(SA), value = TRUE)
  , grep("^lqsofa", names(SA), value = TRUE)
  , grep("^msirs", names(SA), value = TRUE)
  , grep("^pelod2", names(SA), value = TRUE)
  , grep("^pews", names(SA), value = TRUE)
  , grep("^podium", names(SA), value = TRUE)
  , grep("^proulx", names(SA), value = TRUE)
  , grep("^psofa", names(SA), value = TRUE)
  , grep("^qsofa", names(SA), value = TRUE)
  , grep("^qpelod2", names(SA), value = TRUE)
  , grep("^shock_index", names(SA), value = TRUE)
  , grep("^vis", names(SA), value = TRUE)
  , grep("^dic", names(SA), value = TRUE)
  )

# any of the integer_(lasso|ridge)_sepsis_.* variables with the substring "geq"
# are outcomes and need to be omited from the predictors
predictors <- predictors[!grepl("geq\\d", predictors)]

# check to make sure that none of the predictors are also going to be used as an
# outcome
stopifnot(!any(predictors %in% define_outcome()))
#predictors[predictors %in% define_outcome()]

unique_values <-
  setNames(lapply(predictors, function(p) {sort(unique(SA[[p]]))}), predictors)

predictor_types <-
  unique_values |>
  lapply(function(x) {
           y <- data.table::fcase(all(x %in% c(0,1)), "binary",
                                  any(floor(x) != ceiling(x)), "continuous",
                                  default = "categorical"
                                  )
           if (y == "categorical") {
             y <- c("categorical", "continuous")
           }
           list(predictor_type = y)
  })

predictor_types <-
  predictor_types |>
  lapply(as.data.frame) |>
  data.table::rbindlist(idcol = "predictor")

# Any categorical variable needs a factor version added to SA
for (p in predictor_types[predictor_type == "categorical", predictor]) {
  data.table::set(SA, j = paste0(p, "_f"), value = factor(SA[[p]]))
}

predictor_types[, x := fifelse(predictor_type == "categorical", paste0(predictor, "_f"), predictor)]

predictor_types[, predictor_with_type := paste0(predictor, "\n(", predictor_type, ")")]

predictor_types[, organ_system := define_organ_system(predictor)]
stopifnot(!any(is.na(predictor_types[["organ_system"]])))
predictor_types[is.na(organ_system)]
stopifnot(
  setdiff(predictor_types$organ_system, define_organ_system()) |> length() == 0
  ,
  setdiff(define_organ_system(), predictor_types$organ_system) |> length() == 0
)

predictor_types[, scoring_system := define_scoring_system(predictor)]
stopifnot(!any(is.na(predictor_types[["scoring_system"]])))
stopifnot(
  setdiff(predictor_types$scoring_system, define_scoring_system()) |> length() == 0
  ,
  setdiff(define_scoring_system(), predictor_types$scoring_system) |> length() == 0
)

predictor_types[, time_from_hospital_presentation := define_time_from_hospital_presentation(predictor)]
stopifnot(!any(is.na(predictor_types[["time_from_hospital_presentation"]])))
stopifnot(
  setdiff(predictor_types$time_from_hospital_presentation, define_time_from_hospital_presentation()) |> length() == 0
  ,
  setdiff(define_time_from_hospital_presentation(), predictor_types$time_from_hospital_presentation) |> length() == 0
)

tictoc::toc()

for (j in seq_along(predictor_types)) {
  stopifnot(!any(is.na(predictor_types[[j]])))
}

#/* ------------------------------------------------------------------------- */
                    ## LOOK FOR MISING DATA IN PREDICTORS ##

tictoc::tic("check for missing values in predictors")
any_missing <-
  SA[, sapply(.SD, function(x) any(is.na(x))), .SDcols = c(unique(predictor_types[["x"]]))]

if (any(any_missing)) {
  stop(
       paste("\n  Missing values in:", paste(names(any_missing)[any_missing]))
       )
}
tictoc::toc()

#/* ------------------------------------------------------------------------- */
                               ## Export Data ##

# VERIFY THE SITES ARE IN SETS AS EXPECTED
stopifnot(SA[sa_subset == "SA1", setequal(site, c("**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**")) ])
stopifnot(SA[sa_subset == "**REDACTED**", all(site == "**REDACTED**")])
stopifnot(SA[sa_subset == "**REDACTED**", all(site == "**REDACTED**")])
stopifnot(SA[sa_subset == "**REDACTED**", all(site == "**REDACTED**")])

tictoc::tic("writing SA1")
feather::write_feather(x = SA[sa_subset == "SA1"],  path = SA1_data_feather_path)
tictoc::toc()

tictoc::tic("writing SA2g")
feather::write_feather(x = SA[sa_subset == "SA2g"], path = SA2g_data_feather_path)
tictoc::toc()

tictoc::tic("writing SA2h")
feather::write_feather(x = SA[sa_subset == "SA2h"], path = SA2h_data_feather_path)
tictoc::toc()

tictoc::tic("writing SA2t")
feather::write_feather(x = SA[sa_subset == "SA2t"], path = SA2t_data_feather_path)
tictoc::toc()

tictoc::tic("writing **REDACTED**")
# save **REDACTED** data vis sa_subset (preferable) or site
# this is needed as pat_id from **REDACTED** are not consistent from one provided data set
# to the other, that is, the pat_id for John Smith will be different from
# **REDACTED** every time they provide a data set.
feather::write_feather(x = SA[sa_subset == "**REDACTED**" | site == "**REDACTED**"], path = **REDACTED**_data_feather_path)
tictoc::toc()

tictoc::tic("writing **REDACTED**")
feather::write_feather(x = SA[sa_subset == "**REDACTED**" | site == "**REDACTED**"], path = **REDACTED**_data_feather_path)
tictoc::toc()

tictoc::tic("writing **REDACTED**")
feather::write_feather(x = SA[sa_subset == "**REDACTED**" | site == "**REDACTED**"], path = **REDACTED**_data_feather_path)
tictoc::toc()



# export the predictors and metadata about the predictors
feather::write_feather(x = predictor_types, path = predictors_feather_path)

predictor_types[predictor_type == "categorical", x] |>
sapply(function(x) levels(SA[[x]])) |>
saveRDS(file = factor_levels_rds_path)


#/* ------------------------------------------------------------------------- */
                               ## End of File ##
#/* ------------------------------------------------------------------------- */
