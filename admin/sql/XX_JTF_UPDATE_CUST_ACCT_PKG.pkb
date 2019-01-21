CREATE OR REPLACE PACKAGE BODY XX_JTF_UPDATE_CUST_ACCT_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_JTF_UPDATE_CUST_ACCT_PKG                                              |
-- | Rice Id      : E0401_TerritoryManager_Qualifiers                                        |
-- | Description  : Custom Package to implement the logic to identify an organization as     |
-- |                Prospect or Customer.                                                    |
-- |                This custom package will be subscribed to two standard business events:  |
-- |                1. oracle.apps.ar.hz.CustAccount.create                                  |
-- |                2. oracle.apps.ar.hz.CustAccount.update                                  |
-- |                Subscription is set at a phase of 1 so as to run synchronously           |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   12-Sep-2007       Nabarun Ghosh    Initial Version                            |
-- |1.1        16-May-2013       Sreedhar Mohan   code for Customer extract in EBS downtime  |                                                                                        |
-- +=========================================================================================+
AS

 --Declaring varibales

 lc_name                  VARCHAR2(240);
 lc_key                   VARCHAR2(240);
 lc_parameter_list        wf_parameter_list_t := wf_parameter_list_t();
 ln_org_id                org_organization_definitions.operating_unit%TYPE;
 ln_user_id 	          fnd_user.user_id%TYPE;
 ln_resp_id 	          fnd_responsibility.responsibility_id%TYPE;
 ln_resp_appl_id          fnd_responsibility.application_id%TYPE;
 ln_security_group_id     PLS_INTEGER;
 ln_cust_account_id       hz_cust_accounts.cust_account_id%TYPE;
 ln_party_id              hz_cust_accounts.party_id%TYPE;
 ln_object_version_number hz_cust_accounts.object_version_number%TYPE;
 ln_profile               NUMBER;
 lc_return_status         VARCHAR2(1);
 ln_msg_count             PLS_INTEGER;
 lc_msg_data              VARCHAR2(4000);
 l_organization_rec       hz_party_v2pub.organization_rec_type;
 l_party_rec		  hz_party_v2pub.party_rec_type;
 lc_organization_name     hz_parties.party_name%TYPE;
 lc_error_message         VARCHAR2(4000);
 lc_update_flag           VARCHAR2(1)   := 'N';



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
      ,p_program_name            => 'XX_JTF_UPDATE_CUST_ACCT_PKG'
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

 PROCEDURE extractBO(
                     p_cust_account_id     IN     NUMBER
                    )
 IS
   ln_organization_id           NUMBER;
   lc_organization_os           hz_orig_sys_references.orig_system%TYPE;
   lc_organization_osr          hz_orig_sys_references.orig_system_reference%TYPE;
   lo_org_cust_obj              HZ_ORG_CUST_BO := HZ_ORG_CUST_BO(null, null,HZ_CUST_ACCT_BO_TBL());
   lc_return_status             VARCHAR2(1);
   ln_msg_count                 NUMBER;   
   lc_msg_data                  VARCHAR2(2000);

   l_hz_org_cust_bo_payload     sys.XMLTYPE;
   l_xx_cdh_acct_ext_bo_payload sys.XMLTYPE; 

 BEGIN
  --get relavent references from account_id
  select party_id,
         'A0',
         orig_system_reference
  into   ln_organization_id, 
         lc_organization_os, 
         lc_organization_osr
  from   hz_cust_accounts
  where  cust_account_id = p_cust_account_id;

  --get org_cust_bo based on the cust_account_id
  HZ_ORG_CUST_BO_PUB.get_org_cust_bo(
    p_init_msg_list       => fnd_api.g_false,
    p_organization_id     => ln_organization_id,
    p_organization_os	  => lc_organization_os,
    p_organization_osr	  => lc_organization_osr,
    x_org_cust_obj        => lo_org_cust_obj,
    x_return_status       => lc_return_status,
    x_msg_count           => ln_msg_count,    
    x_msg_data            => lc_msg_data     
  );

  --get the BO into XML
  l_hz_org_cust_bo_payload     := XMLTYPE(lo_org_cust_obj);
  --l_xx_cdh_acct_ext_bo_payload := XMLTYPE(p_xx_cdh_acct_ext_bo);

  --Dump the payload into database with the interface_status = 1 (inserted) in XX_CDH_CUST_BO_STG table
  insert into XXCRM.XX_CDH_CUST_BO_STG 
  (   BPEL_PROCESS_ID      ,
      ORG_CUST_BO_PAYLOAD  ,
      ACCT_EXT_BO_PAYLOAD  ,
      INTERFACE_STATUS     ,
      ORIG_SYSTEM_REFERENCE, 
      CREATION_DATE        ,
      CREATED_BY           
  ) values
  (
      p_cust_account_id       ,
      l_hz_org_cust_bo_payload,
      null                    ,  --l_xx_cdh_acct_ext_bo_payload,
      1                       ,
      lc_organization_osr     ,
      SYSDATE                 ,
      FND_GLOBAL.user_id          
  );

  commit;

 EXCEPTION
  WHEN OTHERS THEN
    Log_Exception('XX_JTF_UPDATE_CUST_ACCT_PKG.EXTRACTBO', 'EXTRACTBO_ERROR' , SQLERRM);
 END extractBO;

 FUNCTION Update_Party_Status(p_subscription_guid  IN             RAW,
                              p_event              IN OUT NOCOPY  WF_EVENT_T)
 RETURN VARCHAR2
 -- +===================================================================+
 -- | Name         : Update_Party_Status                                |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  |
 -- | Description  : This Function will be updating the Attribute       |
 -- |                which will identify the account as Prospect or     |
 -- |                Customer at the account level based on the         |
 -- |                status Inactive or Active.                         |
 -- | Parameters                                                        |
 -- | IN        :        p_subscription_guid                            |
 -- |                    p_event                                        |
 -- | Returns   :        SUCCESS / ERROR                                |
 -- +===================================================================+
 AS

   --Declaring local variable
   ln_count            PLS_INTEGER;
   lc_message          VARCHAR2(4000);

 BEGIN

   lc_name             := p_event.geteventname;
   lc_key              := p_event.geteventkey;
   lc_parameter_list   := p_event.getparameterlist;

   --Obtaining the event parameter values
   ln_org_id            := p_event.GetValueForParameter('ORG_ID');
   ln_user_id           := p_event.GetValueForParameter('USER_ID');
   ln_resp_id           := p_event.GetValueForParameter('RESP_ID');
   ln_resp_appl_id      := p_event.GetValueForParameter('RESP_APPL_ID');
   ln_security_group_id := p_event.GetValueForParameter('SECURITY_GROUP_ID');

   --Initializing the application environment
   fnd_global.apps_initialize (ln_user_id, ln_resp_id, ln_resp_appl_id, ln_security_group_id);

   --Obtaining the event parameter value of the Customer Account
   ln_cust_account_id   := p_event.GetValueForParameter('CUST_ACCOUNT_ID');

   extractBO(ln_cust_account_id);

      --Obtaining the party id of this cust account
      SELECT party_id
      INTO   ln_party_id
      FROM   hz_cust_accounts
      WHERE  cust_account_id = ln_cust_account_id;

      SELECT object_version_number
            ,party_name
      INTO   ln_object_version_number
            ,lc_organization_name
      FROM   hz_parties
      WHERE  party_id = ln_party_id;
      
      l_party_rec.party_id                 := ln_party_id;
      l_organization_rec.organization_name := lc_organization_name;

      --Validating the account status
      ln_count                   :=  0 ;
      lc_update_flag             := 'N';
      SELECT COUNT(1)
      INTO   ln_count
      FROM   hz_cust_accounts HCA
            ,hz_parties       PARTY
      WHERE PARTY.party_id      = ln_party_id
      AND   HCA.party_id        = PARTY.party_id
      AND   HCA.status          = 'A';

      IF ln_count = 0 THEN
         ln_count := 0;
         SELECT COUNT(1)
         INTO   ln_count
         FROM   hz_parties
         WHERE  party_id  = ln_party_id
         AND    NVL(Attribute13,c_customer_flag) = c_prospect_flag; --c_customer_flag;

         IF ln_count = 0 THEN
            l_party_rec.attribute13    := c_prospect_flag;
            lc_update_flag             := 'Y';
         END IF;

      ELSE
         ln_count := 0;
         --Validating if the Party is updated as Prospect where atleast one of the
         --account of this party is still active
         SELECT COUNT(1)
         INTO   ln_count
         FROM   hz_parties
         WHERE  party_id  = ln_party_id
         AND    NVL(Attribute13,c_prospect_flag) = c_customer_flag; -- c_prospect_flag;

         IF ln_count = 0 THEN
            l_party_rec.attribute13    := c_customer_flag;
            lc_update_flag             := 'Y';
         END IF;

      END IF;

      IF lc_update_flag   = 'Y' THEN
        --Calling the internal procedure to update party
        Update_Party(
                     p_party_rec              => l_party_rec
                    ,p_object_version_number  => ln_object_version_number
                    ,p_profile                => ln_profile
                    ,x_return_status          => lc_return_status
                    ,x_msg_count              => ln_msg_count
                    ,x_msg_data               => lc_msg_data
                   );


        IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

          IF ln_msg_count = 1 THEN
            lc_msg_data    :=  'Error due to: '||lc_msg_data;

            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0075_UPD_PARTY_API_FAILS');
            lc_error_message     :=  'XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status. API Fails due to '||lc_msg_data;
            FND_MESSAGE.SET_TOKEN('MESSAGE', lc_error_message);

            lc_message := FND_MESSAGE.GET;
            Log_Exception ( p_error_location     =>  'Update_Party_Status'
                           ,p_error_message_code =>  'XX_TM_0075_UPD_PARTY_API_FAILS'
                           ,p_error_msg          =>  lc_message
                          );

          ELSE
           lc_msg_data    :=   NULL;
           FOR l_index IN 1..ln_msg_count
           LOOP
             lc_msg_data    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => l_index
                                                       ,p_encoded => FND_API.G_FALSE),1,255);

             --Log Exception
             ---------------
             FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0075_UPD_PARTY_API_FAILS');
             lc_error_message     :=  'XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status. API Fails due to '||lc_msg_data;
             FND_MESSAGE.SET_TOKEN('MESSAGE', lc_error_message);

             lc_message := FND_MESSAGE.GET;
             Log_Exception ( p_error_location     =>  'Update_Party_Status'
                            ,p_error_message_code =>  'XX_TM_0075_UPD_PARTY_API_FAILS'
                            ,p_error_msg          =>  lc_message
                           );
           END LOOP;
          END IF;

          RETURN 'FAILURE';

        ELSE
          RETURN 'SUCCESS';
        END IF;

      END IF;

 EXCEPTION
   WHEN OTHERS THEN
     WF_CORE.CONTEXT('XX_JTF_UPDATE_CUST_ACCT_PKG', 'Update_Party_Status', p_event.getEventName(), p_subscription_guid);
     WF_EVENT.setErrorInfo(p_event, 'ERROR');

     --Log Exception
     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_JTF_UPDATE_CUST_ACCT_PKG.Update_Party_Status: Unexpected Error in oracle.apps.ar.hz.CustAccount.update. ';
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

     RETURN 'ERROR';
 END Update_Party_Status;

 PROCEDURE Update_Party(
                         p_party_rec              IN  hz_party_v2pub.party_rec_type
                        ,p_object_version_number  IN  hz_parties.object_version_number%TYPE
                        ,p_profile                IN  PLS_INTEGER
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
  --pragma autonomous_transaction;
  lc_message                   VARCHAR2(4000);

 BEGIN

   --Calling the standard API to update Party details in Hz_Parties
   l_organization_rec.party_rec         := p_party_rec;
   ln_object_version_number             := p_object_version_number;
   ln_profile                           := p_profile;

   HZ_PARTY_V2PUB.update_organization (
        p_init_msg_list                 => FND_API.G_TRUE,
        p_organization_rec              => l_organization_rec,
        p_party_object_version_number   => ln_object_version_number,
        x_profile_id                    => ln_profile,
        x_return_status                 => x_return_status,
        x_msg_count                     => x_msg_count ,
        x_msg_data                      => x_msg_data
   ) ;

   IF x_return_status = 'S' THEN
      COMMIT;
   END IF;


 EXCEPTION
   WHEN OTHERS THEN

     ---------------
     lc_return_status := FND_API.G_RET_STS_ERROR;
     FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
     lc_error_message     :=  'In Procedure:XX_JTF_UPDATE_CUST_ACCT_PKG.UPDATE_PARTY API: Unexpected Error in oracle.apps.ar.hz.CustAccount.update: ';
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

END XX_JTF_UPDATE_CUST_ACCT_PKG;
/
SHOW ERRORS;
--EXIT; 
