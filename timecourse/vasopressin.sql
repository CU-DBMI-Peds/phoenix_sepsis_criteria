#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.vasopressin` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS vasopressin_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS vasopressin
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "vasopressin" AND med_dose_units = "units/kg/min" AND med_admin_time IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS vasopressin_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS vasopressin
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "vasopressin" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
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
    SELECT site, enc_id, vasopressin_time, MAX(vasopressin) AS vasopressin
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, vasopressin_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS vasopressin_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS vasopressin_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "vasopressin" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.vasopressin_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS vasopressin_yn_time
      , COALESCE(LAST_VALUE(binary.vasopressin_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS vasopressin_yn
      ,          LAST_VALUE(t.vasopressin_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS vasopressin_time
      , COALESCE(LAST_VALUE(t.vasopressin           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS vasopressin
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.vasopressin_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.vasopressin_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(vasopressin > 0, 1, vasopressin_yn) AS vasopressin_yn
    , IF(vasopressin > 0, vasopressin_time, vasopressin_yn_time) AS vasopressin_yn_time
    , vasopressin
    , vasopressin_time
  FROM locf
)
;

-- check
SELECT IF (vasopressin > 0 and vasopressin_yn = 0, ERROR("vasopressin_yn = 0 while vasopressin > 0"), "PASS")
FROM `**REDACTED**.timecourse.vasopressin`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the vasopressin value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.vasopressin`
SET vasopressin = NULL, vasopressin_time = NULL
WHERE vasopressin_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.vasopressin`
SET vasopressin_yn = NULL, vasopressin_yn_time = NULL
WHERE vasopressin_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
