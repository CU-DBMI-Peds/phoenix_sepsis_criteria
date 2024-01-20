#standardSQL
-- Disseminated intravascular coagulation score

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.dic` AS (
  WITH t0 AS
  (
    SELECT
        a.site
      , a.enc_id
      , a.eclock
      , b.platelets
      , c.fibrinogen
      , d.d_dimer -- used instead of FDP
      , e.inr -- will be used instead of pt per issue #78 and Larsen et.al. (2021)
    FROM **REDACTED**.timecourse.foundation a
    LEFT JOIN **REDACTED**.timecourse.platelets b
    ON a.site = b.site AND a.enc_id = b.enc_id AND a.eclock = b.eclock
    LEFT JOIN **REDACTED**.timecourse.fibrinogen c
    ON a.site = c.site AND a.enc_id = c.enc_id AND a.eclock = c.eclock
    LEFT JOIN **REDACTED**.timecourse.d_dimer d
    ON a.site = d.site AND a.enc_id = d.enc_id AND a.eclock = d.eclock
    LEFT JOIN **REDACTED**.timecourse.inr e
    ON a.site = e.site AND a.enc_id = e.enc_id AND a.eclock = e.eclock
  )
  , inr AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS inr
    FROM
    (
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE inr < 1.3
      UNION ALL
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE inr >= 1.3 AND inr <= 1.6
      UNION ALL
      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE inr > 1.6
    )
    GROUP BY site, enc_id, eclock
  )
  , plts AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS plts
    FROM
    (
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE platelets > 100
      UNION ALL
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE platelets > 50 AND platelets <= 100
      UNION ALL
      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE platelets <= 50
    )
    GROUP BY site, enc_id, eclock
  )
  , fibr AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS fibr
    FROM
    (
      SELECT site, enc_id, eclock, 0 as value
      FROM t0
      WHERE fibrinogen >= 100
      UNION ALL
      SELECT site, enc_id, eclock, 1 as value
      FROM t0
      WHERE fibrinogen < 100
    )
    GROUP BY site, enc_id, eclock
  )
  , d_dimer AS
  (
    SELECT site, enc_id, eclock, MAX(value) as d_dimer
    FROM
    (
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE d_dimer <= 2
      UNION ALL
      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE d_dimer > 2 AND d_dimer <= 8
      UNION ALL
      SELECT site, enc_id, eclock, 3 AS value
      FROM t0
      WHERE d_dimer > 8
    )
    GROUP BY site, enc_id, eclock
  )
  , t1 AS
  (
    SELECT
        t0.site
      , t0.enc_id
      , t0.eclock
      , plts.plts
      , fibr.fibr
      , d_dimer.d_dimer
      , inr.inr
    FROM t0
    LEFT JOIN plts
    ON t0.site = plts.site AND t0.enc_id = plts.enc_id AND t0.eclock = plts.eclock
    LEFT JOIN fibr
    ON t0.site = fibr.site AND t0.enc_id = fibr.enc_id AND t0.eclock = fibr.eclock
    LEFT JOIN d_dimer
    ON t0.site = d_dimer.site AND t0.enc_id = d_dimer.enc_id AND t0.eclock = d_dimer.eclock
    LEFT JOIN inr
    ON t0.site = inr.site AND t0.enc_id = inr.enc_id AND t0.eclock = inr.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    -- REPLACE pt with inr
    , (COALESCE(plts, 0) + COALESCE(fibr, 0) + COALESCE(d_dimer, 0) + COALESCE(inr, 0)) AS dic_min
    , (plts + fibr + d_dimer + inr) AS dic
    , (COALESCE(plts, 2) + COALESCE(fibr, 1) + COALESCE(d_dimer, 3) + COALESCE(inr, 2)) AS dic_max
  FROM t1
)
;

/*
SELECT DISTINCT a.dic_min, a.dic, a.dic_max
FROM **REDACTED**.timecourse.dic a
ORDER BY a.dic_min, a.dic, a.dic_max
;
*/

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("dic", "dic_min");
