#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.dopamine` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS dopamine_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS dopamine
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "dopamine" AND med_dose_units = "mcg/kg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS dopamine_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS dopamine
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "dopamine" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
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
    SELECT site, enc_id, dopamine_time, MAX(dopamine) AS dopamine
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, dopamine_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS dopamine_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS dopamine_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "dopamine" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.dopamine_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS dopamine_yn_time
      , COALESCE(LAST_VALUE(binary.dopamine_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS dopamine_yn
      ,          LAST_VALUE(t.dopamine_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS dopamine_time
      , COALESCE(LAST_VALUE(t.dopamine           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS dopamine
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.dopamine_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.dopamine_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(dopamine > 0, 1, dopamine_yn) AS dopamine_yn
    , IF(dopamine > 0, dopamine_time, dopamine_yn_time) AS dopamine_yn_time
    , dopamine
    , dopamine_time
  FROM locf
)
;

-- check
SELECT IF (dopamine > 0 and dopamine_yn = 0, ERROR("dopamine_yn = 0 while dopamine > 0"), "PASS")
FROM `**REDACTED**.timecourse.dopamine`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the dopamine value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.dopamine`
SET dopamine = NULL, dopamine_time = NULL
WHERE dopamine_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.dopamine`
SET dopamine_yn = NULL, dopamine_yn_time = NULL
WHERE dopamine_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
