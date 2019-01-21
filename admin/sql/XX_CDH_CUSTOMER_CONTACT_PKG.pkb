SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_CUSTOMER_CONTACT_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XXCDHCREATECONTACTB.pls                            |
-- | Description :  CDH Customer Conversion Create Contact Pkg Body    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Apr-2007 Ambarish Mukherjee Initial draft version     |
-- |Draft 1b  30-Apr-2007 Ambarish Mukherjee Commented out custom code |
-- |                                         to create contacts        |
-- |Draft 1c  09-May-2007 Ambarish Mukherjee Modified to handle updates|
-- |Draft 1d  04-Jun-2007 Ambarish Mukherjee Modified to include limit |
-- |                                         clause in bulk fetch      |
-- |Draft 1e  09-Aug-2007 Ambarish Mukherjee Modified for collector    |
-- |                                         contact changes.          |
-- |1.0       20-Dec-2007 Ambarish Mukherjee Added multithreading for  |
-- |                                         contacts roles and resp   |
-- |2.0       15-May-2008 Rajeev Kamath      Added API call to set     |
-- |                                         DQM to batch mode for CtPt|
-- |2.1       11-Jun-2008 Ambarish Mukherjee Removed check for Contact |
-- |                                         OSR in role resp
-- |2.2       01-Jun-2009 Indra Varada       Role Resp logic modified
-- |                                         to handle 'REVOKED_SELF_SERVICE_ROLE' role
-- |2.3       07-Jan-2009 Indra Varada       CD-687 Changes            |
-- |2.4       23-Oct-2013 Deepak V           I0024 - Changes done for R12|
-- |                                         Upgrade retrofit.         |
-- |2.5       05-Jan-2016 Manikant Kasu      Removed schema alias as   | 
-- |                                         part of GSCC R12.2.2      |
-- |                                         Retrofit                  |
-- +===================================================================+
AS
gt_request_id                 fnd_concurrent_requests.request_id%TYPE
                              := fnd_global.conc_request_id();
gv_init_msg_list              VARCHAR2(1)          := fnd_api.g_true;
gn_bulk_fetch_limit           NUMBER               := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;
G_PKG_NAME                    CONSTANT VARCHAR2(30) := 'IEX_CUST_OVERVIEW_PVT';
-- +===================================================================+
-- | Name        :  create_contact_main                                |
-- | Description :  This procedure is invoked from the create contact  |
-- |                Main Concurrent Program.                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_contact_main
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      )
IS
lv_errbuf          VARCHAR2(2000);
lv_retcode         VARCHAR2(10);
le_skip_process    EXCEPTION;
BEGIN

   /*********************************
      This proc is not used anymore
   **********************************/

   log_debug_msg( 'Start of Concurrent Program - OD: Create Contact Conversion Program.');

   IF p_process_yn = 'N' THEN
      RAISE le_skip_process;
   END IF;

   log_debug_msg( 'Calling procedure create_contact.');

   --create_contact
   --      ( x_errbuf    => lv_errbuf,
   --        x_retcode   => lv_retcode,
   --        p_batch_id  => p_batch_id
   ---      );

   IF lv_retcode <> 0 THEN
      RAISE le_skip_process;
   END IF;

   log_debug_msg( 'Calling procedure create_role_responsibility.');

   --create_role_responsibility
   --      (  x_errbuf    => lv_errbuf,
   --         x_retcode   => lv_retcode,
   --         p_batch_id  => p_batch_id
   --      );
   IF lv_retcode <> 0 THEN
      RAISE le_skip_process;
   END IF;

   log_debug_msg( 'Calling procedure create_contact_points.');
   /* Commented on 18-Jul, Registered as new concurrent Request
   create_contact_points
         (  x_errbuf    => lv_errbuf,
            x_retcode   => lv_retcode,
            p_batch_id  => p_batch_id
         );
   IF lv_retcode <> 0 THEN
      RAISE le_skip_process;
   END IF;
   */
EXCEPTION
   WHEN le_skip_process THEN
      x_errbuf  := lv_errbuf;
      x_retcode := lv_retcode;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      x_errbuf  := 'Unexpected Error in Program - '||SQLERRM;
      x_retcode := 2;
END;


-- +===================================================================+
-- | Name        :  create_contact_worker                              |
-- | Description :  This procedure is invoked from the create contact  |
-- |                main procedure. This would create contacts and     |
-- |                also create cust_account_role after fetching       |
-- |                records from staging table                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_contact_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      )
IS

CURSOR lc_fetch_ap_contacts (l_batch_id NUMBER)
IS
SELECT p.party_id,act.cust_account_id
FROM XXOD_HZ_IMP_ACCOUNTS_STG ac,
     HZ_IMP_PARTIES_INT p,
     HZ_CUST_ACCOUNTS act
WHERE ac.party_orig_system_reference = p.party_orig_system_reference
AND act.orig_system_reference = ac.account_orig_system_reference
AND p.party_id IS NOT NULL
AND p.batch_id  = l_batch_id
AND ac.batch_id = l_batch_id; 

CURSOR lc_fetch_contacts_cur
IS
SELECT *
FROM   xxod_hz_imp_acct_contact_stg
WHERE  interface_status IN ('1','4','6')
AND    batch_id = p_batch_id;

CURSOR lc_fetch_contact_roles_cur
IS
SELECT *
FROM   xxod_hz_imp_acct_contact_stg
WHERE  role_interface_status IN ('1','4','6')
AND    MOD(NVL(TO_NUMBER(REGEXP_SUBSTR(account_orig_system_reference, '[123456789]{1,7}')), ASCII(account_orig_system_reference)), fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
AND    batch_id = p_batch_id;

CURSOR lc_fetch_rel_party_id_cur
         ( p_org_contact_id IN NUMBER )
IS
SELECT hr.party_id
FROM   hz_relationships hr,
       hz_org_contacts  hoc
WHERE  hoc.org_contact_id = p_org_contact_id
AND    hr.relationship_id = hoc.party_relationship_id
AND    hr.status          = 'A';

TYPE lt_acct_contact_tbl_type IS TABLE OF XXOD_HZ_IMP_ACCT_CONTACT_STG%ROWTYPE INDEX BY BINARY_INTEGER;
lt_acct_contacts_tbl          lt_acct_contact_tbl_type;

TYPE lt_upd_tbl_type          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lt_upd_record_tbl             lt_upd_tbl_type;
lt_upd_interface_tbl          lt_upd_tbl_type;


l_org_contact_rec             HZ_PARTY_CONTACT_V2PUB.org_contact_rec_type;

lv_record_valid_flag          VARCHAR2(1);
le_skip_record                EXCEPTION;
le_skip_procedure             EXCEPTION;
ln_subject_id                 hz_orig_sys_references.owner_table_id%TYPE;
ln_object_id                  hz_orig_sys_references.owner_table_id%TYPE;
ln_osr_retcode                NUMBER;
lv_osr_errbuf                 VARCHAR2(2000);
lv_subject_party_type         hz_parties.party_type%TYPE;
lv_object_party_type          hz_parties.party_type%TYPE;
ln_contact_id                 hz_orig_sys_references.owner_table_id%TYPE;
ln_relationship_id            hz_relationships.relationship_id%TYPE;
ln_relationship_party_id      hz_parties.party_id%TYPE;
lv_party_number               hz_parties.party_number%TYPE;
lv_return_status              VARCHAR2(10);
ln_msg_count                  NUMBER;
lv_msg_data                   VARCHAR2(2000);
ln_cust_account_id            hz_orig_sys_references.owner_table_id%TYPE;
ln_cust_account_role_id       hz_cust_account_roles.cust_account_role_id%TYPE;
lt_contact_id                 NUMBER;
l_cust_acct_role_rec          HZ_CUST_ACCOUNT_ROLE_V2PUB.cust_account_role_rec_type;
l_df_cust_acct_role_rec       HZ_CUST_ACCOUNT_ROLE_V2PUB.cust_account_role_rec_type;
ln_records_read               NUMBER;
ln_records_success            NUMBER;
ln_records_failed             NUMBER;
le_skip_contact_creation      EXCEPTION;
ln_org_contact_id             NUMBER;
ln_cust_acct_site_id          NUMBER;
ln_up_cust_account_role_id    hz_cust_account_roles.cust_account_role_id%TYPE;
ln_object_version_number      NUMBER;
ln_msg_text                   VARCHAR2(32000);
ln_exists                     NUMBER;
l_pr_cust_acct_role_rec       HZ_CUST_ACCOUNT_ROLE_V2PUB.cust_account_role_rec_type;
ln_pr_cust_account_role_id    hz_cust_account_roles.cust_account_role_id%TYPE;
ln_pr_object_version_number   hz_cust_account_roles.object_version_number%TYPE;

l_batch_chk_sql                 VARCHAR2(2000);
TYPE l_batch_chk_cur_typ        IS REF CURSOR;
l_batch_chk_cur                 l_batch_chk_cur_typ;
l_batch_exists_count            NUMBER := 0;
x_ap_ret_status                 VARCHAR2(2);
x_ap_error_msg                  VARCHAR2(2000);
lv_aops_table_name              VARCHAR2(200);

BEGIN

   log_debug_msg( ' ');
   log_debug_msg( 'Start processing for contact roles');

   ln_records_read    := 0;
   ln_records_success := 0;
   ln_records_failed  := 0;
   
   /*-- CR 687 change begins -- 
     New Logic To Create AP Contact. The procedure (XX_CDH_CUSTOMER_CONTACT_PKG)
     call is common to both BPEL and Conversion Logic. The Procedure does NOT duplicate
     contact if it is already existing.
   */

  IF p_worker_id = 1 THEN
   
  BEGIN

   
    lv_aops_table_name           := fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME');
	
	/*
   
    l_batch_chk_sql  := 'SELECT COUNT(1)
                        FROM    ' || lv_aops_table_name ||
                        ' WHERE trim(orebatchf_parent) = ''C'' ' ||
                        ' AND TRIM(orebatchf_aops_batch_id) IN
                        (
                        SELECT SUBSTR(BATCH_NAME,0,4) 
                        FROM HZ_IMP_BATCH_SUMMARY
                        WHERE BATCH_ID = ' || p_batch_id ||
                        ' AND ORIGINAL_SYSTEM = ''A0'' 
                        )';
     */
    --Recent Datastage extract changes will bring batch load type C (create), P (parent) and U (update) for AOPS batches
    l_batch_chk_sql  := 'SELECT COUNT(1) ' ||
                        ' FROM HZ_IMP_BATCH_SUMMARY ' ||
                        ' WHERE BATCH_ID = ' || p_batch_id ||
                        ' AND ORIGINAL_SYSTEM = ''A0'' ' ||
                        ' AND LOAD_TYPE= ''C'' ' ;
                        
     fnd_file.put_line (fnd_file.log,'Batch Verification SQL:' || l_batch_chk_sql);
    
     OPEN l_batch_chk_cur FOR l_batch_chk_sql;
     FETCH l_batch_chk_cur INTO l_batch_exists_count;
    
     IF l_batch_exists_count > 0 THEN 
       
        fnd_file.put_line(fnd_file.log,'This is a Create Batch - AP Contact Processing Logic Executed');
       
        FOR l_ap_con IN lc_fetch_ap_contacts (p_batch_id) LOOP
           
           x_ap_ret_status := 'S';
           x_ap_error_msg := '';
           
           XX_CDH_ACCOUNT_SETUP_REQ_PKG.create_acct_ap_contact
           (
               p_cust_account_id  => l_ap_con.cust_account_id,
               p_request_id       => NULL,
               p_party_id         => l_ap_con.party_id,
               x_return_status    => x_ap_ret_status,
               x_error_message	  => x_ap_error_msg
            );
            
           IF x_ap_ret_status != 'S' THEN
              fnd_file.put_line(fnd_file.log,'XX_CDH_ACCOUNT_SETUP_REQ_PKG.create_acct_ap_contact API Error While Processing AP Contact For Account:' || l_ap_con.cust_account_id);
              fnd_file.put_line(fnd_file.log,'Error Message:' || x_ap_error_msg);
           END IF;
         
       END LOOP;
    
    END IF;
   
   EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Unexpected Error During AP Contact Processing:' || SQLERRM);
   END;

   END IF;
   
   /*-- CR 687 change ends -- */ 
   
   OPEN  lc_fetch_contact_roles_cur;
   LOOP
      FETCH lc_fetch_contact_roles_cur BULK COLLECT INTO lt_acct_contacts_tbl LIMIT gn_bulk_fetch_limit;

      IF lt_acct_contacts_tbl.count = 0 THEN
         log_debug_msg( 'No records exist in the staging table for batch_id - '||p_batch_id||' for contact roles');
         RAISE le_skip_procedure;
      END IF;

      FOR i IN lt_acct_contacts_tbl.FIRST .. lt_acct_contacts_tbl.LAST
      LOOP
         BEGIN
            ln_records_read := ln_records_read + 1;
            log_debug_msg( ' ');
            log_debug_msg( '-----------------------------------------------');
            log_debug_msg( 'RECORD_ID:'||lt_acct_contacts_tbl(i).record_id);
            log_debug_msg( ' ');
            log_debug_msg( ' ');

            /*****************************
               Create Cust Account Role
            ******************************/

            log_debug_msg( 'Start processing Cust Account Role.');

            ---------------------------------------
            -- Validations
            ---------------------------------------

            IF lt_acct_contacts_tbl(i).account_orig_system_reference   IS NULL AND
               lt_acct_contacts_tbl(i).acct_site_orig_sys_reference    IS NULL THEN
               log_debug_msg( 'account_orig_system_reference and acct_site_orig_system_reference are NULL.');
               log_debug_msg( 'Cust Account Role will not be created.');
               RAISE le_skip_record;
            END IF;

            ---------------------------------------
            -- Fetch Account Orig System Reference
            ---------------------------------------
            ln_cust_account_id       := NULL;
            ln_relationship_party_id := NULL;
            IF lt_acct_contacts_tbl(i).account_orig_system_reference IS NOT NULL THEN

               --ln_cust_account_id       := NULL;
               --ln_relationship_party_id := NULL;
               ln_osr_retcode           := NULL;
               lv_osr_errbuf            := NULL;


               XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                  (  p_orig_system        => lt_acct_contacts_tbl(i).account_orig_system,
                     p_orig_sys_reference => lt_acct_contacts_tbl(i).account_orig_system_reference,
                     p_owner_table_name   => 'HZ_CUST_ACCOUNTS',
                     x_owner_table_id     => ln_cust_account_id,
                     x_retcode            => ln_osr_retcode,
                     x_errbuf             => lv_osr_errbuf
                  );

               IF ln_cust_account_id IS NULL THEN
                  log_debug_msg( 'Error while fetching cust_account_id - account_orig_system_reference is invalid');
                  log_debug_msg( 'account_orig_system_reference - '||lt_acct_contacts_tbl(i).account_orig_system_reference);
                  lt_acct_contacts_tbl(i).role_interface_status := 6;
                  log_exception
                     (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                       ,p_source_system_code     => NULL
                       ,p_procedure_name         => 'CREATE_CONTACT_ROLE'
                       ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                       ,p_staging_column_name    => 'ACCOUNT_ORIG_SYSTEM_REFERENCE'
                       ,p_staging_column_value   => lt_acct_contacts_tbl(i).account_orig_system
                       ,p_source_system_ref      => lt_acct_contacts_tbl(i).account_orig_system_reference
                       ,p_batch_id               => p_batch_id
                       ,p_exception_log          => 'Error while fetching cust_account_id - account_orig_system_reference is invalid'
                       ,p_oracle_error_code      => NULL
                       ,p_oracle_error_msg       => NULL
                     );
                  RAISE le_skip_record;
               END IF;

            END IF;

            --------------------------------------------
            -- Fetch Account Site Orig System Reference
            --------------------------------------------
            ln_cust_acct_site_id     := NULL;
            ln_relationship_party_id := NULL;
            ln_osr_retcode           := NULL;
            lv_osr_errbuf            := NULL;
            IF lt_acct_contacts_tbl(i).acct_site_orig_sys_reference IS NOT NULL THEN

               --ln_cust_acct_site_id     := NULL;
               --ln_relationship_party_id := NULL;
               --ln_osr_retcode           := NULL;
               --lv_osr_errbuf            := NULL;

               XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                  (  p_orig_system        => lt_acct_contacts_tbl(i).acct_site_orig_system,
                     p_orig_sys_reference => lt_acct_contacts_tbl(i).acct_site_orig_sys_reference,
                     p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
                     x_owner_table_id     => ln_cust_acct_site_id,
                     x_retcode            => ln_osr_retcode,
                     x_errbuf             => lv_osr_errbuf
                  );

               IF ln_cust_acct_site_id IS NULL THEN
                  log_debug_msg( 'Error while fetching cust_account_site_id - acct_site_orig_sys_reference is invalid');
                  log_debug_msg( 'acct_site_orig_sys_reference - '||lt_acct_contacts_tbl(i).acct_site_orig_sys_reference);
                  lt_acct_contacts_tbl(i).role_interface_status := 6;
                  log_exception
                     (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                       ,p_source_system_code     => NULL
                       ,p_procedure_name         => 'CREATE_CONTACT_ROLE'
                       ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                       ,p_staging_column_name    => 'ACCT_SITE_ORIG_SYSTEM_REFERENCE'
                       ,p_staging_column_value   => lt_acct_contacts_tbl(i).acct_site_orig_system
                       ,p_source_system_ref      => lt_acct_contacts_tbl(i).acct_site_orig_sys_reference
                       ,p_batch_id               => p_batch_id
                       ,p_exception_log          => 'Error while fetching cust_account_site_id - acct_site_orig_sys_reference is invalid'
                       ,p_oracle_error_code      => NULL
                       ,p_oracle_error_msg       => NULL
                     );
                  RAISE le_skip_record;
               END IF;

               BEGIN
                  SELECT 1
                  INTO   ln_exists
                  FROM   hz_cust_acct_sites
                  WHERE  cust_acct_site_id = ln_cust_acct_site_id;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     lt_acct_contacts_tbl(i).role_interface_status := 4;
                     RAISE le_skip_record;
               END;

            END IF;

            -------------------------------
            -- Fetch Relationship Party Id
            -------------------------------

            ln_org_contact_id        := NULL;
            ln_relationship_party_id := NULL;
            ln_osr_retcode           := NULL;
            lv_osr_errbuf            := NULL;

            XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                  (  p_orig_system        => lt_acct_contacts_tbl(i).contact_orig_system,
                     p_orig_sys_reference => lt_acct_contacts_tbl(i).contact_orig_system_reference,
                     p_owner_table_name   => 'HZ_ORG_CONTACTS',
                     x_owner_table_id     => ln_org_contact_id,
                     x_retcode            => ln_osr_retcode,
                     x_errbuf             => lv_osr_errbuf
                  );

            FOR lc_fetch_rel_party_id_rec IN lc_fetch_rel_party_id_cur (ln_org_contact_id)
            LOOP
               ln_relationship_party_id := lc_fetch_rel_party_id_rec.party_id;
               EXIT;
            END LOOP;

            IF ln_relationship_party_id IS NULL THEN
               lt_acct_contacts_tbl(i).role_interface_status := 6;
               log_debug_msg( 'Error while fetching relationship_party_id - Contact_orig_system_reference is invalid');
               log_debug_msg( 'contact_orig_system_reference - '||lt_acct_contacts_tbl(i).contact_orig_system_reference);
               log_exception
                  (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_CONTACT_ROLE'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                    ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                    ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'Error while fetching relationship_party_id - Contact_orig_system_reference is invalid'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
               RAISE le_skip_record;
            END IF;

            ----------------------------------
            -- Check if record already exists
            ----------------------------------
            BEGIN

               log_debug_msg( 'Checking if record already exists');
               log_debug_msg( 'relationship_party_id - '||ln_relationship_party_id);
               log_debug_msg( 'cust_account_id       - '||ln_cust_account_id);
               log_debug_msg( 'cust_acct_site_id     - '||ln_cust_acct_site_id);


               ln_up_cust_account_role_id := NULL;
               ln_object_version_number   := NULL;

               SELECT cust_account_role_id,
                      object_version_number
               INTO   ln_up_cust_account_role_id,
                      ln_object_version_number
               FROM   hz_cust_account_roles
               WHERE  party_id                 = ln_relationship_party_id
               AND    status                   = 'A'
               AND    NVL(cust_account_id,0)   = NVL(ln_cust_account_id,0)
               AND    NVL(cust_acct_site_id,0) = NVL(ln_cust_acct_site_id,0);

               log_debug_msg( ' ');
               log_debug_msg( 'Record Exists !!');
               log_debug_msg( 'cust_account_role_id - '||ln_up_cust_account_role_id);

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  ln_up_cust_account_role_id := NULL;
                  ln_object_version_number   := NULL;
               WHEN TOO_MANY_ROWS THEN
                  log_debug_msg( 'Too many Account Relationships exist for the same Party Relationship');
                  lt_acct_contacts_tbl(i).role_interface_status := 6;
                  log_exception
                        (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'CREATE_CONTACT_ROLE'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => 'Too many Account Relationships exist for the same Party Relationship'
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                  RAISE le_skip_record;
            END;


            lt_acct_contacts_tbl(i).role_interface_status := 4;

            IF ln_up_cust_account_role_id IS NULL THEN

               ---------------
               -- Create Mode
               ---------------

               l_cust_acct_role_rec                       := l_df_cust_acct_role_rec;

               l_cust_acct_role_rec.party_id              := ln_relationship_party_id;
               l_cust_acct_role_rec.cust_account_id       := ln_cust_account_id;
               l_cust_acct_role_rec.cust_acct_site_id     := ln_cust_acct_site_id;
               l_cust_acct_role_rec.primary_flag          := lt_acct_contacts_tbl(i).primary_flag;
               l_cust_acct_role_rec.role_type             := lt_acct_contacts_tbl(i).role_type;
            -- l_cust_acct_role_rec.source_code           :=
               l_cust_acct_role_rec.attribute_category    := lt_acct_contacts_tbl(i).attribute_category;
               l_cust_acct_role_rec.attribute1            := lt_acct_contacts_tbl(i).attribute1;
               l_cust_acct_role_rec.attribute2            := lt_acct_contacts_tbl(i).attribute2;
               l_cust_acct_role_rec.attribute3            := lt_acct_contacts_tbl(i).attribute3;
               l_cust_acct_role_rec.attribute4            := lt_acct_contacts_tbl(i).attribute4;
               l_cust_acct_role_rec.attribute5            := lt_acct_contacts_tbl(i).attribute5;
               l_cust_acct_role_rec.attribute6            := lt_acct_contacts_tbl(i).attribute6;
               l_cust_acct_role_rec.attribute7            := lt_acct_contacts_tbl(i).attribute7;
               l_cust_acct_role_rec.attribute8            := lt_acct_contacts_tbl(i).attribute8;
               l_cust_acct_role_rec.attribute9            := lt_acct_contacts_tbl(i).attribute9;
               l_cust_acct_role_rec.attribute10           := lt_acct_contacts_tbl(i).attribute10;
               l_cust_acct_role_rec.attribute11           := lt_acct_contacts_tbl(i).attribute11;
               l_cust_acct_role_rec.attribute12           := lt_acct_contacts_tbl(i).attribute12;
               l_cust_acct_role_rec.attribute13           := lt_acct_contacts_tbl(i).attribute13;
               l_cust_acct_role_rec.attribute14           := lt_acct_contacts_tbl(i).attribute14;
               l_cust_acct_role_rec.attribute15           := lt_acct_contacts_tbl(i).attribute15;
               l_cust_acct_role_rec.attribute16           := lt_acct_contacts_tbl(i).attribute16;
               l_cust_acct_role_rec.attribute17           := lt_acct_contacts_tbl(i).attribute17;
               l_cust_acct_role_rec.attribute18           := lt_acct_contacts_tbl(i).attribute18;
               l_cust_acct_role_rec.attribute19           := lt_acct_contacts_tbl(i).attribute19;
               l_cust_acct_role_rec.attribute20           := lt_acct_contacts_tbl(i).attribute20;
            -- l_cust_acct_role_rec.attribute21           :=
            -- l_cust_acct_role_rec.attribute22           :=
            -- l_cust_acct_role_rec.attribute23           :=
            -- l_cust_acct_role_rec.attribute24           :=
            -- l_cust_acct_role_rec.attribute25           :=
               l_cust_acct_role_rec.orig_system_reference := lt_acct_contacts_tbl(i).contact_orig_system_reference;
               l_cust_acct_role_rec.orig_system           := lt_acct_contacts_tbl(i).contact_orig_system;
               l_cust_acct_role_rec.status                := lt_acct_contacts_tbl(i).status;
               l_cust_acct_role_rec.created_by_module     := lt_acct_contacts_tbl(i).created_by_module;
               l_cust_acct_role_rec.application_id        := lt_acct_contacts_tbl(i).program_application_id;

               -- Added on 30-July
               -- If current record is primary and there exists another primary, make the other record
               -- non primary

               IF NVL(l_cust_acct_role_rec.primary_flag, 'N') = 'Y' THEN

                  ln_pr_cust_account_role_id  := NULL;
                  ln_pr_object_version_number := NULL;

                  IF ln_cust_acct_site_id IS NULL THEN
                     BEGIN
                        SELECT cust_account_role_id,
                               object_version_number
                        INTO   ln_pr_cust_account_role_id,
                               ln_pr_object_version_number
                        FROM   hz_cust_account_roles
                        WHERE  cust_account_id       = ln_cust_account_id
                        AND    cust_acct_site_id IS NULL
                        AND    status                = 'A'
                        AND    primary_flag          = 'Y';


                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL;
                     END;
                  ELSE
                     BEGIN
                        SELECT cust_account_role_id,
                               object_version_number
                        INTO   ln_pr_cust_account_role_id,
                               ln_pr_object_version_number
                        FROM   hz_cust_account_roles
                        WHERE  cust_account_id       = ln_cust_account_id
                        AND    cust_acct_site_id     = ln_cust_acct_site_id
                        AND    status                = 'A'
                        AND    primary_flag          = 'Y';


                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL;
                     END;
                  END IF;


                  -- Call API TO make this record non primary
                  IF ln_pr_cust_account_role_id IS NOT NULL THEN

                     l_pr_cust_acct_role_rec                       := l_df_cust_acct_role_rec;

                     l_pr_cust_acct_role_rec.cust_account_role_id  := ln_pr_cust_account_role_id;
                     --l_pr_cust_acct_role_rec.party_id              := ln_relationship_party_id;
                     l_pr_cust_acct_role_rec.cust_account_id       := ln_cust_account_id;
                     --l_pr_cust_acct_role_rec.cust_acct_site_id     := ln_cust_acct_site_id;
                     --l_pr_cust_acct_role_rec.role_type             := lt_acct_contacts_tbl(i).role_type;
                     --l_pr_cust_acct_role_rec.status                := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).status);
                     l_pr_cust_acct_role_rec.primary_flag          := 'N';


                     HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role
                              (
                                  p_init_msg_list          => gv_init_msg_list,
                                  p_cust_account_role_rec  => l_pr_cust_acct_role_rec,
                                  p_object_version_number  => ln_pr_object_version_number,
                                  x_return_status          => lv_return_status,
                                  x_msg_count              => ln_msg_count,
                                  x_msg_data               => lv_msg_data
                              );

                     IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                        log_debug_msg( 'API successful.');
                        ln_records_success := ln_records_success + 1;
                        log_debug_msg( 'p_object_version_number : '||ln_pr_object_version_number);


                     ELSE
                        ln_msg_text := NULL;
                        IF ln_msg_count > 0 THEN
                           log_debug_msg( 'API returned Error.');
                           FOR counter IN 1..ln_msg_count
                           LOOP
                              ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                              log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                           END LOOP;
                           FND_MSG_PUB.Delete_Msg;
                           log_exception
                              (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                                ,p_source_system_code     => NULL
                                ,p_procedure_name         => 'CREATE_CONTACT'
                                ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                                ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                                ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                                ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                                ,p_batch_id               => p_batch_id
                                ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Primary update_cust_account_role API returned Error - '||ln_msg_text)
                                ,p_oracle_error_code      => NULL
                                ,p_oracle_error_msg       => NULL
                              );
                        END IF;
                     END IF;
                  END IF;
               END IF;

               log_debug_msg( 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role.');

               lv_return_status  := NULL;
               ln_msg_count      := 0;
               lv_msg_data       := NULL;

               HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role
                        (
                            p_init_msg_list          => gv_init_msg_list,
                            p_cust_account_role_rec  => l_cust_acct_role_rec,
                            x_cust_account_role_id   => ln_cust_account_role_id,
                            x_return_status          => lv_return_status,
                            x_msg_count              => ln_msg_count,
                            x_msg_data               => lv_msg_data
                        );

               IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  log_debug_msg( 'API successful.');
                  ln_records_success := ln_records_success + 1;
                  log_debug_msg( 'x_cust_account_role_id : '||ln_cust_account_role_id);

                  lt_acct_contacts_tbl(i).role_interface_status := 7;
                  --IF MOD(i,1000) = 0 THEN
                  --   COMMIT;
                  --END IF;
               ELSE
                  lt_acct_contacts_tbl(i).role_interface_status := 6;
                  ln_msg_text := NULL;
                  IF ln_msg_count > 0 THEN
                     log_debug_msg( 'API returned Error.');
                     FOR counter IN 1..ln_msg_count
                     LOOP
                        ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                        log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;
                     log_exception
                        (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'CREATE_CONTACT'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('create_cust_account_role API returned Error - '||ln_msg_text)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                  END IF;
               END IF;

            ELSE

               ---------------
               -- Update Mode
               ---------------
               l_cust_acct_role_rec                       := l_df_cust_acct_role_rec;

               l_cust_acct_role_rec.cust_account_role_id  := ln_up_cust_account_role_id;
               l_cust_acct_role_rec.party_id              := ln_relationship_party_id;
               l_cust_acct_role_rec.cust_account_id       := ln_cust_account_id;
               l_cust_acct_role_rec.cust_acct_site_id     := ln_cust_acct_site_id;
               l_cust_acct_role_rec.role_type             := lt_acct_contacts_tbl(i).role_type;
               l_cust_acct_role_rec.status                := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).status);
               l_cust_acct_role_rec.primary_flag          := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).primary_flag);
               l_cust_acct_role_rec.application_id        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_acct_contacts_tbl(i).program_application_id);
               l_cust_acct_role_rec.attribute_category    := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute_category);
               l_cust_acct_role_rec.attribute1            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute1);
               l_cust_acct_role_rec.attribute2            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute2);
               l_cust_acct_role_rec.attribute3            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute3);
               l_cust_acct_role_rec.attribute4            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute4);
               l_cust_acct_role_rec.attribute5            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute5);
               l_cust_acct_role_rec.attribute6            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute6);
               l_cust_acct_role_rec.attribute7            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute7);
               l_cust_acct_role_rec.attribute8            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute8);
               l_cust_acct_role_rec.attribute9            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute9);
               l_cust_acct_role_rec.attribute10           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute10);
               l_cust_acct_role_rec.attribute11           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute11);
               l_cust_acct_role_rec.attribute12           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute12);
               l_cust_acct_role_rec.attribute13           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute13);
               l_cust_acct_role_rec.attribute14           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute14);
               l_cust_acct_role_rec.attribute15           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute15);
               l_cust_acct_role_rec.attribute16           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute16);
               l_cust_acct_role_rec.attribute17           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute17);
               l_cust_acct_role_rec.attribute18           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute18);
               l_cust_acct_role_rec.attribute19           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute19);
               l_cust_acct_role_rec.attribute20           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).attribute20);

               -- Added on 25-July
               -- If current record is primary and there exists another primary, make the other record
               -- non primary

               IF NVL(l_cust_acct_role_rec.primary_flag, 'N') = 'Y' THEN

                  ln_pr_cust_account_role_id  := NULL;
                  ln_pr_object_version_number := NULL;

                  IF ln_cust_acct_site_id IS NULL THEN
                     BEGIN
                        SELECT cust_account_role_id,
                               object_version_number
                        INTO   ln_pr_cust_account_role_id,
                               ln_pr_object_version_number
                        FROM   hz_cust_account_roles
                        WHERE  cust_account_id       = ln_cust_account_id
                        AND    cust_acct_site_id IS NULL
                        AND    status                = 'A'
                        AND    primary_flag          = 'Y'
                        AND    cust_account_role_id <> ln_up_cust_account_role_id;

                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL;
                     END;
                  ELSE
                     BEGIN
                        SELECT cust_account_role_id,
                               object_version_number
                        INTO   ln_pr_cust_account_role_id,
                               ln_pr_object_version_number
                        FROM   hz_cust_account_roles
                        WHERE  cust_account_id       = ln_cust_account_id
                        AND    cust_acct_site_id     = ln_cust_acct_site_id
                        AND    status                = 'A'
                        AND    primary_flag          = 'Y'
                        AND    cust_account_role_id <> ln_up_cust_account_role_id;

                     EXCEPTION
                        WHEN OTHERS THEN
                           NULL;
                     END;
                  END IF;


                  -- Call API TO make this record non primary
                  IF ln_pr_cust_account_role_id IS NOT NULL THEN

                     l_pr_cust_acct_role_rec                       := l_df_cust_acct_role_rec;

                     l_pr_cust_acct_role_rec.cust_account_role_id  := ln_pr_cust_account_role_id;
                     --l_pr_cust_acct_role_rec.party_id              := ln_relationship_party_id;
                     l_pr_cust_acct_role_rec.cust_account_id       := ln_cust_account_id;
                     --l_pr_cust_acct_role_rec.cust_acct_site_id     := ln_cust_acct_site_id;
                     --l_pr_cust_acct_role_rec.role_type             := lt_acct_contacts_tbl(i).role_type;
                     --l_pr_cust_acct_role_rec.status                := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_acct_contacts_tbl(i).status);
                     l_pr_cust_acct_role_rec.primary_flag          := 'N';


                     HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role
                              (
                                  p_init_msg_list          => gv_init_msg_list,
                                  p_cust_account_role_rec  => l_pr_cust_acct_role_rec,
                                  p_object_version_number  => ln_pr_object_version_number,
                                  x_return_status          => lv_return_status,
                                  x_msg_count              => ln_msg_count,
                                  x_msg_data               => lv_msg_data
                              );

                     IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                        log_debug_msg( 'API successful.');
                        ln_records_success := ln_records_success + 1;
                        log_debug_msg( 'p_object_version_number : '||ln_pr_object_version_number);


                     ELSE
                        ln_msg_text := NULL;
                        IF ln_msg_count > 0 THEN
                           log_debug_msg( 'API returned Error.');
                           FOR counter IN 1..ln_msg_count
                           LOOP
                              ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                              log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                           END LOOP;
                           FND_MSG_PUB.Delete_Msg;
                           log_exception
                              (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                                ,p_source_system_code     => NULL
                                ,p_procedure_name         => 'UPDATE_CONTACT'
                                ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                                ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                                ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                                ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                                ,p_batch_id               => p_batch_id
                                ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Primary update_cust_account_role API returned Error - '||ln_msg_text)
                                ,p_oracle_error_code      => NULL
                                ,p_oracle_error_msg       => NULL
                              );
                        END IF;
                     END IF;
                  END IF;
               END IF;


               log_debug_msg( 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role.');

               lv_return_status  := NULL;
               ln_msg_count      := 0;
               lv_msg_data       := NULL;

               HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role
                        (
                            p_init_msg_list          => gv_init_msg_list,
                            p_cust_account_role_rec  => l_cust_acct_role_rec,
                            p_object_version_number  => ln_object_version_number,
                            x_return_status          => lv_return_status,
                            x_msg_count              => ln_msg_count,
                            x_msg_data               => lv_msg_data
                        );

               IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  log_debug_msg( 'API successful.');
                  ln_records_success := ln_records_success + 1;
                  log_debug_msg( 'p_object_version_number : '||ln_object_version_number);

                  lt_acct_contacts_tbl(i).role_interface_status := 7;
                  --IF MOD(i,1000) = 0 THEN
                  --   COMMIT;
                  --END IF;
               ELSE
                  lt_acct_contacts_tbl(i).role_interface_status := 6;
                  ln_msg_text := NULL;
                  IF ln_msg_count > 0 THEN
                     log_debug_msg( 'API returned Error.');
                     FOR counter IN 1..ln_msg_count
                     LOOP
                        ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                        log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                     END LOOP;
                     FND_MSG_PUB.Delete_Msg;
                     log_exception
                        (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'UPDATE_CONTACT'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('update_cust_account_role API returned Error - '||ln_msg_text)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                  END IF;
               END IF;
            END IF;

         EXCEPTION
            WHEN le_skip_record THEN
               NULL;
            WHEN OTHERS THEN
               log_debug_msg( 'Unepected Error - '||SQLERRM);
               lt_acct_contacts_tbl(i).role_interface_status := 6;
               log_exception
                        (  p_record_control_id      => lt_acct_contacts_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'PROCESS_CONTACT_ROLE'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_acct_contacts_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Unexpected Error - '||SQLERRM)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
         END;

         lt_upd_record_tbl(i)    := lt_acct_contacts_tbl(i).record_id;
         lt_upd_interface_tbl(i) := lt_acct_contacts_tbl(i).role_interface_status;

      END LOOP;

      IF lt_acct_contacts_tbl.LAST > 0 THEN
         FORALL i IN 1 .. lt_acct_contacts_tbl.LAST
         UPDATE xxod_hz_imp_acct_contact_stg
         SET    role_interface_status  = lt_upd_interface_tbl(i)
         WHERE  record_id              = lt_upd_record_tbl(i);
         COMMIT;
      END IF;
      --------------------
      -- Clear the tables
      --------------------
      lt_upd_interface_tbl.DELETE;
      lt_upd_record_tbl.DELETE;
      lt_acct_contacts_tbl.DELETE;
      EXIT WHEN lc_fetch_contact_roles_cur%NOTFOUND;
   END LOOP;
   CLOSE lc_fetch_contact_roles_cur;

   ln_records_failed := (ln_records_read - ln_records_success);

   log_debug_msg( ' ');
   log_debug_msg( ' ');
   log_debug_msg( 'Record Statistics after Processing Contact Roles ');
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( 'Staging Table - XXOD_HZ_IMP_ACCT_CONTACT_STG ');
   log_debug_msg( 'No Of Records Read                   - '||ln_records_read);
   log_debug_msg( 'No Of Records Processesd Succesfully - '||ln_records_success);
   log_debug_msg( 'No Of Records Failed                 - '||ln_records_failed);
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( ' ');
   log_debug_msg( ' ');

   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Contact Roles ');
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, 'Staging Table - XXOD_HZ_IMP_ACCT_CONTACT_STG ');
   fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
   fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
   fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');


   XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc
         (  p_conversion_id                => 00242.2
           ,p_batch_id                     => p_batch_id
           ,p_num_bus_objs_processed       => 0
         );

   XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (  p_conc_mst_req_id              => gt_request_id
           ,p_batch_id                     => p_batch_id
           ,p_conversion_id                => 00242.2
           ,p_num_bus_objs_failed_valid    => 0
           ,p_num_bus_objs_failed_process  => ln_records_success
           ,p_num_bus_objs_succ_process    => ln_records_failed
         );

   x_retcode := 0;
   log_debug_msg( '-------------------------------------');
   log_debug_msg( 'End of Create Contact Procedure.');
   log_debug_msg( ' ');
   log_debug_msg( ' ');
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_contact - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_contact - '||SQLERRM;
END create_contact_worker;

-- +===================================================================+
-- | Name        :  create_role_resp_worker                            |
-- | Description :  This procedure is invoked from the create contact  |
-- |                main procedure. This would create role             |
-- |                responsibilty if roles are created fetching data   |
-- |                records from staging table                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_role_resp_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      )
IS

CURSOR lc_fetch_role_resp_cur
IS
SELECT *
FROM   xxod_hz_imp_acct_cnttroles_stg
WHERE  interface_status IN ('1','4','6')
AND    MOD(NVL(TO_NUMBER(REGEXP_SUBSTR(account_orig_system_reference, '[123456789]{1,7}')), ASCII(account_orig_system_reference)), fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
AND    batch_id = p_batch_id;

TYPE  lt_role_resp_tbl_type       IS TABLE OF xxod_hz_imp_acct_cnttroles_stg%ROWTYPE INDEX BY BINARY_INTEGER;
lt_role_resp_tbl                  lt_role_resp_tbl_type;

TYPE lt_upd_tbl_type              IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lt_upd_record_tbl                 lt_upd_tbl_type;
lt_upd_interface_tbl              lt_upd_tbl_type;


lv_record_valid_flag              VARCHAR2(1);
ln_cust_account_role_id           hz_orig_sys_references.owner_table_id%TYPE;
ln_osr_retcode                    NUMBER;
lv_osr_errbuf                     VARCHAR2(2000);
lv_return_status                  VARCHAR2(1);
ln_msg_count                      NUMBER;
lv_msg_data                       VARCHAR2(2000);
l_role_responsibility_rec         HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;
l_df_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;
le_skip_record                    EXCEPTION;
le_skip_procedure                 EXCEPTION;
ln_responsibility_id              hz_role_responsibility.responsibility_id%TYPE;
ln_records_read                   NUMBER;
ln_records_success                NUMBER;
ln_records_failed                 NUMBER;
ln_object_version_number          NUMBER;
ln_up_responsibility_id           hz_role_responsibility.responsibility_id%TYPE;
ln_msg_text                       VARCHAR2(32000);
ln_exists                         NUMBER;
ln_cust_acct_site_id              NUMBER;

BEGIN

   log_debug_msg( ' ');
   log_debug_msg( '*************************************************');
   log_debug_msg( '* Start of Create Role Responsibilty Procedure. *');
   log_debug_msg( '*************************************************');
   log_debug_msg( ' ');
   ln_records_read    := 0;
   ln_records_success := 0;
   ln_records_failed  := 0;

   OPEN  lc_fetch_role_resp_cur;
   LOOP
      FETCH lc_fetch_role_resp_cur BULK COLLECT INTO lt_role_resp_tbl LIMIT gn_bulk_fetch_limit;

      IF lt_role_resp_tbl.count = 0 THEN
         log_debug_msg( 'No records exist in the staging table for batch_id - '||p_batch_id);
         RAISE le_skip_procedure;
      END IF;

      FOR i IN lt_role_resp_tbl.FIRST .. lt_role_resp_tbl.LAST

      LOOP

         BEGIN

            log_debug_msg( '-----------------------------------------------');
            log_debug_msg('RECORD_ID:'||lt_role_resp_tbl(i).record_id);
            ln_records_read := ln_records_read + 1;
            lv_record_valid_flag := 'Y';

            -----------------------------------------
            -- Validations for the record
            -----------------------------------------
            IF lt_role_resp_tbl(i).contact_orig_system IS NULL THEN
               lv_record_valid_flag := 'N';
               log_debug_msg( 'Error - contact_orig_system is null.');
               log_exception
                  (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM'
                    ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system
                    ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'contact_orig_system is null'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
            END IF;

            IF lt_role_resp_tbl(i).contact_orig_system_reference IS NULL THEN
               lv_record_valid_flag := 'N';
               log_debug_msg( 'Error - contact_orig_system_reference is null.');
               log_exception
                  (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                    ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                    ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'contact_orig_system_reference is null'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
            END IF;
            -------------------------------
            -- Fetch Cust Account Role Id
            -------------------------------
            ln_cust_account_role_id := NULL;
            ln_osr_retcode := NULL;
            lv_osr_errbuf  := NULL;

            BEGIN

               IF lt_role_resp_tbl(i).acct_site_orig_sys_reference IS NOT NULL THEN

                  XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                     (  p_orig_system        => lt_role_resp_tbl(i).acct_site_orig_system,
                        p_orig_sys_reference => lt_role_resp_tbl(i).acct_site_orig_sys_reference,
                        p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
                        x_owner_table_id     => ln_cust_acct_site_id,
                        x_retcode            => ln_osr_retcode,
                        x_errbuf             => lv_osr_errbuf
                     );

                  IF ln_cust_acct_site_id IS NULL THEN
                     log_debug_msg( 'Error while fetching cust_account_site_id - acct_site_orig_sys_reference is invalid');
                     log_debug_msg( 'acct_site_orig_sys_reference - '||lt_role_resp_tbl(i).acct_site_orig_sys_reference);
                     lt_role_resp_tbl(i).interface_status := 6;
                     log_exception
                        (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                          ,p_staging_column_name    => 'ACCT_SITE_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_role_resp_tbl(i).acct_site_orig_system
                          ,p_source_system_ref      => lt_role_resp_tbl(i).acct_site_orig_sys_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => 'Error while fetching cust_account_site_id - acct_site_orig_sys_reference is invalid'
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                     RAISE le_skip_record;
                  END IF;

                  BEGIN
                     SELECT 1
                     INTO   ln_exists
                     FROM   hz_cust_acct_sites
                     WHERE  cust_acct_site_id = ln_cust_acct_site_id;

                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        lt_role_resp_tbl(i).interface_status := 4;
                        RAISE le_skip_record;
                  END;


                  SELECT hcar.cust_account_role_id
                  INTO   ln_cust_account_role_id
                  FROM   hz_orig_sys_references     h1,
                         hz_orig_sys_references     h2,
                         hz_cust_account_roles      hcar
                  WHERE  h1.orig_system             = lt_role_resp_tbl(i).account_orig_system
                  AND    h1.orig_system_reference   = lt_role_resp_tbl(i).account_orig_system_reference
                  AND    h1.owner_table_name        = 'HZ_CUST_ACCOUNTS'
                  AND    h1.status                  = 'A'
                  AND    h2.orig_system             = lt_role_resp_tbl(i).acct_site_orig_system
                  AND    h2.orig_system_reference   = lt_role_resp_tbl(i).acct_site_orig_sys_reference
                  AND    h2.owner_table_name        = 'HZ_CUST_ACCT_SITES_ALL'
                  AND    h2.status                  = 'A'
                  AND    hcar.cust_account_id       = h1.owner_table_id
                  AND    hcar.cust_acct_site_id     = h2.owner_table_id
                  AND    hcar.status                = 'A'
                  AND    hcar.orig_system_reference = lt_role_resp_tbl(i).contact_orig_system_reference;

               ELSE
                  SELECT hcar.cust_account_role_id
                  INTO   ln_cust_account_role_id
                  FROM   hz_orig_sys_references     h1,
                         hz_cust_account_roles      hcar
                  WHERE  h1.orig_system             = lt_role_resp_tbl(i).account_orig_system
                  AND    h1.orig_system_reference   = lt_role_resp_tbl(i).account_orig_system_reference
                  AND    h1.owner_table_name        = 'HZ_CUST_ACCOUNTS'
                  AND    h1.status                  = 'A'
                  AND    hcar.cust_account_id       = h1.owner_table_id
                  AND    hcar.status                = 'A'
                  AND    hcar.orig_system_reference = lt_role_resp_tbl(i).contact_orig_system_reference
                  AND    hcar.cust_acct_site_id    IS NULL;

               END IF;

            EXCEPTION
            --IF ln_cust_account_role_id IS NULL THEN
               WHEN NO_DATA_FOUND THEN
                  lv_record_valid_flag := 'N';
                  log_debug_msg( 'Error while fetching cust_account_role_id - '||SQLERRM);
                  log_debug_msg( 'contact_orig_system_reference - '||lt_role_resp_tbl(i).contact_orig_system_reference);
                  log_exception
                     (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                       ,p_source_system_code     => NULL
                       ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                       ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                       ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                       ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                       ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                       ,p_batch_id               => p_batch_id
                       ,p_exception_log          => 'Error while fetching cust_account_role_id - '||SQLERRM
                       ,p_oracle_error_code      => NULL
                       ,p_oracle_error_msg       => NULL
                     );
            --END IF;
            END;

            IF lv_record_valid_flag = 'N' THEN
               log_debug_msg( 'Record Validation Failed');
               log_debug_msg( 'Skip Processing for this record..');
               lt_role_resp_tbl(i).interface_status := 6;
               RAISE le_skip_record;
            END IF;

            --------------------------------------------
            -- Check if record already exists in Oracle
            --------------------------------------------
            BEGIN

               ln_up_responsibility_id  := NULL;
               ln_object_version_number := NULL;

               IF lt_role_resp_tbl(i).responsibility_type <> 'SELF_SERVICE_USER' THEN

                  SELECT responsibility_id,
                         object_version_number
                  INTO   ln_up_responsibility_id,
                         ln_object_version_number
                  FROM   hz_role_responsibility
                  WHERE  /*orig_system_reference = lt_role_resp_tbl(i).contact_orig_system_reference
                  AND*/  cust_account_role_id  = ln_cust_account_role_id
                  AND    responsibility_type   = lt_role_resp_tbl(i).responsibility_type;

                ELSE

                  BEGIN

                      SELECT responsibility_id,
                             object_version_number
                      INTO   ln_up_responsibility_id,
                             ln_object_version_number
                      FROM   hz_role_responsibility
                      WHERE  /*orig_system_reference = lt_role_resp_tbl(i).contact_orig_system_reference
                      AND*/  cust_account_role_id  = ln_cust_account_role_id
                      AND    responsibility_type = 'SELF_SERVICE_USER';

                  EXCEPTION WHEN NO_DATA_FOUND THEN

                      SELECT responsibility_id,
                             object_version_number
                      INTO   ln_up_responsibility_id,
                             ln_object_version_number
                      FROM   hz_role_responsibility
                      WHERE  /*orig_system_reference = lt_role_resp_tbl(i).contact_orig_system_reference
                      AND*/  cust_account_role_id  = ln_cust_account_role_id
                      AND    responsibility_type = 'REVOKED_SELF_SERVICE_ROLE';

                  END;

                END IF;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  ln_up_responsibility_id  := NULL;
                  ln_object_version_number := NULL;
               WHEN TOO_MANY_ROWS THEN
                  lt_role_resp_tbl(i).interface_status            := 6;
                  log_exception
                        (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Too many rows found for the Contact OSR and Responsibility Type')
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                  RAISE le_skip_record;
            END;

            lt_role_resp_tbl(i).interface_status            := 4;

            IF ln_up_responsibility_id IS NULL THEN
               ---------------
               -- Create Mode
               ---------------
               l_role_responsibility_rec                       := l_df_role_responsibility_rec;
               l_role_responsibility_rec.cust_account_role_id  := ln_cust_account_role_id;
               l_role_responsibility_rec.responsibility_type   := lt_role_resp_tbl(i).responsibility_type;
               l_role_responsibility_rec.primary_flag          := lt_role_resp_tbl(i).primary_flag;
               l_role_responsibility_rec.attribute_category    := lt_role_resp_tbl(i).attribute_category;
               l_role_responsibility_rec.attribute1            := lt_role_resp_tbl(i).attribute1;
               l_role_responsibility_rec.attribute2            := lt_role_resp_tbl(i).attribute2;
               l_role_responsibility_rec.attribute3            := lt_role_resp_tbl(i).attribute3;
               l_role_responsibility_rec.attribute4            := lt_role_resp_tbl(i).attribute4;
               l_role_responsibility_rec.attribute5            := lt_role_resp_tbl(i).attribute5;
               l_role_responsibility_rec.attribute6            := lt_role_resp_tbl(i).attribute6;
               l_role_responsibility_rec.attribute7            := lt_role_resp_tbl(i).attribute7;
               l_role_responsibility_rec.attribute8            := lt_role_resp_tbl(i).attribute8;
               l_role_responsibility_rec.attribute9            := lt_role_resp_tbl(i).attribute9;
               l_role_responsibility_rec.attribute10           := lt_role_resp_tbl(i).attribute10;
               l_role_responsibility_rec.attribute11           := lt_role_resp_tbl(i).attribute11;
               l_role_responsibility_rec.attribute12           := lt_role_resp_tbl(i).attribute12;
               l_role_responsibility_rec.attribute13           := lt_role_resp_tbl(i).attribute13;
               l_role_responsibility_rec.attribute14           := lt_role_resp_tbl(i).attribute14;
               l_role_responsibility_rec.attribute15           := lt_role_resp_tbl(i).attribute15;
               l_role_responsibility_rec.orig_system_reference := lt_role_resp_tbl(i).contact_orig_system_reference;
               l_role_responsibility_rec.created_by_module     := lt_role_resp_tbl(i).created_by_module;
               l_role_responsibility_rec.application_id        := lt_role_resp_tbl(i).program_application_id;

               log_debug_msg( 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility.');

               lv_return_status  := NULL;
               ln_msg_count      := 0;
               lv_msg_data       := NULL;

               HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility
                  (  p_init_msg_list            => gv_init_msg_list,
                     p_role_responsibility_rec  => l_role_responsibility_rec,
                     x_responsibility_id        => ln_responsibility_id,
                     x_return_status            => lv_return_status,
                     x_msg_count                => ln_msg_count,
                     x_msg_data                 => lv_msg_data
                  );

               IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  log_debug_msg( 'API successful.');
                  log_debug_msg( 'x_responsibility_id : '||ln_responsibility_id);
                  lt_role_resp_tbl(i).interface_status := 7;
                  ln_records_success := ln_records_success + 1;

               ELSE
                  lt_role_resp_tbl(i).interface_status := 6;
                  ln_msg_text := NULL;
                  IF ln_msg_count > 0 THEN
                     log_debug_msg( 'API returned Error.');
                     FOR counter IN 1..ln_msg_count
                     LOOP
                        ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                        log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                     END LOOP;
                     log_exception
                        (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'CREATE_ROLE_RESPONSIBILITY'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('create_role_responsibility API returned Error - '||ln_msg_text)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                     FND_MSG_PUB.Delete_Msg;
                  END IF;
               END IF;
            ELSE
               ---------------
               -- Update Mode
               ---------------
               l_role_responsibility_rec                       := l_df_role_responsibility_rec;
               l_role_responsibility_rec.responsibility_id     := ln_up_responsibility_id;
               l_role_responsibility_rec.cust_account_role_id  := ln_cust_account_role_id;
               l_role_responsibility_rec.responsibility_type   := lt_role_resp_tbl(i).responsibility_type;
               l_role_responsibility_rec.primary_flag          := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).primary_flag);
               l_role_responsibility_rec.attribute_category    := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute_category);
               l_role_responsibility_rec.attribute1            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute1);
               l_role_responsibility_rec.attribute2            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute2);
               l_role_responsibility_rec.attribute3            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute3);
               l_role_responsibility_rec.attribute4            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute4);
               l_role_responsibility_rec.attribute5            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute5);
               l_role_responsibility_rec.attribute6            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute6);
               l_role_responsibility_rec.attribute7            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute7);
               l_role_responsibility_rec.attribute8            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute8);
               l_role_responsibility_rec.attribute9            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute9);
               l_role_responsibility_rec.attribute10           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute10);
               l_role_responsibility_rec.attribute11           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute11);
               l_role_responsibility_rec.attribute12           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute12);
               l_role_responsibility_rec.attribute13           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute13);
               l_role_responsibility_rec.attribute14           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute14);
               l_role_responsibility_rec.attribute15           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).attribute15);
               --l_role_responsibility_rec.created_by_module     := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_role_resp_tbl(i).created_by_module);
               --l_role_responsibility_rec.application_id        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_role_resp_tbl(i).program_application_id);


               log_debug_msg( 'Calling API HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility.');

               lv_return_status  := NULL;
               ln_msg_count      := 0;
               lv_msg_data       := NULL;

               HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
                  (  p_init_msg_list            => gv_init_msg_list,
                     p_role_responsibility_rec  => l_role_responsibility_rec,
                     p_object_version_number    => ln_object_version_number,
                     x_return_status            => lv_return_status,
                     x_msg_count                => ln_msg_count,
                     x_msg_data                 => lv_msg_data
                  );

               IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                  log_debug_msg( 'API successful.');
                  log_debug_msg( 'p_object_version_number : '||ln_object_version_number);
                  lt_role_resp_tbl(i).interface_status := 7;
                  ln_records_success := ln_records_success + 1;

               ELSE
                  lt_role_resp_tbl(i).interface_status := 6;
                  ln_msg_text := NULL;
                  IF ln_msg_count > 0 THEN
                     log_debug_msg( 'API returned Error.');
                     FOR counter IN 1..ln_msg_count
                     LOOP
                        ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                        log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                     END LOOP;
                     log_exception
                        (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'UPDATE_ROLE_RESPONSIBILITY'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('update_role_responsibility API returned Error - '||ln_msg_text)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                     FND_MSG_PUB.Delete_Msg;
                  END IF;
               END IF;
            END IF;
         EXCEPTION
            WHEN le_skip_record THEN
               NULL;
            WHEN OTHERS THEN
               log_debug_msg( 'Unexpected Error while processing the record - '||SQLERRM);
               lt_role_resp_tbl(i).interface_status := 6;
               log_exception
                        (  p_record_control_id      => lt_role_resp_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'UPDATE_ROLE_RESPONSIBILITY'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG'
                          ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_source_system_ref      => lt_role_resp_tbl(i).contact_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('Unexpected Error while processing the record - '||SQLERRM)
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
         END;

         lt_upd_record_tbl(i)    := lt_role_resp_tbl(i).record_id;
         lt_upd_interface_tbl(i) := lt_role_resp_tbl(i).interface_status;

      END LOOP;

      IF lt_role_resp_tbl.LAST > 0 THEN

         FORALL i IN 1 .. lt_role_resp_tbl.last
         UPDATE xxod_hz_imp_acct_cnttroles_stg
         SET    interface_status     = lt_upd_interface_tbl(i)
         WHERE  record_id            = lt_upd_record_tbl(i);

         COMMIT;

      END IF;
      --------------------
      -- Clear the tables
      --------------------
      lt_upd_interface_tbl.DELETE;
      lt_upd_record_tbl.DELETE;
      lt_role_resp_tbl.DELETE;
      EXIT WHEN lc_fetch_role_resp_cur%NOTFOUND;
   END LOOP;

   CLOSE lc_fetch_role_resp_cur;

   ln_records_failed := (ln_records_read - ln_records_success);

   log_debug_msg( ' ');
   log_debug_msg( ' ');
   log_debug_msg( 'Record Statistics after Processing Role Responsibilty ');
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( 'Staging Table - XXOD_HZ_IMP_ACCT_CNTTROLES_STG ');
   log_debug_msg( 'No Of Records Read                   - '||ln_records_read);
   log_debug_msg( 'No Of Records Processesd Succesfully - '||ln_records_success);
   log_debug_msg( 'No Of Records Failed                 - '||ln_records_failed);
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( ' ');
   log_debug_msg( ' ');

   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Role Responsibilty ');
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, 'Staging Table - XXOD_HZ_IMP_ACCT_CNTTROLES_STG ');
   fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
   fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
   fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');

   XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc
         (  p_conversion_id                => 00242.3
           ,p_batch_id                     => p_batch_id
           ,p_num_bus_objs_processed       => 0
         );
   XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (  p_conc_mst_req_id              => gt_request_id
           ,p_batch_id                     => p_batch_id
           ,p_conversion_id                => 00242.3
           ,p_num_bus_objs_failed_valid    => 0
           ,p_num_bus_objs_failed_process  => ln_records_success
           ,p_num_bus_objs_succ_process    => ln_records_failed
         );

   x_retcode := 0;

   log_debug_msg( '---------------------------------------------');
   log_debug_msg( 'End of create_role_responsibility Procedure.');
   log_debug_msg( ' ');
   log_debug_msg( ' ');
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_role_responsibility - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_role_responsibility - '||SQLERRM;
END create_role_resp_worker;

-- +===================================================================+
-- | Name        :  create_contact                                     |
-- | Description :  This procedure is invoked from the create contact  |
-- |                role CM. This would create customer account roles  |
-- |                fetching data records from staging table           |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_contact
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      )
IS
lt_conc_request_id            NUMBER;
ln_no_of_workers              NUMBER;
le_skip_process               EXCEPTION;
BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_process;
   END IF;

   ln_no_of_workers := fnd_profile.value('XX_CDH_CONV_WORKERS');

   FOR i IN 1..ln_no_of_workers
   LOOP

      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONTACT_ROLE_WORKER',
                                        description => i,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id,
                                        argument2   => i
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'Customer Contact Role Worker '||i||' Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'Customer Contact Role Worker '||i||' Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'Customer Contact Role Worker '||i||' Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

   END LOOP;

EXCEPTION
   WHEN le_skip_process THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_contact - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_contact - '||SQLERRM;

END create_contact;

-- +===================================================================+
-- | Name        :  create_role_responsibility                         |
-- | Description :  This procedure is invoked from the create contact  |
-- |                role CM. This would create customer account roles  |
-- |                fetching data records from staging table           |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_role_responsibility
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      )
IS
lt_conc_request_id            NUMBER;
ln_no_of_workers              NUMBER;
le_skip_process               EXCEPTION;
BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_process;
   END IF;

   ln_no_of_workers := fnd_profile.value('XX_CDH_CONV_WORKERS');

   FOR i IN 1..ln_no_of_workers
   LOOP

      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_ROLE_RESP_WORKER',
                                        description => i,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id,
                                        argument2   => i
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'Customer Contact Role Responsibility Worker '||i||' Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'Customer Contact Role Responsibility Worker '||i||' Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'Customer Contact Role Responsibility Worker '||i||' Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

   END LOOP;

EXCEPTION
   WHEN le_skip_process THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_role_responsibility - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_role_responsibility - '||SQLERRM;

END create_role_responsibility;


-- +===================================================================+
-- | Name        :  create_contact_points                              |
-- | Description :  This procedure is invoked from the create contact  |
-- |                main procedure. This would create contact points   |
-- |                fetching data records from staging table           |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_contact_points
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_process_yn        IN  VARCHAR2
      )
IS
lt_conc_request_id            NUMBER;
ln_no_of_workers              NUMBER;
le_skip_process               EXCEPTION;
BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_process;
   END IF;

   ln_no_of_workers := fnd_profile.value('XX_CDH_CONV_WORKERS');

   FOR i IN 1..ln_no_of_workers
   LOOP

      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONTACT_PT_WORKER',
                                        description => i,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id,
                                        argument2   => i
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'Customer Contact Point Worker '||i||' Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'Customer Contact Point Worker '||i||' Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'Customer Contact Point Worker '||i||' Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

   END LOOP;

EXCEPTION
   WHEN le_skip_process THEN
      x_retcode := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_contact_points - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_contact_points - '||SQLERRM;

END create_contact_points;

-- +===================================================================+
-- | Name        :  create_contact_point_worker                        |
-- | Description :  This procedure is invoked from the create contact  |
-- |                main procedure. This would create contact points   |
-- |                fetching data records from staging table           |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_contact_point_worker
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_batch_id          IN  NUMBER,
         p_worker_id         IN  NUMBER
      )
IS

CURSOR lc_fetch_contact_pts_cur
IS
SELECT *
FROM   xxod_hz_imp_contactpts_stg
WHERE  interface_status IN ('1','4','6')
AND    batch_id = p_batch_id
AND     MOD(NVL(TO_NUMBER(REGEXP_SUBSTR(contact_orig_system_reference, '[123456789]{1,7}')), ASCII(contact_orig_system_reference)), fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
--AND    mod(ascii(contact_orig_system_reference),fnd_profile.value('XX_CDH_CONV_WORKERS')) = DECODE(p_worker_id,fnd_profile.value('XX_CDH_CONV_WORKERS'),0,p_worker_id)
;

CURSOR lc_fetch_rel_party_id_cur
         ( p_org_contact_id IN NUMBER )
IS
SELECT hr.party_id
FROM   hz_relationships hr,
       hz_org_contacts  hoc
WHERE  hoc.org_contact_id = p_org_contact_id
AND    hr.relationship_id = hoc.party_relationship_id
AND    hr.status          = 'A';


TYPE  lt_contact_points_tbl_type IS TABLE OF xxod_hz_imp_contactpts_stg%ROWTYPE INDEX BY BINARY_INTEGER;
lt_contact_points_tbl            lt_contact_points_tbl_type;

TYPE lt_upd_tbl_type             IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
lt_upd_record_tbl                lt_upd_tbl_type;
lt_upd_interface_tbl             lt_upd_tbl_type;

l_contact_point_rec              HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
l_edi_rec                        HZ_CONTACT_POINT_V2PUB.edi_rec_type;
l_eft_rec                        HZ_CONTACT_POINT_V2PUB.eft_rec_type;
l_email_rec                      HZ_CONTACT_POINT_V2PUB.email_rec_type;
l_phone_rec                      HZ_CONTACT_POINT_V2PUB.phone_rec_type;
l_telex_rec                      HZ_CONTACT_POINT_V2PUB.telex_rec_type;
l_web_rec                        HZ_CONTACT_POINT_V2PUB.web_rec_type;
l_df_contact_point_rec           HZ_CONTACT_POINT_V2PUB.contact_point_rec_type;
l_df_edi_rec                     HZ_CONTACT_POINT_V2PUB.edi_rec_type;
l_df_eft_rec                     HZ_CONTACT_POINT_V2PUB.eft_rec_type;
l_df_email_rec                   HZ_CONTACT_POINT_V2PUB.email_rec_type;
l_df_phone_rec                   HZ_CONTACT_POINT_V2PUB.phone_rec_type;
l_df_telex_rec                   HZ_CONTACT_POINT_V2PUB.telex_rec_type;
l_df_web_rec                     HZ_CONTACT_POINT_V2PUB.web_rec_type;
le_skip_record                   EXCEPTION;
le_skip_procedure                EXCEPTION;
lv_record_valid_flag             VARCHAR2(1);
ln_relationship_party_id         hz_parties.party_id%TYPE;
ln_osr_retcode                   NUMBER;
lv_osr_errbuf                    VARCHAR2(2000);
lv_return_status                 VARCHAR2(10);
ln_msg_count                     NUMBER;
lv_msg_data                      VARCHAR2(2000);
ln_contact_point_id              hz_contact_points.contact_point_id%TYPE;
ln_records_read                  NUMBER;
ln_records_success               NUMBER;
ln_records_failed                NUMBER;
ln_org_contact_id                NUMBER;
ln_up_contact_point_id           NUMBER;
ln_object_version_number         NUMBER;
ln_msg_text                      VARCHAR2(32000);


BEGIN

   log_debug_msg( ' ');
   log_debug_msg( '********************************************');
   log_debug_msg( '* Start of Create Contact Point Procedure. *');
   log_debug_msg( '********************************************');
   log_debug_msg( ' ');
   ln_records_read    := 0;
   ln_records_success := 0;
   ln_records_failed  := 0;

   -- We use TCA V2 APIs that will trigger realtime updates under this condition:
   -- after DQM Staging is complete and when DQM Synchronization mode is not disabled (Realtime or batch goes in as realtime).
   -- HZ_CONTACT_POINT_V2PUB calls HZ_DQM_SYNC.sync_contact_point.
   -- HZ_DQM_SYNC API specifically indicates that the call below can be used if the API is used in batch mode.
   -- Realtime updates from contact point for conversion batches after DQM Staging is complete.
   HZ_DQM_SYNC.SET_TO_BATCH_SYNC;



   OPEN  lc_fetch_contact_pts_cur;
   LOOP

      FETCH lc_fetch_contact_pts_cur BULK COLLECT INTO lt_contact_points_tbl LIMIT gn_bulk_fetch_limit;

      IF lt_contact_points_tbl.count = 0 THEN
         log_debug_msg( 'No records exist in the staging table for batch_id - '||p_batch_id);
         RAISE le_skip_procedure;
      END IF;

      FOR i IN lt_contact_points_tbl.FIRST .. lt_contact_points_tbl.LAST

      LOOP

         BEGIN
            log_debug_msg( '-----------------------------------------------');
            log_debug_msg( 'RECORD_ID:'||lt_contact_points_tbl(i).record_id);
            ln_records_read := ln_records_read + 1;

            --------------------------------------------
            -- Check if record already exists in Oracle
            --------------------------------------------
            ln_up_contact_point_id     := NULL;
            ln_osr_retcode             := NULL;
            lv_osr_errbuf              := NULL;

            XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                  (  p_orig_system        => lt_contact_points_tbl(i).cp_orig_system,
                     p_orig_sys_reference => lt_contact_points_tbl(i).cp_orig_system_reference,
                     p_owner_table_name   => 'HZ_CONTACT_POINTS',
                     x_owner_table_id     => ln_up_contact_point_id,
                     x_retcode            => ln_osr_retcode,
                     x_errbuf             => lv_osr_errbuf
                  );

            lv_record_valid_flag := 'Y';

            -----------------------------------------
            -- Validations for the record
            -----------------------------------------
            IF lt_contact_points_tbl(i).contact_orig_system IS NULL THEN
               lv_record_valid_flag := 'N';
               log_debug_msg( 'Error - contact_orig_system is null.');
               log_exception
                  (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_CONTACT_POINTS'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM'
                    ,p_staging_column_value   => lt_contact_points_tbl(i).contact_orig_system
                    ,p_source_system_ref      => lt_contact_points_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'contact_orig_system is null'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
            END IF;

            IF lt_contact_points_tbl(i).contact_orig_system_reference IS NULL THEN
               lv_record_valid_flag := 'N';
               log_debug_msg( 'Error - contact_orig_system_reference is null.');
               log_exception
                  (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_CONTACT_POINTS'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                    ,p_staging_column_value   => lt_contact_points_tbl(i).contact_orig_system_reference
                    ,p_source_system_ref      => lt_contact_points_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'contact_orig_system_reference is null'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
            END IF;
            -------------------------------
            -- Fetch Relationship Party Id
            -------------------------------
            ln_org_contact_id        := NULL;
            ln_relationship_party_id := NULL;
            ln_osr_retcode           := NULL;
            lv_osr_errbuf            := NULL;

            XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
                  (  p_orig_system        => lt_contact_points_tbl(i).contact_orig_system,
                     p_orig_sys_reference => lt_contact_points_tbl(i).contact_orig_system_reference,
                     p_owner_table_name   => 'HZ_ORG_CONTACTS',
                     x_owner_table_id     => ln_org_contact_id,
                     x_retcode            => ln_osr_retcode,
                     x_errbuf             => lv_osr_errbuf
                  );

            FOR lc_fetch_rel_party_id_rec IN lc_fetch_rel_party_id_cur (ln_org_contact_id)
            LOOP
               ln_relationship_party_id := lc_fetch_rel_party_id_rec.party_id;
               EXIT;
            END LOOP;

            IF ln_relationship_party_id IS NULL THEN
               lv_record_valid_flag := 'N';
               log_debug_msg( 'Error while fetching relationship_party_id - contact_orig_system_reference is invalid');
               log_debug_msg( 'contact_orig_system_reference - '||lt_contact_points_tbl(i).contact_orig_system_reference);
               log_exception
                  (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                    ,p_source_system_code     => NULL
                    ,p_procedure_name         => 'CREATE_CONTACT_POINTS'
                    ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                    ,p_staging_column_name    => 'CONTACT_ORIG_SYSTEM_REFERENCE'
                    ,p_staging_column_value   => lt_contact_points_tbl(i).contact_orig_system_reference
                    ,p_source_system_ref      => lt_contact_points_tbl(i).contact_orig_system_reference
                    ,p_batch_id               => p_batch_id
                    ,p_exception_log          => 'Error while fetching relationship_party_id - contact_orig_system_reference is invalid'
                    ,p_oracle_error_code      => NULL
                    ,p_oracle_error_msg       => NULL
                  );
            END IF;

            IF lv_record_valid_flag = 'N' THEN
               log_debug_msg( 'Record Validation Failed');
               log_debug_msg( 'Skip Processing for this record..');
               lt_contact_points_tbl(i).interface_status := 6;
               RAISE le_skip_record;
            END IF;

            lt_contact_points_tbl(i).interface_status := 4;

            IF ln_up_contact_point_id IS NULL THEN
               ---------------
               -- Create Mode
               ---------------
               l_contact_point_rec                       := l_df_contact_point_rec;

               l_contact_point_rec.contact_point_type    := lt_contact_points_tbl(i).contact_point_type;
               l_contact_point_rec.status                := lt_contact_points_tbl(i).status;
               l_contact_point_rec.owner_table_name      := 'HZ_PARTIES';
               l_contact_point_rec.owner_table_id        := ln_relationship_party_id;
               l_contact_point_rec.primary_flag          := lt_contact_points_tbl(i).primary_flag;
               l_contact_point_rec.orig_system_reference := lt_contact_points_tbl(i).cp_orig_system_reference;
               l_contact_point_rec.orig_system           := lt_contact_points_tbl(i).cp_orig_system;
            -- l_contact_point_rec.content_source_type   :=
               l_contact_point_rec.attribute_category    := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute_category);
               l_contact_point_rec.attribute1            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute1);
               l_contact_point_rec.attribute2            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute2);
               l_contact_point_rec.attribute3            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute3);
               l_contact_point_rec.attribute4            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute4);
               l_contact_point_rec.attribute5            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute5);
               l_contact_point_rec.attribute6            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute6);
               l_contact_point_rec.attribute7            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute7);
               l_contact_point_rec.attribute8            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute8);
               l_contact_point_rec.attribute9            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute9);
               l_contact_point_rec.attribute10           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute10);
               l_contact_point_rec.attribute11           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute11);
               l_contact_point_rec.attribute12           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute12);
               l_contact_point_rec.attribute13           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute13);
               l_contact_point_rec.attribute14           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute14);
               l_contact_point_rec.attribute15           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute15);
               l_contact_point_rec.attribute16           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute16);
               l_contact_point_rec.attribute17           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute17);
               l_contact_point_rec.attribute18           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute18);
               l_contact_point_rec.attribute19           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute19);
               l_contact_point_rec.attribute20           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute20);
               l_contact_point_rec.contact_point_purpose := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).contact_point_purpose);
            -- l_contact_point_rec.primary_by_purpose    :=
               l_contact_point_rec.created_by_module     := lt_contact_points_tbl(i).created_by_module;
               l_contact_point_rec.application_id        := lt_contact_points_tbl(i).program_application_id;
            -- l_contact_point_rec.actual_content_source :=

               l_edi_rec                                 := l_df_edi_rec;
               l_edi_rec.edi_transaction_handling        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_transaction_handling);
               l_edi_rec.edi_id_number                   := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_id_number);
               l_edi_rec.edi_payment_method              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_payment_method);
               l_edi_rec.edi_payment_format              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_payment_format);
               l_edi_rec.edi_remittance_method           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_remittance_method);
               l_edi_rec.edi_remittance_instruction      := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_remittance_instruction);
               l_edi_rec.edi_tp_header_id                := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).edi_tp_header_id);
               l_edi_rec.edi_ece_tp_location_code        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_ece_tp_location_code);

               l_email_rec                               := l_df_email_rec;
               l_email_rec.email_format                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).email_format);
               l_email_rec.email_address                 := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).email_address);

               l_phone_rec                               := l_df_phone_rec;
               l_phone_rec.phone_calling_calendar        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_calling_calendar);
               --l_phone_rec.last_contact_dt_time          := lt_contact_points_tbl(i).last_contact_dt_time;
               --l_phone_rec.timezone_id                   := lt_contact_points_tbl(i).timezone_id;
               l_phone_rec.phone_area_code               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_area_code);
               l_phone_rec.phone_country_code            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_country_code);
               l_phone_rec.phone_number                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_number);
               l_phone_rec.phone_extension               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_extension);
               l_phone_rec.phone_line_type               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_line_type);
               l_phone_rec.raw_phone_number              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).raw_phone_number);

               l_telex_rec                               := l_df_telex_rec;
               l_telex_rec.telex_number                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).telex_number);

               l_web_rec                                 := l_df_web_rec;
               l_web_rec.web_type                        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).web_type);
               l_web_rec.url                             := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).url);

               l_eft_rec                                 := l_df_eft_rec;
               l_eft_rec.eft_transmission_program_id     := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).eft_transmission_program_id);
               l_eft_rec.eft_printing_program_id         := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).eft_printing_program_id);
               l_eft_rec.eft_user_number                 := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).eft_user_number);
               l_eft_rec.eft_swift_code                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).eft_swift_code);


               IF l_contact_point_rec.contact_point_type <> 'EFT' THEN

                  log_debug_msg( 'Calling API HZ_CONTACT_POINT_V2PUB.create_contact_point');

                  lv_return_status  := NULL;
                  ln_msg_count      := 0;
                  lv_msg_data       := NULL;

                  HZ_CONTACT_POINT_V2PUB.create_contact_point
                     (  p_init_msg_list          => gv_init_msg_list,
                        p_contact_point_rec      => l_contact_point_rec,
                        p_edi_rec                => l_edi_rec,
                        p_email_rec              => l_email_rec,
                        p_phone_rec              => l_phone_rec,
                        p_telex_rec              => l_telex_rec,
                        p_web_rec                => l_web_rec,
                        x_contact_point_id       => ln_contact_point_id,
                        x_return_status          => lv_return_status,
                        x_msg_count              => ln_msg_count,
                        x_msg_data               => lv_msg_data
                     );
                  IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'API successful.');
                     log_debug_msg( 'x_contact_point_id : '||ln_contact_point_id);
                     lt_contact_points_tbl(i).interface_status := 7;
                     ln_records_success := ln_records_success + 1;
                     --IF MOD(i,1000) = 0 THEN
                     --   COMMIT;
                     --END IF;
                  ELSE
                     lt_contact_points_tbl(i).interface_status := 6;
                     ln_msg_text := NULL;
                     IF ln_msg_count > 0 THEN
                        log_debug_msg( 'API returned Error.');
                        FOR counter IN 1..ln_msg_count
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                             ,p_source_system_code     => NULL
                             ,p_procedure_name         => 'CREATE_CONTACT_POINTS'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                             ,p_staging_column_name    => 'CP_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_source_system_ref      => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('create_contact_point API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF;
                  END IF;
               ELSE
                  ----------------------------
                  -- Create EFT Contact Point
                  ----------------------------
                  log_debug_msg( 'Calling API HZ_CONTACT_POINT_V2PUB.create_eft_contact_point');

                  lv_return_status  := NULL;
                  ln_msg_count      := 0;
                  lv_msg_data       := NULL;

                  HZ_CONTACT_POINT_V2PUB.create_eft_contact_point
                     (  p_init_msg_list          => gv_init_msg_list,
                        p_contact_point_rec      => l_contact_point_rec,
                        p_eft_rec                => l_eft_rec,
                        x_contact_point_id       => ln_contact_point_id,
                        x_return_status          => lv_return_status,
                        x_msg_count              => ln_msg_count,
                        x_msg_data               => lv_msg_data
                     );
                  IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'API successful.');
                     log_debug_msg( 'x_contact_point_id : '||ln_contact_point_id);
                     lt_contact_points_tbl(i).interface_status := 7;
                     ln_records_success := ln_records_success + 1;
                     --IF MOD(i,1000) = 0 THEN
                     --   COMMIT;
                     --END IF;
                  ELSE
                     lt_contact_points_tbl(i).interface_status := 6;
                     ln_msg_text := NULL;
                     IF ln_msg_count > 0 THEN
                        log_debug_msg( 'API returned Error.');
                        FOR counter IN 1..ln_msg_count
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                             ,p_source_system_code     => NULL
                             ,p_procedure_name         => 'CREATE_CONTACT_POINTS'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                             ,p_staging_column_name    => 'CP_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_source_system_ref      => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('create_eft_contact_point API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF;
                  END IF;

               END IF;

            ELSE
               ---------------
               -- Update Mode
               ---------------
               l_contact_point_rec                       := l_df_contact_point_rec;

               l_contact_point_rec.contact_point_id      := ln_up_contact_point_id;

               l_contact_point_rec.contact_point_type    := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).contact_point_type);
               l_contact_point_rec.status                := 'A'; -- modified by ivarada, hardcoding status to 'A'
               l_contact_point_rec.owner_table_name      := 'HZ_PARTIES';
               l_contact_point_rec.owner_table_id        := ln_relationship_party_id;
               l_contact_point_rec.primary_flag          := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).primary_flag);
               l_contact_point_rec.attribute_category    := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute_category);
               l_contact_point_rec.attribute1            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute1);
               l_contact_point_rec.attribute2            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute2);
               l_contact_point_rec.attribute3            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute3);
               l_contact_point_rec.attribute4            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute4);
               l_contact_point_rec.attribute5            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute5);
               l_contact_point_rec.attribute6            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute6);
               l_contact_point_rec.attribute7            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute7);
               l_contact_point_rec.attribute8            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute8);
               l_contact_point_rec.attribute9            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute9);
               l_contact_point_rec.attribute10           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute10);
               l_contact_point_rec.attribute11           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute11);
               l_contact_point_rec.attribute12           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute12);
               l_contact_point_rec.attribute13           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute13);
               l_contact_point_rec.attribute14           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute14);
               l_contact_point_rec.attribute15           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute15);
               l_contact_point_rec.attribute16           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute16);
               l_contact_point_rec.attribute17           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute17);
               l_contact_point_rec.attribute18           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute18);
               l_contact_point_rec.attribute19           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute19);
               l_contact_point_rec.attribute20           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).attribute20);
               l_contact_point_rec.contact_point_purpose := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).contact_point_purpose);
            -- l_contact_point_rec.primary_by_purpose    :=
            --   l_contact_point_rec.created_by_module     := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).created_by_module);
            --   l_contact_point_rec.application_id        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).program_application_id);
            -- l_contact_point_rec.actual_content_source :=

               l_edi_rec                                 := l_df_edi_rec;
               l_edi_rec.edi_transaction_handling        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_transaction_handling);
               l_edi_rec.edi_id_number                   := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_id_number);
               l_edi_rec.edi_payment_method              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_payment_method);
               l_edi_rec.edi_payment_format              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_payment_format);
               l_edi_rec.edi_remittance_method           := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_remittance_method);
               l_edi_rec.edi_remittance_instruction      := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_remittance_instruction);
               l_edi_rec.edi_tp_header_id                := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).edi_tp_header_id);
               l_edi_rec.edi_ece_tp_location_code        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).edi_ece_tp_location_code);

               l_email_rec                               := l_df_email_rec;
               l_email_rec.email_format                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).email_format);
               l_email_rec.email_address                 := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).email_address);

               l_phone_rec                               := l_df_phone_rec;
               l_phone_rec.phone_calling_calendar        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_calling_calendar);
               --l_phone_rec.last_contact_dt_time          := lt_contact_points_tbl(i).last_contact_dt_time;
               --l_phone_rec.timezone_id                   := lt_contact_points_tbl(i).timezone_id;
               l_phone_rec.phone_area_code               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_area_code);
               l_phone_rec.phone_country_code            := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_country_code);
               l_phone_rec.phone_number                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_number);
               l_phone_rec.phone_extension               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_extension);
               l_phone_rec.phone_line_type               := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).phone_line_type);
               l_phone_rec.raw_phone_number              := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).raw_phone_number);

               l_telex_rec                               := l_df_telex_rec;
               l_telex_rec.telex_number                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).telex_number);

               l_web_rec                                 := l_df_web_rec;
               l_web_rec.web_type                        := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).web_type);
               l_web_rec.url                             := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).url);

               l_eft_rec                                 := l_df_eft_rec;
               l_eft_rec.eft_transmission_program_id     := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).eft_transmission_program_id);
               l_eft_rec.eft_printing_program_id         := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_num (lt_contact_points_tbl(i).eft_printing_program_id);
               l_eft_rec.eft_user_number                 := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).eft_user_number);
               l_eft_rec.eft_swift_code                  := XX_CDH_CONV_MASTER_PKG.get_hz_imp_g_miss_char(lt_contact_points_tbl(i).eft_swift_code);


               -----------------------------
               -- Get Object Version Number
               -----------------------------

               BEGIN

                  ln_object_version_number := NULL;

                  SELECT object_version_number
                  INTO   ln_object_version_number
                  FROM   hz_contact_points
                  WHERE  contact_point_id = ln_up_contact_point_id;

               EXCEPTION
                  WHEN OTHERS THEN
                     log_debug_msg( 'Error while fetching object version number for contact_point_id - '||ln_up_contact_point_id);
                     log_debug_msg( 'Error -'||SQLERRM);
                     log_exception
                        (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                          ,p_source_system_code     => NULL
                          ,p_procedure_name         => 'UPDATE_CONTACT_POINTS'
                          ,p_staging_table_name     => 'XXOD_HZ_IMP_ACCT_CONTACT_STG'
                          ,p_staging_column_name    => 'CP_ORIG_SYSTEM_REFERENCE'
                          ,p_staging_column_value   => lt_contact_points_tbl(i).cp_orig_system_reference
                          ,p_source_system_ref      => lt_contact_points_tbl(i).cp_orig_system_reference
                          ,p_batch_id               => p_batch_id
                          ,p_exception_log          => 'Error while fetching object_version_number for contact_point_id - '||ln_up_contact_point_id
                          ,p_oracle_error_code      => NULL
                          ,p_oracle_error_msg       => NULL
                        );
                     RAISE le_skip_record;
               END;

               IF l_contact_point_rec.contact_point_type <> 'EFT' THEN

                  log_debug_msg( 'Calling API HZ_CONTACT_POINT_V2PUB.update_contact_point');

                  lv_return_status  := NULL;
                  ln_msg_count      := 0;
                  lv_msg_data       := NULL;

                  HZ_CONTACT_POINT_V2PUB.update_contact_point
                     (  p_init_msg_list          => gv_init_msg_list,
                        p_contact_point_rec      => l_contact_point_rec,
                        p_edi_rec                => l_edi_rec,
                        p_email_rec              => l_email_rec,
                        p_phone_rec              => l_phone_rec,
                        p_telex_rec              => l_telex_rec,
                        p_web_rec                => l_web_rec,
                        p_object_version_number  => ln_object_version_number,
                        x_return_status          => lv_return_status,
                        x_msg_count              => ln_msg_count,
                        x_msg_data               => lv_msg_data
                     );
                  IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'API successful.');
                     log_debug_msg( 'p_object_version_number : '||ln_object_version_number);
                     lt_contact_points_tbl(i).interface_status := 7;
                     ln_records_success := ln_records_success + 1;
                     --IF MOD(i,1000) = 0 THEN
                     --   COMMIT;
                     --END IF;
                  ELSE
                     lt_contact_points_tbl(i).interface_status := 6;
                     ln_msg_text := NULL;
                     IF ln_msg_count > 0 THEN
                        log_debug_msg( 'API returned Error.');
                        FOR counter IN 1..ln_msg_count
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                             ,p_source_system_code     => NULL
                             ,p_procedure_name         => 'UPDATE_CONTACT_POINTS'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                             ,p_staging_column_name    => 'CP_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_source_system_ref      => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('update_contact_point API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF;
                  END IF;
               ELSE
                  ----------------------------
                  -- Update EFT Contact Point
                  ----------------------------
                  log_debug_msg( 'Calling API HZ_CONTACT_POINT_V2PUB.update_eft_contact_point');

                  lv_return_status  := NULL;
                  ln_msg_count      := 0;
                  lv_msg_data       := NULL;

                  HZ_CONTACT_POINT_V2PUB.update_eft_contact_point
                     (  p_init_msg_list          => gv_init_msg_list,
                        p_contact_point_rec      => l_contact_point_rec,
                        p_eft_rec                => l_eft_rec,
                        p_object_version_number  => ln_object_version_number,
                        x_return_status          => lv_return_status,
                        x_msg_count              => ln_msg_count,
                        x_msg_data               => lv_msg_data
                     );
                  IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                     log_debug_msg( 'API successful.');
                     log_debug_msg( 'p_object_version_number : '||ln_object_version_number);
                     lt_contact_points_tbl(i).interface_status := 7;
                     ln_records_success := ln_records_success + 1;
                     --IF MOD(i,1000) = 0 THEN
                     --   COMMIT;
                     --END IF;
                  ELSE
                     lt_contact_points_tbl(i).interface_status := 6;
                     ln_msg_text := NULL;
                     IF ln_msg_count > 0 THEN
                        log_debug_msg( 'API returned Error.');
                        FOR counter IN 1..ln_msg_count
                        LOOP
                           ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                           log_debug_msg('Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                        END LOOP;
                        FND_MSG_PUB.Delete_Msg;
                        log_exception
                           (  p_record_control_id      => lt_contact_points_tbl(i).record_id
                             ,p_source_system_code     => NULL
                             ,p_procedure_name         => 'UPDATE_CONTACT_POINTS'
                             ,p_staging_table_name     => 'XXOD_HZ_IMP_CONTACTPTS_STG'
                             ,p_staging_column_name    => 'CP_ORIG_SYSTEM_REFERENCE'
                             ,p_staging_column_value   => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_source_system_ref      => lt_contact_points_tbl(i).cp_orig_system_reference
                             ,p_batch_id               => p_batch_id
                             ,p_exception_log          => XX_CDH_CONV_MASTER_PKG.TRIM_INPUT_MSG('update_eft_contact_point API returned Error - '||ln_msg_text)
                             ,p_oracle_error_code      => NULL
                             ,p_oracle_error_msg       => NULL
                           );
                     END IF;
                  END IF;
               END IF;
            END IF;
         EXCEPTION
            WHEN le_skip_record THEN
               NULL;
            WHEN OTHERS THEN
               log_debug_msg( 'Unexpected Error while processing the record - '||SQLERRM);
               lt_contact_points_tbl(i).interface_status := 6;
         END;

         lt_upd_record_tbl(i)    := lt_contact_points_tbl(i).record_id;
         lt_upd_interface_tbl(i) := lt_contact_points_tbl(i).interface_status;

      END LOOP;

      IF lt_contact_points_tbl.LAST > 0 THEN

         FORALL i IN 1 .. lt_contact_points_tbl.last
         UPDATE xxod_hz_imp_contactpts_stg
         SET    interface_status     = lt_upd_interface_tbl(i)
         WHERE  record_id            = lt_upd_record_tbl(i);

         COMMIT;

      END IF;
      ---------------------
      -- Clear the tables
      ---------------------
      lt_upd_interface_tbl.DELETE;
      lt_upd_record_tbl.DELETE;
      lt_contact_points_tbl.DELETE;
      EXIT WHEN lc_fetch_contact_pts_cur%NOTFOUND;
   END LOOP;
   CLOSE lc_fetch_contact_pts_cur;

   ln_records_failed := (ln_records_read - ln_records_success);

   log_debug_msg( ' ');
   log_debug_msg( ' ');
   log_debug_msg( 'Record Statistics after Processing Contact Points ');
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( 'Staging Table - XXOD_HZ_IMP_CONTACTPTS_STG ');
   log_debug_msg( 'No Of Records Read                   - '||ln_records_read);
   log_debug_msg( 'No Of Records Processesd Succesfully - '||ln_records_success);
   log_debug_msg( 'No Of Records Failed                 - '||ln_records_failed);
   log_debug_msg( '-------------------------------------------------------------');
   log_debug_msg( ' ');
   log_debug_msg( ' ');

   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Contact Points ');
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, 'Staging Table - XXOD_HZ_IMP_CONTACTPTS_STG ');
   fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
   fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
   fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');

   XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc
         (  p_conversion_id                => 00242.4
           ,p_batch_id                     => p_batch_id
           ,p_num_bus_objs_processed       => 0
         );

   XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
         (  p_conc_mst_req_id              => gt_request_id
           ,p_batch_id                     => p_batch_id
           ,p_conversion_id                => 00242.4
           ,p_num_bus_objs_failed_valid    => 0
           ,p_num_bus_objs_failed_process  => ln_records_success
           ,p_num_bus_objs_succ_process    => ln_records_failed
         );


   x_retcode := 0;
   log_debug_msg( 'End of Create Contact Point Procedure.');
   log_debug_msg( '-----------------------------------------------');
   log_debug_msg( ' ');
   log_debug_msg( ' ');
EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode := 0;
   WHEN OTHERS THEN
      log_debug_msg( 'Unexpected Error in procedure create_contact_points - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_contact_points - '||SQLERRM;
END create_contact_point_worker;

-- +===================================================================+
-- | Name        :  log_exception                                      |
-- | Description :  This procedure is invoked is used for logging      |
-- |                exceptions into conversion common elements tables. |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exception
      (  p_record_control_id      IN NUMBER
        ,p_source_system_code     IN VARCHAR2
        ,p_procedure_name         IN VARCHAR2
        ,p_staging_table_name     IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_source_system_ref      IN VARCHAR2
        ,p_batch_id               IN NUMBER
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_oracle_error_msg       IN VARCHAR2
      )

IS
   lv_package_name           VARCHAR2(32)  := 'XX_CDH_CUSTOMER_CONTACT_PKG';
   ln_conversion_id          NUMBER        := 00242;
BEGIN
   XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
      (   p_conversion_id          => ln_conversion_id
         ,p_record_control_id      => p_record_control_id
         ,p_source_system_code     => p_source_system_code
         ,p_package_name           => lv_package_name
         ,p_procedure_name         => p_procedure_name
         ,p_staging_table_name     => p_staging_table_name
         ,p_staging_column_name    => p_staging_column_name
         ,p_staging_column_value   => p_staging_column_value
         ,p_source_system_ref      => p_source_system_ref
         ,p_batch_id               => p_batch_id
         ,p_exception_log          => p_exception_log
         ,p_oracle_error_code      => p_oracle_error_code
         ,p_oracle_error_msg       => p_oracle_error_msg
      );

END log_exception;

-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_debug_msg                                        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (
         p_debug_msg              IN        VARCHAR2
    )
IS
BEGIN
    XX_CDH_CONV_MASTER_PKG.write_conc_log_message(p_debug_msg);
END log_debug_msg;

-- +===================================================================+
-- | Name        :  create_collector_contact                           |
-- | Description :  This procedure creates Collector Contacts for      |
-- |                Get Paid Contact. This would be called from        |
-- |                concurrent program.                                |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_collector_contact
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2,
         p_orig_system       IN  VARCHAR2
      )
IS

CURSOR lc_fetch_coll_contacts_cur
IS
SELECT hpr.party_id,
       hpr.subject_id                         person_party_id,
       hpr.object_id                          org_party_id,
       hcp1.contact_point_id                  phone_contact_point_id,
       hcp2.contact_point_id                  email_contact_point_id,
       hl.location_id                         ,
       hosr.orig_system_reference
FROM   hz_orig_sys_references                 hosr,
       hz_org_contacts                        hoc,
       --hz_party_relationships                 hpr, -- Commented for R12 upgrade retrofit
       hz_relationships                       hpr, -- Added for r12 upgrade retrofit
       hz_contact_points                      hcp1,
       hz_contact_points                      hcp2,
       hz_cust_account_roles                  hcar,
       hz_cust_acct_sites_all                 hcas,
       hz_party_sites                         hps,
       hz_locations                           hl,
       fnd_flex_value_sets                    ffvs,
       fnd_flex_values                        ffv
WHERE  SUBSTR(hosr.orig_system_reference,1,2) = ffv.flex_value
AND    hosr.orig_system                       = p_orig_system
AND    hosr.status                            = 'A'
AND    hosr.owner_table_name                  = 'HZ_ORG_CONTACTS'
AND    hoc.org_contact_id                     = hosr.owner_table_id
AND    hoc.status                             = 'A'
--AND    hpr.party_relationship_id              = hoc.party_relationship_id --Commented for R12 upgrade retrofit
AND    hpr.relationship_id                    = hoc.party_relationship_id --Added for R12 upgrade retrofit
AND    hpr.status                             = 'A'
AND    hcp1.owner_table_id(+)                 = hpr.party_id
AND    hcp1.owner_table_name(+)               = 'HZ_PARTIES'
AND    hcp1.contact_point_type(+)             = 'PHONE'
AND    hcp1.primary_flag(+)                   = 'Y'
AND    hcp1.status(+)                         = 'A'
AND    hcp2.owner_table_id(+)                 = hpr.party_id
AND    hcp2.owner_table_name(+)               = 'HZ_PARTIES'
AND    hcp2.contact_point_type(+)             = 'EMAIL'
AND    hcp2.primary_flag(+)                   = 'Y'
AND    hcp2.status(+)                         = 'A'
AND    hcar.party_id                          = hpr.party_id
AND    hcar.primary_flag                      = 'Y'
AND    hcas.cust_acct_site_id                 = hcar.cust_acct_site_id
AND    hcar.status                            = 'A'
AND    hcas.status                            = 'A'
AND    hcas.party_site_id                     = hps.party_site_id
AND    hps.status                             = 'A'
AND    hl.location_id                         = hps.location_id
AND    ffv.flex_value_set_id                  = ffvs.flex_value_set_id
AND    ffvs.flex_value_set_name               = 'XX_CDH_GET_PAID_OSR'
AND    SYSDATE BETWEEN NVL(ffv.start_date_active,SYSDATE) AND NVL(ffv.end_date_active,SYSDATE)
AND    ffv.enabled_flag                       = 'Y';

TYPE lr_fetch_coll_contacts_rec IS RECORD
   (  party_id                                hz_parties.party_id%TYPE,
      --person_party_id                         hz_party_relationships.subject_id%TYPE, -- Commented by Deepak for R12 Upgrade retrofit
      person_party_id                         hz_relationships.subject_id%TYPE, -- Added by Deepak for R12 Upgrade retroft
      --org_party_id                            hz_party_relationships.object_id%TYPE, -- Commented by Deepak for R12 Upgrade retrofit
      org_party_id                            hz_relationships.object_id%TYPE, -- Added by Deepak for R12 Upgrade retrofit
      phone_contact_point_id                  hz_contact_points.contact_point_id%TYPE,
      email_contact_point_id                  hz_contact_points.contact_point_id%TYPE,
      location_id                             hz_locations.location_id%TYPE,
      contact_orig_system_reference           hz_orig_sys_references.orig_system_reference%TYPE
   );

TYPE lt_fetch_coll_contacts_type              IS TABLE OF lr_fetch_coll_contacts_rec;
lt_fetch_coll_contacts_tbl                    lt_fetch_coll_contacts_type;

ln_records_read                               NUMBER := 0;
ln_records_success                            NUMBER := 0;
ln_records_failed                             NUMBER := 0;
lv_return_status                              VARCHAR2(10);
ln_msg_count                                  NUMBER;
lv_msg_data                                   VARCHAR2(2000);
le_skip_process                               EXCEPTION;
x_rel_id                                      NUMBER;
x_party_id                                    NUMBER;
ln_exists                                     NUMBER;
le_skip_loop                                  EXCEPTION;
lv_index_text                                 VARCHAR2(2000);

BEGIN

   --------------------------------
   -- Create Index for Performance
   --------------------------------
   lv_index_text := 'CREATE INDEX XXCNV.XX_HZ_ORIG_SYS_REFERENCES_N3 ON ar.HZ_ORIG_SYS_REFERENCES '||
                    ' (owner_table_name, SUBSTR(orig_system_reference,1,2), orig_system, status) ';

   EXECUTE IMMEDIATE lv_index_text;

   ---------------
   -- Open Cursor
   ---------------
   OPEN  lc_fetch_coll_contacts_cur;
   LOOP
      FETCH lc_fetch_coll_contacts_cur BULK COLLECT INTO lt_fetch_coll_contacts_tbl LIMIT gn_bulk_fetch_limit;

      IF lt_fetch_coll_contacts_tbl.count = 0 THEN
         fnd_file.put_line(fnd_file.log,'No records exist to create Collector Contacts');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Collector Contacts');
         fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
         fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
         fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
         fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
         fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
         fnd_file.put_line(fnd_file.output, ' ');
         fnd_file.put_line(fnd_file.output, ' ');
         RAISE le_skip_process;
      END IF;

      FOR i IN lt_fetch_coll_contacts_tbl.FIRST .. lt_fetch_coll_contacts_tbl.LAST
      LOOP

         BEGIN

            --------------------------------------------------
            -- Check if Collector Relationship already Exists
            --------------------------------------------------
            /* Commented for now. To be uncommented for fresh load*/

            BEGIN
               SELECT 1
               INTO   ln_exists
               FROM   hz_relationships
               WHERE  subject_id        = lt_fetch_coll_contacts_tbl(i).person_party_id
               AND    object_id         = lt_fetch_coll_contacts_tbl(i).org_party_id
               AND    relationship_code = 'COLLECTIONS'
               AND    status            = 'A';

            EXCEPTION
               WHEN TOO_MANY_ROWS THEN
                  ln_exists := 1;
               WHEN OTHERS THEN
                  ln_exists := 0;
            END;

            IF ln_exists = 1 THEN
               RAISE le_skip_loop;
            END IF;


            lv_return_status  := NULL;
            ln_msg_count      := 0;
            lv_msg_data       := NULL;
            x_rel_id          := 0;
            x_party_id        := 0;

            ln_records_read   := ln_records_read + 1;

            fnd_file.put_line(fnd_file.log,'Processing Contact OSR - '||lt_fetch_coll_contacts_tbl(i).contact_orig_system_reference);

            --IEX_CUST_OVERVIEW_PVT.
            CREATE_DEFAULT_CONTACT
               (   p_api_version            => 1,
                   p_init_msg_list          => FND_API.G_TRUE,
                   p_commit                 => FND_API.G_FALSE,
                   p_validation_level       => 100,
                   x_return_status          => lv_return_status,
                   x_msg_count              => ln_msg_count,
                   x_msg_data               => lv_msg_data,
                   p_org_party_id           => lt_fetch_coll_contacts_tbl(i).org_party_id,
                   p_person_party_id        => lt_fetch_coll_contacts_tbl(i).person_party_id,
                   p_phone_contact_point_id => lt_fetch_coll_contacts_tbl(i).phone_contact_point_id,
                   p_email_contact_point_id => lt_fetch_coll_contacts_tbl(i).email_contact_point_id,
                   p_type                   => 'COLLECTIONS',
                   p_location_id            => lt_fetch_coll_contacts_tbl(i).location_id,
                   x_relationship_id        => x_rel_id,
                   x_party_id               => x_party_id
               );

            IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN
               fnd_file.put_line(fnd_file.log,'Collector Contact Successfully Created !!');
               ln_records_success := ln_records_success + 1;
            ELSE
               ln_records_failed := ln_records_failed + 1;
               IF ln_msg_count > 0 THEN
                  fnd_file.put_line(fnd_file.log,'API returned Error.');
                  FOR counter IN 1..ln_msg_count
                  LOOP
                     fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
                  END LOOP;
                  FND_MSG_PUB.Delete_Msg;
               END IF;
            END IF;
         EXCEPTION
            WHEN le_skip_loop THEN
               NULL;
         END;
      END LOOP;
      COMMIT;
      lt_fetch_coll_contacts_tbl.delete;
      EXIT WHEN lc_fetch_coll_contacts_cur%NOTFOUND;
   END LOOP;

   CLOSE lc_fetch_coll_contacts_cur;

   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, 'Record Statistics after Processing Collector Contacts');
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, 'No Of Records Read                   - '||ln_records_read);
   fnd_file.put_line(fnd_file.output, 'No Of Records Processesd Succesfully - '||ln_records_success);
   fnd_file.put_line(fnd_file.output, 'No Of Records Failed                 - '||ln_records_failed);
   fnd_file.put_line(fnd_file.output, '-------------------------------------------------------------');
   fnd_file.put_line(fnd_file.output, ' ');
   fnd_file.put_line(fnd_file.output, ' ');

   --------------------------
   -- Drop Performance Index
   --------------------------
   lv_index_text := NULL;
   lv_index_text := 'DROP INDEX XXCNV.XX_HZ_ORIG_SYS_REFERENCES_N3';

   EXECUTE IMMEDIATE lv_index_text;

   COMMIT;
EXCEPTION
   WHEN le_skip_process THEN
      NULL;
   WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Unexpected Error in procedure create_collector_contact - '||SQLERRM);
      x_retcode := 2;
      x_errbuf  := 'Unexpected Error in procedure create_collector_contact - '||SQLERRM;
END create_collector_contact;

-- +===================================================================+
-- | Name        :  create_default_contact                             |
-- | Description :  This procedure is copied from standard package     |
-- |                IEX_CUST_OVERVIEW_PVT with updated application_id  |
-- |                and created_by_module                              |
-- |                                                                   |
-- | Parameters  :  p_batch_id (Batch_id)                              |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_default_contact
  (p_api_version      IN  NUMBER := 1.0,
   p_init_msg_list    IN  VARCHAR2,
   p_commit           IN  VARCHAR2,
   p_validation_level IN  NUMBER,
   x_return_status    OUT NOCOPY VARCHAR2,
   x_msg_count        OUT NOCOPY NUMBER,
   x_msg_data         OUT NOCOPY VARCHAR2,
   p_org_party_id     IN  NUMBER,
   p_person_party_id  IN  NUMBER,
   p_phone_contact_point_id IN  NUMBER,
   p_email_contact_point_id IN  NUMBER,
   p_type             IN  VARCHAR2,
   p_location_id      IN  NUMBER,
   x_relationship_id  OUT NOCOPY NUMBER,
   x_party_id         OUT NOCOPY NUMBER)
  IS
    l_api_name        CONSTANT VARCHAR2(30) := 'CREATE_DEFAULT_CONTACT';
    l_api_version     CONSTANT   NUMBER :=  1.0;

    l_party_rel_create_rec HZ_RELATIONSHIP_V2PUB.RELATIONSHIP_REC_TYPE;
    l_org_contact_create_rec HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;

    l_party_rel_update_rec HZ_RELATIONSHIP_V2PUB.RELATIONSHIP_REC_TYPE;
    l_org_contact_update_rec HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;

    l_msg_count             NUMBER;
    l_msg_data              VARCHAR2(2000);
    l_return_status         VARCHAR2(1);

    l_cont_object_version_number  NUMBER;
    l_rel_object_version_number   NUMBER;
    l_party_object_version_number NUMBER;
    l_object_version_number       NUMBER;

    l_party_relationship_id NUMBER;
    l_party_id              NUMBER;
    l_party_number          VARCHAR2(30);

    l_msg_index_out number;
    l_org_contact_id NUMBER;

    l_last_update_date date;

    l_contact_point_create_rec  HZ_CONTACT_POINT_V2PUB.contact_point_Rec_type;
    l_phone_create_rec       HZ_CONTACT_POINT_V2PUB.phone_Rec_type;
    l_contact_point_id       NUMBER;
    l_email_create_rec       HZ_CONTACT_POINT_V2PUB.email_Rec_type;


    CURSOR c_exist_rel IS
      SELECT *
      FROM hz_relationships
      WHERE (subject_id = l_party_id
             AND relationship_code = p_type
             AND status = 'A');

    CURSOR c_org_contact(p_party_relationship_id NUMBER) IS
      SELECT org_contact_id, object_version_number
      FROM hz_org_contacts
      WHERE party_relationship_id = p_party_relationship_id;

    CURSOR c_party(p_party_id NUMBER) IS
      SELECT object_version_number
      FROM hz_parties
      WHERE party_id = p_party_id;

    CURSOR c_contact_point(p_contact_point_id NUMBER) is
      SELECT *
      FROM hz_contact_points
      WHERE contact_point_id = p_contact_point_id;

    l_phone_rec c_contact_point%ROWTYPE;
    l_email_rec c_contact_point%ROWTYPE;

    l_party_site_id NUMBER;
    l_party_site_number VARCHAR2(30);
    l_Party_Site_create_rec   HZ_PARTY_SITE_V2PUB.Party_Site_Rec_type;
    l_call_api BOOLEAN;

    CURSOR c_CheckPartySite(p_partyid number,p_location_id Number) IS
      SELECT party_site_id,party_site_number
      FROM HZ_PARTY_SITES
      where party_id = p_partyid
      AND location_id = p_location_id;

  BEGIN
    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':begin');

    SAVEPOINT  Create_Default_Contact_PVT;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.Compatible_API_Call (l_api_version,
                                        p_api_version,
                                        l_api_name,
                                        G_PKG_NAME)    THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Check p_init_msg_list
    IF FND_API.to_Boolean( p_init_msg_list ) THEN
      FND_MSG_PUB.initialize;
    END IF;

    x_return_status := FND_API.G_RET_STS_SUCCESS;

    l_party_rel_create_rec  := AST_API_RECORDS_V2PKG.INIT_HZ_PARTY_REL_REC_TYPE_V2;
    l_org_contact_create_rec  := AST_API_RECORDS_V2PKG.INIT_HZ_ORG_CONTACT_REC_V2;

    l_party_rel_update_rec  := AST_API_RECORDS_V2PKG.INIT_HZ_PARTY_REL_REC_TYPE_V2;
    l_org_contact_update_rec := AST_API_RECORDS_V2PKG.INIT_HZ_ORG_CONTACT_REC_V2;


    l_cont_object_version_number  := 1.0;
    l_rel_object_version_number   := 1.0;
    l_party_object_version_number := 1.0;
    l_object_version_number       := 1.0;

    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':p_org_party_id=' || p_org_party_id || ':p_person_party_id=' || p_person_party_id
      || ':p_phone_contact_point_id=' || p_phone_contact_point_id || ':p_type=' || p_type);

    l_party_id := p_org_party_id;

    FOR r_exist_rel IN c_exist_rel LOOP
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_relationship_id=' || r_exist_rel.relationship_id);

      l_party_rel_update_rec.relationship_id         := r_exist_rel.relationship_id;
      l_party_rel_update_rec.subject_id              := r_exist_rel.subject_id;
      l_party_rel_update_rec.object_id               := r_exist_rel.object_id;
      l_party_rel_update_rec.status                  := 'I';
      l_party_rel_update_rec.start_date              := r_exist_rel.start_date;
      l_party_rel_update_rec.end_date                := sysdate;
      l_party_rel_update_rec.relationship_type       := r_exist_rel.relationship_type;
      l_party_rel_update_rec.relationship_code       := r_exist_rel.relationship_code;
      l_party_rel_update_rec.subject_table_name      := r_exist_rel.subject_table_name;
      l_party_rel_update_rec.object_table_name       := r_exist_rel.object_table_name;
      l_party_rel_update_rec.subject_type            := r_exist_rel.subject_type;
      l_party_rel_update_rec.object_type             := r_exist_rel.object_type;
      l_party_rel_update_rec.application_id          := r_exist_rel.application_id;

      l_party_rel_update_rec.party_rec.status        := 'I';

      OPEN c_org_contact(r_exist_rel.relationship_id);
      FETCH c_org_contact INTO l_org_contact_id, l_cont_object_version_number;
      CLOSE c_org_contact;

      l_org_contact_update_rec.org_contact_id        := l_org_contact_id;
      l_org_contact_update_rec.party_rel_rec         := l_party_rel_update_rec;
      --l_org_contact_update_rec.application_id        := 625;

      l_rel_object_version_number := r_exist_rel.object_version_number;

      OPEN c_party(r_exist_rel.party_id);
      FETCH c_party INTO l_party_object_version_number;
      CLOSE c_party;

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':Calling HZ_PARTY_CONTACT_V2PUB.Update_Org_Contact...');

      HZ_PARTY_CONTACT_V2PUB.Update_Org_Contact(
                p_init_msg_list          => 'F',
                p_org_contact_rec        => l_org_contact_update_rec,
                x_return_status          => l_return_status,
                x_msg_count              => l_msg_count,
                x_msg_data               => l_msg_data,
                p_cont_object_version_number  => l_cont_object_version_number,
                p_rel_object_version_number   => l_rel_object_version_number,
                p_party_object_version_number => l_party_object_version_number);

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status);
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_cont_object_version_number=' || l_cont_object_version_number);
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_rel_object_version_number=' || l_rel_object_version_number);
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_object_version_number=' || l_party_object_version_number);

      IF l_return_status = FND_API.G_RET_STS_ERROR OR
         l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

    END LOOP;

    l_party_rel_create_rec.subject_id              := p_org_party_id;
    l_party_rel_create_rec.object_id               := p_person_party_id;
    l_party_rel_create_rec.status                  := 'A';
    l_party_rel_create_rec.start_date              := SYSDATE;
    l_party_rel_create_rec.relationship_type       := p_type;
    l_party_rel_create_rec.relationship_code       := p_type;
    l_party_rel_create_rec.subject_table_name      := 'HZ_PARTIES';
    l_party_rel_create_rec.object_table_name       := 'HZ_PARTIES';
    l_party_rel_create_rec.subject_type            := 'ORGANIZATION';
    l_party_rel_create_rec.object_type             := 'PERSON';
    l_party_rel_create_rec.created_by_module       := 'XXCONV';
    --l_party_rel_create_rec.application_id          := 625;

    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':HZ_GENERATE_PARTY_NUMBER=' || fnd_profile.value('HZ_GENERATE_PARTY_NUMBER'));

    IF NVL(fnd_profile.value('HZ_GENERATE_PARTY_NUMBER'), 'Y') = 'N' THEN
     SELECT hz_parties_s.nextval
      INTO l_party_rel_create_rec.party_rec.party_number
      FROM dual;
   ELSE
      l_party_rel_create_rec.party_rec.party_number := '';
    END IF;

    l_party_rel_create_rec.party_rec.status        := 'A';
    l_org_contact_create_rec.party_rel_rec  := l_party_rel_create_rec;
    l_org_contact_create_rec.created_by_module := 'XXCONV';
    --l_org_contact_create_rec.application_id    := 625;

    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':Calling HZ_PARTY_CONTACT_V2PUB.Create_Org_Contact...');

    HZ_PARTY_CONTACT_V2PUB.Create_Org_Contact(
              p_init_msg_list          => 'F',
              p_org_contact_rec        => l_org_contact_create_rec,
              x_return_status          => l_return_status,
              x_msg_count              => l_msg_count,
              x_msg_data               => l_msg_data,
              x_org_contact_id         => l_org_contact_id,
              x_party_rel_id           => l_party_relationship_id,
              x_party_id               => l_party_id,
              x_party_number           => l_party_number );

    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status);
    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_org_contact_id=' || l_org_contact_id || ' l_party_id=' || l_party_id || ' l_party_number=' || l_party_number);
    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_id=' || l_party_id);

    x_party_id := l_party_id;
    x_relationship_id := l_party_relationship_id;

    IF l_return_status = FND_API.G_RET_STS_ERROR OR
       l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF p_phone_contact_point_id IS NOT NULL THEN
      OPEN c_contact_point(p_phone_contact_point_id);
      FETCH c_contact_point INTO l_phone_rec;
      CLOSE c_contact_point;

      l_contact_point_create_rec.contact_point_type := l_phone_rec.contact_point_type;
      l_contact_point_create_rec.status := l_phone_rec.status;
      l_contact_point_create_rec.owner_table_name := l_phone_rec.owner_table_name;
      l_contact_point_create_rec.owner_table_id := l_party_id;
      l_contact_point_create_rec.primary_flag := l_phone_rec.primary_flag;
      l_contact_point_create_rec.contact_point_purpose := p_type;
      l_contact_point_create_rec.primary_by_purpose := 'Y';
      l_contact_point_create_rec.orig_system_reference:= l_phone_rec.orig_system_reference;
      l_contact_point_create_rec.created_by_module := 'XXCONV';
      l_contact_point_create_rec.content_source_type := l_phone_rec.content_source_type;
      l_contact_point_create_rec.attribute_category := l_phone_rec.attribute_category;
      l_contact_point_create_rec.attribute1 := l_phone_rec.attribute1;
      l_contact_point_create_rec.attribute2 := l_phone_rec.attribute2;
      l_contact_point_create_rec.attribute3 := l_phone_rec.attribute3;
      l_contact_point_create_rec.attribute4 := l_phone_rec.attribute4;
      l_contact_point_create_rec.attribute5 := l_phone_rec.attribute5;
      l_contact_point_create_rec.attribute6 := l_phone_rec.attribute6;
      l_contact_point_create_rec.attribute7 := l_phone_rec.attribute7;
      l_contact_point_create_rec.attribute8 := l_phone_rec.attribute8;
      l_contact_point_create_rec.attribute9 := l_phone_rec.attribute9;
      l_contact_point_create_rec.attribute10 := l_phone_rec.attribute10;
      l_contact_point_create_rec.attribute11 := l_phone_rec.attribute11;
      l_contact_point_create_rec.attribute12 := l_phone_rec.attribute12;
      l_contact_point_create_rec.attribute13 := l_phone_rec.attribute13;
      l_contact_point_create_rec.attribute14 := l_phone_rec.attribute14;
      l_contact_point_create_rec.attribute15 := l_phone_rec.attribute15;
      l_contact_point_create_rec.attribute16 := l_phone_rec.attribute16;
      l_contact_point_create_rec.attribute17 := l_phone_rec.attribute17;
      l_contact_point_create_rec.attribute18 := l_phone_rec.attribute18;
      l_contact_point_create_rec.attribute19 := l_phone_rec.attribute19;
      l_contact_point_create_rec.attribute20 := l_phone_rec.attribute20;

      l_phone_create_rec.phone_area_code := l_phone_rec.phone_area_code;
      l_phone_create_rec.phone_country_code := l_phone_rec.phone_country_code;
      l_phone_create_rec.phone_number := l_phone_rec.phone_number;
      l_phone_create_rec.phone_extension := l_phone_rec.phone_extension;
      l_phone_create_rec.phone_line_type := l_phone_rec.phone_line_type;
      --l_phone_create_rec.raw_phone_number := l_phone_rec.raw_phone_number;

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':calling hz_contact_point_v2pub.create_phone_contact_point ...');

      hz_contact_point_v2pub.create_phone_contact_point(
        p_init_msg_list                 => 'F',
        x_return_status                 => l_return_status,
        x_msg_count                     => l_msg_count,
        x_msg_data                      => l_msg_data,
        p_contact_point_rec             => l_contact_point_create_rec,
        p_phone_rec                     => l_phone_create_rec,
        x_contact_point_id              => l_contact_point_id);

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status || ':l_contact_point_id=' || l_contact_point_id);

      IF l_return_status = FND_API.G_RET_STS_ERROR OR
         l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

    END IF;  /*    IF p_phone_contact_point_id IS NOT NULL THEN */

    IF p_email_contact_point_id IS NOT NULL THEN
      OPEN c_contact_point(p_email_contact_point_id);
      FETCH c_contact_point INTO l_email_rec;
      CLOSE c_contact_point;

      l_contact_point_create_rec.contact_point_type := l_email_rec.contact_point_type;
      l_contact_point_create_rec.status := l_email_rec.status;
      l_contact_point_create_rec.owner_table_name := l_email_rec.owner_table_name;
      l_contact_point_create_rec.owner_table_id := l_party_id;
      l_contact_point_create_rec.primary_flag := l_email_rec.primary_flag;
      l_contact_point_create_rec.contact_point_purpose := p_type;
      l_contact_point_create_rec.primary_by_purpose := 'Y';
      l_contact_point_create_rec.orig_system_reference:= l_email_rec.orig_system_reference;
      l_contact_point_create_rec.created_by_module := 'XXCONV';
      l_contact_point_create_rec.content_source_type := l_email_rec.content_source_type;
      l_contact_point_create_rec.attribute_category := l_email_rec.attribute_category;
      l_contact_point_create_rec.attribute1 := l_email_rec.attribute1;
      l_contact_point_create_rec.attribute2 := l_email_rec.attribute2;
      l_contact_point_create_rec.attribute3 := l_email_rec.attribute3;
      l_contact_point_create_rec.attribute4 := l_email_rec.attribute4;
      l_contact_point_create_rec.attribute5 := l_email_rec.attribute5;
      l_contact_point_create_rec.attribute6 := l_email_rec.attribute6;
      l_contact_point_create_rec.attribute7 := l_email_rec.attribute7;
      l_contact_point_create_rec.attribute8 := l_email_rec.attribute8;
      l_contact_point_create_rec.attribute9 := l_email_rec.attribute9;
      l_contact_point_create_rec.attribute10 := l_email_rec.attribute10;
      l_contact_point_create_rec.attribute11 := l_email_rec.attribute11;
      l_contact_point_create_rec.attribute12 := l_email_rec.attribute12;
      l_contact_point_create_rec.attribute13 := l_email_rec.attribute13;
      l_contact_point_create_rec.attribute14 := l_email_rec.attribute14;
      l_contact_point_create_rec.attribute15 := l_email_rec.attribute15;
      l_contact_point_create_rec.attribute16 := l_email_rec.attribute16;
      l_contact_point_create_rec.attribute17 := l_email_rec.attribute17;
      l_contact_point_create_rec.attribute18 := l_email_rec.attribute18;
      l_contact_point_create_rec.attribute19 := l_email_rec.attribute19;
      l_contact_point_create_rec.attribute20 := l_email_rec.attribute20;

      l_email_create_rec.email_format := l_email_rec.email_format;
      l_email_create_rec.email_address := l_email_rec.email_address;

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':calling hz_contact_point_v2pub.create_email_contact_point ...');

      hz_contact_point_v2pub.create_email_contact_point(
        p_init_msg_list                 => 'F',
        x_return_status                 => l_return_status,
        x_msg_count                     => l_msg_count,
        x_msg_data                      => l_msg_data,
        p_contact_point_rec             => l_contact_point_create_rec,
        p_email_rec                     => l_email_create_rec,
        x_contact_point_id              => l_contact_point_id);

      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status || ':l_contact_point_id=' || l_contact_point_id);

      IF l_return_status = FND_API.G_RET_STS_ERROR OR
         l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

    END IF;  /*    IF p_email_contact_point_id IS NOT NULL THEN */

    IF p_location_id IS NOT NULL THEN
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_id=' || l_party_id || ':p_location_id=' || p_location_id);
      OPEN c_CheckPartySite(l_party_id, p_location_id);
      FETCH c_CheckPartySite INTO l_party_site_id, l_party_site_number;

      IF (c_CheckPartySite%FOUND) THEN
        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':party site existing already');
        l_call_api := FALSE;
      ELSE
        l_call_api := TRUE;
      END IF; /*End of C_CheckPartySite%FOUND if loop */
      CLOSE c_CheckPartySite;

      IF l_Call_Api then
        l_Party_Site_Create_rec.Party_Id := l_party_id;
        l_Party_Site_Create_rec.Location_Id := p_location_id;

        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':HZ_GENERATE_PARTY_SITE_NUMBER=' || fnd_profile.value('HZ_GENERATE_PARTY_SITE_NUMBER'));

        IF NVL(fnd_profile.value('HZ_GENERATE_PARTY_SITE_NUMBER'), 'Y') = 'N' THEN
          SELECT hz_party_sites_s.nextval
          INTO  l_Party_Site_Create_rec.Party_Site_Number
          FROM dual;
          iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_site_number=' || l_party_site_create_rec.party_site_number);
        ELSE
          l_Party_Site_Create_rec.Party_Site_Number := NULL;
        END IF;

        l_Party_Site_Create_rec.Identifying_Address_Flag := 'Y';
        l_Party_Site_Create_rec.Status := 'A';
        l_Party_Site_Create_rec.Created_by_module := 'XXCONV';
        --l_Party_Site_Create_rec.Application_id    := 625;

        l_Party_Site_Create_rec.Party_Site_Name := NULL;

        HZ_PARTY_SITE_V2PUB.Create_Party_Site  (
            p_init_msg_list      => 'F',
            p_party_site_rec     => l_party_site_Create_rec,
            x_return_status      => l_return_status,
            x_msg_count          => l_msg_count,
            x_msg_data           => l_msg_data,
            x_party_site_id      => l_party_site_id,
            x_party_site_number  => l_party_site_number
         );

        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status);
        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_site_id=' || l_party_site_id);

        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status);

        IF l_return_status = FND_API.G_RET_STS_ERROR OR
           l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;

      END IF; /*End of if l_Call_Api true loop for Party Site*/

    END IF; /*    IF p_location_id IS NOT NULL THEN */

    IF p_location_id IS NOT NULL THEN
      iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_id=' || l_party_id || ':p_location_id=' || p_location_id);
      OPEN c_CheckPartySite(l_party_id, p_location_id);
      FETCH c_CheckPartySite INTO l_party_site_id, l_party_site_number;

      IF (c_CheckPartySite%FOUND) THEN
        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':party site existing already');
        l_call_api := FALSE;
      ELSE
        l_call_api := TRUE;
      END IF; /*End of C_CheckPartySite%FOUND if loop */
      CLOSE c_CheckPartySite;

      IF l_Call_Api then
        l_Party_Site_Create_rec.Party_Id := l_party_id;
        l_Party_Site_Create_rec.Location_Id := p_location_id;

        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':HZ_GENERATE_PARTY_SITE_NUMBER=' || fnd_profile.value('HZ_GENERATE_PARTY_SITE_NUMBER'));

        IF NVL(fnd_profile.value('HZ_GENERATE_PARTY_SITE_NUMBER'), 'Y') = 'N' THEN
          SELECT hz_party_sites_s.nextval
          INTO  l_Party_Site_Create_rec.Party_Site_Number
          FROM dual;
          iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_site_number=' || l_party_site_create_rec.party_site_number);
        ELSE
          l_Party_Site_Create_rec.Party_Site_Number := NULL;
        END IF;

        l_Party_Site_Create_rec.Identifying_Address_Flag := 'Y';
        l_Party_Site_Create_rec.Status := 'A';
        l_Party_Site_Create_rec.Created_by_module := 'XXCONV';
        --l_Party_Site_Create_rec.Application_id    := 625;

        l_Party_Site_Create_rec.Party_Site_Name := NULL;

        HZ_PARTY_SITE_V2PUB.Create_Party_Site  (
            p_init_msg_list      => 'F',
            p_party_site_rec     => l_party_site_Create_rec,
            x_return_status      => l_return_status,
            x_msg_count          => l_msg_count,
            x_msg_data           => l_msg_data,
            x_party_site_id      => l_party_site_id,
            x_party_site_number  => l_party_site_number
         );

        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_return_status=' || l_return_status);
        iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':l_party_site_id=' || l_party_site_id);

        IF l_return_status = FND_API.G_RET_STS_ERROR OR
           l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;

      END IF; /*End of if l_Call_Api true loop for Party Site*/

    END IF; /*    IF p_location_id IS NOT NULL THEN */

    -- Standard check of p_commit
    IF FND_API.To_Boolean(p_commit) THEN
      COMMIT WORK;
    END IF;

    -- Standard call to get message count and if count is 1, get message info
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data => x_msg_data);


    iex_debug_pub.LogMessage(G_PKG_NAME || '.' || l_api_name || ':end');
  EXCEPTION
  WHEN FND_API.G_EXC_ERROR THEN
    ROLLBACK TO Create_Default_Contact_PVT;
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data => x_msg_data);

  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    ROLLBACK TO Create_Default_Contact_PVT;
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data => x_msg_data);

  WHEN OTHERS THEN
    ROLLBACK TO Create_Default_Contact_PVT;
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
      FND_MSG_PUB.Add_Exc_Msg(G_PKG_NAME, l_api_name);
    END IF;
    FND_MSG_PUB.Count_And_Get(p_count => x_msg_count, p_data => x_msg_data);
  END Create_Default_Contact;

END XX_CDH_CUSTOMER_CONTACT_PKG;
/
SHOW ERRORS;