CREATE OR REPLACE
PACKAGE XXCRM_CUST_ELG_PKG
AS
  --+=====================================================================+
  --|      Office Depot - Project FIT                                     |
  --|   Capgemini/Office Depot/Consulting Organization                    |
  --+=====================================================================+
  --|Name        :XXCRM_CUST_ELG_PKG                                      |
  --| BR #       :106313                                                  |
  --|Description :This Package is for identifying eligble customers       |
  --|                                                                     |
  --|            The STAGING Procedure will perform the following steps   |
  --|                                                                     |
  --|             1. Identify eligible customers based on business rules  |
  --|                 a. All Active Account Billing Customers             |
  --|                 b. Customers with open Balance exluding internal    |
  --|                 c. Parent Customers in hierarchy irrespective of status    |
  --|                                                                     |
  --|             2. Insert data into customer eligbility table           |
  --|                                                                     |
  --|             3. Finds records that have been touched based on last_update_date |
  --|                                                                     |
  --|Change Record:                                                       |
  --|==============                                                       |
  --|Version    Date           Author                       Remarks       |
  --|=======   ======        ====================          =========      |
  --|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version    |
  --+=====================================================================+
  g_last_update_date DATE  := sysdate;
  g_LAST_UPDATED_BY NUMBER := NVL(fnd_profile.value('USER_ID'),-1);
  g_creation_date DATE     := sysdate;
  g_created_by             NUMBER      := NVL(fnd_profile.value('USER_ID'), -1);
  g_last_update_login      NUMBER      := NVL(fnd_profile.value('LOGIN_ID'),-1);
  g_REQUEST_ID             NUMBER      :=                                   -1;
  g_PROGRAM_APPLICATION_ID NUMBER      :=                                   -1;
  g_program_id             NUMBER      :=                                   -1;
  g_PROGRAM_UPDATE_DATE DATE           := sysdate;
  -- +====================================================================+
  -- |      Record Type Declaration                                       |
  -- |                                                                    |
  -- |   Name: Party_Delta                                                |
  -- +====================================================================+
TYPE cust_elg_rec
IS
  RECORD
  (
    PARTY_ID        NUMBER(15) ,
    CUST_ACCOUNT_ID NUMBER(15) ,
    ACCOUNT_NUMBER  VARCHAR2(30) ,
    SITE_USE_ID     NUMBER(15) ,
    INT_SOURCE      VARCHAR2(15) ,
    ORIG_EXTRACTION_DATE DATE ,
    LAST_EXTRACTION_DATE DATE ,
    MASTER_DATA_EXTRACTED VARCHAR2(1) ,
    TRANS_DATA_EXTRACTED  VARCHAR2(1) ,
    LAST_UPDATE_DATE DATE ,
    LAST_UPDATED_BY NUMBER(15) ,
    CREATION_DATE DATE ,
    CREATED_BY             NUMBER(15) ,
    LAST_UPDATE_LOGIN      NUMBER(15) ,
    REQUEST_ID             NUMBER(15) ,
    PROGRAM_APPLICATION_ID NUMBER(15) ,
    PROGRAM_ID             NUMBER(15) ,
    PROGRAM_UPDATE_DATE DATE );
TYPE cust_elg_tab
IS
  TABLE OF cust_elg_rec;
TYPE party_delta_rec
IS
  RECORD
  (
    party_id hz_parties.party_id%type ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE party_delta_tab
IS
  TABLE OF party_delta_rec;
TYPE cust_accounts_delta_rec
IS
  RECORD
  (
    party_id hz_parties.party_id%type,
    cust_account_id hz_cust_accounts.cust_account_id%type,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type); 
TYPE cust_accounts_delta_tab
IS
  TABLE OF cust_accounts_delta_rec;
TYPE adjustment_delta_rec
IS
  RECORD
  (
    adjustment_id ar_adjustments_all.adjustment_id%type ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE adjustment_delta_tab
IS
  TABLE OF adjustment_delta_rec;
TYPE contpoint_delta_rec
IS
  RECORD
  (
    contact_point_id NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE contpoint_delta_tab
IS
  TABLE OF contpoint_delta_rec;
TYPE acct_sites_delta_rec
IS
  RECORD
  (
    cust_acct_site_id NUMBER(15) ,
    cust_account_id   NUMBER(15) ,
    party_site_id     NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE acct_sites_delta_tab
IS
  TABLE OF acct_sites_delta_rec;
TYPE profile_amts_delta_rec
IS
  RECORD
  (
    cust_acct_profile_amt_id NUMBER(15) ,
    cust_account_profile_id  NUMBER(15) ,
    currency_code            VARCHAR2(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE profile_amts_delta_tab
IS
  TABLE OF profile_amts_delta_rec;
TYPE site_uses_delta_rec
IS
  RECORD
  (
    site_use_id           NUMBER(15) ,
    cust_acct_site_id     NUMBER(15) ,
    site_use_code         VARCHAR2(15) ,
    orig_system_reference VARCHAR2(60) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE site_uses_delta_tab
IS
  TABLE OF site_uses_delta_rec;
TYPE CUSTOMER_PROFILES_delta_rec
IS
  RECORD
  (
    cust_account_profile_id NUMBER(15) ,
    cust_account_id         NUMBER(15) ,
    party_id                NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE CUSTOMER_PROFILES_delta_tab
IS
  TABLE OF CUSTOMER_PROFILES_delta_rec;
TYPE org_contacts_delta_rec
IS
  RECORD
  (
    org_contact_id        NUMBER(15) ,
    party_relationship_id NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE org_contacts_delta_tab
IS
  TABLE OF org_contacts_delta_rec;
TYPE party_sites_rec
IS
  RECORD
  (
    party_site_id         NUMBER(15) ,
    party_id              NUMBER(15) ,
    location_id           NUMBER(15) ,
    party_site_number     VARCHAR2(60) ,
    orig_system_reference VARCHAR2(60) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE party_sites_delta_tab
IS
  TABLE OF party_sites_rec;
TYPE RS_GROUP_MEMBERS_rec
IS
  RECORD
  (
    group_member_id NUMBER(15) ,
    group_id        NUMBER(15) ,
    resource_id     NUMBER(15) ,
    person_id       NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE RS_GROUP_MEMBERS_delta_tab
IS
  TABLE OF RS_GROUP_MEMBERS_rec;
TYPE rs_resource_extns_rec
IS
  RECORD
  (
    resource_id     NUMBER(15) ,
    person_party_id NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE rs_resource_extns_tab
IS
  TABLE OF rs_resource_extns_rec;
TYPE TM_NAM_TERR_DTLS_rec
IS
  RECORD
  (
    named_acct_terr_entity_id NUMBER(15) ,
    named_acct_terr_id        NUMBER(15) ,
    entity_type               VARCHAR2(60) ,
    entity_id                 NUMBER(15) ,
    LAST_UPDATE_DATE hz_cust_accounts.last_update_date%type ,
    LAST_UPDATED_BY hz_cust_accounts.LAST_UPDATED_BY%type ,
    CREATION_DATE hz_cust_accounts.creation_date%type ,
    CREATED_BY hz_cust_accounts.created_by%type ,
    LAST_UPDATE_LOGIN hz_cust_accounts.last_update_login%type ,
    REQUEST_ID hz_cust_accounts.request_id%type ,
    PROGRAM_APPLICATION_ID hz_cust_accounts.program_application_id%type ,
    PROGRAM_ID hz_cust_accounts.program_id%type ,
    PROGRAM_UPDATE_DATE hz_cust_accounts.program_update_date%type);
TYPE TM_NAM_TERR_DTLS_delta_tab
IS
  TABLE OF TM_NAM_TERR_DTLS_rec;
PROCEDURE find_active_ab_cust_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER,
    p_sample_count  IN NUMBER);
PROCEDURE find_open_balance_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER,
    p_sample_count  IN NUMBER);
PROCEDURE lupd_parties_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_cust_accounts_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_RELATIONSHIPS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_ADJUSTMENTS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_CONTACT_POINTS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_CUST_ACCT_SITES_PROC(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_CUST_PROFILE_AMTS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_CUST_SITE_USES_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_CUSTOMER_PROFILES_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_ORG_CONTACTS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_PARTY_SITES_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_RS_GROUP_MEMBERS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_RS_RESOURCE_EXTNS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
PROCEDURE lupd_XX_TM_NAM_TERR_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER);
END XXCRM_CUST_ELG_PKG;
/
show errors; 