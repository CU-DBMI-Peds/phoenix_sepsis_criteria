#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    ,
      proulx_cardiovascular + proulx_respiratory +
      proulx_neurological   + proulx_renal +
      proulx_hepatic        + proulx_heme AS proulx_total
    ,
      proulx_cardiovascular_min + proulx_respiratory_min +
      proulx_neurological_min   + proulx_renal_min +
      proulx_hepatic_min        + proulx_heme_min AS proulx_total_min
    ,
      proulx_cardiovascular_max + proulx_respiratory_max +
      proulx_neurological_max   + proulx_renal_max +
      proulx_hepatic_max        + proulx_heme_max AS proulx_total_max
  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.proulx_cardiovascular` a
  ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock

  LEFT JOIN `**REDACTED**.timecourse.proulx_respiratory` b
  ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock

  LEFT JOIN `**REDACTED**.timecourse.proulx_neurological` c
  ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock

  LEFT JOIN `**REDACTED**.timecourse.proulx_renal` d
  ON tc.site = d.site AND tc.enc_id = d.enc_id AND tc.eclock = d.eclock

  LEFT JOIN `**REDACTED**.timecourse.proulx_hepatic` e
  ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock

  LEFT JOIN `**REDACTED**.timecourse.proulx_heme` f
  ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock

)
;
CALL **REDACTED**.sa.aggregate("proulx_total", "proulx_total_min");
