#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.norepinephrine` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS norepinephrine_time
      , MAX(SAFE_CAST(med_dose AS FLOAT64)) AS norepinephrine
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "norepinephrine" AND med_dose_units = "mcg/kg/min" AND med_admin_time IS NOT NULL AND systemic = 1
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  t1 AS
  (
    SELECT
        ma.site
      , ma.enc_id
      , ma.med_admin_time AS norepinephrine_time
      , MAX(SAFE_CAST(ma.med_dose AS FLOAT64) / w.weight) AS norepinephrine
    FROM (
      SELECT * FROM `**REDACTED**.harmonized.medication_admin`
      WHERE med_generic_name = "norepinephrine" AND med_dose_units = "mcg/min" AND med_admin_time IS NOT NULL AND systemic = 1
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
    SELECT site, enc_id, norepinephrine_time, MAX(norepinephrine) AS norepinephrine
    FROM (SELECT * FROM t0 UNION ALL SELECT * FROM t1)
    GROUP BY site, enc_id, norepinephrine_time
  )
  ,
  binary AS
  (
    SELECT
        site
      , enc_id
      , med_admin_time AS norepinephrine_time
      , IF(MAX(SAFE_CAST(med_dose AS FLOAT64)) > 0, 1, 0) AS norepinephrine_yn
    FROM `**REDACTED**.harmonized.medication_admin`
    WHERE med_generic_name = "norepinephrine" AND systemic = 1 AND med_admin_time IS NOT NULL AND med_dose IS NOT NULL
    GROUP BY site, enc_id, med_admin_time
  )
  ,
  locf AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      ,          LAST_VALUE(binary.norepinephrine_time IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS norepinephrine_yn_time
      , COALESCE(LAST_VALUE(binary.norepinephrine_yn   IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS norepinephrine_yn
      ,          LAST_VALUE(t.norepinephrine_time      IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS norepinephrine_time
      , COALESCE(LAST_VALUE(t.norepinephrine           IGNORE NULLS) OVER (PARTITION BY tc.site, tc.enc_id ORDER BY tc.eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS norepinephrine
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN binary
    ON tc.site = binary.site AND tc.enc_id = binary.enc_id AND tc.eclock = binary.norepinephrine_time
    LEFT JOIN t
    ON tc.site = t.site AND tc.enc_id = t.enc_id AND tc.eclock = t.norepinephrine_time
  )

  SELECT
      site
    , enc_id
    , eclock
    , IF(norepinephrine > 0, 1, norepinephrine_yn) AS norepinephrine_yn
    , IF(norepinephrine > 0, norepinephrine_time, norepinephrine_yn_time) AS norepinephrine_yn_time
    , norepinephrine
    , norepinephrine_time
  FROM locf
)
;

-- check
SELECT IF (norepinephrine > 0 and norepinephrine_yn = 0, ERROR("norepinephrine_yn = 0 while norepinephrine > 0"), "PASS")
FROM `**REDACTED**.timecourse.norepinephrine`
LIMIT 1
;

-- -------------------------------------------------------------------------- --
-- Set the norepinephrine value to NULL if the value is more than 12 hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.norepinephrine`
SET norepinephrine = NULL, norepinephrine_time = NULL
WHERE norepinephrine_time - eclock > 60 * 12
;

UPDATE `**REDACTED**.timecourse.norepinephrine`
SET norepinephrine_yn = NULL, norepinephrine_yn_time = NULL
WHERE norepinephrine_yn_time - eclock > 60 * 12
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
