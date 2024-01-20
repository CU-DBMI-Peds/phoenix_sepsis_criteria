#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.epap_niv` AS
(
  WITH t AS
  (
    SELECT
      enc_id,
      event_time AS epap_niv_time,
      MAX(SAFE_CAST(event_value AS FLOAT64)) AS epap_niv,
      IF(MAX(SAFE_CAST(event_value AS FLOAT64)) > 0, 1, 0) AS epap_niv_yn,
    FROM `**REDACTED**.harmonized.observ_interv_events`
    WHERE event_name = "EPAP_NIV" AND event_units = "CMH2O" AND event_time IS NOT NULL
    GROUP BY enc_id, event_time
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
             LAST_VALUE(epap_niv_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS epap_niv_time,
    COALESCE(LAST_VALUE(epap_niv      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS epap_niv,
             LAST_VALUE(epap_niv_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS epap_niv_yn_time,
    COALESCE(LAST_VALUE(epap_niv_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS epap_niv_yn
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.epap_niv_time
)
;

-- -------------------------------------------------------------------------- --
-- Set the epap_niv value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.epap_niv`
SET epap_niv = NULL, epap_niv_time = NULL
WHERE epap_niv_time - eclock > 60 * 6
;

UPDATE `**REDACTED**.timecourse.epap_niv`
SET epap_niv_yn = NULL, epap_niv_yn_time = NULL
WHERE epap_niv_yn_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
