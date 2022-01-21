SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XXOD_OMX_CNV_AR_TRX_STG_EV_SYN.vw                                            |
-- | Description : Scripts to create Editioned Views and synonym for object XXOD_OMX_CNV_AR_TRX_STG  |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        07-Aug-2017     Madhu Bolli          Initial version (Defect#OMX AR Conversion)  |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XXOD_OMX_CNV_AR_TRX_STG .....
PROMPT **Edition View creates as XXOD_OMX_CNV_AR_TRX_STG# in XXFIN schema**
PROMPT **Synonym creates as XXOD_OMX_CNV_AR_TRX_STG in apps schema**
PROMPT

exec ad_zd_table.upgrade('XXFIN','XXOD_OMX_CNV_AR_TRX_STG');

SHOW ERRORS;
EXIT;