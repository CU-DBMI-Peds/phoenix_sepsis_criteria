#standardSQL

/*
 * Neurologic System:
 * (1) Glasgow Coma Score less than 5; and
 * (2) fixed dilated pupils.
*/

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.proulx_neurological` AS
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
    LEFT JOIn `**REDACTED**.timecourse.pupil` pupil
    ON tc.site = pupil.site AND tc.enc_id = pupil.enc_id AND tc.eclock = pupil.eclock
  )
  ,
  t AS
  (
    SELECT site, enc_id, eclock, MAX(value) as proulx_neurological
    FROM
    (
      SELECT site, enc_id, eclock, 1 AS value
      FROM t0
      WHERE gcs_total < 5 OR pupil = "both-fixed"

      UNION ALL

      SELECT site, enc_id, eclock, 0 AS value
      FROM t0
      WHERE (gcs_total < 5 OR pupil = "both-fixed") IS FALSE
    )
    GROUP BY site, enc_id, eclock
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.proulx_neurological
    , COALESCE(t.proulx_neurological, 0) AS proulx_neurological_min
    , COALESCE(t.proulx_neurological, 1) AS proulx_neurological_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("proulx_neurological", "proulx_neurological_min");
