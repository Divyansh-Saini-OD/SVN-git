-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name :  xxfin.XX_RA_INT_SALESCREDITS_ALL.grt                        |
-- | Description :    Grant on xxfin.XX_RA_INT_SALESCREDITS_ALL  to APPS |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      29-MAR-2011    P. Marco             Created base version    |
-- |                                                                     |
-- +=====================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT SELECT,INSERT,UPDATE,DELETE ON xxfin.XX_RA_INT_SALESCREDITS_ALL TO APPS;

/
SHOW ERROR
