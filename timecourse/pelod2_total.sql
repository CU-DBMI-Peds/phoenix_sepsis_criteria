#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , pelod2_cardiovascular     + pelod2_respiratory     + pelod2_neurological     + pelod2_renal     + pelod2_heme     AS pelod2_total
    , pelod2_cardiovascular_min + pelod2_respiratory_min + pelod2_neurological_min + pelod2_renal_min + pelod2_heme_min AS pelod2_total_min
    , pelod2_cardiovascular_max + pelod2_respiratory_max + pelod2_neurological_max + pelod2_renal_max + pelod2_heme_max AS pelod2_total_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN `**REDACTED**.timecourse.pelod2_cardiovascular` cardio
  ON tc.site = cardio.site AND tc.enc_id = cardio.enc_id AND tc.eclock = cardio.eclock
  LEFT JOIN `**REDACTED**.timecourse.pelod2_respiratory` resp
  ON tc.site = resp.site AND tc.enc_id = resp.enc_id AND tc.eclock = resp.eclock
  LEFT JOIN `**REDACTED**.timecourse.pelod2_neurological` neuro
  ON tc.site = neuro.site AND tc.enc_id = neuro.enc_id AND tc.eclock = neuro.eclock
  LEFT JOIN `**REDACTED**.timecourse.pelod2_renal` renal
  ON tc.site = renal.site AND tc.enc_id = renal.enc_id AND tc.eclock = renal.eclock
  LEFT JOIN `**REDACTED**.timecourse.pelod2_heme` heme
  ON tc.site = heme.site AND tc.enc_id = heme.enc_id AND tc.eclock = heme.eclock
)
;
CALL **REDACTED**.sa.aggregate("pelod2_total", "pelod2_total_min");
