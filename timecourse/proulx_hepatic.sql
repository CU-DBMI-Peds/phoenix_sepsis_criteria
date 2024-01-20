#standardSQL

/*
 * Hepatic System
 * (1) Total bilirubin level more than 60 mmol!L (>3 m!lfdL), excluding icterus
 *     due to breast feeding.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_hepatic` AS
(
  WITH t AS
  (
    SELECT enc_id, eclock, MAX(value) as proulx_hepatic
    FROM
    (
      SELECT enc_id, eclock, 1 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot > 3
      UNION ALL
      SELECT enc_id, eclock, 0 AS value
      FROM `**REDACTED**.timecourse.bilirubin_tot`
      WHERE bilirubin_tot <= 3
    )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.proulx_hepatic,
    COALESCE(t.proulx_hepatic, 0) AS proulx_hepatic_min,
    COALESCE(t.proulx_hepatic, 1) AS proulx_hepatic_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("proulx_hepatic", "proulx_hepatic_min");
