.PHONY: all clean med_name_mapping

all : .checks.log

.harmonize_medications.log : harmonize_medications.sql .med_route_mapping.log .med_name_mapping.log
	bq query < $< > $@

.clean_up_routes.log : clean_up_routes.sql .harmonize_medications.log
	bq query < $< > $@

.clean_up_dose.log : clean_up_dose.sql .clean_up_routes.log .harmonize_medications.log
	bq query < $< > $@

.checks.log : checks.sql .clean_up_routes.log .clean_up_dose.log
	bq query < $< > $@

med_name_mapping : .routines.log .create_distinct_med_name_source_table.log .upload_medications_to_curate.log
	rm -f .med_name_mapping.log
	bq query " CREATE OR REPLACE TABLE **REDACTED**.medication.med_name_mapping AS ( SELECT CAST(NULL AS STRING) AS site , CAST(NULL AS STRING) AS med_name_source , CAST(NULL AS STRING) AS med_generic_name LIMIT 0);"
	tail -n +2 medications_to_curate.csv | cut -d',' -f1 | sort | uniq | parallel --bar -j12 --joblog med_name_mapper_parallel.log --resume-failed --kill now,fail=1 bq query "CALL **REDACTED**.medication.med_name_mapper\(\'{}\'\)" >> .med_name_mapping.log

.med_route_mapping.log : med_route_mapping.sql .upload_fda_route_of_administration.log
	bq query < $< > $@

.%.log : %.sql
	bq query < $< > $@

.upload_medications_to_curate.log : medications_to_curate.csv
	bq load\
		--replace\
		--skip_leading_rows=1\
		--source_format=CSV\
		**REDACTED**:medication.medications_to_curate\
		medications_to_curate.csv\
		'med_generic_name:string, regex:string, use:string, med_set:string, med_subset:string' > $@

.upload_fda_route_of_administration.log : fda_route_of_administration.csv
	bq load\
		--replace\
		--skip_leading_rows=1\
		--source_format=CSV\
		**REDACTED**:medication.fda_route_of_administration\
		fda_route_of_administration.csv\
		'NAME:string, DEFINITION:string, SHORT_NAME:string, FDA_CODE:string, NCI_CONCEPT_ID:string' > $@

clean :
	bq query < clean.sql
	/bin/rm -f .*.log
	/bin/rm -f *.log
