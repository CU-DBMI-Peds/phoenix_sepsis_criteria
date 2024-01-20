-- queries to check data
SELECT DISTINCT
  site
FROM `**REDACTED**.full.encounters`;

SELECT DISTINCT
  site, hosp_id
FROM `**REDACTED**.full.encounters`;

SELECT DISTINCT
  site,
  hosp_id,
  MIN(enc_start_time) AS min_enc_start_time,
  MAX(enc_start_time) AS max_enc_start_time,
  MIN(enc_end_time) AS min_enc_end_time,
  MAX(enc_end_time) AS max_enc_end_time,
  MIN(age_days) AS min_age_days,
  MAX(age_days) AS max_age_days,
  MIN(died_time) AS min_died_time,
  MAX(died_time) AS max_died_time
FROM `**REDACTED**.full.encounters`
GROUP BY site, hosp_id;

SELECT DISTINCT
  site,
  hosp_id,
  biennial_admission,
  count(1)
FROM `**REDACTED**.full.encounters`
GROUP BY site, hosp_id, biennial_admission
ORDER BY biennial_admission, site, hosp_id;

SELECT DISTINCT
  site,
  hosp_id,
  season_admission,
  count(1)
FROM `**REDACTED**.full.encounters`
GROUP BY site, hosp_id, season_admission
ORDER BY season_admission, site, hosp_id;

SELECT DISTINCT
  site,
  hosp_id,
  hospital_disposition,
  count(1)
FROM `**REDACTED**.full.encounters`
GROUP BY site, hosp_id, hospital_disposition
ORDER BY hospital_disposition, site, hosp_id;

-- Currently only hospital_dispositions need mapping/harmonization
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.encounters` AS
(
  WITH T AS
  (
    SELECT * EXCEPT(age_days, biennial_admission, hospital_disposition),
      age_days AS age_days_source,
      ABS(age_days) AS age_days, -- inspection of negative values, which are few, suggest that the abs is a valid age
      -- preserve original value
      hospital_disposition AS hospital_disposition_source,
      REGEXP_REPLACE(biennial_admission, r"\s", "") AS biennial_admission,
      CASE
        WHEN hospital_disposition IS NULL OR TRIM(hospital_disposition) = "" THEN NULL
        WHEN TRIM(LOWER(hospital_disposition)) LIKE '%expire%'
          OR TRIM(LOWER(hospital_disposition)) LIKE '%morgue%'
          OR TRIM(LOWER(hospital_disposition)) = 'dead'
          OR TRIM(LOWER(hospital_disposition)) LIKE 'deceased%'
          OR TRIM(LOWER(hospital_disposition)) = 'died'
          THEN 'Expired'
        WHEN TRIM(LOWER(hospital_disposition)) LIKE '%hospice%' THEN 'Discharge to Hospice'
        WHEN TRIM(LOWER(hospital_disposition)) IN (
            'alive',
            'discharge',
            'discharged (routine)',
            'discharged or transferred alive',
            'discharged',
            'edecu - discharge',
            'transfered')
          THEN 'Discharged or Transferred Alive'
        WHEN TRIM(LOWER(hospital_disposition)) = 'discharged to home'
          OR TRIM(LOWER(hospital_disposition)) = 'dc to home or self care (routine disch)'
          OR TRIM(LOWER(hospital_disposition)) = 'home'
          OR TRIM(LOWER(hospital_disposition)) LIKE '%home or self care'
          THEN 'Discharged to Home'
        WHEN TRIM(LOWER(hospital_disposition)) = 'transfer to another hospital'
          OR TRIM(LOWER(hospital_disposition)) = 'other inpatient facility'
          THEN 'Transfer to another Hospital'
        WHEN TRIM(LOWER(hospital_disposition)) = 'transfer to nursing home/rehab'
          THEN 'Transfer to nursing home/rehab'
        ELSE 'MAPPING NEEDED'
      END AS hospital_disposition
    FROM `**REDACTED**.full.encounters`
    -- Want to exclude these type of encounters from any analysis
    WHERE (
      TRIM(hospital_disposition) != 'Dismiss - Patient Never Arrived'
      OR hospital_disposition IS NULL -- keep null values in the harmonized table
    ) AND NOT (
      -- see issue https://**REDACTED**/issues/58
      -- decided to discard encounters with NULL or less than 1 LOS
      enc_start_time IS NULL
      OR enc_end_time IS NULL
      OR enc_start_time < 0
      OR enc_end_time < 0
    )
  )
  ,
  U AS
  (
    SELECT
        site
      , enc_id
      , pat_id
      , hosp_id
      , enc_start_time
      , MAX(enc_end_time) AS enc_end_time
      , biennial_admission
      , season_admission
      , died_time
      , ARRAY_AGG(age_days_source IGNORE NULLS) AS age_days_source
      , MAX(age_days) as age_days
      , ARRAY_AGG(hospital_disposition_source IGNORE NULLS) AS hospital_disposition_source
      , STRING_AGG(hospital_disposition) AS hospital_disposition
    FROM T
    GROUP BY site, enc_id, pat_id, hosp_id, enc_start_time, biennial_admission, season_admission, died_time
  )
  ,
  V AS
  (
    SELECT *, SUM(1) OVER (PARTITION BY site, pat_id ORDER BY age_days) AS enc_number
    FROM U
  )
  ,
  W AS
  (
    SELECT pat_id, MAX(enc_number) AS max_enc_number
    FROM V
    GROUP BY pat_id
  )

  SELECT V.*, IF(V.enc_number = W.max_enc_number, 1, 0) AS final_enc
  FROM V
  LEFT JOIN W
  ON V.pat_id = W.pat_id
)
;

-- Many items not yet mapped, so will have more than 0 rows.
SELECT * FROM `**REDACTED**.harmonized.encounters`
WHERE hospital_disposition = 'MAPPING NEEDED';

-- Verify hospital_disposition are as expected
SELECT IF(count(1) > 1, ERROR("At least one unexpected hospital_disposition in harmonized.encounters"), "PASS") AS hd_check
FROM
(
  SELECT hospital_disposition, count(1) AS N
  FROM `**REDACTED**.harmonized.encounters`
  GROUP BY hospital_disposition
)
WHERE hospital_disposition IS NOT NULL AND
      (
        hospital_disposition <> "MAPPING NEEDED" AND
        hospital_disposition <> "Expired"        AND
        hospital_disposition <> "Discharged to Home" AND
        hospital_disposition <> "Discharge to Hospice" AND
        hospital_disposition <> "Discharged or Transferred Alive" AND
        hospital_disposition <> "Transfer to another Hospital"
      )
;


-- Verify that there is one, and only one, row for each site, enc_id
SELECT IF(count(1) > 1, ERROR("At least one enc_id has more than one row in the harmonized.encounters"), "PASS") AS N_check
FROM `**REDACTED**.harmonized.encounters` a
INNER JOIN
(
  SELECT * FROM
  (
    SELECT site, enc_id, count(1) AS N
    FROM `**REDACTED**.harmonized.encounters`
    GROUP BY site, enc_id
  )
  WHERE N > 1
) b
ON a.site = b.site AND a.enc_id = b.enc_id
--ORDER BY a.site, a.enc_id
;
