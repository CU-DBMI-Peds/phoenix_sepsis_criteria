#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.qsofa_tachypnea` AS
(
  WITH t AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE WHEN vent.vent = 1 THEN 0 -- EXCLUDE VENTED PATIENTS FROM THIS METRIC
           WHEN                       tc.age_years <=  2 AND rr.respiratory_rate > 34 THEN 1
           WHEN tc.age_years >  2 AND tc.age_years <=  5 AND rr.respiratory_rate > 22 THEN 1
           WHEN tc.age_years >  5 AND tc.age_years <= 12 AND rr.respiratory_rate > 18 THEN 1
           WHEN tc.age_years > 12 AND tc.age_years <= 18 AND rr.respiratory_rate > 14 THEN 1
           WHEN vent.vent IS NULL OR rr.respiratory_rate IS NULL then NULL
           ELSE 0 END AS qsofa_tachypnea
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
    , qsofa_tachypnea
    , COALESCE(qsofa_tachypnea, 0) AS qsofa_tachypnea_min
    , COALESCE(qsofa_tachypnea, 1) AS qsofa_tachypnea_max
  FROM t
)
;

CALL **REDACTED**.sa.aggregate("qsofa_tachypnea", "qsofa_tachypnea_min");
