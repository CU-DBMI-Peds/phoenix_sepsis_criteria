#standardSQL

-- join the dbp_* and sbp_* columns onto timecourse
-- after locf, define the dbp and sbp to preferentially use the arterial over
-- the cuff.
-- then join on map values; calculate values for any missing rows where dbp and
-- sbp are defined, and then locf the map values.
--
CREATE OR REPLACE TABLE `**REDACTED**.timecourse.bloodpressure` AS
(
  WITH
  tdbp_art AS
  (
    SELECT
      enc_id,
      event_time AS dbp_art_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS dbp_art,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "DBP_ART" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  tdbp_cuff AS
  (
    SELECT
      enc_id,
      event_time AS dbp_cuff_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS dbp_cuff,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "DBP_CUFF" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  tsbp_art AS
  (
    SELECT
      enc_id,
      event_time AS sbp_art_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS sbp_art,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "SBP_ART" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  tsbp_cuff AS
  (
    SELECT
      enc_id,
      event_time AS sbp_cuff_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS sbp_cuff,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "SBP_CUFF" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  tmap_art AS
  (
    SELECT
      enc_id,
      event_time AS map_art_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS map_art,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "MAP_ART" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  tmap_cuff AS
  (
    SELECT
      enc_id,
      event_time AS map_cuff_time,
      MIN(SAFE_CAST(event_value AS FLOAT64)) AS map_cuff,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "MAP_CUFF" AND event_units = "MMHG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(dbp_art_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dbp_art_time,
    LAST_VALUE(dbp_art       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dbp_art,
    LAST_VALUE(dbp_cuff_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dbp_cuff_time,
    LAST_VALUE(dbp_cuff      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dbp_cuff,
    LAST_VALUE(sbp_art_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sbp_art_time,
    LAST_VALUE(sbp_art       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sbp_art,
    LAST_VALUE(sbp_cuff_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sbp_cuff_time,
    LAST_VALUE(sbp_cuff      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sbp_cuff,
    LAST_VALUE(map_art_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS map_art_time,
    LAST_VALUE(map_art       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS map_art,
    LAST_VALUE(map_cuff_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS map_cuff_time,
    LAST_VALUE(map_cuff      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS map_cuff,
    CAST(NULL AS INT)     AS dbp_time, -- placeholder, will be filled in later
    CAST(NULL AS FLOAT64) AS dbp,      -- placeholder, will be filled in later
    CAST(NULL AS INT)     AS sbp_time, -- placeholder, will be filled in later
    CAST(NULL AS FLOAT64) AS sbp,      -- placeholder, will be filled in later
    CAST(NULL AS INT)     AS map_time, -- placeholder, will be filled in later
    CAST(NULL AS FLOAT64) AS map,      -- placeholder, will be filled in later
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN tdbp_art  ON tc.enc_id = tdbp_art.enc_id  AND tc.eclock = tdbp_art.dbp_art_time
  LEFT JOIN tdbp_cuff ON tc.enc_id = tdbp_cuff.enc_id AND tc.eclock = tdbp_cuff.dbp_cuff_time
  LEFT JOIN tsbp_art  ON tc.enc_id = tsbp_art.enc_id  AND tc.eclock = tsbp_art.sbp_art_time
  LEFT JOIN tsbp_cuff ON tc.enc_id = tsbp_cuff.enc_id AND tc.eclock = tsbp_cuff.sbp_cuff_time
  LEFT JOIN tmap_art  ON tc.enc_id = tmap_art.enc_id  AND tc.eclock = tmap_art.map_art_time
  LEFT JOIN tmap_cuff ON tc.enc_id = tmap_cuff.enc_id AND tc.eclock = tmap_cuff.map_cuff_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the blood pressures value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
--
-- Do this for art and cuff values then coalesce to the preferential value of
-- art over cuff
UPDATE `**REDACTED**.timecourse.bloodpressure`
SET dbp_art = NULL, dbp_art_time = NULL
WHERE dbp_art_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.bloodpressure`
SET dbp_cuff = NULL, dbp_cuff_time = NULL
WHERE dbp_cuff_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.bloodpressure`
SET sbp_art = NULL, sbp_art_time = NULL
WHERE sbp_art_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.bloodpressure`
SET sbp_cuff = NULL, sbp_cuff_time = NULL
WHERE sbp_cuff_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.bloodpressure`
SET map_art = NULL, map_art_time = NULL
WHERE map_art_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.bloodpressure`
SET map_cuff = NULL, map_cuff_time = NULL
WHERE map_cuff_time - eclock > 60 * 6
;


UPDATE `**REDACTED**.timecourse.bloodpressure`
SET
  dbp      = COALESCE(dbp_art, dbp_cuff),
  dbp_time = COALESCE(dbp_art_time, dbp_cuff_time),
  sbp      = COALESCE(sbp_art, sbp_cuff),
  sbp_time = COALESCE(sbp_art_time, sbp_cuff_time),
  map      = COALESCE(map_art, map_cuff),
  map_time = COALESCE(map_art_time, map_cuff_time)
WHERE TRUE
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
