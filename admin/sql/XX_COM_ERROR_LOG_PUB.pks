create or replace PACKAGE XX_COM_ERROR_LOG_PUB
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Oracle Consulting Organization                   |
-- +===================================================================+
-- | Name  :        xx_com_error_log_pub                               |
-- | Description:   Package Bofy for Common Error Handling Routines    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       22-FEB-2007 A Sahay          Initial version             |
-- +===================================================================+

  PROCEDURE log_error( p_return_code             IN VARCHAR2  DEFAULT NULL
                     , p_msg_count               IN NUMBER    DEFAULT NULL
                     , p_application_name        IN VARCHAR2  DEFAULT 'EBS'
                     , p_program_type            IN VARCHAR2  DEFAULT NULL
                     , p_program_name            IN VARCHAR2  DEFAULT NULL
                     , p_program_id              IN NUMBER    DEFAULT NULL
                     , p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_error_location          IN VARCHAR2  DEFAULT NULL
                     , p_error_message_count     IN NUMBER    DEFAULT NULL
                     , p_error_message_code      IN VARCHAR2  DEFAULT NULL
                     , p_error_message           IN VARCHAR2  DEFAULT NULL
                     , p_error_message_severity  IN VARCHAR2  DEFAULT NULL
                     , p_error_status            IN VARCHAR2  DEFAULT 'LOG_ONLY'
                     , p_notify_flag             IN VARCHAR2  DEFAULT NULL
                     , p_recipient               IN VARCHAR2  DEFAULT NULL
                     , p_object_type             IN VARCHAR2  DEFAULT NULL
                     , p_object_id               IN VARCHAR2  DEFAULT NULL
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
                     , p_attribute16             IN VARCHAR2  DEFAULT NULL
                     , p_attribute17             IN VARCHAR2  DEFAULT NULL
                     , p_attribute18             IN VARCHAR2  DEFAULT NULL
                     , p_attribute19             IN VARCHAR2  DEFAULT NULL
                     , p_attribute20             IN VARCHAR2  DEFAULT NULL
                     , p_creation_date           IN DATE      DEFAULT SYSDATE
                     , p_created_by              IN NUMBER    DEFAULT -1
                     , p_last_update_date        IN DATE      DEFAULT SYSDATE
                     , p_last_updated_by         IN NUMBER    DEFAULT -1
                     , p_last_update_login       IN NUMBER    DEFAULT -1
                     );

   PROCEDURE purge_log(  errbuf           OUT VARCHAR2
                      ,  retcode          OUT VARCHAR2
                      ,  p_days_to_purge  IN NUMBER
                      );

END XX_COM_ERROR_LOG_PUB;
/
SHOW ERROR