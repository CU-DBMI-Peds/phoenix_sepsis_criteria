/*
Table for curating death information

Although this table has various columns related to death, only death_during_encounter == 1
should be treated as indicating a person died during encounter. died_time aka enc_tbl_died_time and
adt_tbl_died_time should NOT be used to determine death during encounter or encounter ending
in mortality.

*/
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.death` AS

SELECT
  COALESCE(a.site, e.site) AS site,
  COALESCE(a.enc_id, e.enc_id) AS enc_id,
  a.* EXCEPT(site, enc_id),
  e.* EXCEPT(site, enc_id),
  CASE
    WHEN LOWER(hospital_disposition) = 'expired' THEN 1
    ELSE 0
  END AS death_during_encounter
FROM (
  -- query to get the few ADT records indicating death
  SELECT
    adt.site,
    enc_id,
    adt_type,
    adt.adt_location,
    adt_time AS adt_tbl_died_time,
    adt.adt_other
FROM `**REDACTED**.harmonized.adt` adt
INNER JOIN `**REDACTED**.full.adt_mapping_configuration` m
  ON adt.site = m.site
  AND adt.adt_other = m.adt_other
  AND m.adt_location = '*') a
FULL OUTER JOIN (
  -- get encounter level death information (and all encounters)
  SELECT DISTINCT
    site, enc_id, pat_id, died_time AS enc_tbl_died_time, enc_end_time, hospital_disposition,
  FROM `**REDACTED**.harmonized.encounters`
) e
  ON a.site = e.site
  AND a.enc_id = e.enc_id
;