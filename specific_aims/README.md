# Specific Aims

The contents of this directory are intended to execute the analysis for each
specific aim.

## Shiny Apps for Reviewing results
There are, without exaggeration, hundreds of millions of models which have been
trained and assessed at some point during the summer of 2023.  To make it
possible to review all these models by a human, several Shiny Apps have been
built and deployed on a Shiny Server on the **REDACTED** NoMachine VM.

Open the app by opening a browser inside NoMachine and then navigating to
**REDACTED**.

## Specific Aim 1 (SA1)

Use `make` to build the data sets, download data, fit models, bootstrap the
models, and build the summary report.

## Specific Aim 2 (SA2)
Stacked Regression models

## Integer Sepsis Model
Making an easy to use integer scored assessment tool.


## Workflow

### Time course
In the ../timecourse directory are the sql scripts needed to build encounter
level data reporting the by the minute, at least by the known minute, the
events, observations, test, medications, etc. of each encounter.

* `../timecourse/build_sa_data_subsets.sql` splits the data into six sets,
  1. sa1  - data for specific aim 1  and training of g level models in SA2
  2. sa2g - "g-level" data for specific aim 2 - used to train h-levle models
  3. sa2h - "h-level" data for specific aim 2 - used to assses h-level models
  4. sa2t - "testing" data for specific aim 2 - hold out set
  5. **REDACTED** - old out set
  6. keyna - old out site

  See the comments in the script for details on how the sets are split up.

* `../timecourse/build_sa1_data.sql` builds the needed data set for all the sa1 analysis.

### Specific Aims

You can build everything via calling

```bash
make
```
