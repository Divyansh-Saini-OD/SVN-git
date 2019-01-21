SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package BODY XX_CDH_HZ_EXTENSIBILITY_PUB
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_HZ_EXTENSIBILITY_PUB.pkb                    |
-- | Description :  CDH Additional Attributes package                  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Apr-2007 Jeevan Babu        Initial draft version     |
-- |1.1       09-May-2014 Avinash Baddam     Modified for R12
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
x_msg_data                             OUT NOCOPY VARCHAR2)
is 
l_pk_column_values                     EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_class_code_values                    EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_user_privileges_on_object            EGO_VARCHAR_TBL_TYPE; 
begin
    l_pk_column_values :=
      EGO_COL_NAME_VALUE_PAIR_ARRAY(
       EGO_COL_NAME_VALUE_PAIR_OBJ('CUST_ACCOUNT_ID', TO_CHAR(p_cust_account_id))
      );
    
    --changed params by Avinash for R12
    EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data(
      p_api_version                   => 1.0
     ,p_object_name                   => 'XX_CDH_CUST_ACCOUNT'
     ,p_attributes_row_table          => p_attributes_row_table
     ,p_attributes_data_table         => p_attributes_data_table
     ,p_pk_column_name_value_pairs    => l_pk_column_values
     ,p_class_code_name_value_pairs   => l_class_code_values
     ,p_user_privileges_on_object     => l_user_privileges_on_object
     --,p_change_info_table             => null
     --,p_pending_b_table_name          => 'XX_CDH_CUST_ACCT_EXT_B'
     --,p_pending_tl_table_name         => 'XX_CDH_CUST_ACCT_EXT_TL'
     --,p_pending_vl_name               => 'XX_CDH_CUST_ACCT_EXT_VL'
     ,p_entity_id                     => p_entity_id
     ,p_entity_index                  => p_entity_index
     ,p_entity_code                   => p_entity_code
     ,p_debug_level                   => p_debug_level
     ,p_init_error_handler            => p_init_error_handler
     ,p_write_to_concurrent_log       => p_write_to_concurrent_log
     ,p_init_fnd_msg_list             => p_init_fnd_msg_list
     ,p_log_errors                    => p_log_errors
     ,p_add_errors_to_fnd_stack       => p_add_errors_to_fnd_stack
     ,p_commit                        => p_commit
     ,x_failed_row_id_list            => x_failed_row_id_list
     ,x_return_status                 => x_return_status
     ,x_errorcode                     => x_errorcode
     ,x_msg_count                     => x_msg_count
     ,x_msg_data                      => x_msg_data
    );
end Process_Account_Record;
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
x_msg_data                             OUT NOCOPY VARCHAR2)
is 
l_pk_column_values                     EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_class_code_values                    EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_user_privileges_on_object            EGO_VARCHAR_TBL_TYPE; 
begin
    l_pk_column_values :=
      EGO_COL_NAME_VALUE_PAIR_ARRAY(
       EGO_COL_NAME_VALUE_PAIR_OBJ('CUST_ACCT_SITE_ID', TO_CHAR(p_cust_acct_site_id))
      );
      
    EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data(
      p_api_version                   => 1.0
     ,p_object_name                   => 'XX_CDH_CUST_ACCT_SITE'
     ,p_attributes_row_table          => p_attributes_row_table
     ,p_attributes_data_table         => p_attributes_data_table
     ,p_pk_column_name_value_pairs    => l_pk_column_values
     ,p_class_code_name_value_pairs   => l_class_code_values
     ,p_user_privileges_on_object     => l_user_privileges_on_object
     --,p_change_info_table             => null
     --,p_pending_b_table_name          => 'XX_CDH_ACCT_SITE_EXT_B'
     --,p_pending_tl_table_name         => 'XX_CDH_ACCT_SITE_EXT_TL'
     --,p_pending_vl_name               => 'XX_CDH_ACCT_SITE_EXT_VL'
     ,p_entity_id                     => p_entity_id
     ,p_entity_index                  => p_entity_index
     ,p_entity_code                   => p_entity_code
     ,p_debug_level                   => p_debug_level
     ,p_init_error_handler            => p_init_error_handler
     ,p_write_to_concurrent_log       => p_write_to_concurrent_log
     ,p_init_fnd_msg_list             => p_init_fnd_msg_list
     ,p_log_errors                    => p_log_errors
     ,p_add_errors_to_fnd_stack       => p_add_errors_to_fnd_stack
     ,p_commit                        => p_commit
     ,x_failed_row_id_list            => x_failed_row_id_list
     ,x_return_status                 => x_return_status
     ,x_errorcode                     => x_errorcode
     ,x_msg_count                     => x_msg_count
     ,x_msg_data                      => x_msg_data
    );
end Process_Acct_site_Record;
-- +===================================================================+
-- | Name        :  Process_Acct_site_use_Record                       |
-- | Description :  Creates or updates information in extensions tables|
-- |                for Account Site Use.  The XX_CDH_SITE_USES_EXT_B and  |    
-- |                XX_CDH_SITE_USES_EXT_TL tables hold extended,          |
-- |                custom attributes about Account.                   |
-- |                Use this API to maintain records in                |
-- |                these tables for a given Account.                  |
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
x_msg_data                             OUT NOCOPY VARCHAR2)
is 
l_pk_column_values                     EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_class_code_values                    EGO_COL_NAME_VALUE_PAIR_ARRAY;
l_user_privileges_on_object            EGO_VARCHAR_TBL_TYPE; 
begin
    l_pk_column_values :=
      EGO_COL_NAME_VALUE_PAIR_ARRAY(
       EGO_COL_NAME_VALUE_PAIR_OBJ('SITE_USE_ID', TO_CHAR(p_site_use_id))
      );
      
    EGO_USER_ATTRS_DATA_PUB.Process_User_Attrs_Data(
      p_api_version                   => 1.0
     ,p_object_name                   => 'XX_CDH_ACCT_SITE_USES'
     ,p_attributes_row_table          => p_attributes_row_table
     ,p_attributes_data_table         => p_attributes_data_table
     ,p_pk_column_name_value_pairs    => l_pk_column_values
     ,p_class_code_name_value_pairs   => l_class_code_values
     ,p_user_privileges_on_object     => l_user_privileges_on_object
     --,p_change_info_table             => null
     --,p_pending_b_table_name          => 'XX_CDH_SITE_USES_EXT_B'
     --,p_pending_tl_table_name         => 'XX_CDH_SITE_USES_EXT_TL'
     --,p_pending_vl_name               => 'XX_CDH_SITE_USES_EXT_VL'
     ,p_entity_id                     => p_entity_id
     ,p_entity_index                  => p_entity_index
     ,p_entity_code                   => p_entity_code
     ,p_debug_level                   => p_debug_level
     ,p_init_error_handler            => p_init_error_handler
     ,p_write_to_concurrent_log       => p_write_to_concurrent_log
     ,p_init_fnd_msg_list             => p_init_fnd_msg_list
     ,p_log_errors                    => p_log_errors
     ,p_add_errors_to_fnd_stack       => p_add_errors_to_fnd_stack
     ,p_commit                        => p_commit
     ,x_failed_row_id_list            => x_failed_row_id_list
     ,x_return_status                 => x_return_status
     ,x_errorcode                     => x_errorcode
     ,x_msg_count                     => x_msg_count
     ,x_msg_data                      => x_msg_data
    );
end Process_Acct_site_use_Record;

end XX_CDH_HZ_EXTENSIBILITY_PUB;
/
show errors;
EXIT;