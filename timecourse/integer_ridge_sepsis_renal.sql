#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_renal` AS (
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , CASE WHEN                       age_months <    1 AND creatinine.creatinine >= 0.8 THEN 1
             WHEN age_months >=   1 AND age_months <   12 AND creatinine.creatinine >= 0.3 THEN 1
             WHEN age_months >=  12 AND age_months <   24 AND creatinine.creatinine >= 0.4 THEN 1
             WHEN age_months >=  24 AND age_months <   60 AND creatinine.creatinine >= 0.6 THEN 1
             WHEN age_months >=  60 AND age_months <  144 AND creatinine.creatinine >= 0.7 THEN 1
             WHEN age_months >= 144 AND age_months <= 216 AND creatinine.creatinine >= 1.0 THEN 1
             WHEN age_months IS NULL OR creatinine.creatinine IS NULL THEN NULL
            ELSE 0 END AS integer_ridge_sepsis_renal
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.creatinine` creatinine
    ON tc.site = creatinine.site AND tc.enc_id = creatinine.enc_id AND tc.eclock = creatinine.eclock
  )

  SELECT
      t.site
    , t.enc_id
    , t.eclock

    , integer_ridge_sepsis_renal
    , COALESCE(integer_ridge_sepsis_renal, 0) AS integer_ridge_sepsis_renal_min
    , COALESCE(integer_ridge_sepsis_renal, 1) AS integer_ridge_sepsis_renal_max

    , suspected_infection_0dose * integer_ridge_sepsis_renal AS integer_ridge_sepsis_renal_0dose
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_renal, 0) AS integer_ridge_sepsis_renal_0dose_min
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_renal, 1) AS integer_ridge_sepsis_renal_0dose_max

    , suspected_infection_1dose * integer_ridge_sepsis_renal AS integer_ridge_sepsis_renal_1dose
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_renal, 0) AS integer_ridge_sepsis_renal_1dose_min
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_renal, 1) AS integer_ridge_sepsis_renal_1dose_max

    , suspected_infection_2doses * integer_ridge_sepsis_renal AS integer_ridge_sepsis_renal_2doses
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_renal, 0) AS integer_ridge_sepsis_renal_2doses_min
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_renal, 1) AS integer_ridge_sepsis_renal_2doses_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_renal", "integer_ridge_sepsis_renal_min");
