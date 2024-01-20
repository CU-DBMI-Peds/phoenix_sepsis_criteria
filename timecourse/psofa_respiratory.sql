#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , pfr.pf_ratio
      , sfr.sf_ratio
      , spo2.ok_for_non_podium
      , vent.vent
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` pfr
    ON tc.site = pfr.site AND tc.enc_id = pfr.enc_id AND tc.eclock = pfr.eclock
    LEFT JOIN `**REDACTED**.timecourse.sf_ratio` sfr
    ON tc.site = sfr.site AND tc.enc_id = sfr.enc_id AND tc.eclock = sfr.eclock
    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.site = spo2.site AND tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS psofa_respiratory
    FROM
    (
      SELECT site, enc_id, eclock, 4 AS value
      FROM t0
      WHERE (pf_ratio < 100 OR (ok_for_non_podium = 1 AND sf_ratio < 148)) AND (vent = 1)

      UNION ALL

      SELECT site, enc_id, eclock, 3 AS value
      FROM t0
      WHERE (pf_ratio < 200 OR (ok_for_non_podium = 1 AND sf_ratio < 221)) AND (vent = 1)

      UNION ALL

      SELECT site, enc_id, eclock, 2 AS value
      FROM t0
      WHERE (pf_ratio < 300 OR (ok_for_non_podium = 1 AND sf_ratio < 264))

      UNION ALL

      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (pf_ratio < 400 OR (ok_for_non_podium = 1 AND sf_ratio < 292))

      UNION ALL
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE ((pf_ratio < 100 OR (ok_for_non_podium = 1 AND sf_ratio < 148)) AND (vent = 1)) IS FALSE AND
            ((pf_ratio < 200 OR (ok_for_non_podium = 1 AND sf_ratio < 221)) AND (vent = 1)) IS FALSE AND
            ((pf_ratio < 300 OR (ok_for_non_podium = 1 AND sf_ratio < 264))) IS FALSE AND
            ((pf_ratio < 400 OR (ok_for_non_podium = 1 AND sf_ratio < 292))) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.psofa_respiratory
    , COALESCE(t.psofa_respiratory, 0) AS psofa_respiratory_min
    , COALESCE(t.psofa_respiratory, 4) AS psofa_respiratory_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_respiratory", "psofa_respiratory_min");
