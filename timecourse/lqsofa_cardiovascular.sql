#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.lqsofa_cardiovascular` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE
           WHEN tc.age_months >=  0 AND tc.age_months <  3 AND p.pulse > 186 THEN 1
           WHEN tc.age_months >=  3 AND tc.age_months <  6 AND p.pulse > 182 THEN 1
           WHEN tc.age_months >=  6 AND tc.age_months <  9 AND p.pulse > 178 THEN 1
           WHEN tc.age_months >=  9 AND tc.age_months < 12 AND p.pulse > 176 THEN 1
           WHEN tc.age_months >= 12 AND tc.age_months < 18 AND p.pulse > 173 THEN 1
           WHEN tc.age_months >= 18 AND tc.age_months < 24 AND p.pulse > 170 THEN 1
           WHEN tc.age_months >= 24 AND tc.age_years  <  3 AND p.pulse > 167 THEN 1
           WHEN tc.age_years  >=  3 AND tc.age_years  <  4 AND p.pulse > 164 THEN 1
           WHEN tc.age_years  >=  4 AND tc.age_years  <  6 AND p.pulse > 161 THEN 1
           WHEN tc.age_years  >=  6 AND tc.age_years  <  8 AND p.pulse > 155 THEN 1
           WHEN tc.age_years  >=  8 AND tc.age_years  < 12 AND p.pulse > 147 THEN 1
           WHEN tc.age_years  >= 12 AND tc.age_years  < 15 AND p.pulse > 138 THEN 1
           WHEN tc.age_years  >= 15 AND tc.age_years  < 18 AND p.pulse > 132 THEN 1
           WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR p.pulse IS NULL THEN NULL
           ELSE 0 END AS lqsofa_cardiovascular_hr
      , CASE
          WHEN crt.crt_prolonged_5 = 1 THEN 1
          WHEN crt.crt_prolonged_3 = 1 THEN 1
          WHEN crt.crt_prolonged_3 IS NULL THEN NULL
          ELSE 0 END AS lqsofa_cardiovascular_cap_refil
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.pulse` p
    ON tc.site = p.site AND tc.enc_id = p.enc_id AND tc.eclock = p.eclock
    LEFT JOIN `**REDACTED**.timecourse.crt_prolonged` crt
    ON tc.site = crt.site AND tc.enc_id = crt.enc_id AND tc.eclock = crt.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , lqsofa_cardiovascular_hr + lqsofa_cardiovascular_cap_refil AS lqsofa_cardiovascular
    , COALESCE(lqsofa_cardiovascular_hr, 0) + COALESCE(lqsofa_cardiovascular_cap_refil, 0) AS lqsofa_cardiovascular_min
    , COALESCE(lqsofa_cardiovascular_hr, 1) + COALESCE(lqsofa_cardiovascular_cap_refil, 1) AS lqsofa_cardiovascular_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("lqsofa_cardiovascular", "lqsofa_cardiovascular_min");
