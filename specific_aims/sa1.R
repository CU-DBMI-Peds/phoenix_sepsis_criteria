options(warn = 2)
library(data.table)
source("utilities.R")

################################################################################
                            ## command line args ##

if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
} else {
  # for dev work
  # logs <- data.table::fread(file = "high_value_sa1_model_calls1.log", colClasses = character(), header = TRUE)
  logs[Exitval != 0]
  cargs <- list()
  cargs[['x']] <- "pews_saturation_24_hour_f"
  cargs[["outcome"]] <- "death"
  cargs[["trained_on"]] <- "78b12f5069ca8530f878d857e0058f67"
  cargs[["bootstraps"]] <- "100"
  # cargs[["bootstraps"]] <- "3"
}

stopifnot(length(cargs) == 4L)
names(cargs) <- c("x", "outcome", "trained_on", "bootstraps")
cargs$bootstraps <- as.integer(cargs[["bootstraps"]])

training_strata <- read_training_strata()
stopifnot(cargs[["trained_on"]] %in% training_strata[["strata_hash"]])

predictors <- read_predictors()
stopifnot(cargs[["x"]] %in% predictors[["x"]])

stopifnot(cargs[["outcome"]] %in% define_outcome())

################################################################################
                      ## Define paths for output files ##

out_files <- define_sa1_bootstrap_out_files(cargs)

################################################################################
             ## Determine if the model fitting needs to be done ##

# if all the output files exist and the modified time is greater than the
# modified time for the SA1 data on the disk then there is no need to think
# about this any harder, the results are up to date.
if (all(sapply(out_files, file.exists))) {
  mtimes <-
    lapply(out_files, file.info) |>
    lapply(getElement, "mtime")
  SA1_mtime <- file.info(SA1_data_feather_path)$mtime
  if (all(mtimes > SA1_mtime)) {
    if (interactive()) {
      stop("No need for update")
    } else {
      quit()
    }
  }
}


# If the script reaches this point in non-interactive mode, then we should check
# the sha1 hash of the data to see if an update is needed

SA1 <- read_SA1_data()

ss <- training_strata[["strata"]][training_strata[["strata_hash"]] == cargs[["trained_on"]]]
training_data <-
  subset(SA1
         , subset = eval(parse(text = ss))
         , select = c(cargs$outcome, cargs$x, "enc_id")
         )

data.table::setnames(training_data, old = c(cargs[["outcome"]], cargs$x), new = c("outcome", "x"))

new_data_hash <- digest::sha1(training_data[, .SD, .SDcols = c("outcome", "x")])

# If the training data has no rows then write an empty results file, write the
# cargs and data hash out. then exit the script.  This will make any
# reassessment of the script faster as the out_files will exist.
if (nrow(training_data) == 0L) {
  if (interactive()) {
    stop("training_data has zero rows")
  } else {
    sapply(out_files, function(f) { if (file.exists(f)) file.remove(f)} )
    file.create(out_files[["gcs_results"]])
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
        # touching the files so the mtime check will find that the results are up to date
        system(paste("touch", f))
      }
      quit()
    }
  }
}

################################################################################
                              ## Fit the Model ##

# Deine a function for fitting the model and getting the needed results
fit_sa1_model <- function(this_data) {
  fit <- tryCatchWE(glm(outcome ~ x, data = this_data, family = binomial()))

  e <- NULL

  if (inherits(fit$value, "glm")) {
    if (!any(is.na(coef(fit$value)))) {
      m <- fit[[1]]
    } else {
      m <- NULL
      e <- "not all regression coefficients are defined"
    }
  } else if (inherits(fit$value, "simpleError")) {
    m <- NULL
    e <- fit$value$message
  } else {
    stop("unexpected return for fit object")
  }

  if (is.null(m)) {
    b <- NA_character_
    s <- NA_character_
  } else {
    b <- m |> coef() |> dput() |> capture.output() |> paste(collapse = "") |> gsub("\"", "'", x = _)
    s <- m |> vcov() |> dput() |> capture.output() |> paste(collapse = "") |> gsub("\"", "'", x = _)
  }

  results <-
    data.table::data.table(
        coef        = b
      , vcov        = s
      , warning     = NA_character_
      , error       = NA_character_
      )

  if (is.null(fit$warning$message)) {
    results[, warning := NA_character_]
  } else {
    results[, warning := fit$warning$message]
  }

  if (is.null(e)) {
    results[, error := NA_character_]
  } else {
    results[, error := e]
  }

  results
}

b0 <- fit_sa1_model(training_data)
b0[, bootstrap := 0]

b <- replicate(cargs$bootstraps,
                {
                  this_data <- training_data[sample(1:nrow(training_data), replace = TRUE)]
                  fit_sa1_model(this_data)
                },
                simplify = FALSE
                )

r <- data.table::rbindlist(b, idcol = "bootstrap")
r <- rbind(b0, r, use.names = TRUE)

# set meta data
data.table::set(r, j = "trained_on", value = cargs[["trained_on"]])
data.table::set(r, j = "outcome", value = cargs[["outcome"]])
data.table::set(r, j = "x", value = cargs[["x"]])

################################################################################
                              ## Write to disk ##

if (!interactive()) {
  dput(cargs, file = out_files[["gcs_cargs"]])
  write(new_data_hash, file = out_files[["gcs_data_hash"]])
  data.table::fwrite(r, file = out_files[["gcs_results"]])
}


################################################################################
                               ## END OF FILE ##
################################################################################
