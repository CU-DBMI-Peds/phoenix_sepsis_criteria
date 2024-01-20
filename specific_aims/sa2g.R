options(warn = 2)
# Train the g-level models
#
# IMPORTANT NOTE: -- **REDACTED**
# June 2023) the data used to train the g-level models with be the SA1 data
# split.  SA2g will then be used to train the h-level models SA2h will be used
# as a testing / assessment set for SA2 to help select hyper parameters such as
# lambda (ridge/lasso penalty) and alpha (ridge/elastic net/lasso)
#
library(data.table)
source("utilities.R")

################################################################################
                            ## command line args ##
if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
  cargs <- cargs[1:3]
} else {
  # logs <- data.table::fread("high_value_sa2g.log")
  # logs[Exitval == 1]
  cargs <- list()
  cargs[["x"]] <- "pelod2_neurological_24_hour_f"
  cargs[["outcome"]] <- "integer_lasso_sepsis_1dose_geq3_24_hour"
  cargs[["trained_on"]] <- "cd46c372ac5f249c561da18eab129391"
}

stopifnot(length(cargs) == 3L)
cargs <- setNames(cargs, c("x", "outcome", "trained_on"))

stopifnot(cargs[["outcome"]] %in% define_outcome())

training_strata <- read_training_strata()
stopifnot(cargs[["trained_on"]] %in% training_strata[["strata_hash"]])

################################################################################
                      ## Define paths for output files ##

out_files <- define_sa2g_out_files(cargs)

################################################################################
             ## Determine if the model fitting needs to be done ##

# If the out_files exists and are younger than the SA2g data then there is no
# needed to update the model
if (all(sapply(out_files, file.exists))) {
  mtimes <-
    lapply(out_files, file.info) |>
    lapply(getElement, "mtime")
  SA1_mtime <- file.info(SA1_data_feather_path)$mtime
  if (all(mtimes > SA1_mtime)) {
    if (interactive()) {
      message("No need for update")
    } else {
      quit()
    }
  }
}

# If the script reaches this point in non-interactive mode, then we should check
# the md5 hash of the data to see if an update is needed
SA1 <- read_SA1_data()

training_data <-
  subset(SA1,
         , subset = eval(parse(text =
             training_strata[["strata"]][training_strata[["strata_hash"]] == cargs[["trained_on"]]]
           ))
         , select = c(cargs[["outcome"]], cargs[["x"]], "enc_id")
         )

new_data_hash <- digest::sha1(training_data[, .SD, .SDcols = c(cargs[["outcome"]], cargs[["x"]])])

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
    write(new_data_hash, file = out_files[["gcs_data_hash"]])
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


if ( length((unique(training_data[[cargs[["x"]]]]))) < 2) {
  f <- formula(paste(cargs[["outcome"]], "1", sep = " ~ "))
} else {
  f <- formula(paste(cargs[["outcome"]], cargs[["x"]], sep = " ~ "))
}

g <- tryCatchWE(glm(formula = f, data = training_data, family = binomial()))

if (is.null(g[["warning"]])) {
  g <- g[["value"]]
} else if (g[["warning"]][["message"]] == "glm.fit: fitted probabilities numerically 0 or 1 occurred") {
  g <- g[["value"]]
} else if (g[["warning"]][["message"]] == "glm.fit: algorithm did not converge") {
  g <- g[["value"]]
} else {
  stop("Unexpected warning in g model training")
}

if (inherits(g, "simpleError")) {
  stop("Error in g model training")
}

# remove, or rather, retain only the details needed for the predict() call to
# work in the next step
g <- reduce_glm_size(g, verbose = interactive())

################################################################################
                              ## Write to disk ##
if (!interactive()) {

  saveRDS(g, file = out_files[["gcs_model_rds"]])
  dput(cargs, file = out_files[["gcs_cargs"]])
  write(new_data_hash, file = out_files[["gcs_data_hash"]])

}


################################################################################
                               ## END OF FILE ##
################################################################################
