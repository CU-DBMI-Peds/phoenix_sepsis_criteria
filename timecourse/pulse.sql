#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pulse` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      event_time AS pulse_time,
      MAX(SAFE_CAST(event_value AS FLOAT64)) AS pulse,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PULSE" AND event_units = "BPM" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.pulse_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pulse_time,
    LAST_VALUE(t.pulse      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pulse
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.pulse_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the pulse value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.pulse`
SET pulse = NULL, pulse_time = NULL
WHERE pulse_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
