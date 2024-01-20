#standardSQL

/*
 * Code to generate an initial mapping from source medications to harmonized
 * values
 * 
 * Start with the CREATE OR REPLACE using regex to get the needed medications
 * based on med_name_source.
 *
 * Use several UPDATE statements to then exclude medications based on route or
 * other criteria
*/

CREATE OR REPLACE TABLE `**REDACTED**.full.medication_mapping` AS
(
  SELECT
    *
    , CASE
    -- Albumin 25 
    WHEN REGEXP_CONTAINS(med_name_source, r"albumin(,)*( human)*\ 25") THEN "ALBUMIN_25"

    -- Albumin 5 
    WHEN REGEXP_CONTAINS(med_name_source, r"albumin(,)*( human)*\ 5")  THEN "ALBUMIN_5"

    -- Antimicrobial
    WHEN REGEXP_CONTAINS(med_name_source, r"acyclovir")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"amikacin")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"amoxicillin")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"amphotericin")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ampicillin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"azithromycin")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"aztreonam")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefazolin")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefdinir")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefepime")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefixime")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefotaxime")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefotetan")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefoxitin")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefprozil")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ceftazidime")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ceftriaxone")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cefuroxime")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cephalexin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"cidofovir")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ciprofloxacin")    THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"clarithromycin")   THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"clindamycin")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"dapsone")          THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"daptomycin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"doxycycline")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ertapenem")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ethambutol")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"fluconazole")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"foscarnet")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ganciclovir")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"gentamicin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"imipenem")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"isoniazid")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"levofloxacin")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"linezolid")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"meropenem")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"metronidazole")    THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"micafungin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"moxifloxacin")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"nitrofurantoin")   THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"oseltamivir")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"oxacillin")        THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"penicillin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"piperacillin")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"posaconazole")     THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"rifampin")         THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"sulfamethoxazole") THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"ticarcillin")      THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"tobramycin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"vancomycin")       THEN "ANTIMICROBIAL"
    WHEN REGEXP_CONTAINS(med_name_source, r"voriconazole")     THEN "ANTIMICROBIAL"

    -- Dexamtehasone
    WHEN REGEXP_CONTAINS(med_name_source, r"dexamethasone") THEN "DEXAMETHASONE"

    -- Dobutamine Drip
    WHEN REGEXP_CONTAINS(med_name_source, r"dobutamine")  THEN "DOBUTAMINE_DRIP"
    
    -- Dopamine Drip
    WHEN REGEXP_CONTAINS(med_name_source, r"dopamine")  THEN "DOPAMINE_DRIP"

    -- Epinephrine Drip
    WHEN REGEXP_CONTAINS(med_name_source, r"norepinephrine") IS FALSE AND
         REGEXP_CONTAINS(med_name_source, r"racepinephrine") IS FALSE AND
         REGEXP_CONTAINS(med_name_source, r"lidocaine") IS FALSE      AND
         REGEXP_CONTAINS(med_name_source, r"bupivacaine") IS FALSE AND
         REGEXP_CONTAINS(med_name_source, r"epinephrine")
      THEN "EPINEPHRINE_DRIP"
    
    -- Hydrocortisone 
    WHEN REGEXP_CONTAINS(med_name_source, r"hydrocortisone") THEN "HYDROCORTISONE"
    
    -- Methylprednisolone
    WHEN REGEXP_CONTAINS(med_name_source, r"methylprednisolone") THEN "METHYLPREDNISOLONE"
    
    -- Milrinnoe Drip
    WHEN REGEXP_CONTAINS(med_name_source, r"milrinone")  THEN "MILRINONE_DRIP"
    
    -- Norepiphrine Drip 
    WHEN REGEXP_CONTAINS(med_name_source, r"norepinephrine")  THEN "NOREPINEPHRINE_DRIP"
    
    -- Prednisone 
    WHEN REGEXP_CONTAINS(med_name_source, r"prednisone") THEN "PREDNISONE"
    
    -- Vasopressin Drip 
    WHEN REGEXP_CONTAINS(med_name_source, r"vasopressin") THEN "VASOPRESSIN_DRIP"
    
    ELSE NULL
    END AS med_name
  FROM
  (
    SELECT
      site
      , med_name_source
      , med_route_source
      , med_dose_units_source
      , COUNT(*) AS N_ROWS
      , APPROX_QUANTILES(med_dose_source, 4) AS min_q1_med_q3_max_source
    FROM
    (
      SELECT
        site
        , lower(med_name_source) as med_name_source
        , lower(med_route_source) as med_route_source
        , med_dose_units_source
        , med_dose_source
        FROM `**REDACTED**.full.medication_admin`
    )
    GROUP BY site, med_name_source, med_route_source, med_dose_units_source
    ORDER BY site, med_name_source, med_route_source, med_dose_units_source
  )
)
;


/* -------------------------------------------------------------------------- */
/* Unmap based on routes                                                      */
/* first update is for all med_names
/* additional updates for specific meds
/* -------------------------------------------------------------------------- */
UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE
  lower(med_route_source) IN (
  -- ears
  "both ears", "each ear",
  "ear (each)", "ear (left)", "ear (right)",
  "left ear", "right ear",
  -- eyes
  "affected eye", "both eyes", "each affected eye", "each eye",
  "eye", "eye (each)", "left eye", "right eye", "eye (right)",
  "eye (left)",
  "intravitreal left eye",
  "intravitreal right eye",
  "operative eye",
  -- Topical
  "topical", "topically"
  )
;

UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE med_name = "ANTIMICROBIAL" AND
  lower(med_route_source) IN (
            "apply to affected area(s)",
            "caudal",
            "endotracheal", "endotracheally",
            "epidural", "by epidural",
            "im",
            "infiltration", "local infiltration",
            "injection",
            "inhaled", "inhalation",
            "intracameral",
            "intradermal",
            "intralesional",
            "intramuscular",
            "intraosseosus",
            "intrathecal",
            "intratracheal", "intratracheal tube",
            "ipv inhalation",
            "irrigation", "by irrigation",
            "nasally",
            "nebulization", "nebulized inhalation",
            "nebulizer", "via nebulizer",
            "perineural",
            "other",
            "regional block",
            "soak",
            "subconjunctival",
            "subcutaneous", "subcutaneously",
            "subdermal", "subdermally",
            "transdermal",
            "transtracheal",
            "vaginal"
          )
;

UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE med_name = "EPINEPHRINE_DRIP" AND
  lower(med_route_source) IN (
    "by epidural",
    "endotracheal",
    "endotracheally",
    "im",
    "infiltration", "local infiltration",
    "injection",
    "inhaled", "inhalation",
    "intracameral",
    "intradermal",
    "intralesional",
    "intramuscular",
    "intraosseosus",
    "intrathecal",
    "intratracheal", "intratracheal tube",
    "ipv inhalation",
    "irrigation", "by irrigation",
    "nasally",
    "nebulization", "nebulized inhalation",
    "nebulizer", "via nebulizer",
    "perineural",
    "other",
    "regional block",
    "subcutaneous",
    "subcutaneously"
  )
;    

UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE med_name = "HYDROCORTISONE" AND
  lower(med_route_source) IN (
    "intrathecal",
    "intraommaya",
    "nasal",
    "otic",
    "retal",
    "retally"
  )
;    

UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE
  med_name = "METHYLPREDNISOLONE" AND
  lower(med_route_source) IN (
    "intralesional",
    "intra-lesional"
  )
;     

UPDATE `**REDACTED**.full.medication_mapping`
SET med_name = NULL
WHERE
  med_name = "VASOPRESSIN_DRIP" AND
  lower(med_route_source) IN (
    "subcutaneously"
  )
;


/* -----------------------------------------------------------------------------
                                  End of File
----------------------------------------------------------------------------- */
