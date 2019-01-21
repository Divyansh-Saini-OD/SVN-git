SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_UPDATE_CUST_ACCT_PKG
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
-- |                                                                                         |
-- +=========================================================================================+
AS 

 c_customer_flag  CONSTANT  VARCHAR2(15) := 'CUSTOMER';
 c_prospect_flag  CONSTANT  VARCHAR2(15) := 'PROSPECT';


 -- +===================================================================+
 -- | Name  : Update_Party_Status                                       |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description:       This Function will be updating the Attribute   |
 -- |                    which will identify the account as Prospect or |
 -- |                    Customer at the account level based on the     |
 -- |                    status Inactive or Active.                     |  
 -- +===================================================================+   
 FUNCTION Update_Party_Status(p_subscription_guid  IN             RAW,
                              p_event              IN OUT NOCOPY  WF_EVENT_T) 
 RETURN VARCHAR2;
 
 -- +===================================================================+
 -- | Name  : Update_Party                                              |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description:       This Procedure will call the standard API to   |
 -- |                    HZ_PARTY_V2PUB to update HZ_PARTIES.Attribute13|   
 -- +===================================================================+  
 PROCEDURE Update_Party( 
                         p_party_rec              IN  hz_party_v2pub.party_rec_type
                        ,p_object_version_number  IN  hz_parties.object_version_number%TYPE
                        ,p_profile                IN  PLS_INTEGER
                        ,x_return_status          OUT NOCOPY VARCHAR2
                        ,x_msg_count              OUT NOCOPY PLS_INTEGER
                        ,x_msg_data               OUT NOCOPY VARCHAR2
                       );


END XX_JTF_UPDATE_CUST_ACCT_PKG;
/
SHOW ERRORS;
--EXIT; 