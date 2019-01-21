SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

CREATE OR REPLACE PACKAGE XX_JTF_UPDATE_CUST_ACCOUNT_PKG
-- +=====================================================================================+
-- |                        Office Depot - Project Simplify                              |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                   |
-- +=====================================================================================+
-- | Name         : XX_JTF_UPDATE_CUST_ACCOUNT_PKG                                       |
-- | Rice Id      : E0401_TerritoryManager_Qualifiers                                    | 
-- | Description  : Custom Package to implement the logic to identify an organization as |
-- |                Prospect or Customer.                                                |
-- |                This custom package will be registered as concurrent program.        |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version    Date              Author           Remarks                                | 
-- |=======    ==========        =============    =======================                |
-- |DRAFT 1A   28-Sep-2007       Nabarun Ghosh    Initial Version                        |
-- |                                                                                     |
-- +=====================================================================================+
AS 

 c_customer_flag  CONSTANT  VARCHAR2(15) := 'CUSTOMER';
 c_prospect_flag  CONSTANT  VARCHAR2(15) := 'PROSPECT';
 
 --Declaring a record, which contains the party details 
 
 TYPE xxcrm_hz_parties_t IS RECORD 
                  (  party_id              NUMBER(20)
                    ,party_name            VARCHAR2(2000)
                    ,object_version_number NUMBER(20)
                    ,attribute13           VARCHAR2(2000)
                    ,party_type            VARCHAR2(2000)
                    ,person_first_name     VARCHAR2(2000)
                    ,person_last_name      VARCHAR2(2000)
                   );
 
 TYPE xxcrm_pipelines_tbl     IS TABLE OF xx_jtf_update_cust_account_pkg.xxcrm_hz_parties_t; 
 TYPE xxcrm_incoming_data_ntt IS TABLE OF xx_jtf_update_cust_account_pkg.xxcrm_hz_parties_t;     
 v_incoming                   xxcrm_incoming_data_ntt; 
 v_outgoing                   xx_jtf_update_cust_account_pkg.xxcrm_hz_parties_t;
 
 
 -- +===================================================================+
 -- | Name  : Update_Party_Status                                       |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description  : This Procedure will be loop through all the account|
 -- |                updating the Attribute which will identify the     |
 -- |                account as Prospect or Customer at the account     |
 -- |                level based on the status Inactive or Active.      |  
 -- +===================================================================+   
 PROCEDURE Update_Party_Status(x_errbuf        OUT NOCOPY  VARCHAR2
                              ,x_retcode       OUT NOCOPY  NUMBER
                              ) ;
 
 -- +===================================================================+
 -- | Name  : Update_Party                                              |
 -- | Rice Id      : E0401_TerritoryManager_Qualifiers                  | 
 -- | Description:       This Procedure will call the standard API to   |
 -- |                    HZ_PARTY_V2PUB to update HZ_PARTIES.Attribute13|   
 -- +===================================================================+  
 PROCEDURE Update_Party( 
                         p_party_rec              IN  hz_party_v2pub.party_rec_type
                        ,p_object_version_number  IN  hz_parties.object_version_number%TYPE
                        ,p_party_type             IN  VARCHAR2
                        ,x_return_status          OUT NOCOPY VARCHAR2
                        ,x_msg_count              OUT NOCOPY PLS_INTEGER
                        ,x_msg_data               OUT NOCOPY VARCHAR2
                       );


 
 FUNCTION Pipelined_Party_Details (
                                    cursor_in IN SYS_REFCURSOR
                                  ) RETURN xx_jtf_update_cust_account_pkg.xxcrm_pipelines_tbl
                                  PIPELINED
                                  PARALLEL_ENABLE (PARTITION cursor_in BY ANY) ;


END XX_JTF_UPDATE_CUST_ACCOUNT_PKG;
/
SHOW ERRORS;
--EXIT; 