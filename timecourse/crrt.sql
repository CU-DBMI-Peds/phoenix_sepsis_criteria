#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.crrt` AS
(
  WITH tcrrt AS
  (
    SELECT
      enc_id,
      event_time AS crrt_time,
      1 AS crrt,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "CRRT" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
             LAST_VALUE(crrt_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS crrt_time,
    COALESCE(LAST_VALUE(crrt       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS crrt
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN tcrrt  ON tc.enc_id = tcrrt.enc_id  AND tc.eclock = tcrrt.crrt_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the crrt value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.crrt`
SET crrt = NULL, crrt_time = NULL
WHERE crrt_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
