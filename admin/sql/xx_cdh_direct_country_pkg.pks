CREATE OR REPLACE
PACKAGE  xx_cdh_direct_country_pkg
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  xx_cdh_direct_country_pkg.pks                                       |
-- | Description :  The AOPS system allows user to change the country for Direct        |
-- |                customers. BPEL sync has to inactivate the existing account site and|
-- |                the corresponsing OSRs. Also, Avtivate the new account site related |
-- |                entries which are related to the new country.    
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  15-Oct-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

PROCEDURE check_country_main(
                            p_orig_system            IN   VARCHAR2
                          , p_acct_site_osr          IN   VARCHAR2
                          , p_current_country_code   IN   VARCHAR2
			  , p_current_org_id         IN   NUMBER
			  , x_country_change_flg     OUT  NOCOPY   VARCHAR2
			  , x_return_status          OUT  NOCOPY   VARCHAR2
			  , x_error_message          OUT  NOCOPY   VARCHAR2
			  ); 

PROCEDURE inactivate_acct_site(
                            p_acct_site_osr          IN   VARCHAR2
			  , p_current_org_id         IN   NUMBER
			  , x_return_status          OUT  NOCOPY   VARCHAR2
			  , x_error_message          OUT  NOCOPY   VARCHAR2
			  ); 

END xx_cdh_direct_country_pkg;
/