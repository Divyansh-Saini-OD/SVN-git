create or replace
package XX_CDH_BPEL_RETAIL_ORG_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_BPEL_RETAIL_ORG_PKG.pks                     |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  14-Jul-2008 Kathirvel          Initial draft version     |
-- +===================================================================+
as


-- +========================================================================+
-- | Name        :  Validate_Org_Main                                       |
-- | Description :  To create site in CA operating unit.                    |
-- |                Called from SaveAddressProcess.                         |
-- +========================================================================+

PROCEDURE Process_Org_Main (
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_acct_site_OSR                        IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_target_aops_country                  IN VARCHAR2,
p_target_site_org_id                   IN NUMBER,          
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +===========================================================================+
-- | Name        :  Process_Org_Details                                        |
-- | Description :  To duplicate site in CA operating unit.                    |
-- |                Called from CreateAccountProcess.                          |
-- +===========================================================================+

PROCEDURE Process_Org_Details(
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_source_site_OSR                      IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_target_org_id                        IN NUMBER,          
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +===========================================================================+
-- | Name        :  Process_Org_Sites                                          |
-- | Description :  To update site in CA operating unit.                       |
-- |                Called from SaveAddressProcess.                            |
-- +===========================================================================+

PROCEDURE Process_Org_Sites(
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_source_site_OSR                      IN VARCHAR2,
p_target_site_OSR                      IN VARCHAR2,
p_status                               IN VARCHAR2,
-- Modified by Kalyan
p_target_country1                      IN VARCHAR2 := NULL,
p_target_country2                      IN VARCHAR2 := NULL,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

end XX_CDH_BPEL_RETAIL_ORG_PKG;
/