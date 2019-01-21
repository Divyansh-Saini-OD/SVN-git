SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OD_HZ_UTILITY
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_HZ_UTILITY                                            |
-- | Description :                                                             |
-- | This package helps us to get the Site uses for the Account Site addresses |
-- | This is developed to fix Defect # 28196 to get rid of the multiple rows   |
-- | that were returned by joining the VO query with hz_cust_site_uses_all     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      28-Feb-2014 Shubhashree R Initial version                         |
-- |                                                                           |
-- +===========================================================================+
AS
-- +===========================================================================+
-- |                                                                           |
-- | Name        : get_cust_site_uses                                          |
-- |                                                                           |
-- | Description :                                                             |
-- | This Function returms comma separated string of distinct locations        |
-- |                                                                           |
-- |                                                                           |
-- | Parameters  :      cust_acct_site_id                                      |
-- |                                                                           |
-- |                                                                           |
-- | Returns     :                                                             |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
FUNCTION get_cust_site_locations (  p_cust_acct_site_id                         IN     NUMBER)
RETURN VARCHAR2;

END XX_OD_HZ_UTILITY;
/

SHOW ERROR;