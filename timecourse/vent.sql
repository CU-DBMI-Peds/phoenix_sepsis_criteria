#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.vent` AS
(
  WITH t1 AS
  (
    SELECT
        enc_id
      , event_time AS map_vent_time
      , MAX(SAFE_CAST(event_value AS FLOAT64)) AS map_vent
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "MAP_VENT" AND event_units = "CMH2O" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  t2 AS
  (
    SELECT
        enc_id
      , event_time AS map_hfov_time
      , MAX(SAFE_CAST(event_value AS FLOAT64)) AS map_hfov
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "MAP_HFOV" AND event_units = "CMH2O" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  t3 AS
  (
    SELECT
        enc_id
      , event_time AS peep_vent_time
      , MAX(SAFE_CAST(event_value AS FLOAT64)) AS peep_vent
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PEEP_VENT" AND event_units = "CMH2O" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  vent_b AS
  (
    SELECT
      site,
      enc_id,
      event_time AS vent_b_time,
      1 AS vent_b
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE
          -- variable for sites without ventilator specifics
          (event_name = "VENT_DURING_STAY" AND event_value = "true" AND event_time IS NOT NULL)
    GROUP BY site, enc_id, event_time
  )
  , t4 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , t1.map_vent
      , t1.map_vent_time
      , t2.map_hfov
      , t2.map_hfov_time
      , t3.peep_vent
      , t3.peep_vent_time
      , vent_b.vent_b_time
      , vent_b.vent_b
      --, IF(t1.map_vent > 0 OR t2.map_hfov > 0 OR t3.peep_vent > 3 OR vent_b.vent_b = 1, 1, 0) AS vent
      , CASE WHEN t1.map_vent > 0  THEN 1
             WHEN t2.map_hfov > 0  THEN 1
             WHEN t3.peep_vent > 3 THEN 1
             WHEN vent_b.vent_b = 1 THEN 1
             WHEN t1.map_vent IS NOT NULL AND t2.map_hfov IS NOT NULL AND t3.peep_vent IS NOT NULL AND vent_b.vent_b IS NOT NULL THEN 0
             ELSE NULL END as vent
      , CASE
        WHEN t1.map_vent_time <= t2.map_hfov_time AND t1.map_vent_time <= t3.peep_vent_time AND t1.map_vent_time <= vent_b.vent_b_time THEN t1.map_vent_time
        WHEN t2.map_hfov_time <= t1.map_vent_time AND t2.map_hfov_time <= t3.peep_vent_time AND t2.map_hfov_time <= vent_b.vent_b_time THEN t2.map_hfov_time
        WHEN t3.peep_vent_time <= t1.map_vent_time AND t3.peep_vent_time <= t2.map_hfov_time AND t3.peep_vent_time <= vent_b.vent_b_time THEN t3.peep_vent_time
        WHEN vent_b.vent_b_time <= t1.map_vent_time AND vent_b.vent_b_time <= t2.map_hfov_time AND vent_b.vent_b_time <= t3.peep_vent_time THEN vent_b.vent_b_time
        END AS vent_time
      , COALESCE(t1.map_vent, t2.map_hfov, t3.peep_vent) AS vent_map
      , COALESCE(t1.map_vent_time, t2.map_hfov_time, t3.peep_vent_time) AS vent_map_time
      FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN t1     ON tc.enc_id = t1.enc_id     AND tc.eclock = t1.map_vent_time
    LEFT JOIN t2     ON tc.enc_id = t2.enc_id     AND tc.eclock = t2.map_hfov_time
    LEFT JOIN t3     ON tc.enc_id = t3.enc_id     AND tc.eclock = t3.peep_vent_time
    LEFT JOIN vent_b ON tc.enc_id = vent_b.enc_id AND tc.eclock = vent_b.vent_b_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    ,          LAST_VALUE(map_vent_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS map_vent_time
    , COALESCE(LAST_VALUE(map_vent       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS map_vent
    ,          LAST_VALUE(map_hfov_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS map_hfov_time
    , COALESCE(LAST_VALUE(map_hfov       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS map_hfov
    ,          LAST_VALUE(peep_vent_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS peep_vent_time
    , COALESCE(LAST_VALUE(peep_vent      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS peep_vent
    ,          LAST_VALUE(vent_b_time    IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS vent_b_time
    , COALESCE(LAST_VALUE(vent_b         IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS vent_b
    ,          LAST_VALUE(vent_map_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS vent_map_time
    ,          LAST_VALUE(vent_map   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS vent_map
    ,          LAST_VALUE(vent_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS vent_time
    , COALESCE(LAST_VALUE(vent       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS vent

  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t4  ON tc.enc_id = t4.enc_id  AND tc.eclock = t4.vent_map_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the vent value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.vent`
SET map_vent = NULL, map_vent_time = NULL
WHERE map_vent_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.vent`
SET map_hfov = NULL, map_hfov_time = NULL
WHERE map_hfov_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.vent`
SET peep_vent = NULL, peep_vent_time = NULL
WHERE peep_vent_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.vent`
SET vent_map = NULL, vent_map_time = NULL
WHERE vent_map_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.vent`
SET vent = NULL, vent_time = NULL
WHERE (vent_time - eclock > 60 * 6)
  AND vent_b != 1
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
