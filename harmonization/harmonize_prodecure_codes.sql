#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.harmonized.procedure_codes` AS
SELECT DISTINCT
  site,
  enc_id,
  UPPER(TRIM(procedure_code)) AS procedure_code,
  -- as '_source' is our standard for the original value of a column, changing name
  UPPER(TRIM(procedure_code_source)) AS procedure_code_system_source,
  procedure_name,
  procedure_time,
  procedure_other,
  CASE
    WHEN UPPER(TRIM(procedure_code_source)) IN ('ICD-9-CM', 'ICD-9-CM PROCEDURE CODE') THEN 'ICD9PCS'
    WHEN UPPER(TRIM(procedure_code_source)) IN ('ICD-10-CM', 'ICD-10-CM PROCEDURE CODE', 'ICD-10-PCS', 'ICD10PCS') THEN 'ICD10PCS'
    WHEN UPPER(TRIM(procedure_code_source)) IN ('CPT', 'CPT(R)', 'CPT4') THEN 'CPT'
    WHEN TRIM(procedure_code_source) = '' THEN NULL
    ELSE UPPER(TRIM(procedure_code_source))
  END AS procedure_code_system
FROM `**REDACTED**.full.procedure_codes`
;