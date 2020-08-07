create or replace PACKAGE BODY XX_COM_ERROR_LOG_PUB
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Oracle Consulting Organization                   |
-- +===================================================================+
-- | Name  :        xx_com_error_log_pub                               |
-- | Description:   Package Body for Common Error Handling Routines    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       22-FEB-2007 A Sahay          Initial version             |
-- +===================================================================+

   -- ------------------------------------------------------------------
   -- Local Procedure
  procedure log_error_details( p_error_log_id            IN NUMBER DEFAULT NULL
                             , p_msg_count               IN NUMBER DEFAULT NULL
                             );

  --------------------------------------------------------------
  -- create procedure for table XX_COM_ERROR_LOG

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
                     )
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;

         ln_error_log_id        NUMBER;
         ln_created_by          NUMBER;
         ln_last_updated_by     NUMBER;
         ln_login_id            NUMBER;

  BEGIN

    -- Set the default value for who columns
    ln_login_id     := NVL(p_last_update_login, FND_GLOBAL.LOGIN_ID);

    IF p_created_by IS NULL
    THEN
        FND_PROFILE.GET('USER_ID',ln_created_by);
    ELSE
        ln_created_by := p_created_by;
    END IF; -- p_created_by IS NULL

    IF p_last_updated_by IS NULL
    THEN
        ln_last_updated_by := ln_created_by;
    ELSE
        ln_last_updated_by := p_last_updated_by;
    END IF; -- p_created_by IS NULL


    SELECT XX_COM_ERROR_LOG_S.NEXTVAL
    INTO   ln_error_log_id
    FROM DUAl;

    INSERT INTO XX_COM_ERROR_LOG
                  ( ERROR_LOG_ID
                  , PROGRAM_TYPE
                  , PROGRAM_NAME
                  , PROGRAM_ID
                  , MODULE_NAME
                  , ERROR_LOCATION
                  , ERROR_MESSAGE_COUNT
                  , ERROR_MESSAGE_CODE
                  , ERROR_MESSAGE
                  , ERROR_MESSAGE_SEVERITY
                  , ERROR_STATUS_FLAG
                  , NOTIFY_FLAG
                  , RECIPIENT
                  , OBJECT_TYPE
                  , OBJECT_ID
                  , ATTRIBUTE1
                  , ATTRIBUTE2
                  , ATTRIBUTE3
                  , ATTRIBUTE4
                  , ATTRIBUTE5
                  , ATTRIBUTE6
                  , ATTRIBUTE7
                  , ATTRIBUTE8
                  , ATTRIBUTE9
                  , ATTRIBUTE10
                  , ATTRIBUTE11
                  , ATTRIBUTE12
                  , ATTRIBUTE13
                  , ATTRIBUTE14
                  , ATTRIBUTE15
                  , ATTRIBUTE16
                  , ATTRIBUTE17
                  , ATTRIBUTE18
                  , ATTRIBUTE19
                  , ATTRIBUTE20
                  , CREATION_DATE
                  , CREATED_BY
                  , LAST_UPDATE_DATE
                  , LAST_UPDATE_LOGIN
                  , LAST_UPDATED_BY)
    VALUES
                  ( ln_error_log_id
                  , p_program_type
                  , p_program_name
                  , p_program_id
                  , p_module_name
                  , p_error_location
                  , p_error_message_count
                  , p_error_message_code
                  , p_error_message
                  , p_error_message_severity
                  , p_error_status
                  , p_notify_flag
                  , p_recipient
                  , p_object_type
                  , p_object_id
                  , p_attribute1
                  , p_attribute2
                  , p_attribute3
                  , p_attribute4
                  , p_attribute5
                  , p_attribute6
                  , p_attribute7
                  , p_attribute8
                  , p_attribute9
                  , p_attribute10
                  , p_attribute11
                  , p_attribute12
                  , p_attribute13
                  , p_attribute14
                  , p_attribute15
                  , p_attribute16
                  , p_attribute17
                  , p_attribute18
                  , p_attribute19
                  , p_attribute20
                  , p_creation_date
                  , ln_created_by
                  , p_last_update_date
                  , ln_login_id
                  , ln_last_updated_by);

   XX_COM_ERROR_LOG_PUB.log_error_details (
        p_error_log_id            => ln_error_log_id
      , p_msg_count               => p_msg_count
      );

    COMMIT;

  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END log_error;

  procedure log_error_details( p_error_log_id            IN NUMBER DEFAULT NULL
                             , p_msg_count               IN NUMBER DEFAULT NULL
                             )
  IS
  BEGIN
    NULL;
  END log_error_details;

  PROCEDURE purge_log(  errbuf           OUT VARCHAR2
                     ,  retcode          OUT VARCHAR2
                     ,  p_days_to_purge  IN NUMBER
                     )
  IS
  BEGIN
    NULL;
  END purge_log;


END XX_COM_ERROR_LOG_PUB;
/
SHOW ERROR