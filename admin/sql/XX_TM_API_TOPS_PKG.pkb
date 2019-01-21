SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_TM_API_TOPS_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_API_TOPS_PKG.pkb                                                    |
-- | Description : Package Body to perform perform the reassignment of resource,role         |
-- |               and group on the basis of territory ID.                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   12-Mar-2008       Piyush Khandelwal     Initial draft version                 |
-- |DRAFT 1b   18-Mar-2008       Piyush Khandelwal     Incorporated Code review comments.    |
-- +=========================================================================================+
AS

G_ERRBUF     VARCHAR2(2000);

-- +================================================================================+
-- | Name        :  Log_Exception                                                   |
-- | Description :  This procedure is used to log any exceptions raised using custom|
-- |                Error Handling Framework                                        |
-- +================================================================================+
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'Wrapper API for TOPS'
     ,p_program_name            => 'XX_TM_API_TOPS_PKG.main_proc'
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     ,p_program_id              => G_REQUEST_ID
     );

END Log_Exception;

--------------------------------------------------------------------------------------------
  -- Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                              --
  --------------------------------------------------------------------------------------------

  PROCEDURE MAIN_PROC(X_ERRBUF  OUT NOCOPY VARCHAR2,
                      X_RETCODE OUT NOCOPY NUMBER
                      )
  -- +===================================================================+
    -- | Name       : MAIN_PROC                                            |
    -- | Description: *** See above ***                                    |
    -- |                                                                   |
    -- | Parameters : No Input Parameters                                  |
    -- |                                                                   |
    -- | Returns    : Standard Out parameters of a concurrent program      |
    -- |                                                                   |
    -- +===================================================================+
   IS
    lc_error_code       VARCHAR2(10)  ;
    lc_error_message    VARCHAR2(4000);
    ln_total_rec_cnt    NUMBER := 0;
    ln_total_err_cnt    NUMBER := 0;
    ln_counter_site     NUMBER := 0;
    ln_total_site_cnt   NUMBER := 0;
    ln_site_err_cnt     NUMBER := 0;
    ln_bulk_count       NUMBER := 0; 
    ln_bulk_terr_id     NUMBER ;
    ln_api_v            NUMBER  := 1.0; 
    ln_terr_count       NUMBER;
    ln_terr_id          NUMBER; 
    ln_counter          NUMBER;
    lc_status           VARCHAR(10) ;
    lc_status_message   VARCHAR(4000) ;  
    lc_flag             VARCHAR(1) := Null ; 
    lc_eligible_flag    VARCHAR(1);
   
    
    -- Cursor to fetch count of records from TOPS table
    
     CURSOR   LCU_GET_TPS_CNT IS
    
     SELECT   COUNT(TED.named_acct_terr_id) terr_cnt
             ,TED.named_acct_terr_id
     FROM     xx_tm_nam_terr_entity_dtls TED
     WHERE    TED.entity_type='PARTY_SITE'
     AND     EXISTS  (SELECT  1
                      FROM xxtps_site_requests TSR
              WHERE  TSR.request_status_code = 'QUEUED'
              AND    TSR.effective_date <= (sysdate + 1) - 1 / 24
              AND    TSR.terr_rec_id = TED.named_acct_terr_entity_id
             )
     GROUP BY TED.named_acct_terr_id
     ORDER BY TED.named_acct_terr_id;    
     
     -- Cursor to fetch count of records from custom territory table
     
     CURSOR LCU_GET_TERR_CNT(p_acct_terr_id NUMBER) IS
    
     SELECT COUNT(terr.named_acct_terr_id), 
             terr.named_acct_terr_id
     FROM XX_TM_NAM_TERR_DEFN        TERR,
          XX_TM_NAM_TERR_ENTITY_DTLS TERR_ENT,
          XX_TM_NAM_TERR_RSC_DTLS    TERR_RSC
     WHERE TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID
     AND TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID
     AND TERR_ENT.ENTITY_TYPE = 'PARTY_SITE'
     AND terr.named_acct_terr_id = p_acct_terr_id
     GROUP BY terr.named_acct_terr_id;
    
     -- Cursor to fetch the entity id based on accnt_terr_id
     
     CURSOR LCU_GET_RES_DTLS (p_acct_terr_id NUMBER)IS

     SELECT   TSR.from_resource_id
	           ,TSR.to_resource_id
      	     ,TSR.from_group_id
      	     ,TSR.to_group_id
      	     ,TSR.from_role_id
      	     ,TSR.to_role_id
      	     ,TED.entity_type
      	     ,TSR.party_site_id
             ,TSR.site_request_id
      FROM  xxtps_site_requests TSR,
            xx_tm_nam_terr_entity_dtls TED      
      WHERE TSR.request_status_code = 'QUEUED'
      AND   TSR.effective_date <= (sysdate + 1) - 1 / 24
      AND   TED. entity_type='PARTY_SITE'    
      AND   TSR.terr_rec_id=TED.named_acct_terr_entity_id   
      AND   TED.named_acct_terr_id = p_acct_terr_id;
            
    
   BEGIN ---Main block
     
     lc_flag :='N';--To check if count is zero
     
     FOR lr_blk_tps IN LCU_GET_TPS_CNT LOOP--Main Loop
   
    -- Re-initialize the local variables
       ln_bulk_count   := 0;
       ln_bulk_terr_id := 0;
       ln_terr_count   := 0;
       ln_terr_id      := 0;
       ln_bulk_count   := lr_blk_tps.terr_cnt;
       ln_bulk_terr_id := lr_blk_tps.named_acct_terr_id;
       lc_flag         := 'Y';
       lc_eligible_flag := 'Y';
               
       OPEN   LCU_GET_TERR_CNT(ln_bulk_terr_id);
       FETCH  LCU_GET_TERR_CNT INTO ln_terr_count,ln_terr_id;
       CLOSE  LCU_GET_TERR_CNT;      
                
              
       IF ln_bulk_count > 0 AND ln_bulk_count = ln_terr_count   
      
       THEN
            ln_counter :=0;
            ln_total_err_cnt :=0;
            FOR lr_blk_rsc IN LCU_GET_RES_DTLS (ln_bulk_terr_id )--Open LCU_GET_RES_DTLS
             LOOP
                   
                    ln_counter :=ln_counter+1;
                    IF ln_counter =1 THEN   --checking counter
                            
                      IF lr_blk_tps.named_acct_terr_id IS NULL  THEN          
                         FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0255_FRM_TERR_NT_EXIST');
                         FND_MESSAGE.SET_TOKEN('SQLERR', lr_blk_rsc.party_site_id); 
                         lc_eligible_flag :='N';
                         lc_status := null;
                         lc_status := 'ERROR';
                         lc_status_message:= FND_MESSAGE.GET;
                      END IF;    
                       
                       IF lc_eligible_flag = 'Y' THEN
                       /*For Bulk Assignments Call Move_Resource_Territories API*/
                         
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
                         APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                                   'Calling Move_Resource_Territories with named_acct_terr_id : ' ||
                                                   lr_blk_tps.named_acct_terr_id || ' From Resource Id: ' ||
                                                   lr_blk_rsc.from_resource_id || ' From Role Id: ' ||
                                                   lr_blk_rsc.from_role_id || ' From Group Id: ' ||
                                                   lr_blk_rsc.from_group_id);
                                                               
                         XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Resource_Territories
                              			(
                              			  p_api_version_number       => ln_api_v
                              			 ,p_from_named_acct_terr_id  => lr_blk_tps.named_acct_terr_id
                              			 ,p_from_start_date_active   => SYSDATE
                              			 ,p_from_resource_id         => lr_blk_rsc.from_resource_id
                              			 ,p_to_resource_id           => lr_blk_rsc.to_resource_id
                              			 ,p_from_role_id             => lr_blk_rsc.from_role_id
                              			 ,p_to_role_id               => lr_blk_rsc.to_role_id
                              			 ,p_from_group_id            => lr_blk_rsc.from_group_id
                              			 ,p_to_group_id              => lr_blk_rsc.to_group_id
                              			 ,x_error_code               => lc_error_code
                              			 ,x_error_message            => lc_error_message
                                 		 );
                                      
                                                       
                                        IF     lc_error_code = 'S' THEN   --Checking API error status
                                               lc_status := null;
                                               lc_status := 'COMPLETED';
                                               lc_status_message := null;
                                               lc_status_message := lc_error_message;
                                                                
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Move_Resource_Territories Status Completed Successfully : ' || lc_error_code);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                       
                                        ELSIF  lc_error_code <> 'S' THEN
                                               lc_status := null;
                                               lc_status := 'ERROR';
                                               lc_status_message :=null;
                                               lc_status_message := lc_error_message;
                                               
                                               
                                               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR Message :'||lc_error_message);
                                               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :' ||lc_error_code);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                               X_RETCODE := 1;
                                  
                                                Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                                               ,p_error_message_code =>  lc_error_code
                                                               ,p_error_msg          =>  lc_error_message
                                                              );
                                              
                                        END IF;  ---Checking API error status    
                     END IF;
                    END IF;--End Counter      
                         
                                  
                         BEGIN  ---Updating record status 
                                                 
                         UPDATE xxtps_site_requests 
                         SET    request_status_code = lc_status,
                                reject_reason = lc_status_message ,
                                program_id = G_REQUEST_ID,
                                last_update_date = sysdate                          
                         WHERE  request_status_code = 'QUEUED' 
                         AND    site_request_id = lr_blk_rsc.site_request_id;
                         
                         EXCEPTION
                          WHEN OTHERS THEN
                             G_ERRBUF  := null;
                             APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in UPDATING request_status_code for xxtps_site_requests for Move_Resource_Territories  - ' ||SQLERRM);
                             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0253_MAIN_PRG_ERRR');
                             FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
                             G_ERRBUF  := FND_MESSAGE.GET;
                             X_RETCODE := 2;
                                                       
                             Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                            ,p_error_message_code =>  'XX_TM_0253_MAIN_PRG_ERR'
                                            ,p_error_msg          =>  G_ERRBUF
                                           );                        
                             
                            
                         END;   ---Updating record status 
                    
                    ln_total_rec_cnt:=ln_counter;
                    
                    IF  lc_status = 'ERROR' THEN
                    ln_total_err_cnt := ln_total_err_cnt +1;
                    END IF;
                             
            END LOOP;--Close LCU_GET_RES_DTLS
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record Count For Move_Resource_Territories :' ||ln_total_rec_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Errored Out For Move_Resource_Territories :' ||ln_total_err_cnt);
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Processed Successfully For Move_Resource_Territories :' ||TO_CHAR(ln_total_rec_cnt - ln_total_err_cnt) );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
            APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
            
       END IF; ---End Of Bulk_Cnt condition
    
       IF    ln_bulk_count > 0 AND ln_bulk_count < ln_terr_count    THEN  ---Check for condition to call Move_Party_Sites
                    
             ln_counter_site :=0;
             ln_site_err_cnt :=0;   
             
                        
             FOR lr_blk_rsc IN LCU_GET_RES_DTLS (lr_blk_tps.named_acct_terr_id )  --Loop to call Move_Party_Sites
             LOOP
                    ln_counter_site := ln_counter_site+1;
                    
                    APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,
                                                   'Calling Move_Party_Sites with from_named_acct_terr_id : ' ||
                                                   lr_blk_tps.named_acct_terr_id ||' From Resource Id: ' ||
                                                   lr_blk_rsc.from_resource_id || ' Party Site Id: ' ||
                                                   lr_blk_rsc.party_site_id || ' From Group Id: ' ||
                                                   lr_blk_rsc.from_group_id);
                                             
                    XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Party_Sites
                                 (
                                   p_api_version_number       =>  ln_api_v
                                  ,p_from_named_acct_terr_id  =>  lr_blk_tps.named_acct_terr_id
                                  ,p_to_named_acct_terr_id    =>  NULL
                            	    ,p_from_start_date_active   =>  SYSDATE
                            	    ,p_to_start_date_active     =>  NULL
                            	    ,p_from_resource_id         =>  lr_blk_rsc.from_resource_id
                            	    ,p_to_resource_id           =>  lr_blk_rsc.to_resource_id
                            	    ,p_from_role_id             =>  lr_blk_rsc.from_role_id
                            	    ,p_to_role_id               =>  lr_blk_rsc.to_role_id
                                  ,p_from_group_id            =>  lr_blk_rsc.from_group_id
                                  ,p_to_group_id              =>  lr_blk_rsc.to_group_id
                                  ,p_entity_type              =>  lr_blk_rsc.entity_type
                                  ,p_entity_id                =>  lr_blk_rsc.party_site_id
                                  ,x_error_code               =>  lc_error_code
                                  ,x_error_message            =>  lc_error_message
                                 );
        
                                       IF      lc_error_code = 'S' THEN   --Checking API error status
                                               lc_status         := null;
                                               lc_status         := 'COMPLETED';
                                               lc_status_message := null;
                                               lc_status_message := lc_error_message;
                                               
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Move_Party_Sites Completed Successfully : ' || lc_error_code);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
             
                                        ELSIF  lc_error_code <> 'S' THEN --OR lc_error_code IS NULL THEN
                                               lc_status         := null;
                                               lc_status         := 'ERROR';
                                               lc_status_message := null;
                                               lc_status_message := lc_error_message;
                                               ln_site_err_cnt   := ln_site_err_cnt + 1; 
                                               
                                               APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,lc_error_message);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR CODE :'||lc_error_code);
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                               APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'                                                                    ');
                                              
                                               X_RETCODE := 1;
                                  
                                               Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                                              ,p_error_message_code =>  lc_error_code
                                                              ,p_error_msg          =>  lc_error_message
                                                             );      
                                              
         	                             END IF;  
                                             
                         BEGIN
                         UPDATE xxtps_site_requests 
                         SET    request_status_code = lc_status,
                                reject_reason = lc_status_message,
                                program_id = G_REQUEST_ID,
                                last_update_date = sysdate          
                         WHERE  request_status_code = 'QUEUED' 
                         AND    site_request_id = lr_blk_rsc.site_request_id;
                        
                         EXCEPTION
                          WHEN OTHERS THEN
                             G_ERRBUF  := null;
                             APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,'Unexpected error in UPDATING request_status_code for xxtps_site_requests for Move_Party_Sites  - ' ||SQLERRM);
                             FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0254_MAIN_PRG_ERR');
                             FND_MESSAGE.SET_TOKEN('SQLERR', SQLERRM);
                             G_ERRBUF  := FND_MESSAGE.GET;
                             X_RETCODE := 2;
                             
                             Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                                            ,p_error_message_code =>  'XX_TM_0254_MAIN_PRG_ERR'
                                            ,p_error_msg          =>  G_ERRBUF
                                           );    
    
                         END;
                       ln_total_site_cnt := ln_counter_site; 
                                                 
        END LOOP;   --Loop to call Move_Party_Sites
         
          IF ln_counter_site =0 THEN 
          G_ERRBUF := null;
          FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0252_NOREC_TO_PROCESS');
          G_ERRBUF := FND_MESSAGE.GET;
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, G_ERRBUF);
          APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'REQUEST_ID :' || G_REQUEST_ID);
        
         Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                        ,p_error_message_code =>  'XX_TM_0252_NOREC_TO_PROCESS'
                        ,p_error_msg          =>  G_ERRBUF
                       );   
           
           END IF;
    	  APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record Count For Move_Party_Sites :' ||ln_total_site_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Errored Out For Move_Party_Sites :' ||ln_site_err_cnt);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Records Processed Successfully For Move_Party_Sites :' ||TO_CHAR(ln_total_site_cnt - ln_site_err_cnt) ); 
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------------------------------------' );   
        END IF;   ---Check for condition to call Move_Party_Sites
       
     
     END LOOP;--End Of Main Loop
     
     IF    lc_flag = 'N' THEN  --checking if count=0
   
        G_ERRBUF := null;
        FND_MESSAGE.SET_NAME('XXCRM', 'XX_TM_0252_NOREC_TO_PROCESS');
        G_ERRBUF := FND_MESSAGE.GET;
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, G_ERRBUF);
        APPS.FND_FILE.PUT_LINE(FND_FILE.LOG, 'REQUEST_ID :' || G_REQUEST_ID);
              
        Log_Exception ( p_error_location     =>  'XX_TM_API_TOPS_PKG.main_proc'
                       ,p_error_message_code =>  'XX_TM_0252_NOREC_TO_PROCESS'
                       ,p_error_msg          => G_ERRBUF
                      );   
 
  END IF;
   COMMIT;
   END MAIN_PROC ;  ---End of main procrdure
END XX_TM_API_TOPS_PKG;

/
SHOW ERRORS;
EXIT;
