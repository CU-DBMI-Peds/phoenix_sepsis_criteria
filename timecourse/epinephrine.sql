#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.epinephrine` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS epinephrine_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS epinephrine
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "epinephrine" AND med_dose_units = "mcg/kg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS epinephrine_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS epinephrine
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "epinephrine" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
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
    SELECT site, enc_id, epinephrine_time, MAX(epinephrine) AS epinephrine
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, epinephrine_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS epinephrine_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS epinephrine_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "epinephrine" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.epinephrine_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS epinephrine_yn_time
      , COALESCE(LAST_VALUE(binary.epinephrine_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS epinephrine_yn
      ,          LAST_VALUE(t.epinephrine_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS epinephrine_time
      , COALESCE(LAST_VALUE(t.epinephrine           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS epinephrine
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.epinephrine_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.epinephrine_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(epinephrine > 0, 1, epinephrine_yn) AS epinephrine_yn
    , IF(epinephrine > 0, epinephrine_time, epinephrine_yn_time) AS epinephrine_yn_time
    , epinephrine
    , epinephrine_time
  FROM locf
)
;

-- check
SELECT IF (epinephrine > 0 and epinephrine_yn = 0, ERROR("epinephrine_yn = 0 while epinephrine > 0"), "PASS")
FROM `**REDACTED**.timecourse.epinephrine`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the epinephrine value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.epinephrine`
SET epinephrine = NULL, epinephrine_time = NULL
WHERE epinephrine_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.epinephrine`
SET epinephrine_yn = NULL, epinephrine_yn_time = NULL
WHERE epinephrine_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
