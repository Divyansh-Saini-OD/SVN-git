SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SL_REP_UNASSGN_INT_CUST package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SL_REP_UNASSGN_INT_CUST
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SL_REP_UNASSGN_INT_CUST                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Unassign Internal Customers' to unassign      |
-- |                     the party sites of the internal customer in the custom        |
-- |                     assignments entity table                                      |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    End_Date_Entity         This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  11-Jan-08   Abhradip Ghosh               Initial draft version           |
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
                                          , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.WRITE_LOG'
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
                                          , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
      
END write_out;

-- +===================================================================+
-- | Name  : end_date_entity                                           |
-- |                                                                   |
-- | Description: This is a public procedure which will get called     |
-- |              from the concurrent program 'OD: TM Unassign Internal|
-- |              Customers' to unassign the party sites of the        |
-- |              internal customer in the custom assignments entity   |
-- |              table                                                |
-- +===================================================================+

PROCEDURE end_date_entity
            (
               x_errbuf     OUT NOCOPY VARCHAR2
             , x_retcode    OUT NOCOPY NUMBER
            )
IS

---------------------------
--Declaring local variables
---------------------------
EX_PARTY_SITE_ERR       EXCEPTION;
EX_PARTY_ERR            EXCEPTION;
ln_total_count          PLS_INTEGER := 0;
ln_success_count        PLS_INTEGER := 0;
ln_error_count          PLS_INTEGER := 0;
ln_exists_count         PLS_INTEGER := 0;
ln_total_record_upd     PLS_INTEGER := 0;
ln_no_pty_site_count    PLS_INTEGER := 0;
ln_pty_site_count       PLS_INTEGER := 0;
ln_party_id             PLS_INTEGER;
ln_party_site_id        PLS_INTEGER;
ln_named_acct_terr_id   PLS_INTEGER;
ln_msg_count            PLS_INTEGER;
ln_api_version          NUMBER      := 1.0;
lc_error_message        VARCHAR2(2000);
lc_total_count          VARCHAR2(1000);
lc_total_success        VARCHAR2(1000);
lc_total_failed         VARCHAR2(1000);
lc_set_message          VARCHAR2(2000);
lc_total_exists         VARCHAR2(1000);
lc_return_status        VARCHAR2(03);
lc_msg_data             VARCHAR2(2000);
lc_pty_upd_succ         VARCHAR2(03); 

-- --------------------------------------------------------------------------------
-- Declare cursor to fetch all the internal customer records from HZ_CUST_ACCOUNTS
-- --------------------------------------------------------------------------------
CURSOR lcu_int_parties
IS
SELECT distinct HZC.party_id
FROM   hz_cust_accounts HZC
WHERE  HZC.customer_type = 'I';

-- --------------------------------------------------------------------------
-- Declare cursor to fetch the party sites present in the custom assignments 
-- entity table XX_TM_NAM_TERR_ENTITY_DTLS for a party_id
-- --------------------------------------------------------------------------
CURSOR lcu_entity_id(p_party_id NUMBER)
IS
SELECT XTM.entity_id
       , XTM.named_acct_terr_id
FROM   xx_tm_nam_terr_entity_dtls XTM
       , hz_party_sites HPS
WHERE  XTM.entity_id   = HPS.party_site_id  
AND    HPS.party_id    = p_party_id
AND    XTM.entity_type = 'PARTY_SITE'
AND    NVL(XTM.status,'A') = 'A'
AND    XTM.end_date_active IS NULL;

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_id_tbl_type IS TABLE OF hz_cust_accounts.party_id%TYPE INDEX BY BINARY_INTEGER;
lt_party_id party_id_tbl_type;


BEGIN

   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
   
   WRITE_LOG(RPAD('Office Depot',65)||LPAD('Date: '||TRUNC(sysdate),25));
   WRITE_LOG(RPAD(' ',90,'-'));
   WRITE_LOG(LPAD('OD: TM Unassign Internal Customers',62));
   WRITE_LOG(RPAD(' ',90,'-'));
   WRITE_LOG('');
   
   WRITE_OUT(RPAD('Office Depot',65)||LPAD('Date: '||TRUNC(sysdate),25));
   WRITE_OUT(RPAD(' ',90,'-'));
   WRITE_OUT(LPAD('OD: TM Unassign Internal Customers',62));
   WRITE_OUT(RPAD(' ',90,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',90,'-'));
   
   -- First retrieve all the internal customer records from HZ_CUST_ACCOUNTS 
   
   OPEN lcu_int_parties;
   LOOP
       
       FETCH lcu_int_parties BULK COLLECT INTO lt_party_id LIMIT G_LIMIT;
       
       IF (lt_party_id.COUNT <> 0) THEN
         
         FOR i IN lt_party_id.FIRST .. lt_party_id.LAST
         LOOP
             
             BEGIN
                  
                  -- Initializing the variables
                  ln_party_id      := NULL;
                  lc_error_message := NULL;
                  lc_pty_upd_succ  := 'Y';
                  
                  -- To keep the total count of the records retrieved
                  ln_total_count := ln_total_count + 1;
                  
                  -- Retrieve each party_id of the internal customers
                  ln_party_id           := lt_party_id(i);
                  ln_pty_site_count     := 0;
                           
                  WRITE_LOG(RPAD(' ',80,'-'));
                  WRITE_LOG('Processing for the party id: '||ln_party_id);
                  
                  -- Retrieve all the party sites present for that party_id 
                  -- from the custom entity table XX_TM_NAM_TERR_ENTITY_DTLS and update it
                  
                  FOR entity_id_rec IN lcu_entity_id(ln_party_id)
                  LOOP
                      
                      -- Initializing the variables
                      ln_party_site_id      := NULL;
                      ln_named_acct_terr_id := NULL;
                      lc_return_status      := NULL;
                      ln_msg_count          := NULL;
                      lc_msg_data           := NULL;
                      lc_error_message      := NULL;
                      
                      ln_party_site_id      := entity_id_rec.entity_id;
                      ln_named_acct_terr_id := entity_id_rec.named_acct_terr_id;
                      ln_pty_site_count     := ln_pty_site_count + 1;
                      
                      WRITE_LOG(RPAD(' ',70,'-'));
                      WRITE_LOG('Processing for the party site id : '||ln_party_site_id||' in the 
                                    named_acct_terr_id : '||ln_named_acct_terr_id);
                                    
                      BEGIN
                           
                           XX_JTF_RS_NAMED_ACC_TERR.update_row(
                                                               p_api_version            => ln_api_version
                                                               , p_end_date_active      => SYSDATE
                                                               , p_named_acct_terr_id   => ln_named_acct_terr_id
                                                               , p_entity_type          => 'PARTY_SITE'
                                                               , p_entity_id            => ln_party_site_id
                                                               , x_return_status        => lc_return_status
                                                               , x_msg_count            => ln_msg_count
                                                               , x_message_data         => lc_msg_data
                                                              );
                           
                           IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                                                                  
                             FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0179_PROC_RETURNS_ERR');
                             FND_MESSAGE.SET_TOKEN('P_PROCEDURE_NAME', 'XX_JTF_RS_NAMED_ACC_TERR.UPDATE_ROW');
                             lc_error_message := FND_MESSAGE.GET;  
                             WRITE_LOG(lc_error_message);
                             
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
                                                                    , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                    , p_program_id             => gn_program_id
                                                                    , p_module_name            => G_MODULE_NAME
                                                                    , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                    , p_error_message_count    => m
                                                                    , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                    , p_error_message          => lc_msg_data
                                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                                   );
                                                                                          
                             END LOOP; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                             RAISE EX_PARTY_SITE_ERR;
                           
                           ELSE
                               
                               ln_total_record_upd := ln_total_record_upd + 1;
                           
                           END IF; --lc_return_status <> FND_API.G_RET_STS_SUCCESS
                      
                      EXCEPTION
                         WHEN EX_PARTY_SITE_ERR THEN
                             FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0209_ED_DT_PT_SITE_FAILD');
                             FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                             FND_MESSAGE.SET_TOKEN('P_PARTY_ID', ln_party_id);
                             lc_error_message := FND_MESSAGE.GET;
                             WRITE_LOG(lc_error_message);
                             XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                , p_application_name       => G_APPLICATION_NAME
                                                                , p_program_type           => G_PROGRAM_TYPE
                                                                , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                , p_program_id             => gn_program_id 
                                                                , p_module_name            => G_MODULE_NAME
                                                                , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                , p_error_message_code     => 'XX_TM_0209_ED_DT_PT_SITE_FAILD'
                                                                , p_error_message          => lc_error_message
                                                                , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                , p_error_status           => G_ERROR_STATUS_FLAG
                                                               );
                             RAISE EX_PARTY_ERR;
                          WHEN OTHERS THEN
                              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                              lc_set_message     :=  'Unexpected Error while updating the party site : '||ln_party_site_id||' of the party_id : '||ln_party_id;
                              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                              lc_error_message := FND_MESSAGE.GET;
                              WRITE_LOG(lc_error_message);
                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                 p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                 , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                 , p_program_id             => gn_program_id 
                                                                 , p_module_name            => G_MODULE_NAME
                                                                 , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                 , p_error_message          => lc_error_message
                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                ); 
                              RAISE EX_PARTY_ERR;
                      END;
                      
                  END LOOP; -- entity_id_rec IN lcu_entity_id(ln_party_id)
                  
                  IF (ln_pty_site_count = 0) THEN
                    
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0213_NO_PTY_SITE_REC');
                    FND_MESSAGE.SET_TOKEN('P_PARTY_ID', ln_party_id);
                    lc_error_message := FND_MESSAGE.GET;
                    lc_pty_upd_succ := 'NP';
                    WRITE_LOG(lc_error_message);
                  
                  END IF; -- ln_pty_site_count = 0
                  
                EXCEPTION
                   WHEN EX_PARTY_ERR THEN
                       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0208_END_DATE_FAILED');
                       FND_MESSAGE.SET_TOKEN('P_PARTY_ID', ln_party_id);
                       lc_error_message := FND_MESSAGE.GET;
                       lc_pty_upd_succ := 'N';
                       WRITE_LOG(lc_error_message);
                   WHEN OTHERS THEN
                       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                       lc_set_message     :=  'Unexpected Error while updating the party site of the party_id : '||ln_party_id;
                       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                       lc_error_message := FND_MESSAGE.GET;
                       lc_pty_upd_succ := 'N';
                       WRITE_LOG(lc_error_message);
                       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                                          , p_application_name       => G_APPLICATION_NAME
                                                          , p_program_type           => G_PROGRAM_TYPE
                                                          , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                          , p_program_id             => gn_program_id 
                                                          , p_module_name            => G_MODULE_NAME
                                                          , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                          , p_error_message          => lc_error_message
                                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                                         );
              END;
                     
              IF (lc_pty_upd_succ = 'Y') THEN
                                                                                    
                ln_success_count := ln_success_count + 1;
                                                                                    
              ELSIF (lc_pty_upd_succ = 'N') THEN
                                                                                    
                   ln_error_count := ln_error_count + 1;
                   
              ELSIF (lc_pty_upd_succ = 'NP') THEN    
                   
                   ln_no_pty_site_count := ln_no_pty_site_count + 1;
                   
              END IF; -- lc_pty_upd_succ = 'Y'    
              
              IF MOD(ln_total_record_upd,G_COMMIT) = 0 THEN
                COMMIT;
              END IF;
              
         END LOOP; -- lt_party_id.FIRST .. lt_party_id.LAST
       
       END IF; -- lt_party_id.COUNT <> 0
       
       EXIT WHEN lcu_int_parties%NOTFOUND;
   
   END LOOP;  -- lcu_int_parties
   
   CLOSE lcu_int_parties;
   
   COMMIT;
   
   IF (ln_total_count = 0) THEN
                  
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0206_NO_RECORDS');
     lc_error_message := FND_MESSAGE.GET;
     WRITE_LOG(lc_error_message);
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code               => FND_API.G_RET_STS_ERROR 
                                        , p_application_name        => G_APPLICATION_NAME
                                        , p_program_type            => G_PROGRAM_TYPE
                                        , p_program_name            => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                        , p_program_id              => gn_program_id
                                        , p_module_name             => G_MODULE_NAME
                                        , p_error_location          => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                        , p_error_message_code      => 'XX_TM_0206_NO_RECORDS'
                                        , p_error_message           => lc_error_message
                                        , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                        , p_error_status            => G_ERROR_STATUS_FLAG
                                       );
     x_retcode := 1;                                  
   END IF; -- ln_total_count = 0
   
   -- ----------------------------------------------------------------------------
   -- Write to output file, the total number of records updated, number of
   -- success and failure records.
   -- ----------------------------------------------------------------------------
            
   WRITE_OUT(' ');
            
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0212_PTY_RECORD_READ');
   FND_MESSAGE.SET_TOKEN('P_RECORD_FETCHED', ln_total_count);
   lc_total_count    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_count);
            
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0207_PTY_TOTAL_REC_UPDT');
   FND_MESSAGE.SET_TOKEN('P_RECORD_UPDATED', ln_success_count);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);
            
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0210_PTY_TOTAL_REC_FAILD');
   FND_MESSAGE.SET_TOKEN('P_RECORD_UPDATED', ln_error_count);
   lc_total_failed    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_failed);
         
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0211_PT_ST_RECORD_UPD');
   FND_MESSAGE.SET_TOKEN('P_RECORD_AL_UPDATED', ln_total_record_upd);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0214_TTL_NO_PTY_SITE_REC');
   FND_MESSAGE.SET_TOKEN('P_NO_PARTY_SITE', ln_no_pty_site_count);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);
      
   IF (ln_error_count <> 0) THEN
        
        x_retcode  := 1;
      
   END IF;
   
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while end dating the internal customer';
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
                                          , p_program_name           => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SL_REP_UNASSGN_INT_CUST.END_DATE_ENTITY'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message 
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );    
END end_date_entity;
END XX_JTF_SL_REP_UNASSGN_INT_CUST; 
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================   
