#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.o2_flow` AS
(
  WITH t AS
  (
    SELECT
      site,
      enc_id,
      event_time AS o2_flow_time,
      MAX(SAFE_CAST(event_value AS FLOAT64)) AS o2_flow,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "O2_FLOW" AND event_units = "L/MIN" AND event_time IS NOT NULL
    GROUP BY site, enc_id, event_time
  ),
  b AS
  (
    SELECT
      site,
      enc_id,
      event_time AS oxygen_b_time,
      1 AS oxygen_b
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE (event_name = "O2_FLOW" AND event_units = "L/MIN" AND SAFE_CAST(event_value AS FLOAT64) > 0 AND event_time IS NOT NULL) OR
          -- SUP_O2 also tracks when not on oxygen. At this time we only care when on supplemental oxygen.
          (event_name = "SUP_O2" AND event_value = "true" AND event_time IS NOT NULL) OR
          (event_name = "FIO2" AND event_units = "%" AND SAFE_CAST(event_value AS FLOAT64) / 100 > 0.21 AND event_time IS NOT NULL) OR
          (event_name = "EPAP_NIV" AND event_units = "CMH2O" AND SAFE_CAST(event_value AS FLOAT64) > 0 AND event_time IS NOT NULL)
    GROUP BY site, enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    LAST_VALUE(t.o2_flow_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS o2_flow_time,
    LAST_VALUE(t.o2_flow      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS o2_flow,
    LAST_VALUE(b.oxygen_b_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS oxygen_b_time,
    LAST_VALUE(b.oxygen_b      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS oxygen_b
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.o2_flow_time
  LEFT JOIN b
  ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.oxygen_b_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the o2_flow value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.o2_flow`
SET o2_flow = NULL, o2_flow_time = NULL
WHERE o2_flow_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
