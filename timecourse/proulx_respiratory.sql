#standardSQL

/*
 * Respiratory System:
 * (1) Respiratory rate more than 90 breaths/min for patients younger than 12
 *     months or more than 70 breaths/min for patients 12 months or older;
 * (2) PaC02 more than 8.7 kPa (>65 mm Hg);
 * (3) Pa02less than 5.3 kPa ( <40 mm Hg), in the absence of cyanotic congenital
 *     heart disease;
 * (4) mechanical ventilation (for >24 h in a postoperative patient); and
 * (5) PaOd fraction of inspired oxygen less than 200, in the absence of
 *     cyanotic congenital heart disease.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , rr.respiratory_rate
      , paco2.paco2
      , pao2.pao2
      , pf_ratio.pf_ratio
      , vent.vent
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.respiratory_rate` rr
    ON tc.site = rr.site AND tc.enc_id = rr.enc_id AND tc.eclock = rr.eclock

    LEFT JOIN `**REDACTED**.timecourse.paco2` paco2
    ON tc.site = paco2.site AND tc.enc_id = paco2.enc_id AND tc.eclock = paco2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pao2` pao2
    ON tc.site = pao2.site AND tc.enc_id = pao2.enc_id AND tc.eclock = pao2.eclock

    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock

    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` pf_ratio
    ON tc.site = pf_ratio.site AND tc.enc_id = pf_ratio.enc_id AND tc.eclock = pf_ratio.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_respiratory
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (respiratory_rate > 90 AND age_months <  12) OR
            (respiratory_rate > 70 AND age_months >= 12) OR
            (paco2 > 65) OR
            (pao2 < 40) OR
            (vent > 0) OR
            (pf_ratio < 200)
      UNION ALL
      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (respiratory_rate > 90 AND age_months <  12) IS FALSE AND
            (respiratory_rate > 70 AND age_months >= 12) IS FALSE AND
            (paco2 > 65) IS FALSE AND
            (pao2 < 40) IS FALSE AND
            (vent > 0) IS FALSE AND
            (pf_ratio < 200) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.proulx_respiratory
    , COALESCE(t.proulx_respiratory, 0) AS proulx_respiratory_min
    , COALESCE(t.proulx_respiratory, 1) AS proulx_respiratory_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("proulx_respiratory", "proulx_respiratory_min");
