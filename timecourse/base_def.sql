#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.base_def` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS base_def_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS base_def,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "BASE_DEF" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(base_def_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS base_def_time,
    LAST_VALUE(base_def       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS base_def,
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t  ON tc.enc_id = t.enc_id  AND tc.eclock = t.base_def_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the base_def value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.base_def`
SET base_def = NULL, base_def_time = NULL
WHERE base_def_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
