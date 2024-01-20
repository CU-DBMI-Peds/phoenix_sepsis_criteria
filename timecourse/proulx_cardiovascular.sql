#standardSQL

/*
 * Cardiovascular System:
 * (1) Systolic BP less than 40 mm Hg for patients younger than 12 months or
 *     less than 50 mm Hg for patients 12 months or older;
 * (2) heart rate less than 50 or more than 220 beats/min for patients younger
 *     than 12 months or less than 40 or more than 200 beats/min for patients
 *     aged 12 months or older;
 * (3) cardiac arrest;
 * (4) serum pH less than 7.2 with a normal PaC02 value; and
 * (5) continuous IV infusion of inotropic agents to maintain BP and/or cardiac
 *     output (dopamine :55 pglk!lfmin was excluded).
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months

      , bp.sbp
      , dobutamine.dobutamine
      , dobutamine.dobutamine_yn
      , dopamine.dopamine
      , dopamine.dopamine_yn
      , epinephrine.epinephrine
      , epinephrine.epinephrine_yn
      , norepinephrine.norepinephrine
      , norepinephrine.norepinephrine_yn
      , paco2.paco2
      , pulse.pulse
      , serum_ph.serum_ph

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock

    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dobutamine
    ON tc.site = dobutamine.site AND tc.enc_id = dobutamine.enc_id AND tc.eclock = dobutamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.dopamine` dopamine
    ON tc.site = dopamine.site AND tc.enc_id = dopamine.enc_id AND tc.eclock = dopamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epinephrine
    ON tc.site = epinephrine.site AND tc.enc_id = epinephrine.enc_id AND tc.eclock = epinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepinephrine
    ON tc.site = norepinephrine.site AND tc.enc_id = norepinephrine.enc_id AND tc.eclock = norepinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.paco2` paco2
    ON tc.site = paco2.site AND tc.enc_id = paco2.enc_id AND tc.eclock = paco2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
    ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock

    LEFT JOIN `**REDACTED**.timecourse.serum_ph` serum_ph
    ON tc.site = serum_ph.site AND tc.enc_id = serum_ph.enc_id AND tc.eclock = serum_ph.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_cardiovascular
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE
        (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) OR
        (sbp < 40 AND age_months < 12) OR
        (sbp < 50 AND age_months >= 12) OR
        ((pulse < 50 OR pulse > 220) AND age_months < 12) OR
        ((pulse < 40 OR pulse > 200) AND age_months >= 12) OR
        (serum_ph < 7.2 AND (paco2 >= 38 AND paco2 <= 42))

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE
        (dobutamine > 0 OR dopamine > 5 OR epinephrine > 0 OR norepinephrine > 0) IS FALSE AND
        (sbp < 40 AND age_months < 12) IS FALSE AND
        (sbp < 50 AND age_months >= 12) IS FALSE AND
        ((pulse < 50 OR pulse > 220) AND age_months < 12) IS FALSE AND
        ((pulse < 40 OR pulse > 200) AND age_months >= 12) IS FALSE AND
        (serum_ph < 7.2 AND (paco2 >= 38 AND paco2 <= 42)) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )
  ,
  t_b AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_cardiovascular_b
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE
        (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) OR
        (sbp < 40 AND age_months < 12) OR
        (sbp < 50 AND age_months >= 12) OR
        ((pulse < 50 OR pulse > 220) AND age_months < 12) OR
        ((pulse < 40 OR pulse > 200) AND age_months >= 12) OR
        (serum_ph < 7.2 AND (paco2 >= 38 AND paco2 <= 42))

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE
        (dobutamine_yn > 0 OR dopamine_yn > 0 OR epinephrine_yn > 0 OR norepinephrine_yn > 0) IS FALSE AND
        (sbp < 40 AND age_months < 12) IS FALSE AND
        (sbp < 50 AND age_months >= 12) IS FALSE AND
        ((pulse < 50 OR pulse > 220) AND age_months < 12) IS FALSE AND
        ((pulse < 40 OR pulse > 200) AND age_months >= 12) IS FALSE AND
        (serum_ph < 7.2 AND (paco2 >= 38 AND paco2 <= 42)) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.proulx_cardiovascular
    , COALESCE(t.proulx_cardiovascular, 0) AS proulx_cardiovascular_min
    , COALESCE(t.proulx_cardiovascular, 1) AS proulx_cardiovascular_max
    , t_b.proulx_cardiovascular_b
    , COALESCE(t_b.proulx_cardiovascular_b, 0) AS proulx_cardiovascular_b_min
    , COALESCE(t_b.proulx_cardiovascular_b, 1) AS proulx_cardiovascular_b_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
  LEFT JOIN t_b
  ON tc.site = t_b.site AND tc.enc_id = t_b.enc_id AND tc.eclock = t_b.eclock
)
;
CALL **REDACTED**.sa.aggregate("proulx_cardiovascular", "proulx_cardiovascular_min");
CALL **REDACTED**.sa.aggregate("proulx_cardiovascular", "proulx_cardiovascular_b_min");
