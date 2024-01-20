################################################################################
utilities <- new.env()
source("../specific_aims/utilities.R", local = utilities)
sensitivity_strata <- utilities$read_sensitivity_strata() # this includes all the training strata.

################################################################################
                               ## DATA IMPORT ##
R01_DATA <- rbind(                                   # DO NOT CHANGE SUBSET BELOW
                    utilities$read_SA1_data()        # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_SA2g_data()       # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_SA2h_data()       # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_SA2t_data()       # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_**REDACTED**_data() # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_**REDACTED**_data()      # DO NOT CHANGE SUBSET BELOW
                  , utilities$read_**REDACTED**_data()      # DO NOT CHANGE SUBSET BELOW
                )                                    # DO NOT CHANGE SUBSET BELOW

################################################################################
                              ## Rename Columns ##

# Here, we rename columns built in the timecourse pipeline, and used within the
# specific aims 1 assessments, to the short hand names coined by **REDACTED** and/or
# **REDACTED**.

# FYI: the arguments `old` and `new` can be vectorized.  I have written them out
# individually for clarity.

# LASSO X Points
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq1_24_hour", new = "La1pt")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq2_24_hour", new = "Phoenix_Sepsis") # Used to be La2pt
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq3_24_hour", new = "La3pt")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq4_24_hour", new = "La4pt")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq5_24_hour", new = "La5pt")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq6_24_hour", new = "La6pt")

# LASSO X Points, Early (first three hours)
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq1_03_hour", new = "La1pt03hr")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq2_03_hour", new = "La2pt03hr")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq3_03_hour", new = "La3pt03hr")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq4_03_hour", new = "La4pt03hr")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq5_03_hour", new = "La5pt03hr")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_geq6_03_hour", new = "La6pt03hr")

# LASSO X Points, respiratory only
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq1_24_hour", new = "La1resp")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq2_24_hour", new = "La2resp")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq3_24_hour", new = "La3resp")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq4_24_hour", new = "La4resp")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq5_24_hour", new = "La5resp")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_respiratory_only_geq6_24_hour", new = "La6resp")

# LASSO X Points, neurologic only
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq1_24_hour", new = "La1neuro")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq2_24_hour", new = "La2neuro")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq3_24_hour", new = "La3neuro")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq4_24_hour", new = "La4neuro")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq5_24_hour", new = "La5neuro")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_neurologic_only_geq6_24_hour", new = "La6neuro")

# LASSO X Points, CV score at least 1
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq1_24_hour", new = "La1cv1")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq2_24_hour", new = "Phoenix_Septic_Shock")  # Used to be La2cv1
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq3_24_hour", new = "La3cv1")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq4_24_hour", new = "La4cv1")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq5_24_hour", new = "La5cv1")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv1_geq6_24_hour", new = "La6cv1")

# LASSO X Points, CV score at least 2
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq1_24_hour", new = "La1cv2") # this is redundant with La2cv2
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq2_24_hour", new = "La2cv2")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq3_24_hour", new = "La3cv2")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq4_24_hour", new = "La4cv2")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq5_24_hour", new = "La5cv2")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv2_geq6_24_hour", new = "La6cv2")

# LASSO X Points, CV score at least 3
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq1_24_hour", new = "La1cv3")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq2_24_hour", new = "La2cv3")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq3_24_hour", new = "La3cv3")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq4_24_hour", new = "La4cv3")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq5_24_hour", new = "La5cv3")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv3_geq6_24_hour", new = "La6cv3")

# LASSO X Points, CV score at least 4
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq1_24_hour", new = "La1cv4")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq2_24_hour", new = "La2cv4")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq3_24_hour", new = "La3cv4")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq4_24_hour", new = "La4cv4")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq5_24_hour", new = "La5cv4")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv4_geq6_24_hour", new = "La6cv4")

# LASSO X Points, CV score at least 5
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq1_24_hour", new = "La1cv5")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq2_24_hour", new = "La2cv5")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq3_24_hour", new = "La3cv5")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq4_24_hour", new = "La4cv5")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq5_24_hour", new = "La5cv5")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv5_geq6_24_hour", new = "La6cv5")

# LASSO X Points, CV score at least 6
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq1_24_hour", new = "La1cv6")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq2_24_hour", new = "La2cv6")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq3_24_hour", new = "La3cv6")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq4_24_hour", new = "La4cv6")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq5_24_hour", new = "La5cv6")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_cv6_geq6_24_hour", new = "La6cv6")

# LASSO X Remote
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq1_24_hour", new = "La1rem")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq2_24_hour", new = "sepsis_remote") # Used to be La2rem
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq3_24_hour", new = "La3rem")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq4_24_hour", new = "La4rem")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq5_24_hour", new = "La5rem")
data.table::setnames(R01_DATA, old = "integer_lasso_sepsis_remote_geq6_24_hour", new = "La6rem")

# Possible Sepsis has been defined in the timecourse
# grep("^possible", names(R01_DATA), value = TRUE)
data.table::setnames(R01_DATA, old = "possible_sepsis_geq1_03_hour", new = "PossSep1pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_geq2_03_hour", new = "PossSep2pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_geq3_03_hour", new = "PossSep3pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_geq4_03_hour", new = "PossSep4pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_geq5_03_hour", new = "PossSep5pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_geq6_03_hour", new = "PossSep6pt")

data.table::setnames(R01_DATA, old = "possible_sepsis_resp_geq1_03_hour", new = "PossSepResp1pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_resp_geq2_03_hour", new = "PossSepResp2pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_resp_geq3_03_hour", new = "PossSepResp3pt")

data.table::setnames(R01_DATA, old = "possible_sepsis_neuro_geq1_03_hour", new = "PossSepNeuro1pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_neuro_geq2_03_hour", new = "PossSepNeuro2pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_neuro_geq3_03_hour", new = "PossSepNeuro3pt")

data.table::setnames(R01_DATA, old = "possible_sepsis_cv_geq1_03_hour", new = "PossSepCV1pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_cv_geq2_03_hour", new = "PossSepCV2pt")
data.table::setnames(R01_DATA, old = "possible_sepsis_cv_geq3_03_hour", new = "PossSepCV3pt")

data.table::setnames(R01_DATA, old = "possible_sepsis_total_03_hour", new = "possible_sepsis_score")

# Other
data.table::setnames(R01_DATA, old = "ipscc_sirs_24_hour", new = "IPSCC_SIRS_Sepsis")
data.table::setnames(R01_DATA, old = "ipscc_severe_sepsis_06_1dose_24_hour", new = "IPSCC_Severe_Sepsis")
data.table::setnames(R01_DATA, old = "ipscc_septic_shock_06_1dose_24_hour", new = "IPSCC_Septic_Shock")

################################################################################
                              ## ad hoc columns ##

##### Possible Sepsis Score V1
R01_DATA[, PossSep2ptor1La := as.integer(PossSep2pt + La1pt03hr > 0)]

R01_DATA[, lqSOFA1pt := as.integer(lqsofa_total_03_hour >= 1) ]
R01_DATA[, lqSOFA2pt := as.integer(lqsofa_total_03_hour >= 2) ]
R01_DATA[, lqSOFA3pt := as.integer(lqsofa_total_03_hour >= 3) ]

R01_DATA[, qSOFA1pt := as.integer(qsofa_total_03_hour >= 1) ]
R01_DATA[, qSOFA2pt := as.integer(qsofa_total_03_hour >= 2) ]
R01_DATA[, qSOFA3pt := as.integer(qsofa_total_03_hour >= 3) ]

R01_DATA[, pews1pt := as.integer(pews_total_03_hour >= 1) ]
R01_DATA[, pews2pt := as.integer(pews_total_03_hour >= 2) ]
R01_DATA[, pews3pt := as.integer(pews_total_03_hour >= 3) ]

R01_DATA[, la1pt_03_hour := as.integer(integer_lasso_sepsis_total_03_hour >= 1) ]
R01_DATA[, la2pt_03_hour := as.integer(integer_lasso_sepsis_total_03_hour >= 2) ]

################################################################################
                              ## Define Remote ##

# build indicators to flag when integer_lasso_sepsis_total_24_hour > 0 is due only
# to (a) respiratory, (b) neuro.  Do this ingeneral, and then you can use these
# indicators to build other indicators such as sepsis_remote

R01_DATA[, la_resp_only_03_hour := FALSE]
R01_DATA[, la_resp_only_24_hour := FALSE]
R01_DATA[, la_neuro_only_03_hour := FALSE]
R01_DATA[, la_neuro_only_24_hour := FALSE]

R01_DATA[integer_lasso_sepsis_total_03_hour > 0
         , la_resp_only_03_hour := (
              integer_lasso_sepsis_total_03_hour == integer_lasso_sepsis_respiratory_03_hour
            & integer_lasso_sepsis_cardiovascular_03_hour == 0
            & integer_lasso_sepsis_coagulation_03_hour == 0
            & integer_lasso_sepsis_neurologic_03_hour    == 0
            )
         ]

R01_DATA[integer_lasso_sepsis_total_24_hour > 0
         , la_resp_only_24_hour := (
              integer_lasso_sepsis_total_24_hour == integer_lasso_sepsis_respiratory_24_hour
            & integer_lasso_sepsis_cardiovascular_24_hour == 0
            & integer_lasso_sepsis_coagulation_24_hour == 0
            & integer_lasso_sepsis_neurologic_24_hour == 0
            )
         ]

R01_DATA[integer_lasso_sepsis_total_03_hour > 0
         , la_neuro_only_03_hour := (
              integer_lasso_sepsis_total_03_hour == integer_lasso_sepsis_neurologic_03_hour
            & integer_lasso_sepsis_cardiovascular_03_hour == 0
            & integer_lasso_sepsis_coagulation_03_hour == 0
            & integer_lasso_sepsis_respiratory_03_hour == 0
            )
         ]

R01_DATA[integer_lasso_sepsis_total_24_hour > 0
         , la_neuro_only_24_hour := (
              integer_lasso_sepsis_total_24_hour == integer_lasso_sepsis_neurologic_24_hour
            & integer_lasso_sepsis_cardiovascular_24_hour == 0
            & integer_lasso_sepsis_coagulation_24_hour == 0
            & integer_lasso_sepsis_respiratory_24_hour == 0
            )
         ]


R01_DATA[, .N, keyby = .(integer_lasso_sepsis_total_03_hour > 0, la_resp_only_03_hour, la_neuro_only_03_hour)]
R01_DATA[, .N, keyby = .(integer_lasso_sepsis_total_24_hour > 0, la_resp_only_24_hour, la_neuro_only_24_hour)]


### LASSO 2 points, no single organ resp or neuro
R01_DATA[, la2resp_03_hour := as.integer( (integer_lasso_sepsis_respiratory_03_hour >= 2) & la_resp_only_03_hour) ]
R01_DATA[, la2resp_24_hour := as.integer( (integer_lasso_sepsis_respiratory_24_hour >= 2) & la_resp_only_24_hour) ]

R01_DATA[, la2neuro_03_hour := as.integer( (integer_lasso_sepsis_neurologic_03_hour >= 2) & la_neuro_only_03_hour) ]
R01_DATA[, la2neuro_24_hour := as.integer( (integer_lasso_sepsis_neurologic_24_hour >= 2) & la_neuro_only_24_hour) ]

R01_DATA[, La2rem_03_hour :=
         as.integer((integer_lasso_sepsis_total_03_hour >= 2) &
                    (la2resp_03_hour == 0) &
                    (la2neuro_03_hour == 0))
         ]
R01_DATA[, La2rem_24_hour :=
         as.integer((integer_lasso_sepsis_total_24_hour >= 2) &
                    (la2resp_24_hour == 0) &
                    (la2neuro_24_hour == 0))
         ]

### Ridge 3 points
R01_DATA[, ridge3pt :=
         as.integer(integer_ridge_sepsis_total_24_hour >= 3)
       ]

R01_DATA[, table(Phoenix_Sepsis, ridge3pt)]
R01_DATA[, table(La2rem_24_hour, ridge3pt)]

### Phoenix_Sepsis and La2rem and ridge3pt
R01_DATA[, all3 := as.integer(Phoenix_Sepsis & La2rem_24_hour & ridge3pt) ]

### LASSO 2 remote, CV at least 1 points
R01_DATA[, La2remcv1 :=
           as.integer((integer_lasso_sepsis_remote_geq2_72_hour > 0) &
                        (integer_lasso_sepsis_cardiovascular_24_hour >= 1))
]

### LASSO 2 remote, CV at least 2 points
R01_DATA[, La2remcv2 :=
           as.integer((integer_lasso_sepsis_remote_geq2_72_hour > 0) &
                        (integer_lasso_sepsis_cardiovascular_24_hour >= 2))
]

################################################################################
                                ## SUBSETTING ##

# Define a function load_strata to make is easy
load_strata <- function(strata_name, DT) {
  idx <- which(sensitivity_strata[["strata_name"]] == strata_name)
  if (length(idx) == 0L) {
    stop(paste0("strata_name: ", strata_name, " not found in sensitivity_strata"))
  } else if (length(idx) > 1L) {
    stop(paste0("strata_name: ", strata_name, " matches multiple rows in sensitivity_strata"))
  }
  ss <- sensitivity_strata[["strata"]][idx]
  message(paste0("Building ", strata_name, " defined as:\n  ", ss))
  subset(DT, subset = eval(parse(text = ss)))
}

R01_TRAINING                     <- R01_DATA[sa_subset %in% c("SA1", "SA2g", "SA2h")]
R01_VALIDATION                   <- R01_DATA[sa_subset %in% c("SA2t", "**REDACTED**", "**REDACTED**", "**REDACTED**")]

HIC_1dose_training              <- load_strata("HIC_1dose",            DT = R01_TRAINING)
HIC_1dose_validation            <- load_strata("HIC_1dose",            DT = R01_VALIDATION)
HIC1d_ph_training               <- load_strata("HIC1d_ph",             DT = R01_TRAINING)  ## previously healthy proxy
HIC1d_ph_validation             <- load_strata("HIC1d_ph",             DT = R01_VALIDATION)  ## previously healthy proxy
**REDACTED**_1dose_validation            <- load_strata("**REDACTED**_1dose",            DT = R01_VALIDATION)
**REDACTED**_1dose_validation          <- load_strata("**REDACTED**_1dose",          DT = R01_VALIDATION)
HIC_ED_0dose_training           <- load_strata("HIC_ED_0dose",         DT = R01_TRAINING)
HIC_ED_0dose_no_**REDACTED**_training   <- load_strata("HIC_ED_0dose_no_**REDACTED**", DT = R01_TRAINING)
HIC_ED_0dose_no_**REDACTED**_validation <- load_strata("HIC_ED_0dose_no_**REDACTED**", DT = R01_VALIDATION)
HIC_ED_1dose_training           <- load_strata("HIC_ED_1dose",         DT = R01_TRAINING)
**REDACTED**_0dose_training              <- load_strata("**REDACTED**_0dose",            DT = R01_TRAINING)
**REDACTED**_0dose_training            <- load_strata("**REDACTED**_0dose",          DT = R01_TRAINING)
**REDACTED**_0dose_early_training      <- load_strata("**REDACTED**_0dose_early",    DT = R01_TRAINING)
LMIC_1dose_training             <- load_strata("LMIC_1dose",           DT = R01_TRAINING)
**REDACTED**_1dose_training              <- load_strata("**REDACTED**_1dose",            DT = R01_TRAINING)

HIC_1d_under_2yr_training        <- HIC_1dose_training[  admit_age_months <= 24]
**REDACTED**_0dose_sa2h                 <- **REDACTED**_0dose_early_training[sa_subset == "SA2h"]
**REDACTED**_1dose_validation            <- R01_VALIDATION[site=="**REDACTED**" & suspected_infection_1dose_24_hour ==1]
**REDACTED**_1dose_validation           <- R01_VALIDATION[site=="**REDACTED**" & suspected_infection_1dose_24_hour ==1]
**REDACTED**_1dose_validation           <- R01_VALIDATION[site=="**REDACTED**" & suspected_infection_1dose_24_hour ==1]
HIC_ED_1dose_no_**REDACTED**_sa2h        <- R01_DATA[!(site %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**", "**REDACTED**")) & ever_ed == 1L & suspected_infection_1dose_03_hour ==1 & sa_subset=="SA2h"]
HIC_ED_0dose_no_la2pt3h_training <- R01_TRAINING[  !(site %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**")) & ever_ed == 1L & suspected_infection_0dose_03_hour ==1 & la2pt_03_hour==0]
HIC_1d_ICU_validation            <- HIC_1dose_validation[ever_icu==1]
HIC_ED_1dose_no_la2pt3h_training <- R01_TRAINING[  !(site %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**")) & ever_ed == 1L & suspected_infection_1dose_03_hour ==1 & la2pt_03_hour==0]
HIC_ED_0dose_sa2h   <- R01_DATA[!(site %in% c("**REDACTED**", "**REDACTED**", "**REDACTED**")) & ever_ed == 1L & suspected_infection_0dose_03_hour ==1 & sa_subset=="SA2h"]

################################################################################
                               ## END OF FILE ##
################################################################################
