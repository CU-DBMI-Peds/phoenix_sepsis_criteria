SA_PREREQS  = ../specific_aims/utilities.R
SA_PREREQS += ../specific_aims/utilities2.R
SA_PREREQS += **REDACTED**/specific_aims/high_value_list.rds
SA_PREREQS += **REDACTED**/specific_aims/**REDACTED**_data.feather
SA_PREREQS += **REDACTED**/specific_aims/**REDACTED**_data.feather
SA_PREREQS += **REDACTED**/specific_aims/**REDACTED**_data.feather
SA_PREREQS += **REDACTED**/specific_aims/predictors.feather
SA_PREREQS += **REDACTED**/specific_aims/SA1_data.feather
SA_PREREQS += **REDACTED**/specific_aims/SA2g_data.feather
SA_PREREQS += **REDACTED**/specific_aims/SA2h_data.feather
SA_PREREQS += **REDACTED**/specific_aims/SA2t_data.feather
SA_PREREQS += **REDACTED**/specific_aims/sensitivity_strata.feather
SA_PREREQS += **REDACTED**/specific_aims/training_strata.feather

TABLES  = outcome_summary_table.csv
TABLES += cohort_summary_whole_data_set.csv
TABLES += cohort_summary_suspected_infection_1dose.csv

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

all : check_version individual_subscore_summaries.Rout $(TABLES) stacked_model_summaries.Rout missingness_HIC_1dose.Rout missingness_LMIC_1dose.Rout venn_diagrams.Rout sensitivity_precision_plots.Rout

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

outcome_summary_table.csv cohort_summary_whole_data_set.csv cohort_summary_suspected_infection_1dose.csv &: cohort_summary_tables.R $(SA_PREREQS)
	R CMD BATCH --vanilla $< $@

missingness_LMIC_1dose.Rout : missingness.R
	R CMD BATCH --vanilla '--args LMIC_1dose' $< $@

missingness_HIC_1dose.Rout : missingness.R
	R CMD BATCH --vanilla '--args HIC_1dose' $< $@

venn_diagrams.Rout : venn_diagrams.R **REDACTED**_R01_data.R ../specific_aims/utilities.R
	R CMD BATCH --vanilla $< $@

sensitivity_precision_plots.Rout : sensitivity_precision_plots.R **REDACTED**_R01_data.R ../specific_aims/utilities.R
	R CMD BATCH --vanilla $< $@

%.Rout : %.R $(SA_PREREQS)
	R CMD BATCH --vanilla $< $@

individual_subscore_summaries.Rout : individual_subscore_summaries.R individual_subscore_summaries_data_prep.Rout
	R CMD BATCH --vanilla $< $@


clean:
	/bin/rm -f *.Rout
	/bin/rm -f *.csv
	/bin/rm -f *.feather
