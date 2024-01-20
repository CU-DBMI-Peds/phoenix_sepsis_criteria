#standardSQL
-- formula for VIS is in gaies 2010

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.vis` AS (
  WITH t0 AS
  (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock


      , dobutamine.dobutamine
      , dobutamine.dobutamine_yn
      , dopamine.dopamine
      , dopamine.dopamine_yn
      , epinephrine.epinephrine
      , epinephrine.epinephrine_yn
      , milrinone.milrinone
      , milrinone.milrinone_yn
      , norepinephrine.norepinephrine
      , norepinephrine.norepinephrine_yn
      , vasopressin.vasopressin
      , vasopressin.vasopressin_yn

    FROM `**REDACTED**.timecourse.foundation` tc

    LEFT JOIN `**REDACTED**.timecourse.dobutamine` dobutamine
    ON tc.site = dobutamine.site AND tc.enc_id = dobutamine.enc_id AND tc.eclock = dobutamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.dopamine` dopamine
    ON tc.site = dopamine.site AND tc.enc_id = dopamine.enc_id AND tc.eclock = dopamine.eclock

    LEFT JOIN `**REDACTED**.timecourse.epinephrine` epinephrine
    ON tc.site = epinephrine.site AND tc.enc_id = epinephrine.enc_id AND tc.eclock = epinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.milrinone` milrinone
    ON tc.site = milrinone.site AND tc.enc_id = milrinone.enc_id AND tc.eclock = milrinone.eclock

    LEFT JOIN `**REDACTED**.timecourse.norepinephrine` norepinephrine
    ON tc.site = norepinephrine.site AND tc.enc_id = norepinephrine.enc_id AND tc.eclock = norepinephrine.eclock

    LEFT JOIN `**REDACTED**.timecourse.vasopressin` vasopressin
    ON tc.site = vasopressin.site AND tc.enc_id = vasopressin.enc_id AND tc.eclock = vasopressin.eclock
  )
  ,
  t AS
  (
    SELECT
        enc_id
      , eclock
      , (       dopamine +
                dobutamine +
          100 * epinephrine +
           10 * milrinone +
        10000 * vasopressin +
          100 * norepinephrine ) AS vis
      , (       COALESCE(dopamine, 0) +
                COALESCE(dobutamine, 0) +
          100 * COALESCE(epinephrine, 0) +
           10 * COALESCE(milrinone, 0) +
        10000 * COALESCE(vasopressin, 0) +
          100 * COALESCE(norepinephrine, 0) ) AS vis_min
      , dopamine_yn + dobutamine_yn + epinephrine_yn + milrinone_yn + vasopressin_yn AS vis_b_count
      , IF(dopamine_yn + dobutamine_yn + epinephrine_yn + milrinone_yn + vasopressin_yn > 0, 1, 0) AS vis_b
    FROM t0
  )

  SELECT
      tc.site
    , tc.enc_id
    , tc.eclock
    , t.vis_min
    , t.vis
    , t.vis_b
    , t.vis_b_count
  FROM `**REDACTED**.timecourse.foundation` tc
  LEFT JOIN t
  ON tc.enc_id = t.enc_id AND tc.eclock = t.eclock
)
;

-- aggregate for specific aims
CALL **REDACTED**.sa.aggregate("vis", "vis_min");
CALL **REDACTED**.sa.aggregate("vis", "vis_b");
CALL **REDACTED**.sa.aggregate("vis", "vis_b_count");
