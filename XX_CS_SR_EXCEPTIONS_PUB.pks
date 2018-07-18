create or replace
PACKAGE XX_CS_SR_EXCEPTIONS_PUB
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Oracle Consulting Organization                   |
-- +===================================================================+
-- | Name  :        XX_OM_SR_EXCEPTIONS_PUB                               |
-- | Description:   Package Bofy for Common Error Handling Routines    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       27-APR-2010 A Sahay          Initial version             |
-- +===================================================================+
-- +===================================================================+
-- | Name  : log_error_details                                         |
-- | Description      : Function to lg the errors to the commomn error |
-- |                    framework.                                     |
-- |                                                                   |
-- | Parameters :       p_return_code                                  |
-- |                    p_msg_count                                    |
-- |                    p_application_name                             |
-- |                    p_program_type                                 |
-- |                    p_program_name                                 |
-- |                    p_program_id                                   |
-- |                    p_module_name                                  |
-- |                    p_error_location                               |
-- |                    p_error_message_count                          |
-- |                    p_error_message_code                           |
-- |                    p_error_message                                |
-- |                    p_error_message_severity                       |
-- |                    p_error_status                                 |
-- |                    p_notify_flag                                  |
-- |                    p_recipient                                    |
-- |                    p_object_type                                  |
-- |                    p_object_id                                    |
-- |                    p_attribute1                                   |
-- |                    p_attribute2                                   |
-- |                    p_attribute3                                   |
-- |                    p_attribute4                                   |
-- |                    p_attribute5                                   |
-- |                    p_attribute6                                   |
-- |                    p_attribute7                                   |
-- |                    p_attribute8                                   |
-- |                    p_attribute9                                   |
-- |                    p_attribute10                                  |
-- |                    p_attribute11                                  |
-- |                    p_attribute12                                  |
-- |                    p_attribute13                                  |
-- |                    p_attribute14                                  |
-- |                    p_attribute15                                  |
-- |                    p_attribute16                                  |
-- |                    p_attribute17                                  |
-- |                    p_attribute18                                  |
-- |                    p_attribute19                                  |
-- |                    p_attribute20                                  |
-- |                    p_creation_date                                |
-- |                    p_created_by                                   |
-- |                    p_last_update_date                             |
-- |                    p_last_updated_by                              |
-- |                    p_last_update_login                            |
-- |                                                                   |
-- | Returns :          None                                           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE log_error( p_application_name        IN VARCHAR2  DEFAULT 'EBS'
                     , p_program_type            IN VARCHAR2  DEFAULT NULL
                     , p_program_name            IN VARCHAR2  DEFAULT NULL
                     , p_program_id              IN NUMBER    DEFAULT NULL
                     , p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_exception_location          IN VARCHAR2  DEFAULT NULL
                     , p_exception_message_count     IN NUMBER    DEFAULT NULL
                     , p_exception_message_code      IN VARCHAR2  DEFAULT NULL
                  --   , p_exception_message           IN VARCHAR2  DEFAULT NULL
                      , p_exception_message           IN CLOB
                     , p_exception_message_severity  IN VARCHAR2  DEFAULT NULL
                     , p_exception_status            IN VARCHAR2  DEFAULT 'LOG_ONLY'
                     , p_notify_flag             IN VARCHAR2  DEFAULT NULL
                     , p_exception_payload       IN VARCHAR2 DEFAULT NULL
                     , p_attribute1              IN VARCHAR2  DEFAULT NULL
                     , p_attribute2              IN VARCHAR2  DEFAULT NULL
                     , p_attribute3              IN VARCHAR2  DEFAULT NULL
                     , p_attribute4              IN VARCHAR2  DEFAULT NULL
                     , p_attribute5              IN VARCHAR2  DEFAULT NULL
                     , p_attribute6              IN VARCHAR2  DEFAULT NULL
                     , p_attribute7              IN VARCHAR2  DEFAULT NULL
                     , p_attribute8              IN VARCHAR2  DEFAULT NULL
                     , p_attribute9              IN VARCHAR2  DEFAULT NULL
                     , p_attribute10             IN VARCHAR2  DEFAULT NULL
                     , p_attribute11             IN VARCHAR2  DEFAULT NULL
                     , p_attribute12             IN VARCHAR2  DEFAULT NULL
                     , p_attribute13             IN VARCHAR2  DEFAULT NULL
                     , p_attribute14             IN VARCHAR2  DEFAULT NULL
                     , p_attribute15             IN VARCHAR2  DEFAULT NULL
                     , p_creation_date           IN DATE      DEFAULT SYSDATE
                     , p_created_by              IN NUMBER    DEFAULT -1
                     , p_last_update_date        IN DATE      DEFAULT SYSDATE
                     , p_last_updated_by         IN NUMBER    DEFAULT -1
                     , p_last_update_login       IN NUMBER    DEFAULT -1
                     , x_retcode                 OUT VARCHAR2
                     , x_ret_status              OUT VARCHAR2
                     );
  PROCEDURE log_error( p_return_code             IN VARCHAR2
                     , p_msg_count               IN NUMBER
                     , p_application_name        IN VARCHAR2  DEFAULT 'EBS'
                     , p_program_type            IN VARCHAR2  DEFAULT NULL
                     , p_program_name            IN VARCHAR2  DEFAULT NULL
                     , p_program_id              IN NUMBER    DEFAULT NULL
                     , p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_exception_location          IN VARCHAR2  DEFAULT NULL
                     , p_exception_message_count     IN NUMBER    DEFAULT NULL
                     , p_exception_message_code      IN VARCHAR2  DEFAULT NULL
                    -- , p_exception_message           IN VARCHAR2  DEFAULT NULL
                     , p_exception_message           IN CLOB
                     , p_exception_message_severity  IN VARCHAR2  DEFAULT NULL
                     , p_exception_status            IN VARCHAR2  DEFAULT 'LOG_ONLY'
                     , p_notify_flag             IN VARCHAR2  DEFAULT NULL
                     , p_exception_payload       IN VARCHAR2 DEFAULT NULL
                     , p_attribute1              IN VARCHAR2  DEFAULT NULL
                     , p_attribute2              IN VARCHAR2  DEFAULT NULL
                     , p_attribute3              IN VARCHAR2  DEFAULT NULL
                     , p_attribute4              IN VARCHAR2  DEFAULT NULL
                     , p_attribute5              IN VARCHAR2  DEFAULT NULL
                     , p_attribute6              IN VARCHAR2  DEFAULT NULL
                     , p_attribute7              IN VARCHAR2  DEFAULT NULL
                     , p_attribute8              IN VARCHAR2  DEFAULT NULL
                     , p_attribute9              IN VARCHAR2  DEFAULT NULL
                     , p_attribute10             IN VARCHAR2  DEFAULT NULL
                     , p_attribute11             IN VARCHAR2  DEFAULT NULL
                     , p_attribute12             IN VARCHAR2  DEFAULT NULL
                     , p_attribute13             IN VARCHAR2  DEFAULT NULL
                     , p_attribute14             IN VARCHAR2  DEFAULT NULL
                     , p_attribute15             IN VARCHAR2  DEFAULT NULL
                     , p_creation_date           IN DATE      DEFAULT SYSDATE
                     , p_created_by              IN NUMBER    DEFAULT -1
                     , p_last_update_date        IN DATE      DEFAULT SYSDATE
                     , p_last_updated_by         IN NUMBER    DEFAULT -1
                     , p_last_update_login       IN NUMBER    DEFAULT -1
                     , x_retcode                 OUT VARCHAR2
                     , x_ret_status              OUT VARCHAR2
                     );                   
END XX_CS_SR_EXCEPTIONS_PUB;
/
show errors;
exit;
