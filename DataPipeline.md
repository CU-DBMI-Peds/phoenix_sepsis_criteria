# Data Pipeline

General notes on how to run the data pipeline in **REDACTED**.

## The Pipeline

There are five major parts of the pipeline
1. Data import
2. Harmonization
3. timecourse
4. Specific Aims
5. Manuscript

* Specific Aims depends on the Timecourse and the Timecourse Depends on the
  Harmonization.

* The specific aims data built at the end of the timecourse pipeline is
  downloaded and processed on the **REDACTED** VM.  This means that changes to
  timecourse code/data will not impact the model training and assessment until
  the updated data is downloaded from GBQ to the VM.

* Each of the three sections of the pipeline need to be initiated explicitly.

### Data import
* Data from each of the sites is uploaded to GBQ with a generally consistent
  structure, e.g, an encounter table, a person table, an
  events/tests/observations table, ...

### Harmonization
* Takes raw data from the sites into a consistent schema.  This included mapping
  all the site specific versions of a test, lab, observation, medication, ...
  to a consistent name.

### Timecourse
* organize the data into encounter level time courses of events, tests,
  observations, etc.
* build organ dysfunction scores
* build the specific aims data sets
    * define subsets
    * define the max(organ dysfunction score) during a time window from
      hospital presentation, e.g., `psofa_cardiovascular_03_hour` is the
      highest `psofa_cardiovascular` score observed within the first three
      hours of the encounter.  If labs/observations/tests/medications, etc.
      are not available to inform the score, the default is assume a healthy
      value.
* Suspected infection is defined within the timecourse pipeline as a 0/1
  flag in the timecourse.  A value of 0 starts at eclock 0 (start of the
  encounter, eclock for "encounter clock") and remains 0 until two systemic
  does of antimicrobial medications are ordered and at least one test for
  infection has been ordered when the flag turns to 1 and remains 1 for the
  duration of the encounter.  Within the specific aims data, the values
  `suspected_infection_status_03_hour` is a 0/1, 0 if no suspected
  infection, and 1 if the suspected infection criteria was met within the
  first three hours of the encounter.

* All the data sets generated here are retained within Google Big Query and, in
  some cases, exported to cloud storage.

### Specific Aims

* The defined pipeline will download the needed data from GBQ to the VM.
* Checks for when to (re)train a model are:
    * If any of the expected output files do not exist then the model is
      (re)trained.
    * If all the expected output files exist and are younger than the data
      sources then the model will not be retrained. (Estimated Time: about 4
      seconds)
    * If all the expected output files exist and any one is older than the data
      sources then the data is read into memory and a sha of the data is found
      and compared to the data sha for the prior run.  If the new and old sha
      are the same then the model does not need to be retrained and all the
      output files are touched so that the next time the check for refit is
      needed the check will take less time as only file modification dates are
      needed to be checked. (Estimated time: about 30 seconds)
    * If all the expected output files exists, any one is older than the data,
      and the data sha check fails, then the model will be retrained.
      (Estimated time runs from 400 seconds to 4000+ seconds depending on the
      specific model specifications).

### Manuscript

* a subset of the analyses are reproduced within this directory to make it clear
  what is going into the manuscript.

## Interacting with the **REDACTED** VM

The following notes on how to interact with the **REDACTED** VM to for running the
whole or parts of the data pipeline. While not every step here is required,
following all these guidelines will make running the pipeline easier.

0. You will need to have authenticated and set up their profile to interact with
   GBQ.  This should have been done by running the script
   `<repo_root>/run_first_user_setup.R`.  There is a check in the harmonization
   pipeline to verify this has been done.

1. Log into the **REDACTED** virtual machine and open a terminal emulator.

2. Start a tmux session by executing the command
```sh
tmux
```
    * Recommend working in tmux as the tmux sessions will persist when your

      working on a **REDACTED** Desktop and have your session terminated losing any
      unsaved work and all open applications.  Working in the tmux session will
      allow you to get back to your work in a new desktop session.
    * To reattach to your last tmux session start tmux via
```sh
tmux a
```
    * Additional features of tmux can be found by reading the tmux manual or
      reference this [cheat sheet](https://tmuxcheatsheet.com/)

## Run the Harmonization Pipeline

1. Within the terminal emulator, navigate to the sepsis_lt repo under your user
   profile on the VM.

2. cd to `<repo_root>/harmonization`

3. execute the command
```sh
sh ./pipeline.sh
```

## Run the Timecourse Pipeline

1. Navigate to `<repo_root>/timecourse`
2. Run the pipeline via:
```sh
make -B -j 12
```

What does `make -B -j 12` mean?

* `make` is [GNU make](https://www.gnu.org/software/make/) and reads the
  commands defined in the `Makefile`. GNU make has been used to control this
  pipeline for several reasons:

   1. Explicitly define and control dependencies. Each organ system component score
       will rebuild if any of it's component parts have been modified, but will not
       rebuild if the component parts have not changed.  This is extremely
       helpful during development.
   2. GNU makes it easy to process disjoint commands in parallel.

* `-B`: this option forces a full rebuild.  While having only the needed sql
  script evaluated during development, there is no check out to GBQ to determine
  if the harmonized data has be modified.  So, when running the timecourse to
  update all values after the harmonization pipeline has run it is strongly
  recommended that make is called with the `-B` option.

* `-j 12`: the `-j` is short for `--jobs`, the number of parallel jobs.  `-j 12`
  tells GNU make to run 12 parallel jobs.  This will make the building process
  much faster and calling just `make -B`.  By default GNU make is a single
  thread process so everything runs in sequence.  `-j N` will run _up to_ N jobs
  in parallel.  It is easy to observe in this pipeline that only one job,
  foundation.sql, will run at first as it is a prerequisite for all other
  targets.  One that job has completed, as many as N jobs will start and run,
  with a new job starting as soon as a thread is freed up.  You may also notice
  when running this process that the number of active jobs will vary over time.
  It is recommended to run between 12 and 20 parallel jobs at a time.  If you
  run too many there can be errors from too many GBQ API calls within a given
  time window.

## Run the Specific Aims Pipeline

After the timecourse pipeline completes you can rerun the specific aims
pipeline.

0. This pipeline depends on GNU make version 4.3 or newer.  The timecourse
   pipeline works with considerably older versions of make so this was not an
   issue.  However, for the specific aims, as several of the scripts generate
**REDACTED**
   handle multiple target from the same recipe.  There is a check in the
   Makefile that will verify if you are using the correct version of make or not
   and there are instructions on how to active the needed version if you are not
   using the correct version of make. To active the needed version of make
   you'll need to enable

1. Navigate to `<repo_root>/specific_aims`

2. Execute the command
```sh
make
```

* IMPORTANT NOTES:

  * _DO NOT USE -j_ The pipeline process has been built to run a lot of models
    and model assessments in parallel.  The Makefile defines several system
    environmental variables to control the number of threads created. If you
    call multiple jobs, it is possible, that even with these variables set, too
    many threads will attempt, and then fail, to be allocated resulting a
    cascade of errors.  R might be a single threaded process, but the OPENBLAS
    linear algebra library and the OMP tools behind data.table and other R
    tools, are multithreaded.  Invoking too many parallel R calls without
    controlling the needed environmental variables will results in the system
    failing to allocate requested resources.

  * Conceptually, the parallelization advantages between the timecourse pipeline
    and the specific aims pipeline are very different.

    In the timecourse pipeline there are alot of explicitly defined targets
    which can be build in parallel as Make is able to sequence calls so that the
    needed prerequisites are updated in the correct order.

    On the other hand, training a lot of models, is a perfect parallel job that
    could be managed by make if all the targets could be defined a priori.
    While this is possible, the number of targets is extremely large and make
    can have problems with that.

    Further, make determines when to rebuild a target only based on the
    modification date of the prerequisites and the target.  In the model
    training and assessments, there are many times that the modificiation dates
    suggest a rebuild is needed, e.g., downloading new data.  However, say the
    new data only impacted the renal scores.  There would be no need to retrain
    the cardiovascular scores.  Make can't deal with this.

    The solution was to use GNU parallel to call the R scripts which determine
    when to retrain the models based on modification dates, and data hashes. The
    end result, a model that could take 4000 seconds to train will only take 30
    seconds to verify that there is no need to retrain becuase the data has not
    changed, and only 3 or 4 seconds to determine all the output files are up to
    date.

    The makefile process will call GNU parallel in sequence as needed.  By
    default, 50 jobs will run in parallel.  You can change this number, in this
    case, by using a bespoke command relevent to this makefile only.

      ```sh
      make PJOBS=100
      ```
    will run 100 parallel jobs.  I recommend not exceeding 100, 110 max, as the
    current VM will have too high of a cpu load and interactiveity will be
    difficult.

    I would recomend keeping on make call active and running in the background
    with 20 to 50 parallel jobs at all times and then envoking the make file to
    start the process again when updates are needed as needed.

  * To insure you have the most current specific aims data from GBQ run make
      with the -B flag.
  * If you have the pipeline running and need to stop it, from the command
      line type `crtl-c`

### Adding to the Specific Aims Pipeline

There are a lot of strata already defined.  At the time of writing this document
the team has been used to referring to specific subsets by a hash.  You can
add/omit training and assessment strata of interest in the
`build_high_value_targets.R` script.   Additionally, this is where you can
define sets of variables which are of high value too.  These variable lists must
consist of variables which have been defined upstream of the specific aims
pipeline.

If you do modify the `build_high_value_targets.R` scripts you need only to
(re)start the pipeline with make for the changes to take effect.

### Creating New Variables for Specific Aims Pipeline

First, what is the purpose of the variable?  Is it a variable used as part of
an existing or novel organ dysfunction score?  It is a variable used to identify
strata of data, e.g., demographics?

If the adding a new variable to define a new strata do the following:

1. build this new variable in the `./timecourse/foundation.sql` script
2. run the time course pipeline
3. define the new strata in `./specific_aims/build_strata.R`.  You'll see that
   you'll need to define all the wanted sub-setting strings for the variable and
   then add them to the cross joins used to define the training and/or
   sensitivity strata.
4. Evaluate this script (explicitly or by calling make)
5. To find the hash for a new strata to add to the high value targets you can
   either query the generated data.table of strata in an interactive R session
   or after building the new strata, refresh either the sa1 or sa2 shiny apps
   and query the strata tables there.
6. Add the new training and/or sensitivity hashes to `build_high_value_targets.R`
7. (re)start the specific aims pipeline

If adding a variable that is part of an existing or novel organ dysfunction
score

1. Define the variable in the timecourse pipeline

  a. Specific file: `<variable_name>.sql`

  b. Modify `./timecourse/Makefile` to build this variable

  c. Edit `./timecourse/build_sa_data.sql` to generate the `01_hour`, `03_hour`,
     `24_hour`, and 'ever' versions of the variable which will be columns in the
     exported specific aims data set.

  d. run the timecourse pipeline

2. Make the needed changes in the specific aims pipeline

  a. Verify/update logic in the function `define_organ_system` defined in the
     `utilities.R` script to map any new variables the correct organ system.

  b. Verify/updates logic in the function `define_scoring_system` defined in the
     `utilities.R` script.

  c. Edit `build_high_value_targets.R` to include this new variable as
     wanted/needed.

  d. (re)start the specific aims pipeline by calling `make -B` to make sure and
      download the current data set.

Alternatively, you could define a new variable based on the current specific
aims data within the `./specific_aims/build_predictors.R` script instead of
modifying the timecourse pipeline.  The edits to the specific aims pipeline
noted above will still need to take place.


