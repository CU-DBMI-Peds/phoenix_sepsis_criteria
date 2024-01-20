#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ecmo` AS
(
  WITH tecmo AS
  (
    SELECT
      enc_id,
      event_time AS ecmo_time,
      MAX(IF (LOWER(event_value) = "false", 0, 1)) as ecmo, -- this will set true, va, and vv as ecmo
      MAX(IF (LOWER(event_value) = "va", 1, 0)) as ecmo_va,
      MAX(IF (LOWER(event_value) = "vv", 1, 0)) as ecmo_vv,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "ECMO" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
             LAST_VALUE(ecmo_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS ecmo_time,
    COALESCE(LAST_VALUE(ecmo       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS ecmo,
    COALESCE(LAST_VALUE(ecmo_va    IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS ecmo_va,
    COALESCE(LAST_VALUE(ecmo_vv    IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS ecmo_vv
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN tecmo  ON tc.enc_id = tecmo.enc_id  AND tc.eclock = tecmo.ecmo_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the ecmo value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.ecmo`
SET ecmo = NULL
  , ecmo_va = NULL
  , ecmo_vv = NULL
  , ecmo_time = NULL
WHERE ecmo_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
