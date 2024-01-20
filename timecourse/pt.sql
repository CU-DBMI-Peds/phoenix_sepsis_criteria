#standardSQL

-- Prothrombin Time

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pt` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS pt_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS pt,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "PT" AND test_units = "SECONDS" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.pt_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pt_time,
    LAST_VALUE(t.pt      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS pt
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.pt_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the pt value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.pt`
SET pt = NULL, pt_time = NULL
WHERE pt_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
