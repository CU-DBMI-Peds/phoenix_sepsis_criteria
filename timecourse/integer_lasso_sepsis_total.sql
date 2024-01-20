#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_lasso_sepsis_total` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock

      , resp.integer_lasso_sepsis_respiratory
      , resp.integer_lasso_sepsis_respiratory_min
      , resp.integer_lasso_sepsis_respiratory_max
      , resp.integer_lasso_sepsis_respiratory_0dose
      , resp.integer_lasso_sepsis_respiratory_0dose_min
      , resp.integer_lasso_sepsis_respiratory_0dose_max
      , resp.integer_lasso_sepsis_respiratory_1dose
      , resp.integer_lasso_sepsis_respiratory_1dose_min
      , resp.integer_lasso_sepsis_respiratory_1dose_max
      , resp.integer_lasso_sepsis_respiratory_2doses
      , resp.integer_lasso_sepsis_respiratory_2doses_min
      , resp.integer_lasso_sepsis_respiratory_2doses_max

      , cardio.integer_lasso_sepsis_cardiovascular
      , cardio.integer_lasso_sepsis_cardiovascular_min
      , cardio.integer_lasso_sepsis_cardiovascular_max
      , cardio.integer_lasso_sepsis_cardiovascular_0dose
      , cardio.integer_lasso_sepsis_cardiovascular_0dose_min
      , cardio.integer_lasso_sepsis_cardiovascular_0dose_max
      , cardio.integer_lasso_sepsis_cardiovascular_1dose
      , cardio.integer_lasso_sepsis_cardiovascular_1dose_min
      , cardio.integer_lasso_sepsis_cardiovascular_1dose_max
      , cardio.integer_lasso_sepsis_cardiovascular_2doses
      , cardio.integer_lasso_sepsis_cardiovascular_2doses_min
      , cardio.integer_lasso_sepsis_cardiovascular_2doses_max

      , coag.integer_lasso_sepsis_coagulation
      , coag.integer_lasso_sepsis_coagulation_min
      , coag.integer_lasso_sepsis_coagulation_max
      , coag.integer_lasso_sepsis_coagulation_0dose
      , coag.integer_lasso_sepsis_coagulation_0dose_min
      , coag.integer_lasso_sepsis_coagulation_0dose_max
      , coag.integer_lasso_sepsis_coagulation_1dose
      , coag.integer_lasso_sepsis_coagulation_1dose_min
      , coag.integer_lasso_sepsis_coagulation_1dose_max
      , coag.integer_lasso_sepsis_coagulation_2doses
      , coag.integer_lasso_sepsis_coagulation_2doses_min
      , coag.integer_lasso_sepsis_coagulation_2doses_max

      , neuro.integer_lasso_sepsis_neurologic
      , neuro.integer_lasso_sepsis_neurologic_min
      , neuro.integer_lasso_sepsis_neurologic_max
      , neuro.integer_lasso_sepsis_neurologic_0dose
      , neuro.integer_lasso_sepsis_neurologic_0dose_min
      , neuro.integer_lasso_sepsis_neurologic_0dose_max
      , neuro.integer_lasso_sepsis_neurologic_1dose
      , neuro.integer_lasso_sepsis_neurologic_1dose_min
      , neuro.integer_lasso_sepsis_neurologic_1dose_max
      , neuro.integer_lasso_sepsis_neurologic_2doses
      , neuro.integer_lasso_sepsis_neurologic_2doses_min
      , neuro.integer_lasso_sepsis_neurologic_2doses_max

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.integer_lasso_sepsis_respiratory` resp
    ON tc.site = resp.site AND tc.enc_id = resp.enc_id AND tc.eclock = resp.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_lasso_sepsis_cardiovascular` cardio
    ON tc.site = cardio.site AND tc.enc_id = cardio.enc_id AND tc.eclock = cardio.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_lasso_sepsis_coagulation` coag
    ON tc.site = coag.site AND tc.enc_id = coag.enc_id AND tc.eclock = coag.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_lasso_sepsis_neurologic` neuro
    ON tc.site = neuro.site AND tc.enc_id = neuro.enc_id AND tc.eclock = neuro.eclock

  )

  SELECT
      site
    , enc_id
    , eclock
    , integer_lasso_sepsis_respiratory     + integer_lasso_sepsis_cardiovascular     + integer_lasso_sepsis_coagulation     + integer_lasso_sepsis_neurologic     AS integer_lasso_sepsis_total
    , integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min AS integer_lasso_sepsis_total_min
    , integer_lasso_sepsis_respiratory_max + integer_lasso_sepsis_cardiovascular_max + integer_lasso_sepsis_coagulation_max + integer_lasso_sepsis_neurologic_max AS integer_lasso_sepsis_total_max

    , IF(integer_lasso_sepsis_cardiovascular_min >= 1, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv1_min
    , IF(integer_lasso_sepsis_cardiovascular_min >= 2, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv2_min
    , IF(integer_lasso_sepsis_cardiovascular_min >= 3, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv3_min
    , IF(integer_lasso_sepsis_cardiovascular_min >= 4, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv4_min
    , IF(integer_lasso_sepsis_cardiovascular_min >= 5, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv5_min
    , IF(integer_lasso_sepsis_cardiovascular_min >= 6, integer_lasso_sepsis_respiratory_min + integer_lasso_sepsis_cardiovascular_min + integer_lasso_sepsis_coagulation_min + integer_lasso_sepsis_neurologic_min, 0) AS integer_lasso_sepsis_total_cv6_min

    , integer_lasso_sepsis_respiratory_0dose     + integer_lasso_sepsis_cardiovascular_0dose     + integer_lasso_sepsis_coagulation_0dose     + integer_lasso_sepsis_neurologic_0dose     AS integer_lasso_sepsis_total_0dose
    , integer_lasso_sepsis_respiratory_0dose_min + integer_lasso_sepsis_cardiovascular_0dose_min + integer_lasso_sepsis_coagulation_0dose_min + integer_lasso_sepsis_neurologic_0dose_min AS integer_lasso_sepsis_total_0dose_min
    , integer_lasso_sepsis_respiratory_0dose_max + integer_lasso_sepsis_cardiovascular_0dose_max + integer_lasso_sepsis_coagulation_0dose_max + integer_lasso_sepsis_neurologic_0dose_max AS integer_lasso_sepsis_total_0dose_max
    , integer_lasso_sepsis_respiratory_1dose     + integer_lasso_sepsis_cardiovascular_1dose     + integer_lasso_sepsis_coagulation_1dose     + integer_lasso_sepsis_neurologic_1dose     AS integer_lasso_sepsis_total_1dose
    , integer_lasso_sepsis_respiratory_1dose_min + integer_lasso_sepsis_cardiovascular_1dose_min + integer_lasso_sepsis_coagulation_1dose_min + integer_lasso_sepsis_neurologic_1dose_min AS integer_lasso_sepsis_total_1dose_min
    , integer_lasso_sepsis_respiratory_1dose_max + integer_lasso_sepsis_cardiovascular_1dose_max + integer_lasso_sepsis_coagulation_1dose_max + integer_lasso_sepsis_neurologic_1dose_max AS integer_lasso_sepsis_total_1dose_max
    , integer_lasso_sepsis_respiratory_2doses     + integer_lasso_sepsis_cardiovascular_2doses     + integer_lasso_sepsis_coagulation_2doses     + integer_lasso_sepsis_neurologic_2doses     AS integer_lasso_sepsis_total_2doses
    , integer_lasso_sepsis_respiratory_2doses_min + integer_lasso_sepsis_cardiovascular_2doses_min + integer_lasso_sepsis_coagulation_2doses_min + integer_lasso_sepsis_neurologic_2doses_min AS integer_lasso_sepsis_total_2doses_min
    , integer_lasso_sepsis_respiratory_2doses_max + integer_lasso_sepsis_cardiovascular_2doses_max + integer_lasso_sepsis_coagulation_2doses_max + integer_lasso_sepsis_neurologic_2doses_max AS integer_lasso_sepsis_total_2doses_max

  FROM t0
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv1_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv2_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv3_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv4_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv5_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_cv6_min");
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_total", "integer_lasso_sepsis_total_min");
