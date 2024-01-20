#standardSQL

/*
 * Hematologic System:
 * (1) Hemoglobin level less than 50 !lfL (<5 !lfdL);
 * (2) WBC count less than 3x109/L (<3,000 cells per cubic millimeter);
 * (3) platelet count less than 20xl09/L ( <20,000 cells per cubic millimeter); and
 * (4) D-dimer more than 0.5 v!lfmL with prothrombin time more than 20 s or
 *     partial thromboplastin time more than 60 s.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_heme` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , d_dimer.d_dimer
      , hgb.hgb
      , plts.platelets
      , pt.pt
      , ptt.ptt
      , wbc.wbc
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.d_dimer` d_dimer
    ON tc.site = d_dimer.site AND tc.enc_id = d_dimer.enc_id AND tc.eclock = d_dimer.eclock

    LEFT JOIN `**REDACTED**.timecourse.hgb` hgb
    ON tc.site = hgb.site AND tc.enc_id = hgb.enc_id AND tc.eclock = hgb.eclock

    LEFT JOIN `**REDACTED**.timecourse.platelets` plts
    ON tc.site = plts.site AND tc.enc_id = plts.enc_id AND tc.eclock = plts.eclock

    LEFT JOIN `**REDACTED**.timecourse.pt` pt
    ON tc.site = pt.site AND tc.enc_id = pt.enc_id AND tc.eclock = pt.eclock

    LEFT JOIN `**REDACTED**.timecourse.ptt` ptt
    ON tc.site = ptt.site AND tc.enc_id = ptt.enc_id AND tc.eclock = ptt.eclock

    LEFT JOIN `**REDACTED**.timecourse.wbc` wbc
    ON tc.site = wbc.site AND tc.enc_id = wbc.enc_id AND tc.eclock = wbc.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_heme
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (hgb < 5) OR (wbc < 3) OR (platelets < 20) OR (d_dimer > 0.5 AND (PT > 20 OR PTT > 60))

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (hgb < 5) IS FALSE AND
            (wbc < 3) IS FALSE AND
            (platelets < 20) IS FALSE AND
            (d_dimer > 0.5 AND (PT > 20 OR PTT > 60)) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.proulx_heme
    , COALESCE(t.proulx_heme, 0) AS proulx_heme_min
    , COALESCE(t.proulx_heme, 1) AS proulx_heme_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock

)
;
CALL **REDACTED**.sa.aggregate("proulx_heme", "proulx_heme_min");
