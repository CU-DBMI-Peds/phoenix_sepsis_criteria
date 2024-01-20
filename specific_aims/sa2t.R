options(warn = 2)
library(data.table)
suppressPackageStartupMessages( library(glmnet) )
source("utilities.R")

# IMPORTANT NOTE: -- **REDACTED**
# June 2023) the data used to train the g-level models with be the SA1 data
# split.  SA2g will then be used to train the h-level models SA2h will be used
# as a testing / assessment set for SA2 to help select hyper parameters such as
# lambda (ridge/lasso penalty) and alpha (ridge/elastic net/lasso)

################################################################################
                            ## Command Line Args ##

# The number of arguments is not fixed for this script.  The order matters.
#
# outcome training_hash type.measure assessment_hash x1 x2 x3 x4 ... xn
#
# Where the outcome, training_hash, and assessment_hash, are as they have been
# with prior scripts.
#
# The type.measure is needed in this call to identify the h level model
#
# x1, x2, ... (will require at least one) are the organ
# dysfunction component scores
#
if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
} else {

  # logs <- data.table::fread("high_value_sa2t1.log")
  # logs[Exitval != 0]

  high_value_list <- readRDS(high_value_list_rds_path)

  h_cargs <- list(
      outcome = "death"
    , trained_on = "04910835052f8948f57b88483e70c31d"
    , type.measure = "deviance"
    , alpha = "0"
    , xs = high_value_list$variable_sets$set021_no_factors
    )
  define_h_model_hash(h_cargs)

  cargs <- list(
                # h_model_hash = define_h_model_hash(h_cargs)
                  h_model_hash = "bac0d6b50e4a56d285392c4132948368"
                , assessment_strata_hash = "9a0adaa5cff8b01c699f447056080870"
                , assessment_data = "**REDACTED**"
    )
  sensitivity_strata <- read_sensitivity_strata()
  stopifnot(cargs[["assessment_strata_hash"]] %in% sensitivity_strata[["strata_hash"]])

}

stopifnot(length(cargs) == 3L)
names(cargs) <- c("h_model_hash", "assessment_strata_hash", "assessment_data")


# hash with all character values, all.equal(0, 0) is TRUE, but identical(0, 0)
# can be false
cargs[["assessment_hash"]] <- define_sa2_assessment_hash(cargs)

################################################################################
                               ## Define paths ##
out_files <- define_sa2_assessment_out_files(cargs)

h_model_files <-
  list.files(
             paste(gcs_base_path, "sa2", "hmodels", cargs[["h_model_hash"]], sep = "/")
             ,
             full.names = TRUE) |> as.list()
names(h_model_files) <- sapply(h_model_files, basename)

if ( length(h_model_files) == 0L) {
  if (interactive()) {
    stop(paste("h model", cargs[["h_model_hash"]], "out put files are missing"))
  } else {
    for (f in out_files) {
      if (file.exists(f)) {
        file.remove(f)
      }
    quit()
  }
  }
}

h_model_cargs <- dget(file = h_model_files[["cargs"]])

sa2g_model_files <-
  lapply(
         seq_along(h_model_cargs[["xs"]])
         ,
         function(i) {
           cargsi <- h_model_cargs
           cargsi[["x"]] <- h_model_cargs[["xs"]][i]
           define_sa2g_out_files(cargsi)[["gcs_model_rds"]]
         })

################################################################################
             ## Determine if the model fitting needs to be done ##

# if the h model rds files exists and is younger than all the component g models
# then there is no needed to refit the model
stopifnot(all(sapply(sa2g_model_files, file.exists)))
stopifnot(file.exists(h_model_files[["h.rds"]]))

h_model <- try(readRDS(h_model_files[["h.rds"]]), silent = TRUE)

if (inherits(h_model, "try-error")) {
  if (interactive()) {
    stop("error in readRDS for h_model  - likley means h_model could not be trained.")
  } else {
    for(f in out_files) {
      if (file.exists(f)) {
        file.remove(f)
      }
    }
    dput(h_model
         , file = paste(dirname(out_files[["gcs_cargs"]]), "h_errors", sep = "/")
         )
    quit()
  }
}

if (inherits(h_model, "simpleError")) {
  if ((h_model[["message"]] == "All used predictors have zero variance") |
      (h_model[["message"]] == "'from' must be a finite number") ) {
    if (interactive()) {
      stop(h_model[["message"]])
    } else {
      for(f in out_files) {
        if (file.exists(f)) {
          file.remove(f)
        }
      }
      dput(h_model
           , file = paste(dirname(out_files[["gcs_cargs"]]), "h_errors", sep = "/")
           )
      quit()
    }
  } else {
    stop("Unknwon h_model simpleError")
  }
}

if (!inherits(h_model, "cv.glmnet")) {
  stop("h_model is of unexpected type")
}

# out file younger than needed input files?
if (all(sapply(out_files, file.exists))) {

  out_mtimes <-
    lapply(out_files, file.info) |>
    lapply(getElement, "mtime")

  dp <- eval(parse(text = paste0(cargs[["assessment_data"]], "_data_feather_path")))

  in_mtime <-
    c(dp, sa2g_model_files, h_model_files) |>
    lapply(file.info) |>
    lapply(getElement, "mtime") |>
    do.call(c, args = _) |>
    max()

  if (all(out_mtimes > in_mtime)) {
    if (interactive()) {
      stop("No need for update")
    } else {
      quit()
    }
  }
}

# If the script reaches this point in non-interactive mode, then we should check
# the md5 hash of the data to see if an update is needed

assessment_data <- eval(parse(text = paste0("read_", cargs[["assessment_data"]], "_data()")))
sensitivity_strata <- read_sensitivity_strata()
stopifnot(cargs[["assessment_strata_hash"]] %in% sensitivity_strata[["strata_hash"]])

ss <- sensitivity_strata[["strata"]][sensitivity_strata[["strata_hash"]] == cargs[["assessment_strata_hash"]]]

assessment_data <-
  subset(assessment_data
         , subset = eval(parse(text = ss))
         , select = c(h_model_cargs[["outcome"]], h_model_cargs[["xs"]], "enc_id")
         )

new_data_hash <- digest::sha1(assessment_data[, .SD, .SDcols = c(h_model_cargs[["outcome"]], h_model_cargs[["xs"]])])

if (nrow(assessment_data) == 0L) {
  if (interactive()) {
    stop("assessment_data has zero rows")
  } else {
    sapply(out_files, function(f) { if (file.exists(f)) file.remove(f)} )
    quit()
  }
}

if (all(sapply(out_files, file.exists))) {
  old_data_hash <- scan(out_files[["gcs_data_hash"]], what = character(), quiet = TRUE)
  if ((length(old_data_hash) > 0L) && (old_data_hash == new_data_hash)) {
    if (!interactive()) {
      for(f in out_files) {
        system(paste("touch", f))
      }
      quit()
    }
  }
}



################################################################################
            ## move the assessment_data through the needed models ##
g_pred <-
  lapply(sa2g_model_files, readRDS) |>
  lapply(function(x){ try(predict(x, newdata = assessment_data, type = "response"), silent = TRUE)}) |>
  setNames(h_model_cargs[["xs"]])

if (any(sapply(g_pred, inherits, "try-error"))) {
  if (interactive()) {
    stop("g_pred failure")
  } else {
    for(f in out_files) {
      if (file.exists(f)) {
        file.remove(f)
      }
      system(paste("touch", f))
    }
    dput(g_pred[which(sapply(g_pred, inherits, "try-error"))]
         , file = paste(dirname(out_files[["gcs_cargs"]]), "g_errors", sep = "/")
         )
    quit()
  }
}


for(j in names(g_pred)) {
  data.table::set(assessment_data, j = j , value = g_pred[[j]])
}

X <- as.matrix(assessment_data[, .SD, .SDcols = h_model_cargs[["xs"]]])

preds <- list(
              "lambda.1se" = predict(h_model, newx = X, type = "response", s = "lambda.1se")
              ,"lambda.min" = predict(h_model, newx = X, type = "response", s = "lambda.min")
              )

for (j in names(preds)) {
  data.table::set(assessment_data, j = j, value = preds[[j]])
}

# build data set for model assessement
foo <- function(DT, pred) {
  DT <-
    data.table::data.table(
                           prediction = assessment_data[[pred]]
                           , truth = assessment_data[[h_model_cargs[["outcome"]]]]
                           )[, .N, by = .(prediction, truth)]
  class(DT) <- c("sa1_output", class(DT))
  DT
}

ms <- lapply(c("lambda.min", "lambda.1se"), foo, DT = assessment_data)
names(ms) <- c("lambda.min", "lambda.1se")
reporting_thresholds <- lapply(ms, function(x) sort(unique(x[["prediction"]])))
thresholds <- lapply(ms, function(x) c(0, sort(unique(x[["prediction"]])), 1))

ms <- Map(model_summary, x = ms, thresholds = thresholds)

au <-
  lapply(ms,
         function(x) {data.table::data.table(auroc = attr(x, "auroc"),
                                             auprc = attr(x, "auprc"),
                                             nullmodel = attr(x, "nullmodel"))})

ms <- data.table::rbindlist(ms, idcol = "lambda")
au <- data.table::rbindlist(au, idcol = "lambda")

au[, auroc_label := paste0("AUROC: ", qwraps2::frmt(auroc, digits = 4))]
au[, auprc_label := paste0("AUPRC: ", qwraps2::frmt(auprc, digits = 4))]
au[, nullmodel_label := paste0("Null Model: ", qwraps2::frmt(nullmodel, digits = 4))]

reporting_thresholds <-
  reporting_thresholds |>
  lapply(function(x) {if (is.numeric(x)) {data.table(thresholds = x)} else {NULL}}) |>
  data.table::rbindlist(use.names = TRUE, fill = TRUE, idcol = "lambda")


################################################################################
                              ## Write to disk ##
if (!interactive()) {

  ggplot2::ggsave(  filename = out_files[["gcs_roc_1se"]]
                  , plot     = roc_plot(ms[lambda == "lambda.1se"], au[lambda == "lambda.1se"])
                  , width    = 7
                  , height   = 7
                  , units    = "in"
                  )

  ggplot2::ggsave(  filename = out_files[["gcs_roc_min"]]
                  , plot     = roc_plot(ms[lambda == "lambda.min"], au[lambda == "lambda.min"])
                  , width    = 7
                  , height   = 7
                  , units    = "in"
                  )

  ggplot2::ggsave(  filename = out_files[["gcs_prc_1se"]]
                  , plot     = prc_plot(ms[lambda == "lambda.1se"], au[lambda == "lambda.1se"])
                  , width    = 7
                  , height   = 7
                  , units    = "in"
                  )

  ggplot2::ggsave(  filename = out_files[["gcs_prc_min"]]
                  , plot     = prc_plot(ms[lambda == "lambda.min"], au[lambda == "lambda.min"])
                  , width    = 7
                  , height   = 7
                  , units    = "in"
                  )

  ggplot2::ggsave(plot = confusion_matrix_by_threshold_plot(ms[lambda == "lambda.1se"], vset = 1)
                  , filename = out_files[["gcs_cmtp1_1se"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  ggplot2::ggsave(plot = confusion_matrix_by_threshold_plot(ms[lambda == "lambda.1se"], vset = 2)
                  , filename = out_files[["gcs_cmtp2_1se"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  ggplot2::ggsave(plot = confusion_matrix_by_threshold_plot(ms[lambda == "lambda.min"], vset = 1)
                  , filename = out_files[["gcs_cmtp1_min"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  ggplot2::ggsave(plot = confusion_matrix_by_threshold_plot(ms[lambda == "lambda.min"], vset = 2)
                  , filename = out_files[["gcs_cmtp2_min"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  data.table::fwrite(ms, file = out_files[["gcs_model_summary"]])

  data.table::fwrite(au, file = out_files[["gcs_auroc_auprc"]])

  data.table::fwrite(reporting_thresholds, file = out_files[["gcs_reporting_thresholds"]])

  dput(cargs, file = out_files[["gcs_cargs"]])

  write(new_data_hash, file = out_files[["gcs_data_hash"]])

  # If an error file existed, remove it
  f <- paste(dirname(out_files[["gcs_cargs"]]), "g_errors", sep = "/")
  if (file.exists(f)) {
    file.remove(f)
  }

  f <- paste(dirname(out_files[["gcs_cargs"]]), "h_errors", sep = "/")
  if (file.exists(f)) {
    file.remove(f)
  }
}


################################################################################
                               ## END OF FILE ##
################################################################################
