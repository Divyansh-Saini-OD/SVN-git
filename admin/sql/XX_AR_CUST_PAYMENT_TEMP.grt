SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating Grant XX_AR_CUST_PAYMENT_TEMP

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : XX_AR_CUST_PAYMENT_TEMP                                             |
-- | Description : Create grants for the table XX_AR_CUST_PAYMENT_TEMP                 |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date         Author               Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | V1.0     28-Sep-2010  Ganga Devi R          Initial version                       |
-- +===================================================================================+

GRANT ALL ON XXFIN.XX_AR_CUST_PAYMENT_TEMP TO APPS;

/
SHOW ERROR

