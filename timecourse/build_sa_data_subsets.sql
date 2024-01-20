#standardSQL
/*
Build Analysis Cohorts

Per section 3.3.2 of the Grant

> 3.3.2 Train/Test Datasets. We will randomly select 25% (>1.25 million ED and
>  >250,000 inpatient encounters, ~2,000 deaths) of the overall dataset to
> perform SA1. Because the organ dysfunction criteria we will validate in SA1
> already exist (Table 2), we do not need separate train and test datasets for
> SA1. Children with confirmed or suspected infection in the remaining 75%
> (>150,000 encounters with infection,  ~3,000 deaths + infection) will be used
> in SA2 (2/3 train, 1/3 test). To prevent leakage, we will ensure that all
> encounters for a given patient are in only one dataset. We will ensure a
> balanced distribution of LMIC versus HIC.

LMIC: low- and middle- income country
HIC: high income country

The approach that will be taken here - split the data within each site by
mortalities.

25% of _patients_ will go into the SA1 set, call this SA1

      / 25%  SA2g
75% ==  25%  SA2h
      \ 25%  SA2t


For Specific Aim 2:
* train the g-level models on the SA1 data
* train the h-level models on the SA1g data
* Assess the h-level models with SA2h data.  This will help select hyper
* parameters such as the penalty term lambda in the glmnet calls, or the alpha
* value mixing the ridge/lasso/elastic net
* SA2t is a hold out testing set

The code below might be a bit overkill but should insure that distribution of
sites and deaths (person level) will be on par with the whole cohort.

There is no way to set the random number generator see in GBQ.  So, to have a
random, yet reproducible splitting of the patients into the different data sets
we will do the following:

1. get the site, pat_id, and death (ever).
2. get the sha256 for each row in the table generated in step 1
3. sort the table by the sha256.
4. split the data by site and death status
5. first 25% of each split to sa1
6. second 25% of each split to sa2g
7. second 25% of each split to sa2h
8. second 25% of each split to sa2t

** IMPORTANT NOTE ** **REDACTED**, **REDACTED**, and **REDACTED** are to be excluded from this work and used as additional validation sets**
They are denoted in the sa_subset column as **REDACTED** and **REDACTED** respectfully.

**REDACTED**
data used to train the g-level models with be the SA1 data split.
SA2g will then be used to train the h-level models
SA2h will be used as a testing / assessment set for SA2 to help select hyper
parameters such as lambda (ridge/lasso penalty) and alpha (ridge/elastic
net/lasso)

*/

CREATE OR REPLACE TABLE `**REDACTED**.sa.patient_cohorts` AS
(
  WITH t0 AS
  (
    SELECT
        site
      , pat_id
      , MAX(death_during_encounter) AS death
    FROM `**REDACTED**.harmonized.death`
    GROUP BY site, pat_id
  )
  ,
  t1 AS
  (
    SELECT
        t0.site
      , t0.pat_id
      , t0.death
      , SHA256(CONCAT(t0.site, t0.pat_id, CAST(t0.death AS STRING), CAST(e.biennial_admission AS STRING))) AS sha256
      , e.biennial_admission
    FROM t0
    LEFT JOIN (SELECT pat_id, biennial_admission FROM `**REDACTED**.harmonized.encounters` WHERE final_enc = 1) e
    ON t0.pat_id = e.pat_id
  )
  ,
  sdn AS
  (
    SELECT
        site
      , biennial_admission
      , death
      , count(1) AS siteN
    FROM t1
    GROUP BY site, biennial_admission, death
  )
  ,
  t2 AS
  (
    SELECT
        *
      , SUM(1) OVER (PARTITION BY site, biennial_admission, death ORDER BY site, biennial_admission, death, sha256) as cN
    FROM t1
  )
  ,
  t3 AS
  (
    SELECT t2.*, t2.cN/sdn.siteN AS p
    FROM t2
    LEFT JOIN sdn
    ON t2.site = sdn.site AND t2.biennial_admission = sdn.biennial_admission AND t2.death = sdn.death
    ORDER BY site, biennial_admission, death, sha256
  )
  ,
  t4 AS
  (
    SELECT site, pat_id, biennial_admission, death, sha256,
      CASE
        WHEN site = "**REDACTED**" THEN "**REDACTED**"
        WHEN site = "**REDACTED**" THEN "**REDACTED**"
        WHEN site = "**REDACTED**" THEN "**REDACTED**"
        WHEN p < 0.25 THEN "SA1"
        WHEN p < 0.50 THEN "SA2g"
        WHEN p < 0.75 THEN "SA2h"
        ELSE "SA2t" END AS sa_subset
    FROM t3
  )

  SELECT
      *
    , count(1) OVER (PARTITION BY sa_subset ORDER BY site, biennial_admission, death, sha256) AS set_index
  FROM t4
);





-- Look to see if the relative percentages between the encounters table and
-- these splits are similar.
WITH T AS (
SELECT e.site, e.pat_id, e.biennial_admission, d.death
FROM (SELECT site, pat_id, biennial_admission FROM **REDACTED**.harmonized.encounters WHERE final_enc = 1) e
LEFT JOIN (
    SELECT
        site
      , pat_id
      , MAX(death_during_encounter) AS death
    FROM `**REDACTED**.harmonized.death`
    GROUP BY site, pat_id
  ) d
ON e.site = d.site AND e.pat_id = d.pat_id
)
,
ENC AS (
  SELECT *, N_patients / N AS P_patients
  FROM (
    SELECT
        site
      , biennial_admission
      , death
      , COUNT(pat_id) AS N_patients
    FROM T
    GROUP BY site, biennial_admission, death
    )
  LEFT JOIN (SELECT COUNT(1) AS N FROM T) ON TRUE
  ORDER BY site, biennial_admission, death
)
,
SA AS (
  SELECT a.*, N_patients / N AS P_patients
  FROM (
    SELECT
        sa_subset
      , site
      , biennial_admission
      , death
      , COUNT(pat_id) AS N_patients
    FROM **REDACTED**.sa.patient_cohorts
    GROUP BY sa_subset, site, biennial_admission, death
    ) a
  LEFT JOIN (SELECT sa_subset, COUNT(1) AS N FROM **REDACTED**.sa.patient_cohorts GROUP BY sa_subset) b
  ON a.sa_subset = b.sa_subset
  ORDER BY sa_subset, site, biennial_admission, death
)

SELECT
    SA.sa_subset
  , ENC.site
  , ENC.biennial_admission
  , ENC.death
  , ENC.N_patients AS N_ENCOUNTERS
  , SA.N_patients  AS N_SA
  , ENC.P_patients AS PERCENT_OF_ENCOUNTERS
  , SA.P_patients  AS PERCENT_OF_SA
FROM SA
LEFT JOIN ENC
ON SA.site = ENC.site AND
   SA.biennial_admission = ENC.biennial_admission AND
   SA.death = ENC.death
ORDER BY site, biennial_admission, death, sa_subset
;
