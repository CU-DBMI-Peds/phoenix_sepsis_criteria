#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.lqsofa_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , lqsofa_cardiovascular     + lqsofa_respiratory     + lqsofa_neurological     AS lqsofa_total
    , lqsofa_cardiovascular_min + lqsofa_respiratory_min + lqsofa_neurological_min AS lqsofa_total_min
    , lqsofa_cardiovascular_max + lqsofa_respiratory_max + lqsofa_neurological_max AS lqsofa_total_max
  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.lqsofa_cardiovascular` a
  ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock

  LEFT JOIN `**REDACTED**.timecourse.lqsofa_respiratory` b
  ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock

  LEFT JOIN `**REDACTED**.timecourse.lqsofa_neurological` c
  ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock
)
;
CALL **REDACTED**.sa.aggregate("lqsofa_total", "lqsofa_total_min");
