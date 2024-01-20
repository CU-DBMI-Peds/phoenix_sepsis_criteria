#standardSQL

-- setup configuration for later use
CREATE OR REPLACE TABLE `**REDACTED**.full.infectious_tests` AS
SELECT *,
  CASE
    WHEN infection_location = 'BLOOD_OR_OTHER' THEN 1
    ELSE 0
    END AS blood_or_other,
  CASE
    WHEN infection_location = 'CSF' THEN 1
    ELSE 0
    END AS csf,
  CASE
    WHEN infection_location = 'GU' THEN 1
    ELSE 0
    END AS gu,
  CASE
    WHEN infection_location = 'RESP' THEN 1
    ELSE 0
    END AS resp
FROM `**REDACTED**.full.infectious_tests_configuration`
;

CREATE OR REPLACE TABLE `**REDACTED**.harmonized.proven_infections` AS
SELECT * EXCEPT (proven_infection),
  CASE
    WHEN proven_infection = 1 AND (
        test_value_source IN ('neg', 'negative', 'n', 'final no growth', 'no fungus isolated', 'no aerobic organisms isolated', 'no anaerobic organisms isolated', 'non-reactive', 'nonreactive', 'not detected', 'none detected', 'none detected.', 'not present')
        OR
        REGEXP_CONTAINS(test_value_source, r'no fungus|no growth|no organisms|no organisms detected|not detected|mixed upper respiratory flora|mixed flora|contains mixed organisms|respiratory flora|skin flora|negative for|negativo para|no beta|no group b|collection method|no ova|not provided|unable to r|no yeast|no antigen|no aerobic|presumptive negative|no a|gram stain:|flora|no b|no c|no e|no gram|no m|no n|no p|no pl|no r|no s|endolimax|normal |wrong|pleural fluid|pericardial fl|equivocal for|isolated to|body fl|acids are not')
        OR
        orig_test_value_source IN ('neg', 'negative', 'n', 'final no growth', 'no fungus isolated', 'no aerobic organisms isolated', 'no anaerobic organisms isolated', 'non-reactive', 'nonreactive', 'not detected', 'none detected', 'none detected.', 'not present')
        OR
        REGEXP_CONTAINS(orig_test_value_source, r'no fungus|no growth|no organisms|no organisms detected|not detected|mixed upper respiratory flora|mixed flora|contains mixed organisms|respiratory flora|skin flora|negative for|negativo para|no beta|no group b|collection method|no ova|not provided|unable to r|no yeast|no antigen|no aerobic|presumptive negative|no a|gram stain:|flora|no b|no c|no e|no gram|no m|no n|no p|no pl|no r|no s|endolimax|normal |wrong|pleural fluid|pericardial fl|equivocal for|isolated to|body fl|acids are not')
        OR
        REGEXP_CONTAINS(test_name_source, r'smear, afb|calcofluor|by latex|cmv igm|antibody igm|ebv vca')
        OR
        -- **REDACTED** specific rules
        orig_test_value_source LIKE '%negative reference range: negative%'
        OR
        orig_test_value_source = 'nasopharyngeal mucous'
        OR
        orig_test_value_source LIKE '%some adenovirus serotypes cannot be effectively detected%'
      )
      THEN 0
    ELSE proven_infection
  END AS proven_infection
FROM (
  SELECT *,
  CASE
    WHEN (test_value_source IN ('y', 'yes', '+', 'pos', 'positive', 'positivo', 'posititve', 'positve', 'postitive', 'postive', 'postive', 'detected', 'p', 'abnormal', 'reactive', 'cre')
      OR orig_test_value_source IN ('y', 'yes', '+', 'pos', 'positive', 'positivo', 'posititve', 'positve', 'postitive', 'postive', 'postive', 'detected', 'p', 'abnormal', 'reactive', 'cre'))
      AND test_name_source NOT LIKE '%qc-%'
      THEN 1
    WHEN (
        test_value_source LIKE '%cfu/ml%' OR
        test_value_source LIKE '%greater than%' OR
        orig_test_value_source LIKE '%cfu/ml%' OR
        orig_test_value_source LIKE '%greater than%'
      )
      AND test_value_source NOT LIKE '%respiratory flora%'
      AND test_name_source NOT LIKE '%urine%'
      THEN 1
    WHEN (
        test_value_source LIKE '%>100,000 cfu/ml%' OR
        test_value_source LIKE '%greater than 100,000 cfu/ml%' OR
        orig_test_value_source LIKE '%>100,000 cfu/ml%' OR
        orig_test_value_source LIKE '%greater than 100,000 cfu/ml%'
      )
      AND test_name_source LIKE '%urine%'
      THEN 1
    WHEN (
        REGEXP_CONTAINS(test_value_source, r'acre|acnes|actino|amoeba|anaerobes|anaerobic|anerobes iso|anus|asc|aspergillus|atis|avium|avidus|baum|bacill|bacteroides|bacterium|beta|blasto|burk|candida|cata|chlam|citre|clost|cocc|coli|coryn|crypto|detected|diph|ella|elmii|entero|erans|ercia|escens|esch|ettii|faec|frag|fungus|gram|haem|hemolytic col|herpes simplex |hsv|icus|influenz|kleb|kristinae|lactose|lamblia| log|fermenter|magn|meth|milleri|mixed a|mold|muco|myce|neis|obacter|onas|ophilus|ochro|oplasma|orans|osus|oxida|parasite|pert|phyte|plasmo|pista|pos |positive |positivo |presumptive|propion|prot|prov|ralis|rdia|rhod|rhizo|rod|rothia|septic|serr|shig|species| sp|spor|spp|staph|strep|togenes|troph|trich|unable to|weak pos|vir|yeast')
        OR REGEXP_CONTAINS(orig_test_value_source, r'acre|acnes|actino|amoeba|anaerobes|anaerobic|anerobes iso|anus|asc|aspergillus|atis|avium|avidus|baum|bacill|bacteroides|bacterium|beta|blasto|burk|candida|cata|chlam|citre|clost|cocc|coli|coryn|crypto|detected|diph|ella|elmii|entero|erans|ercia|escens|esch|ettii|faec|frag|fungus|gram|haem|hemolytic col|herpes simplex |hsv|icus|influenz|kleb|kristinae|lactose|lamblia| log|fermenter|magn|meth|milleri|mixed a|mold|muco|myce|neis|obacter|onas|ophilus|ochro|oplasma|orans|osus|oxida|parasite|pert|phyte|plasmo|pista|pos |positive |positivo |presumptive|propion|prot|prov|ralis|rdia|rhod|rhizo|rod|rothia|septic|serr|shig|species| sp|spor|spp|staph|strep|togenes|troph|trich|unable to|weak pos|vir|yeast')
      )
      AND test_name_source NOT LIKE '%gram stain%'
      THEN 1
    WHEN test_value_source LIKE '%enrichment broth only%'
      OR orig_test_value_source LIKE '%enrichment broth only%'
      THEN 1
    WHEN
      REGEXP_CONTAINS(test_name_source, r'ebv pcr quant value| log|ebv dna|ebv viral load|cmv pcr quant value')
      AND test_value_source IS NOT NULL
      AND SAFE_CAST(test_value_source AS FLOAT64) IS NOT NULL
    THEN 1
    ELSE 0
    END AS proven_infection
  FROM (
  SELECT t.* EXCEPT(test_name_source, test_value_source, orig_test_value_source),
    c.* EXCEPT(test_name),
    TRIM(LOWER(test_name_source)) AS test_name_source,
    TRIM(LOWER(test_value_source)) AS test_value_source,
    TRIM(LOWER(orig_test_value_source)) AS orig_test_value_source,
  FROM `**REDACTED**.harmonized.tests` t
  INNER JOIN `**REDACTED**.full.infectious_tests` c
     ON t.test_name = c.test_name
  )
)
;