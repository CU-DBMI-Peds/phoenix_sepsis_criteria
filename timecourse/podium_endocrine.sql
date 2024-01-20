#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_endocrine` AS
(
  WITH t0 AS
  (
    SELECT a.site, a.enc_id, a.eclock, g.glucose, t.thyroxine
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.glucose` g
    ON a.enc_id = g.enc_id AND a.eclock = g.eclock
    LEFT JOIN `**REDACTED**.timecourse.thyroxine` t
    ON a.enc_id = t.enc_id AND a.eclock = t.eclock
  )

  SELECT site, enc_id, eclock,
    CASE
      WHEN glucose >= 150 THEN 1
      WHEN glucose <   50 THEN 1
      WHEN (glucose >= 150) IS FALSE AND (glucose < 50) IS FALSE THEN 0
      ELSE NULL END AS podium_endocrine_wo_thyroxine,
    CASE
      WHEN glucose >= 150 OR thyroxine < 4.2 THEN 1
      WHEN glucose <   50 OR thyroxine < 4.2 THEN 1
      WHEN
        (glucose >= 150) IS FALSE
        AND (glucose < 50) IS FALSE
        AND (thyroxine < 4.2 ) IS FALSE
        THEN 0
      ELSE NULL END AS podium_endocrine_w_thyroxine,
    CAST(NULL AS INT64) AS podium_endocrine_wo_thyroxine_min,
    CAST(NULL AS INT64) AS podium_endocrine_wo_thyroxine_max,
    CAST(NULL AS INT64) AS podium_endocrine_w_thyroxine_min,
    CAST(NULL AS INT64) AS podium_endocrine_w_thyroxine_max
  FROM t0
)
;

UPDATE `**REDACTED**.timecourse.podium_endocrine`
SET podium_endocrine_wo_thyroxine_min = COALESCE(podium_endocrine_wo_thyroxine, 0),
    podium_endocrine_wo_thyroxine_max = COALESCE(podium_endocrine_wo_thyroxine, 1),
    podium_endocrine_w_thyroxine_min = COALESCE(podium_endocrine_w_thyroxine, 0),
    podium_endocrine_w_thyroxine_max = COALESCE(podium_endocrine_w_thyroxine, 1)
WHERE TRUE
;
CALL **REDACTED**.sa.aggregate("podium_endocrine", "podium_endocrine_wo_thyroxine_min");
CALL **REDACTED**.sa.aggregate("podium_endocrine", "podium_endocrine_w_thyroxine_min");
