#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.d_dimer` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS d_dimer_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS d_dimer,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "D_DIMER" AND test_units = "MG/L FEU" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.d_dimer_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS d_dimer_time,
    LAST_VALUE(t.d_dimer      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS d_dimer
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.d_dimer_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the d_dimer value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.d_dimer`
SET d_dimer = NULL, d_dimer_time = NULL
WHERE d_dimer_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
