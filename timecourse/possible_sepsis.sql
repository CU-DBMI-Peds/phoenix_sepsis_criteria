#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.possible_sepsis` AS
(
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , pews_resp.pews_saturation
      , pews_resp.pews_oxygen
      , pews_resp.pews_tachypnea
      , qc.qsofa_cardiovascular
      , pews_card.pews_cap_refill
      , pews_card.pews_tachycardia
      , pn.psofa_neurological
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.pews_respiratory` pews_resp
    ON tc.site = pews_resp.site AND tc.enc_id = pews_resp.enc_id AND tc.eclock = pews_resp.eclock
    LEFT JOIN `**REDACTED**.timecourse.qsofa_cardiovascular` qc
    ON tc.site = qc.site AND tc.enc_id = qc.enc_id AND tc.eclock = qc.eclock
    LEFT JOIN `**REDACTED**.timecourse.pews_cardiovascular` pews_card
    ON tc.site = pews_card.site AND tc.enc_id = pews_card.enc_id AND tc.eclock = pews_card.eclock
    LEFT JOIN `**REDACTED**.timecourse.psofa_neurological` pn
    ON tc.site = pn.site AND tc.enc_id = pn.enc_id AND tc.eclock = pn.eclock
  )
  ,
  subscores AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , CASE WHEN pews_saturation = 3 OR pews_oxygen = 1 THEN 2
             WHEN pews_tachypnea = 3 THEN 1
             WHEN pews_saturation IS NOT NULL AND pews_oxygen IS NOT NULL AND pews_tachypnea IS NOT NULL THEN 0
             ELSE NULL END AS possible_resp
      , CASE WHEN qsofa_cardiovascular = 1 OR pews_cap_refill >= 1 THEN 2
             WHEN pews_tachycardia >=3 THEN 1
             WHEN qsofa_cardiovascular IS NOT NULL AND pews_cap_refill IS NOT NULL AND pews_tachycardia IS NOT NULL THEN 0
             ELSE NULL END AS possible_cv
      , CASE WHEN psofa_neurological >= 2 THEN 2
             WHEN psofa_neurological >= 1 THEN 1
             WHEN psofa_neurological IS NOT NULL THEN 0
             ELSE NULL END AS possible_neuro
    FROM t0
  )

  SELECT
      site
    , enc_id
    , eclock
    , possible_resp AS possible_sepsis_resp
    , possible_neuro AS possible_sepsis_neuro
    , possible_cv AS possible_sepsis_cv
    , COALESCE(possible_resp, 0) AS possible_sepsis_resp_min
    , COALESCE(possible_neuro, 0) AS possible_sepsis_neuro_min
    , COALESCE(possible_cv, 0) AS possible_sepsis_cv_min
    , possible_resp + possible_neuro + possible_cv AS possible_sepsis_total
    , COALESCE(possible_resp, 0) + COALESCE(possible_neuro, 0) + COALESCE(possible_cv, 0) AS possible_sepsis_total_min
  FROM subscores
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("possible_sepsis", "possible_sepsis_resp_min");
CALL **REDACTED**.sa.aggregate("possible_sepsis", "possible_sepsis_neuro_min");
CALL **REDACTED**.sa.aggregate("possible_sepsis", "possible_sepsis_cv_min");
CALL **REDACTED**.sa.aggregate("possible_sepsis", "possible_sepsis_total_min");
