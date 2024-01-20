OrganDysfunctionScores  = .ipscc_total.log
OrganDysfunctionScores += .pelod2_total.log
OrganDysfunctionScores += .pews_total.log
OrganDysfunctionScores += .podium_total.log
OrganDysfunctionScores += .proulx_total.log
OrganDysfunctionScores += .psofa_total.log
OrganDysfunctionScores += .msirs_total.log
OrganDysfunctionScores += .qpelod2_total.log
OrganDysfunctionScores += .shock_index.log
OrganDysfunctionScores += .vis.log
OrganDysfunctionScores += .dic.log
OrganDysfunctionScores += .qsofa_total.log
OrganDysfunctionScores += .lqsofa_total.log
OrganDysfunctionScores += .integer_lasso_sepsis_total.log
OrganDysfunctionScores += .integer_ridge_sepsis_total.log
OrganDysfunctionScores += .possible_sepsis_total.log

OtherTargets  = .weight_for_age_zscore.log
OtherTargets += .ipscc_sepsis.log
OtherTargets += .ipscc_tachypnea.log
OtherTargets += .proulx_tachypnea.log
OtherTargets += .proven_infection.log
OtherTargets += .rsv_infection.log
OtherTargets += .hmpv_infection.log

QA = .qa_variable_counts.log .qa_table_counts.log #.cardiovascular.log

SpecificAimsData = .build_sa_data_subsets.log **REDACTED**/specific_aims/.build_sa_data.log

.PHONY: all clean

all : $(SpecificAimsData) $(QA)

.ipscc_cardiovascular.log : ipscc_cardiovascular.sql .foundation.log .base_def.log .lactate.log .bloodpressure.log .dopamine.log .dobutamine.log .epinephrine.log .norepinephrine.log .urine.log .crt_prolonged.log .routines.log
	bq query < $< > $@

.ipscc_respiratory.log : ipscc_respiratory.sql .foundation.log .pf_ratio.log .sf_ratio.log .vent.log .paco2.log .spo2.log .niv.log .routines.log
	bq query < $< > $@

.ipscc_neurological.log : ipscc_neurological.sql .foundation.log .gcs.log .routines.log
	bq query < $< > $@

.ipscc_hepatic.log : ipscc_hepatic.sql .foundation.log .alt.log .bilirubin_tot.log .routines.log
	bq query < $< > $@

.ipscc_heme.log : ipscc_heme.sql .foundation.log .platelets.log .inr.log .routines.log
	bq query < $< > $@

.ipscc_renal.log : ipscc_renal.sql .foundation.log .creatinine.log .routines.log
	bq query < $< > $@

.ipscc_total.log : ipscc_total.sql .foundation.log .ipscc_cardiovascular.log .ipscc_respiratory.log .ipscc_neurological.log .ipscc_hepatic.log .ipscc_heme.log .ipscc_renal.log .routines.log
	bq query < $< > $@

.ipscc_sepsis.log : ipscc_sepsis.sql .suspected_infection.log .temperature.log .pulse.log .respiratory_rate.log .vent.log .wbc.log .ipscc_cardiovascular.log .ipscc_respiratory.log .ipscc_neurological.log .ipscc_hepatic.log .ipscc_heme.log .ipscc_renal.log .foundation.log .routines.log
	bq query < $< > $@

.ipscc_tachypnea.log : ipscc_tachypnea.sql .respiratory_rate.log .foundation.log .vent.log .routines.log
	bq query < $< > $@

.pelod2_cardiovascular.log : pelod2_cardiovascular.sql .foundation.log .lactate.log .bloodpressure.log .routines.log
	bq query < $< > $@

.pelod2_respiratory.log : pelod2_respiratory.sql .foundation.log .paco2.log .vent.log .pf_ratio.log .routines.log
	bq query < $< > $@

.pelod2_neurological.log : pelod2_neurological.sql .foundation.log .gcs.log .pupil.log .routines.log
	bq query < $< > $@

.pelod2_renal.log : pelod2_renal.sql .creatinine.log .foundation.log .routines.log
	bq query < $< > $@

.pelod2_heme.log : pelod2_heme.sql .foundation.log .wbc.log .platelets.log .routines.log
	bq query < $< > $@

.pelod2_total.log : pelod2_total.sql .foundation.log .pelod2_cardiovascular.log .pelod2_respiratory.log .pelod2_neurological.log .pelod2_renal.log .pelod2_heme.log .routines.log
	bq query < $< > $@

.podium_cardiovascular.log : podium_cardiovascular.sql .pulse.log .foundation.log .bloodpressure.log .vis.log .lactate.log .ecmo.log .troponin.log .routines.log
	bq query < $< > $@

.podium_respiratory.log : podium_respiratory.sql .foundation.log .ecmo.log .pf_ratio.log .sf_ratio.log .spo2.log .fio2.log .nppv.log .vent.log .oi.log .osi.log .routines.log
	bq query < $< > $@

.podium_neurological.log : podium_neurological.sql .foundation.log .gcs.log .routines.log
	bq query < $< > $@

.podium_renal.log : podium_renal.sql .foundation.log .creatinine.log .crrt.log .weight.log .urine.log .routines.log
	bq query < $< > $@

.podium_hepatic.log : podium_hepatic.sql .foundation.log .ast.log .alt.log .ggt.log .bilirubin_tot.log .bilirubin_dir.log .inr.log .gcs.log .routines.log
	bq query < $< > $@

.podium_coag.log : podium_coag.sql .platelets.log .inr.log .fibrinogen.log .d_dimer.log .foundation.log .podium_hepatic.log .wbc.log .hemoglobin.log .routines.log
	bq query < $< > $@

.podium_heme.log : podium_heme.sql .platelets.log .foundation.log .wbc.log .hemoglobin.log .podium_coag.log .routines.log
	bq query < $< > $@

.podium_immunologic.log : podium_immunologic.sql .foundation.log .anc.log .alc.log .routines.log
	bq query < $< > $@

.podium_endocrine.log : podium_endocrine.sql .foundation.log .glucose.log .thyroxine.log .routines.log
	bq query < $< > $@

.podium_total.log : podium_total.sql .foundation.log .podium_cardiovascular.log .podium_respiratory.log .podium_neurological.log .podium_renal.log .podium_hepatic.log .podium_coag.log .podium_heme.log .podium_immunologic.log .podium_endocrine.log .routines.log
	bq query < $< > $@

.proulx_cardiovascular.log : proulx_cardiovascular.sql .foundation.log .bloodpressure.log .pulse.log .serum_ph.log .paco2.log .dobutamine.log .dopamine.log .epinephrine.log .norepinephrine.log .routines.log
	bq query < $< > $@

.proulx_respiratory.log : proulx_respiratory.sql .foundation.log .respiratory_rate.log .paco2.log .vent.log .pao2.log .pf_ratio.log .routines.log
	bq query < $< > $@

.proulx_neurological.log : proulx_neurological.sql .foundation.log .gcs.log .pupil.log .routines.log
	bq query < $< > $@

.proulx_renal.log : proulx_renal.sql .foundation.log .creatinine.log .crrt.log .bun.log .routines.log
	bq query < $< > $@

.proulx_heme.log : proulx_heme.sql .foundation.log .hemoglobin.log .wbc.log .platelets.log .d_dimer.log .ptt.log .pt.log .routines.log
	bq query < $< > $@

.proulx_hepatic.log : proulx_hepatic.sql .foundation.log .bilirubin_tot.log .routines.log
	bq query < $< > $@

.proulx_total.log : proulx_total.sql .foundation.log .proulx_cardiovascular.log .proulx_respiratory.log .proulx_neurological.log .proulx_renal.log .proulx_heme.log .proulx_hepatic.log .routines.log
	bq query < $< > $@

.proulx_tachypnea.log : proulx_tachypnea.sql .foundation.log .respiratory_rate.log .vent.log .routines.log
	bq query < $< > $@

.psofa_cardiovascular.log : psofa_cardiovascular.sql .dopamine.log .dobutamine.log .epinephrine.log .norepinephrine.log .foundation.log .bloodpressure.log .routines.log
	bq query < $< > $@

.psofa_respiratory.log : psofa_respiratory.sql .foundation.log .pf_ratio.log .sf_ratio.log .spo2.log .vent.log .routines.log
	bq query < $< > $@

.psofa_neurological.log : psofa_neurological.sql .foundation.log .gcs.log .routines.log
	bq query < $< > $@

.psofa_renal.log : psofa_renal.sql .foundation.log .creatinine.log .routines.log
	bq query < $< > $@

.psofa_coagulation.log : psofa_coagulation.sql .foundation.log .platelets.log .routines.log
	bq query < $< > $@

.psofa_hepatic.log : psofa_hepatic.sql .foundation.log .bilirubin_tot.log .routines.log
	bq query < $< > $@

.psofa_total.log : psofa_total.sql .foundation.log .psofa_cardiovascular.log .psofa_respiratory.log .psofa_neurological.log .psofa_renal.log .psofa_coagulation.log .psofa_hepatic.log .routines.log
	bq query < $< > $@

.oi.log : oi.sql .foundation.log .vent.log .pao2.log .fio2.log
	bq query < $< > $@

.osi.log : osi.sql .foundation.log .vent.log .spo2.log .fio2.log
	bq query < $< > $@

.niv.log : niv.sql .foundation.log .epap_niv.log .ipap_niv.log
	bq query < $< > $@

.nppv.log : nppv.sql .foundation.log .epap_niv.log .o2_flow.log .weight.log .routines.log
	bq query < $< > $@

.shock_index.log : shock_index.sql .foundation.log .pulse.log .bloodpressure.log .crt_prolonged.log .routines.log
	bq query < $< > $@

.vis.log : vis.sql .foundation.log .dobutamine.log .dopamine.log .epinephrine.log .milrinone.log .vasopressin.log .norepinephrine.log .routines.log
	bq query < $< > $@

.dic.log : dic.sql .foundation.log .platelets.log .fibrinogen.log .d_dimer.log .inr.log .routines.log
	bq query < $< > $@

.pf_ratio.log : pf_ratio.sql .foundation.log .pao2.log .fio2.log
	bq query < $< > $@

.sf_ratio.log : sf_ratio.sql .foundation.log .spo2.log .fio2.log
	bq query < $< > $@

.dobutamine.log : dobutamine.sql .foundation.log .weight.log
	bq query < $< > $@

.dopamine.log : dopamine.sql .foundation.log .weight.log
	bq query < $< > $@

.epinephrine.log : epinephrine.sql .foundation.log .weight.log
	bq query < $< > $@

.milrinone.log : milrinone.sql .foundation.log .weight.log
	bq query < $< > $@

.norepinephrine.log : norepinephrine.sql .foundation.log .weight.log
	bq query < $< > $@

.vasopressin.log : vasopressin.sql .foundation.log .weight.log
	bq query < $< > $@

.foundation.log : foundation.sql
	bq query < $< > $@

.routines.log : routines.sql
	bq query < $< > $@

.weights_and_urine.log: weights_and_urine.sql .foundation.log .weight.log
	bq query < $< > $@

.weight_for_age_zscore.log : weight_for_age_zscore.sql .foundation.log .weight.log
	bq query < $< > $@

.urine_6hr.log : urine_6hr.sql .weights_and_urine.log
	bq query < $< > $@

.urine_12hr.log : urine_12hr.sql .weights_and_urine.log
	bq query < $< > $@

.urine.log : urine.sql .urine_6hr.log .urine_12hr.log
	bq query < $< > $@

.qsofa_tachypnea.log : qsofa_tachypnea.sql .foundation.log .respiratory_rate.log .vent.log .routines.log
	bq query < $< > $@

.qsofa_neurological.log : qsofa_neurological.sql .foundation.log .gcs.log .routines.log
	bq query < $< > $@

.qsofa_cardiovascular.log : qsofa_cardiovascular.sql .foundation.log .bloodpressure.log .routines.log
	bq query < $< > $@

.qsofa_total.log : qsofa_total.sql .foundation.log .qsofa_tachypnea.log .qsofa_neurological.log .qsofa_cardiovascular.log .routines.log
	bq query < $< > $@

.lqsofa_cardiovascular.log : lqsofa_cardiovascular.sql .foundation.log .pulse.log .crt_prolonged.log .routines.log
	bq query < $< > $@

.lqsofa_respiratory.log : lqsofa_respiratory.sql .foundation.log .respiratory_rate.log .vent.log .routines.log
	bq query < $< > $@

.lqsofa_neurological.log : lqsofa_neurological.sql .foundation.log .gcs.log .routines.log
	bq query < $< > $@

.lqsofa_total.log : lqsofa_total.sql .foundation.log .lqsofa_cardiovascular.log .lqsofa_neurological.log .lqsofa_respiratory.log .routines.log
	bq query < $< > $@

.integer_lasso_sepsis_respiratory.log : integer_lasso_sepsis_respiratory.sql .foundation.log .suspected_infection.log .pf_ratio.log .sf_ratio.log .spo2.log .vent.log .routines.log
	bq query < $< > $@

.integer_lasso_sepsis_cardiovascular.log : integer_lasso_sepsis_cardiovascular.sql .foundation.log .suspected_infection.log .dobutamine.log .dopamine.log .epinephrine.log .norepinephrine.log .milrinone.log .vasopressin.log .lactate.log .bloodpressure.log .routines.log
	bq query < $< > $@

.integer_lasso_sepsis_coagulation.log : integer_lasso_sepsis_coagulation.sql .foundation.log .suspected_infection.log .platelets.log .inr.log .d_dimer.log .fibrinogen.log .routines.log
	bq query < $< > $@

.integer_lasso_sepsis_neurological.log : integer_lasso_sepsis_neurological.sql .foundation.log .suspected_infection.log .gcs.log .pupil.log .routines.log
	bq query < $< > $@

.integer_lasso_sepsis_total.log : integer_lasso_sepsis_total.sql .foundation.log .integer_lasso_sepsis_respiratory.log .integer_lasso_sepsis_cardiovascular.log .integer_lasso_sepsis_coagulation.log .integer_lasso_sepsis_neurological.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_respiratory.log : integer_ridge_sepsis_respiratory.sql .integer_lasso_sepsis_respiratory.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_cardiovascular.log : integer_ridge_sepsis_cardiovascular.sql .integer_lasso_sepsis_cardiovascular.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_coagulation.log : integer_ridge_sepsis_coagulation.sql .integer_lasso_sepsis_coagulation.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_renal.log : integer_ridge_sepsis_renal.sql .foundation.log .creatinine.log .suspected_infection.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_hepatic.log : integer_ridge_sepsis_hepatic.sql .foundation.log .suspected_infection.log .bilirubin_tot.log .alt.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_endocrine.log : integer_ridge_sepsis_endocrine.sql .foundation.log .suspected_infection.log .glucose.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_immunologic.log : integer_ridge_sepsis_immunologic.sql .foundation.log .suspected_infection.log .anc.log .alc.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_neurological.log : integer_ridge_sepsis_neurological.sql .integer_lasso_sepsis_neurological.log .routines.log
	bq query < $< > $@

.integer_ridge_sepsis_total.log : integer_ridge_sepsis_total.sql .foundation.log .integer_ridge_sepsis_respiratory.log .integer_ridge_sepsis_cardiovascular.log .integer_ridge_sepsis_renal.log .integer_ridge_sepsis_hepatic.log .integer_ridge_sepsis_coagulation.log .integer_ridge_sepsis_endocrine.log .integer_ridge_sepsis_immunologic.log .integer_ridge_sepsis_neurological.log .routines.log
	bq query < $< > $@

.pews_respiratory.log : pews_respiratory.sql .respiratory_rate.log .vent.log .spo2.log .o2_flow.log .foundation.log .routines.log
	bq query < $< > $@

.pews_inflammation.log : pews_inflammation.sql .temperature.log .foundation.log .routines.log
	bq query < $< > $@

.pews_neurological.log : pews_neurological.sql .gcs.log .foundation.log .routines.log
	bq query < $< > $@

.pews_cardiovascular.log : pews_cardiovascular.sql .crt_prolonged.log .bloodpressure.log .pulse.log .foundation.log .routines.log
	bq query < $< > $@

.pews_total.log : pews_total.sql .foundation.log .pews_respiratory.log .pews_inflammation.log .pews_cardiovascular.log .pews_neurological.log .routines.log
	bq query < $< > $@

.possible_sepsis_total.log : possible_sepsis.sql .foundation.log .pews_respiratory.log .qsofa_cardiovascular.log .pews_cardiovascular.log .psofa_neurological.log
	bq query < $< > $@

.mirs_total.log : mirs_total.sql .foundation.log .temperature.log .pulse.log .respiratory_rate.log .routines.log
	bq query < $< > $@

.qpelod2_total.log : qpelod2_total.sql .bloodpressure.log .gcs.log .pulse.log .foundation.log .routines.log
	bq query < $< > $@

.hmpv_infection.log : hmpv_infection.sql .routines.log .foundation.log
	bq query < $< > $@

.proven_infections.log : proven_infections.sql .routines.log .foundation.log
	bq query < $< > $@

.suspected_infection.log : suspected_infection.sql .foundation.log .temperature.log .routines.log
	bq query < $< > $@


.rsv_infection.log : rsv_infection.sql .routines.log .foundation.log
	bq query < $< > $@

.msirs_total.log : msirs_total.sql .temperature.log .pulse.log .respiratory_rate.log .foundation.log .routines.log

.qa_table_counts.log : qa_table_counts.sh $(OtherTargets) $(OrganDysfunctionScores)
	./$< > $@

.qa_variable_counts.log : qa_variable_counts.sh $(OtherTargets) $(OrganDysfunctionScores)
	./$< > $@

.cardiovascular.log : cardiovascular.sql $(OtherTargets) $(OrganDysfunctionScores)
	bq query < $< > $@

.%.log : %.sql .foundation.log
	bq query < $< > $@

.build_sa_data_subsets.log : build_sa_data_subsets.sql
	bq query < $< > $@

**REDACTED**/specific_aims/.build_sa_data.log : build_sa_data.sql .build_sa_data_subsets.log $(OrganDysfunctionScores) $(OtherTargets)
	bq query < $< > $@

clean:
	bq query < clean.sql
	/bin/rm -f .*.log
