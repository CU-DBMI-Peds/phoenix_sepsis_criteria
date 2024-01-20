#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_renal` AS
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
    SELECT site, enc_id, eclock, MAX(value) as pelod2_renal
    FROM
    (
      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months < 1 AND creatinine >= 70 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months < 1 AND creatinine >= 70 * 0.0113) IS FALSE

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months >= 1 AND age_months < 12 AND creatinine >= 23 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months >= 1 AND age_months < 12 AND creatinine >= 23 * 0.0113) IS FALSE

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months >= 12 AND age_months < 24 AND creatinine >= 35 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months >= 12 AND age_months < 24 AND creatinine >= 35 * 0.0113) IS FALSE

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months >= 24 AND age_months < 60 AND creatinine >= 51 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months >= 24 AND age_months < 60 AND creatinine >= 51 * 0.0113) IS FALSE

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months >= 60 AND age_months < 144 AND creatinine >= 59 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months >= 60 AND age_months < 144 AND creatinine >= 59 * 0.0113) IS FALSE

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (age_months >= 144 AND creatinine >= 93 * 0.0113)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (age_months >= 144 AND creatinine >= 93 * 0.0113) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.pelod2_renal
    , COALESCE(t.pelod2_renal, 0) AS pelod2_renal_min
    , COALESCE(t.pelod2_renal, 2) AS pelod2_renal_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("pelod2_renal", "pelod2_renal_min");
