#!/bin/R

options(warn = 2) # turn warnings into errors
options(qwraps2_markup = "markdown")
stopifnot(packageVersion("base") >= "4.1.1")
library(data.table)
library(parallel)
source("utilities.R")
SA1 <- read_SA1_data()


#/* ------------------------------------------------------------------------- */
                               ## Build Strata ##

# The strata will be defined in several steps, not all combinations of sites,
# locations (ED, ICU, IP), infection status, and assessment times, are to be
# considered.

# The training_strata are strata of the data that need to be fit
# Additional strata are defined for sensitivity analyses

# define the categories here so that they can be used in both the
# training_strata and sensitivity_strata
resource_availability <-
  c(
      NA_character_ # default to all sites
    , "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**')))"  # omit **REDACTED** - holdout set
    , "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"           # omit **REDACTED** - holdout set
    , "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"  # omit **REDACTED** - holdout set
    , "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"           # omit **REDACTED** - holdout set
    , "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))" # HIC no  **REDACTED**
    # these are sites where we've curated proven_infection
    , "(site %in% c(PI = c('**REDACTED**', '**REDACTED**', '**REDACTED**')))"
    # these are sites with troponin and thyroxine labs
    , "(site %in% c(TT = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
    # sites with ED stay curated
    , "(site %in% c(ED = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))" # omit **REDACTED**
    # each individual site
    , paste0("(site == '", c("**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**"), "')")
    )

suspected_infection_status <-
  c(
      NA_character_
    , "(suspected_infection_0dose_01_hour == 1L)"
    , "(suspected_infection_0dose_03_hour == 1L)"
    , "(suspected_infection_0dose_24_hour == 1L)"
    , "(suspected_infection_0dose == 1L)"
    , "(suspected_infection_1dose_01_hour == 1L)"
    , "(suspected_infection_1dose_03_hour == 1L)"
    , "(suspected_infection_1dose_24_hour == 1L)"
    , "(suspected_infection_1dose == 1L)"
    , "(suspected_infection_2doses_01_hour == 1L)"
    , "(suspected_infection_2doses_03_hour == 1L)"
    , "(suspected_infection_2doses_24_hour == 1L)"
    , "(suspected_infection_2doses == 1L)"
    )

proven_infection_status <-
  c(
      NA_character_
    , "(proven_infection_01_hour == 1L)"
    , "(proven_infection_03_hour == 1L)"
    , "(proven_infection_24_hour == 1L)"
    , "(proven_infection == 1L)"
    )

# although have other windows available, MDs just want <= 24 hours for now
hmpv_infection_status <-
  c(
      NA_character_
    , "(hmpv_infection_01_hour == 1L)"
    , "(hmpv_infection_03_hour == 1L)"
    , "(hmpv_infection_24_hour == 1L)"
    , "(hmpv_infection == 1L)"
    )

rsv_infection_status <-
  c(
      NA_character_
    , "(rsv_infection_01_hour == 1L)"
    , "(rsv_infection_03_hour == 1L)"
    , "(rsv_infection_24_hour == 1L)"
    , "(rsv_infection == 1L)"
    )

ever_ed  <- c(NA_character_, "(ever_ed == 0L)",  "(ever_ed == 1L)")
ever_ip  <- c(NA_character_, "(ever_ip == 0L)",  "(ever_ip == 1L)")
ever_icu <- c(NA_character_, "(ever_icu == 0L)", "(ever_icu == 1L)")

comorb_cvd                   <- c(NA_character_, "(pccc_cvd == 0L)", "(pccc_cvd == 1L)")
comorb_malignancy_transplant <- c(NA_character_, "(pccc_malignancy == 1L)", "(pccc_transplant == 1L)", "(pccc_malignancy + pccc_transplant > 0L)", "(pccc_malignancy + pccc_transplant == 0L)")
comorb_tech_dep              <- c(NA_character_, "(pccc_tech_dep == 0L)", "(pccc_tech_dep == 1L)")
comorb_severe_malnutrition   <- c(NA_character_, "(severe_malnutrition == 0L)", "(severe_malnutrition == 1L)")
comorb_pccc_count            <- c(NA_character_, "(pccc_count == 0L)", "(pccc_count <= 1L)")

# length of stay less than 12 hours
los <- c(NA_character_, "(los < 12 * 60)")

sex <- c(NA_character_, "(male == 1L)", "(male == 0L)")

ages <- c(NA_character_, "(admit_age_months < 24)", paste0("(age_category == '", levels(SA1$age_category), "')"))

# Integer LASSO limits
integer_lasso_sepsis_geq2_24_hour <- c(NA_character_, "(integer_lasso_sepsis_geq2_24_hour == 1L)")


# verify these strings return at least one row of data
verify_at_least_one_row <- function(x) {
  checks <- sapply(na.omit(x), function(s) {SA1[eval(parse(text = s)), .N]})
  while (any(checks == 0)) {
    s <- names(checks)[checks == 0][1]
    message(paste("Omitting :", s))
    x <- x[x != s]
    checks <- sapply(na.omit(x), function(s) {SA1[eval(parse(text = s)), .N]})
  }
  x
}

resource_availability        <- verify_at_least_one_row(resource_availability)
suspected_infection_status   <- verify_at_least_one_row(suspected_infection_status)
proven_infection_status      <- verify_at_least_one_row(proven_infection_status)
hmpv_infection_status        <- verify_at_least_one_row(hmpv_infection_status)
rsv_infection_status         <- verify_at_least_one_row(rsv_infection_status)
ever_ed                      <- verify_at_least_one_row(ever_ed)
ever_ip                      <- verify_at_least_one_row(ever_ip)
ever_icu                     <- verify_at_least_one_row(ever_icu)
comorb_cvd                   <- verify_at_least_one_row(comorb_cvd)
comorb_malignancy_transplant <- verify_at_least_one_row(comorb_malignancy_transplant)
comorb_tech_dep              <- verify_at_least_one_row(comorb_tech_dep)
comorb_severe_malnutrition   <- verify_at_least_one_row(comorb_severe_malnutrition)
comorb_pccc_count            <- verify_at_least_one_row(comorb_pccc_count)
los                          <- verify_at_least_one_row(los)
sex                          <- verify_at_least_one_row(sex)
ages                         <- verify_at_least_one_row(ages)

#/* ------------------------------------------------------------------------- */
                   ## Define the possible Training Strata ##

# Use simple names here

training_strata <-
  list(
      "All" = data.table(resource_availability = NA_character_)
    , "HIC_0dose" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "HIC0d_ph" = data.table(  # previously healthy proxy
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        , comorb_pccc_count = "(pccc_count == 0L)"
        )
    , "HIC_1dose" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "HIC1d_ph" = data.table(  # previously healthy proxy
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        , comorb_pccc_count = "(pccc_count == 0L)"
        )
    , "HIC1d_no_mal_no_tech_pccc_leq1" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        , comorb_malignancy_transplant = "(pccc_malignancy + pccc_transplant == 0L)"
        , comorb_tech_dep = "(pccc_tech_dep == 0L)"
        , comorb_pccc_count = "(pccc_count <= 1L)"
        )
    , "HIC_ED" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , ever_ed = "(ever_ed == 1L)"
        )
    , "HIC_ED_0dose" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , ever_ed = "(ever_ed == 1L)"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "HIC_ED_0dose_no_**REDACTED**" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , ever_ed = "(ever_ed == 1L)"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "HIC_ED_1dose" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , ever_ed = "(ever_ed == 1L)"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "HIC_ED_1dose_no_**REDACTED**" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , ever_ed = "(ever_ed == 1L)"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "LMIC_0dose" = data.table(
          resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "LMIC_1dose" = data.table(
          resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "HIC_1dose_icu" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        , ever_icu = "(ever_icu == 1L)"
        )
    , "**REDACTED**_0dose" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "**REDACTED**_1dose" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "**REDACTED**_0dose" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_24_hour == 1L)"
        )
    , "**REDACTED**_1dose" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)"
        )
    , "**REDACTED**_0dose_early" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        )
    , "**REDACTED**_under_2yr" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , ages = "(admit_age_months < 24)"
        )
    , "HIC_0dose_early" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        )
    , "HIC_0dose_early_ed" = data.table(
          resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        , ever_ed = "(ever_ed == 1L)"
        )
    , "LMIC_0dose_early_ed" = data.table(
          resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        , ever_ed = "(ever_ed == 1L)"
        )
    , "LMIC_0dose_early" = data.table(
          resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        )
    , "**REDACTED**_0dose_early_ed" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        , ever_ed = "(ever_ed == 1L)"
        )
    , "**REDACTED**_0dose_early_ed" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        , ever_ed = "(ever_ed == 1L)"
        )
    , "**REDACTED**_0dose_early" = data.table(
          resource_availability = "(site == '**REDACTED**')"
        , suspected_infection_status = "(suspected_infection_0dose_03_hour == 1L)"
        )
       )

stopifnot(
  names(training_strata) == make.names(names(training_strata))
)

training_strata <- data.table::rbindlist(training_strata, use.names = TRUE, fill = TRUE, id = "strata_name")
setcolorder(training_strata, neworder = c("strata_name", "resource_availability", "suspected_infection_status", "ever_ed", "ever_icu"))

# check that the column names and values are as expected
cn <- names(training_strata)
cn <- cn[-which(cn == "strata_name")]
stopifnot( cn %in% ls() )
for (j in cn) {
  stopifnot(training_strata[[j]] %in% get(j))
}


#/* ------------------------------------------------------------------------- */
                  ## Define the possible Sensitivity Strata ##

sensitivity_strata <-
  list(
    "Suspected_infection_1dose" = data.table(suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "Suspected_infection_2doses" = data.table(suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "HIC" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))")
  , "HIC_with_**REDACTED**" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))")
  , "HIC_2doses" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                              , suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "HIC_with_**REDACTED**_1dose" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                              , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "HIC_with_**REDACTED**_2doses" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                              , suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "LMIC_with_**REDACTED**" = data.table(resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**')))")
  , "LMIC" = data.table(resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))")
  , "LMIC_with_**REDACTED**_1dose" = data.table(resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                                         , suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "LMIC_with_**REDACTED**_2doses" = data.table(resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                                         , suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "LMIC_2doses" = data.table(resource_availability = "(site %in% c(LMIC = c('**REDACTED**', '**REDACTED**')))"
                               , suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "HIC_2doses_icu" = data.table(resource_availability = "(site %in% c(HIC = c('**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**', '**REDACTED**')))"
                                  , suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)"
                                  , ever_icu = "(ever_icu == 1L)")
  , "**REDACTED**" = data.table(resource_availability = "(site == '**REDACTED**')")
  , "Ever_ED" = data.table(ever_ed = "(ever_ed == 1L)")
  , "PCCC_CVD" = data.table(comorb_cvd = "(pccc_cvd == 1L)")
  , "PCCC_CVD_1dose" = data.table(comorb_cvd = "(pccc_cvd == 1L)", suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "PCCC_CVD_2doses" = data.table(comorb_cvd = "(pccc_cvd == 1L)", suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "Malignacy_or_Transplant" = data.table(comorb_malignancy_transplant = "(pccc_malignancy + pccc_transplant > 0L)")
  , "Malignacy_or_Transplant_1dose" = data.table(comorb_malignancy_transplant = "(pccc_malignancy + pccc_transplant > 0L)", suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "Malignacy_or_Transplant_2doses" = data.table(comorb_malignancy_transplant = "(pccc_malignancy + pccc_transplant > 0L)", suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "Severe_Malnutrition" = data.table(comorb_severe_malnutrition = "(severe_malnutrition == 1L)")
  , "Severe_Malnutrition_1dose" = data.table(comorb_severe_malnutrition = "(severe_malnutrition == 1L)", suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "Severe_Malnutrition_2doses" = data.table(comorb_severe_malnutrition = "(severe_malnutrition == 1L)", suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  , "Tech_Dep" = data.table(comorb_tech_dep = "(pccc_tech_dep == 1L)")
  , "Tech_Dep_1dose" = data.table(comorb_tech_dep = "(pccc_tech_dep == 1L)", suspected_infection_status = "(suspected_infection_1dose_24_hour == 1L)")
  , "Tech_Dep_2doses" = data.table(comorb_tech_dep = "(pccc_tech_dep == 1L)", suspected_infection_status = "(suspected_infection_2doses_24_hour == 1L)")
  )

stopifnot(
  names(sensitivity_strata) == make.names(names(sensitivity_strata))
)

sensitivity_strata <- data.table::rbindlist(sensitivity_strata, use.names = TRUE, fill = TRUE, id = "strata_name")

# check that the column names and values are as expected
cn <- names(sensitivity_strata)
cn <- cn[-which(cn == "strata_name")]
stopifnot( cn %in% ls() )
for (j in cn) {
  stopifnot(sensitivity_strata[[j]] %in% get(j))
  sensitivity_strata[[j]] %in% get(j)
}

#/* ------------------------------------------------------------------------- */
                          ## Set strata description ##


#/* ------------------------------------------------------------------------- */
                             ## set column order ##

sensitivity_strata <- rbind(training_strata, sensitivity_strata, use.names = TRUE, fill = TRUE)
data.table::setcolorder(sensitivity_strata, neworder = sort(names(sensitivity_strata)))
data.table::setcolorder(sensitivity_strata, neworder = names(training_strata))

#/* ------------------------------------------------------------------------- */
                         ## build sub setting logic ##

foo <- function(x) { paste(x[!is.na(x)], collapse = " & ")}

data.table::set(training_strata, j = "strata", value = apply(training_strata[, -"strata_name"], 1, foo))
data.table::set(sensitivity_strata, j = "strata", value = apply(sensitivity_strata[, -"strata_name"], 1, foo))

training_strata[strata == "", strata := "TRUE"]
sensitivity_strata[strata == "", strata := "TRUE"]

# verify all the strata are distinct
stopifnot(!duplicated(training_strata[["strata_hash"]]))
stopifnot(!duplicated(sensitivity_strata[["strata_hash"]]))

#/* ------------------------------------------------------------------------- */
                             ## hash the strata ##

# instead of a sequential strata number use a hash so that if more strata are
# generated or are removed, then the hash will still be valid.

data.table::set(
    training_strata
  , j = "strata_hash"
  , value = apply(training_strata, 1, function(x) digest::digest(x[["strata"]], algo = "md5"))
  )

data.table::set(
    sensitivity_strata
  , j = "strata_hash"
  , value = apply(sensitivity_strata, 1, function(x) digest::digest(x[["strata"]], algo = "md5"))
  )

#/* ------------------------------------------------------------------------- */
                     ## how many strata conditions? ##

# order by the number of conditions from fewest to most.  the fewer conditions,
# the more likely the strata will be of interest.

data.table::set(training_strata, j ="conditions", value = rowSums(!is.na(training_strata)) - 2)
data.table::set(sensitivity_strata, j ="conditions", value = rowSums(!is.na(sensitivity_strata)) - 2)

data.table::setorder(training_strata, conditions)
data.table::setorder(sensitivity_strata, conditions)

#/* ------------------------------------------------------------------------- */
                               ## Export Data ##

if (!interactive()) {
  feather::write_feather(x = training_strata, path = training_strata_feather_path)
  feather::write_feather(x = sensitivity_strata, path = sensitivity_strata_feather_path)
}

#/* ------------------------------------------------------------------------- */
#/*                               END OF FILE                                 */
#/* ------------------------------------------------------------------------- */
