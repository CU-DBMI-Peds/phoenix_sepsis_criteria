#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.bilirubin_tot` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS bilirubin_tot_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS bilirubin_tot,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "BILIRUBIN_TOT" AND test_units = "MG/DL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.bilirubin_tot_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS bilirubin_tot_time,
    LAST_VALUE(t.bilirubin_tot      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS bilirubin_tot
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.bilirubin_tot_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the bilirubin_tot value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.bilirubin_tot`
SET bilirubin_tot = NULL, bilirubin_tot_time = NULL
WHERE bilirubin_tot_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
