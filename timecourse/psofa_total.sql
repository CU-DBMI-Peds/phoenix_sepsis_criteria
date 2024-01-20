#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    ,
      psofa_cardiovascular + psofa_respiratory +
      psofa_neurological   + psofa_renal +
      psofa_hepatic        + psofa_coagulation AS psofa_total
    ,
      psofa_cardiovascular_min + psofa_respiratory_min +
      psofa_neurological_min   + psofa_renal_min +
      psofa_hepatic_min        + psofa_coagulation_min AS psofa_total_min
    ,
      psofa_cardiovascular_max + psofa_respiratory_max +
      psofa_neurological_max   + psofa_renal_max +
      psofa_hepatic_max        + psofa_coagulation_max AS psofa_total_max

  FROM `**REDACTED**.timecourse.foundation` tc

  LEFT JOIN `**REDACTED**.timecourse.psofa_cardiovascular` a
  ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock
  LEFT JOIN `**REDACTED**.timecourse.psofa_respiratory` b
  ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock
  LEFT JOIN `**REDACTED**.timecourse.psofa_neurological` c
  ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock
  LEFT JOIN `**REDACTED**.timecourse.psofa_renal` d
  ON tc.site = d.site AND tc.enc_id = d.enc_id AND tc.eclock = d.eclock
  LEFT JOIN `**REDACTED**.timecourse.psofa_hepatic` e
  ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock
  LEFT JOIN `**REDACTED**.timecourse.psofa_coagulation` f
  ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_total", "psofa_total_min");
