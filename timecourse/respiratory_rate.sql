#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.respiratory_rate` AS
(
  WITH t AS
  (
    SELECT
        enc_id
      , event_time AS respiratory_rate_time
      , MAX(SAFE_CAST(event_value AS FLOAT64)) AS respiratory_rate
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "RESP_RATE" AND event_units = "BRPM" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(respiratory_rate_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS respiratory_rate_time
    , LAST_VALUE(respiratory_rate       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS respiratory_rate
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t ON tc.enc_id = t.enc_id  AND tc.eclock = t.respiratory_rate_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the respiratory_rate value to NULL if the value is more than six hours
-- old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.respiratory_rate`
SET respiratory_rate = NULL, respiratory_rate_time = NULL
WHERE respiratory_rate_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
