#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_lasso_sepsis_neurologic` AS
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
      , gcs.gcs_total
      , pupil.pupil
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
    ON tc.site = gcs.site AND tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
    LEFT JOIN `**REDACTED**.timecourse.pupil` pupil
    ON tc.site = pupil.site AND tc.enc_id = pupil.enc_id AND tc.eclock = pupil.eclock
  )
  ,
  t1 AS
  (
    SELECT
        *
      , CASE WHEN pupil = "both-fixed" THEN 2
             WHEN gcs_total <= 10 THEN 1
             WHEN pupil IS NULL OR gcs_total IS NULL THEN NULL
            ELSE 0 END AS integer_lasso_sepsis_neurologic
    FROM t0
  )

  SELECT
      t1.site
    , t1.enc_id
    , t1.eclock

    , t1.pupil
    , t1.gcs_total

    , integer_lasso_sepsis_neurologic
    , COALESCE(integer_lasso_sepsis_neurologic, 0) AS integer_lasso_sepsis_neurologic_min
    , COALESCE(integer_lasso_sepsis_neurologic, 2) AS integer_lasso_sepsis_neurologic_max

    , suspected_infection_0dose * integer_lasso_sepsis_neurologic AS integer_lasso_sepsis_neurologic_0dose
    , COALESCE(suspected_infection_0dose * integer_lasso_sepsis_neurologic, 0) AS integer_lasso_sepsis_neurologic_0dose_min
    , COALESCE(suspected_infection_0dose * integer_lasso_sepsis_neurologic, 2) AS integer_lasso_sepsis_neurologic_0dose_max

    , suspected_infection_1dose * integer_lasso_sepsis_neurologic AS integer_lasso_sepsis_neurologic_1dose
    , COALESCE(suspected_infection_1dose * integer_lasso_sepsis_neurologic, 0) AS integer_lasso_sepsis_neurologic_1dose_min
    , COALESCE(suspected_infection_1dose * integer_lasso_sepsis_neurologic, 2) AS integer_lasso_sepsis_neurologic_1dose_max

    , suspected_infection_2doses * integer_lasso_sepsis_neurologic AS integer_lasso_sepsis_neurologic_2doses
    , COALESCE(suspected_infection_2doses * integer_lasso_sepsis_neurologic, 0) AS integer_lasso_sepsis_neurologic_2doses_min
    , COALESCE(suspected_infection_2doses * integer_lasso_sepsis_neurologic, 2) AS integer_lasso_sepsis_neurologic_2doses_max
  FROM t1
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_neurologic", "integer_lasso_sepsis_neurologic_min");
