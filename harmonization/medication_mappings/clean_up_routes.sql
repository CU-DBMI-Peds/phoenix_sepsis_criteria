#standardSQL
/* -------------------------------------------------------------------------- */
--                           -- Clean up routes --                            --

-- multiple sequential update statements are likely to cause an error:
-- "Could not serialize access to table
-- **REDACTED**:harmonized.medication_admin due to concurrent update"
--
-- Try to batch updates
/*
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.medication_admin` AS
(
  SELECT
      a.*EXCEPT(med_fda_route)
    , COALESCE(b.med_fda_route, a.med_fda_route) AS med_fda_route -- take the b version prefentially as the name has a route in it more often than not
  FROM `**REDACTED**.harmonized.medication_admin` a
  LEFT JOIN (SELECT DISTINCT * FROM `**REDACTED**.medication.med_name_source_to_routes`) b
  ON a.site = b.site AND lower(a.med_name_source) = b.med_name_source
)
;
*/

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "AURICULAR (OTIC)", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       REGEXP_CONTAINS(med_name_source, r'\sot$')
    OR REGEXP_CONTAINS(med_name_source, r'\sot\ssoln$')
    OR REGEXP_CONTAINS(med_name_source, r'\sot\ssusp$')
    OR REGEXP_CONTAINS(med_name_source, r'\sotic\ssoln$')
    OR REGEXP_CONTAINS(med_name_source, r'\sotic\ssolution$')
    OR med_name_source LIKE "%eye drop%"
  )
;


UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "INTRAMUSCULAR", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
    med_name_source IN (
        "epinephrine hcl (anaphylaxis) 0.15 mg/0.3ml (1:2000) im devi"
      , "epinephrine hcl (anaphylaxis) 0.3 mg/0.3ml (1:1000) im devi"
      , "epinephrine hcl (anaphylaxis) im"
      , "epipen 2-pak im"
      , "epipen im"
      , "epipen jr 2-pak im"
      , "epipen jr im"
    )
    OR REGEXP_CONTAINS(med_name_source, r'\sim$')
    OR REGEXP_CONTAINS(med_name_source, r'\sim\ssolr$')
    OR REGEXP_CONTAINS(med_name_source, r'\sim\ssusp$')
    OR REGEXP_CONTAINS(med_name_source, r'\sim\ssoln$')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "INTRAVENOUS", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
      med_name_source IN (
          "********zosyn 40mg/ml in ns lock***********"
        , "dobutamine hcl 12.5 mg/ml iv soln"
        , "dobutamine hcl iv"
        , "dobutamine iv infusion (central line)"
        , "dobutamine iv infusion (peripheral line)"
        , "dopamine 0.6 mg/ml in d5w infusion custom"
        , "dopamine 1.6 mg/ml in d5w infusion custom"
        , "dopamine 3.2 mg/ml in d5w infusion custom"
        , "dopamine 40 mg/ml in total volume (central line only) infusion custom"
        , 'dopamine 400 mg/250 ml (1,600 mcg/ml) in 5 % dextrose intravenous soln'
        , "dopamine 6 mg/ml in d5w infusion custom"
        , "dopamine hcl 40 mg/ml iv soln"
        , "dopamine hcl iv"
        , "dopamine in d5w 1.6-5 mg/ml-% iv soln"
        , "dopamine in d5w iv"
        , "dopamine infusion anes"
        , "dopamine iv infusion (anesthesia)"
        , "dopamine iv infusion (central line)"
        , "dopamine iv infusion (peripheral line)"
        , "epinephrine 0.1 mg/10ml iv sosy"
        , "epinephrine 1000 mcg/ml in total volume (central line only) infusion"
        , "epinephrine 16 mcg/ml in d5w infusion custom"
        , "epinephrine 3 mcg/ml in d5w infusion custom"
        , "epinephrine 64 mcg/ml in d5w infusion custom"
        , "epinephrine bitartrate in"
        , "epinephrine infusion anes"
        , "epinephrine iv infusion (adult) (anesthesia)"
        , "epinephrine iv infusion (adult) (central line)"
        , "epinephrine iv infusion (adult) (peripheral line)"
        , "epinephrine iv infusion (anesthesia)"
        , "epinephrine iv infusion (central line)"
        , "epinephrine iv infusion (peripheral line)"
        , "epinephrine mist in"
        , "milrinone 0.05 mg/ml in d5w infusion custom"
        , "milrinone 0.2 mg/ml in d5w infusion custom"
        , "milrinone 1 mg/ml in total volume (central line only) infusion custom"
        , "milrinone in dextrose 20 mg/100ml iv soln"
        , "milrinone in dextrose 200-5 mcg/ml-% iv soln"
        , "milrinone in dextrose iv"
        , "milrinone iv infusion (anesthesia)"
        , "milrinone iv infusion (central line)"
        , "milrinone iv infusion (central line) (home supply)"
        , "milrinone iv infusion (central line) (home supply) non-formulary"
        , "milrinone iv infusion (peripheral line)"
        , "milrinone iv infusion (peripheral line) (home supply)"
        , "milrinone lactate 1 mg/ml iv soln"
        , "milrinone lactate 20 mg/20ml iv soln"
        , "milrinone lactate 50 mg/50ml iv soln"
        , "norepinephrine iv infusion (adult) (central line)"
        , "norepinephrine iv infusion (adult) (peripheral line)"
        , "norepinephrine iv infusion (anesthesia)"
        , "norepinephrine iv infusion (central line)"
        , "norepinephrine iv infusion (peripheral line)"
        , "vasopressin (diabetes insipidus) iv infusion (anesthesia)"
        , "vasopressin (diabetes insipidus) iv infusion (central line)"
        , "vasopressin (diabetes insipidus) iv infusion (peripheral line)"
        , "vasopressin (gi hemorrhage adults) iv infusion (central line)"
        , "vasopressin (gi hemorrhage adults) iv infusion (peripheral line)"
        , "vasopressin (gi hemorrhage infants/children) iv infusion (central lin"
        , "vasopressin (gi hemorrhage infants/children) iv infusion (peripheral"
        , "vasopressin (hypotension adults) iv infusion (central line)"
        , "vasopressin (hypotension adults) iv infusion (peripheral line)"
        , "vasopressin (hypotension infants/children) iv infusion (anesthesia)"
        , "vasopressin (hypotension infants/children) iv infusion (central line)"
        , "vasopressin (hypotension infants/children) iv infusion (peripheral li"
        , "vasopressin 20 unit/ml iv soln"
        , "vasopressin iv infusion (central line)"
        , "vasopressin iv infusion (peripheral line)"
      )
      OR REGEXP_CONTAINS(med_name_source, r'\siv$')
      OR REGEXP_CONTAINS(med_name_source, r'\siv\ssolr$')
      OR REGEXP_CONTAINS(med_name_source, r'\siv\ssoln')
      OR REGEXP_CONTAINS(med_name_source, r'\siv\ssolution$')
      OR REGEXP_CONTAINS(med_name_source, r'\sintravenous\ssolution$')
      OR REGEXP_CONTAINS(med_name_source, r'\sinfusion(\s|$)')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "INTRAVESICAL", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
    med_name_source LIKE "%bladder irrigation%"
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "NASAL", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
    med_name_source LIKE "%intranasal%"
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "PARENTERAL", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
    med_name_source IN (
      "dopamin inj, 200 mg"
      , "dopamine inj. 200mg"
      , "adrenalin injection 1mg/1ml amp."
      , "adrenalin injection 1mg/1ml amp."
      , "adrenaline inj. 1 mg/1ml amp."
      , "adrenaline inj. 1mg / 1ml amp"
      , "auvi-q 0.15 mg/0.15ml ij soaj"
      , "auvi-q 0.3 mg/0.3ml ij soaj"
      , "epinefrina 1mg/1ml inyectable"
      , "epinefrina 1mg/1ml solucion inyectable"
      , "epinephrine (pf) 100 mcg/10 ml (10 mcg/ml) iv syringe"
      , "epinephrine (anaphylaxis) 1 mg/ml ij soln"
      , "epinephrine (anaphylaxis) ij"
      , "epinephrine 0.1 mg/ml injectable solution"
      , "epinephrine 0.1 mg/0.1ml ij soaj"
      , "epinephrine 0.1 mg/ml injection endotracheal use custom"
      , "epinephrine 0.15 mg/0.15ml ij soaj"
      , "epinephrine 0.15 mg/0.3ml ij devi"
      , "epinephrine 0.15 mg/0.3ml ij soaj"
      , "epinephrine 0.3 mg/0.3ml ij devi"
      , "epinephrine 0.3 mg/0.3ml ij soaj"
      , "epinephrine 0.3 mg/0.3ml ij sosy"
      , "epinephrine 1 mg/10ml ij sosy"
      , "epinephrine 1 mg/ml ij soln"
      , "epinephrine 1 mg/ml injection endotracheal use custom"
      , "epinephrine 10 mcg/ml (nss) injection custom"
      , "epinephrine 10 mcg/ml: 10 ml (anesthesia)"
      , "epinephrine hcl 0.1 mg/ml ij soln"
      , "epinephrine hcl 0.1 mg/ml ij soln for critical care dilution"
      , "epinephrine hcl 0.1 mg/ml ij sosy"
      , "epinephrine hcl 0.1 mg/ml im/subq ij sosy"
      , "epinephrine hcl 1 mg/ml ij soln"
      , "epinephrine hcl ij"
      , "epinephrine hcl in"
      , "epinephrine ij"
      , "epinephrine inj anes (10 mcg/ml) - 10 ml"
      , "epinephrine pf 1 mg/10ml ij sosy"
      , "epipen 2-pak 0.3 mg/0.3ml ij soaj"
      , "epipen ij"
      , "epipen jr 0.15 mg/0.3ml ij soaj"
      , "epipen jr 2-pak 0.15 mg/0.3ml ij soaj"
      , "epipen jr 2-pak ij"
      , "milrinone injection anes"
      , "noradrenaline 4 mg/2 ml inj."
      , "vasopressin 1 unit/ml injection custom"
      , "vasopressin 20 unit/ml ij soln"
      , "vasopressin injection custom orderable"
    )
    OR REGEXP_CONTAINS(med_name_source, r'inj\.')
    OR REGEXP_CONTAINS(med_name_source, r'inj,')
    OR REGEXP_CONTAINS(med_name_source, r'inj\scustom$')
    OR REGEXP_CONTAINS(med_name_source, r'injection')
    OR REGEXP_CONTAINS(med_name_source, r'\sij$')
    OR REGEXP_CONTAINS(med_name_source, r'\sinj(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sij\ssolr(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sij\ssolr\spd$')
    OR REGEXP_CONTAINS(med_name_source, r'\sij\ssoln(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sij\ssusp(\s|$)')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "RESPIRATORY (INHALATION)", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
    med_name_source IN (
      "colistimethate neb sol custom"
      , "epinephrine hcl 2.25 % in nebu"
    )
    OR med_name_source LIKE "%inhalation%"
    OR REGEXP_CONTAINS(med_name_source, r'\sin\snebu(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sneb\ssoln(\s|$)')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "OPHTHALMIC", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       REGEXP_CONTAINS(med_name_source, r'\sop\ssoln(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sop\ssusp(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sop\sgel(s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sop$')
    OR REGEXP_CONTAINS(med_name_source, r'\sop\soint(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\.\soint(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\sointment(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\ssolution(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\ssusp(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\ssuspension(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sophth\ssoln(\s|$)')
    OR med_name_source LIKE "%ophthalmic%"
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "RECTAL", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       med_name_source LIKE "%rectal suppository%"
    OR REGEXP_CONTAINS(med_name_source, r'\senema(\s|$)')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "ORAL", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       med_name_source = 'neomycin sulfate 500 mg tab (crush and mix)'
    OR REGEXP_CONTAINS(med_name_source, r'\sor$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\suse\sonly')
    OR REGEXP_CONTAINS(med_name_source, r'\ssyp\.\s')
    OR REGEXP_CONTAINS(med_name_source, r'\spowd$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\spkt$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\scaps(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\stabs(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\sliqd$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\schew(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\sstrp$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\stbdp$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssusr$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\selix$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssyrp(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssusp(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\soral\ssusp(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\soral\ssuspension(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssoln(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\soral\ssolution(\s|$)')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssol\scustom$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\smisc$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\skit$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\ssolr$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\stbec$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\scpep$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\scpdr$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\stbpk$')
    OR REGEXP_CONTAINS(med_name_source, r'\sor\sconc$')
    OR REGEXP_CONTAINS(med_name_source, r'\slozg$') -- lozenge
    OR REGEXP_CONTAINS(med_name_source, r'\stroc$') -- troche, aka, lozenge
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "SUBCUTANEOUS", systemic = 1
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       med_name_source LIKE "%sc soln%"
    OR REGEXP_CONTAINS(med_name_source, r'\ssc$')
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "TOPICAL", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       med_name_source LIKE "neosporin%"
    OR med_name_source LIKE "benzoyl peroxide%"
    OR med_name_source LIKE "%ex liqd%"
    OR med_name_source LIKE "%ex oint%"
    OR med_name_source LIKE "%ud oint%"
    OR med_name_source LIKE "%ex crea%"
    OR med_name_source LIKE "%ex gel%"
    OR med_name_source LIKE "%ex lotn%"
    OR med_name_source LIKE "%ex foam%"
    OR med_name_source LIKE "%ex pads%"
    OR med_name_source LIKE "%ex stck%"
    OR med_name_source LIKE "%ex kit%"
    OR med_name_source LIKE "%ex soln%"
    OR med_name_source LIKE "%ex sham%"
    OR med_name_source LIKE "%ex swab%"
    OR med_name_source LIKE "%topical%"
    OR REGEXP_CONTAINS(med_name_source, r'\sex$')
    OR med_name_source IN (
        "clotrimazole,1% ointment, 10gm/tube"
      , "neomycin sulphate+bacitracin zinc oint."
    )
  )
;

UPDATE `**REDACTED**.harmonized.medication_admin`
SET med_fda_route = "VAGINAL", systemic = 0
WHERE
  (med_fda_route IS NULL OR med_fda_route = "UNKNOWN")
  AND
  (
       med_name_source LIKE "%vaginal tab%"
    OR med_name_source LIKE "%va crea%"
    OR med_name_source LIKE "%va gel%"
    OR med_name_source LIKE "%va supp%"
    OR med_name_source LIKE "%va kit%"
    OR REGEXP_CONTAINS(med_name_source, r'\sva$')
    OR REGEXP_CONTAINS(med_name_source, r'\sva tab(s|$)')
  )
;

/*
CREATE OR REPLACE TABLE `**REDACTED**.harmonized.medication_admin` AS
(
  SELECT
      a.*EXCEPT(systemic)
    , COALESCE(b.systemic, a.systemic) AS systemic
  FROM `**REDACTED**.harmonized.medication_admin` a
  LEFT JOIN `**REDACTED**.medication.med_route_mapping` b
  ON a.med_fda_route = b.med_fda_route
)
;
*/


/* -------------------------------------------------------------------------- */
--               -- High Probability Systemic Antimicrobials --               --
-- These medications are almost certainly going to be systemic.  So, if route is
-- missing set as systemic

UPDATE `**REDACTED**.harmonized.medication_admin`
SET systemic = 1
WHERE med_fda_route IS NULL
  AND med_generic_name IN (
      "acyclovir"
    , "amikacin"
    , "amoxicillin"
    , "amphotericin"
    , "amphotericin_b"
    , "ampicillin"
    , "azithromycin"
    , "aztreonam"
    , "cefazolin"
    , "cefdinir"
    , "cefepime"
    , "cefixime"
    , "cefotaxime"
    , "cefotetan"
    , "cefoxitin"
    , "cefprozil"
    , "ceftazidime"
    , "ceftriaxone"
    , "cefuroxime"
    , "cephalexin"
    , "cidofovir"
    , "ciprofloxacin"
    , "clarithromycin"
    , "clindamycin"
    , "dapsone"
    , "daptomycin"
    , "doxycycline"
    , "ertapenem"
    , "ethambutol"
    , "fluconazole"
    , "foscarnet"
    , "ganciclovir"
    , "gentamicin"
    , "imipenem"
    , "isoniazid"
    , "levofloxacin"
    , "linezolid"
    , "meropenem"
    , "metronidazole"
    , "micafungin"
    , "moxifloxacin"
    , "nitrofurantoin"
    , "oseltamivir"
    , "oxacillin"
    , "penicillin"
    , "piperacillin"
    , "posaconazole"
    , "rifampin"
    , "sulfamethoxazole"
    , "ticarcillin"
    , "tobramycin"
    , "vancomycin"
    , "voriconazole"
    )
;


/* -------------------------------------------------------------------------- */
--                             -- End of File --                              --
/* -------------------------------------------------------------------------- */
