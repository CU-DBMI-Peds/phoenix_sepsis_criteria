#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pews_cardiovascular` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (bp.sbp <  60                ) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (bp.sbp <  70                ) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (bp.sbp <  60                ) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (bp.sbp <  70                ) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (bp.sbp <  70                ) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (bp.sbp <  80                ) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (bp.sbp <  80                ) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (bp.sbp <  90                ) THEN 1
        WHEN tc.age_years  >= 12                        AND (bp.sbp <  90                ) THEN 3
        WHEN tc.age_years  >= 12                        AND (bp.sbp < 100                ) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR bp.sbp IS NULL THEN NULL
        ELSE 0 END AS pews_hypotension
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                bp.sbp > 109) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                bp.sbp >  99) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                bp.sbp > 109) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                bp.sbp >  99) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                bp.sbp > 119) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                bp.sbp >  99) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                bp.sbp > 129) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                bp.sbp > 109) THEN 1
        WHEN tc.age_years  >= 12                        AND (                bp.sbp > 139) THEN 3
        WHEN tc.age_years  >= 12                        AND (                bp.sbp > 119) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR bp.sbp IS NULL THEN NULL
        ELSE 0 END AS pews_hypertension
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (bp.sbp <  60 OR bp.sbp > 109) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (bp.sbp <  70 OR bp.sbp >  99) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (bp.sbp <  60 OR bp.sbp > 109) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (bp.sbp <  70 OR bp.sbp >  99) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (bp.sbp <  70 OR bp.sbp > 119) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (bp.sbp <  80 OR bp.sbp >  99) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (bp.sbp <  80 OR bp.sbp > 129) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (bp.sbp <  90 OR bp.sbp > 109) THEN 1
        WHEN tc.age_years  >= 12                        AND (bp.sbp <  90 OR bp.sbp > 139) THEN 3
        WHEN tc.age_years  >= 12                        AND (bp.sbp < 100 OR bp.sbp > 119) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR bp.sbp IS NULL THEN NULL
        ELSE 0 END AS pews_sbp

      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (pulse.pulse < 100                     ) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (pulse.pulse < 110                     ) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (pulse.pulse <  80                     ) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (pulse.pulse < 100                     ) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (pulse.pulse <  70                     ) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (pulse.pulse <  90                     ) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (pulse.pulse <  60                     ) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (pulse.pulse <  80                     ) THEN 1
        WHEN tc.age_years  >= 12                        AND (pulse.pulse <  50                     ) THEN 3
        WHEN tc.age_years  >= 12                        AND (pulse.pulse <  70                     ) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR pulse.pulse IS NULL THEN NULL
        ELSE 0 END AS pews_bradycardia
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                     pulse.pulse > 169) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (                     pulse.pulse > 159) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                     pulse.pulse > 159) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (                     pulse.pulse > 149) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                     pulse.pulse > 149) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (                     pulse.pulse > 139) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                     pulse.pulse > 139) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (                     pulse.pulse > 129) THEN 1
        WHEN tc.age_years  >= 12                        AND (                     pulse.pulse > 129) THEN 3
        WHEN tc.age_years  >= 12                        AND (                     pulse.pulse > 109) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR pulse.pulse IS NULL THEN NULL
        ELSE 0 END AS pews_tachycardia
      , CASE
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (pulse.pulse < 100 OR pulse.pulse > 169) THEN 3
        WHEN tc.age_months >=  0 AND tc.age_months < 12 AND (pulse.pulse < 110 OR pulse.pulse > 159) THEN 1
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (pulse.pulse <  80 OR pulse.pulse > 159) THEN 3
        WHEN tc.age_months >= 12 AND tc.age_months < 24 AND (pulse.pulse < 100 OR pulse.pulse > 149) THEN 1
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (pulse.pulse <  70 OR pulse.pulse > 149) THEN 3
        WHEN tc.age_months >= 24 AND tc.age_years  <  5 AND (pulse.pulse <  90 OR pulse.pulse > 139) THEN 1
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (pulse.pulse <  60 OR pulse.pulse > 139) THEN 3
        WHEN tc.age_years  >=  5 AND tc.age_years  < 12 AND (pulse.pulse <  80 OR pulse.pulse > 129) THEN 1
        WHEN tc.age_years  >= 12                        AND (pulse.pulse <  50 OR pulse.pulse > 129) THEN 3
        WHEN tc.age_years  >= 12                        AND (pulse.pulse <  70 OR pulse.pulse > 109) THEN 1
        WHEN tc.age_months IS NULL OR tc.age_years IS NULL OR pulse.pulse IS NULL THEN NULL
        ELSE 0 END AS pews_heart_rate

      , CASE
          WHEN crt.crt_prolonged_5 = 1 THEN 3
          WHEN crt.crt_prolonged_3 = 1 THEN 1
          WHEN crt.crt_prolonged_5 IS NULL OR crt.crt_prolonged_3 IS NULL THEN NULL
          ELSE 0 END AS pews_cap_refill

    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
    ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock
    LEFT JOIN `**REDACTED**.timecourse.crt_prolonged` crt
    ON tc.site = crt.site AND tc.enc_id = crt.enc_id AND tc.eclock = crt.eclock
    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , pews_hypotension   AS pews_hypotension
    , pews_hypertension  AS pews_hypertension
    , pews_sbp           AS pews_sbp
    , pews_tachycardia   AS pews_tachycardia
    , pews_bradycardia   AS pews_bradycardia
    , pews_heart_rate    AS pews_heart_rate
    , pews_cap_refill    AS pews_cap_refill
    , COALESCE(pews_hypotension, 0)   AS pews_hypotension_min
    , COALESCE(pews_hypertension, 0)  AS pews_hypertension_min
    , COALESCE(pews_sbp, 0)           AS pews_sbp_min
    , COALESCE(pews_tachycardia, 0)   AS pews_tachycardia_min
    , COALESCE(pews_bradycardia, 0)   AS pews_bradycardia_min
    , COALESCE(pews_heart_rate, 0)    AS pews_heart_rate_min
    , COALESCE(pews_cap_refill, 0)    AS pews_cap_refill_min
    , pews_sbp              + pews_heart_rate              + pews_cap_refill              AS pews_cardiovascular
    , COALESCE(pews_sbp, 0) + COALESCE(pews_heart_rate, 0) + COALESCE(pews_cap_refill, 0) AS pews_cardiovascular_min
    , COALESCE(pews_sbp, 3) + COALESCE(pews_heart_rate, 3) + COALESCE(pews_cap_refill, 3) AS pews_cardiovascular_max
  FROM t
)
;
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_hypertension_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_hypotension_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_sbp_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_tachycardia_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_bradycardia_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_heart_rate_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_cap_refill_min");
CALL **REDACTED**.sa.aggregate("pews_cardiovascular", "pews_cardiovascular_min");
