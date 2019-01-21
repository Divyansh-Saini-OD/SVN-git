CREATE OR REPLACE
PACKAGE BODY xx_cdhar_cust_elg_wj_pkg
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
PROCEDURE find_active_ab_cust_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER,
    p_sample_count  IN NUMBER)
IS
  cust_elg_full cust_elg_tab;
  CURSOR lcu_active_AB_cust
  IS
    SELECT  /*+ PARALLEL(HCA,4) PARALLEL(HCP,4) */ hca.PARTY_ID ,
      hca.CUST_ACCOUNT_ID,
      hca.ACCOUNT_NUMBER ,
      NULL "site_use_id" ,
      'AB ACTIVE' "int_source",
      NULL "ORIG_EXTRACTION_DATE",
      NULL "LAST_EXTRACTION_DATE",
      NULL "MASTER_DATA_EXTRACTED",
      NULL "TRANS_DATA_EXTRACTED",
      g_LAST_UPDATE_DATE ,
      g_LAST_UPDATED_BY ,
      g_CREATION_DATE ,
      g_CREATED_BY ,
      g_LAST_UPDATE_LOGIN ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM hz_customer_profiles hcp ,
         hz_cust_accounts hca
    WHERE hcp.status        = 'A'
    AND hcp.attribute3      = 'Y'
    AND hcp.site_use_id    IS NULL
    AND hcp.cust_account_id = hca.cust_account_id
    AND rownum             <= p_sample_count;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
  
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_wcelg_cust';
  ------------------------------------------
  --lcu_active_AB_cust cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_active_AB_cust;
  LOOP
    FETCH lcu_active_AB_cust BULK COLLECT INTO cust_elg_full LIMIT v_batchlimit;
    FORALL i IN 1 .. cust_elg_full.COUNT
    INSERT INTO xxcrm_wcelg_cust VALUES cust_elg_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_active_AB_cust%NOTFOUND;
  END LOOP;
  CLOSE lcu_active_AB_cust;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE find_open_balance_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER,
    p_sample_count  IN NUMBER
  )
IS
  open_bal_cust_full cust_elg_tab;
  CURSOR lcu_open_bal_cust
  IS
    SELECT /*+ INDEX_FFS(CAS XX_HZ_CUST_ACCT_SITES_ALL_N1) PARALLEL(PS,4) PARALLEL(CSU,4) PARALLEL(HCA,4) */ hca.party_id ,
      hca.cust_account_id ,
      hca.account_number ,
      ps.customer_site_use_id ,
      'OPEN BAL' "int_source" ,
      NULL "ORIG_EXTRACTION_DATE" ,
      NULL "LAST_EXTRACTION_DATE" ,
      NULL "MASTER_DATA_EXTRACTED" ,
      NULL "TRANS_DATA_EXTRACTED" ,
      g_LAST_UPDATE_DATE ,
      g_LAST_UPDATED_BY ,
      g_CREATION_DATE ,
      g_CREATED_BY ,
      g_LAST_UPDATE_LOGIN ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM XX_AR_OPEN_TRANS_ITM ps,
      hz_cust_site_uses_all csu,
      hz_cust_acct_sites_all cas,
      hz_cust_accounts hca
    WHERE ps.customer_site_use_id = csu.site_use_id
    AND csu.cust_acct_site_id     = cas.cust_acct_site_id
    AND cas.cust_account_id       = hca.cust_account_id
    AND NOT EXISTS
      (SELECT '1'
      FROM XX_AR_INTSTORECUST_OTC int_cust
      WHERE int_cust.cust_account_id = hca.cust_account_id
      )
  AND NOT EXISTS
    (SELECT '1'
    FROM xxcrm_wcelg_cust ec
    WHERE ec.cust_account_id = hca.cust_account_id
    )
  AND rownum <= p_sample_count;
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  ------------------------------------------
  --lcu_open_bal_cust cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_open_bal_cust;
  LOOP
    FETCH lcu_open_bal_cust BULK COLLECT
    INTO open_bal_cust_full LIMIT v_batchlimit;
    FORALL i IN 1 .. open_bal_cust_full.COUNT
    INSERT INTO xxcrm_wcelg_cust VALUES open_bal_cust_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_open_bal_cust%NOTFOUND;
  END LOOP;
  CLOSE lcu_open_bal_cust;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
  
  fnd_stats.gather_table_stats(ownname => 'XXCRM', tabname =>'XXCRM_WCELG_CUST');
END;
PROCEDURE lupd_parties_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  party_full party_delta_tab;
  CURSOR lcu_party_delta
  IS
    SELECT hp.party_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM hz_parties hp
    WHERE hp.last_update_date > p_last_run_date
    AND hp.last_update_date  <= p_to_run_date
    AND EXISTS
      ( SELECT '1' FROM xxcrm_wcelg_cust ec WHERE ec.party_id = hp.party_id
      );
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_party_delta';
  ------------------------------------------
  --lcu_party_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_party_delta;
  LOOP
    FETCH lcu_party_delta BULK COLLECT INTO party_full LIMIT v_batchlimit;
    FORALL i IN 1 .. party_full.COUNT
    INSERT INTO xxcrm_party_delta VALUES party_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_party_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_party_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;

/**
PROCEDURE lupd_cust_accounts_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  cust_accounts_full cust_accounts_delta_tab;
  CURSOR lcu_cust_accounts_delta
  IS
    SELECT hca.party_id ,
           hca.cust_account_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM hz_cust_accounts hca
    WHERE hca.last_update_date > p_last_run_date
    AND hca.last_update_date  <= p_to_run_date
    AND EXISTS
      ( SELECT '1' FROM xxcrm_wcelg_cust ec WHERE ec.cust_account_id = hca.cust_account_id
      );
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_accounts_delta';
  ------------------------------------------
  --lcu_cust_accounts_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_cust_accounts_delta;
  LOOP
    FETCH lcu_cust_accounts_delta BULK COLLECT INTO cust_accounts_full LIMIT v_batchlimit;
    FORALL i IN 1 .. cust_accounts_full.COUNT
    INSERT INTO xxcrm_cust_accounts_delta VALUES cust_accounts_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_cust_accounts_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_cust_accounts_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END; **/


PROCEDURE lupd_cust_accounts_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  ) IS
BEGIN
  null;
END;

PROCEDURE lupd_RELATIONSHIPS_proc(
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER)
IS
BEGIN
  null;
END;

PROCEDURE lupd_adjustments_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  adjustment_full adjustment_delta_tab;
  CURSOR lcu_adjustment_delta
  IS
    SELECT adjustment_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM ar_adjustments_all
    WHERE last_update_date > p_last_run_date
    AND last_update_date  <= p_to_run_date;
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxar_adjustment_delta';
  ------------------------------------------
  --lcu_adjustment_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_adjustment_delta;
  LOOP
    FETCH lcu_adjustment_delta BULK COLLECT
    INTO adjustment_full LIMIT v_batchlimit;
    FORALL i IN 1 .. adjustment_full.COUNT
    INSERT INTO xxar_adjustment_delta VALUES adjustment_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_adjustment_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_adjustment_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_CONTACT_POINTS_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  contpoint_full contpoint_delta_tab;
  CURSOR lcu_contact_point_delta
  IS
    SELECT /*+ PARALLEL(HCP,4) INDEX_FFS(EC XXCRM_WCELG_CUST_N2) */ hcp.contact_point_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec,
         hz_party_relationships hpr,
         HZ_CONTACT_POINTS HCP
    WHERE ec.party_id = hpr.object_id
    and   hcp.OWNER_TABLE_ID(+) = hpr.PARTY_ID 
    and   hcp.last_update_date > p_last_run_date
    AND hcp.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_contpoint_delta';
  ------------------------------------------
  --lcu_contact_point_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_contact_point_delta;
  LOOP
    FETCH lcu_contact_point_delta BULK COLLECT
    INTO contpoint_full LIMIT v_batchlimit;
    FORALL i IN 1 .. contpoint_full.COUNT
    INSERT INTO xxcrm_contpoint_delta VALUES contpoint_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_contact_point_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_contact_point_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_CUST_ACCT_SITES_PROC
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  acct_sites_full acct_sites_delta_tab;
  CURSOR lcu_acct_sites_delta
  IS
    SELECT hcsu.cust_acct_site_id ,
      hcsu.cust_account_id ,
      hcsu.party_site_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec,
         HZ_CUST_ACCT_SITES_ALL hcsu
    WHERE ec.cust_account_id = hcsu.cust_account_id
    AND hcsu.last_update_date > p_last_run_date
    AND hcsu.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_site_uses_delta';
  ------------------------------------------
  --lcu_acct_sites_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_acct_sites_delta;
  LOOP
    FETCH lcu_acct_sites_delta BULK COLLECT
    INTO acct_sites_full LIMIT v_batchlimit;
    FORALL i IN 1 .. acct_sites_full.COUNT
    INSERT INTO xxcrm_cust_acct_sites_delta VALUES acct_sites_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_acct_sites_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_acct_sites_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_CUST_PROFILE_AMTS_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  profile_amts_full profile_amts_delta_tab;
  CURSOR lcu_profile_amts_delta
  IS
    SELECT /*+ PARALLEL(HPA,4) INDEX_FFS(EC XXCRM_WCELG_CUST_N1) */ hpa.cust_acct_profile_amt_id ,
      hpa.cust_account_profile_id ,
      hpa.currency_code ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec,
         HZ_CUST_PROFILE_AMTS hpa
    WHERE ec.cust_account_id = hpa.cust_account_id
    AND hpa.last_update_date > p_last_run_date
    AND hpa.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_profile_amts_delta';
  ------------------------------------------
  --lcu_profile_amts_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_profile_amts_delta;
  LOOP
    FETCH lcu_profile_amts_delta BULK COLLECT
    INTO profile_amts_full LIMIT v_batchlimit;
    FORALL i IN 1 .. profile_amts_full.COUNT
    INSERT INTO xxcrm_cust_profile_amts_delta VALUES profile_amts_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_profile_amts_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_profile_amts_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_CUST_SITE_USES_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  site_uses_full site_uses_delta_tab;
  CURSOR lcu_site_uses_delta
  IS
    SELECT /*+ PARALLEL(HCSU,4) INDEX_FFS(EC XXCRM_WCELG_CUST_N1) */ hcsu.site_use_id ,
      hcsu.cust_acct_site_id ,
      hcsu.site_use_code ,
      hcsu.orig_system_reference ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec ,
         hz_cust_acct_sites_all hcas,
         HZ_CUST_SITE_USES_ALL hcsu
    WHERE ec.cust_account_id   = hcas.cust_account_id
    AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id         
    AND hcsu.last_update_date > p_last_run_date
    AND hcsu.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_cust_site_uses_delta';
  ------------------------------------------
  --lcu_site_uses_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_site_uses_delta;
  LOOP
    FETCH lcu_site_uses_delta BULK COLLECT INTO site_uses_full LIMIT v_batchlimit;
    FORALL i IN 1 .. site_uses_full.COUNT
    INSERT INTO xxcrm_cust_site_uses_delta VALUES site_uses_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_site_uses_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_site_uses_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_CUSTOMER_PROFILES_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  profiles_full CUSTOMER_PROFILES_delta_tab;
  CURSOR lcu_profiles_delta
  IS
    SELECT /*+ PARALLEL(HCP,4) INDEX_FFS(EC XXCRM_WCELG_CUST_N1) */ hcp.cust_account_profile_id ,
      hcp.cust_account_id ,
      hcp.party_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec,
         HZ_CUSTOMER_PROFILES hcp
    WHERE ec.cust_account_id = hcp.cust_account_id         
    AND hcp.last_update_date > p_last_run_date
    AND hcp.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_CUSTOMER_PROFILES_delta';
  ------------------------------------------
  --lcu_profiles_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_profiles_delta;
  LOOP
    FETCH lcu_profiles_delta BULK COLLECT INTO profiles_full LIMIT v_batchlimit;
    FORALL i IN 1 .. profiles_full.COUNT
    INSERT INTO xxcrm_CUSTOMER_PROFILES_delta VALUES profiles_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_profiles_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_profiles_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_ORG_CONTACTS_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  org_contacts_full org_contacts_delta_tab;
  CURSOR lcu_org_contacts_delta
  IS
    SELECT /*+ PARALLEL(HOC,4) USE_NL(EC) */ org_contact_id ,
      party_relationship_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
   FROM xxcrm_wcelg_cust ec ,
        hz_relationships rel ,
        HZ_ORG_CONTACTS hoc
   WHERE ec.party_id         = rel.subject_id
   AND rel.directional_flag  = 'F'
   AND REL.OBJECT_TABLE_NAME = 'HZ_PARTIES'
   AND rel.relationship_id   = hoc.party_relationship_id
   AND hoc.last_update_date > p_last_run_date
   AND hoc.last_update_date  <= p_to_run_date;
   
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_org_contacts_delta';
  ------------------------------------------
  --lcu_org_contacts_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_org_contacts_delta;
  LOOP
    FETCH lcu_org_contacts_delta BULK COLLECT
    INTO org_contacts_full LIMIT v_batchlimit;
    FORALL i IN 1 .. org_contacts_full.COUNT
    INSERT INTO xxcrm_org_contacts_delta VALUES org_contacts_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_org_contacts_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_org_contacts_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_PARTY_SITES_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  party_sites_full party_sites_delta_tab;
  CURSOR lcu_party_sites_delta
  IS
    SELECT /*+ PARALLEL(HPS,4) INDEX_FFS(EC XXCRM_WCELG_CUST_N2) */ hps.party_site_id ,
      hps.party_id ,
      hps.location_id ,
      hps.party_site_number ,
      hps.orig_system_reference ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM xxcrm_wcelg_cust ec,
         HZ_PARTY_SITES hps
    WHERE ec.party_id = hps.party_id
    AND   hps.last_update_date > p_last_run_date
    AND hps.last_update_date  <= p_to_run_date;
    
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_party_sites_delta';
  ------------------------------------------
  --lcu_party_sites_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_party_sites_delta;
  LOOP
    FETCH lcu_party_sites_delta BULK COLLECT
    INTO party_sites_full LIMIT v_batchlimit;
    FORALL i IN 1 .. party_sites_full.COUNT
    INSERT INTO xxcrm_party_sites_delta VALUES party_sites_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_party_sites_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_party_sites_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_RS_GROUP_MEMBERS_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  group_members_full RS_GROUP_MEMBERS_delta_tab;
  CURSOR lcu_group_members_delta
  IS
    SELECT group_member_id ,
      group_id ,
      resource_id ,
      person_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM JTF_RS_GROUP_MEMBERS
    WHERE last_update_date > p_last_run_date
    AND last_update_date  <= p_to_run_date;
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_rs_group_members_delta';
  ------------------------------------------
  --lcu_group_members_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_group_members_delta;
  LOOP
    FETCH lcu_group_members_delta BULK COLLECT
    INTO group_members_full LIMIT v_batchlimit;
    FORALL i IN 1 .. group_members_full.COUNT
    INSERT INTO xxcrm_rs_group_members_delta VALUES group_members_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_group_members_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_group_members_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_RS_RESOURCE_EXTNS_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  resource_extns_full rs_resource_extns_tab;
  CURSOR lcu_resource_extns_delta
  IS
    SELECT resource_id ,
      person_party_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM JTF_RS_RESOURCE_EXTNS
    WHERE last_update_date > p_last_run_date
    AND last_update_date  <= p_to_run_date;
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_rs_resource_extns';
  ------------------------------------------
  --lcu_resource_extns_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_resource_extns_delta;
  LOOP
    FETCH lcu_resource_extns_delta BULK COLLECT
    INTO resource_extns_full LIMIT v_batchlimit;
    FORALL i IN 1 .. resource_extns_full.COUNT
    INSERT INTO xxcrm_rs_resource_extns VALUES resource_extns_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_resource_extns_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_resource_extns_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
PROCEDURE lupd_XX_TM_NAM_TERR_proc
  (
    p_last_run_date IN DATE,
    p_to_run_date   IN DATE,
    p_batch_limit   IN NUMBER
  )
IS
  terr_dtls_full TM_NAM_TERR_DTLS_delta_tab;
  CURSOR lcu_terr_dtls_delta
  IS
    SELECT /*+ PARALLEL(XX_TM_NAM_TERR_ENTITY_DTLS,4) */ named_acct_terr_entity_id ,
      named_acct_terr_id ,
      entity_type ,
      entity_id ,
      g_last_update_date ,
      g_last_updated_by ,
      g_creation_date ,
      g_created_by ,
      g_last_update_login ,
      g_REQUEST_ID ,
      g_PROGRAM_APPLICATION_ID ,
      g_PROGRAM_ID ,
      g_PROGRAM_UPDATE_DATE
    FROM XX_TM_NAM_TERR_ENTITY_DTLS
    WHERE last_update_date > p_last_run_date
    AND last_update_date  <= p_to_run_date;
  v_batchlimit NUMBER;
  lc_error_loc VARCHAR2(240) := NULL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xxcrm_TM_NAM_DTLS_delta';
  ------------------------------------------
  --lcu_terr_dtls_delta cursor Loop started here
  ------------------------------------------
  v_batchlimit := p_batch_limit;
  OPEN lcu_terr_dtls_delta;
  LOOP
    FETCH lcu_terr_dtls_delta BULK COLLECT INTO terr_dtls_full LIMIT v_batchlimit;
    FORALL i IN 1 .. terr_dtls_full.COUNT
    INSERT INTO xxcrm_TM_NAM_DTLS_delta VALUES terr_dtls_full
      (i
      );
    COMMIT;
    EXIT
  WHEN lcu_terr_dtls_delta%NOTFOUND;
  END LOOP;
  CLOSE lcu_terr_dtls_delta;
  -------------------------------------
  --cm_fulldata curosr Loop ended here
  ----------------------------------------
  COMMIT;
END;
END xx_cdhar_cust_elg_wj_pkg;
/
show errors;
