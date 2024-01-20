#standardSQL
-- -------------------------------------------------------------------------- --
-- Build some empty tables to fill in with specific aims data
--
-- Build a foundation table for left-joining onto all the timecourse values.
-- This table should have the site, pat_id, enc_id, all the static variables,
-- and, all the distinct eclock values for each enc_id
--
-- -------------------------------------------------------------------------- --
                          -- Create empty sa tables --
CREATE OR REPLACE TABLE `**REDACTED**.sa.integer_valued_predictors` AS
(
  SELECT
      CAST(NULL AS STRING)  AS site
    , CAST(NULL AS STRING)  AS enc_id
    , CAST(NULL AS STRING)  AS variable
    , CAST(NULL AS INTEGER) AS value
    , CAST(NULL AS DATETIME) AS write_datetime
  LIMIT 0
);

CREATE OR REPLACE TABLE `**REDACTED**.sa.float_valued_predictors` AS
(
  SELECT
      CAST(NULL AS STRING)  AS site
    , CAST(NULL AS STRING)  AS enc_id
    , CAST(NULL AS STRING)  AS variable
    , CAST(NULL AS FLOAT64) AS value
    , CAST(NULL AS DATETIME) AS write_datetime
  LIMIT 0
);

CREATE OR REPLACE TABLE `**REDACTED**.sa.outcomes` AS
(
  SELECT
      CAST(NULL AS STRING)  AS site
    , CAST(NULL AS STRING)  AS enc_id
    , CAST(NULL AS STRING)  AS outcome
    , CAST(NULL AS FLOAT64) AS value
    , CAST(NULL AS DATETIME) AS write_datetime
  LIMIT 0
);

-- -------------------------------------------------------------------------- --
                  -- create the timecourse foundation table --

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.foundation_phase0` AS
(
  WITH
  eclocks AS -- Get all the known times for tests, events, and medications
    (
      SELECT DISTINCT site, enc_id, 0 AS eclock -- this will make an entry for all encounters as there are many encounters without any tests, events, or meds.
      FROM **REDACTED**.harmonized.encounters

      UNION DISTINCT

      SELECT DISTINCT
        site, enc_id, test_ordered_time AS eclock
      FROM `**REDACTED**.harmonized.tests`
      WHERE test_ordered_time IS NOT NULL

      UNION DISTINCT

      SELECT DISTINCT
        site, enc_id, test_obtained_time AS eclock
      FROM `**REDACTED**.harmonized.tests`
      WHERE test_obtained_time IS NOT NULL

      UNION DISTINCT

      SELECT DISTINCT
        site, enc_id, test_result_time AS eclock
      FROM `**REDACTED**.harmonized.tests`
      WHERE test_result_time IS NOT NULL

      UNION DISTINCT

      SELECT DISTINCT site, enc_id, event_time as eclock
      FROM `**REDACTED**.harmonized.observ_interv_events`
      WHERE event_time IS NOT NULL

      UNION DISTINCT

      SELECT DISTINCT site, enc_id, med_admin_time as eclock
      FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_admin_time IS NOT NULL

      UNION DISTINCT

      SELECT DISTINCT site, enc_id, io_time AS eclock
      FROM `**REDACTED**.harmonized.inputs_outputs`
      WHERE io_time IS NOT NULL
    )
  , ages AS
    (
      SELECT
        pat_id,
        enc_id,
        biennial_admission,
        age_days AS admit_age_days,
        (age_days / 365.25) * 12 AS admit_age_months,
        age_days / 365.25 AS admit_age_years
      FROM `**REDACTED**.harmonized.encounters`
    )
  , patients AS
    (
      SELECT pat_id, gender, male, race, ethnicity FROM `**REDACTED**.harmonized.patients`
    )
  , pccc AS
    (
      SELECT enc_id,
        congeni_genetic_prior_to_this_enc AS pccc_congeni_genetic,
        cvd_prior_to_this_enc             AS pccc_cvd,
        gi_prior_to_this_enc              AS pccc_gi,
        hemato_immu_prior_to_this_enc     AS pccc_hemato_immu,
        malignancy_prior_to_this_enc      AS pccc_malignancy,
        metabolic_prior_to_this_enc       AS pccc_metabolic,
        neonatal_prior_to_this_enc        AS pccc_neonatal,
        neuromusc_prior_to_this_enc       AS pccc_neuromusc,
        renal_prior_to_this_enc           AS pccc_renal,
        respiratory_prior_to_this_enc     AS pccc_respiratory,
        tech_dep_prior_to_this_enc        AS pccc_tech_dep,
        transplant_prior_to_this_enc      AS pccc_transplant
      FROM `**REDACTED**.harmonized.pccc_encounters`
    )

  SELECT DISTINCT
      eclocks.site
    , death.pat_id AS pat_id
    , patients.gender
    , patients.male
    , patients.race
    , patients.ethnicity
    , eclocks.enc_id
    , ages.biennial_admission
    , ages.admit_age_days
    , ages.admit_age_months
    , ages.admit_age_years
    , death.death_during_encounter AS death
    , eclocks.eclock
    , 0 AS in_or -- this will be updated
    , CAST(NULL AS STRING) AS eclock_bin
    , ages.admit_age_days   +  (eclocks.eclock / 1440) AS age_days
    , ages.admit_age_months + ((eclocks.eclock / 1440)/365.25)*12 AS age_months
    , ages.admit_age_years  +  (eclocks.eclock / 1440)/365.25 AS age_years
    , pccc.pccc_congeni_genetic
    , pccc.pccc_cvd
    , pccc.pccc_gi
    , pccc.pccc_hemato_immu
    , pccc.pccc_malignancy
    , pccc.pccc_metabolic
    , pccc.pccc_neonatal
    , pccc.pccc_neuromusc
    , pccc.pccc_renal
    , pccc.pccc_respiratory
    , pccc.pccc_tech_dep
    , pccc.pccc_transplant
    , adtes.ever_icu
    , adtes.ever_ed
    , adtes.ever_ip
    , adtes.ever_operation
    , adtes.los
    , CAST(NULL AS FLOAT64) AS baseline_creatinine
  FROM eclocks
  INNER JOIN **REDACTED**.harmonized.death death
  ON eclocks.enc_id = death.enc_id
  INNER JOIN ages
  ON eclocks.enc_id = ages.enc_id
  INNER JOIN patients
  ON death.pat_id = patients.pat_id
  LEFT JOIN pccc
  ON eclocks.enc_id = pccc.enc_id
  LEFT JOIN **REDACTED**.harmonized.adt_encounter_summary adtes
  ON eclocks.site = adtes.site AND eclocks.enc_id = adtes.enc_id

  ORDER BY site, pat_id, age_days, eclock
)
;

-- -------------------------------------------------------------------------- --
                       -- clean up any missing values --
UPDATE `**REDACTED**.timecourse.foundation_phase0`
SET gender = "Not Reported/Non-binary"
WHERE gender IS NULL
;

UPDATE `**REDACTED**.timecourse.foundation_phase0`
SET race = "Unknown/Other"
WHERE race IS NULL
;

UPDATE `**REDACTED**.timecourse.foundation_phase0`
SET ethnicity = "Unavailable or Unknown"
WHERE ethnicity IS NULL
;

-- -------------------------------------------------------------------------- --
              -- Set the eclock_bin and the baseline_creatinine --
UPDATE `**REDACTED**.timecourse.foundation_phase0`
SET eclock_bin =
  CASE
      WHEN eclock =     0     THEN "00 - Admission"
      WHEN eclock <=   60     THEN "01 - (0, 1] hour"
      WHEN eclock <=  180     THEN "02 - (1, 3] hours"
      WHEN eclock <=  360     THEN "03 - (3, 6] hours"
      WHEN eclock <=  720     THEN "04 - (6, 12] hours"
      WHEN eclock <= 1440     THEN "05 - (12, 24] hours"
      WHEN eclock <= 1440 * 2 THEN "06 - (1, 2] days"
      WHEN eclock <= 1440 * 3 THEN "07 - (2, 3] days"
      WHEN eclock <= 1440 * 4 THEN "08 - (3, 4] days"
      WHEN eclock <= 1440 * 5 THEN "09 - (4, 5] days"
      WHEN eclock <= 1440 * 6 THEN "10 - (5, 6] days"
      WHEN eclock <= 1440 * 7 THEN "11 - (6, 7] days"
      WHEN eclock <= 1440 * 7 * 2 THEN "12 - (1, 2] weeks"
      WHEN eclock <= 1440 * 7 * 3 THEN "13 - (2, 3] weeks"
      WHEN eclock <= 1440 * 7 * 4 THEN "14 - (3, 4] weeks"
      WHEN eclock >  1440 * 7 * 4 THEN "15 - after 4 weeks"
      ELSE NULL END
  ,
-- NOTE: when building baseline creatinine the "average" value between the
-- Male and Female is used if gender is not Male or Female.  This is a trade off
-- for the fact that sex is not known, only gender.
  baseline_creatinine =
    CASE
      WHEN age_months <   1 AND gender = "Male"   THEN 0.57
      WHEN age_months <   1 AND gender = "Female" THEN 0.62
      WHEN age_months <   1                       THEN 0.595
      WHEN age_months <   3 AND gender = "Male"   THEN 0.43
      WHEN age_months <   3 AND gender = "Female" THEN 0.46
      WHEN age_months <   3                       THEN 0.445
      WHEN age_months <   6 AND gender = "Male"   THEN 0.35
      WHEN age_months <   6 AND gender = "Female" THEN 0.37
      WHEN age_months <   6                       THEN 0.36
      WHEN age_months <  12 AND gender = "Male"   THEN 0.31
      WHEN age_months <  12 AND gender = "Female" THEN 0.32
      WHEN age_months <  12                       THEN 0.315
      WHEN age_months <  18                       THEN 0.32
      WHEN age_months <  24                       THEN 0.31
      WHEN age_months <  60 AND gender = "Male"   THEN 0.31
      WHEN age_months <  60 AND gender = "Female" THEN 0.30
      WHEN age_months <  60                       THEN 0.305
      WHEN age_months <  96                       THEN 0.37
      WHEN age_months < 144                       THEN 0.46
      WHEN age_months < 216 AND gender = "Male"   THEN 0.65
      WHEN age_months < 216 AND gender = "Female" THEN 0.58
      WHEN age_months < 216                       THEN 0.615
      ELSE NULL END
WHERE TRUE
;

-- -------------------------------------------------------------------------- --
                               -- Update in_or --

UPDATE `**REDACTED**.timecourse.foundation_phase0` tc
SET in_or = 1
WHERE EXISTS
(
  SELECT 1
  FROM `**REDACTED**.harmonized.or_stays` o
  WHERE tc.site = o.site AND tc.enc_id = o.enc_id AND tc.eclock >= o.start_adt_time AND tc.eclock <= o.end_adt_time
)
;

-- -------------------------------------------------------------------------- --

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.foundation` AS
(
  SELECT DISTINCT f.*
  FROM `**REDACTED**.timecourse.foundation_phase0` f
  INNER JOIN (
      SELECT DISTINCT site, enc_id
      FROM `**REDACTED**.harmonized.observ_interv_events`
      WHERE event_time IS NOT NULL
  ) oie
  ON f.site = oie.site AND f.enc_id = oie.enc_id
)
;

-- -------------------------------------------------------------------------- --
                               -- End of File --
-- -------------------------------------------------------------------------- --
