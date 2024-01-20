#standardSQL
CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_heme` AS
(
  WITH t0 AS (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.pccc_malignancy
      , a.platelets
      , f.wbc
      , g.hgb
      , h.podium_coag
    FROM **REDACTED**.timecourse.foundation tc
    LEFT JOIN **REDACTED**.timecourse.platelets a
    ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock
    LEFT JOIN **REDACTED**.timecourse.wbc f
    ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock
    LEFT JOIN **REDACTED**.timecourse.hgb g
    ON tc.site = g.site AND tc.enc_id = g.enc_id AND tc.eclock = g.eclock
    LEFT JOIN **REDACTED**.timecourse.podium_coag h
    ON tc.site = h.site AND tc.enc_id = h.enc_id AND tc.eclock = h.eclock
  )
  ,
  t1 AS (
    SELECT site, enc_id, eclock, MAX(value) AS podium_heme
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (platelets < 100 AND podium_coag = 0) OR
            (platelets < 30) OR
            (wbc < 3) OR
            (hgb < 7)
      UNION ALL
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE NOT (
            (platelets < 100 AND podium_coag = 0) OR
            (platelets < 30) OR
            (wbc < 3) OR
            (hgb < 7)
          )
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      t0.site
    , t0.enc_id
    , t0.eclock
    , COALESCE(t1.podium_heme, 0) AS podium_heme_min
    , COALESCE(t1.podium_heme, 1) AS podium_heme_max
    , t1.podium_heme AS podium_heme
  FROM t0
  LEFT JOIN t1
  ON t0.site = t1.site AND t0.enc_id = t1.enc_id AND t0.eclock = t1.eclock
)
;
CALL **REDACTED**.sa.aggregate("podium_heme", "podium_heme_min");
