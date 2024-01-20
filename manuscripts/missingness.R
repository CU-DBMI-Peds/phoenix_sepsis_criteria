################################################################################
source("../interim_reports/utilities.R")
params <- list()
training_strata <- read_training_strata()
training_strata$strata_name

if (!interactive()) {
  cargs <- as.list(commandArgs(trailingOnly = TRUE))
  stopifnot(!is.null(cargs[[1]]))
  cargs[[1]] <- gsub("\"", "", cargs[[1]])
  print(cargs)
  print(str(cargs))
  stopifnot(cargs[[1]] %in% training_strata$strata_name)
} else {
  cargs <- list()
  cargs[[1]] <- "\"LMIC_1dose\""
  cargs[[1]] <- "HIC_1dose"
  cargs[[1]] <- "LMIC_1dose"
}
stopifnot(!is.null(cargs[[1]]))
stopifnot(cargs[[1]] %in% training_strata$strata_name)

# params$strata_hash <- training_strata[strata_name == "HIC_1dose", strata_hash]
params$strata_hash <- training_strata[strata_name == cargs[[1]], strata_hash]
stopifnot(!is.null(params$strata_hash))

params$eclock_upper_limit = 1440 * 3 # 3 days
params$strata_name <- training_strata[strata_hash == params$strata_hash, strata_name]

print(params)

################################################################################
##                             Active Encounters                              ##

foundation <-
  paste0(
    "\nSELECT enc_id, death, MAX(eclock) AS max_eclock"
  , "\nFROM **REDACTED**.timecourse.foundation"
  , "\nWHERE enc_id IN (SELECT DISTINCT enc_id FROM **REDACTED**.sa.strata WHERE sa_subset IN ('SA1', 'SA2g', 'SA2h') AND strata_hash = '", params$strata_hash, "')"
  , "\nGROUP BY enc_id, death"
  ) |>
  bq_project_query(project_id, query = _) |>
  bq_table_download() |>
  data.table::setDT()

encounter_status <- data.table(eclock = seq(0, params$eclock_upper_limit, by = 1))
encounter_status <-
  merge(
      encounter_status
    , data.table::rbindlist(
        pblapply(encounter_status[["eclock"]]
                 , function(m) {
                   data.table(eclock = m
                              , active_encounters = foundation[max_eclock > m, .N]
                              , encounter_ended_death = foundation[max_eclock == m & death == 1, .N]
                              , encounter_ended_alive = foundation[max_eclock == m & death == 0, .N]
                              )
                 })
      )
    , by = "eclock"
  )
encounter_status[, cummulative_deaths := cumsum(encounter_ended_death)]
encounter_status[, cummulative_discharged_alive := cumsum(encounter_ended_alive)]

encounter_status <- melt(
     data = encounter_status
   , id.vars = c("eclock")
   , measure.vars = c(
                      "cummulative_deaths"
                     , "cummulative_discharged_alive"
                     , "active_encounters")
   , value.name = "N"
   , variable.name = "encounter_status"
   )

encounter_status[, p := N / sum(N), by = .(eclock)]

encounter_status[, ymin := cumsum(shift(p, fill = 0)), by = .(eclock)]
encounter_status[, ymax := cumsum(p), by = .(eclock)]

ggplot2::ggplot(data = encounter_status) +
  ggplot2::aes(x = eclock, y = ymin, ymin = ymin, ymax = ymax, fill = encounter_status) +
  ggplot2::scale_x_continuous(  name = "Time from Hospital Presentation (Hours)"
                              , breaks = seq(0, max(encounter_status[["eclock"]]), by = 180)
                              , labels = seq(0, max(encounter_status[["eclock"]]), by = 180) %/% 60
                              , minor_breaks = seq(0, max(encounter_status[["eclock"]]), by = 60)
                              ) +
  ggplot2::scale_y_log10(name = "All Encounters", label = scales::percent,
                         sec.axis = ggplot2::sec_axis(trans = ~ .*encounter_status[eclock == 0 & encounter_status == "active_encounters", max(N)]
                                                      , label = scales::comma
                                                      )
                         ) +
  ggplot2::geom_ribbon() +
  ggplot2::ggtitle("Encounter Status") +
  ggplot2::theme(legend.position = "bottom", legend.title = ggplot2::element_blank())

################################################################################
##                            Timecourse summaries                            ##

timecourse_query <- function(hash = params$strata_hash, variable, table, eclock_upper_limit = params$eclock_upper_limit) {
  query <-
  "
  WITH L0 AS
  (
    SELECT strata.site, strata.sa_subset, strata.enc_id, e.eclock, m.max_eclock
    FROM (
      SELECT site, sa_subset, enc_id
      FROM `**REDACTED**.sa.strata`
      WHERE sa_subset IN ('SA1', 'SA2g', 'SA2h') AND strata_hash = 'STRATA_HASH'
    ) strata
    CROSS JOIN (SELECT eclock FROM UNNEST(GENERATE_ARRAY(0, ECLOCK_UPPPER_LIMIT)) AS eclock) e
    LEFT JOIN (
      SELECT enc_id, MAX(eclock) AS max_eclock
      FROM **REDACTED**.timecourse.foundation
      WHERE enc_id IN (SELECT DISTINCT enc_id FROM **REDACTED**.sa.strata WHERE strata_hash = 'STRATA_HASH')
      GROUP BY enc_id
    ) m
    ON strata.enc_id = m.enc_id
  )
  ,
  T AS
  (
  SELECT
        L.site
      , L.sa_subset
      , L.enc_id
      , L.eclock
      , LAST_VALUE(tab.VARIABLE  IGNORE NULLS) OVER (PARTITION BY L.site, L.enc_id ORDER BY L.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS value
    FROM (SELECT * FROM L0 WHERE eclock < max_eclock) L
    LEFT JOIN `**REDACTED**.timecourse.foundation` tc
    ON L.site = tc.site AND L.enc_id = tc.enc_id AND L.eclock = tc.eclock
    LEFT JOIN `**REDACTED**.timecourse.TABLE` tab
    ON L.site = tab.site AND L.enc_id = tab.enc_id AND L.eclock = tab.eclock
  ORDER BY site, enc_id, L.eclock
  )
  SELECT
      eclock
    , 'STRATA_HASH' AS strata_hash
    , 'VARIABLE' AS variable
    , value
    , COUNT(1) AS N
  FROM T
  GROUP BY eclock, value
  ORDER BY eclock, value
  "
  query <- gsub("STRATA_HASH", hash, query)
  query <- gsub("TABLE", table, query)
  query <- gsub("VARIABLE", variable, query)
  query <- gsub("ECLOCK_UPPPER_LIMIT", eclock_upper_limit, query)
  query
}

download <- function(query) {
  bq_project_query(project_id, query = query) |>
  bq_table_download() |>
  data.table::setDT()
}

integer_lasso_sepsis_queries <-
  list(
       "temperature"               = timecourse_query(variable = "temperature",               table = "temperature")
     , "total_antimicrobial_doses" = timecourse_query(variable = "total_antimicrobial_doses", table = "suspected_infection")
     , "total_ordered_tests"       = timecourse_query(variable = "total_ordered_tests",       table = "suspected_infection")
     , "o2_flow"                   = timecourse_query(variable = "o2_flow",                   table = "o2_flow")
     , "respiratory_rate"          = timecourse_query(variable = "respiratory_rate",          table = "respiratory_rate")
     , "pews_saturation"           = timecourse_query(variable = "pews_saturation",           table = "pews_respiratory")
     , "pews_oxygen"               = timecourse_query(variable = "pews_oxygen",               table = "pews_respiratory")
     , "pews_tachypnea"            = timecourse_query(variable = "pews_tachypnea",            table = "pews_respiratory")
     , "qsofa_cardiovascular"      = timecourse_query(variable = "qsofa_cardiovascular",      table = "qsofa_cardiovascular")
     , "pews_cap_refill"           = timecourse_query(variable = "pews_cap_refill",           table = "pews_cardiovascular")
     , "pews_tachycardia"          = timecourse_query(variable = "pews_tachycardia",          table = "pews_cardiovascular")
     , "psofa_neurological"        = timecourse_query(variable = "psofa_neurological",        table = "psofa_neurological")
     , "lqsofa_total"              = timecourse_query(variable = "lqsofa_total",              table = "lqsofa_total")
     , "qsofa_total"               = timecourse_query(variable = "qsofa_total",               table = "qsofa_total")
     , "pews_total"                = timecourse_query(variable = "pews_total",                table = "pews_total")
     , "possible_sepsis_resp"      = timecourse_query(variable = "possible_sepsis_resp",      table = "possible_sepsis")
     , "possible_sepsis_neuro"     = timecourse_query(variable = "possible_sepsis_neuro",     table = "possible_sepsis")
     , "possible_sepsis_cv"        = timecourse_query(variable = "possible_sepsis_cv",        table = "possible_sepsis")
     , "possible_sepsis_total"     = timecourse_query(variable = "possible_sepsis_total",     table = "possible_sepsis")
     , "possible_sepsis_total_min" = timecourse_query(variable = "possible_sepsis_total_min", table = "possible_sepsis")
     , "dobutamine_yn"     = timecourse_query(variable = "dobutamine_yn",     table = "dobutamine")
     , "dopamine_yn"       = timecourse_query(variable = "dopamine_yn",       table = "dopamine")
     , "epinephrine_yn"    = timecourse_query(variable = "epinephrine_yn",    table = "epinephrine")
     , "milrinone_yn"      = timecourse_query(variable = "milrinone_yn",      table = "milrinone")
     , "norepinephrine_yn" = timecourse_query(variable = "norepinephrine_yn", table = "norepinephrine")
     , "vasopressin_yn"    = timecourse_query(variable = "vasopressin_yn",    table = "vasopressin")
     , "lactate"           = timecourse_query(variable = "lactate",           table = "lactate")
     , "map"               = timecourse_query(variable = "map",               table = "bloodpressure")
     , "integer_lasso_sepsis_cardiovascular" = timecourse_query(variable = "integer_lasso_sepsis_cardiovascular" , table = "integer_lasso_sepsis_cardiovascular")
     , "integer_lasso_sepsis_cardiovascular_min" = timecourse_query(variable = "integer_lasso_sepsis_cardiovascular_min" , table = "integer_lasso_sepsis_cardiovascular")
     , "platelets"  = timecourse_query(variable = "platelets",  table = "platelets")
     , "inr"        = timecourse_query(variable = "inr",        table = "inr")
     , "d_dimer"    = timecourse_query(variable = "d_dimer",    table = "d_dimer")
     , "fibrinogen" = timecourse_query(variable = "fibrinogen", table = "fibrinogen")
     , "integer_lasso_sepsis_coagulation" = timecourse_query(variable = "integer_lasso_sepsis_coagulation" , table = "integer_lasso_sepsis_coagulation")
     , "integer_lasso_sepsis_coagulation_min" = timecourse_query(variable = "integer_lasso_sepsis_coagulation_min" , table = "integer_lasso_sepsis_coagulation")
     , "gcs_total" = timecourse_query(variable = "gcs_total",  table = "gcs")
     , "pupil"     = timecourse_query(variable = "pupil",      table = "pupil")
     , "integer_lasso_sepsis_neurologic" = timecourse_query(variable = "integer_lasso_sepsis_neurologic" , table = "integer_lasso_sepsis_neurologic")
     , "integer_lasso_sepsis_neurologic_min" = timecourse_query(variable = "integer_lasso_sepsis_neurologic_min" , table = "integer_lasso_sepsis_neurologic")
     , "spo2_for_non_podium" = timecourse_query(variable = "spo2_for_non_podium", table = "spo2")
     , "pao2" = timecourse_query(variable = "pao2", table = "pao2")
     , "fio2" = timecourse_query(variable = "fio2", table = "fio2")
     , "vent" = timecourse_query(variable = "vent", table = "vent")
     , "integer_lasso_sepsis_respiratory" = timecourse_query(variable = "integer_lasso_sepsis_respiratory" , table = "integer_lasso_sepsis_respiratory")
     , "integer_lasso_sepsis_respiratory_min" = timecourse_query(variable = "integer_lasso_sepsis_respiratory_min" , table = "integer_lasso_sepsis_respiratory")
     , "integer_lasso_sepsis_total" = timecourse_query(variable = "integer_lasso_sepsis_total", table = "integer_lasso_sepsis_total")
     , "integer_lasso_sepsis_total_min" = timecourse_query(variable = "integer_lasso_sepsis_total_min", table = "integer_lasso_sepsis_total")
     , "glucose" = timecourse_query(variable = "glucose", table = "glucose")
     , "bilirubin_tot" = timecourse_query(variable = "bilirubin_tot", table = "bilirubin_tot")
     , "anc" = timecourse_query(variable = "anc", table = "anc")
     , "alc" = timecourse_query(variable = "alc", table = "alc")
     , "creatinine" = timecourse_query(variable = "creatinine", table = "creatinine")
  )

integer_lasso_sepsis <- pblapply(integer_lasso_sepsis_queries, download, cl = length(integer_lasso_sepsis_queries))

not_data_table <- which( !(sapply(integer_lasso_sepsis, inherits, what = "data.table")) )
for(i in not_data_table) {
  integer_lasso_sepsis[[i]] <- download(integer_lasso_sepsis_queries[[i]])
}
stopifnot( sapply(integer_lasso_sepsis, inherits, what = "data.table") )

integer_lasso_sepsis$La2pt <- data.table::copy(integer_lasso_sepsis$integer_lasso_sepsis_total_min)
integer_lasso_sepsis$La2pt[, variable := "La2pt"]
integer_lasso_sepsis$La2pt[, value := as.integer(value >= 2)]
integer_lasso_sepsis$La2pt[, .(N = sum(N)), keyby = .(eclock, strata_hash, variable, value)]

# set factor levels for the variable, helpful for some plotting
# and omit hash for the data.tables
lapply(integer_lasso_sepsis,
       function(x) {
         x[, strata_hash := NULL]
         x[, variable := factor(variable, levels = names(integer_lasso_sepsis))]
       })

# set factor levels for the variable, helpful for some plotting
lapply(integer_lasso_sepsis,
       function(x) {
         x[, variable := factor(variable, levels = names(integer_lasso_sepsis))]
       })


# set the value for pupil to an integer value so that all the value columns are
# numeric (integer being a subset of numeric)
integer_lasso_sepsis$pupil[, value := fcase(value == "both-reactive", 0L,
                                            value == "at least one fixed", 1L,
                                            value == "both-fixed", 2L)]


fill_in_missing_combos <- function(DT) {
  LEFT <- data.table::CJ(eclock = unique(DT$eclock), status = levels(DT$status))
  LEFT[, status := factor(status, levels = levels(DT$status))]
  rtn <- merge(LEFT, DT, by = c("eclock", "status"), all.x = TRUE)
  rtn <- rtn[, .(N = sum(N)), keyby = .(eclock, status)]
  rtn[, N := nafill(N, fill = 0L)]
  # merge on the active_encounter count
  rtn <-
    merge(x = rtn
          , y = encounter_status[encounter_status == "active_encounters", .(eclock, active_encounters = N)]
          , by = "eclock"
          , all.x = TRUE
          )
  rtn
}

# Scores/status equal to numeric values
for (j in c("dobutamine_yn"
            , "dopamine_yn"
            , "epinephrine_yn"
            , "milrinone_yn"
            , "norepinephrine_yn"
            , "vasopressin_yn"
            , "pupil"
            , "vent"
            , "possible_sepsis_resp"
            , "possible_sepsis_neuro"
            , "possible_sepsis_cv"
            , "possible_sepsis_total"
            , "possible_sepsis_total_min"
            , "integer_lasso_sepsis_cardiovascular"
            , "integer_lasso_sepsis_cardiovascular_min"
            , "integer_lasso_sepsis_coagulation"
            , "integer_lasso_sepsis_coagulation_min"
            , "integer_lasso_sepsis_neurologic"
            , "integer_lasso_sepsis_neurologic_min"
            , "integer_lasso_sepsis_respiratory"
            , "integer_lasso_sepsis_respiratory_min"
            , "integer_lasso_sepsis_total"
            , "integer_lasso_sepsis_total_min"
            , "La2pt"
            , "lqsofa_total"
            , "pews_cap_refill"
            , "pews_oxygen"
            , "pews_saturation"
            , "pews_tachycardia"
            , "pews_tachypnea"
            , "pews_total"
            , "psofa_neurological"
            , "qsofa_cardiovascular"
            , "qsofa_total"
            ))
{
  integer_lasso_sepsis[[j]][, .N, by = .(value)]
  integer_lasso_sepsis[[j]][, status := fifelse(is.na(value), "Unknown", as.character(value))]
  if (!all(is.na(integer_lasso_sepsis[[j]][["value"]]))) {
    integer_lasso_sepsis[[j]][, status := factor(status, c("Unknown", as.character(0:max(value, na.rm = TRUE))))]
  } else {
    integer_lasso_sepsis[[j]][, status := factor(status)]
  }
  integer_lasso_sepsis[[j]] <- fill_in_missing_combos(DT = integer_lasso_sepsis[[j]])
}

# Scores/Status unknown/know is sufficient
for (j in c("anc", "alc", "bilirubin_tot", "creatinine", "map", "inr", "d_dimer", "fibrinogen", "gcs_total", "glucose", "spo2_for_non_podium", "pao2", "fio2", "o2_flow", "respiratory_rate")) {
  integer_lasso_sepsis[[j]][, .N, by = .(value)]
  integer_lasso_sepsis[[j]][, status := fcase(is.na(value), "Unknown", default = "Known")]
  integer_lasso_sepsis[[j]][, status := factor(status, c("Unknown", "Known"))]
  integer_lasso_sepsis[[j]] <- fill_in_missing_combos(DT = integer_lasso_sepsis[[j]])
}

## Scores/status bespoke binning
integer_lasso_sepsis[["temperature"]]
integer_lasso_sepsis[["temperature"]][, status := fcase(is.na(value), "Unknown", value <= 38, "No Fever", value > 38, "Fever") ]
integer_lasso_sepsis[["temperature"]][, status := factor(status, c("Unknown", "No Fever", "Fever"))]
integer_lasso_sepsis[["temperature"]] <- fill_in_missing_combos(integer_lasso_sepsis[["temperature"]])

integer_lasso_sepsis[["total_antimicrobial_doses"]][value == 0, status := "0"]
integer_lasso_sepsis[["total_antimicrobial_doses"]][value == 1, status := "1"]
integer_lasso_sepsis[["total_antimicrobial_doses"]][value >= 2, status := ">= 2"]
integer_lasso_sepsis[["total_antimicrobial_doses"]][is.na(value), status := "Unknown"]
integer_lasso_sepsis[["total_antimicrobial_doses"]][, status :=factor(status, c("Unknown", "0", "1", ">= 2"))]
integer_lasso_sepsis[["total_antimicrobial_doses"]] <- fill_in_missing_combos( integer_lasso_sepsis[["total_antimicrobial_doses"]])

integer_lasso_sepsis[["total_ordered_tests"]][value == 0, status := "0"]
integer_lasso_sepsis[["total_ordered_tests"]][value >= 1, status := ">= 1"]
integer_lasso_sepsis[["total_ordered_tests"]][is.na(value), status := "Unknown"]
integer_lasso_sepsis[["total_ordered_tests"]][, status :=factor(status, c("Unknown", "0", ">= 1"))]
integer_lasso_sepsis[["total_ordered_tests"]] <- fill_in_missing_combos( integer_lasso_sepsis[["total_ordered_tests"]])


integer_lasso_sepsis[["lactate"]][, .N, by = .(value)]
integer_lasso_sepsis[["lactate"]][, status := fcase(is.na(value), "Unknown",
                                                    value >= 11, ">= 11",
                                                    value >=  5, ">= 5",
                                                    value <   5, "< 5"
                                                    ) ]
integer_lasso_sepsis[["lactate"]][, status := factor(status, c("Unknown", "< 5", ">= 5", ">= 11"))]
integer_lasso_sepsis[["lactate"]] <- fill_in_missing_combos(DT = integer_lasso_sepsis[["lactate"]])


integer_lasso_sepsis[["platelets"]][, .N, by = .(value)]
integer_lasso_sepsis[["platelets"]][, status := fcase(is.na(value), "Unknown",
                                                    value >= 100, ">= 100",
                                                    value <  100, "< 100"
                                                    ) ]
integer_lasso_sepsis[["platelets"]][, status := factor(status, c("Unknown", ">= 100", "< 100"))]
integer_lasso_sepsis[["platelets"]] <- fill_in_missing_combos(DT = integer_lasso_sepsis[["platelets"]])

# Set the ymin and ymax for plotting
set_ymin_ymax <- function(DT, ...) {
  DT[, ymin := cumsum(shift(N/active_encounters, fill = 0)), by = .(eclock)]
  DT[, ymax := cumsum(N/active_encounters), by = .(eclock)]
  DT[, active_encounters_p := active_encounters / max(active_encounters)]
}

for(i in seq_along(integer_lasso_sepsis)) {
  set_ymin_ymax(integer_lasso_sepsis[[i]])
}

# Define plotting method
status_plot <- function(data) {
  nlvls <- nlevels(data[["status"]])
  if (nlvls > 9) {
    status_colors <- colorRampPalette(RColorBrewer::brewer.pal(n = 9, name = "BuPu"))(nlvls)
  } else {
    status_colors <- RColorBrewer::brewer.pal(n = max(c(3, nlvls)), name = "BuPu")
  }
  names(status_colors) <- levels(data[["status"]])
  #
  g <-
    ggplot2::ggplot(data) +
    ggplot2::aes(x = eclock, y = ymin, ymin = ymin, ymax = ymax, fill = status) +
    ggplot2::geom_ribbon(alpha = 0.7) +
    ggplot2::geom_line(mapping = ggplot2::aes(y = active_encounters_p, color = "Active Encounters", fill = NULL)) +
    ggplot2::geom_vline(xintercept = 60 * c(24, 48), linetype = 3) +
    ggplot2::scale_y_continuous(name = "Percent of\nactive encounters"
                                , label = scales::percent
                                , sec.axis = ggplot2::sec_axis(name = "Active Encounters"
                                                               , trans =  ~ . * max(data[["active_encounters"]])
                                                               , label = scales::comma
                                                               )
                                ) +
  ggplot2::scale_color_manual(name = ggplot2::element_blank(), values = c("Active Encounters" = "#000000")) +
  ggplot2::scale_fill_manual(name = ggplot2::element_blank(), values = status_colors) +
  ggplot2::theme(legend.position = "bottom")
  if (max(data[["eclock"]]) <= 60 * 12) {
    g <- g +
    ggplot2::scale_x_continuous(  name = "Time from Hospital Presentation (Hours)"
                                , breaks = seq(0, max(data[["eclock"]]), by = 60)
                                , labels = seq(0, max(data[["eclock"]]), by = 60) %/% 60
                                , minor_breaks = seq(0, max(data[["eclock"]]), by = 30)
                                )
  } else {
    g <- g +
    ggplot2::scale_x_continuous(  name = "Time from Hospital Presentation (Hours)"
                                , breaks = seq(0, max(data[["eclock"]]), by = 12*60)
                                , labels = seq(0, max(data[["eclock"]]), by = 12*60) %/% 60
                                , minor_breaks = seq(0, max(data[["eclock"]]), by = 3 * 60)
                                )
  }
  g
}

save_graphics <- function(x, organ_system, width = 7, height = 3.5, ...) {
  integer_lasso_sepsis[[x]] |>
  status_plot() |>
  print() |>
  ggplot2::ggsave(plot = _
                  , filename = paste0("missingness_", organ_system, "_", x, "_", params$strata_name, ".svg")
                  , width = width
                  , height = height
                  , ...
                  )
}

# Cardiovascular
save_graphics("dobutamine_yn", "Cardiovascular")
save_graphics("dopamine_yn", "Cardiovascular")
save_graphics("epinephrine_yn", "Cardiovascular")
save_graphics("norepinephrine_yn", "Cardiovascular")
save_graphics("milrinone_yn", "Cardiovascular")
save_graphics("norepinephrine_yn", "Cardiovascular")
save_graphics("vasopressin_yn", "Cardiovascular")
save_graphics("lactate", "Cardiovascular")
save_graphics("map", "Cardiovascular")

# Coagulation
save_graphics("platelets", "Coagulation")
save_graphics("inr", "Coagulation")
save_graphics("d_dimer", "Coagulation")
save_graphics("fibrinogen", "Coagulation")

# Neurological
save_graphics("gcs_total", "Neurological")
save_graphics("pupil", "Neurological")

# Respiratory
save_graphics("fio2", "Respiratory")
save_graphics("pao2", "Respiratory")
save_graphics("spo2_for_non_podium", "Respiratory")
save_graphics("vent", "Respiratory")

gridExtra::grid.arrange(
    integer_lasso_sepsis[["lactate"]] |> status_plot() + ggplot2::ggtitle("Lactate")
  , integer_lasso_sepsis[["map"]] |> status_plot() + ggplot2::ggtitle("MAP")
  , integer_lasso_sepsis[["epinephrine_yn"]] |> status_plot() + ggplot2::ggtitle("Epinephrine")
  , integer_lasso_sepsis[["norepinephrine_yn"]] |> status_plot() + ggplot2::ggtitle("Norepinephrine")
  , integer_lasso_sepsis[["vasopressin_yn"]] |> status_plot() + ggplot2::ggtitle("Vasopressin")
  , integer_lasso_sepsis[["dopamine_yn"]] |> status_plot() + ggplot2::ggtitle("Dopamine")
  , integer_lasso_sepsis[["milrinone_yn"]] |> status_plot() + ggplot2::ggtitle("Milrinone")
  , integer_lasso_sepsis[["dobutamine_yn"]] |> status_plot() + ggplot2::ggtitle("Dobutamine")
  , ncol = 2
) |>
ggplot2::ggsave(plot = _
                , file = paste0("missingness_cardiovascular_", params$strata_name, ".svg")
                , width = 7
                , height = 10.0
                )

gridExtra::grid.arrange(
    integer_lasso_sepsis[["pao2"]] |> status_plot() + ggplot2::ggtitle("PaO2")
  , integer_lasso_sepsis[["spo2_for_non_podium"]] |> status_plot() + ggplot2::ggtitle("SpO2")
  , integer_lasso_sepsis[["fio2"]] |> status_plot() + ggplot2::ggtitle("FiO2")
  , integer_lasso_sepsis[["vent"]] |> status_plot() + ggplot2::ggtitle("Ventilation")
  , ncol = 2
) |>
ggplot2::ggsave(plot = _
                , file = paste0("missingness_respiratory_", params$strata_name, ".svg")
                , width = 7
                , height = 5
                )


gridExtra::grid.arrange(
    integer_lasso_sepsis[["gcs_total"]] |> status_plot() + ggplot2::ggtitle("GCS")
  , integer_lasso_sepsis[["pupil"]] |> status_plot() + ggplot2::ggtitle("Pupils")
  , ncol = 2
) |>
ggplot2::ggsave(plot = _
                , file = paste0("missingness_neurological_", params$strata_name, ".svg")
                , width = 7
                , height = 2.5
                )

gridExtra::grid.arrange(
    integer_lasso_sepsis[["platelets"]] |> status_plot() + ggplot2::ggtitle("Platelets")
  , integer_lasso_sepsis[["inr"]] |> status_plot() + ggplot2::ggtitle("INR")
  , integer_lasso_sepsis[["d_dimer"]] |> status_plot() + ggplot2::ggtitle("D-dimer")
  , integer_lasso_sepsis[["fibrinogen"]] |> status_plot() + ggplot2::ggtitle("Fibrinogen")
) |>
ggplot2::ggsave(plot = _
                , file = paste0("missingness_coag_", params$strata_name, ".svg")
                , width = 7
                , height = 5
                )

# Endocrine
save_graphics("glucose", "Endocrine")

# Hepatic
save_graphics("bilirubin_tot", "Hepatic")

# Immunologic
save_graphics("anc", "Immunologic")
save_graphics("alc", "Immunologic")

# Renal
save_graphics("creatinine", "Renal")











################################################################################
##                                  Time to                                   ##

query <-
  "
  WITH la AS
  (
    SELECT t.enc_id, t.eclock, t.integer_lasso_sepsis_total_min
    FROM **REDACTED**.timecourse.integer_lasso_sepsis_total t
    WHERE t.enc_id IN (
      SELECT  enc_id
      FROM `**REDACTED**.sa.strata`
      WHERE sa_subset IN ('SA1', 'SA2g', 'SA2h') AND strata_hash = 'STRATA_HASH'
    ) AND eclock >= 0
  )
  ,
  ps AS
  (
    SELECT t.enc_id, t.eclock, t.possible_sepsis_total_min
    FROM **REDACTED**.timecourse.possible_sepsis t
    WHERE t.enc_id IN (
      SELECT  enc_id
      FROM `**REDACTED**.sa.strata`
      WHERE sa_subset IN ('SA1', 'SA2g', 'SA2h') AND strata_hash = 'STRATA_HASH'
    ) AND eclock >= 0
  )
  SELECT la.*, ps.possible_sepsis_total_min
  FROM la
  LEFT JOIN ps
  ON la.enc_id = ps.enc_id AND la.eclock = ps.eclock
  "
query <- gsub("STRATA_HASH", params$strata_hash, query)
time_to <-
  bq_project_query(project_id, query = query) |>
  bq_table_download() |>
  data.table::setDT()
data.table::setorder(time_to, enc_id, eclock)

timecourse_download <- copy(time_to)
timecourse_download[, length(unique(enc_id))]
timecourse_download[eclock <= 72 * 60 & integer_lasso_sepsis_total_min >= 2, length(unique(enc_id))]
timecourse_download[eclock <= 72 * 60 &integer_lasso_sepsis_total_min >= 2, .(time_to_La2pt = min(eclock)), by = .(enc_id)][, summary(time_to_La2pt)]
timecourse_download[eclock <= 72 * 60 &integer_lasso_sepsis_total_min >= 2, .(time_to_La2pt = min(eclock)), by = .(enc_id)][, summary(time_to_La2pt)/60]

time_to[, La2pt := as.integer(integer_lasso_sepsis_total_min >= 2)]
time_to[, ps1 := as.integer(possible_sepsis_total_min >= 1)]
time_to[, ps2 := as.integer(possible_sepsis_total_min >= 2)]
time_to[, ps3 := as.integer(possible_sepsis_total_min >= 3)]
time_to[, ps4 := as.integer(possible_sepsis_total_min >= 4)]
time_to[, ps5 := as.integer(possible_sepsis_total_min >= 5)]
time_to[, ps6 := as.integer(possible_sepsis_total_min >= 6)]
time_to[, possible_sepsis_total_min := NULL]
time_to <-
  Reduce(f = function(x, y) {merge(x, y, by = "enc_id", all = TRUE)}
         , init = time_to[La2pt > 0, .(La2pt = min(eclock)), by = .(enc_id)]
         , x = list(
                  time_to[ps1 > 0, .(ps1 = min(eclock)), by = .(enc_id)]
                , time_to[ps2 > 0, .(ps2 = min(eclock)), by = .(enc_id)]
                , time_to[ps3 > 0, .(ps3 = min(eclock)), by = .(enc_id)]
                , time_to[ps4 > 0, .(ps4 = min(eclock)), by = .(enc_id)]
                , time_to[ps5 > 0, .(ps5 = min(eclock)), by = .(enc_id)]
                , time_to[ps6 > 0, .(ps6 = min(eclock)), by = .(enc_id)]
                ))


s <- expression(
  .(
      N = qwraps2::frmt(.N)
    , La2pt_never = n_perc(is.na(La2pt))
    , La2pt_03_hour = n_perc(!is.na(La2pt) & La2pt <= 180)
    , La2pt_06_hour = n_perc(!is.na(La2pt) & La2pt <= 360)
    , La2pt_12_hour = n_perc(!is.na(La2pt) & La2pt <= 720)
    , La2pt_72_hour = n_perc(!is.na(La2pt) & La2pt <= 72*60)
    , La2pt_ever = n_perc(!is.na(La2pt)))
)
list(
"Possible Sepsis = 0, ever" = time_to[is.na(ps1), eval(s)]
,
"Possible Sepsis >=1, within 3hr" = time_to[ps1 <= 180, eval(s)]
,
"Possible Sepsis >=2, within 3hr" = time_to[ps2 <= 180, eval(s)]
,
"Possible Sepsis >=3, within 3hr" = time_to[ps3 <= 180, eval(s)]
,
"Possible Sepsis >=4, within 3hr" = time_to[ps4 <= 180, eval(s)]
,
"Possible Sepsis >=5, within 3hr" = time_to[ps5 <= 180, eval(s)]
,
"Possible Sepsis >=6, within 3hr" = time_to[ps6 <= 180, eval(s)]
,
"Possible Sepsis >= 1, ever" = time_to[ps1 <= Inf, eval(s)]
) |>
rbindlist(idcol = "Possible Sepsis") |>
knitr::kable(align = "lrrrrrrr")

time_to[!is.na(La2pt) & is.na(ps1)]



################################################################################
##                                End of File                                 ##
################################################################################
