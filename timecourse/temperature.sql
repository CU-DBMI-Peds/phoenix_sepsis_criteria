#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.temperature` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      event_time AS temperature_time,
      MAX(SAFE_CAST(event_value AS FLOAT64)) AS temperature
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "TEMP" AND event_units = "DEGC" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(t.temperature_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS temperature_time
    , LAST_VALUE(t.temperature      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS temperature
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.temperature_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the temperature value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.temperature`
SET temperature = NULL, temperature_time = NULL
WHERE temperature_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
