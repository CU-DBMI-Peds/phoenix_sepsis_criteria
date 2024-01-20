#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_tachypnea` AS
(
  WITH t AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN vent.vent = 1 THEN 0 -- EXCLUDE VENTED PATIENTS FROM THIS METRIC
           WHEN tc.age_months <  12 AND rr.respiratory_rate > 90 THEN 1
           WHEN tc.age_months >= 12 AND rr.respiratory_rate > 70 THEN 1
           WHEN vent.vent IS NULL OR rr.respiratory_rate IS NULL then NULL
           ELSE 0 END AS proulx_tachypnea
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.respiratory_rate` rr
    ON tc.enc_id = rr.enc_id AND tc.eclock = rr.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , proulx_tachypnea
    , COALESCE(proulx_tachypnea, 0) AS proulx_tachypnea_min
    , COALESCE(proulx_tachypnea, 1) AS proulx_tachypnea_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("proulx_tachypnea", "proulx_tachypnea_min");
