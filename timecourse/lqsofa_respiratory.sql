#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.lqsofa_respiratory` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE
        WHEN vent.vent = 1 THEN 0 -- EXCLUDE VENTED PATIENTS FROM THIS METRIC
        WHEN tc.age_months >=  0 AND tc.age_months <  3 AND rr.respiratory_rate > 76 THEN 1
        WHEN tc.age_months >=  3 AND tc.age_months <  6 AND rr.respiratory_rate > 71 THEN 1
        WHEN tc.age_months >=  6 AND tc.age_months <  9 AND rr.respiratory_rate > 67 THEN 1
        WHEN tc.age_months >=  9 AND tc.age_months < 12 AND rr.respiratory_rate > 63 THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 18 AND rr.respiratory_rate > 60 THEN 1
        WHEN tc.age_months >= 18 AND tc.age_months < 24 AND rr.respiratory_rate > 57 THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  3 AND rr.respiratory_rate > 54 THEN 1
        WHEN tc.age_years  >=  3 AND tc.age_years  <  4 AND rr.respiratory_rate > 52 THEN 1
        WHEN tc.age_years  >=  4 AND tc.age_years  <  6 AND rr.respiratory_rate > 50 THEN 1
        WHEN tc.age_years  >=  6 AND tc.age_years  <  8 AND rr.respiratory_rate > 46 THEN 1
        WHEN tc.age_years  >=  8 AND tc.age_years  < 12 AND rr.respiratory_rate > 41 THEN 1
        WHEN tc.age_years  >= 12 AND tc.age_years  < 15 AND rr.respiratory_rate > 35 THEN 1
        WHEN tc.age_years  >= 15 AND tc.age_years  < 18 AND rr.respiratory_rate > 32 THEN 1
        WHEN vent.vent IS NULL OR tc.age_months IS NULL OR tc.age_years IS NULL OR rr.respiratory_rate IS NULL THEN NULL
        ELSE 0 END AS lqsofa_respiratory
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
    , lqsofa_respiratory
    , COALESCE(lqsofa_respiratory, 0) AS lqsofa_respiratory_min
    , COALESCE(lqsofa_respiratory, 1) AS lqsofa_respiratory_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("lqsofa_respiratory", "lqsofa_respiratory_min");
