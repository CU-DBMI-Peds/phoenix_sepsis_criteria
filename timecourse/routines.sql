#standardSQL
-- -------------------------------------------------------------------------- --
           -- Define Procedures for inserting data into the tables --

-- The variables need to be summarized as the max observed value observed within
-- the first hour, first 3 hours, first 24 hours, or ever

-- IMPORTANT NOTE RE ISSUE 104
-- MAX(total) within a time period is <= MAX(component1) + MAX(component2) + ...  + MAX(componentn)
-- The explanation for this is documented here:   https://**REDACTED**/issues/90#issuecomment-1610759506
--
-- Simple example:
--
-- eclock  component1 component2 total
-- 5             0           2     2
-- 10            0           3     3
-- 15            1           1     2
--
-- In this case MAX(total) is 3, but MAX(component1) + MAX(compoent2) = 4
--
-- So, what is the definition of MAX within a time period?
--
-- MAX(total) = MAX(component1 + component2 + ... + componentn)  -- the current implimentation
--
-- OR
--
-- MAX(total) = MAX(component1) + MAX(component2) + ... + MAX(componentn)
--
-- The latter makes ahoc work with the sums of components in the data used to
-- train the models seem reasonable, but the former version seems more
-- reasonable for the how to summarize the data.
--
-- USE THE FIRST SUM PER DISCUSSION ON ISSUE 104 ON 8 July 2023

CREATE OR REPLACE PROCEDURE **REDACTED**.sa.aggregate(source_table STRING, source_column STRING)
BEGIN
  DECLARE v01 STRING;
  DECLARE v03 STRING;
  DECLARE v24 STRING;
  DECLARE v   STRING;
  DECLARE t   STRING;

  EXECUTE IMMEDIATE """
    SELECT data_type FROM `timecourse.INFORMATION_SCHEMA.COLUMNS`
    WHERE column_name = '""" || source_column || """' AND
          table_name  = '""" || source_table  || """'
  """
  INTO t
  ;

  IF t = "INT64" THEN
    SET t = "integer";
  ELSEIF t = "FLOAT64" THEN
    SET t = "float";
  END IF;


  SET v01 = regexp_replace(source_column, r'_min$', '') || '_01_hour';
  SET v03 = regexp_replace(source_column, r'_min$', '') || '_03_hour';
  SET v24 = regexp_replace(source_column, r'_min$', '') || '_24_hour';
  SET v   = regexp_replace(source_column, r'_min$', '');

  -- remove old values
  -- DO NOT DO THIS HERE --
  -- INSERT can be serialized, but the delete statements cannot.  run make clean
  -- then build the whole timecourse to make sure that the correct data is in
  -- the sa.integer_valued_predictors and sa.float_valued_predictors is upto
  -- date.

  --EXECUTE IMMEDIATE """
  --  DELETE FROM **REDACTED**.sa.""" || t || """_valued_predictors
  --  WHERE variable in ('""" || v01 || """', '""" || v03 || """', '""" || v24 || """', '""" || v || """')
  --"""
  --;

  -- insert new values
  EXECUTE IMMEDIATE """
    INSERT **REDACTED**.sa.""" || t || """_valued_predictors (site, enc_id, variable, value, write_datetime)
    SELECT
        site
      , enc_id
      , '""" || v01 || """' AS variable
      , MAX(t.""" || source_column || """) AS value
      , current_datetime() AS write_datetime
    FROM **REDACTED**.timecourse.""" || source_table || """ t
    WHERE eclock >= 0 AND eclock < 60
    GROUP BY site, enc_id
  """
  ;

  EXECUTE IMMEDIATE """
    INSERT **REDACTED**.sa.""" || t || """_valued_predictors (site, enc_id, variable, value, write_datetime)
    SELECT
        site
      , enc_id
      , '""" || v03 || """' AS variable
      , MAX(t.""" || source_column || """) AS value
      , current_datetime() AS write_datetime
    FROM **REDACTED**.timecourse.""" || source_table || """ t
    WHERE eclock >= 0 AND eclock < 60 * 3
    GROUP BY site, enc_id
  """
  ;

  EXECUTE IMMEDIATE """
    INSERT **REDACTED**.sa.""" || t || """_valued_predictors (site, enc_id, variable, value, write_datetime)
    SELECT
        site
      , enc_id
      , '""" || v24 || """' AS variable
      , MAX(t.""" || source_column || """) AS value
      , current_datetime() AS write_datetime
    FROM **REDACTED**.timecourse.""" || source_table || """ t
    WHERE eclock >= 0 AND eclock < 60 * 24
    GROUP BY site, enc_id
  """
  ;

  EXECUTE IMMEDIATE """
    INSERT **REDACTED**.sa.""" || t || """_valued_predictors (site, enc_id, variable, value, write_datetime)
    SELECT
        site
      , enc_id
      , '""" || v || """' AS variable
      , MAX(t.""" || source_column || """) AS value
      , current_datetime() AS write_datetime
    FROM **REDACTED**.timecourse.""" || source_table || """ t
    WHERE eclock >= 0
    GROUP BY site, enc_id
  """
  ;
END
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
