#standardSQL

CREATE OR REPLACE TABLE `**REDACTED**.timecourse.niv` AS
(
  WITH t0 AS (
    SELECT
        tc.site
      , tc.enc_id
      , tc.eclock
      , e.epap_niv_yn
      , e.epap_niv_yn_time
      , i.ipap_niv_yn
      , i.ipap_niv_yn_time
    FROM `**REDACTED**.timecourse.foundation` tc
    LEFT JOIN `**REDACTED**.timecourse.epap_niv` e
    ON tc.site = e.site AND tc.enc_id = e.enc_id AND tc.eclock = e.eclock
    LEFT JOIN `**REDACTED**.timecourse.ipap_niv` i
    ON tc.site = i.site AND tc.enc_id = i.enc_id AND tc.eclock = i.eclock
  )
  , t AS
  (
    SELECT
        site
      , enc_id
      , eclock
      , IF(epap_niv_yn > 0 OR ipap_niv_yn > 0, 1, 0) AS niv
      , COALESCE(epap_niv_yn_time, ipap_niv_yn_time) AS niv_time
    FROM t0
  )

  SELECT
      site
    , enc_id
    , eclock
    ,          LAST_VALUE(niv_time IGNORE NULLS) OVER (PARTITION BY site, enc_id ORDER BY eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)     AS niv_time
    , COALESCE(LAST_VALUE(niv      IGNORE NULLS) OVER (PARTITION BY site, enc_id ORDER BY eclock RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS niv
  FROM t
)
;

-- -------------------------------------------------------------------------- --
-- Set the niv value to NULL if the value is more than six hours old
-- re: **REDACTED**/issues/117
UPDATE `**REDACTED**.timecourse.niv`
SET niv = NULL, niv_time = NULL
WHERE niv_time - eclock > 60 * 6
;

-- -------------------------------------------------------------------------- --
--                                end of file                                 --
-- -------------------------------------------------------------------------- --
