SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SLS_REP_NW_DIV_PTY_SITE package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_SLS_REP_NW_DIV_PTY_SITE 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SLS_REP_NW_DIV_PTY_SITE                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: New Division Named Account Assignment' to create |
-- |                     a new division for the party sites                            |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Update_Oppty            This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  16-Oct-07   Abhradip Ghosh               Initial draft version           |
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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.WRITE_LOG'
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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.WRITE_OUT'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.WRITE_OUT'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
      
END write_out;

-- +===================================================================+
-- | Name  : master_main                                               |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD:        |
-- |                    New Division Named Account Assignment Master   |
-- |                    Program' to create a new division for          |
-- |                    the party sites                                |
-- |                                                                   |
-- +===================================================================+  
PROCEDURE master_main
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_division           IN  VARCHAR2
            )
IS
---------------------------
--Declaring local variables
---------------------------
EX_SUBMIT_CHILD                 EXCEPTION;
ln_batch_size                   PLS_INTEGER;
ln_min_party_site_id            PLS_INTEGER;
ln_max_party_site_id            PLS_INTEGER;
ln_batch_size_count             PLS_INTEGER := 0;
ln_record_count                 PLS_INTEGER := 0;
ln_batch_count                  PLS_INTEGER := 0;
ln_min_index                    PLS_INTEGER;
ln_max_index                    PLS_INTEGER;
ln_request_id                   PLS_INTEGER;
ln_dpl_resource_id              PLS_INTEGER;
ln_dpl_resource_role_id         PLS_INTEGER;
ln_dpl_group_id                 PLS_INTEGER;
ln_max_named_acct_terr_id       PLS_INTEGER;
ln_min_named_acct_terr_id       PLS_INTEGER;
ln_entity_id                    PLS_INTEGER;
ln_count_named_acct_terr_id     PLS_INTEGER := 0;
lc_error_message                VARCHAR2(4000);
lc_set_message                  VARCHAR2(2000);
lc_message                      VARCHAR2(2000);
lc_phase                        VARCHAR2(03);

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_sites_tbl_type IS TABLE OF xx_tm_nam_terr_entity_dtls.entity_id%TYPE INDEX BY BINARY_INTEGER;
lt_party_sites party_sites_tbl_type;

-- ---------------------------------------------------------------------------------
-- Declare cursor to fetch the records from hz_party_sites when both the parameters
-- are passed
-- ---------------------------------------------------------------------------------
CURSOR lcu_party_sites
IS
SELECT DISTINCT TERR_ENT.entity_id
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
--AND    entity_id between 3478789 and 3484904
--AND    entity_id between 3426070 and 3486070 --4574597
ORDER BY TERR_ENT.entity_id;

-- --------------------------------------------------------------
-- Declare cursor to check whether any duplicate resource exists
-- --------------------------------------------------------------
CURSOR lcu_duplicate_assign_exists
IS
SELECT XTNT.resource_id
       , XTNT.resource_role_id
       , XTNT.group_id
       , COUNT(1)
FROM   xx_tm_nam_terr_rsc_dtls XTNT
WHERE  NVL(XTNT.status,'A') = 'A'
AND    SYSDATE between XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE)
GROUP BY XTNT.resource_id, XTNT.resource_role_id, XTNT.group_id
HAVING COUNT(1) > 1;

-- -------------------------------------------------------------------------------------------
-- Declare cursor to fetch each of the named_acct_terr_id for which duplicate resource exists
-- -------------------------------------------------------------------------------------------
CURSOR lcu_named_acct_terr_id(
                              p_resource_id        NUMBER
                              , p_resource_role_id NUMBER
                              , p_group_id         NUMBER
                             )
IS
SELECT XTNT.named_acct_terr_id
FROM   xx_tm_nam_terr_rsc_dtls XTNT
WHERE  XTNT.resource_id = p_resource_id
AND    XTNT.resource_role_id = p_resource_role_id
AND    XTNT.group_id = p_group_id
AND    NVL(XTNT.status,'A') = 'A'
AND    SYSDATE between XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE)
ORDER BY 1;

-- -----------------------------------------------------------------------------------
-- Declare cursor to fetch the entity_id which exist in the duplicate resource record
-- -----------------------------------------------------------------------------------
CURSOR lcu_entity_id
              (
               p_min_named_acct_terr_id   NUMBER
               , p_max_named_acct_terr_id NUMBER
              )
IS
SELECT XTNT.entity_id
FROM   xx_tm_nam_terr_entity_dtls XTNT
WHERE  XTNT.named_acct_terr_id = p_max_named_acct_terr_id
AND    XTNT.entity_type = 'PARTY_SITE'
AND    NVL(XTNT.status,'A') = 'A'
AND    SYSDATE BETWEEN XTNT.start_date_active AND NVL(XTNT.end_date_active,SYSDATE)
MINUS
SELECT XTNT.entity_id
FROM   xx_tm_nam_terr_entity_dtls XTNT
WHERE  XTNT.named_acct_terr_id = p_min_named_acct_terr_id
AND    XTNT.entity_type = 'PARTY_SITE'
AND    NVL(XTNT.status,'A') = 'A'
AND    SYSDATE BETWEEN XTNT.start_date_active AND NVL(XTNT.end_date_active,SYSDATE);

BEGIN
     
     -- --------------------------------------
     -- DISPLAY PROJECT NAME AND PROGRAM NAME
     -- --------------------------------------
     
     WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
     WRITE_LOG(RPAD(' ',80,'-'));
     WRITE_LOG(LPAD('OD: TM New Division Named Account Assignment Master Program',60));
     WRITE_LOG(RPAD(' ',80,'-'));
     WRITE_LOG('');
     WRITE_LOG('Input Parameters ');
     WRITE_LOG('Division : '||p_division);
     WRITE_LOG(RPAD(' ',80,'-'));
     
     WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
     WRITE_OUT(RPAD(' ',80,'-'));
     WRITE_OUT(LPAD('OD: TM New Division Named Account Assignment Master Program',60));
     WRITE_OUT(RPAD(' ',80,'-'));
     WRITE_OUT('');
     WRITE_OUT(RPAD(' ',80,'-'));
     
     -- Derive the batch Size from the profile
     
     ln_batch_size := NVL(FND_PROFILE.VALUE('XX_TM_PARTY_SITE_BATCH_SIZE'),G_BATCH_SIZE);
     
     OPEN lcu_party_sites;
     LOOP
         
         FETCH lcu_party_sites BULK COLLECT INTO lt_party_sites LIMIT ln_batch_size;
         write_log (' lt_party_sites.count => '|| lt_party_sites.COUNT);
         
         IF lt_party_sites.COUNT <> 0 THEN
            
            -- Get the minimum and maximum index of the table type
            write_log (' lt_party_sites.FIRST => '|| lt_party_sites.FIRST);
            write_log (' lt_party_sites.LAST => '|| lt_party_sites.LAST);
            ln_min_index := lt_party_sites.FIRST;
            ln_max_index := lt_party_sites.LAST;
            
            -- Get the minimum and maximum party_site_id
            write_log (' lt_party_sites(ln_min_index) => '|| lt_party_sites(ln_min_index));
            write_log (' lt_party_sites(ln_max_index) => '|| lt_party_sites(ln_max_index));
            ln_min_party_site_id := lt_party_sites(ln_min_index);
            ln_max_party_site_id := lt_party_sites(ln_max_index);
            
            -- Get the count of the total number of records for the batch to be launched
            ln_batch_size_count := lt_party_sites.COUNT;
            
            -- Get the count of the total number of records
            ln_record_count := ln_record_count + ln_batch_size_count;
            
            -- ---------------------------------------------------------
            -- Call the custom concurrent program for parallel execution
            -- ---------------------------------------------------------
            ln_request_id := FND_REQUEST.submit_request(
                                                        application  => G_CHLD_PROG_APPLICATION
                                                        ,program     => G_CHLD_PROG_EXECUTABLE
                                                        ,sub_request => FALSE
                                                        ,argument1   => p_division
                                                        ,argument2   => ln_min_party_site_id
                                                        ,argument3   => ln_max_party_site_id
                                                       );
            
            IF ln_request_id = 0 THEN
                     
               RAISE EX_SUBMIT_CHILD;
                    
            ELSE
                 
                COMMIT;
                ln_batch_count  := ln_batch_count + 1;
                gn_index_req_id    := gn_index_req_id + 1;
                gt_req_id_pty_site_id(gn_index_req_id).request_id         := ln_request_id;
                gt_req_id_pty_site_id(gn_index_req_id).from_party_site_id := ln_min_party_site_id;
                gt_req_id_pty_site_id(gn_index_req_id).to_party_site_id   := ln_max_party_site_id;
                gt_req_id_pty_site_id(gn_index_req_id).record_count       := ln_batch_size_count;
            
            END IF; -- ln_request_id = 0
                  
         END IF; -- lt_party_sites.COUNT <> 0
         
         EXIT WHEN lcu_party_sites%NOTFOUND;
     
     END LOOP; -- lcu_param_null_party_sites
     
     CLOSE lcu_party_sites;
     
     -- Delete the table type
     lt_party_sites.DELETE;
     
     IF ln_record_count = 0 THEN
          
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0240_NO_RECORDS');
        lc_error_message := FND_MESSAGE.GET;
        WRITE_LOG(lc_error_message);
        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                           p_return_code               => FND_API.G_RET_STS_ERROR
                                           , p_application_name        => G_APPLICATION_NAME
                                           , p_program_type            => G_PROGRAM_TYPE
                                           , p_program_name            => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
                                           , p_program_id              => gn_program_id
                                           , p_module_name             => G_MODULE_NAME
                                           , p_error_location          => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
                                           , p_error_message_code      => 'XX_TM_0129_NO_RECORDS'
                                           , p_error_message           => lc_error_message
                                           , p_error_message_severity  => G_MEDIUM_ERROR_MSG_SEVERTY
                                           , p_error_status            => G_ERROR_STATUS_FLAG
                                          );
     END IF; -- ln_total_count = 0
     
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
     
     FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0236_TOTAL_RECORDS');
     FND_MESSAGE.SET_TOKEN('P_RECORDS_READ', ln_record_count);
     lc_message    := FND_MESSAGE.GET;
     WRITE_OUT(lc_message);
     
     WRITE_OUT(RPAD('-',78,'-'));
     WRITE_OUT(RPAD('-',78,'-'));
     WRITE_OUT(
               RPAD('Request_Id',15,' ')||RPAD(' ',3,' ')||
               RPAD('From_Party_Site_Id',18,' ')||RPAD(' ',3,' ')||
               RPAD('To_Party_Site_Id',18,' ')||RPAD(' ',3,' ')||
               RPAD('Record Count',15,' ')||RPAD(' ',3,' ')
              );
     WRITE_OUT(
               RPAD('-',15,'-')||RPAD(' ',3,' ')||
               RPAD('-',18,'-')||RPAD(' ',3,' ')||
               RPAD('-',18,'-')||RPAD(' ',3,' ')||
               RPAD('-',18,'-')||RPAD(' ',3,' ')
              );
              
     IF gt_req_id_pty_site_id.COUNT <> 0 THEN
        
        FOR i IN gt_req_id_pty_site_id.FIRST .. gt_req_id_pty_site_id.LAST
        LOOP
                           
            WRITE_OUT(
                      RPAD(gt_req_id_pty_site_id(i).request_id,15,' ')||RPAD(' ',3,' ')||
                      RPAD(gt_req_id_pty_site_id(i).from_party_site_id,18,' ')||RPAD(' ',3,' ')||
                      RPAD(gt_req_id_pty_site_id(i).to_party_site_id,18,' ')||RPAD(' ',3,' ')||
                      RPAD(gt_req_id_pty_site_id(i).record_count,15,' ')||RPAD(' ',3,' ')
                     );
                  
        END LOOP;
                                 
     END IF;
     
     -- --------------------------------------------------
     -- To check whether the child requests have finished
     -- If not then wait
     -- --------------------------------------------------
     FOR i IN gt_req_id_pty_site_id.FIRST .. gt_req_id_pty_site_id.LAST
     LOOP
            
         LOOP
                           
             SELECT FCR.phase_code
             INTO   lc_phase
             FROM   fnd_concurrent_requests FCR
             WHERE  FCR.request_id = gt_req_id_pty_site_id(i).request_id;
                                 
             IF lc_phase = 'C' THEN
                EXIT;
             ELSE
                    DBMS_LOCK.SLEEP(G_SLEEP);
             END IF;
             
         END LOOP;
         
     END LOOP;
     
     -- -----------------------------------------------------------------
     -- Check whether any duplicate record exists and if exists clean it
     -- -----------------------------------------------------------------
     FOR duplicate_assign_exists_rec IN lcu_duplicate_assign_exists
     LOOP
          
         -- Initializing the variables
         ln_dpl_resource_id          := NULL;
         ln_dpl_resource_role_id     := NULL;
         ln_dpl_group_id              := NULL;
         ln_count_named_acct_terr_id := 0;
            
         ln_dpl_resource_id      := duplicate_assign_exists_rec.resource_id;
         ln_dpl_resource_role_id := duplicate_assign_exists_rec.resource_role_id;
         ln_dpl_group_id         := duplicate_assign_exists_rec.group_id;
              
         -- Fetch each of the named_acct_terr_id for the combination of
         -- resource_id, resource_role_id and group_id
         FOR named_acct_terr_id_rec IN lcu_named_acct_terr_id
                                   (
                                    p_resource_id        => ln_dpl_resource_id
                                    , p_resource_role_id => ln_dpl_resource_role_id
                                    , p_group_id         => ln_dpl_group_id
                                    )
         LOOP
                       
             -- Initializing the variables
             ln_max_named_acct_terr_id := NULL;
             ln_count_named_acct_terr_id := ln_count_named_acct_terr_id + 1;
                                                                  
             IF ln_count_named_acct_terr_id = 1 THEN
                                                                     
                -- Initializing the variables
                ln_min_named_acct_terr_id := NULL;
                                                   
                ln_min_named_acct_terr_id := named_acct_terr_id_rec.named_acct_terr_id;
                                                   
             ELSE
                                                   
                 ln_max_named_acct_terr_id := named_acct_terr_id_rec.named_acct_terr_id;
                                                
                 -- Find the entity_id which exist in the next territory
                 -- but not in the first territory
                                                               
                 FOR entity_id_rec IN lcu_entity_id
                             (
                               p_min_named_acct_terr_id   => ln_min_named_acct_terr_id
                               , p_max_named_acct_terr_id => ln_max_named_acct_terr_id
                             )
                 LOOP
                                                      
                     -- Initialize the variables
                     ln_entity_id := NULL;
                                                         
                     ln_entity_id := entity_id_rec.entity_id;
                                                      
                     -- Move the entity id to the named_acct_terr_id created earlier
                                                   
                     UPDATE xx_tm_nam_terr_entity_dtls XTNT
                     SET    XTNT.named_acct_terr_id = ln_min_named_acct_terr_id
                     WHERE  XTNT.named_acct_terr_id = ln_max_named_acct_terr_id
                     AND    XTNT.entity_id          = ln_entity_id
                     AND    XTNT.entity_type        = 'PARTY_SITE'
                     AND    NVL(status,'A')         = 'A'
                     AND    SYSDATE BETWEEN XTNT.start_date_active AND NVL(XTNT.end_date_active,SYSDATE);
                                                                     
                 END LOOP;
                                                               
                 -- Delete the duplicate named_acct_terr_id from XX_TM_NAM_TERR_DEFN
                                                   
                 DELETE FROM xx_tm_nam_terr_defn XTNT
                 WHERE  XTNT.named_acct_terr_id = ln_max_named_acct_terr_id
                 AND    NVL(XTNT.status,'A')    = 'A'
                 AND    SYSDATE BETWEEN XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE);
                                    
                 -- Delete the duplicate combination of resource_id, resource_role_id and group_id
                 -- from XX_TM_NAM_TERR_RSC_DTLS for the named_acct_terr_id created later
                                                         
                 DELETE FROM xx_tm_nam_terr_rsc_dtls XTNT
                 WHERE  XTNT.named_acct_terr_id = ln_max_named_acct_terr_id
                 AND    XTNT.resource_id        = ln_dpl_resource_id
                 AND    XTNT.resource_role_id   = ln_dpl_resource_role_id
                 AND    XTNT.group_id           = ln_dpl_group_id
                 AND    NVL(XTNT.status,'A')    = 'A'
                 AND    SYSDATE BETWEEN XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE);
                                                      
                 -- Delete all the remaining entities of type PARTY_SITE from the
                 -- named_acct_terr_id created later
                                                      
                 DELETE FROM xx_tm_nam_terr_entity_dtls XTNT
                 WHERE  XTNT.entity_type        = 'PARTY_SITE'
                 AND    XTNT.named_acct_terr_id = ln_max_named_acct_terr_id
                 AND    NVL(XTNT.status,'A')    = 'A'
                 AND    SYSDATE BETWEEN XTNT.start_date_active and NVL(XTNT.end_date_active,SYSDATE);
                                          
             END IF; -- named_acct_terr_id_rec.counter = 1
                                                
         END LOOP; -- named_acct_terr_id_rec IN lcu_named_acct_terr_id
                                             
     END LOOP; -- duplicate_assign_exists_rec IN lcu_duplicate_assign_exists
     
     COMMIT;
     
EXCEPTION
   WHEN EX_SUBMIT_CHILD THEN
       IF lcu_party_sites%ISOPEN THEN
          CLOSE lcu_party_sites;
       END IF;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0237_SUBMIT_CHILD_ERR');
       lc_error_message := FND_MESSAGE.GET;
       x_retcode   := 2;
       x_errbuf    := lc_error_message;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
                                          , p_error_message_code     => 'XX_TM_0237_SUBMIT_CHILD_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating a batch to process the party_site_id';
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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.MASTER_MAIN'
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
             , x_named_acct_terr_id   OUT NOCOPY  NUMBER
             , x_return_status        OUT NOCOPY  VARCHAR2
             , x_msg_count            OUT NOCOPY  NUMBER
             , x_message_data         OUT NOCOPY  VARCHAR2
            )
IS

-----------------------------
-- Declaring local variables
-----------------------------
EX_INSERT_ROW            EXCEPTION;
ln_named_acct_terr_id    PLS_INTEGER;
lc_error_message         VARCHAR2(1000);
lc_set_message           VARCHAR2(2000);

BEGIN

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
                                                , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                , p_program_id             => gn_program_id
                                                , p_module_name            => G_MODULE_NAME
                                                , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                , p_error_message          => lc_error_message
                                                , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                , p_error_status           => G_ERROR_STATUS_FLAG
                                               );
             RAISE EX_INSERT_ROW;
      END;

      -- Insert a row into the XX_TM_NAM_TERR_RSC_DTLS

      IF p_resource_id IS NOT NULL THEN

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
                                                    , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                    , p_program_id             => gn_program_id
                                                    , p_module_name            => G_MODULE_NAME
                                                    , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                    , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                    , p_error_message          => lc_error_message
                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                   );
                 RAISE EX_INSERT_ROW;
         END;

      END IF;

   ELSE

       ln_named_acct_terr_id := p_named_acct_terr_id;

   END IF; -- p_named_acct_terr_id IS NULL

   lc_error_message := NULL;
   lc_set_message   := NULL;

   -- Check whether the entity_type and entity exists for the named_acct_terr_id
   lc_error_message := NULL;
   lc_set_message   := NULL;

   IF (p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL AND ln_named_acct_terr_id IS NOT NULL) THEN

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
                                                   , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                   , p_program_id             => gn_program_id
                                                   , p_module_name            => G_MODULE_NAME
                                                   , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                                   , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                   , p_error_message          => lc_error_message
                                                   , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                   , p_error_status           => G_ERROR_STATUS_FLAG
                                                  );
                RAISE EX_INSERT_ROW;
         END;

   END IF; -- p_entity_type IS NOT NULL AND p_entity_id IS NOT NULL

   x_named_acct_terr_id := ln_named_acct_terr_id;

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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.INSERT_ROW'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END insert_row;

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
                        p_resource_id            IN  NUMBER
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
EX_CREATE_RECORD          EXCEPTION;
ln_api_version            PLS_INTEGER := 1.0;
lc_return_status          VARCHAR2(03);
lc_msg_data               VARCHAR2(2000);
ln_msg_count              PLS_INTEGER;
lc_message                VARCHAR2(2000);
lc_err_message            VARCHAR2(2000);
lc_concat_rsc_role_grp_id VARCHAR2(2000);
ln_named_acct_terr_id     PLS_INTEGER;
lc_terr_name              VARCHAR2(2000);
lc_error_message          VARCHAR2(2000);
lc_set_message            VARCHAR2(2000);

BEGIN

   --  Initialize API return status to success

   x_return_status := FND_API.G_RET_STS_SUCCESS;

   lc_return_status := NULL;
   lc_msg_data      := NULL;

   -- Check whether the resource exists in the custom resource table

   BEGIN

        SELECT XTNT.named_acct_terr_id
        INTO   ln_named_acct_terr_id
        FROM   xx_tm_nam_terr_rsc_dtls XTNT
               , xx_tm_nam_terr_defn   XTTD
        WHERE  XTNT.resource_id      = p_resource_id
        AND    XTTD.named_acct_terr_id = XTNT.named_acct_terr_id
        AND    XTNT.resource_role_id = p_role_id
        AND    XTNT.group_id         = p_group_id
        AND    NVL(XTNT.status,'A')  = 'A'
        AND    NVL(XTTD.status,'A')  = 'A'
        AND    SYSDATE BETWEEN XTNT.start_date_active AND NVL(XTNT.end_date_active,SYSDATE)
        AND    SYSDATE BETWEEN XTTD.start_date_active AND NVL(XTTD.end_date_active,SYSDATE)
        AND    rownum = 1;

   EXCEPTION
      WHEN OTHERS THEN
          ln_named_acct_terr_id := NULL;
   END;

   IF ln_named_acct_terr_id IS NOT NULL THEN

      insert_row
              (
               p_api_version            => ln_api_version
               , p_named_acct_terr_id   => ln_named_acct_terr_id
               , p_entity_type          => 'PARTY_SITE'
               , p_entity_id            => p_party_site_id
               , x_named_acct_terr_id   => ln_named_acct_terr_id
               , x_return_status        => lc_return_status
               , x_msg_count            => lc_msg_data
               , x_message_data         => ln_msg_count
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
                                                , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                                , p_program_id             => gn_program_id
                                                , p_module_name            => G_MODULE_NAME
                                                , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
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

       -- Derive the territory_name and description

       BEGIN

            SELECT NVL(source_name,'No Territoty Name')
            INTO   lc_terr_name
            FROM   jtf_rs_resource_extns JRR
            WHERE  JRR.resource_id = p_resource_id;

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0124_NOT_VALID_TERRITORY');
               lc_error_message := FND_MESSAGE.GET;
               WRITE_LOG(lc_error_message);
               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                 , p_application_name       => G_APPLICATION_NAME
                                                 , p_program_type           => G_PROGRAM_TYPE
                                                 , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                 , p_program_id             => gn_program_id
                                                 , p_module_name            => G_MODULE_NAME
                                                 , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                 , p_error_message_code     => 'XX_TM_0124_NOT_VALID_TERRITORY'
                                                 , p_error_message          => lc_error_message
                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                );
               RAISE EX_CREATE_RECORD;
          WHEN OTHERS THEN
              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
              lc_set_message     :=  'Unexpected Error while deriving territory name and description';
              FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
              FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
              FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
              lc_error_message := FND_MESSAGE.GET;
              WRITE_LOG(lc_error_message);
              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                 , p_application_name       => G_APPLICATION_NAME
                                                 , p_program_type           => G_PROGRAM_TYPE
                                                 , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                 , p_program_id             => gn_program_id
                                                 , p_module_name            => G_MODULE_NAME
                                                 , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                 , p_error_message          => lc_error_message
                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                );
              RAISE EX_CREATE_RECORD;
       END;

      insert_row(
                 p_api_version            => ln_api_version
                 , p_named_acct_terr_name => lc_terr_name
                 , p_named_acct_terr_desc => lc_terr_name
                 , p_full_access_flag     => p_full_access_flag
                 , p_resource_id          => p_resource_id
                 , p_role_id              => p_role_id
                 , p_group_id             => p_group_id
                 , p_entity_type          => 'PARTY_SITE'
                 , p_entity_id            => p_party_site_id
                 , x_named_acct_terr_id   => ln_named_acct_terr_id
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
                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                               , p_program_id             => gn_program_id
                                               , p_module_name            => G_MODULE_NAME
                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                               , p_error_message_count    => b
                                               , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                               , p_error_message          => lc_msg_data
                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                              );

        END LOOP;
        RAISE EX_CREATE_RECORD;

      END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

   END IF; -- ln_named_acct_terr_id IS NOT NULL

EXCEPTION
   WHEN EX_CREATE_RECORD THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0126_CREATE_RECRD_TERMIN');
       lc_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
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
       WRITE_LOG(lc_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CREATE_RECORD'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END create_record;

-- +===================================================================+
-- | Name  : child_main                                                |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD:        |
-- |                    New Division Named Account Assignment Child    |
-- |                    Program' to create a new division for          |
-- |                    the party sites                                |
-- |                                                                   |
-- +===================================================================+  

PROCEDURE child_main
                    (
                     x_errbuf               OUT NOCOPY VARCHAR2
                     , x_retcode            OUT NOCOPY NUMBER
                     , p_division           IN  VARCHAR2
                     , p_party_site_id_from IN NUMBER
                     , p_party_site_id_to   IN NUMBER
                    )
IS
---------------------------
--Declaring local variables
---------------------------
EX_NEW_DIVISION             EXCEPTION;
EX_NO_RESOURCE_DIV          EXCEPTION;
EX_CREATE_ERR               EXCEPTION;
ln_party_site_id            PLS_INTEGER;
ln_total_count              PLS_INTEGER := 0;
lc_error_message            VARCHAR2(4000);
lc_new_divsn_success        VARCHAR2(03) ;
ln_api_version              PLS_INTEGER := 1.0;
lc_return_status            VARCHAR2(03);
ln_msg_count                PLS_INTEGER;
lc_msg_data                 VARCHAR2(2000);
l_counter                   PLS_INTEGER;
ln_salesforce_id            PLS_INTEGER;
ln_role_id                  PLS_INTEGER;
ln_sales_group_id           PLS_INTEGER;
ln_group_id                 PLS_INTEGER;
lc_full_access_flag         VARCHAR2(03);
ln_asignee_role_id          PLS_INTEGER;
lc_assignee_role_division   VARCHAR2(50);
lc_party_site_div_exists    VARCHAR2(03);
ln_resource_id              PLS_INTEGER;
lc_role_division            VARCHAR2(50);
lc_new_divsn_terr_exists    VARCHAR2(03);
lc_set_message              VARCHAR2(2000);
ln_success_count            PLS_INTEGER := 0;
ln_error_count              PLS_INTEGER := 0;
l_squal_char01              VARCHAR2(4000);
l_squal_char02              VARCHAR2(4000);
l_squal_char03              VARCHAR2(4000);
l_squal_char04              VARCHAR2(4000);
l_squal_char05              VARCHAR2(4000);
l_squal_char06              VARCHAR2(4000);
l_squal_char07              VARCHAR2(4000);
l_squal_char08              VARCHAR2(4000);
l_squal_char09              VARCHAR2(4000);
l_squal_char10              VARCHAR2(4000);
l_squal_char11              VARCHAR2(4000);
l_squal_char50              VARCHAR2(4000);
l_squal_char59              VARCHAR2(4000);
l_squal_char60              VARCHAR2(4000);
l_squal_char61              VARCHAR2(4000);
l_squal_num60               VARCHAR2(4000);
l_squal_curc01              VARCHAR2(4000);
l_squal_num01               NUMBER;
l_squal_num02               NUMBER;
l_squal_num03               NUMBER;
l_squal_num04               NUMBER;
l_squal_num05               NUMBER;
l_squal_num06               NUMBER;  
l_squal_num07               NUMBER;   
lc_total_count              VARCHAR2(1000);
ln_exists_count             PLS_INTEGER := 0;
ln_no_resource_div          PLS_INTEGER := 0;
lc_total_success            VARCHAR2(1000);
lc_total_failed             VARCHAR2(1000);
lc_total_exists             VARCHAR2(1000);
lc_no_resource              VARCHAR2(1000);
lc_role                     VARCHAR2(50);
lc_manager_flag             VARCHAR2(03);
ln_count                    PLS_INTEGER;
lc_message_code             VARCHAR2(30);
lc_status                   VARCHAR2(10);
ln_admin_count              PLS_INTEGER;
lc_assignee_admin_flag      VARCHAR2(03);
ln_party_site_enrich        NUMBER := 0;
lc_party_site_enrich_exists VARCHAR2(10);
--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE party_sites_tbl_type IS TABLE OF xx_tm_nam_terr_curr_assign_v.entity_id%TYPE INDEX BY BINARY_INTEGER;
lt_party_sites party_sites_tbl_type;

-----------------------------------
-- Declaring Record Type Variables
-----------------------------------
lp_gen_bulk_rec    JTF_TERR_ASSIGN_PUB.bulk_trans_rec_type;
lx_gen_return_rec  JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type;

-- ------------------------------------------------
-- Cursor to fetch the party_site_id from the view
-- ------------------------------------------------
CURSOR lcu_party_sites(
                       p_party_site_id_from NUMBER
                       , p_party_site_id_to NUMBER
                      )
IS
SELECT DISTINCT TERR_ENT.entity_id
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
AND    TERR_ENT.entity_id BETWEEN p_party_site_id_from AND p_party_site_id_to
ORDER BY TERR_ENT.entity_id;

-- --------------------------------------------------------------------------------------
-- Declare cursor to verify whether the party_site_id already exists in the entity table
-- --------------------------------------------------------------------------------------
CURSOR lcu_party_site_assignments(
                                  p_party_site_id NUMBER
                                 )
IS
SELECT TERR_RSC.resource_id        resource_id
       , TERR_RSC.resource_role_id role_id
       , TERR_RSC.group_id         group_id
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
AND    TERR_ENT.entity_id = p_party_site_id;

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

--Added by jeevan

CURSOR lcu_pros_party_sites(
                            p_from_party_site_id NUMBER
                            , p_to_party_site_id NUMBER
                           ) 
IS
SELECT HPS.party_site_id
FROM   hz_party_sites HPS
       , hz_parties HP
WHERE  HP.party_id = HPS.party_id
AND    HP.party_type = 'ORGANIZATION'
AND    HPS.status = 'A'
AND    HP.status = 'A'
AND    hp.attribute13 = 'PROSPECT'
AND    HPS.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id
ORDER BY 1;

CURSOR lcu_enrich_party_sites(
                              p_from_party_site_id NUMBER
                              , p_to_party_site_id NUMBER
                             )
IS
SELECT HPSB.party_site_id,n_ext_attr8
FROM   hz_party_sites_ext_b HPSB
       --, hz_imp_batch_summary HIBS
       , ego_attr_groups_v EAGV
WHERE  EAGV.attr_group_type = 'HZ_PARTY_SITES_GROUP'
AND    EAGV.attr_group_name = 'SITE_DEMOGRAPHICS'
AND    HPSB.attr_group_id = EAGV.attr_group_id
AND    HPSB.party_site_id BETWEEN p_from_party_site_id AND p_to_party_site_id;
--AND    HIBS.batch_id = HPSB.n_ext_attr20
--AND    HIBS.original_system='GDW';

-- -------------------------------
-- Declaring Table Type variables
-- -------------------------------
TYPE pst_rsc_role_group_id_tbl_type IS TABLE OF lcu_party_site_assignments%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_pst_rsc_role_group_id pst_rsc_role_group_id_tbl_type;

TYPE tbl_party_sites_type IS TABLE OF lcu_pros_party_sites%ROWTYPE INDEX BY BINARY_INTEGER;
lt_pros_party_sites party_sites_tbl_type;

TYPE ltb_enrich_party_sites IS TABLE OF lcu_enrich_party_sites%ROWTYPE INDEX BY BINARY_INTEGER;
lt_enrich_party_sites ltb_enrich_party_sites;

BEGIN

   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   WRITE_LOG(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG(LPAD('OD: TM New Division Named Account Assignment Child Program',60));
   WRITE_LOG(RPAD(' ',80,'-'));
   WRITE_LOG('');
   WRITE_LOG('Input Parameters ');
   WRITE_LOG('Division           : '||p_division);
   WRITE_LOG('Party Site Id From : '||p_party_site_id_from);
   WRITE_LOG('Party Site Id To   : '||p_party_site_id_to);
   WRITE_LOG(RPAD(' ',80,'-'));

   WRITE_OUT(RPAD('Office Depot',60)||'Date: '||trunc(sysdate));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT(LPAD('OD: TM New Division Named Account Assignment Child Program',60));
   WRITE_OUT(RPAD(' ',80,'-'));
   WRITE_OUT('');
   WRITE_OUT(RPAD(' ',80,'-'));
   
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
   lp_gen_bulk_rec.squal_char61.EXTEND;
   lp_gen_bulk_rec.squal_num60.EXTEND;
   lp_gen_bulk_rec.squal_num01.EXTEND;
   lp_gen_bulk_rec.squal_num02.EXTEND;
   lp_gen_bulk_rec.squal_num03.EXTEND;
   lp_gen_bulk_rec.squal_num04.EXTEND;
   lp_gen_bulk_rec.squal_num05.EXTEND;
   lp_gen_bulk_rec.squal_num06.EXTEND;
   lp_gen_bulk_rec.squal_num07.EXTEND;
   
   OPEN lcu_party_sites(
                        p_party_site_id_from => p_party_site_id_from
                        , p_party_site_id_to => p_party_site_id_to  
                       );
   LOOP
       
       FETCH lcu_party_sites BULK COLLECT INTO lt_party_sites LIMIT G_LIMIT;
       

       IF lt_party_sites.COUNT <> 0 THEN

       lt_pros_party_sites.DELETE;
       OPEN lcu_pros_party_sites(
                                 lt_party_sites(lt_party_sites.FIRST)
                                 , lt_party_sites(lt_party_sites.LAST)
                                ); 
       FETCH lcu_pros_party_sites BULK COLLECT INTO lt_pros_party_sites;
       CLOSE lcu_pros_party_sites;
              
       lt_enrich_party_sites.DELETE;
       OPEN lcu_enrich_party_sites(
                                   lt_party_sites(lt_party_sites.FIRST)
                                   , lt_party_sites(lt_party_sites.LAST)
                                  ); 
       FETCH lcu_enrich_party_sites BULK COLLECT INTO lt_enrich_party_sites;                                  
       CLOSE lcu_enrich_party_sites;
                
         FOR i IN lt_party_sites.FIRST .. lt_party_sites.LAST
         LOOP
             
             BEGIN
             
                      -- Initializing the variable

                      ln_party_site_id         := NULL;
                      lt_pst_rsc_role_group_id.DELETE;
                      lc_new_divsn_success := 'Y';
                      lc_party_site_div_exists := NULL;
                      lc_new_divsn_terr_exists := NULL;

                      ln_total_count := ln_total_count + 1;

                      ln_party_site_id := lt_party_sites(i);

                      WRITE_LOG(RPAD(' ',80,'-'));
                      WRITE_LOG('Processing for the party site id: '||ln_party_site_id);

                      -- Call to Named Account Lookup API with the party_site_id

                      -- Derive resource_id , role_id and group_id 
                      -- by passing the address_id to the Current Date Named Account Lookup API

                      OPEN  lcu_party_site_assignments(ln_party_site_id);
                      FETCH lcu_party_site_assignments BULK COLLECT INTO lt_pst_rsc_role_group_id;
                      CLOSE lcu_party_site_assignments;

                      lc_error_message := NULL;

                      IF lt_pst_rsc_role_group_id.COUNT = 0 THEN

                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0135_NO_TERRITORY');
                        FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                        lc_error_message := FND_MESSAGE.GET;
                        WRITE_LOG(lc_error_message);
                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                           , p_application_name       => G_APPLICATION_NAME
                                                           , p_program_type           => G_PROGRAM_TYPE
                                                           , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                           , p_program_id             => gn_program_id 
                                                           , p_module_name            => G_MODULE_NAME
                                                           , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                           , p_error_message_code     => 'XX_TM_0135_NO_TERRITORY'
                                                           , p_error_message          => lc_error_message
                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                          );
                        RAISE EX_NEW_DIVISION;

                      END IF; -- lt_details_rec.COUNT = 0 

                      -- For each of the resource find a matching division as the input parameter

                      lc_new_divsn_terr_exists := 'N';

                      FOR x IN lt_pst_rsc_role_group_id.FIRST .. lt_pst_rsc_role_group_id.LAST
                      LOOP

                          -- Initializing the variables
                          ln_resource_id   := NULL;
                          ln_role_id       := NULL;
                          ln_group_id      := NULL;
                          lc_role_division := NULL;
                          lc_error_message := NULL;

                          ln_resource_id := lt_pst_rsc_role_group_id(x).resource_id;
                          ln_role_id     := lt_pst_rsc_role_group_id(x).role_id;
                          ln_group_id    := lt_pst_rsc_role_group_id(x).group_id;

                          BEGIN

                               -- Derive the division for this resource

                               SELECT ROL.attribute15
                               INTO   lc_role_division
                               FROM   jtf_rs_role_relations JRR
                                      , jtf_rs_group_members MEM
                                      , jtf_rs_group_usages JRU
                                      , jtf_rs_roles_b ROL
                               WHERE  MEM.resource_id = ln_resource_id
                               AND    NVL(MEM.delete_flag,'N') <> 'Y'
                               AND    MEM.group_id = ln_group_id
                               AND    JRU.group_id = MEM.group_id
                               AND    JRU.usage = 'SALES'
                               AND    JRR.role_resource_id    = MEM.group_member_id
                               AND    JRR.role_resource_type  = 'RS_GROUP_MEMBER'
                               AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                                                     AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                               AND    NVL(JRR.delete_flag,'N') <> 'Y'                          
                               AND    ROL.role_id = JRR.role_id
                               AND    ROL.role_id  = ln_role_id
                               AND    ROL.role_type_code='SALES'
                               AND    ROL.active_flag = 'Y';
                               
                          EXCEPTION
                             WHEN NO_DATA_FOUND THEN
                                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0122_AS_NO_SALES_ROLE');
                                 FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_resource_id);
                                 lc_error_message := FND_MESSAGE.GET;
                                 WRITE_LOG(lc_error_message);
                                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                    p_return_code              => FND_API.G_RET_STS_ERROR
                                                                    , p_application_name       => G_APPLICATION_NAME
                                                                    , p_program_type           => G_PROGRAM_TYPE
                                                                    , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_program_id             => gn_program_id 
                                                                    , p_module_name            => G_MODULE_NAME
                                                                    , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_error_message_code     => 'XX_TM_0122_AS_NO_SALES_ROLE'
                                                                    , p_error_message          => lc_error_message
                                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                                   );
                                 RAISE EX_NEW_DIVISION;
                             WHEN TOO_MANY_ROWS THEN
                                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0123_AS_MANY_SALES_ROLE');
                                 FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_resource_id);
                                 lc_error_message := FND_MESSAGE.GET;
                                 WRITE_LOG(lc_error_message);
                                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                    p_return_code              => FND_API.G_RET_STS_ERROR
                                                                    , p_application_name       => G_APPLICATION_NAME
                                                                    , p_program_type           => G_PROGRAM_TYPE
                                                                    , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_program_id             => gn_program_id 
                                                                    , p_module_name            => G_MODULE_NAME
                                                                    , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_error_message_code     => 'XX_TM_0123_AS_MANY_SALES_ROLE'
                                                                    , p_error_message          => lc_error_message
                                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                                   );
                                 RAISE EX_NEW_DIVISION;
                             WHEN OTHERS THEN
                                 FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                 lc_set_message     :=  'Unexpected Error while deriving role_division of the resource';
                                 FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                 FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                 FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                 lc_error_message := FND_MESSAGE.GET;
                                 WRITE_LOG(lc_error_message);
                                 XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                    p_return_code              => FND_API.G_RET_STS_ERROR
                                                                    , p_application_name       => G_APPLICATION_NAME
                                                                    , p_program_type           => G_PROGRAM_TYPE
                                                                    , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_program_id             => gn_program_id 
                                                                    , p_module_name            => G_MODULE_NAME
                                                                    , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                    , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                    , p_error_message          => lc_error_message
                                                                    , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                    , p_error_status           => G_ERROR_STATUS_FLAG
                                                                   );
                                 RAISE EX_NEW_DIVISION;
                          END;

                          IF UPPER(lc_role_division) = UPPER(p_division) THEN

                            lc_new_divsn_terr_exists := 'S';
                            EXIT;

                          END IF;  

                      END LOOP; -- lt_details_rec.FIRST .. lt_details_rec.LAST

                      IF lc_new_divsn_terr_exists = 'S' THEN

                        WRITE_LOG('For the party_site_id : '||ln_party_site_id||' the new division : '||p_division||' already exists');
                        ln_exists_count := ln_exists_count + 1;
                        lc_new_divsn_success := NULL;

                      ELSE
                          
                          lc_party_site_enrich_exists :='N';
                          
                          IF lt_pros_party_sites.count > 0 THEN
                            FOR a IN lt_pros_party_sites.FIRST .. lt_pros_party_sites.last
                            LOOP
                                IF lt_pros_party_sites(a) = ln_party_site_id THEN 
                                   lc_party_site_enrich_exists :='Y';
                                   EXIT;
                                END IF;
                            END LOOP;
                          END IF;
                          
                          IF lc_party_site_enrich_exists = 'Y' AND 
                          lt_enrich_party_sites.COUNT > 0 THEN
                             lc_party_site_enrich_exists := 'N';
                             FOR e IN lt_enrich_party_sites.FIRST .. lt_enrich_party_sites.LAST
                             LOOP
                                 IF lt_enrich_party_sites(e).party_site_id = ln_party_site_id THEN
                                    lc_party_site_enrich_exists:='Y';
                                    EXIT;
                                 END IF;
                             END LOOP;        
                          END IF;  
                          
                          IF lc_party_site_enrich_exists = 'N' THEN
                             WRITE_LOG('Party Site ID : '||ln_party_site_id||' data not enriched' );
                             RAISE EX_NEW_DIVISION;
                          END IF;
                          
                          lc_error_message := NULL;
                          lc_return_status := NULL;
                          ln_msg_count     := NULL;
                          lc_msg_data      := NULL;
                          l_counter        := NULL;

                         -- Call to JTF_TERR_ASSIGN_PUB.get_winners with the party_site_id and country parameter

                         lp_gen_bulk_rec.squal_char01(1) := l_squal_char01;
                         lp_gen_bulk_rec.squal_char02(1) := l_squal_char02 ;
                         lp_gen_bulk_rec.squal_char03(1) := l_squal_char03;
                         lp_gen_bulk_rec.squal_char04(1) := l_squal_char04;
                         lp_gen_bulk_rec.squal_char05(1) := l_squal_char05;
                         lp_gen_bulk_rec.squal_char06(1) := l_squal_char06;  
                         lp_gen_bulk_rec.squal_char07(1) := l_squal_char07;  
                         lp_gen_bulk_rec.squal_char08(1) := l_squal_char08;
                         lp_gen_bulk_rec.squal_char09(1) := l_squal_char09;
                         lp_gen_bulk_rec.squal_char10(1) := l_squal_char10;
                         lp_gen_bulk_rec.squal_char11(1) := l_squal_char11;
                         lp_gen_bulk_rec.squal_char50(1) := l_squal_char50;
                         lp_gen_bulk_rec.squal_char59(1) := l_squal_char59;   
                         lp_gen_bulk_rec.squal_char60(1) := l_squal_char60;   
                         lp_gen_bulk_rec.squal_char61(1) := ln_party_site_id; 
                         lp_gen_bulk_rec.squal_num60(1)  := l_squal_num60;    
                         lp_gen_bulk_rec.squal_num01(1)  := l_squal_num01;    
                         lp_gen_bulk_rec.squal_num02(1)  := ln_party_site_id; --Party Site Id
                         lp_gen_bulk_rec.squal_num03(1)  := l_squal_num03;
                         lp_gen_bulk_rec.squal_num04(1)  := l_squal_num04;
                         lp_gen_bulk_rec.squal_num05(1)  := l_squal_num05;
                         lp_gen_bulk_rec.squal_num06(1)  := l_squal_num06;
                         lp_gen_bulk_rec.squal_num07(1)  := l_squal_num07;  

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
                               WRITE_LOG('Error for the party site id: '||ln_party_site_id||' '||lc_msg_data);
                               XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                  p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                  , p_application_name       => G_APPLICATION_NAME
                                                                  , p_program_type           => G_PROGRAM_TYPE
                                                                  , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                  , p_program_id             => gn_program_id 
                                                                  , p_module_name            => G_MODULE_NAME
                                                                  , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                  , p_error_message_count    => k
                                                                  , p_error_message_code     => 'XX_TM_0179_PROC_RETURNS_ERR'
                                                                  , p_error_message          => lc_msg_data
                                                                  , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                  , p_error_status           => G_ERROR_STATUS_FLAG
                                                                 );
                           END LOOP;

                           RAISE EX_NEW_DIVISION;

                         END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

                         lc_error_message := NULL;

                         IF lx_gen_return_rec.resource_id.COUNT = 0 THEN

                           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0121_NO_RES_RETURNED');
                           lc_error_message := FND_MESSAGE.GET;
                           WRITE_LOG(lc_error_message);
                           XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                              p_return_code              => FND_API.G_RET_STS_ERROR 
                                                              , p_application_name       => G_APPLICATION_NAME
                                                              , p_program_type           => G_PROGRAM_TYPE
                                                              , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                              , p_program_id             => gn_program_id 
                                                              , p_module_name            => G_MODULE_NAME
                                                              , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                              , p_error_message_code     => 'XX_TM_0121_NO_RES_RETURNED'
                                                              , p_error_message          => lc_error_message
                                                              , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                              , p_error_status           => G_ERROR_STATUS_FLAG
                                                             );
                           RAISE EX_NEW_DIVISION;

                         END IF; -- lx_gen_return_rec.resource_id.COUNT = 0

                         lc_party_site_div_exists := 'N';

                         -- To retirieve the matching division resource_id, role_id and group_id
                         --l_counter := lx_gen_return_rec.resource_id.FIRST;
                         write_log(' Counter =>'||lx_gen_return_rec.terr_id.count);
                         For l_counter in lx_gen_return_rec.terr_id.first ..lx_gen_return_rec.terr_id.LAST
                         --WHILE (l_counter <= lx_gen_return_rec.terr_id.LAST)
                         LOOP
                                                      
                             BEGIN
                                   -- Initializing the variables
                                  
                                   ln_salesforce_id          := NULL;
                                   ln_sales_group_id         := NULL;
                                   lc_full_access_flag       := NULL;
                                   ln_asignee_role_id        := NULL;
                                   lc_assignee_role_division := NULL;
                                   lc_error_message          := NULL;
                                   lc_role                   := NULL;
                                   lc_manager_flag           := NULL;
                                   ln_count                  := 0;
                                   lc_set_message            := NULL;

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
                                                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                          , p_module_name            => G_MODULE_NAME
                                                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                          , p_error_message_code     => 'XX_TM_0243_ADM_MORE_THAN_ONE'
                                                                          , p_error_message          => lc_error_message
                                                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                                                         );
                                       RAISE EX_CREATE_ERR;
                                                                 
                                   END IF;
                                   
                                   -- Deriving the group id of the resource if ln_sales_group_id IS NULL
                                                                     
                                   IF (ln_sales_group_id IS NULL) THEN
                                                      
                                     /*
                                     BEGIN
                                                            
                                        SELECT MEM.group_id
                                        INTO   ln_sales_group_id
                                        FROM   jtf_rs_group_members MEM
                                               , jtf_rs_group_usages JRU
                                        WHERE  MEM.resource_id = ln_salesforce_id
                                        AND    MEM.group_id = JRU.group_id
                                        AND    JRU.USAGE='SALES'
                                        AND    NVL(MEM.delete_flag,'N') <> 'Y';

                                     EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0215_NO_SALES_GROUP');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => 'XX_TM_0215_NO_SALES_GROUP'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                        WHEN TOO_MANY_ROWS THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0216_MANY_SALES_GROUP');
                                            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                            lc_error_message := FND_MESSAGE.GET;
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => 'XX_TM_0216_MANY_SALES_GROUP'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                        WHEN OTHERS THEN
                                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                            lc_set_message     :=  'Unexpected Error while deriving group_id of the assignee.';
                                            FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                            FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                            FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                            lc_error_message := FND_MESSAGE.GET;
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                     END;
                                     */
                                     
                                     IF lc_assignee_admin_flag = 'Y' THEN
                                                                                         
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0244_ADM_GRP_MANDATORY');
                                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                        lc_error_message := FND_MESSAGE.GET;
                                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                                           , p_application_name       => G_APPLICATION_NAME
                                                                           , p_program_type           => G_PROGRAM_TYPE
                                                                           , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                           , p_module_name            => G_MODULE_NAME
                                                                           , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                           , p_error_message_code     => 'XX_TM_0244_ADM_GRP_MANDATORY'
                                                                           , p_error_message          => lc_error_message
                                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                                          );
                                        RAISE EX_CREATE_ERR;
                                                                                      
                                     END IF; -- lc_assignee_admin_flag = 'Y'
                                     SELECT count(ROL.manager_flag)
                                     INTO   ln_count
                                     FROM   jtf_rs_role_relations JRR
                                            , jtf_rs_group_members MEM
                                            , jtf_rs_group_usages JRU
                                            , jtf_rs_roles_b ROL
                                     WHERE  MEM.resource_id = ln_salesforce_id
                                     AND    NVL(MEM.delete_flag,'N') <> 'Y'
                                     AND    MEM.group_id = NVL(ln_sales_group_id,MEM.group_id)
                                     AND    JRU.group_id = MEM.group_id
                                     AND    JRU.usage = 'SALES'
                                     AND    JRR.role_resource_id    = MEM.group_member_id
                                     AND    JRR.role_resource_type = 'RS_GROUP_MEMBER'
                                     AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                                                           AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                     AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                     AND    ROL.role_id = JRR.role_id
                                     AND    ROL.role_type_code='SALES'
                                     AND    ROL.manager_flag = 'Y'
                                     AND    ROL.active_flag = 'Y';
                                     
                                     IF ln_count = 0 THEN

                                       -- This means the resource is a sales-rep
                                       lc_manager_flag := 'N';

                                     ELSIF ln_count = 1 THEN

                                          -- This means the resource is a manager
                                          lc_manager_flag := 'Y';
                                          
                                     END IF;
                                     BEGIN
                                                                                    
                                          SELECT MEM_ASG.group_id                                                 
                                          INTO   ln_sales_group_id
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
                                          AND    (CASE lc_manager_flag 
                                                       WHEN 'Y' THEN ROL_ASG.attribute14 
                                                       ELSE 'N' 
                                                               END) = (CASE lc_manager_flag 
                                                                            WHEN 'Y' THEN 'HSE' 
                                                                            ELSE 'N' 
                                                                                    END);   
                                     EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                            IF lc_manager_flag = 'Y' THEN
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => lc_message_code
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                        WHEN TOO_MANY_ROWS THEN
                                            IF lc_manager_flag = 'Y' THEN
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                     END;

                                     
                                   END IF; -- ln_sales_group_id IS NULL
                                                      
                                   -- Deriving the role of the resource if lc_role IS NULL
                                                            
                                   IF lc_role IS NULL THEN
                                                                  
                                     IF lc_assignee_admin_flag = 'Y' THEN
                                                                                                        
                                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0245_ADM_ROLE_MANDATORY');
                                        FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                        lc_error_message := FND_MESSAGE.GET;
                                        XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                           p_return_code              => FND_API.G_RET_STS_ERROR
                                                                           , p_application_name       => G_APPLICATION_NAME
                                                                           , p_program_type           => G_PROGRAM_TYPE
                                                                           , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                           , p_module_name            => G_MODULE_NAME
                                                                           , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                           , p_error_message_code     => 'XX_TM_0245_ADM_ROLE_MANDATORY'
                                                                           , p_error_message          => lc_error_message
                                                                           , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                           , p_error_status           => G_ERROR_STATUS_FLAG
                                                                          );
                                        RAISE EX_CREATE_ERR;
                                                                                                     
                                     END IF; -- lc_assignee_admin_flag = 'Y'
                                     
                                     -- First check whether the resource is a manager
                                                               
                                     SELECT count(ROL.manager_flag)
                                     INTO   ln_count
                                     FROM   jtf_rs_role_relations JRR
                                            , jtf_rs_group_members MEM
                                            , jtf_rs_group_usages JRU
                                            , jtf_rs_roles_b ROL
                                     WHERE  MEM.resource_id = ln_salesforce_id
                                     AND    NVL(MEM.delete_flag,'N') <> 'Y'
                                     AND    MEM.group_id = NVL(ln_sales_group_id,MEM.group_id)
                                     AND    JRU.group_id = MEM.group_id
                                     AND    JRU.usage = 'SALES'
                                     AND    JRR.role_resource_id    = MEM.group_member_id
                                     AND    JRR.role_resource_type = 'RS_GROUP_MEMBER'
                                     AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) 
                                                           AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
                                     AND    NVL(JRR.delete_flag,'N') <> 'Y'
                                     AND    ROL.role_id = JRR.role_id
                                     AND    ROL.role_type_code='SALES'
                                     AND    ROL.manager_flag = 'Y'
                                     AND    ROL.active_flag = 'Y';
                                     
                                     IF ln_count = 0 THEN

                                       -- This means the resource is a sales-rep
                                       lc_manager_flag := 'N';

                                     ELSIF ln_count = 1 THEN

                                          -- This means the resource is a manager
                                          lc_manager_flag := 'Y';

                                     ELSE 

                                         -- The resource is a manger of more than one group
                                         FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0219_MGR_MORE_THAN_ONE');
                                         FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', ln_salesforce_id);
                                         lc_error_message := FND_MESSAGE.GET;
                                         WRITE_LOG(lc_error_message);
                                         XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                            p_return_code              => FND_API.G_RET_STS_ERROR
                                                                            , p_application_name       => G_APPLICATION_NAME
                                                                            , p_program_type           => G_PROGRAM_TYPE
                                                                            , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                            , p_program_id             => gn_program_id 
                                                                            , p_module_name            => G_MODULE_NAME
                                                                            , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                            , p_error_message_code     => 'XX_TM_0219_MGR_MORE_THAN_ONE'
                                                                            , p_error_message          => lc_error_message
                                                                            , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                            , p_error_status           => G_ERROR_STATUS_FLAG
                                                                           );
                                         RAISE EX_CREATE_ERR;
                              
                                     END IF; -- ln_count = 0
                                             
                                     -- Derive the role_id and role_division of assignee resource
                                     -- with the resource_id and group_id derived
                                             
                                     BEGIN
                                                                                    
                                          SELECT JRR_ASG.role_id
                                                 , ROL_ASG.attribute15
                                          INTO   ln_asignee_role_id
                                                 , lc_assignee_role_division
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
                                          AND    (CASE lc_manager_flag 
                                                       WHEN 'Y' THEN ROL_ASG.attribute14 
                                                       ELSE 'N' 
                                                               END) = (CASE lc_manager_flag 
                                                                            WHEN 'Y' THEN 'HSE' 
                                                                            ELSE 'N' 
                                                                                    END);   
                                     EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                            IF lc_manager_flag = 'Y' THEN
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_error_message_code     => lc_message_code
                                                                               , p_error_message          => lc_error_message
                                                                               , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                               , p_error_status           => G_ERROR_STATUS_FLAG
                                                                              );
                                            RAISE EX_CREATE_ERR;
                                        WHEN TOO_MANY_ROWS THEN
                                            IF lc_manager_flag = 'Y' THEN
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
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
                                            WRITE_LOG(lc_error_message);
                                            XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                               p_return_code              => FND_API.G_RET_STS_ERROR
                                                                               , p_application_name       => G_APPLICATION_NAME
                                                                               , p_program_type           => G_PROGRAM_TYPE
                                                                               , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                               , p_program_id             => gn_program_id 
                                                                               , p_module_name            => G_MODULE_NAME
                                                                               , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
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
                                            INTO   ln_asignee_role_id
                                                   , lc_assignee_role_division
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
                                              WRITE_LOG(lc_error_message);
                                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                                 , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                                 , p_program_id             => gn_program_id 
                                                                                 , p_module_name            => G_MODULE_NAME
                                                                                 , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
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
                                              WRITE_LOG(lc_error_message);
                                              XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                                 p_return_code              => FND_API.G_RET_STS_ERROR
                                                                                 , p_application_name       => G_APPLICATION_NAME
                                                                                 , p_program_type           => G_PROGRAM_TYPE
                                                                                 , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                                 , p_program_id             => gn_program_id 
                                                                                 , p_module_name            => G_MODULE_NAME
                                                                                 , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                                 , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                                 , p_error_message          => lc_error_message
                                                                                 , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                                 , p_error_status           => G_ERROR_STATUS_FLAG
                                                                                );
                                              RAISE EX_CREATE_ERR;
                                       END;

                                   END IF; -- lc_role IS NULL 

                                   -- Compare whether the resource retrieved belong to the same division 
                                   -- as passed in the input paramter

                                   IF UPPER(lc_assignee_role_division) = UPPER(p_division) THEN

                                     lc_party_site_div_exists := 'Y';
                                     EXIT;

                                   END IF; -- UPPER(lc_assignee_role_division) = UPPER(p_division)  

                                   
                             
                             EXCEPTION
                                WHEN EX_CREATE_ERR THEN
                                    NULL;
                                WHEN OTHERS THEN
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                                    lc_set_message     :=  'Unexpected Error in creating the new division : '||p_division;
                                    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                                    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                                    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                                    lc_error_message := FND_MESSAGE.GET;
                                    WRITE_LOG(lc_error_message);
                                    XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                                       p_return_code              => FND_API.G_RET_STS_ERROR 
                                                                       , p_application_name       => G_APPLICATION_NAME
                                                                       , p_program_type           => G_PROGRAM_TYPE
                                                                       , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                       , p_program_id             => gn_program_id 
                                                                       , p_module_name            => G_MODULE_NAME
                                                                       , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                                       , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                                       , p_error_message          => lc_error_message
                                                                       , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                                       , p_error_status           => G_ERROR_STATUS_FLAG
                                                                      );
                             END;
                             
                             --l_counter := l_counter + 1;
                   
                   END LOOP; -- l_counter <= lx_gen_return_rec.terr_id.LAST
                   
                   IF lc_party_site_div_exists = 'N' THEN
                                        
                     RAISE EX_NO_RESOURCE_DIV;
                                        
                   END IF;
                   
                   create_record(
                                 p_resource_id            => ln_salesforce_id
                                 , p_role_id              => ln_asignee_role_id
                                 , p_group_id             => ln_sales_group_id
                                 , p_party_site_id        => ln_party_site_id
                                 , p_full_access_flag     => lc_full_access_flag
                                 , x_return_status        => lc_status
                                );
                                
                    IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                              
                       RAISE EX_NEW_DIVISION;
                       
                                         
                    ELSE
                            
                        lc_new_divsn_success := 'Y';
                        COMMIT;
                             
                    END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
                                          
                END IF; -- lc_new_divsn_terr_exists = 'S'
                  
             EXCEPTION
                WHEN EX_NO_RESOURCE_DIV THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0168_NO_DIV_RESOURCE');
                    FND_MESSAGE.SET_TOKEN('P_DIVISION', p_division);
                    FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                    lc_error_message := FND_MESSAGE.GET;
                    lc_new_divsn_success := NULL;
                    WRITE_LOG(lc_error_message);
                    ln_no_resource_div := ln_no_resource_div + 1;
                    ROLLBACK;
                WHEN EX_NEW_DIVISION THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0167_NEW_DIVISION_ERR');
                    FND_MESSAGE.SET_TOKEN('P_PARTY_SITE_ID', ln_party_site_id);
                    lc_error_message := FND_MESSAGE.GET;
                    lc_new_divsn_success := 'N';
                    WRITE_LOG(lc_error_message);
                    XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                       p_return_code              => FND_API.G_RET_STS_ERROR 
                                                       , p_application_name       => G_APPLICATION_NAME
                                                       , p_program_type           => G_PROGRAM_TYPE
                                                       , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                       , p_program_id             => gn_program_id 
                                                       , p_module_name            => G_MODULE_NAME
                                                       , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                       , p_error_message_code     => 'XX_TM_0167_NEW_DIVISION_ERR'
                                                       , p_error_message          => lc_error_message
                                                       , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                       , p_error_status           => G_ERROR_STATUS_FLAG
                                                      );
                    ROLLBACK;
                WHEN OTHERS THEN
                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
                    lc_set_message     :=  'Unexpected Error in creating the new division : '||p_division;
                    FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
                    FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
                    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
                    lc_error_message := FND_MESSAGE.GET;
                    lc_new_divsn_success := 'N';
                    WRITE_LOG(lc_error_message);
                    XX_COM_ERROR_LOG_PUB.log_error_crm(
                                                       p_return_code              => FND_API.G_RET_STS_ERROR 
                                                       , p_application_name       => G_APPLICATION_NAME
                                                       , p_program_type           => G_PROGRAM_TYPE
                                                       , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                       , p_program_id             => gn_program_id 
                                                       , p_module_name            => G_MODULE_NAME
                                                       , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                                       , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                                       , p_error_message          => lc_error_message
                                                       , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                                       , p_error_status           => G_ERROR_STATUS_FLAG
                                                      );
                    ROLLBACK;
             END; 
             
             
             IF lc_new_divsn_success = 'Y' THEN
                                          
               ln_success_count := ln_success_count + 1;
                                        
             ELSIF lc_new_divsn_success = 'N' THEN
                                             
               ln_error_count := ln_error_count + 1;
                                        
             END IF; -- lc_new_divsn_success = 'Y'
                          
         END LOOP; -- lt_party_sites.FIRST .. lt_party_sites.LAST
         
       END IF; -- lt_party_sites.COUNT <> 0
                          
       EXIT WHEN lcu_party_sites%NOTFOUND;
       
   END LOOP; -- lcu_party_sites
                      
   CLOSE lcu_party_sites;
   
   IF ln_total_count = 0 THEN
        
     lc_error_message := NULL;
                                                            
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0170_NO_RECORDS');
     lc_error_message := FND_MESSAGE.GET;
     WRITE_LOG(lc_error_message);
     XX_COM_ERROR_LOG_PUB.log_error_crm(
                                        p_return_code               => FND_API.G_RET_STS_ERROR
                                        , p_application_name        => G_APPLICATION_NAME
                                        , p_program_type            => G_PROGRAM_TYPE
                                        , p_program_name            => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                        , p_program_id              => gn_program_id
                                        , p_module_name             => G_MODULE_NAME
                                        , p_error_location          => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                        , p_error_message_code      => 'XX_TM_0170_NO_RECORDS'
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
   
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0133_TOTAL_RECORD_ERR');
   FND_MESSAGE.SET_TOKEN('P_RECORD_ERROR', ln_error_count);
   lc_total_failed    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_failed);
      
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0132_TOTAL_RECORD_SUCC');
   FND_MESSAGE.SET_TOKEN('P_RECORD_SUCCESS', ln_success_count);
   lc_total_success    := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_success);
      
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0146_TOTAL_RECORDS_EXIST');
   FND_MESSAGE.SET_TOKEN('P_RECORD_EXIST', ln_exists_count);
   lc_total_exists  := FND_MESSAGE.GET;
   WRITE_OUT(lc_total_exists);
      
   FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0171_NO_RESOURCE_EXISTS');
   FND_MESSAGE.SET_TOKEN('P_DIVISION', p_division);
   FND_MESSAGE.SET_TOKEN('P_RECORD_COUNT', ln_no_resource_div);
   lc_no_resource  := FND_MESSAGE.GET;
   WRITE_OUT(lc_no_resource);
      
   IF ln_error_count <> 0 THEN
           
     x_retcode := 1;
        
   END IF;   

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error in creating the new division : '||p_division;
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
                                          , p_program_name           => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                          , p_program_id             => gn_program_id 
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE.CHILD_MAIN'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
       
END;
            
END XX_JTF_SLS_REP_NW_DIV_PTY_SITE;     
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
