#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_neurological` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , gcs.gcs_total
      , pupil.pupil
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.gcs` gcs
    ON tc.site = gcs.site AND tc.enc_id = gcs.enc_id AND tc.eclock = gcs.eclock
    LEFT JOIN `**REDACTED**.timecourse.pupil` pupil
    ON tc.site = pupil.site AND tc.enc_id = pupil.enc_id AND tc.eclock = pupil.eclock
  )
  ,
  t1 AS
  (
    SELECT site, enc_id, eclock,
      MAX(v1) AS pelod2_neuro_gcs,
      MAX(v2) AS pelod2_neuro_pup
    FROM
    (
      SELECT site, enc_id, eclock, 4 as v1, NULL v2
      FROM t0 WHERE gcs_total < 5
      UNION ALL
      SELECT site, enc_id, eclock, 1 as v1, NULL v2
      FROM t0 WHERE gcs_total < 11
      UNION ALL
      SELECT site, enc_id, eclock, 0 as v1, NULL v2
      FROM t0 WHERE gcs_total >= 11
      UNION ALL
      SELECT site, enc_id, eclock, NULL as v1, 5 v2
      FROM t0 WHERE pupil = "both-fixed"
      UNION ALL
      SELECT site, enc_id, eclock, NULL as v1, 0 v2
      FROM t0 WHERE (pupil = "both-fixed") IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t1.pelod2_neuro_gcs + t1.pelod2_neuro_pup AS pelod2_neurological
    , COALESCE(t1.pelod2_neuro_gcs, 0) + COALESCE(t1.pelod2_neuro_pup, 0) AS pelod2_neurological_min
    , COALESCE(t1.pelod2_neuro_gcs, 4) + COALESCE(t1.pelod2_neuro_pup, 5) AS pelod2_neurological_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t1
  ON tc.site = t1.site AND tc.enc_id = t1.enc_id AND tc.eclock = t1.eclock
)
;
CALL **REDACTED**.sa.aggregate("pelod2_neurological", "pelod2_neurological_min");
