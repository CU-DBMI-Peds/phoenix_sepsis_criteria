library(data.table)
source("utilities.R")

################################################################################
# build a set of commands to build the model assessments
training_strata  <- readRDS(training_strata_rds_path)
predictors       <- readRDS(predictors_rds_path)

model_assessment_calls <-
  data.table::CJ(
                   trained_on = training_strata$strata_hash
                 , outcome = unname(define_outcome())
                 , x = predictors$x
                 , sorted = FALSE
                 )
data.table::set(model_assessment_calls, j = "assessed_with", value = model_assessment_calls$trained_on)

# model_assessment_calls[, assessed_with := trained_on]
model_assessment_calls <-
  model_assessment_calls[, .(cl = "Rscript --vanilla --quiet sa1_model_assessments.R", x, outcome, trained_on, assessed_with)]

data.table::fwrite(model_assessment_calls, file = "sa1_model_assessment_calls.txt", col.names = FALSE, sep = " ", quote = FALSE)

sa1_organ_system_summary_calls <-
  sa1_organ_system_summary_calls[, .(cl = "Rscript --vanilla --quiet sa1_organ_system_summaries.R", organ_system, tfhp, outcome, trained_on, assessed_with)]

data.table::fwrite(sa1_organ_system_summary_calls, file = "sa1_organ_system_summary_calls.txt", col.names = FALSE, sep = " ", quote = FALSE)

################################################################################
                               ## END OF FILE ##
################################################################################
