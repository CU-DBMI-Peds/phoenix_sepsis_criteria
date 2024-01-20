#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_hepatic` AS (
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , CASE WHEN bilirubin_tot.bilirubin_tot >= 4 OR alt.alt > 102 THEN 1
             WHEN bilirubin_tot.bilirubin_tot IS NULL OR alt.alt IS NULL THEN NULL
            ELSE 0 END AS integer_ridge_sepsis_hepatic

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.bilirubin_tot` bilirubin_tot
    ON tc.site = bilirubin_tot.site AND tc.enc_id = bilirubin_tot.enc_id AND tc.eclock = bilirubin_tot.eclock
    LEFT JOIN `**REDACTED**.timecourse.alt` alt
    ON tc.site = alt.site AND tc.enc_id = alt.enc_id AND tc.eclock = alt.eclock
  )

  SELECT
      t.site
    , t.enc_id
    , t.eclock

    , integer_ridge_sepsis_hepatic
    , COALESCE(integer_ridge_sepsis_hepatic, 0) AS integer_ridge_sepsis_hepatic_min
    , COALESCE(integer_ridge_sepsis_hepatic, 1) AS integer_ridge_sepsis_hepatic_max

    , suspected_infection_0dose * integer_ridge_sepsis_hepatic AS integer_ridge_sepsis_hepatic_0dose
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_hepatic, 0) AS integer_ridge_sepsis_hepatic_0dose_min
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_hepatic, 1) AS integer_ridge_sepsis_hepatic_0dose_max

    , suspected_infection_1dose * integer_ridge_sepsis_hepatic AS integer_ridge_sepsis_hepatic_1dose
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_hepatic, 0) AS integer_ridge_sepsis_hepatic_1dose_min
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_hepatic, 1) AS integer_ridge_sepsis_hepatic_1dose_max

    , suspected_infection_2doses * integer_ridge_sepsis_hepatic AS integer_ridge_sepsis_hepatic_2doses
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_hepatic, 0) AS integer_ridge_sepsis_hepatic_2doses_min
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_hepatic, 1) AS integer_ridge_sepsis_hepatic_2doses_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_hepatic", "integer_ridge_sepsis_hepatic_min");
