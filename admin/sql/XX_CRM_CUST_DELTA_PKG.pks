CREATE OR REPLACE PACKAGE xx_crm_cust_delta_pkg
AS
--+===============================================================================+
--|      Office Depot - Project FIT                                               |
--|   Capgemini/Office Depot/Consulting Organization                              |
--+===============================================================================+
--|Name        :XX_CRM_CUST_ELG_PKG                                               |
--| BR #       :106313                                                            |
--|Description :This Package is for identifying incremental data                  |
--|                                                                               |
--|            The STAGING Procedure will perform the following steps             |
--|                                                                               |
--|             1. Identify incremental datafor each customer based on            |
--|                 last upadte date  and insert into common delat table          |
--|             2. For each table we have one saperate procedure                  |
--|                  to get the incremental data into common delta table          |
--|                                                                               |
--|Change Record:                                                                 |
--|==============                                                                 |
--|Version    Date           Author                       Remarks                 |
--|=======   ======        ====================          =========                |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version              |
--+===============================================================================+

   -- Global variable declaration
   gd_last_update_date   hz_cust_accounts.last_update_date%TYPE   := SYSDATE;
   gn_last_updated_by    hz_cust_accounts.last_updated_by%TYPE    := NVL (fnd_profile.VALUE ('USER_ID'), -1);
   gd_creation_date      hz_cust_accounts.creation_date%TYPE      := SYSDATE;
   gn_created_by         hz_cust_accounts.created_by%TYPE         := NVL (fnd_profile.VALUE ('USER_ID'), -1);
   gn_request_id         hz_cust_accounts.request_id%TYPE         := NVL (fnd_profile.VALUE ('REQUEST_ID'), -1);
   gn_program_id         hz_cust_accounts.program_id%TYPE         := NVL (fnd_profile.VALUE ('PROGRAM_ID'), -1);
   gc_program_type       xx_com_error_log.program_type%TYPE       := 'CONCURRENT PROGRAM';
   gc_program_name       xx_com_error_log.program_name%TYPE       := NVL (fnd_profile.VALUE ('PROGRAM_NAME'), 'Oracle to WC');
   gc_module_name        xx_com_error_log.module_name%TYPE        := 'XXCRM';
   gc_error_debug        VARCHAR2 (400);
   gc_debug_flag         VARCHAR2 (1);
   gc_compute_stats      VARCHAR2 (1);

-- +====================================================================+
-- |      Record Type Declaration                                       |
-- |                                                                    |
-- |   Name: Party Delta                                                |
-- +====================================================================+
   TYPE lr_common_delta IS RECORD (
      content_type                VARCHAR2 (30)
     ,party_id                    hz_parties.party_id%TYPE
     ,cust_account_id             hz_cust_accounts.cust_account_id%TYPE
     ,cust_account_profile_id     hz_customer_profiles.cust_account_profile_id%TYPE
     ,cust_acct_profile_amt_id    hz_cust_profile_amts.cust_acct_profile_amt_id%TYPE
     ,currency_code               hz_cust_profile_amts.currency_code%TYPE
     ,party_site_id               hz_party_sites.party_site_id%TYPE
     ,location_id                 hz_party_sites.location_id%TYPE
     ,party_site_number           hz_party_sites.party_site_number%TYPE
     ,cust_acct_site_id           hz_cust_acct_sites_all.cust_acct_site_id%TYPE
     ,site_use_id                 hz_cust_site_uses_all.site_use_id%TYPE
     ,site_use_code               hz_cust_site_uses_all.site_use_code%TYPE
     ,orig_system_reference       hz_cust_site_uses_all.orig_system_reference%TYPE
     ,contact_point_id            hz_contact_points.contact_point_id%TYPE
     ,org_contact_id              hz_org_contacts.org_contact_id%TYPE
     ,group_member_id             jtf_rs_group_members.group_member_id%TYPE
     ,GROUP_ID                    jtf_rs_group_members.GROUP_ID%TYPE
     ,resource_id                 jtf_rs_group_members.resource_id%TYPE
     ,person_id                   jtf_rs_group_members.person_id%TYPE
     ,party_relationship_id       hz_org_contacts.party_relationship_id%TYPE
     ,person_party_id             jtf_rs_resource_extns.person_party_id%TYPE
     ,named_acct_terr_entity_id   xx_tm_nam_terr_entity_dtls.named_acct_terr_entity_id%TYPE
     ,named_acct_terr_id          xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE
     ,entity_type                 xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,entity_id                   xx_tm_nam_terr_entity_dtls.entity_id%TYPE
     ,cust_account_role_id        hz_cust_account_roles.cust_account_role_id%TYPE
     ,last_update_date            hz_cust_accounts.last_update_date%TYPE
     ,last_updated_by             hz_cust_accounts.LAST_UPDATED_BY%TYPE
     ,creation_date               hz_cust_accounts.creation_date%TYPE
     ,created_by                  hz_cust_accounts.created_by%TYPE
     ,request_id                  hz_cust_accounts.request_id%TYPE
     ,program_id                  hz_cust_accounts.program_id%TYPE
   );

   TYPE lt_common_delta IS TABLE OF lr_common_delta;

   TYPE lt_req_id IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

-- +================================================================================================+
-- |   To find hz_parties that have been touched (created or updated) based on last_update_date     |
-- +================================================================================================+
   PROCEDURE get_delta_parties (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find hz_cust_accounts that have been touched (created or updated) based on last_update_date     |
-- +====================================================================================================+
   PROCEDURE get_delta_cust_accounts (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

   -- +====================================================================================================+
-- | To find hz_contact_points that have been touched (created or updated) based on last_update_date    |
-- +====================================================================================================+
   PROCEDURE get_delta_CONTACT_POINTS (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +==========================================================================================================+
-- | To find hz_cust_acct_sites_all that have been touched (created or updated) based on last_update_date     |
-- +==========================================================================================================+
   PROCEDURE get_delta_CUST_ACCT_SITES (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find hz_cust_profile_amts that have been touched (created or updated) based on last_update_date |
-- +====================================================================================================+
   PROCEDURE get_delta_CUST_PROFILE_AMTS (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +=========================================================================================================+
-- | To find hz_cust_site_uses_all that have been touched (created or updated) based on last_update_date     |
-- +=========================================================================================================+
   PROCEDURE get_delta_CUST_SITE_USES (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find hz_customer_profiles that have been touched (created or updated) based on last_update_date |
-- +====================================================================================================+
   PROCEDURE get_delta_CUSTOMER_PROFILES (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find Org_contacts that have been touched (created or updated) based on last_update_date         |
-- +====================================================================================================+
   PROCEDURE get_delta_ORG_CONTACTS (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find hz_party_sites that have been touched (created or updated) based on last_update_date       |
-- +====================================================================================================+
   PROCEDURE get_delta_PARTY_SITES (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +=====================================================================================================+
-- | To find hz_locations that have been touched (created or updated) based on last_update_date          |
-- +=====================================================================================================+
   PROCEDURE get_locations_delta (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +=====================================================================================================+
-- | To find hz_cust_account_roles that have been touched (created or updated) based on last_update_date      |
-- +=====================================================================================================+
   PROCEDURE get_account_roles_delta (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find RS_group_members that have been touched (created or updated) based on last_update_date     |
-- +====================================================================================================+
   PROCEDURE get_delta_RS_GROUP_MEMBERS (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find RS_RESOURCE_EXTNS that have been touched (created or updated) based on last_update_date    |
-- +====================================================================================================+
   PROCEDURE get_delta_RS_RESOURCE_EXTNS (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | To find XX_TM_NAM_TERR that have been touched (created or updated) based on last_update_date       |
-- +====================================================================================================+
   PROCEDURE get_delta_XX_TM_NAM_TERR (
      p_errbuf                 OUT      VARCHAR2
     ,p_retcode                OUT      NUMBER
     ,p_last_run_date          IN       VARCHAR2
     ,p_to_run_date            IN       VARCHAR2
     ,p_batch_limit            IN       NUMBER
     ,p_from_cust_account_id   IN       NUMBER
     ,p_to_cust_account_id     IN       NUMBER
     ,p_compute_stats          IN       VARCHAR2
     ,p_debug_flag             IN       VARCHAR2
     ,p_thread_num             IN       NUMBER
   );

-- +====================================================================================================+
-- | This main procedure is used to submit all delta procedures in batch wise                           |
-- +====================================================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_from_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,P_no_of_threads   IN       NUMBER
     ,P_content_type    IN       VARCHAR2
     ,P_compute_stats   IN       VARCHAR2
     ,P_debug_flag      IN       VARCHAR2
   );
END xx_crm_cust_delta_pkg;
/

SHOW errors;