#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , niv.niv
      , paco2.paco2
      , pfr.pf_ratio
      , sfr.sf_ratio
      , spo2.ok_for_non_podium
      , vent.vent
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.niv` niv
    ON tc.site = niv.site AND tc.enc_id = niv.enc_id AND tc.eclock = niv.eclock

    LEFT JOIN `**REDACTED**.timecourse.paco2` paco2
    ON tc.site = paco2.site AND tc.enc_id = paco2.enc_id AND tc.eclock = paco2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` pfr
    ON tc.site = pfr.site AND tc.enc_id = pfr.enc_id AND tc.eclock = pfr.eclock

    LEFT JOIN `**REDACTED**.timecourse.sf_ratio` sfr
    ON tc.site = sfr.site AND tc.enc_id = sfr.enc_id AND tc.eclock = sfr.eclock

    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.site = spo2.site AND tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock

    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock

  )
  , t AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS ipscc_respiratory
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (pf_ratio < 300) OR
            (ok_for_non_podium = 1 AND sf_ratio < 180) OR
            (vent = 1) OR
            (paco2 > 65) OR
            (niv = 1)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (pf_ratio < 300) IS FALSE AND
            (ok_for_non_podium = 1 AND sf_ratio >= 180) AND
            (vent = 1) IS FALSE AND
            (paco2 > 65) IS FALSE AND
            (niv = 1) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.ipscc_respiratory
    , COALESCE(t.ipscc_respiratory, 0) AS ipscc_respiratory_min
    , COALESCE(t.ipscc_respiratory, 1) AS ipscc_respiratory_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_respiratory", "ipscc_respiratory_min");
