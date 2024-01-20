#standardSQL


CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_renal` AS
(
  WITH t0 AS
  (
    SELECT
        a.enc_id
      , a.eclock
      , b.creatinine_delta
      , c.crrt
      , d.weight_delta
      , u.urine_low_6hr
      , u.urine_low_12hr
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.creatinine` b
    ON a.enc_id = b.enc_id AND a.eclock = b.eclock
    LEFT JOIN `**REDACTED**.timecourse.crrt` c
    ON a.enc_id = c.enc_id AND a.eclock = c.eclock
    LEFT JOIN `**REDACTED**.timecourse.weight` d
    ON a.enc_id = d.enc_id AND a.eclock = d.eclock
    LEFT JOIN `**REDACTED**.timecourse.urine` u
    ON a.enc_id = u.enc_id AND a.eclock = u.eclock
  )
  , t AS
  (
    SELECT enc_id, eclock, MAX(value) as podium_renal
    FROM
    (
      SELECT enc_id, eclock, 1 AS value
      FROM t0
      WHERE (creatinine_delta >= 2) OR
            (crrt > 0) OR
            (creatinine_delta >= 1.5 AND creatinine_delta <= 1.9 AND urine_low_6hr = 1) OR
            (urine_low_12hr = 1) OR
            ((weight_delta >= 0.20) AND (eclock >= 2880))
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (creatinine_delta >= 2) OR
            (crrt > 0) OR
            (creatinine_delta >= 1.5 AND creatinine_delta <= 1.9 AND urine_low_6hr = 1) OR
            (urine_low_12hr = 1) OR
            ((weight_delta >= 0.20) AND (eclock >= 2880))
          )
    )
    GROUP BY enc_id, eclock
  )

 SELECT tc.site, tc.enc_id, tc.eclock,
   t.podium_renal,
   COALESCE(t.podium_renal, 0) AS podium_renal_min,
   COALESCE(t.podium_renal, 1) AS podium_renal_max
 FROM `**REDACTED**.timecourse.foundation` tc
 LEFT JOIN t
 ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("podium_renal", "podium_renal_min");
