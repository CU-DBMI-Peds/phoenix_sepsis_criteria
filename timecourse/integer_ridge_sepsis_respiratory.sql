#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_respiratory` AS
(
  SELECT
      site
    , enc_id
    , eclock
    , integer_lasso_sepsis_respiratory AS integer_ridge_sepsis_respiratory
    , integer_lasso_sepsis_respiratory_min AS integer_ridge_sepsis_respiratory_min
    , integer_lasso_sepsis_respiratory_max AS integer_ridge_sepsis_respiratory_max

    , integer_lasso_sepsis_respiratory_0dose AS integer_ridge_sepsis_respiratory_0dose
    , integer_lasso_sepsis_respiratory_0dose_min AS integer_ridge_sepsis_respiratory_0dose_min
    , integer_lasso_sepsis_respiratory_0dose_max AS integer_ridge_sepsis_respiratory_0dose_max

    , integer_lasso_sepsis_respiratory_1dose AS integer_ridge_sepsis_respiratory_1dose
    , integer_lasso_sepsis_respiratory_1dose_min AS integer_ridge_sepsis_respiratory_1dose_min
    , integer_lasso_sepsis_respiratory_1dose_max AS integer_ridge_sepsis_respiratory_1dose_max

    , integer_lasso_sepsis_respiratory_2doses AS integer_ridge_sepsis_respiratory_2doses
    , integer_lasso_sepsis_respiratory_2doses_min AS integer_ridge_sepsis_respiratory_2doses_min
    , integer_lasso_sepsis_respiratory_2doses_max AS integer_ridge_sepsis_respiratory_2doses_max

  FROM `**REDACTED**.timecourse.integer_lasso_sepsis_respiratory`

)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_respiratory", "integer_ridge_sepsis_respiratory_min");
