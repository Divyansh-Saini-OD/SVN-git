SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +===================================================================+
-- |                        Office Depot                               |
-- |                                                                   |
-- +===================================================================+
-- |Name  :  XX_C2T_CC_TOKEN_STG_OE_PMT.grt                            |
-- |Rice  :  C0705                                                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       16-SEP-2015  Havish Kasina      Initial draft version    |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

PROMPT
PROMPT Grant XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT to ERP_SYSTEM_TABLE_SELECT_ROLE
PROMPT    
GRANT SELECT ON XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT Grant XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT to APPS
PROMPT   
GRANT ALL ON XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT TO APPS
/
            
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
