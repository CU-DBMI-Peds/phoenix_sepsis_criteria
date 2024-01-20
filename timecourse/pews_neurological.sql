#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pews_neurological` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE WHEN gcs.gcs_total IS NULL THEN NULL
             WHEN gcs.gcs_total <= 13 THEN 3
            ELSE 0 END AS pews_neurological
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
    ON tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , pews_neurological
    , COALESCE(pews_neurological, 0) AS pews_neurological_min
    , COALESCE(pews_neurological, 3) AS pews_neurological_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("pews_neurological", "pews_neurological_min");
