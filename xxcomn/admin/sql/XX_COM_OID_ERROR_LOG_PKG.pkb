-- +===========================================================================+
-- |                            Office Depot Inc.                              |
-- +===========================================================================+
-- | Name        : XX_COM_OID_ERROR_LOG_PKG                                    |
-- | RICE        :                                                             |
-- |                                                                           |
-- | Description : Capture logs for OID Dip Sync failures                      |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author            Remarks                             |
-- |======== =========== =============     ====================================|
-- | 1.0     22-MAY-2015 Manikant Kasu     Package to capture logs from        |
-- |                                       XX_WF_OID.PutOIDEvent proc as per   |
-- |                                       defect # 33463                      |
-- |                                                                           |
-- +===========================================================================+

create or replace PACKAGE BODY XX_COM_OID_ERROR_LOG_PKG
IS

-- +===================================================================+
-- | Name  : log_error                                                 |
-- | Description      : Function to lg the errors to the commomn error |
-- |                    framework.                                     |
-- |                                                                   |
-- | Parameters :       p_module_name                                  |
-- |                    p_error_message                                |
-- |                    P_EVENT_TYPE                                   |
-- |                    P_ERROR_FLAG                                   |
-- |                    P_FND_USER_NAME                                |
-- |                    P_USER_GUID                                    |
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
  PROCEDURE log_error( p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_error_message           IN VARCHAR2  DEFAULT NULL
                     , P_EVENT_TYPE              IN VARCHAR2  DEFAULT NULL 
                     , P_ERROR_FLAG              IN VARCHAR2  DEFAULT NULL 
                     , P_FND_USER_NAME           IN VARCHAR2  DEFAULT NULL 
                     , P_USER_GUID               IN VARCHAR2  DEFAULT NULL
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
                     , p_last_update_login       IN NUMBER    DEFAULT -1
                     , p_last_updated_by         IN NUMBER    DEFAULT -1
                     )
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;

         ln_error_log_id        NUMBER;
         ln_created_by          NUMBER;
         ln_last_updated_by     NUMBER;
         ln_login_id            NUMBER;

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
    SELECT XX_COM_ERROR_LOG_S.NEXTVAL
    INTO   ln_error_log_id
    FROM   DUAL;

    -- -------------------------------------------------------------
    -- Insert Error into the Errot table
    -- -------------------------------------------------------------
    INSERT INTO XX_COM_OID_ERROR_LOG
                   ( ERROR_LOG_ID
                    ,MODULE_NAME              
                    ,ERROR_MESSAGE            
                    ,EVENT_TYPE               
                    ,ERROR_FLAG               
                    ,FND_USER_NAME            
                    ,USER_GUID                
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
                    ,ATTRIBUTE16              
                    ,ATTRIBUTE17              
                    ,ATTRIBUTE18              
                    ,ATTRIBUTE19
                    ,ATTRIBUTE20
                    ,CREATION_DATE
                    ,CREATED_BY
                    ,LAST_UPDATE_DATE
                    ,LAST_UPDATE_LOGIN
                    ,LAST_UPDATED_BY
                    )
    VALUES
                  (  ln_error_log_id
                    ,P_MODULE_NAME              
                    ,P_ERROR_MESSAGE            
                    ,P_EVENT_TYPE               
                    ,P_ERROR_FLAG               
                    ,P_FND_USER_NAME            
                    ,P_USER_GUID                
                    ,P_ATTRIBUTE1               
                    ,P_ATTRIBUTE2               
                    ,P_ATTRIBUTE3               
                    ,P_ATTRIBUTE4               
                    ,P_ATTRIBUTE5               
                    ,P_ATTRIBUTE6               
                    ,P_ATTRIBUTE7               
                    ,P_ATTRIBUTE8               
                    ,P_ATTRIBUTE9               
                    ,P_ATTRIBUTE10              
                    ,P_ATTRIBUTE11              
                    ,P_ATTRIBUTE12              
                    ,P_ATTRIBUTE13              
                    ,P_ATTRIBUTE14              
                    ,P_ATTRIBUTE15              
                    ,P_ATTRIBUTE16              
                    ,P_ATTRIBUTE17              
                    ,P_ATTRIBUTE18              
                    ,P_ATTRIBUTE19
                    ,P_ATTRIBUTE20
                    ,P_CREATION_DATE
                    ,ln_created_by
                    ,P_LAST_UPDATE_DATE
                    ,ln_login_id
                    ,ln_last_updated_by);

      COMMIT;

  EXCEPTION
     WHEN OTHERS THEN
        NULL;
  END log_error;

END XX_COM_OID_ERROR_LOG_PKG;
/