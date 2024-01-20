#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.paco2` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS paco2_time,
      MAX(SAFE_CAST(test_value AS FLOAT64)) AS paco2,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "PCO2_ART" AND test_units = "MMHG" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , LAST_VALUE(paco2_time  IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS paco2_time
    , LAST_VALUE(paco2       IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS paco2
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t  ON tc.enc_id = t.enc_id  AND tc.eclock = t.paco2_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the paco2 value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.paco2`
SET paco2 = NULL, paco2_time = NULL
WHERE paco2_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
