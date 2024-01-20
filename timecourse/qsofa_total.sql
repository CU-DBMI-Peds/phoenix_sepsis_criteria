#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.qsofa_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , qsofa_cardiovascular     + qsofa_tachypnea     + qsofa_neurological     AS qsofa_total
    , qsofa_cardiovascular_min + qsofa_tachypnea_min + qsofa_neurological_min AS qsofa_total_min
    , qsofa_cardiovascular_max + qsofa_tachypnea_max + qsofa_neurological_max AS qsofa_total_max
  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.qsofa_cardiovascular` cardio
  ON tc.site = cardio.site AND tc.enc_id = cardio.enc_id AND tc.eclock = cardio.eclock
  LEFT JOIN `**REDACTED**.timecourse.qsofa_tachypnea`tachypnea
  ON tc.site = tachypnea.site AND tc.enc_id = tachypnea.enc_id AND tc.eclock = tachypnea.eclock
  LEFT JOIN `**REDACTED**.timecourse.qsofa_neurological` neuro
  ON tc.site = neuro.site AND tc.enc_id = neuro.enc_id AND tc.eclock = neuro.eclock
)
;
CALL **REDACTED**.sa.aggregate("qsofa_total", "qsofa_total_min");
