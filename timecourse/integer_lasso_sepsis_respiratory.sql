#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_lasso_sepsis_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , pfr.pf_ratio
      , sfr.sf_ratio
      , spo2.ok_for_non_podium
      , vent.vent
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` pfr
    ON tc.site = pfr.site AND tc.enc_id = pfr.enc_id AND tc.eclock = pfr.eclock
    LEFT JOIN `**REDACTED**.timecourse.sf_ratio` sfr
    ON tc.site = sfr.site AND tc.enc_id = sfr.enc_id AND tc.eclock = sfr.eclock
    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.site = spo2.site AND tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )
  ,
  t1 AS
  (
    SELECT
        *
      , CASE

             WHEN pf_ratio < 100 AND vent = 1 THEN 3
             WHEN ok_for_non_podium = 1 AND sf_ratio < 148 AND vent = 1 THEN 3

             WHEN pf_ratio < 200 AND vent = 1 THEN 2
             WHEN ok_for_non_podium = 1 AND sf_ratio < 220 AND vent = 1 THEN 2

             WHEN pf_ratio < 400 THEN 1
             WHEN ok_for_non_podium = 1 AND sf_ratio < 292 THEN 1

             WHEN pf_ratio IS NULL OR ok_for_non_podium IS NULL OR sf_ratio IS NULL OR vent IS NULL THEN NULL

            ELSE 0 END AS integer_lasso_sepsis_respiratory

    FROM t0
  )

  SELECT
      t1.site
    , t1.enc_id
    , t1.eclock

    , pf_ratio
    , vent
    , ok_for_non_podium
    , sf_ratio

    , integer_lasso_sepsis_respiratory
    , COALESCE(integer_lasso_sepsis_respiratory, 0) AS integer_lasso_sepsis_respiratory_min
    , COALESCE(integer_lasso_sepsis_respiratory, 3) AS integer_lasso_sepsis_respiratory_max

    , suspected_infection_0dose * integer_lasso_sepsis_respiratory AS integer_lasso_sepsis_respiratory_0dose
    , COALESCE(suspected_infection_0dose * integer_lasso_sepsis_respiratory, 0) AS integer_lasso_sepsis_respiratory_0dose_min
    , COALESCE(suspected_infection_0dose * integer_lasso_sepsis_respiratory, 3) AS integer_lasso_sepsis_respiratory_0dose_max

    , suspected_infection_1dose * integer_lasso_sepsis_respiratory AS integer_lasso_sepsis_respiratory_1dose
    , COALESCE(suspected_infection_1dose * integer_lasso_sepsis_respiratory, 0) AS integer_lasso_sepsis_respiratory_1dose_min
    , COALESCE(suspected_infection_1dose * integer_lasso_sepsis_respiratory, 3) AS integer_lasso_sepsis_respiratory_1dose_max

    , suspected_infection_2doses * integer_lasso_sepsis_respiratory AS integer_lasso_sepsis_respiratory_2doses
    , COALESCE(suspected_infection_2doses * integer_lasso_sepsis_respiratory, 0) AS integer_lasso_sepsis_respiratory_2doses_min
    , COALESCE(suspected_infection_2doses * integer_lasso_sepsis_respiratory, 3) AS integer_lasso_sepsis_respiratory_2doses_max
  FROM t1
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_respiratory", "integer_lasso_sepsis_respiratory_min");
