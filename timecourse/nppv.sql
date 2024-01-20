#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.nppv` AS
(
  WITH t0 AS (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , epap_niv.epap_niv
      , epap_niv.epap_niv_time
      , o2_flow.o2_flow
      , o2_flow.o2_flow_time
      , wt.weight
      , wt.weight_time
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.o2_flow` o2_flow
    ON tc.site = o2_flow.site AND tc.enc_id = o2_flow.enc_id AND tc.eclock = o2_flow.eclock
    LEFT JOIN `**REDACTED**.timecourse.epap_niv` epap_niv
    ON tc.site = epap_niv.site AND tc.enc_id = epap_niv.enc_id AND tc.eclock = epap_niv.eclock
    LEFT JOIN `**REDACTED**.timecourse.weight` wt
    ON tc.site = wt.site AND tc.enc_id = wt.enc_id AND tc.eclock = wt.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) AS nppv, AVG(time) AS nppv_time
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value, epap_niv_time AS time
      FROM t0
      WHERE (epap_niv > 0)

      UNION ALL

      SELECT site, enc_id, eclock, 1 AS value, (o2_flow_time +  weight_time) / 2.0 AS time
      FROM t0
      WHERE (o2_flow > 30 AND (o2_flow / weight) > 1.5)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value, (epap_niv_time + ((o2_flow_time +  weight_time) / 2.0)) / 2.0 AS time
      FROM t0
      WHERE (epap_niv > 0) IS FALSE AND
            (o2_flow > 30 AND (o2_flow / weight) > 1.5) IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.nppv
    , t.nppv_time
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("nppv", "nppv");
