################################################################################
##             Calculations and Summaries for the JAMA Manuscript             ##


################################################################################
##                           Namespaces and Options                           ##
library(data.table)
library(bigrquery)
project_id <- "**REDACTED**"
project_number <- "**REDACTED**"

options(qwraps2_markup = "markdown",
        gargle_oauth_email = TRUE)
ggplot2::theme_set(ggplot2::theme_bw())

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
}

# define a function to capture the markdown version of qwraps2_summary_table
# and output as a csv.
# @param x a qwraps2_summary_table object
# @param ... passed to data.table::fwrite
summary_table_2_csv <- function(x, ...) {
  UseMethod("summary_table_2_csv")
}
summary_table_2_csv.qwraps2_summary_table <- function(x, ...) {
  xdt <- capture.output(x)
  xdt <- data.table::fread(text = xdt)
  xdt <- xdt[, lapply(.SD, gsub, pattern = "&nbsp;", replacement = "")]
  xdt <- xdt[, lapply(.SD, gsub, pattern = "&plusmn;", replacement = "+/-")]
  data.table::fwrite(x = xdt, ...)
}

################################################################################
##                                   Tables                                   ##

cohort_summary <- list(
  "Encounters and Patients" =
    list(
    "Encounters" = ~ qwraps2::frmt(length(unique(enc_id)))
 #   , "Patients*"  = ~ qwraps2::frmt(length(unique(pat_id)))
    )
  ,
  "Resource setting" =
    list(
      "HIC" = ~ qwraps2::n_perc0(IC == "HIC", digits = 1)
      , "LMIC" = ~ qwraps2::n_perc0(IC == "LMIC", digits = 1)
    )
  ,
  
#  "Biennial Admissions" =
#    list(
#      "2010-2011" = ~qwraps2::n_perc0(biennial_admission == "2010-2011", digits = 0)
#    , "2012-2013" = ~qwraps2::n_perc0(biennial_admission == "2012-2013", digits = 0)
#    , "2014-2015" = ~qwraps2::n_perc0(biennial_admission == "2014-2015", digits = 0)
#    , "2016-2017" = ~qwraps2::n_perc0(biennial_admission == "2016-2017", digits = 0)
#    , "2018-2019" = ~qwraps2::n_perc0(biennial_admission == "2018-2019", digits = 0)
#    , "2010-2018" = ~qwraps2::n_perc0(biennial_admission == "2010-2018", digits = 0)
#    )
#  ,
  "Race" =
    list(
    "Asian" = ~qwraps2::n_perc0(race == "Asian", digits = 1)
    , "Black" = ~qwraps2::n_perc0(race == "Black or African American", digits = 1)
    , "Multiple" = ~qwraps2::n_perc0(race == "Multiple Races", digits = 1)
    , "Other/Unknown/Not Applicable" = ~qwraps2::n_perc0(race == "Unknown/Other", digits = 1)
    , "American Indian or Alaskan Native" = ~qwraps2::n_perc0(race == "American Indian or Alaksa Native", digits = 1)
    , "Native Hawaiian or Other Pacific Islander" = ~qwraps2::n_perc0(race == "Native Hawaiian or Other Pacific Islander", digits = 1)
    , "White" = ~qwraps2::n_perc0(race == "White", digits = 1)
    )
  ,
  "Ethnicity" =
    list(
      "Hispanic or Latino" = ~qwraps2::n_perc0(ethnicity == "Hispanic or Latino", digits = 1)
    )
  ,
  "Gender" =
    list(
      "Female" = ~ qwraps2::n_perc0(gender == "Female", digits = 1)
    , "Male"   = ~ qwraps2::n_perc0(gender == "Male",  digits = 1)
    )
  ,
  "Age" =
    list(
#      "Under 1 month" = ~qwraps2::n_perc0(na.omit(age_category) == "[0,1)", digits = 1)
#    , "1 month up to 12 months" = ~qwraps2::n_perc0(na.omit(age_category) == "[1,12)", digits = 1)
#    , "1 up to 2 years" = ~qwraps2::n_perc0(na.omit(age_category) == "[12,24)", digits = 1)
#    , "2 up to 5 years" = ~qwraps2::n_perc0(na.omit(age_category) == "[24,60)", digits = 1)
#    , "5 up to 12 year" = ~qwraps2::n_perc0(na.omit(age_category) == "[60,144)", digits = 1)
#    , "12 and over" = ~qwraps2::n_perc0(na.omit(age_category) == "[144,240)", digits = 1)
#    , "Unknown/Missing" = ~qwraps2::n_perc0(is.na(age_category))
#    , "Median (IQR) (months)" = ~ qwraps2::median_iqr(na.omit(admit_age_months))
     "Median (IQR) (years)" = ~ qwraps2::median_iqr(na.omit(admit_age_months/12))
   )
  ,
  "Ever ICU" =
    list(
     "ICU" = ~ qwraps2::n_perc0(na.omit(ever_icu) == 1, digits = 1)
    )
  ,
  "Ever ED" =
    list(
    "ED" = ~ qwraps2::n_perc0(na.omit(ever_ed) == 1, digits = 1)
    )
  ,
  "Ever OR" =
    list(
    "OR" = ~ qwraps2::n_perc0(na.omit(ever_operation) == 1, digits = 1)
    )
  ,
  "Major comorbidities" =
    list(
#      "Congeni Genetic" = ~ qwraps2::n_perc0(pccc_congeni_genetic)
#    , "CVD"             = ~ qwraps2::n_perc0(pccc_cvd)
#    , "GI"              = ~ qwraps2::n_perc0(pccc_gi)
#    , "Hemato Immu"     = ~ qwraps2::n_perc0(pccc_hemato_immu)
     "Malignancy"      = ~ qwraps2::n_perc0(pccc_malignancy, digits = 1)
#    , "Metabolic"       = ~ qwraps2::n_perc0(pccc_metabolic)
#    , "Neuromusc"       = ~ qwraps2::n_perc0(pccc_neuromusc)
#    , "Neonatal"        = ~ qwraps2::n_perc0(pccc_neonatal)
#    , "Renal"           = ~ qwraps2::n_perc0(pccc_renal)
#    , "Respiratory"     = ~ qwraps2::n_perc0(pccc_respiratory)
    , "Tech Dep"        = ~ qwraps2::n_perc0(pccc_tech_dep, digits = 1)
    , "Transplant"      = ~ qwraps2::n_perc0(pccc_transplant, digits = 1)
    , "Severe malnutrition" = ~ qwraps2::n_perc0(na.omit(severe_malnutrition == 1, digits = 1))
    )
  ,
  "PCCC Count" =
    list(
      "No Known Prior Comorbidity" = ~ qwraps2::n_perc0(pccc_count == 0, digits = 1)
    , "1 PCCC" = ~ qwraps2::n_perc0(pccc_count == 1, digits = 1)
    , "2 or more PCCC" = ~ qwraps2::n_perc0(pccc_count >= 2, digits = 1)
    )

,
 "SIRS first 24 hours" =
  list(
    "SIRS" = ~ qwraps2::n_perc0(ipscc_sirs_24_hour == 1, digits = 1)
  )
 ,

  "Outcomes" =
    list(
      "Death" = ~ qwraps2::n_perc0(death == 1, digits = 1)
      , "Early Death or ECMO" = ~ qwraps2::n_perc0(ecmo_or_early_death == 1, digits = 1)
    )
)

cohort_summary_whole_data_set <-
  cbind(
      qwraps2::summary_table(R01_DATA,                                                 summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset)],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & IC == "HIC"],          summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & IC == "LMIC"],         summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],    summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset)],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"], summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
  )
summary_table_2_csv(cohort_summary_whole_data_set, file = "cohort_summary_whole_data_set.csv")

cohort_summary_suspected_infection_1dose <-
  cbind(
      qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1],                                                  summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset)],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & IC == "HIC"],          summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & IC == "LMIC"],         summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],    summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & !grepl("SA", sa_subset)],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & !grepl("SA", sa_subset) & site == "**REDACTED**"], summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & !grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & !grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = cohort_summary)
  )
summary_table_2_csv(cohort_summary_suspected_infection_1dose, file = "cohort_summary_suspected_infection_1dose.csv")

#######
# Data paper tables

cohort_summary_table1 <-
  cbind(
      qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("SA1", "SA2g", "SA2h", "SA2t")], summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("SA1", "SA2g", "SA2h")], summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  sa_subset == "SA2t"], summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 &  sa_subset %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**")], summaries = cohort_summary)
     )
summary_table_2_csv(cohort_summary_table1, file = "cohort_summary_table1.csv")


cohort_summary_etable3 <-
  cbind(
    qwraps2::summary_table(R01_DATA[sa_subset %in% c("SA1", "SA2g", "SA2h", "SA2t")],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("SA1", "SA2g", "SA2h", "SA2t")],          summaries = cohort_summary)
  )
summary_table_2_csv(cohort_summary_etable3, file = "cohort_summary_etable3.csv")

cohort_summary_etable4 <-
  cbind(
    qwraps2::summary_table(R01_DATA[IC=="HIC" & sa_subset %in% c("SA1", "SA2g", "SA2h", "SA2t")], summaries = cohort_summary)
    ,qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & IC=="HIC" & sa_subset %in% c("SA1", "SA2g", "SA2h", "SA2t")],         summaries = cohort_summary)
    ,qwraps2::summary_table(R01_DATA[site=="**REDACTED**"], summaries = cohort_summary)
    ,qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & site=="**REDACTED**"],    summaries = cohort_summary) 
    ,qwraps2::summary_table(R01_DATA[site=="**REDACTED**"], summaries = cohort_summary)
    ,qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & site=="**REDACTED**"],    summaries = cohort_summary) 
  )
summary_table_2_csv(cohort_summary_etable4, file = "cohort_summary_etable4.csv")


cohort_summary_etable5 <-
  cbind(
    qwraps2::summary_table(R01_DATA[sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
    ,qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
    , qwraps2::summary_table(R01_DATA[suspected_infection_1dose_24_hour == 1 & sa_subset %in% c("**REDACTED**")],                        summaries = cohort_summary)
     )
summary_table_2_csv(cohort_summary_etable5, file = "cohort_summary_etable5.csv")

#########


outcome_summary <-
  list(
    "Death and ECMO" =
      list(
        "Encounters"  = ~ length(enc_id)
      , "Death"       = ~ qwraps2::n_perc0(death, digits = 1)
      , "Early Death" = ~ qwraps2::n_perc0(early_death, digits = 1)
      , "ECMO"        = ~ qwraps2::n_perc0(ecmo, digits = 1)
      , "Early ECMO"  = ~ qwraps2::n_perc0(early_ecmo, digits = 1)
      , "ECMO or Death"  = ~ qwraps2::n_perc0(ecmo_or_death, digits = 1)
      , "ECMO or Early Death" = ~ qwraps2::n_perc0(ecmo_or_early_death, digits = 1)
      , "Early ECMO or Death" = ~ qwraps2::n_perc0(early_ecmo_or_death, digits = 1)
      , "Early ECMO or Early Death" = ~ qwraps2::n_perc0(early_ecmo_or_early_death, digits = 1)
      #, "Sepsis (Phoenix) within 24 hours" = ~ qwraps2::n_perc0(integer_lasso_sepsis_geq2_24_hour, digits = 1)
      #, "Septic Shock within 24 hours" = ~ qwraps2::n_perc0(integer_lasso_sepsis_cv1_geq2_24_hour, digits = 1)
        )
    ,
    "Suspected Infection (1dose) within 24 hours" =
      list(
        "Encounters"                = ~ qwraps2::frmt(sum(suspected_infection_1dose_24_hour))
      , "Death"                     = ~ qwraps2::n_perc0(death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "Early Death"               = ~ qwraps2::n_perc0(early_death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "ECMO"                      = ~ qwraps2::n_perc0(ecmo[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "Early ECMO"                = ~ qwraps2::n_perc0(early_ecmo[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "ECMO or Death"             = ~ qwraps2::n_perc0(ecmo_or_death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "ECMO or Early Death"       = ~ qwraps2::n_perc0(ecmo_or_early_death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "Early ECMO or Death"       = ~ qwraps2::n_perc0(early_ecmo_or_death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "Early ECMO or Early Death" = ~ qwraps2::n_perc0(early_ecmo_or_early_death[suspected_infection_1dose_24_hour == 1], digits = 1)
      , "Sepsis (Phoenix)"          = ~ qwraps2::n_perc0(integer_lasso_sepsis_geq2_24_hour[suspected_infection_1dose_24_hour == 1L], digits = 1)
      , "Septic Shock"              = ~ qwraps2::n_perc0(integer_lasso_sepsis_cv1_geq2_24_hour[suspected_infection_1dose_24_hour == 1L], digits = 1)
      )
    ,
    "Sepsis (Phoenix)" =
      list(
        "Encounters"                = ~ qwraps2::frmt(sum(integer_lasso_sepsis_1dose_geq2_24_hour))
      , "Death"                     = ~ qwraps2::n_perc0(death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "Early Death"               = ~ qwraps2::n_perc0(early_death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "ECMO"                      = ~ qwraps2::n_perc0(ecmo[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "Early ECMO"                = ~ qwraps2::n_perc0(early_ecmo[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "ECMO or Death"             = ~ qwraps2::n_perc0(ecmo_or_death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "ECMO or Early Death"       = ~ qwraps2::n_perc0(ecmo_or_early_death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "Early ECMO or Death"       = ~ qwraps2::n_perc0(early_ecmo_or_death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "Early ECMO or Early Death" = ~ qwraps2::n_perc0(early_ecmo_or_early_death[integer_lasso_sepsis_1dose_geq2_24_hour == 1], digits = 1)
      , "Sepsis (Phoenix)"          = ~ qwraps2::n_perc0(integer_lasso_sepsis_geq2_24_hour[integer_lasso_sepsis_1dose_geq2_24_hour == 1L], digits = 1)
      , "Septic Shock"              = ~ qwraps2::n_perc0(integer_lasso_sepsis_cv1_geq2_24_hour[integer_lasso_sepsis_1dose_geq2_24_hour == 1L], digits = 1)
      )
    ,
    "Septic Shock (Phoenix)" =
      list(
        "Encounters"                = ~ qwraps2::frmt(sum(suspected_infection_1dose_24_hour == 1 & integer_lasso_sepsis_cv1_geq2_24_hour))
      , "Death"                     = ~ qwraps2::n_perc0(death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "Early Death"               = ~ qwraps2::n_perc0(early_death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "ECMO"                      = ~ qwraps2::n_perc0(ecmo[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "Early ECMO"                = ~ qwraps2::n_perc0(early_ecmo[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "ECMO or Death"             = ~ qwraps2::n_perc0(ecmo_or_death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "ECMO or Early Death"       = ~ qwraps2::n_perc0(ecmo_or_early_death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "Early ECMO or Death"       = ~ qwraps2::n_perc0(early_ecmo_or_death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "Early ECMO or Early Death" = ~ qwraps2::n_perc0(early_ecmo_or_early_death[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1], digits = 1)
      , "Sepsis (Phoenix)"          = ~ qwraps2::n_perc0(integer_lasso_sepsis_geq2_24_hour[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1L], digits = 1)
      , "Septic Shock"              = ~ qwraps2::n_perc0(integer_lasso_sepsis_cv1_geq2_24_hour[suspected_infection_1dose_24_hour == 1 &integer_lasso_sepsis_cv1_geq2_24_hour == 1L], digits = 1)
      )
    )

outcome_summary_table <-
  cbind(
      qwraps2::summary_table(R01_DATA,                                                 summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset)],                        summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & IC == "HIC"],          summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & IC == "LMIC"],         summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],       summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],    summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[ grepl("SA", sa_subset) & site == "**REDACTED**"],        summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset)],                        summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"], summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = outcome_summary)
    , qwraps2::summary_table(R01_DATA[!grepl("SA", sa_subset) & site == "**REDACTED**"],      summaries = outcome_summary)
  )
summary_table_2_csv(outcome_summary_table, file = "outcome_summary_table.csv")

################################################################################
##                                End of File                                 ##
################################################################################
