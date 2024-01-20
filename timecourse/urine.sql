#standardSQL
/*
Table to show urine measurements and time periods with less than 0.5 ml/kg/hr
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.urine` AS

SELECT
  *,
  CASE
    WHEN eclock < 360 THEN NULL
    WHEN eclock >= 360 AND weight IS NULL AND occurrence_6hr IS NULL THEN NULL
    WHEN eclock >= 360 AND occurrence_6hr IS NULL AND urine_6hr_rate < 0.5 THEN 1
    WHEN eclock >= 360 AND occurrence_6hr IS NULL AND urine_6hr_rate IS NULL THEN 1
    ELSE 0
  END AS urine_low_6hr,
  CASE
    WHEN eclock < 360 THEN NULL
    WHEN occurrence_6hr IS NULL AND urine_6hr_rate IS NULL THEN 1
    ELSE 0
  END as urine_low_6hr_no_obs,
  CASE
    WHEN eclock < 720 THEN NULL
    WHEN eclock >= 720 AND weight IS NULL AND occurrence_12hr IS NULL THEN NULL
    WHEN eclock >= 720 AND occurrence_12hr IS NULL AND urine_12hr_rate < 0.5 THEN 1
    WHEN eclock >= 720 AND occurrence_12hr IS NULL AND urine_12hr_rate IS NULL THEN 1
    ELSE 0
  END AS urine_low_12hr,
  CASE
    WHEN eclock < 720 THEN NULL
    WHEN occurrence_12hr IS NULL AND urine_12hr_rate IS NULL THEN 1
    ELSE 0
  END as urine_low_12hr_no_obs,
  CASE
    WHEN weight IS NULL THEN 1
    ELSE 0
  END as no_weight,
FROM (
SELECT s_h.*,
  t_h.urine_12hr,
  t_h.urine_12hr_rate,
  t_h.occurrence_12hr
FROM **REDACTED**.timecourse.urine_6hr s_h
FULL JOIN **REDACTED**.timecourse.urine_12hr t_h
  ON s_h.site = t_h.site
  AND s_h.enc_id = t_h.enc_id
  AND s_h.eclock = t_h.eclock
)
;
