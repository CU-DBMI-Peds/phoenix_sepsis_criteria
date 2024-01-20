#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.spo2` AS
(
  WITH tspo2 AS
  (
    SELECT
        enc_id
      , event_time AS spo2_time
      , MIN(SAFE_CAST(event_value AS FLOAT64)) AS spo2
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PULSE_OX" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  , t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , LAST_VALUE(spo2_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS spo2_time
      , LAST_VALUE(spo2       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS spo2
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN (SELECT * FROM tspo2 WHERE spo2 >= 1) b
    ON tc.enc_id = b.enc_id  AND tc.eclock = b.spo2_time
  )

  SELECT
      *
      , IF(spo2 >= 80 AND spo2 <= 97, 1, 0) AS ok_for_podium
      , IF(               spo2 <= 97, 1, 0) AS ok_for_non_podium
      , IF(spo2 >= 80 AND spo2 <= 97, spo2, NULL) AS spo2_for_podium
      , IF(               spo2 <= 97, spo2, NULL) AS spo2_for_non_podium
  FROM t0
)
;


-- Check for unexpected values
-- Expect SPO2 to be (mostly) integer valued between 0 and 100
SELECT
    IF(MIN(spo2) < 0,               ERROR("Unexpected low spo2 value"), "PASS") AS low_value_check
  , IF(MAX(spo2) > 100,             ERROR("Unexpected high spo2 value"), "PASS") AS high_value_check
  , IF(SUM(IF(ok_for_non_podium IS NULL, 1, 0)) > 0,  ERROR("NULL value in ok_for_non_podium"), "PASS") as ok_for_non_podium_check
  , IF(SUM(IF(ok_for_podium     IS NULL, 1, 0)) > 0,  ERROR("NULL value in ok_for_podium"    ), "PASS") as ok_for_podium_check
  FROM `**REDACTED**.timecourse.spo2`
;

-- -------------------------------------------------------------------------- --
-- Set the spo2 value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.spo2`
SET spo2 = NULL, spo2_time = NULL
WHERE spo2_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
