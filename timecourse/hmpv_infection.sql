#standardsql

-- Build an indicator for proven infection which will be zero until
-- at least one test result indicates a proven infection has been found

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.hmpv_infection` AS
(
  WITH infectious_tests AS
  (
    SELECT
        site
      , enc_id
      , COALESCE(test_ordered_time, test_obtained_time, test_result_time) AS eclock
      , COUNT(1) AS hmpv_positive_tests
    FROM `**REDACTED**.harmonized.proven_infections`
    WHERE 1=1
      AND COALESCE(test_ordered_time, test_obtained_time, test_result_time) >= 0
      AND proven_infection = 1
      AND LOWER(test_name) = 'hmpv'
    GROUP BY site, enc_id, (COALESCE(test_ordered_time, test_obtained_time, test_result_time))
  )
  ,
  t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , COALESCE(infectious_tests.hmpv_positive_tests, 0) AS hmpv_positive_tests
      , SUM(COALESCE(infectious_tests.hmpv_positive_tests, 0)) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.site, tc.enc_id, tc.eclock) AS total_hmpv_positive_tests
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN infectious_tests
    ON tc.site   = infectious_tests.site    AND
       tc.enc_id = infectious_tests.enc_id  AND
       tc.eclock = infectious_tests.eclock
  )

  SELECT *,
    COALESCE(IF(total_hmpv_positive_tests >= 1, 1, 0), 0) AS hmpv_infection
  FROM t
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("hmpv_infection", "hmpv_infection");
