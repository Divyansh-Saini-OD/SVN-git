SET VERIFY       OFF
SET ECHO         OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name        :  XX_MON_BILLING_BATCH.grt                             |
-- | Description :  Grant on XX_MON_BILLING_BATCH                        |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      29-FEB-2016    Manikant Kasu        Initial draft version   |
-- +=====================================================================+

PROMPT
PROMPT 'Granting XX_MON_BILLING_BATCH to ERP_SYSTEM_TABLE_SELECT_ROLE...'
PROMPT 
GRANT SELECT ON XX_MON_BILLING_BATCH TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

SHOW ERROR;
EXIT;

