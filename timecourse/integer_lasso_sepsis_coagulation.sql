#standardSQL

-- Define a novel sepsis criteria that will be used as an outcome in the models.
-- See issue **REDACTED**/issues/90

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_lasso_sepsis_coagulation` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , si.suspected_infection_0dose
      , si.suspected_infection_1dose
      , si.suspected_infection_2doses
      , CASE WHEN plts.platelets IS NULL THEN NULL
             WHEN plts.platelets < 100 THEN 1
             WHEN plts.platelets >= 100 THEN 0
            END AS platelets
      , CASE WHEN inr.inr IS NULL THEN NULL
             WHEN inr.inr > 1.3 THEN 1
             WHEN inr.inr <= 1.3 THEN 0
            END AS inr
      , CASE WHEN d_dimer.d_dimer IS NULL THEN NULL
             WHEN d_dimer.d_dimer > 2 THEN 1
             WHEN d_dimer.d_dimer <= 2 THEN 0
            END AS d_dimer
      , CASE WHEN fib.fibrinogen IS NULL THEN NULL
             WHEN fib.fibrinogen < 100 THEN 1
             WHEN fib.fibrinogen >= 100 THEN 0
            END AS fibrinogen
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.suspected_infection` si
    ON tc.site = si.site AND tc.enc_id = si.enc_id AND tc.eclock = si.eclock
    LEFT JOIN `**REDACTED**.timecourse.platelets` plts
    ON tc.site = plts.site AND tc.enc_id = plts.enc_id AND tc.eclock = plts.eclock
    LEFT JOIN `**REDACTED**.timecourse.inr` inr
    ON tc.site = inr.site AND tc.enc_id = inr.enc_id AND tc.eclock = inr.eclock
    LEFT JOIN `**REDACTED**.timecourse.d_dimer` d_dimer
    ON tc.site = d_dimer.site AND tc.enc_id = d_dimer.enc_id AND tc.eclock = d_dimer.eclock
    LEFT JOIN `**REDACTED**.timecourse.fibrinogen` fib
    ON tc.site = fib.site AND tc.enc_id = fib.enc_id AND tc.eclock = fib.eclock
  )
  ,
  t1 AS
  (
    SELECT
        *
      , CASE WHEN COALESCE(platelets, 0) + COALESCE(inr, 0) + COALESCE(d_dimer, 0) + COALESCE(fibrinogen, 0) >= 2 THEN 2
             ELSE platelets + inr + d_dimer + fibrinogen
             END AS integer_lasso_sepsis_coagulation
      , CASE WHEN COALESCE(platelets, 0) + COALESCE(inr, 0) + COALESCE(d_dimer, 0) + COALESCE(fibrinogen, 0) >= 2 THEN 2
             WHEN COALESCE(platelets, 0) + COALESCE(inr, 0) + COALESCE(d_dimer, 0) + COALESCE(fibrinogen, 0)  = 1 THEN 1
             ELSE 0 END AS integer_lasso_sepsis_coagulation_min
      , CASE WHEN COALESCE(platelets, 0) + COALESCE(inr, 0) + COALESCE(d_dimer, 0) + COALESCE(fibrinogen, 0) >= 2 THEN 2
             ELSE 2 END AS integer_lasso_sepsis_coagulation_max
    FROM t0
  )

  SELECT
      t1.site
    , t1.enc_id
    , t1.eclock

    , platelets AS platelets
    , inr AS inr
    , d_dimer AS d_dimer
    , fibrinogen AS fibrinogen

    , integer_lasso_sepsis_coagulation
    , integer_lasso_sepsis_coagulation_min
    , integer_lasso_sepsis_coagulation_max

    , suspected_infection_0dose * integer_lasso_sepsis_coagulation AS integer_lasso_sepsis_coagulation_0dose
    , suspected_infection_0dose * integer_lasso_sepsis_coagulation_min AS integer_lasso_sepsis_coagulation_0dose_min
    , suspected_infection_0dose * integer_lasso_sepsis_coagulation_max AS integer_lasso_sepsis_coagulation_0dose_max

    , suspected_infection_1dose * integer_lasso_sepsis_coagulation AS integer_lasso_sepsis_coagulation_1dose
    , suspected_infection_1dose * integer_lasso_sepsis_coagulation_min AS integer_lasso_sepsis_coagulation_1dose_min
    , suspected_infection_1dose * integer_lasso_sepsis_coagulation_max AS integer_lasso_sepsis_coagulation_1dose_max

    , suspected_infection_2doses * integer_lasso_sepsis_coagulation AS integer_lasso_sepsis_coagulation_2doses
    , suspected_infection_2doses * integer_lasso_sepsis_coagulation_min AS integer_lasso_sepsis_coagulation_2doses_min
    , suspected_infection_2doses * integer_lasso_sepsis_coagulation_max AS integer_lasso_sepsis_coagulation_2doses_max
  FROM t1
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("integer_lasso_sepsis_coagulation", "integer_lasso_sepsis_coagulation_min");
