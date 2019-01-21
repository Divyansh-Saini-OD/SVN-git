SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SALES_REP_BL_LEAD_CRTN package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SALES_REP_BL_LEAD_CRTN
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SALES_REP_BL_LEAD_CRTN                                 |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Lead Named Account Mass Assignment Master     | 
-- |                     Program' and 'OD: TM Lead Named Account Mass Assignment Child |
-- |                     Program' Lead ID From and Lead ID To as the Input parameter.  |
-- |                     This public procedure will create a lead record in the custom |
-- |                     assignments table                                             |
-- |                                                                                   |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Master_Main             This is a public procedure.                   |
-- |PROCEDURE    Child_Main              This is a public procedure.                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  12-Oct-07   Abhradip Ghosh               Initial draft version           |
-- |Draft 1b  12-Nov-07   Abhradip Ghosh               Incorporated the standards for  |
-- |                                                   EBS error logging               |
-- |Draft 1c  25-Feb-08   Abhradip Ghosh               Changed the program to          |
-- |                                                   multi-threading                 |
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
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.WRITE_LOG'
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
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;

-- +===================================================================+
-- | Name  : master_main                                                |
-- |                                                                    |
-- | Description:       This is the public procedure which will get     |
-- |                    called from the concurrent program 'OD: TM Lead |
-- |                    Named Account Mass Assignment Master            |
-- |                    Program' with Lead ID From and Lead ID To       |
-- |                    as the Input parameters to launch a             |
-- |                    number of child processes for parallel          |
-- |                    execution depending upon the batch size         |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main
            (
               x_errbuf       OUT NOCOPY VARCHAR2
             , x_retcode      OUT NOCOPY NUMBER
             , p_from_lead_id IN         NUMBER
             , p_to_lead_id   IN         NUMBER
            )
IS
--------------------------------
-- Declaring Local Variables
--------------------------------
EX_PARAM_ERROR         EXCEPTION;
EX_SUBMIT_CHILD        EXCEPTION;
ln_succ_lead_id        PLS_INTEGER;
ln_min_lead_id         PLS_INTEGER;
ln_max_lead_id         PLS_INTEGER;
ln_batch_size          PLS_INTEGER := NVL(FND_PROFILE.VALUE('XX_TM_PARTY_SITE_BATCH_SIZE'),G_BATCH_SIZE);
ln_request_id          PLS_INTEGER;
ln_max_range_lead_id   PLS_INTEGER;
ln_profile_min_lead_id PLS_INTEGER;
ln_min_range_lead_id   PLS_INTEGER;
ln_value               PLS_INTEGER;
ln_profile_max_lead_id PLS_INTEGER;
ln_lead_crtn_scs_id    PLS_INTEGER;
ln_batch_count         PLS_INTEGER := 0;
lc_error_message       VARCHAR2(2000);
lc_update_profile_flag VARCHAR2(03);
lc_message             VARCHAR2(2000);
lc_set_message         VARCHAR2(2000);
lc_phase               VARCHAR2(30);

BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   WRITE_LOG(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',5,' ')||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(RPAD(' ',10,' ')||RPAD('OD: TM Lead Named Account Mass Assignment Master Program',56));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG(RPAD(' ',1,' ')||'Input Parameters ');
   WRITE_LOG(RPAD(' ',1,' ')||'Lead ID From : '||p_from_lead_id);
   WRITE_LOG(RPAD(' ',1,' ')||'Lead ID To   : '||p_to_lead_id);
   WRITE_LOG(RPAD(' ',80,'-'));

   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',5,' ')||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT(RPAD(' ',10,' ')||RPAD('OD: TM Lead Named Account Mass Assignment Master Program',56));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',80,'-'));
   
   
   IF (p_from_lead_id IS NULL AND p_to_lead_id IS NULL) THEN
       
      lc_update_profile_flag := 'Y'; 
      ln_value := 0;
      
      -- Fetch the last successfully processed lead id from the profile
      BEGIN
                      
           SELECT FPOV.profile_option_value
           INTO   ln_succ_lead_id
           FROM   fnd_profile_option_values FPOV
                  , fnd_profile_options FPO
           WHERE  FPO.profile_option_id = FPOV.profile_option_id
           AND    FPO.application_id = FPOV.application_id
           AND    FPOV.level_id = G_LEVEL_ID
           AND    FPOV.level_value = G_LEVEL_VALUE
           AND    FPOV.profile_option_value IS NOT NULL
           AND    FPO.profile_option_name = 'XX_TM_AUTO_MAX_LEAD_ID';
                      
      EXCEPTION
      WHEN OTHERS THEN
          ln_succ_lead_id := 0;
      END;      
      
      -- Select max sales_lead_id from the table AS_SALES_LEADS
      SELECT MAX(ASL.sales_lead_id)
      INTO   ln_max_range_lead_id
      FROM   as_sales_leads ASL
      WHERE  ASL.sales_lead_id > ln_succ_lead_id;
      
      ln_min_range_lead_id := ln_succ_lead_id;
      
      
   ELSIF (p_from_lead_id IS NOT NULL AND p_to_lead_id IS NOT NULL) THEN
         
         lc_update_profile_flag := 'N';
         ln_value := -1;
         
         ln_min_range_lead_id := p_from_lead_id;
         ln_max_range_lead_id := p_to_lead_id;
         
   ELSE
       
       RAISE EX_PARAM_ERROR;
       
   END IF;
   
   IF ln_max_range_lead_id IS NOT NULL THEN
      IF  CEIL((ln_max_range_lead_id - ln_min_range_lead_id) / ln_batch_size)  >0 then
      FOR i in 1.. CEIL((ln_max_range_lead_id - ln_min_range_lead_id) / ln_batch_size) 
      LOOP
          
          ln_min_lead_id := ((ln_min_range_lead_id + i + ln_value) + (ln_batch_size * (i-1)));
                              
          ln_max_lead_id := CASE WHEN ((ln_min_range_lead_id + i + ln_value) + (ln_batch_size * i)) > ln_max_range_lead_id
                                      THEN ln_max_range_lead_id
                                 ELSE ((ln_min_range_lead_id + i + ln_value) + (ln_batch_size * i)) 
                            END;
          
          -- ---------------------------------------------------------
          -- Call the custom concurrent program for parallel execution
          -- ---------------------------------------------------------
          ln_request_id := FND_REQUEST.submit_request(
                                                      application  => G_APPLICATION_NAME
                                                      ,program     => G_CHLD_PROG_EXECUTABLE
                                                      ,sub_request => FALSE
                                                      ,argument1   => ln_min_lead_id
                                                      ,argument2   => ln_max_lead_id
                                                     ); 
                       
          IF ln_request_id = 0 THEN
                          
             RAISE EX_SUBMIT_CHILD;
                       
          ELSE
                            
              COMMIT;
              gn_index_req_id                                 := gn_index_req_id + 1;
              gt_req_id_lead_id(gn_index_req_id).request_id   := ln_request_id;
              gt_req_id_lead_id(gn_index_req_id).from_lead_id := ln_min_lead_id;
              gt_req_id_lead_id(gn_index_req_id).to_lead_id   := ln_max_lead_id;
              ln_batch_count                                  := ln_batch_count + 1;
                 
          END IF; -- ln_request_id = 0          
      
      END LOOP;
      ELSE
      
             ln_request_id := FND_REQUEST.submit_request(
                                                         application  => G_APPLICATION_NAME
                                                         ,program     => G_CHLD_PROG_EXECUTABLE
                                                         ,sub_request => FALSE
                                                         ,argument1   => ln_min_range_lead_id
                                                         ,argument2   => ln_max_range_lead_id
                                                        ); 
                          
             IF ln_request_id = 0 THEN
                             
                RAISE EX_SUBMIT_CHILD;
                          
             ELSE
                               
                 COMMIT;
                 gn_index_req_id                                 := gn_index_req_id + 1;
                 gt_req_id_lead_id(gn_index_req_id).request_id   := ln_request_id;
                 gt_req_id_lead_id(gn_index_req_id).from_lead_id := ln_min_lead_id;
                 gt_req_id_lead_id(gn_index_req_id).to_lead_id   := ln_max_lead_id;
                 ln_batch_count                                  := ln_batch_count + 1;
             END IF;
       END IF;
   ELSE
       
       WRITE_LOG('No more lead_id record exists greater than the profile value : '||ln_succ_lead_id);
       
   END IF;
   
   -- ----------------------------------------------------------------------------
   -- Write to output file batch size, the total number of batches launched,
   -- number of records fetched
   -- ----------------------------------------------------------------------------
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0234_BATCH_SIZE');
   FND_MESSAGE.SET_TOKEN('P_BATCH_SIZE', ln_batch_size);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0235_BATCHES_LAUNCHED');
   FND_MESSAGE.SET_TOKEN('P_BATCH_LAUNCHED', ln_batch_count);
   lc_message    := FND_MESSAGE.GET;
   WRITE_OUT(lc_message);
   
   WRITE_OUT(RPAD('-',80,'-'));
   WRITE_OUT(RPAD('-',80,'-'));
   WRITE_OUT(
             RPAD('Request_Id',15,' ')||RPAD(' ',3,' ')||
             RPAD('Lead_Id_From',15,' ')||RPAD(' ',3,' ')||
             RPAD('Lead_Id_To',15,' ')||RPAD(' ',3,' ')
            );
   WRITE_OUT(
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')||
             RPAD('-',15,'-')||RPAD(' ',3,' ')
            );
            
   IF gt_req_id_lead_id.COUNT <> 0 THEN
          
      FOR i IN gt_req_id_lead_id.FIRST .. gt_req_id_lead_id.LAST
      LOOP
                  
          WRITE_OUT(
                    RPAD(gt_req_id_lead_id(i).request_id,15,' ')||RPAD(' ',3,' ')||
                    RPAD(gt_req_id_lead_id(i).from_lead_id,15,' ')||RPAD(' ',3,' ')||
                    RPAD(gt_req_id_lead_id(i).to_lead_id,15,' ')||RPAD(' ',3,' ')
                   );
                   
      END LOOP;
   
   END IF;
   
   -- To update the profile
   
   IF lc_update_profile_flag = 'Y' THEN
   
      IF gt_req_id_lead_id.COUNT <> 0 THEN
      
         -- --------------------------------------------------
         -- To check whether the child requests have finished
         -- If not then wait
         -- --------------------------------------------------
         FOR i IN gt_req_id_lead_id.FIRST .. gt_req_id_lead_id.LAST
         LOOP

             LOOP

                SELECT FCR.phase_code
                INTO   lc_phase
                FROM   fnd_concurrent_requests FCR
                WHERE  FCR.request_id = gt_req_id_lead_id(i).request_id;

                IF lc_phase = 'C' THEN
                   EXIT;
                ELSE
                    DBMS_LOCK.SLEEP(G_SLEEP);
                END IF;
             END LOOP;
         END LOOP;

         ln_profile_min_lead_id := gt_req_id_lead_id(gt_req_id_lead_id.FIRST).from_lead_id;
         ln_profile_max_lead_id := gt_req_id_lead_id(gt_req_id_lead_id.LAST).to_lead_id;

         -- Select the maximum of the lead id successfully processed in the entity table

         SELECT max(TERR_ENT.entity_id)
         INTO   ln_lead_crtn_scs_id
         FROM   xx_tm_nam_terr_defn          TERR
                , xx_tm_nam_terr_entity_dtls TERR_ENT
                , xx_tm_nam_terr_rsc_dtls    TERR_RSC
         WHERE  TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
         AND    TERR.named_acct_terr_id = TERR_RSC.named_acct_terr_id
         AND    SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
         AND    SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
         AND    SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)
         AND    NVL(TERR.status,'A')     = 'A'
         AND    NVL(TERR_ENT.status,'A') = 'A'
         AND    NVL(TERR_RSC.status,'A') = 'A'
         AND    TERR_ENT.entity_type = 'LEAD'
         AND    TERR_ENT.entity_id BETWEEN ln_profile_min_lead_id AND ln_profile_max_lead_id;

         -- Check if the lead_id derived is less than the last successfully processed lead_id
         -- of this program

         IF ( ln_succ_lead_id < ln_lead_crtn_scs_id ) THEN

            -- Update with the successfully processed party_site_id of this program

            IF FND_PROFILE.SAVE('XX_TM_AUTO_MAX_LEAD_ID',ln_lead_crtn_scs_id,'SITE') THEN

               COMMIT;

            ELSE

                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0163_LEAD_PROFILE_ERR');
                lc_error_message := FND_MESSAGE.GET;
                WRITE_LOG(lc_error_message);
                XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                   p_return_code              => FND_API.G_RET_STS_ERROR
                                                   , p_application_name       => G_APPLICATION_NAME
                                                   , p_program_type           => G_PROGRAM_TYPE
                                                   , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                                   , p_program_id             => gn_program_id
                                                   , p_module_name            => G_MODULE_NAME
                                                   , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                                   , p_error_message_code     => 'XX_TM_0163_LEAD_PROFILE_ERR'
                                                   , p_error_message          => lc_error_message
                                                   , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                   , p_error_status           => G_ERROR_STATUS_FLAG
                                                  );
                x_retcode := 1;
                                 
            END IF;  -- FND_PROFILE.SAVE('XX_TM_AUTO_MAX_LEAD_ID',ln_lead_crtn_scs_id,'SITE')
            
         END IF; -- ln_succ_lead_id < ln_lead_crtn_scs_id 
         
      END IF;    
   
   END IF; -- lc_update_profile_flag = 'Y'
   
EXCEPTION
   WHEN EX_SUBMIT_CHILD THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0241_SUBMIT_LD_CHLD_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_retcode   := 2;
       x_errbuf    := lc_error_message;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_error_message_code     => 'XX_TM_0241_SUBMIT_LD_CHLD_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN EX_PARAM_ERROR THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0164_LEAD_PARAM_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_retcode   := 2;
       x_errbuf    := lc_error_message;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_error_message_code     => 'XX_TM_0164_LEAD_PARAM_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a lead';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.MASTER_MAIN'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END master_main;

-- +===================================================================+
-- | Name  : Insert_Row                                                |
-- |                                                                   |
-- | Description:       This is the public procedure will be used to   |
-- |                    insert record in the ENTITY custom assignment  |
-- |                    table XX_TM_NAM_TERR_ENTITY_DTLS               |
-- |                                                                   |
-- +===================================================================+

PROCEDURE insert_row
            (
             p_api_version            IN NUMBER
             , p_start_date_active    IN DATE     DEFAULT SYSDATE
             , p_named_acct_terr_id   IN NUMBER   
             , p_entity_type          IN VARCHAR2 
             , p_entity_id            IN NUMBER   DEFAULT NULL
             , x_return_status        OUT NOCOPY  VARCHAR2
             , x_msg_count            OUT NOCOPY  NUMBER
             , x_message_data         OUT NOCOPY  VARCHAR2
            )
IS

-----------------------------
-- Declaring local variables
-----------------------------
EX_INSERT_ROW            EXCEPTION;
lc_error_message         VARCHAR2(1000);
lc_set_message           VARCHAR2(2000);

BEGIN

   IF (p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL AND p_named_acct_terr_id IS NOT NULL) THEN

      -- Insert a row into the XX_TM_NAM_TERR_ENTITY_DTLS
               
      INSERT INTO xx_tm_nam_terr_entity_dtls(
                                             named_acct_terr_entity_id
                                             , named_acct_terr_id
                                             , entity_type
                                             , entity_id
                                             , status
                                             , start_date_active
                                             , created_by
                                             , creation_date
                                             , last_updated_by
                                             , last_update_date
                                             , last_update_login
                                            )
                                      VALUES(
                                             xx_tm_nam_terr_entity_dtls_s.NEXTVAL
                                             , p_named_acct_terr_id
                                             , p_entity_type
                                             , p_entity_id
                                             , 'A'
                                             , p_start_date_active
                                             , FND_GLOBAL.USER_ID
                                             , SYSDATE
                                             , FND_GLOBAL.USER_ID
                                             , SYSDATE
                                             , FND_GLOBAL.USER_ID
                                            );
                                                    
      WRITE_LOG('Entity with entity_type = '||p_entity_type||' and entity_id = '||p_entity_id||'
                        is created in the territory : '||p_named_acct_terr_id);
   END IF; -- p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL
   
   x_return_status := FND_API.G_RET_STS_SUCCESS;

EXCEPTION
   WHEN OTHERS THEN
       x_return_status  :=  FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.set_name('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message  :=  'In Procedure:INSERT_ROW: Unexpected Error while inserting record into XX_TM_NAM_TERR_ENTITY_DTLS : ';
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
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.INSERT_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.INSERT_ROW'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END insert_row;

-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: TM Lead|
-- |                    Named Account Mass Assignment Child            |
-- |                    Program' with Lead ID From and Lead ID To      |
-- |                    as the Input parameters to  create a           |
-- |                    lead record in the custom assignments          |
-- |                    table                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE child_main
                (
                 x_errbuf               OUT NOCOPY VARCHAR2
                 , x_retcode            OUT NOCOPY NUMBER
                 , p_from_lead_id       IN  NUMBER
                 , p_to_lead_id         IN  NUMBER
                )
IS

---------------------------
--Declaring local variables
---------------------------
EX_CREATE_LEAD         EXCEPTION;
ln_min_index           PLS_INTEGER;
ln_max_index           PLS_INTEGER;
ln_min_lead_id         PLS_INTEGER;
ln_max_lead_id         PLS_INTEGER;
ln_address_id          PLS_INTEGER;
ln_lead_id             PLS_INTEGER;
ln_named_acct_terr_id  PLS_INTEGER;
ln_msg_count           PLS_INTEGER;
ln_api_version         PLS_INTEGER := 1.0;
ln_total_count         PLS_INTEGER := 0;
ln_exists_count        PLS_INTEGER := 0;
ln_success_count       PLS_INTEGER := 0;
ln_error_count         PLS_INTEGER := 0;
lc_error_message       VARCHAR2(4000);
lc_lead_assign_exists  VARCHAR2(03);
lc_lead_crtn_success   VARCHAR2(03);
lc_return_status       VARCHAR2(03);
lc_msg_data            VARCHAR2(2000);
lc_total_count         VARCHAR2(1000);
lc_total_success       VARCHAR2(1000);
lc_total_failed        VARCHAR2(1000);
lc_total_exists        VARCHAR2(1000);
lc_set_message         VARCHAR2(2000);

-- ------------------------------------------------------------------------------------------------
-- Declare cursor to fetch the records from as_sales_leads based on p_from_lead_id and p_to_lead_id
-- ------------------------------------------------------------------------------------------------
CURSOR lcu_lead_id
IS
SELECT ASL.sales_lead_id lead_id
       , ASL.address_id  address_id
FROM   as_sales_leads ASL
WHERE  ASL.sales_lead_id BETWEEN p_from_lead_id AND p_to_lead_id
ORDER BY ASL.sales_lead_id;

-- --------------------------------------------------------------------------------------
-- Declare cursor to verify whether the lead_id already exists in the entity table
-- --------------------------------------------------------------------------------------
CURSOR lcu_lead_assign_exists(
                              p_from_lead_id NUMBER
                              , p_to_lead_id NUMBER
                             )
IS
SELECT TERR.named_acct_terr_id named_acct_terr_id
       , TERR_ENT.entity_id    entity_id
FROM   xx_tm_nam_terr_defn          TERR
       , xx_tm_nam_terr_entity_dtls TERR_ENT
       , xx_tm_nam_terr_rsc_dtls    TERR_RSC
WHERE  TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
AND    TERR.named_acct_terr_id = TERR_RSC.named_acct_terr_id
AND    SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
AND    SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
AND    SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)
AND    NVL(TERR.status,'A')     = 'A'
AND    NVL(TERR_ENT.status,'A') = 'A'
AND    NVL(TERR_RSC.status,'A') = 'A'
AND    TERR_ENT.entity_type = 'LEAD'
AND    TERR_ENT.entity_id BETWEEN p_from_lead_id AND p_to_lead_id
ORDER BY TERR_ENT.entity_id;

-- --------------------------------------------------------------------------------------
-- Declare cursor to fetch the named_acct_terr_id's in which the address_id is assigned
-- -------------------------------------------------------------------------------------- 
CURSOR lcu_address_terr_id(
                           p_address_id NUMBER
                          )
IS
SELECT TERR.named_acct_terr_id named_acct_terr_id
FROM   xx_tm_nam_terr_defn          TERR
       , xx_tm_nam_terr_entity_dtls TERR_ENT
       , xx_tm_nam_terr_rsc_dtls    TERR_RSC
WHERE  TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
AND    TERR.named_acct_terr_id = TERR_RSC.named_acct_terr_id
AND    SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
AND    SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
AND    SYSDATE between TERR_RSC.start_date_active AND NVL(TERR_RSC.end_date_active,SYSDATE)
AND    NVL(TERR.status,'A')     = 'A'
AND    NVL(TERR_ENT.status,'A') = 'A'
AND    NVL(TERR_RSC.status,'A') = 'A'
AND    TERR_ENT.entity_type = 'PARTY_SITE'
AND    TERR_ENT.entity_id = p_address_id;

---------------------------------------
--Declaring Local Table Type Variables
---------------------------------------
TYPE lead_id_address_id_tbl_type IS TABLE OF lcu_lead_id%ROWTYPE INDEX BY BINARY_INTEGER;
lt_lead_id_address_id lead_id_address_id_tbl_type;

TYPE terr_id_lead_id_tbl_type IS TABLE OF lcu_lead_assign_exists%ROWTYPE INDEX BY BINARY_INTEGER;
lt_terr_id_lead_id terr_id_lead_id_tbl_type;

TYPE named_acct_terr_id_tbl_type IS TABLE OF lcu_address_terr_id%ROWTYPE INDEX BY BINARY_INTEGER;
lt_named_acct_terr_id named_acct_terr_id_tbl_type;

BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   WRITE_LOG(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',5,' ')||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(RPAD(' ',10,' ')||LPAD('OD: TM Lead Named Account Mass Assignment Child Program',56));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG(RPAD(' ',1,' ')||'Input Parameters ');
   WRITE_LOG(RPAD(' ',1,' ')||'Lead ID From : '||p_from_lead_id);
   WRITE_LOG(RPAD(' ',1,' ')||'Lead ID To   : '||p_to_lead_id);
   WRITE_LOG(RPAD(' ',80,'-'));

   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',60)||RPAD(' ',5,' ')||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT(RPAD(' ',10,' ')||LPAD('OD: TM Lead Named Account Mass Assignment Child Program',56));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',80,'-'));
   
   -- Retrieve the records from AS_SALES_LEADS based on the two input parameters to the table type
   OPEN lcu_lead_id;
   LOOP
       
       -- Initializing the variables
       ln_min_index         := NULL;
       ln_max_index         := NULL;
       ln_min_lead_id       := NULL;
       ln_max_lead_id       := NULL;
       lt_lead_id_address_id.DELETE;
       lt_terr_id_lead_id.DELETE;
       
       FETCH lcu_lead_id BULK COLLECT INTO lt_lead_id_address_id LIMIT G_LIMIT;
       
       IF lt_lead_id_address_id.COUNT <> 0 THEN
          
          -- Get the minimum and maximum index of the table type
          
          ln_min_index := lt_lead_id_address_id.FIRST;
          ln_max_index := lt_lead_id_address_id.LAST;
          
          -- Get the minimum and maximum lead_id
          
          ln_min_lead_id := lt_lead_id_address_id(ln_min_index).lead_id;
          ln_max_lead_id := lt_lead_id_address_id(ln_max_index).lead_id;
          
          -- Fetch the already existing data between the range of lead_id in a tbl type
          
          OPEN lcu_lead_assign_exists(
                                      p_from_lead_id => ln_min_lead_id
                                      , p_to_lead_id => ln_max_lead_id
                                     );
          FETCH lcu_lead_assign_exists BULK COLLECT INTO lt_terr_id_lead_id;
          CLOSE lcu_lead_assign_exists;
          
          FOR i IN lt_lead_id_address_id.FIRST .. lt_lead_id_address_id.LAST
          LOOP
              
              -- Initializing the variables
              ln_address_id         := NULL;
              ln_lead_id            := NULL;
              lc_error_message      := NULL;
              lt_named_acct_terr_id.DELETE;
              
              -- To count the number of records read
              ln_total_count   := ln_total_count + 1;
              
              -- Fetch the address_id and lead_id
                                                   
              ln_address_id := lt_lead_id_address_id(i).address_id;
              ln_lead_id    := lt_lead_id_address_id(i).lead_id;
                                       
              WRITE_LOG(RPAD(' ',80,'-'));
              WRITE_LOG('Processing for the lead id : '||ln_lead_id);
              
              lc_lead_assign_exists := 'N';
              
              IF lt_terr_id_lead_id.COUNT <> 0 THEN
                 
                 FOR j IN lt_terr_id_lead_id.FIRST .. lt_terr_id_lead_id.LAST
                 LOOP
                     
                     IF lt_terr_id_lead_id(j).entity_id = ln_lead_id THEN
                        
                        WRITE_LOG('Lead ID : '||ln_lead_id||' already exists in named_acct_terr_id : '||lt_terr_id_lead_id(j).named_acct_terr_id);
                        lc_lead_assign_exists := 'Y';
                     
                     END IF; 
                 
                 END LOOP;  --lt_terr_id_lead_id.FIRST .. lt_terr_id_lead_id.LAST
                 
              END IF; -- lt_terr_id_lead_id.COUNT <> 0
              
              IF lc_lead_assign_exists = 'Y' THEN
                 
                 ln_exists_count := ln_exists_count + 1;
              
              ELSE
                  
                  BEGIN
                  
                       -- Fetch the territories in which the address_id is assigned
                       
                       OPEN  lcu_address_terr_id(p_address_id => ln_address_id);
                       FETCH lcu_address_terr_id BULK COLLECT INTO lt_named_acct_terr_id;
                       CLOSE lcu_address_terr_id;
                       
                       lc_lead_crtn_success := 'Y';
                       
                       IF lt_named_acct_terr_id.COUNT = 0 THEN
                                    
                          FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0135_NO_TERRITORY');
                          FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_address_id);
                          lc_error_message := FND_MESSAGE.GET;
                          WRITE_LOG(lc_error_message);
                          XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                             p_return_code              => FND_API.G_RET_STS_ERROR
                                                             , p_application_name       => G_APPLICATION_NAME
                                                             , p_program_type           => G_PROGRAM_TYPE
                                                             , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                             , p_program_id             => gn_program_id
                                                             , p_module_name            => G_MODULE_NAME
                                                             , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                             , p_error_message_code     => 'XX_TM_0135_NO_TERRITORY'
                                                             , p_error_message          => lc_error_message
                                                             , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                             , p_error_status           => G_ERROR_STATUS_FLAG
                                                            );
                          RAISE EX_CREATE_LEAD;
                                 
                       END IF; -- lt_named_acct_terr_id.COUNT = 0
                       
                       FOR k IN lt_named_acct_terr_id.FIRST .. lt_named_acct_terr_id.LAST
                       LOOP
                           
                           -- Initializing the variables
                           ln_named_acct_terr_id := NULL;
                           lc_return_status      := NULL;
                           lc_msg_data           := NULL;
                           ln_msg_count          := NULL;
                              
                           ln_named_acct_terr_id := lt_named_acct_terr_id(k).named_acct_terr_id;
                           
                           /* The entity_type 'LEAD' does not exist for this named_acct_terr_id. So creating an entity
                           with this named_acct_terr_id */
                           
                           Insert_row(
                                      p_api_version          => ln_api_version
                                      , p_named_acct_terr_id => ln_named_acct_terr_id
                                      , p_entity_type        => 'LEAD'
                                      , p_entity_id          => ln_lead_id
                                      , x_return_status      => lc_return_status
                                      , x_message_data       => lc_msg_data
                                      , x_msg_count          => ln_msg_count
                                     );
                                
                           IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN
                                     
                              FOR l IN 1 .. ln_msg_count
                              LOOP
                                                         
                                  lc_msg_data := FND_MSG_PUB.GET(
                                                                 p_encoded     => FND_API.G_FALSE
                                                                 , p_msg_index => l
                                                                );
                                                                        
                                  WRITE_LOG(lc_msg_data);
                                  XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                     p_return_code              => FND_API.G_RET_STS_ERROR
                                                                     , p_application_name       => G_APPLICATION_NAME
                                                                     , p_program_type           => G_PROGRAM_TYPE
                                                                     , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                                     , p_program_id             => gn_program_id
                                                                     , p_module_name            => G_MODULE_NAME
                                                                     , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                                     , p_error_message_count    => l
                                                                     , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                     , p_error_message          => lc_msg_data
                                                                     , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                     , p_error_status           => G_ERROR_STATUS_FLAG
                                                                    );
                              END LOOP;
                              RAISE EX_CREATE_LEAD;
                                                                                                        
                           END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                                                                                                                       
                       END LOOP; -- lt_details_rec.FIRST .. lt_details_rec.LAST
                       
                  EXCEPTION
                     WHEN EX_CREATE_LEAD THEN
                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0161_LEAD_ERROR');
                         FND_MESSAGE.SET_TOKEN('P_LEAD_ID', ln_lead_id);
                         lc_error_message := FND_MESSAGE.GET;
                         WRITE_LOG(lc_error_message);
                         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                                            , p_application_name       => G_APPLICATION_NAME
                                                            , p_program_type           => G_PROGRAM_TYPE
                                                            , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                            , p_program_id             => gn_program_id
                                                            , p_module_name            => G_MODULE_NAME
                                                            , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                            , p_error_message_code     => 'XX_TM_0161_LEAD_ERROR'
                                                            , p_error_message          => lc_error_message
                                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                                           );
                         lc_lead_crtn_success := 'N';
                     WHEN OTHERS THEN
                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                         lc_set_message     :=  'Unexpected Error while creating an lead with id : '||ln_lead_id;
                         FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                         FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                         lc_error_message := FND_MESSAGE.GET;
                         WRITE_LOG(lc_error_message);
                         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                                            , p_application_name       => G_APPLICATION_NAME
                                                            , p_program_type           => G_PROGRAM_TYPE
                                                            , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                            , p_program_id             => gn_program_id
                                                            , p_module_name            => G_MODULE_NAME
                                                            , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                                            , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                            , p_error_message          => lc_error_message
                                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                                           );
                         lc_lead_crtn_success := 'N';
                  
                  END;
                  
                  IF lc_lead_crtn_success = 'Y' THEN
                      
                     ln_success_count := ln_success_count + 1;
                  
                  ELSIF lc_lead_crtn_success = 'N' THEN
                         
                        ln_error_count := ln_error_count + 1;
                             
                  END IF;
                  
                  IF MOD(i,G_COMMIT) = 0 THEN
                     COMMIT;
                  END IF;
              
              END IF; -- lc_lead_assign_exists = 'Y'
          
          END LOOP; -- lt_lead_id_address_id.FIRST .. lt_lead_id_address_id.LAST
       
       END IF; -- lt_lead_id_address_id.COUNT <> 0
       
       EXIT WHEN lcu_lead_id%NOTFOUND;
       
   END LOOP; -- lcu_lead_id
      
   CLOSE lcu_lead_id;
         
   COMMIT;
      
   lc_error_message := NULL;
         
   IF ln_total_count = 0 THEN
         
      FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0162_NO_LEAD_RECS');
      FND_MESSAGE.SET_TOKEN('P_FROM_LEAD_ID', p_from_lead_id );
      FND_MESSAGE.SET_TOKEN('P_TO_LEAD_ID', p_to_lead_id );
      lc_error_message := FND_MESSAGE.GET;
      WRITE_LOG(lc_error_message);
      XX_COM_ERROR_LOG_PUB.log_error_crm(
                                         p_return_code               => FND_API.G_RET_STS_ERROR
                                         , p_application_name        => G_APPLICATION_NAME
                                         , p_program_type            => G_PROGRAM_TYPE
                                         , p_program_name            => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                         , p_program_id              => gn_program_id
                                         , p_module_name             => G_MODULE_NAME
                                         , p_error_location          => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                         , p_error_message_code      => 'XX_TM_0162_NO_LEAD_RECS'
                                         , p_error_message           => lc_error_message
                                         , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                         , p_error_status            => G_ERROR_STATUS_FLAG
                                        );
      x_retcode := 1;
   
   END IF; -- ln_total_count = 0
   
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
   
   IF ln_error_count <> 0 THEN
   
      -- End the program with warning
      x_retcode := 1;
   
   END IF;

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a lead';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SALES_REP_BL_LEAD_CRTN.CHILD_MAIN'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END child_main;

END XX_JTF_SALES_REP_BL_LEAD_CRTN;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================