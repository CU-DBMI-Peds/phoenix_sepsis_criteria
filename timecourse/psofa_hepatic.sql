#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_hepatic` AS
(
  WITH t AS
  (
    SELECT enc_id, eclock, MAX(value) as psofa_hepatic
    FROM
    (
      SELECT enc_id, eclock, 4 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot > 12
      UNION ALL
      SELECT enc_id, eclock, 3 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot > 6
      UNION ALL
      SELECT enc_id, eclock, 2 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot > 2
      UNION ALL
      SELECT enc_id, eclock, 1 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot > 1.2
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot IS NOT NULL
    )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.psofa_hepatic,
    COALESCE(t.psofa_hepatic, 0) AS psofa_hepatic_min,
    COALESCE(t.psofa_hepatic, 4) AS psofa_hepatic_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_hepatic", "psofa_hepatic_min");
