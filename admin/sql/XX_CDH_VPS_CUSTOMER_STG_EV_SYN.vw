SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_VPS_CUSTOMER_STG_EV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XX_CDH_VPS_CUSTOMER_STG|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        31-JUL-2017     Thejaswini Rajula          Initial version         				|
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_CDH_VPS_CUSTOMER_STG .....
PROMPT **Edition View creates as XX_CDH_VPS_CUSTOMER_STG# in XXCRM schema**
PROMPT **Synonym creates as XX_CDH_VPS_CUSTOMER_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXCRM','XX_CDH_VPS_CUSTOMER_STG');

SHOW ERRORS;
EXIT;