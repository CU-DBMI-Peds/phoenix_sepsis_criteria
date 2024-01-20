#standardSQL

CREATE OR REPLACE PROCEDURE **REDACTED**.medication.med_name_mapper(med_generic_name STRING)
BEGIN
  DECLARE aPREGEX ARRAY<STRING>;
  DECLARE aNREGEX ARRAY<STRING>;
  DECLARE sPREGEX STRING;
  DECLARE sNREGEX STRING;
  DECLARE sWHERE STRING;

  EXECUTE IMMEDIATE """
    SELECT ARRAY(SELECT regex FROM `**REDACTED**.medication.medications_to_curate` WHERE med_generic_name = @mgn AND use = 'include')
  """
  INTO aPREGEX
  USING med_generic_name AS mgn;

  EXECUTE IMMEDIATE """
    SELECT ARRAY(SELECT regex FROM `**REDACTED**.medication.medications_to_curate` WHERE med_generic_name = @mgn AND use = 'exclude')
  """
  INTO aNREGEX
  USING med_generic_name AS mgn;

  SET aPREGEX = ARRAY(SELECT CONCAT("REGEXP_CONTAINS(lower(med_name_source), r'", nb, "')") FROM UNNEST(aPREGEX) as nb);
  SET sPREGEX = ARRAY_TO_STRING(aPREGEX, " OR ");

  SET aNREGEX = ARRAY(SELECT CONCAT("REGEXP_CONTAINS(lower(med_name_source), r'", nb, "')") FROM UNNEST(aNREGEX) as nb);
  SET sNREGEX = ARRAY_TO_STRING(aNREGEX, " OR ");

  IF LENGTH(sNREGEX) = 0 THEN
    SET sWHERE = FORMAT("WHERE (%s)", sPREGEX);
  ELSE
    SET sWHERE = FORMAT("WHERE (%s) AND NOT (%s)", sPREGEX, sNREGEX);
  END IF;

  EXECUTE IMMEDIATE FORMAT("""
  INSERT medication.med_name_mapping (site, med_name_source, med_generic_name)
  SELECT site, med_name_source, '%s' AS med_generic_name
  FROM `**REDACTED**.medication.distinct_med_name_source`
  %s
  """, med_generic_name, sWHERE)
  ;
END;

/* -------------------------------------------------------------------------- */
                               -- END OF FILE --
/* -------------------------------------------------------------------------- */
