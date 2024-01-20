#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_renal` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.baseline_creatinine
      , creatinine.creatinine
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.creatinine` creatinine
    ON tc.site = creatinine.site AND tc.enc_id = creatinine.enc_id AND tc.eclock = creatinine.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_renal
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      /*
        note: score says:
          * Serum creatinine >= 2 times upper limit of normal for age
          * 2-fold increase in baseline creatinine

        however, baseline is based on age normal if person level baseline not available
        so following logic has just one calculation
      */
      WHERE creatinine / baseline_creatinine >= 2

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (creatinine / baseline_creatinine >= 2) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.ipscc_renal
    , COALESCE(t.ipscc_renal, 0) AS ipscc_renal_min
    , COALESCE(t.ipscc_renal, 1) AS ipscc_renal_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock

)
;
CALL **REDACTED**.sa.aggregate("ipscc_renal", "ipscc_renal_min");
