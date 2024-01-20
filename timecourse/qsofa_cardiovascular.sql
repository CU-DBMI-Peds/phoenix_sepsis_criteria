#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.qsofa_cardiovascular` AS
(
  WITH t AS
  (
    SELECT tc.site, tc.enc_id, tc.eclock,
      CASE
           WHEN                       tc.age_years <=  2 AND bp.map < 60 THEN 1
           WHEN tc.age_years >  2 AND tc.age_years <=  5 AND bp.map < 62 THEN 1
           WHEN tc.age_years >  5 AND tc.age_years <= 12 AND bp.map < 65 THEN 1
           WHEN tc.age_years > 12 AND tc.age_years <= 18 AND bp.map < 67 THEN 1
           WHEN bp.map IS NULL then NULL
           ELSE 0 END AS qsofa_cardiovascular
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , qsofa_cardiovascular
    , COALESCE(qsofa_cardiovascular, 0) AS qsofa_cardiovascular_min
    , COALESCE(qsofa_cardiovascular, 1) AS qsofa_cardiovascular_max
  FROM t
)
;

CALL **REDACTED**.sa.aggregate("qsofa_cardiovascular", "qsofa_cardiovascular_min");
