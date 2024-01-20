#standardSQL
/*
notes:
* only **REDACTED** provides PUPIL_RESP_B.
* **REDACTED** PUPIL_RESP_B values are mapped to both PUPIL_RESP_L and PUPIL_RESP_R.
*/

/*
CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pupil` AS
(
  WITH L AS
  (
    SELECT
      enc_id,
      event_time AS pupil_time,
      IF (STRING_AGG(event_value, ",") LIKE "%non-%", 1, 0) AS pupil
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PUPIL_RESP_L" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  R AS
  (
    SELECT
      enc_id,
      event_time AS pupil_time,
      IF (STRING_AGG(event_value, ",") LIKE "%non-%", 1, 0) AS pupil
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PUPIL_RESP_R" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )
  ,
  B AS
  (
    SELECT
      enc_id,
      event_time AS pupil_time,
      IF (STRING_AGG(event_value, ",") LIKE "%non-%", 1, 0) AS pupil
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "PUPIL_RESP_B" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.pupil_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pupil_time,
    LAST_VALUE(t.pupil      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pupil
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN
  (
    SELECT
      COALESCE(B.enc_id, L.enc_id, R.enc_id) AS enc_id,
      CASE
        WHEN B.pupil = 1 THEN "both-fixed"
        WHEN B.pupil = 0 THEN "both-reactive"
        WHEN (L.pupil + R.pupil) = 2 THEN "both-fixed"
        WHEN (L.pupil + R.pupil) = 0 THEN "both-reactive"
        WHEN (COALESCE(L.pupil, 0) + COALESCE(R.pupil, 0)) > 0  THEN "at least one fixed"
        ELSE NULL END AS pupil
      ,
      COALESCE(B.pupil_time, L.pupil_time, R.pupil_time) AS pupil_time
      FROM L
      FULL JOIN R ON L.enc_id = R.enc_id AND L.pupil_time = R.pupil_time
      FULL JOIN B ON L.enc_id = B.enc_id AND L.pupil_time = B.pupil_time
  ) t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.pupil_time
)
;
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pupil` AS
(
  WITH t AS (
    SELECT
          site
        , enc_id
        , CASE -- use L and R preferentially over B
          WHEN IF(COALESCE(event_value_PUPIL_RESP_L, 0) > 0, 1, 0) + IF(COALESCE(event_value_PUPIL_RESP_R, 0) > 0, 1, 0) = 2 THEN "both-fixed"
          WHEN IF(COALESCE(event_value_PUPIL_RESP_L, 0) > 0, 1, 0) + IF(COALESCE(event_value_PUPIL_RESP_R, 0) > 0, 1, 0) = 1 THEN "at least one fixed"
          WHEN event_value_PUPIL_RESP_L + event_value_PUPIL_RESP_R = 0 THEN "both-reactive"
          WHEN COALESCE(event_value_PUPIL_RESP_B, 0) > 0 THEN "both-fixed"
          WHEN event_value_PUPIL_RESP_B = 0 THEN "both-reactive"
          ELSE NULL END AS pupil
        , event_time AS pupil_time

    FROM
    (
      SELECT
          site
        , enc_id
        , event_name
        , IF(event_value = "reactive", 0, 1) as event_value
        , event_time
      FROM `**REDACTED**.harmonized.observ_interv_events`
      WHERE event_name IN ("PUPIL_RESP_L", "PUPIL_RESP_R", "PUPIL_RESP_B")
    )
    PIVOT
    (
      sum(event_value) as event_value
      FOR event_name IN ("PUPIL_RESP_L", "PUPIL_RESP_R", "PUPIL_RESP_B")
    )
    GROUP BY event_value_PUPIL_RESP_L, event_value_PUPIL_RESP_R, event_value_PUPIL_RESP_B, site, enc_id, event_time
  )
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(t.pupil_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pupil_time
    , LAST_VALUE(t.pupil      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pupil
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.pupil_time
);

-- -------------------------------------------------------------------------- --
-- Set the pupil value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.pupil`
SET pupil = NULL, pupil_time = NULL
WHERE pupil_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
