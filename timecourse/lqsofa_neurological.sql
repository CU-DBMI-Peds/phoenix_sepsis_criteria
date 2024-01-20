#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.lqsofa_neurological` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE WHEN gcs.gcs_total IS NULL THEN NULL
             WHEN gcs.gcs_total <= 13 THEN 1
            ELSE 0 END AS lqsofa_neurological
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
    ON tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , lqsofa_neurological
    , COALESCE(lqsofa_neurological, 0) AS lqsofa_neurological_min
    , COALESCE(lqsofa_neurological, 1) AS lqsofa_neurological_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("lqsofa_neurological", "lqsofa_neurological_min");
