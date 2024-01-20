#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_immunologic` AS (
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , CASE WHEN anc.anc < 0.500 THEN 1  -- units are 10^3cells/mm3
             WHEN alc.alc < 1.000 THEN 1  -- units are 10^3cells/mm3
             WHEN anc.anc IS NULL or alc.alc IS NULL then NULL
            ELSE 0 END AS integer_ridge_sepsis_immunologic

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.anc` anc
    ON tc.site = anc.site AND tc.enc_id = anc.enc_id AND tc.eclock = anc.eclock
    LEFT JOIN `**REDACTED**.timecourse.alc` alc
    ON tc.site = alc.site AND tc.enc_id = alc.enc_id AND tc.eclock = alc.eclock
  )

  SELECT
      t.site
    , t.enc_id
    , t.eclock

    , integer_ridge_sepsis_immunologic
    , COALESCE(integer_ridge_sepsis_immunologic, 0) AS integer_ridge_sepsis_immunologic_min
    , COALESCE(integer_ridge_sepsis_immunologic, 1) AS integer_ridge_sepsis_immunologic_max

    , suspected_infection_0dose * integer_ridge_sepsis_immunologic AS integer_ridge_sepsis_immunologic_0dose
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_immunologic, 0) AS integer_ridge_sepsis_immunologic_0dose_min
    , COALESCE(suspected_infection_0dose * integer_ridge_sepsis_immunologic, 1) AS integer_ridge_sepsis_immunologic_0dose_max

    , suspected_infection_1dose * integer_ridge_sepsis_immunologic AS integer_ridge_sepsis_immunologic_1dose
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_immunologic, 0) AS integer_ridge_sepsis_immunologic_1dose_min
    , COALESCE(suspected_infection_1dose * integer_ridge_sepsis_immunologic, 1) AS integer_ridge_sepsis_immunologic_1dose_max

    , suspected_infection_2doses * integer_ridge_sepsis_immunologic AS integer_ridge_sepsis_immunologic_2doses
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_immunologic, 0) AS integer_ridge_sepsis_immunologic_2doses_min
    , COALESCE(suspected_infection_2doses * integer_ridge_sepsis_immunologic, 1) AS integer_ridge_sepsis_immunologic_2doses_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_immunologic", "integer_ridge_sepsis_immunologic_min");
