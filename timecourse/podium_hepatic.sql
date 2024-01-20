#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_hepatic` AS
(
  WITH t0 AS
  (
    SELECT a.site, a.enc_id, a.eclock, b.ast, c.alt, d.ggt, e.bilirubin_tot, f.gcs_total, g.inr,
      h.bilirubin_dir
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.ast` b
    ON a.enc_id = b.enc_id ANd a.eclock = b.eclock
    LEFT JOIN `**REDACTED**.timecourse.alt` c
    ON a.enc_id = c.enc_id AND a.eclock = c.eclock
    LEFT JOIN `**REDACTED**.timecourse.ggt` d
    ON a.enc_id = d.enc_id AND a.eclock = d.eclock
    LEFT JOIN `**REDACTED**.timecourse.bilirubin_tot` e
    ON a.enc_id = e.enc_id AND a.eclock = e.eclock
    LEFT JOIN `**REDACTED**.timecourse.gcs` f
    ON a.enc_id = f.enc_id AND a.eclock = f.eclock
    LEFT JOIN `**REDACTED**.timecourse.inr` g
    ON a.enc_id = g.enc_id AND a.eclock = g.eclock
    LEFT JOIN `**REDACTED**.timecourse.bilirubin_dir` h
    ON a.enc_id = h.enc_id AND a.eclock = h.eclock
  )
  , t1 AS
  (
    SELECT site, enc_id, eclock, gcs_total, inr,
      CASE
        WHEN ast > 100 THEN 1
        WHEN alt > 100 THEN 1
        WHEN ggt > 100 THEN 1
        WHEN bilirubin_tot > 5 THEN 1
        WHEN bilirubin_dir > 2 THEN 1
        WHEN (ast > 100) IS FALSE AND
             (alt > 100) IS FALSE AND
             (ggt > 100) IS FALSE AND
             (bilirubin_tot > 5) IS FALSE AND
             (bilirubin_dir > 2) IS FALSE THEN 0
      ELSE NULL END as podium_hep_lft
    FROM t0
  )
  , t2 AS
  (
    SELECT site, enc_id, eclock, podium_hep_lft,
      CASE
        WHEN podium_hep_lft = 1 AND gcs_total <= 8 AND inr >= 1.5 AND inr < 2 THEN 1
        WHEN (podium_hep_lft = 1 AND gcs_total <= 8 AND inr >= 1.5 AND inr < 2) IS FALSE THEN 0
        ELSE NULL END AS podium_hep_low,
      CASE
        WHEN podium_hep_lft = 1  AND gcs_total <= 8 AND inr > 2           THEN 1
        WHEN (podium_hep_lft = 1 AND gcs_total <= 8 AND inr > 2) IS FALSE THEN 0
        ELSE NULL END AS podium_hep_hi
    FROM t1
  )

  SELECT site, enc_id, eclock, podium_hep_lft, podium_hep_hi, podium_hep_low,
    CASE
      WHEN podium_hep_lft = 1 THEN 1
      WHEN podium_hep_low = 1 THEN 1
      WHEN podium_hep_hi  = 1 THEN 1
      WHEN (podium_hep_lft = 1) IS FALSE AND
           (podium_hep_low = 1) IS FALSE AND
           (podium_hep_hi  = 1) IS FALSE THEN 0
      ELSE NULL END as podium_hepatic,
    CAST(NULL AS INT64) AS podium_hepatic_min,
    CAST(NULL AS INT64) AS podium_hepatic_max
    FROM t2
)
;

UPDATE `**REDACTED**.timecourse.podium_hepatic`
SET podium_hepatic_min = COALESCE(podium_hepatic, 0),
    podium_hepatic_max = COALESCE(podium_hepatic, 1)
WHERE TRUE
;
CALL **REDACTED**.sa.aggregate("podium_hepatic", "podium_hepatic_min");
