SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   XX_AP_TRADE_CUSTOM_TABLES.grt                             |
-- |  RICE ID  	:   E3522_Custom Tables Grants                           	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      02-10-2017   Paddy Sanjeevi      	Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_AP_MERCH_CONT_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_MERCH_CONTACTS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_COST_VAR_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_COST_VARIANCE TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_SUPERTRAN_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_TR_MATCH_EXCEPTIONS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_PREVAL_INVOICES_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_RCVWRITE_OFF_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_UIACTION_ERRORS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_CHBK_ACTION_DTL TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_CHBK_ACTION_HDR TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_CHBK_ACTION_HOLDS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT UPDATE ON XX_AP_CHBK_ACTION_HDR TO u510093;
GRANT UPDATE ON XX_AP_CHBK_ACTION_DTL TO u510093;
GRANT UPDATE ON XX_AP_CHBK_ACTION_HOLDS TO u510093;

GRANT ALL ON XX_AP_MERCH_CONT_STG TO APPS;
GRANT ALL ON XX_AP_MERCH_CONTACTS TO APPS;
GRANT ALL ON XX_AP_COST_VAR_STG TO APPS;
GRANT ALL ON XX_AP_COST_VARIANCE TO APPS;
GRANT ALL ON XX_AP_SUPERTRAN_STG TO APPS;
GRANT ALL ON XX_AP_TR_MATCH_EXCEPTIONS TO APPS;
GRANT ALL ON XX_AP_PREVAL_INVOICES_STG TO APPS;
GRANT ALL ON XX_AP_RCVWRITE_OFF_STG TO APPS;
GRANT ALL ON XX_AP_UIACTION_ERRORS TO APPS;
GRANT ALL ON XX_AP_CHBK_ACTION_DTL TO APPS;
GRANT ALL ON XX_AP_CHBK_ACTION_HDR TO APPS;
GRANT ALL ON XX_AP_CHBK_ACTION_HOLDS TO APPS;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
