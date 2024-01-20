#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.oi` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , fio2.fio2
      , fio2.fio2_time
      , pao2.pao2
      , pao2.pao2_time
      , vent.vent_map
      , vent.vent_map_time
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.fio2` fio2
    ON tc.site = fio2.site AND tc.enc_id = fio2.enc_id AND tc.eclock = fio2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pao2` pao2
    ON tc.site = pao2.site AND tc.enc_id = pao2.enc_id AND tc.eclock = pao2.eclock

    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , vent_map * fio2 * 100 / NULLIF(pao2, 0)       AS oi
    , (vent_map_time + fio2_time + pao2_time) / 3.0 AS oi_time
  FROM t0
)
;
