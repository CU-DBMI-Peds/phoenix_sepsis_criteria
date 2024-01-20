#standardSQL
-- -------------------------------------------------------------------------- --
                          -- General Dose Cleaning --
-- -------------------------------------------------------------------------- --
-- Set dose to NULL if value is less than zero.  We want to keep all the meds
-- incase we need just a binary exposed/unexposed
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = NULL
WHERE med_dose < 0
;

-- -------------------------------------------------------------------------- --
                        -- General Dose Unit Cleaning --
-- -------------------------------------------------------------------------- --
-- set transform the dose, and the dose units in general for some meds.  This
-- is done, for example, to get the unit of time to all be minutes instead of a
-- mix of hours and minutes.
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose_units = "mcg"
WHERE med_set = "vasoactive"
  AND med_dose_units = "microgram"
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose_units = REGEXP_REPLACE(med_dose_units, r"unit\(s\)", "units")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"unit\(s\)")
;

-- convert hour to minutes
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose * 1 / 60
  , med_dose_units = REGEXP_REPLACE(med_dose_units, r"\/hr", "/min")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"\/hr")
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose * 1 / 60
  , med_dose_units = REGEXP_REPLACE(med_dose_units, r"\/hour", "/min")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"\/hour")
;

-- nano grams to mcg
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose * 0.001
  , med_dose_units = REGEXP_REPLACE(med_dose_units, r"^ng", "mcg")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"^ng")
;

-- unify milliunits
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose_units = REGEXP_REPLACE(med_dose_units, r"^milli-units\/", "milliunits/")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"^milli-units\/")
;

UPDATE `**REDACTED**.harmonized.medication_admin`
-- GBQ DOES NOT SUPPORT NEGATIVE LOOK AHEAD
-- SET med_dose_units = REGEXP_REPLACE(med_dose_units, r"^milliunit(?!s)", "milliunits")
SET med_dose_units = REGEXP_REPLACE(med_dose_units, r"^milliunit\/", "milliunits/")
WHERE med_set = "vasoactive"
-- AND REGEXP_CONTAINS(med_dose_units, r"^milliunit(?!s)")
  AND REGEXP_CONTAINS(med_dose_units, r"^milliunit\/")
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose / 1000
  , med_dose_units = "units/min"
WHERE med_dose_units = "milliunits/min"
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose / 1000
  , med_dose_units = "units/kg/min"
WHERE med_dose_units = "milliunits/kg/min"
;

-- convert mg to mcg
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = med_dose * 1000
  , med_dose_units = REGEXP_REPLACE(med_dose_units, r"^mg", "mcg")
WHERE med_set = "vasoactive"
  AND REGEXP_CONTAINS(med_dose_units, r"^mg")
;

---- -------------------------------------------------------------------------- --
--                    -- Extract dose from med_name_source --
------------------------------------------------------------------------------- --
UPDATE `**REDACTED**.harmonized.medication_admin`
SET
    med_dose =
      CASE
        WHEN med_name_source LIKE "%[0.005 mcg/kg/min]%"  THEN   0.005
        WHEN med_name_source LIKE "%[0.006 mcg/kg/min]%"  THEN   0.006
        WHEN med_name_source LIKE "%[0.007 mcg/kg/min]%"  THEN   0.007
        WHEN med_name_source LIKE "%[0.0075 mcg/kg/min]%" THEN   0.0075
        WHEN med_name_source LIKE "%[0.01 mcg/kg/min]%"   THEN   0.01
        WHEN med_name_source LIKE "%[0.011 mcg/kg/min]%"  THEN   0.011
        WHEN med_name_source LIKE "%[0.012 mcg/kg/min]%"  THEN   0.012
        WHEN med_name_source LIKE "%[0.0128 mcg/kg/min]%" THEN   0.0128
        WHEN med_name_source LIKE "%[0.013 mcg/kg/min]%"  THEN   0.013
        WHEN med_name_source LIKE "%[0.014 mcg/kg/min]%"  THEN   0.014
        WHEN med_name_source LIKE "%[0.015 mcg/kg/min]%"  THEN   0.015
        WHEN med_name_source LIKE "%[0.016 mcg/kg/min]%"  THEN   0.016
        WHEN med_name_source LIKE "%[0.017 mcg/kg/min]%"  THEN   0.017
        WHEN med_name_source LIKE "%[0.0175 mcg/kg/min]%" THEN   0.0175
        WHEN med_name_source LIKE "%[0.02 mcg/kg/min]%"   THEN   0.02
        WHEN med_name_source LIKE "%[0.021 mcg/kg/min]%"  THEN   0.021
        WHEN med_name_source LIKE "%[0.025 mcg/kg/min]%"  THEN   0.025
        WHEN med_name_source LIKE "%[0.03 mcg/kg/min]%"   THEN   0.03
        WHEN med_name_source LIKE "%[0.035 mcg/kg/min]%"  THEN   0.035
        WHEN med_name_source LIKE "%[0.036 mcg/kg/min]%"  THEN   0.036
        WHEN med_name_source LIKE "%[0.04 mcg/kg/min]%"   THEN   0.04
        WHEN med_name_source LIKE "%[0.045 mcg/kg/min]%"  THEN   0.045
        WHEN med_name_source LIKE "%[0.05 mcg/kg/min]%"   THEN   0.05
        WHEN med_name_source LIKE "%[0.06 mcg/kg/min]%"   THEN   0.06
        WHEN med_name_source LIKE "%[0.065 mcg/kg/min]%"  THEN   0.065
        WHEN med_name_source LIKE "%[0.07 mcg/kg/min]%"   THEN   0.07
        WHEN med_name_source LIKE "%[0.075 mcg/kg/min]%"  THEN   0.075
        WHEN med_name_source LIKE "%[0.08 mcg/kg/min]%"   THEN   0.08
        WHEN med_name_source LIKE "%[0.09 mcg/kg/min]%"   THEN   0.09
        WHEN med_name_source LIKE "%[0.1 mcg/kg/min]%"    THEN   0.10
        WHEN med_name_source LIKE "%[0.11 mcg/kg/min]%"   THEN   0.11
        WHEN med_name_source LIKE "%[0.12 mcg/kg/min]%"   THEN   0.12
        WHEN med_name_source LIKE "%[0.13 mcg/kg/min]%"   THEN   0.13
        WHEN med_name_source LIKE "%[0.14 mcg/kg/min]%"   THEN   0.14
        WHEN med_name_source LIKE "%[0.15 mcg/kg/min]%"   THEN   0.15
        WHEN med_name_source LIKE "%[0.152 mcg/kg/min]%"  THEN   0.152
        WHEN med_name_source LIKE "%[0.16 mcg/kg/min]%"   THEN   0.16
        WHEN med_name_source LIKE "%[0.17 mcg/kg/min]%"   THEN   0.17
        WHEN med_name_source LIKE "%[0.175 mcg/kg/min]%"  THEN   0.175
        WHEN med_name_source LIKE "%[0.18 mcg/kg/min]%"   THEN   0.18
        WHEN med_name_source LIKE "%[0.19 mcg/kg/min]%"   THEN   0.19
        WHEN med_name_source LIKE "%[0.1 mcg/kg/min]%"    THEN   0.10
        WHEN med_name_source LIKE "%[0.1235 mcg/kg/min]%" THEN   0.1235
        WHEN med_name_source LIKE "%[0.125 mcg/kg/min]%"  THEN   0.125
        WHEN med_name_source LIKE "%[0.145 mcg/kg/min]%"  THEN   0.145
        WHEN med_name_source LIKE "%[0.2 mcg/kg/min]%"    THEN   0.20
        WHEN med_name_source LIKE "%[0.21 mcg/kg/min]%"   THEN   0.21
        WHEN med_name_source LIKE "%[0.22 mcg/kg/min]%"   THEN   0.22
        WHEN med_name_source LIKE "%[0.23 mcg/kg/min]%"   THEN   0.23
        WHEN med_name_source LIKE "%[0.24 mcg/kg/min]%"   THEN   0.24
        WHEN med_name_source LIKE "%[0.25 mcg/kg/min]%"   THEN   0.25
        WHEN med_name_source LIKE "%[0.26 mcg/kg/min]%"   THEN   0.26
        WHEN med_name_source LIKE "%[0.27 mcg/kg/min]%"   THEN   0.27
        WHEN med_name_source LIKE "%[0.28 mcg/kg/min]%"   THEN   0.28
        WHEN med_name_source LIKE "%[0.2858 mcg/kg/min]%" THEN   0.2858
        WHEN med_name_source LIKE "%[0.29 mcg/kg/min]%"   THEN   0.29
        WHEN med_name_source LIKE "%[0.3 mcg/kg/min]%"    THEN   0.30
        WHEN med_name_source LIKE "%[0.31 mcg/kg/min]%"   THEN   0.31
        WHEN med_name_source LIKE "%[0.32 mcg/kg/min]%"   THEN   0.32
        WHEN med_name_source LIKE "%[0.33 mcg/kg/min]%"   THEN   0.33
        WHEN med_name_source LIKE "%[0.34 mcg/kg/min]%"   THEN   0.34
        WHEN med_name_source LIKE "%[0.35 mcg/kg/min]%"   THEN   0.35
        WHEN med_name_source LIKE "%[0.36 mcg/kg/min]%"   THEN   0.36
        WHEN med_name_source LIKE "%[0.37 mcg/kg/min]%"   THEN   0.37
        WHEN med_name_source LIKE "%[0.38 mcg/kg/min]%"   THEN   0.38
        WHEN med_name_source LIKE "%[0.39 mcg/kg/min]%"   THEN   0.39
        WHEN med_name_source LIKE "%[0.4 mcg/kg/min]%"    THEN   0.40
        WHEN med_name_source LIKE "%[0.41 mcg/kg/min]%"   THEN   0.41
        WHEN med_name_source LIKE "%[0.42 mcg/kg/min]%"   THEN   0.42
        WHEN med_name_source LIKE "%[0.43 mcg/kg/min]%"   THEN   0.43
        WHEN med_name_source LIKE "%[0.44 mcg/kg/min]%"   THEN   0.44
        WHEN med_name_source LIKE "%[0.45 mcg/kg/min]%"   THEN   0.45
        WHEN med_name_source LIKE "%[0.5 mcg/kg/min]%"    THEN   0.50
        WHEN med_name_source LIKE "%[0.55 mcg/kg/min]%"   THEN   0.55
        WHEN med_name_source LIKE "%[0.56 mcg/kg/min]%"   THEN   0.56
        WHEN med_name_source LIKE "%[0.57 mcg/kg/min]%"   THEN   0.57
        WHEN med_name_source LIKE "%[0.58 mcg/kg/min]%"   THEN   0.58
        WHEN med_name_source LIKE "%[0.59 mcg/kg/min]%"   THEN   0.59
        WHEN med_name_source LIKE "%[0.6 mcg/kg/min]%"    THEN   0.60
        WHEN med_name_source LIKE "%[0.65 mcg/kg/min]%"   THEN   0.65
        WHEN med_name_source LIKE "%[0.68 mcg/kg/min]%"   THEN   0.68
        WHEN med_name_source LIKE "%[0.7 mcg/kg/min]%"    THEN   0.70
        WHEN med_name_source LIKE "%[0.75 mcg/kg/min]%"   THEN   0.75
        WHEN med_name_source LIKE "%[0.8 mcg/kg/min]%"    THEN   0.80
        WHEN med_name_source LIKE "%[0.85 mcg/kg/min]%"   THEN   0.85
        WHEN med_name_source LIKE "%[0.9 mcg/kg/min]%"    THEN   0.90
        WHEN med_name_source LIKE "%[0.95 mcg/kg/min]%"   THEN   0.95
        WHEN med_name_source LIKE "%[1 mcg/kg/min]%"      THEN   1.00
        WHEN med_name_source LIKE "%[1.1 mcg/kg/min]%"    THEN   1.10
        WHEN med_name_source LIKE "%[1.15 mcg/kg/min]%"   THEN   1.15
        WHEN med_name_source LIKE "%[1.2 mcg/kg/min]%"    THEN   1.20
        WHEN med_name_source LIKE "%[1.25 mcg/kg/min]%"   THEN   1.25
        WHEN med_name_source LIKE "%[1.3 mcg/kg/min]%"    THEN   1.30
        WHEN med_name_source LIKE "%[1.4 mcg/kg/min]%"    THEN   1.40
        WHEN med_name_source LIKE "%[1.5 mcg/kg/min]%"    THEN   1.50
        WHEN med_name_source LIKE "%[1.6 mcg/kg/min]%"    THEN   1.60
        WHEN med_name_source LIKE "%[1.7 mcg/kg/min]%"    THEN   1.70
        WHEN med_name_source LIKE "%[1.8 mcg/kg/min]%"    THEN   1.80
        WHEN med_name_source LIKE "%[1.9 mcg/kg/min]%"    THEN   1.90
        WHEN med_name_source LIKE "%[2 mcg/kg/min]%"      THEN   2.00
        WHEN med_name_source LIKE "%[2.5 mcg/kg/min]%"    THEN   2.50
        WHEN med_name_source LIKE "%[3 mcg/kg/min]%"      THEN   3.00
        WHEN med_name_source LIKE "%[3.125 mcg/kg/min]%"  THEN   3.125
        WHEN med_name_source LIKE "%[3.5 mcg/kg/min]%"    THEN   3.50
        WHEN med_name_source LIKE "%[4 mcg/kg/min]%"      THEN   4.00
        WHEN med_name_source LIKE "%[4.19 mcg/kg/min]%"   THEN   4.19
        WHEN med_name_source LIKE "%[5 mcg/kg/min]%"      THEN   5.00
        WHEN med_name_source LIKE "%[5.5 mcg/kg/min]%"    THEN   5.50
        WHEN med_name_source LIKE "%[6 mcg/kg/min]%"      THEN   6.00
        WHEN med_name_source LIKE "%[7 mcg/kg/min]%"      THEN   7.00
        WHEN med_name_source LIKE "%[7.5 mcg/kg/min]%"    THEN   7.50
        WHEN med_name_source LIKE "%[8 mcg/kg/min]%"      THEN   8.00
        WHEN med_name_source LIKE "%[8.9 mcg/kg/min]%"    THEN   8.90
        WHEN med_name_source LIKE "%[9 mcg/kg/min]%"      THEN   9.00
        WHEN med_name_source LIKE "%[9.5 mcg/kg/min]%"    THEN   9.50
        WHEN med_name_source LIKE "%[10 mcg/kg/min]%"     THEN  10.00
        WHEN med_name_source LIKE "%[11 mcg/kg/min]%"     THEN  11.00
        WHEN med_name_source LIKE "%[12 mcg/kg/min]%"     THEN  12.00
        WHEN med_name_source LIKE "%[12.5 mcg/kg/min]%"   THEN  12.50
        WHEN med_name_source LIKE "%[13 mcg/kg/min]%"     THEN  13.00
        WHEN med_name_source LIKE "%[14 mcg/kg/min]%"     THEN  14.00
        WHEN med_name_source LIKE "%[15 mcg/kg/min]%"     THEN  15.00
        WHEN med_name_source LIKE "%[16 mcg/kg/min]%"     THEN  16.00
        WHEN med_name_source LIKE "%[17 mcg/kg/min]%"     THEN  17.00
        WHEN med_name_source LIKE "%[18 mcg/kg/min]%"     THEN  18.00
        WHEN med_name_source LIKE "%[19 mcg/kg/min]%"     THEN  19.00
        WHEN med_name_source LIKE "%[20 mcg/kg/min]%"     THEN  20.00
        WHEN med_name_source LIKE "%[25 mcg/kg/min]%"     THEN  25.00
        WHEN med_name_source LIKE "%[111 mcg/kg/min]%"    THEN 111.00
      ELSE med_dose
      END
  , med_dose_units = "mcg/kg/min"
WHERE med_set = "vasoactive"
  AND med_name_source LIKE "%[% mcg/kg/min]%"
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = 0.03
  , med_dose_units = "mcg/min"
WHERE med_set = "vasoactive"
  AND med_name_source = "epinephrine 0.9 mg [0.03 mcg/min] + d10w 30 ml"
;

-- units per kg per hr to units per kg per min:
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose =
    CASE
      WHEN med_name_source LIKE "%[0.0001 units/kg/hr]%" THEN 0.0001 / 60
      WHEN med_name_source LIKE "%[0.0002 units/kg/hr]%" THEN 0.0002 / 60
      WHEN med_name_source LIKE "%[0.0003 units/kg/hr]%" THEN 0.0003 / 60
      WHEN med_name_source LIKE "%[0.0004 units/kg/hr]%" THEN 0.0004 / 60
      WHEN med_name_source LIKE "%[0.0005 units/kg/hr]%" THEN 0.0005 / 60
      WHEN med_name_source LIKE "%[0.0006 units/kg/hr]%" THEN 0.0006 / 60
      WHEN med_name_source LIKE "%[0.0007 units/kg/hr]%" THEN 0.0007 / 60
      WHEN med_name_source LIKE "%[0.0008 units/kg/hr]%" THEN 0.0008 / 60
      WHEN med_name_source LIKE "%[0.0009 units/kg/hr]%" THEN 0.0009 / 60
      WHEN med_name_source LIKE "%[0.001 units/kg/hr]%"  THEN 0.001 / 60
      WHEN med_name_source LIKE "%[0.0011 units/kg/hr]%" THEN 0.0011 / 60
      WHEN med_name_source LIKE "%[0.0012 units/kg/hr]%" THEN 0.0012 / 60
      WHEN med_name_source LIKE "%[0.0013 units/kg/hr]%" THEN 0.0013 / 60
      WHEN med_name_source LIKE "%[0.0014 units/kg/hr]%" THEN 0.0014 / 60
      WHEN med_name_source LIKE "%[0.0015 units/kg/hr]%" THEN 0.0015 / 60
      WHEN med_name_source LIKE "%[0.0016 units/kg/hr]%" THEN 0.0016 / 60
      WHEN med_name_source LIKE "%[0.0017 units/kg/hr]%" THEN 0.0017 / 60
      WHEN med_name_source LIKE "%[0.0018 units/kg/hr]%" THEN 0.0018 / 60
      WHEN med_name_source LIKE "%[0.0019 units/kg/hr]%" THEN 0.0019 / 60
      WHEN med_name_source LIKE "%[0.002 units/kg/hr]%"  THEN 0.002 / 60
      WHEN med_name_source LIKE "%[0.0021 units/kg/hr]%" THEN 0.0021 / 60
      WHEN med_name_source LIKE "%[0.0022 units/kg/hr]%" THEN 0.0022 / 60
      WHEN med_name_source LIKE "%[0.0023 units/kg/hr]%" THEN 0.0023 / 60
      WHEN med_name_source LIKE "%[0.0024 units/kg/hr]%" THEN 0.0024 / 60
      WHEN med_name_source LIKE "%[0.0025 units/kg/hr]%" THEN 0.0025 / 60
      WHEN med_name_source LIKE "%[0.0026 units/kg/hr]%" THEN 0.0026 / 60
      WHEN med_name_source LIKE "%[0.0027 units/kg/hr]%" THEN 0.0027 / 60
      WHEN med_name_source LIKE "%[0.0028 units/kg/hr]%" THEN 0.0028 / 60
      WHEN med_name_source LIKE "%[0.0029 units/kg/hr]%" THEN 0.0029 / 60
      WHEN med_name_source LIKE "%[0.002 units/kg/hr]%"  THEN 0.002 / 60
      WHEN med_name_source LIKE "%[0.003 units/kg/hr]%"  THEN 0.003 / 60
      WHEN med_name_source LIKE "%[0.004 units/kg/hr]%"  THEN 0.004 / 60
      WHEN med_name_source LIKE "%[0.005 units/kg/hr]%"  THEN 0.005 / 60
      WHEN med_name_source LIKE "%[0.006 units/kg/hr]%"  THEN 0.006 / 60
      WHEN med_name_source LIKE "%[0.007 units/kg/hr]%"  THEN 0.007 / 60
      WHEN med_name_source LIKE "%[0.008 units/kg/hr]%"  THEN 0.008 / 60
      WHEN med_name_source LIKE "%[0.009 units/kg/hr]%"  THEN 0.009 / 60
      WHEN med_name_source LIKE "%[0.01 units/kg/hr]%"   THEN 0.010 / 60
      WHEN med_name_source LIKE "%[0.011 units/kg/hr]%"  THEN 0.011 / 60
      WHEN med_name_source LIKE "%[0.012 units/kg/hr]%"  THEN 0.012 / 60
      WHEN med_name_source LIKE "%[0.013 units/kg/hr]%"  THEN 0.013 / 60
      WHEN med_name_source LIKE "%[0.014 units/kg/hr]%"  THEN 0.014 / 60
      WHEN med_name_source LIKE "%[0.015 units/kg/hr]%"  THEN 0.015 / 60
      WHEN med_name_source LIKE "%[0.016 units/kg/hr]%"  THEN 0.016 / 60
      WHEN med_name_source LIKE "%[0.017 units/kg/hr]%"  THEN 0.017 / 60
      WHEN med_name_source LIKE "%[0.018 units/kg/hr]%"  THEN 0.018 / 60
      WHEN med_name_source LIKE "%[0.019 units/kg/hr]%"  THEN 0.019 / 60
      WHEN med_name_source LIKE "%[0.02 units/kg/hr]%"   THEN 0.02 / 60
      WHEN med_name_source LIKE "%[0.12 units/kg/hr]%"   THEN 0.12 / 60
      ELSE med_dose
      END
  , med_dose_units = "units/kg/min"
WHERE med_set = "vasoactive"
  AND med_name_source LIKE "%[% units/kg/hr]%"
;

-- -------------------------------------------------------------------------- --
--                     A few more specific modifications                      --
-- -------------------------------------------------------------------------- --

UPDATE `**REDACTED**.harmonized.medication_admin`
SET
    med_dose =
      CASE
        WHEN med_name_source LIKE "dobutamine infusion 2 mg/ml%" THEN med_dose * 2000
        WHEN med_name_source LIKE "dobutamine infusion 4 mg/ml%" THEN med_dose * 4000
        WHEN med_name_source =    "epinephrine 5 mg [1 mcg/min] + ns 45 ml" THEN 1
        ELSE med_dose
      END
  , med_dose_units = "mcg/min"
WHERE med_set = "vasoactive"
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET
    med_dose =
      CASE
        WHEN med_name_source =  "milrinone 10 mg [1 mg/kg/hr] + dextrose 5% in water 40 ml" THEN 1000
        WHEN med_name_source =  "milrinone 30 mg [1 mg/kg/hr] + dextrose 5% in water 20 ml" THEN 1000
        ELSE med_dose
      END
  , med_dose_units = "mcg/kg/min"
WHERE med_set = "vasoactive"
;

-- -------------------------------------------------------------------------- --
                           -- Stopped medications? --

-- For stoped medications, set the dosage to 0, that will help with the
-- vasoactive medications for sure.
UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_dose = 0
WHERE lower(med_admin_action_source) = "stopped"
;

-- -------------------------------------------------------------------------- --
                               -- End of File --
-- -------------------------------------------------------------------------- --
