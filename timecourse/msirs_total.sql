#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.msirs_total` AS
(
  WITH t0 AS
  (
    SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , CASE
      WHEN temp.temperature IS NULL THEN NULL
      WHEN temp.temperature > 38.0 THEN 1
      WHEN temp.temperature < 35.5 THEN 1
      ELSE 0 END as msirs_inflammation
    , CASE
      WHEN tc.age_months >=  0 AND tc.age_months <  3 AND (pulse.pulse < 133 OR pulse.pulse > 171) THEN 1
      WHEN tc.age_months >=  3 AND tc.age_months <  6 AND (pulse.pulse < 108 OR pulse.pulse > 167) THEN 1
      WHEN tc.age_months >=  6 AND tc.age_months <  9 AND (pulse.pulse < 104 OR pulse.pulse > 163) THEN 1
      WHEN tc.age_months >=  9 AND tc.age_months < 12 AND (pulse.pulse < 101 OR pulse.pulse > 160) THEN 1
      WHEN tc.age_months >= 12 AND tc.age_months < 18 AND (pulse.pulse <  97 OR pulse.pulse > 157) THEN 1
      WHEN tc.age_months >= 18 AND tc.age_months < 24 AND (pulse.pulse <  92 OR pulse.pulse > 154) THEN 1
      WHEN tc.age_months >= 24 AND tc.age_years  <  3 AND (pulse.pulse <  87 OR pulse.pulse > 150) THEN 1
      WHEN tc.age_years  >=  3 AND tc.age_years  <  4 AND (pulse.pulse <  82 OR pulse.pulse > 146) THEN 1
      WHEN tc.age_years  >=  4 AND tc.age_years  <  6 AND (pulse.pulse <  77 OR pulse.pulse > 142) THEN 1
      WHEN tc.age_years  >=  6 AND tc.age_years  <  8 AND (pulse.pulse <  71 OR pulse.pulse > 137) THEN 1
      WHEN tc.age_years  >=  8 AND tc.age_years  < 12 AND (pulse.pulse <  66 OR pulse.pulse > 129) THEN 1
      WHEN tc.age_years  >= 12 AND tc.age_years  < 15 AND (pulse.pulse <  61 OR pulse.pulse > 121) THEN 1
      WHEN tc.age_years  >= 15 AND tc.age_years  < 18 AND (pulse.pulse <  57 OR pulse.pulse > 115) THEN 1
      WHEN pulse.pulse IS NULL OR tc.age_months IS NULL or tc.age_years IS NULL THEN NULL
      ELSE 0 END AS msirs_cardiovascular
    , CASE
      WHEN tc.age_months >=  0 AND tc.age_months <  3 AND respiratory_rate.respiratory_rate > 62 THEN 1
      WHEN tc.age_months >=  3 AND tc.age_months <  6 AND respiratory_rate.respiratory_rate > 58 THEN 1
      WHEN tc.age_months >=  6 AND tc.age_months <  9 AND respiratory_rate.respiratory_rate > 54 THEN 1
      WHEN tc.age_months >=  9 AND tc.age_months < 12 AND respiratory_rate.respiratory_rate > 51 THEN 1
      WHEN tc.age_months >= 12 AND tc.age_months < 18 AND respiratory_rate.respiratory_rate > 48 THEN 1
      WHEN tc.age_months >= 18 AND tc.age_months < 24 AND respiratory_rate.respiratory_rate > 45 THEN 1
      WHEN tc.age_months >= 24 AND tc.age_years  <  3 AND respiratory_rate.respiratory_rate > 42 THEN 1
      WHEN tc.age_years  >=  3 AND tc.age_years  <  4 AND respiratory_rate.respiratory_rate > 40 THEN 1
      WHEN tc.age_years  >=  4 AND tc.age_years  <  6 AND respiratory_rate.respiratory_rate > 37 THEN 1
      WHEN tc.age_years  >=  6 AND tc.age_years  <  8 AND respiratory_rate.respiratory_rate > 35 THEN 1
      WHEN tc.age_years  >=  8 AND tc.age_years  < 12 AND respiratory_rate.respiratory_rate > 31 THEN 1
      WHEN tc.age_years  >= 12 AND tc.age_years  < 15 AND respiratory_rate.respiratory_rate > 28 THEN 1
      WHEN tc.age_years  >= 15 AND tc.age_years  < 18 AND respiratory_rate.respiratory_rate > 26 THEN 1
      WHEN respiratory_rate.respiratory_rate IS NULL OR tc.age_months IS NULL or tc.age_years IS NULL THEN NULL
      ELSE 0 END AS msirs_respiratory

  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN `**REDACTED**.timecourse.temperature` temp
  ON tc.site = temp.site AND tc.enc_id = temp.enc_id AND tc.eclock = temp.eclock
  LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
  ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock
  LEFT JOIN `**REDACTED**.timecourse.respiratory_rate` respiratory_rate
  ON tc.site = respiratory_rate.site AND tc.enc_id = respiratory_rate.enc_id AND tc.eclock = respiratory_rate.eclock
  )

  SELECT
      site
    , enc_id
    , eclock

    , msirs_inflammation
    , COALESCE(msirs_inflammation, 0) AS msirs_inflammation_min
    , COALESCE(msirs_inflammation, 1) AS msirs_inflammation_max

    , msirs_cardiovascular
    , COALESCE(msirs_cardiovascular, 0) AS msirs_cardiovascular_min
    , COALESCE(msirs_cardiovascular, 1) AS msirs_cardiovascular_max

    , msirs_respiratory
    , COALESCE(msirs_respiratory, 0) AS msirs_respiratory_min
    , COALESCE(msirs_respiratory, 1) AS msirs_respiratory_max

    , msirs_inflammation              + msirs_cardiovascular              + msirs_respiratory              AS msirs_total
    , COALESCE(msirs_inflammation, 0) + COALESCE(msirs_cardiovascular, 0) + COALESCE(msirs_respiratory, 0) AS msirs_total_min
    , COALESCE(msirs_inflammation, 1) + COALESCE(msirs_cardiovascular, 1) + COALESCE(msirs_respiratory, 1) AS msirs_total_max

    FROM t0

)
;
CALL **REDACTED**.sa.aggregate('msirs_total', "msirs_cardiovascular_min");
CALL **REDACTED**.sa.aggregate('msirs_total', "msirs_inflammation_min");
CALL **REDACTED**.sa.aggregate('msirs_total', "msirs_respiratory_min");
CALL **REDACTED**.sa.aggregate('msirs_total', "msirs_total_min");
