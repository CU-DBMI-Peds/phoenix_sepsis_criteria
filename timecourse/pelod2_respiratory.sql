#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_respiratory` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , paco2.paco2
      , pfr.pf_ratio
      , vent.vent
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.paco2` paco2
    ON tc.site = paco2.site AND tc.enc_id = paco2.enc_id AND tc.eclock = paco2.eclock
    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
    LEFT JOIN `**REDACTED**.timecourse.pf_ratio` pfr
    ON tc.site = pfr.site AND tc.enc_id = pfr.enc_id AND tc.eclock = pfr.eclock
  )
  , t AS
  (
    SELECT site, enc_id, eclock,
      MAX(v1) as pelod2_resp_paco2,
      MAX(v2) as pelod2_resp_vent,
      MAX(v3) as pelod2_resp_pf
    FROM
    (
      SELECT site, enc_id, eclock, 3 as v1, NULL AS v2, NULL AS v3
      FROM t0 WHERE (paco2 >= 95)

      UNION ALL

      SELECT site, enc_id, eclock, 1 as v1, NULL AS v2, NULL AS v3
      FROM t0 WHERE (paco2 >= 59)

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS v1, NULL AS v2, NULL AS v3
      FROM t0 WHERE paco2 IS NOT NULL

      UNION ALL

      SELECT site, enc_id, eclock, NULL As v1, 3 AS v2, NULL AS v3
      FROM t0 WHERE vent = 1

      UNION ALL

      SELECT site, enc_id, eclock, NULL As v1, 0 AS v2, NULL AS v3
      FROM t0 WHERE vent = 0

      UNION ALL

      SELECT site, enc_id, eclock, NULL As v1, NULL AS v2, 2 AS v3
      FROM t0 WHERE pf_ratio <= 60

      UNION ALL

      SELECT site, enc_id, eclock, NULL AS v1, NULL AS v2, 0 AS v3
      FROM t0 WHERE pf_ratio > 60
    )
    GROUP BY site, enc_id, eclock
  )
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.pelod2_resp_pf + pelod2_resp_vent + pelod2_resp_pf As pelod2_respiratory
    , COALESCE(t.pelod2_resp_pf, 0) + COALESCE(pelod2_resp_vent, 0) + COALESCE(pelod2_resp_pf, 0) As pelod2_respiratory_min
    , COALESCE(t.pelod2_resp_pf, 3) + COALESCE(pelod2_resp_vent, 3) + COALESCE(pelod2_resp_pf, 2) As pelod2_respiratory_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("pelod2_respiratory", "pelod2_respiratory_min");
