#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_renal` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , creatinine.creatinine
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.creatinine` creatinine
    ON tc.site = creatinine.site AND tc.enc_id = creatinine.enc_id AND tc.eclock = creatinine.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS psofa_renal
    FROM
    (
      SELECT site, enc_id, eclock, 4 AS value
      FROM t0
      WHERE (age_months <    1 AND creatinine >= 1.6) OR
            (age_months <   12 AND creatinine >= 1.2) OR
            (age_months <   24 AND creatinine >= 1.5) OR
            (age_months <   60 AND creatinine >= 2.3) OR
            (age_months <  144 AND creatinine >= 2.6) OR
            (age_months <  216 AND creatinine >= 4.2) OR
            (age_months >= 216 AND creatinine >= 5.0)

      UNION ALL

      SELECT site, enc_id, eclock, 3 AS value
      FROM t0
      WHERE (age_months <    1 AND creatinine >= 1.2) OR
            (age_months <   12 AND creatinine >= 0.8) OR
            (age_months <   24 AND creatinine >= 1.1) OR
            (age_months <   60 AND creatinine >= 1.6) OR
            (age_months <  144 AND creatinine >= 1.8) OR
            (age_months <  216 AND creatinine >= 2.9) OR
            (age_months >= 216 AND creatinine >= 3.5)

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months <    1 AND creatinine >= 1.0) OR
            (age_months <   12 AND creatinine >= 0.5) OR
            (age_months <   24 AND creatinine >= 0.6) OR
            (age_months <   60 AND creatinine >= 0.9) OR
            (age_months <  144 AND creatinine >= 1.1) OR
            (age_months <  216 AND creatinine >= 1.7) OR
            (age_months >= 216 AND creatinine >= 2.0)

      UNION ALL

      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (age_months <    1 AND creatinine >= 0.8) OR
            (age_months <   12 AND creatinine >= 0.3) OR
            (age_months <   24 AND creatinine >= 0.4) OR
            (age_months <   60 AND creatinine >= 0.6) OR
            (age_months <  144 AND creatinine >= 0.7) OR
            (age_months <  216 AND creatinine >= 1.0) OR
            (age_months >= 216 AND creatinine >= 1.2)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months <    1 AND creatinine >= 1.6) IS FALSE AND
            (age_months <    1 AND creatinine >= 1.2) IS FALSE AND
            (age_months <    1 AND creatinine >= 1.0) IS FALSE AND
            (age_months <    1 AND creatinine >= 0.8) IS FALSE AND
            (age_months <   12 AND creatinine >= 1.2) IS FALSE AND
            (age_months <   12 AND creatinine >= 0.8) IS FALSE AND
            (age_months <   12 AND creatinine >= 0.5) IS FALSE AND
            (age_months <   12 AND creatinine >= 0.3) IS FALSE AND
            (age_months <   24 AND creatinine >= 1.5) IS FALSE AND
            (age_months <   24 AND creatinine >= 1.1) IS FALSE AND
            (age_months <   24 AND creatinine >= 0.6) IS FALSE AND
            (age_months <   24 AND creatinine >= 0.4) IS FALSE AND
            (age_months <   60 AND creatinine >= 2.3) IS FALSE AND
            (age_months <   60 AND creatinine >= 1.6) IS FALSE AND
            (age_months <   60 AND creatinine >= 0.9) IS FALSE AND
            (age_months <   60 AND creatinine >= 0.6) IS FALSE AND
            (age_months <  144 AND creatinine >= 2.6) IS FALSE AND
            (age_months <  144 AND creatinine >= 1.8) IS FALSE AND
            (age_months <  144 AND creatinine >= 1.1) IS FALSE AND
            (age_months <  144 AND creatinine >= 0.7) IS FALSE AND
            (age_months <  216 AND creatinine >= 4.2) IS FALSE AND
            (age_months <  216 AND creatinine >= 2.9) IS FALSE AND
            (age_months <  216 AND creatinine >= 1.7) IS FALSE AND
            (age_months <  216 AND creatinine >= 1.0) IS FALSE AND
            (age_months >= 216 AND creatinine >= 5.0) IS FALSE AND
            (age_months >= 216 AND creatinine >= 3.5) IS FALSE AND
            (age_months >= 216 AND creatinine >= 2.0) IS FALSE AND
            (age_months >= 216 AND creatinine >= 1.2) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.psofa_renal
    , COALESCE(t.psofa_renal, 0) AS psofa_renal_min
    , COALESCE(t.psofa_renal, 4) AS psofa_renal_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock

)
;
CALL **REDACTED**.sa.aggregate("psofa_renal", "psofa_renal_min");
