#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.glucose` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS glucose_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS glucose,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "GLUCOSE" AND test_units = "MG/DL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.glucose_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS glucose_time,
    LAST_VALUE(t.glucose      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS glucose
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.glucose_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the glucose value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.glucose`
SET glucose = NULL, glucose_time = NULL
WHERE glucose_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
