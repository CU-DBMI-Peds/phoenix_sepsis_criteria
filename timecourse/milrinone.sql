#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.milrinone` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS milrinone_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS milrinone
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "milrinone" AND med_dose_units = "mcg/kg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS milrinone_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS milrinone
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "milrinone" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    ) ma

    LEFT JOIN (
      SELECT * FROM `**REDACTED**.timecourse.weight`
    ) w

    ON ma.site = w.site AND ma.enc_id = w.enc_id AND ma.med_admin_time = w.weight_time

    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t AS
  (
    SELECT site, enc_id, milrinone_time, MAX(milrinone) AS milrinone
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, milrinone_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS milrinone_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS milrinone_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "milrinone" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.milrinone_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS milrinone_yn_time
      , COALESCE(LAST_VALUE(binary.milrinone_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS milrinone_yn
      ,          LAST_VALUE(t.milrinone_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS milrinone_time
      , COALESCE(LAST_VALUE(t.milrinone           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS milrinone
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.milrinone_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.milrinone_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(milrinone > 0, 1, milrinone_yn) AS milrinone_yn
    , IF(milrinone > 0, milrinone_time, milrinone_yn_time) AS milrinone_yn_time
    , milrinone
    , milrinone_time
  FROM locf
)
;

-- check
SELECT IF (milrinone > 0 and milrinone_yn = 0, ERROR("milrinone_yn = 0 while milrinone > 0"), "PASS")
FROM `**REDACTED**.timecourse.milrinone`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the milrinone value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.milrinone`
SET milrinone = NULL, milrinone_time = NULL
WHERE milrinone_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.milrinone`
SET milrinone_yn = NULL, milrinone_yn_time = NULL
WHERE milrinone_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
