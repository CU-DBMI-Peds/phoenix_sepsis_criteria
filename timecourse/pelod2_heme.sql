#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.pelod2_heme` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , IF(wbc.wbc <= 2, 2, 0) + IF(plts.platelets <= 76, 2, IF(plts.platelets < 142, 1, 0)) AS pelod2_heme
    , COALESCE(IF(wbc.wbc <= 2, 2, 0), 0) + COALESCE(IF(plts.platelets <= 76, 2, IF(plts.platelets < 142, 1, 0)), 0) AS pelod2_heme_min
    , COALESCE(IF(wbc.wbc <= 2, 2, 0), 4) + COALESCE(IF(plts.platelets <= 76, 2, IF(plts.platelets < 142, 1, 0)), 4) AS pelod2_heme_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN `**REDACTED**.timecourse.wbc` wbc
  ON tc.site = wbc.site AND tc.enc_id = wbc.enc_id AND tc.eclock = wbc.eclock
  LEFT JOIN `**REDACTED**.timecourse.platelets` plts
  ON tc.site = plts.site AND tc.enc_id = plts.enc_id AND tc.eclock = plts.eclock
  /* test cases
  WHERE wbc IS NULL AND platelets IS NULL  -- both null results in 0 score
  WHERE wbc IS NOT NULL AND platelets IS NULL
  WHERE wbc IS NULL AND platelets IS NOT NULL
  WHERE wbc > 2 AND platelets > 142 -- healthy
  WHERE wbc < 2 AND platelets > 142 -- 2
  WHERE wbc > 2 AND platelets < 142 AND platelets > 76-- 1
  WHERE wbc > 2 AND platelets = 130 -- 1
  WHERE wbc < 2 AND platelets IS NULL -- 2
  WHERE wbc IS NULL AND platelets > 142 -- 0
  WHERE wbc IS NULL AND platelets < 76 -- 2
  WHERE wbc IS NULL AND platelets = 130 -- 1
  WHERE wbc < 2 AND platelets < 76 -- 4
  */
)
;
CALL **REDACTED**.sa.aggregate("pelod2_heme", "pelod2_heme_min");
