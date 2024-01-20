#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_neurologic` AS
(
  SELECT
      site
    , enc_id
    , eclock
    , integer_lasso_sepsis_neurologic AS integer_ridge_sepsis_neurologic
    , integer_lasso_sepsis_neurologic_min AS integer_ridge_sepsis_neurologic_min
    , integer_lasso_sepsis_neurologic_max AS integer_ridge_sepsis_neurologic_max

    , integer_lasso_sepsis_neurologic_0dose AS integer_ridge_sepsis_neurologic_0dose
    , integer_lasso_sepsis_neurologic_0dose_min AS integer_ridge_sepsis_neurologic_0dose_min
    , integer_lasso_sepsis_neurologic_0dose_max AS integer_ridge_sepsis_neurologic_0dose_max

    , integer_lasso_sepsis_neurologic_1dose AS integer_ridge_sepsis_neurologic_1dose
    , integer_lasso_sepsis_neurologic_1dose_min AS integer_ridge_sepsis_neurologic_1dose_min
    , integer_lasso_sepsis_neurologic_1dose_max AS integer_ridge_sepsis_neurologic_1dose_max

    , integer_lasso_sepsis_neurologic_2doses AS integer_ridge_sepsis_neurologic_2doses
    , integer_lasso_sepsis_neurologic_2doses_min AS integer_ridge_sepsis_neurologic_2doses_min
    , integer_lasso_sepsis_neurologic_2doses_max AS integer_ridge_sepsis_neurologic_2doses_max

  FROM `**REDACTED**.timecourse.integer_lasso_sepsis_neurologic`

)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_neurologic", "integer_ridge_sepsis_neurologic_min");
