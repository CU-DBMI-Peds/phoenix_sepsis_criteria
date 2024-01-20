#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , bp.sbp
      , ecmo.ecmo_va
      , lactate.lactate
      , pulse.pulse
      , vis.vis
      , troponin.troponin
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock

    LEFT JOIN `**REDACTED**.timecourse.ecmo` ecmo
    ON tc.site = ecmo.site AND tc.enc_id = ecmo.enc_id AND tc.eclock = ecmo.eclock

    LEFT JOIN `**REDACTED**.timecourse.lactate` lactate
    ON tc.site = lactate.site AND tc.enc_id = lactate.enc_id AND tc.eclock = lactate.eclock

    LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
    ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock

    LEFT JOIN `**REDACTED**.timecourse.troponin` troponin
    ON tc.site = troponin.site AND tc.enc_id = troponin.enc_id AND tc.eclock = troponin.eclock

    LEFT JOIN `**REDACTED**.timecourse.vis` vis
    ON tc.site = vis.site AND tc.enc_id = vis.enc_id AND tc.eclock = vis.eclock
  )
  , cv_hr AS (
    SELECT site, enc_id, eclock, MAX(value) as podium_cv_hr
    FROM
    (
        SELECT site, enc_id, eclock, 1 as value
        FROM t0
        WHERE (pulse > 180 AND                       age_months <   12) OR
              (pulse > 160 AND age_months >=  12 AND age_months <   72) OR
              (pulse > 150 AND age_months >=  72 AND age_months <  156) OR
              (pulse > 130 AND age_months >= 156 AND age_months >= 156)

        UNION ALL

        SELECT site, enc_id, eclock, 0 as value
        FROM t0
        WHERE (pulse > 180 AND                       age_months <   12) IS FALSE AND
              (pulse > 160 AND age_months >=  12 AND age_months <   72) IS FALSE AND
              (pulse > 150 AND age_months >=  72 AND age_months <  156) IS FALSE AND
              (pulse > 130 AND age_months >= 156 AND age_months >= 156)
    )
    GROUP BY site, enc_id, eclock
  )
  , cv_sbp AS (
    SELECT site, enc_id, eclock, MAX(value) as podium_cv_sbp
    FROM
    (
        SELECT site, enc_id, eclock, 1 as value
        FROM t0
        WHERE (sbp < 50 AND                         age_months <   0.25) OR
              (sbp < 70 AND age_months >=  0.25 AND age_months <   1.00) OR
              (sbp < 75 AND age_months >=  1.00 AND age_months <  72.00) OR
              (sbp < 80 AND age_months >= 72.00 AND age_months >= 72.00)

        UNION ALL

        SELECT site, enc_id, eclock, 0 as value
        FROM t0
        WHERE (sbp < 50 AND                         age_months <   0.25) IS FALSE AND
              (sbp < 70 AND age_months >=  0.25 AND age_months <   1.00) IS FALSE AND
              (sbp < 75 AND age_months >=  1.00 AND age_months <  72.00) IS FALSE AND
              (sbp < 80 AND age_months >= 72.00 AND age_months >= 72.00)
    )
    GROUP BY site, enc_id, eclock
  )
  , cv_vis AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_cv_vis
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0 WHERE vis >= 5

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0 WHERE vis < 5
    )
    GROUP BY site, enc_id, eclock
  )
  , cv_lact AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_cv_lact
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0 WHERE lactate >= 3

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0 WHERE lactate < 3
    )
    GROUP BY site, enc_id, eclock
  )
  , cv_ecmo_va AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_cv_ecmo_va
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0 WHERE ecmo_va > 0

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0 WHERE (ecmo_va > 0) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )
  , cv_trop AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_cv_trop
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0 WHERE troponin >= 0.6

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0 WHERE troponin < 0.6
    )
    GROUP BY site, enc_id, eclock
  )
  , cv AS (
    SELECT tc.site, tc.enc_id, tc.eclock,
      podium_cv_hr, podium_cv_sbp, podium_cv_vis,
      podium_cv_lact, podium_cv_ecmo_va, podium_cv_trop
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN cv_hr
    ON tc.site = cv_hr.site AND tc.enc_id = cv_hr.enc_id AND tc.eclock = cv_hr.eclock
    LEFT JOIN cv_sbp
    ON tc.site = cv_sbp.site AND tc.enc_id = cv_sbp.enc_id AND tc.eclock = cv_sbp.eclock
    LEFT JOIN cv_vis
    ON tc.site = cv_vis.site AND tc.enc_id = cv_vis.enc_id AND tc.eclock = cv_vis.eclock
    LEFT JOIN cv_lact
    ON tc.site = cv_lact.site AND tc.enc_id = cv_lact.enc_id AND tc.eclock = cv_lact.eclock
    LEFT JOIN cv_ecmo_va
    ON tc.site = cv_ecmo_va.site AND tc.enc_id = cv_ecmo_va.enc_id AND tc.eclock = cv_ecmo_va.eclock
    LEFT JOIN cv_trop
    ON tc.site = cv_trop.site AND tc.enc_id = cv_trop.enc_id AND tc.eclock = cv_trop.eclock
  )
  , t AS (
    SELECT site, enc_id, eclock,
      CASE
        WHEN podium_cv_ecmo_va = 1 THEN 1
        WHEN COALESCE(podium_cv_hr, 0) +
             COALESCE(podium_cv_sbp, 0) +
             COALESCE(podium_cv_vis, 0) +
             COALESCE(podium_cv_lact, 0) >= 2 THEN 1
        WHEN podium_cv_ecmo_va = 0 AND
             (
              (COALESCE(podium_cv_hr, 0) + COALESCE(podium_cv_sbp, 0) + COALESCE(podium_cv_vis, 0) + COALESCE(podium_cv_lact, 0)) = 1
              AND
             (IF(podium_cv_hr IS NULL, 1, 0) + IF(podium_cv_sbp IS NULL, 1, 0) + IF(podium_cv_vis IS NULL, 1, 0) + IF(podium_cv_lact IS NULL, 1, 0)) = 0
            ) THEN 0
        WHEN podium_cv_ecmo_va = 0 AND
             (
              (COALESCE(podium_cv_hr, 0) + COALESCE(podium_cv_sbp, 0) + COALESCE(podium_cv_vis, 0) + COALESCE(podium_cv_lact, 0)) = 0
              AND
             (IF(podium_cv_hr IS NULL, 1, 0) + IF(podium_cv_sbp IS NULL, 1, 0) + IF(podium_cv_vis IS NULL, 1, 0) + IF(podium_cv_lact IS NULL, 1, 0)) <= 1
          ) THEN 0
        ELSE NULL
      END AS podium_cardiovascular_wo_troponin,
      CASE
        WHEN podium_cv_ecmo_va = 1 THEN 1
        WHEN COALESCE(podium_cv_hr, 0) +
             COALESCE(podium_cv_sbp, 0) +
             COALESCE(podium_cv_vis, 0) +
             COALESCE(podium_cv_lact, 0) +
             COALESCE(podium_cv_trop, 0) >= 2 THEN 1
        WHEN podium_cv_ecmo_va = 0 AND
             (
              (COALESCE(podium_cv_hr, 0) + COALESCE(podium_cv_sbp, 0) + COALESCE(podium_cv_vis, 0) + COALESCE(podium_cv_lact, 0) + COALESCE(podium_cv_trop, 0)) = 1
              AND
             (IF(podium_cv_hr IS NULL, 1, 0) + IF(podium_cv_sbp IS NULL, 1, 0) + IF(podium_cv_vis IS NULL, 1, 0) + IF(podium_cv_lact IS NULL, 1, 0) + IF(podium_cv_trop IS NULL, 1, 0)) = 0
            ) THEN 0
        WHEN podium_cv_ecmo_va = 0 AND
             (
              (COALESCE(podium_cv_hr, 0) + COALESCE(podium_cv_sbp, 0) + COALESCE(podium_cv_vis, 0) + COALESCE(podium_cv_lact, 0) + COALESCE(podium_cv_trop, 0)) = 0
              AND
             (IF(podium_cv_hr IS NULL, 1, 0) + IF(podium_cv_sbp IS NULL, 1, 0) + IF(podium_cv_vis IS NULL, 1, 0) + IF(podium_cv_lact IS NULL, 1, 0) + IF(podium_cv_trop IS NULL, 1, 0)) <= 1
          ) THEN 0
        ELSE NULL
      END AS podium_cardiovascular_w_troponin
    FROM cv
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.podium_cardiovascular_w_troponin
    , t.podium_cardiovascular_wo_troponin
    , COALESCE(t.podium_cardiovascular_wo_troponin, 0) AS podium_cardiovascular_wo_troponin_min
    , COALESCE(t.podium_cardiovascular_wo_troponin, 1) AS podium_cardiovascular_wo_troponin_max
    , COALESCE(t.podium_cardiovascular_w_troponin,  0) AS podium_cardiovascular_w_troponin_min
    , COALESCE(t.podium_cardiovascular_w_troponin,  1) AS podium_cardiovascular_w_troponin_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("podium_cardiovascular", "podium_cardiovascular_wo_troponin_min");
CALL **REDACTED**.sa.aggregate("podium_cardiovascular", "podium_cardiovascular_w_troponin_min");
