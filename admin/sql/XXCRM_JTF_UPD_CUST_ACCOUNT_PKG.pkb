SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XXCRM_JTF_UPD_CUST_ACCOUNT_PKG
-- +=====================================================================================+
-- |                        Office Depot - Project Simplify                              |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                   |
-- +=====================================================================================+
-- | Name         : XX_JTF_UPDATE_CUST_ACCOUNT_PKG                                       |
-- | Rice Id      : E0401_TerritoryManager_Qualifiers                                    | 
-- | Description  : Custom Package to implement the logic to identify an organization as |
-- |                Prospect or Customer.                                                |
-- |                This custom package will be registered as concurrent program         |
-- |                OD: Update Customer/Prospect Flag                                    |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version    Date              Author           Remarks                                | 
-- |=======    ==========        =============    ========================               |
-- |DRAFT 1A   28-Sep-2007       Nabarun Ghosh    Initial Version                        |
-- |                                                                                     |
-- +=====================================================================================+
AS 

 --Declaring varibales 
 ln_object_version_number hz_cust_accounts.object_version_number%TYPE;
 ln_profile               PLS_INTEGER;
 lc_return_status         VARCHAR2(1);
 ln_msg_count             PLS_INTEGER;
 lc_msg_data              VARCHAR2(4000);
 l_organization_rec       hz_party_v2pub.organization_rec_type;
 l_person_rec             hz_party_v2pub.person_rec_type;
 l_party_rec		  hz_party_v2pub.party_rec_type;
 lc_organization_name     hz_parties.party_name%TYPE;
 lc_error_message         VARCHAR2(4000);
 lc_update_flag           VARCHAR2(1)            := 'N'; 
 gc_conc_prg_id           PLS_INTEGER            := apps.fnd_global.conc_request_id; 
 gn_bulk_limit            NUMBER                 := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),200);
 g_sleep                  CONSTANT PLS_INTEGER   := 60; 

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
      ,p_program_type            => 'E0401_TerritoryManager_Qualifiers'
      ,p_program_name            => 'XX_JTF_UPDATE_CUST_ACCOUNT_PKG'
      ,p_program_id              => gc_conc_prg_id
      ,p_module_name             => 'TM'
      ,p_error_location          => p_error_location
      ,p_error_message_code      => p_error_message_code
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
 
 END Log_Exception;
 
 PROCEDURE Update_Party_Status_Main(x_errbuf        OUT NOCOPY  VARCHAR2
                                    ,x_retcode       OUT NOCOPY  NUMBER
                                    ,p_from_party_id IN  PLS_INTEGER
                                    ,p_to_party_id   IN  PLS_INTEGER
                                    )  
 AS
   ln_worker        PLS_INTEGER := fnd_profile.value('XX_CDH_CONV_WORKERS');
   ln_request_id    PLS_INTEGER := 0;
   EX_SUBMIT_CHILD  EXCEPTION;
   lc_message       VARCHAR2(4000);
   type xxcrm_request_id is table of number index by binary_integer;
   lct_request_id   xxcrm_request_id;
   
   CURSOR lcu_get_party_id (p_request_id IN NUMBER)
   IS
   SELECT NVL(MAX(party_id),0) 
   FROM hz_parties
   WHERE request_id= p_request_id;
   
   ln_party_id      hz_parties.party_id%TYPE  :=0;
   ln_temp_party_id hz_parties.party_id%TYPE  :=0;
   lc_phase         VARCHAR2(1000);
   
 BEGIN
   
    FOR ln_index IN 0..ln_worker-1
    LOOP
        ln_request_id := FND_REQUEST.submit_request(
                                                     application  => 'xxcrm'
                                                    ,program      => 'XXCRMUPDCUSTPROSPECT'
                                                    ,sub_request  => FALSE
                                                    ,argument1    => p_from_party_id
                                                    ,argument2    => p_to_party_id
                                                    ,argument3    => ln_index
                                                   );
        
        IF ln_request_id = 0 THEN
           RAISE EX_SUBMIT_CHILD;
        ELSE
            lct_request_id(ln_index) := ln_request_id; 
            COMMIT;
        END IF; 
    END LOOP;
    
    -- --------------------------------------------------
    -- To check whether the child requests have finished
    -- If not then wait
    -- --------------------------------------------------
    FOR I IN lct_request_id.FIRST .. lct_request_id.LAST
    LOOP
        LOOP
    
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   fnd_concurrent_requests FCR
            WHERE  FCR.request_id = lct_request_id(i);
    
            IF lc_phase = 'C' THEN
               EXIT;
            ELSE
                DBMS_LOCK.SLEEP(G_SLEEP);
            END IF;
        END LOOP;
        
    END LOOP;
    IF p_from_party_id IS NULL THEN
         
      ln_party_id := NVL(FND_PROFILE.VALUE('XXCRM_E401_MAX_PARTY_ID'),0);
      
      FOR I IN lct_request_id.first .. lct_request_id.last
      LOOP
        OPEN lcu_get_party_id(lct_request_id(i));
         FETCH lcu_get_party_id 
         INTO ln_temp_party_id;
        CLOSE lcu_get_party_id;
    
        IF ln_temp_party_id > ln_party_id THEN 
           ln_party_id := ln_temp_party_id;
        END IF;
      END LOOP;
    
      IF FND_PROFILE.SAVE('XXCRM_E401_MAX_PARTY_ID',ln_party_id,'SITE') THEN
         COMMIT;
      END IF;
    
    END IF;
    
 EXCEPTION
    WHEN EX_SUBMIT_CHILD THEN
     x_retcode        := 2;
     lc_error_message := SQLERRM;
     x_errbuf         := lc_error_message;
 
     FND_FILE.put_line(FND_FILE.output, lc_error_message);
     FND_FILE.put_line(FND_FILE.log, lc_error_message);
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'Unexpected Error:Submit failed:XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.Update_Party_Status_Main: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);
                                
     lc_message := FND_MESSAGE.GET;
     Log_Exception ( p_error_location     =>  'Update_Party_Status_Main'
                    ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                    ,p_error_msg          =>  lc_message                      
                );                           

   WHEN OTHERS THEN
     x_retcode        := 2;
     lc_error_message := SQLERRM;
     x_errbuf         := lc_error_message;
 
     FND_FILE.put_line(FND_FILE.output, lc_error_message);
     FND_FILE.put_line(FND_FILE.log, lc_error_message);
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'Unexpected Error:XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.Update_Party_Status_Main: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);
                                
     lc_message := FND_MESSAGE.GET;
     Log_Exception ( p_error_location     =>  'Update_Party_Status_Main'
                    ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                    ,p_error_msg          =>  lc_message                      
                );                           
 END Update_Party_Status_Main;
 
 PROCEDURE Update_Party_Status(x_errbuf        OUT NOCOPY  VARCHAR2
                              ,x_retcode       OUT NOCOPY  NUMBER
                              ,p_from_party_id IN  PLS_INTEGER
                              ,p_to_party_id   IN  PLS_INTEGER
                              ,p_worker        IN  PLS_INTEGER
                              )  
 -- +===================================================================+
 -- | Name         : Update_Party_Status                                |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description  : This Procedure will be loop through all the account|
 -- |                updating the Attribute which will identify the     |
 -- |                account as Prospect or Customer at the account     |
 -- |                level based on the status Inactive or Active.      |  
 -- | Parameters                                                        |
 -- | OUT          :x_errbuf                                            |
 -- |              :x_retcode                                           |
 -- +===================================================================+   
 AS
   
   --Cursor to fetch parties having atleast one Account.    
   CURSOR lcu_get_parties(p_workr_id IN PLS_INTEGER) 
   IS
   SELECT /*+ first_rows(10 */
          HZP.party_id               party_id             
         ,HZP.party_name	     party_name           
         ,HZP.object_version_number  object_version_number
         ,HZP.attribute13	     attribute13 
         ,HZP.party_type             party_type
         ,DECODE(HZP.party_type,'PERSON',HZP.person_first_name,'X') person_first_name
	 ,DECODE(HZP.party_type,'PERSON',HZP.person_last_name,'X')  person_last_name
   FROM   hz_parties         HZP
   WHERE  HZP.party_type IN ('ORGANIZATION','PERSON')
   AND    HZP.party_id BETWEEN p_from_party_id AND p_to_party_id
   AND    MOD(HZP.party_id,p_workr_id) = p_worker
   AND    1=1
   ORDER BY 1; 
   
   CURSOR lcu_get_parties1(p_workr_id             IN PLS_INTEGER 
                          ,p_last_processed_party IN PLS_INTEGER
                          )
   IS
   SELECT /*+ first_rows(10) */
          HZP.party_id               party_id             
         ,HZP.party_name	     party_name           
         ,HZP.object_version_number  object_version_number
         ,HZP.attribute13	     attribute13 
         ,HZP.party_type             party_type
         ,DECODE(HZP.party_type,'PERSON',HZP.person_first_name,'X') person_first_name
	 ,DECODE(HZP.party_type,'PERSON',HZP.person_last_name,'X')  person_last_name
   FROM   hz_parties         HZP
   WHERE  HZP.party_type IN ('ORGANIZATION','PERSON')
   And    HZP.party_id > NVL(p_last_processed_party,0)
   AND    MOD(HZP.party_id,p_workr_id) = p_worker
   AND    1=1
   ORDER BY 1;    

   CURSOR lcu_get_acct_status(p_from_party_id IN hz_parties.party_id%TYPE
                             ,p_to_party_id IN hz_parties.party_id%TYPE) 
   IS
   SELECT PARTY.party_id
         ,HCA.cust_account_id 
         ,HCA.attribute18  
         ,HCA.customer_type
   FROM   hz_cust_accounts HCA
         ,hz_parties       PARTY
   WHERE HCA.party_id     BETWEEN p_from_party_id AND p_to_party_id
   AND   PARTY.party_type IN ('ORGANIZATION','PERSON')
   AND   HCA.party_id        = PARTY.party_id
   AND   HCA.status          = 'A'
   AND   1=1
   ORDER BY 1;

   --Declaring local variable
   ln_count                     PLS_INTEGER;
   
   ln_row                       PLS_INTEGER := 0;
   lc_message                   VARCHAR2(4000);
   ln_row_count                 PLS_INTEGER := 0;  
   
   lc_custom_prospect_flag      VARCHAR2(2000);
   ln_record_processed          PLS_INTEGER := 0;
   ln_min_party_id              PLS_INTEGER := 0;
   ln_max_party_id              PLS_INTEGER := 0;
   
   ln_worker_id                 PLS_INTEGER := fnd_profile.value('XX_CDH_CONV_WORKERS'); 
   ln_last_processed_party   hz_parties.party_id%TYPE := FND_PROFILE.VALUE('XXCRM_E401_MAX_PARTY_ID');

   TYPE xxcrm_hz_acct_tbl IS TABLE OF lcu_get_acct_status%rowtype INDEX BY PLS_INTEGER;
   lt_hz_acct_tbl               xxcrm_hz_acct_tbl;   
   lt_hz_acct_tbl_init          xxcrm_hz_acct_tbl;   
   
   
   ln_total_record_fetched      PLS_INTEGER := 0;  
   ln_total_internal_customers  PLS_INTEGER := 0;
   ln_total_external_customers  PLS_INTEGER := 0;
   ln_total_corrected_records   PLS_INTEGER := 0;
   ln_total_processed_records   PLS_INTEGER := 0;
   
   --Table of the record contains party detail info
   TYPE xxcrm_hz_parties_tbl IS TABLE OF xxcrm_hz_parties_t INDEX BY PLS_INTEGER;
   lt_hz_parties_tbl      xxcrm_hz_parties_tbl;  
   lt_hz_parties_tbl_init xxcrm_hz_parties_tbl;  
   
   
 BEGIN
      
   --Opening the cursor to extract party account details.
   IF p_from_party_id IS NOT NULL THEN 
   
     OPEN lcu_get_parties(
                          ln_worker_id
                         );
   ELSE 
     OPEN lcu_get_parties1(
                           ln_worker_id
                          ,ln_last_processed_party
                          );
   END IF;
   
   LOOP
   IF p_from_party_id IS NOT NULL THEN 
     FETCH lcu_get_parties BULK COLLECT 
     INTO  lt_hz_parties_tbl LIMIT gn_bulk_limit;
   ELSE 
     FETCH lcu_get_parties1 BULK COLLECT 
     INTO  lt_hz_parties_tbl LIMIT gn_bulk_limit;
   END IF;
   
   
     IF lt_hz_parties_tbl.count > 0 THEN
        
        ln_min_party_id  := 0;
        ln_max_party_id  := 0;
        lt_hz_acct_tbl.delete;
        ln_min_party_id  := lt_hz_parties_tbl(lt_hz_parties_tbl.first).party_id;
        ln_max_party_id  := lt_hz_parties_tbl(lt_hz_parties_tbl.last).party_id;
        
        OPEN lcu_get_acct_status(
                                 ln_min_party_id
                                ,ln_max_party_id
                                );
        FETCH lcu_get_acct_status BULK COLLECT
        INTO  lt_hz_acct_tbl;
        CLOSE lcu_get_acct_status;
        
        
        FOR ln_row IN lt_hz_parties_tbl.first..lt_hz_parties_tbl.last
        LOOP
         
         ln_total_record_fetched     := ln_total_record_fetched + 1;
         l_party_rec.party_id        := lt_hz_parties_tbl(ln_row).party_id;
         
         IF lt_hz_parties_tbl(ln_row).party_type = 'ORGANIZATION' THEN
            l_organization_rec.organization_name := lt_hz_parties_tbl(ln_row).party_name;
         ELSIF lt_hz_parties_tbl(ln_row).party_type = 'PERSON' THEN
            l_person_rec.person_first_name := lt_hz_parties_tbl(ln_row).person_first_name;
            l_person_rec.person_last_name  := lt_hz_parties_tbl(ln_row).person_last_name;
         END IF;
              
         --Validating the account status
         lc_update_flag  :='N';
         lc_custom_prospect_flag :='N';
         
         IF lt_hz_acct_tbl.count > 0 THEN
         
             FOR ln_row1 in lt_hz_acct_tbl.first..lt_hz_acct_tbl.last
             LOOP
             
               IF lt_hz_parties_tbl(ln_row).party_id = lt_hz_acct_tbl(ln_row1).party_id 
               AND lt_hz_acct_tbl(ln_row1).customer_type <> 'I' 
               AND NVL(lt_hz_acct_tbl(ln_row1).attribute18,'X') = 'CONTRACT' THEN
               
                  ln_total_external_customers   := ln_total_external_customers + 1;
                  lc_custom_prospect_flag :='Y';
                  EXIT;
                  
               ELSIF lt_hz_parties_tbl(ln_row).party_id = lt_hz_acct_tbl(ln_row1).party_id 
               AND (lt_hz_acct_tbl(ln_row1).customer_type = 'I' 
               OR NVL(lt_hz_acct_tbl(ln_row1).attribute18,'X') <> 'CONTRACT') THEN                  

                  ln_total_internal_customers  := ln_total_internal_customers + 1;
                  lc_custom_prospect_flag := 'I';
                  EXIT;

               END IF;
    
             END LOOP;
             
         END IF;         
         lt_hz_acct_tbl := lt_hz_acct_tbl_init;
         
         IF lc_custom_prospect_flag = 'N' THEN
              IF NVL(lt_hz_parties_tbl(ln_row).attribute13,c_customer_flag) <> c_prospect_flag THEN
                l_party_rec.attribute13    := c_prospect_flag;
                lc_update_flag             := 'Y';
              ELSE                 
		ln_total_corrected_records  := ln_total_corrected_records + 1;
              END IF;
         ELSIF lc_custom_prospect_flag = 'Y' THEN
              --Validating if the Party is updated as Prospect where atleast one of the
              --account of this party is still active
              IF NVL(lt_hz_parties_tbl(ln_row).attribute13,c_prospect_flag) <> c_customer_flag THEN
                l_party_rec.attribute13    := c_customer_flag;
                lc_update_flag             := 'Y';
              ELSE                 
                ln_total_corrected_records  := ln_total_corrected_records + 1;
              END IF;
         END IF;     
           
         IF lc_update_flag   = 'Y' THEN
           
           ln_total_processed_records  := ln_total_processed_records + 1;
           
           --FND_FILE.put_line(FND_FILE.log,'Party Id: '||lt_hz_parties_tbl(ln_row).party_id||'  ::Party Type:: '||lt_hz_parties_tbl(ln_row).party_type||' ::Obj Version#:: '||lt_hz_parties_tbl(ln_row).object_version_number); 
           
           --Calling the internal procedure to update party 
           Update_Party( 
                         p_party_rec              => l_party_rec
                        ,p_object_version_number  => lt_hz_parties_tbl(ln_row).object_version_number
                        ,p_party_type             => lt_hz_parties_tbl(ln_row).party_type
                        ,x_return_status          => lc_return_status
                        ,x_msg_count              => ln_msg_count    
                        ,x_msg_data               => lc_msg_data     
                       );
                  
           IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN 
                lc_msg_data    :=   NULL;
                FOR l_index IN 1..ln_msg_count 
                LOOP
                  lc_msg_data    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                            ,p_encoded => FND_API.G_FALSE),1,255);
                  --Log Exception
                  ---------------
                  FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0075_UPD_PARTY_API_FAILS');
                  lc_error_message     :=  'XX_JTF_UPDATE_CUST_ACCOUNT_PKG.Update_Party_Status. API Fails due to '||lc_msg_data;
                  FND_MESSAGE.SET_TOKEN('MESSAGE', lc_error_message);
    
                  lc_message := FND_MESSAGE.GET;
                  Log_Exception ( p_error_location     =>  'Update_Party_Status'
                                 ,p_error_message_code =>  'XX_TM_0075_UPD_PARTY_API_FAILS'
                                 ,p_error_msg          =>  lc_message                           
                             );
                  --FND_FILE.put_line(FND_FILE.output, 'Failed to update the party:'||lt_hz_parties_tbl(ln_row).party_id||' due to '||lc_error_message);
	          FND_FILE.put_line(FND_FILE.log, lc_error_message);
                                    
                END LOOP;
           END IF;
         END IF;         
              
        END LOOP; -- End of table Loop
      
        lt_hz_parties_tbl := lt_hz_parties_tbl_init;    
      
      
     END IF; -- If table count > 0
   
   IF p_from_party_id IS NOT NULL THEN 
      EXIT WHEN lcu_get_parties%NOTFOUND;
   ELSE
      EXIT WHEN lcu_get_parties1%NOTFOUND;
   END IF;
   
   END LOOP;  -- End of Cursor loop
   
   IF p_from_party_id IS NOT NULL THEN    
     CLOSE lcu_get_parties;
   ELSE
     CLOSE lcu_get_parties1; 
   END IF;
   
   COMMIT;
   
   DBMS_SESSION.free_unused_user_memory;
   
         FND_FILE.put_line(FND_FILE.output, 'Total record fetched in the main cursor: '||lt_hz_parties_tbl.count);
         FND_FILE.put_line(FND_FILE.output, 'Total No Of record Read:'||ln_total_record_fetched);
         FND_FILE.put_line(FND_FILE.output, 'Total No Of record processed:'||ln_total_processed_records);
         FND_FILE.put_line(FND_FILE.output, 'Total No Of record already corrected:'||ln_total_corrected_records);
         FND_FILE.put_line(FND_FILE.output, 'Total No Of internal Customer:'||ln_total_internal_customers);
         FND_FILE.put_line(FND_FILE.output, 'Total No Of external Customer:'||ln_total_external_customers);
 EXCEPTION
   WHEN OTHERS THEN
     x_retcode        := 2;
     lc_error_message := SQLERRM;
     x_errbuf         := lc_error_message;

     FND_FILE.put_line(FND_FILE.output, lc_error_message);
     FND_FILE.put_line(FND_FILE.log, lc_error_message);
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'Unexpected Error:XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.Update_Party_Status: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);
                                
     lc_message := FND_MESSAGE.GET;
     Log_Exception ( p_error_location     =>  'Update_Party_Status'
                    ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                    ,p_error_msg          =>  lc_message                      
                );                           
                                
 END Update_Party_Status;
 
 PROCEDURE Update_Party( 
                         p_party_rec              IN  hz_party_v2pub.party_rec_type
                        ,p_object_version_number  IN  hz_parties.object_version_number%TYPE
                        ,p_party_type             IN  VARCHAR2
                        ,x_return_status          OUT NOCOPY VARCHAR2
                        ,x_msg_count              OUT NOCOPY PLS_INTEGER
                        ,x_msg_data               OUT NOCOPY VARCHAR2
                       )
 -- +===================================================================+
 -- | Name  : Update_Party                                              |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description:       This Procedure will call the standard API to   |
 -- |                    HZ_PARTY_V2PUB to update HZ_PARTIES.Attribute13|  
 -- | Parameters                                                        |
 -- | IN        :        p_party_rec                                    |
 -- |                    p_object_version_number                        |
 -- |                    p_profile                                      |
 -- |                                                                   |
 -- | Returns   :        x_return_status                                |
 -- |                    x_msg_count                                    |
 -- |                    x_msg_data                                     |
 -- +===================================================================+                    
 AS 
 
  lc_message     VARCHAR2(4000);
  ln_profile_id  PLS_INTEGER; 
  
 BEGIN
   FND_MSG_PUB.INITIALIZE;
   --Calling the standard API to update Party details in Hz_Parties
   ln_object_version_number             := p_object_version_number; 
   
   IF p_party_type = 'ORGANIZATION' THEN
   
     l_organization_rec.party_rec         := p_party_rec;   
   
     HZ_PARTY_V2PUB.update_organization (
          p_init_msg_list                 => FND_API.G_FALSE,
          p_organization_rec              => l_organization_rec,
          p_party_object_version_number   => ln_object_version_number,
          x_profile_id                    => ln_profile_id,
          x_return_status                 => x_return_status,
          x_msg_count                     => x_msg_count ,   
          x_msg_data                      => x_msg_data     
     ) ;  
   
   ELSIF p_party_type = 'PERSON' THEN
   
     l_person_rec.party_rec         := p_party_rec;
     
     HZ_PARTY_V2PUB.update_person (
         p_init_msg_list                    => FND_API.G_FALSE,
         p_person_rec                       => l_person_rec,
         p_party_object_version_number      => ln_object_version_number,
         x_profile_id                       => ln_profile_id,
         x_return_status                    => x_return_status,
         x_msg_count                        => x_msg_count ,   
         x_msg_data                         => x_msg_data     
     ) ;
   END IF;
   
 EXCEPTION
   WHEN OTHERS THEN

     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'Unexpected Error:XXCRM_JTF_UPD_CUST_ACCOUNT_PKG.UPDATE_PARTY API: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);

     lc_message := FND_MESSAGE.GET;
     Log_Exception ( p_error_location     =>  'Update_Party'
                    ,p_error_message_code =>  'XX_TM_0007_UNEXPECTED_ERR'
                    ,p_error_msg          =>  lc_message                      
                );

     x_return_status := FND_API.G_RET_STS_ERROR;
     x_msg_count     :=  1 ; 
     x_msg_data      :=  'Unexpected Error:'||SQLERRM;
     
 END Update_Party;
 
END XXCRM_JTF_UPD_CUST_ACCOUNT_PKG;
/
SHOW ERRORS;
--EXIT; 