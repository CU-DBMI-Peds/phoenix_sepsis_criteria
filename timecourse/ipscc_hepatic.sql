#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_hepatic` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , bilirubin_tot.bilirubin_tot
      , alt.alt

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.bilirubin_tot` bilirubin_tot
    ON tc.site = bilirubin_tot.site AND tc.enc_id = bilirubin_tot.enc_id AND tc.eclock = bilirubin_tot.eclock

    LEFT JOIN `**REDACTED**.timecourse.alt` alt
    ON tc.site = alt.site AND tc.enc_id = alt.enc_id AND tc.eclock = alt.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_hepatic
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      /*
      note: although IPSCC says age adjusted ALT rate, values don't vary
            much, so just using this one value
      */
      WHERE (bilirubin_tot >= 4 AND age_months >= 1) OR (alt > 102)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (bilirubin_tot >= 4 AND age_months >= 1) IS FALSE AND (alt > 102) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.ipscc_hepatic
    , COALESCE(t.ipscc_hepatic, 0) AS ipscc_hepatic_min
    , COALESCE(t.ipscc_hepatic, 1) AS ipscc_hepatic_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_hepatic", "ipscc_hepatic_min");
