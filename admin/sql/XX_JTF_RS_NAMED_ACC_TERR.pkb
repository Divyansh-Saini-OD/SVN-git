SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_RS_NAMED_ACC_TERR package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_RS_NAMED_ACC_TERR
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_RS_NAMED_ACC_TERR                                      |
-- |                                                                                   |
-- | Description      :  This custom package will be used to insert record in the three|
-- |                     custom assignment tables XX_TM_NAM_TERR_DEFN,                 |
-- |                     XX_TM_NAM_TERR_RSC_DTLS and  XX_TM_NAM_TERR_ENTITY_DTLS.      |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    Insert_Row            This is the public procedure.                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  25-Sep-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
-----------------------------
-- Declaring local variables
-----------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;

-- +===================================================================+
-- | Name  : Insert_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    insert record in the three custom assignment   |
-- |                    tables XX_TM_NAM_TERR_DEFN,                    |
-- |                    XX_TM_NAM_TERR_RSC_DTLS and                    |
-- |                    XX_TM_NAM_TERR_ENTITY_DTLS                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE insert_row
            (
             p_api_version            IN NUMBER
             , p_start_date_active    IN DATE     DEFAULT SYSDATE
             , p_end_date_active      IN DATE     DEFAULT NULL
             , p_named_acct_terr_id   IN NUMBER   DEFAULT NULL
             , p_named_acct_terr_name IN VARCHAR2 DEFAULT NULL
             , p_named_acct_terr_desc IN VARCHAR2 DEFAULT NULL
             , p_full_access_flag     IN VARCHAR2 DEFAULT NULL
             , p_source_terr_id       IN NUMBER   DEFAULT NULL
             , p_resource_id          IN NUMBER   DEFAULT NULL
             , p_role_id              IN NUMBER   DEFAULT NULL
             , p_group_id             IN NUMBER   DEFAULT NULL
             , p_entity_type          IN VARCHAR2 DEFAULT NULL
             , p_entity_id            IN NUMBER   DEFAULT NULL
             , x_return_status        OUT NOCOPY  VARCHAR2
             , x_msg_count            OUT NOCOPY  NUMBER
             , x_message_data         OUT NOCOPY  VARCHAR2
            )
IS
-----------------------------
-- Declaring Local Constants
-----------------------------
l_api_version_number  CONSTANT NUMBER := 1.0;
l_api_name            CONSTANT VARCHAR2(30) := 'INSERT_ROW';

-----------------------------
-- Declaring local variables
-----------------------------
EX_INSERT_ROW                EXCEPTION;
ln_named_acct_terr_id        PLS_INTEGER;
lc_resc_exists               VARCHAR2(03);
lc_entity_exists             VARCHAR2(03);
lc_error_message             VARCHAR2(1000);
lc_set_message               VARCHAR2(2000);
lc_terr_exists               VARCHAR2(03);

BEGIN

   -- Initialize message list

   FND_MSG_PUB.initialize;

   --  Initialize API return status to success

   x_return_status := fnd_api.g_ret_sts_success;

   -- Standard call to check for call compatibility.

   IF NOT fnd_api.compatible_api_call(
                                      p_current_version_number  => l_api_version_number
                                      , p_caller_version_number => p_api_version
                                      , p_api_name              => l_api_name
                                      , p_pkg_name              => 'XX_JTF_RS_NAMED_ACC_TERR'
                                      )
   THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
   END IF;

   IF p_named_acct_terr_id IS NULL THEN

      BEGIN

         -- Derive the value of named_acct_terr_id from the sequence

         SELECT xx_tm_nam_terr_defn_s.NEXTVAL
         INTO   ln_named_acct_terr_id
         FROM   dual;

         -- Insert a row into the XX_TM_NAM_TERR_DEFN

         INSERT INTO xx_tm_nam_terr_defn(
                                         named_acct_terr_id
                                         , named_acct_terr_name
                                         , named_acct_terr_desc
                                         , status
                                         , start_date_active
                                         , end_date_active
                                         , source_territory_id
                                         , created_by
                                         , creation_date
                                         , last_updated_by
                                         , last_update_date
                                         , last_update_login
                                        )
                                  VALUES(
                                         ln_named_acct_terr_id
                                         , p_named_acct_terr_name
                                         , p_named_acct_terr_desc
                                         , 'A'
                                         , p_start_date_active
                                         , p_end_date_active
                                         , p_source_terr_id
                                         , FND_GLOBAL.USER_ID
                                         , SYSDATE
                                         , FND_GLOBAL.USER_ID
                                         , SYSDATE
                                         , FND_GLOBAL.USER_ID
                                        );

         WRITE_LOG('Territory successfully created. Territory ID = '|| ln_named_acct_terr_id);

      EXCEPTION
         WHEN OTHERS THEN
             x_return_status  := FND_API.G_RET_STS_ERROR;
             FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
             lc_set_message  :=  'In Procedure:INSERT_ROW: Unexpected Error while inserting record into XX_TM_NAM_TERR_DEFN: ';
             FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
             FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
             lc_error_message := FND_MESSAGE.GET;
             WRITE_LOG(lc_error_message);
             FND_MSG_PUB.add;
             XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                p_return_code              => FND_API.G_RET_STS_ERROR
                                                , p_application_name       => G_APPLICATION_NAME
                                                , p_program_type           => G_PROGRAM_TYPE
                                                , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                , p_program_id             => gn_program_id
                                                , p_module_name            => G_MODULE_NAME
                                                , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                , p_error_message          => lc_error_message
                                                , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                , p_error_status           => G_ERROR_STATUS_FLAG
                                               );
             RAISE EX_INSERT_ROW;
      END;

   ELSE

       BEGIN

            SELECT 'Y'
            INTO   lc_terr_exists
            FROM   xx_tm_nam_terr_defn XTTD
            WHERE  XTTD.named_acct_terr_id = p_named_acct_terr_id
            AND    SYSDATE BETWEEN XTTD.start_date_active and NVL(XTTD.end_date_active,SYSDATE)
            AND    NVL(XTTD.status,'A') = 'A';

       EXCEPTION
          WHEN OTHERS THEN
              lc_terr_exists := NULL;
       END;

       IF lc_terr_exists = NULL THEN
         x_return_status  := FND_API.G_RET_STS_ERROR;
         FND_MESSAGE.set_name('XXCRM','XX_TM_0139_NO_NAMEDACT_TERR_ID');
         FND_MESSAGE.SET_TOKEN('P_NAMED_ACCT_TERR_ID', p_named_acct_terr_id);
         lc_error_message := FND_MESSAGE.GET;
         WRITE_LOG(lc_error_message);
         FND_MSG_PUB.add;
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                            , p_application_name       => G_APPLICATION_NAME
                                            , p_program_type           => G_PROGRAM_TYPE
                                            , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                            , p_program_id             => gn_program_id
                                            , p_module_name            => G_MODULE_NAME
                                            , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                            , p_error_message_code     => 'XX_TM_0139_NO_NAMEDACT_TERR_ID'
                                            , p_error_message          => lc_error_message
                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                           );
         RAISE EX_INSERT_ROW;

       ELSE

           ln_named_acct_terr_id := p_named_acct_terr_id;
           WRITE_LOG('Territory already exists. Territory ID = '|| ln_named_acct_terr_id);

       END IF; -- lc_terr_exists = NULL

   END IF; -- p_named_acct_terr_id IS NULL

   lc_error_message := NULL;
   lc_set_message   := NULL;

   -- Check whether the resource exists for the named_acct_terr_id

   IF p_resource_id IS NOT NULL THEN

     BEGIN

        SELECT 'Y'
        INTO   lc_resc_exists
        FROM   xx_tm_nam_terr_rsc_dtls XTNT
        WHERE  XTNT.named_acct_terr_id = ln_named_acct_terr_id
        AND    XTNT.resource_id = p_resource_id
        AND    XTNT.resource_role_id = p_role_id
        AND    XTNT.group_id = p_group_id
        AND    SYSDATE BETWEEN XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE)
        AND    NVL(XTNT.status,'A') = 'A';

     EXCEPTION
        WHEN OTHERS THEN
            lc_resc_exists := NULL;
     END;

     IF lc_resc_exists IS NULL THEN

       -- Insert a row into the XX_TM_NAM_TERR_RSC_DTLS

       BEGIN

          INSERT INTO xx_tm_nam_terr_rsc_dtls(
                                              named_acct_terr_rsc_id
                                              , named_acct_terr_id
                                              , resource_id
                                              , resource_role_id
                                              , group_id
                                              , status
                                              , start_date_active
                                              , end_date_active
                                              , created_by
                                              , creation_date
                                              , last_updated_by
                                              , last_update_date
                                              , last_update_login
                                             )
                                       VALUES(
                                              xx_tm_nam_terr_rsc_dtls_s.NEXTVAL
                                              , ln_named_acct_terr_id
                                              , p_resource_id
                                              , p_role_id
                                              , p_group_id
                                              , 'A'
                                              , p_start_date_active
                                              , p_end_date_active
                                              , FND_GLOBAL.USER_ID
                                              , SYSDATE
                                              , FND_GLOBAL.USER_ID
                                              , SYSDATE
                                              , FND_GLOBAL.USER_ID
                                             );

          WRITE_LOG('Resource created in the territory : '|| ln_named_acct_terr_id);

       EXCEPTION
          WHEN OTHERS THEN
              x_return_status   := FND_API.G_RET_STS_ERROR;
              FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
              lc_set_message  :=  'In Procedure:INSERT_ROW: Unexpected Error while inserting record into XX_TM_NAM_TERR_RSC_DTLS : ';
              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
              lc_error_message := FND_MESSAGE.GET;
              WRITE_LOG(lc_error_message);
              FND_MSG_PUB.add;
              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                 , p_application_name       => G_APPLICATION_NAME
                                                 , p_program_type           => G_PROGRAM_TYPE
                                                 , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                 , p_program_id             => gn_program_id
                                                 , p_module_name            => G_MODULE_NAME
                                                 , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                 , p_error_message          => lc_error_message
                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                );
              RAISE EX_INSERT_ROW;
       END;

     ELSE
         WRITE_LOG('Resource already exists in the territory : '|| ln_named_acct_terr_id);
     END IF;

   END IF;

   -- Check whether the entity_type and entity exists for the named_acct_terr_id
   lc_error_message := NULL;
   lc_set_message   := NULL;

   IF p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL THEN

     BEGIN

       SELECT 'Y'
       INTO   lc_entity_exists
       FROM   xx_tm_nam_terr_entity_dtls XTTE
       WHERE  XTTE.named_acct_terr_id = p_named_acct_terr_id
       AND    XTTE.entity_type = p_entity_type
       AND    XTTE.entity_id = p_entity_id
       AND    SYSDATE BETWEEN XTTE.start_date_active and NVL(XTTE.end_date_active,SYSDATE)
       AND    NVL(XTTE.status,'A') = 'A';

     EXCEPTION
        WHEN OTHERS THEN
            lc_entity_exists := NULL;
     END;

     IF lc_entity_exists = 'Y' THEN

       WRITE_LOG('Entity with entity_type = '||p_entity_type||' and entity_id = '||p_entity_id||'
                        already exists in the territory : '||ln_named_acct_terr_id);


     ELSE

         -- Insert a row into the XX_TM_NAM_TERR_ENTITY_DTLS

         BEGIN

              INSERT INTO xx_tm_nam_terr_entity_dtls(
                                                     named_acct_terr_entity_id
                                                     , named_acct_terr_id
                                                     , entity_type
                                                     , entity_id
                                                     , status
                                                     , start_date_active
                                                     , end_date_active
                                                     , full_access_flag
                                                     , created_by
                                                     , creation_date
                                                     , last_updated_by
                                                     , last_update_date
                                                     , last_update_login
                                                    )
                                              VALUES(
                                                     xx_tm_nam_terr_entity_dtls_s.NEXTVAL
                                                     , ln_named_acct_terr_id
                                                     , p_entity_type
                                                     , p_entity_id
                                                     , 'A'
                                                     , p_start_date_active
                                                     , p_end_date_active
                                                     , p_full_access_flag
                                                     , FND_GLOBAL.USER_ID
                                                     , SYSDATE
                                                     , FND_GLOBAL.USER_ID
                                                     , SYSDATE
                                                     , FND_GLOBAL.USER_ID
                                                    );
              WRITE_LOG('Entity with entity_type = '||p_entity_type||' and entity_id = '||p_entity_id||'
                        is created in the territory : '||ln_named_acct_terr_id);

         EXCEPTION
            WHEN OTHERS THEN
                x_return_status  := FND_API.G_RET_STS_ERROR;
                FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                lc_set_message  :=  'In Procedure:INSERT_ROW: Unexpected Error while inserting record into XX_TM_NAM_TERR_ENTITY_DTLS : ';
                FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
                FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                lc_error_message := FND_MESSAGE.GET;
                WRITE_LOG(lc_error_message);
                FND_MSG_PUB.add;
                XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                   p_return_code              => FND_API.G_RET_STS_ERROR
                                                   , p_application_name       => G_APPLICATION_NAME
                                                   , p_program_type           => G_PROGRAM_TYPE
                                                   , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                   , p_program_id             => gn_program_id
                                                   , p_module_name            => G_MODULE_NAME
                                                   , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                                   , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                   , p_error_message          => lc_error_message
                                                   , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                   , p_error_status           => G_ERROR_STATUS_FLAG
                                                  );
                RAISE EX_INSERT_ROW;
         END;
     END IF; -- lc_entity_exists = 'Y'
   END IF; -- p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL

EXCEPTION
   WHEN EX_INSERT_ROW THEN
       x_return_status  :=  FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0137_INSERT_ROW_ERR');
       lc_error_message := FND_MESSAGE.GET;
       FND_MSG_PUB.add;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                          , p_error_message_code     => 'XX_TM_0137_INSERT_ROW_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       x_return_status  :=  FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message  :=  'In Procedure: INSERT_ROW: Unexpected Error : ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       FND_MSG_PUB.add;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.INSERT_ROW'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END insert_row;

-- +===================================================================+
-- | Name  : Update_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    update record in the custom assignment table   |
-- |                    XX_TM_NAM_TERR_ENTITY_DTLS                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_row
            (
             p_api_version            IN  NUMBER
             , p_start_date_active    IN  DATE     DEFAULT SYSDATE
             , p_end_date_active      IN  DATE     DEFAULT NULL
             , p_named_acct_terr_id   IN  NUMBER
             , p_entity_type          IN  VARCHAR2
             , p_entity_id            IN  NUMBER   DEFAULT NULL
             , x_return_status        OUT NOCOPY   VARCHAR2
             , x_msg_count            OUT NOCOPY   NUMBER
             , x_message_data         OUT NOCOPY   VARCHAR2
            )
IS
-----------------------------
-- Declaring Local Constants
-----------------------------
l_api_version_number   CONSTANT NUMBER := 1.0;
l_api_name             CONSTANT VARCHAR2(30) := 'UPDATE_ROW';
-----------------------------
-- Declaring Local Variables
-----------------------------
EX_UPDATE_ROW          EXCEPTION;
lc_error_message       VARCHAR2(2000);
lc_terr_exists         VARCHAR2(03);
ln_named_acct_terr_id  PLS_INTEGER;
lc_entity_exists       VARCHAR2(03);
lc_set_message         VARCHAR2(2000);

BEGIN

     -- Initialize message list

     FND_MSG_PUB.initialize;

     --  Initialize API return status to success

     x_return_status := fnd_api.g_ret_sts_success;

     -- Standard call to check for call compatibility.

     IF NOT fnd_api.compatible_api_call(
                                        p_current_version_number  => l_api_version_number
                                        , p_caller_version_number => p_api_version
                                        , p_api_name              => l_api_name
                                        , p_pkg_name              => 'XX_JTF_RS_NAMED_ACC_TERR'
                                       )
     THEN
         RAISE fnd_api.g_exc_unexpected_error;
     END IF;

     -- Check whether the named_acct_terr_id exists

      IF p_named_acct_terr_id IS NULL THEN

        x_return_status        := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.set_name('XXCRM','XX_TM_0140_NAMDACT_TER_ID_N ULL');
        lc_error_message := FND_MESSAGE.GET;
        WRITE_LOG(lc_error_message);
        FND_MSG_PUB.add;
        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                           , p_application_name       => G_APPLICATION_NAME
                                           , p_program_type           => G_PROGRAM_TYPE
                                           , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                           , p_program_id             => gn_program_id
                                           , p_module_name            => G_MODULE_NAME
                                           , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                           , p_error_message_code     => 'XX_TM_0140_NAMDACT_TER_ID_NULL'
                                           , p_error_message          => lc_error_message
                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                          );
        RAISE EX_UPDATE_ROW;

      ELSE

          BEGIN

               SELECT 'Y'
               INTO   lc_terr_exists
               FROM   xx_tm_nam_terr_defn XTTD
               WHERE  XTTD.named_acct_terr_id = p_named_acct_terr_id
               AND    SYSDATE BETWEEN XTTD.start_date_active AND NVL(XTTD.end_date_active,SYSDATE)
               AND    NVL(XTTD.status,'A') = 'A';

          EXCEPTION
             WHEN OTHERS THEN
                 lc_terr_exists := NULL;
          END;

          IF lc_terr_exists = NULL THEN
            x_return_status        := FND_API.G_RET_STS_ERROR;
            FND_MESSAGE.set_name('XXCRM','XX_TM_0139_NO_NAMEDACT_TERR_ID');
            FND_MESSAGE.SET_TOKEN('P_NAMED_ACCT_TERR_ID', p_named_acct_terr_id);
            lc_error_message := FND_MESSAGE.GET;
            WRITE_LOG(lc_error_message);
            FND_MSG_PUB.add;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                               , p_program_id             => gn_program_id
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                               , p_error_message_code     => 'XX_TM_0139_NO_NAMEDACT_TERR_ID'
                                               , p_error_message          => lc_error_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_UPDATE_ROW;

          ELSE

              ln_named_acct_terr_id := p_named_acct_terr_id;
              WRITE_LOG('Territory exists. Territory ID = '|| ln_named_acct_terr_id);

          END IF; -- lc_terr_exists = NULL

      END IF; -- p_named_acct_terr_id IS NULL

      -- Check whether the entity_type and entity exists for the named_acct_terr_id

      lc_error_message := NULL;

      IF p_entity_type IS NULL THEN

        x_return_status        := FND_API.G_RET_STS_ERROR;
        FND_MESSAGE.set_name('XXCRM','XX_TM_0141_ENTITY_TYPE_NULL');
        lc_error_message := FND_MESSAGE.GET;
        WRITE_LOG(lc_error_message);
        FND_MSG_PUB.add;
        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                           , p_application_name       => G_APPLICATION_NAME
                                           , p_program_type           => G_PROGRAM_TYPE
                                           , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                           , p_program_id             => gn_program_id
                                           , p_module_name            => G_MODULE_NAME
                                           , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                           , p_error_message_code     => 'XX_TM_0141_ENTITY_TYPE_NULL'
                                           , p_error_message          => lc_error_message
                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                          );
        RAISE EX_UPDATE_ROW;

      ELSIF p_entity_id IS NULL THEN

           x_return_status        := FND_API.G_RET_STS_ERROR;
           FND_MESSAGE.set_name('XXCRM','XX_TM_0142_ENTITY_ID_NULL');
           lc_error_message := FND_MESSAGE.GET;
           WRITE_LOG(lc_error_message);
           FND_MSG_PUB.add;
           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                              p_return_code              => FND_API.G_RET_STS_ERROR
                                              , p_application_name       => G_APPLICATION_NAME
                                              , p_program_type           => G_PROGRAM_TYPE
                                              , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                              , p_program_id             => gn_program_id
                                              , p_module_name            => G_MODULE_NAME
                                              , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                              , p_error_message_code     => 'XX_TM_0142_ENTITY_ID_NULL'
                                              , p_error_message          => lc_error_message
                                              , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                              , p_error_status           => G_ERROR_STATUS_FLAG
                                             );
           RAISE EX_UPDATE_ROW;

      ELSE

          lc_error_message := NULL;
          lc_set_message   := NULL;

          BEGIN

               SELECT 'Y'
               INTO   lc_entity_exists
               FROM   xx_tm_nam_terr_entity_dtls XTTE
               WHERE  XTTE.named_acct_terr_id = p_named_acct_terr_id
               AND    XTTE.entity_type = p_entity_type
               AND    XTTE.entity_id = p_entity_id
               AND    SYSDATE BETWEEN XTTE.start_date_active and NVL(XTTE.end_date_active,SYSDATE)
               AND    NVL(XTTE.status,'A') = 'A'
               AND    rownum = 1;

          EXCEPTION
             WHEN OTHERS THEN
                 lc_entity_exists := NULL;
          END;

          IF lc_entity_exists IS NULL THEN

            x_return_status        := FND_API.G_RET_STS_ERROR;
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0143_NO_ENT_TYP_ID_EXIST');
            FND_MESSAGE.SET_TOKEN('P_ENTITY_TYPE',p_entity_type);
            FND_MESSAGE.SET_TOKEN('P_ENTITY_ID',p_entity_id);
            FND_MESSAGE.SET_TOKEN('P_NAMED_ACCT_TERR_ID',ln_named_acct_terr_id);
            lc_error_message := FND_MESSAGE.GET;
            WRITE_LOG(lc_error_message);
            FND_MSG_PUB.add;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                               , p_program_id             => gn_program_id
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                               , p_error_message_code     => 'XX_TM_0143_NO_ENT_TYP_ID_EXIST'
                                               , p_error_message          => lc_error_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_UPDATE_ROW;

          ELSE

              IF p_entity_type IN ('LEAD','OPPORTUNITY', 'PARTY_SITE') AND p_end_date_active IS NOT NULL THEN

                BEGIN

                     UPDATE xx_tm_nam_terr_entity_dtls XTTE
                     SET    XTTE.end_date_active = p_end_date_active
                            , XTTE.status = 'I'
                     WHERE  XTTE.named_acct_terr_id = p_named_acct_terr_id
                     AND    XTTE.entity_type = p_entity_type
                     AND    XTTE.entity_id = p_entity_id;

                EXCEPTION
                   WHEN OTHERS THEN
                       x_return_status        := FND_API.G_RET_STS_ERROR;
                       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                       lc_set_message  :=  'In Procedure:UPDATE_ROW: Unexpected Error while updating record into xx_tm_nam_terr_entity_dtls: ';
                       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                       lc_error_message := FND_MESSAGE.GET;
                       WRITE_LOG(lc_error_message);
                       FND_MSG_PUB.add;
                       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                                          , p_application_name       => G_APPLICATION_NAME
                                                          , p_program_type           => G_PROGRAM_TYPE
                                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                                          , p_program_id             => gn_program_id
                                                          , p_module_name            => G_MODULE_NAME
                                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                          , p_error_message          => lc_error_message
                                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                                         );
                       RAISE EX_UPDATE_ROW;

                END;

                lc_error_message := NULL;

                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0144_ENTITY_UPDATED');
                FND_MESSAGE.SET_TOKEN('P_ENTITY_TYPE',p_entity_type);
                FND_MESSAGE.SET_TOKEN('P_ENTITY_ID',p_entity_id);
                FND_MESSAGE.SET_TOKEN('P_NAMED_ACCT_TERR_ID',ln_named_acct_terr_id);
                lc_error_message := FND_MESSAGE.GET;
                WRITE_LOG(lc_error_message);

              END IF;

          END IF; -- lc_entity_exists IS NULL

      END IF; -- p_entity_type IS NULL

EXCEPTION
   WHEN EX_UPDATE_ROW THEN
       x_return_status        := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0138_UPDATE_ROW_ERR');
       lc_error_message := FND_MESSAGE.GET;
       FND_MSG_PUB.add;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                          , p_error_message_code     => 'XX_TM_0138_UPDATE_ROW_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       x_return_status        := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message  :=  'In Procedure: UPDATE_ROW: Unexpected Error : ';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       FND_MSG_PUB.add;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END update_row;

END XX_JTF_RS_NAMED_ACC_TERR;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================


