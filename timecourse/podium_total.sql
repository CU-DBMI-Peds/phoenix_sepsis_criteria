#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.podium_total` AS
(
  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    ,
      podium_cardiovascular_wo_troponin + podium_respiratory            +
      podium_neurological               + podium_renal                  +
      podium_hepatic                    + podium_coag                   +
      podium_heme                       + podium_endocrine_wo_thyroxine + podium_immunologic AS podium_total_wo_troponin_wo_thyroxine
    ,
      podium_cardiovascular_wo_troponin_min + podium_respiratory_min            +
      podium_neurological_min               + podium_renal_min                  +
      podium_hepatic_min                    + podium_coag_min                   +
      podium_heme_min                       + podium_endocrine_wo_thyroxine_min + podium_immunologic_min AS podium_total_wo_troponin_wo_thyroxine_min
    ,
      podium_cardiovascular_wo_troponin_max + podium_respiratory_max            +
      podium_neurological_max               + podium_renal_max                  +
      podium_hepatic_max                    + podium_coag_max                   +
      podium_heme_max                       + podium_endocrine_wo_thyroxine_max + podium_immunologic_max AS podium_total_wo_troponin_wo_thyroxine_max
    ,
      podium_cardiovascular_wo_troponin + podium_respiratory           +
      podium_neurological               + podium_renal                 +
      podium_hepatic                    + podium_coag                  +
      podium_heme                       + podium_endocrine_w_thyroxine + podium_immunologic AS podium_wo_troponin_w_thyroxine_total
    ,
      podium_cardiovascular_wo_troponin_min + podium_respiratory_min           +
      podium_neurological_min               + podium_renal_min                 +
      podium_hepatic_min                    + podium_coag_min                  +
      podium_heme_min                       + podium_endocrine_w_thyroxine_min + podium_immunologic_min AS podium_total_wo_troponin_w_thyroxine_min
    ,
      podium_cardiovascular_wo_troponin_max + podium_respiratory_max           +
      podium_neurological_max               + podium_renal_max                 +
      podium_hepatic_max                    + podium_coag_max                  +
      podium_heme_max                       + podium_endocrine_w_thyroxine_max + podium_immunologic_max AS podium_total_wo_troponin_w_thyroxine_max
    ,
      podium_cardiovascular_w_troponin + podium_respiratory            +
      podium_neurological              + podium_renal                  +
      podium_hepatic                   + podium_coag                   +
      podium_heme                      + podium_endocrine_wo_thyroxine + podium_immunologic AS podium_total_w_troponin_wo_thyroxine
    ,
      podium_cardiovascular_w_troponin_min + podium_respiratory_min            +
      podium_neurological_min              + podium_renal_min                  +
      podium_hepatic_min                   + podium_coag_min                   +
      podium_heme_min                      + podium_endocrine_wo_thyroxine_min + podium_immunologic_min AS podium_total_w_troponin_wo_thyroxine_min
    ,
      podium_cardiovascular_w_troponin_max + podium_respiratory_max            +
      podium_neurological_max              + podium_renal_max                  +
      podium_hepatic_max                   + podium_coag_max                   +
      podium_heme_max                      + podium_endocrine_wo_thyroxine_max + podium_immunologic_max AS podium_total_w_troponin_wo_thyroxine_max
    ,
      podium_cardiovascular_w_troponin + podium_respiratory           +
      podium_neurological              + podium_renal                 +
      podium_hepatic                   + podium_coag                  +
      podium_heme                      + podium_endocrine_w_thyroxine + podium_immunologic AS podium_total_w_troponin_w_thyroxine
    ,
      podium_cardiovascular_w_troponin_min + podium_respiratory_min           +
      podium_neurological_min              + podium_renal_min                 +
      podium_hepatic_min                   + podium_coag_min                  +
      podium_heme_min                      + podium_endocrine_w_thyroxine_min + podium_immunologic_min AS podium_total_w_troponin_w_thyroxine_min
    ,
      podium_cardiovascular_w_troponin_max + podium_respiratory_max           +
      podium_neurological_max              + podium_renal_max                 +
      podium_hepatic_max                   + podium_coag_max                  +
      podium_heme_max                      + podium_endocrine_w_thyroxine_max + podium_immunologic_max AS podium_total_w_troponin_w_thyroxine_max

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.podium_cardiovascular` a
    ON tc.site = a.site AND tc.enc_id = a.enc_id AND tc.eclock = a.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_respiratory` b
    ON tc.site = b.site AND tc.enc_id = b.enc_id AND tc.eclock = b.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_neurological` c
    ON tc.site = c.site AND tc.enc_id = c.enc_id AND tc.eclock = c.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_renal` d
    ON tc.site = d.site AND tc.enc_id = d.enc_id AND tc.eclock = d.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_hepatic` e
    ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_heme` f
    ON tc.site = f.site AND tc.enc_id = f.enc_id AND tc.eclock = f.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_endocrine` g
    ON tc.site = g.site AND tc.enc_id = g.enc_id AND tc.eclock = g.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_immunologic` h
    ON tc.site = h.site AND tc.enc_id = h.enc_id AND tc.eclock = h.eclock

    LEFT JOIN `**REDACTED**.timecourse.podium_coag` i
    ON tc.site = i.site AND tc.enc_id = i.enc_id AND tc.eclock = i.eclock
)
;
CALL **REDACTED**.sa.aggregate("podium_total", "podium_total_wo_troponin_wo_thyroxine_min");
CALL **REDACTED**.sa.aggregate("podium_total", "podium_total_wo_troponin_w_thyroxine_min");
CALL **REDACTED**.sa.aggregate("podium_total", "podium_total_w_troponin_w_thyroxine_min");
CALL **REDACTED**.sa.aggregate("podium_total", "podium_total_w_troponin_wo_thyroxine_min");
