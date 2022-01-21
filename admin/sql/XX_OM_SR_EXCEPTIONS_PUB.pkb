create or replace
PACKAGE BODY XX_OM_SR_EXCEPTIONS_PUB
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Oracle Consulting Organization                   |
-- +===================================================================+
-- | Name  :        XX_OM_SR_EXCEPTIONS_PUB                               |
-- | Description:   Package Body for Common Error Handling Routines    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       27-APR-2010 Bala E           Initial version             |
-- |            						       |
-- +===================================================================+
   -- ------------------------------------------------------------------
   -- Local Procedures
PROCEDURE log_error(  p_application_name        IN VARCHAR2  DEFAULT 'EBS'
                     , p_program_type            IN VARCHAR2  DEFAULT NULL
                     , p_program_name            IN VARCHAR2  DEFAULT NULL
                     , p_program_id              IN NUMBER    DEFAULT NULL
                     , p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_exception_location          IN VARCHAR2  DEFAULT NULL
                     , p_exception_message_count     IN NUMBER    DEFAULT NULL
                     , p_exception_message_code      IN VARCHAR2  DEFAULT NULL
                --     , p_exception_message           IN VARCHAR2  DEFAULT NULL
                     , p_exception_message           IN CLOB
                     , p_exception_message_severity  IN VARCHAR2  DEFAULT NULL
                     , p_exception_status            IN VARCHAR2  DEFAULT 'LOG_ONLY'
                     , p_notify_flag             IN VARCHAR2  DEFAULT NULL
                     , p_exception_payload       IN XMLTYPE 
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
                     )
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
         ln_error_log_id        NUMBER;
         ln_created_by          NUMBER;
         ln_last_updated_by     NUMBER;
         ln_login_id            NUMBER;
         lc_ret_status          VARCHAR2(100);
         lc_ret_code            VARCHAR2(100);
         lc_CLOB_SR                 CLOB;
         lc_XML_SR              XMLType;
  BEGIN
    -- -------------------------------------------------------------
    -- Set the default value for who columns
    -- -------------------------------------------------------------
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
    -- -------------------------------------------------------------
    -- Get the next value for the sequence
    -- -------------------------------------------------------------
    SELECT XXOM.XX_OM_SR_EXCEPTIONS_S.NEXTVAL
    INTO   ln_error_log_id
    FROM   DUAL;
    -- -------------------------------------------------------------
    -- Insert Error into the Errot table
    -- -------------------------------------------------------------
    x_retcode := 'N';
 --   lc_XML_SR := XMLType(p_exception_payload);
    INSERT INTO XX_OM_SR_EXCEPTIONS
                  ( EXCEPTION_ID
                    ,PROCESS_ID
                    ,PROCESS_NAME
                    ,MODULE_NAME
                    ,EXCEPTION_LOCATION
		                ,EXCEPTION_MSG_COUNT
 		                ,EXCEPTION_MSG_CODE
                    ,EXCEPTION_MSG_SEVERITY
                    ,EXCEPTION_MSG
                    ,EXCEPTION_STATUS_FLAG
                    ,NOTIFY_FLAG
                    ,EXCEPTION_PAYLOAD
                    ,ATTRIBUTE1
                    ,ATTRIBUTE2
                    ,ATTRIBUTE3
                    ,ATTRIBUTE4
                    ,ATTRIBUTE5
                    ,ATTRIBUTE6
                    ,ATTRIBUTE7
                    ,ATTRIBUTE8
                    ,ATTRIBUTE9
                    ,ATTRIBUTE10
                    ,ATTRIBUTE11
                    ,ATTRIBUTE12
                    ,ATTRIBUTE13
                    ,ATTRIBUTE14
                    ,ATTRIBUTE15
                    ,CREATION_DATE
                    ,CREATED_BY
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATE_LOGIN
                    ,LAST_UPDATED_BY 
)
   VALUES
                  ( ln_error_log_id
                    ,p_program_id
                    ,p_program_name
                  	,p_program_type
                    ,p_exception_location
                    ,p_exception_message_count
                    ,p_exception_message_code
                    ,p_exception_message_severity
                    ,p_exception_message
                    ,p_exception_status
                    ,p_notify_flag
                    ,p_exception_payload
                 --   ,lc_XML_SR
                    ,p_attribute1
                    ,p_attribute2
                    ,p_attribute3
                    ,p_attribute4
                    ,p_attribute5
                    ,p_attribute6
                    ,p_attribute7
                    ,p_attribute8
                    ,p_attribute9
                    ,p_attribute10
                    ,p_attribute11
                    ,p_attribute12
                    ,p_attribute13
                    ,p_attribute14
                    ,p_attribute15
                    ,p_creation_date
                    ,p_created_by
                    ,p_last_update_date
                    ,p_last_updated_by
                    ,p_last_update_login
); 
     COMMIT;
    x_retcode := 'Y';
  EXCEPTION
     WHEN OTHERS THEN
        x_retcode := 'N';
        x_ret_status := 'Error in Insert ' || sqlerrm ;
  END log_error;
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
                   --  , p_exception_message           IN VARCHAR2  DEFAULT NULL
                     , p_exception_message           IN CLOB
                     , p_exception_message_severity  IN VARCHAR2  DEFAULT NULL
                     , p_exception_status            IN VARCHAR2  DEFAULT 'LOG_ONLY'
                     , p_notify_flag             IN VARCHAR2  DEFAULT NULL 
                     , p_exception_payload       IN XMLTYPE 
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
                     )
  IS
  lc_ret_code VARCHAR2(100);
  lc_ret_status VARCHAR2(1000);
  BEGIN
       XX_OM_SR_EXCEPTIONS_PUB.log_error
                     ( p_application_name        =>  p_application_name
                     , p_program_type            =>  p_program_type
                     , p_program_name            =>  p_program_name
                     , p_program_id              =>  p_program_id
                     , p_module_name             =>  p_module_name
                     , p_exception_location          =>  p_exception_location
                     , p_exception_message_count     =>  NVL(p_exception_message_count,p_exception_message_count)
                     , p_exception_message_code      =>  NVL(p_exception_message_code,p_exception_message_code)
                     , p_exception_message           =>  p_exception_message
                     , p_exception_message_severity  =>  p_exception_message_severity
                     , p_exception_status            =>  p_exception_status
                     , p_notify_flag             =>  p_notify_flag
                     , p_exception_payload      =>   p_exception_payload 
                     , p_attribute1              =>  p_attribute1
                     , p_attribute2              =>  p_attribute2
                     , p_attribute3              =>  p_attribute3
                     , p_attribute4              =>  p_attribute4
                     , p_attribute5              =>  p_attribute5
                     , p_attribute6              =>  p_attribute6
                     , p_attribute7              =>  p_attribute7
                     , p_attribute8              =>  p_attribute8
                     , p_attribute9              =>  p_attribute9
                     , p_attribute10             =>  p_attribute10
                     , p_attribute11             =>  p_attribute11
                     , p_attribute12             =>  p_attribute12
                     , p_attribute13             =>  p_attribute13
                     , p_attribute14             =>  p_attribute14
                     , p_attribute15             =>  p_attribute15
                     , p_creation_date           =>  p_creation_date
                     , p_created_by              =>  p_created_by
                     , p_last_update_date        =>  p_last_update_date
                     , p_last_updated_by         =>  p_last_updated_by
                     , p_last_update_login       =>  p_last_update_login
                     , x_retcode                 => lc_ret_code 
                     , x_ret_status              => lc_ret_status
                     );
  END log_error;  
END XX_OM_SR_EXCEPTIONS_PUB;
/

show errors;
exit;