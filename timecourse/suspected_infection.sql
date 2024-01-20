#standardsql

-- Build an indicator for suspected infection which will be zero until
-- at least one test order
-- at least two doses of systemic antimicrobial medications
-- and then will be 1 for the duration of the encounter

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.suspected_infection` AS
(
  WITH antimicrobial_doses AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS eclock
      , count(1) AS antimicrobial_doses
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_admin_time >= 0
      AND systemic = 1
      AND (
        (
          med_set = "antimicrobial"
          AND med_subset IN ('antibacterial', 'antimalarial', 'antimycotics', 'antivirals', 'antimycobacterials', 'anthelmintic')
        )
        OR
        (
          med_generic_name = 'quinine'
          AND site IN ('**REDACTED**', '**REDACTED**', '**REDACTED**')
        )
      )
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  ordered_tests AS
  (
    SELECT
        site
      , enc_id
      , COALESCE(test_ordered_time, test_obtained_time, test_result_time) AS eclock
      , count(1) AS ordered_tests
    FROM `**REDACTED**.harmonized.tests`
    WHERE
      (COALESCE(test_ordered_time, test_obtained_time, test_result_time) >= 0)
      AND
      (test_name IN (
        SELECT DISTINCT test_name FROM `**REDACTED**.full.infectious_tests`
      ))
    GROUP BY site, enc_id, (COALESCE(test_ordered_time, test_obtained_time, test_result_time))
  )
  ,
  t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , COALESCE(antimicrobial_doses.antimicrobial_doses, 0) AS antimicrobial_doses
      , SUM(COALESCE(antimicrobial_doses.antimicrobial_doses, 0)) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.site, tc.enc_id, tc.eclock) AS total_antimicrobial_doses
      , COALESCE(ordered_tests.ordered_tests, 0) AS ordered_tests
      , SUM(COALESCE(ordered_tests.ordered_tests, 0)) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.site, tc.enc_id, tc.eclock) AS total_ordered_tests
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN antimicrobial_doses
    ON tc.site   = antimicrobial_doses.site    AND
       tc.enc_id = antimicrobial_doses.enc_id  AND
       tc.eclock = antimicrobial_doses.eclock
    LEFT JOIN ordered_tests
    ON tc.site   = ordered_tests.site    AND
       tc.enc_id = ordered_tests.enc_id  AND
       tc.eclock = ordered_tests.eclock
  )

  SELECT
      t.*
    , COALESCE(IF(    temperature.temperature > 38 OR  t.total_ordered_tests >= 1, 1, 0), 0) AS suspected_infection_0dose
    , COALESCE(IF(t.total_antimicrobial_doses >= 1 AND t.total_ordered_tests >= 1, 1, 0), 0) AS suspected_infection_1dose
    , COALESCE(IF(t.total_antimicrobial_doses >= 2 AND t.total_ordered_tests >= 1, 1, 0), 0) AS suspected_infection_2doses
  FROM t
  LEFT JOIN `**REDACTED**.timecourse.temperature` temperature
  ON t.site = temperature.site AND t.enc_id = temperature.enc_id AND t.eclock = temperature.eclock
)
;

CALL **REDACTED**.sa.aggregate("suspected_infection", "suspected_infection_0dose");
CALL **REDACTED**.sa.aggregate("suspected_infection", "suspected_infection_1dose");
CALL **REDACTED**.sa.aggregate("suspected_infection", "suspected_infection_2doses");
