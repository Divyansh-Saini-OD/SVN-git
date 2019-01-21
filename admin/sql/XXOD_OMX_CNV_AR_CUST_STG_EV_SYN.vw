SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XXOD_OMX_CNV_AR_CUST_STG_EV_SYN                                              |
-- | Description : Scripts to create Editioned Views and synonym for object XXOD_OMX_CNV_AR_CUST_STG|
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author            Remarks                                        |
-- |=======    ==========      ================  ===============================================|
-- |1.0        04-DEC-2017     Punit Gupta       Initial version(Defect#OMX AR CUST Conversion) |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XXOD_OMX_CNV_AR_CUST_STG .....
PROMPT **Edition View creates as XXOD_OMX_CNV_AR_CUST_STG# in XXFIN schema**
PROMPT **Synonym creates as XXOD_OMX_CNV_AR_CUST_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XXOD_OMX_CNV_AR_CUST_STG');

COMMIT;

SHOW ERRORS;

EXIT;