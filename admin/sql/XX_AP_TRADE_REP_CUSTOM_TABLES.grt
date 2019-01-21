SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   XX_AP_TRADE_REP_CUSTOM_TABLES.grt                         |
-- |  RICE ID  	:   E3522_Custom Tables Grants                           	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      22-03-2018   Digamber S      	    Initial version               |
-- +==========================================================================+
WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

GRANT SELECT ON XX_AP_PO_RECINV_DASHB_GTEMP TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_RECEIPT_PO_TEMP_218 TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_INV_MATCH_DETAIL_219 TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XXAP_CHBK_LINES_TEMP TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT SELECT ON XX_AP_XXAPRTVAPDM_TMP TO ERP_SYSTEM_TABLE_SELECT_ROLE;


GRANT SELECT ON XX_AP_PO_RECINV_DASHB_GTEMP TO APPS;
GRANT SELECT ON XX_AP_RECEIPT_PO_TEMP_218 TO APPS;
GRANT SELECT ON XX_AP_INV_MATCH_DETAIL_219 TO APPS;
GRANT SELECT ON XXAP_CHBK_LINES_TEMP TO APPS;
GRANT SELECT ON XX_AP_XXAPRTVAPDM_TMP TO APPS;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
