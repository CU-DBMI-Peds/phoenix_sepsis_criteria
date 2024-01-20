# TimeCourse

Objective - create a set of tables to record the time course of each medication,
test, event, lab, etc., needed for the organ dysfunction scores and/or of
interest in the care of the patient.

## Table Structures

There are three basic table formats to build

### Foundation

**REDACTED**.timecourse.foundation is, as the name implies, the foundational
table for the timecourse work. This table has all the static values, e.g.,
gender, admit age, pccc, and _all_ the distinct eclock (time in minuetes from
hospital presentation) for all the test/labs/events/medications of interest.

This table is used as _the_ left join target for build other time courses.

### Tests, Labs, Events, Medications, etc.

For the test/labs/events/medications the tables should be of the form:

        +------+--------+--------+-------------+--------+
        | site | enc_id | eclock | <name>_time | <name> |
        +------+--------+--------+-------------+--------+

Where <name> denotes the test/lab/eveent/medication, etc.  The eclock is the
time, in minutes, from hospital presentation, and the <name>_time is the last
known time for the value, e.g.,


        +------+--------+--------+-------------+--------+
        | site | enc_id | eclock | <name>_time | <name> |
        +------+--------+--------+-------------+--------+
        |  A   |  a1    |   0    | NULL        | NULL   |
        |  A   |  a1    |  10    | 10          | x      |
        |  A   |  a1    |  12    | 10          | x      |
        |  A   |  a1    |  20    | 20          | y      |

In this case the first known value is ten minutes into the encounter.  That
value of x is carried forwared at time 12, when some other
test/lab/event/medication value was observed, and then a new value, y, is
reported twenty minutes into the encouter.

This structure will help with any analysis where the age of an obesvered value
is of concern.

### Organ Dysfunction Scores

Each organ dysfucntion score, and subscore, are build in their own tables with
the general structure of :

        +------+--------+--------+-------------+--------+-------------+
        | site | enc_id | eclock | <score>_min | <score>| <score>_max |
        +------+--------+--------+-------------+--------+-------------+
        |  A   |  a1    |   0    | 0           | NULL   |    4        |
        |  A   |  a1    |  10    | 0           | NULL   |    4        |
        |  A   |  a1    |  12    | 2           | 2      |    2        |
        |  A   |  a1    |  20    | 2           | 2      |    2        |

Here the <score> is the _known_ value.  It is NULL when any of the needed input
tests, labs, medications, etc. are unknown.  The <score>_min is the min value
for the score, which is either the same and the known score or set to 0.  The
<score>_max is the max value for the score if <score> is NULL, else it is equal
to <score>  The reason for the three cases is so we can explore the impacts of
missing data at the beginning of an encounter.

## Workflow

The construction of the timecourse data set is controled by the Makefile in this
directory.  All the dependencies for each score is documented therein.  You can
build the whole timecourse data set with ease by simply typing

```sh
cd <repo_root>/timecouse
make
```

You can save a lot of time by seending parallel jobs:

```sh
make -j8  # send eight parallel jobs
```

You can force a full rebuild at any time by
```sh
make -B
```

Find out what is out of date and will be rebuilt:
```sh
make -n
```

If you have a target you know you don't want to update but make wants to
```sh
touch <target>
```

Or, especially after a merge, you might find

```sh
make -t
```

useful as it touches all targets instead of a rebuild.

Say you wanted to rebuild only the dic table after a merge:
```sh
make -t
touch dic.sql
make
```
## Key Files

* foundation.sql
  - builds the table with patient and encounter level variables over eclock and
    eclock_bin onto which other tables should be joined for evenetual modeling.

## Variables

* admit_weight
  - units: KG
  - built in the file weight.sql
  - this is the weight as recored nearist admission (eclock 0) but no more than
    1440 minutes (24 hours) into the admission.

* age_days, age_months, age_years, admit_age_days, admit_age_months, admit_age_year
  - units: days or months based on the variable name.
  - admit_age_days defined from the encounter table and part of the build_timecourse_foundation.sql
  - age_days and ade_months are generated in age.sql

* alc, alc_time
  - Units: 10E3/UL
  - built in the file alc.sql
  - LOCF

* alt, alt_time
  - Units: U/L
  - built in the file alt.sql
  - LOCF

* anc, anc_time
  - Units: 10E3/UL
  - built in the file anc.sql
  - LOCF

* ast, ast_time
  - Units: U/L
  - built in the file ast.sql
  - LOCF

* baseline_creatinine
  - built in foundation.sql
  - average between Male and Female is used if gender is not Male or Female.
    This is tradeoff for having gender and not sex.

* bilirubin_tot, bilirubin_tot_time
  - units: MG/DL
  - built in bilirubin_tot.sql
  - LOCF

* bun, bun_time
  - blood urea nitrogen
  - units: MG/DL
  - LOCF
  - built in bun.sql

* creatinine, creatinine_time
  - Units: MG/DL
  - built in file creatinine.sql
  - LOCF

* crrt, crrt_time
  - No units
  - built in file crrt.sql
  - 1 if present and LOCF
  - set crrt = 0 after LOCF to indicate crrt has not started.
  - TODO: 13 Jan 2023 - When does CRRT End?

* crt_prolonged
  - Aka "Capillary refill time" Can be central or peripheral
  - units: >= X seconds (source value converted to boolean)
  - built in file crt_prolonged.sql
  - LOCF

* dbp_art, dbp_art_time, dbp_cuff, dbp_cuff_time, sbp_art, sbp_art_time, sbp_cuff, sbp_cuff_time, map_art, map_art_time, map_cuff, map_cuff_time
  - Units: MMHG
  - built in file bloodpressure.sql
  - LOCF

* dbp, dbp_time, sbp, sbp_time, map, map_time (mean artial pressure)
  - Units: MMHG
  - built in file bloodpressure.sql
  - Preferentially arterial pressure over cuff pressure

* d_dimer, d_dimer_time
  - units: MG/L FEU
  - built in d_dimer.sql
  - LOCF

* dobutamine, dobutamine_time
  - units: mcg/kg/min
  - built in dobutamine.sql
  - LOCF with leading 0s

* dopamine, dopamine_time
  - units: mcg/kg/min
  - built in dopamine.sql
  - LOCF with leading 0s

* ecmo, ecmo_va, ecmo_vv, ecmo_time
  - no units
  - binary indicators
  - built in file ecmo.sql
  - ecmo_time is for all three ecmo variables
  - ecmo = 1 is equivent to event_value in (TRUE, VA, VV)

* epap_niv, epap_niv_time
  - Units: CMH2O
  - built in file epap_niv.sql
  - LOCF with leading 0s

* epinephrine, epinephrine_time
  - units: mcg/kg/min
  - built in epinephrine.sql
  - LOCF with leading 0s

* fibrinogen, fibrinogen_time
  - units: MG/DL
  - built in fibrinogen.sql
  - LOCF

* fio2, fio2_time
  - Units: %
  - built in fio2.sql
  - LOCF, 21 is the default for any missing values after LOCF

* gcs_total, gcs_motor, gcs_eye, gcs_verbal, gcs_total_time, gcs_motor_time, gcs_eye_time, gcs_verbal_time
  - no units,
  - built in gcs.sql
  - LOCF
  - TODO: NOCB?, healthy default?

* ggt, ggt_time
  - Units: U/L
  - built in the file ggt.sql
  - LOCF

* hgb, hgb_time
  - units: G/DL
  - hemoglobin
  - built in hemoglobin.sql
  - LOCF

* hppv, hppv_time
  - indicator
  - built in hppv.sql
  - requires epap_niv, o2_flow, weight

* inr, inr_time
  - units: none
  - built in inr.sql

* lactate
  - units: MMOL/L
  - built in lactate.sql
  - LOCF

* map_vent, map_vent_time, map_hfov, map_hfov_time
  - units: CMH2O
  - aka: map_hfov is also paw
  - LOCF
  - vent.sql

* norepinephrine, norepinephrine_time
  - units: mcg/kg/min
  - built in epinephrine.sql
  - LOCF with leading 0s

* o2_flow, o2_flow_time
  - units: L/MIN
  - built in o2_flow.sql
  - LOCF

* oi, oi_time
  - built in oi.sql
  - requires paw (map_hfov), fio2, pao2

* osi, osi_time
  - built in osi.sql
  - requires paw (map_hfov), fio2, spo2

* pao2, pao2_time
  - Units:  MMHG
  - aka: PO2_ART
  - built in pao2.sql
  - LOCF

* pccc_*
  - no units
  - aka: pediatric complex chronic conditions
  - part of the build_timecourse_foundation.sql script

* platelets, platelets_time
  - Platelets
  - Units: 10E3/UL
  - built in platelets.sql
  - LOCF

* pulse, pulse_time
  - units: BPM
  - aka: heart rate
  - built in pulse.sql
  - LOCF

* pupil, pupil_time
  - no units
  - built in pupil.sql
  - values: "both-reactive" "both-fixed" or "at least one-fixed"

* psofa
  - built in files psofa_*.sql
  - components and total

* pt, pt_time
  - units: SECONDS
  - built in pt.sql
  - LOCF

* ptt, ptt_time
  - units: SECONDS
  - built in ptt.sql
  - LOCF

* respiratory_rate, respiratory_rate_time
  - units: breaths per minute (BRPM)
  - built in respiratory_rate.sql
  - LOCF

* serum_ph
  - blood serum pH
  - built in serum_ph.sql
  - LOCF

* shock_index
  - built in shock_index.sql
  - no units, a floating point value, pulse/sbp

* spo2, spo2_time
  - Units: ... (expected to be in %)
  - aka: pulse_ox
  - built in spo2.sql
  - LOCF

* urine
  - Source unites: ml; converted to ml/kg/hr
  - built in urine.sql which relies on urine_6hr.sql and urine_12hr.sql. 6hr and 12hr are built from weights_and_urine.sql which is partially derived from weight.sql
  - No carry forward/no imputation
  - If no patient weight documented, cannot calculate urine rate; No urine observations are assumed to mean no urine output.

* vent, vent_time
  - units: 1/0 indicator, if map_vent or map_hfov is greater than 0
  - built in vent.sql
  - LOCF

* vis
  - Vasoactive-Inotropic Score
  - built in vis.sql

* wbc, wbc_time
  - units: 10E3/UL
  - aka: white blood cell count
  - built in wbc.sql

* weight, weight_time
  - units: KG
  - built in the file weight.sql
  - LOCF
