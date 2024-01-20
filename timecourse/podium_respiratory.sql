#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        a.enc_id
      , a.eclock
      , b.ecmo
      , c.pf_ratio
      , d.sf_ratio
      , d1.ok_for_podium
      , e.nppv
      , f.vent
      , g.oi
      , h.osi
      , i.fio2
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.ecmo` b
    ON a.enc_id = b.enc_id AND a.eclock = b.eclock
    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` c
    ON a.enc_id = c.enc_id AND a.eclock = c.eclock
    LEFT JOIN `**REDACTED**.timecourse.sf_ratio` d
    ON a.enc_id = d.enc_id AND a.eclock = d.eclock
    LEFT JOIN `**REDACTED**.timecourse.spo2` d1
    ON a.enc_id = d1.enc_id AND a.eclock = d1.eclock
    LEFT JOIN `**REDACTED**.timecourse.nppv` e
    ON a.enc_id = e.enc_id AND a.eclock = e.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` f
    ON a.enc_id = f.enc_id AND a.eclock = f.eclock
    LEFT JOIN `**REDACTED**.timecourse.oi` g
    ON a.enc_id = g.enc_id AND a.eclock = g.eclock
    LEFT JOIN `**REDACTED**.timecourse.osi` h
    ON a.enc_id = h.enc_id AND a.eclock = h.eclock
    LEFT JOIN `**REDACTED**.timecourse.fio2` i
    ON a.enc_id = i.enc_id AND a.eclock = i.eclock
  )
  , t AS
  (
    SELECT enc_id, eclock, MAX(value) as podium_respiratory
    FROM
    (
      SELECT enc_id, eclock, 1 AS value
      FROM t0
      WHERE (ecmo > 0) OR
            (pf_ratio <= 300 AND nppv = 1 AND fio2 >= 0.4) OR
            (ok_for_podium = 1 AND sf_ratio <= 264 AND nppv = 1 AND fio2 >= 0.4) OR
            (vent > 0 AND oi >= 4) OR
            (vent > 0 AND osi >= 5)
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM t0
      WHERE (ecmo > 0) IS FALSE AND
            (pf_ratio <= 300 AND nppv = 1 AND fio2 >= 0.4) IS FALSE AND
            (ok_for_podium = 1 AND ((sf_ratio <= 264 AND nppv = 1 AND fio2 >= 0.4) IS FALSE)) AND
            (vent > 0 AND oi >= 4) IS FALSE AND
            (vent > 0 and osi >= 5) IS FALSE
    )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.podium_respiratory,
    COALESCE(t.podium_respiratory, 0) AS podium_respiratory_min,
    COALESCE(t.podium_respiratory, 1) AS podium_respiratory_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock

)
;
CALL **REDACTED**.sa.aggregate("podium_respiratory", "podium_respiratory_min");
