#standardSQL

/* -------------------------------------------------------------------------- */
/*                    -- build med_route_mapping table --                     */
/*                                                                            */
/* This step maps the med_route_source values to the fda values and sets a    */
/* default value of 0 for systemic routes.  After the table is created,       */
/* UPDATE statements will modify the systemic column.                         */
/* -------------------------------------------------------------------------- */

CREATE OR REPLACE TABLE `**REDACTED**.medication.med_route_mapping` AS
(
  SELECT DISTINCT
    med_route_source,
    CASE
      -- No mapping needed
        WHEN UPPER(TRIM(med_route_source)) IN (
          SELECT UPPER(TRIM(NAME)) FROM `**REDACTED**.medication.fda_route_of_administration`
        ) THEN UPPER(TRIM(med_route_source))

        WHEN med_route_source IS NULL THEN "UNKNOWN"

      -- AURICULAR (OTIC)
        WHEN UPPER(TRIM(med_route_source)) IN (
            'AFFECTED EAR'
          , 'BOTH EARS'
          , 'EACH AFFECTED EAR'
          , 'EACH EAR'
          , 'EAR (EACH)'
          , 'EAR (LEFT)'
          , 'EAR (RIGHT)'
          , 'LEFT EAR'
          , 'RIGHT EAR'
          , 'OTIC'
          , 'VIA OTICA'
        ) THEN "AURICULAR (OTIC)"

      -- BUCCAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BUCCALLY'
        ) THEN "BUCCAL"

      -- CONJUNCTIVAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'LEFT CONJ SAC'
          , 'RIGHT CONJ SAC'
        ) THEN 'CONJUNCTIVAL'

      -- CUTANEOUS

      -- DENTAL

      -- ELECTRO-OSMOSIS

      -- ENDOCERVICAL -- Synonymous with INTRACERVICAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRACERVICAL'
          , 'PERICERVICAL'
        ) THEN "ENDOCERVICAL"

      -- ENDOSINUSIAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'SINUS CAVITY'
          , 'SINUS IRRIGATION'
        ) THEN 'ENDOSINUSIAL'

      -- ENDOTRACHEAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ENDOTRACHEALLY'
          , 'INHALED BY TRACH'
          , 'INTRATRACHEAL'
          , 'INTRATRACHEAL TUBE'
          , 'TRACHEAL TUBE'
          , 'VIA ENDOTRAQUEAL'
          , 'VIA INTRATRAQUEAL O INTRABRONQUIAL'
        ) THEN "ENDOTRACHEAL"

      -- ENTERAL -- administration directly into the intestines
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ACE' -- Antegrade Continence Enema
          , 'ACE STOMA'
          , 'BY J-TUBE'
          , 'CECOSTOMY'
          , 'G-J TUBE'
          , 'GJ TUBE'
          , 'GJ-TUBE'
          , 'GASTROJEJUNAL'
          , 'J TUBE'
          , 'J-TUBE'
          , 'JEJUNAL TUBE'
          , 'JEJUNOSTOMY TUBE'
        ) THEN "ENTERAL"

      -- EPIDURAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY EPIDURAL'
          , 'EPIDURAL CATHETER'
          , 'EPIDURAL INFUSION'
          , 'EPIDURAL PCA'
          , 'SPINAL'
          , 'VIA EPIDURAL'
          , 'VIA RAQUIDEA'
        ) THEN "EPIDURAL"

      -- EXTRA‑AMNIOTIC

      -- EXTRACORPOREAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'APHERESIS CATHETER'
          , 'APHERESIS CIRCUIT'
          , 'BY APHERESIS CATHETER'
          , 'BY APHERESIS CIRCUIT'
          , 'BY ECLS'
          , 'ECMO CIRCUIT'
          , 'USE FOR APHERESIS'
        ) THEN 'EXTRACORPOREAL'

      -- HEMODIALYSIS
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ADD TO DIALYSATE'
          , 'BY CRRT CIRCUIT'
          , 'BY DIALYSIS CATHETER'
          , 'BY DIALYSIS CIRCUIT'
          , 'BY DIALYSIS MACHINE'
          , 'CRRT CIRCUIT'
          , 'DIALYSIS'
          , 'HEMODIALYSIS CATHETER'
          , 'HEMODIALYSIS CIRCUIT'
          , 'PERITONEAL DIALYSIS CATHETER'
          , 'USE TO PRIME DIALYSIS CIRCUIT'
          , 'VIA CRRT MACHINE'
          , 'VIA DIALYSIS CIRCUIT'
        ) THEN "HEMODIALYSIS"

      -- INFILTRATION
        WHEN UPPER(TRIM(med_route_source)) IN (
            'LOCAL INFILTRATION'
          , 'LOCAL INFILTRATION - PNC'
        ) THEN 'INFILTRATION'

      -- INTERSTITIAL

      -- INTRA-ABDOMINAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ABDOMINAL DRAIN'
          , 'TRANSP'
          , 'TRANSVERSE ADBOMINUS PLANE'
        ) THEN 'INTRA-ABDOMINAL'

      -- INTRA-AMNIOTIC
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRA-AMNIOTICALLY'
        ) THEN 'INTRA-AMNIOTIC'


      -- INTRA-ARTERIAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ARTERIAL LINE'
          , 'BY LEFT ATRIAL LINE'
          , 'BY PULMONARY ARTERY LINE'
          , 'BY RIGHT ATRIAL LINE'
          , 'INTRAARTICULAR'
          , 'LA LINE'
          , 'PA LINE'
          , 'RA LINE'
          , 'INTRAARTERIAL'
          , 'VIA INTRAARTERIAL'
          , 'UMBILICAL ARTERIAL'
        ) THEN 'INTRA-ARTERIAL'

      -- INTRA-ARTICULAR
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRAARTICULAR'
          , 'VIA INTRA ARTICULAR'
        ) THEN "INTRA-ARTICULAR"

      -- INTRABILIARY
      -- INTRABRONCHIAL

      -- INTRABURSAL
        WHEN UPPER(TRIM(med_route_source)) IN (
          'INJ INTO BURSA'
        ) THEN "INTRABURSAL"

      -- INTRACARDIAC

      -- INTRACARTILAGINOUS

      -- INTRACAUDAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'CAUDAL'
        ) THEN "INTRACAUDAL"

      -- INTRACAVERNOUS

      -- INTRACAVITARY

      -- INTRACEREBRAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRAOMMAYA'
          , 'OMMAYA RESERVOIR'
        ) THEN 'INTRACEREBRAL'

      -- INTRACISTERNAL

      -- INTRACORNEAL

      -- "INTRACORONAL, DENTAL"

      -- INTRACORONARY
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRA-CORONARY'
          , 'VIA INTRACORONARIA'
        ) THEN 'INTRACORONARY'

      -- INTRACORPORUS CAVERNOSUM
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRACAVERNOSAL'
        ) THEN "INTRACORPORUS CAVERNOSUM"

      -- INTRADERMAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'VIA INTRADERMICA'
        ) THEN "INTRADERMAL"

      -- INTRADISCAL

      -- INTRADUCTAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRAGLANDULAR'
        ) THEN 'INTRADUCTAL'

      -- INTRADUODENAL

      -- INTRADURAL
        WHEN UPPER(TRIM(med_route_source)) IN (
          'ID'
        ) THEN "INTRADURAL"

      -- INTRAEPIDERMAL

      -- INTRAESOPHAGEAL

      -- INTRAGASTRIC
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY G-TUBE'
          , 'BY OG-TUBE'
          , 'FEEDING TUBE'
          , 'G TUBE'
          , 'G-TUBE'
          , 'GASTRIC TUBE'
          , 'GASTROSTOMY TUBE'
          , 'OG TUBE'
          , 'OROGASTRIC'
          , 'OROGASTRIC TUBE'
          , 'PE TUBE'
          , 'PEG TUBE'
          , 'PE TUBE'
          , 'PEG TUBE'
          , 'VIA OROGASTRICA'
          , 'VIA OSTOMIA'
        ) THEN "INTRAGASTRIC"

      -- INTRAGINGIVAL
      -- INTRAILEAL

      -- INTRALESIONAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ABSCESS/FLUID COLLECTION'
          , 'INTRA-LESIONAL'
          , 'INTRAWOUND'
        ) THEN "INTRALESIONAL"

      -- INTRALUMINAL
      -- INTRALYMPHATIC
      -- INTRAMEDULLARY
      -- INTRAMENINGEAL

      -- INTRAMUSCULAR
        WHEN UPPER(TRIM(med_route_source)) IN (
            'IM'
          , 'INTRAMUSCULAR - VIT K'
          , 'VIA INTRAMUSCULAR'
        ) THEN "INTRAMUSCULAR"

      -- INTRAOCULAR
        WHEN UPPER(TRIM(med_route_source)) IN (
            'VIA INTRA OCULAR'
        ) THEN "INTRAOCULAR"

      -- INTRAOVARIAN

      -- INTRAPERICARDIAL

      -- INTRAPERITONEAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'IPERITONEAL'
          , 'PERITONEAL CATHETER'
          , 'VIA INTRAPERITONEAL'
        ) THEN 'INTRAPERITONEAL'

      -- INTRAPLEURAL
      -- INTRAPROSTATIC
      -- INTRAPULMONARY
      -- INTRASINAL
      -- INTRASPINAL
      -- INTRASYNOVIAL
      -- INTRATENDINOUS
      -- INTRATESTICULAR

      -- INTRATHECAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRATHECAL PUMP'
          , 'VIA INTRATECAL'
        ) THEN 'INTRATHECAL'

      -- INTRATHORACIC
      -- INTRATUBULAR
      -- INTRATUMOR
      -- INTRATYMPANIC
      -- INTRAUTERINE

      -- INTRAVASCULAR
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRAVASCULAR IR'
        ) THEN 'INTRAVASCULAR'

      -- INTRAVENOUS
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY CENTRAL VENOUS LINE'
          , 'BY CVP MEDIAL LUMEN'
          , 'BY CVP PROXIMAL LUMEN'
          , 'BY CIRCUIT'
          , 'CENTRAL LINE IRRIGATION'
          , 'CENTRAL VENOUS ACCESS PORT INJ'
          , 'CENTRAL VENOUS CATHETER'
          , 'CENTRAL VENOUS LINE INFUSION'
          , 'VIA ACCESO VENOSO CENTRAL' -- **REDACTED**
          , 'VIA ACCESO VENOSO PERIFERICO' -- **REDACTED**
          , 'CONTINUOUS IV INFUSION'
          , 'CVP LINE'
          , 'INTERCATHETER'
          , 'INTRAVENOUS (CONTINUOUS INFUSION)'
          , 'INTRAVENOUS (IVP, IVPB)'
          , 'INTRAVENOUS PUSH'
          , 'IV'
          , 'IV PIGGYBACK'
          , 'IV PUSH'
          , 'PERFUSION'
          , 'PICC LINE'
          , 'TUNNELED, CUFFED CENTRAL CATHETER'
          , 'UMBILICAL VENOUS'
          , 'UV LINE'
          , 'VIA INTRAVENOSA'
        ) THEN "INTRAVENOUS"

      -- INTRAVENOUS BOLUS

      -- INTRAVENOUS DRIP

      -- INTRAVENTRICULAR
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY VAD'
          , 'EVD'
          , 'EXTERNAL VENTRICULAR DRAIN'
          , 'INTRAVENTRICULARLY'
        ) THEN 'INTRAVENTRICULAR'

      -- INTRAVESICAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BLADDER'
          , 'BLADDER INSTILLATION'
          , 'BLADDER IRRIG'
          , 'GU IRRIGANT'
          , 'INTRAVESICAL IRRIGATION'
          , 'INTRAVESICLE'
          , 'INTRAVESICULAR'
          , 'URINARY CATHETER'
          , 'URETER'
          , 'VIA INTRA VESICAL'
        ) THEN "INTRAVESICAL"

      -- INTRAVITREAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INTRA-VITREAL'
        ) THEN 'INTRAVITREAL'

      -- IONTOPHORESIS

      -- IRRIGATION
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY IRRIGATION'
        ) THEN "IRRIGATION"

      -- LARYNGEAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'LARYNGOTRACHEAL'
        ) THEN 'LARYNGEAL'

      -- NASAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ALTERNATING NARES'
          , 'EACH AFFECTED NOSTRIL'
          , 'EACH NARE'
          , 'EACH NOSTRIL'
          , 'INTRA-NASAL'
          , 'INTRANASAL'
          , 'LEFT NARE'
          , 'LEFT NOSTRIL'
          , 'NASALLY'
          , 'NOSTRIL (EACH)'
          , 'NOSTRIL (LEFT)'
          , 'NOSTRIL (RIGHT)'
          , 'ONE NOSTRIL'
          , 'RIGHT NARE'
          , 'RIGHT NOSTRIL'
          , 'VIA NASAL O INHALACION'
        ) THEN "NASAL"

      -- NASOGASTRIC
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY NG-TUBE'
          , 'BY NJ-TUBE'
          , 'BY NG OR NJ TUBE'
          , 'BY ND-TUBE'
          , 'D TUBE'
          , 'NASODUODENAL'
          , 'NASODUODENAL TUBE'
          , 'NASOGASTRIC TUBE'
          , 'NASOJEJUNAL'
          , 'NASOJEJUNAL TUBE'
          , 'ND TUBE'
          , 'NG'
          , 'NG-TUBE'
          , 'NJ TUBE'
          , 'NJ-TUBE'
          , 'PER NG TUBE'
          , 'PO'
          , 'PO OR NG-TUBE'
          , 'TUBE'
          , 'VIA NASOGASTRICA'
          , 'VIA NASOYEYUNAL'
        ) THEN "NASOGASTRIC"

      -- NOT APPLICABLE
        WHEN UPPER(TRIM(med_route_source)) IN (
            '(ROUTE IS NOT APPLICABLE)'
          , 'DOES NOT APPLY'
        ) THEN "NOT APPLICABLE"

      -- OCCLUSIVE DRESSING TECHNIQUE

      -- OPHTHALMIC
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BOTH EYES'
          , 'AFFECTED EYE'
          , 'AFFECTED EYE(S)'
          , 'EACH AFFECTED EYE'
          , 'EACH EYE'
          , 'EYE (EACH)'
          , 'EYE (LEFT)'
          , 'EYE (RIGHT)'
          , 'INTRACAMERAL'
          , 'INTRAVITREAL'
          , 'INTRAVITREAL LEFT EYE'
          , 'INTRAVITREAL RIGHT EYE'
          , 'INTRAOCULAR'
          , 'INTRAOCCULAR'
          , 'INTRAOCULAR BOTH EYES'
          , 'LEFT EYE'
          , 'OPERATIVE EYE'
          , 'RIGHT EYE'
          , 'VIA OFTALMICA'
        ) THEN "OPHTHALMIC"

      -- ORAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'CHEWED'
          , 'DISSOLVE IN MOUTH'
          , 'FEEDING'
          , 'GARGLE AND SWALLOW'
          , 'GUMS'
          , 'MOUTH/THROAT'
          , 'ORAL OR NASOGASTRIC'
          , 'ORAL TRANSMUCOSAL'
          , 'ORAL/G-TUBE'
          , 'ORAL/J-TUBE'
          , 'ORAL/NG-TUBE'
          , 'ORAL/TUBE'
          , 'SUCK AND SWALLOW'
          , 'SWISH & SPIT'
          , 'SWISH & SWALLOW'
          , 'SWISH AND SPIT'
          , 'SWISH AND SWALLOW'
          , 'TABLET/CAPSULE'
          , 'VIA ORAL'
          , 'RN TO ADD TO HUMAN MILK'
          , 'RN TO ADD TO FORMULA BOTTLE'
          , 'RN TO ADD TO ENTERAL FEEDS'
        ) THEN "ORAL"

      -- OROPHARYNGEAL

      -- OTHER
        WHEN UPPER(TRIM(med_route_source)) IN (
            'AFFECTED CATH'
          , 'ANGIO JET CATHETER'
          , 'BY TRANSDUCER'
          , 'CHEST TUBE'
          , 'VIA CHEST TUBE'
          , 'CHINESE PATENT DRUG'
          , 'COMBINATION'
          , 'COMMUNICATION'
          , 'BY PUMP'
          , 'EXCIPIENT'
          , 'FOR COMMUNICATION'
          , 'FOR PUMP USE ONLY'
          , 'MISC'
          , 'MISC.(NON-DRUG; COMBO ROUTE)'
          , 'MISCELLANEOUS'
          , 'POPLITEAL FOSSA'
          , 'OTHER ROUTE'
          , 'SPECIMEN CONTAINER'
          , 'WATER AQUA'
          , 'ZCHARGE'
          , 'INTRACATHETER'
          , 'NON-VASCULAR IR'
          , 'TRELLIS CATHETER'
          , 'CLOTTED CATH'
          , 'INTRA-CATHETER'
          , 'TRANSPYLORIC'
          , 'PERIPHERAL LINE'
          , 'VORTEX PORT'
          , 'CIRCUIT'
          , 'VAS-CATH'
          , 'TRANSFUSION'
          , 'INTRAOSSEOUS'
          , 'PLEURAL CATHETER'
          , 'INTERCOSTAL CATHETER'
          , 'PERIPHERAL VENOUS CATHETER'
          , 'QUADRATUS LUMBORUM'
          , 'BY CATHETER'
          , 'THROMBOLYSIS INFUSION CATHETER'
          , 'SYSTEM PRIME'
          , 'TRANSVERSE ABDOMINUS PLANE'
        ) THEN "OTHER"

      -- PARENTERAL - injection, infusion, implantation
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BY INJECTION'
          , 'BY ELASTOMERIC PUMP' -- for chemo
          , 'IM-DEPOT'
          , 'IMPLANT'
          , 'IMPLANTED PORT'
          , 'INFUSION'
          , 'INJECTION'
          , 'IRR'
          , 'SQ'
        ) THEN 'PARENTERAL'

      -- PERCUTANEOUS
      -- PERIARTICULAR
      -- PERIDURAL

      -- PERINEURAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'BRACHIAL PLEXUS'
          , 'BY PERIPHERAL NERVE CATHETER'
          , 'DIGITAL BLOCK'
          , 'ERECTOR SPINAE PLANE'
          , 'FACIA ILIACA'
          , 'FEMORAL NERVE'
          , 'FEMORAL PERIPHERAL NERVE CATHETER'
          , 'INFRACLAVICULAR'
          , 'INFRACLAVICULAR PERIPHERAL NERVE CATHETER'
          , 'INTERSCALENE'
          , 'INTERSCALENE PERIPHERAL NERVE CATHETER'
          , 'INTRANEURAL'
          , 'LUMBAR PLEXUS'
          , 'LUMBAR PLEXUS PERIPHERAL NERVE CATHETER'
          , 'NERVE BLOCK'
          , 'PARAVERTEBRAL'
          , 'PARAVERTEBRAL NERVE CATHETER'
          , 'PERIPHERAL NERVE BLOCK'
          , 'PERIPHERAL NERVE CATHETER'
          , 'REGIONAL BLOCK'
          , 'SAPHENOUS NERVE'
          , 'SCIATIC / POPLITEAL NERVE'
          , 'SCIATIC PERIPHERAL NERVE CATHETER'
          , 'SUPRACLAVICULAR'
          , 'WOUND PERIPHERAL NERVE CATHETER'
          , 'VIA INFILTRATIVA - BLOQUEOS' -- **REDACTED**
        ) THEN 'PERINEURAL'


      -- PERIODONTAL

      -- RECTAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'COLOSTOMY'
          , 'COLOSTOMY AND MUCUS FISTULA'
          , 'MUCUS FISTULA'
          , 'OSTOMY'
          , 'RECTALLY'
          , 'VIA RECTAL'
          , 'PR'
        ) THEN 'RECTAL'

      -- RESPIRATORY (INHALATION)
        WHEN UPPER(TRIM(med_route_source)) IN (
            'AEROSOLIZED'
          , 'CONT NEB'
          , 'HAND-BULB NEB'
          , 'INH'
          , 'INHALATION'
          , 'INHALED'
          , 'IPPB' -- intermittent positive pressure breathing
          , 'IPV INHALATION'
          , 'MDI' -- Metered dose inhaler???
          , 'NEB'
          , 'NEBULIZATION'
          , 'NEBULIZED INHALATION'
          , 'NEBULIZER'
          , 'VIA NEBULIZER'
          , 'VIA NEBULIZACION'
          , 'VALVED HOLDING CHAMBER'
          , 'VALVED HOLDING CHAMBER AND MASK'
        ) THEN "RESPIRATORY (INHALATION)"

      -- RETROBULBAR

      -- SOFT TISSUE
        WHEN UPPER(TRIM(med_route_source)) IN (
            'INJ INTO SOFT TISS'
        ) THEN "SOFT TISSUE"

      -- SUBARACHNOID

      -- SUBCONJUNCTIVAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'SUB-CONJ'
        ) THEN 'SUBCONJUNCTIVAL'

      -- SUBCUTANEOUS synonymous with SUBDERMAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'CONTIN. SUBCUTANEOUS INFUSION'
          , 'SUBCUT.'
          , 'SUBCUT. INFUSION'
          , 'SUBCUTANEOUS (VIA WEARABLE INJECTOR)'
          , 'SUBCUTANEOUS CATHETER'
          , 'SUBCUTANEOUS INFUSION'
          , 'SUBCUTANEOUSLY'
          , 'SUBDERMAL'
          , 'SUBDERMALLY'
          , 'VIA SUBCUTANEOUS PUMP'
          , 'VIA SUBCUTANEA'
          , 'SC' -- **REDACTED**
        ) THEN 'SUBCUTANEOUS'

      -- SUBLINGUAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'SUBLINGUALLY'
          , 'VIA SUBLINGUAL'
          , 'SL' -- **REDACTED**
        ) THEN 'SUBLINGUAL'

      -- SUBMUCOSAL

      -- TOPICAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'AFFECTED AREA'
          , 'APPLY EXTERNALLY'
          , 'APPLY TO AFFECTED AREA(S)'
          , 'VIA DERMICA O TOPICA' -- **REDACTED**
          , 'EXTERNAL'
          , 'LOCAL WOUND INFILTRATION CATHETER'
          , 'POWDER'
          , 'SKIN PRICK TEST/ORAL'
          , 'SOAK'
          , 'SWAB'
          , 'TOP'
          , 'TOPICAL (TOP)'
          , 'TOPICALLY'
          , 'WOUND CATHETER'
          , 'WOUND SOAK'
          , 'WOUND SOAKER'
        ) THEN "TOPICAL"

      -- TRANSDERMAL

      -- TRANSMUCOSAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'MUCOUS MEM'
          , 'MUCOUS MEMBRANE'
          , 'TRANSMUCOSAL ADM'
        ) THEN 'TRANSMUCOSAL'

      -- TRANSPLACENTAL
      -- TRANSTRACHEAL
      -- TRANSTYMPANIC
      -- UNASSIGNED

      -- UNKNOWN
        WHEN UPPER(TRIM(med_route_source)) IN (
            ''
          , '*'
          , '*UNKNOWN'
          , '*UNSPECIFIED'
          , '-'
          , '250'
          , 'AS INSTRUCTED'
          , 'CABINET'
          , 'IT'
          , 'NOT LISTED'
          , 'RECORDED/NOT ADMINIS'
        ) THEN "UNKNOWN"

      -- URETERAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'VIA URETRAL'
        ) THEN 'URETERAL'

      -- URETHRAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'TRANSURETHRAL'
        ) THEN 'URETHRAL'

      -- VAGINAL
        WHEN UPPER(TRIM(med_route_source)) IN (
            'VIA VAGINAL'
          , 'VAG'
        ) THEN 'VAGINAL'

      -- Custom case for **REDACTED**. Might need to use this for other sites.
        WHEN UPPER(TRIM(med_route_source)) IN (
            'ASSUMED SYSTEMIC'
        ) THEN 'ASSUMED SYSTEMIC'

    END AS med_fda_route,
    0 AS systemic
  FROM `**REDACTED**.full.medication_admin`
);

/* -------------------------------------------------------------------------- */
/*                        -- Define systemic routes --                        */
/* two steps                                                                  */
/* 1) map general fda routes to systemic                                      */
/* 2) specify specific cases when the source route indicates non systemic     */
/* -------------------------------------------------------------------------- */

UPDATE `**REDACTED**.medication.med_route_mapping`
SET systemic = 1
WHERE med_fda_route IN (
    'ASSUMED SYSTEMIC'
  , 'ENTERAL'
  , 'HEMODIALYSIS'
  , 'INTRA-ARTERIAL'
  , 'INTRACARDIAC'
  , 'INTRADUODENAL'
  , 'INTRAGASTRIC'
  , 'INTRAILEAL'
  , 'INTRAMUSCULAR'
  , 'INTRAVASCULAR'
  , 'INTRAVENOUS'
  , 'INTRAVENOUS BOLUS'
  , 'INTRAVENOUS DRIP'
  , 'NASOGASTRIC'
  , 'ORAL'
  , 'OROPHARYNGEAL'
  , 'PARENTERAL'
  , 'RECTAL'
  , 'SUBCUTANEOUS'
)
;

UPDATE `**REDACTED**.medication.med_route_mapping`
SET systemic = 0
WHERE UPPER(TRIM(med_route_source)) IN (
    'ACE'
  , 'ACE STOMA'
  , 'CECOSTOMY'
  , 'CLOTTED CATH'
  , 'GUMS'
  , 'MOUTH/THROAT'
  , 'PE TUBE'
)
;

-- CHECK FOR UNMAPPED ROUTES
SELECT IF(count(1) > 0, ERROR("UNMAPPED ROUTE"), "PASS") AS check_for_unmapped_routes
--SELECT med_route_source
FROM `**REDACTED**.medication.med_route_mapping`
WHERE med_fda_route IS NULL
  AND med_route_source NOT IN ("PV")
;


/*
EXPORT DATA
OPTIONS(
  uri='gs://**REDACTED**/qa/medication_route_mapping*.csv',
  format='CSV',
  overwrite=true,
  header=true,
  field_delimiter=',')
AS
SELECT DISTINCT
    UPPER(TRIM(med_route_source)) as med_route_source
  , med_fda_route
  , systemic
FROM `**REDACTED**.medication.med_route_mapping`
ORDER BY med_route_source
*/
