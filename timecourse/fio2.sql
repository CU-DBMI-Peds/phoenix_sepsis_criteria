#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.fio2` AS
(
  WITH tfio2 AS
  (
    SELECT
        enc_id
      , event_time AS fio2_time
      , MAX(SAFE_CAST(event_value AS FLOAT64)) / 100 AS fio2
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "FIO2" AND event_units = "%" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(fio2_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fio2_time

    -- Set a default FiO2 value of 0.21 for missing values
    --, COALESCE(LAST_VALUE(fio2       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0.21) AS fio2

    -- per **REDACTED**/issues/116 - _DO NOT SET A DEFAULT VALUE FOR FiO2_
    , LAST_VALUE(fio2 IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fio2
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN tfio2  ON tc.enc_id = tfio2.enc_id  AND tc.eclock = tfio2.fio2_time
)
;

-- Check for unexpected values
SELECT
    IF(MIN(fio2) < 0.21, ERROR("Unexpected low fio2 value"), "PASS") AS low_value_check
  , IF(MAX(fio2) > 1.00, ERROR("Unexpected high fio2 value"), "PASS") AS high_value_check
  FROM `**REDACTED**.timecourse.fio2`
;

-- -------------------------------------------------------------------------- --
-- Set the FiO2 value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.fio2`
SET fio2 = NULL, fio2_time = NULL
WHERE fio2_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
