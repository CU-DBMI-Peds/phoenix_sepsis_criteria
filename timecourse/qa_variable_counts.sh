#!/bin/bash
# need to cover multiple schemas, so using bash
# to templatize the script
set -x

query_template+="
SELECT DISTINCT
  CONCAT(
    'SELECT site, \"', table_name, '\" AS table_name, \"', column_name, '\" AS var_name, SAFE_CAST(', column_name, ' AS STRING) ',
    'AS var_value, \"rows\" AS cnt_type, COUNT(1) AS cnt ',
    'FROM \`', table_catalog, '.', table_schema, '.', table_name, '\` ',
    'GROUP BY site, ', column_name, ' ',
    'UNION ALL ',
    'SELECT site, \"', table_name, '\" AS table_name, \"', column_name, '\" AS var_name, SAFE_CAST(', column_name, ' AS STRING) ',
    'AS var_value, \"encs\" AS cnt_type, COUNT(DISTINCT enc_id) AS cnt ',
    'FROM \`', table_catalog, '.', table_schema, '.', table_name, '\` ',
    'GROUP BY site, ', column_name, ' ',
    'UNION ALL'
    ) AS query
FROM **REDACTED**.timecourse.INFORMATION_SCHEMA.COLUMNS
WHERE 1=1
  AND table_name NOT LIKE '%count%'
  AND column_name NOT IN ('site', 'enc_id', 'pat_id')
  AND column_name NOT LIKE 'eclock%'
  AND column_name NOT LIKE '%time%'
  AND column_name NOT LIKE '%_min'
  AND column_name NOT LIKE '%_max'
"

# if want to preserve sql for inspection
# echo -e "$query_template" > variable_counts_build.sql
bq query --format=csv $query_template > variable_counts_build_steps_phase1.sql

cat ./variable_counts_build_steps_phase1.sql | tail -n +2 | sed 's/""/"/g' | sed 's/^"//g' | sed 's/"$//g' | sed '$ s/ UNION ALL$//' > variable_counts_build_steps_phase2.sql
query_body=`cat variable_counts_build_steps_phase2.sql`

query="
DECLARE today STRING DEFAULT FORMAT_DATE('%Y%m%d', CURRENT_DATE());
  EXECUTE IMMEDIATE format('''
  CREATE OR REPLACE TABLE **REDACTED**.timecourse.timecourse_variable_counts_v2_%s AS
"
query+=$query_body
query+="''', today)"

# if want to preserve sql for inspection
# echo -e "$query" > variable_counts_build_steps_phase3.sql
# bq query < variable_counts_build_steps_phase3.sql > .build_variable_counts.log 2>&1
bq query $query