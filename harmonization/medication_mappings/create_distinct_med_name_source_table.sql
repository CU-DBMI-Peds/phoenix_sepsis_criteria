#standardSQL
CREATE OR REPLACE TABLE `**REDACTED**.medication.distinct_med_name_source` AS
(
  SELECT site, med_name_source, count(1) as N
  FROM `**REDACTED**.full.medication_admin`
  WHERE med_name_source IS NOT NULL
  GROUP BY site, med_name_source
  ORDER BY site, med_name_source
)
