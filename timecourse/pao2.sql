#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pao2` AS
(
  WITH tpao2 AS
  (
    SELECT
      enc_id,
      test_time AS pao2_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS pao2,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "PO2_ART" AND test_units = "MMHG" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(pao2_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pao2_time,
    LAST_VALUE(pao2       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pao2,
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN tpao2  ON tc.enc_id = tpao2.enc_id  AND tc.eclock = tpao2.pao2_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the pao2 value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.pao2`
SET pao2 = NULL, pao2_time = NULL
WHERE pao2_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
