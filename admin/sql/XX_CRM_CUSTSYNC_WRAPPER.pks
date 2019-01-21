SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |            Oracle AMS /Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_CRM_CUSTSYNC_WRAPPER                                                   |
-- | Description : This package is developed to optimize the DB calls in TDS BPEL process    |
--                  AOPS_CustSync2COM_Process 
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1          APR-2011       AMS                   Initial draft version                    |
-- |                                                                                         |
-- +=========================================================================================+
CREATE OR REPLACE PACKAGE XX_CRM_CUSTSYNC_WRAPPER IS

  PROCEDURE xx_crm_custsync_proc
  (
    p_orig_system_ref      IN VARCHAR2
   ,p_aops_cust_id         IN VARCHAR2
   ,p_aops_country_code1   IN VARCHAR2
   ,p_aops_country_code2   IN VARCHAR2
   ,p_bpel_process_name    IN VARCHAR2
   ,px_customer_type       IN OUT NOCOPY VARCHAR2
   ,p_org_party_osr        IN apps.hz_parties.orig_system_reference%TYPE
   ,p_org_party_id         IN apps.hz_parties.party_id%TYPE
   ,p_contact_party_osr    IN apps.hz_parties.orig_system_reference%TYPE
   ,p_contact_party_id     IN apps.hz_parties.party_id%TYPE
   ,p_customer_osr         IN apps.hz_cust_accounts.orig_system_reference%TYPE
   ,p_reactivated_flag     IN apps.hz_customer_profiles.attribute4%TYPE
   ,p_ab_flag              IN apps.hz_customer_profiles.attribute3%TYPE
   ,p_status               IN apps.hz_cust_accounts.status%TYPE
   ,p_customer_type        IN apps.hz_cust_accounts.attribute18%TYPE
   ,p_cust_template        IN VARCHAR2
   ,p_party_id             IN hz_parties.party_id%TYPE
   ,p_person_id            IN hz_parties.party_id%TYPE
   ,p_org_contact_id       IN hz_org_contacts.org_contact_id%TYPE
   ,p_org_contact_role_id  IN hz_org_contact_roles.org_contact_role_id%TYPE
   ,p_contact_point1_id    IN hz_org_contacts.org_contact_id%TYPE
   ,p_contact_point2_id    IN hz_org_contacts.org_contact_id%TYPE
   ,p_orig_system          IN hz_orig_sys_references.orig_system%TYPE
   ,p_org_contact_osr      IN hz_orig_sys_references.orig_system_reference%TYPE
   ,p_contact_point1_osr   IN hz_orig_sys_references.orig_system_reference%TYPE
   ,p_contact_point2_osr   IN hz_orig_sys_references.orig_system_reference%TYPE
   ,p_osr_record           xx_validate_crm_osr_t_osr_tab
   ,x_target_country1      OUT NOCOPY VARCHAR2
   ,x_target_country2      OUT NOCOPY VARCHAR2
   ,x_target_org_id1       OUT NOCOPY NUMBER
   ,x_target_org_id2       OUT NOCOPY NUMBER
   ,x_comm_context_country OUT NOCOPY VARCHAR2
   ,x_target_add_org_id    OUT NOCOPY NUMBER
   ,x_null_address_element OUT NOCOPY VARCHAR2
   ,x_org_party_cs         OUT apps.hz_organization_profiles.actual_content_source%TYPE
   ,x_contact_party_cs     OUT apps.hz_person_profiles.actual_content_source%TYPE
   ,x_prof_class_modify    OUT NOCOPY VARCHAR2
   ,x_prof_class_name      OUT NOCOPY hz_cust_profile_classes.NAME%TYPE
   ,x_prof_class_id        OUT NOCOPY apps.hz_cust_profile_classes.profile_class_id%TYPE
   ,x_cust_act_status      OUT NOCOPY apps.hz_cust_accounts.status%TYPE
   ,x_retain_collect_cd    OUT NOCOPY VARCHAR2
   ,x_collector_code       OUT NOCOPY hz_customer_profiles.collector_id%TYPE
   ,x_collector_name       OUT NOCOPY apps.ar_collectors.NAME%TYPE
   ,x_owner_table_id       OUT NUMBER
   ,x_no_osr               OUT VARCHAR2
   ,x_no_osr_table         OUT VARCHAR2
   ,x_pkg_proc_name        OUT NOCOPY VARCHAR2
   ,x_msg_count            OUT NUMBER
   ,x_return_status        OUT NOCOPY VARCHAR2
   ,x_error_message        OUT NOCOPY VARCHAR2
  );

   PROCEDURE xx_crm_custsync2_proc
  (
    p_orig_system        IN VARCHAR2
   ,p_account_osr        IN VARCHAR2
   ,p_source_site_osr    IN VARCHAR2
   ,p_target_site_osr    IN VARCHAR2
   ,p_target_org_id      IN NUMBER
   ,p_status             IN VARCHAR2
   ,p_target_country1    IN VARCHAR2
   ,p_target_country2    IN VARCHAR2
   ,px_target_country2   IN VARCHAR2
   ,px_cazpad2           IN NUMBER
   ,p_validate_bo_flag   IN VARCHAR2 := fnd_api.g_true
   ,p_cust_acct_site_obj IN hz_cust_acct_site_bo
   ,p_created_by_module  IN VARCHAR2
   ,p_obj_source         IN VARCHAR2 := NULL
   ,p_return_obj_flag    IN VARCHAR2 := fnd_api.g_true
   ,x_messages           OUT NOCOPY hz_message_obj_tbl
   ,x_return_obj         OUT NOCOPY hz_cust_acct_site_bo
   ,x_cust_acct_site_id  OUT NOCOPY NUMBER
   ,x_cust_acct_site_os  OUT NOCOPY VARCHAR2
   ,px_parent_acct_id    IN OUT NOCOPY NUMBER
   ,px_parent_acct_os    IN OUT NOCOPY VARCHAR2
   ,px_parent_acct_osr   IN OUT NOCOPY VARCHAR2
   ,x_return_status      OUT NOCOPY VARCHAR2
   ,x_msg_data           OUT NOCOPY VARCHAR2  
	 ,x_pkg_proc_name        OUT NOCOPY VARCHAR2
  );

  PROCEDURE xx_crm_custsync3_proc
  (
    p_osr             IN hz_cust_accounts.orig_system_reference%TYPE
   ,p_request_id      IN xx_cdh_account_setup_req.request_id%TYPE
   ,x_party_id        OUT NOCOPY hz_cust_accounts.party_id%TYPE
   ,x_account_num     OUT NOCOPY hz_cust_accounts.account_number%TYPE
   ,x_cust_account_id OUT NOCOPY hz_cust_accounts.cust_account_id%TYPE
   ,x_pkg_proc_name   OUT NOCOPY VARCHAR2
   ,x_return_status   OUT NOCOPY VARCHAR2
   ,x_msg_data        OUT NOCOPY VARCHAR2
  );

END xx_crm_custsync_wrapper;
/