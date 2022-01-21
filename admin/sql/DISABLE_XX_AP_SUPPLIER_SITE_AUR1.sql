SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name :DISABLE_XX_AP_SUPPLIER_SITE_AUR1                                    |
-- | Description :   Script to Disable Index XX_AP_SUPPLIER_SITE_AUR1          |
-- | Rice ID     :  E3523                                                      |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0      30-AUG-2017      Sridhar G.               Initial draft version  |
-- +===========================================================================+

ALTER TRIGGER XX_AP_SUPPLIER_SITE_AUR1  DISABLE;
SHOW ERRORS;
