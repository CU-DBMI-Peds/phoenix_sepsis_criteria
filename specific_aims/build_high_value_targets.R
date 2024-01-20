# build "high value" models and assessments
library(data.table)
source("utilities.R")
training_strata <- read_training_strata()
sensitivity_strata <- read_sensitivity_strata()
predictors <- read_predictors()

################################################################################
                       ## Specify High Value Outcomes ##

outcomes <- c(
    "death"
  , "early_death"
  , "ecmo_or_death"
  , "ecmo"
  , "early_ecmo"
  , "ecmo_or_early_death"
  , "early_ecmo_or_death"
  , "early_ecmo_or_early_death"

  , "integer_lasso_sepsis_geq2_24_hour"
  , "integer_lasso_sepsis_geq2_48_hour"
  , "integer_lasso_sepsis_geq2_72_hour"
  # , "integer_lasso_sepsis_0dose_geq2_24_hour"
  # , "integer_lasso_sepsis_0dose_geq2_48_hour"
  # , "integer_lasso_sepsis_0dose_geq2_72_hour"
  # , "integer_lasso_sepsis_1dose_geq2_24_hour"
  # , "integer_lasso_sepsis_1dose_geq2_48_hour"
  # , "integer_lasso_sepsis_1dose_geq2_72_hour"
  # , "integer_lasso_sepsis_2doses_geq2_24_hour"
  # , "integer_lasso_sepsis_2doses_geq2_48_hour"
  # , "integer_lasso_sepsis_2doses_geq2_72_hour"

  #   , "integer_lasso_sepsis_geq3_24_hour"
  #   , "integer_lasso_sepsis_geq3_48_hour"
  #   , "integer_lasso_sepsis_geq3_72_hour"
  #   , "integer_lasso_sepsis_0dose_geq3_24_hour"
  #   , "integer_lasso_sepsis_0dose_geq3_48_hour"
  #   , "integer_lasso_sepsis_0dose_geq3_72_hour"
  #   , "integer_lasso_sepsis_1dose_geq3_24_hour"
  #   , "integer_lasso_sepsis_1dose_geq3_48_hour"
  #   , "integer_lasso_sepsis_1dose_geq3_72_hour"
  #   , "integer_lasso_sepsis_2doses_geq3_24_hour"
  #   , "integer_lasso_sepsis_2doses_geq3_48_hour"
  #   , "integer_lasso_sepsis_2doses_geq3_72_hour"
  #
  #   , "integer_lasso_sepsis_geq4_24_hour"
  #   , "integer_lasso_sepsis_geq4_48_hour"
  #   , "integer_lasso_sepsis_geq4_72_hour"
  #   , "integer_lasso_sepsis_0dose_geq4_24_hour"
  #   , "integer_lasso_sepsis_0dose_geq4_48_hour"
  #   , "integer_lasso_sepsis_0dose_geq4_72_hour"
  #   , "integer_lasso_sepsis_1dose_geq4_24_hour"
  #   , "integer_lasso_sepsis_1dose_geq4_48_hour"
  #   , "integer_lasso_sepsis_1dose_geq4_72_hour"
  #   , "integer_lasso_sepsis_2doses_geq4_24_hour"
  #   , "integer_lasso_sepsis_2doses_geq4_48_hour"
  #   , "integer_lasso_sepsis_2doses_geq4_72_hour"
  #
  #   , "integer_lasso_sepsis_geq5_24_hour"
  #   , "integer_lasso_sepsis_geq5_48_hour"
  #   , "integer_lasso_sepsis_geq5_72_hour"
  #   , "integer_lasso_sepsis_0dose_geq5_24_hour"
  #   , "integer_lasso_sepsis_0dose_geq5_48_hour"
  #   , "integer_lasso_sepsis_0dose_geq5_72_hour"
  #   , "integer_lasso_sepsis_1dose_geq5_24_hour"
  #   , "integer_lasso_sepsis_1dose_geq5_48_hour"
  #   , "integer_lasso_sepsis_1dose_geq5_72_hour"
  #   , "integer_lasso_sepsis_2doses_geq5_24_hour"
  #   , "integer_lasso_sepsis_2doses_geq5_48_hour"
  #   , "integer_lasso_sepsis_2doses_geq5_72_hour"

  # , "integer_lasso_sepsis_geq6_24_hour"
  # , "integer_lasso_sepsis_geq6_48_hour"
  # , "integer_lasso_sepsis_geq6_72_hour"
  # , "integer_lasso_sepsis_0dose_geq6_24_hour"
  # , "integer_lasso_sepsis_0dose_geq6_48_hour"
  # , "integer_lasso_sepsis_0dose_geq6_72_hour"
  # , "integer_lasso_sepsis_1dose_geq6_24_hour"
  # , "integer_lasso_sepsis_1dose_geq6_48_hour"
  # , "integer_lasso_sepsis_1dose_geq6_72_hour"
  # , "integer_lasso_sepsis_2doses_geq6_24_hour"
  # , "integer_lasso_sepsis_2doses_geq6_48_hour"
  # , "integer_lasso_sepsis_2doses_geq6_72_hour"

  #   , "integer_lasso_sepsis_remote_geq2_24_hour"
  #   , "integer_lasso_sepsis_remote_geq2_48_hour"
  #   , "integer_lasso_sepsis_remote_geq2_72_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq2_24_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq2_48_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq2_72_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq2_24_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq2_48_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq2_72_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq2_24_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq2_48_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq2_72_hour"
  #
  #   , "integer_lasso_sepsis_remote_geq3_24_hour"
  #   , "integer_lasso_sepsis_remote_geq3_48_hour"
  #   , "integer_lasso_sepsis_remote_geq3_72_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq3_24_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq3_48_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq3_72_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq3_24_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq3_48_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq3_72_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq3_24_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq3_48_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq3_72_hour"
  #
  #   , "integer_lasso_sepsis_remote_geq4_24_hour"
  #   , "integer_lasso_sepsis_remote_geq4_48_hour"
  #   , "integer_lasso_sepsis_remote_geq4_72_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq4_24_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq4_48_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq4_72_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq4_24_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq4_48_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq4_72_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq4_24_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq4_48_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq4_72_hour"
  #
  #   , "integer_lasso_sepsis_remote_geq5_24_hour"
  #   , "integer_lasso_sepsis_remote_geq5_48_hour"
  #   , "integer_lasso_sepsis_remote_geq5_72_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq5_24_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq5_48_hour"
  #   , "integer_lasso_sepsis_remote_0dose_geq5_72_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq5_24_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq5_48_hour"
  #   , "integer_lasso_sepsis_remote_1dose_geq5_72_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq5_24_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq5_48_hour"
  #   , "integer_lasso_sepsis_remote_2doses_geq5_72_hour"

  # , "integer_lasso_sepsis_remote_geq6_24_hour"
  # , "integer_lasso_sepsis_remote_geq6_48_hour"
  # , "integer_lasso_sepsis_remote_geq6_72_hour"
  # , "integer_lasso_sepsis_remote_0dose_geq6_24_hour"
  # , "integer_lasso_sepsis_remote_0dose_geq6_48_hour"
  # , "integer_lasso_sepsis_remote_0dose_geq6_72_hour"
  # , "integer_lasso_sepsis_remote_1dose_geq6_24_hour"
  # , "integer_lasso_sepsis_remote_1dose_geq6_48_hour"
  # , "integer_lasso_sepsis_remote_1dose_geq6_72_hour"
  # , "integer_lasso_sepsis_remote_2doses_geq6_24_hour"
  # , "integer_lasso_sepsis_remote_2doses_geq6_48_hour"
  # , "integer_lasso_sepsis_remote_2doses_geq6_72_hour"

  )

################################################################################
                    ## Specify High Value Trafning Sets ##

## This is no longer done in this script.  See build_strata.R.
##
## Previously, all the possible combinations for conditions for strata were
## being generated, but that has gotten too big to be usefule.  Specific, and
## named, strata are now generated in the build_strata.R script and used here.
training_hashes <-training_strata[["strata_hash"]]

################################################################################
                   ## Specify High Value Assessment Sets ##
## This is no longer done in this script.  See build_strata.R.
##
## Previously, all the possible combinations for conditions for strata were
## being generated, but that has gotten too big to be usefule.  Specific, and
## named, strata are now generated in the build_strata.R script and used here.
assessment_hashes <- sensitivity_strata[["strata_hash"]]

################################################################################
                ## Specify glmnet control options (SA2 Only) ##
glmnet_type_measures <- c("deviance")
glmnet_alphas <- c("0", "0.9", "1")

################################################################################
                     ## Specify variable sets (SA2 Only) ##
variable_sets <- list()

# variable_sets[["set001"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "proulx_renal_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set001_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "proulx_renal_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set002"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "proulx_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set002_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "proulx_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set003"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set003_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set004"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set004_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set005"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "proulx_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set005_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "proulx_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set006"]] <-
#   c("dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "proulx_renal_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set006_no_factors"]] <-
#   c("dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "proulx_renal_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set007"]] <-
#   c("dic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_hepatic_24_hour_f"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set007_no_factors"]] <-
#   c("dic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_hepatic_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_b_count_24_hour"
#     )

# variable_sets[["set008"]] <-
#   c("dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour_f"
#     , "vis_24_hour"
#     )

# variable_sets[["set008_no_factors"]] <-
#   c(  "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_24_hour"
#     )

# variable_sets[["set009"]] <-
#   c("dic_24_hour_f"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "pelod2_respiratory_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour_f"
#     , "psofa_respiratory_24_hour_f"
#     , "vis_b_count_24_hour_f"
#     )

# variable_sets[["set009_no_factors"]] <-
#   c("dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "pelod2_respiratory_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_b_count_24_hour"
#     )

### set010 was presented as HR on 6/13
# variable_sets[["set010"]] <-
#   c( "dic_24_hour_f"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour_f"
#     , "psofa_respiratory_24_hour_f"
#     , "vis_24_hour"
#     )
#
# variable_sets[["set010_no_factors"]] <-
#   c( "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_24_hour"
#     )

### set011 - final low resource, pre-LASSO
# variable_sets[["set011"]] <-
#  c( "ipscc_hepatic_24_hour"
#    , "pelod2_cardiovascular_24_hour_f"
#    , "pelod2_neurological_24_hour_f"
#    , "podium_endocrine_wo_thyroxine_24_hour"
#    , "psofa_coagulation_24_hour_f"
#    , "psofa_renal_24_hour_f"
#    , "psofa_respiratory_24_hour_f"
#    , "vis_b_count_24_hour_f"
#    )

#variable_sets[["set011-2"]] <-
#  c( "ipscc_hepatic_24_hour"
#    , "pelod2_cardiovascular_24_hour_f"
#    , "pelod2_neurological_24_hour_f"
#    , "podium_endocrine_wo_thyroxine_24_hour"
#    , "psofa_coagulation_24_hour_f"
#    , "psofa_renal_24_hour_f"
#    , "psofa_respiratory_24_hour_f"
#    , "vis_b_count_24_hour"
#    )

#variable_sets[["set011_no_factors"]] <-
#  c( "ipscc_hepatic_24_hour"
#    , "pelod2_cardiovascular_24_hour"
#    , "pelod2_neurological_24_hour"
#    , "podium_endocrine_wo_thyroxine_24_hour"
#    , "psofa_coagulation_24_hour"
#    , "psofa_renal_24_hour"
#    , "psofa_respiratory_24_hour"
#    , "vis_b_count_24_hour"
#    )

### the other LR option presented 6/20
# variable_sets[["set012"]] <-
#   c( "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_coagulation_24_hour_f"
#     , "psofa_renal_24_hour_f"
#     , "psofa_respiratory_24_hour_f"
#     )
#
# variable_sets[["set012_no_factors"]] <-
#   c( "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_coagulation_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     )

### set014 = Low Resource set if VIS wins out, without endocrine
# variable_sets[["set014"]] <-
#   c( "pelod2_cardiovascular_24_hour_f"
# , "vis_b_count_24_hour_f"
# , "psofa_respiratory_24_hour_f"
# , "pelod2_neurological_24_hour_f"
# , "psofa_renal_24_hour_f"
# , "psofa_coagulation_24_hour_f"
# , "ipscc_hepatic_24_hour"
# )

# variable_sets[["set014_no_factors "]] <- ### all continuous or binary
#   c( "pelod2_cardiovascular_24_hour"
# , "vis_b_count_24_hour"
# , "psofa_respiratory_24_hour"
# , "pelod2_neurological_24_hour"
# , "psofa_renal_24_hour"
# , "psofa_coagulation_24_hour"
# , "ipscc_hepatic_24_hour"
# )

### set015 =  current High Resource set. all factors unless performance very different cont/categ
variable_sets[["set015"]] <-
  c( "dic_24_hour_f"
    , "ipscc_hepatic_24_hour"
    , "pelod2_cardiovascular_24_hour_f"
    , "pelod2_neurological_24_hour_f"
    , "podium_endocrine_wo_thyroxine_24_hour"
    , "podium_immunologic_24_hour"
    , "psofa_respiratory_24_hour_f"
    , "psofa_renal_24_hour_f"
    , "vis_b_count_24_hour_f"
    )

variable_sets[["set015_no_factors "]] <- ### all continuous or binary
  c( "dic_24_hour"
    , "ipscc_hepatic_24_hour"
    , "pelod2_cardiovascular_24_hour"
    , "pelod2_neurological_24_hour"
    , "podium_endocrine_wo_thyroxine_24_hour"
    , "podium_immunologic_24_hour"
    , "psofa_respiratory_24_hour"
    , "psofa_renal_24_hour"
    , "vis_b_count_24_hour"
    )

### set016 = only difference from set 15 is the parameterization of the VIS
# variable_sets[["set016 "]] <-
#   c( "dic_24_hour_f"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_renal_24_hour_f"
#     , "psofa_respiratory_24_hour_f"
#     , "vis_24_hour"
#     )
#
# variable_sets[["set016_no_factors"]] <-
#   c( "dic_24_hour_f"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "podium_immunologic_24_hour"
#     , "psofa_renal_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "vis_24_hour"
#     )

### set017 =  only difference from set 15 is this one lacks immunologic
# variable_sets[["set017"]] <-
#   c( "dic_24_hour_f"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour_f"
#     , "pelod2_neurological_24_hour_f"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_respiratory_24_hour_f"
#     , "psofa_renal_24_hour_f"
#     , "vis_b_count_24_hour_f"
#     )
#
# variable_sets[["set017_no_factors "]] <- ### all continuous or binary
#   c( "dic_24_hour"
#     , "ipscc_hepatic_24_hour"
#     , "pelod2_cardiovascular_24_hour"
#     , "pelod2_neurological_24_hour"
#     , "podium_endocrine_wo_thyroxine_24_hour"
#     , "psofa_respiratory_24_hour"
#     , "psofa_renal_24_hour"
#     , "vis_b_count_24_hour"
#     )

### set018 = currently redundant
# variable_sets[["set018"]] <-
#   c( "pelod2_cardiovascular_24_hour_f"
# , "vis_b_count_24_hour"
# , "podium_endocrine_wo_thyroxine_24_hour"
# , "dic_24_hour_f"
# , "ipscc_hepatic_24_hour"
# , "pelod2_neurological_24_hour_f"
# , "psofa_renal_24_hour_f"
# , "psofa_respiratory_24_hour_f"
# , "podium_immunologic_24_hour"
# )

# variable_sets[["set018_no_factors"]] <-
#   c( "pelod2_cardiovascular_24_hour"
# , "vis_b_count_24_hour"
# , "podium_endocrine_wo_thyroxine_24_hour"
# , "dic_24_hour"
# , "ipscc_hepatic_24_hour"
# , "pelod2_neurological_24_hour"
# , "psofa_renal_24_hour"
# , "psofa_respiratory_24_hour"
# , "podium_immunologic_24_hour"
# )

### set019 is the first of the 03 hour sets
variable_sets[["set019a"]] <-
  c( "pews_cardiovascular_03_hour_f"
    , "qpelod2_hypotension_03_hour"
    , "pews_respiratory_03_hour_f"
    , "psofa_neurological_03_hour_f"
    )

variable_sets[["set019_no_factors"]] <-
  c( "pews_cardiovascular_03_hour"
    , "qpelod2_hypotension_03_hour"
    , "pews_respiratory_03_hour"
    , "psofa_neurological_03_hour"
    )

variable_sets[["set019b"]] <- ### for Low Resource, no oxygen or spo2
  c( "pews_cardiovascular_03_hour_f"
    , "qpelod2_hypotension_03_hour"
    , "msirs_respiratory_03_hour"  # binary variable
    , "psofa_neurological_03_hour_f"
    )

variable_sets[["set020a"]] <-
  c( "pews_cardiovascular_03_hour_f"
    , "pews_respiratory_03_hour_f"
    , "lqsofa_neurological_03_hour"
    )

variable_sets[["set020_no_factors"]] <-
  c( "pews_cardiovascular_03_hour"
    , "pews_respiratory_03_hour"
    , "lqsofa_neurological_03_hour"
    )

variable_sets[["set020b"]] <- ### candidate for low resource
  c( "pews_cardiovascular_03_hour_f"
    , "msirs_respiratory_03_hour"  # binary
    , "psofa_neurological_03_hour_f"
    )

variable_sets[["set020c"]] <- ### candidate for low resource
  c( "qpelod2_hypotension_03_hour" # binary
    , "msirs_respiratory_03_hour" # binary
    , "psofa_neurological_03_hour_f"
    )

variable_sets[["set021"]] <-
  c( "pews_cardiovascular_03_hour"
    , "qpelod2_hypotension_03_hour"
    , "pews_respiratory_03_hour_f"
    , "psofa_neurological_03_hour_f"
    , "podium_endocrine_wo_thyroxine_03_hour"
    )

variable_sets[["set021_no_factors"]] <-
  c( "pews_cardiovascular_03_hour"
    , "qpelod2_hypotension_03_hour"
    , "pews_respiratory_03_hour"
    , "psofa_neurological_03_hour"
    , "podium_endocrine_wo_thyroxine_03_hour"
    )

################################################################################
                ## Checks to make sure inputs are reasonable ##

# all outcomes should be known
stopifnot(outcomes %in% define_outcome())

# all training_hashes should be known
stopifnot(training_hashes %in% training_strata$strata_hash)

# all assessment_hashes should be known
stopifnot(assessment_hashes %in% sensitivity_strata$strata_hash)

# all glmnet controls are as expected
stopifnot(glmnet_type_measures %in% c('deviance', 'class', 'auc', 'mae'))
stopifnot(is.character(glmnet_alphas))
stopifnot(as.numeric(glmnet_alphas) >= 0.0)
stopifnot(as.numeric(glmnet_alphas) <= 1.0)

# variable sets should be named and unique
stopifnot(!any("" %in% names(variable_sets)))
variable_sets <- variable_sets |> lapply(unique) |> lapply(sort)

dup_check <- duplicated(variable_sets)
if (any(dup_check)) {
  for(i in rev(which(dup_check))) {
    nms <- setdiff(
            names(which(sapply(variable_sets, identical, y = variable_sets[[i]])))
            ,
            names(variable_sets)[i]
    )
    msg <- paste(names(variable_sets)[i], "is a duplicate of", paste(nms, collapse = ", "))
    message(msg)
  }
}
stopifnot(!duplicated(variable_sets))

# Verify that all the variables are in the predictors set
variable_sets |>
  lapply(function(x) {x %in% predictors[["x"]]}) |>
  sapply(all) |>
  # print() |>
  stopifnot()

variable_sets_collapsed <- sapply(variable_sets, function(x) paste(sort(x), collapse = " "))
xs <- sort(unique(do.call(c, variable_sets)))

################################################################################
                  ## Build files with the needed SA1 calls ##

### SA1 Model Calls
sa1_model_calls <-
  data.table::CJ(
                   trained_on = training_hashes
                 , outcome = outcomes
                 , x = predictors$x
                 )

sa1_model_calls <-
  sa1_model_calls[,
      .(cl = "Rscript --vanilla --quiet sa1.R", x, outcome, trained_on, bootstraps = "100;", cl2 = "Rscript --vanilla --quiet sa1_model_assessments.R", x, outcome, trained_on, trained_on)
  ]

sa1_model_calls1 <-
  sa1_model_calls[(grepl("03_hour", x) | grepl("24_hour", x)) & (grepl("72", outcome) | outcome == "death")]

sa1_model_calls2 <-
  sa1_model_calls[(grepl("03_hour", x) | grepl("24_hour", x))]

sa1_model_calls3 <- sa1_model_calls

data.table::fwrite(sa1_model_calls1, file = "high_value_sa1_model_calls1.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_model_calls2, file = "high_value_sa1_model_calls2.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_model_calls3, file = "high_value_sa1_model_calls3.txt", col.names = FALSE, sep = " ", quote = FALSE)

### SA1 Assessment Calls
sa1_assessment_calls <-
  data.table::CJ(
                   trained_on = training_hashes
                 , outcome = outcomes
                 , x = predictors$x
                 , assessed_with = assessment_hashes
                 )

sa1_assessment_calls <-
  sa1_assessment_calls[, .(cl = "Rscript --vanilla --quiet sa1_model_assessments.R", x, outcome, trained_on, assessed_with)]

# split up the assessment calls to get the ones assessed by the training sets
# computed first
sa1_assessment_calls1 <-
  sa1_assessment_calls[(trained_on == assessed_with) & (grepl("03_hour", x) | grepl("24_hour", x)) & (grepl("72", outcome) | outcome == "death")]

sa1_assessment_calls2 <-
  sa1_assessment_calls[(trained_on == assessed_with) & (grepl("03", x) | grepl("24", x))]

sa1_assessment_calls3 <-
  rbind(
    sa1_assessment_calls[(trained_on == assessed_with)]
    ,
    sa1_assessment_calls[(trained_on != assessed_with)]
    )

data.table::fwrite(sa1_assessment_calls1, file = "high_value_sa1_assessment_calls1.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_assessment_calls2, file = "high_value_sa1_assessment_calls2.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_assessment_calls3, file = "high_value_sa1_assessment_calls3.txt", col.names = FALSE, sep = " ", quote = FALSE)

### SA1 Organ System Summary Calls
sa1_organ_system_summary_calls <-
  data.table::CJ(
                   trained_on = training_hashes
                 , organ_system = unique(predictors$organ_system)
                 , tfhp = c("1hour", "3hours", "24hours", "ever")
                 , assessed_with = assessment_hashes
                 , outcome = outcomes
                 )


sa1_organ_system_summary_calls <-
  sa1_organ_system_summary_calls[, .(cl = "Rscript --vanilla --quiet sa1_organ_system_summaries.R", organ_system, tfhp, outcome, trained_on, assessed_with)]

sa1_organ_system_summary_calls1 <-
  sa1_organ_system_summary_calls[(trained_on == assessed_with) & (grepl("3hours", tfhp) | grepl("24hours", tfhp)) & (grepl("72", outcome) | outcome == "death")]

sa1_organ_system_summary_calls2 <-
  sa1_organ_system_summary_calls[(trained_on == assessed_with) & (grepl("24hours", tfhp) | grepl("3hours", tfhp))]

sa1_organ_system_summary_calls3 <-
  rbind(
        sa1_organ_system_summary_calls[trained_on == assessed_with]
        ,
        sa1_organ_system_summary_calls[trained_on != assessed_with]
        )

data.table::fwrite(sa1_organ_system_summary_calls1, file = "high_value_sa1_organ_system_summary_calls1.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_organ_system_summary_calls2, file = "high_value_sa1_organ_system_summary_calls2.txt", col.names = FALSE, sep = " ", quote = FALSE)
data.table::fwrite(sa1_organ_system_summary_calls3, file = "high_value_sa1_organ_system_summary_calls3.txt", col.names = FALSE, sep = " ", quote = FALSE)

################################################################################
                  ## Build files with the needed SA2 calls ##

### SA2 g level calls
gcalls <- data.table::CJ(x = xs, outcome = outcomes, trained_on = training_hashes)
gcalls <- gcalls[, .(paste("Rscript --vanilla --quiet sa2g.R", x, outcome, trained_on))]
cat(gcalls$V1, sep = "\n", file = "high_value_sa2g.txt")

### SA2 h level calls
hcalls <- data.table::CJ(
            outcome = outcomes
            , trained_on = training_hashes
            , glmnet_type_measure = glmnet_type_measures
            , glmnet_alpha = glmnet_alphas
            , xs = variable_sets_collapsed
            )

h_model_hashes <-
  apply(hcalls, 1, function(x) {
          y <- list(
                      outcome = unname(x["outcome"])
                    , trained_on = unname(x["trained_on"])
                    , type.measure = unname(x["glmnet_type_measure"])
                    , alpha = unname(x["glmnet_alpha"])
                    , xs = strsplit(unname(x["xs"]), " ")[[1]]
                    )
          define_h_model_hash(y)
  })

### SA2 t level calls
tcalls <- data.table::CJ(
              h_model_hash = h_model_hashes
            , assessment_strata_hash = assessment_hashes
            , assessment_data = c("SA2h", "SA2t", "**REDACTED**", "**REDACTED**", "**REDACTED**")
            )


# set the order for these calls to cases were the trained_on and assessed_with
# hashes are the same first
tcalls <-
  merge(
          x = tcalls
        , y = data.table(trained_on = hcalls$trained_on, h_model_hash = h_model_hashes, outcome = hcalls$outcome),
        , all.x = TRUE
        , by = "h_model_hash"
        )

# write out the hcalls and tcalls
hcalls1 <- hcalls[(outcome == "death" | grepl("72", outcome)), .(paste("Rscript --vanilla --quiet sa2h.R", outcome, trained_on, glmnet_type_measure, glmnet_alpha, xs))]
hcalls2 <- hcalls[, .(paste("Rscript --vanilla --quiet sa2h.R", outcome, trained_on, glmnet_type_measure, glmnet_alpha, xs))]
cat(hcalls1$V1, sep = "\n", file = "high_value_sa2h1.txt")
cat(hcalls2$V1, sep = "\n", file = "high_value_sa2h2.txt")

tcalls1 <- tcalls[(outcome == "death" | grepl("72", outcome)) & (trained_on == assessment_strata_hash), .(paste("Rscript --vanilla --quiet sa2t.R", h_model_hash, assessment_strata_hash, assessment_data))]
tcalls2 <- tcalls[, .(paste("Rscript --vanilla --quiet sa2t.R", h_model_hash, assessment_strata_hash, assessment_data))]
cat(tcalls1$V1, sep = "\n", file = "high_value_sa2t1.txt")
cat(tcalls2$V1, sep = "\n", file = "high_value_sa2t2.txt")

################################################################################
                         ## Save High Value Targets ##

list(
       outcomes = outcomes
     , training_hashes = training_hashes
     , assessment_hashes = assessment_hashes
     , variable_sets = variable_sets
     , glmnet_type_measures = glmnet_type_measures
     , glmnet_alphas = glmnet_alphas
     ) |>
  saveRDS(file = high_value_list_rds_path)

################################################################################
                               ## End of File ##
################################################################################
