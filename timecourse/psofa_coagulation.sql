#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.psofa_coagulation` AS (

WITH t AS (
  SELECT enc_id, eclock, MAX(value) as psofa_coagulation
  FROM
  (
    SELECT enc_id, eclock, 4 AS value
    FROM `**REDACTED**.timecourse.platelets`
    WHERE platelets < 20
    UNION ALL
    SELECT enc_id, eclock, 3 AS value
    FROM `**REDACTED**.timecourse.platelets`
    WHERE platelets < 50
    UNION ALL
    SELECT enc_id, eclock, 2 AS value
    FROM `**REDACTED**.timecourse.platelets`
    WHERE platelets < 100
    UNION ALL
    SELECT enc_id, eclock, 1 AS value
    FROM `**REDACTED**.timecourse.platelets`
    WHERE platelets < 150
    UNION ALL
    SELECT enc_id, eclock, 0 AS value
    FROM `**REDACTED**.timecourse.platelets`
    WHERE platelets IS NOT NULL
  )
    GROUP BY enc_id, eclock
  )

  SELECT tc.site, tc.enc_id, tc.eclock,
    t.psofa_coagulation,
    COALESCE(t.psofa_coagulation, 0) AS psofa_coagulation_min,
    COALESCE(t.psofa_coagulation, 4) AS psofa_coagulation_max
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;
CALL **REDACTED**.sa.aggregate("psofa_coagulation", "psofa_coagulation_min");
