################################################################################
                ## Namespaces, utility functions, data import ##
library(data.table)

# import all elements of utilities2.R into the .GlobalEnv
# this includes the venn_diagram function
source("../specific_aims/utilities2.R", local = .GlobalEnv)

# set base function for where to save graphics
gcs_base_path <-
  paste0("~/gcs/**REDACTED**/integer_sepsis_graphics")

################################################################################
                               ## DATA IMPORT ##

# sourcing the following function will load the data, rename columns, create
# coulumns, and generate specific subsets.  This also loads some utilities
# functions into an environment called utilities
source(file = "../manuscripts/**REDACTED**_R01_data.R", echo = TRUE)

################################################################################
### HIC 1-5 Death
Sepsis_HIC1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = HIC_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "Panel A: Positive predictive value versus\nsensitivity for death at high resource sites"
    , Nn = TRUE
    , NnOutcome = "deaths"
  ) |>
  print()

Sepsis_HIC1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_A_HIC1to5_1dose_death.svg")
                , plot = Sepsis_HIC1dose_death
                , width = 7
                , height = 7
)

# removing some objects to help make sure they are not reused by mistake
rm(Sepsis_HIC1dose_death)

################################################################################
### HIC 1-5 Early Death or ECMO
Sepsis_HIC1dose_early_death <-
  list(
      ecmo_or_early_death ~ Phoenix_Sepsis
    , ecmo_or_early_death ~ IPSCC_Severe_Sepsis
    , ecmo_or_early_death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = HIC_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    #, title = "HRS 1-5, Outcome: Early Death or ECMO"
    , title = "Panel B: Positive predictive value versus\nsensitivity for early death or ECMO\nat high resource sites"
    , Nn = TRUE
    , NnOutcome = "early deaths or ECMO"
  ) |>
  print()

Sepsis_HIC1dose_early_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_B_HIC1to5_1dose_earlydeathecmo.svg")
                , plot = Sepsis_HIC1dose_early_death
                , width = 7
                , height = 7
)

rm(Sepsis_HIC1dose_early_death)

################################################################################
### HIC 1-5 PH Death
Sepsis_HIC1d_ph_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = HIC1d_ph_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    #, title = "HRS 1-5 with no comorbidity, Outcome: Death"
    , title = "Panel C: Positive predictive value versus\nsensitivity for death at high resource sites\nin children with no comorbidities"
    , Nn = TRUE
    , NnOutcome = "deaths"
  ) |>
  print()

Sepsis_HIC1d_ph_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_C_HIC1to5_1dose_ph_death.svg")
                , plot = Sepsis_HIC1d_ph_death
                , width = 7
                , height = 7
)

rm(Sepsis_HIC1d_ph_death)

################################################################################
### HIC 1-5 ever ICU
Sepsis_HIC_1d_ICU_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = HIC_1d_ICU_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    #, title = "HRS 1-5, Encounters with ICU, Outcome: Death"
    , title = "Panel D: Positive predictive value versus\nsensitivity for death at high resource\n sites - encounters with an ICU stay"
    , Nn = TRUE
    , NnOutcome = "deaths"
  ) |>
  print()

Sepsis_HIC_1d_ICU_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_D_HIC1to5_1dose_ICU_death.svg")
                , plot = Sepsis_HIC_1d_ICU_death
                , width = 7
                , height = 7
)

rm(Sepsis_HIC_1d_ICU_death)

################################################################################
### HIC 6 Death
Sepsis_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HRS 6, Outcome: Death"
    , Nn = TRUE
  ) |>
  print()

Sepsis_**REDACTED**1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/HIC6_1dose_death.svg")
                , plot = Sepsis_**REDACTED**1dose_death
                , width = 7
                , height = 7
)

rm(Sepsis_**REDACTED**1dose_death)

################################################################################
### HIC 6 Early Death or ECMO
Sepsis_**REDACTED**1dose_early_death <-
  list(
      ecmo_or_early_death ~ Phoenix_Sepsis
    , ecmo_or_early_death ~ IPSCC_Severe_Sepsis
    , ecmo_or_early_death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HRS 6, Outcome: Early Death or ECMO"
    , Nn = TRUE
  ) |>
  print()

Sepsis_**REDACTED**1dose_early_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/HIC6_1dose_earlydeathecmo.svg")
                , plot = Sepsis_**REDACTED**1dose_early_death
                , width = 7
                , height = 7
)
rm(Sepsis_**REDACTED**1dose_early_death)

################################################################################
### LMIC 1 Death
Sepsis_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    #, title = "LRS 1, Outcome: Death"
    , title = "Panel E: Positive predictive value versus\nsensitivity for death at lower resource site 1"
    , Nn = TRUE
    , NnOutcome = "deaths"
  ) |>
  print()

Sepsis_**REDACTED**1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_E_LMIC1_1dose_death.svg")
                , plot = Sepsis_**REDACTED**1dose_death
                , width = 7
                , height = 7
)

rm(Sepsis_**REDACTED**1dose_death)

################################################################################
### LMIC 2 Death
Sepsis_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.70)
    , xlim = c(0, 1)
    , cis = TRUE
    #, title = "LRS 2*, Outcome: Death"
    , title = "Panel F: Positive predictive value versus\nsensitivity for death at lower resource site 2*"
    , Nn = TRUE
    , NnOutcome = "deaths"
  ) |>
  print()

Sepsis_**REDACTED**1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Panel_F_LMIC2_1dose_death.svg")
                , plot = Sepsis_**REDACTED**1dose_death
                , width = 7
                , height = 7
)

rm(Sepsis_**REDACTED**1dose_death)

################################################################################
### LMIC 3 Death
Sepsis_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.30)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "LRS 3*, Outcome: Death"
    , Nn = TRUE
  ) |>
  print()

Sepsis_**REDACTED**1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/LMIC3_1dose_death.svg")
                , plot = Sepsis_**REDACTED**1dose_death
                , width = 7
                , height = 7
)

rm(Sepsis_**REDACTED**1dose_death)

################################################################################
### LMIC 4  Death
Sepsis_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Sepsis
    , death ~ IPSCC_Severe_Sepsis
    , death ~ IPSCC_SIRS_Sepsis
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_validation) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.30)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "LRS 4*, Outcome: Death"
    , Nn = TRUE
  ) |>
  print()

Sepsis_**REDACTED**1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/LMIC4_1dose_death.svg")
                , plot = Sepsis_**REDACTED**1dose_death
                , width = 7
                , height = 7
)

rm(Sepsis_**REDACTED**1dose_death)

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_0dose <-
  list(
      integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
    ) |>
  lapply(confusion_matrix, data = HIC_ED_0dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HIC ED 0 Dose, Outcome: La2pt 72 hour"
    , Nn = TRUE
  ) |>
  print()

SepsisTF_La2pt72hour_within_HIC_ED_0dose

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_0dose.svg")
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_0dose
                , width = 7
                , height = 7
                )
rm(SepsisTF_La2pt72hour_within_HIC_ED_0dose)

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_**REDACTED** <-
  list(
      integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
  ) |>
  lapply(confusion_matrix, data = HIC_ED_0dose_no_**REDACTED**_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HIC ED 0 Dose, no **REDACTED**, Outcome: La2pt 72 hour"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_**REDACTED**.svg")
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_**REDACTED**
                , width = 7
                , height = 7
)
rm(SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_**REDACTED**)

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_la2pt3h <-
  list(
      integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
  ) |>
  lapply(confusion_matrix, data = HIC_ED_0dose_no_la2pt3h_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HIC ED 0 Dose, no la2pt3h, Outcome: La2pt 72 hour"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_la2pt3h.svg")
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_la2pt3h
                , width = 7
                , height = 7
)
rm(SepsisTF_La2pt72hour_within_HIC_ED_0dose_no_la2pt3h)

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_1dose <-
  list(
      integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
    ) |>
  lapply(confusion_matrix, data = HIC_ED_1dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_La2pt72hour_within_HIC_ED_1dose"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_1dose.svg" )
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_1dose
                , width = 7
                , height = 7
                )

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_**REDACTED**_sa2h <-
  list(
      integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
  ) |>
  lapply(confusion_matrix, data = HIC_ED_1dose_no_**REDACTED**_sa2h) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_**REDACTED**_sa2h"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_**REDACTED**_sa2h.svg")
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_**REDACTED**_sa2h
                , width = 7
                , height = 7
)

################################################################################
SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_la2pt3h <-
  list(
    integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
  ) |>
  lapply(confusion_matrix, data = HIC_ED_1dose_no_la2pt3h_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_la2pt3h"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_la2pt3h.svg")
                , plot = SepsisTF_La2pt72hour_within_HIC_ED_1dose_no_la2pt3h
                , width = 7
                , height = 7
)

################################################################################
SepsisTF_La2pt72hour_within_**REDACTED**_0dose <-
  list(
    integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
    ) |>
  lapply(confusion_matrix, data = **REDACTED**_0dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_La2pt72hour_within_**REDACTED**_0dose"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_**REDACTED**_0dose.svg")
                , plot = SepsisTF_La2pt72hour_within_**REDACTED**_0dose
                , width = 7
                , height = 7
                )
################################################################################
SepsisTF_La2pt72hour_within_**REDACTED**_0dose <-
  list(
    integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ qSOFA2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2ptor1La
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep1pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep2pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep3pt
    , integer_lasso_sepsis_geq2_72_hour ~ PossSep4pt
    , integer_lasso_sepsis_geq2_72_hour ~ IPSCC_SIRS_Sepsis
    , integer_lasso_sepsis_geq2_72_hour ~ pews2pt
    , integer_lasso_sepsis_geq2_72_hour ~ La2pt03hr
    , integer_lasso_sepsis_geq2_72_hour ~ La1pt03hr
    ) |>
  lapply(confusion_matrix, data = **REDACTED**_0dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_La2pt72hour_within_**REDACTED**_0dose"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_La2pt72hour_within_**REDACTED**_0dose.svg")
                , plot = SepsisTF_La2pt72hour_within_**REDACTED**_0dose
                , width = 7
                , height = 7
                )

################################################################################
SepsisTF_death_within_**REDACTED**_0dose_sa2h <-
  list(
      death ~ La4pt
    , death ~ La5pt
    , death ~ La2remcv2
    , death ~ La2cv2
    ) |>
  lapply(confusion_matrix, data = **REDACTED**_0dose_sa2h) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "SepsisTF_death_within_**REDACTED**_0dose_sa2h"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_death_within_**REDACTED**_0dose_sa2h.svg")
                , plot = SepsisTF_death_within_**REDACTED**_0dose_sa2h
                , width = 7
                , height = 7
                )

################################################################################
                                ## Septic Shock ##
### HIC Death
Septic_shock_HIC1dose_death <-
  list(
      death ~ Phoenix_Septic_Shock #La2cv1
    , death ~ La2cv2
    , death ~ La2cv3
    , death ~ La2cv4
    , death ~ Phoenix_Sepsis #La2pt
    , death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = HIC_1dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "Septic_shock_HIC1dose_death"
    , Nn = TRUE
  ) |>
  print()

Septic_shock_HIC1dose_death

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_HIC1dose_death.svg")
                , plot = Septic_shock_HIC1dose_death
                , width = 7
                , height = 7
)


### HIC ECMO or early death
Septic_shock_HIC1dose_ecmoearly <-
  list(
      ecmo_or_early_death ~ Phoenix_Septic_Shock
    , ecmo_or_early_death ~ La2cv2
    , ecmo_or_early_death ~ La2cv3
    , ecmo_or_early_death ~ La2cv4
    , ecmo_or_early_death ~ Phoenix_Sepsis #La2pt
    , ecmo_or_early_death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = HIC_1dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "HIC 1dose ECMO or Early Death"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_HIC1dose_ecmoearly.svg")
                , plot = Septic_shock_HIC1dose_ecmoearly
                , width = 7
                , height = 7
)


### LMIC death
Septic_shock_LMIC1dose_death <-
  list(
      death ~ Phoenix_Septic_Shock
    , death ~ La2cv2
    , death ~ La2cv3
    , death ~ La2cv4
    , death ~ Phoenix_Sepsis #La2pt
    , death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = LMIC_1dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "Both LMIC Sites, Death"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_LMIC1dose_death.svg")
                , plot = Septic_shock_LMIC1dose_death
                , width = 7
                , height = 7
)


### **REDACTED** death
Septic_shock_**REDACTED**1dose_death <-
  list(
      death ~ Phoenix_Septic_Shock #La2cv1
    , death ~ La2cv2
    , death ~ La2cv3
    , death ~ La2cv4
    , death ~ Phoenix_Sepsis #La2pt
    , death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = **REDACTED**_1dose_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "LMIC Site #1, Death"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_**REDACTED**1dose_death.svg")
                , plot = Septic_shock_**REDACTED**1dose_death
                , width = 7
                , height = 7
)




### HIC Previously Healthy Death
Septic_shock_HIC1d_ph_death <-
  list(
      death ~ Phoenix_Septic_Shock #La2cv1
    , death ~ La2cv2
    , death ~ La2cv3
    , death ~ La2cv4
    , death ~ Phoenix_Sepsis #La2pt
    , death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = HIC1d_ph_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "No Known Comorbidities. Outcome = Death"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_HIC1d_ph_death.svg")
                , plot = Septic_shock_HIC1d_ph_death
                , width = 7
                , height = 7
)



### HIC Previously Healthy ECMO or Early Death
Septic_shock_HIC1d_ph_ecmoearly <-
  list(
      ecmo_or_early_death ~ Phoenix_Septic_Shock #La2cv1
    , ecmo_or_early_death ~ La2cv2
    , ecmo_or_early_death ~ La2cv3
    , ecmo_or_early_death ~ La2cv4
    , ecmo_or_early_death ~ Phoenix_Sepsis #La2pt
    , ecmo_or_early_death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = HIC1d_ph_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "No Known Comorbidities. Outcome = ECMO or Early Death"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_HIC1d_ph_ecmoearly.svg")
                , plot = Septic_shock_HIC1d_ph_ecmoearly
                , width = 7
                , height = 7
)


### HIC, Death, under 2 years
Septic_shock_HIC1dose_death_under2 <-
  list(
    death ~ Phoenix_Septic_Shock #La2cv1
    , death ~ La2cv2
    , death ~ La2cv3
    , death ~ La2cv4
    , death ~ Phoenix_Sepsis #La2pt
    , death ~ IPSCC_Septic_Shock
  ) |>
  lapply(confusion_matrix, data = HIC_1d_under_2yr_training) |>
  data.table::rbindlist() |>
  print() |>
  sensitivity_precision_plot(
      dat = _
    , ylim = c(0, 0.15)
    , xlim = c(0, 1)
    , cis = TRUE
    , title = "Death, Under 2 Years only"
    , Nn = TRUE
  ) |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Septic_shock_HIC1dose_death_under2.svg")
                , plot = Septic_shock_HIC1dose_death_under2
                , width = 7
                , height = 7
)

################################################################################
                               ## END OF FILE ##
################################################################################
