#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pf_ratio` AS
(
  WITH t0 AS
  ( SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , a.fio2
      , a.fio2_time
      , b.pao2
      , b.pao2_time
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.fio2` a
    ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock
    LEFT JOIN `**REDACTED**.timecourse.pao2` b
    ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock
  )

  SELECT
      site
    , enc_id
    , eclock

    -- pf_ratio is only valid when fio2_time <= pao2_time, re #116
    , CASE
      WHEN fio2_time IS NULL THEN NULL
      WHEN pao2_time IS NULL THEN NULL
      WHEN fio2_time > pao2_time THEN NULL
      ELSE pao2 / NULLIF(fio2, 0)
      END AS pf_ratio

    , CASE
      WHEN fio2_time IS NULL THEN NULL
      WHEN pao2_time IS NULL THEN NULL
      WHEN fio2_time > pao2_time THEN NULL
      ELSE fio2_time
      END AS pf_ratio_time
  FROM t0
)
;
