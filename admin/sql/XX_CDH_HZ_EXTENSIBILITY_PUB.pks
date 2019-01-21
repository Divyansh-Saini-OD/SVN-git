SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package XX_CDH_HZ_EXTENSIBILITY_PUB
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_HZ_EXTENSIBILITY_PUB.pks                    |
-- | Description :  CDH Additional Attributes package                  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Apr-2007 Jeevan Babu        Initial draft version     |
-- +===================================================================+
is 


-- +===================================================================+
-- | Name        :  Process_Account_Record                             |
-- | Description :  Creates or updates information in extensions tables|
-- |                for Account.  The XX_CDH_CUST_ACCT_EXT_B and           |
-- |                XX_CDH_CUST_ACCT_EXT_TL tables hold extended,          |
-- |                custom attributes about Account.                   |
-- |                Use this API to maintain records in                |
-- |                these tables for a given Account.                  |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_Account_Record (
p_api_version                          IN NUMBER,
p_cust_account_id                      IN NUMBER,
p_attributes_row_table                 IN EGO_USER_ATTR_ROW_TABLE,
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
p_change_info_table                    IN EGO_USER_ATTR_CHANGE_TABLE DEFAULT NULL,
p_entity_id                            IN NUMBER DEFAULT NULL,
p_entity_index                         IN NUMBER DEFAULT NULL,
p_entity_code                          IN VARCHAR2 DEFAULT NULL,
p_debug_level                          IN NUMBER DEFAULT 0,
p_init_error_handler                   IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_write_to_concurrent_log              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_init_fnd_msg_list                    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_log_errors                           IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_add_errors_to_fnd_stack              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_commit                               IN VARCHAR2 DEFAULT FND_API.G_FALSE,
x_failed_row_id_list                   OUT NOCOPY VARCHAR2,
x_return_status                        OUT NOCOPY VARCHAR2,
x_errorcode                            OUT NOCOPY NUMBER,
x_msg_count                            OUT NOCOPY NUMBER,
x_msg_data                             OUT NOCOPY VARCHAR2);
-- +===================================================================+
-- | Name        :  Process_Acct_site_Record                           |
-- | Description :  Creates or updates information in extensions tables|
-- |                for Account Site.  The XX_CDH_ACCT_SITE_EXT_B and      |     
-- |                XX_CDH_ACCT_SITE_EXT_TL tables hold extended,          |
-- |                custom attributes about Account Site.              |
-- |                Use this API to maintain records in                |
-- |                these tables for a given Account Site.             |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_Acct_site_Record (
p_api_version                          IN NUMBER,
p_cust_acct_site_id                    IN NUMBER,
p_attributes_row_table                 IN EGO_USER_ATTR_ROW_TABLE,
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
p_change_info_table                    IN EGO_USER_ATTR_CHANGE_TABLE DEFAULT NULL,
p_entity_id                            IN NUMBER DEFAULT NULL,
p_entity_index                         IN NUMBER DEFAULT NULL,
p_entity_code                          IN VARCHAR2 DEFAULT NULL,
p_debug_level                          IN NUMBER DEFAULT 0,
p_init_error_handler                   IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_write_to_concurrent_log              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_init_fnd_msg_list                    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_log_errors                           IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_add_errors_to_fnd_stack              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_commit                               IN VARCHAR2 DEFAULT FND_API.G_FALSE,
x_failed_row_id_list                   OUT NOCOPY VARCHAR2,
x_return_status                        OUT NOCOPY VARCHAR2,
x_errorcode                            OUT NOCOPY NUMBER,
x_msg_count                            OUT NOCOPY NUMBER,
x_msg_data                             OUT NOCOPY VARCHAR2);
-- +===================================================================+
-- | Name        :  Process_Acct_site_use_Record                       |
-- | Description :  Creates or updates information in extensions tables|
-- |                for Account Site Use.  The XX_CDH_SITE_USES_EXT_B and  |    
-- |                XX_CDH_SITE_USES_EXT_TL tables hold extended,          |
-- |                custom attributes about Account.                   |
-- |                Use this API to maintain records in                |
-- |                these tables for a given Account.                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Process_Acct_site_use_Record (
p_api_version                          IN NUMBER,
p_site_use_id                          IN NUMBER,
p_attributes_row_table                 IN EGO_USER_ATTR_ROW_TABLE,
p_attributes_data_table                IN EGO_USER_ATTR_DATA_TABLE,
p_change_info_table                    IN EGO_USER_ATTR_CHANGE_TABLE DEFAULT NULL,
p_entity_id                            IN NUMBER DEFAULT NULL,
p_entity_index                         IN NUMBER DEFAULT NULL,
p_entity_code                          IN VARCHAR2 DEFAULT NULL,
p_debug_level                          IN NUMBER DEFAULT 0,
p_init_error_handler                   IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_write_to_concurrent_log              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_init_fnd_msg_list                    IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_log_errors                           IN VARCHAR2 DEFAULT FND_API.G_TRUE,
p_add_errors_to_fnd_stack              IN VARCHAR2 DEFAULT FND_API.G_FALSE,
p_commit                               IN VARCHAR2 DEFAULT FND_API.G_FALSE,
x_failed_row_id_list                   OUT NOCOPY VARCHAR2,
x_return_status                        OUT NOCOPY VARCHAR2,
x_errorcode                            OUT NOCOPY NUMBER,
x_msg_count                            OUT NOCOPY NUMBER,
x_msg_data                             OUT NOCOPY VARCHAR2);

end XX_CDH_HZ_EXTENSIBILITY_PUB;
/
show errors;
EXIT;