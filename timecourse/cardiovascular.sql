#standardSQL

-- Build one table with the needed info to QA/QC and report on Cardiovascular
-- scores

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.cardiovascular` AS
(
  WITH t AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , tc.age_months
      , tc.admit_age_months

      , bp.map
      , bp.sbp
      , crt.crt_prolonged_3
      , crt_prolonged_5
      , dob.dobutamine
      , dob.dobutamine_yn
      , dop.dopamine
      , dop.dopamine_yn
      , ecmo.ecmo_va
      , epi.epinephrine
      , epi.epinephrine_yn
      , lac.lactate
      , mil.milrinone
      , mil.milrinone_yn
      , norepi.norepinephrine
      , norepi.norepinephrine_yn
      , paco2.paco2
      , pulse.pulse
      , serum_ph.serum_ph
      , troponin.troponin
      , urine.urine_6hr
      , urine.urine_12hr
      , vas.vasopressin
      , vas.vasopressin_yn

      , integer_lasso_sepsis.*EXCEPT(site, enc_id, eclock)
      , integer_ridge_sepsis.*EXCEPT(site, enc_id, eclock)
      , ipscc.*EXCEPT(site, enc_id, eclock)
      , lqsofa.*EXCEPT(site, enc_id, eclock)
      , msirs.*EXCEPT(site, enc_id, eclock)
      , pelod2.*EXCEPT(site, enc_id, eclock)
      , pews.*EXCEPT(site, enc_id, eclock)
      , podium.*EXCEPT(site, enc_id, eclock)
      , proulx.*EXCEPT(site, enc_id, eclock)
      , psofa.*EXCEPT(site, enc_id, eclock)
      , qsofa.*EXCEPT(site, enc_id, eclock)
      , shock_index.*EXCEPT(site, enc_id, eclock)
      , vis.*EXCEPT(site, enc_id, eclock)
    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` bp
    ON tc.site = bp.site AND tc.enc_id = bp.enc_id AND tc.eclock = bp.eclock

    LEFT JOIN `**REDACTED**.timecourse.crt_prolonged` crt
    ON tc.site = crt.site AND tc.enc_id = crt.enc_id AND tc.eclock = crt.eclock

    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dob
    ON tc.site = dob.site AND tc.enc_id = dob.enc_id AND tc.eclock = dob.eclock

    LEFT JOIN `**REDACTED**.timecourse.dopamine` dop
    ON tc.site = dop.site AND tc.enc_id = dop.enc_id AND tc.eclock = dop.eclock

    LEFT JOIN `**REDACTED**.timecourse.ecmo` ecmo
    ON tc.site = ecmo.site AND tc.enc_id = ecmo.enc_id AND tc.eclock = ecmo.eclock

    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epi
    ON tc.site = epi.site AND tc.enc_id = epi.enc_id AND tc.eclock = epi.eclock

    LEFT JOIN `**REDACTED**.timecourse.lactate` lac
    ON tc.site = lac.site AND tc.enc_id = lac.enc_id AND tc.eclock = lac.eclock

    LEFT JOIN `**REDACTED**.timecourse.milrinone` mil
    ON tc.site = mil.site AND tc.enc_id = mil.enc_id AND tc.eclock = mil.eclock

    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepi
    ON tc.site = norepi.site AND tc.enc_id = norepi.enc_id AND tc.eclock = norepi.eclock

    LEFT JOIN `**REDACTED**.timecourse.paco2` paco2
    ON tc.site = paco2.site AND tc.enc_id = paco2.enc_id AND tc.eclock = paco2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pulse` pulse
    ON tc.site = pulse.site AND tc.enc_id = pulse.enc_id AND tc.eclock = pulse.eclock

    LEFT JOIN `**REDACTED**.timecourse.serum_ph` serum_ph
    ON tc.site = serum_ph.site AND tc.enc_id = serum_ph.enc_id AND tc.eclock = serum_ph.eclock

    LEFT JOIN `**REDACTED**.timecourse.troponin` troponin
    ON tc.site = troponin.site AND tc.enc_id = troponin.enc_id AND tc.eclock = troponin.eclock

    LEFT JOIN `**REDACTED**.timecourse.urine` urine
    ON tc.site = urine.site AND tc.enc_id = urine.enc_id AND tc.eclock = urine.eclock

    LEFT JOIN `**REDACTED**.timecourse.vasopressin` vas
    ON tc.site = vas.site AND tc.enc_id = vas.enc_id AND tc.eclock = vas.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_lasso_sepsis_cardiovascular` integer_lasso_sepsis
    ON tc.site = integer_lasso_sepsis.site AND tc.enc_id = integer_lasso_sepsis.enc_id AND tc.eclock = integer_lasso_sepsis.eclock

    LEFT JOIN `**REDACTED**.timecourse.integer_ridge_sepsis_cardiovascular` integer_ridge_sepsis
    ON tc.site = integer_ridge_sepsis.site AND tc.enc_id = integer_ridge_sepsis.enc_id AND tc.eclock = integer_ridge_sepsis.eclock

    LEFT JOIN `**REDACTED**.timecourse.ipscc_cardiovascular` ipscc
    ON tc.site = ipscc.site AND tc.enc_id = ipscc.enc_id AND tc.eclock = ipscc.eclock

    LEFT JOIN `**REDACTED**.timecourse.lqsofa_cardiovascular` lqsofa
    ON tc.site = lqsofa.site AND tc.enc_id = lqsofa.enc_id AND tc.eclock = lqsofa.eclock

    LEFT JOIN `**REDACTED**.timecourse.msirs_total` msirs
    ON tc.site = msirs.site AND tc.enc_id = msirs.enc_id AND tc.eclock = msirs.eclock

    LEFT JOIN `**REDACTED**.timecourse.pelod2_cardiovascular` pelod2
    ON tc.site = pelod2.site AND tc.enc_id = pelod2.enc_id AND tc.eclock = pelod2.eclock

    LEFT JOIN `**REDACTED**.timecourse.pews_cardiovascular` pews
    ON tc.site = pews.site AND tc.enc_id = pews.enc_id AND tc.eclock = pews.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_cardiovascular` podium
    ON tc.site = podium.site AND tc.enc_id = podium.enc_id AND tc.eclock = podium.eclock

    LEFT JOIN `**REDACTED**.timecourse.proulx_cardiovascular` proulx
    ON tc.site = proulx.site AND tc.enc_id = proulx.enc_id AND tc.eclock = proulx.eclock

    LEFT JOIN `**REDACTED**.timecourse.psofa_cardiovascular` psofa
    ON tc.site = psofa.site AND tc.enc_id = psofa.enc_id AND tc.eclock = psofa.eclock

    LEFT JOIN `**REDACTED**.timecourse.qsofa_cardiovascular` qsofa
    ON tc.site = qsofa.site AND tc.enc_id = qsofa.enc_id AND tc.eclock = qsofa.eclock

    LEFT JOIN `**REDACTED**.timecourse.shock_index` shock_index
    ON tc.site = shock_index.site AND tc.enc_id = shock_index.enc_id AND tc.eclock = shock_index.eclock

    LEFT JOIN `**REDACTED**.timecourse.vis` vis
    ON tc.site = vis.site AND tc.enc_id = vis.enc_id AND tc.eclock = vis.eclock

    WHERE tc.eclock >= 0
  )

  SELECT
      site
    , enc_id
    , MIN(eclock) AS eclock

    , age_months
    , map
    , sbp
    , crt_prolonged_3
    , crt_prolonged_5
    , dobutamine
    , dobutamine_yn
    , dopamine
    , dopamine_yn
    , ecmo_va
    , epinephrine
    , epinephrine_yn
    , lactate
    , milrinone
    , milrinone_yn
    , norepinephrine
    , norepinephrine_yn
    , paco2
    , pulse
    , serum_ph
    , troponin
    , urine_6hr
    , urine_12hr
    , vasopressin
    , vasopressin_yn

    , integer_lasso_sepsis_cardiovascular_1dose_min
    , integer_lasso_sepsis_cardiovascular_2doses_min
    , integer_lasso_sepsis_cardiovascular_min
    , integer_ridge_sepsis_cardiovascular_1dose_min
    , integer_ridge_sepsis_cardiovascular_2doses_min
    , integer_ridge_sepsis_cardiovascular_min
    , ipscc_cardiovascular_06_min
    , ipscc_cardiovascular_12_min
    , ipscc_cardiovascular_06_b_min
    , ipscc_cardiovascular_12_b_min
    , lqsofa_cardiovascular_min
    , msirs_cardiovascular_min
    , msirs_inflammation_min
    , msirs_respiratory_min
    , msirs_total_min
    , pelod2_cardiovascular_min
    , pelod2_cv_lact_min
    , pelod2_cv_map_min
    , pews_cardiovascular_min
    , podium_cardiovascular_w_troponin_min
    , podium_cardiovascular_wo_troponin_min
    , proulx_cardiovascular_b_min
    , proulx_cardiovascular_min
    , psofa_cardiovascular_b_min
    , psofa_cardiovascular_min
    , qsofa_cardiovascular_min
    , shock_index_atls_min
    , shock_index_pals_min
    , shock_index_rousseaux_min
    , shock_index_sipa_min
    , shock_index_who_min
    , vis_min
  FROM t
  GROUP BY
      site
    , enc_id

    , age_months
    , map
    , sbp
    , crt_prolonged_3
    , crt_prolonged_5
    , dobutamine
    , dobutamine_yn
    , dopamine
    , dopamine_yn
    , ecmo_va
    , epinephrine
    , epinephrine_yn
    , lactate
    , milrinone
    , milrinone_yn
    , norepinephrine
    , norepinephrine_yn
    , paco2
    , pulse
    , serum_ph
    , troponin
    , urine_6hr
    , urine_12hr
    , vasopressin
    , vasopressin_yn

    , integer_lasso_sepsis_cardiovascular_1dose_min
    , integer_lasso_sepsis_cardiovascular_2doses_min
    , integer_lasso_sepsis_cardiovascular_min
    , integer_ridge_sepsis_cardiovascular_1dose_min
    , integer_ridge_sepsis_cardiovascular_2doses_min
    , integer_ridge_sepsis_cardiovascular_min
    , ipscc_cardiovascular_06_min
    , ipscc_cardiovascular_12_min
    , ipscc_cardiovascular_06_b_min
    , ipscc_cardiovascular_12_b_min
    , lqsofa_cardiovascular_min
    , msirs_cardiovascular_min
    , msirs_inflammation_min
    , msirs_respiratory_min
    , msirs_total_min
    , pelod2_cardiovascular_min
    , pelod2_cv_lact_min
    , pelod2_cv_map_min
    , pews_cardiovascular_min
    , podium_cardiovascular_w_troponin_min
    , podium_cardiovascular_wo_troponin_min
    , proulx_cardiovascular_b_min
    , proulx_cardiovascular_min
    , psofa_cardiovascular_b_min
    , psofa_cardiovascular_min
    , qsofa_cardiovascular_min
    , shock_index_atls_min
    , shock_index_pals_min
    , shock_index_rousseaux_min
    , shock_index_sipa_min
    , shock_index_who_min
    , vis_min
);

SELECT count(1) AS N FROM `**REDACTED**.timecourse.cardiovascular`;

--SELECT * FROM `**REDACTED**.timecourse.INFORMATION_SCHEMA.COLUMNS`
--WHERE (lower(table_name) LIKE "%msirs%" OR lower(table_name) LIKE "%shock%" OR lower(table_name) LIKE "%vis%") AND column_name LIKE "%_min"
--ORDER BY table_name, column_name
--;


-- SOME QA/QC work, re issue 99
SELECT DISTINCT
    site
  , enc_id
  , eclock
  , dobutamine
  , dobutamine_yn
  , dopamine
  , dopamine_yn
  , epinephrine
  , epinephrine_yn
  , milrinone_yn
  , norepinephrine
  , norepinephrine_yn
  , vasopressin_yn
  , lactate
  , map
  , integer_lasso_sepsis_cardiovascular_min
  , psofa_cardiovascular_min
FROM `**REDACTED**.timecourse.cardiovascular`
;


SELECT integer_lasso_sepsis_cardiovascular_min, psofa_cardiovascular_min, count(1) AS N
FROM `**REDACTED**.timecourse.cardiovascular`
GROUP BY integer_lasso_sepsis_cardiovascular_min, psofa_cardiovascular_min
ORDER BY integer_lasso_sepsis_cardiovascular_min, psofa_cardiovascular_min
;

SELECT integer_lasso_sepsis_cardiovascular_min, pelod2_cardiovascular_min, count(1) AS N
FROM (SELECT * FROM `**REDACTED**.timecourse.cardiovascular` WHERE lactate IS NULL)
GROUP BY integer_lasso_sepsis_cardiovascular_min, pelod2_cardiovascular_min
ORDER BY integer_lasso_sepsis_cardiovascular_min, pelod2_cardiovascular_min
;

SELECT
    SUM(IF(psofa_cardiovascular_min = 0, 1, 0)) as psofa
  , SUM(IF(integer_lasso_sepsis_cardiovascular_min = 0, 1, 0)) as integer_lasso_sepsis
  , SUM(IF(integer_lasso_sepsis_cardiovascular_min = 0, 1, 0)) < SUM(IF(psofa_cardiovascular_min = 0, 1, 0)) AS expectation_check
FROM `**REDACTED**.timecourse.cardiovascular`
;

SELECT
    age_months
  , map
  , lactate
  , milrinone_yn
  , vasopressin_yn
  , dobutamine
  , dobutamine_yn
  , dopamine
  , dopamine_yn
  , epinephrine
  , epinephrine_yn
  , norepinephrine
  , norepinephrine_yn
  , integer_lasso_sepsis_cardiovascular_min
  , psofa_cardiovascular_min
  , pelod2_cardiovascular_min
FROM `**REDACTED**.timecourse.cardiovascular`
--WHERE (milrinone_yn = 1 OR vasopressin_yn = 1) AND (dobutamine_yn = 0 AND dopamine_yn = 0 AND epinephrine_yn = 0 AND norepinephrine_yn = 0)
WHERE (integer_lasso_sepsis_cardiovascular_min = 0) AND (psofa_cardiovascular_min <> 0)
--WHERE (age_months >= 1 AND age_months < 12) AND map < 55
--WHERE integer_lasso_sepsis_cardiovascular_min = 0 AND pelod2_cardiovascular_min = 3

;
