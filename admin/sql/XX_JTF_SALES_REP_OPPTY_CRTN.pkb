SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_OPPTY_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SALES_REP_OPPTY_CRTN 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_OPPTY_CRTN                                   |
-- |                                                                                   |
-- | Description      :  This custom package will get triggered when a sales-rep       |
-- |                     creates an opportunity                                        |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                  Description                                     |
-- |=========    ===========           ================================================|
-- |PROCEDURE    Create_Sales_Oppty    This is the public procedure.                   |
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
-- | Name  : Create_Sales_Oppty                                        |
-- |                                                                   |
-- | Description:       This is the public procedure to create an      |
-- |                    opportunity record in the custom assignments   |
-- |                    table when a sales-rep creates a party_site    |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE create_sales_oppty(
                             p_oppty_id IN NUMBER
                            )
IS

---------------------------
--Declaring local variables
---------------------------
EX_CREATE_OPPTY       EXCEPTION;
ln_address_id         PLS_INTEGER;
ln_api_version        PLS_INTEGER := 1.0;
lc_return_status      VARCHAR2(03);
lc_msg_data           VARCHAR2(2000);
ln_msg_count          PLS_INTEGER;
lc_message            VARCHAR2(2000);
ln_named_acct_terr_id PLS_INTEGER;
lc_entity_exists      VARCHAR2(03);
lc_set_message        VARCHAR2(2000);
-- --------------------------------------------------------------------------------------
-- Declare cursor to fetch the records from hz_party_sites based on initialization_date
-- --------------------------------------------------------------------------------------
CURSOR lcu_oppty
IS 
SELECT address_id
FROM   as_leads_all
WHERE  lead_id = p_oppty_id;

--------------------------------
--Declaring Table Type Variables
--------------------------------
lt_details_rec        XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup_out_tbl_type;


BEGIN
   
   -- Derive the record from AS_LEADS_ALL
   
   OPEN  lcu_oppty;
   FETCH lcu_oppty INTO ln_address_id;
   CLOSE lcu_oppty;
   
   IF ((p_oppty_id IS NOT NULL) AND (ln_address_id IS NOT NULL)) THEN
     
     -- Call to Current Date Named Account Territory Lookup API 
        
     -- Derive named_acct_terr_id, resource_id , role_id and group_id 
     -- by passing the address_id to the Current Date Named Account Lookup API
        
     lt_details_rec.DELETE;
     lc_return_status := NULL;
     lc_msg_data      := NULL;
        
     XX_TM_TERRITORY_UTIL_PKG.nam_terr_lookup(
                                              p_api_version_number             => ln_api_version 
                                              , p_entity_type                  => 'PARTY_SITE' 
                                              , p_entity_id                    => ln_address_id
                                              , x_nam_terr_lookup_out_tbl_type => lt_details_rec
                                              , x_return_status                => lc_return_status
                                              , x_message_data                 => lc_msg_data
                                             );
                                                
     IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_error_message_count    => 1
                                          , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                          , p_error_message          => lc_msg_data
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         ); 
                                                         
       RAISE EX_CREATE_OPPTY;
        
     END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
     
     lc_message := NULL;
        
     IF lt_details_rec.COUNT = 0 THEN
              
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0135_NO_TERRITORY');
       FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_address_id);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_error_message_code     => 'XX_TM_0135_NO_TERRITORY'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
       RAISE EX_CREATE_OPPTY;
     END IF; -- lt_details_rec.COUNT = 0   
     
     -- Else for each of the named_acct_terr_ids returned 
                
     FOR I IN lt_details_rec.FIRST .. lt_details_rec.LAST
     LOOP
                    
         -- Initializing the variables
         ln_named_acct_terr_id := NULL;
         lc_entity_exists      := NULL;
                    
         ln_named_acct_terr_id := lt_details_rec(i).nam_terr_id;
                    
         -- Since the territory exists, check whether the entity_type and 
         -- entity_id already exists 
                                    
         BEGIN
                                    
              SELECT 'Y'
              INTO   lc_entity_exists
              FROM   xx_tm_nam_terr_curr_assign_v XTNT
              WHERE  XTNT.named_acct_terr_id = ln_named_acct_terr_id
              AND    XTNT.entity_id = p_oppty_id
              AND    XTNT.entity_type = 'OPPORTUNITY'; 
                                       
         EXCEPTION
            WHEN OTHERS THEN
                lc_entity_exists := NULL;
         END;
                    
                    
         IF lc_entity_exists IS NULL THEN 
                      
           /* The entity_type 'OPPORTUNITY' does not exist for this named_acct_terr_id. So creating an entity 
               with this named_acct_terr_id */
                      
           lc_return_status  := NULL;
           lc_msg_data       := NULL;
           ln_msg_count      := NULL;
              
           XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                                  p_api_version          => ln_api_version
                                                  , p_named_acct_terr_id => ln_named_acct_terr_id
                                                  , p_entity_type        => 'OPPORTUNITY'
                                                  , p_entity_id          => p_oppty_id
                                                  , x_return_status      => lc_return_status
                                                  , x_message_data       => lc_msg_data
                                                  , x_msg_count          => ln_msg_count 
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
                                                    , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                                    , p_module_name            => G_MODULE_NAME
                                                    , p_error_location         => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                                    , p_error_message_count    => k
                                                    , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                    , p_error_message          => lc_msg_data
                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                   ); 
                                                      
             END LOOP;
             RAISE EX_CREATE_OPPTY;
                                                      
           END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS of XX_JTF_RS_NAMED_ACC_TERR.insert_row
                    
         END IF; -- lc_entity_exists IS NULL
                
     END LOOP; -- lt_details_rec.FIRST .. lt_details_rec.LAST
     
     -- As the record is successfully populated in the custom assignments table 
     -- Insert a record into the log table
           
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code              => FND_API.G_RET_STS_SUCCESS
                                        , p_application_name       => G_APPLICATION_NAME
                                        , p_program_type           => G_PROGRAM_TYPE
                                        , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                        , p_module_name            => G_MODULE_NAME
                                        , p_error_location         => 'Successfully created'
                                        , p_error_message_code     => 'Success'
                                        , p_error_message          => 'Successfully created for the opportunity_id : '||p_oppty_id
                                        , p_error_message_severity => 'SUCCESS'
                                       );
                                             
     COMMIT;              
                     
   END IF; -- ((p_oppty_id IS NOT NULL) AND (ln_address_id IS NOT NULL))
                      
EXCEPTION
   WHEN EX_CREATE_OPPTY THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0134_OPPTY_ERR');
       FND_MESSAGE.SET_TOKEN('P_LEAD_ID', p_oppty_id);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_error_message_code     => 'XX_TM_0134_OPPTY_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating an opportunity with lead_id : '||p_oppty_id;
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_OPPTY_CRTN.CREATE_SALES_OPPTY'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
       
END create_sales_oppty;
            
END XX_JTF_SALES_REP_OPPTY_CRTN;     
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
