#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.dobutamine` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS dobutamine_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS dobutamine
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "dobutamine" AND med_dose_units = "mcg/kg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS dobutamine_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS dobutamine
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "dobutamine" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
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
    SELECT site, enc_id, dobutamine_time, MAX(dobutamine) AS dobutamine
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, dobutamine_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS dobutamine_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS dobutamine_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "dobutamine" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.dobutamine_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS dobutamine_yn_time
      , COALESCE(LAST_VALUE(binary.dobutamine_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS dobutamine_yn
      ,          LAST_VALUE(t.dobutamine_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS dobutamine_time
      , COALESCE(LAST_VALUE(t.dobutamine           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS dobutamine
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.dobutamine_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.dobutamine_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(dobutamine > 0, 1, dobutamine_yn) AS dobutamine_yn
    , IF(dobutamine > 0, dobutamine_time, dobutamine_yn_time) AS dobutamine_yn_time
    , dobutamine
    , dobutamine_time
  FROM locf
)
;

-- check
SELECT IF (dobutamine > 0 and dobutamine_yn = 0, ERROR("dobutamine_yn = 0 while dobutamine > 0"), "PASS")
FROM `**REDACTED**.timecourse.dobutamine`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the dobutamine value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.dobutamine`
SET dobutamine = NULL, dobutamine_time = NULL
WHERE dobutamine_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.dobutamine`
SET dobutamine_yn = NULL, dobutamine_yn_time = NULL
WHERE dobutamine_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
