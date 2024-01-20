#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.thyroxine` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS thyroxine_time,
      -- PODIUM logic: Serum total thyroxine (T4) <4.2 mcg/dL (<54 nmol/L) - so keep lowest
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS thyroxine,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE UPPER(test_name) = "THYROXINE" AND UPPER(test_units) = "MCG/DL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.thyroxine_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS thyroxine_time,
    LAST_VALUE(t.thyroxine      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS thyroxine
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.thyroxine_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the thyroxine value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.thyroxine`
SET thyroxine = NULL, thyroxine_time = NULL
WHERE thyroxine_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
