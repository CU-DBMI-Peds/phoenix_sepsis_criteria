#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pews_inflammation` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE
        WHEN temp.temperature IS NULL THEN NULL
        WHEN temp.temperature < 35 THEN 3
        WHEN temp.temperature < 36 THEN 1
        WHEN temp.temperature < 38 THEN 0
        ELSE 1 END AS pews_inflammation

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.temperature` temp
    ON tc.site = temp.site AND tc.enc_id = temp.enc_id AND tc.eclock = temp.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , pews_inflammation
    , COALESCE(pews_inflammation, 0) AS pews_inflammation_min
    , COALESCE(pews_inflammation, 3) AS pews_inflammation_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("pews_inflammation", "pews_inflammation_min");
