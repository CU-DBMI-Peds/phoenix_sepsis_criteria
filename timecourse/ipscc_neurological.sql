#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_neurological` AS
(
  WITH t AS (
    SELECT enc_id, eclock, MAX(value) as ipscc_neurological
    FROM
    (
      SELECT enc_id, eclock, 1 AS value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE gcs_total <= 11
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM `**REDACTED**.timecourse.gcs`
      WHERE (gcs_total <= 11) IS FALSE
    )_
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.ipscc_neurological,
    COALESCE(t.ipscc_neurological, 0) AS ipscc_neurological_min,
    COALESCE(t.ipscc_neurological, 1) AS ipscc_neurological_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_neurological", "ipscc_neurological_min");
