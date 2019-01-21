create or replace
package XX_CRM_EXTN_ATTBT_SYNC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CRM_EXTN_ATTBT_SYNC_PKG.pks                     |
-- | Description :  CDH Additional Attributes package                  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  30-Jul-2007 Kathirvel          Initial draft version     |
-- |1.1       29-Jan-2008 Kathirvel          Included the procedure    |
-- |                                         Process_Person_Record for |
-- |                                         person profile extensible |
-- |                                         Attribute                 |
-- |          29-May-2009 Yusuf Ali          Added new parm, status,   |
-- |                                         to Process_Account_Record |
-- |                                         stored proc               |
-- +===================================================================+
as


-- +========================================================================+
-- | Name        :  Process_Account_Record                                 |
-- | Description :  Creates or updates the information in extensions tables|
-- |                for Account.                                           |
-- +========================================================================+
PROCEDURE Process_Account_Record (
p_cust_account_id                      IN NUMBER, 
p_orig_system                          IN VARCHAR2,
p_orig_sys_reference                   IN VARCHAR2,
p_account_status                       IN VARCHAR2,
p_attr_group_type                      IN VARCHAR2,
p_attr_group_name                      IN VARCHAR2,      
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +========================================================================+
-- | Name        :  Process_Acct_Site_Record                               |
-- | Description :  Creates or updates the information in extensions tables|
-- |                for Account Site.                                      |
-- +========================================================================+
PROCEDURE Process_Acct_Site_Record (
p_acct_site_id                      IN NUMBER, 
p_orig_system                          IN VARCHAR2,
p_orig_sys_reference                   IN VARCHAR2,
p_attr_group_type                      IN VARCHAR2,
p_attr_group_name                      IN VARCHAR2,      
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +==========================================================================+
-- | Name        :  Process_Acct_Site_Use_Record                             |
-- | Description :  Creates or updates the information in extensions tables  |
-- |                for Account Site Use.                                    |
-- +==========================================================================+
PROCEDURE Process_Acct_Site_Use_Record (
p_acct_site_use_id                     IN NUMBER, 
p_orig_system                          IN VARCHAR2,
p_orig_sys_reference                   IN VARCHAR2,
p_attr_group_type                      IN VARCHAR2,
p_attr_group_name                      IN VARCHAR2,      
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

-- +==========================================================================+
-- | Name        :  Process_Person_Record                                    |
-- | Description :  Creates or updates the information in extensions tables  |
-- |                for Person Profile.                                      |
-- +==========================================================================+
PROCEDURE Process_Person_Record (
p_person_id                            IN NUMBER, 
p_person_osr                           IN VARCHAR2,
p_attr_group_type                      IN VARCHAR2,
p_attr_group_name                      IN VARCHAR2,      
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2);

end XX_CRM_EXTN_ATTBT_SYNC_PKG;
/