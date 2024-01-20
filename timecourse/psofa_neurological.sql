#standardSQL

CREATE OR REPLACE TABLe `**REDACTED**.timecourse.psofa_neurological` AS
(
  WITH t AS (
    SELECT enc_id, eclock, MAX(value) AS psofa_neurological
    FROM
    (
      SELECT enc_id, eclock, 4 as value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total < 6
      UNION ALL
      SELECT enc_id, eclock, 3 as value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total < 10
      UNION ALL
      SELECT enc_id, eclock, 2 as value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total < 13
      UNION ALL
      SELECT enc_id, eclock, 1 as value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total < 15
      UNION ALL
      SELECT enc_id, eclock, 0 as value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total >= 15
    )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.psofa_neurological,
    COALESCE(t.psofa_neurological, 0) AS psofa_neurological_min,
    COALESCE(t.psofa_neurological, 4) AS psofa_neurological_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_neurological", "psofa_neurological_min");
