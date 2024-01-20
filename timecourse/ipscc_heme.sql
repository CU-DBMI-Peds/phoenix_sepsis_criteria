#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.ipscc_heme` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.pccc_malignancy
      , plts.platelets
      , inr.inr
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.platelets` plts
    ON tc.site = plts.site AND tc.enc_id = plts.enc_id AND tc.eclock = plts.eclock

    LEFT JOIN `**REDACTED**.timecourse.inr` inr
    ON tc.site = inr.site AND tc.enc_id = inr.enc_id AND tc.eclock = inr.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as ipscc_heme
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE (platelets < 80) OR
            (inr > 2)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (platelets < 80) IS FALSE AND
            (inr > 2) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.ipscc_heme
    , COALESCE(t.ipscc_heme, 0) AS ipscc_heme_min
    , COALESCE(t.ipscc_heme, 1) AS ipscc_heme_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("ipscc_heme", "ipscc_heme_min");
