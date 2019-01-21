CREATE OR REPLACE PACKAGE BODY XX_CDHAR_CUST_ELG_PKG
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :xx_cdhar_cust_elg_pkg                                   |
--|RICE        :                                                        |
--|Description :This Package is for identifying eligble customers       |                                                                     |
--|                                                                     |
--|            The STAGING Procedure will perform the following steps   |
--|                                                                     |
--|             1. Identify eligible customers based on business rules  |
--|                 a. All Active Account Billing Customers             |
--|                 b. Customers with open Balance exluding internal    |
--|                                                                     |
--|             2. Insert data into customer eligbility table           |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version    |
--+=====================================================================+
  PROCEDURE find_active_ab_cust_proc (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number,
                                    p_sample_count  in number)
IS
  cust_elg_full cust_elg_tab;
  CURSOR lcu_active_AB_cust IS 
  select 
   hca.PARTY_ID ,
hca.CUST_ACCOUNT_ID,
hca.ACCOUNT_NUMBER  ,
null "site_use_id"  ,
'AB ACTIVE' "int_source",        
null "ORIG_EXTRACTION_DATE",
null "LAST_EXTRACTION_DATE",
null "MASTER_DATA_EXTRACTED",
null "TRANS_DATA_EXTRACTED",
g_LAST_UPDATE_DATE                ,
g_LAST_UPDATED_BY                 ,
g_CREATION_DATE                   ,
g_CREATED_BY                      ,
g_LAST_UPDATE_LOGIN               ,
g_REQUEST_ID                      ,
g_PROGRAM_APPLICATION_ID          ,
g_PROGRAM_ID                      ,
g_PROGRAM_UPDATE_DATE             
FROM hz_customer_profiles hcp
    ,hz_cust_accounts hca
WHERE hcp.status = 'A'
AND hcp.attribute3 = 'Y'
AND hcp.site_use_id is null
AND hcp.cust_account_id = hca.cust_account_id
and rownum <= p_sample_count;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_wcelg_cust';
  
------------------------------------------
--lcu_active_AB_cust cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_active_AB_cust;

      LOOP
         FETCH lcu_active_AB_cust
         BULK COLLECT INTO cust_elg_full LIMIT v_batchlimit;

         FORALL i IN 1 .. cust_elg_full.COUNT 
               INSERT INTO xxcrm_wcelg_cust VALUES cust_elg_full(i);
               COMMIT;
         EXIT WHEN lcu_active_AB_cust%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_active_AB_cust;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;

PROCEDURE find_open_balance_proc (p_last_run_date in date, 
                                  p_to_run_date   in date,
                                  p_batch_limit   in number,
                                  p_sample_count  in number)
IS
  open_bal_cust_full cust_elg_tab;
  cursor lcu_open_bal_cust is 
SELECT hca.party_id
  ,hca.cust_account_id
  ,hca.account_number
  ,ps.customer_site_use_id     
  ,'OPEN BAL' "int_source"
,null "ORIG_EXTRACTION_DATE"
,null "LAST_EXTRACTION_DATE"
,null "MASTER_DATA_EXTRACTED"
,null "TRANS_DATA_EXTRACTED"
,g_LAST_UPDATE_DATE                
,g_LAST_UPDATED_BY                 
,g_CREATION_DATE                   
,g_CREATED_BY                      
,g_LAST_UPDATE_LOGIN               
,g_REQUEST_ID                      
,g_PROGRAM_APPLICATION_ID          
,g_PROGRAM_ID                      
,g_PROGRAM_UPDATE_DATE             
FROM XX_AR_OPEN_TRANS_ITM ps,
     hz_cust_site_uses_all csu,
     hz_cust_acct_sites_all cas,
     hz_cust_accounts hca
WHERE ps.customer_site_use_id = csu.site_use_id
AND csu.cust_acct_site_id = cas.cust_acct_site_id
AND cas.cust_account_id = hca.cust_account_id
AND not exists ( select '1' from XX_AR_INTSTORECUST_OTC int_cust
                 where int_cust.cust_account_id = hca.cust_account_id)
AND NOT exists ( select '1' from xxcrm_wcelg_cust ec
                 where ec.cust_account_id = hca.cust_account_id)
and rownum <= p_sample_count;

  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN

  
------------------------------------------
--lcu_open_bal_cust cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_open_bal_cust;

      LOOP
         FETCH lcu_open_bal_cust
         BULK COLLECT INTO open_bal_cust_full LIMIT v_batchlimit;

         FORALL i IN 1 .. open_bal_cust_full.COUNT 
               INSERT INTO xxcrm_wcelg_cust VALUES open_bal_cust_full(i);
               COMMIT;
         EXIT WHEN lcu_open_bal_cust%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_open_bal_cust;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
   
PROCEDURE lupd_parties_proc (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number)
IS
  party_full  party_delta_tab;
  CURSOR lcu_party_delta IS 
   select  party_id
          ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from hz_parties
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_party_delta';
  
------------------------------------------
--lcu_party_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_party_delta;

      LOOP
         FETCH lcu_party_delta
         BULK COLLECT INTO party_full LIMIT v_batchlimit;

         FORALL i IN 1 .. party_full.COUNT 
               INSERT INTO xxcrm_party_delta VALUES party_full(i);
               COMMIT;
         EXIT WHEN lcu_party_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_party_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
                                    
PROCEDURE lupd_adjustments_proc (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number)
IS
  adjustment_full  adjustment_delta_tab;
  CURSOR lcu_adjustment_delta IS 
   select  adjustment_id
          ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from ar_adjustments_all
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxar_adjustment_delta';
  
------------------------------------------
--lcu_adjustment_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_adjustment_delta;

      LOOP
         FETCH lcu_adjustment_delta
         BULK COLLECT INTO adjustment_full LIMIT v_batchlimit;

         FORALL i IN 1 .. adjustment_full.COUNT 
               INSERT INTO xxar_adjustment_delta VALUES adjustment_full(i);
               COMMIT;
         EXIT WHEN lcu_adjustment_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_adjustment_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
                                    
                                    
PROCEDURE lupd_CONTACT_POINTS_proc (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number)
IS
 contpoint_full contpoint_delta_tab;
 cursor lcu_contact_point_delta is 
 select 
 contact_point_id 
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_CONTACT_POINTS
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_contpoint_delta';
  
------------------------------------------
--lcu_contact_point_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_contact_point_delta;

      LOOP
         FETCH lcu_contact_point_delta
         BULK COLLECT INTO contpoint_full LIMIT v_batchlimit;

         FORALL i IN 1 .. contpoint_full.COUNT 
               INSERT INTO xxcrm_contpoint_delta VALUES contpoint_full(i);
               COMMIT;
         EXIT WHEN lcu_contact_point_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_contact_point_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_CUST_ACCT_SITES_PROC (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number)
IS
 acct_sites_full acct_sites_delta_tab;
 cursor lcu_acct_sites_delta is 
 select 
    hcsu.cust_acct_site_id  
   ,hcsu.cust_account_id
   ,hcsu.party_site_id      
   ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_CUST_ACCT_SITES_ALL hcsu
   where hcsu.last_update_date > p_last_run_date 
   and   hcsu.last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_site_uses_delta';
  
------------------------------------------
--lcu_acct_sites_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_acct_sites_delta;

      LOOP
         FETCH lcu_acct_sites_delta
         BULK COLLECT INTO acct_sites_full LIMIT v_batchlimit;

         FORALL i IN 1 .. acct_sites_full.COUNT 
               INSERT INTO xxcrm_cust_acct_sites_delta  VALUES acct_sites_full(i);
               COMMIT;
         EXIT WHEN lcu_acct_sites_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_acct_sites_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_CUST_PROFILE_AMTS_proc (p_last_run_date in date, 
                                       p_to_run_date   in date,
                                       p_batch_limit   in number)
IS
 profile_amts_full profile_amts_delta_tab;
 cursor lcu_profile_amts_delta is 
 select 
cust_acct_profile_amt_id   
   ,cust_account_profile_id
   ,currency_code           
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_CUST_PROFILE_AMTS
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_profile_amts_delta';
  
------------------------------------------
--lcu_profile_amts_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_profile_amts_delta;

      LOOP
         FETCH lcu_profile_amts_delta
         BULK COLLECT INTO profile_amts_full LIMIT v_batchlimit;

         FORALL i IN 1 .. profile_amts_full.COUNT 
               INSERT INTO xxcrm_cust_profile_amts_delta VALUES profile_amts_full(i);
               COMMIT;
         EXIT WHEN lcu_profile_amts_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_profile_amts_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_CUST_SITE_USES_proc (p_last_run_date in date, 
                                    p_to_run_date   in date,
                                    p_batch_limit   in number)
IS
 site_uses_full site_uses_delta_tab;
 cursor lcu_site_uses_delta is 
 select 
 site_use_id   		
   ,cust_acct_site_id   
   ,site_use_code       
   ,orig_system_reference 
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_CUST_SITE_USES_ALL
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_site_uses_delta';
  
------------------------------------------
--lcu_site_uses_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_site_uses_delta;

      LOOP
         FETCH lcu_site_uses_delta
         BULK COLLECT INTO site_uses_full LIMIT v_batchlimit;

         FORALL i IN 1 .. site_uses_full.COUNT 
               INSERT INTO xxcrm_cust_site_uses_delta VALUES site_uses_full(i);
               COMMIT;
         EXIT WHEN lcu_site_uses_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_site_uses_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_CUSTOMER_PROFILES_proc (p_last_run_date in date, 
                                       p_to_run_date   in date,
                                       p_batch_limit   in number)
IS
 profiles_full CUSTOMER_PROFILES_delta_tab;
 cursor lcu_profiles_delta is 
 select 
cust_account_profile_id    
,cust_account_id 
,party_id        
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_CUSTOMER_PROFILES
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_CUSTOMER_PROFILES_delta';
  
------------------------------------------
--lcu_profiles_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_profiles_delta;

      LOOP
         FETCH lcu_profiles_delta
         BULK COLLECT INTO profiles_full LIMIT v_batchlimit;

         FORALL i IN 1 .. profiles_full.COUNT 
               INSERT INTO xxcrm_CUSTOMER_PROFILES_delta VALUES profiles_full(i);
               COMMIT;
         EXIT WHEN lcu_profiles_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_profiles_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_ORG_CONTACTS_proc (p_last_run_date in date, 
                                       p_to_run_date   in date,
                                       p_batch_limit   in number)
IS
 org_contacts_full org_contacts_delta_tab;
 cursor lcu_org_contacts_delta is 
 select 
 org_contact_id    
 ,party_relationship_id 
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_ORG_CONTACTS
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_org_contacts_delta';
  
------------------------------------------
--lcu_org_contacts_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_org_contacts_delta;

      LOOP
         FETCH lcu_org_contacts_delta
         BULK COLLECT INTO org_contacts_full LIMIT v_batchlimit;

         FORALL i IN 1 .. org_contacts_full.COUNT 
               INSERT INTO xxcrm_org_contacts_delta VALUES org_contacts_full(i);
               COMMIT;
         EXIT WHEN lcu_org_contacts_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_org_contacts_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_PARTY_SITES_proc (p_last_run_date in date, 
                                 p_to_run_date   in date,
                                 p_batch_limit   in number)
IS
 party_sites_full party_sites_delta_tab;
 cursor lcu_party_sites_delta is 
 select  
party_site_id   
,party_id        
,location_id     
,party_site_number
,orig_system_reference 
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from HZ_PARTY_SITES
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_party_sites_delta';
  
------------------------------------------
--lcu_party_sites_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_party_sites_delta;

      LOOP
         FETCH lcu_party_sites_delta
         BULK COLLECT INTO party_sites_full LIMIT v_batchlimit;

         FORALL i IN 1 .. party_sites_full.COUNT 
               INSERT INTO xxcrm_party_sites_delta VALUES party_sites_full(i);
               COMMIT;
         EXIT WHEN lcu_party_sites_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_party_sites_delta;
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_RS_GROUP_MEMBERS_proc (p_last_run_date in date, 
                                 p_to_run_date   in date,
                                 p_batch_limit   in number)
IS
 group_members_full RS_GROUP_MEMBERS_delta_tab;
 cursor lcu_group_members_delta is 
 select  
group_member_id  
,group_id        
,resource_id     
,person_id      
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from JTF_RS_GROUP_MEMBERS        
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_rs_group_members_delta';
  
------------------------------------------
--lcu_group_members_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_group_members_delta;

      LOOP
         FETCH lcu_group_members_delta
         BULK COLLECT INTO group_members_full LIMIT v_batchlimit;

         FORALL i IN 1 .. group_members_full.COUNT 
               INSERT INTO xxcrm_rs_group_members_delta VALUES group_members_full(i);
               COMMIT;
         EXIT WHEN lcu_group_members_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_group_members_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;  
                                    
PROCEDURE lupd_RS_RESOURCE_EXTNS_proc (p_last_run_date in date, 
                                 p_to_run_date   in date,
                                 p_batch_limit   in number)
IS
 resource_extns_full rs_resource_extns_tab;
 cursor lcu_resource_extns_delta is 
 select  
resource_id 
,person_party_id 
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from JTF_RS_RESOURCE_EXTNS       
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_rs_resource_extns';
  
------------------------------------------
--lcu_resource_extns_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_resource_extns_delta;

      LOOP
         FETCH lcu_resource_extns_delta
         BULK COLLECT INTO resource_extns_full LIMIT v_batchlimit;

         FORALL i IN 1 .. resource_extns_full.COUNT 
               INSERT INTO xxcrm_rs_resource_extns VALUES resource_extns_full(i);
               COMMIT;
         EXIT WHEN lcu_resource_extns_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_resource_extns_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  
                                    
PROCEDURE lupd_XX_TM_NAM_TERR_proc (p_last_run_date in date, 
                                 p_to_run_date   in date,
                                 p_batch_limit   in number)
IS
 terr_dtls_full TM_NAM_TERR_DTLS_delta_tab;
 cursor lcu_terr_dtls_delta is 
 select  
named_acct_terr_entity_id  
,named_acct_terr_id        
,entity_type      
,entity_id      
 ,g_last_update_date
          ,g_last_updated_by
          ,g_creation_date
          ,g_created_by
          ,g_last_update_login          
          ,g_REQUEST_ID            
          ,g_PROGRAM_APPLICATION_ID          
          ,g_PROGRAM_ID                      
          ,g_PROGRAM_UPDATE_DATE             
   from XX_TM_NAM_TERR_ENTITY_DTLS
   where last_update_date > p_last_run_date 
   and   last_update_date <= p_to_run_date;
  v_batchlimit   NUMBER;
  lc_error_loc   varchar2(240) := null;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_TM_NAM_DTLS_delta';
  
------------------------------------------
--lcu_terr_dtls_delta cursor Loop started here
------------------------------------------
      
      v_batchlimit := p_batch_limit;

            OPEN lcu_terr_dtls_delta;

      LOOP
         FETCH lcu_terr_dtls_delta
         BULK COLLECT INTO terr_dtls_full LIMIT v_batchlimit;

         FORALL i IN 1 .. terr_dtls_full.COUNT 
               INSERT INTO xxcrm_TM_NAM_DTLS_delta VALUES terr_dtls_full(i);
               COMMIT;
         EXIT WHEN lcu_terr_dtls_delta%NOTFOUND;
      END LOOP;
      

      CLOSE lcu_terr_dtls_delta;

 
      
-------------------------------------
--cm_fulldata curosr Loop ended here
----------------------------------------

  COMMIT;
END;
  

END xx_cdhar_cust_elg_pkg;
/
show errors;                 