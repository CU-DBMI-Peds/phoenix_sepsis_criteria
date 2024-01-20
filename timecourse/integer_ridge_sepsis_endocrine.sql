#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_endocrine` AS (
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , CASE WHEN glucose.glucose < 50 OR glucose.glucose > 150 THEN 1
             WHEN glucose.glucose IS NULL THEN NULL
            ELSE 0 END AS integer_ridge_sepsis_endocrine

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.glucose` glucose
    ON tc.site = glucose.site AND tc.enc_id = glucose.enc_id AND tc.eclock = glucose.eclock
  )

  SELECT
      t.site
    , t.enc_id
    , t.eclock

    , integer_ridge_sepsis_endocrine
    , COALESCE(integer_ridge_sepsis_endocrine, 0) AS integer_ridge_sepsis_endocrine_min
    , COALESCE(integer_ridge_sepsis_endocrine, 1) AS integer_ridge_sepsis_endocrine_max

    , suspected_infection_0dose * integer_ridge_sepsis_endocrine AS integer_ridge_sepsis_endocrine_0dose
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_endocrine, 0) AS integer_ridge_sepsis_endocrine_0dose_min
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_endocrine, 1) AS integer_ridge_sepsis_endocrine_0dose_max

    , suspected_infection_1dose * integer_ridge_sepsis_endocrine AS integer_ridge_sepsis_endocrine_1dose
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_endocrine, 0) AS integer_ridge_sepsis_endocrine_1dose_min
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_endocrine, 1) AS integer_ridge_sepsis_endocrine_1dose_max

    , suspected_infection_2doses * integer_ridge_sepsis_endocrine AS integer_ridge_sepsis_endocrine_2doses
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_endocrine, 0) AS integer_ridge_sepsis_endocrine_2doses_min
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_endocrine, 1) AS integer_ridge_sepsis_endocrine_2doses_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_endocrine", "integer_ridge_sepsis_endocrine_min");
