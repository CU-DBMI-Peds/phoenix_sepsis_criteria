#standardSQL

-- NOTE:
--   fio2 is coming from the fio2.sql script as a fraction between 0.21 and 1.00
--   spo2 is comming in from spo2.sql as a value between 0 and 100 (mostly, but
--   not all, integer valued, stored as FLOAT64)
--
-- in the spo2.sql script two indicators are generated:
--
--    , IF(spo2 >= 80 AND spo2 <= 97, 1, 0) AS ok_for_podium
--    , IF(               spo2 <= 97, 1, 0) AS ok_for_non_podium
--
-- Use these indictors when building the organ dysfunction component scores.

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.sf_ratio` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , fio2.fio2
      , fio2.fio2_time
      , spo2.spo2
      , spo2.spo2_time
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.fio2` fio2
    ON tc.site = fio2.site AND tc.enc_id = fio2.enc_id AND tc.eclock = fio2.eclock
    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.site = spo2.site AND tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock
  )

  SELECT
      site
    , enc_id
    , eclock

    -- sf_ratio is only valid when fio2_time <= spo2_time, re #116
    , CASE
      WHEN fio2_time IS NULL THEN NULL
      WHEN spo2_time IS NULL THEN NULL
      WHEN fio2_time > spo2_time THEN NULL
      ELSE spo2 / NULLIF(fio2, 0)
      END AS sf_ratio

    , CASE
      WHEN fio2_time IS NULL THEN NULL
      WHEN spo2_time IS NULL THEN NULL
      WHEN fio2_time > spo2_time THEN NULL
      ELSE fio2_time
      END AS sf_ratio_time

  FROM t0
)
;
