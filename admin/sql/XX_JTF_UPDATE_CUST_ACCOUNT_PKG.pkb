SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_JTF_UPDATE_CUST_ACCOUNT_PKG
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
 lc_update_flag           VARCHAR2(1)   := 'N'; 
 gc_conc_prg_id           PLS_INTEGER         := apps.fnd_global.conc_request_id;  

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
 
 FUNCTION Pipelined_Party_Details (
                                    cursor_in IN SYS_REFCURSOR
                                  ) RETURN xx_jtf_update_cust_account_pkg.xxcrm_pipelines_tbl
                                  PIPELINED
                                  PARALLEL_ENABLE (PARTITION cursor_in BY ANY) 
 IS
     ln_limit                     PLS_INTEGER := 200;
    
 BEGIN
    
    LOOP
    
       FETCH cursor_in BULK COLLECT 
       INTO xx_jtf_update_cust_account_pkg.v_incoming 
       LIMIT ln_limit;
    
       FOR i IN 1 .. v_incoming.COUNT 
       LOOP
       
         xx_jtf_update_cust_account_pkg.v_outgoing.party_id             :=  xx_jtf_update_cust_account_pkg.v_incoming(i).party_id             ;
         xx_jtf_update_cust_account_pkg.v_outgoing.party_name           :=  xx_jtf_update_cust_account_pkg.v_incoming(i).party_name           ;
         xx_jtf_update_cust_account_pkg.v_outgoing.object_version_number:=  xx_jtf_update_cust_account_pkg.v_incoming(i).object_version_number;
         xx_jtf_update_cust_account_pkg.v_outgoing.attribute13          :=  xx_jtf_update_cust_account_pkg.v_incoming(i).attribute13          ;
         xx_jtf_update_cust_account_pkg.v_outgoing.party_type           :=  xx_jtf_update_cust_account_pkg.v_incoming(i).party_type           ;
         xx_jtf_update_cust_account_pkg.v_outgoing.person_first_name    :=  xx_jtf_update_cust_account_pkg.v_incoming(i).person_first_name    ;
         xx_jtf_update_cust_account_pkg.v_outgoing.person_last_name     :=  xx_jtf_update_cust_account_pkg.v_incoming(i).person_last_name     ;                                                                       
    
         PIPE ROW (xx_jtf_update_cust_account_pkg.v_outgoing);
    
       END LOOP;
    
          EXIT WHEN cursor_in%NOTFOUND;
    
    END LOOP;
    CLOSE cursor_in;
    
    RETURN;
 
 END Pipelined_Party_Details;

 
 PROCEDURE Update_Party_Status(x_errbuf  OUT NOCOPY  VARCHAR2
                              ,x_retcode OUT NOCOPY  NUMBER)  
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
   
   --Declaring local variable
   ln_count            PLS_INTEGER;
   
   --Cursor to fetch parties having atleast one Account.    
   CURSOR lcu_get_parties IS      
   SELECT   pe.party_id             
          , pe.party_name           
          , pe.object_version_number
          , pe.attribute13 
    	  , pe.party_type
          , pe.person_first_name 
          , pe.person_last_name    
    FROM   TABLE(
                  XX_JTF_UPDATE_CUST_ACCOUNT_PKG.Pipelined_Party_Details
                    (                                                  
                      CURSOR (                                                 
                               SELECT /*+ parallel(hzp 5) */                                                 
                      		       HZP.party_id               party_id                                                             
                              	      ,HZP.party_name	          party_name                                                           
                      		      ,HZP.object_version_number  object_version_number                                                
                      		      ,HZP.attribute13	          attribute13                                                 
                      		      ,HZP.party_type             party_type                                                
                      		      ,(CASE HZP.party_type WHEN 'PERSON' THEN HZP.person_first_name ELSE 'X' END) person_first_name                                                
                      		      ,(CASE HZP.party_type WHEN 'PERSON' THEN HZP.person_last_name ELSE 'X' END) person_last_name                                               
                      		FROM   hz_parties         HZP                                                 
                      		WHERE  HZP.party_type IN ('ORGANIZATION','PERSON')                                                
                      		AND    1=1
                              )                                                 
                    )                                                 
                ) PE; 
    
   ln_row                       PLS_INTEGER := 0;
   lc_message                   VARCHAR2(4000);
   ln_row_count                 PLS_INTEGER := 0;  
   ln_limit                     PLS_INTEGER := 200;
   
   TYPE xxcrm_hz_parties_tbl IS TABLE OF xxcrm_hz_parties_t INDEX BY PLS_INTEGER;
   lt_hz_parties_tbl         xxcrm_hz_parties_tbl;
   lt_hz_parties_tbl_init    xxcrm_hz_parties_tbl;
   
   lr_p_party_rec_init   hz_party_v2pub.party_rec_type;

 BEGIN
   
   ln_row_count := 0;
   --Opening the cursor to extract party account details.
   OPEN lcu_get_parties;
   LOOP
   
   FETCH lcu_get_parties BULK COLLECT
   INTO  lt_hz_parties_tbl LIMIT ln_limit;
    
    EXIT WHEN lt_hz_parties_tbl.COUNT = 0;
    
    IF lt_hz_parties_tbl.COUNT > 0 THEN
      
      
      FOR ln_row IN lt_hz_parties_tbl.FIRST..lt_hz_parties_tbl.LAST
      LOOP
       
       ln_row_count                              := ln_row_count+1;       
       l_party_rec.party_id                      := lt_hz_parties_tbl(ln_row).party_id;
       
       IF lt_hz_parties_tbl(ln_row).party_type    = 'ORGANIZATION' THEN
       
          l_organization_rec.organization_name   := lt_hz_parties_tbl(ln_row).party_name;
       
       ELSIF lt_hz_parties_tbl(ln_row).party_type = 'PERSON' THEN
       
          l_person_rec.person_first_name         := lt_hz_parties_tbl(ln_row).person_first_name;
          l_person_rec.person_last_name          := lt_hz_parties_tbl(ln_row).person_last_name;
       
       END IF;
              
       --Validating the account status
       ln_count        := 0;
       lc_update_flag  :='N';
     
       SELECT  COUNT(1)
       INTO    ln_count
       FROM    DUAL
       WHERE   EXISTS ( SELECT 1
       			FROM   hz_cust_accounts HCA
       			      ,hz_parties       PARTY
       			WHERE PARTY.party_id      = lt_hz_parties_tbl(ln_row).party_id
       			AND   HCA.party_id        = PARTY.party_id
       			AND   HCA.status          = 'A'
       		      )	;
       
       IF ln_count = 0 THEN
          IF COALESCE(lt_hz_parties_tbl(ln_row).attribute13,c_customer_flag) <> c_prospect_flag THEN
            l_party_rec.attribute13    := c_prospect_flag;
            lc_update_flag             := 'Y';
          END IF;
       ELSE
          ln_count := 0;
          --Validating if the Party is updated as Prospect where atleast one of the
          --account of this party is still active
          IF COALESCE(lt_hz_parties_tbl(ln_row).attribute13,c_prospect_flag) <> c_customer_flag THEN
            l_party_rec.attribute13    := c_customer_flag;
            lc_update_flag             := 'Y';
          END IF;
       END IF;    
       
       IF lc_update_flag   = 'Y' THEN
         
         --Calling the internal procedure to update party 
         Update_Party( 
                       p_party_rec              => l_party_rec
                      ,p_object_version_number  => lt_hz_parties_tbl(ln_row).object_version_number
                      ,p_party_type             => lt_hz_parties_tbl(ln_row).party_type
                      ,x_return_status          => lc_return_status
                      ,x_msg_count              => ln_msg_count    
                      ,x_msg_data               => lc_msg_data     
                     );
                
         IF COALESCE(lc_return_status,'E') <> FND_API.G_RET_STS_SUCCESS THEN 
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
               
                FND_FILE.put_line(FND_FILE.output, 'Failed to update the party:'||lt_hz_parties_tbl(ln_row).party_id||' due to '||lc_error_message);
	        FND_FILE.put_line(FND_FILE.log, lc_error_message);
                
              END LOOP;
         END IF;
         
       END IF;      
      
       l_party_rec := lr_p_party_rec_init;

      END LOOP; -- End of table Loop
      
    END IF; -- If table count > 0
        
    lt_hz_parties_tbl.delete;
    lt_hz_parties_tbl := lt_hz_parties_tbl_init;
    
    IF MOD(ln_row_count,100000) = 0 THEN 
       COMMIT;
    END IF;
    
   END LOOP;
   CLOSE lcu_get_parties;
   
   DBMS_SESSION.free_unused_user_memory;
   
 EXCEPTION
   WHEN OTHERS THEN
     x_retcode        := 2;
     lc_error_message := SQLERRM;
     x_errbuf         := lc_error_message;
     
     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_JTF_UPDATE_CUST_ACCOUNT_PKG.Update_Party_Status: Unexpected Error: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);
                                
     lc_message := FND_MESSAGE.GET;
     FND_FILE.put_line(FND_FILE.log, lc_message);
     
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
 
  lc_message            VARCHAR2(4000);
  ln_profile_id         PLS_INTEGER; 
  lr_p_party_rec_init   hz_party_v2pub.party_rec_type;
  lr_org_rec_init       hz_party_v2pub.organization_rec_type;
  lr_person_rec_init    hz_party_v2pub.person_rec_type;

 BEGIN
 
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
      
   l_organization_rec.party_rec := lr_p_party_rec_init;   
   l_organization_rec := lr_org_rec_init;
   l_person_rec       := lr_person_rec_init;
   
 EXCEPTION
   WHEN OTHERS THEN
   
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_JTF_UPDATE_CUST_ACCOUNT_PKG.UPDATE_PARTY API: Unexpected Error: ';
     FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_error_message);
     FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
     FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
     -- lc_error_message     := FND_MESSAGE.GET;
     FND_MSG_PUB.add;
     FND_MSG_PUB.count_and_get (p_count => ln_msg_count,
                                p_data  => lc_msg_data);

     lc_message := FND_MESSAGE.GET;

     x_return_status := FND_API.G_RET_STS_ERROR;
     x_msg_count     :=  1 ; 
     x_msg_data      :=  'Unexpected Error in API:'||lc_message;
     
 END Update_Party;
 
END XX_JTF_UPDATE_CUST_ACCOUNT_PKG;
/
SHOW ERRORS;
--EXIT; 