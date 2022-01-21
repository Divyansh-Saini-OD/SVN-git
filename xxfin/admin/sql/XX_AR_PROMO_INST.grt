-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :  XX_AR_PROMO_GRT.grt                                         |
-- | Description :    Grant on xx_ar_promo_cardtypes to APPS.            |
-- |                  Grant on xx_ar_promo_header to APPS.               |
-- |                  Grant on xx_ar_promo_detail to APPS.               |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      05-MAR-2007   Raji Natarajan,       Created base version    |
-- |                       Wipro Technologies                            |
-- |                                                                     |
-- +=====================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_cardtypes TO APPS;
GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_header TO APPS;
GRANT SELECT,INSERT,UPDATE ON xxfin.xx_ar_promo_detail TO APPS;
/
SHOW ERROR

 