/*
table to combine input_output urine information with weight information
for urine rate calculation
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.weights_and_urine` AS

SELECT
  f.site,
  f.enc_id,
  f.eclock,
  w.weight,
  io.urine_measured,
  o.urine_occurrence
FROM `**REDACTED**.timecourse.foundation` f
LEFT JOIN `**REDACTED**.timecourse.weight` w
  ON f.site = w.site AND f.enc_id = w.enc_id AND f.eclock = w.eclock
LEFT JOIN (
  SELECT DISTINCT site, enc_id, io_name, io_time, SUM(SAFE_CAST(io_value AS FLOAT64)) AS urine_measured
  FROM `**REDACTED**.harmonized.inputs_outputs`
  WHERE io_name = 'urine'
  AND io_units = 'ml'
  GROUP BY site, enc_id, io_name, io_time) io
ON w.site = io.site
  AND w.enc_id = io.enc_id
  AND w.eclock = io.io_time
LEFT JOIN (
  SELECT DISTINCT site, enc_id, io_time, SAFE_CAST(1 AS INT) AS urine_occurrence
  FROM `**REDACTED**.harmonized.inputs_outputs`
  WHERE
    (io_name = 'urine_occurrence' AND io_value = '1') OR
    (io_name = 'urine_stool_mix' AND SAFE_CAST(io_value AS FLOAT64) > 0)
) o
ON w.site = o.site
  AND w.enc_id = o.enc_id
  AND w.eclock = o.io_time
;
