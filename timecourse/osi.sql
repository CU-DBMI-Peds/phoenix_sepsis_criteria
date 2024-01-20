#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.osi` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , fio2.fio2
      , fio2.fio2_time
      , spo2.spo2
      , spo2.spo2_time
      , spo2.ok_for_podium
      , vent.vent_map
      , vent.vent_map_time
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.fio2` fio2
    ON tc.site = fio2.site AND tc.enc_id = fio2.enc_id AND tc.eclock = fio2.eclock

    LEFT JOIN `**REDACTED**.timecourse.spo2` spo2
    ON tc.site = spo2.site AND tc.enc_id = spo2.enc_id AND tc.eclock = spo2.eclock

    LEFT JOIN `**REDACTED**.timecourse.vent` vent
    ON tc.site = vent.site AND tc.enc_id = vent.enc_id AND tc.eclock = vent.eclock
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF (ok_for_podium = 1, vent_map * fio2 * 100 / NULLIF(spo2, 0),       NULL) AS osi
    , IF (ok_for_podium = 1, (vent_map_time + fio2_time + spo2_time) / 3.0, NULL) AS osi_time
    FROM t0
)
;
