LOGS  = check_version
LOGS += high_value_sa2.log
LOGS += high_value_sa1.log

.PHONY: all clean check_version
.PRECIOUS:

PJOBS=$1
ifeq ($(PJOBS),)
	PJOBS=50
endif

MEMFREE=$2
ifeq ($(MEMFREE),)
	MEMFREE=100G
endif

all : check_version .sa_strata **REDACTED**/specific_aims/extrapolation_checks.rds $(LOGS)

interim_reports :
	$(MAKE) -C ../interim_reports

check_version:
	@sh ../gcs_setup.sh
ifeq (4.3, $(firstword $(sort $(MAKE_VERSION) 4.3)))
	@echo "This is make $(MAKE_VERSION)"
else
	@echo "*****************************************************"
	@echo "*** You need to use make version 4.3 or higher    ***"
	@echo "*** on **REDACTED** you can get the needed version via: ***"
	@echo "*** source /opt/rh/devtoolset-11/enable           ***"
	@echo "*****************************************************"
	@exit 1
endif

**REDACTED**/specific_aims/extrapolation_checks.rds : extrapolation_checks.R utilities.R **REDACTED**/specific_aims/predictors.feather **REDACTED**/specific_aims/sensitivity_strata.feather **REDACTED**/specific_aims/high_value_list.rds
	Rscript $<

high_value_sa1.log : export OPENBLAS_NUM_THREADS=1
high_value_sa1.log : export OMP_NUM_THREADS=1
high_value_sa1.log : export R_DATATABLE_NUM_THREADS=1
high_value_sa1.log : **REDACTED**/specific_aims/high_value_list.rds **REDACTED**/specific_aims/SA1_data.feather utilities.R sa1.R sa1_model_assessments.R sa1_organ_system_summaries.R
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_model_calls1.log < high_value_sa1_model_calls1.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_assessment_calls1.log < high_value_sa1_assessment_calls1.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_organ_system_summary_calls1.log < high_value_sa1_organ_system_summary_calls1.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_model_calls2.log < high_value_sa1_model_calls2.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_assessment_calls2.log < high_value_sa1_assessment_calls2.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_organ_system_summary_calls2.log < high_value_sa1_organ_system_summary_calls2.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_model_calls3.log < high_value_sa1_model_calls3.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_assessment_calls3.log < high_value_sa1_assessment_calls3.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa1_organ_system_summary_calls3.log < high_value_sa1_organ_system_summary_calls3.txt
	@touch $@

high_value_sa2.log : export OPENBLAS_NUM_THREADS=1
high_value_sa2.log : export OMP_NUM_THREADS=1
high_value_sa2.log : export R_DATATABLE_NUM_THREADS=1
high_value_sa2.log : **REDACTED**/specific_aims/high_value_list.rds **REDACTED**/specific_aims/SA1_data.feather **REDACTED**/specific_aims/SA2g_data.feather **REDACTED**/specific_aims/SA2h_data.feather **REDACTED**/specific_aims/SA2t_data.feather utilities.R sa2g.R sa2h.R sa2t.R
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa2g.log < high_value_sa2g.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa2h1.log < high_value_sa2h1.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa2t1.log < high_value_sa2t1.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa2h2.log < high_value_sa2h2.txt
	parallel --memfree $(MEMFREE) --jobs $(PJOBS) --bar --shuf --joblog high_value_sa2t2.log < high_value_sa2t2.txt
	@touch $@

**REDACTED**/specific_aims/high_value_list.rds : build_high_value_targets.R utilities.R **REDACTED**/specific_aims/predictors.feather **REDACTED**/specific_aims/training_strata.feather **REDACTED**/specific_aims/sensitivity_strata.feather
	Rscript $<

.sa_strata : build_sa_strata.R **REDACTED**/specific_aims/high_value_list.rds
	Rscript $<
	@touch $@

**REDACTED**/specific_aims/training_strata.feather\
	**REDACTED**/specific_aims/sensitivity_strata.feather\
	&: build_strata.R **REDACTED**/specific_aims/predictors.feather **REDACTED**/specific_aims/.download.log utilities.R
	Rscript --vanilla --quiet $<

**REDACTED**/specific_aims/SA1_data.feather\
	**REDACTED**/specific_aims/SA2g_data.feather\
	**REDACTED**/specific_aims/SA2h_data.feather\
	**REDACTED**/specific_aims/SA2t_data.feather\
	**REDACTED**/specific_aims/predictors.feather\
	&: build_predictors.R **REDACTED**/specific_aims/.download.log utilities.R
	Rscript --vanilla --quiet $<

**REDACTED**/specific_aims/.download.log : **REDACTED**/specific_aims/.build_sa_data.log
	/bin/rm -f **REDACTED**/specific_aims/*.csv
	bq query "EXPORT DATA OPTIONS ( uri = 'gs://**REDACTED**/specific_aims_data/*.csv', format = 'CSV', overwrite = true, header = true, field_delimiter = ',') AS ( SELECT * FROM **REDACTED**.sa.sa);"
	gsutil -m cp gs://**REDACTED**/specific_aims_data/*.csv **REDACTED**/specific_aims/
	gsutil -m rm -f "gs://**REDACTED**/specific_aims_data/*.csv"
	@touch $@

clean:
	/bin/rm -f .*.log
	/bin/rm -f *.log
	/bin/rm -f *.txt
	/bin/rm -f .sa_strata
