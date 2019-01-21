SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_LEAD_SYNC package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SALES_REP_LEAD_SYNC
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_LEAD_SYNC                                    |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: Synchronize Lead Named Account' to update        |
-- |                     the lead in the custom assignments entity table               |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Update_Lead             This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  16-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  08-Nov-07   Abhradip Ghosh               Modified code according to the  |
-- |                                                   new logic of comparing          |
-- |                                                   named_acct_terr_ids             |
-- |Draft 1c  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- |Draft 1d  04-Aug-09   Kishore Jena                 Changed the main query to pick  |
-- |                                                   only lead records that have a   |
-- |                                                   different territory assignment  |
-- |                                                   than the corresponding party    |
-- |                                                   site instead of all leads.      |
-- |                                                   (Performance QC Defect # 1757)  |  
-- |2.0       09-Nov-16   Havish Kasina                Removed the schema references   |
-- |                                                   for 12.2 GSCC changes           |
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
---------------------------
--Declaring local variables
---------------------------
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
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the output file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;

-- +===================================================================+
-- | Name  : update_lead                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD:        |
-- |                    Synchronize lead Named Account' to             |
-- |                    update the lead in the custom                  |
-- |                    assignments entity table                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_lead
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            )
IS

---------------------------
--Declaring local variables
---------------------------
EX_LEAD_SYNC         EXCEPTION;
ln_lead_id           PLS_INTEGER;
ln_total_count       PLS_INTEGER := 0;
lc_error_message     VARCHAR2(2000);
ln_error_count       PLS_INTEGER := 0;
lc_set_message       VARCHAR2(2000);
ln_address_id        PLS_INTEGER;
ln_success_count     PLS_INTEGER := 0;
lc_return_status     VARCHAR2(03);
ln_msg_count         PLS_INTEGER;
lc_msg_data          VARCHAR2(2000);
ln_exists_count      PLS_INTEGER := 0;
lc_total_count       VARCHAR2(1000);
lc_total_success     VARCHAR2(1000);
lc_total_failed      VARCHAR2(1000);
lc_total_exists      VARCHAR2(1000);
lc_lead_sync_success VARCHAR2(03);
ln_lead_updt_success PLS_INTEGER := 0;
lc_total_upd_success VARCHAR2(1000);
lc_record_exists     VARCHAR2(03);

-- --------------------------------------------------------------------------------------
-- Declare cursor to fetch the records from Current Date Named Account Assignment View
-- --------------------------------------------------------------------------------------
CURSOR lcu_lead_id IS
SELECT a.entity_id
FROM   xx_tm_nam_terr_curr_assign_v a 
WHERE  a.entity_type = 'LEAD'
  and  NOT EXISTS (SELECT 1
                   FROM   as_sales_leads b,
                          xx_tm_nam_terr_curr_assign_v c
                   WHERE  b.sales_lead_id = a.entity_id
                     AND  c.entity_type   = 'PARTY_SITE'
                     AND  c.entity_id     = b.address_id  
                     AND  nvl(c.named_acct_terr_id, 0) = nvl(a.named_acct_terr_id, 0)
                  );             
-------------------------------------------------------------------------------------------
-- Declare cursor to fetch the records that do not exist either for the PARTY_SITE OR LEAD
-------------------------------------------------------------------------------------------
CURSOR lcu_named_acct_terr_id(
                              p_entity_type1   VARCHAR2                
                              , p_entity_id1   NUMBER
                              , p_entity_type2 VARCHAR2
                              , p_entity_id2   NUMBER
                             )
IS
SELECT XTNV1.named_acct_terr_id
FROM   xx_tm_nam_terr_curr_assign_v XTNV1
WHERE  XTNV1.entity_type = p_entity_type1
AND    XTNV1.entity_id   = p_entity_id1
MINUS
SELECT XTNV2.named_acct_terr_id
FROM   xx_tm_nam_terr_curr_assign_v XTNV2
WHERE  XTNV2.entity_type = p_entity_type2
AND    XTNV2.entity_id   = p_entity_id2;

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE lead_id_tbl_type IS TABLE OF xx_tm_nam_terr_curr_assign_v.entity_id%TYPE INDEX BY BINARY_INTEGER;
lt_lead_id lead_id_tbl_type;

TYPE named_acct_tbl_type IS TABLE OF xx_tm_nam_terr_curr_assign_v.named_acct_terr_id%TYPE INDEX BY BINARY_INTEGER;
lt_named_acct_site named_acct_tbl_type;
lt_named_acct_lead named_acct_tbl_type;

BEGIN
                                                   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
                                                                     
   WRITE_LOG(RPAD('Office Depot',65)||LPAD('Date: '||TRUNC(sysdate),25));
   WRITE_LOG(RPAD(' ',90,'-'));
   WRITE_LOG(LPAD('OD: Synchronize Lead Named Account',62));
   WRITE_LOG(RPAD(' ',90,'-'));
   WRITE_LOG('');
                                                
   WRITE_OUT(RPAD('Office Depot',65)||LPAD('Date: '||TRUNC(sysdate),25));
   WRITE_OUT(RPAD(' ',90,'-'));
   WRITE_OUT(LPAD('OD: Synchronize Lead Named Account',62));
   WRITE_OUT(RPAD(' ',90,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',90,'-'));
                                             
   -- First retrieve all the records from Current Date Named Account Assignment View
                                             
   OPEN lcu_lead_id;
   LOOP
                                             
       FETCH lcu_lead_id BULK COLLECT INTO lt_lead_id LIMIT G_LIMIT;
                                          
       IF lt_lead_id.COUNT <> 0 THEN
                                             
          FOR i IN lt_lead_id.FIRST .. lt_lead_id.LAST
          LOOP
                                       
              BEGIN
                                                
                 -- Initializing the variable
                                       
                 ln_lead_id := NULL;
                 lt_named_acct_site.DELETE;
                 lc_error_message := NULL;
                 ln_address_id := NULL;
                 lc_record_exists := NULL;
                 lc_lead_sync_success := NULL;
                 lt_named_acct_lead.DELETE;
                                                                    
                 -- To count the number of records read
                                                      
                 ln_total_count := ln_total_count + 1;
                                                      
                 ln_lead_id := lt_lead_id(i);
                                                               
                 WRITE_LOG(RPAD(' ',80,'-'));
                 WRITE_LOG('Processing for the lead_id: '||ln_lead_id);
                 
                 -- Fetch the address_id for that lead_id from the table AS_SALES_LEADS
                 
                 BEGIN
                                               
                      SELECT ASL.address_id
                      INTO   ln_address_id
                      FROM   as_sales_leads ASL
                      WHERE  ASL.sales_lead_id =  ln_lead_id;
                 
                 EXCEPTION
                    WHEN OTHERS THEN
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0150_ADDRESS_ERR');
                        FND_MESSAGE.SET_TOKEN('P_LEAD_ID', ln_lead_id);
                        lc_error_message := FND_MESSAGE.GET;
                        WRITE_LOG(lc_error_message);
                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                           , p_application_name       => G_APPLICATION_NAME
                                                           , p_program_type           => G_PROGRAM_TYPE
                                                           , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                           , p_program_id             => gn_program_id
                                                           , p_module_name            => G_MODULE_NAME
                                                           , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                           , p_error_message_code     => 'XX_TM_0150_ADDRESS_ERR'
                                                           , p_error_message          => lc_error_message
                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                          );
                        RAISE EX_LEAD_SYNC;
                 END;
                 
                 -- Validate whether the Named_Acct_Terr_ID (associated to the PARTY SITE) derived
                 -- is different from the Named_Acct_Terr_ID (associated to the LEAD)
                                                           
                 OPEN lcu_named_acct_terr_id(
                                             p_entity_type1   => 'PARTY_SITE'                
                                             , p_entity_id1   => ln_address_id
                                             , p_entity_type2 => 'LEAD'
                                             , p_entity_id2   => ln_lead_id
                                            );
                 FETCH lcu_named_acct_terr_id BULK COLLECT INTO lt_named_acct_site;
                 CLOSE lcu_named_acct_terr_id;
                 
                 -- If any record is found, insert that record in the custom assignments table
                 
                 IF lt_named_acct_site.COUNT <> 0 THEN
                   
                   lc_record_exists      := 'N';
                   lc_lead_sync_success  := 'Y';
                   
                   FOR j IN lt_named_acct_site.FIRST .. lt_named_acct_site.LAST
                   LOOP
                       
                       lc_return_status      := NULL;
                       ln_msg_count          := NULL;
                       lc_msg_data           := NULL;
                       
                       -- Create a new entity record entity_type = 'LEAD'
                       
                       XX_JTF_RS_NAMED_ACC_TERR.insert_row(
                                                           p_api_version            => 1.0
                                                           , p_start_date_active    => SYSDATE
                                                           , p_named_acct_terr_id   => lt_named_acct_site(j)
                                                           , p_entity_type          => 'LEAD'
                                                           , p_entity_id            => ln_lead_id
                                                           , x_return_status        => lc_return_status
                                                           , x_msg_count            => ln_msg_count
                                                           , x_message_data         => lc_msg_data
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
                                                                , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                                , p_program_id             => gn_program_id
                                                                , p_module_name            => G_MODULE_NAME
                                                                , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                                , p_error_message_count    => k
                                                                , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                , p_error_message          => lc_msg_data
                                                                , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                , p_error_status           => G_ERROR_STATUS_FLAG
                                                               );
                         END LOOP; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                         RAISE EX_LEAD_SYNC;
                       
                       ELSE
                           
                           ln_lead_updt_success := ln_lead_updt_success + 1;
                           
                           
                       END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                             
                   END LOOP; -- lt_named_acct_site.FIRST .. lt_named_acct_site.LAST
                 
                 END IF; -- lt_named_acct_site.COUNT <> 0
                 
                 -- Validate whether the Named_Acct_Terr_ID (associated to the LEAD) derived
                 -- is different from the Named_Acct_Terr_ID (associated to the Party Site)
                 
                 OPEN lcu_named_acct_terr_id(
                                             p_entity_type1   => 'LEAD'
                                             , p_entity_id1   => ln_lead_id 
                                             , p_entity_type2 => 'PARTY_SITE'
                                             , p_entity_id2   => ln_address_id
                                            );
                 FETCH lcu_named_acct_terr_id BULK COLLECT INTO lt_named_acct_lead;
                 CLOSE lcu_named_acct_terr_id; 
                 
                 -- If any record is found, end date that record in the custom assignments table
                                  
                 IF lt_named_acct_lead.COUNT <> 0 THEN
                   
                   lc_record_exists      := 'N';
                   lc_lead_sync_success  := 'Y';                   
                   
                   FOR l IN lt_named_acct_lead.FIRST .. lt_named_acct_lead.LAST
                   LOOP
                                        
                       lc_return_status      := NULL;
                       ln_msg_count          := NULL;
                       lc_msg_data           := NULL;
                                        
                       -- End Date the entity record entity_type = 'LEAD'
                                        
                       XX_JTF_RS_NAMED_ACC_TERR.update_row(
                                                           p_api_version            => 1.0
                                                           , p_start_date_active    => NULL
                                                           , p_end_date_active      => SYSDATE
                                                           , p_named_acct_terr_id   => lt_named_acct_lead(l)
                                                           , p_entity_type          => 'LEAD'
                                                           , p_entity_id            => ln_lead_id
                                                           , x_return_status        => lc_return_status
                                                           , x_msg_count            => ln_msg_count
                                                           , x_message_data         => lc_msg_data
                                                          );
                                       
                       IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                                       
                         FOR m IN 1 .. ln_msg_count
                         LOOP
                                       
                             lc_msg_data := FND_MSG_PUB.GET(
                                                            p_encoded     => FND_API.G_FALSE
                                                            , p_msg_index => m
                                                           );
                             XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                p_return_code              => FND_API.G_RET_STS_ERROR
                                                                , p_application_name       => G_APPLICATION_NAME
                                                                , p_program_type           => G_PROGRAM_TYPE
                                                                , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                                , p_program_id             => gn_program_id
                                                                , p_module_name            => G_MODULE_NAME
                                                                , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                                , p_error_message_count    => m
                                                                , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                , p_error_message          => lc_msg_data
                                                                , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                , p_error_status           => G_ERROR_STATUS_FLAG
                                                               );
                                                               
                         END LOOP; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                         RAISE EX_LEAD_SYNC;
                                       
                       ELSE
                                                  
                           ln_lead_updt_success := ln_lead_updt_success + 1;
                           
                       END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                                              
                   END LOOP; -- lt_named_acct_lead.FIRST .. lt_named_acct_lead.LAST
                                  
                 END IF; -- lt_named_acct_lead.COUNT <> 0
                 
              EXCEPTION
                 WHEN EX_LEAD_SYNC THEN
                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0169_LEAD_SYNC_FAILED');
                     FND_MESSAGE.SET_TOKEN('P_LEAD_ID', ln_lead_id);
                     lc_error_message := FND_MESSAGE.GET;
                     lc_lead_sync_success := 'N';
                     lc_record_exists     := 'N';
                     WRITE_LOG(lc_error_message);
                     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                        p_return_code              => FND_API.G_RET_STS_ERROR
                                                        , p_application_name       => G_APPLICATION_NAME
                                                        , p_program_type           => G_PROGRAM_TYPE
                                                        , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                        , p_program_id             => gn_program_id
                                                        , p_module_name            => G_MODULE_NAME
                                                        , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                        , p_error_message_code     => 'XX_TM_0169_LEAD_SYNC_FAILED'
                                                        , p_error_message          => lc_error_message
                                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                                       );
                 WHEN OTHERS THEN
                     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                     lc_set_message     :=  'Unexpected Error while synchronization of lead_id : '||ln_lead_id;
                     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                     lc_error_message := FND_MESSAGE.GET;
                     lc_lead_sync_success := 'N';
                     lc_record_exists     := 'N';
                     WRITE_LOG(lc_error_message);
                     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                        p_return_code              => FND_API.G_RET_STS_ERROR
                                                        , p_application_name       => G_APPLICATION_NAME
                                                        , p_program_type           => G_PROGRAM_TYPE
                                                        , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                        , p_program_id             => gn_program_id
                                                        , p_module_name            => G_MODULE_NAME
                                                        , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                                        , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                        , p_error_message          => lc_error_message
                                                        , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                        , p_error_status           => G_ERROR_STATUS_FLAG
                                                       );
              END;
              
              IF lc_lead_sync_success = 'Y' THEN
                                                                  
                ln_success_count := ln_success_count + 1;
                                                                  
              ELSIF lc_lead_sync_success = 'N' THEN
                                                                  
                   ln_error_count := ln_error_count + 1;
                                                                  
              END IF; -- lc_lead_sync_success = 'Y'
              
              IF lc_record_exists IS NULL THEN
                
                ln_exists_count := ln_exists_count + 1;
                
              END IF;
                                                                     
              IF MOD(i,G_COMMIT) = 0 THEN
                COMMIT;
              END IF;
                                 
          END LOOP; -- lt_lead_id.FIRST .. lt_lead_id.LAST
                              
       END IF; -- lt_lead_id.COUNT <> 0
                           
       EXIT WHEN lcu_lead_id%NOTFOUND;
                                          
   END LOOP;  -- lcu_lead_id
                                       
   CLOSE lcu_lead_id;
                                             
   COMMIT;

/* Code is commented by Kishore Jena on 08/04/2009 as no more needed                                                
   IF ln_total_count = 0 THEN                                                   
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0155_NO_RECORDS_ENTITY');
     FND_MESSAGE.SET_TOKEN('P_ENTITY_TYPE', 'LEAD');
     lc_error_message := FND_MESSAGE.GET;
     WRITE_LOG(lc_error_message);
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code               => FND_API.G_RET_STS_ERROR
                                        , p_application_name        => G_APPLICATION_NAME
                                        , p_program_type            => G_PROGRAM_TYPE
                                        , p_program_name            => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                        , p_program_id              => gn_program_id
                                        , p_module_name             => G_MODULE_NAME
                                        , p_error_location          => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                        , p_error_message_code      => 'XX_TM_0155_NO_RECORDS_ENTITY'
                                        , p_error_message           => lc_error_message
                                        , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status            => G_ERROR_STATUS_FLAG
                                       );
     x_retcode := 1;
   END IF; -- ln_total_count = 0
*/

   -- ----------------------------------------------------------------------------
   -- Write to output file, the total number of records processed, number of
   -- success and failure records.
   -- ----------------------------------------------------------------------------

   WRITE_OUT(' ');

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0131_TOTAL_RECORD_READ');
   FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', ln_total_count);
   lc_total_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_count);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0132_TOTAL_RECORD_SUCC');
   FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS', ln_success_count);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0133_TOTAL_RECORD_ERR');
   FND_MESSAGE.SET_TOKEN('P_RECORD_ERROR', ln_error_count);
   lc_total_failed    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_failed);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0146_TOTAL_RECORDS_EXIST');
   FND_MESSAGE.SET_TOKEN('P_RECORD_EXIST', ln_exists_count);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);

   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0165_TOTAL_RECS_UPDATED');
   FND_MESSAGE.SET_TOKEN('P_RECORDS_UPDATED', ln_lead_updt_success);
   lc_total_upd_success  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_upd_success);
   
   IF ln_error_count <> 0 THEN
     
     x_retcode := 1;
   
   END IF;
   
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while synchronization of lead';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                            p_return_code            => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_LEAD_SYNC.UPDATE_LEAD'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END update_lead;

END XX_JTF_SALES_REP_LEAD_SYNC;
/
SHOW ERRORS;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
