#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , dobutamine.dobutamine
      , dobutamine.dobutamine_yn
      , dopamine.dopamine
      , dopamine.dopamine_yn
      , epinephrine.epinephrine
      , epinephrine.epinephrine_yn
      , norepinephrine.norepinephrine
      , norepinephrine.norepinephrine_yn
      , bp.map
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dobutamine
    ON tc.site = dobutamine.site AND tc.enc_id = dobutamine.enc_id AND tc.eclock = dobutamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.dopamine` dopamine
    ON tc.site = dopamine.site AND tc.enc_id = dopamine.enc_id AND tc.eclock = dopamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epinephrine
    ON tc.site = epinephrine.site AND tc.enc_id = epinephrine.enc_id AND tc.eclock = epinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepinephrine
    ON tc.site = norepinephrine.site AND tc.enc_id = norepinephrine.enc_id AND tc.eclock = norepinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock

  )
  ,
  t AS (
    SELECT enc_id, eclock, MAX(psofa_cardiovascular) as psofa_cardiovascular
    FROM
    (
      SELECT enc_id, eclock, 4 AS psofa_cardiovascular
      FROM t0
      WHERE dopamine > 15.0 OR epinephrine > 0.1 OR norepinephrine > 0.1
      UNION ALL
      SELECT enc_id, eclock, 3 AS psofa_cardiovascular
      FROM t0
      WHERE dopamine >  5.0 OR epinephrine > 0.0 OR norepinephrine > 0.0
      UNION ALL
      SELECT enc_id, eclock, 2 AS psofa_cardiovascular
      FROM t0
      WHERE dopamine >  0.0 OR dobutamine > 0.0
      UNION ALL
      SELECT enc_id, eclock, 1 AS psofa_cardiovascular
      FROM t0
      WHERE (                      age_months <    1 AND map < 46) OR
            (age_months >=   1 AND age_months <   12 AND map < 55) OR
            (age_months >=  12 AND age_months <   24 AND map < 60) OR
            (age_months >=  24 AND age_months <   60 AND map < 62) OR
            (age_months >=  60 AND age_months <  144 AND map < 65) OR
            (age_months >= 144 AND age_months <= 216 AND map < 67) OR
            (age_months >  216                       AND map < 70)
      UNION ALL
      SELECT enc_id, eclock, 0 AS psofa_cardiovascular
      FROM t0
      WHERE (dopamine > 15.0 OR epinephrine > 0.1 OR norepinephrine > 0.1) IS FALSE AND
            (dopamine >  5.0 OR epinephrine > 0.0 OR norepinephrine > 0.0) IS FALSE AND
            (dopamine >  0.0 OR dobutamine  > 0.0) IS FALSE AND
            (
              (                      age_months <    1 AND map < 46) OR
              (age_months >=   1 AND age_months <   12 AND map < 55) OR
              (age_months >=  12 AND age_months <   24 AND map < 60) OR
              (age_months >=  24 AND age_months <   60 AND map < 62) OR
              (age_months >=  60 AND age_months <  144 AND map < 65) OR
              (age_months >= 144 AND age_months <= 216 AND map < 67) OR
              (age_months >  216                       AND map < 70)
            ) IS FALSE
      )
      GROUP BY enc_id, eclock
  )
  ,
  t_b AS (
    SELECT enc_id, eclock, MAX(psofa_cardiovascular) as psofa_cardiovascular
    FROM
    (
      SELECT enc_id, eclock, 4 AS psofa_cardiovascular
      FROM t0
      WHERE dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0
      UNION ALL
      SELECT enc_id, eclock, 2 AS psofa_cardiovascular
      FROM t0
      WHERE dopamine_yn > 0 OR dobutamine_yn > 0
      UNION ALL
      SELECT enc_id, eclock, 1 AS psofa_cardiovascular
      FROM t0
      WHERE (                      age_months <    1 AND map < 46) OR
            (age_months >=   1 AND age_months <   12 AND map < 55) OR
            (age_months >=  12 AND age_months <   24 AND map < 60) OR
            (age_months >=  24 AND age_months <   60 AND map < 62) OR
            (age_months >=  60 AND age_months <  144 AND map < 65) OR
            (age_months >= 144 AND age_months <= 216 AND map < 67) OR
            (age_months >  216                       AND map < 70)
      UNION ALL
      SELECT enc_id, eclock, 0 AS psofa_cardiovascular
      FROM t0
      WHERE (dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) IS FALSE AND
            (dopamine_yn > 0 OR epinephrine_yn > 0) IS FALSE AND
            (
              (                      age_months <    1 AND map < 46) OR
              (age_months >=   1 AND age_months <   12 AND map < 55) OR
              (age_months >=  12 AND age_months <   24 AND map < 60) OR
              (age_months >=  24 AND age_months <   60 AND map < 62) OR
              (age_months >=  60 AND age_months <  144 AND map < 65) OR
              (age_months >= 144 AND age_months <= 216 AND map < 67) OR
              (age_months >  216                       AND map < 70)
            ) IS FALSE
      )
      GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.psofa_cardiovascular,
    COALESCE(t.psofa_cardiovascular, 0) AS psofa_cardiovascular_min,
    COALESCE(t.psofa_cardiovascular, 4) AS psofa_cardiovascular_max,
    t_b.psofa_cardiovascular as psofa_cardiovascular_b,
    COALESCE(t_b.psofa_cardiovascular, 0) AS psofa_cardiovascular_b_min,
    COALESCE(t_b.psofa_cardiovascular, 4) AS psofa_cardiovascular_b_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
  LEFT JOIN t_b
  ON tc.enc_id = t_b.enc_id AND tc.eclock = t_b.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_cardiovascular", "psofa_cardiovascular_min");
CALL **REDACTED**.sa.aggregate("psofa_cardiovascular", "psofa_cardiovascular_b_min");
