#standardSQL
/*
Table create rolling 6 hour summary of urine measurements or urine/urine_stool occurrences

Used to create final urine rate table.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.urine_6hr` AS
SELECT
  b1.site,
  b1.enc_id,
  b1.eclock,
  b1.weight,
  b1.urine_measured,
  b1.urine_occurrence,
  SUM(b2.urine_measured) AS urine_6hr,
  SAFE_DIVIDE(SUM(b2.urine_measured), b1.weight) / 6 AS urine_6hr_rate,
  MAX(b2.urine_occurrence) AS occurrence_6hr,
FROM `**REDACTED**.timecourse.weights_and_urine` b1
JOIN `**REDACTED**.timecourse.weights_and_urine` b2
    ON b1.site = b2.site
    AND b1.enc_id = b2.enc_id
    AND b2.eclock BETWEEN (b1.eclock - 360) AND b1.eclock
GROUP BY b1.site, b1.enc_id, b1.eclock, b1.weight, b1.urine_measured, b1.urine_occurrence
;
