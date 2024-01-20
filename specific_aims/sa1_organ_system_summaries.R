options(warn = 2)
library(data.table)
source("utilities.R")

################################################################################
                            ## command line args ##
if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
} else {
  # logs <- data.table::fread("high_value_sa1_organ_system_summary_calls1.log")
  # logs[Exitval != 0]
  cargs <- list(
                  "Heme/Coag"
                , "24hours"
                , "integer_lasso_sepsis_0dose_geq2_72_hour"
                , "04910835052f8948f57b88483e70c31d"
                , "04910835052f8948f57b88483e70c31d"
                )
}

stopifnot(length(cargs) == 5L)
names(cargs) <- c('organ_system', "time_from_hospital_presentation", 'outcome', 'trained_on', 'assessed_with')

################################################################################
                        ## is the assessment needed? ##

out_files <- define_sa1_organ_system_summary_out_files(cargs)
predictors <- read_predictors()

xs <-
  predictors[organ_system == cargs$organ_system &
             gsub("\\s", "", sub("<", "", time_from_hospital_presentation)) == cargs$time_from_hospital_presentation
             , x]

model_summary_files <-
  xs |>
  lapply(function(x) {c(cargs, x = x)}) |>
  lapply(define_sa1_assessment_out_files) |>
  setNames(xs)

# if all the out_files exits and are younger than the results file then there is
# nothing to do -- HOWEVER -- REBUILDING EVERYTHING TAKES LESS TIME THAN THIS
# CHECK TAKES
# if (all(sapply(out_files, file.exists))) {
#   # find the oldest outfile"
#   mtimes <-
#     lapply(out_files, file.info) |>
#     lapply(getElement, "mtime") |>
#     lapply(as.numeric) |>
#     do.call(c, args = _) |>
#     min()
#
#   # find youngest model summary file mtime
#   msfs_mtimes <-
#     model_summary_files |>
#     lapply(lapply, file.info) |>
#     lapply(lapply, function(x) as.numeric(getElement(x, "mtime"))) |>
#     lapply(function(x) max(do.call(c, x))) |>
#     do.call(c, args = _) |>
#     max()
#
#   # if the oldest mtime is younger than the youngest msfs then do nothing
#   if (all(mtimes > msfs_mtimes)) {
#     if (interactive()) {
#       stop("No need for update")
#     } else {
#       quit()
#     }
#   }
# }

# If you've made it this far in the script then the assessment needs to be (re)built
# get all the coef
auroc_auprc <-
  model_summary_files |>
  lapply(getElement, "gcs_auroc_auprc") |>
  Filter(f = function(x) file.size(x) > 0) |>
  lapply(data.table::fread) |>
  data.table::rbindlist(idcol = "x", use.names = TRUE, fill = TRUE)

model_summary <-
  model_summary_files |>
  lapply(getElement, "gcs_model_summary") |>
  Filter(f = function(x) file.size(x) > 0) |>
  lapply(data.table::fread) |>
  data.table::rbindlist(idcol = "x", use.names = TRUE, fill = TRUE)

# handle the case when there is no data to plot as there was no data generated
# create empty files and graphics
if (nrow(auroc_auprc) == 0L & nrow(model_summary) == 0L) {
  mean_auc <- data.table()
  roc_plot <- prc_plot <- auroc_by_auprc_plot <-
    ggplot2::ggplot() +
      ggplot2::theme_void() +
      ggplot2::aes(x = 1, y = 1) +
      ggplot2::geom_text(label = "No model summary information to plot")
} else {
  mean_auc <-
    auroc_auprc[, .(
        min_auroc  = min(auroc)
      , mean_auroc = mean(auroc)
      , max_auroc = max(auroc)
      , min_auprc = min(auprc)
      , mean_auprc = mean(auprc)
      , max_auprc = max(auprc)
      , mean_nullmodel = mean(nullmodel)
      )
      , by = .(x)
      ]
  mean_auc[, auroc_rank := rank(-mean_auroc, ties.method = "first")]
  mean_auc[, auprc_rank := rank(-mean_auprc, ties.method = "first")]

  top_three <- mean_auc[auroc_rank <= 3 | auprc_rank <= 3]
  data.table::setorder(top_three, auprc_rank)

  model_summary[x %in% top_three$x, x2 := x]
  model_summary[is.na(x2), x2 := "Others"]
  model_summary[, x2 := factor(x2, levels = c(top_three$x, "Others"))]
  model_summary <- merge(model_summary, top_three, all.x = TRUE, by = "x")

  mean_auc[x %in% top_three$x, x2 := x]
  mean_auc[is.na(x2), x2 := "Others"]
  mean_auc[, x2 := factor(x2, levels = c(top_three$x, "Others"))]
  # data.table::setorder(mean_auc, auprc_rank, auroc_rank)

  roc_plot <-
    ggplot2::ggplot(model_summary) +
    ggplot2::theme_bw() +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::aes(x = 1 - specificity, y = sensitivity, group = x, color = x2) +
    ggplot2::geom_line(data = ~ subset(.x, .x$x2 == "Others"), alpha = 0.5) +
    ggplot2::geom_point(data = ~ subset(.x, .x$x2 != "Others")) +
    ggplot2::geom_line(data = ~ subset(.x, .x$x2 != "Others")) +
    ggplot2::geom_segment(data = data.frame(x = 0, y = 0, xend = 1, yend = 1)
                          , mapping = ggplot2::aes(x = 0, y = 0, xend = 1, yend = 1)
                          , linetype = 3
                          , inherit.aes = FALSE
                          ) +
    ggplot2::scale_color_brewer(type = "qual", palette = "Paired", breaks = levels(model_summary$x2)) +
    ggplot2::theme(
        legend.position = c(0.99, 0.01)
      , legend.title = ggplot2::element_blank()
      , legend.justification = c(1, 0)
      )

  prc_plot <-
    ggplot2::ggplot() +
    ggplot2::theme_bw() +
    ggplot2::aes(x = sensitivity, y = ppv, group = x, color = x2) +
    ggplot2::geom_line(data = model_summary[x2 == "Others"], alpha = 0.5) +
    ggplot2::geom_point(data = model_summary[x2 != "Others"]) +
    ggplot2::geom_line(data = model_summary[x2 != "Others"]) +
    ggplot2::geom_hline(data = mean_auc[!is.na(mean_nullmodel)], mapping = ggplot2::aes(yintercept = mean_nullmodel)) +
    ggplot2::scale_color_brewer(type = "qual", palette = "Paired", breaks = levels(model_summary$x2)) +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::theme(
        legend.position = c(0.99, 0.99)
      , legend.title = ggplot2::element_blank()
      , legend.justification = c(1, 1)
      )

  auroc_by_auprc_plot <-
    ggplot2::ggplot(mean_auc[!is.na(mean_auprc) & !is.na(mean_auroc)]) +
    ggplot2::theme_bw() +
    ggplot2::aes(x = mean_auprc, y = mean_auroc, color = x2) +
    ggplot2::geom_point(data = function(x) subset(x, x2 != "Others")) + #mean_auc[x2 != "Others"]) +
    ggplot2::geom_point(data = function(x) subset(x, x2 == "Others"), alpha = 0.5) + #mean_auc[x2 != "Others"]) +
    ggplot2::geom_linerange(mapping = ggplot2::aes(xmin = min_auprc, xmax = max_auprc)) +
    ggplot2::geom_linerange(mapping = ggplot2::aes(ymin = min_auroc, ymax = max_auroc)) +
    ggplot2::scale_color_brewer(type = "qual", palette = "Paired", breaks = levels(model_summary$x2)) +
    # ggplot2::coord_equal(xlim = c(0, 0.5), ylim = c(0.5, 1.0)) +
    ggplot2::coord_equal(ylim = c(0.5, 1.0)) +
    ggplot2::xlab("Mean AUPRC") +
    ggplot2::ylab("Mean AUROC") +
    ggplot2::theme(
                   # legend.position = "bottom", #c(0.99, 0.01)
      , legend.title = ggplot2::element_blank()
      # , legend.justification = c(1, 0)
      # , legend.background = ggplot2::element_rect(linetype = 1)
      )

}


################################################################################
                              ## Write to disk ##

if (!interactive()) {
  # gcs output first then local disk, gcsfuse is required and the mount needs to
  # be active

  # ROC Plot
  ggplot2::ggsave(filename = out_files[["gcs_roc_plot"]]
                  , plot = roc_plot
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # PRC Plot
  ggplot2::ggsave(filename = out_files[["gcs_prc_plot"]]
                  , plot = prc_plot
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # Regression Coefficient Plots
  ggplot2::ggsave(filename = out_files[["gcs_auroc_by_auprc_plot"]]
                  , plot = auroc_by_auprc_plot
                  , width = 7
                  , height = 7
                  , units = "in"
                  )

  # mean_auc
  saveRDS(mean_auc, file = out_files[["gcs_mean_auc"]])

}

################################################################################
                               ## End of file ##
################################################################################
