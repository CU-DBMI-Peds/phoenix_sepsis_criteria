#standardSQL
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.medication_admin` AS
(
  WITH
  base AS
    (
        SELECT
          site
        , enc_id
        , med_name_source
        , med_route_source
        , med_dose_source
        , SAFE_CAST(med_dose_source AS FLOAT64) AS med_dose
        , med_dose_units_source
        , LOWER(TRIM(med_dose_units_source)) AS med_dose_units
        , med_ordered_time_source
        , med_admin_time_source
        , COALESCE(SAFE_CAST(med_admin_time_source AS INTEGER), SAFE_CAST(med_ordered_time_source AS INTEGER)) AS med_admin_time
        , med_admin_action_source
        FROM `**REDACTED**.full.medication_admin`
    ),
  routes AS
    (
      SELECT *
      FROM `**REDACTED**.medication.med_route_mapping`
    ),
  names AS
    (
      SELECT *
      FROM `**REDACTED**.medication.med_name_mapping`
    )

  SELECT DISTINCT
      base.*
    , routes.med_fda_route
    , routes.systemic
    , names.med_generic_name
    , m2c.med_set
    , m2c.med_subset
  FROM base
  LEFT JOIN routes
  ON base.med_route_source = routes.med_route_source
  LEFT JOIN names
  ON base.med_name_source = names.med_name_source
  LEFT join `**REDACTED**.medication.medications_to_curate` m2c
  ON names.med_generic_name = m2c.med_generic_name

)
;

-- -------------------------------------------------------------------------- --
DELETE FROM `**REDACTED**.harmonized.medication_admin`
WHERE lower(med_admin_action_source) IN (
    "automatically held"
  , "canceled entry"
  , "held"
  , "held by provider"
  , "label provided to patient"
  , "label varificiation"
  , "not given"
  , "st not given"
)
;

-- -------------------------------------------------------------------------- --
--                                END OF FILE                                 --
-- -------------------------------------------------------------------------- --
