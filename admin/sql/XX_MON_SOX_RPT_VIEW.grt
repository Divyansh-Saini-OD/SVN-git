SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name        :  XX_MON_SOX_RPT.grt                                   |
-- | Description :  Grant on XX_MON_SOX_RPT                              |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      29-FEB-2016    Manikant Kasu        Initial draft version   |
-- +=====================================================================+

PROMPT
PROMPT 'Granting XX_MON_SOX_RPT to ERP_SYSTEM_TABLE_SELECT_ROLE...'
PROMPT 
GRANT SELECT ON XX_MON_SOX_RPT TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

SHOW ERROR;
EXIT;
