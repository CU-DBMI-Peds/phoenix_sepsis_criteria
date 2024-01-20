#!/bin/bash
# need table created in multiple schemas, so using bash
# to templatize the script
set -x
query_template=""

for dataset in full harmonized
do
  query_template+="
  CREATE OR REPLACE TABLE \`**REDACTED**.$dataset.tests_checks\` AS

  WITH m AS (
      SELECT DISTINCT
          site,
          test_name_source,
          test_name,
          biennial_admission,
          test_units,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.50) OVER (PARTITION BY site, test_name_source, test_name, biennial_admission, test_units), 3) AS median,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.25) OVER (PARTITION BY site, test_name_source, test_name, biennial_admission, test_units), 3) AS quart25,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.75) OVER (PARTITION BY site, test_name_source, test_name, biennial_admission, test_units), 3) AS quart75
      FROM (
      SELECT
          t.* EXCEPT(test_units),
          COALESCE(test_units, '') AS test_units,
          e.biennial_admission,
          SAFE_CAST(test_value AS FLOAT64) AS test_value_numeric
      FROM \`**REDACTED**.$dataset.tests\` t
          LEFT JOIN \`**REDACTED**.$dataset.encounters\` e
          ON t.enc_id = e.enc_id
          AND t.site = e.site
      WHERE SAFE_CAST(test_value AS FLOAT64) IS NOT NULL
      )
  )

  SELECT
      q.*,
      m.* EXCEPT (site, test_name_source, test_name, biennial_admission, test_units)
  FROM (
      SELECT
          site,
          test_name_source,
          test_name,
          test_units,
          biennial_admission,
          COUNT(1) AS test_count,
          MIN(test_value_numeric) AS min,
          MAX(test_value_numeric) AS max,
          ROUND(AVG(test_value_numeric), 3) AS mean,
          ROUND(STDDEV(test_value_numeric), 3) AS sd
      FROM (
          SELECT
              t.* EXCEPT(test_units),
              COALESCE(test_units, '') AS test_units,
              e.biennial_admission,
              SAFE_CAST(test_value AS FLOAT64) AS test_value_numeric
          FROM \`**REDACTED**.$dataset.tests\` t
              LEFT JOIN \`**REDACTED**.$dataset.encounters\` e
              ON t.enc_id = e.enc_id
              AND t.site = e.site
          WHERE SAFE_CAST(test_value AS FLOAT64) IS NOT NULL
          )
      GROUP BY site, test_name_source, test_name, test_units, biennial_admission
      ) q LEFT JOIN m ON
      q.site = m.site AND
      q.test_name_source = m.test_name_source AND
      q.test_name = m.test_name AND
      q.biennial_admission = m.biennial_admission AND
      q.test_units = m.test_units
  ORDER BY site, test_name_source, test_name, test_units, biennial_admission
  ;"

  bq extract \
  --destination_format CSV \
  --field_delimiter ',' \
  **REDACTED**:$dataset.tests_checks \
  gs://**REDACTED**/qa/test_checks_$dataset\_*.csv

done

bq query $query_template

query_template=""

for dataset in full harmonized
do
  query_template+="
  CREATE OR REPLACE TABLE \`**REDACTED**.$dataset.tests_checks_with_grouper\` AS

  WITH m AS (
      SELECT DISTINCT
          site,
          test_grouper,
          test_name_source,
          test_name,
          biennial_admission,
          test_units,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.50) OVER (PARTITION BY site, test_grouper, test_name_source, test_name, biennial_admission, test_units), 3) AS median,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.25) OVER (PARTITION BY site, test_grouper, test_name_source, test_name, biennial_admission, test_units), 3) AS quart25,
          ROUND(PERCENTILE_CONT(test_value_numeric, 0.75) OVER (PARTITION BY site, test_grouper, test_name_source, test_name, biennial_admission, test_units), 3) AS quart75
      FROM (
      SELECT
          t.* EXCEPT(test_units),
          COALESCE(test_units, '') AS test_units,
          e.biennial_admission,
          SAFE_CAST(test_value AS FLOAT64) AS test_value_numeric
      FROM \`**REDACTED**.$dataset.tests\` t
          LEFT JOIN \`**REDACTED**.$dataset.encounters\` e
          ON t.enc_id = e.enc_id
          AND t.site = e.site
      WHERE SAFE_CAST(test_value AS FLOAT64) IS NOT NULL
      )
  )

  SELECT
      q.*,
      m.* EXCEPT (site, test_grouper, test_name_source, test_name, biennial_admission, test_units)
  FROM (
      SELECT
          site,
          test_grouper,
          test_name_source,
          test_name,
          test_units,
          biennial_admission,
          COUNT(1) AS test_count,
          MIN(test_value_numeric) AS min,
          MAX(test_value_numeric) AS max,
          ROUND(AVG(test_value_numeric), 3) AS mean,
          ROUND(STDDEV(test_value_numeric), 3) AS sd
      FROM (
          SELECT
              t.* EXCEPT(test_units),
              COALESCE(test_units, '') AS test_units,
              e.biennial_admission,
              SAFE_CAST(test_value AS FLOAT64) AS test_value_numeric
          FROM \`**REDACTED**.$dataset.tests\` t
              LEFT JOIN \`**REDACTED**.$dataset.encounters\` e
              ON t.enc_id = e.enc_id
              AND t.site = e.site
          WHERE SAFE_CAST(test_value AS FLOAT64) IS NOT NULL
          )
      GROUP BY site, test_grouper, test_name_source, test_name, test_units, biennial_admission
      ) q LEFT JOIN m ON
      q.site = m.site AND
      q.test_grouper = m.test_grouper AND
      q.test_name_source = m.test_name_source AND
      q.test_name = m.test_name AND
      q.biennial_admission = m.biennial_admission AND
      q.test_units = m.test_units
  ORDER BY site, test_grouper, test_name_source, test_name, test_units, biennial_admission
  ;"

  bq extract \
  --destination_format CSV \
  --field_delimiter ',' \
  **REDACTED**:$dataset.tests_checks_with_grouper \
  gs://**REDACTED**/qa/tests_checks_with_grouper_$dataset\_*.csv

done

bq query $query_template
