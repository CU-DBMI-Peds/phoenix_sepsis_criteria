#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.fibrinogen` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS fibrinogen_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS fibrinogen,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "FIBRINOGEN" AND test_units = "MG/DL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.fibrinogen_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fibrinogen_time,
    LAST_VALUE(t.fibrinogen      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fibrinogen
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.fibrinogen_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the fibrinogen value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.fibrinogen`
SET fibrinogen = NULL, fibrinogen_time = NULL
WHERE fibrinogen_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
