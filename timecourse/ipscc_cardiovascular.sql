#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , base_def.base_def
      , lactate.lactate
      , dob.dobutamine
      , dob.dobutamine_yn
      , dop.dopamine
      , dop.dopamine_yn
      , epi.epinephrine
      , epi.epinephrine_yn
      , norepi.norepinephrine
      , norepi.norepinephrine_yn
      , bp.sbp
      , u.urine_low_6hr
      , u.urine_low_12hr
      , crt.crt_prolonged_5
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.base_def` base_def
    ON tc.site = base_def.site AND tc.enc_id = base_def.enc_id AND tc.eclock = base_def.eclock

    LEFT JOIN `**REDACTED**.timecourse.lactate` lactate
    ON tc.site = lactate.site AND tc.enc_id = lactate.enc_id AND tc.eclock = lactate.eclock

    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dob
    ON tc.site = dob.site AND tc.enc_id = dob.enc_id AND tc.eclock = dob.eclock

    LEFT JOIN `**REDACTED**.timecourse.dopamine` dop
    ON tc.site = dop.site AND tc.enc_id = dop.enc_id AND tc.eclock = dop.eclock

    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epi
    ON tc.site = epi.site AND tc.enc_id = epi.enc_id AND tc.eclock = epi.eclock

    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepi
    ON tc.site = norepi.site AND tc.enc_id = norepi.enc_id AND tc.eclock = norepi.eclock

    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock

    LEFT JOIN `**REDACTED**.timecourse.urine` u
    ON tc.site = u.site AND tc.enc_id = u.enc_id AND tc.eclock = u.eclock

    LEFT JOIN `**REDACTED**.timecourse.crt_prolonged` crt
    ON tc.site = crt.site AND tc.enc_id = crt.enc_id AND tc.eclock = crt.eclock
  )
  ,
  t06 AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_cardiovascular_06
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_6hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_6hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_6hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_6hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_6hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_6hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)
      )
    )
    GROUP BY site, enc_id, eclock
  )
  , t12 AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_cardiovascular_12
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_12hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_12hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_12hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_12hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_12hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_12hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)
      )
    )
    GROUP BY site, enc_id, eclock
  )
  ,
  t06_b AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_cardiovascular_06_b
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_6hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_6hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_6hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_6hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_6hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_6hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)
      )
    )
    GROUP BY site, enc_id, eclock
  )
  , t12_b AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_cardiovascular_12_b
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_12hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_12hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_12hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (
              (base_def > 5 AND lactate > 4.4) OR
              (base_def > 5 AND urine_low_12hr = 1) OR
              (base_def > 5 AND crt_prolonged_5 = 1) OR
              (lactate > 4.4 AND urine_low_12hr = 1) OR
              (lactate > 4.4 AND crt_prolonged_5 = 1) OR
              (urine_low_12hr = 1 AND crt_prolonged_5 = 1)
            ) OR
            (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) OR
            (age_months <   0.25 AND                       sbp < 59) OR
            (age_months >=  0.25 AND age_months <    1 AND sbp < 79) OR
            (age_months >=  1.00 AND age_months <=  12 AND sbp < 75) OR
            (age_months >  12.00 AND age_months <=  72 AND sbp < 74) OR
            (age_months >  72.00 AND age_months <= 144 AND sbp < 83) OR
            (age_months > 144.00 AND                       sbp < 90)
      )
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t06.ipscc_cardiovascular_06
    , COALESCE(t06.ipscc_cardiovascular_06, 0) AS ipscc_cardiovascular_06_min
    , COALESCE(t06.ipscc_cardiovascular_06, 1) AS ipscc_cardiovascular_06_max
    , t12.ipscc_cardiovascular_12
    , COALESCE(t12.ipscc_cardiovascular_12, 0) AS ipscc_cardiovascular_12_min
    , COALESCE(t12.ipscc_cardiovascular_12, 1) AS ipscc_cardiovascular_12_max
    , t06_b.ipscc_cardiovascular_06_b
    , COALESCE(t06_b.ipscc_cardiovascular_06_b, 0) AS ipscc_cardiovascular_06_b_min
    , COALESCE(t06_b.ipscc_cardiovascular_06_b, 1) AS ipscc_cardiovascular_06_b_max
    , t12_b.ipscc_cardiovascular_12_b
    , COALESCE(t12_b.ipscc_cardiovascular_12_b, 0) AS ipscc_cardiovascular_12_b_min
    , COALESCE(t12_b.ipscc_cardiovascular_12_b, 1) AS ipscc_cardiovascular_12_b_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t06
  ON tc.site = t06.site AND tc.enc_id = t06.enc_id AND tc.eclock = t06.eclock
  LEFT JOIN t12
  ON tc.site = t12.site AND tc.enc_id = t12.enc_id AND tc.eclock = t12.eclock
  LEFT JOIN t06_b
  ON tc.site = t06_b.site AND tc.enc_id = t06_b.enc_id AND tc.eclock = t06_b.eclock
  LEFT JOIN t12_b
  ON tc.site = t12_b.site AND tc.enc_id = t12_b.enc_id AND tc.eclock = t12_b.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_cardiovascular", "ipscc_cardiovascular_06_min");
CALL **REDACTED**.sa.aggregate("ipscc_cardiovascular", "ipscc_cardiovascular_12_min");
CALL **REDACTED**.sa.aggregate("ipscc_cardiovascular", "ipscc_cardiovascular_06_b_min");
CALL **REDACTED**.sa.aggregate("ipscc_cardiovascular", "ipscc_cardiovascular_12_b_min");
