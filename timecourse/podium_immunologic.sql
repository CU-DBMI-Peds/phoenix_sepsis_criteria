#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_immunologic` AS
(
  WITH t0 AS
  (
    SELECT a.enc_id, a.eclock, b.anc, c.alc
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.anc` b
    ON a.enc_id = b.enc_id AND a.eclock = b.eclock
    LEFT JOIN `**REDACTED**.timecourse.alc` c
    ON a.enc_id = c.enc_id AND a.eclock = c.eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    CASE
      WHEN anc < 0.5 THEN 1
      WHEN alc < 1.0 THEN 1
      WHEN (anc < 0.5) IS FALSE AND (alc < 1.0) IS FALSE THEN 0
      ELSE NULL END AS podium_immunologic,
    CAST(NULL AS INT64) AS podium_immunologic_min,
    CAST(NULL AS INT64) AS podium_immunologic_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t0
  ON tc.enc_id = t0.enc_id AND tc.eclock = t0.eclock

)
;

UPDATE `**REDACTED**.timecourse.podium_immunologic`
SET podium_immunologic_min = COALESCE(podium_immunologic, 0),
    podium_immunologic_max = COALESCE(podium_immunologic, 1)
WHERE TRUE
;
CALL **REDACTED**.sa.aggregate("podium_immunologic", "podium_immunologic_min");
