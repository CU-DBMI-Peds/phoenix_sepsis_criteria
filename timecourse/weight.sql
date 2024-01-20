#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.weight` AS
(
  WITH weight AS
  (
    SELECT
      enc_id,
      event_time AS weight_time,
      AVG(SAFE_CAST(event_value AS FLOAT64)) AS weight,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "WEIGHT" AND event_units = "KG" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  , a AS -- first weight post hospital presentation
  (
      SELECT
          w.enc_id
        , w.weight
        , p.eclock
      FROM weight w
      INNER JOIN (
        SELECT enc_id, MIN(weight_time) AS eclock
        FROM weight
        WHERE weight_time >= 0 AND weight_time < 1440
        GROUP BY enc_id
      ) p
      ON w.enc_id = p.enc_id AND w.weight_time = p.eclock
  )
  , b AS -- last weight before hospital presentation
  (
      SELECT
          w.enc_id
        , w.weight
        , p.eclock
      FROM weight w
      INNER JOIN (
        SELECT enc_id, MAX(weight_time) AS eclock
        FROM weight
        WHERE weight_time < 0 AND weight_time > -1440
        GROUP BY enc_id
      ) p
      ON w.enc_id = p.enc_id AND w.weight_time = p.eclock
  )
  , admit_weight AS
  (
    SELECT
        COALESCE(a.enc_id, b.enc_id) AS enc_id
      , CASE
            WHEN a.eclock IS NULL OR b.eclock IS NULL THEN COALESCE(a.weight, b.weight)
            WHEN a.eclock <= abs(b.eclock) THEN a.weight
            WHEN NOT(a.eclock <= abs(b.eclock)) THEN b.weight
            ELSE NULL
        END AS admit_weight
    FROM a
    FULL OUTER JOIN b
    ON a.enc_id = b.enc_id
  )
  , t0 AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock, tc.eclock_bin,
      aw.admit_weight,
      LAST_VALUE(w.weight_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weight_time,
      LAST_VALUE(w.weight      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS weight
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN admit_weight aw
    ON tc.enc_id = aw.enc_id
    LEFT JOIN weight w
    ON tc.enc_id = w.enc_id AND tc.eclock = w.weight_time
  )
-- used for some organ dysfunction scores
  SELECT *, (weight - admit_weight) / NULLIF(admit_weight, 0) AS weight_delta
  FROM t0
)
;

-- -------------------------------------------------------------------------- --
-- Set the weight value to NULL if the value is more than one month old?  or for
-- the whole encounter?
-- re: **REDACTED**/issues/117
--UPDATE `**REDACTED**.timecourse.weight`
--SET weight_time = NULL, weight_time = NULL
--WHERE weight_time - eclock > 60 * 24 * 30.5 -- mintues * hours * days = 1 month
--;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
