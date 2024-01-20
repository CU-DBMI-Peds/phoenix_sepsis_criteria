options(warn = 2)
# Train the h-level models
library(data.table)
#library(glmnet) # wait to load this namespace until it is needed, save a little time
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
# outcome training_hash type.measure x1 x2 x3 x4 ... xn
#
# Where the outcome and training_hash, are as they have been with prior scripts.
#
# type.measure - passed to cv.glmnet, options are deviance, class, auc, mae
#
# x1, x2, ... (will require at least one) are the organ
# dysfunction component scores
#
if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
} else {
  # logs <- data.table::fread('high_value_sa2h1.log')
  # logs[Exitval != 0]
  # logs[Exitval != 0, Command ][1]

  high_value_list <- readRDS(high_value_list_rds_path)
  cargs <- list(
      outcome = "death"
    , trained_on = "04910835052f8948f57b88483e70c31d"
    , type.measure = "deviance"
    , alpha = "0"
    , "dic_24_hour_f"
    , "ipscc_hepatic_24_hour"
    , "pelod2_cardiovascular_24_hour_f"
    , "pelod2_neurological_24_hour_f"
    , "podium_endocrine_wo_thyroxine_24_hour"
    , "podium_immunologic_24_hour"
    , "psofa_renal_24_hour_f"
    , "psofa_respiratory_24_hour_f"
    , "vis_b_count_24_hour_f"
    )

}

stopifnot(length(cargs) >= 4L)

names(cargs)[1:4] <- c("outcome", "trained_on", "type.measure", "alpha")
cargs[["xs"]] <- sort(unique(do.call(c, cargs[seq(5, length(cargs))])))
cargs <-cargs[c("outcome", "trained_on", "type.measure", "alpha", "xs")]

training_strata <- read_training_strata()
stopifnot(cargs[["trained_on"]] %in% training_strata[["strata_hash"]])

cargs[["model_hash"]] <- define_h_model_hash(cargs)


################################################################################
                               ## Define paths ##
out_files <- define_sa2h_out_files(cargs)

sa2g_model_files <-
  lapply(
         seq_along(cargs[["xs"]])
         ,
         function(i) {
           cargsi <- cargs
           cargsi[["x"]] <- cargs[["xs"]][i]
           define_sa2g_out_files(cargsi)[["gcs_model_rds"]]
         })

################################################################################
             ## Determine if the model fitting needs to be done ##

# if the h model rds files exists and is younger than all the component g models
# then there is no needed to refit the model
stopifnot(sapply(sa2g_model_files, file.exists))

if (all(sapply(out_files, file.exists))) {

  out_mtimes <-
    lapply(out_files, file.info) |>
    lapply(getElement, "mtime")

  in_mtime <-
    c(SA2g_data_feather_path, SA1_data_feather_path, sa2g_model_files) |>
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
SA2g <- read_SA2g_data()

training_data <-
  subset(SA2g
         , subset = eval(parse(text =
             training_strata[["strata"]][training_strata[["strata_hash"]] == cargs[["trained_on"]]]
           ))
         , select = c(cargs[["outcome"]], cargs[["xs"]], "enc_id")
         )

new_data_hash <- digest::sha1(training_data[, .SD, .SDcols = c(cargs[["outcome"]], cargs[["xs"]])])

# If the training data has no rows then write an empty results file, write the
# cargs and data hash out. then exit the script.  This will make any
# reassessment of the script faster as the out_files will exist.
if (nrow(training_data) == 0L) {
  if (interactive()) {
    stop("training_data has zero rows")
  } else {
    sapply(out_files, function(f) { if (file.exists(f)) file.remove(f)} )
    file.create(out_files[["gcs_model_rds"]])
    dput(cargs, file = out_files[["gcs_cargs"]])
    write(new_data_hash, file = out_files[["data_hash"]])
    quit()
  }
}

# So, now, there is data that could be used to fit a model.  Have we already
# fitted the model on this data?  If so, exit, otherwise, update the model and
# results.
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
                              ## Fit the Model ##
# If you've made it this far in the script then the model needes to be fitted
g_pred <-
  lapply(sa2g_model_files, readRDS) |>
  lapply(function(x){ try(predict(x, newdata = training_data, type = "response"), silent = TRUE)}) |>
  setNames(cargs[["xs"]])

if (any(sapply(g_pred, inherits, "try-error"))) {
  if (interactive()) {
    stop("g_pred failure")
  } else {
    for(f in out_files) {
      system(paste("touch", f))
    }
    dput(g_pred[which(sapply(g_pred, inherits, "try-error"))]
         , file = paste(dirname(out_files[["gcs_model_rds"]]), "g_errors", sep = "/")
         )
    quit()
  }
}

for(j in names(g_pred)) {
    data.table::set(training_data, j = j , value = g_pred[[j]])
}

Y <- matrix(training_data[[cargs[["outcome"]]]], ncol = 1)
X <- as.matrix(training_data[, .SD, .SDcols = cargs[["xs"]]])

# load and attach glmnet namespace now, this saves a little bit of time if there
# was no need to (re)train the model
suppressPackageStartupMessages( library(glmnet) )

h <-
  tryCatchWE({
    cv.glmnet(
        x = X
      , y = Y
      , type.measure = cargs[["type.measure"]]
      , standardized = FALSE # all values are between 0 and 1 already
      , alpha = cargs[["alpha"]] # okay to pass a character, e.g., "0" or "0.02", it works as if you passed the numeric value
      , family = binomial()
    )
  })

# not sure what to do about the errors...
if ( inherits(h[["value"]], "simpleError") ) {
  if (h[["value"]][["message"]] == "All used predictors have zero variance") {
    # well, you will need deal with this in sa2t.R
    message(paste("All used predictors have zero variance\n\n", paste(cargs, collapse = " ")))
  } else if( h[["value"]][["message"]] == "'from' must be a finite number") {
    # well, this is another error that will prevent the model from fitting, so
    # hopefuly sa2t.R will just deal with this
    message(paste("error in seq.default(log(lambda_max), log(lambda_max * lambda.min.ratio),  : 'from' must be a finite number\n\n", paste(cargs, collapse = " ")))
  } else {
    stop("Unexpected error in cv.glment call")
  }
}

if (is.null(h[["warning"]])) {
  h <- h[["value"]]
} else if (h[["warning"]][["message"]] == "glmnet.fit: algorithm did not converge") {
  message(paste(h[["warning"]][["message"]], "\n\n", paste(cargs, collapse = " ")))
  h <- h[["value"]]
} else if (grepl("solutions for larger lambdas returned$", h[["warning"]][["message"]])) {
  message(paste(h[["warning"]][["message"]], "\n\n", paste(cargs, collapse = " ")))
  h <- h[["value"]]
} else {
  stop("Unexpected warning in cv.glmnet")
}

################################################################################
                              ## Write to disk ##
if (!interactive()) {

  saveRDS(h, file = out_files[["gcs_model_rds"]])
  dput(cargs, file = out_files[["gcs_cargs"]])
  write(new_data_hash, file = out_files[["gcs_data_hash"]])

  # If an error file existed, remove it
  f <- paste(dirname(out_files[["gcs_model_rds"]]), "g_errors", sep = "/")
  if (file.exists(f)) {
    file.remove(f)
  }

}

################################################################################
                               ## END OF FILE ##
################################################################################
