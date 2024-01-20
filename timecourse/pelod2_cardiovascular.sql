#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , lactate.lactate
      , bp.map
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.lactate` lactate
    ON tc.site = lactate.site AND tc.enc_id = lactate.enc_id AND tc.eclock = lactate.eclock
    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock
  )
  ,
  t1 AS
  (
    SELECT site, enc_id, eclock,
      MAX(V1) as pelod2_cv_lact,
      MAX(v2) AS pelod2_cv_map
    FROM
    (
      SELECT site, enc_id, eclock, 4 AS v1, NULL as v2
      FROM t0
      WHERE lactate >= 11

      UNION ALL

      SELECT site, enc_id, eclock, 1 AS v1, NULL as v2
      FROM t0
      WHERE lactate >= 5

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS v1, NULL as v2
      FROM t0
      WHERE lactate < 5

      UNION ALL

      SELECT site, enc_id, eclock, NULL AS v1, 6 as v2
      FROM t0
      WHERE (
             (                      age_months <   1 AND map < 17) OR
             (age_months >=   1 AND age_months <  12 AND map < 25) OR
             (age_months >=  12 AND age_months <  24 AND map < 31) OR
             (age_months >=  24 AND age_months <  60 AND map < 32) OR
             (age_months >=  60 AND age_months < 144 AND map < 36) OR
             (age_months >= 144                      AND map < 38)
            )

      UNION ALL

      SELECT site, enc_id, eclock, NULL AS v1, 3 as v2
      FROM t0
      WHERE (
             (                      age_months <   1 AND map < 31) OR
             -- note this does not match reference. We believe reference
             -- had typo that should have been 38 instead of 28
             (age_months >=   1 AND age_months <  12 AND map < 39) OR
             (age_months >=  12 AND age_months <  24 AND map < 44) OR
             (age_months >=  24 AND age_months <  60 AND map < 45) OR
             (age_months >=  60 AND age_months < 144 AND map < 49) OR
             (age_months >= 144                      AND map < 52)
            )

      UNION ALL

      SELECT site, enc_id, eclock, NULL AS v1, 2 as v2
      FROM t0
      WHERE (
             (                      age_months <   1 AND map < 46) OR
             (age_months >=   1 AND age_months <  12 AND map < 55) OR
             (age_months >=  12 AND age_months <  24 AND map < 60) OR
             (age_months >=  24 AND age_months <  60 AND map < 62) OR
             (age_months >=  60 AND age_months < 144 AND map < 65) OR
             (age_months >= 144                      AND map < 67)
            )

      UNION ALL

      SELECT site, enc_id, eclock, NULL AS v1, 0 as v2
      FROM t0
      WHERE (
             (                      age_months <   1 AND map < 17) OR
             (age_months >=   1 AND age_months <  12 AND map < 24) OR
             (age_months >=  12 AND age_months <  24 AND map < 31) OR
             (age_months >=  24 AND age_months <  60 AND map < 32) OR
             (age_months >=  60 AND age_months < 144 AND map < 36) OR
             (age_months >= 144                      AND map < 38)
            ) IS FALSE AND
            (
             (                      age_months <   1 AND map < 31) OR
             (age_months >=   1 AND age_months <  12 AND map < 29) OR
             (age_months >=  12 AND age_months <  24 AND map < 44) OR
             (age_months >=  24 AND age_months <  60 AND map < 45) OR
             (age_months >=  60 AND age_months < 144 AND map < 49) OR
             (age_months >= 144                      AND map < 52)
            ) IS FALSE AND
            (
             (                      age_months <   1 AND map < 46) OR
             (age_months >=   1 AND age_months <  12 AND map < 55) OR
             (age_months >=  12 AND age_months <  24 AND map < 60) OR
             (age_months >=  24 AND age_months <  60 AND map < 62) OR
             (age_months >=  60 AND age_months < 144 AND map < 65) OR
             (age_months >= 144                      AND map < 67)
            ) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )
  ,
  t2 AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , COALESCE(pelod2_cv_lact, 0) AS pelod2_cv_lact_min
      , pelod2_cv_lact
      , COALESCE(pelod2_cv_lact, 4) AS pelod2_cv_lact_max
      , COALESCE(pelod2_cv_map, 0) AS pelod2_cv_map_min
      , pelod2_cv_map
      , COALESCE(pelod2_cv_map, 6) AS pelod2_cv_map_max
    FROM t1
  )
  ,
  t3 AS
  (
    SELECT
        *
      , pelod2_cv_lact_min + pelod2_cv_map_min AS pelod2_cardiovascular_min
      , pelod2_cv_lact     + pelod2_cv_map     AS pelod2_cardiovascular
      , pelod2_cv_lact_max + pelod2_cv_map_max AS pelod2_cardiovascular_max
    FROM t2
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t3.pelod2_cv_lact
    , COALESCE(t3.pelod2_cv_lact_min, 0) AS pelod2_cv_lact_min
    , COALESCE(t3.pelod2_cv_lact_max, 4) AS pelod2_cv_lact_max
    , t3.pelod2_cv_map
    , COALESCE(t3.pelod2_cv_map_min, 0) AS pelod2_cv_map_min
    , COALESCE(t3.pelod2_cv_map_max, 6) AS pelod2_cv_map_max
    , t3.pelod2_cardiovascular
    , COALESCE(t3.pelod2_cardiovascular_min, 0) AS pelod2_cardiovascular_min
    , COALESCE(t3.pelod2_cardiovascular_max, 10) AS pelod2_cardiovascular_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t3
  ON tc.site = t3.site AND tc.enc_id = t3.enc_id AND tc.eclock = t3.eclock
)
;
CALL **REDACTED**.sa.aggregate("pelod2_cardiovascular", "pelod2_cardiovascular_min");
