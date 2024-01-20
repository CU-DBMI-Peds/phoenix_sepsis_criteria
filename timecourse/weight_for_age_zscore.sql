#standardSQL

-- NOTE: The resulting table will be smaller than most tables in the timecourse
-- set.  Only returning site, enc_id, and admit_weight_for_age_zscore where
-- admit_weight_for_age_zscore is not null.  Older patients will not be captured
-- as the max age from the WHO for weight-for-age calculations is 120 months

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.weight_for_age_zscore` AS
(
  WITH t0 AS
  (
    SELECT
        f.site
      , f.enc_id
      , f.male
      , f.admit_age_months
      , (f.admit_age_months - lms.age_months) AS age_delta
      , lms.L
      , lms.M
      , lms.S
      , lms.metric
    FROM (SELECT DISTINCT site, enc_id, male, admit_age_months FROM `**REDACTED**.timecourse.foundation`) f
       , (SELECT * FROM `**REDACTED**.utilities.who_lms` WHERE metric = "weight-for-age" AND source = 'WHO') lms
    WHERE
        (f.male = lms.male) AND
        (ABS(f.admit_age_months - lms.age_months) < 1.0) AND
        (f.admit_age_months >= lms.age_months)
  )
  , min_age_delta AS
  (
    SELECT enc_id, min(age_delta) AS min_age_delta FROM t0 GROUP BY enc_id
  )
  , t1 AS
  (
    SELECT t0.*, w.admit_weight
    FROM t0
    LEFT JOIN `**REDACTED**.timecourse.weight` w
    ON t0.enc_id = w.enc_id
  )

  SELECT
      t1.site
    , t1.enc_id
    , CASE
        WHEN t1.admit_weight > 0 THEN (POW(t1.admit_weight / t1.M, t1.L) - 1) / (t1.L * t1.S)
        ELSE NULL
      END AS admit_weight_for_age_zscore
  FROM t1, (SELECT * FROM min_age_delta) mad
  WHERE t1.enc_id = mad.enc_id AND t1.age_delta = mad.min_age_delta
)
;
