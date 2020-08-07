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

CREATE OR REPLACE PACKAGE XX_COM_OID_ERROR_LOG_PKG
IS
PROCEDURE log_error  ( p_module_name             IN VARCHAR2  DEFAULT NULL
                     , p_error_message           IN VARCHAR2  DEFAULT NULL
                     , p_event_type              IN VARCHAR2  DEFAULT NULL 
                     , p_error_flag              IN VARCHAR2  DEFAULT NULL 
                     , p_fnd_user_name           IN VARCHAR2  DEFAULT NULL 
                     , p_user_guid               IN VARCHAR2  DEFAULT NULL
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
                   );
END XX_COM_OID_ERROR_LOG_PKG;
/