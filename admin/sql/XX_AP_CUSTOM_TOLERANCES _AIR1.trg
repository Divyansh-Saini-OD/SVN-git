
  CREATE OR REPLACE  TRIGGER "APPS"."XX_AP_CUSTOM_TOLERANCES_AIR1" AFTER
INSERT
 ON  "APPS"."XX_AP_CUSTOM_TOLERANCES" FOR EACH ROW 


  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_AP_CUSTOM_TOLERANCES_AIR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  04-FEB-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
  

  DECLARE
  
  BEGIN
INSERT INTO XX_AP_CUST_TOLERANCE_AUD (CUST_TOL_AUD_ID,
VERSIONS_OPERATION,
VERSION_TIMESTAMP,
SUPPLIER_SITE_ID,
LAST_UPDATE_DATE,
LAST_UPDATED_BY,
CREATION_DATE,
CREATED_BY,
FAVOURABLE_PRICE_PCT,
MAX_PRICE_AMT,
MIN_CHARGEBACK_AMT,
MAX_FREIGHT_AMT,
DIST_VAR_NEG_AMT,
DIST_VAR_POS_AMT
) 
VALUES (XX_AP_CUST_TOLERANCE_AUD_SEQ.NEXTVAL
,'I'
,systimestamp
,:new.SUPPLIER_SITE_ID
,:new.LAST_UPDATE_DATE
,:new.LAST_UPDATED_BY
,:new.CREATION_DATE
,:new.CREATED_BY
,:new.FAVOURABLE_PRICE_PCT
,:new.MAX_PRICE_AMT
,:new.MIN_CHARGEBACK_AMT
,:new.MAX_FREIGHT_AMT
,:new.DIST_VAR_NEG_AMT
,:new.DIST_VAR_POS_AMT);


END;



