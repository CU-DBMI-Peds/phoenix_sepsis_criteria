#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.anc` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      test_time AS anc_time,
      MIN(SAFE_CAST(test_value AS FLOAT64)) AS anc,
    FROM
    (
      SELECT
        enc_id, test_name, test_value, test_units,
        COALESCE(test_obtained_time, test_result_time, test_ordered_time) AS test_time
      FROM `**REDACTED**.harmonized.tests`
    )
    WHERE test_name = "ANC" AND test_units = "10E3/UL" AND test_time IS NOT NULL
    GROUP BY enc_id, test_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.anc_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS anc_time,
    LAST_VALUE(t.anc      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS anc
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.anc_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the anc value to NULL if the value is more than 24 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.anc`
SET anc = NULL, anc_time = NULL
WHERE anc_time - eclock > 60 * 24
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
