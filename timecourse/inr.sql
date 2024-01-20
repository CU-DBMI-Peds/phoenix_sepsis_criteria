#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.inr` AS
(
  WITH inr AS
  (
    SELECT
      enc_id,
      test_time AS inr_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS inr,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "INR" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(inr.inr_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS inr_time,
    LAST_VALUE(inr.inr      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS inr
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN inr
  ON tc.enc_id = inr.enc_id AND tc.eclock = inr.inr_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the inr value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.inr`
SET inr = NULL, inr_time = NULL
WHERE inr_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
