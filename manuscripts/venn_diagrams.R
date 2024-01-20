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
# functions.
source(file = "**REDACTED**_R01_data.R", echo = TRUE)
sensitivity_strata <- utilities$read_sensitivity_strata() # this includes all the training strata.

################################################################################
SepsisTF_lqSOFA2pt_venn_within_HIC_ED_0dose_sa2h <-
  confusion_matrix(integer_lasso_sepsis_geq2_72_hour ~ lqSOFA2pt, data = HIC_ED_0dose_sa2h) |>
  print() |>
  venn_diagram(tlabel = "La2pt (72h)") |>
  print()

ggplot2::ggsave(filename = paste0(gcs_base_path, "/SepsisTF_lqSOFA2pt_venn_within_HIC_ED_0dose_sa2h.svg")
                , plot = SepsisTF_lqSOFA2pt_venn_within_HIC_ED_0dose_sa2h
                , width = 7
                , height = 7
                )

################################################################################
#
# Venn diagram with mortality of La2rem with any CV dysfunciton
# La2ptcv1 is Phoenix_Sepsis = 1 AND cardiovascular >= 1, see ../timecourse/integer_lasso_sepsis_total.sql
### HIC
confusion_matrix(death ~ Phoenix_Septic_Shock, data = HIC_1dose_training) |> ### La2cv1 is now called septic shock, see top
venn_diagram(data = _)

confusion_matrix(Phoenix_Sepsis ~ Phoenix_Septic_Shock, data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

confusion_matrix(Phoenix_Sepsis ~ sepsis_remote, data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

p <-
  confusion_matrix(Phoenix_Sepsis ~ sepsis_remote, data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

### eFigure7
ggplot2::ggsave(filename = paste0(gcs_base_path, "/Venn_HIC1dose_La2pt_La2rem.svg")
                , plot = p
                , width = 7
                , height = 3.5
)

confusion_matrix(Phoenix_Sepsis ~ sepsis_remote, data = LMIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

q <-
  confusion_matrix(Phoenix_Sepsis ~ sepsis_remote, data = LMIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

ggplot2::ggsave(filename = paste0(gcs_base_path, "/Venn_LMIC1dose_La2pt_La2rem.svg")
                , plot = q
                , width = 7
                , height = 3.5
)

confusion_matrix(Phoenix_Sepsis ~ La2cv2, data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

confusion_matrix(sepsis_remote ~ Phoenix_Septic_Shock, data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

### LMIC
confusion_matrix(Phoenix_Sepsis ~ Phoenix_Septic_Shock, data = LMIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

# La2 Remote, as the truth, by CV1 >= 1 (within 24 hours) regardless of other criteria.
confusion_matrix(sepsis_remote ~ integer_lasso_sepsis_cardiovascular_24_hour >= 1
                 , data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

# La2 Remote, as the truth, by CV1 == 1 (within 24 hours) regardless of other criteria.
confusion_matrix(sepsis_remote ~ integer_lasso_sepsis_cardiovascular_24_hour == 1
                 , data = HIC_1dose_training) |>
  print() |>
  venn_diagram(data = _)

# Venn diagram with mortality of Phoenix_Sepsis with CV1, CV2, ...
confusion_matrix(death ~ Phoenix_Septic_Shock, data = HIC_1dose_training) |>
venn_diagram(data = _)

confusion_matrix(death ~ La2cv2, data = HIC_1dose_training) |>
venn_diagram(data = _)

################################################################################
                               ## END OF FILE ##
################################################################################
