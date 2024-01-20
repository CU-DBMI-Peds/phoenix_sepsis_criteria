#standardSQL
/*
DECLARE thisOutcome STRING;
DECLARE thisX STRING;
DECLARE thisStrata STRING;
DECLARE thisWHERE STRING;

SET thisOutcome = "death";
SET thisX = "vis_01_hour";
SET thisStrata = "temp";
SET thisWHERE = "";

EXECUTE IMMEDIATE FORMAT("""
CREATE OR REPLACE MODEL `**REDACTED**.sa.sa1__%s__%s__%s`
OPTIONS
(
    model_type = 'logistic_reg'
  , input_label_cols = ['death']
  , OPTIMIZE_STRATEGY = 'BATCH_GRADIENT_DESCENT'
  , WARM_START = FALSE
)
AS
SELECT %s, %s
FROM `**REDACTED**.sa.sa` WHERE sa_subset = 'SA1'
%s
""", thisOutcome, thisX, thisStrata, thisOutcome, thisX, thisWHERE
)
;
*/

/*(
SELECT * FROM
ML.FEATURE_INFO(MODEL `**REDACTED**.sa.sa1__death__vis_01_hour__temp`)
LEFT JOIN
ML.WEIGHTS(MODEL `**REDACTED**.sa.sa1__death__vis_01_hour__temp`)
ON input = processed_input
;

SELECT * FROM
ML.PREDICT(MODEL `**REDACTED**.sa.sa1__death__vis_01_hour__temp
(
  SELECT enc_id, death_during_encounter, psofa_total_min_1hour
  FROM `**REDACTED**.sa.sa1`
  WHERE psofa_total_min_1hour IS NOT NULL
)
);
*/

-- ROC
SELECT * FROM
ML.ROC_CURVE(MODEL `**REDACTED**.sa.sa1__death__vis_01_hour__temp`
  , ((SELECT * FROM `**REDACTED**.sa.sa` WHERE sa_subset = "SA1"))
  , GENERATE_ARRAY(0.00, 1.00, 0.01) -- thresholds
  )
;

/*
-- PRC
SELECT recall, true_positives/ (true_positives + false_positives) AS precision
FROM
ML.ROC_CURVE(MODEL `**REDACTED**.sa.sa1__death__vis_01_hour__temp`
  , TABLE ((SELECT * FROM `**REDACTED**.sa.sa` WHERE sa_subset = "SA1"))
  , GENERATE_ARRAY(0.01, 0.99, 0.01) -- thresholds
  )
;
*/
