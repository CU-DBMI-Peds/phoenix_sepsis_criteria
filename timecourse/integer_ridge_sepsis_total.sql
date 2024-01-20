#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_total` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock

      , resp.integer_ridge_sepsis_respiratory
      , resp.integer_ridge_sepsis_respiratory_min
      , resp.integer_ridge_sepsis_respiratory_max
      , resp.integer_ridge_sepsis_respiratory_0dose
      , resp.integer_ridge_sepsis_respiratory_0dose_min
      , resp.integer_ridge_sepsis_respiratory_0dose_max
      , resp.integer_ridge_sepsis_respiratory_1dose
      , resp.integer_ridge_sepsis_respiratory_1dose_min
      , resp.integer_ridge_sepsis_respiratory_1dose_max
      , resp.integer_ridge_sepsis_respiratory_2doses
      , resp.integer_ridge_sepsis_respiratory_2doses_min
      , resp.integer_ridge_sepsis_respiratory_2doses_max

      , cardio.integer_ridge_sepsis_cardiovascular
      , cardio.integer_ridge_sepsis_cardiovascular_min
      , cardio.integer_ridge_sepsis_cardiovascular_max
      , cardio.integer_ridge_sepsis_cardiovascular_0dose
      , cardio.integer_ridge_sepsis_cardiovascular_0dose_min
      , cardio.integer_ridge_sepsis_cardiovascular_0dose_max
      , cardio.integer_ridge_sepsis_cardiovascular_1dose
      , cardio.integer_ridge_sepsis_cardiovascular_1dose_min
      , cardio.integer_ridge_sepsis_cardiovascular_1dose_max
      , cardio.integer_ridge_sepsis_cardiovascular_2doses
      , cardio.integer_ridge_sepsis_cardiovascular_2doses_min
      , cardio.integer_ridge_sepsis_cardiovascular_2doses_max

      , renal.integer_ridge_sepsis_renal
      , renal.integer_ridge_sepsis_renal_min
      , renal.integer_ridge_sepsis_renal_max
      , renal.integer_ridge_sepsis_renal_0dose
      , renal.integer_ridge_sepsis_renal_0dose_min
      , renal.integer_ridge_sepsis_renal_0dose_max
      , renal.integer_ridge_sepsis_renal_1dose
      , renal.integer_ridge_sepsis_renal_1dose_min
      , renal.integer_ridge_sepsis_renal_1dose_max
      , renal.integer_ridge_sepsis_renal_2doses
      , renal.integer_ridge_sepsis_renal_2doses_min
      , renal.integer_ridge_sepsis_renal_2doses_max

      , hepatic.integer_ridge_sepsis_hepatic
      , hepatic.integer_ridge_sepsis_hepatic_min
      , hepatic.integer_ridge_sepsis_hepatic_max
      , hepatic.integer_ridge_sepsis_hepatic_0dose
      , hepatic.integer_ridge_sepsis_hepatic_0dose_min
      , hepatic.integer_ridge_sepsis_hepatic_0dose_max
      , hepatic.integer_ridge_sepsis_hepatic_1dose
      , hepatic.integer_ridge_sepsis_hepatic_1dose_min
      , hepatic.integer_ridge_sepsis_hepatic_1dose_max
      , hepatic.integer_ridge_sepsis_hepatic_2doses
      , hepatic.integer_ridge_sepsis_hepatic_2doses_min
      , hepatic.integer_ridge_sepsis_hepatic_2doses_max

      , coag.integer_ridge_sepsis_coagulation
      , coag.integer_ridge_sepsis_coagulation_min
      , coag.integer_ridge_sepsis_coagulation_max
      , coag.integer_ridge_sepsis_coagulation_0dose
      , coag.integer_ridge_sepsis_coagulation_0dose_min
      , coag.integer_ridge_sepsis_coagulation_0dose_max
      , coag.integer_ridge_sepsis_coagulation_1dose
      , coag.integer_ridge_sepsis_coagulation_1dose_min
      , coag.integer_ridge_sepsis_coagulation_1dose_max
      , coag.integer_ridge_sepsis_coagulation_2doses
      , coag.integer_ridge_sepsis_coagulation_2doses_min
      , coag.integer_ridge_sepsis_coagulation_2doses_max

      , endocrine.integer_ridge_sepsis_endocrine
      , endocrine.integer_ridge_sepsis_endocrine_min
      , endocrine.integer_ridge_sepsis_endocrine_max
      , endocrine.integer_ridge_sepsis_endocrine_0dose
      , endocrine.integer_ridge_sepsis_endocrine_0dose_min
      , endocrine.integer_ridge_sepsis_endocrine_0dose_max
      , endocrine.integer_ridge_sepsis_endocrine_1dose
      , endocrine.integer_ridge_sepsis_endocrine_1dose_min
      , endocrine.integer_ridge_sepsis_endocrine_1dose_max
      , endocrine.integer_ridge_sepsis_endocrine_2doses
      , endocrine.integer_ridge_sepsis_endocrine_2doses_min
      , endocrine.integer_ridge_sepsis_endocrine_2doses_max

      , immunologic.integer_ridge_sepsis_immunologic
      , immunologic.integer_ridge_sepsis_immunologic_min
      , immunologic.integer_ridge_sepsis_immunologic_max
      , immunologic.integer_ridge_sepsis_immunologic_0dose
      , immunologic.integer_ridge_sepsis_immunologic_0dose_min
      , immunologic.integer_ridge_sepsis_immunologic_0dose_max
      , immunologic.integer_ridge_sepsis_immunologic_1dose
      , immunologic.integer_ridge_sepsis_immunologic_1dose_min
      , immunologic.integer_ridge_sepsis_immunologic_1dose_max
      , immunologic.integer_ridge_sepsis_immunologic_2doses
      , immunologic.integer_ridge_sepsis_immunologic_2doses_min
      , immunologic.integer_ridge_sepsis_immunologic_2doses_max

      , neuro.integer_ridge_sepsis_neurologic
      , neuro.integer_ridge_sepsis_neurologic_min
      , neuro.integer_ridge_sepsis_neurologic_max
      , neuro.integer_ridge_sepsis_neurologic_0dose
      , neuro.integer_ridge_sepsis_neurologic_0dose_min
      , neuro.integer_ridge_sepsis_neurologic_0dose_max
      , neuro.integer_ridge_sepsis_neurologic_1dose
      , neuro.integer_ridge_sepsis_neurologic_1dose_min
      , neuro.integer_ridge_sepsis_neurologic_1dose_max
      , neuro.integer_ridge_sepsis_neurologic_2doses
      , neuro.integer_ridge_sepsis_neurologic_2doses_min
      , neuro.integer_ridge_sepsis_neurologic_2doses_max

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_respiratory` resp
    ON tc.site = resp.site AND tc.enc_id = resp.enc_id AND tc.eclock = resp.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_cardiovascular` cardio
    ON tc.site = cardio.site AND tc.enc_id = cardio.enc_id AND tc.eclock = cardio.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_renal` renal
    ON tc.site = renal.site AND tc.enc_id = renal.enc_id AND tc.eclock = renal.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_hepatic` hepatic
    ON tc.site = hepatic.site AND tc.enc_id = hepatic.enc_id AND tc.eclock = hepatic.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_coagulation` coag
    ON tc.site = coag.site AND tc.enc_id = coag.enc_id AND tc.eclock = coag.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_endocrine` endocrine
    ON tc.site = endocrine.site AND tc.enc_id = endocrine.enc_id AND tc.eclock = endocrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_immunologic` immunologic
    ON tc.site = immunologic.site AND tc.enc_id = immunologic.enc_id AND tc.eclock = immunologic.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_neurologic` neuro
    ON tc.site = neuro.site AND tc.enc_id = neuro.enc_id AND tc.eclock = neuro.eclock

  )

  SELECT
      site
    , enc_id
    , eclock

    , integer_ridge_sepsis_respiratory            + integer_ridge_sepsis_cardiovascular            + integer_ridge_sepsis_renal            + integer_ridge_sepsis_coagulation            + integer_ridge_sepsis_neurologic             + integer_ridge_sepsis_endocrine           + integer_ridge_sepsis_immunologic             + integer_ridge_sepsis_hepatic AS integer_ridge_sepsis_total
    , integer_ridge_sepsis_respiratory_min        + integer_ridge_sepsis_cardiovascular_min        + integer_ridge_sepsis_renal_min        + integer_ridge_sepsis_coagulation_min        + integer_ridge_sepsis_neurologic_min         + integer_ridge_sepsis_endocrine_min       + integer_ridge_sepsis_immunologic_min         + integer_ridge_sepsis_hepatic_min AS integer_ridge_sepsis_total_min
    , integer_ridge_sepsis_respiratory_max        + integer_ridge_sepsis_cardiovascular_max        + integer_ridge_sepsis_renal_max        + integer_ridge_sepsis_coagulation_max        + integer_ridge_sepsis_neurologic_max         + integer_ridge_sepsis_endocrine_max       + integer_ridge_sepsis_immunologic_max         + integer_ridge_sepsis_hepatic_max AS integer_ridge_sepsis_total_max

    , integer_ridge_sepsis_respiratory_0dose      + integer_ridge_sepsis_cardiovascular_0dose      + integer_ridge_sepsis_renal_0dose      + integer_ridge_sepsis_coagulation_0dose      + integer_ridge_sepsis_neurologic_0dose       + integer_ridge_sepsis_endocrine_0dose     + integer_ridge_sepsis_immunologic_0dose       + integer_ridge_sepsis_hepatic_0dose AS integer_ridge_sepsis_total_0dose
    , integer_ridge_sepsis_respiratory_0dose_min  + integer_ridge_sepsis_cardiovascular_0dose_min  + integer_ridge_sepsis_renal_0dose_min  + integer_ridge_sepsis_coagulation_0dose_min  + integer_ridge_sepsis_neurologic_0dose_min   + integer_ridge_sepsis_endocrine_0dose_min + integer_ridge_sepsis_immunologic_0dose_min   + integer_ridge_sepsis_hepatic_0dose_min AS integer_ridge_sepsis_total_0dose_min
    , integer_ridge_sepsis_respiratory_0dose_max  + integer_ridge_sepsis_cardiovascular_0dose_max  + integer_ridge_sepsis_renal_0dose_max  + integer_ridge_sepsis_coagulation_0dose_max  + integer_ridge_sepsis_neurologic_0dose_max   + integer_ridge_sepsis_endocrine_0dose_max + integer_ridge_sepsis_immunologic_0dose_max   + integer_ridge_sepsis_hepatic_0dose_max AS integer_ridge_sepsis_total_0dose_max

    , integer_ridge_sepsis_respiratory_1dose      + integer_ridge_sepsis_cardiovascular_1dose      + integer_ridge_sepsis_renal_1dose      + integer_ridge_sepsis_coagulation_1dose      + integer_ridge_sepsis_neurologic_1dose       + integer_ridge_sepsis_endocrine_1dose     + integer_ridge_sepsis_immunologic_1dose       + integer_ridge_sepsis_hepatic_1dose AS integer_ridge_sepsis_total_1dose
    , integer_ridge_sepsis_respiratory_1dose_min  + integer_ridge_sepsis_cardiovascular_1dose_min  + integer_ridge_sepsis_renal_1dose_min  + integer_ridge_sepsis_coagulation_1dose_min  + integer_ridge_sepsis_neurologic_1dose_min   + integer_ridge_sepsis_endocrine_1dose_min + integer_ridge_sepsis_immunologic_1dose_min   + integer_ridge_sepsis_hepatic_1dose_min AS integer_ridge_sepsis_total_1dose_min
    , integer_ridge_sepsis_respiratory_1dose_max  + integer_ridge_sepsis_cardiovascular_1dose_max  + integer_ridge_sepsis_renal_1dose_max  + integer_ridge_sepsis_coagulation_1dose_max  + integer_ridge_sepsis_neurologic_1dose_max   + integer_ridge_sepsis_endocrine_1dose_max + integer_ridge_sepsis_immunologic_1dose_max   + integer_ridge_sepsis_hepatic_1dose_max AS integer_ridge_sepsis_total_1dose_max

    , integer_ridge_sepsis_respiratory_2doses     + integer_ridge_sepsis_cardiovascular_2doses     + integer_ridge_sepsis_renal_2doses     + integer_ridge_sepsis_coagulation_2doses     + integer_ridge_sepsis_neurologic_2doses      + integer_ridge_sepsis_endocrine_2doses     + integer_ridge_sepsis_immunologic_2doses     + integer_ridge_sepsis_hepatic_2doses AS integer_ridge_sepsis_total_2doses
    , integer_ridge_sepsis_respiratory_2doses_min + integer_ridge_sepsis_cardiovascular_2doses_min + integer_ridge_sepsis_renal_2doses_min + integer_ridge_sepsis_coagulation_2doses_min + integer_ridge_sepsis_neurologic_2doses_min  + integer_ridge_sepsis_endocrine_2doses_min + integer_ridge_sepsis_immunologic_2doses_min + integer_ridge_sepsis_hepatic_2doses_min AS integer_ridge_sepsis_total_2doses_min
    , integer_ridge_sepsis_respiratory_2doses_max + integer_ridge_sepsis_cardiovascular_2doses_max + integer_ridge_sepsis_renal_2doses_max + integer_ridge_sepsis_coagulation_2doses_max + integer_ridge_sepsis_neurologic_2doses_max  + integer_ridge_sepsis_endocrine_2doses_max + integer_ridge_sepsis_immunologic_2doses_max + integer_ridge_sepsis_hepatic_2doses_max AS integer_ridge_sepsis_total_2doses_max

  FROM t0
)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_total", "integer_ridge_sepsis_total_min");
