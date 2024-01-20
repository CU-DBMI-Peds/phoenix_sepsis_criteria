
################################################################################
##                           Namespaces and Options                           ##
library(data.table)

u1 <- new.env()
u2 <- new.env()
source("../specific_aims/utilities.R", local = u1)
source("../specific_aims/utilities2.R", local = u2)

if (!("R01_DATA" %in% ls())) {
  R01_DATA <-
    list(
        "read_SA1_data"
      , "read_SA2g_data"
      , "read_SA2h_data"
      , "read_SA2t_data"
      , "read_**REDACTED**_data"
      , "read_**REDACTED**_data"
      , "read_**REDACTED**_data"
    )
  R01_DATA <-
    with(u1,
         parallel::mclapply(
             X = R01_DATA
          , FUN = function(w) {do.call(what = w, args = list())}
          , mc.cores = length(R01_DATA)
          )
         ) |>
    data.table::rbindlist()
  R01_DATA[, IC := fifelse(site %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**"), "LMIC", "HIC")]
  SA1 <- R01_DATA[sa_subset == "SA1"]
  SA1_HIC_1DOSE <- SA1[IC == "HIC" & suspected_infection_1dose_24_hour == 1L]
}

################################################################################

p24 <- u1$read_predictors()[time_from_hospital_presentation == "< 24 hours"]
p24[, f := paste("glm(death ~", x, ", data = SA1, family = binomial())"), by = x]

auc <- function(x) {
  fit <- eval(parse(text = x))
  DT <- data.table(d = SA1[["death"]], p = fit$fitted)[, .N, keyby = .(d, p)]
  thresholds <- c(0, unique(DT[["p"]]), 1)
  TN <- sapply(thresholds, function(x) {DT[d == 0 & p <  x, sum(N)]})
  TP <- sapply(thresholds, function(x) {DT[d == 1 & p >= x, sum(N)]})
  FN <- sapply(thresholds, function(x) {DT[d == 1 & p <  x, sum(N)]})
  FP <- sapply(thresholds, function(x) {DT[d == 0 & p >= x, sum(N)]})
  DT <- data.table(threshold = thresholds, TP, TN, FN, FP)
  DT[,
     `:=`(
            precision = u2$precision(TP, TN, FP, FN) #ppv
          , recall = u2$recall(TP, TN, FP, FN) # sensitivity
          , specificity = u2$specificity(TP, TN, FP, FN)
         )
     , by = .(threshold)]
  n <- nrow(DT)

  auprc <- sum((DT$recall[1:(n-1)] - DT$recall[2:n]) * 1/2 * (DT$precision[1:(n-1)] + DT$precision[2:n]))
  auroc <- sum(((1 - DT$specificity[1:(n-1)]) - (1 - DT$specificity[2:n])) * 1/2 * (DT$recall[1:(n-1)] + DT$recall[2:n]))

  N <- unique(TN + TP + FN + FP)
  stopifnot(length(N) == 1L)

  theta_hat <- auprc
  mu_hat    <- qlogis(theta_hat)
  tau       <- 1 / sqrt( N * theta_hat * (1 - theta_hat))

  auprc_lcl <- plogis(mu_hat + qnorm(0.025) * tau)
  auprc_ucl <- plogis(mu_hat + qnorm(0.975) * tau)

  theta_hat <- auroc
  mu_hat    <- qlogis(theta_hat)
  tau       <- 1 / sqrt( N * theta_hat * (1 - theta_hat))
  auroc_lcl <- plogis(mu_hat + qnorm(0.025) * tau)
  auroc_ucl <- plogis(mu_hat + qnorm(0.975) * tau)

  data.table(
    auprc = auprc
  , auprc_lcl
  , auprc_ucl
  , auroc
  , auroc_lcl
  , auroc_ucl
  )
}

p24_auc <- p24[, auc(f), by = .(predictor, predictor_type, organ_system, scoring_system)]

p24_auc[grepl("Shock Index", scoring_system), scoring_system := "Shock Index"]


p24_auc[, txt := gsub("_24_hour", "", predictor), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub(paste0(scoring_system), "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("shock_index_", "", txt), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("qpelod2", "", txt), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("pelod2", "", txt), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub(organ_system, "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("integer_lasso_sepsis", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("integer_ridge_sepsis", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("coagulation", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("coag", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("heme", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("neurologic", "", txt, ignore.case = TRUE), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("^_+", "", txt), by = .(predictor,predictor_type,organ_system,scoring_system)]
p24_auc[, txt := gsub("_", " ", txt), by = .(predictor,predictor_type,organ_system,scoring_system)]


################################################################################
##                             Save Data to Disk                              ##
feather::write_feather(p24_auc, path = "individual_subscore_summaries.feather")

data.table::setkey(p24_auc, organ_system, scoring_system, predictor)

p24_auc[organ_system == "Cardiovascular"] |> print(n=Inf)

data.table::fwrite(p24_auc, file = "individual_subscore_summaries.csv")

################################################################################
##                                End of File                                 ##
################################################################################
