#standardSQL

/*

if multiple values present, choose worst
some sites have both central and peripheral, peripheral
usually worse than central

*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.crt_prolonged` AS
(
  SELECT f.site, f.enc_id, f.eclock,
             LAST_VALUE(event_time      IGNORE NULLS) OVER (PARTITION BY f.site, f.enc_id ORDER BY f.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS crt_prolonged_time,
    COALESCE(LAST_VALUE(crt_prolonged_3 IGNORE NULLS) OVER (PARTITION BY f.site, f.enc_id ORDER BY f.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS crt_prolonged_3,
    COALESCE(LAST_VALUE(crt_prolonged_5 IGNORE NULLS) OVER (PARTITION BY f.site, f.enc_id ORDER BY f.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS crt_prolonged_5
  FROM `**REDACTED**.timecourse.foundation` f
    LEFT JOIN (
  SELECT
    COALESCE(t.enc_id, f.enc_id) AS enc_id,
    COALESCE(t.event_time, f.event_time) AS event_time,
    t.crt_prolonged_3,
    f.crt_prolonged_5
  FROM (
    SELECT
      enc_id,
      event_time,
      MAX(crt_prolonged_3) AS crt_prolonged_3
    FROM (
      SELECT DISTINCT
        enc_id,
        event_time,
        CASE
          WHEN LOWER(event_value) = 'true' THEN 1
          ELSE 0
        END as crt_prolonged_3
      FROM
      `**REDACTED**.harmonized.observ_interv_events`
      WHERE
        event_name = 'CRT_PROLONGED_3'
        AND event_time IS NOT NULL
    )
    GROUP BY enc_id, event_time) t

  FULL JOIN (

    SELECT
      enc_id,
      event_time,
      MAX(crt_prolonged_5) AS crt_prolonged_5
    FROM (
      SELECT DISTINCT
        enc_id,
        event_time,
        CASE
          WHEN LOWER(event_value) = 'true' THEN 1
          ELSE 0
        END as crt_prolonged_5
      FROM
      `**REDACTED**.harmonized.observ_interv_events`
      WHERE
        event_name = 'CRT_PROLONGED_5'
        AND event_time IS NOT NULL
    )
    GROUP BY enc_id, event_time) f
    ON t.enc_id = f.enc_id
    AND t.event_time = f.event_time
    ) c
  ON f.enc_id = c.enc_id  AND f.eclock = c.event_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the crt_prolonged value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.crt_prolonged`
SET crt_prolonged_3 = NULL, crt_prolonged_5 = NULL, crt_prolonged_time = NULL
WHERE crt_prolonged_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
