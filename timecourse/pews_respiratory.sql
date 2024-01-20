#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pews_respiratory` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                            rr.respiratory_rate > 69) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                            rr.respiratory_rate > 49) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                            rr.respiratory_rate > 59) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                            rr.respiratory_rate > 39) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                            rr.respiratory_rate > 49) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                            rr.respiratory_rate > 34) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                            rr.respiratory_rate > 39) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                            rr.respiratory_rate > 29) THEN 1
        WHEN tc.age_years  >= 12                        AND (                            rr.respiratory_rate > 34) THEN 3
        WHEN tc.age_years  >= 12                        AND (                            rr.respiratory_rate > 24) THEN 1
        WHEN vent.vent IS NULL OR tc.age_months IS NULL OR tc.age_years IS NULL OR rr.respiratory_rate IS NULL THEN NULL
        ELSE 0 END AS pews_tachypnea
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (rr.respiratory_rate < 20                            ) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (rr.respiratory_rate < 30                            ) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (rr.respiratory_rate < 20                            ) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (rr.respiratory_rate < 25                            ) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (rr.respiratory_rate < 15                            ) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (rr.respiratory_rate < 20                            ) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (rr.respiratory_rate < 15                            ) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (rr.respiratory_rate < 20                            ) THEN 1
        WHEN tc.age_years  >= 12                        AND (rr.respiratory_rate < 10                            ) THEN 3
        WHEN tc.age_years  >= 12                        AND (rr.respiratory_rate < 15                            ) THEN 1
        WHEN vent.vent IS NULL OR tc.age_months IS NULL OR tc.age_years IS NULL OR rr.respiratory_rate IS NULL THEN NULL
        ELSE 0 END AS pews_bradypnea
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (rr.respiratory_rate < 20 OR rr.respiratory_rate > 69) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (rr.respiratory_rate < 30 OR rr.respiratory_rate > 49) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (rr.respiratory_rate < 20 OR rr.respiratory_rate > 59) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (rr.respiratory_rate < 25 OR rr.respiratory_rate > 39) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (rr.respiratory_rate < 15 OR rr.respiratory_rate > 49) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (rr.respiratory_rate < 20 OR rr.respiratory_rate > 34) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (rr.respiratory_rate < 15 OR rr.respiratory_rate > 39) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (rr.respiratory_rate < 20 OR rr.respiratory_rate > 29) THEN 1
        WHEN tc.age_years  >= 12                        AND (rr.respiratory_rate < 10 OR rr.respiratory_rate > 34) THEN 3
        WHEN tc.age_years  >= 12                        AND (rr.respiratory_rate < 15 OR rr.respiratory_rate > 24) THEN 1
        WHEN vent.vent IS NULL OR tc.age_months IS NULL OR tc.age_years IS NULL OR rr.respiratory_rate IS NULL THEN NULL
        ELSE 0 END AS pews_respiratory_rate

      , CASE
        WHEN spo2.spo2 IS NULL THEN NULL
        WHEN spo2.ok_for_non_podium = 0 THEN NULL
        WHEN spo2.ok_for_non_podium = 1 AND spo2.spo2 <= 92 THEN 3
        WHEN spo2.ok_for_non_podium = 1 AND spo2.spo2 <= 94 THEN 1
        ELSE 0 END AS pews_saturation

      , CASE
        WHEN vent.vent = 1 THEN 1
        WHEN o2_flow.o2_flow > 0 THEN 1
        WHEN o2_flow.oxygen_b > 0 THEN 1
        ELSE 0 END AS pews_oxygen

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.respiratory_rate` rr
    ON tc.enc_id = rr.enc_id AND tc.eclock = rr.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock
    LEFT JOIN `**REDACTED**.timecourse.o2_flow` o2_flow
    ON tc.enc_id = o2_flow.enc_id AND tc.eclock = o2_flow.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , pews_tachypnea         AS pews_tachypnea
    , pews_bradypnea         AS pews_bradypnea
    , pews_respiratory_rate  AS pews_respiratory_rate
    , pews_saturation        AS pews_saturation
    , pews_oxygen            AS pews_oxygen
    , COALESCE(pews_tachypnea, 0)         AS pews_tachypnea_min
    , COALESCE(pews_bradypnea, 0)         AS pews_bradypnea_min
    , COALESCE(pews_respiratory_rate, 0)  AS pews_respiratory_rate_min
    , COALESCE(pews_saturation, 0)        AS pews_saturation_min
    , COALESCE(pews_oxygen, 0)            AS pews_oxygen_min
    , pews_respiratory_rate + pews_saturation + pews_oxygen    AS pews_respiratory
    , COALESCE(pews_respiratory_rate, 0) + COALESCE(pews_saturation, 0) + COALESCE(pews_oxygen, 0)  AS pews_respiratory_min
    , COALESCE(pews_respiratory_rate, 3) + COALESCE(pews_saturation, 3) + COALESCE(pews_oxygen, 1)  AS pews_respiratory_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_tachypnea_min");
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_bradypnea_min");
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_respiratory_rate_min");
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_saturation_min");
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_oxygen_min");
CALL **REDACTED**.sa.aggregate("pews_respiratory", "pews_respiratory_min");
