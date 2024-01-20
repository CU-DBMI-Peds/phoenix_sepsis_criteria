#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pews_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , pews_cardiovascular     + pews_inflammation     + pews_respiratory     + pews_neurological     AS pews_total
    , pews_cardiovascular_min + pews_inflammation_min + pews_respiratory_min + pews_neurological_min AS pews_total_min
    , pews_cardiovascular_max + pews_inflammation_max + pews_respiratory_max + pews_neurological_max AS pews_total_max
  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.pews_cardiovascular` cardio
  ON tc.site = cardio.site AND tc.enc_id = cardio.enc_id AND tc.eclock = cardio.eclock

  LEFT JOIN `**REDACTED**.timecourse.pews_respiratory` resp
  ON tc.site = resp.site AND tc.enc_id = resp.enc_id AND tc.eclock = resp.eclock

  LEFT JOIN `**REDACTED**.timecourse.pews_neurological` neuro
  ON tc.site = neuro.site AND tc.enc_id = neuro.enc_id AND tc.eclock = neuro.eclock

  LEFT JOIN `**REDACTED**.timecourse.pews_inflammation` inflammation
  ON tc.site = inflammation.site AND tc.enc_id = inflammation.enc_id AND tc.eclock = inflammation.eclock

)
;
CALL **REDACTED**.sa.aggregate("pews_total", "pews_total_min");
