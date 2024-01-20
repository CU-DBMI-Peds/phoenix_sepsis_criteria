#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_cardiovascular` AS
(
  SELECT
      site
    , enc_id
    , eclock
    , integer_lasso_sepsis_cardiovascular AS integer_ridge_sepsis_cardiovascular
    , integer_lasso_sepsis_cardiovascular_min AS integer_ridge_sepsis_cardiovascular_min
    , integer_lasso_sepsis_cardiovascular_max AS integer_ridge_sepsis_cardiovascular_max

    , integer_lasso_sepsis_cardiovascular_0dose AS integer_ridge_sepsis_cardiovascular_0dose
    , integer_lasso_sepsis_cardiovascular_0dose_min AS integer_ridge_sepsis_cardiovascular_0dose_min
    , integer_lasso_sepsis_cardiovascular_0dose_max AS integer_ridge_sepsis_cardiovascular_0dose_max

    , integer_lasso_sepsis_cardiovascular_1dose AS integer_ridge_sepsis_cardiovascular_1dose
    , integer_lasso_sepsis_cardiovascular_1dose_min AS integer_ridge_sepsis_cardiovascular_1dose_min
    , integer_lasso_sepsis_cardiovascular_1dose_max AS integer_ridge_sepsis_cardiovascular_1dose_max

    , integer_lasso_sepsis_cardiovascular_2doses AS integer_ridge_sepsis_cardiovascular_2doses
    , integer_lasso_sepsis_cardiovascular_2doses_min AS integer_ridge_sepsis_cardiovascular_2doses_min
    , integer_lasso_sepsis_cardiovascular_2doses_max AS integer_ridge_sepsis_cardiovascular_2doses_max

  FROM `**REDACTED**.timecourse.integer_lasso_sepsis_cardiovascular`

)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_cardiovascular", "integer_ridge_sepsis_cardiovascular_min");
