SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                           Office Depot Inc.                         |
-- +=====================================================================+
-- | Name        :  XXOM.XX_C2T_CONV_THREADS_RETURNS.grt                 |
-- | Description :  Grant on XXOM.XX_C2T_CONV_THREADS_RETURNS to APPS    |
-- | Rice Id     :  C0705                                                |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      16-SEP-2015    Manikant Kasu        Initial draft version   |
-- +=====================================================================+

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT 'Granting XX_C2T_CONV_THREADS_RETURNS to ERP_SYSTEM_TABLE_SELECT_ROLE...'
PROMPT 
GRANT SELECT ON XXOM.XX_C2T_CONV_THREADS_RETURNS TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT 'Granting XX_C2T_CONV_THREADS_RETURNS to APPS......'
PROMPT   
GRANT ALL ON XXOM.XX_C2T_CONV_THREADS_RETURNS TO APPS
/
           
PROMPT
PROMPT 'Exiting....'
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
