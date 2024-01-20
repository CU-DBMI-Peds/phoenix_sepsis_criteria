#standardSQL

/* 
 * Set units for temperature to DEGC
 *
 * See discussion at **REDACTED**/issues/30
 *
 * 1. any numeric value >= 80 is assumed to be DEGF and will be translated to
 * DEGC
 *
 * 2. <= 45 is DEGC
 * 3. clean up - drop any value less than 25 or greater than 45
*/


UPDATE `**REDACTED**.harmonized.observ_interv_events`
SET   event_value = CAST((SAFE_CAST(event_value_source AS FLOAT64) - 32) * 5/9 AS STRING)
    , event_units = "DEGC"
WHERE event_name = "TEMP" AND SAFE_CAST(event_value_source AS FLOAT64) >= 80
;

UPDATE `**REDACTED**.harmonized.observ_interv_events`
SET   event_value = event_value_source
    , event_units = "DEGC"
WHERE event_name = "TEMP" AND SAFE_CAST(event_value_source AS FLOAT64) <= 45
;

-- Values below 25C too low and above 45C too high
DELETE FROM `**REDACTED**.harmonized.observ_interv_events`
WHERE event_name = "TEMP" AND 
  (
    SAFE_CAST(event_value AS FLOAT64) < 25 OR
    SAFE_CAST(event_value AS FLOAT64) > 45
  )
;
