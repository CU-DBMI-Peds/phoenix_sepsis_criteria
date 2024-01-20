#standardSQL

/*
some sites report multiple codes per row, comma separated
split them to their own row for use with comorbidity code
*/
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.diagnosis_codes` AS
SELECT DISTINCT
  * EXCEPT(diagnosis_code_system),
  CASE
    WHEN diagnosis_code_system IN ('ICD-10', 'ICD-10-CM', 'ICD-10_CM') THEN 'ICD10'
    WHEN diagnosis_code_system IN ('ICD-9-CM') THEN 'ICD9'
    WHEN diagnosis_code_system = '' THEN NULL
    ELSE diagnosis_code_system
  END AS diagnosis_code_system,
  diagnosis_code_system AS diagnosis_code_system_source
FROM (
  SELECT * EXCEPT (diagnosis_code_arr, diagnosis_code_arr_length)
  FROM (
  SELECT
    *,
    SPLIT(diagnosis_code_source, ',') AS diagnosis_code_arr,
    -- this column for troubleshooting/validation
    ARRAY_LENGTH(SPLIT(diagnosis_code_source, ',')) AS diagnosis_code_arr_length
  FROM (
    SELECT
      * EXCEPT(diagnosis_code, diagnosis_code_source),
      UPPER(TRIM(REGEXP_REPLACE(diagnosis_code, r'\s+', ''))) AS diagnosis_code_source,
      -- as '_source' is our standard for the original value of a column, changing name
      UPPER(TRIM(diagnosis_code_source)) AS diagnosis_code_system
    FROM `**REDACTED**.full.diagnosis_codes`
    )
  ) d_inner
  CROSS JOIN d_inner.diagnosis_code_arr AS diagnosis_code
)
;