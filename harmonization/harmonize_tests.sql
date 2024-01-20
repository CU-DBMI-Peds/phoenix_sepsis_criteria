/*
Views and tables to curate tests
*/
-- view to join together default/standard labs with mappings
CREATE OR REPLACE VIEW `**REDACTED**.full.test_name_mapping` AS
-- allow for both default names for tests and custom mappings
SELECT DISTINCT * FROM (
    -- default names for tests
    SELECT * FROM (
      SELECT DISTINCT
        site,
        standard_name AS test_name_mapped,
        'test_name' AS col_1,
        standard_name AS col_1_value,
        SAFE_CAST(NULL AS STRING) AS col_2,
        SAFE_CAST(NULL AS STRING) AS col_2_value,
        SAFE_CAST(NULL AS STRING) AS col_3,
        SAFE_CAST(NULL AS STRING) AS col_3_value,
        'inclusion' AS match_type,
        standard_unit
      -- cross join to map all sites to standard tests
      FROM `**REDACTED**.full.test_name_mapping_configuration` c,
        `**REDACTED**.full.standard_names_and_units` s
      WHERE s.type = 'tests'
    ) std
    WHERE NOT EXISTS (
      SELECT col_1_value
      FROM  `**REDACTED**.full.test_name_mapping_configuration` i
      WHERE i.col_1 = 'test_name'
      AND i.col_1_value = std.col_1_value
      AND i.site = std.site
    )

    UNION ALL
    -- custom mappings
    SELECT DISTINCT
        c.site,
        c.test_name_mapped,
        c.col_1,
        TRIM(UPPER(c.col_1_value)) AS col_1_value,
        c.col_2,
        TRIM(UPPER(c.col_2_value)) AS col_2_value,
        c.col_3,
        TRIM(UPPER(c.col_3_value)) AS col_3_value,
        c.match_type,
        s.standard_unit
    FROM `**REDACTED**.full.test_name_mapping_configuration` c
    LEFT JOIN `**REDACTED**.full.standard_names_and_units` s
        ON c.test_name_mapped = s.standard_name
        AND s.type = 'tests'
)
ORDER BY site, test_name_mapped
;

CREATE OR REPLACE TABLE `**REDACTED**.full.tests_phase1` AS

SELECT DISTINCT
    base.* EXCEPT(test_units, test_value),
    test_units AS test_units_source,
    COALESCE(unit_dest, test_units, standard_unit) AS test_units,
    CASE
        WHEN conversion_operation = '/' THEN ROUND(SAFE_CAST(test_value AS FLOAT64) / SAFE_CAST(conversion_factor AS FLOAT64), 3)
        WHEN conversion_operation = '*' THEN ROUND(SAFE_CAST(test_value AS FLOAT64) * SAFE_CAST(conversion_factor AS FLOAT64), 3)
        ELSE SAFE_CAST(test_value AS FLOAT64)
    END AS test_value
FROM (
    SELECT DISTINCT
        t.* EXCEPT(test_value, test_value_source, test_units, test_name, test_name_source),
        --  if a test_value_source already exists, preserve it
        COALESCE(test_value_source, test_value) AS test_value_source,
        -- fixing some values that can be converted to numeric with basic rules
        CASE
            WHEN UPPER(test_value_source) LIKE '%NOTE NEW METHOD AND REFERENCE RANGE%'
                AND test_value IS NULL
                THEN SAFE_CAST(TRIM(REPLACE(UPPER(test_value_source), 'NOTE NEW METHOD AND REFERENCE RANGE', '')) AS FLOAT64)
            WHEN UPPER(test_value) LIKE '%GREATER THAN%' THEN ROUND(SAFE_CAST(TRIM(REPLACE(UPPER(test_value), 'GREATER THAN', '')) AS FLOAT64) * 1.1, 3)
            WHEN UPPER(test_value) LIKE '>%'             THEN ROUND(SAFE_CAST(TRIM(REPLACE(      test_value,  '>'           , '')) AS FLOAT64) * 1.1, 3)
            WHEN UPPER(test_value) LIKE '%LESS THAN%' THEN ROUND(SAFE_CAST(TRIM(REPLACE(UPPER(test_value), 'LESS THAN', '')) AS FLOAT64) * 0.9, 3)
            WHEN UPPER(test_value) LIKE '<%'          THEN ROUND(SAFE_CAST(TRIM(REPLACE(      test_value,  '<',         '')) AS FLOAT64) * 0.9, 3)
            WHEN REGEXP_CONTAINS(TRIM(test_value), r'^((\d*)(\.(\d+))?)\s*%$') THEN SAFE_CAST(TRIM(REPLACE(test_value, '%', '')) AS FLOAT64)
        ELSE SAFE_CAST(TRIM(test_value) AS FLOAT64)
        END AS test_value,
        CASE
            WHEN REGEXP_CONTAINS(TRIM(test_value), r'^((\d*)(\.(\d+))?)\s*%$') THEN '%'
        ELSE TRIM(UPPER(test_units)) -- standardizing case of units
        END AS test_units,
        m.test_name_mapped AS test_name,
        COALESCE(t.test_name_source, m.col_1_value) AS test_name_source,
        m.standard_unit
    FROM `**REDACTED**.full.tests` t
    INNER JOIN `**REDACTED**.full.test_name_mapping` m
        ON TRIM(UPPER(t.site)) = TRIM(UPPER(m.site))
        AND m.match_type = 'inclusion'
        AND m.col_1 = 'test_name'
        AND TRIM(UPPER(t.test_name)) = m.col_1_value
        AND (
                (
                    m.col_2 IS NULL
                ) OR (
                    m.col_2 = 'test_grouper'
                    AND (
                      TRIM(UPPER(t.test_grouper)) = TRIM(UPPER(m.col_2_value))
                      OR (m.col_2_value IS NULL AND (t.test_grouper IS NULL OR TRIM(t.test_grouper) = ''))
                    )
                    AND (
                      (m.col_3 IS NULL)
                      OR (
                        m.col_3 = 'test_other'
                        AND (
                          TRIM(UPPER(m.col_3_value)) = TRIM(UPPER(t.test_other))
                          OR (m.col_3_value IS NULL AND (t.test_other IS NULL OR TRIM(t.test_other) = ''))
                        )
                      )
                    )
                ) OR (
                    m.col_2 = 'test_specimen'
                    AND (
                        TRIM(UPPER(m.col_2_value)) = TRIM(UPPER(t.test_specimen))
                        OR (m.col_2_value IS NULL AND (t.test_specimen IS NULL OR TRIM(t.test_specimen) = ''))
                    )
                ) OR (
                    m.col_2 = 'test_units'
                    AND (
                        TRIM(UPPER(m.col_2_value)) = TRIM(UPPER(t.test_units))
                        OR (m.col_2_value IS NULL AND (t.test_units IS NULL OR TRIM(t.test_units) = ''))
                    )
                )
        )
) base
LEFT JOIN `**REDACTED**.full.test_unit_mapping_configuration` u
    ON TRIM(UPPER(base.site)) = TRIM(UPPER(u.site)) AND
    TRIM(UPPER(base.test_name)) = TRIM(UPPER(u.test_name)) AND
    TRIM(base.test_units) = TRIM(UPPER(u.unit_match))
;

/*
The above includes all the tests we want, but also includes a few we don't want. Drop those
using 'exclusion' rows from the configuration table
*/
CREATE OR REPLACE TABLE `**REDACTED**.full.tests_phase2` AS

SELECT
  *
FROM `**REDACTED**.full.tests_phase1`

EXCEPT DISTINCT

SELECT
  t.*
FROM `**REDACTED**.full.tests_phase1` t
INNER JOIN `**REDACTED**.full.test_name_mapping` m
  ON
    m.match_type = 'exclusion'
    AND m.col_1 = 'test_name'
    AND TRIM(UPPER(t.test_name_source)) = m.col_1_value
    AND TRIM(UPPER(t.site)) = TRIM(UPPER(m.site))
    AND (
      (
        m.col_2 IS NULL
        AND m.col_3 IS NULL)
      OR (
        m.col_2 = 'test_grouper'
        AND TRIM(UPPER(t.test_grouper)) = m.col_2_value
        AND m.col_3 IS NULL)
      OR (
        m.col_2 = 'test_grouper'
        AND m.col_3 = 'test_units'
        AND TRIM(UPPER(t.test_grouper)) = m.col_2_value
        AND TRIM(UPPER(t.test_units_source)) = m.col_3_value)
      OR (
        m.col_2 = 'test_specimen'
        AND TRIM(UPPER(t.test_specimen)) = m.col_2_value)
      OR (
        m.col_2 = 'test_units'
        AND TRIM(UPPER(t.test_units)) = m.col_2_value)
    )
;

/*

Process to update tests based on criteria in tests_value_parser_configuration

*/
CREATE OR REPLACE TABLE `**REDACTED**.full.tests_phase3` AS

SELECT DISTINCT
  t.site,
  t.enc_id,
  t.test_grouper,
  c.param_string_1 AS test_name,
  t.test_name_source,
  ABS(test_value) AS test_value,
  t.test_value_source,
  t.orig_test_value_source,
  t.test_specimen,
  t.test_ordered_time,
  t.test_obtained_time,
  t.test_result_time,
  t.test_units,
  t.test_units_source,
  t.standard_unit,
  t.test_other,
FROM `**REDACTED**.full.tests_phase2` t
INNER JOIN `**REDACTED**.full.tests_value_parser_configuration` c
  ON c.type = 'base_exc_to_base_def'
  AND c.test_name = t.test_name
  AND test_value < c.param_int_1

UNION ALL

SELECT DISTINCT
  t.site,
  t.enc_id,
  t.test_grouper,
  c.param_string_1 AS test_name,
  t.test_name_source,
  t.test_value,
  t.test_value_source,
  t.orig_test_value_source,
  t.test_specimen,
  t.test_ordered_time,
  t.test_obtained_time,
  t.test_result_time,
  t.test_units,
  t.test_units_source,
  c.param_string_2 AS standard_unit,
  t.test_other,
FROM `**REDACTED**.full.tests_phase2` t
INNER JOIN `**REDACTED**.full.tests_value_parser_configuration` c
  ON c.type = 'map_lymph_to_pct'
  AND t.test_name = c.test_name
  AND t.site = c.site
  AND test_units_source = c.param_string_2

UNION ALL

SELECT DISTINCT
  t.site,
  t.enc_id,
  t.test_grouper,
  t.test_name,
  t.test_name_source,
  CASE
    WHEN t.test_value_source IS NOT NULL
      AND ARRAY_LENGTH(REGEXP_EXTRACT_ALL(t.test_value_source, r',')) = 1
      THEN SAFE_CAST(REPLACE(t.test_value_source, ',', '.') AS FLOAT64)
    ELSE t.test_value
  END AS test_value,
  t.test_value_source,
  t.orig_test_value_source,
  t.test_specimen,
  t.test_ordered_time,
  t.test_obtained_time,
  t.test_result_time,
  t.test_units,
  t.test_units_source,
  t.standard_unit,
  t.test_other
FROM `**REDACTED**.full.tests_phase2` t
INNER JOIN `**REDACTED**.full.tests_value_parser_configuration` c
  ON c.type = 'numeric_notation'
  AND t.test_name IN (c.test_name)
  AND t.site = c.site

UNION ALL
(
SELECT
  site,
  enc_id,
  test_grouper,
  test_name,
  test_name_source,
  test_value,
  test_value_source,
  orig_test_value_source,
  test_specimen,
  test_ordered_time,
  test_obtained_time,
  test_result_time,
  test_units,
  test_units_source,
  standard_unit,
  test_other
FROM `**REDACTED**.full.tests_phase2`

EXCEPT DISTINCT

SELECT
  t.site,
  t.enc_id,
  t.test_grouper,
  t.test_name,
  t.test_name_source,
  t.test_value,
  t.test_value_source,
  t.orig_test_value_source,
  t.test_specimen,
  t.test_ordered_time,
  t.test_obtained_time,
  t.test_result_time,
  t.test_units,
  t.test_units_source,
  t.standard_unit,
  t.test_other,
FROM `**REDACTED**.full.tests_phase2` t
INNER JOIN `**REDACTED**.full.tests_value_parser_configuration` c
  ON
  (
    c.type = 'base_exc_to_base_def'
    AND c.test_name = t.test_name
    AND test_value < c.param_int_1
  )
  OR
  (
    c.type = 'map_lymph_to_pct'
    AND t.test_name = c.test_name
    AND t.site = c.site
    AND test_units_source = c.param_string_2
  )
  OR
  (
      c.type = 'numeric_notation'
      AND t.test_name IN (c.test_name)
      AND t.site = c.site
  )
)
;

/*

Process to filter values outside of possible range. Current logic will get rid of non-numeric values
in addition to values outside min_value to max_value.

Also at this point all units should have been standardized, so replace unit with standardized name
if missed in previous steps

*/
CREATE OR REPLACE TABLE `**REDACTED**.full.tests_phase4` AS
SELECT
  site,
  enc_id,
  test_grouper,
  test_name,
  test_name_source,
  test_value,
  test_value_source,
  orig_test_value_source,
  test_specimen,
  test_ordered_time,
  test_obtained_time,
  test_result_time,
  t.standard_unit AS test_units,
  test_units_source,
  test_other,
FROM `**REDACTED**.full.tests_phase3` t
LEFT JOIN `**REDACTED**.full.standard_names_and_units` s
  ON t.test_name = s.standard_name
WHERE
  s.type IS NULL -- rows with no entry in standar_names_and_units
  OR
  (
  s.type = 'tests'
  AND test_value IS NOT NULL
  -- filter values if min/max value provided
  AND ((min_value IS NULL)
    OR (min_value IS NOT NULL AND test_value >= min_value))
  AND ((max_value IS NULL)
    OR (max_value IS NOT NULL AND test_value <= max_value))
  )
;

-- some virus tests have result that identifies a generically named test as something more specific
CREATE OR REPLACE TABLE `**REDACTED**.full.tests_phase5` AS
SELECT t.* EXCEPT(test_name),
  CASE
    WHEN m.test_name IS NULL THEN t.test_name
    ELSE UPPER(m.test_name)
    END AS test_name
FROM `**REDACTED**.full.tests_phase4` t
LEFT JOIN `**REDACTED**.full.test_value_to_test_name_configuration` m
  ON t.site = m.site
  AND LOWER(t.test_value_source) = LOWER(TRIM(m.test_value))
;

-- done selecting/filtering/processing tests now copy to harmonized dataset
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.tests` AS
SELECT DISTINCT * FROM `**REDACTED**.full.tests_phase5`
;

-- check for duplicate rows - should be 0
SELECT
  site,
  enc_id,
  test_grouper,
  test_specimen,
  test_ordered_time,
  test_obtained_time,
  test_result_time,
  test_other,
  test_value_source,
  orig_test_value_source,
  test_name,
  test_name_source,
  test_units_source,
  test_units,
  test_value,
  COUNT(1)
FROM `**REDACTED**.harmonized.tests`
GROUP BY
  site,
  enc_id,
  test_grouper,
  test_specimen,
  test_ordered_time,
  test_obtained_time,
  test_result_time,
  test_other,
  test_value_source,
  orig_test_value_source,
  test_name,
  test_name_source,
  test_units_source,
  test_units,
  test_value
HAVING COUNT(1) > 1
ORDER BY site, test_name, test_name_source
;

-- smaller summary table with some different information from tests_checks
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.tests_checks_abbrev` AS

SELECT
    t.site,
    test_name,
    test_units,
    biennial_admission,
    count(DISTINCT t.enc_id) AS unique_encounters,
    count(t.enc_id) AS total_obs,
    ROUND(count(t.enc_id) / count(DISTINCT t.enc_id), 2) AS tests_per_encounter
FROM `**REDACTED**.harmonized.tests` t
    LEFT JOIN `**REDACTED**.harmonized.encounters` e
    ON t.enc_id = e.enc_id
    AND t.site = e.site
GROUP BY
    site,
    test_name,
    test_units,
    biennial_admission
ORDER BY
    test_name,
    biennial_admission,
    test_units,
    site
;

EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_checks_abbrev_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT *
FROM `**REDACTED**.harmonized.tests_checks_abbrev`
ORDER BY site, test_name
;

-- view to show rough counts of tests
CREATE OR REPLACE VIEW `**REDACTED**.harmonized.tests_mapping_counts` AS
SELECT
  e.test_name,
  s.in_od_score,
  e.site,
  COUNT(DISTINCT e.enc_id) AS num_encounters,
  COUNT(DISTINCT p.pat_id) AS num_patients,
  COUNT(1) AS num_obs,
  ROUND(COUNT(DISTINCT e.enc_id) / COUNT(1), 3) AS obs_per_encounter,
  ROUND(COUNT(DISTINCT p.pat_id) / COUNT(1), 3) AS obs_per_patient
FROM `**REDACTED**.harmonized.tests` e
LEFT JOIN `**REDACTED**.full.standard_names_and_units` s
  ON s.type = 'tests'
  AND e.test_name = s.standard_name
LEFT JOIN `**REDACTED**.harmonized.encounters` p
  ON e.site = p.site
  AND e.enc_id = p.enc_id
GROUP BY site, test_name, in_od_score
ORDER BY test_name, site
;

EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_mapping_counts_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT *
FROM `**REDACTED**.harmonized.tests_mapping_counts`
ORDER BY test_name, site
;

-- query to see which mappings don't have any matches
-- most like keep these in case get matching data with next feed from site.
EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_mappings_with_no_matches_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT
  m.*
FROM `**REDACTED**.full.test_name_mapping_configuration` m
LEFT JOIN `**REDACTED**.full.tests` t
  ON m.site = t.site
  AND m.col_1 = 'test_name'
  AND TRIM(UPPER(m.col_1_value)) = TRIM(UPPER(t.test_name))
  AND TRIM(UPPER(t.test_name)) = TRIM(UPPER(m.col_1_value))
  AND (
    (
      m.col_2 IS NULL
    ) OR (
      m.col_2 = 'test_grouper'
      AND (
        TRIM(UPPER(t.test_grouper)) = TRIM(UPPER(m.col_2_value))
        OR (m.col_2_value IS NULL AND (t.test_grouper IS NULL OR TRIM(t.test_grouper) = ''))
      )
      AND (
        (m.col_3 IS NULL)
        OR (
          m.col_3 = 'test_other'
          AND (
            TRIM(UPPER(m.col_3_value)) = TRIM(UPPER(t.test_other))
            OR (m.col_3_value IS NULL AND (t.test_other IS NULL OR TRIM(t.test_other) = ''))
          )
        )
      )
    ) OR (
      m.col_2 = 'test_specimen'
      AND (
        TRIM(UPPER(m.col_2_value)) = TRIM(UPPER(t.test_specimen))
        OR (m.col_2_value IS NULL AND (t.test_specimen IS NULL OR TRIM(t.test_specimen) = ''))
      )
    ) OR (
      m.col_2 = 'test_units'
      AND (
        TRIM(UPPER(m.col_2_value)) = TRIM(UPPER(t.test_units))
        OR (m.col_2_value IS NULL AND (t.test_units IS NULL OR TRIM(t.test_units) = ''))
      )
    )
  )
WHERE t.test_name IS NULL
  AND match_type = 'inclusion'
ORDER BY site, test_name_mapped
;

-- same test name source mapping to multiple harmonized tests
EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_name_multi_mappings_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT m.*
FROM `**REDACTED**.full.test_name_mapping` m
INNER JOIN (
  SELECT site, col_1_value, count(1)
  FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1 IS NOT NULL
    AND col_2 IS NULL
    AND col_3 IS NULL
    AND match_type = 'inclusion'
  GROUP BY site, col_1_value
  HAVING count(1) > 1
) d
ON d.site = m.site
AND d.col_1_value = m.col_1_value
;

-- same test_name and test_grouper or test_name and test_specimen mapped to multiple harmonized tests
EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_grouper_or_specimen_multi_mappings_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT m.*
FROM `**REDACTED**.full.test_name_mapping` m
INNER JOIN (
  SELECT site, col_1_value, col_2_value, count(1)
  FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1 IS NOT NULL
    AND col_2 IS NOT NULL
    AND col_3 IS NULL
    AND match_type = 'inclusion'
  GROUP BY site, col_1_value, col_2_value
  HAVING count(1) > 1
) d
ON d.site = m.site
AND d.col_1_value = m.col_1_value
AND d.col_2_value = m.col_2_value
;


-- Need to check for rows where test_name only match also present for grouper/specimen match
EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/tests_name_override_mappings_*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
-- show test_name only mappings that conflict
SELECT DISTINCT a.*
FROM (
  -- test_name only mappings
  SELECT * FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1_value IS NOT NULL
    AND col_2 IS NULL
    AND match_type = 'inclusion'
) a
INNER JOIN (
  -- test_name and test_grouper or
  -- test_name and test_speciment mappings
  SELECT * FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1_value IS NOT NULL
    -- can't use col_2_value as test_specimen mappings can be NULL and correct
    AND col_2 IS NOT NULL
    AND match_type = 'inclusion'
) b
ON a.site = b.site
AND a.col_1_value = b.col_1_value
AND a.test_name_mapped = b.test_name_mapped

UNION ALL

-- show test_name and X mappings that conflict
SELECT DISTINCT b.*
FROM (
  SELECT * FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1_value IS NOT NULL
    AND col_2 IS NULL
    AND match_type = 'inclusion'
) a
INNER JOIN (
  -- test_name and test_grouper or
  -- test_name and test_speciment mappings
  SELECT * FROM `**REDACTED**.full.test_name_mapping`
  WHERE 1=1
    AND col_1_value IS NOT NULL
    -- can't use col_2_value as test_specimen mappings can be NULL and correct
    AND col_2 IS NOT NULL
    AND match_type = 'inclusion'
) b
ON a.site = b.site
AND a.col_1_value = b.col_1_value
AND a.test_name_mapped = b.test_name_mapped

ORDER BY site, test_name_mapped, col_1_value, col_2
;