#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.troponin` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS troponin_time,
      -- PODIUM logic: Serum troponin I: >2.0 ng/mL - so keep highest
      MAX(SAFE_CAST(test_value AS FLOAT64)) AS troponin,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE UPPER(test_name) = "TROPONIN" AND UPPER(test_units) = "NG/ML" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.troponin_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS troponin_time,
    LAST_VALUE(t.troponin      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS troponin
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.troponin_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the troponin value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.troponin`
SET troponin = NULL, troponin_time = NULL
WHERE troponin_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
