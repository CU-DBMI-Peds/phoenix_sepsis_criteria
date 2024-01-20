options(warn = 2)
library(data.table)
source("utilities.R")

################################################################################
predictors <- read_predictors()
sensitivity_strata <- read_sensitivity_strata()
high_value_list <- read_high_value_list()

SA_DATA <-
  list(
         SA1  = read_SA_data(SA1_data_feather_path)   # SA1 and training g-level
       , SA2g = read_SA_data(SA2g_data_feather_path)  # training h-level
       , SA2h = read_SA_data(SA2h_data_feather_path)  # assessing h-level
       # , SA2t = read_SA_data(SA2t_data_feather_path)  # hold out testing
       )

variables_of_interest <-
  high_value_list$variable_sets |>
  do.call(c, args = _) |>
  unname() |>
  unique()

nonx <- setdiff(names(SA_DATA[[1]]), predictors$x)

SA_DATA <-
  lapply(SA_DATA, function(DT) {DT[, .SD, .SDcols = c(nonx, variables_of_interest)]})

################################################################################

get_range_levels <- function(DT, x) {
  if (grepl("_f$", x)) {
    levels(DT[[x]])
  } else {
    range(DT[[x]])
  }
}

# will h_traning extrapolate from the g training?
# start by looking for any variable with differences in the range of levels
extraplation_checker <- function(x, y) {
  if (isTRUE(all.equal(x, y))) {
    rtn <- list(extrapolation = FALSE, why = NA_character_)
  } else if (is.numeric(x) & is.numeric(y)) {
    if ((max(y) <= max(x)) & (min(x) <= min(y))) {
      rtn <- list(extrapolation = FALSE, why = NA_character_)
    } else {
      mx <- max(y) > max(x)
      mn <- min(y) < min(x)
      if (mx | !mn) {
        rtn <- list(extrapolation = TRUE, why = "greater maximum value")
      } else if (!mx & mn) {
        rtn <- list(extrapolation = TRUE, why = "lower minimum value")
      } else {
        rtn <- list(extrapolation = TRUE, why = "wider range")
      }
    }
  } else if (is.character(x) & is.character(y)) {
    d <- setdiff(y, x)
    if (length(d) > 0L) {
      rtn <- list(extrapolation = TRUE, why = paste("new levels:", paste(d, collapse = ", ")))
    } else {
      rtn <- list(extrapolation = FALSE, why = NA_character_)
    }
  } else {
    stop("unexpected x or y mode")
  }
  data.table::as.data.table(rtn)
}

# training_hash <- assessment_hash <- "aa3217790410d866d9fd384d233e4667"

extrapolation_check <- function(training_hash, assessment_hash) {
  training_subset   <- parse(text = sensitivity_strata[["strata"]][sensitivity_strata[["strata_hash"]] == training_hash])
  assessment_subset <- parse(text = sensitivity_strata[["strata"]][sensitivity_strata[["strata_hash"]] == assessment_hash])

  gtd <- droplevels(SA_DATA$SA1[eval(training_subset)])
  htd <- droplevels(SA_DATA$SA2g[eval(training_subset)])
  had <- droplevels(SA_DATA$SA2h[eval(assessment_subset)])

  g_training <- lapply(variables_of_interest, get_range_levels, DT = gtd)
  h_training <- lapply(variables_of_interest, get_range_levels, DT = htd)
  assessment <- lapply(variables_of_interest, get_range_levels, DT = had)

  h_training_extrapoloations <-
    Map(extraplation_checker, x = g_training, y = h_training) |>
    data.table::rbindlist()
  data.table::setnames(h_training_extrapoloations,
                       old = names(h_training_extrapoloations),
                       new = paste0("h_training_", names(h_training_extrapoloations)))
  data.table::set(h_training_extrapoloations, j = "x", value = variables_of_interest)

  assessment_vs_g_extrapoloations <-
    Map(extraplation_checker, x = g_training, y = assessment) |>
    data.table::rbindlist()
  data.table::setnames(assessment_vs_g_extrapoloations,
                       old = names(assessment_vs_g_extrapoloations),
                       new = paste0("assessment_vs_g_", names(assessment_vs_g_extrapoloations)))
  data.table::set(assessment_vs_g_extrapoloations, j = "x", value = variables_of_interest)

  assessment_vs_h_extrapoloations <-
    Map(extraplation_checker, x = h_training, y = assessment) |>
    data.table::rbindlist()
  data.table::setnames(assessment_vs_h_extrapoloations,
                       old = names(assessment_vs_h_extrapoloations),
                       new = paste0("assessment_vs_h_", names(assessment_vs_h_extrapoloations)))
  data.table::set(assessment_vs_h_extrapoloations, j = "x", value = variables_of_interest)

  g_training <- data.table::data.table(g_training, x = variables_of_interest)
  h_training <- data.table::data.table(h_training, x = variables_of_interest)
  assessment <- data.table::data.table(assessment, x = variables_of_interest)

  rtn <- list(g_training, h_training, assessment, h_training_extrapoloations, assessment_vs_g_extrapoloations, assessment_vs_h_extrapoloations)

  rtn <- Reduce(function(x, y) {merge(x, y, by = "x")}, x = rtn)

  data.table::set(rtn, j = "training_hash", value = training_hash)
  data.table::set(rtn, j = "assessment_hash", value = assessment_hash)

  rtn

}

hashes <- data.table::CJ(training_hashes = high_value_list$training_hashes,
                         assessment_hashes = high_value_list$assessment_hashes)
output <-
  pbapply::pblapply(1:nrow(hashes), function(i) {
                      extrapolation_check(training_hash = hashes[["training_hashes"]][i],
                                          assessment_hash = hashes[["assessment_hashes"]][i])
                         })
output <- data.table::rbindlist(output)

saveRDS(output, file = extrapolation_checks_rds_path)


################################################################################
                               ## End of File ##
################################################################################
