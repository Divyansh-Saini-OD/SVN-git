-- +=====================================================================+
-- |                         Office Depot Inc.                           |
-- +=====================================================================+
-- | RICE ID     :  E2025                                                |
-- | Name        :  XXFIN.XX_MON_TPS.grt                                 |
-- | Description :  Grant on xxfin.XX_MON_TPS to APPS.                   |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      23-APR-2015    Manikant Kasu        Initial draft version   |
-- |                                                                     |
-- +=====================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT
PROMPT 'Granting SELECT ON XXFIN.XX_MON_TPS TO ERP_SYSTEM_TABLE_SELECT_ROLE.....'
PROMPT 
GRANT SELECT ON XXFIN.XX_MON_TPS TO ERP_SYSTEM_TABLE_SELECT_ROLE;

PROMPT
PROMPT 'Granting ALL ON XXFIN.XX_MON_TPS TO APPS.....'
PROMPT   
GRANT ALL ON XXFIN.XX_MON_TPS TO APPS;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
