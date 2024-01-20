#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.gcs` AS
(
  WITH
  gcsm AS
  (
    SELECT
      enc_id,
      event_time AS gcs_motor_time,
      MAX(SAFE_CAST(event_value AS INT)) AS gcs_motor,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "GCS_MOTOR" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  gcse AS
  (
    SELECT
      enc_id,
      event_time AS gcs_eye_time,
      MAX(SAFE_CAST(event_value AS INT)) AS gcs_eye,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "GCS_EYE" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  gcsv AS
  (
    SELECT
      enc_id,
      event_time AS gcs_verbal_time,
      MAX(SAFE_CAST(event_value AS INT)) AS gcs_verbal,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "GCS_VERBAL" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  gcst AS
  (
    SELECT
      enc_id,
      event_time AS gcs_total_time,
      MAX(SAFE_CAST(event_value AS INT)) AS gcs_total,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "GCS_TOTAL" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )


  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(gcs_motor_time   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_motor_time,
    LAST_VALUE(gcs_motor        IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_motor,
    LAST_VALUE(gcs_eye_time     IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_eye_time,
    LAST_VALUE(gcs_eye          IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_eye,
    LAST_VALUE(gcs_verbal_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_verbal_time,
    LAST_VALUE(gcs_verbal       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_verbal,
    LAST_VALUE(gcs_total_time   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_total_time,
    LAST_VALUE(gcs_total        IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS gcs_total
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN gcsm  ON tc.enc_id = gcsm.enc_id  AND tc.eclock = gcsm.gcs_motor_time
  LEFT JOIN gcse  ON tc.enc_id = gcse.enc_id  AND tc.eclock = gcse.gcs_eye_time
  LEFT JOIN gcsv  ON tc.enc_id = gcsv.enc_id  AND tc.eclock = gcsv.gcs_verbal_time
  LEFT JOIN gcst  ON tc.enc_id = gcst.enc_id  AND tc.eclock = gcst.gcs_total_time
)
;

-- -------------------------------------------------------------------------- --
-- We are going to assume that if at least one componet score (eye, verbal,
-- motor) is update and the others are not, then it is because there was no
-- change or need to update those values.
--
-- This will lead to updating some gcs_total scores.

UPDATE `**REDACTED**.timecourse.gcs`
SET gcs_total = gcs_eye + gcs_verbal + gcs_motor
  , gcs_total_time = GREATEST(gcs_eye_time, gcs_verbal_time, gcs_motor_time)
WHERE gcs_total_time < gcs_eye_time
   OR gcs_total_time < gcs_verbal_time
   OR gcs_total_time < gcs_motor_time
;


-- -------------------------------------------------------------------------- --
-- Set the gcs value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
-- based on gcs_total_time as we are assuming that componets that are not
-- updated when other componets are updated are still valid.
UPDATE `**REDACTED**.timecourse.gcs`
SET gcs_motor  = NULL, gcs_motor_time  = NULL,
    gcs_eye    = NULL, gcs_eye_time    = NULL,
    gcs_verbal = NULL, gcs_verbal_time = NULL,
    gcs_total  = NULL, gcs_total_time  = NULL
WHERE gcs_total_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
-- checks
WITH checks AS (
  SELECT
      MIN(gcs_eye) AS min_gcs_eye
    , MAX(gcs_eye) AS max_gcs_eye
    , MIN(gcs_verbal) AS min_gcs_verbal
    , MAX(gcs_verbal) AS max_gcs_verbal
    , MIN(gcs_motor) AS min_gcs_motor
    , MAX(gcs_motor) AS max_gcs_motor
    , MIN(gcs_total) AS min_gcs_total
    , MAX(gcs_total) AS max_gcs_total
  FROM **REDACTED**.timecourse.gcs
)
SELECT
    CASE
    WHEN min_gcs_eye < 1 THEN ERROR("impossible min gcs eye value")
    WHEN max_gcs_eye > 4 THEN ERROR("impossible max gcs eye value")
    WHEN min_gcs_verbal < 1 THEN ERROR("impossible min gcs verbal value")
    WHEN max_gcs_verbal > 5 THEN ERROR("impossible max gcs verbal value")
    WHEN min_gcs_motor < 1 THEN ERROR("impossible min gcs motor value")
    WHEN max_gcs_motor > 6 THEN ERROR("impossible max gcs motor value")
    WHEN min_gcs_total <  3 THEN ERROR("impossible min gcs total value")
    WHEN max_gcs_total > 15 THEN ERROR("impossible max gcs total value")
    ELSE "PASS" END AS value_check
FROM checks
;


-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
