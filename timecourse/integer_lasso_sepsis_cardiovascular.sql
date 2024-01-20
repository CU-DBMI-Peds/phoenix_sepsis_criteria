#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_lasso_sepsis_cardiovascular` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , dob.dobutamine_yn
      , dop.dopamine_yn
      , epi.epinephrine_yn
      , mil.milrinone_yn
      , norepi.norepinephrine_yn
      , vas.vasopressin_yn
      , lac.lactate
      , bp.map
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dob
    ON tc.site = dob.site AND tc.enc_id = dob.enc_id AND tc.eclock = dob.eclock
    LEFT JOIN `**REDACTED**.timecourse.dopamine` dop
    ON tc.site = dop.site AND tc.enc_id = dop.enc_id AND tc.eclock = dop.eclock
    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epi
    ON tc.site = epi.site AND tc.enc_id = epi.enc_id AND tc.eclock = epi.eclock
    LEFT JOIN `**REDACTED**.timecourse.milrinone` mil
    ON tc.site = mil.site AND tc.enc_id = mil.enc_id AND tc.eclock = mil.eclock
    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepi
    ON tc.site = norepi.site AND tc.enc_id = norepi.enc_id AND tc.eclock = norepi.eclock
    LEFT JOIN `**REDACTED**.timecourse.vasopressin` vas
    ON tc.site = vas.site AND tc.enc_id = vas.enc_id AND tc.eclock = vas.eclock
    LEFT JOIN `**REDACTED**.timecourse.lactate` lac
    ON tc.site = lac.site AND tc.enc_id = lac.enc_id AND tc.eclock = lac.eclock
    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock
  )
  ,
  inotropes AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , CASE WHEN COALESCE(dobutamine_yn, 0) + COALESCE(dopamine_yn, 0) + COALESCE(epinephrine_yn, 0) + COALESCE(milrinone_yn, 0) + COALESCE(norepinephrine_yn, 0) + COALESCE(vasopressin_yn, 0) >= 2 THEN 2
             WHEN COALESCE(dobutamine_yn, 0) + COALESCE(dopamine_yn, 0) + COALESCE(epinephrine_yn, 0) + COALESCE(milrinone_yn, 0) + COALESCE(norepinephrine_yn, 0) + COALESCE(vasopressin_yn, 0)  = 1 THEN 1
             WHEN dobutamine_yn IS NULL OR dopamine_yn IS NULL OR epinephrine_yn IS NULL OR milrinone_yn IS NULL OR norepinephrine_yn IS NULL OR vasopressin_yn IS NULL THEN NULL
            ELSE 0 END AS inotropes
    FROM t0
  )
  ,
  lactate AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , CASE WHEN lactate >= 11 THEN 2
             WHEN lactate >= 5  THEN 1
             WHEN lactate IS NULL THEN NULL
            ELSE 0 END AS lactate
    FROM t0
  )
  ,
  map AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , CASE WHEN age_months IS NULL             THEN NULL
             WHEN map        IS NULL             THEN NULL

             WHEN                       age_months <    1 AND map < 17 THEN 2
             WHEN age_months >=   1 AND age_months <   12 AND map < 25 THEN 2
             WHEN age_months >=  12 AND age_months <   24 AND map < 31 THEN 2
             WHEN age_months >=  24 AND age_months <   60 AND map < 32 THEN 2
             WHEN age_months >=  60 AND age_months <  144 AND map < 36 THEN 2
             WHEN age_months >= 144                       AND map < 38 THEN 2

             WHEN                       age_months <    1 AND map < 31 THEN 1
             WHEN age_months >=   1 AND age_months <   12 AND map < 39 THEN 1
             WHEN age_months >=  12 AND age_months <   24 AND map < 44 THEN 1
             WHEN age_months >=  24 AND age_months <   60 AND map < 45 THEN 1
             WHEN age_months >=  60 AND age_months <  144 AND map < 49 THEN 1
             WHEN age_months >= 144 AND                       map < 52 THEN 1
            ELSE 0 END AS map
    FROM t0
  )
  ,
  t1 AS
  (
    SELECT
        t0.site
      , t0.enc_id
      , t0.eclock
      , t0.suspected_infection_0dose
      , t0.suspected_infection_1dose
      , t0.suspected_infection_2doses
      , inotropes.inotropes
      , lactate.lactate
      , map.map
    FROM t0
    LEFT JOIN inotropes ON t0.site = inotropes.site AND t0.enc_id = inotropes.enc_id AND t0.eclock = inotropes.eclock
    LEFT JOIN lactate   ON t0.site = lactate.site   AND t0.enc_id = lactate.enc_id   AND t0.eclock = lactate.eclock
    LEFT JOIN map       ON t0.site = map.site       AND t0.enc_id = map.enc_id       AND t0.eclock = map.eclock
  )

  SELECT
      t1.site
    , t1.enc_id
    , t1.eclock

    , t1.inotropes AS ilsc_inotropes
    , t1.lactate AS ilsc_lactate
    , t1.map AS ilsc_map

    , t1.inotropes + t1.lactate + t1.map AS integer_lasso_sepsis_cardiovascular
    , COALESCE(t1.inotropes, 0) + COALESCE(t1.lactate, 0) + COALESCE(t1.map, 0) AS integer_lasso_sepsis_cardiovascular_min
    , COALESCE(t1.inotropes, 2) + COALESCE(t1.lactate, 2) + COALESCE(t1.map, 2) AS integer_lasso_sepsis_cardiovascular_max

    , suspected_infection_0dose * t1.inotropes + suspected_infection_0dose * t1.lactate + suspected_infection_0dose * t1.map AS integer_lasso_sepsis_cardiovascular_0dose
    , COALESCE(suspected_infection_0dose * t1.inotropes, 0) + COALESCE(suspected_infection_0dose * t1.lactate, 0) + COALESCE(suspected_infection_0dose * t1.map, 0) AS integer_lasso_sepsis_cardiovascular_0dose_min
    , COALESCE(suspected_infection_0dose * t1.inotropes, 2) + COALESCE(suspected_infection_0dose * t1.lactate, 2) + COALESCE(suspected_infection_0dose * t1.map, 2) AS integer_lasso_sepsis_cardiovascular_0dose_max

    , suspected_infection_1dose * t1.inotropes + suspected_infection_1dose * t1.lactate + suspected_infection_1dose * t1.map AS integer_lasso_sepsis_cardiovascular_1dose
    , COALESCE(suspected_infection_1dose * t1.inotropes, 0) + COALESCE(suspected_infection_1dose * t1.lactate, 0) + COALESCE(suspected_infection_1dose * t1.map, 0) AS integer_lasso_sepsis_cardiovascular_1dose_min
    , COALESCE(suspected_infection_1dose * t1.inotropes, 2) + COALESCE(suspected_infection_1dose * t1.lactate, 2) + COALESCE(suspected_infection_1dose * t1.map, 2) AS integer_lasso_sepsis_cardiovascular_1dose_max

    , suspected_infection_2doses * t1.inotropes + suspected_infection_2doses * t1.lactate + suspected_infection_2doses * t1.map AS integer_lasso_sepsis_cardiovascular_2doses
    , COALESCE(suspected_infection_2doses * t1.inotropes, 0) + COALESCE(suspected_infection_2doses * t1.lactate, 0) + COALESCE(suspected_infection_2doses * t1.map, 0) AS integer_lasso_sepsis_cardiovascular_2doses_min
    , COALESCE(suspected_infection_2doses * t1.inotropes, 2) + COALESCE(suspected_infection_2doses * t1.lactate, 2) + COALESCE(suspected_infection_2doses * t1.map, 2) AS integer_lasso_sepsis_cardiovascular_2doses_max

  FROM t1
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_cardiovascular", "integer_lasso_sepsis_cardiovascular_min");
