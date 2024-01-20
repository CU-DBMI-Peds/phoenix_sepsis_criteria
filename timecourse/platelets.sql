#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.platelets` AS
(
  WITH platelets AS
  (
    SELECT
      enc_id,
      test_time AS platelets_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS platelets,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "PLTS" AND test_units = "10E3/UL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(platelets.platelets_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS platelets_time,
    LAST_VALUE(platelets.platelets      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS platelets
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN platelets
  ON tc.enc_id = platelets.enc_id AND tc.eclock = platelets.platelets_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the platelets value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.platelets`
SET platelets = NULL, platelets_time = NULL
WHERE platelets_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
