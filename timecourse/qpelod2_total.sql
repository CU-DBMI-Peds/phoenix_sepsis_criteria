#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.qpelod2_total` AS
(
  WITH t0 AS
  (
    SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , CASE
      WHEN gcs.gcs_total IS NULL THEN NULL
      WHEN gcs.gcs_total < 11 THEN 1
      ELSE 0 END as qpelod2_neurological

    , CASE
      WHEN tc.age_months >=   0 AND tc.age_months <   1 AND (bp.sbp < 65 OR bp.map < 46) THEN 1
      WHEN tc.age_months >=   1 AND tc.age_months <  12 AND (bp.sbp < 75 OR bp.map < 55) THEN 1
      WHEN tc.age_months >=  12 AND tc.age_months <  24 AND (bp.sbp < 85 OR bp.map < 60) THEN 1
      WHEN tc.age_months >=  24 AND tc.age_months <  60 AND (bp.sbp < 85 OR bp.map < 62) THEN 1
      WHEN tc.age_months >=  60 AND tc.age_months < 144 AND (bp.sbp < 85 OR bp.map < 65) THEN 1
      WHEN tc.age_months >= 144                      AND (bp.sbp < 95 OR bp.map < 67) THEN 1
      WHEN tc.age_months IS NULL OR bp.sbp IS NULL OR bp.map IS NULL THEN NULL
      ELSE 0 END AS qpelod2_hypotension

    , CASE
      WHEN tc.age_years <  12 AND pulse.pulse > 195 THEN 1
      WHEN tc.age_years >= 12 AND pulse.pulse > 150 THEN 1
      WHEN pulse.pulse IS NULL OR tc.age_years IS NULL THEN NULL
      ELSE 0 END AS qpelod2_tachycardia

  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
  ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock
  LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
  ON tc.site = gcs.site AND tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
  LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
  ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock
  )

  SELECT
      site
    , enc_id
    , eclock

    , qpelod2_neurological
    , COALESCE(qpelod2_neurological, 0) AS qpelod2_neurological_min
    , COALESCE(qpelod2_neurological, 1) AS qpelod2_neurological_max

    , qpelod2_hypotension
    , COALESCE(qpelod2_hypotension, 0) AS qpelod2_hypotension_min
    , COALESCE(qpelod2_hypotension, 1) AS qpelod2_hypotension_max

    , qpelod2_tachycardia
    , COALESCE(qpelod2_tachycardia, 0) AS qpelod2_tachycardia_min
    , COALESCE(qpelod2_tachycardia, 1) AS qpelod2_tachycardia_max

    , qpelod2_neurological              + qpelod2_hypotension              + qpelod2_tachycardia              AS qpelod2_total
    , COALESCE(qpelod2_neurological, 0) + COALESCE(qpelod2_hypotension, 0) + COALESCE(qpelod2_tachycardia, 0) AS qpelod2_total_min
    , COALESCE(qpelod2_neurological, 1) + COALESCE(qpelod2_hypotension, 1) + COALESCE(qpelod2_tachycardia, 1) AS qpelod2_total_max

    FROM t0

)
;

CALL **REDACTED**.sa.aggregate('qpelod2_total', "qpelod2_neurological_min");
CALL **REDACTED**.sa.aggregate('qpelod2_total', "qpelod2_hypotension_min");
CALL **REDACTED**.sa.aggregate('qpelod2_total', "qpelod2_tachycardia_min");
CALL **REDACTED**.sa.aggregate('qpelod2_total', "qpelod2_total_min");
