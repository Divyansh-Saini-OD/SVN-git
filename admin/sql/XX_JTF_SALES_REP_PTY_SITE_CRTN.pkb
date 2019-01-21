SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_PTY_SITE_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SALES_REP_PTY_SITE_CRTN 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_PTY_SITE_CRTN                                |
-- |                                                                                   |
-- | Description      :  This custom package will get triggered when a sales-rep       |
-- |                     creates a party_site                                          |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    Create_Party_Site     This is the public procedure.                   |
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
-- | Name  : create_record                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to actually      |
-- |                    create a party site record in the custom       |
-- |                    assignments table when a sales-rep creates     |
-- |                    a party_site                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_record(
                        p_resource_id          IN  NUMBER
                        , p_role_id              IN  NUMBER
                        , p_group_id             IN  NUMBER
                        , p_party_site_id        IN  NUMBER
                        , p_full_access_flag     IN  VARCHAR2
                        , x_return_status        OUT NOCOPY VARCHAR2
                       )
IS
---------------------------
--Declaring local variables
---------------------------
EX_CREATE_RECORD      EXCEPTION;
ln_api_version        PLS_INTEGER := 1.0;
lc_return_status      VARCHAR2(03);
lc_msg_data           VARCHAR2(2000);
ln_msg_count          PLS_INTEGER;
lc_message            VARCHAR2(2000);
ln_named_acct_terr_id PLS_INTEGER;
lc_terr_exists        VARCHAR2(03);
lc_err_message        VARCHAR2(2000);
lc_terr_name          VARCHAR2(100);

--------------------------------
--Declaring Table Type Variables
--------------------------------
lt_details_rec        XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup_out_tbl_type;

BEGIN

   --  Initialize API return status to success
      
   x_return_status := FND_API.G_RET_STS_SUCCESS;
   lt_details_rec.DELETE;
   lc_return_status := NULL;
   lc_msg_data      := NULL;
   
   -- Call to Current Date Named Account Territory Lookup API 
   
   XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup1(
                                            p_api_version_number             => ln_api_version 
                                            , p_resource_id                  => p_resource_id
                                            , p_res_role_id                  => p_role_id
                                            , p_res_group_id                 => p_group_id
                                            , p_entity_type                  => NULL 
                                            , p_entity_id                    => NULL 
                                            , x_nam_terr_lookup_out_tbl_type => lt_details_rec
                                            , x_return_status                => lc_return_status
                                            , x_message_data                 => lc_msg_data
                                           );
                                           
   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
     
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code              => FND_API.G_RET_STS_ERROR 
                                        , p_application_name       => G_APPLICATION_NAME
                                        , p_program_type           => G_PROGRAM_TYPE
                                        , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                        , p_module_name            => G_MODULE_NAME
                                        , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                        , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                        , p_error_message          => lc_msg_data
                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                       ); 
     RAISE EX_CREATE_RECORD;
   END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
     
   
   IF lt_details_rec.COUNT = 0 THEN
   
     -- Derive the territory_name and description 
            
     BEGIN
                 
          SELECT NVL(source_name,'No Territoty Name')
          INTO   lc_terr_name 
          FROM   jtf_rs_resource_extns JRR 
          WHERE  JRR.resource_id = p_resource_id; 
            
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0124_NOT_VALID_TERRITORY');
            lc_message := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR 
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                               , p_error_message_code     => 'XX_TM_0109_NOT_VALID_TERRITORY'
                                               , p_error_message          => lc_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_CREATE_RECORD;
        WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
            lc_err_message     :=  'Unexpected Error while deriving territory name and description';
            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            lc_message := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR 
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                               , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                               , p_error_message          => lc_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_CREATE_RECORD;
            
     END;
          
     /* As no named_acct_terr_id is returned, create a territory record, an entity record 
        and a resource record in the respective custom assignments table */
          
     lc_return_status  := NULL;
     lc_msg_data       := NULL;
     ln_msg_count      := NULL;
          
     XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                         p_api_version            => ln_api_version
                                         , p_named_acct_terr_name => lc_terr_name
                                         , p_named_acct_terr_desc => lc_terr_name
                                         , p_full_access_flag     => p_full_access_flag
                                         , p_resource_id          => p_resource_id
                                         , p_role_id              => p_role_id                                 
                                         , p_group_id             => p_group_id
                                         , p_entity_type          => 'PARTY_SITE'
                                         , p_entity_id            => p_party_site_id
                                         , x_return_status        => lc_return_status
                                         , x_message_data         => lc_msg_data
                                         , x_msg_count            => ln_msg_count
                                        );
                                             
     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                                                     
       FOR b IN 1 .. ln_msg_count
       LOOP
                                                         
           lc_msg_data := FND_MSG_PUB.GET( 
                                          p_encoded     => FND_API.G_FALSE 
                                          , p_msg_index => b
                                         );
                                                         
           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                              p_return_code              => FND_API.G_RET_STS_ERROR 
                                              , p_application_name       => G_APPLICATION_NAME
                                              , p_program_type           => G_PROGRAM_TYPE
                                              , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                              , p_module_name            => G_MODULE_NAME
                                              , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                              , p_error_message_count    => b
                                              , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                              , p_error_message          => lc_msg_data
                                              , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                              , p_error_status           => G_ERROR_STATUS_FLAG
                                             ); 
                                                                                   
       END LOOP;
       RAISE EX_CREATE_RECORD;
                                                                                   
     END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
        
   ELSE
            
       -- Else for each of the named_acct_terr_ids returned 
            
       FOR I IN lt_details_rec.FIRST .. lt_details_rec.LAST
       LOOP
       
           -- Initialize the variables
           ln_named_acct_terr_id  := NULL;
           lc_terr_exists         := NULL;
           lc_return_status       := NULL;
           lc_msg_data            := NULL;
           ln_msg_count           := NULL;
                
           ln_named_acct_terr_id := lt_details_rec(i).nam_terr_id;
                
           -- Since the territory exists, check whether the entity_type and 
           -- entity_id already exists 
                
           BEGIN
                
                SELECT  'Y'
                INTO    lc_terr_exists
                FROM    xx_tm_nam_terr_curr_assign_v XTNT
                WHERE   XTNT.named_acct_terr_id = ln_named_acct_terr_id
                AND     XTNT.entity_id = p_party_site_id
                AND     XTNT.entity_type = 'PARTY_SITE';
                   
           EXCEPTION
              WHEN OTHERS THEN
                  lc_terr_exists := NULL;
           END;
                
           IF lc_terr_exists IS NULL THEN
                  
             XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                                 p_api_version          => ln_api_version
                                                 , p_named_acct_terr_id => ln_named_acct_terr_id
                                                 , p_entity_type        => 'PARTY_SITE'
                                                 , p_entity_id          => p_party_site_id
                                                 , x_return_status      => lc_return_status
                                                 , x_message_data       => lc_msg_data
                                                 , x_msg_count          => ln_msg_count 
                                                );
                                                     
             IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
               
               FOR c IN 1 .. ln_msg_count
               LOOP
                                                                                                           
                   lc_msg_data := FND_MSG_PUB.GET( 
                                                  p_encoded     => FND_API.G_FALSE 
                                                  , p_msg_index => c
                                                 );
                                                                                                           
                   XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                      p_return_code              => FND_API.G_RET_STS_ERROR 
                                                      , p_application_name       => G_APPLICATION_NAME
                                                      , p_program_type           => G_PROGRAM_TYPE
                                                      , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                                      , p_module_name            => G_MODULE_NAME
                                                      , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                                      , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                      , p_error_message          => lc_msg_data
                                                      , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                      , p_error_status           => G_ERROR_STATUS_FLAG
                                                     ); 
                                                      
               END LOOP;
               RAISE EX_CREATE_RECORD;
             END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS of XX_JTF_RS_NAMED_ACC_TERR.insert_row
                
           END IF; -- lc_terr_exists IS NULL
                
       END LOOP; -- lt_details_rec.FIRST .. lt_details_rec.LAST
        
   END IF; -- lt_details_rec.COUNT = 0

EXCEPTION
   WHEN EX_CREATE_RECORD THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0126_CREATE_RECRD_TERMIN');
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD' 
                                          , p_error_message_code     => 'XX_TM_0126_CREATE_RECRD_TERMIN'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );   
   WHEN OTHERS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: CREATE_RECORD';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_RECORD' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END create_record;

-- +===================================================================+
-- | Name  : Create_Party_Site                                         |
-- |                                                                   |
-- | Description:       This is the public procedure to create a party |
-- |                    site record in the custom assignments table    |
-- |                    when a sales-rep creates a party_site          |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE create_party_site
            (
              p_party_site_id        IN NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_PARTY_SITE_ERROR       EXCEPTION;
EX_CREATE_ERR             EXCEPTION;
ln_created_by             PLS_INTEGER;
lc_party_type             VARCHAR2(30);
ln_creator_resource_id    PLS_INTEGER;
ln_creator_role_id        PLS_INTEGER;
lc_creator_role_division  VARCHAR2(50);
ln_creator_group_id       PLS_INTEGER;
ln_creator_manager_id     PLS_INTEGER;
ln_api_version            PLS_INTEGER := 1.0;
lc_return_status          VARCHAR2(03);
ln_msg_count              PLS_INTEGER;
lc_msg_data               VARCHAR2(2000);
l_counter                 PLS_INTEGER;
ln_salesforce_id          PLS_INTEGER;
ln_sales_group_id         PLS_INTEGER;
ln_asignee_role_id        PLS_INTEGER;
lc_assignee_role_division VARCHAR2(50);
lc_error_message          VARCHAR2(2000);
lc_set_message            VARCHAR2(2000);
lc_creator_admin_flag     VARCHAR2(03);
lc_full_access_flag       VARCHAR2(03);
ln_asignee_manager_id     PLS_INTEGER;
l_squal_char01            VARCHAR2(4000);
l_squal_char02            VARCHAR2(4000);
l_squal_char03            VARCHAR2(4000);
l_squal_char04            VARCHAR2(4000);
l_squal_char05            VARCHAR2(4000);
l_squal_char06            VARCHAR2(4000);
l_squal_char07            VARCHAR2(4000);
l_squal_char08            VARCHAR2(4000);
l_squal_char09            VARCHAR2(4000);
l_squal_char10            VARCHAR2(4000);
l_squal_char11            VARCHAR2(4000);
l_squal_char50            VARCHAR2(4000);
l_squal_char59            VARCHAR2(4000);
l_squal_char60            VARCHAR2(4000);
l_squal_char61            VARCHAR2(4000);
l_squal_num60             VARCHAR2(4000);
l_squal_curc01            VARCHAR2(4000);
l_squal_num01             NUMBER;
l_squal_num02             NUMBER;
l_squal_num03             NUMBER;
l_squal_num04             NUMBER;
l_squal_num05             NUMBER;
l_squal_num06             NUMBER;  
l_squal_num07             NUMBER; 
lc_role                   VARCHAR2(50);
lc_creator_manager_flag   VARCHAR2(03);
ln_manager_count          PLS_INTEGER;
ln_admin_count            PLS_INTEGER; 
lc_message_code           VARCHAR2(30);
lc_assignee_admin_flag    VARCHAR2(10);
lc_assignee_manager_flag  VARCHAR2(10);

----------------------------------
--Declaring Record Type Variables
----------------------------------
lp_gen_bulk_rec           JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec         JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- ---------------------------------------------------------
-- Declare cursor to check whether the resource is an admin
-- ---------------------------------------------------------
CURSOR lcu_admin(
                 p_resource_id NUMBER
                 , p_group_id  NUMBER DEFAULT NULL
                )
IS
SELECT count(ROL.admin_flag)
FROM   jtf_rs_role_relations JRR
       , jtf_rs_group_members MEM
       , jtf_rs_group_usages JRU
       , jtf_rs_roles_b ROL
WHERE  MEM.resource_id = p_resource_id
AND    NVL(MEM.delete_flag,'N') <> 'Y'
AND    MEM.group_id = NVL(p_group_id,MEM.group_id)
AND    JRU.group_id = MEM.group_id
AND    JRU.usage = 'SALES'
AND    JRR.role_resource_id    = MEM.group_member_id
AND    JRR.role_resource_type  = 'RS_GROUP_MEMBER'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                      AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'                          
AND    ROL.role_id = JRR.role_id
AND    ROL.role_type_code='SALES'
AND    ROL.admin_flag = 'Y'
AND    ROL.active_flag = 'Y';

-- ----------------------------------------------------------
-- Declare cursor to check whether the resource is a manager
-- ----------------------------------------------------------
CURSOR lcu_manager(
                   p_resource_id NUMBER
                   , p_group_id  NUMBER DEFAULT NULL
                  )
IS
SELECT count(ROL.manager_flag)
FROM   jtf_rs_role_relations JRR
       , jtf_rs_group_members MEM
       , jtf_rs_group_usages JRU
       , jtf_rs_roles_b ROL
WHERE  MEM.resource_id = p_resource_id
AND    NVL(MEM.delete_flag,'N') <> 'Y'
AND    MEM.group_id = NVL(p_group_id,MEM.group_id)
AND    JRU.group_id = MEM.group_id
AND    JRU.usage = 'SALES'
AND    JRR.role_resource_id    = MEM.group_member_id
AND    JRR.role_resource_type  = 'RS_GROUP_MEMBER'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                      AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'                          
AND    ROL.role_id = JRR.role_id
AND    ROL.role_type_code='SALES'
AND    ROL.manager_flag = 'Y'
AND    ROL.active_flag = 'Y';       
       
BEGIN

   -- Check whether the party_site_id is of party_type 'ORGANIZATION'
   
   SELECT HP.party_type
   INTO   lc_party_type
   FROM   hz_party_sites HPS
          , hz_parties HP
   WHERE  HP.party_id = HPS.party_id
   AND    HPS.party_site_id = p_party_site_id;
   
   IF lc_party_type <> 'ORGANIZATION' THEN
     
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0185_NOT_ORGANIZATION');
     FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', p_party_site_id );
     lc_error_message := FND_MESSAGE.GET;
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code              => FND_API.G_RET_STS_ERROR 
                                        , p_application_name       => G_APPLICATION_NAME
                                        , p_program_type           => G_PROGRAM_TYPE
                                        , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                        , p_module_name            => G_MODULE_NAME
                                        , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                        , p_error_message_code     => 'XX_TM_0185_NOT_ORGANIZATION'
                                        , p_error_message          => lc_error_message
                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                       );
     RAISE EX_PARTY_SITE_ERROR;
     
   END IF;
   
   -- Retrieve the creator resource 
   
   ln_created_by := FND_GLOBAL.user_id;
   
   -- Derive the resource_id of creator resource 
   
   BEGIN
      
      SELECT JRR.resource_id
      INTO   ln_creator_resource_id
      FROM   jtf_rs_resource_extns JRR
      WHERE  JRR.user_id = ln_created_by;
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0158_RESOURCE_NOT_FOUND');
          FND_MESSAGE.SET_TOKEN('P_USER_ID', ln_created_by );
          lc_error_message := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code              => FND_API.G_RET_STS_ERROR 
                                             , p_application_name       => G_APPLICATION_NAME
                                             , p_program_type           => G_PROGRAM_TYPE
                                             , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_module_name            => G_MODULE_NAME
                                             , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_error_message_code     => 'XX_TM_0158_RESOURCE_NOT_FOUND'
                                             , p_error_message          => lc_error_message
                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                            );
          RAISE EX_PARTY_SITE_ERROR;
      WHEN OTHERS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Unexpected Error while deriving resource_id of the creator: ';
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code              => FND_API.G_RET_STS_ERROR 
                                             , p_application_name       => G_APPLICATION_NAME
                                             , p_program_type           => G_PROGRAM_TYPE
                                             , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_module_name            => G_MODULE_NAME
                                             , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                             , p_error_message          => lc_error_message
                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                            );
          RAISE EX_PARTY_SITE_ERROR;
   END;
   
   lc_creator_admin_flag   := 'N';
   lc_creator_manager_flag := 'N';
   
   -- Check whether the creator resource is an admin
   
   OPEN  lcu_admin(
                   p_resource_id => ln_creator_resource_id
                   , p_group_id  => ln_creator_group_id
                  );
   FETCH lcu_admin INTO ln_admin_count;
   CLOSE lcu_admin;
   
   IF ln_admin_count = 0 THEN
     
     lc_creator_admin_flag := 'N';
     
     -- As the resource is not an admin
     -- then check whether the resource is a manager
     
     OPEN lcu_manager(
                      p_resource_id => ln_creator_resource_id
                      , p_group_id  => ln_creator_group_id
                      );
     FETCH lcu_manager INTO ln_manager_count;
     CLOSE lcu_manager;
     
     IF ln_manager_count = 0 THEN
       
       -- The creator resource is a sales-rep
       lc_creator_manager_flag := 'N';
     
     ELSIF ln_manager_count = 1 THEN
          
          -- The creator resource is a manager
          lc_creator_manager_flag := 'Y';
          
     ELSE
         
         -- The resource has more than one manager role
         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0226_CR_MGR_MR_THAN_ONE');
         FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
         lc_error_message := FND_MESSAGE.GET;
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                            , p_application_name       => G_APPLICATION_NAME
                                            , p_program_type           => G_PROGRAM_TYPE
                                            , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                            , p_module_name            => G_MODULE_NAME
                                            , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                            , p_error_message_code     => 'XX_TM_0226_CR_MGR_MR_THAN_ONE'
                                            , p_error_message          => lc_error_message
                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                           );
         RAISE EX_PARTY_SITE_ERROR;
         
     END IF; -- ln_manager_count = 0   
     
   ELSIF ln_admin_count = 1 THEN
        
        lc_creator_admin_flag := 'Y';
   
   ELSE
       
       -- The resource has more than one admin role
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0225_ADM_MORE_THAN_ONE');
       FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
       lc_error_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0225_ADM_MORE_THAN_ONE'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
       RAISE EX_PARTY_SITE_ERROR;
       
   END IF ; -- ln_admin_count = 0
   
   -- Derive the role_id , group_id and role_division of creator resource 
        
   BEGIN
          
        SELECT JRR_CR.role_id
               , ROL_CR.attribute15
               , MEM_CR.group_id
        INTO   ln_creator_role_id
               , lc_creator_role_division
               , ln_creator_group_id
        FROM   jtf_rs_group_members MEM_CR
               , jtf_rs_role_relations JRR_CR
               , jtf_rs_group_usages JRU_CR
               , jtf_rs_roles_b ROL_CR
        WHERE  MEM_CR.resource_id          = ln_creator_resource_id
        AND    NVL(MEM_CR.delete_flag,'N') <> 'Y'
        AND    JRU_CR.group_id             = MEM_CR.group_id
        AND    JRU_CR.usage                = 'SALES'
        AND    JRR_CR.role_resource_id     = MEM_CR.group_member_id
        AND    JRR_CR.role_resource_type   = 'RS_GROUP_MEMBER'
        AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_CR.start_date_active) 
                              AND NVL(TRUNC(JRR_CR.end_date_active),TRUNC(SYSDATE))
        AND    NVL(JRR_CR.delete_flag,'N') <> 'Y'
        AND    ROL_CR.role_id              = JRR_CR.role_id
        AND    ROL_CR.role_type_code       = 'SALES'
        AND    ROL_CR.active_flag          = 'Y'
        AND    (CASE lc_creator_admin_flag 
                     WHEN 'Y' THEN ROL_CR.admin_flag
                     ELSE 'N' 
                             END) = (CASE lc_creator_admin_flag 
                                          WHEN 'Y' THEN 'Y' 
                                          ELSE 'N' 
                                                  END)
        AND    (CASE lc_creator_manager_flag 
                     WHEN 'Y' THEN ROL_CR.attribute14 
                     ELSE 'N' 
                             END) = (CASE lc_creator_manager_flag 
                                          WHEN 'Y' THEN 'HSE' 
                                          ELSE 'N' 
                                                  END);
        
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
          IF lc_creator_manager_flag = 'Y' THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0227_CR_MGR_NO_HSE_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0227_CR_MGR_NO_HSE_ROLE';
          ELSE
              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0160_CR_NO_SALES_ROLE');
              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
              lc_error_message := FND_MESSAGE.GET;
              lc_message_code  := 'XX_TM_0160_CR_NO_SALES_ROLE';
          END IF;
          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code              => FND_API.G_RET_STS_ERROR 
                                             , p_application_name       => G_APPLICATION_NAME
                                             , p_program_type           => G_PROGRAM_TYPE
                                             , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_module_name            => G_MODULE_NAME
                                             , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_error_message_code     => lc_message_code
                                             , p_error_message          => lc_error_message
                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                            ); 
          RAISE EX_PARTY_SITE_ERROR;
      WHEN TOO_MANY_ROWS THEN
          IF lc_creator_manager_flag = 'Y' THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0228_CR_MGR_HSE_ROLE');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            lc_message_code  := 'XX_TM_0228_CR_MGR_HSE_ROLE';
          ELSE
              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0118_CR_MANY_SALES_ROLE');
              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
              lc_error_message := FND_MESSAGE.GET;
              lc_message_code  := 'XX_TM_0118_CR_MANY_SALES_ROLE';
          END IF;
          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code              => FND_API.G_RET_STS_ERROR 
                                             , p_application_name       => G_APPLICATION_NAME
                                             , p_program_type           => G_PROGRAM_TYPE
                                             , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_module_name            => G_MODULE_NAME
                                             , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_error_message_code     => lc_message_code
                                             , p_error_message          => lc_error_message
                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                            );
          RAISE EX_PARTY_SITE_ERROR;
      WHEN OTHERS THEN
          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
          lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the creator';
          FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
          FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
          lc_error_message := FND_MESSAGE.GET;
          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                             p_return_code              => FND_API.G_RET_STS_ERROR 
                                             , p_application_name       => G_APPLICATION_NAME
                                             , p_program_type           => G_PROGRAM_TYPE
                                             , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_module_name            => G_MODULE_NAME
                                             , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                             , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                             , p_error_message          => lc_error_message
                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                            );
          RAISE EX_PARTY_SITE_ERROR;
   END;
     
   -- If Creator is not a manager and admin
   
   IF (lc_creator_admin_flag <> 'Y' AND lc_creator_manager_flag <> 'Y') THEN
   
     -- Derive the manager resource_id of the creator
     
     BEGIN
        
           SELECT MEM_MGR.resource_id
           INTO   ln_creator_manager_id
           FROM   jtf_rs_group_members MEM_CR
                  , jtf_rs_role_relations JRR_CR
                  , jtf_rs_roles_b ROL_CR
                  , jtf_rs_group_usages JRU
                  , jtf_rs_group_members MEM_MGR
                  , jtf_rs_role_relations JRR_MGR
                  , jtf_rs_roles_b ROL_MGR
           WHERE  MEM_CR.resource_id = ln_creator_resource_id
           AND    NVL(MEM_CR.delete_flag,'N') <> 'Y'
           AND    JRU.group_id                = MEM_CR.group_id
           AND    JRU.usage                   = 'SALES'
           AND    JRR_CR.role_resource_id     = MEM_CR.group_member_id
           AND    JRR_CR.role_resource_type   = 'RS_GROUP_MEMBER'
           AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_CR.start_date_active) 
                                 AND NVL(TRUNC(JRR_CR.end_date_active),TRUNC(SYSDATE))
           AND    NVL(JRR_CR.delete_flag,'N') <> 'Y'
           AND    ROL_CR.role_id              = JRR_CR.role_id
           AND    ROL_CR.role_type_code       = 'SALES'
           AND    ROL_CR.active_flag          = 'Y'
           AND    MEM_MGR.group_id            = MEM_CR.group_id
           AND    NVL(MEM_MGR.delete_flag,'N') <> 'Y'
           AND    JRU.group_id                = MEM_MGR.group_id
           AND    JRU.usage                   = 'SALES'
           AND    JRR_MGR.role_resource_id    = MEM_MGR.group_member_id
           AND    JRR_MGR.role_resource_type  = 'RS_GROUP_MEMBER'
           AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_MGR.start_date_active) 
                                 AND NVL(TRUNC(JRR_MGR.end_date_active),TRUNC(SYSDATE))
           AND    NVL(JRR_MGR.delete_flag,'N') <> 'Y'
           AND    ROL_MGR.role_id              = JRR_MGR.role_id
           AND    ROL_MGR.role_type_code       = 'SALES'
           AND    ROL_MGR.active_flag          = 'Y'
           AND    ROL_MGR.manager_flag         = 'Y';
           
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0119_CR_NO_MANAGER');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR 
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_error_message_code     => 'XX_TM_0119_CR_NO_MANAGER'
                                               , p_error_message          => lc_error_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              ); 
            RAISE EX_PARTY_SITE_ERROR;
        WHEN TOO_MANY_ROWS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0120_CR_MANY_MANAGERS');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_creator_resource_id);
            lc_error_message := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR 
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_error_message_code     => 'XX_TM_0120_CR_MANY_MANAGERS'
                                               , p_error_message          => lc_error_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_PARTY_SITE_ERROR;
        WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
            lc_set_message     :=  'Unexpected Error while deriving manager_id of the creator.';
            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
            lc_error_message := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                               p_return_code              => FND_API.G_RET_STS_ERROR 
                                               , p_application_name       => G_APPLICATION_NAME
                                               , p_program_type           => G_PROGRAM_TYPE
                                               , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                               , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                               , p_error_message          => lc_error_message
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );
            RAISE EX_PARTY_SITE_ERROR;
     END;
   
   END IF;
   
   lp_gen_bulk_rec.trans_object_id         := JTF_TERR_NUMBER_LIST(null);
   lp_gen_bulk_rec.trans_detail_object_id  := JTF_TERR_NUMBER_LIST(null);
   
   -- Extend Qualifier Elements
   lp_gen_bulk_rec.squal_char01.EXTEND;
   lp_gen_bulk_rec.squal_char02.EXTEND;
   lp_gen_bulk_rec.squal_char03.EXTEND;
   lp_gen_bulk_rec.squal_char04.EXTEND;
   lp_gen_bulk_rec.squal_char05.EXTEND;
   lp_gen_bulk_rec.squal_char06.EXTEND;
   lp_gen_bulk_rec.squal_char07.EXTEND;
   lp_gen_bulk_rec.squal_char08.EXTEND;
   lp_gen_bulk_rec.squal_char09.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char10.EXTEND;
   lp_gen_bulk_rec.squal_char11.EXTEND;
   lp_gen_bulk_rec.squal_char50.EXTEND;
   lp_gen_bulk_rec.squal_char59.EXTEND;
   lp_gen_bulk_rec.squal_char60.EXTEND;
   lp_gen_bulk_rec.squal_num60.EXTEND;
   lp_gen_bulk_rec.squal_num01.EXTEND;
   lp_gen_bulk_rec.squal_num02.EXTEND;
   lp_gen_bulk_rec.squal_num03.EXTEND;
   lp_gen_bulk_rec.squal_num04.EXTEND;
   lp_gen_bulk_rec.squal_num05.EXTEND;
   lp_gen_bulk_rec.squal_num06.EXTEND;
   lp_gen_bulk_rec.squal_num07.EXTEND;
   lp_gen_bulk_rec.squal_char61.EXTEND;
   
   
   lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
   lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
   lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
   lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
   lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
   lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  --Postal Code
   lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  --Country
   lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
   lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
   lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
   lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
   lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
   lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;  --SIC Code(Site Level)
   lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;  --Customer/Prospect
   lp_gen_bulk_rec.squal_char61(1) := p_party_site_id; 
   lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;   --WCW
   lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;   --Party Id
   lp_gen_bulk_rec.squal_num02(1)  := p_party_site_id; --Party Site Id
   lp_gen_bulk_rec.squal_num03(1)  := l_squal_num03;
   lp_gen_bulk_rec.squal_num04(1)  := l_squal_num04;
   lp_gen_bulk_rec.squal_num05(1)  := l_squal_num05;
   lp_gen_bulk_rec.squal_num06(1)  := l_squal_num06;
   lp_gen_bulk_rec.squal_num07(1)  := l_squal_num07;  
   
   -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id
   
   
   JTF_TERR_ASSIGN_PUB.get_winners(  
                                   p_api_version_number  => ln_api_version
                                   , p_init_msg_list     => FND_API.G_FALSE
                                   , p_use_type          => 'LOOKUP'
                                   , p_source_id         => -1001
                                   , p_trans_id          => -1002
                                   , p_trans_rec         => lp_gen_bulk_rec
                                   , p_resource_type     => FND_API.G_MISS_CHAR
                                   , p_role              => FND_API.G_MISS_CHAR
                                   , p_top_level_terr_id => FND_API.G_MISS_NUM
                                   , p_num_winners       => FND_API.G_MISS_NUM
                                   , x_return_status     => lc_return_status
                                   , x_msg_count         => ln_msg_count
                                   , x_msg_data          => lc_msg_data
                                   , x_winners_rec       => lx_gen_return_rec
                                  );
   
   IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
     
     FOR k IN 1 .. ln_msg_count
     LOOP
     
         lc_msg_data := FND_MSG_PUB.GET( 
                                        p_encoded     => FND_API.G_FALSE 
                                        , p_msg_index => k
                                       ); 
     
         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code              => FND_API.G_RET_STS_ERROR 
                                            , p_application_name       => G_APPLICATION_NAME
                                            , p_program_type           => G_PROGRAM_TYPE
                                            , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                            , p_module_name            => G_MODULE_NAME
                                            , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                            , p_error_message_count    => k
                                            , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                            , p_error_message          => lc_msg_data
                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                           );   
                                         
     END LOOP;
     RAISE EX_PARTY_SITE_ERROR;
   
   END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
   
   -- JTF_TERR_ASSIGN_PUB.get_winners did not return any resource
   
   IF lx_gen_return_rec.resource_id.COUNT = 0 THEN
     
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0121_NO_RES_RETURNED');
     lc_error_message := FND_MESSAGE.GET;
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code              => FND_API.G_RET_STS_ERROR 
                                        , p_application_name       => G_APPLICATION_NAME
                                        , p_program_type           => G_PROGRAM_TYPE
                                        , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                        , p_module_name            => G_MODULE_NAME
                                        , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                        , p_error_message_code     => 'XX_TM_0121_NO_RES_RETURNED'
                                        , p_error_message          => lc_error_message
                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                       );
     RAISE EX_PARTY_SITE_ERROR;
     
   END IF; -- lx_gen_return_rec.resource_id.COUNT = 0
   
   -- For each resource returned from JTF_TERR_ASSIGN_PUB.get_winners
   
   l_counter := lx_gen_return_rec.resource_id.FIRST;
   
   WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
   LOOP
       
       BEGIN
             -- Initialize the variables
             ln_salesforce_id          := NULL;
             ln_sales_group_id         := NULL;
             lc_full_access_flag       := NULL;
             ln_asignee_role_id        := NULL;
             lc_assignee_role_division := NULL;
             lc_error_message          := NULL;
             lc_set_message            := NULL;
             lc_return_status          := NULL;
             ln_asignee_manager_id     := NULL;
             lc_role                   := NULL;
             ln_admin_count            := NULL;
             lc_assignee_admin_flag    := 'N';
             lc_assignee_manager_flag  := 'N';
             ln_admin_count            := NULL;
             ln_manager_count          := NULL;

             -- Fetch the assignee resource_id, sales_group_id and full_access_flag

             ln_salesforce_id    := lx_gen_return_rec.resource_id(l_counter);
             ln_sales_group_id   := lx_gen_return_rec.group_id(l_counter);
             lc_full_access_flag := lx_gen_return_rec.full_access_flag(l_counter);
             lc_role             := lx_gen_return_rec.role(l_counter);
             
             -- Check whether the assignee resource is an admin
             OPEN  lcu_admin(
                             p_resource_id => ln_salesforce_id
                             , p_group_id  => ln_sales_group_id
                            );
             FETCH lcu_admin INTO ln_admin_count;
             CLOSE lcu_admin;
             
             IF ln_admin_count = 0 THEN
                
                lc_assignee_admin_flag := 'N';
                
                -- Check whether the assignee resource is a manager
                
                OPEN lcu_manager(
                                 p_resource_id => ln_salesforce_id
                                 , p_group_id  => ln_sales_group_id
                                );
                FETCH lcu_manager INTO ln_manager_count;
                CLOSE lcu_manager;
                
                IF (ln_manager_count = 0) THEN
                   
                   -- This means the resource is a sales-rep
                   lc_assignee_manager_flag := 'N';
                         
                ELSIF ln_manager_count = 1 THEN
                         
                      -- This means the resource is a manager
                      lc_assignee_manager_flag := 'Y';
                        
                ELSE 
                
                    -- The resource is a manger of more than one group
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                    FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                    lc_error_message := FND_MESSAGE.GET;
                    XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                       p_return_code              => FND_API.G_RET_STS_ERROR
                                                       , p_application_name       => G_APPLICATION_NAME
                                                       , p_program_type           => G_PROGRAM_TYPE
                                                       , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                       , p_module_name            => G_MODULE_NAME
                                                       , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                       , p_error_message_code     => 'XX_TM_0219_MGR_MORE_THAN_ONE'
                                                       , p_error_message          => lc_error_message
                                                       , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                       , p_error_status           => G_ERROR_STATUS_FLAG
                                                      );
                    RAISE EX_CREATE_ERR;
                
               END IF; -- ln_manager_count = 0
             
             ELSIF ln_admin_count = 1 THEN
                     
                   lc_assignee_admin_flag := 'Y';
                
             ELSE
                    
                 -- The resource has more than one admin role
                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0243_ADM_MORE_THAN_ONE');
                 FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                 lc_error_message := FND_MESSAGE.GET;
                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                       p_return_code              => FND_API.G_RET_STS_ERROR
                                                       , p_application_name       => G_APPLICATION_NAME
                                                       , p_program_type           => G_PROGRAM_TYPE
                                                       , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                       , p_module_name            => G_MODULE_NAME
                                                       , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                       , p_error_message_code     => 'XX_TM_0243_ADM_MORE_THAN_ONE'
                                                       , p_error_message          => lc_error_message
                                                       , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                       , p_error_status           => G_ERROR_STATUS_FLAG
                                                   );
                 RAISE EX_CREATE_ERR;
                    
             END IF ; -- ln_admin_count = 0
                           
             -- Deriving the group id of the resource if ln_sales_group_id IS NULL

             IF (ln_sales_group_id IS NULL) THEN
                
                IF lc_assignee_admin_flag = 'Y' THEN
                   
                   FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0244_ADM_GRP_MANDATORY');
                   FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                   lc_error_message := FND_MESSAGE.GET;
                   XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                      p_return_code              => FND_API.G_RET_STS_ERROR
                                                      , p_application_name       => G_APPLICATION_NAME
                                                      , p_program_type           => G_PROGRAM_TYPE
                                                      , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                      , p_module_name            => G_MODULE_NAME
                                                      , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                      , p_error_message_code     => 'XX_TM_0244_ADM_GRP_MANDATORY'
                                                      , p_error_message          => lc_error_message
                                                      , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                      , p_error_status           => G_ERROR_STATUS_FLAG
                                                     );
                 RAISE EX_CREATE_ERR;
                
                END IF; -- lc_assignee_admin_flag = 'Y'
                              
             END IF; -- ln_sales_group_id IS NULL
                                          
             -- Deriving the role of the resource if lc_role IS NULL
                                                            
             IF (lc_role IS NULL ) THEN
                
                IF lc_assignee_admin_flag = 'Y' THEN
                                   
                   FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0245_ADM_ROLE_MANDATORY');
                   FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                   lc_error_message := FND_MESSAGE.GET;
                   XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                      p_return_code              => FND_API.G_RET_STS_ERROR
                                                      , p_application_name       => G_APPLICATION_NAME
                                                      , p_program_type           => G_PROGRAM_TYPE
                                                      , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                      , p_module_name            => G_MODULE_NAME
                                                      , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                      , p_error_message_code     => 'XX_TM_0245_ADM_ROLE_MANDATORY'
                                                      , p_error_message          => lc_error_message
                                                      , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                      , p_error_status           => G_ERROR_STATUS_FLAG
                                                     );
                   RAISE EX_CREATE_ERR;
                                
                END IF; -- lc_assignee_admin_flag = 'Y'
                                                            
               -- Derive the role_id group_id and role_division of assignee resource
               -- with the resource_id and group_id derived

               BEGIN

                     SELECT JRR_ASG.role_id
                            , ROL_ASG.attribute15
                            , MEM_ASG.group_id
                     INTO   ln_asignee_role_id
                            , lc_assignee_role_division
                            , ln_sales_group_id
                     FROM   jtf_rs_group_members MEM_ASG
                            , jtf_rs_role_relations JRR_ASG
                            , jtf_rs_group_usages JRU_ASG
                            , jtf_rs_roles_b ROL_ASG
                     WHERE  MEM_ASG.resource_id      = ln_salesforce_id
                     AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                     AND    MEM_ASG.group_id         = NVL(ln_sales_group_id,MEM_ASG.group_id)
                     AND    JRU_ASG.group_id         = MEM_ASG.group_id
                     AND    JRU_ASG.usage            = 'SALES'
                     AND    JRR_ASG.role_resource_id = MEM_ASG.group_member_id
                     AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                     AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active) 
                              AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                     AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                     AND    ROL_ASG.role_id         = JRR_ASG.role_id
                     AND    ROL_ASG.role_type_code  = 'SALES'
                     AND    ROL_ASG.active_flag     = 'Y'
                     AND    (CASE lc_assignee_manager_flag 
                                  WHEN 'Y' THEN ROL_ASG.attribute14 
                                  ELSE 'N' 
                                          END) = (CASE lc_assignee_manager_flag 
                                                       WHEN 'Y' THEN 'HSE' 
                                                       ELSE 'N' 
                                                               END);
                     
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      IF lc_assignee_manager_flag = 'Y' THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0229_AS_MGR_NO_HSE_ROLE');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        lc_error_message := FND_MESSAGE.GET;
                        lc_message_code  := 'XX_TM_0229_AS_MGR_NO_HSE_ROLE';
                      ELSE
                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                          lc_error_message := FND_MESSAGE.GET;
                          lc_message_code  := 'XX_TM_0122_AS_NO_SALES_ROLE';
                      END IF;
                      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                         p_return_code              => FND_API.G_RET_STS_ERROR
                                                         , p_application_name       => G_APPLICATION_NAME
                                                         , p_program_type           => G_PROGRAM_TYPE
                                                         , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_module_name            => G_MODULE_NAME
                                                         , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_error_message_code     => lc_message_code
                                                         , p_error_message          => lc_error_message
                                                         , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                         , p_error_status           => G_ERROR_STATUS_FLAG
                                                        );
                      RAISE EX_CREATE_ERR;
                  WHEN TOO_MANY_ROWS THEN
                      IF lc_assignee_manager_flag = 'Y' THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0230_AS_MGR_HSE_ROLE');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        lc_error_message := FND_MESSAGE.GET;
                        lc_message_code  := 'XX_TM_0230_AS_MGR_HSE_ROLE';
                      ELSE
                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                          FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                          lc_error_message := FND_MESSAGE.GET;
                          lc_message_code  := 'XX_TM_0123_AS_MANY_SALES_ROLE';
                      END IF;
                      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                         p_return_code              => FND_API.G_RET_STS_ERROR
                                                         , p_application_name       => G_APPLICATION_NAME
                                                         , p_program_type           => G_PROGRAM_TYPE
                                                         , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_module_name            => G_MODULE_NAME
                                                         , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_error_message_code     => lc_message_code
                                                         , p_error_message          => lc_error_message
                                                         , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                         , p_error_status           => G_ERROR_STATUS_FLAG
                                                        );
                      RAISE EX_CREATE_ERR;
                  WHEN OTHERS THEN
                      FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                      lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee.';
                      FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                      FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                      lc_error_message := FND_MESSAGE.GET;
                      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                         p_return_code              => FND_API.G_RET_STS_ERROR
                                                         , p_application_name       => G_APPLICATION_NAME
                                                         , p_program_type           => G_PROGRAM_TYPE
                                                         , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_module_name            => G_MODULE_NAME
                                                         , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                         , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                         , p_error_message          => lc_error_message
                                                         , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                         , p_error_status           => G_ERROR_STATUS_FLAG
                                                        );
                      RAISE EX_CREATE_ERR;

               END;

             ELSE

                 -- Derive the role_id and role_division of assignee resource
                 -- with the resource_id, group_id and role_code returned
                 -- from get_winners

                 BEGIN

                       SELECT JRR_ASG.role_id
                              , ROL_ASG.attribute15
                              , MEM_ASG.group_id
                       INTO   ln_asignee_role_id
                              , lc_assignee_role_division
                              , ln_sales_group_id
                       FROM   jtf_rs_group_members MEM_ASG
                              , jtf_rs_role_relations JRR_ASG
                              , jtf_rs_group_usages JRU_ASG
                              , jtf_rs_roles_b ROL_ASG
                       WHERE  MEM_ASG.resource_id = ln_salesforce_id
                       AND    MEM_ASG.group_id    = NVL(ln_sales_group_id,MEM_ASG.group_id)
                       AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                       AND    JRU_ASG.group_id    = MEM_ASG.group_id
                       AND    JRU_ASG.usage       = 'SALES'
                       AND    JRR_ASG.role_resource_id = MEM_ASG.group_member_id
                       AND    JRR_ASG.role_resource_type  = 'RS_GROUP_MEMBER'
                       AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active) 
                                             AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                       AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                       AND    ROL_ASG.role_id         = JRR_ASG.role_id
                       AND    ROL_ASG.role_code       = lc_role
                       AND    ROL_ASG.role_type_code  = 'SALES'
                       AND    ROL_ASG.active_flag     = 'Y';
                       
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0218_NO_SALES_ROLE');
                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                        FND_MESSAGE.SET_TOKEN('P_ROLE_CODE', lc_role);
                        FND_MESSAGE.SET_TOKEN('P_GROUP_ID', ln_sales_group_id);
                        lc_error_message := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                           , p_application_name       => G_APPLICATION_NAME
                                                           , p_program_type           => G_PROGRAM_TYPE
                                                           , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                           , p_module_name            => G_MODULE_NAME
                                                           , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                           , p_error_message_code     => 'XX_TM_0218_NO_SALES_ROLE'
                                                           , p_error_message          => lc_error_message
                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                          );
                        RAISE EX_CREATE_ERR;
                    WHEN OTHERS THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                        lc_set_message     :=  'Unexpected Error while deriving role_id and role_division of the assignee with the role_code';
                        FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                        FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                        lc_error_message := FND_MESSAGE.GET;
                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                           , p_application_name       => G_APPLICATION_NAME
                                                           , p_program_type           => G_PROGRAM_TYPE
                                                           , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                           , p_module_name            => G_MODULE_NAME
                                                           , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                           , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                           , p_error_message          => lc_error_message
                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                          );
                        RAISE EX_CREATE_ERR;
                 END;

             END IF; -- lc_role IS NULL
             
             IF (lc_creator_admin_flag = 'Y' OR lc_creator_manager_flag = 'Y' 
                           OR lc_assignee_admin_flag = 'Y') THEN

               lc_return_status := NULL;

               create_record(
                             p_resource_id            => ln_salesforce_id
                             , p_role_id              => ln_asignee_role_id
                             , p_group_id             => ln_sales_group_id
                             , p_party_site_id        => p_party_site_id
                             , p_full_access_flag     => lc_full_access_flag
                             , x_return_status        => lc_return_status
                            );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                 RAISE EX_CREATE_ERR;

               END IF;

             ELSE

                 -- Compare the division of assignee and creator resource 

                 IF lc_assignee_role_division = lc_creator_role_division THEN

                   -- If the resource returned is a manager

                   IF lc_assignee_manager_flag = 'Y' THEN

                     -- Check whether the creator and the assignee belong to the same group

                     IF ln_creator_group_id <> ln_sales_group_id THEN

                       -- This means that the manager and the creator belong to seperate group
                       -- So assign it to the manager

                       create_record(
                                     p_resource_id            => ln_salesforce_id
                                     , p_role_id              => ln_asignee_role_id
                                     , p_group_id             => ln_sales_group_id
                                     , p_party_site_id        => p_party_site_id
                                     , p_full_access_flag     => lc_full_access_flag
                                     , x_return_status        => lc_return_status
                                    );

                       IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

                         RAISE EX_CREATE_ERR;

                       END IF;

                     ELSE

                         -- This means that the manager and the creator belong to the same group
                         -- So assign it to the creator

                         create_record(
                                       p_resource_id            => ln_creator_resource_id
                                       , p_role_id              => ln_creator_role_id
                                       , p_group_id             => ln_creator_group_id
                                       , p_party_site_id        => p_party_site_id
                                       , p_full_access_flag     => lc_full_access_flag
                                       , x_return_status        => lc_return_status
                                      );

                         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                           RAISE EX_CREATE_ERR;
                         END IF;

                     END IF; -- ln_creator_group_id <> ln_sales_group_id

                   ELSE

                       -- Derive the manager of the asignee

                       BEGIN

                            SELECT MEM_MGR.resource_id
                            INTO   ln_asignee_manager_id
                            FROM   jtf_rs_group_members MEM_ASG
                                   , jtf_rs_role_relations JRR_ASG
                                   , jtf_rs_roles_b ROL_ASG
                                   , jtf_rs_group_usages JRU
                                   , jtf_rs_group_members MEM_MGR
                                   , jtf_rs_role_relations JRR_MGR
                                   , jtf_rs_roles_b ROL_MGR
                            WHERE  MEM_ASG.resource_id = ln_salesforce_id
                            AND    NVL(MEM_ASG.delete_flag,'N') <> 'Y'
                            AND    JRU.group_id        = MEM_ASG.group_id
                            AND    JRU.usage           = 'SALES'
                            AND    JRR_ASG.role_resource_id   = MEM_ASG.group_member_id
                            AND    JRR_ASG.role_resource_type = 'RS_GROUP_MEMBER'
                            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_ASG.start_date_active) 
                                                  AND NVL(TRUNC(JRR_ASG.end_date_active),TRUNC(SYSDATE))
                            AND    NVL(JRR_ASG.delete_flag,'N') <> 'Y'
                            AND    ROL_ASG.role_id         = JRR_ASG.role_id
                            AND    ROL_ASG.role_type_code  = 'SALES'
                            AND    ROL_ASG.active_flag     = 'Y'
                            AND    MEM_MGR.group_id        = MEM_ASG.group_id
                            AND    NVL(MEM_MGR.delete_flag,'N') <> 'Y'
                            AND    JRU.group_id            = MEM_MGR.group_id
                            AND    JRU.usage               = 'SALES'
                            AND    JRR_MGR.role_resource_id   = MEM_MGR.group_member_id
                            AND    JRR_MGR.role_resource_type = 'RS_GROUP_MEMBER'
                            AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR_MGR.start_date_active) 
                                                  AND NVL(TRUNC(JRR_MGR.end_date_active),TRUNC(SYSDATE))
                            AND    NVL(JRR_MGR.delete_flag,'N') <> 'Y'
                            AND    ROL_MGR.role_id        = JRR_MGR.role_id
                            AND    ROL_MGR.role_type_code = 'SALES'
                            AND    ROL_MGR.active_flag    = 'Y'
                            AND    ROL_MGR.manager_flag   = 'Y';
                                       
                       EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0127_AS_NO_MANAGER');
                              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                              lc_error_message := FND_MESSAGE.GET;
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0127_AS_NO_MANAGER'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                ); 
                              RAISE EX_CREATE_ERR;
                          WHEN TOO_MANY_ROWS THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0128_AS_MANY_MANAGERS');
                              FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                              lc_error_message := FND_MESSAGE.GET;
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0128_AS_MANY_MANAGERS'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                );
                              RAISE EX_CREATE_ERR;
                          WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                              lc_set_message     :=  'Unexpected Error while deriving manager_id of the assignee';
                              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                              lc_error_message := FND_MESSAGE.GET;
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                );
                              RAISE EX_CREATE_ERR;

                       END;

                       -- Compare the manager of the creator to that of the asignee 

                       IF ln_creator_manager_id = ln_asignee_manager_id THEN

                         lc_return_status := NULL;

                         -- Create a territory, an entity and a resource for the creator of the party-site

                         create_record(
                                       p_resource_id            => ln_creator_resource_id
                                       , p_role_id              => ln_creator_role_id
                                       , p_group_id             => ln_creator_group_id
                                       , p_party_site_id        => p_party_site_id
                                       , p_full_access_flag     => lc_full_access_flag
                                       , x_return_status        => lc_return_status
                                      );

                         IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                           RAISE EX_CREATE_ERR;
                         END IF;

                       ELSE

                           lc_return_status := NULL;

                           -- Create a territory, an entity and a resource for the asignee of the party-site

                           create_record(
                                         p_resource_id            => ln_salesforce_id
                                         , p_role_id              => ln_asignee_role_id
                                         , p_group_id             => ln_sales_group_id
                                         , p_party_site_id        => p_party_site_id
                                         , p_full_access_flag     => lc_full_access_flag
                                         , x_return_status        => lc_return_status
                                        );

                           IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                             RAISE EX_CREATE_ERR;
                           END IF;

                       END IF; -- ln_creator_manager_id = ln_asignee_manager_id

                   END IF; -- lc_assignee_manager_flag = 'Y'

                 ELSE

                     lc_return_status := NULL;

                     -- Create a territory, an entity and a resource for the asignee of the party-site 

                     create_record(
                                   p_resource_id            => ln_salesforce_id
                                   , p_role_id              => ln_asignee_role_id
                                   , p_group_id             => ln_sales_group_id
                                   , p_party_site_id        => p_party_site_id
                                   , p_full_access_flag     => lc_full_access_flag
                                   , x_return_status        => lc_return_status
                                  );

                     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                       RAISE EX_CREATE_ERR;
                     END IF;

                 END IF; -- lc_assignee_role_division = lc_creator_role_division

             END IF; -- lc_creator_admin_flag = 'Y'
       
       EXCEPTION
          WHEN EX_CREATE_ERR THEN
              NULL;
          WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
              lc_set_message     :=  'Unexpected Error while creating a party site id : '||p_party_site_id;
              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
              lc_error_message := FND_MESSAGE.GET;
              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                 , p_application_name       => G_APPLICATION_NAME
                                                 , p_program_type           => G_PROGRAM_TYPE
                                                 , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                                 , p_module_name            => G_MODULE_NAME
                                                 , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE' 
                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                 , p_error_message          => lc_error_message 
                                                 , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                ); 
       END;
       
       l_counter   := l_counter + 1;
   
   END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST
   
   -- As the record is successfully populated in the custom assignments table 
   -- Insert a record into the log table
   
   XX_COM_ERROR_LOG_PUB.log_error_crm(
                                      p_return_code              => FND_API.G_RET_STS_SUCCESS
                                      , p_application_name       => G_APPLICATION_NAME
                                      , p_program_type           => G_PROGRAM_TYPE
                                      , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                      , p_module_name            => G_MODULE_NAME
                                      , p_error_location         => 'Successfully created'
                                      , p_error_message_code     => 'Success'
                                      , p_error_message          => 'Successfully created for the party_site_id : '||p_party_site_id
                                      , p_error_message_severity => 'SUCCESS'
                                     );
                                     
   COMMIT;                                  

EXCEPTION
   WHEN EX_PARTY_SITE_ERROR THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0159_MANU_PARTY_SITE_ERR');
       FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', p_party_site_id);
       lc_error_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0159_MANU_PARTY_SITE_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         ); 
       ROLLBACK;
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a party site id : '||p_party_site_id;
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_PTY_SITE_CRTN.CREATE_PARTY_SITE' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message 
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         ); 
      ROLLBACK;

END create_party_site;
END XX_JTF_SALES_REP_PTY_SITE_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
