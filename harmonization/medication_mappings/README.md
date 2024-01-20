# Harmonization of Medications

Just type `make` in this directory to build all the tables, views, and build the
harmonized table.

Type `make -B` for force a full rebuild.

There are several routines (SQL PROCEDURES) defined for this work and these
procedures are defined in the `routines.sql` file.

## Routes
The reported medication routes have been mapped to FDA routes.  See the script
`med_route_mapping.sql` for specifics.

## Weights
Weights are needed for some of the medication units.  However, weight will not
be curated in the harmonization.  Use of the weight will be done in the
timecourse.


## Medication Names
All sites have provided a combination of generic medication names and brand
names.  It is important to know that the mapping of `med_name_source` to
`med_generic_name` is not 1-to-1. It is n-to-n as there are many entries in
`med_name_source` which will map to one `med_generic_name` and there are
combination medications such that one `med_name_source` will map to more than
one `med_generic_name`.

We have defined a procedure to help in the mapping.

Fill out the table: `med_names_to_harmonize` to define the medications to
curate, and the regular expressions to use to positively identify
`med_name_source` along with additional regular expression to omit some
`med_name_source` values which are captured by the namebrand regular
expressions.
