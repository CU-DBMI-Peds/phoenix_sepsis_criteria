#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.qsofa_neurological` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE WHEN gcs.gcs_total IS NULL THEN NULL
             WHEN gcs.gcs_total < 15 THEN 1
             WHEN gcs.gcs_total = 15 THEN 0
            END AS qsofa_neurological
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
    ON tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , qsofa_neurological
    , COALESCE(qsofa_neurological, 0) AS qsofa_neurological_min
    , COALESCE(qsofa_neurological, 1) AS qsofa_neurological_max
  FROM t
)
;

CALL **REDACTED**.sa.aggregate("qsofa_neurological", "qsofa_neurological_min");
