/*
Views and tables to curate ADT information.

Due to complexities involved with creating OR episodes, that portion is in a different file.
*/

/*
part 1 harmonize ADT location information

**REDACTED** and **REDACTED** use adt_other to indicate a discharge disposition
in all cases I've seen adt_other matches encounter discharge disposition
*/
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.adt` AS

WITH adt AS (

  SELECT * EXCEPT(adt_type),
    CASE
      WHEN adt_type = 'admitted to' THEN 'admission'
      WHEN adt_type = 'discharged' THEN 'discharge'
      WHEN adt_type IN ('transferred to', 'transfer in') THEN 'transfer to'
      ELSE adt_type
    END AS adt_type,
  FROM (
    SELECT
      site,
      enc_id,
      TRIM(LOWER(adt_type)) AS adt_type,
      TRIM(LOWER(adt_location)) AS adt_location,
      adt_time,
      CASE
        WHEN TRIM(LOWER(adt_other)) = 'na' OR TRIM(LOWER(adt_other)) = '' THEN NULL
        ELSE TRIM(LOWER(adt_other))
        END AS adt_other
    FROM `**REDACTED**.full.adt`
  )
)

SELECT DISTINCT
    adt.site,
    adt.enc_id,
    adt.adt_type,
    m.adt_location_mapped AS adt_location,
    adt.adt_location AS adt_location_source,
    adt_time,
    adt.adt_other
FROM adt
LEFT JOIN `**REDACTED**.full.adt_mapping_configuration` m
  ON adt.site = m.site
  AND adt.adt_location LIKE m.adt_location
WHERE m.adt_location IS NOT NULL

UNION ALL

SELECT DISTINCT
    adt.site,
    adt.enc_id,
    adt.adt_type,
    'unmapped' AS adt_location,
    adt.adt_location AS adt_location_source,
    adt_time,
    adt.adt_other
FROM adt
LEFT JOIN `**REDACTED**.full.adt_mapping_configuration` m
  ON adt.site = m.site
  AND adt.adt_location LIKE m.adt_location
WHERE m.adt_location IS NULL
;

CREATE OR REPLACE TABLE `**REDACTED**.harmonized.los` AS
SELECT
  *,
  COALESCE(e_los, a_los) AS los
FROM (
  SELECT
    COALESCE(e.site, a.site) AS site,
    COALESCE(e.enc_id, a.enc_id) AS enc_id,
    MAX(e.enc_end_time) AS e_los,
    MAX(a.adt_time) AS a_los
  FROM `**REDACTED**.harmonized.encounters` e
  FULL JOIN `**REDACTED**.harmonized.adt` a
    ON e.enc_id = a.enc_id
    AND e.site = a.site
  GROUP BY site, enc_id
)
;

/*
part 2 create summary by encounter
*/
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.adt_encounter_summary` AS
SELECT DISTINCT
  adt.site,
  adt.enc_id,
  CASE
    WHEN EXISTS (
      SELECT DISTINCT enc_id
      FROM `**REDACTED**.harmonized.adt` i
      WHERE i.site = adt.site
        AND i.enc_id = adt.enc_id
        AND adt_location LIKE '%icu'
    ) THEN 1
    ELSE 0
  END AS ever_icu,
  CASE
    WHEN adt.site = '**REDACTED**' THEN NULL
    WHEN EXISTS (
      SELECT DISTINCT enc_id
      FROM `**REDACTED**.harmonized.adt` i
      WHERE i.site = adt.site
        AND i.enc_id = adt.enc_id
        AND adt_location = 'emergency department'
    ) THEN 1
    ELSE 0
  END AS ever_ed,
  CASE
    WHEN adt.site = '**REDACTED**' THEN NULL
    WHEN EXISTS (
      SELECT DISTINCT enc_id
      FROM `**REDACTED**.harmonized.adt` i
      WHERE i.site = adt.site
        AND i.enc_id = adt.enc_id
        AND adt_location LIKE "%inpatient%"
    ) THEN 1
    ELSE 0
  END AS ever_ip,
  CASE
    WHEN adt.site = '**REDACTED**' THEN NULL
    WHEN EXISTS (
      SELECT DISTINCT enc_id
      FROM `**REDACTED**.harmonized.adt` i
      WHERE i.site = adt.site
        AND i.enc_id = adt.enc_id
        AND adt_location = 'operating room'
    ) THEN 1
    ELSE 0
  END AS ever_operation_adt,
  los.los
FROM `**REDACTED**.harmonized.adt` adt
LEFT JOIN `**REDACTED**.harmonized.los` los
  ON adt.site = los.site
    AND adt.enc_id = los.enc_id
;