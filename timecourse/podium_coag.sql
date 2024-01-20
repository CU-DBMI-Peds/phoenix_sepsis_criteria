#standardSQL
CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_coag` AS
(
  WITH t0 AS (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.pccc_malignancy
      , a.platelets
      , b.inr
      , c.fibrinogen
      , d.d_dimer
      , e.podium_hepatic
      , f.wbc
      , g.hgb
    FROM **REDACTED**.timecourse.foundation tc
    LEFT JOIN **REDACTED**.timecourse.platelets a
    ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock
    LEFT JOIN **REDACTED**.timecourse.inr b
    ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock
    LEFT JOIN **REDACTED**.timecourse.fibrinogen c
    ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock
    LEFT JOIN **REDACTED**.timecourse.d_dimer d
    ON tc.site = d.site AND tc.enc_id = d.enc_id AND tc.eclock = d.eclock
    LEFT JOIN **REDACTED**.timecourse.podium_hepatic e
    ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock
    LEFT JOIN **REDACTED**.timecourse.wbc f
    ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock
    LEFT JOIN **REDACTED**.timecourse.hgb g
    ON tc.site = g.site AND tc.enc_id = g.enc_id AND tc.eclock = g.eclock
  )
  ,
  t1 AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_coag
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE ((platelets < 100) OR (inr > 1.5) OR (fibrinogen < 150) OR (d_dimer > 5)) AND podium_hepatic = 0
      UNION ALL
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (((platelets < 100) OR (inr > 1.5) OR (fibrinogen < 150) OR (d_dimer > 5)) AND podium_hepatic = 0)
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      t0.site
    , t0.enc_id
    , t0.eclock
    , COALESCE(t1.podium_coag, 0) AS podium_coag_min
    , COALESCE(t1.podium_coag, 1) AS podium_coag_max
    , t1.podium_coag AS podium_coag
  FROM t0
  LEFT JOIN t1
  ON t0.site = t1.site AND t0.enc_id = t1.enc_id AND t0.eclock = t1.eclock
)
;
CALL **REDACTED**.sa.aggregate("podium_coag", "podium_coag_min");
