#standardSQL
/******************************************************************************

Build comorbidities.

Previous harmonization processes should make sure all codes are uppercase only

FYI, tried these options:

  AND STARTS_WITH(REPLACE(d.diagnosis_code, '.', ''), c.code)
  AND REPLACE(d.diagnosis_code, '.', '') LIKE c.code || '%'
  AND REGEXP_CONTAINS(REPLACE(d.diagnosis_code, '.', ''), r'^(' || c.code || ')')

For large datasets (20M rows) STARTS_WITH() is significantly faster

Notes:

* During this process I discovered that there are 3 encouters that have
no pat_id. Those persons are dropped from the PCCC tables.
* Some patients appear to not have encounters. The pccc_patient summary
joins against the patients table to prevent no PCCC records for patients.
* Right now the pccc_patients table has NULL for patients who have NO diagnoses
and NO procedures.

******************************************************************************/
DECLARE cond_coalesce STRING;
DECLARE conditions STRING;
DECLARE cond_sum STRING;

CREATE OR REPLACE TABLE `**REDACTED**.harmonized.pccc_diagnosis_detail` AS

SELECT *,
  REPLACE(d.diagnosis_code, '.', '') AS match_code
FROM `**REDACTED**.harmonized.diagnosis_codes` d
INNER JOIN `**REDACTED**.utilities.comorbidity_configuration` c
  ON LOWER(d.diagnosis_code_system) = LOWER(c.code_system)
  -- previous processes should make sure all codes are uppercase only
  AND REPLACE(d.diagnosis_code, '.', '') = c.code
WHERE 1=1
  AND c.fixed = TRUE
  AND c.type = 'dx'
  AND c.comorbidity_system = 'pccc'

UNION ALL

SELECT *,
  REPLACE(d.diagnosis_code, '.', '') AS match_code
FROM `**REDACTED**.harmonized.diagnosis_codes` d
INNER JOIN `**REDACTED**.utilities.comorbidity_configuration` c
  ON LOWER(d.diagnosis_code_system) = LOWER(c.code_system)
  -- previous processes should make sure all codes are uppercase only
  AND STARTS_WITH(REPLACE(d.diagnosis_code, '.', ''), c.code)
WHERE 1=1
  AND c.fixed = FALSE
  AND c.type = 'dx'
  AND c.comorbidity_system = 'pccc'
;

CREATE OR REPLACE TABLE `**REDACTED**.harmonized.pccc_procedure_detail` AS

SELECT *,
  REPLACE(d.procedure_code, '.', '') AS match_code
FROM `**REDACTED**.harmonized.procedure_codes` d
INNER JOIN `**REDACTED**.utilities.comorbidity_configuration` c
  ON LOWER(d.procedure_code_system) LIKE LOWER(c.code_system) || '%'
  -- previous processes should make sure all codes are uppercase only
  AND REPLACE(d.procedure_code, '.', '') = c.code
WHERE 1=1
  AND c.fixed = TRUE
  AND c.type = 'pc'
  AND c.comorbidity_system = 'pccc'

UNION ALL

SELECT *,
  REPLACE(d.procedure_code, '.', '') AS match_procedure_code
FROM `**REDACTED**.harmonized.procedure_codes` d
INNER JOIN `**REDACTED**.utilities.comorbidity_configuration` c
  ON LOWER(d.procedure_code_system) LIKE LOWER(c.code_system) || '%'
  -- previous processes should make sure all codes are uppercase only
  AND STARTS_WITH(REPLACE(d.procedure_code, '.', ''), c.code)
WHERE 1=1
  AND c.fixed = FALSE
  AND c.type = 'pc'
  AND c.comorbidity_system = 'pccc'
;

SET cond_coalesce = (
  SELECT DISTINCT
    STRING_AGG(DISTINCT 'COALESCE(' || condition || ', FALSE) AS ' || condition)
  FROM `**REDACTED**.utilities.comorbidity_configuration`
  WHERE comorbidity_system = 'pccc'
);

SET conditions = (
  SELECT
    CONCAT('("', STRING_AGG(DISTINCT condition, '", "'), '")'),
  FROM `**REDACTED**.utilities.comorbidity_configuration`
  WHERE comorbidity_system = 'pccc'
);

EXECUTE IMMEDIATE format("""
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.pccc_encounters` AS
SELECT
  COALESCE(e.site, p.site) AS site,
  e.pat_id,
  COALESCE(e.enc_id, p.enc_id) AS enc_id,
  %s,
FROM (
  SELECT DISTINCT
    site,
    enc_id,
    condition,
    TRUE AS val
  FROM `**REDACTED**.harmonized.pccc_diagnosis_detail`
  UNION ALL
  SELECT DISTINCT
    site,
    enc_id,
    condition,
    TRUE AS val
  FROM `**REDACTED**.harmonized.pccc_procedure_detail`
)
PIVOT
(
  MAX(val)
  FOR condition IN %s
) p
FULL JOIN `**REDACTED**.harmonized.encounters` e
  ON p.enc_id = e.enc_id
-- drop encounters with no patient id
WHERE e.pat_id IS NOT NULL
""", cond_coalesce, conditions);

SET cond_sum = (
  SELECT DISTINCT
    STRING_AGG(DISTINCT 'MAX(' || condition || ') AS ' || condition)
  FROM `**REDACTED**.utilities.comorbidity_configuration`
  WHERE comorbidity_system = 'pccc'
);

EXECUTE IMMEDIATE format("""
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.pccc_patients` AS
SELECT
  COALESCE(p.site, e.site) AS site,
  COALESCE(p.pat_id, e.pat_id) AS pat_id,
  %s,
FROM `**REDACTED**.harmonized.pccc_encounters` e
FULL JOIN `**REDACTED**.harmonized.patients` p
  ON e.pat_id = p.pat_id
GROUP BY e.site, p.site, e.pat_id, p.pat_id
""", cond_sum)
;


-- Create additional columns to account for time and when the pccc flag should
-- be 1 or 0
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.pccc_encounters` AS
(
  WITH T AS (
    SELECT
        a.site
      , a.pat_id
      , b.age_days
      , a.enc_id
      , IF(a.congeni_genetic, 1, 0) AS congeni_genetic_this_enc
      , IF(a.cvd, 1, 0)             AS cvd_this_enc
      , IF(a.gi, 1, 0)              AS gi_this_enc
      , IF(a.hemato_immu, 1, 0)     AS hemato_immu_this_enc
      , IF(a.malignancy, 1, 0)      AS malignancy_this_enc
      , IF(a.metabolic, 1, 0)       AS metabolic_this_enc
      , IF(a.neonatal, 1, 0)        AS neonatal_this_enc
      , IF(a.neuromusc, 1, 0)       AS neuromusc_this_enc
      , IF(a.renal, 1, 0)           AS renal_this_enc
      , IF(a.respiratory, 1, 0)     AS respiratory_this_enc
      , IF(a.tech_dep, 1, 0)        AS tech_dep_this_enc
      , IF(a.transplant, 1, 0)      AS transplant_this_enc
      , IF(SUM(IF(a.congeni_genetic, 1, 0)) OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS congeni_genetic_this_enc_forward
      , IF(SUM(IF(a.cvd, 1, 0))             OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS cvd_this_enc_forward
      , IF(SUM(IF(a.gi, 1, 0))              OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS gi_this_enc_forward
      , IF(SUM(IF(a.hemato_immu, 1, 0))     OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS hemato_immu_this_enc_forward
      , IF(SUM(IF(a.malignancy, 1, 0))      OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS malignancy_this_enc_forward
      , IF(SUM(IF(a.metabolic, 1, 0))       OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS metabolic_this_enc_forward
      , IF(SUM(IF(a.neonatal, 1, 0))        OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS neonatal_this_enc_forward
      , IF(SUM(IF(a.neuromusc, 1, 0))       OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS neuromusc_this_enc_forward
      , IF(SUM(IF(a.renal, 1, 0))           OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS renal_this_enc_forward
      , IF(SUM(IF(a.respiratory, 1, 0))     OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS respiratory_this_enc_forward
      , IF(SUM(IF(a.tech_dep, 1, 0))        OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS tech_dep_this_enc_forward
      , IF(SUM(IF(a.transplant, 1, 0))      OVER (PARTITION BY a.site, a.pat_id ORDER BY b.age_days) > 0, 1, 0) AS transplant_this_enc_forward
    FROM `**REDACTED**.harmonized.pccc_encounters` a
    LEFT JOIN
    `**REDACTED**.harmonized.encounters` b
    ON a.site = b.site AND
       a.pat_id = b.pat_id AND
       a.enc_id = b.enc_id
  )

  SELECT
      *
    , IF(SUM(congeni_genetic_this_enc_forward) OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS congeni_genetic_prior_to_this_enc
    , IF(SUM(cvd_this_enc_forward)             OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS cvd_prior_to_this_enc
    , IF(SUM(gi_this_enc_forward)              OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS gi_prior_to_this_enc
    , IF(SUM(hemato_immu_this_enc_forward)     OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS hemato_immu_prior_to_this_enc
    , IF(SUM(malignancy_this_enc_forward)      OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS malignancy_prior_to_this_enc
    , IF(SUM(metabolic_this_enc_forward)       OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS metabolic_prior_to_this_enc
    , IF(SUM(neonatal_this_enc_forward)        OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS neonatal_prior_to_this_enc
    , IF(SUM(neuromusc_this_enc_forward)       OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS neuromusc_prior_to_this_enc
    , IF(SUM(renal_this_enc_forward)           OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS renal_prior_to_this_enc
    , IF(SUM(respiratory_this_enc_forward)     OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS respiratory_prior_to_this_enc
    , IF(SUM(tech_dep_this_enc_forward)        OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS tech_dep_prior_to_this_enc
    , IF(SUM(transplant_this_enc_forward)      OVER (PARTITION BY site, pat_id ORDER BY age_days) > 1, 1, 0) AS transplant_prior_to_this_enc
  FROM T
  ORDER BY site, pat_id, age_days
)
;
