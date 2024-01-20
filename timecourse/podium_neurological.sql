#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_neurological` AS
(
  WITH t0 AS
  (
    SELECT a.enc_id, a.eclock, b.gcs_total, b.gcs_motor
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.gcs` b
    ON a.enc_id = b.enc_id AND a.eclock = b.eclock
  )
  , t AS
  (
    SELECT enc_id, eclock, MAX(value) as podium_neurological
    FROM
    (
      SELECT enc_id, eclock, 1 AS value
      FROM t0
      WHERE gcs_total <= 8
      UNION ALL
      SELECT enc_id, eclock, 1 AS value
      FROM t0
      WHERE gcs_motor <= 4
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM t0
      WHERE (gcs_total <= 8) IS FALSE AND (gcs_motor <= 4) IS FALSE
    )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.podium_neurological,
    COALESCE(t.podium_neurological, 0) AS podium_neurological_min,
    COALESCE(t.podium_neurological, 1) AS podium_neurological_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock

)
;
CALL **REDACTED**.sa.aggregate("podium_neurological", "podium_neurological_min");
