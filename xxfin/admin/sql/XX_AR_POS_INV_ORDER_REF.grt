-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name :  XXFIN.XX_AR_POS_INV_ORDER_REF.grt                           |
-- | Description :    Grant on XXFIN.XX_AR_POS_INV_ORDER_REF  to APPS    |
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

GRANT SELECT,INSERT,UPDATE,DELETE ON XXFIN.XX_AR_POS_INV_ORDER_REF TO APPS;

/

SHOW ERROR
