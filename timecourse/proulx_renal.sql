#standardSQL

/*
 * Renal System:
 * (1) Serum urea nitrogen value of 36 mmol!L or more (~100 m!lfdL);
 * (2) serum creatinine concentration of 177 vmol!L or more (~2.0 m!lfdL), in
 *     the absence of preexisting renal disease; and
 * (3) dialysis.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_renal` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , bun.bun
      , creatinine.creatinine
      , crrt.crrt
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.bun` bun
    ON tc.site = bun.site AND tc.enc_id = bun.enc_id AND tc.eclock = bun.eclock

    LEFT JOIN `**REDACTED**.timecourse.creatinine` creatinine
    ON tc.site = creatinine.site AND tc.enc_id = creatinine.enc_id AND tc.eclock = creatinine.eclock

    LEFT JOIN `**REDACTED**.timecourse.crrt` crrt
    ON tc.site = crrt.site AND tc.enc_id = crrt.enc_id AND tc.eclock = crrt.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_renal
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (bun > 100 OR creatinine >= 2.0 OR crrt > 0)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (bun > 100 OR creatinine >= 2.0 OR crrt > 0) IS FALSE
    )_
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.proulx_renal
    , COALESCE(t.proulx_renal, 0) AS proulx_renal_min
    , COALESCE(t.proulx_renal, 1) AS proulx_renal_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("proulx_renal", "proulx_renal_min");
