#standardSQL

/*
 * Condition(s) defined by
 *
 * Georgette N, Keskey R, Mbadiwe N, Hampton D, McQueen A, Slidell MB.
 * Alternative shock index cutoffs for pediatric patients outperform the Shock
 * Index Pediatric Age-adjusted (SIPA) on strength of association with adverse
 * outcomes in pediatric trauma patients. Surgery. 2022 Jul;172(1):343-348. doi:
 * 10.1016/j.surg.2022.01.028. Epub 2022 Feb 21. PMID: 35210102.
 *
 *
 * McCormick T, Haukoos J, Hopkins E, Trent S, Adelgais K, Cohen M, Gausche-Hill
 * M. Adding age-adjusted shock index to the American College of Surgeons'
 * trauma team activation criteria to predict severe injury in children. Journal
 * of trauma and acute care surgery. 2023 Feb 1;94(2):295-303.
 *
 *
 * Acker SN, Ross JT, Partrick DA, Tong S, Bensard DD. Pediatric specific shock
 * index accurately identifies severely injured children. Journal of pediatric
 * surgery. 2015 Feb 1;50(2):331-4.
 *
 * Rousseaux J, Grandbastien B, Dorkenoo A, Lampin ME, Leteurtre S, Leclerc F.
 * Prognostic value of shock index in children with septic shock. Pediatric
 * emergency care. 2013 Oct 1;29(10):1055-9.
 *
 * Acker provides SIPA
 * McCormick provides lower end for PALS, also reports SIPA.  See Table 1 on pg 296
 * Georgette provides PALS, ATLS, SIPA (see table 1 in that manuscript)
 *
 * Rousseaux et.al. (2013) is the paper cited in the grant
*/



CREATE OR REPLACE TABLE `**REDACTED**.timecourse.shock_index` AS (

  WITH t0 AS
  (
    SELECT
        a.site
      , a.enc_id
      , a.eclock
      , a.age_years
      , b.pulse
      , c.sbp
      , d.crt_prolonged_3
    FROM `**REDACTED**.timecourse.foundation` a
    LEFT JOIN `**REDACTED**.timecourse.pulse` b
    ON a.site = b.site AND a.enc_id = b.enc_id AND a.eclock = b.eclock
    LEFT JOIN `**REDACTED**.timecourse.bloodpressure` c
    ON a.site = c.site AND a.enc_id = c.enc_id AND a.eclock = c.eclock
    LEFT JOIN `**REDACTED**.timecourse.crt_prolonged` d
    ON a.site = d.site AND a.enc_id = d.enc_id AND a.eclock = d.eclock
  )
  ,
  t1 AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , age_years
      , pulse
      , pulse / NULLIF(sbp, 0) AS shock_index
      , crt_prolonged_3
    FROM t0
    WHERE pulse IS NOT NULL AND sbp IS NOT NULL
  )
  ,
  t2 AS
  (
    SELECT site, enc_id, eclock,
      CASE
        WHEN (                    age_years <  3 AND shock_index >= 2.1) THEN 1
        WHEN (age_years >=  3 AND age_years <  6 AND shock_index >= 1.9) THEN 1
        WHEN (age_years >=  6 AND age_years < 13 AND shock_index >= 1.5) THEN 1
        WHEN (age_years >= 13 AND age_years < 18 AND shock_index >= 1.1) THEN 1
        WHEN (age_years >= 18                                          ) THEN NULL
        ELSE 0 END AS shock_index_atls
      ,
      CASE
        WHEN (                    age_years <   1 AND shock_index >= 2.5) THEN 1
        WHEN (age_years >=  1 AND age_years <   3 AND shock_index >= 1.6) THEN 1
        WHEN (age_years >=  3 AND age_years <   6 AND shock_index >= 1.3) THEN 1
        WHEN (age_years >=  6 AND age_years <  12 AND shock_index >= 1.2) THEN 1
        WHEN (age_years >= 12                     AND shock_index >= 0.9) THEN 1
        ELSE 0 END AS shock_index_pals
      ,
      CASE
        WHEN (                    age_years <  7 AND shock_index > 1.22) THEN 1
        WHEN (age_years >=  7 AND age_years < 13 AND shock_index > 1.0) THEN 1
        WHEN (age_years >= 13                    AND shock_index > 0.9) THEN 1
        ELSE 0 END as shock_index_sipa
      ,
      CASE
        WHEN (                    age_years <  1 AND shock_index >= 2.30) THEN 1
        WHEN (age_years >=  1 AND age_years <  2 AND shock_index >= 1.90) THEN 1
        WHEN (age_years >=  2 AND age_years <  5 AND shock_index >= 1.75) THEN 1
        WHEN (age_years >=  5 AND age_years < 12 AND shock_index >= 1.30) THEN 1
        WHEN (age_years >= 12                    AND shock_index >= 1.00) THEN 1
        ELSE 0 END as shock_index_rousseaux
      ,
      CASE
        WHEN (                    age_years <  1 AND pulse > 180 AND crt_prolonged_3 = 1) THEN 1
        WHEN (age_years >=  1 AND age_years <  6 AND pulse > 160 AND crt_prolonged_3 = 1) THEN 1
        WHEN (age_years >=  6 AND age_years < 13 AND pulse > 150 AND crt_prolonged_3 = 1) THEN 1
        WHEN (age_years >= 13 AND age_years < 18 AND pulse > 130 AND crt_prolonged_3 = 1) THEN 1
        ELSE 0 END as shock_index_who
    FROM t1
  )

  SELECT
      t0.site
    , t0.enc_id
    , t0.eclock

    , COALESCE(t2.shock_index_atls, 0) AS shock_index_atls_min
    , COALESCE(t2.shock_index_pals, 0) AS shock_index_pals_min
    , COALESCE(t2.shock_index_sipa, 0) AS shock_index_sipa_min
    , COALESCE(t2.shock_index_rousseaux, 0) AS shock_index_rousseaux_min
    , COALESCE(t2.shock_index_who, 0) AS shock_index_who_min

    , t2.shock_index_atls AS shock_index_atls
    , t2.shock_index_pals AS shock_index_pals
    , t2.shock_index_sipa AS shock_index_sipa
    , t2.shock_index_rousseaux AS shock_index_rousseaux
    , t2.shock_index_who AS shock_index_who

    , COALESCE(t2.shock_index_atls, 1) AS shock_index_atls_max
    , COALESCE(t2.shock_index_pals, 1) AS shock_index_pals_max
    , COALESCE(t2.shock_index_sipa, 1) AS shock_index_sipa_max
    , COALESCE(t2.shock_index_rousseaux, 1) AS shock_index_rousseaux_max
    , COALESCE(t2.shock_index_who, 1) AS shock_index_who_max
  FROM t0
  LEFT JOIN t2
  ON t0.site = t2.site AND t0.enc_id = t2.enc_id AND t0.eclock = t2.eclock
)
;

CALL **REDACTED**.sa.aggregate("shock_index", "shock_index_atls_min");
CALL **REDACTED**.sa.aggregate("shock_index", "shock_index_pals_min");
CALL **REDACTED**.sa.aggregate("shock_index", "shock_index_sipa_min");
CALL **REDACTED**.sa.aggregate("shock_index", "shock_index_rousseaux_min");
CALL **REDACTED**.sa.aggregate("shock_index", "shock_index_who_min");
