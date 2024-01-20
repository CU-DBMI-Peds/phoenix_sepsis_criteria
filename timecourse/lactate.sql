#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.lactate` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS lactate_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS lactate,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "LACTATE" AND test_units = "MMOL/L" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(lactate_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS lactate_time,
    LAST_VALUE(lactate       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS lactate,
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t ON tc.enc_id = t.enc_id AND tc.eclock = t.lactate_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the lactate value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.lactate`
SET lactate = NULL, lactate_time = NULL
WHERE lactate_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
