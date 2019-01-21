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
-- | Table Name  :  XX_SCM_BILL_SIGNAL_GRT.grt                         |
-- | Rice Name: I3126                                                  |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       09-OCT-2018  Havish Kasina      Initial draft version    |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

PROMPT
PROMPT Grant XXFIN.XX_SCM_BILL_SIGNAL to ERP_SYSTEM_TABLE_SELECT_ROLE
PROMPT    
GRANT SELECT ON XXFIN.XX_SCM_BILL_SIGNAL TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT Grant XXFIN.XX_SCM_BILL_SIGNAL to APPS
PROMPT   
GRANT ALL ON XXFIN.XX_SCM_BILL_SIGNAL TO APPS
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
