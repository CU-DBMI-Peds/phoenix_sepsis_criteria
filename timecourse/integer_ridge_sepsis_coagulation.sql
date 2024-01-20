#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.integer_ridge_sepsis_coagulation` AS
(
  SELECT
      site
    , enc_id
    , eclock
    , integer_lasso_sepsis_coagulation AS integer_ridge_sepsis_coagulation
    , integer_lasso_sepsis_coagulation_min AS integer_ridge_sepsis_coagulation_min
    , integer_lasso_sepsis_coagulation_max AS integer_ridge_sepsis_coagulation_max

    , integer_lasso_sepsis_coagulation_0dose AS integer_ridge_sepsis_coagulation_0dose
    , integer_lasso_sepsis_coagulation_0dose_min AS integer_ridge_sepsis_coagulation_0dose_min
    , integer_lasso_sepsis_coagulation_0dose_max AS integer_ridge_sepsis_coagulation_0dose_max

    , integer_lasso_sepsis_coagulation_1dose AS integer_ridge_sepsis_coagulation_1dose
    , integer_lasso_sepsis_coagulation_1dose_min AS integer_ridge_sepsis_coagulation_1dose_min
    , integer_lasso_sepsis_coagulation_1dose_max AS integer_ridge_sepsis_coagulation_1dose_max

    , integer_lasso_sepsis_coagulation_2doses AS integer_ridge_sepsis_coagulation_2doses
    , integer_lasso_sepsis_coagulation_2doses_min AS integer_ridge_sepsis_coagulation_2doses_min
    , integer_lasso_sepsis_coagulation_2doses_max AS integer_ridge_sepsis_coagulation_2doses_max

  FROM `**REDACTED**.timecourse.integer_lasso_sepsis_coagulation`

)
;
CALL **REDACTED**.sa.aggregate("integer_ridge_sepsis_coagulation", "integer_ridge_sepsis_coagulation_min");
