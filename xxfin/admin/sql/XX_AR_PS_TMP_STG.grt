-- +=====================================================================+
-- |                      Office Depot Inc.                              |
-- +=====================================================================+
-- | Name :  XXFIN.XX_AR_PS_TMP_STG.grt                                  |
-- | Description :    Grant on XXFIN.XX_AR_PS_TMP_STG to APPS.           |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      20-JUL-2015    Manikant Kasu        Initial draft version   |
-- |                                                                     |
-- +=====================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT Grant XXFIN.XX_AR_PS_TMP_STG
PROMPT 
GRANT SELECT ON XXFIN.XX_AR_PS_TMP_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT Grants XXFIN.XX_AR_PS_TMP_STG to APPS
PROMPT   
GRANT ALL ON XXFIN.XX_AR_PS_TMP_STG TO APPS
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