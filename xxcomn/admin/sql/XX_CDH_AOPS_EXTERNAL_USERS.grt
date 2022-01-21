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
-- | Table Name  :  XX_CDH_AOPS_EXTERNAL_USERS.grt                     |
-- | Rice Name: E1328                                                  |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       31-DEC-2018  Havish Kasina      Initial draft version    |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

SET TERM OFF

SET TERM ON

PROMPT
PROMPT Grant XXCOMN.XX_CDH_AOPS_EXTERNAL_USERS to ERP_SYSTEM_TABLE_SELECT_ROLE
PROMPT    
GRANT SELECT ON XXCOMN.XX_CDH_AOPS_EXTERNAL_USERS TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT Grant XXCOMN.XX_CDH_AOPS_EXTERNAL_USERS to APPS
PROMPT   
GRANT ALL ON XXCOMN.XX_CDH_AOPS_EXTERNAL_USERS TO APPS
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
