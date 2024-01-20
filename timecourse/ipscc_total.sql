#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    ,
      ipscc_cardiovascular_06 + ipscc_respiratory +
      ipscc_neurological      + ipscc_renal +
      ipscc_hepatic           + ipscc_heme AS ipscc_total_06
    ,
      ipscc_cardiovascular_06_min + ipscc_respiratory_min +
      ipscc_neurological_min      + ipscc_renal_min +
      ipscc_hepatic_min           + ipscc_heme_min AS ipscc_total_06_min
    ,
      ipscc_cardiovascular_06_max + ipscc_respiratory_max +
      ipscc_neurological_max      + ipscc_renal_max +
      ipscc_hepatic_max           + ipscc_heme_max AS ipscc_total_06_max
    ,
      ipscc_cardiovascular_12 + ipscc_respiratory +
      ipscc_neurological      + ipscc_renal +
      ipscc_hepatic           + ipscc_heme AS ipscc_total_12
    ,
      ipscc_cardiovascular_12_min + ipscc_respiratory_min +
      ipscc_neurological_min      + ipscc_renal_min +
      ipscc_hepatic_min           + ipscc_heme_min AS ipscc_total_12_min
    ,
      ipscc_cardiovascular_12_max + ipscc_respiratory_max +
      ipscc_neurological_max      + ipscc_renal_max +
      ipscc_hepatic_max           + ipscc_heme_max AS ipscc_total_12_max
  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.ipscc_cardiovascular` a
  ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_respiratory` b
  ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_neurological` c
  ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_renal` d
  ON tc.site = d.site AND tc.enc_id = d.enc_id AND tc.eclock = d.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_hepatic` e
  ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock

  LEFT JOIN `**REDACTED**.timecourse.ipscc_heme` f
  ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_total", "ipscc_total_06_min");
CALL **REDACTED**.sa.aggregate("ipscc_total", "ipscc_total_12_min");
