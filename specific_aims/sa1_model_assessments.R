options(warn = 2)
library(data.table)
source("utilities.R")

################################################################################
                            ## command line args ##
if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
} else {
  # logs <- data.table::fread(file = "high_value_sa1_assessment_calls.log")
  # logs[Exitval == 1]

  cargs <- list()
  cargs[['x']] <- "ipscc_cardiovascular_12_b_24_hour"
  cargs[["outcome"]] <- "integer_lasso_sepsis_geq2_72_hour"
  cargs[["trained_on"]] <- "64d29573409a0c3b5bc0398b81a7eac2"
  cargs[["assessed_with"]] <- "64d29573409a0c3b5bc0398b81a7eac2"

}

stopifnot(length(cargs) == 4L)
names(cargs) <- c('x', 'outcome', 'trained_on', 'assessed_with')

training_strata <- read_training_strata()
stopifnot(cargs[["trained_on"]] %in% training_strata[["strata_hash"]])

################################################################################
                        ## is the assessment needed? ##

bootstrap_files <- define_sa1_bootstrap_out_files(cargs)
out_files <- define_sa1_assessment_out_files(cargs)

if (length(bootstrap_files[["gcs_results"]]) == 0) {
  stop("no fit_file")
}


# if all the out_files exits and are younger than the results file then there is
# nothing to do
if (all(sapply(out_files, file.exists))) {
  mtimes <-
    lapply(out_files, file.info) |>
    lapply(getElement, "mtime")
  bootstrap_files_youngest <-
    lapply(bootstrap_files, file.info) |>
    sapply(getElement, "mtime") |>
    max()
  if (all(mtimes > bootstrap_files_youngest)) {
    if (interactive()) {
      stop("No need for update")
    } else {
      quit()
    }
  }
}

# If you've made it this far in the script then the assessment needs to be (re)built
# get all the coef
coefs <-
  try(data.table::fread(bootstrap_files[["gcs_results"]]), silent = TRUE)

if ( inherits(coefs, "try-error") ) {
  if (grepl("Discarded single-line footer", coefs)) {
    system(paste("rm", bootstrap_files[["gcs_results"]]))
  } else if (grepl("has size 0", coefs)) {
    if (interactive()) {
      coefs
    } else {
      quit()
    }
  } else {
    stop("Unknown error reading in coefs")
  }
} else {
coefs <-
  coefs |>
  getElement("coef") |>
  lapply(function(x) eval(parse(text = x)))
}

# exit if none of the coefs are numeric
if ( !any(sapply(coefs, is.numeric))) {
  if (interactive()) {
    stop("All coefs are NA")
  } else {
    for(f in out_files) {
      suppressWarnings(file.remove(f))
      system(paste("touch", f))
    }
    quit()
  }
}

new_coef_hash <- digest::digest(coefs, algo = "md5")

if (all(sapply(out_files, file.exists))) {
  old_coef_hash <- scan(out_files[["gcs_coef_hash"]], what = character(), quiet = TRUE)
  if ((length(old_coef_hash) > 0L) && (old_coef_hash == new_coef_hash)) {
    if (!interactive()) {
      for(f in out_files) {
        system(paste("touch", f))
      }
      quit()
    }
  }
}



################################################################################
# if the script has not exited by now then it is time to read in the data for
# the assessment
sensitivity_strata  <- read_sensitivity_strata()
stopifnot(cargs[["assessed_with"]] %in% sensitivity_strata[["strata_hash"]])

sensitivity_strata <-
  subset(sensitivity_strata,
         sensitivity_strata$strata_hash == cargs$assessed_with)

stopifnot(nrow(sensitivity_strata) == 1L)


# NOTE: I have seen cases were a factor has n > 1 levels in the training set but
# only n = 1 levels in the assessment set.  This would cause an error if the
# model matrix was constructed only from the assessment data _after_ subsetting
# to a strata.  Solution, build the model matrix from the full set and then
# subset to a strata via an index.
SA1 <- read_SA1_data()

model_matrix <- model.matrix(formula(paste("~", cargs[["x"]])), data = SA1)

assessment_index <- which(SA1[, eval(parse(text = sensitivity_strata[["strata"]]))])

assessment_data <-
  SA1[assessment_index, .SD, .SDcols = c(cargs[["outcome"]], cargs[["x"]])]

model_matrix <- model_matrix[assessment_index, ]


assessment_data <- droplevels(assessment_data)
data.table::setnames(assessment_data,
                     old = names(assessment_data),
                     new = c("outcome", "x"))


preds <- lapply(coefs, function(B) {
                   try(plogis(as.numeric(model_matrix %*% B)), silent = TRUE)
                     })

reporting_thresholds <- lapply(preds, function(x) sort(unique(x)))
thresholds <- lapply(preds, function(x) c(0, sort(unique(x)), 1))

foo <- function(pred, thresholds) {
  if (is.numeric(pred)) {
    DT <- data.table(prediction = pred, truth = assessment_data[["outcome"]])
    DT <- DT[, .N, by = .(prediction, truth)]
    class(DT) <- c("sa1_output", class(DT))
    model_summary(DT, thresholds = thresholds)
  } else {
    NULL
  }
}

ms <- Map(foo, pred = preds, thresholds = thresholds)

au <-
  lapply(ms,
         function(x) {data.table::data.table(auroc = attr(x, "auroc"),
                                             auprc = attr(x, "auprc"),
                                             nullmodel = attr(x, "nullmodel"))})

ms <- data.table::rbindlist(ms, idcol = "bootstrap")

if(nrow(ms) > 0) {
  ms[, bootstrap := bootstrap - 1L]
} else {
  ms[, bootstrap := integer(0)]
}

au <- data.table::rbindlist(au, idcol = "bootstrap")

if(nrow(au) > 0L) {
  au[, auroc_label := paste0("AUROC: ", qwraps2::frmt(auroc, digits = 4))]
  au[, auprc_label := paste0("AUPRC: ", qwraps2::frmt(auprc, digits = 4))]
  au[, nullmodel_label := paste0("Null Model: ", qwraps2::frmt(nullmodel, digits = 4))]
  au[, bootstrap := bootstrap - 1L]

  au2 <- au[,
    .(
        auroc = mean(auroc)
      , auprc = mean(auprc)
      , nullmodel = mean(nullmodel)
      , auroc_label = paste("AUROC:", qwraps2::frmt(mean(auroc), digits = 4))
      , auprc_label = paste("AUPRC:", qwraps2::frmt(mean(auprc), digits = 4))
      , nullmodel_label = paste("Null:", qwraps2::frmt(mean(nullmodel), digits = 4))
      )]
} else {
  au[, auroc := NA_real_]
  au[, auprc := NA_real_]
  au[, nullmodel := NA_real_]
  au[, auroc_label := character(0)]
  au[, auprc_label := character(0)]
  au[, nullmodel_label := character(0)]
  au[, bootstrap := integer(0)]
  au2 <- au[0]
}

reporting_thresholds <-
  reporting_thresholds |>
  lapply(function(x) {if (is.numeric(x)) {data.table(thresholds = x)} else {NULL}}) |>
  data.table::rbindlist(use.names = TRUE, fill = TRUE, idcol = "bootstrap")

if (nrow(reporting_thresholds) > 0L) {
  reporting_thresholds[, bootstrap := bootstrap - 1L]
} else {
  reporting_thresholds[, bootstrap := integer(0)]
}

coefs <-
  coefs |>
  lapply(as.list) |>
  lapply(data.table::as.data.table) |>
  data.table::rbindlist(use.names = TRUE, fill = TRUE, idcol = "bootstrap") |>
  data.table::melt(id.vars = "bootstrap")

coefs <- coefs[variable != "(Intercept)"]
coefs <- coefs[, bootstrap := bootstrap - 1]
coefs[, variable := sub("x", cargs$x, variable)]

################################################################################
                               ## Define Plots ##

plots <- list()

g_blank_plot <-
  ggplot2::ggplot() +
    ggplot2::theme_void() +
    ggplot2::aes(x = 1, y = 1) +
    ggplot2::geom_text(label = "No model summary information to plot")

if (nrow(ms) > 0L) {
  plots[["roc_plot"]] <- roc_plot(ms, au2)
  plots[["prc_plot"]] <- prc_plot(ms, au2)
  plots[["cmbt_plot1"]] <- confusion_matrix_by_threshold_plot(ms, vset = 1)
  plots[["cmbt_plot2"]] <- confusion_matrix_by_threshold_plot(ms, vset = 2)
} else {
  plots[["roc_plot"]] <- g_blank_plot
  plots[["prc_plot"]] <- g_blank_plot
  plots[["cmbt_plot1"]] <- g_blank_plot
  plots[["cmbt_plot2"]] <- g_blank_plot
}

if (nrow(reporting_thresholds) > 0L) {
  plots[["threshold_violin_plot"]] <-
    ggplot2::ggplot(reporting_thresholds) +
    ggplot2::theme_bw() +
    ggplot2::aes(x = cargs$x, y = thresholds) +
    ggplot2::geom_violin() +
    ggplot2::geom_point() +
    ggplot2::theme(
      axis.title.x = ggplot2::element_blank()
      )
} else {
  plots[["threshold_violin_plot"]] <- g_blank_plot
}

if (nrow(coefs) > 0L) {
  plots[["regression_coefficient_plot"]] <-
    ggplot2::ggplot(coefs[!is.na(value)]) +
    ggplot2::theme_bw() +
    ggplot2::aes(x = variable, y = value) +
    ggplot2::geom_violin() +
    ggplot2::geom_boxplot(alpha = 0.5) +
    ggplot2::geom_point(data = coefs[bootstrap == "0"], color = "red") +
    ggplot2::xlab("") +
    ggplot2::ylab("")
} else {
  plots[["regression_coefficient_plot"]] <- g_blank_plot
}



################################################################################
                              ## Write to disk ##

if (!interactive()) {
  # some of the plots generate warnings that should not be errors but will only
  # do so when printed, saved, etc. Reduce the warning level so the graphics
  # will save.  Most common error is an infinite value on the x-axis comming
  # from the log10 transformin cmbt_plot1 and cmbt_plot2.
  options(warn = 1)

  # gcs output first then local disk, gcsfuse is required and the mount needs to
  # be active

  # ROC Plot
  ggplot2::ggsave(filename = out_files[["gcs_roc_plot"]]
                  , plot = plots[["roc_plot"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # PRC Plot
  ggplot2::ggsave(filename = out_files[["gcs_prc_plot"]]
                  , plot = plots[["prc_plot"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # Confusion Matrix by Threshold 1
  ggplot2::ggsave(filename = out_files[["gcs_cmbt_plot1"]]
                  , plot = plots[["cmbt_plot1"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # Confusion Matrix by Threshold 2
  ggplot2::ggsave(filename = out_files[["gcs_cmbt_plot2"]]
                  , plot = plots[["cmbt_plot2"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # Threshold Violin Plot
  ggplot2::ggsave(filename = out_files[["gcs_threshold_violin_plot"]]
                  , plot = plots[["threshold_violin_plot"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # Regression Coefficient Plots
  ggplot2::ggsave(filename = out_files[["gcs_regression_coefficient_plot"]]
                  , plot = plots[["regression_coefficient_plot"]]
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # model summary
  data.table::fwrite(ms, file = out_files[["gcs_model_summary"]])

  # au
  data.table::fwrite(au, file = out_files[["gcs_auroc_auprc"]])

  # reporting_thresholds
  data.table::fwrite(reporting_thresholds, file = out_files[["gcs_reporting_thresholds"]])

  # coef_hash
  write(new_coef_hash, file = out_files[["gcs_coef_hash"]])

}

################################################################################
                               ## End of file ##
################################################################################
