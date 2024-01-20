#standardSQL

/*
SELECT DISTINCT med_name_source
FROM `**REDACTED**.harmonized.medication_admin`
WHERE med_set = "vasoactive"
;

SELECT DISTINCT site, med_name_source, med_dose_source, med_dose_units_source, med_dose, med_dose_units, systemic
FROM `**REDACTED**.harmonized.medication_admin`
WHERE site = "**REDACTED**"
  AND med_set = "vasoactive"
  AND med_dose IS NULL
  AND (
    med_name_source NOT IN (
        "dextrose 5% in water 49.5 ml + **vasopressin 0.1 units/ml dilution 0.05 unit(s)"
      , "dobutamine 75 mg + sodium chloride 0.9% 44 ml"
      , "dopamine 150 mg + dextrose 5% in water 3.12 ml"
      , "dopamine 150 mg + dextrose 5% in water 46.25 ml"
      , "dopamine 300 mg + sodium chloride 0.9% 42.5 ml"
      , "dopamine 75 mg + dextrose 5% in water 26.56 ml"
      , "dopamine 75 mg + dextrose 5% in water 48.12 ml"
      , "dopamine 75 mg + sodium chloride 0.9% 48.12 ml"
      , "epinephrine 1.5 mg + dextrose 5% in water 48.5 ml"
      , "epinephrine 1.5 mg + sodium chloride 0.9% 48.5 ml"
      , "epinephrine 2.5 mg + dextrose 5% in water 47.5 ml"
      , "epinephrine 2.5 mg + sodium chloride 0.9% 47.5 ml"
      , "epinephrine 5 mg + dextrose 5% in water 45 ml"
      , "epinephrine 5 mg + sodium chloride 0.9% 45 ml"
      , "milrinone 10 mg + dextrose 5% in water 40 ml"
    )
  )
ORDER BY med_name_source
LIMIT 1000
*/

SELECT DISTINCT
  --  site, enc_id ,
  -- med_name_source
  --, med_route_source, med_fda_route, systemic
  med_dose_source, med_dose
  , SAFE_CAST(med_dose_source AS FLOAT64) med_dose2
  --, med_dose_units_source, med_dose_units
FROM `**REDACTED**.harmonized.medication_admin`
--        FROM `**REDACTED**.full.medication_admin`
--WHERE med_dose_source IS NOT NULL AND med_dose IS NULL
--where med_dose_source IS NOT NULL AND med_dose IS NULL
WHERE med_name_source IS NOT NULL
  AND med_dose_source IS NOT NULL
  --and SAFE_CAST(med_dose_source AS FLOAT64) <> med_dose
  --and med_dose IS NULL
ORDER BY med_dose_source




-- -------------------------------------------------------------------------- --
                               -- END OF FILE --
-- -------------------------------------------------------------------------- --
