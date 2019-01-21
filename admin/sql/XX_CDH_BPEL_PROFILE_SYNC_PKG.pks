CREATE OR REPLACE
package XX_CDH_BPEL_PROFILE_SYNC_PKG
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- +======================================================================+
-- | Name        :  XX_CDH_BPEL_PROFILE_SYNC_PKG.pks                     |
-- | Description :  Maintain profile at account level and Account Site   |
-- |                Use (Bill To) level based on the payment term        |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date        Author             Remarks                     |
-- |========  =========== ================== ============================|
-- |DRAFT 1a  26-Jun-2008 Kathirvel          Initial draft version       |
-- |1.1       03-Sep-2008 Kathirvel          Since BO API does not create|
-- |                                         profile ambout by default,  |
-- |                                         this API is made to support |
-- |                                         for BPEL invokation.        |
-- +======================================================================+
as


-- +========================================================================+
-- | Name        :  Process_Profile_Main                                   |
-- | Description :  Process the inputs to create Profile at Account and    |
-- |                Account Site Use level                                 |
-- +========================================================================+

PROCEDURE Process_Profile_Main (
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_site_use_OSR                         IN VARCHAR2,
p_currency_code                        IN VARCHAR2,
p_profile_cls_name                     IN VARCHAR2,
p_status                               IN VARCHAR2,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +===========================================================================+
-- | Name        :  Create_Profile_Details                                    |
-- | Description :  Creates the profile at Account and Site Use level based on| 
-- |                the payment term or profile class name                    |
-- +===========================================================================+

PROCEDURE Create_Profile_Details(
p_profile_rec                          IN  hz_customer_profile_v2pub.customer_profile_rec_type,
p_currency_code                        IN  VARCHAR2,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +================================================================================+
-- | Name        :  Update_Profile_Details                                         |
-- | Description :  Updates the existing profile for Activate or Inactivate purpose|
-- +================================================================================+

PROCEDURE Update_Profile_Details(
p_profile_rec                          IN  hz_customer_profile_v2pub.customer_profile_rec_type,
p_currency_code                        IN  VARCHAR2,
p_object_version                       IN  NUMBER,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +================================================================================+
-- | Name        :  Get_Site_Use_Profile                                         |
-- | Description :  To look up the profile which is store at Site use level      |
-- +================================================================================+

  PROCEDURE Get_Site_Use_Profile (
  p_orig_system                          IN VARCHAR2,
  p_site_use_OSR                         IN VARCHAR2,
  x_profile_id                           OUT NOCOPY NUMBER,
  x_return_status 		           OUT NOCOPY VARCHAR2,
  x_error_message                        OUT NOCOPY VARCHAR2);

end XX_CDH_BPEL_PROFILE_SYNC_PKG;
/