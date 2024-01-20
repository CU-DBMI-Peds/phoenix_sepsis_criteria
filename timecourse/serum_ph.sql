#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.serum_ph` AS
(
  WITH t AS
  (
    SELECT
        enc_id
      , test_time AS serum_ph_time
      , MIN(SAFE_CAST(test_value AS FLOAT64)) AS serum_ph
    FROM
    (
      SELECT
          enc_id
        , test_name
        , test_value
        , test_units
        , COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name LIKE "PH_%" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(t.serum_ph_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS serum_ph_time
    , LAST_VALUE(t.serum_ph      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS serum_ph
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.serum_ph_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the serum_ph value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.serum_ph`
SET serum_ph = NULL, serum_ph_time = NULL
WHERE serum_ph_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
