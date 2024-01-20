#standardSQL

-- -------------------------------------------------------------------------- --
                -- build the **REDACTED**.sa.sa data set --
-- Start with a distinct site and enc_id from the timecourse foundation table

CREATE OR REPLACE TABLE `**REDACTED**.sa.sa` AS
(
  SELECT DISTINCT
      tc.site
    , tc.biennial_admission
    , tc.pat_id
    , tc.admit_age_months
    , tc.gender
    , tc.male
    , tc.race
    , tc.ethnicity
    , tc.enc_id
    , tc.death
    , tc.pccc_congeni_genetic
    , tc.pccc_cvd
    , tc.pccc_gi
    , tc.pccc_hemato_immu
    , tc.pccc_malignancy
    , tc.pccc_metabolic
    , tc.pccc_neuromusc
    , tc.pccc_neonatal
    , tc.pccc_renal
    , tc.pccc_respiratory
    , tc.pccc_tech_dep
    , tc.pccc_transplant
    , tc.pccc_congeni_genetic + tc.pccc_cvd         + tc.pccc_gi        + tc.pccc_hemato_immu +
      tc.pccc_malignancy      + tc.pccc_metabolic   + tc.pccc_neuromusc + tc.pccc_neonatal    +
      tc.pccc_renal           + tc.pccc_respiratory + tc.pccc_tech_dep  + tc.pccc_transplant    AS pccc_count
    , tc.ever_icu
    , tc.ever_ed
    , tc.ever_ip
    , tc.ever_operation
    , tc.los
    , s.sa_subset
    , CASE WHEN smn.admit_weight_for_age_zscore IS NULL THEN NULL
           WHEN smn.admit_weight_for_age_zscore < -3 THEN 1
           ELSE 0 END AS severe_malnutrition
  FROM (SELECT * FROM `**REDACTED**.timecourse.foundation` WHERE eclock >= 0) tc
  LEFT JOIN (SELECT DISTINCT site, pat_id, sa_subset FROM `**REDACTED**.sa.patient_cohorts`) s
  ON tc.site = s.site AND tc.pat_id = s.pat_id
  LEFT JOIN (SELECT DISTINCT site, enc_id, admit_weight_for_age_zscore FROM `**REDACTED**.timecourse.weight_for_age_zscore`) smn
  ON tc.site = smn.site AND tc.enc_id = smn.enc_id
)
;

-- --------------------------------------------------------------------------
-- get the most recient entry in the integer_valued_predictors and
-- float_valued_predictors tables
CREATE OR REPLACE TABLE **REDACTED**.sa.integer_valued_predictors AS
(
  SELECT
      site
    , enc_id
    , variable
    , MAX_BY(value, write_datetime) AS value
    , MAX(write_datetime) AS write_datetime
  FROM **REDACTED**.sa.integer_valued_predictors
  GROUP BY site, enc_id, variable
)
;

CREATE OR REPLACE TABLE **REDACTED**.sa.float_valued_predictors AS
(
  SELECT
      site
    , enc_id
    , variable
    , MAX_BY(value, write_datetime) AS value
    , MAX(write_datetime) AS write_datetime
  FROM **REDACTED**.sa.float_valued_predictors
  GROUP BY site, enc_id, variable
)
;

-- -------------------------------------------------------------------------- --
-- Pivot the predictor table and join onto the sa.sa table
BEGIN
  DECLARE v1 STRING;
  DECLARE v2 STRING;
  SET v1 = (SELECT CONCAT('("', STRING_AGG(DISTINCT variable, '", "'), '")'), FROM `**REDACTED**.sa.integer_valued_predictors`);
  SET v2 = (SELECT CONCAT('("', STRING_AGG(DISTINCT variable, '", "'), '")'), FROM `**REDACTED**.sa.float_valued_predictors`);

  EXECUTE IMMEDIATE format("""
  CREATE OR REPLACE TABLE `**REDACTED**.sa.sa` AS
  (
    WITH T1 AS (
      SELECT * FROM
      (
        SELECT site, enc_id, variable, value
        FROM `**REDACTED**.sa.integer_valued_predictors`
      )
      PIVOT
      (
        MAX(value)
        FOR variable in %s
      )
    )
    ,
    T2 AS (
      SELECT * FROM
      (
        SELECT site, enc_id, variable, value
        FROM `**REDACTED**.sa.float_valued_predictors`
      )
      PIVOT
      (
        MAX(value)
        FOR variable in %s
      )
    )
    SELECT a.*, T1.*EXCEPT(site,enc_id), T2.*EXCEPT(site,enc_id)
    FROM `**REDACTED**.sa.sa` a
    LEFT JOIN T1
    ON a.site = T1.site AND a.enc_id = T1.enc_id
    LEFT JOIN T2
    ON a.site = T2.site AND a.enc_id = T2.enc_id
  )
  """, v1, v2);
END;


-- -------------------------------------------------------------------------- --
                                 -- outcomes --

-- death (ever) already part of the data set
-- ecmo (ever)
-- early death (within 72 hours)
-- ECMO or Death
-- ECMO or Early Death

CREATE OR REPLACE TABLE `**REDACTED**.sa.sa` AS
(
  WITH early_ecmo AS
  (
    SELECT enc_id, IF(MAX(ecmo) > 0, 1, 0) AS early_ecmo
    FROM `**REDACTED**.timecourse.ecmo`
    WHERE (eclock >= 0) AND (eclock < 72 * 60) AND (ecmo = 1)
    GROUP BY enc_id
  )
  ,
  ecmo AS
  (
    SELECT enc_id, IF(MAX(ecmo) > 0, 1, 0) AS ecmo
    FROM `**REDACTED**.timecourse.ecmo`
    WHERE ecmo = 1
    GROUP BY enc_id
  )
  ,
  early_death AS
  (
    SELECT enc_id, IF(MAX(death) > 0, 1, 0) AS early_death
    FROM `**REDACTED**.timecourse.foundation`
    WHERE los < 72 * 60
    GROUP BY enc_id
  )
  , t AS
  (
  SELECT
      f.enc_id
    , f.death
    , COALESCE(ed.early_death, 0) AS early_death
    , COALESCE(ee.early_ecmo, 0) AS early_ecmo
    , COALESCE(e.ecmo, 0) AS ecmo

    FROM `**REDACTED**.timecourse.foundation` f
    LEFT JOIN early_death ed
    ON f.enc_id = ed.enc_id
    LEFT JOIN early_ecmo ee
    ON f.enc_id = ee.enc_id
    LEFT JOIN ecmo e
    ON f.enc_id = e.enc_id
  )
  SELECT DISTINCT
      a.*
    , t.early_death
    , t.early_ecmo
    , t.ecmo
    , IF(t.ecmo + t.death > 0, 1, 0) AS ecmo_or_death
    , IF(t.ecmo + t.early_death > 0, 1, 0) AS ecmo_or_early_death
    , IF(t.ecmo + t.death = 2, 1, 0) AS ecmo_and_death
    , IF(t.ecmo + t.early_death = 2, 1, 0) AS ecmo_and_early_death
    , IF(t.early_ecmo + t.death > 0, 1, 0) as early_ecmo_or_death
    , IF(t.early_ecmo + t.early_death > 0, 1, 0) as early_ecmo_or_early_death
    , IF(t.early_ecmo + t.death = 2, 1, 0) as early_ecmo_and_death
    , IF(t.early_ecmo + t.early_death > 2, 1, 0) as early_ecmo_and_early_death
  FROM `**REDACTED**.sa.sa` a
  LEFT JOIN t
  ON a.enc_id = t.enc_id
);

-- -------------------------------------------------------------------------- --
--                       integer lasso related outcomes                       --
-- -------------------------------------------------------------------------- --
-- There are two approaches that could be used for this.  see discussion
-- on https://**REDACTED**/issues/90
--
-- option 1
-- Require suspected_infection and integer_lasso_sepsis_total >= 3 to occur
-- simultaneously within the noted time from hospital presentation
-- , IF(MAX(integer_lasso_sepsis_total_1dose_min)  >= 3, 1, 0) AS integer_lasso_sepsis_1dose_geq3_24_hour
-- , IF(MAX(integer_lasso_sepsis_total_2doses_min) >= 3, 1, 0) AS integer_lasso_sepsis_2doses_geq3_24_hour
-- FROM `**REDACTED**.timecourse.integer_lasso_sepsis_total`
--
-- option 2
-- integer_lasso_sepsis_1dose_geq3_24_hour will be true if
-- suspected_infection_1dose is 1 any time within the window AND
-- max(integer_lasso_sepsis_total_1dose_min) >= 3 at any time within the window.
--
-- **REDACTED**
-- **REDACTED**
CREATE OR REPLACE PROCEDURE **REDACTED**.sa.join_on_integer_lasso_outcomes(HOURS STRING)
BEGIN
  DECLARE QUERY_STRING  string;
  DECLARE QUERY_STRING1 string;
  DECLARE QUERY_STRING2 string;
  DECLARE MIN_SCORE INT64;
  DECLARE MAX_SCORE INT64;
  DECLARE CURRENT_SCORE INT64;

  SET MIN_SCORE=1;
  SET MAX_SCORE=6;


  SET QUERY_STRING1 = "";
  SET QUERY_STRING2 = "";
  SET CURRENT_SCORE = MIN_SCORE;
  LOOP
    IF CURRENT_SCORE > MAX_SCORE THEN LEAVE; END IF;
    SET QUERY_STRING1 = (SELECT CONCAT(
          QUERY_STRING1
        , ", IF((MAX(lst.integer_lasso_sepsis_total_min) >= ", CAST(CURRENT_SCORE AS STRING), "), 1, 0) AS integer_lasso_sepsis_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "

        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv1_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv1_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv2_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv2_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv3_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv3_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv4_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv4_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv5_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv5_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_cv6_min) >= ", CAST(CURRENT_SCORE AS STRING), ") , 1, 0) AS integer_lasso_sepsis_cv6_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "

        , ", IF((MAX(lst.integer_lasso_sepsis_total_min) >= ", CAST(CURRENT_SCORE AS STRING), ") AND (MAX(si.suspected_infection_0dose)  > 0), 1, 0) AS integer_lasso_sepsis_0dose_geq",  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_min) >= ", CAST(CURRENT_SCORE AS STRING), ") AND (MAX(si.suspected_infection_1dose)  > 0), 1, 0) AS integer_lasso_sepsis_1dose_geq",  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(lst.integer_lasso_sepsis_total_min) >= ", CAST(CURRENT_SCORE AS STRING), ") AND (MAX(si.suspected_infection_2doses) > 0), 1, 0) AS integer_lasso_sepsis_2doses_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "

        , ", MAX(IF(lst.integer_lasso_sepsis_total_min >=   ", CAST(CURRENT_SCORE AS STRING), " AND lst.integer_lasso_sepsis_total_min = lsr.integer_lasso_sepsis_respiratory_min, 1, 0)) AS integer_lasso_sepsis_respiratory_only_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", MAX(IF(lst.integer_lasso_sepsis_total_min >=   ", CAST(CURRENT_SCORE AS STRING), " AND lst.integer_lasso_sepsis_total_min = lsn.integer_lasso_sepsis_neurologic_min, 1, 0))  AS integer_lasso_sepsis_neurologic_only_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "

        , ", IF(MAX( "
        , "    IF((lst.integer_lasso_sepsis_total_min >= ", CAST(CURRENT_SCORE AS STRING), ") AND "
        , "       (lst.integer_lasso_sepsis_total_min <> lsr.integer_lasso_sepsis_respiratory_min) AND "
        , "       (lst.integer_lasso_sepsis_total_min <> lsn.integer_lasso_sepsis_neurologic_min), 1, 0)) > 0, 1, 0) "
        , "   AS integer_lasso_sepsis_remote_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF(MAX( "
        , "   IF((lst.integer_lasso_sepsis_total_min >= ", CAST(CURRENT_SCORE AS STRING), ") AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsr.integer_lasso_sepsis_respiratory_min) AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsn.integer_lasso_sepsis_neurologic_min), 1, 0)) > 0 "
        , "   AND MAX(si.suspected_infection_0dose > 0) , 1, 0) "
        , "   AS integer_lasso_sepsis_remote_0dose_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF(MAX( "
        , "   IF((lst.integer_lasso_sepsis_total_min >= ", CAST(CURRENT_SCORE AS STRING), ") AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsr.integer_lasso_sepsis_respiratory_min) AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsn.integer_lasso_sepsis_neurologic_min), 1, 0)) > 0 "
        , "   AND MAX(si.suspected_infection_1dose > 0) , 1, 0) "
        , "   AS integer_lasso_sepsis_remote_1dose_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF(MAX( "
        , "   IF((lst.integer_lasso_sepsis_total_min >= ", CAST(CURRENT_SCORE AS STRING), ") AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsr.integer_lasso_sepsis_respiratory_min) AND "
        , "      (lst.integer_lasso_sepsis_total_min <> lsn.integer_lasso_sepsis_neurologic_min), 1, 0)) > 0 "
        , "   AND MAX(si.suspected_infection_2doses > 0) , 1, 0) "
        , "   AS integer_lasso_sepsis_remote_2doses_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", IF((MAX(ps.possible_sepsis_resp_min) >= ",  CAST(CURRENT_SCORE AS STRING), "), 1, 0) AS possible_sepsis_resp_geq",  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour"
        , ", IF((MAX(ps.possible_sepsis_neuro_min) >= ", CAST(CURRENT_SCORE AS STRING), "), 1, 0) AS possible_sepsis_neuro_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour"
        , ", IF((MAX(ps.possible_sepsis_cv_min) >= ",    CAST(CURRENT_SCORE AS STRING), "), 1, 0) AS possible_sepsis_cv_geq",    CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour"
        , ", IF((MAX(ps.possible_sepsis_total_min) >= ", CAST(CURRENT_SCORE AS STRING), "), 1, 0) AS possible_sepsis_geq",       CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour"
      ));
    SET QUERY_STRING2 = (SELECT CONCAT(
          QUERY_STRING2
        , ", COALESCE(t.integer_lasso_sepsis_geq",                  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_geq",                  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv1_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv1_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv2_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv2_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv3_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv3_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv4_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv4_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv5_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv5_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_cv6_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_cv6_geq",              CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_respiratory_only_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_respiratory_only_geq", CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_neurologic_only_geq",  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_neurologic_only_geq",  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_0dose_geq",            CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_0dose_geq",            CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_1dose_geq",            CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_1dose_geq",            CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_2doses_geq",           CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_2doses_geq",           CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_remote_geq",           CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_remote_geq",           CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_remote_0dose_geq",     CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_remote_0dose_geq",     CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_remote_1dose_geq",     CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_remote_1dose_geq",     CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.integer_lasso_sepsis_remote_2doses_geq",    CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS integer_lasso_sepsis_remote_2doses_geq",    CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.possible_sepsis_resp_geq",                  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS possible_sepsis_resp_geq",                  CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.possible_sepsis_neuro_geq",                 CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS possible_sepsis_neuro_geq",                 CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.possible_sepsis_cv_geq",                    CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS possible_sepsis_cv_geq",                    CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
        , ", COALESCE(t.possible_sepsis_geq",                       CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour, 0) AS possible_sepsis_geq",                       CAST(CURRENT_SCORE AS STRING), "_", HOURS, "_hour "
      ));
    SET CURRENT_SCORE = CURRENT_SCORE + 1;
  END LOOP;

  SET QUERY_STRING = (SELECT CONCAT(
      "CREATE OR REPLACE TABLE **REDACTED**.sa.sa AS "
      ,"( "
      , "with t AS "
      , "( "
      , "SELECT si.enc_id "
      , QUERY_STRING1
      , " FROM **REDACTED**.timecourse.suspected_infection si "
      , "LEFT JOIN **REDACTED**.timecourse.integer_lasso_sepsis_total lst "
      , "ON si.site = lst.site AND si.enc_id = lst.enc_id AND si.eclock = lst.eclock "
      , "LEFT JOIN **REDACTED**.timecourse.integer_lasso_sepsis_respiratory lsr "
      , "ON si.site = lsr.site AND si.enc_id = lsr.enc_id AND si.eclock = lsr.eclock "
      , "LEFT JOIN **REDACTED**.timecourse.integer_lasso_sepsis_neurologic lsn "
      , "ON si.site = lsn.site AND si.enc_id = lsn.enc_id AND si.eclock = lsn.eclock "
      , "LEFT JOIN **REDACTED**.timecourse.possible_sepsis ps "
      , "ON si.site = ps.site AND si.enc_id = ps.enc_id AND si.eclock = ps.eclock "
      , "WHERE si.eclock >= 0 AND si.eclock < ", HOURS, " * 60 "
      , "GROUP BY si.enc_id "
      , ") "
      , "SELECT a.* "
      , QUERY_STRING2
      , "FROM **REDACTED**.sa.sa a "
      , "LEFT JOIN t "
      , "ON a.enc_id = t.enc_id "
      , ");"
  ));

  EXECUTE IMMEDIATE QUERY_STRING;

END
;

CALL **REDACTED**.sa.join_on_integer_lasso_outcomes("03");
CALL **REDACTED**.sa.join_on_integer_lasso_outcomes("24");
CALL **REDACTED**.sa.join_on_integer_lasso_outcomes("48");
CALL **REDACTED**.sa.join_on_integer_lasso_outcomes("72");

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
