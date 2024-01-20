#standardSQL
-- Definitions in Table 2 of Goldstein et.al. (2005)

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_sepsis` AS
(
  WITH core_temperature AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN a.temperature > 38.8 THEN 1
           WHEN a.temperature < 36   THEN 1
           WHEN a.temperature IS NULL THEN NULL
           ELSE 0 END AS core_temperature
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.temperature` a
    ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock
  )
  ,
  tachycardia AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN                         tc.age_days   <  7 AND pulse.pulse > 180 THEN 1
           WHEN tc.age_days   >=  7 AND tc.age_months <  1 AND pulse.pulse > 180 THEN 1
           WHEN tc.age_months >=  1 AND tc.age_years  <  1 AND pulse.pulse > 180 THEN 1
           WHEN tc.age_years  >=  1 AND tc.age_years  <  5 AND pulse.pulse > 140 THEN 1
           WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND pulse.pulse > 130 THEN 1
           WHEN tc.age_years  >= 12 AND tc.age_years  < 18 AND pulse.pulse > 110 THEN 1
           WHEN pulse.pulse IS NULL OR tc.age_years IS NULL OR tc.age_months IS NULL OR tc.age_days IS NULL THEN NULL
           ELSE 0 END AS tachycardia,
      CASE WHEN                        tc.age_days   <  7 AND pulse.pulse < 100 THEN 1
           WHEN tc.age_days   >= 7 AND tc.age_months <  1 AND pulse.pulse < 100 THEN 1
           WHEN tc.age_months >= 1 AND tc.age_years  <  1 AND pulse.pulse <  90 THEN 1
           WHEN tc.age_years  >= 1 THEN NULL
           WHEN pulse.pulse IS NULL OR tc.age_years IS NULL OR tc.age_months IS NULL OR tc.age_days IS NULL THEN NULL
           ELSE 0 END AS bradycardia
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
    ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock
  )
  ,
  rr AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN vent.vent = 1 THEN 1
           WHEN                         tc.age_days   <  7 AND rr.respiratory_rate > 50 THEN 1
           WHEN tc.age_days   >=  7 AND tc.age_months <  1 AND rr.respiratory_rate > 40 THEN 1
           WHEN tc.age_months >=  1 AND tc.age_years  <  1 AND rr.respiratory_rate > 34 THEN 1
           WHEN tc.age_years  >=  1 AND tc.age_years  <  5 AND rr.respiratory_rate > 22 THEN 1
           WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND rr.respiratory_rate > 18 THEN 1
           WHEN tc.age_years  >= 12 AND tc.age_years  < 18 AND rr.respiratory_rate > 14 THEN 1
           WHEN vent.vent IS NULL OR rr.respiratory_rate IS NULL then NULL
           ELSE 0 END AS rr
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.respiratory_rate` rr
    ON tc.site = rr.site AND tc.enc_id = rr.enc_id AND tc.eclock = rr.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )
  ,
  wbc AS -- wbc (white blood cells, aka, leukocytes)
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN                         tc.age_days   <  7 AND  wbc.wbc > 34.0                   THEN 1
           WHEN tc.age_days   >=  7 AND tc.age_months <  1 AND (wbc.wbc > 19.5 OR wbc.wbc < 5.0) THEN 1
           WHEN tc.age_months >=  1 AND tc.age_years  <  1 AND (wbc.wbc > 17.5 OR wbc.wbc < 5.0) THEN 1
           WHEN tc.age_years  >=  1 AND tc.age_years  <  5 AND (wbc.wbc > 15.5 OR wbc.wbc < 6.0) THEN 1
           WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (wbc.wbc > 13.5 OR wbc.wbc < 4.5) THEN 1
           WHEN tc.age_years  >= 12 AND tc.age_years  < 18 AND (wbc.wbc > 11.0 OR wbc.wbc < 4.5) THEN 1
           WHEN wbc.wbc IS NULL then NULL
           ELSE 0 END AS wbc
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.wbc` wbc
    ON tc.site = wbc.site AND tc.enc_id = wbc.enc_id AND tc.eclock = wbc.eclock
  )
  ,
  t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE WHEN (COALESCE(core_temperature.core_temperature, 0) + COALESCE(wbc.wbc, 0) >= 1) AND
                  (COALESCE(core_temperature.core_temperature, 0) +
                   COALESCE(tachycardia.tachycardia, 0) +
                   COALESCE(tachycardia.bradycardia, 0) +
                   COALESCE(rr.rr, 0) +
                   COALESCE(wbc.wbc, 0) >= 2) THEN 1
            WHEN core_temperature.core_temperature IS NULL AND wbc.wbc IS NULL THEN NULL
            WHEN core_temperature.core_temperature IS NULL AND wbc.wbc = 0     THEN NULL
            WHEN core_temperature.core_temperature = 0     AND wbc.wbc IS NULL THEN NULL
            ELSE 0 END as ipscc_sirs
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN core_temperature
    ON tc.site = core_temperature.site AND tc.enc_id = core_temperature.enc_id AND tc.eclock = core_temperature.eclock
    LEFT JOIN tachycardia
    ON tc.site = tachycardia.site AND tc.enc_id = tachycardia.enc_id AND tc.eclock = tachycardia.eclock
    LEFT JOIN rr
    ON tc.site = rr.site AND tc.enc_id = rr.enc_id AND tc.eclock = rr.eclock
    LEFT JOIN wbc
    ON tc.site = wbc.site AND tc.enc_id = wbc.enc_id AND tc.eclock = wbc.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , ipscc_sirs
    , COALESCE(ipscc_sirs, 0) AS ipscc_sirs_min
    , COALESCE(ipscc_sirs, 1) AS ipscc_sirs_max
  FROM t
)
;

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_sepsis` AS
(
  WITH sepsis AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , COALESCE(sirs.ipscc_sirs, 0) AS ipscc_sirs
      , COALESCE(sirs.ipscc_sirs * si.suspected_infection_0dose, 0)  AS ipscc_sepsis_0dose
      , COALESCE(sirs.ipscc_sirs * si.suspected_infection_1dose, 0)  AS ipscc_sepsis_1dose
      , COALESCE(sirs.ipscc_sirs * si.suspected_infection_2doses, 0) AS ipscc_sepsis_2doses
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.ipscc_sepsis` sirs
    ON tc.enc_id = sirs.enc_id AND tc.eclock = sirs.eclock

    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.enc_id = si.enc_id AND tc.eclock = si.eclock
  )

  SELECT
      sepsis.site
    , sepsis.enc_id
    , sepsis.eclock

    -- Only need to select these columns if/when interactive qa/qc work
    --, ipscc_cardiovascular_06_min
    --, ipscc_cardiovascular_12_min
    --, ipscc_respiratory_min
    --, ipscc_heme_min
    --, ipscc_hepatic_min
    --, ipscc_neurological_min
    --, ipscc_renal_min

    , sepsis.ipscc_sirs
    , sepsis.ipscc_sepsis_0dose
    , sepsis.ipscc_sepsis_1dose
    , sepsis.ipscc_sepsis_2doses

    , sepsis.ipscc_sepsis_0dose * IF((ipscc_cardiovascular_06_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_06_0dose
    , sepsis.ipscc_sepsis_0dose * IF((ipscc_cardiovascular_12_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_12_0dose

    , sepsis.ipscc_sepsis_1dose * IF((ipscc_cardiovascular_06_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_06_1dose
    , sepsis.ipscc_sepsis_1dose * IF((ipscc_cardiovascular_12_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_12_1dose

    , sepsis.ipscc_sepsis_2doses * IF((ipscc_cardiovascular_06_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_06_2doses
    , sepsis.ipscc_sepsis_2doses * IF((ipscc_cardiovascular_12_min + ipscc_respiratory_min >= 1) OR (ipscc_heme_min + ipscc_hepatic_min + ipscc_neurological_min + ipscc_renal_min >= 2), 1, 0) AS ipscc_severe_sepsis_12_2doses

    , ipscc_sepsis_0dose * ipscc_cardiovascular_06_min AS ipscc_septic_shock_06_0dose
    , ipscc_sepsis_0dose * ipscc_cardiovascular_12_min AS ipscc_septic_shock_12_0dose

    , ipscc_sepsis_1dose * ipscc_cardiovascular_06_min AS ipscc_septic_shock_06_1dose
    , ipscc_sepsis_1dose * ipscc_cardiovascular_12_min AS ipscc_septic_shock_12_1dose

    , ipscc_sepsis_2doses * ipscc_cardiovascular_06_min AS ipscc_septic_shock_06_2doses
    , ipscc_sepsis_2doses * ipscc_cardiovascular_12_min AS ipscc_septic_shock_12_2doses

  FROM sepsis

  LEFT JOIN `**REDACTED**.timecourse.ipscc_cardiovascular` cardiovascular
  ON sepsis.site = cardiovascular.site AND sepsis.enc_id = cardiovascular.enc_id AND sepsis.eclock = cardiovascular.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_heme` heme
  ON sepsis.site = heme.site AND sepsis.enc_id = heme.enc_id AND sepsis.eclock = heme.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_hepatic` hepatic
  ON sepsis.site = hepatic.site AND sepsis.enc_id = hepatic.enc_id AND sepsis.eclock = hepatic.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_neurological` neurological
  ON sepsis.site = neurological.site AND sepsis.enc_id = neurological.enc_id AND sepsis.eclock = neurological.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_renal` renal
  ON sepsis.site = renal.site AND sepsis.enc_id = renal.enc_id AND sepsis.eclock = renal.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_respiratory` respiratory
  ON sepsis.site = respiratory.site AND sepsis.enc_id = respiratory.enc_id AND sepsis.eclock = respiratory.eclock

)
;

/* Query to help with QA/QC
SELECT
    ipscc_sirs
  , ipscc_sepsis_1dose
  , ipscc_severe_sepsis_06_1dose
  , ipscc_septic_shock_06_1dose
  , count(1) AS N
FROM `**REDACTED**.timecourse.ipscc_sepsis`
GROUP BY ipscc_sirs, ipscc_sepsis_1dose, ipscc_severe_sepsis_06_1dose, ipscc_septic_shock_06_1dose
ORDER BY ipscc_sirs, ipscc_sepsis_1dose, ipscc_severe_sepsis_06_1dose, ipscc_septic_shock_06_1dose
;

SELECT
    ipscc_cardiovascular_06_min
  , ipscc_respiratory_min
  , ipscc_heme_min
  , ipscc_hepatic_min
  , ipscc_neurological_min
  , ipscc_renal_min
  , ipscc_sirs
  , ipscc_sepsis_1dose
  , ipscc_severe_sepsis_06_1dose
  , ipscc_septic_shock_06_1dose
FROM `**REDACTED**.timecourse.ipscc_sepsis`
WHERE ipscc_septic_shock_06_1dose > ipscc_severe_sepsis_06_1dose
;
*/

SELECT IF(ipscc_septic_shock_06_0dose > ipscc_severe_sepsis_06_0dose,   ERROR("Shock not a subset of severe 06 0dose"), "PASS")  FROM `**REDACTED**.timecourse.ipscc_sepsis`;
SELECT IF(ipscc_septic_shock_06_1dose > ipscc_severe_sepsis_06_1dose,   ERROR("Shock not a subset of severe 06 1dose"), "PASS")  FROM `**REDACTED**.timecourse.ipscc_sepsis`;
SELECT IF(ipscc_septic_shock_06_2doses > ipscc_severe_sepsis_06_2doses, ERROR("Shock not a subset of severe 06 2doses"), "PASS") FROM `**REDACTED**.timecourse.ipscc_sepsis`;

SELECT IF(ipscc_septic_shock_12_0dose > ipscc_severe_sepsis_12_0dose,   ERROR("Shock not a subset of severe 12 0dose"), "PASS")  FROM `**REDACTED**.timecourse.ipscc_sepsis`;
SELECT IF(ipscc_septic_shock_12_1dose > ipscc_severe_sepsis_12_1dose,   ERROR("Shock not a subset of severe 12 1dose"), "PASS")  FROM `**REDACTED**.timecourse.ipscc_sepsis`;
SELECT IF(ipscc_septic_shock_12_2doses > ipscc_severe_sepsis_12_2doses, ERROR("Shock not a subset of severe 12 2doses"), "PASS") FROM `**REDACTED**.timecourse.ipscc_sepsis`;

CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_sirs");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_sepsis_0dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_sepsis_1dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_sepsis_2doses");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_06_0dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_06_1dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_06_2doses");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_12_0dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_12_1dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_severe_sepsis_12_2doses");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_06_0dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_06_1dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_06_2doses");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_12_0dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_12_1dose");
CALL **REDACTED**.sa.aggregate("ipscc_sepsis", "ipscc_septic_shock_12_2doses");
