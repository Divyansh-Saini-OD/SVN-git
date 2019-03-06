CREATE OR REPLACE
TYPE        "XX_GLB_SITEKEY_REC_TYPE" AS OBJECT (
      locale       VARCHAR2(40)
    , brand        VARCHAR2(40)   -- OD, VIKING, TECH DEPOT
    , site_mode    VARCHAR2(40)   -- BUSINESS, CONSUMER
);
