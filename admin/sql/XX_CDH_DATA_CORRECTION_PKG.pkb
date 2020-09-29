-- SET DEFINE OFF ;

CREATE OR REPLACE PACKAGE BODY xx_cdh_data_correction_pkg
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                         Oracle Consulting                                               |
-- +=========================================================================================+
-- | Name        : XX_CDH_DATA_CORRECTION_PKG                                                |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        17-Sep-2007     Rajeev Kamath        Initial version                          |
-- |2.0        10-Jul-2007     Ambarish Mukherjee   Added code for operating unit fix AOPS   |
-- |3.0        15-Jul-2008     Indra Varada         Modified Code for Operating unit fix AOPS|
-- |3.1        29-Jul-2008     Indra Varada         New Procdedure added to inactivate site  |
-- |3.2        22-Aug-2008     Indra Varada         New Procdedure added to change OSR CA    |
-- |3.3        27-Aug-2008     Kathirvel P        New Procedure added to change attribute13|
-- |3.4        17-Sep-2008     Indra Varada         New Procdedure added to Fix Grandparents |
-- |3.5        02-Jan-2009     Indra Varada         Modified Procedure Main To Dynamically   |
-- |                                                Call the data correction Procedures.     |
-- |3.6        05-Jan-2009     Indra Varada         Modified Procedure process_acct_sites    |
-- |                                                to handle duplicate active sites.        |
-- |3.7        05-Jan-2008     Naga Kalyan          New Procedure fix_multiple_sites_uses    |
-- |                                                added to inactivate duplicate sites and  |
-- |                                                uses in 404 Op Unit.                     |
-- |3.8        05-Feb-2009     Indra Varada         Join condition on OU fix modified        |
-- |3.5        15-Feb-2009     Indra Varada         Added Procedure to Convert customer from |
-- |                                                 indirect to Direct                      |
-- |3.6        22-Apr-2009     Indra Varada         Added procedure to correct CA OSR for    |
-- |                                                   Site Uses                             |
-- |3.7        06-May-2009     Sreedhar Mohan       Added procedure to correct Dup party     |
-- |                                                   Sites for the same site OSR           |
-- |3.8        21-May-2009     Indra Varada         Added procedure to non US,CA Country ou  |
-- |                                                  This script is for one time run only   |
-- |3.9        02-Jun-2009     Indra Varada         Added procedure to fix 'REVOKED' roles   |
-- |4.0        05-Jun-2009     Indra Varada         Data Fix For QC#15686                    |
-- |4.1        09-Jun-2009     Indra Varada        Added procedure to fix prospect flag     |
-- |4.2        09-Jun-2009     Kalyan            Added procedure to activate account      |
-- |                                                profile status.                          |
-- |4.3        02-July-2009    Indra Varada         Procedures added to fix duplicate acct   |
-- |                                                roles, null states, null provinces       |
-- |4.4        09-July-2009    Indra Varada         FiX To Remove Duplicate SPC Defect#493   |
-- |4.4        09-July-2009    Kalyan               FiX To Correct invalid hz_org_contact    |
--                                                  records.                                 |
-- |4.5        10-July-2009    Indra Varada         Logic added to send email alerts         |
-- |4.6        23-July-2009    Kalyan               FiX To inactivate direct customer records|
--                                                  in xx_tm_nam_terr_entity_dtls.           |
-- |4.7        17-Sep-2009     Kalyan               FiX To reset fdk_code for tasks.         |
-- |4.8        04-Nov-2009     Kalyan               Fix for nodes_correction.                |
-- |4.9        19-Nov-2009     Indra Varada         Fix to sync account and party name       |
-- |4.8        19-Jan-2010     Kalyan               Fix collection/contact records related to|
-- |                                                hz_cust_account_roles/hz_contact_points. |
-- |3.7        18-May-2010     Sreedhar Mohan       Added procedure to correct Dup party     |
-- |                                                   Sites extensible attribute groups     |
-- |4.10       21-Jul-2010     Devi                 Fix collection/contact records related to|
-- |                                                hz_cust_account_roles/hz_contact_points  |
-- |                                                for AB customers                         |
-- |                                                                                         |
-- |5.1        15-Jun-2011     Indra Varada         GrandParent Relationship end date        |
-- |5.2        02-Jan-2012     Dheeraj Vernekar     Adding xx_cdh_loyalty_code_fix_main procedure|
-- |                                                for correcting primary flag of party loyalty |
-- |                                                class code, QC 15894.                       |
-- |5.3        13-Feb-2012     Satish Siliveri       Added last_update_date = sysdate in update stmt |
-- |                        in proc fix_dup_primary_site as per the defect 16918|
---| 5.4       27-Sep-2013     Pratesh              Added cust_acct_site_id as a part of retrofit for R12
---|                                               in procedure XX_CDH_DATA_CORRECTION_PKG.convert_indirect_to_direct
---|5.5        24-oCT-2013     Deepak V             I0024 - Changes done for R12 upgrade retrofit|
---|5.6        13-MAY-2015     Sridhar Pamu          Added xxcdh_update_null_pt to correct null payment |
---|                                                 terms in Customer Profiles for defect 34126 |
-- |5.7        05-Jan-2016     Manikant Kasu         Removed schema alias as part of GSCC    |
-- |                                                 R12.2.2 Retrofits                       |
-- |5.8        11-May-2016     Sreedhar Mohan        Removed procedure fix_duplicate_banks   |
-- |                                                 Removed procedure inactivate_entity_dtls|
-- |5.9        26-Jul-2016     Prasad Devar         Removed table reference for TOPS retire Project    |
-- |5.10       21-Sep-2016     Hanmanth Jogiraju     Removed fix_ab_collect_rec procedures   |
---/5.10       22-NOV-2016     Sridhar Pamu         Added delete record logic in SP_EPDF_PURGE_BILLDOCS_PROC and
----                                                SP_EPDF_PURGE_BILLDOCS_INPROC from table xx_cdh_acct_site_ext_b
--- 5.11       04-MAR-2017     Sridhar Pamu         Added procedure xxcdh_update_override_terms for defect 40857
--- 5.12       29-SEP-2020     Rakesh Reddy         Updated error msg variable length in 
----                                                xxcdh_update_override_terms for defect NAIT-156165
-- +=========================================================================================+
AS
   gv_init_msg_list      VARCHAR2 (1) := fnd_api.g_true;
   gn_bulk_fetch_limit   NUMBER  := xx_cdh_conv_master_pkg.g_bulk_fetch_limit;

   PROCEDURE send_data_corr_notif (
      p_subject            VARCHAR2,
      p_body               VARCHAR2,
      p_module             VARCHAR2,
      x_ret_status   OUT   VARCHAR2,
      x_ret_msg      OUT   VARCHAR2
   );

   PROCEDURE fix_duplicate_prim_acct_st_use (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      -- Get accounts that have multiple primary site-uses with same site use code
      CURSOR c_multiples_su
      IS
         SELECT   a.orig_system_reference aosr,
                  su.site_use_code site_use_code
             FROM hz_cust_site_uses su,
                  hz_cust_acct_sites s,
                  hz_cust_accounts_all a
            WHERE s.cust_acct_site_id = su.cust_acct_site_id
              AND s.cust_account_id = a.cust_account_id
              AND su.primary_flag = 'Y'
         GROUP BY a.orig_system_reference, su.site_use_code
           HAVING COUNT (1) > 1;

      -- Get the records from the stg table for those accounts
      CURSOR c_su_stg (cv_aosr IN VARCHAR2, cv_suc IN VARCHAR2)
      IS
         SELECT account_orig_system_reference aosr,
                acct_site_orig_sys_reference asosr, site_use_code,
                primary_flag
           FROM xxod_hz_imp_acct_site_uses_stg stg
          WHERE account_orig_system_reference = cv_aosr
            AND stg.site_use_code = cv_suc;

      l_csai          NUMBER := 0;
      l_cui_updated   NUMBER := 0;
   BEGIN
      log_debug_msg
         (   'Begin: XX_CDH_DATA_CORRECTION_PKG.fix_duplicate_prim_acct_st_use '
          || TO_CHAR (SYSDATE, 'DD-MON HH24:MI:SS')
         );
      log_debug_msg ('Commit is: ' || p_commit);
      -- Create Temporary indexes
      log_debug_msg ('Creating temporary index xxod_hi_asuses_stg_temp1...');

      BEGIN
         EXECUTE IMMEDIATE 'create index xxcnv.xxod_hi_asuses_stg_temp1 on xxcnv.xxod_hz_imp_acct_site_uses_stg(account_orig_system_reference, site_use_code)';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
            log_debug_msg ('Exception while creating index: ' || SQLERRM);
      END;

      -- Get all site uses that have multiple primaries for the same site-use
      FOR mrec IN c_multiples_su
      LOOP
         -- For each of these, look up the value in the staging table
         FOR stgrec IN c_su_stg (mrec.aosr, mrec.site_use_code)
         LOOP
            -- for each of those get the site-id
            -- and then for that site, reset the primary to what is in the staging tables.
            -- We cannot use the API, since the multiple primaries will cause the same problem we have with the create
            BEGIN
               l_csai := 0;

               -- Get the site id for those sites
               SELECT cust_acct_site_id
                 INTO l_csai
                 FROM hz_cust_acct_sites
                WHERE orig_system_reference = stgrec.asosr;

               -- Update the primary flag to what is in the staging table for that acct/site/site-use code combination
               UPDATE hz_cust_site_uses_all su
                  SET primary_flag = stgrec.primary_flag
                WHERE cust_acct_site_id = l_csai
                  AND site_use_code = stgrec.site_use_code
                  AND status = 'A';

               -- Update count of records updated
               l_cui_updated := l_cui_updated + 1;
               -- Log message of updated record
               log_debug_msg (   'Updated Site/UseCode: '
                              || l_csai
                              || '/'
                              || stgrec.site_use_code
                             );
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  log_debug_msg ('Othes Exception: ' || SQLERRM);
            END;

            -- commit at the end of each account since this may be long running
            IF (UPPER (NVL (p_commit, 'N')) = 'Y')
            THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;
         END LOOP;
      END LOOP;

      log_debug_msg ('Total Records Updated: ' || l_cui_updated);
      log_debug_msg ('Dropping temporary index xxod_hi_asuses_stg_temp1...');

      BEGIN
         EXECUTE IMMEDIATE 'drop index xxcnv.xxod_hi_asuses_stg_temp1';
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
            log_debug_msg ('Exception while creating index: ' || SQLERRM);
      END;

      log_debug_msg
         (   'End: XX_CDH_DATA_CORRECTION_PKG.fix_duplicate_prim_acct_st_use '
          || TO_CHAR (SYSDATE, 'DD-MON HH24:MI:SS')
         );
   END fix_duplicate_prim_acct_st_use;

-- +===================================================================+
-- | Name        : fix_duplicate_person_profiles                       |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_duplicate_person_profiles (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      l_ct_deleted         NUMBER;
      l_ct_total_deleted   NUMBER;
   BEGIN
      log_debug_msg (   'Begin fix_duplicate_person_profiles: '
                     || TO_CHAR (SYSDATE, 'DD-MON HH24:MI:SS')
                    );
      log_debug_msg ('Commit is: ' || p_commit);
      -- Disable the VPD policy for this session
      hz_common_pub.disable_cont_source_security;
      log_debug_msg
                 ('VPD Policy on HZ_PERSON_PROFILES disabled for this session');

      -- There are millions of errors that should be deleted.
      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         -- Create batches
         l_ct_total_deleted := 0;

         LOOP
            l_ct_deleted := 0;

            DELETE FROM hz_person_profiles
                  WHERE person_profile_id IN (
                           SELECT person_profile_id
                             FROM (SELECT person_profile_id,
                                          RANK () OVER (PARTITION BY party_id, actual_content_source ORDER BY person_profile_id DESC)
                                                                            r
                                     FROM hz_person_profiles
                                    WHERE effective_end_date IS NULL)
                            WHERE r > 1 AND ROWNUM <= 200000)
              RETURNING COUNT (1)
                   INTO l_ct_deleted;

            -- Maintain count of the total
            l_ct_total_deleted := l_ct_total_deleted + l_ct_deleted;
            log_debug_msg ('Records deleted: ' || l_ct_deleted);
            -- commit at the end of each account since this may be long running
            COMMIT;

            IF (l_ct_deleted < 1)
            THEN
               EXIT;
            END IF;
         END LOOP;

         log_debug_msg ('Total Records deleted: ' || l_ct_total_deleted);
      ELSE
         SELECT COUNT (1)
           INTO l_ct_total_deleted
           FROM (SELECT person_profile_id,
                        RANK () OVER (PARTITION BY party_id, actual_content_source ORDER BY person_profile_id DESC)
                                                                            r
                   FROM hz_person_profiles
                  WHERE effective_end_date IS NULL)
          WHERE r > 1;

         log_debug_msg ('Total records to be deleted: ' || l_ct_total_deleted);
      END IF;

      log_debug_msg (   'End fix_duplicate_person_profiles: '
                     || TO_CHAR (SYSDATE, 'DD-MON HH24:MI:SS')
                    );
   END fix_duplicate_person_profiles;

-- +===================================================================+
-- | Name        : fix_incorrect_org_id                                |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_incorrect_org_id (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      ln_count       NUMBER;
      ln_us_org_id   NUMBER;
      ln_ca_org_id   NUMBER;
      ln_exists      NUMBER;

      CURSOR lc_org_update_cur (ln_org_id NUMBER)
      IS
         SELECT a.cust_acct_site_id,
                b.orig_system_reference account_orig_system_reference,
                a.cust_account_id,
                a.orig_system_reference site_orig_system_reference
           FROM hz_cust_acct_sites_all a, hz_cust_accounts b
          WHERE a.orig_system_reference LIKE '%A0'
            AND a.org_id = ln_org_id
            AND a.cust_account_id = b.cust_account_id;
   BEGIN
      BEGIN
         SELECT hou.organization_id
           INTO ln_us_org_id
           FROM hr_organization_units_v hou
          WHERE hou.NAME = 'OU_US';
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_us_org_id := -1;
            log_debug_msg ('Others exception for US org-id: ' || SQLERRM);
      END;

      BEGIN
         SELECT hou.organization_id
           INTO ln_ca_org_id
           FROM hr_organization_units_v hou
          WHERE hou.NAME = 'OU_CA';
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_ca_org_id := -1;
            log_debug_msg ('Others exception for CA org-id: ' || SQLERRM);
      END;

      FOR lc_org_update_rec IN lc_org_update_cur (ln_ca_org_id)
      LOOP
         BEGIN
            ln_count := ln_count + 1;

            BEGIN
               SELECT 1
                 INTO ln_exists
                 FROM hz_cust_site_uses_all a,
                      hz_cust_acct_sites_all c,
                      hz_party_sites d,
                      hz_locations e
                WHERE c.cust_account_id = lc_org_update_rec.cust_account_id
                  AND c.cust_acct_site_id = a.cust_acct_site_id
                  AND c.party_site_id = d.party_site_id
                  AND d.location_id = e.location_id
                  AND e.country = 'CA'
                  AND a.site_use_code = 'SHIP_TO'
                  AND c.org_id = ln_ca_org_id
                  AND c.orig_system_reference NOT LIKE '%-00001-%';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  ln_exists := 0;
               WHEN TOO_MANY_ROWS
               THEN
                  ln_exists := 1;
               WHEN OTHERS
               THEN
                  ln_exists := 2;
            END;

            IF ln_exists = 0
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   '--------------------------------------------------------'
                  );
               fnd_file.put_line
                              (fnd_file.LOG,
                                  'Account selected for update - '
                               || lc_org_update_rec.account_orig_system_reference
                              );
               fnd_file.put_line (fnd_file.LOG,
                                     'Account Site                - '
                                  || lc_org_update_rec.site_orig_system_reference
                                 );

               --UPDATE hz_cust_accounts
               --SET    org_id = ln_us_org_id
               --WHERE  cust_account_id = lc_org_update_rec.cust_account_id;

               --fnd_file.put_line (fnd_file.log,'Cust Account updated !');
               UPDATE hz_cust_acct_sites_all
                  SET org_id = ln_us_org_id
                WHERE cust_acct_site_id = lc_org_update_rec.cust_acct_site_id;

               fnd_file.put_line (fnd_file.LOG,
                                     'No of Cust Sites updated - '
                                  || SQL%ROWCOUNT
                                 );

               UPDATE hz_cust_site_uses_all
                  SET org_id = ln_us_org_id
                WHERE cust_acct_site_id = lc_org_update_rec.cust_acct_site_id;

               fnd_file.put_line (fnd_file.LOG,
                                     'No of Cust Site Uses updated - '
                                  || SQL%ROWCOUNT
                                 );

               --UPDATE ap_bank_account_uses_all
               --SET    org_id = ln_us_org_id
               --WHERE  customer_id = lc_org_update_rec.cust_account_id;

               --fnd_file.put_line (fnd_file.log,'No of Bank Account Uses updated - '||SQL%ROWCOUNT);

               -- commit at the end of each account since this may be long running
               IF (UPPER (NVL (p_commit, 'N')) = 'Y')
               THEN
                  COMMIT;
                  fnd_file.put_line (fnd_file.LOG, 'Committed changes.. ');
               ELSE
                  ROLLBACK;
                  fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Unexpected Error - ' || SQLERRM
                                 );
               ROLLBACK;
               fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
         END;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Accounts selected for update -' || ln_count
                        );
   END fix_incorrect_org_id;

-- +===================================================================+
-- | Name        : fix_hz_loc_assignments                              |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_hz_loc_assignments (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR lc_fetch_location_cur (p_us_org_id NUMBER, p_ca_org_id NUMBER)
      IS
         SELECT c.location_id
           FROM hz_cust_acct_sites_all a,
                hz_party_sites b,
                hz_loc_assignments c
          WHERE a.org_id = p_us_org_id
            AND a.party_site_id = b.party_site_id
            AND b.location_id = c.location_id
            AND c.org_id = p_ca_org_id;

      ln_count       NUMBER := 0;
      ln_us_org_id   NUMBER;
      ln_ca_org_id   NUMBER;
   BEGIN
      BEGIN
         SELECT hou.organization_id
           INTO ln_us_org_id
           FROM hr_organization_units_v hou
          WHERE hou.NAME = 'OU_US';
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_us_org_id := -1;
            fnd_file.put_line (fnd_file.LOG,
                               'Others exception for US org-id: ' || SQLERRM
                              );
      END;

      BEGIN
         SELECT hou.organization_id
           INTO ln_ca_org_id
           FROM hr_organization_units_v hou
          WHERE hou.NAME = 'OU_CA';
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_ca_org_id := -1;
            fnd_file.put_line (fnd_file.LOG,
                               'Others exception for CA org-id: ' || SQLERRM
                              );
      END;

      FOR lc_fetch_location_rec IN lc_fetch_location_cur (ln_us_org_id,
                                                          ln_ca_org_id
                                                         )
      LOOP
         BEGIN
            UPDATE hz_loc_assignments
               SET org_id = ln_us_org_id
             WHERE location_id = lc_fetch_location_rec.location_id;

            ln_count := ln_count + 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                   (fnd_file.LOG,
                       'Unexpected error while updating hz_loc_assignments -'
                    || SQLERRM
                   );
               fnd_file.put_line (fnd_file.LOG,
                                     'Location Id -'
                                  || lc_fetch_location_rec.location_id
                                 );
         END;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Number of Records Updated -' || ln_count
                        );

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
         fnd_file.put_line (fnd_file.LOG, 'Committed changes.. ');
      ELSE
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
      END IF;
   END;

-- +===================================================================+
-- | Name        : fix_duplicate_role_resp                             |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_duplicate_role_resp (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR lc_fetch_duplicates_cur
      IS
         SELECT   cust_account_role_id, responsibility_type
             FROM hz_role_responsibility
         GROUP BY cust_account_role_id, responsibility_type
           HAVING COUNT (*) > 1;

      ln_count               NUMBER                                      := 0;
      ln_responsibility_id   hz_role_responsibility.responsibility_id%TYPE;
   BEGIN
      log_debug_msg ('Delete duplicate records from hz_role_responsibility');

/*
DELETE
FROM   hz_role_responsibility
WHERE  ROWID IN ( SELECT MIN(rowid)
                  FROM   hz_role_responsibility
                  GROUP BY cust_account_role_id,responsibility_type
                  HAVING COUNT(*) > 1
                );
*/
      FOR lc_fetch_duplicates_rec IN lc_fetch_duplicates_cur
      LOOP
         SELECT MIN (responsibility_id)
           INTO ln_responsibility_id
           FROM hz_role_responsibility
          WHERE cust_account_role_id =
                                  lc_fetch_duplicates_rec.cust_account_role_id
            AND responsibility_type =
                                   lc_fetch_duplicates_rec.responsibility_type;

         DELETE FROM hz_role_responsibility
               WHERE responsibility_id = ln_responsibility_id;

         ln_count := ln_count + SQL%ROWCOUNT;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
         log_debug_msg ('Number of Records Deleted: ' || ln_count);
      ELSE
         ROLLBACK;
         log_debug_msg ('Number of Records to be Deleted: ' || ln_count);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         log_debug_msg
            (   'Unexpected Error while deleting duplicate records from hz_role_responsibility: '
             || SQLERRM
            );
   END fix_duplicate_role_resp;

-- +===================================================================+
-- | Name        : main                                                |
-- |                                                                   |
-- | Description : concurrent program main                             |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE main (
      x_errbuf           OUT      VARCHAR2,
      x_retcode          OUT      VARCHAR2,
      p_commit           IN       VARCHAR2,
      p_procedure_name   IN       VARCHAR2
   )
   AS
      lc_record_count       NUMBER;
      lc_worker_count       NUMBER;
      lc_invoke_procedure   VARCHAR2 (200);
   BEGIN
      log_debug_msg ('Procedure Name Being Invoked:' || p_procedure_name);
      lc_invoke_procedure :=
            'Begin xx_cdh_data_correction_pkg.'
         || p_procedure_name
         || '(:errbuf, :retcode, :commit_val); End;';

      EXECUTE IMMEDIATE lc_invoke_procedure
                  USING OUT x_errbuf, OUT x_retcode, IN p_commit;
   END main;

-- +===================================================================+
-- | Name        : process_acct_sites                                  |
-- |                                                                   |
-- | Description : This procedure will create account sites/uses for a |
-- |               given account OSR.                                  |
-- |                                                                   |
-- | Parameters  : p_account_osr                                       |
-- |                                                                   |
-- +===================================================================+
   FUNCTION process_acct_sites (
      x_errbuf        OUT      VARCHAR2,
      x_retcode       OUT      VARCHAR2,
      p_account_osr   IN       VARCHAR2
   )
      RETURN BOOLEAN
   AS
-- Begin: Change as part of Version 3.8
      CURSOR lc_fetch_cust_acct_sites_cur (p_in_acct_osr IN VARCHAR2)
      IS
         SELECT hcas.*, site_orig.orig_system_ref_id,
                site_orig.object_version_number site_ovn
           FROM hz_orig_sys_references hosr,
                hz_cust_acct_sites_all hcas,
                (SELECT hosr1.orig_system_ref_id, hosr1.orig_system_reference,
                        hosr1.object_version_number, hosr1.owner_table_id
                   FROM hz_orig_sys_references hosr1
                  WHERE hosr1.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
                    --AND    hosr1.status           = 'A'
                    AND hosr1.orig_system = 'A0') site_orig
          WHERE hosr.orig_system_reference = p_in_acct_osr
            AND hosr.orig_system = 'A0'
            AND hosr.status = 'A'
            AND hcas.status = 'A'
            AND hosr.owner_table_name = 'HZ_CUST_ACCOUNTS'
            AND hosr.owner_table_id = hcas.cust_account_id
            AND hcas.cust_acct_site_id = site_orig.owner_table_id
            AND hcas.org_id !=
                   NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'),
                                                    1,
                                                    1
                                                   ),
                                           ' ', NULL,
                                           SUBSTRB (USERENV ('CLIENT_INFO'),
                                                    1,
                                                    10
                                                   )
                                          )
                                  ),
                        -99
                       );

-- End: Change as part of Version 3.8
      CURSOR lc_fetch_acct_site_uses_cur (p_in_cust_acct_site_id IN NUMBER)
      IS
         SELECT hcsu.*
           FROM hz_cust_site_uses_all hcsu
          WHERE hcsu.cust_acct_site_id = p_in_cust_acct_site_id
            AND hcsu.status = 'A';

      lr_cust_acct_site_rec           hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      lr_def_cust_acct_site_rec       hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      lv_return_status                VARCHAR2 (10);
      ln_msg_count                    NUMBER;
      lv_msg_data                     VARCHAR2 (2000);
      l_transaction_error             BOOLEAN                         := FALSE;
      ln_cust_acct_site_id            NUMBER;
      ln_cust_site_use_id             NUMBER;
      lr_cust_site_use_rec            hz_cust_account_site_v2pub.cust_site_use_rec_type;
      lr_def_cust_site_use_rec        hz_cust_account_site_v2pub.cust_site_use_rec_type;
      lr_orig_sys_reference_rec       hz_orig_system_ref_pub.orig_sys_reference_rec_type;
      lr_def_orig_sys_reference_rec   hz_orig_system_ref_pub.orig_sys_reference_rec_type;
      l_operation                     VARCHAR2 (10);
      l_osr_value                     VARCHAR2 (100);
      l_orig_sys_ref_id               NUMBER;
      l_osr_ovn                       NUMBER;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                            'Start of proc process_acct_sites...'
                         || TO_CHAR (SYSDATE, 'HH24:MI:SS')
                        );

      FOR lc_fetch_acct_sites_rec IN
         lc_fetch_cust_acct_sites_cur (p_account_osr)
      LOOP
         IF l_transaction_error
         THEN
            EXIT;
         END IF;

         l_operation := 'NO_VALUE';
         fnd_file.put_line
            (fnd_file.LOG,
             '-------------------------------------------------------------------'
            );
         fnd_file.put_line
            (fnd_file.LOG,
             '-------------------------------------------------------------------'
            );

         BEGIN
            SELECT cust_acct_site_id, orig_system_reference
              INTO ln_cust_acct_site_id, l_osr_value
              FROM hz_cust_acct_sites_all
             WHERE cust_account_id = lc_fetch_acct_sites_rec.cust_account_id
               AND party_site_id = lc_fetch_acct_sites_rec.party_site_id
               AND org_id =
                      NVL
                         (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'),
                                                      1,
                                                      1
                                                     ),
                                             ' ', NULL,
                                             SUBSTRB (USERENV ('CLIENT_INFO'),
                                                      1,
                                                      10
                                                     )
                                            )
                                    ),
                          -99
                         );

            --AND Status            = 'I';

            ---------------------------------------
-- Reactivate Inactive Account Site
---------------------------------------
            UPDATE hz_cust_acct_sites_all
               SET status = 'A',
                   last_update_date = SYSDATE
             WHERE cust_acct_site_id = ln_cust_acct_site_id;

            UPDATE hz_orig_sys_references
               SET status = 'A',
                   last_update_date = SYSDATE,
                   end_date_active = NULL
             WHERE orig_system_reference = l_osr_value
               AND orig_system = 'A0'
               AND owner_table_id = ln_cust_acct_site_id
               AND owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';

            l_operation := 'UPDATED';
            fnd_file.put_line
               (fnd_file.LOG,
                'Inactive Account Site Exists and Successfully Re-Activated...'
               );
            fnd_file.put_line (fnd_file.LOG,
                               'cust_acct_site_id...' || ln_cust_acct_site_id
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
---------------------------------------
-- API Call to Create account site
---------------------------------------
               lr_cust_acct_site_rec := lr_def_cust_acct_site_rec;
               --lr_cust_acct_site_rec.cust_acct_site_id          :=
               lr_cust_acct_site_rec.cust_account_id :=
                                      lc_fetch_acct_sites_rec.cust_account_id;
               lr_cust_acct_site_rec.party_site_id :=
                                        lc_fetch_acct_sites_rec.party_site_id;
               lr_cust_acct_site_rec.attribute_category :=
                                   lc_fetch_acct_sites_rec.attribute_category;
               lr_cust_acct_site_rec.attribute1 :=
                                           lc_fetch_acct_sites_rec.attribute1;
               lr_cust_acct_site_rec.attribute2 :=
                                           lc_fetch_acct_sites_rec.attribute2;
               lr_cust_acct_site_rec.attribute3 :=
                                           lc_fetch_acct_sites_rec.attribute3;
               lr_cust_acct_site_rec.attribute4 :=
                                           lc_fetch_acct_sites_rec.attribute4;
               lr_cust_acct_site_rec.attribute5 :=
                                           lc_fetch_acct_sites_rec.attribute5;
               lr_cust_acct_site_rec.attribute6 :=
                                           lc_fetch_acct_sites_rec.attribute6;
               lr_cust_acct_site_rec.attribute7 :=
                                           lc_fetch_acct_sites_rec.attribute7;
               lr_cust_acct_site_rec.attribute8 :=
                                           lc_fetch_acct_sites_rec.attribute8;
               lr_cust_acct_site_rec.attribute9 :=
                                           lc_fetch_acct_sites_rec.attribute9;
               lr_cust_acct_site_rec.attribute10 :=
                                          lc_fetch_acct_sites_rec.attribute10;
               lr_cust_acct_site_rec.attribute11 :=
                                          lc_fetch_acct_sites_rec.attribute11;
               lr_cust_acct_site_rec.attribute12 :=
                                          lc_fetch_acct_sites_rec.attribute12;
               lr_cust_acct_site_rec.attribute13 :=
                                          lc_fetch_acct_sites_rec.attribute13;
               lr_cust_acct_site_rec.attribute14 :=
                                          lc_fetch_acct_sites_rec.attribute14;
               lr_cust_acct_site_rec.attribute15 :=
                                          lc_fetch_acct_sites_rec.attribute15;
               lr_cust_acct_site_rec.attribute16 :=
                                          lc_fetch_acct_sites_rec.attribute16;
               lr_cust_acct_site_rec.attribute17 :=
                                          lc_fetch_acct_sites_rec.attribute17;
               lr_cust_acct_site_rec.attribute18 :=
                                          lc_fetch_acct_sites_rec.attribute18;
               lr_cust_acct_site_rec.attribute19 :=
                                          lc_fetch_acct_sites_rec.attribute19;
               lr_cust_acct_site_rec.attribute20 :=
                                          lc_fetch_acct_sites_rec.attribute20;
               lr_cust_acct_site_rec.global_attribute_category :=
                            lc_fetch_acct_sites_rec.global_attribute_category;
               lr_cust_acct_site_rec.global_attribute1 :=
                                    lc_fetch_acct_sites_rec.global_attribute1;
               lr_cust_acct_site_rec.global_attribute2 :=
                                    lc_fetch_acct_sites_rec.global_attribute2;
               lr_cust_acct_site_rec.global_attribute3 :=
                                    lc_fetch_acct_sites_rec.global_attribute3;
               lr_cust_acct_site_rec.global_attribute4 :=
                                    lc_fetch_acct_sites_rec.global_attribute4;
               lr_cust_acct_site_rec.global_attribute5 :=
                                    lc_fetch_acct_sites_rec.global_attribute5;
               lr_cust_acct_site_rec.global_attribute6 :=
                                    lc_fetch_acct_sites_rec.global_attribute6;
               lr_cust_acct_site_rec.global_attribute7 :=
                                    lc_fetch_acct_sites_rec.global_attribute7;
               lr_cust_acct_site_rec.global_attribute8 :=
                                    lc_fetch_acct_sites_rec.global_attribute8;
               lr_cust_acct_site_rec.global_attribute9 :=
                                    lc_fetch_acct_sites_rec.global_attribute9;
               lr_cust_acct_site_rec.global_attribute10 :=
                                   lc_fetch_acct_sites_rec.global_attribute10;
               lr_cust_acct_site_rec.global_attribute11 :=
                                   lc_fetch_acct_sites_rec.global_attribute11;
               lr_cust_acct_site_rec.global_attribute12 :=
                                   lc_fetch_acct_sites_rec.global_attribute12;
               lr_cust_acct_site_rec.global_attribute13 :=
                                   lc_fetch_acct_sites_rec.global_attribute13;
               lr_cust_acct_site_rec.global_attribute14 :=
                                   lc_fetch_acct_sites_rec.global_attribute14;
               lr_cust_acct_site_rec.global_attribute15 :=
                                   lc_fetch_acct_sites_rec.global_attribute15;
               lr_cust_acct_site_rec.global_attribute16 :=
                                   lc_fetch_acct_sites_rec.global_attribute16;
               lr_cust_acct_site_rec.global_attribute17 :=
                                   lc_fetch_acct_sites_rec.global_attribute17;
               lr_cust_acct_site_rec.global_attribute18 :=
                                   lc_fetch_acct_sites_rec.global_attribute18;
               lr_cust_acct_site_rec.global_attribute19 :=
                                   lc_fetch_acct_sites_rec.global_attribute19;
               lr_cust_acct_site_rec.global_attribute20 :=
                                   lc_fetch_acct_sites_rec.global_attribute20;
               lr_cust_acct_site_rec.orig_system_reference :=
                                lc_fetch_acct_sites_rec.orig_system_reference;
               lr_cust_acct_site_rec.orig_system := 'A0';
               lr_cust_acct_site_rec.status := 'A';
               lr_cust_acct_site_rec.customer_category_code :=
                               lc_fetch_acct_sites_rec.customer_category_code;
               lr_cust_acct_site_rec.LANGUAGE :=
                                             lc_fetch_acct_sites_rec.LANGUAGE;
               lr_cust_acct_site_rec.key_account_flag :=
                                     lc_fetch_acct_sites_rec.key_account_flag;
               lr_cust_acct_site_rec.tp_header_id :=
                                         lc_fetch_acct_sites_rec.tp_header_id;
               lr_cust_acct_site_rec.ece_tp_location_code :=
                                 lc_fetch_acct_sites_rec.ece_tp_location_code;
               lr_cust_acct_site_rec.primary_specialist_id :=
                                lc_fetch_acct_sites_rec.primary_specialist_id;
               lr_cust_acct_site_rec.secondary_specialist_id :=
                              lc_fetch_acct_sites_rec.secondary_specialist_id;
               lr_cust_acct_site_rec.territory_id :=
                                         lc_fetch_acct_sites_rec.territory_id;
               lr_cust_acct_site_rec.territory :=
                                            lc_fetch_acct_sites_rec.territory;
               lr_cust_acct_site_rec.translated_customer_name :=
                             lc_fetch_acct_sites_rec.translated_customer_name;
               lr_cust_acct_site_rec.created_by_module := 'XXCONV';
               lr_cust_acct_site_rec.application_id :=
                                       lc_fetch_acct_sites_rec.application_id;
               fnd_file.put_line
                               (fnd_file.LOG,
                                   'Create Account Site :'
                                || lc_fetch_acct_sites_rec.orig_system_reference
                               );
               hz_cust_account_site_v2pub.create_cust_acct_site
                               (p_init_msg_list           => fnd_api.g_true,
                                p_cust_acct_site_rec      => lr_cust_acct_site_rec,
                                x_cust_acct_site_id       => ln_cust_acct_site_id,
                                x_return_status           => lv_return_status,
                                x_msg_count               => ln_msg_count,
                                x_msg_data                => lv_msg_data
                               );
               l_operation := 'CREATED';

               IF lv_return_status = fnd_api.g_ret_sts_success
               THEN
                  fnd_file.put_line (fnd_file.LOG,
                                     'Account Site successfully created...'
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                        'cust_acct_site_id...'
                                     || ln_cust_acct_site_id
                                    );
               ELSE
                  l_transaction_error := TRUE;
               END IF;
         END;

         IF    (    l_operation = 'CREATED'
                AND lv_return_status = fnd_api.g_ret_sts_success
               )
            OR l_operation = 'UPDATED'
         THEN
            IF ln_cust_acct_site_id IS NOT NULL
            THEN
               FOR lc_fetch_acct_site_uses_rec IN
                  lc_fetch_acct_site_uses_cur
                                   (lc_fetch_acct_sites_rec.cust_acct_site_id)
               LOOP
                  fnd_file.put_line (fnd_file.LOG, ' ');

                  BEGIN
                     SELECT site_use_id, orig_system_reference
                       INTO ln_cust_site_use_id, l_osr_value
                       FROM hz_cust_site_uses_all
                      WHERE cust_acct_site_id = ln_cust_acct_site_id
                        AND site_use_code =
                                     lc_fetch_acct_site_uses_rec.site_use_code
                        AND org_id =
                               NVL
                                  (TO_NUMBER
                                      (DECODE
                                            (SUBSTRB (USERENV ('CLIENT_INFO'),
                                                      1,
                                                      1
                                                     ),
                                             ' ', NULL,
                                             SUBSTRB (USERENV ('CLIENT_INFO'),
                                                      1,
                                                      10
                                                     )
                                            )
                                      ),
                                   -99
                                  );

                     --AND Status              = 'I';

                     ------------------------------------------
 -- Reactivate Inactive Account Site Use
------------------------------------------
                     UPDATE hz_cust_site_uses_all
                        SET status = 'A',
                            primary_flag =
                                      lc_fetch_acct_site_uses_rec.primary_flag,
                            last_update_date = SYSDATE
                      WHERE site_use_id = ln_cust_site_use_id;

                     UPDATE hz_orig_sys_references
                        SET status = 'A',
                            last_update_date = SYSDATE,
                            end_date_active = NULL
                      WHERE orig_system_reference = l_osr_value
                        AND orig_system = 'A0'
                        AND owner_table_id = ln_cust_site_use_id
                        AND owner_table_name = 'HZ_CUST_SITE_USES_ALL';

                     l_operation := 'UPDATED';
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'Inactive Site Use Exists and Successfully Re-Activated...'
                        );
                     fnd_file.put_line (fnd_file.LOG,
                                        'site_use_id...'
                                        || ln_cust_site_use_id
                                       );
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
---------------------------------------
 -- API Call to Create account site Uses
---------------------------------------
                        lr_cust_site_use_rec := lr_def_cust_site_use_rec;
                        --lr_cust_site_use_rec.site_use_id                     :=
                        lr_cust_site_use_rec.cust_acct_site_id :=
                                                         ln_cust_acct_site_id;
                        lr_cust_site_use_rec.site_use_code :=
                                    lc_fetch_acct_site_uses_rec.site_use_code;
                        lr_cust_site_use_rec.primary_flag :=
                                     lc_fetch_acct_site_uses_rec.primary_flag;
                        lr_cust_site_use_rec.status := 'A';
                        lr_cust_site_use_rec.LOCATION :=
                                         lc_fetch_acct_site_uses_rec.LOCATION;
                        lr_cust_site_use_rec.contact_id :=
                                       lc_fetch_acct_site_uses_rec.contact_id;
                        lr_cust_site_use_rec.bill_to_site_use_id :=
                              lc_fetch_acct_site_uses_rec.bill_to_site_use_id;
                        lr_cust_site_use_rec.orig_system_reference :=
                            lc_fetch_acct_site_uses_rec.orig_system_reference;
                        lr_cust_site_use_rec.orig_system := 'A0';
                        lr_cust_site_use_rec.sic_code :=
                                         lc_fetch_acct_site_uses_rec.sic_code;
                        lr_cust_site_use_rec.payment_term_id :=
                                  lc_fetch_acct_site_uses_rec.payment_term_id;
                        lr_cust_site_use_rec.gsa_indicator :=
                                    lc_fetch_acct_site_uses_rec.gsa_indicator;
                        lr_cust_site_use_rec.ship_partial :=
                                     lc_fetch_acct_site_uses_rec.ship_partial;
                        lr_cust_site_use_rec.ship_via :=
                                         lc_fetch_acct_site_uses_rec.ship_via;
                        lr_cust_site_use_rec.fob_point :=
                                        lc_fetch_acct_site_uses_rec.fob_point;
                        lr_cust_site_use_rec.order_type_id :=
                                    lc_fetch_acct_site_uses_rec.order_type_id;
                        lr_cust_site_use_rec.price_list_id :=
                                    lc_fetch_acct_site_uses_rec.price_list_id;
                        lr_cust_site_use_rec.freight_term :=
                                     lc_fetch_acct_site_uses_rec.freight_term;
                        lr_cust_site_use_rec.warehouse_id :=
                                     lc_fetch_acct_site_uses_rec.warehouse_id;
                        lr_cust_site_use_rec.territory_id :=
                                     lc_fetch_acct_site_uses_rec.territory_id;
                        lr_cust_site_use_rec.attribute_category :=
                               lc_fetch_acct_site_uses_rec.attribute_category;
                        lr_cust_site_use_rec.attribute1 :=
                                       lc_fetch_acct_site_uses_rec.attribute1;
                        lr_cust_site_use_rec.attribute2 :=
                                       lc_fetch_acct_site_uses_rec.attribute2;
                        lr_cust_site_use_rec.attribute3 :=
                                       lc_fetch_acct_site_uses_rec.attribute3;
                        lr_cust_site_use_rec.attribute4 :=
                                       lc_fetch_acct_site_uses_rec.attribute4;
                        lr_cust_site_use_rec.attribute5 :=
                                       lc_fetch_acct_site_uses_rec.attribute5;
                        lr_cust_site_use_rec.attribute6 :=
                                       lc_fetch_acct_site_uses_rec.attribute6;
                        lr_cust_site_use_rec.attribute7 :=
                                       lc_fetch_acct_site_uses_rec.attribute7;
                        lr_cust_site_use_rec.attribute8 :=
                                       lc_fetch_acct_site_uses_rec.attribute8;
                        lr_cust_site_use_rec.attribute9 :=
                                       lc_fetch_acct_site_uses_rec.attribute9;
                        lr_cust_site_use_rec.attribute10 :=
                                      lc_fetch_acct_site_uses_rec.attribute10;
                        lr_cust_site_use_rec.tax_reference :=
                                    lc_fetch_acct_site_uses_rec.tax_reference;
                        lr_cust_site_use_rec.sort_priority :=
                                    lc_fetch_acct_site_uses_rec.sort_priority;
                        lr_cust_site_use_rec.tax_code :=
                                         lc_fetch_acct_site_uses_rec.tax_code;
                        lr_cust_site_use_rec.attribute11 :=
                                      lc_fetch_acct_site_uses_rec.attribute11;
                        lr_cust_site_use_rec.attribute12 :=
                                      lc_fetch_acct_site_uses_rec.attribute12;
                        lr_cust_site_use_rec.attribute13 :=
                                      lc_fetch_acct_site_uses_rec.attribute13;
                        lr_cust_site_use_rec.attribute14 :=
                                      lc_fetch_acct_site_uses_rec.attribute14;
                        lr_cust_site_use_rec.attribute15 :=
                                      lc_fetch_acct_site_uses_rec.attribute15;
                        lr_cust_site_use_rec.attribute16 :=
                                      lc_fetch_acct_site_uses_rec.attribute16;
                        lr_cust_site_use_rec.attribute17 :=
                                      lc_fetch_acct_site_uses_rec.attribute17;
                        lr_cust_site_use_rec.attribute18 :=
                                      lc_fetch_acct_site_uses_rec.attribute18;
                        lr_cust_site_use_rec.attribute19 :=
                                      lc_fetch_acct_site_uses_rec.attribute19;
                        lr_cust_site_use_rec.attribute20 :=
                                      lc_fetch_acct_site_uses_rec.attribute20;
                        lr_cust_site_use_rec.attribute21 :=
                                      lc_fetch_acct_site_uses_rec.attribute21;
                        lr_cust_site_use_rec.attribute22 :=
                                      lc_fetch_acct_site_uses_rec.attribute22;
                        lr_cust_site_use_rec.attribute23 :=
                                      lc_fetch_acct_site_uses_rec.attribute23;
                        lr_cust_site_use_rec.attribute24 :=
                                      lc_fetch_acct_site_uses_rec.attribute24;
                        lr_cust_site_use_rec.attribute25 :=
                                      lc_fetch_acct_site_uses_rec.attribute25;
                        lr_cust_site_use_rec.demand_class_code :=
                                lc_fetch_acct_site_uses_rec.demand_class_code;
                        lr_cust_site_use_rec.tax_header_level_flag :=
                            lc_fetch_acct_site_uses_rec.tax_header_level_flag;
                        lr_cust_site_use_rec.tax_rounding_rule :=
                                lc_fetch_acct_site_uses_rec.tax_rounding_rule;
                        lr_cust_site_use_rec.global_attribute1 :=
                                lc_fetch_acct_site_uses_rec.global_attribute1;
                        lr_cust_site_use_rec.global_attribute2 :=
                                lc_fetch_acct_site_uses_rec.global_attribute2;
                        lr_cust_site_use_rec.global_attribute3 :=
                                lc_fetch_acct_site_uses_rec.global_attribute3;
                        lr_cust_site_use_rec.global_attribute4 :=
                                lc_fetch_acct_site_uses_rec.global_attribute4;
                        lr_cust_site_use_rec.global_attribute5 :=
                                lc_fetch_acct_site_uses_rec.global_attribute5;
                        lr_cust_site_use_rec.global_attribute6 :=
                                lc_fetch_acct_site_uses_rec.global_attribute6;
                        lr_cust_site_use_rec.global_attribute7 :=
                                lc_fetch_acct_site_uses_rec.global_attribute7;
                        lr_cust_site_use_rec.global_attribute8 :=
                                lc_fetch_acct_site_uses_rec.global_attribute8;
                        lr_cust_site_use_rec.global_attribute9 :=
                                lc_fetch_acct_site_uses_rec.global_attribute9;
                        lr_cust_site_use_rec.global_attribute10 :=
                               lc_fetch_acct_site_uses_rec.global_attribute10;
                        lr_cust_site_use_rec.global_attribute11 :=
                               lc_fetch_acct_site_uses_rec.global_attribute11;
                        lr_cust_site_use_rec.global_attribute12 :=
                               lc_fetch_acct_site_uses_rec.global_attribute12;
                        lr_cust_site_use_rec.global_attribute13 :=
                               lc_fetch_acct_site_uses_rec.global_attribute13;
                        lr_cust_site_use_rec.global_attribute14 :=
                               lc_fetch_acct_site_uses_rec.global_attribute14;
                        lr_cust_site_use_rec.global_attribute15 :=
                               lc_fetch_acct_site_uses_rec.global_attribute15;
                        lr_cust_site_use_rec.global_attribute16 :=
                               lc_fetch_acct_site_uses_rec.global_attribute16;
                        lr_cust_site_use_rec.global_attribute17 :=
                               lc_fetch_acct_site_uses_rec.global_attribute17;
                        lr_cust_site_use_rec.global_attribute18 :=
                               lc_fetch_acct_site_uses_rec.global_attribute18;
                        lr_cust_site_use_rec.global_attribute19 :=
                               lc_fetch_acct_site_uses_rec.global_attribute19;
                        lr_cust_site_use_rec.global_attribute20 :=
                               lc_fetch_acct_site_uses_rec.global_attribute20;
                        lr_cust_site_use_rec.global_attribute_category :=
                           lc_fetch_acct_site_uses_rec.global_attribute_category;
                        lr_cust_site_use_rec.primary_salesrep_id :=
                              lc_fetch_acct_site_uses_rec.primary_salesrep_id;
                        lr_cust_site_use_rec.finchrg_receivables_trx_id :=
                           lc_fetch_acct_site_uses_rec.finchrg_receivables_trx_id;
                        lr_cust_site_use_rec.dates_negative_tolerance :=
                           lc_fetch_acct_site_uses_rec.dates_negative_tolerance;
                        lr_cust_site_use_rec.dates_positive_tolerance :=
                           lc_fetch_acct_site_uses_rec.dates_positive_tolerance;
                        lr_cust_site_use_rec.date_type_preference :=
                             lc_fetch_acct_site_uses_rec.date_type_preference;
                        lr_cust_site_use_rec.over_shipment_tolerance :=
                           lc_fetch_acct_site_uses_rec.over_shipment_tolerance;
                        lr_cust_site_use_rec.under_shipment_tolerance :=
                           lc_fetch_acct_site_uses_rec.under_shipment_tolerance;
                        lr_cust_site_use_rec.item_cross_ref_pref :=
                              lc_fetch_acct_site_uses_rec.item_cross_ref_pref;
                        lr_cust_site_use_rec.over_return_tolerance :=
                            lc_fetch_acct_site_uses_rec.over_return_tolerance;
                        lr_cust_site_use_rec.under_return_tolerance :=
                           lc_fetch_acct_site_uses_rec.under_return_tolerance;
                        lr_cust_site_use_rec.ship_sets_include_lines_flag :=
                           lc_fetch_acct_site_uses_rec.ship_sets_include_lines_flag;
                        lr_cust_site_use_rec.arrivalsets_include_lines_flag :=
                           lc_fetch_acct_site_uses_rec.arrivalsets_include_lines_flag;
                        lr_cust_site_use_rec.sched_date_push_flag :=
                             lc_fetch_acct_site_uses_rec.sched_date_push_flag;
                        lr_cust_site_use_rec.invoice_quantity_rule :=
                            lc_fetch_acct_site_uses_rec.invoice_quantity_rule;
                        lr_cust_site_use_rec.pricing_event :=
                                    lc_fetch_acct_site_uses_rec.pricing_event;
                        lr_cust_site_use_rec.gl_id_rec :=
                                        lc_fetch_acct_site_uses_rec.gl_id_rec;
                        lr_cust_site_use_rec.gl_id_rev :=
                                        lc_fetch_acct_site_uses_rec.gl_id_rev;
                        lr_cust_site_use_rec.gl_id_tax :=
                                        lc_fetch_acct_site_uses_rec.gl_id_tax;
                        lr_cust_site_use_rec.gl_id_freight :=
                                    lc_fetch_acct_site_uses_rec.gl_id_freight;
                        lr_cust_site_use_rec.gl_id_clearing :=
                                   lc_fetch_acct_site_uses_rec.gl_id_clearing;
                        lr_cust_site_use_rec.gl_id_unbilled :=
                                   lc_fetch_acct_site_uses_rec.gl_id_unbilled;
                        lr_cust_site_use_rec.gl_id_unearned :=
                                   lc_fetch_acct_site_uses_rec.gl_id_unearned;
                        lr_cust_site_use_rec.gl_id_unpaid_rec :=
                                 lc_fetch_acct_site_uses_rec.gl_id_unpaid_rec;
                        lr_cust_site_use_rec.gl_id_remittance :=
                                 lc_fetch_acct_site_uses_rec.gl_id_remittance;
                        lr_cust_site_use_rec.gl_id_factor :=
                                     lc_fetch_acct_site_uses_rec.gl_id_factor;
                        lr_cust_site_use_rec.tax_classification :=
                               lc_fetch_acct_site_uses_rec.tax_classification;
                        lr_cust_site_use_rec.created_by_module := 'XXCONV';
                        lr_cust_site_use_rec.application_id :=
                                   lc_fetch_acct_site_uses_rec.application_id;
                        fnd_file.put_line
                           (fnd_file.LOG,
                               'Create Account Site Use :'
                            || lc_fetch_acct_site_uses_rec.orig_system_reference
                           );
                        hz_cust_account_site_v2pub.create_cust_site_use
                                 (p_init_msg_list             => fnd_api.g_true,
                                  p_cust_site_use_rec         => lr_cust_site_use_rec,
                                  p_customer_profile_rec      => NULL,
                                  p_create_profile            => fnd_api.g_false,
                                  p_create_profile_amt        => fnd_api.g_false,
                                  x_site_use_id               => ln_cust_site_use_id,
                                  x_return_status             => lv_return_status,
                                  x_msg_count                 => ln_msg_count,
                                  x_msg_data                  => lv_msg_data
                                 );
                        l_operation := 'CREATED';

                        IF lv_return_status = fnd_api.g_ret_sts_success
                        THEN
                           fnd_file.put_line
                                  (fnd_file.LOG,
                                   'Account Site Use successfully created...'
                                  );
                           fnd_file.put_line (fnd_file.LOG,
                                                 'cust_site_use_id...'
                                              || ln_cust_site_use_id
                                             );
                        ELSE
                           l_transaction_error := TRUE;
                        END IF;
                  END;

                  IF     (   (    l_operation = 'CREATED'
                              AND lv_return_status = fnd_api.g_ret_sts_success
                             )
                          OR l_operation = 'UPDATED'
                         )
                     AND ln_cust_site_use_id IS NOT NULL
                  THEN
                     UPDATE hz_cust_site_uses_all
                        SET primary_flag = 'N',
                            status = 'I',
                            last_update_date = SYSDATE
                      WHERE site_use_id =
                                       lc_fetch_acct_site_uses_rec.site_use_id;

                     fnd_file.put_line
                              (fnd_file.LOG,
                               'Old Account Site Use successfully Inactivated'
                              );
                     fnd_file.put_line
                                      (fnd_file.LOG,
                                          'Old Account Site Use ID:'
                                       || lc_fetch_acct_site_uses_rec.site_use_id
                                      );

                     BEGIN
                        SELECT orig_system_ref_id, object_version_number
                          INTO l_orig_sys_ref_id, l_osr_ovn
                          FROM hz_orig_sys_references
                         WHERE orig_system_reference =
                                  lc_fetch_acct_site_uses_rec.orig_system_reference
                           AND orig_system = 'A0'
                           AND owner_table_name = 'HZ_CUST_SITE_USES_ALL'
                           AND owner_table_id =
                                       lc_fetch_acct_site_uses_rec.site_use_id
                           AND status = 'A';

------------------------------------------------------------
-- API Call to inactivate record in hz_orig_sys_references
 ------------------------------------------------------------
                        fnd_file.put_line (fnd_file.LOG,
                                              'orig_system_ref_id- '
                                           || l_orig_sys_ref_id
                                          );
                        lr_orig_sys_reference_rec :=
                                                 lr_def_orig_sys_reference_rec;
                        lr_orig_sys_reference_rec.orig_system_ref_id :=
                                                             l_orig_sys_ref_id;
                        lr_orig_sys_reference_rec.orig_system := 'A0';
                        lr_orig_sys_reference_rec.orig_system_reference :=
                             lc_fetch_acct_site_uses_rec.orig_system_reference;
                        lr_orig_sys_reference_rec.owner_table_name :=
                                                       'HZ_CUST_SITE_USES_ALL';
                        lr_orig_sys_reference_rec.owner_table_id :=
                                       lc_fetch_acct_site_uses_rec.site_use_id;
                        lr_orig_sys_reference_rec.status := 'I';
                        lr_orig_sys_reference_rec.end_date_active :=
                                                               TRUNC (SYSDATE);
                        hz_orig_system_ref_pub.update_orig_system_reference
                           (p_init_msg_list               => fnd_api.g_true,
                            p_orig_sys_reference_rec      => lr_orig_sys_reference_rec,
                            p_object_version_number       => l_osr_ovn,
                            x_return_status               => lv_return_status,
                            x_msg_count                   => ln_msg_count,
                            x_msg_data                    => lv_msg_data
                           );

                        IF lv_return_status = fnd_api.g_ret_sts_success
                        THEN
                           fnd_file.put_line
                              (fnd_file.LOG,
                               'Record in hz_orig_sys_references successfully inactivated...'
                              );
                        ELSE
                           l_transaction_error := TRUE;

                           IF ln_msg_count > 0
                           THEN
                              fnd_file.put_line
                                 (fnd_file.LOG,
                                  'API HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference returned Error while inactivating account site... '
                                 );

                              FOR counter IN 1 .. ln_msg_count
                              LOOP
                                 fnd_file.put_line
                                            (fnd_file.LOG,
                                                'Error - '
                                             || fnd_msg_pub.get
                                                              (counter,
                                                               fnd_api.g_false
                                                              )
                                            );
                              END LOOP;

                              fnd_msg_pub.delete_msg;
                           END IF;
                        END IF;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           --l_transaction_error := TRUE;
                           fnd_file.put_line
                              (fnd_file.LOG,
                                  'Warning - OSR Entry Not Found For SiteUse OSR: '
                               || lc_fetch_acct_site_uses_rec.orig_system_reference
                              );
                     END;
                  ELSE
                     l_transaction_error := TRUE;

                     IF ln_msg_count > 0
                     THEN
                        fnd_file.put_line
                           (fnd_file.LOG,
                            'API HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_site_use returned Error ... '
                           );

                        FOR counter IN 1 .. ln_msg_count
                        LOOP
                           fnd_file.put_line
                                            (fnd_file.LOG,
                                                'Error - '
                                             || fnd_msg_pub.get
                                                              (counter,
                                                               fnd_api.g_false
                                                              )
                                            );
                        END LOOP;

                        fnd_msg_pub.delete_msg;
                     END IF;
                  END IF;
               END LOOP;
            END IF;

            IF l_transaction_error = FALSE
            THEN
               UPDATE hz_cust_acct_sites_all
                  SET status = 'I',
                      last_update_date = SYSDATE
                WHERE cust_acct_site_id =
                                     lc_fetch_acct_sites_rec.cust_acct_site_id;

               fnd_file.put_line (fnd_file.LOG,
                                  'Old Account Site Successfully Inactivated'
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                     'Old Account Site ID:'
                                  || lc_fetch_acct_sites_rec.cust_acct_site_id
                                 );
------------------------------------------------------------
-- API Call to inactivate record in hz_orig_sys_references
------------------------------------------------------------
               fnd_file.put_line (fnd_file.LOG,
                                     'orig_system_ref_id- '
                                  || lc_fetch_acct_sites_rec.orig_system_ref_id
                                 );
               lr_orig_sys_reference_rec := lr_def_orig_sys_reference_rec;
               lr_orig_sys_reference_rec.orig_system_ref_id :=
                                    lc_fetch_acct_sites_rec.orig_system_ref_id;
               lr_orig_sys_reference_rec.orig_system := 'A0';
               lr_orig_sys_reference_rec.orig_system_reference :=
                                 lc_fetch_acct_sites_rec.orig_system_reference;
               lr_orig_sys_reference_rec.owner_table_name :=
                                                      'HZ_CUST_ACCT_SITES_ALL';
               lr_orig_sys_reference_rec.owner_table_id :=
                                     lc_fetch_acct_sites_rec.cust_acct_site_id;
               lr_orig_sys_reference_rec.status := 'I';
               lr_orig_sys_reference_rec.end_date_active := TRUNC (SYSDATE);
               hz_orig_system_ref_pub.update_orig_system_reference
                  (p_init_msg_list               => fnd_api.g_true,
                   p_orig_sys_reference_rec      => lr_orig_sys_reference_rec,
                   p_object_version_number       => lc_fetch_acct_sites_rec.site_ovn,
                   x_return_status               => lv_return_status,
                   x_msg_count                   => ln_msg_count,
                   x_msg_data                    => lv_msg_data
                  );

               IF lv_return_status = fnd_api.g_ret_sts_success
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                      'Record in hz_orig_sys_references successfully inactivated...'
                     );
               ELSE
                  l_transaction_error := TRUE;

                  IF ln_msg_count > 0
                  THEN
                     fnd_file.put_line
                        (fnd_file.LOG,
                         'API HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference returned Error while inactivating account site... '
                        );

                     FOR counter IN 1 .. ln_msg_count
                     LOOP
                        fnd_file.put_line (fnd_file.LOG,
                                              'Error - '
                                           || fnd_msg_pub.get (counter,
                                                               fnd_api.g_false
                                                              )
                                          );
                     END LOOP;

                     fnd_msg_pub.delete_msg;
                  END IF;
               END IF;
            END IF;
         ELSE
            l_transaction_error := TRUE;

            IF ln_msg_count > 0
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'API HZ_CUST_ACCOUNT_SITE_V2PUB.create_cust_acct_site returned Error ... '
                  );

               FOR counter IN 1 .. ln_msg_count
               LOOP
                  fnd_file.put_line (fnd_file.LOG,
                                        'Error - '
                                     || fnd_msg_pub.get (counter,
                                                         fnd_api.g_false
                                                        )
                                    );
               END LOOP;

               fnd_msg_pub.delete_msg;
            END IF;
         END IF;
      END LOOP;

      RETURN l_transaction_error;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         x_retcode := 1;
         x_errbuf :=
                'Unexpected Error in procedure process_acct_sites' || SQLERRM;
   END process_acct_sites;

-- +===================================================================+
-- | Name        : acct_ou_correction_main                             |
-- |                                                                   |
-- | Description : concurrent program main                             |
-- |                                                                   |
-- | Parameters  : p_commit                                            |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE acct_ou_correction_main (
      x_errbuf         OUT      VARCHAR2,
      x_retcode        OUT      VARCHAR2,
      p_bulk_process   IN       VARCHAR2 DEFAULT 'N',
      p_batch_id       IN       NUMBER,
      p_account_osr    IN       VARCHAR2
   )
   IS
      p_acct_osr         VARCHAR2 (2000);
      p_acct_osr_rem     VARCHAR2 (2000);
      ln_count           NUMBER;
      l_error            BOOLEAN;
      l_total_rec        NUMBER          := 0;
      l_succ_rec         NUMBER          := 0;
      l_failed_rec       NUMBER          := 0;
      l_acct_not_found   NUMBER          := 0;

      CURSOR p_osr_cur (p_batch_id NUMBER)
      IS
         SELECT organization_name
           FROM hz_imp_parties_int
          WHERE batch_id = p_batch_id;
   BEGIN
      fnd_file.put_line (fnd_file.output,
                         '========= SUCCESS : Account OSRs ========='
                        );

      IF p_bulk_process = 'N' OR TRIM (p_bulk_process) IS NULL
      THEN
         IF num_chars (p_account_osr, ',') = 0
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               '--------------------------------'
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Account OSR : ' || p_account_osr);
            fnd_file.put_line (fnd_file.LOG,
                               '--------------------------------'
                              );
            l_total_rec := l_total_rec + 1;
            l_error :=
               process_acct_sites (x_errbuf           => x_errbuf,
                                   x_retcode          => x_retcode,
                                   p_account_osr      => p_account_osr
                                  );

            IF l_error = TRUE
            THEN
               ROLLBACK;
               l_failed_rec := l_failed_rec + 1;
            ELSE
               COMMIT;
               l_succ_rec := l_succ_rec + 1;
               fnd_file.put_line (fnd_file.output, p_account_osr);
            END IF;
         ELSE
            p_acct_osr_rem := ',' || p_account_osr;
            ln_count := num_chars (p_acct_osr_rem, ',');

            FOR i IN 1 .. ln_count
            LOOP
               IF i < ln_count
               THEN
                  p_acct_osr :=
                     REGEXP_REPLACE (REGEXP_SUBSTR (p_acct_osr_rem, ',[^,]*,'),
                                     ',',
                                     ''
                                    );
                  p_acct_osr_rem :=
                        REGEXP_REPLACE (p_acct_osr_rem, ',' || p_acct_osr, '');
               ELSE
                  p_acct_osr := REGEXP_REPLACE (p_acct_osr_rem, ',', '');
               END IF;

               p_acct_osr := TRIM (p_acct_osr);

               IF p_acct_osr IS NOT NULL
               THEN
                  fnd_file.put_line (fnd_file.LOG,
                                     '--------------------------------'
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     'Account OSR : ' || p_acct_osr
                                    );
                  fnd_file.put_line (fnd_file.LOG,
                                     '--------------------------------'
                                    );
                  l_total_rec := l_total_rec + 1;
                  l_error :=
                     process_acct_sites (x_errbuf           => x_errbuf,
                                         x_retcode          => x_retcode,
                                         p_account_osr      => p_acct_osr
                                        );

                  IF l_error = TRUE
                  THEN
                     ROLLBACK;
                     l_failed_rec := l_failed_rec + 1;
                  ELSE
                     COMMIT;
                     l_succ_rec := l_succ_rec + 1;
                     fnd_file.put_line (fnd_file.output, p_acct_osr);
                  END IF;
               END IF;
            END LOOP;
         END IF;
      ELSE
         FOR l_acct_osr IN p_osr_cur (p_batch_id)
         LOOP
            fnd_file.put_line (fnd_file.LOG,
                               '--------------------------------'
                              );
            fnd_file.put_line (fnd_file.LOG,
                               'Account OSR : '
                               || l_acct_osr.organization_name
                              );
            fnd_file.put_line (fnd_file.LOG,
                               '--------------------------------'
                              );
            l_total_rec := l_total_rec + 1;
            l_error :=
               process_acct_sites
                                (x_errbuf           => x_errbuf,
                                 x_retcode          => x_retcode,
                                 p_account_osr      => l_acct_osr.organization_name
                                );

            IF l_error = TRUE
            THEN
               ROLLBACK;
               l_failed_rec := l_failed_rec + 1;
            ELSE
               COMMIT;
               l_succ_rec := l_succ_rec + 1;
               fnd_file.put_line (fnd_file.output,
                                  l_acct_osr.organization_name
                                 );
            END IF;
         END LOOP;
      END IF;

      l_acct_not_found := l_total_rec - (l_succ_rec + l_failed_rec);
      fnd_file.put_line (fnd_file.output,
                         '========= SUCCESS : Account OSRs ========='
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Accounts Processed:' || l_total_rec
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Accounts Successful:' || l_succ_rec
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Accounts Failed:' || l_failed_rec
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Account OSRs Not Found:' || l_acct_not_found
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 1;
         x_errbuf :=
            'Unexpected Error in procedure acct_ou_correction_main'
            || SQLERRM;
   END acct_ou_correction_main;

-- +===================================================================+
-- | Name        :         NUM_CHARS                                   |
-- | Description :         This Function will be used to find the      |
-- |                       count of a patterm in a string              |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :         INSTRING, INPATTERN                         |
-- |                                                                   |
-- | Returns     :         error message                               |
-- |                                                                   |
-- +===================================================================+
   FUNCTION num_chars (instring VARCHAR2, inpattern VARCHAR2)
      RETURN NUMBER
   IS
      counter      NUMBER;
      next_index   NUMBER;
      STRING       VARCHAR2 (2000);
      pattern      VARCHAR2 (2000);
   BEGIN
      counter := 0;
      next_index := 1;
      STRING := LOWER (instring);
      pattern := LOWER (inpattern);

      FOR i IN 1 .. LENGTH (STRING)
      LOOP
         IF     (LENGTH (pattern) <= LENGTH (STRING) - next_index + 1)
            AND (SUBSTR (STRING, next_index, LENGTH (pattern)) = pattern)
         THEN
            counter := counter + 1;
         END IF;

         next_index := next_index + 1;
      END LOOP;

      RETURN counter;
   END num_chars;

-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- |                                                                   |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE log_debug_msg (p_debug_msg IN VARCHAR2)
   AS
   BEGIN
      xx_cdh_conv_master_pkg.write_conc_log_message (p_debug_msg);
   END log_debug_msg;

-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |               conversion common elements tables.                  |
-- |                                                                   |
-- | Parameters  : p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
   PROCEDURE log_exception (
      p_record_control_id      IN   NUMBER,
      p_source_system_code     IN   VARCHAR2,
      p_source_system_ref      IN   VARCHAR2,
      p_procedure_name         IN   VARCHAR2,
      p_staging_table_name     IN   VARCHAR2,
      p_staging_column_name    IN   VARCHAR2,
      p_staging_column_value   IN   VARCHAR2,
      p_batch_id               IN   NUMBER,
      p_exception_log          IN   VARCHAR2,
      p_oracle_error_code      IN   VARCHAR2,
      p_oracle_error_msg       IN   VARCHAR2
   )
   AS
      lc_package_name    VARCHAR2 (32) := 'XX_CDH_DATA_CORRECTION_PKG';
      ln_conversion_id   NUMBER        := 00243.99;
   BEGIN
      xx_com_conv_elements_pkg.log_exceptions_proc
                           (p_conversion_id             => ln_conversion_id,
                            p_record_control_id         => p_record_control_id,
                            p_source_system_code        => p_source_system_code,
                            p_package_name              => lc_package_name,
                            p_procedure_name            => p_procedure_name,
                            p_staging_table_name        => p_staging_table_name,
                            p_staging_column_name       => p_staging_column_name,
                            p_staging_column_value      => p_staging_column_value,
                            p_source_system_ref         => p_source_system_ref,
                            p_batch_id                  => p_batch_id,
                            p_exception_log             => p_exception_log,
                            p_oracle_error_code         => p_oracle_error_code,
                            p_oracle_error_msg          => p_oracle_error_msg
                           );
   EXCEPTION
      WHEN OTHERS
      THEN
         log_debug_msg (   'LOG_EXCEPTION: Error in logging exception :'
                        || SQLERRM
                       );
   END log_exception;

   PROCEDURE inactivate_acct_sites_main (
      x_errbuf        OUT      VARCHAR2,
      x_retcode       OUT      VARCHAR2,
      p_account_osr   IN       VARCHAR2
   )
   AS
      p_acct_osr       VARCHAR2 (2000);
      p_acct_osr_rem   VARCHAR2 (2000);
      ln_count         NUMBER;
   BEGIN
      IF num_chars (p_account_osr, ',') = 0
      THEN
         fnd_file.put_line (fnd_file.LOG, '--------------------------------');
         fnd_file.put_line (fnd_file.LOG, 'Account OSR : ' || p_account_osr);
         fnd_file.put_line (fnd_file.LOG, '--------------------------------');
         inactivate_acct_sites (x_errbuf           => x_errbuf,
                                x_retcode          => x_retcode,
                                p_account_osr      => p_account_osr
                               );
      ELSE
         p_acct_osr_rem := ',' || p_account_osr;
         ln_count := num_chars (p_acct_osr_rem, ',');

         FOR i IN 1 .. ln_count
         LOOP
            IF i < ln_count
            THEN
               p_acct_osr :=
                  REGEXP_REPLACE (REGEXP_SUBSTR (p_acct_osr_rem, ',[^,]*,'),
                                  ',',
                                  ''
                                 );
               p_acct_osr_rem :=
                        REGEXP_REPLACE (p_acct_osr_rem, ',' || p_acct_osr, '');
            ELSE
               p_acct_osr := REGEXP_REPLACE (p_acct_osr_rem, ',', '');
            END IF;

            p_acct_osr := TRIM (p_acct_osr);

            IF p_acct_osr IS NOT NULL
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  '--------------------------------'
                                 );
               fnd_file.put_line (fnd_file.LOG,
                                  'Account OSR : ' || p_acct_osr);
               fnd_file.put_line (fnd_file.LOG,
                                  '--------------------------------'
                                 );
               inactivate_acct_sites (x_errbuf           => x_errbuf,
                                      x_retcode          => x_retcode,
                                      p_account_osr      => p_acct_osr
                                     );
            END IF;
         END LOOP;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 1;
         x_errbuf :=
            'Unexpected Error in procedure acct_ou_correction_main'
            || SQLERRM;
   END inactivate_acct_sites_main;

   -- +===================================================================+
-- | Name        : inactivate_acct_sites                               |
-- |                                                                   |
-- | Description : This procedure will inactivate all sites for a      |
-- |               given account OSR.                                  |
-- |                                                                   |
-- | Parameters  : p_account_osr                                       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE inactivate_acct_sites (
      x_errbuf        OUT      VARCHAR2,
      x_retcode       OUT      VARCHAR2,
      p_account_osr   IN       VARCHAR2
   )
   AS
      CURSOR lc_fetch_cust_acct_sites_cur (p_in_acct_osr IN VARCHAR2)
      IS
         SELECT hcas.cust_acct_site_id, hcas.cust_account_id,
                hcas.party_site_id, hcas.object_version_number,
                hcas.orig_system_reference, site_orig.orig_system_ref_id,
                site_orig.object_version_number site_ovn
           FROM hz_orig_sys_references hosr,
                hz_cust_acct_sites_all hcas,
                (SELECT hosr1.orig_system_ref_id, hosr1.orig_system_reference,
                        hosr1.object_version_number
                   FROM hz_orig_sys_references hosr1
                  WHERE hosr1.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
                    AND hosr1.status = 'A'
                    AND hosr1.orig_system = 'A0') site_orig
          WHERE hosr.orig_system_reference = p_in_acct_osr
            AND hosr.orig_system = 'A0'
            AND hosr.status = 'A'
            AND hcas.status = 'A'
            AND hosr.owner_table_name = 'HZ_CUST_ACCOUNTS'
            AND hosr.owner_table_id = hcas.cust_account_id
            AND hcas.orig_system_reference = site_orig.orig_system_reference;

      lr_cust_acct_site_rec           hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      lr_def_cust_acct_site_rec       hz_cust_account_site_v2pub.cust_acct_site_rec_type;
      lv_return_status                VARCHAR2 (10);
      ln_msg_count                    NUMBER;
      lv_msg_data                     VARCHAR2 (2000);
      lr_orig_sys_reference_rec       hz_orig_system_ref_pub.orig_sys_reference_rec_type;
      lr_def_orig_sys_reference_rec   hz_orig_system_ref_pub.orig_sys_reference_rec_type;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                            'Start of proc inactivate_acct_sites...'
                         || TO_CHAR (SYSDATE, 'HH24:MI:SS')
                        );

      FOR lc_fetch_cust_acct_sites_rec IN
         lc_fetch_cust_acct_sites_cur (p_account_osr)
      LOOP
         fnd_file.put_line
            (fnd_file.LOG,
             '-------------------------------------------------------------------'
            );
---------------------------------------
-- API Call to inactivate account site
---------------------------------------
         lr_cust_acct_site_rec := lr_def_cust_acct_site_rec;
         lr_cust_acct_site_rec.cust_acct_site_id :=
                                lc_fetch_cust_acct_sites_rec.cust_acct_site_id;
         lr_cust_acct_site_rec.cust_account_id :=
                                  lc_fetch_cust_acct_sites_rec.cust_account_id;
         lr_cust_acct_site_rec.party_site_id :=
                                    lc_fetch_cust_acct_sites_rec.party_site_id;
         lr_cust_acct_site_rec.status := 'I';
         fnd_file.put_line (fnd_file.LOG,
                               'Account Site :'
                            || lc_fetch_cust_acct_sites_rec.orig_system_reference
                           );
         hz_cust_account_site_v2pub.update_cust_acct_site
            (p_init_msg_list              => fnd_api.g_true,
             p_cust_acct_site_rec         => lr_cust_acct_site_rec,
             p_object_version_number      => lc_fetch_cust_acct_sites_rec.object_version_number,
             x_return_status              => lv_return_status,
             x_msg_count                  => ln_msg_count,
             x_msg_data                   => lv_msg_data
            );

         IF lv_return_status = fnd_api.g_ret_sts_success
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Account Site successfully inactivated...'
                              );
            fnd_file.put_line (fnd_file.LOG, ' ');
------------------------------------------------------------
-- API Call to inactivate record in hz_orig_sys_references
------------------------------------------------------------
            fnd_file.put_line (fnd_file.LOG,
                                  'orig_system_ref_id- '
                               || lc_fetch_cust_acct_sites_rec.orig_system_ref_id
                              );
            lr_orig_sys_reference_rec := lr_def_orig_sys_reference_rec;
            lr_orig_sys_reference_rec.orig_system_ref_id :=
                               lc_fetch_cust_acct_sites_rec.orig_system_ref_id;
            lr_orig_sys_reference_rec.orig_system := 'A0';
            lr_orig_sys_reference_rec.orig_system_reference :=
                            lc_fetch_cust_acct_sites_rec.orig_system_reference;
            lr_orig_sys_reference_rec.owner_table_name :=
                                                      'HZ_CUST_ACCT_SITES_ALL';
            lr_orig_sys_reference_rec.owner_table_id :=
                                lc_fetch_cust_acct_sites_rec.cust_acct_site_id;
            lr_orig_sys_reference_rec.status := 'I';
            lr_orig_sys_reference_rec.end_date_active := TRUNC (SYSDATE);
            hz_orig_system_ref_pub.update_orig_system_reference
               (p_init_msg_list               => fnd_api.g_true,
                p_orig_sys_reference_rec      => lr_orig_sys_reference_rec,
                p_object_version_number       => lc_fetch_cust_acct_sites_rec.site_ovn,
                x_return_status               => lv_return_status,
                x_msg_count                   => ln_msg_count,
                x_msg_data                    => lv_msg_data
               );

            IF lv_return_status = fnd_api.g_ret_sts_success
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'Record in hz_orig_sys_references successfully inactivated...'
                  );
               COMMIT;
            ELSE
               IF ln_msg_count > 0
               THEN
                  fnd_file.put_line
                     (fnd_file.LOG,
                      'API HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference returned Error while inactivating account site... '
                     );

                  FOR counter IN 1 .. ln_msg_count
                  LOOP
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error - '
                                        || fnd_msg_pub.get (counter,
                                                            fnd_api.g_false
                                                           )
                                       );
                  END LOOP;

                  fnd_msg_pub.delete_msg;
               END IF;
            END IF;
         ELSE
            IF ln_msg_count > 0
            THEN
               fnd_file.put_line
                  (fnd_file.LOG,
                   'API HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_acct_site returned Error while inactivating account site... '
                  );

               FOR counter IN 1 .. ln_msg_count
               LOOP
                  fnd_file.put_line (fnd_file.LOG,
                                        'Error - '
                                     || fnd_msg_pub.get (counter,
                                                         fnd_api.g_false
                                                        )
                                    );
               END LOOP;

               fnd_msg_pub.delete_msg;
            END IF;
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 1;
         x_errbuf :=
             'Unexpected Error in procedure inactivate_acct_sites' || SQLERRM;
   END inactivate_acct_sites;

   PROCEDURE fix_ca_osr (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR osr_cur
      IS
         SELECT /*+ parallel (a,8)*/
                orig_system_reference, owner_table_id
           FROM hz_orig_sys_references a
          WHERE orig_system_reference LIKE '%00001-A0CA%'
            AND orig_system = 'A0'
            AND owner_table_name = 'HZ_CUST_SITE_USES_ALL';

      l_osr_val            VARCHAR2 (30);
      l_osr_records_upd    NUMBER        := 0;
      l_site_records_upd   NUMBER        := 0;
      l_owner_table_id     NUMBER;
   BEGIN
      OPEN osr_cur;

      LOOP
         FETCH osr_cur
          INTO l_osr_val, l_owner_table_id;

         EXIT WHEN osr_cur%NOTFOUND;

         UPDATE hz_orig_sys_references
            SET orig_system_reference =
                                     REPLACE (orig_system_reference, 'CA', '')
          WHERE orig_system_reference = l_osr_val
            AND orig_system = 'A0'
            AND owner_table_name = 'HZ_CUST_SITE_USES_ALL';

         l_osr_records_upd := l_osr_records_upd + SQL%ROWCOUNT;

         UPDATE hz_cust_site_uses_all
            SET orig_system_reference =
                                     REPLACE (orig_system_reference, 'CA', '')
          WHERE site_use_id = l_owner_table_id;

         l_site_records_upd := l_site_records_upd + SQL%ROWCOUNT;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      END IF;

      fnd_file.put_line (fnd_file.LOG, 'OSRs Modified:' || l_osr_records_upd);
      fnd_file.put_line (fnd_file.LOG,
                         'Sie Uses Updated:' || l_site_records_upd
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
   END fix_ca_osr;

   PROCEDURE fix_attribute_prospect (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR party_cur
      IS
         SELECT /*+ parallel (a,8)*/
                hp.party_id
           FROM hz_orig_sys_references osr, hz_parties hp
          WHERE osr.orig_system = 'A0'
            AND osr.owner_table_name = 'HZ_PARTIES'
            AND osr.owner_table_id = hp.party_id
            AND osr.status = 'A'
            AND hp.status = 'A'
            AND hp.attribute13 = 'PROSPECT';

      l_party_records_upd   NUMBER := 0;
      l_party_id            NUMBER;
   BEGIN
      OPEN party_cur;

      LOOP
         FETCH party_cur
          INTO l_party_id;

         EXIT WHEN party_cur%NOTFOUND;

         UPDATE hz_parties
            SET attribute13 = 'CUSTOMER'
          WHERE party_id = l_party_id;

         l_party_records_upd := l_party_records_upd + SQL%ROWCOUNT;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Party  Modified:' || l_party_records_upd
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
   END fix_attribute_prospect;

   PROCEDURE fix_duplicate_grandparents (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      l_parent_id             NUMBER;
      l_child_id              NUMBER;
      l_row_id                VARCHAR2 (200);
      l_tot                   NUMBER;
      l_grand_parent_id       NUMBER;
      l_tot_records_updated   NUMBER         := 0;

/*CURSOR hier_cur IS
SELECT PARENT_ID,CHILD_ID,TOT FROM (
select PARENT_ID,CHILD_ID,COUNT(*) TOT from hz_hierarchy_nodes
where level_number=2 and hierarchy_type='OD_CUST_HIER'
AND PARENT_TABLE_NAME='HZ_PARTIES' AND CHILD_TABLE_NAME='HZ_PARTIES'
AND TRUNC(EFFECTIVE_END_DATE) >= TRUNC(SYSDATE)
GROUP BY PARENT_ID,CHILD_ID) A
WHERE A.TOT >1;*/
      CURSOR hier_cur2
      IS
         SELECT DISTINCT child_id
                    FROM hz_hierarchy_nodes z
                   WHERE level_number = 2
                     AND hierarchy_type = 'OD_CUST_HIER'
                     AND parent_object_type = 'ORGANIZATION'
                     AND child_object_type = 'ORGANIZATION'
                     AND parent_table_name = 'HZ_PARTIES'
                     AND child_table_name = 'HZ_PARTIES'
                     AND SYSDATE BETWEEN NVL (effective_start_date,
                                              SYSDATE - 1
                                             )
                                     AND NVL (effective_end_date, SYSDATE + 1)
                     AND NVL (status, 'A') = 'A'
                GROUP BY child_id
                  HAVING COUNT (1) > 1;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         ' Start Of Procedure Fix Duplicate GrandParents'
                        );

/*OPEN hier_cur;

LOOP

FETCH hier_cur INTO l_parent_id,l_child_id,l_tot;
EXIT WHEN hier_cur%NOTFOUND;


UPDATE HZ_HIERARCHY_NODES SET EFFECTIVE_END_DATE = TRUNC(SYSDATE)
WHERE parent_id=l_parent_id and child_id=l_child_id
and level_number=2 and hierarchy_type='OD_CUST_HIER'
AND PARENT_TABLE_NAME='HZ_PARTIES' AND CHILD_TABLE_NAME='HZ_PARTIES'
AND TRUNC(EFFECTIVE_END_DATE) >= TRUNC(SYSDATE)
AND ROWNUM < l_tot;

l_tot_records_updated := l_tot_records_updated + SQL%ROWCOUNT;

end loop;

CLOSE hier_cur;*/
      OPEN hier_cur2;

      LOOP
         l_child_id := NULL;
         l_parent_id := NULL;
         l_grand_parent_id := NULL;

         FETCH hier_cur2
          INTO l_child_id;

         EXIT WHEN hier_cur2%NOTFOUND;

         BEGIN
            SELECT parent_id
              INTO l_parent_id
              FROM hz_hierarchy_nodes
             WHERE child_id = l_child_id
               AND level_number = 1
               AND TRUNC (effective_end_date) <= TRUNC (SYSDATE);

            SELECT parent_id
              INTO l_grand_parent_id
              FROM hz_hierarchy_nodes
             WHERE child_id = l_parent_id
               AND level_number = 1
               AND TRUNC (effective_end_date) >= TRUNC (SYSDATE);
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line
                          (fnd_file.LOG,
                              'Error: Parent or GrandParent Not Found For - '
                           || l_child_id
                          );
         END;

         IF l_grand_parent_id IS NOT NULL AND l_child_id IS NOT NULL
         THEN
            UPDATE hz_hierarchy_nodes
               SET effective_end_date = TRUNC (SYSDATE)
             WHERE parent_id = l_grand_parent_id
               AND child_id = l_child_id
               AND level_number = 2
               AND hierarchy_type = 'OD_CUST_HIER'
               AND parent_table_name = 'HZ_PARTIES'
               AND child_table_name = 'HZ_PARTIES'
               AND TRUNC (effective_end_date) >= TRUNC (SYSDATE);

            l_tot_records_updated := l_tot_records_updated + SQL%ROWCOUNT;
         ELSE
            fnd_file.put_line
                   (fnd_file.LOG,
                       'Parent or GrandParent ID Could Not Be Derived For - '
                    || l_child_id
                   );
         END IF;
      END LOOP;

      CLOSE hier_cur2;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Records Updated: ' || l_tot_records_updated
                        );
      fnd_file.put_line (fnd_file.LOG,
                         ' End Of Procedure Fix Duplicate GrandParents'
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         fnd_file.put_line
            (fnd_file.LOG,
                'Unexpected Error In Procedure Fix Duplicate GrandParents - '
             || SQLERRM
            );
   END fix_duplicate_grandparents;

   PROCEDURE fix_ou_change (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR osr_corr
      IS
         SELECT /*+parallel (osr,8)*/
                orig_system_ref_id, owner_table_id
           FROM hz_orig_sys_references osr
          WHERE osr.orig_system_reference LIKE '%CA'
            AND osr.orig_system = 'A0'
            AND osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL';

      l_commit_interval   NUMBER := 0;
   BEGIN
      fnd_file.put_line (fnd_file.LOG, 'Inside OU Change');

      FOR l_osr_corr IN osr_corr
      LOOP
         l_commit_interval := l_commit_interval + 1;

         UPDATE hz_orig_sys_references
            SET orig_system_reference =
                      RTRIM (orig_system_reference, '-' || 'BILL_TO' || 'CA')
                   || 'CA-'
                   || 'BILL_TO'
          WHERE orig_system_ref_id = l_osr_corr.orig_system_ref_id;

         UPDATE hz_cust_site_uses_all
            SET orig_system_reference =
                      RTRIM (orig_system_reference, '-' || 'BILL_TO' || 'CA')
                   || 'CA-'
                   || 'BILL_TO'
          WHERE site_use_code = l_osr_corr.owner_table_id;

         l_commit_interval := l_commit_interval + 1;

         IF l_commit_interval = 200
         THEN
            COMMIT;
            l_commit_interval := 0;
         END IF;
      END LOOP;
   END fix_ou_change;

   PROCEDURE fix_party_inactive (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      p_org_rec           hz_party_v2pub.organization_rec_type;
      l_profile_id        NUMBER;
      l_return_status     VARCHAR2 (50);
      l_msg_count         NUMBER;
      l_msg_data          VARCHAR2 (2000);
      l_success           NUMBER                               := 0;
      l_error             NUMBER                               := 0;
      l_ovn               NUMBER;
      l_commit_interval   NUMBER                               := 0;
      l_msg_text          VARCHAR2 (4200);

      CURSOR inactive_parties
      IS
         SELECT /*+parallel(A,8)*/
                party_id, object_version_number
           FROM hz_parties a
          WHERE party_type = 'ORGANIZATION' AND status = 'I';
   BEGIN
      FOR l_parties IN inactive_parties
      LOOP
         l_return_status := NULL;
         l_msg_count := 0;
         l_msg_data := NULL;
         p_org_rec.party_rec.party_id := l_parties.party_id;
         p_org_rec.party_rec.status := 'A';
         l_ovn := l_parties.object_version_number;
         hz_party_v2pub.update_organization
                                     (p_init_msg_list                    => fnd_api.g_true,
                                      p_organization_rec                 => p_org_rec,
                                      p_party_object_version_number      => l_ovn,
                                      x_profile_id                       => l_profile_id,
                                      x_return_status                    => l_return_status,
                                      x_msg_count                        => l_msg_count,
                                      x_msg_data                         => l_msg_data
                                     );

         IF l_return_status = 'S'
         THEN
            l_success := l_success + 1;
         ELSE
            l_error := l_error + 1;
            fnd_file.put_line (fnd_file.LOG,
                                  ' ******** Error Party Id: '
                               || l_parties.party_id
                              );

            IF l_msg_count >= 1
            THEN
               FOR i IN 1 .. l_msg_count
               LOOP
                  l_msg_text :=
                     l_msg_text || ' '
                     || fnd_msg_pub.get (i, fnd_api.g_false);
                  fnd_file.put_line (fnd_file.LOG,
                                        'Error - '
                                     || fnd_msg_pub.get (i, fnd_api.g_false)
                                    );
               END LOOP;
            END IF;
         END IF;

         l_commit_interval := l_commit_interval + 1;

         IF l_commit_interval = 5000 AND p_commit = 'Y'
         THEN
            l_commit_interval := 0;
            COMMIT;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.output, 'Records Successful: ' || l_success);
      fnd_file.put_line (fnd_file.output, 'Records Error: ' || l_error);
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected Error: ' || SQLERRM);
   END fix_party_inactive;

-- +===================================================================+
-- | Name        : fix_multiple_sites_uses                             |
-- |                                                                   |
-- | Description : Inactivate duplicate sites and uses in 404 Op Unit. |
-- |                                                                   |
-- | Parameters  :  p_commit                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_multiple_sites_uses (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      ln_count              NUMBER      := 0;
      l_cust_acct_site_id   NUMBER (15);

      CURSOR lc_mul_site_cur
      IS
         SELECT   /*+ parallel(a,8) */
                  party_site_id
             FROM hz_cust_acct_sites_all a
            WHERE status = 'A'
         GROUP BY party_site_id
           HAVING COUNT (*) > 1;
   BEGIN
      FOR lc_mul_site_rec IN lc_mul_site_cur
      LOOP
         BEGIN
            -- Get cust_acct_site_id to update in 404 Op Unit
            SELECT cas.cust_acct_site_id
              INTO l_cust_acct_site_id
              FROM hz_cust_acct_sites_all cas
             WHERE cas.party_site_id = lc_mul_site_rec.party_site_id
               AND cas.org_id = 404;

            ln_count := ln_count + 1;

            -- Update acct_sites_all
            UPDATE hz_cust_acct_sites_all cas
               SET status = 'I'
             WHERE cust_acct_site_id = l_cust_acct_site_id;

            fnd_file.put_line (fnd_file.LOG,
                                  l_cust_acct_site_id
                               || ' No of Acct Sites updated - '
                               || SQL%ROWCOUNT
                              );

            -- Update site_uses_all
            UPDATE hz_cust_site_uses_all csu
               SET status = 'I'
             WHERE cust_acct_site_id = l_cust_acct_site_id;

            fnd_file.put_line (fnd_file.LOG,
                                  l_cust_acct_site_id
                               || ' No of Site Uses updated - '
                               || SQL%ROWCOUNT
                              );
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'No Records Exist for '
                                  || l_cust_acct_site_id
                                 );
         END;
      END LOOP;

      -- commit the changes
      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
         fnd_file.put_line (fnd_file.LOG, 'Committed changes.. ');
      ELSE
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                            'Total Account Sites selected for update -'
                         || ln_count
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected Error - ' || SQLERRM);
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
   END fix_multiple_sites_uses;

-- +===================================================================+
-- | Name        : fix_bill_to_data                                    |
-- |                                                                   |
-- | Description : Set bill_to_site_use_id to null when BILL_TO usage  |
-- |               is 'I'.                                             |
-- |                                                                   |
-- | Parameters  :  p_commit                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE fix_bill_to_data (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
-- Not including site_use_code in the cursor query because of performance issues.
      CURSOR site_uses_cur
      IS
         SELECT cust_acct_site_id, site_use_id, site_use_code
           FROM hz_cust_site_uses_all
          WHERE status = 'I';

      TYPE site_uses_cur_tbl_type IS TABLE OF site_uses_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;

      site_uses_cur_tbl   site_uses_cur_tbl_type;
      l_cust_account_id   NUMBER;
      l_bulk_limit        NUMBER                 := 200;
      l_records_updated   NUMBER                 := 0;
      l_commit_flag       VARCHAR2 (1);
   BEGIN
      OPEN site_uses_cur;

      LOOP
         FETCH site_uses_cur
         BULK COLLECT INTO site_uses_cur_tbl LIMIT l_bulk_limit;

         IF site_uses_cur_tbl.COUNT = 0
         THEN
            EXIT;
         END IF;

         FOR ln_counter IN site_uses_cur_tbl.FIRST .. site_uses_cur_tbl.LAST
         LOOP
            IF site_uses_cur_tbl (ln_counter).site_use_code = 'BILL_TO'
            THEN
               BEGIN
                  SELECT cust_account_id
                    INTO l_cust_account_id
                    FROM hz_cust_acct_sites_all
                   WHERE cust_acct_site_id =
                              site_uses_cur_tbl (ln_counter).cust_acct_site_id;

                  UPDATE hz_cust_site_uses_all
                     SET bill_to_site_use_id = NULL
                   WHERE bill_to_site_use_id =
                                    site_uses_cur_tbl (ln_counter).site_use_id
                     AND cust_acct_site_id IN (
                                     SELECT cust_acct_site_id
                                       FROM hz_cust_acct_sites_all
                                      WHERE cust_account_id =
                                                             l_cust_account_id);

                  l_records_updated := l_records_updated + SQL%ROWCOUNT;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     fnd_file.put_line
                             (fnd_file.LOG,
                                 'No Cust Site Record Found For Site Id:'
                              || site_uses_cur_tbl (ln_counter).cust_acct_site_id
                             );
               END;
            END IF;
         END LOOP;

         -- commit the changes
         IF (UPPER (NVL (p_commit, 'N')) = 'Y')
         THEN
            COMMIT;
            fnd_file.put_line (fnd_file.LOG, 'Committed changes.. ');
         ELSE
            ROLLBACK;
            fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Records Updated:' || l_records_updated
                        );
      fnd_file.put_line (fnd_file.LOG,
                         'Commit Executed?:' || NVL (l_commit_flag, 'N')
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Unexpected Error - ' || SQLERRM);
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Rollback changes.. ');
   END fix_bill_to_data;

   PROCEDURE convert_indirect_to_direct (
      x_errbuf      OUT      VARCHAR2,
      x_retcode     OUT      VARCHAR2,
      p_aops_acct   IN       VARCHAR2,
      p_commit      IN       VARCHAR2
   )
   AS
      CURSOR bill_to_site_id_cur
      IS
         SELECT asu.site_use_id, asu.object_version_number, asu.org_id,
                asu.orig_system_reference, asi.cust_acct_site_id
           FROM hz_cust_acct_sites_all asi,
                hz_cust_accounts acc,
                hz_cust_site_uses_all asu
          WHERE asi.cust_account_id = acc.cust_account_id
            AND asu.cust_acct_site_id = asi.cust_acct_site_id
            AND asu.bill_to_site_use_id IS NOT NULL
            AND acc.orig_system_reference =
                                           TO_CHAR (p_aops_acct)
                                           || '-00001-A0';

      CURSOR bill_to_site_use_cur
      IS
         SELECT asu.site_use_id, asu.object_version_number, asu.org_id,
                asu.orig_system_reference, asi.cust_acct_site_id
           FROM hz_cust_acct_sites_all asi,
                hz_cust_accounts acc,
                hz_cust_site_uses_all asu
          WHERE asi.cust_account_id = acc.cust_account_id
            AND asu.cust_acct_site_id = asi.cust_acct_site_id
            AND asu.site_use_code = 'BILL_TO'
            AND asi.orig_system_reference NOT LIKE '%-00001-A0%'
            AND asu.status = 'A'
            AND acc.orig_system_reference =
                                           TO_CHAR (p_aops_acct)
                                           || '-00001-A0';

      l_site_use_id      NUMBER;
      l_ovn              NUMBER;
      lc_return_status   VARCHAR (1);
      ln_msg_count       NUMBER;
      lc_msg_data        VARCHAR2 (4000);
      l_msg_text         VARCHAR2 (4200);
      l_site_use_rec     hz_cust_account_site_v2pub.cust_site_use_rec_type;
      l_org_id           NUMBER;
      l_succ             NUMBER                                           := 0;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         '--------- Removing BILL_TO_SITE_USE_IDs ----------'
                        );

      FOR l_bill_to_site_id_cur IN bill_to_site_id_cur
      LOOP
         l_site_use_rec := NULL;
----- Added cust_acct_site_id as a part of retrofit for R12
         l_site_use_rec.cust_acct_site_id :=
                                      l_bill_to_site_id_cur.cust_acct_site_id;
         l_site_use_rec.site_use_id := l_bill_to_site_id_cur.site_use_id;
         l_site_use_rec.bill_to_site_use_id := fnd_api.g_null_num;
         fnd_client_info.set_org_context (l_bill_to_site_id_cur.org_id);
         hz_cust_account_site_v2pub.update_cust_site_use
            (p_init_msg_list              => fnd_api.g_true,
             p_cust_site_use_rec          => l_site_use_rec,
             p_object_version_number      => l_bill_to_site_id_cur.object_version_number,
             x_return_status              => lc_return_status,
             x_msg_count                  => ln_msg_count,
             x_msg_data                   => lc_msg_data
            );

         IF ln_msg_count >= 1
         THEN
            x_retcode := 2;

            FOR i IN 1 .. ln_msg_count
            LOOP
               l_msg_text :=
                    l_msg_text || ' ' || fnd_msg_pub.get (i, fnd_api.g_false);
               fnd_file.put_line (fnd_file.LOG,
                                     'Error - '
                                  || fnd_msg_pub.get (i, fnd_api.g_false)
                                 );
            END LOOP;

            fnd_file.put_line
               (fnd_file.LOG,
                   '------------------------------------------------------------'
                || CHR (10)
               );
         ELSE
            l_succ := l_succ + 1;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Successfully Removed Bill_To_Site_Use_ID For SiteUseID/OSR:'
                || l_site_use_rec.site_use_id
                || '/'
                || l_bill_to_site_id_cur.orig_system_reference
               );
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                            'Total BILL_TO_SITE_USE_ID Values Removed : '
                         || l_succ
                        );
      fnd_file.put_line
         (fnd_file.LOG,
          '--------- Inactivating BILL_TO Site Uses (Other Than Sequence -00001-) ----------'
         );
      l_succ := 0;

      FOR l_bill_to_site_use_cur IN bill_to_site_use_cur
      LOOP
         l_site_use_rec := NULL;
----- Added cust_acct_site_id as a part of retrofit for R12
         l_site_use_rec.cust_acct_site_id :=
                                     l_bill_to_site_use_cur.cust_acct_site_id;
         l_site_use_rec.site_use_id := l_bill_to_site_use_cur.site_use_id;
         l_site_use_rec.status := 'I';
         fnd_client_info.set_org_context (l_bill_to_site_use_cur.org_id);
         hz_cust_account_site_v2pub.update_cust_site_use
            (p_init_msg_list              => fnd_api.g_true,
             p_cust_site_use_rec          => l_site_use_rec,
             p_object_version_number      => l_bill_to_site_use_cur.object_version_number,
             x_return_status              => lc_return_status,
             x_msg_count                  => ln_msg_count,
             x_msg_data                   => lc_msg_data
            );

         IF ln_msg_count >= 1
         THEN
            x_retcode := 2;

            FOR i IN 1 .. ln_msg_count
            LOOP
               l_msg_text :=
                    l_msg_text || ' ' || fnd_msg_pub.get (i, fnd_api.g_false);
               fnd_file.put_line (fnd_file.LOG,
                                     'Error - '
                                  || fnd_msg_pub.get (i, fnd_api.g_false)
                                 );
            END LOOP;

            fnd_file.put_line
               (fnd_file.LOG,
                   '------------------------------------------------------------'
                || CHR (10)
               );
         ELSE
            l_succ := l_succ + 1;
            fnd_file.put_line
               (fnd_file.LOG,
                   'Successfully Inactivated BILL_TO Site Use For SiteUseID/OSR:'
                || l_site_use_rec.site_use_id
                || '/'
                || l_bill_to_site_use_cur.orig_system_reference
               );
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'Total BILL_TO Site Uses Inactivated: ' || l_succ
                        );

      IF p_commit = 'Y' AND NVL (x_retcode, 0) <> 2
      THEN
         COMMIT;
         fnd_file.put_line (fnd_file.LOG, 'All Changes Have Been Committed');
      ELSE
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'All Changes have been Rolled Back');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
                'Unexpected Error in proecedure convert_indirect_to_direct - Error - '
             || SQLERRM
            );
         x_errbuf :=
               'Unexpected Error in proecedure convert_indirect_to_direct - Error - '
            || SQLERRM;
         x_retcode := 2;
         ROLLBACK;
   END convert_indirect_to_direct;

   PROCEDURE fix_dup_primary_site (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR dup_prim_site
      IS
         SELECT   /*+PARALLEL(s,8)*/
                  party_id, MIN (party_site_id) party_site_id
             FROM hz_party_sites s
            WHERE identifying_address_flag = 'Y'
         GROUP BY party_id
           HAVING COUNT (1) > 1;

      l_succ      NUMBER := 0;
      l_tot_rec   NUMBER := 0;
   BEGIN
      FOR l_prim_site_cur IN dup_prim_site
      LOOP
         l_tot_rec := l_tot_rec + 1;

         UPDATE hz_party_sites
            SET identifying_address_flag = 'N',
                last_update_date = SYSDATE
          WHERE party_site_id = l_prim_site_cur.party_site_id;

         IF SQL%ROWCOUNT = 1
         THEN
            l_succ := l_succ + 1;
         ELSE
            fnd_file.put_line
                           (fnd_file.LOG,
                               'Party Site Cannot Be Updated, PartySiteID : '
                            || l_prim_site_cur.party_site_id
                           );
         END IF;

         IF MOD (l_succ, 200) = 0 AND p_commit = 'Y'
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
         fnd_file.put_line (fnd_file.output, 'All Changes Committed');
      ELSE
         ROLLBACK;
         fnd_file.put_line (fnd_file.output, 'All Changes Rolled Back');
      END IF;

      fnd_file.put_line (fnd_file.output,
                         'Total Records Processed: ' || l_tot_rec
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Records Successful: ' || l_succ
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
                (fnd_file.LOG,
                    'Unexpected Error in proecedure dup_prim_site - Error - '
                 || SQLERRM
                );
         x_errbuf :=
               'Unexpected Error in proecedure dup_prim_site - Error - '
            || SQLERRM;
         x_retcode := 2;
   END fix_dup_primary_site;

   PROCEDURE fix_ca_shipto_site_use_osr (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR ca_shipto_cur
      IS
         SELECT /*+parallel(a,8)*/
                site_use_id
           FROM hz_cust_site_uses_all a
          WHERE org_id = 403
            AND site_use_code = 'SHIP_TO'
            AND orig_system_reference LIKE '%-00001-A0CA-SHIP_TO';

      l_site_use_count   NUMBER := 0;
      l_osr_count        NUMBER := 0;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Inside Procedure - fix_ca_shipto_site_use_osr'
                        );

      FOR l_ca_shipto IN ca_shipto_cur
      LOOP
         UPDATE hz_cust_site_uses_all
            SET orig_system_reference =
                      SUBSTR (orig_system_reference, 0, 17)
                   || SUBSTR (orig_system_reference, 20)
          WHERE site_use_id = l_ca_shipto.site_use_id;

         l_site_use_count := l_site_use_count + SQL%ROWCOUNT;

         UPDATE hz_orig_sys_references
            SET orig_system_reference =
                      SUBSTR (orig_system_reference, 0, 17)
                   || SUBSTR (orig_system_reference, 20)
          WHERE owner_table_name = 'HZ_CUST_SITE_USES_ALL'
            AND owner_table_id = l_ca_shipto.site_use_id
            AND orig_system_reference LIKE '%-00001-A0CA-SHIP_TO';

         l_osr_count := l_osr_count + SQL%ROWCOUNT;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                            'Total Site Use Records Updated : '
                         || l_site_use_count
                        );
      fnd_file.put_line (fnd_file.LOG,
                         'Total OSR Records Updated : ' || l_osr_count
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
         fnd_file.put_line (fnd_file.LOG, 'Changes Committed');
      ELSE
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG, 'Changes RolledBack');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG,
                'Unexpected Error in proecedure fix_ca_shipto_site_use_osr - Error - '
             || SQLERRM
            );
         x_errbuf :=
               'Unexpected Error in proecedure fix_ca_shipto_site_use_osr - Error - '
            || SQLERRM;
         x_retcode := 2;
         ROLLBACK;
   END fix_ca_shipto_site_use_osr;

   PROCEDURE do_update_party_site (p_party_site_id IN NUMBER)
   IS
      x_return_status           VARCHAR2 (10);
      x_msg_count               NUMBER;
      x_msg_data                VARCHAR (2000);
      x_err_message             VARCHAR (2000);
      x_object_version_number   NUMBER;
      p_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
   BEGIN
      SELECT object_version_number
        INTO x_object_version_number
        FROM hz_party_sites
       WHERE party_site_id = p_party_site_id;

      p_party_site_rec.party_site_id := p_party_site_id;
      p_party_site_rec.status := 'I';
      hz_party_site_v2pub.update_party_site
                          (p_init_msg_list              => 'T',
                           p_party_site_rec             => p_party_site_rec,
                           p_object_version_number      => x_object_version_number,
                           x_return_status              => x_return_status,
                           x_msg_count                  => x_msg_count,
                           x_msg_data                   => x_msg_data
                          );
      COMMIT;

      IF (x_return_status = 'S')
      THEN
         log_debug_msg (   'Party_site_id '
                        || p_party_site_id
                        || ' in-activated successfully.'
                       );
      END IF;

      IF x_msg_count > 0
      THEN
         x_err_message :=
              SUBSTR (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 250);
         log_debug_msg (   'Party_site_id: '
                        || p_party_site_id
                        || ', '
                        || x_err_message
                       );
      END IF;

      log_debug_msg ('x_return_status: ' || x_return_status);
      log_debug_msg ('End do_update_party_site');
   EXCEPTION
      WHEN OTHERS
      THEN
         x_err_message := SUBSTR (SQLERRM, 1, 100);
         log_debug_msg ('Exception in do_update_party_site: ' || x_err_message
                       );
   END do_update_party_site;

   PROCEDURE fix_dup_party_sites (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      l_party_site_id   hz_party_sites.party_site_id%TYPE;
      x_return_status   VARCHAR2 (10);
      x_msg_count       NUMBER;
      x_msg_data        VARCHAR (2000);
      x_err_message     VARCHAR (2000);

      CURSOR c1
      IS
         SELECT   orig_system_reference, COUNT (1)
             FROM hz_party_sites
            WHERE status = 'A'
         GROUP BY orig_system_reference
           HAVING COUNT (1) > 1;

      CURSOR c2 (p_orig_system_reference IN VARCHAR2)
      IS
         SELECT owner_table_id
           FROM hz_orig_sys_references
          WHERE orig_system_reference = p_orig_system_reference
            AND owner_table_name = 'HZ_PARTY_SITES'
            AND status = 'I';
   BEGIN
      log_debug_msg (   'BEGIN fix_dup_party_sites--'
                     || TO_CHAR (SYSDATE, 'DD-MON HH24:MI:SS')
                    );
      log_debug_msg ('Commit is: ' || p_commit);

      FOR i IN c1
      LOOP
         l_party_site_id := 0;

         OPEN c2 (i.orig_system_reference);

         FETCH c2
          INTO l_party_site_id;

         IF c2%NOTFOUND
         THEN
            l_party_site_id := 0;
         END IF;

         log_debug_msg (   'orig_system_reference-'
                        || i.orig_system_reference
                        || ', Party_site_id-'
                        || l_party_site_id
                       );

         IF ((UPPER (NVL (p_commit, 'N')) = 'Y') AND l_party_site_id != 0)
         THEN
            do_update_party_site (l_party_site_id);
         END IF;

         CLOSE c2;
      END LOOP;

      log_debug_msg ('End of fix_dup_party_sites');
   EXCEPTION
      WHEN OTHERS
      THEN
         log_debug_msg ('Exception in fix_dup_party_sites: ' || SQLERRM);
         ROLLBACK;
   END fix_dup_party_sites;

   PROCEDURE flush_summary_batchid (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
   BEGIN
      DELETE FROM xxod_hz_summary
            WHERE batch_id = 99999999999999;

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         log_debug_msg ('Exception in flush_summary_batchid: ' || SQLERRM);
   END flush_summary_batchid;

   PROCEDURE flush_summary_summaryid (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
   BEGIN
      DELETE FROM xxod_hz_summary
            WHERE summary_id = 99999999999999;

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         log_debug_msg ('Exception in flush_summary_summaryid: ' || SQLERRM);
   END flush_summary_summaryid;

   PROCEDURE flush_custprofiles_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
   BEGIN
      DELETE FROM xxod_hz_imp_account_prof_stg
            WHERE batch_id = 99999999999999;

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         log_debug_msg ('Exception in flush_custprofiles_batch: ' || SQLERRM);
   END flush_custprofiles_batch;

   PROCEDURE flush_classifics_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
   BEGIN
      DELETE FROM hz_imp_classifics_int
            WHERE batch_id = 99999999999999;

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         log_debug_msg ('Exception in flush_classifics_batch: ' || SQLERRM);
   END flush_classifics_batch;

   PROCEDURE flush_extensibles_batch (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
   BEGIN
      DELETE FROM hz_imp_classifics_int
            WHERE batch_id = 99999999999999;

      IF (UPPER (NVL (p_commit, 'N')) = 'Y')
      THEN
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         log_debug_msg ('Exception in flush_extensibles_batch: ' || SQLERRM);
   END flush_extensibles_batch;

   PROCEDURE fix_country_ou_onetime (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
   BEGIN
      UPDATE hz_orig_sys_references
         SET status = 'A',
             end_date_active = NULL
       WHERE orig_system_ref_id IN
                (39581115,
                 147096033,
                 39588716,
                 39585528,
                 39725300,
                 39733304,
                 39496206,
                 39493070,
                 39491017,
                 39491019,
                 39430582,
                 39488938,
                 45239526,
                 45215277,
                 45208346,
                 45192065,
                 45175034,
                 45172642,
                 45172647,
                 45172650,
                 45250641,
                 45185374,
                 45212716,
                 45212718,
                 45212720,
                 47757042,
                 47757044,
                 147272721,
                 47737494,
                 47737495,
                 41387236,
                 41393989,
                 41394483,
                 41310594,
                 41315666,
                 41316386,
                 41315581,
                 41376081,
                 41390287,
                 41441665,
                 41439215,
                 41439216,
                 41360670,
                 41396063,
                 41438385,
                 41364672,
                 41256119,
                 41406853,
                 41405520,
                 41393803,
                 41376623,
                 41376631,
                 46962845,
                 121570164,
                 46977287,
                 47032226,
                 47035125,
                 47016025,
                 47010960,
                 42893302,
                 42777267,
                 42830186,
                 43017712,
                 43014394,
                 42982421,
                 42982133,
                 42951712,
                 46394227,
                 46394348,
                 46331893,
                 46346319,
                 104267385,
                 104313757,
                 45923496,
                 45960494,
                 44022111,
                 43979786,
                 43989871,
                 43989886,
                 44039715,
                 44044921,
                 47601776,
                 49419567,
                 49487861,
                 49560233,
                 52895755,
                 51088490,
                 51088962,
                 51088967,
                 51088979,
                 51088991,
                 146660275,
                 54022217,
                 56176832,
                 56255471,
                 55515254,
                 55515256,
                 55756710,
                 55387765,
                 55387798,
                 59931797,
                 68522402,
                 68415388,
                 61694227
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_orig_sys_references
         SET status = 'I',
             end_date_active = SYSDATE
       WHERE orig_system_ref_id IN
                (151558761,
                 151558558,
                 151559708,
                 151560069,
                 151559075,
                 151558330,
                 151558812,
                 151559268,
                 151558362,
                 151558364,
                 151560149,
                 151560286,
                 151558273,
                 151560091,
                 151558908,
                 151559798,
                 151558436,
                 151559302,
                 151559315,
                 151559279,
                 151559957,
                 151559495,
                 151558553,
                 151558516,
                 151558551,
                 151559716,
                 151559670,
                 151559497,
                 151559104,
                 151559138,
                 151558480,
                 151558524,
                 151558532,
                 151559058,
                 151559088,
                 151559445,
                 151559002,
                 151558964,
                 151559549,
                 151558860,
                 151559864,
                 151559919,
                 151558454,
                 151558685,
                 151558491,
                 151559051,
                 151560004,
                 151560009,
                 151560266,
                 151559628,
                 151559796,
                 151559817,
                 151558746,
                 151559374,
                 151559366,
                 151559803,
                 151559416,
                 151558777,
                 151560130,
                 151560128,
                 151559630,
                 151558862,
                 151559083,
                 151560205,
                 151558910,
                 151558704,
                 151560138,
                 151559093,
                 151558366,
                 151559260,
                 151558923,
                 151559447,
                 151559161,
                 151558387,
                 151558543,
                 151558385,
                 151560086,
                 151559974,
                 151559584,
                 151560058,
                 151558948,
                 151559753,
                 151559837,
                 151560120,
                 151559493,
                 151559839,
                 151558748,
                 151558720,
                 151558725,
                 151558714,
                 151558750,
                 151558727,
                 151559037,
                 151559154,
                 151559186,
                 151559620,
                 151559603,
                 151559056,
                 151558284,
                 151558301,
                 151560264,
                 151558623,
                 151559962,
                 151559200
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_orig_sys_references
         SET status = 'A',
             end_date_active = NULL
       WHERE orig_system_ref_id IN
                (40322603,
                 147096039,
                 40517668,
                 40503748,
                 40378189,
                 40124293,
                 40332516,
                 40240277,
                 40245211,
                 40245213,
                 40333415,
                 40249585,
                 45708137,
                 45695587,
                 45771771,
                 45775747,
                 45775961,
                 45777248,
                 45777249,
                 45777250,
                 45776131,
                 45715391,
                 45717235,
                 45717239,
                 45717242,
                 47959493,
                 47898441,
                 147272862,
                 47946191,
                 47946194,
                 42280394,
                 42236651,
                 42236658,
                 42224938,
                 42156008,
                 42151231,
                 42164469,
                 42181888,
                 42080837,
                 42157283,
                 42074233,
                 42074328,
                 41999855,
                 42274437,
                 42065272,
                 41992626,
                 41769224,
                 42112259,
                 42021806,
                 42016760,
                 41749792,
                 41749823,
                 47462380,
                 121570165,
                 47463593,
                 47273558,
                 47462014,
                 47259233,
                 47266916,
                 43899678,
                 43766063,
                 43860655,
                 43729624,
                 43722359,
                 43580949,
                 43586368,
                 43468670,
                 46762665,
                 46839735,
                 46843212,
                 46708087,
                 104845375,
                 104868829,
                 46142181,
                 46155694,
                 44623684,
                 44532965,
                 44538229,
                 44538316,
                 44644757,
                 44642181,
                 47717836,
                 50016563,
                 50008728,
                 49966759,
                 53862415,
                 51738604,
                 51738610,
                 51738612,
                 51738620,
                 51738625,
                 146660277,
                 54970302,
                 57594021,
                 57606853,
                 57721740,
                 57721743,
                 57981046,
                 56269988,
                 56270014,
                 60718479,
                 69123917,
                 69060174,
                 62339233
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_orig_sys_references
         SET status = 'I',
             end_date_active = SYSDATE
       WHERE orig_system_ref_id IN
                (151558762,
                 151558559,
                 151559709,
                 151560070,
                 151559076,
                 151558331,
                 151558813,
                 151559269,
                 151558363,
                 151558365,
                 151560150,
                 151560287,
                 151558274,
                 151560092,
                 151558909,
                 151559799,
                 151558437,
                 151559303,
                 151559316,
                 151559280,
                 151559958,
                 151559496,
                 151558554,
                 151558517,
                 151558552,
                 151559717,
                 151559671,
                 151559498,
                 151559105,
                 151559139,
                 151558481,
                 151558525,
                 151558533,
                 151559059,
                 151559089,
                 151559446,
                 151559003,
                 151558965,
                 151559550,
                 151558861,
                 151559865,
                 151559920,
                 151558455,
                 151558686,
                 151558492,
                 151559052,
                 151560005,
                 151560010,
                 151560267,
                 151559629,
                 151559797,
                 151559818,
                 151558747,
                 151559375,
                 151559367,
                 151559804,
                 151559417,
                 151558778,
                 151560131,
                 151560129,
                 151559631,
                 151558863,
                 151559084,
                 151560206,
                 151558911,
                 151558705,
                 151560139,
                 151559094,
                 151558367,
                 151559261,
                 151558924,
                 151559448,
                 151559162,
                 151558388,
                 151558544,
                 151558386,
                 151560087,
                 151559975,
                 151559585,
                 151560059,
                 151558949,
                 151559754,
                 151559838,
                 151560121,
                 151559494,
                 151559840,
                 151558749,
                 151558721,
                 151558726,
                 151558715,
                 151558751,
                 151558728,
                 151559038,
                 151559155,
                 151559187,
                 151559621,
                 151559604,
                 151559057,
                 151558285,
                 151558302,
                 151560265,
                 151558624,
                 151559963,
                 151559201
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_cust_acct_sites_all
         SET status = 'A'
       WHERE cust_acct_site_id IN
                (2889618,
                 64832385,
                 2892690,
                 2891374,
                 2911917,
                 2919921,
                 2875749,
                 2874543,
                 2873475,
                 2873476,
                 2860567,
                 2872638,
                 3412716,
                 3408467,
                 3401536,
                 3382696,
                 3362684,
                 3360014,
                 3360017,
                 3360040,
                 3423831,
                 3374884,
                 3405906,
                 3405908,
                 3405910,
                 3581814,
                 3581817,
                 64848581,
                 3594718,
                 3594719,
                 3109246,
                 3122099,
                 3122973,
                 3059013,
                 3067345,
                 3068618,
                 3067204,
                 3106340,
                 3115657,
                 3137895,
                 3132565,
                 3132566,
                 3076630,
                 3126273,
                 3130795,
                 3085032,
                 3085729,
                 3128893,
                 3126040,
                 3121792,
                 3107563,
                 3107570,
                 3505969,
                 10297321,
                 3533951,
                 3553150,
                 3556049,
                 3543942,
                 3530697,
                 3203525,
                 3171463,
                 3182901,
                 3230670,
                 3229574,
                 3218167,
                 3217969,
                 3215114,
                 3476176,
                 3476317,
                 3456103,
                 3464287,
                 8983676,
                 9062514,
                 3431662,
                 3435768,
                 3297842,
                 3278348,
                 3287106,
                 3287118,
                 3314329,
                 3319535,
                 3576026,
                 3721443,
                 3758105,
                 3806411,
                 4050430,
                 3923851,
                 3923938,
                 3923939,
                 3923942,
                 3923944,
                 64791914,
                 4225694,
                 4421986,
                 4459837,
                 4313044,
                 4313045,
                 4365322,
                 4290229,
                 4290234,
                 4792892,
                 5576751,
                 5536624,
                 4939282
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_cust_site_uses_all
         SET status = 'A'
       WHERE cust_acct_site_id IN
                (2889618,
                 64832385,
                 2892690,
                 2891374,
                 2911917,
                 2919921,
                 2875749,
                 2874543,
                 2873475,
                 2873476,
                 2860567,
                 2872638,
                 3412716,
                 3408467,
                 3401536,
                 3382696,
                 3362684,
                 3360014,
                 3360017,
                 3360040,
                 3423831,
                 3374884,
                 3405906,
                 3405908,
                 3405910,
                 3581814,
                 3581817,
                 64848581,
                 3594718,
                 3594719,
                 3109246,
                 3122099,
                 3122973,
                 3059013,
                 3067345,
                 3068618,
                 3067204,
                 3106340,
                 3115657,
                 3137895,
                 3132565,
                 3132566,
                 3076630,
                 3126273,
                 3130795,
                 3085032,
                 3085729,
                 3128893,
                 3126040,
                 3121792,
                 3107563,
                 3107570,
                 3505969,
                 10297321,
                 3533951,
                 3553150,
                 3556049,
                 3543942,
                 3530697,
                 3203525,
                 3171463,
                 3182901,
                 3230670,
                 3229574,
                 3218167,
                 3217969,
                 3215114,
                 3476176,
                 3476317,
                 3456103,
                 3464287,
                 8983676,
                 9062514,
                 3431662,
                 3435768,
                 3297842,
                 3278348,
                 3287106,
                 3287118,
                 3314329,
                 3319535,
                 3576026,
                 3721443,
                 3758105,
                 3806411,
                 4050430,
                 3923851,
                 3923938,
                 3923939,
                 3923942,
                 3923944,
                 64791914,
                 4225694,
                 4421986,
                 4459837,
                 4313044,
                 4313045,
                 4365322,
                 4290229,
                 4290234,
                 4792892,
                 5576751,
                 5536624,
                 4939282
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_cust_acct_sites_all
         SET status = 'I'
       WHERE cust_acct_site_id IN
                (235004014,
                 235003940,
                 235004356,
                 235004485,
                 235004130,
                 235003857,
                 235004033,
                 235004200,
                 235003868,
                 235003869,
                 235004515,
                 235004562,
                 235003836,
                 235004494,
                 235004068,
                 235004388,
                 235003895,
                 235004212,
                 235004217,
                 235004204,
                 235004444,
                 235004281,
                 235003938,
                 235003924,
                 235003937,
                 235004359,
                 235004343,
                 235004282,
                 235004141,
                 235004153,
                 235003911,
                 235003927,
                 235003930,
                 235004124,
                 235004135,
                 235004263,
                 235004103,
                 235004089,
                 235004300,
                 235004051,
                 235004412,
                 235004431,
                 235003902,
                 235003984,
                 235003915,
                 235004121,
                 235004462,
                 235004464,
                 235004555,
                 235004328,
                 235004387,
                 235004395,
                 235004008,
                 235004238,
                 235004235,
                 235004390,
                 235004253,
                 235004020,
                 235004508,
                 235004507,
                 235004329,
                 235004052,
                 235004133,
                 235004534,
                 235004069,
                 235003991,
                 235004511,
                 235004137,
                 235003870,
                 235004197,
                 235004074,
                 235004264,
                 235004162,
                 235003878,
                 235003934,
                 235003877,
                 235004492,
                 235004451,
                 235004312,
                 235004481,
                 235004083,
                 235004372,
                 235004402,
                 235004504,
                 235004280,
                 235004403,
                 235004009,
                 235003998,
                 235004000,
                 235003995,
                 235004010,
                 235004001,
                 235004116,
                 235004159,
                 235004171,
                 235004325,
                 235004319,
                 235004123,
                 235003840,
                 235003846,
                 235004554,
                 235003963,
                 235004446,
                 235004176
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      UPDATE hz_cust_site_uses_all
         SET status = 'I'
       WHERE cust_acct_site_id IN
                (235004014,
                 235003940,
                 235004356,
                 235004485,
                 235004130,
                 235003857,
                 235004033,
                 235004200,
                 235003868,
                 235003869,
                 235004515,
                 235004562,
                 235003836,
                 235004494,
                 235004068,
                 235004388,
                 235003895,
                 235004212,
                 235004217,
                 235004204,
                 235004444,
                 235004281,
                 235003938,
                 235003924,
                 235003937,
                 235004359,
                 235004343,
                 235004282,
                 235004141,
                 235004153,
                 235003911,
                 235003927,
                 235003930,
                 235004124,
                 235004135,
                 235004263,
                 235004103,
                 235004089,
                 235004300,
                 235004051,
                 235004412,
                 235004431,
                 235003902,
                 235003984,
                 235003915,
                 235004121,
                 235004462,
                 235004464,
                 235004555,
                 235004328,
                 235004387,
                 235004395,
                 235004008,
                 235004238,
                 235004235,
                 235004390,
                 235004253,
                 235004020,
                 235004508,
                 235004507,
                 235004329,
                 235004052,
                 235004133,
                 235004534,
                 235004069,
                 235003991,
                 235004511,
                 235004137,
                 235003870,
                 235004197,
                 235004074,
                 235004264,
                 235004162,
                 235003878,
                 235003934,
                 235003877,
                 235004492,
                 235004451,
                 235004312,
                 235004481,
                 235004083,
                 235004372,
                 235004402,
                 235004504,
                 235004280,
                 235004403,
                 235004009,
                 235003998,
                 235004000,
                 235003995,
                 235004010,
                 235004001,
                 235004116,
                 235004159,
                 235004171,
                 235004325,
                 235004319,
                 235004123,
                 235003840,
                 235003846,
                 235004554,
                 235003963,
                 235004446,
                 235004176
                );

      fnd_file.put_line (fnd_file.LOG,
                         'Total Sites Updated: ' || SQL%ROWCOUNT
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   END fix_country_ou_onetime;

   PROCEDURE end_fin_hier_rels (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR fin_rel_cur
      IS
         SELECT relationship_id, object_version_number
           FROM hz_relationships
          WHERE relationship_type = 'OD_FIN_HIER' AND direction_code = 'P';

      l_rel_id             NUMBER;
      l_ovn                NUMBER;
      l_relationship_rec   hz_relationship_v2pub.relationship_rec_type;
      x_return_status      VARCHAR2 (2000);
      x_msg_count          NUMBER;
      x_msg_data           VARCHAR2 (2000);
      l_party_ovn          NUMBER;
      l_process_flag       VARCHAR2 (2);
      l_succ               NUMBER;
      l_err                NUMBER;
      l_succ_flag          BOOLEAN;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Executing Procedure end_fin_hier_rels'
                        );
      l_process_flag := NVL (fnd_profile.VALUE ('XX_CDH_REL_END_DATE'), 'N');

      IF l_process_flag = 'Y'
      THEN
         IF p_commit = 'Y'
         THEN
            l_succ_flag :=
                        fnd_profile.SAVE ('XX_CDH_REL_END_DATE', 'N', 'SITE');

            IF l_succ_flag
            THEN
               fnd_file.put_line
                              (fnd_file.LOG,
                               'Profile XX_CDH_REL_END_DATE Successfully Set'
                              );
            ELSE
               fnd_file.put_line
                      (fnd_file.LOG,
                       'ERROR: Profile XXX_CDH_REL_END_DATE Failed to be Set'
                      );
            END IF;
         END IF;

         FOR l_rels IN fin_rel_cur
         LOOP
            l_relationship_rec.relationship_id := l_rels.relationship_id;
            l_relationship_rec.end_date := SYSDATE;
            l_ovn := l_rels.object_version_number;
            hz_relationship_v2pub.update_relationship
                               (p_init_msg_list                    => 'T',
                                p_relationship_rec                 => l_relationship_rec,
                                p_object_version_number            => l_ovn,
                                p_party_object_version_number      => l_party_ovn,
                                x_return_status                    => x_return_status,
                                x_msg_count                        => x_msg_count,
                                x_msg_data                         => x_msg_data
                               );

            IF x_return_status = fnd_api.g_ret_sts_success
            THEN
               l_succ := l_succ + 1;
            ELSE
               l_err := l_err + 1;
               fnd_file.put_line (fnd_file.LOG,
                                     'Error during processing Relationship:'
                                  || l_relationship_rec.relationship_id
                                 );
               fnd_file.put_line (fnd_file.LOG, 'Error MSG:' || SQLERRM);
            END IF;

            IF p_commit = 'Y' AND MOD (l_succ, 300) = 0
            THEN
               COMMIT;
            END IF;
         END LOOP;

         IF p_commit = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;

         fnd_file.put_line (fnd_file.output,
                            'Total Records Successful:' || l_succ
                           );
         fnd_file.put_line (fnd_file.output, 'Total Records Error:' || l_err);
      ELSE
         fnd_file.put_line
               (fnd_file.LOG,
                'No Data Processed,Profile XX_CDH_REL_END_DATE is Turned OFF'
               );
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Procedure Execution end_fin_hier_rels Complete'
                        );
   END end_fin_hier_rels;

   PROCEDURE fix_revoke_roles (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR dup_roles
      IS
         SELECT   /*+parallel(r,4)*/
                  cust_account_role_id
             FROM hz_role_responsibility r
            WHERE responsibility_type IN
                          ('SELF_SERVICE_USER', 'REVOKED_SELF_SERVICE_ROLE')
         GROUP BY cust_account_role_id
           HAVING COUNT (1) > 1;

      l_rows_deleted   NUMBER := 0;
   BEGIN
      FOR l_dup_role IN dup_roles
      LOOP
         DELETE FROM hz_role_responsibility
               WHERE cust_account_role_id = l_dup_role.cust_account_role_id
                 AND responsibility_type = 'REVOKED_SELF_SERVICE_ROLE';

         l_rows_deleted := l_rows_deleted + SQL%ROWCOUNT;

         IF p_commit = 'Y' AND MOD (l_rows_deleted, 300) = 0
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Number Of Rows Deleted:' || l_rows_deleted
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_revoke_roles: ' || SQLERRM
                           );
   END fix_revoke_roles;

   PROCEDURE fix_loc_content_source (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
   BEGIN
      UPDATE hz_party_sites
         SET actual_content_source = 'A0',
             last_update_date = SYSDATE
       WHERE actual_content_source = 'USER_ENTERED';

      fnd_file.put_line (fnd_file.LOG,
                         'Party Site Records Modified:' || SQL%ROWCOUNT
                        );

      UPDATE hz_locations
         SET actual_content_source = 'A0',
             last_update_date = SYSDATE
       WHERE actual_content_source = 'USER_ENTERED';

      fnd_file.put_line (fnd_file.LOG,
                         'Location Records Modified:' || SQL%ROWCOUNT
                        );

      UPDATE hz_location_profiles
         SET actual_content_source = 'A0',
             last_update_date = SYSDATE
       WHERE actual_content_source = 'USER_ENTERED';

      fnd_file.put_line (fnd_file.LOG,
                         'Location Profile Records Modified:'
                         || SQL%ROWCOUNT
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_loc_content_source: ' || SQLERRM
                           );
   END fix_loc_content_source;

   PROCEDURE fix_party_prospect_flag (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR prosp_cur
      IS
         SELECT pa.party_id
           FROM hz_parties pa, hz_cust_accounts ac
          WHERE pa.party_id = ac.party_id AND pa.attribute13 = 'PROSPECT';

      l_rows_updated   NUMBER := 0;
   BEGIN
      FOR l_prosp IN prosp_cur
      LOOP
         UPDATE hz_parties
            SET attribute13 = 'CUSTOMER',
                last_update_date = SYSDATE
          WHERE party_id = l_prosp.party_id;

         l_rows_updated := l_rows_updated + SQL%ROWCOUNT;

         IF p_commit = 'Y' AND MOD (l_rows_updated, 500) = 0
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Number Of Rows Updated:' || l_rows_updated
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_party_prospect_flag: '
                            || SQLERRM
                           );
   END fix_party_prospect_flag;

   PROCEDURE activate_acct_prof (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR c_inactive_prof
      IS
         SELECT cust_account_profile_id
           FROM hz_customer_profiles
          WHERE status = 'I';

      l_rows_updated   NUMBER := 0;
   BEGIN
      FOR l_prof IN c_inactive_prof
      LOOP
         UPDATE hz_customer_profiles
            SET status = 'A',
                last_update_date = SYSDATE
          WHERE cust_account_profile_id = l_prof.cust_account_profile_id;

         l_rows_updated := l_rows_updated + SQL%ROWCOUNT;

         IF MOD (l_rows_updated, 500) = 0
         THEN
            IF p_commit = 'Y'
            THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Value of commit flag is ' || NVL (p_commit, 'N')
                        );
      fnd_file.put_line (fnd_file.LOG,
                         'Total Number Of Rows Updated:' || l_rows_updated
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in activate_acct_prof: ' || SQLERRM
                           );
   END activate_acct_prof;

   PROCEDURE fix_dup_acct_roles (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR dup_role_cur
      IS
         SELECT   /*+parallel(a,4)*/
                  MIN (cust_account_role_id) cust_account_role_id
             FROM hz_cust_account_roles a
            WHERE status = 'A' AND cust_acct_site_id IS NULL
         GROUP BY orig_system_reference
           HAVING COUNT (1) > 1;

      l_cust_acct_role_rec   hz_cust_account_role_v2pub.cust_account_role_rec_type;
      l_ovn                  NUMBER;
      lv_return_status       VARCHAR2 (10);
      ln_msg_count           NUMBER;
      lv_msg_data            VARCHAR2 (2000);
      l_succ_count           NUMBER                                      := 0;
      l_error_count          NUMBER                                      := 0;
      ln_msg_text            VARCHAR2 (32000);
   BEGIN
      FOR l_dup_role IN dup_role_cur
      LOOP
         SELECT object_version_number
           INTO l_ovn
           FROM hz_cust_account_roles
          WHERE cust_account_role_id = l_dup_role.cust_account_role_id
            AND cust_acct_site_id IS NULL;

         l_cust_acct_role_rec.cust_account_role_id :=
                                               l_dup_role.cust_account_role_id;
         l_cust_acct_role_rec.status := 'I';
         hz_cust_account_role_v2pub.update_cust_account_role
                             (p_init_msg_list              => 'T',
                              p_cust_account_role_rec      => l_cust_acct_role_rec,
                              p_object_version_number      => l_ovn,
                              x_return_status              => lv_return_status,
                              x_msg_count                  => ln_msg_count,
                              x_msg_data                   => lv_msg_data
                             );

         IF lv_return_status = fnd_api.g_ret_sts_success
         THEN
            l_succ_count := l_succ_count + 1;
         ELSE
            l_error_count := l_error_count + 1;

            IF ln_msg_count > 0
            THEN
               FOR counter IN 1 .. ln_msg_count
               LOOP
                  ln_msg_text :=
                        ln_msg_text
                     || ' '
                     || fnd_msg_pub.get (counter, fnd_api.g_false);
                  log_debug_msg (   'Error - '
                                 || fnd_msg_pub.get (counter, fnd_api.g_false)
                                );
               END LOOP;

               fnd_msg_pub.delete_msg;
               fnd_file.put_line (fnd_file.LOG, ln_msg_text);
            END IF;
         END IF;

         IF p_commit = 'Y' AND MOD (l_succ_count, 500) = 0
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.output,
                         'Total Records Successful:' || l_succ_count
                        );
      fnd_file.put_line (fnd_file.output,
                         'Total Records In Error:' || l_error_count
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_dup_acct_roles: ' || SQLERRM
                           );
   END fix_dup_acct_roles;

   PROCEDURE fix_null_states (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR states_cur
      IS
         SELECT /*+parallel(loc,8)*/
                loc.location_id
           FROM hz_locations loc
          WHERE EXISTS (
                   SELECT 'Y'
                     FROM hz_party_sites ps
                    WHERE ps.location_id = loc.location_id
                      AND EXISTS (
                             SELECT 'Y'
                               FROM hz_cust_acct_sites_all asi
                              WHERE asi.party_site_id = ps.party_site_id
                                AND asi.status = 'I'
                                AND ROWNUM = 1))
            AND country = 'US'
            AND state IS NULL;

      l_upd_count   NUMBER := 0;
   BEGIN
      FOR l_states_cur IN states_cur
      LOOP
         UPDATE hz_locations
            SET state = 'FL',
                last_update_date = SYSDATE
          WHERE location_id = l_states_cur.location_id;

         l_upd_count := l_upd_count + SQL%ROWCOUNT;

         IF p_commit = 'Y' AND MOD (l_upd_count, 500) = 0
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.output,
                         'Total Records Updated:' || l_upd_count
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_null_states: ' || SQLERRM
                           );
   END fix_null_states;

   PROCEDURE fix_null_provinces (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR provinces_cur
      IS
         SELECT /*+parallel(loc,8)*/
                loc.location_id
           FROM hz_locations loc
          WHERE EXISTS (
                   SELECT 'Y'
                     FROM hz_party_sites ps
                    WHERE ps.location_id = loc.location_id
                      AND EXISTS (
                             SELECT 'Y'
                               FROM hz_cust_acct_sites_all asi
                              WHERE asi.party_site_id = ps.party_site_id
                                AND asi.status = 'I'
                                AND ROWNUM = 1))
            AND country = 'CA'
            AND province IS NULL;

      l_upd_count   NUMBER := 0;
   BEGIN
      FOR l_provinces_cur IN provinces_cur
      LOOP
         UPDATE hz_locations
            SET province = 'ON',
                last_update_date = SYSDATE
          WHERE location_id = l_provinces_cur.location_id;

         l_upd_count := l_upd_count + SQL%ROWCOUNT;

         IF p_commit = 'Y' AND MOD (l_upd_count, 500) = 0
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.output,
                         'Total Records Updated:' || l_upd_count
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_null_provinces: ' || SQLERRM
                           );
   END fix_null_provinces;

   PROCEDURE fix_dup_spc (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      CURSOR dup_spc_cur (p_attr_grp_id NUMBER)
      IS
         SELECT   /*+PARALLEL(ext,4)*/
                  n_ext_attr1
             FROM xx_cdh_cust_acct_ext_b ext
            WHERE attr_group_id = p_attr_grp_id
         GROUP BY n_ext_attr1
           HAVING COUNT (1) > 1;

      CURSOR del_ext_cur (p_ext_attr1 NUMBER, p_attr_grp_id NUMBER)
      IS
         SELECT extension_id
           FROM xx_cdh_cust_acct_ext_b
          WHERE n_ext_attr1 = p_ext_attr1
            AND attr_group_id = p_attr_grp_id
            AND extension_id NOT IN (
                   SELECT MAX (extension_id)
                     FROM xx_cdh_cust_acct_ext_b
                    WHERE n_ext_attr1 = p_ext_attr1
                      AND attr_group_id = p_attr_grp_id);

      l_attr_grp_id    NUMBER;
      l_rows_deleted   NUMBER          := 0;
      ret_status       VARCHAR2 (1000);
      ret_msg          VARCHAR2 (6000);
      l_notify_msg     VARCHAR2 (1000);
   BEGIN
      SELECT attr_group_id
        INTO l_attr_grp_id
        FROM ego_attr_groups_v
       WHERE application_id = 222
         AND attr_group_name = 'SPC_INFO'
         AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

      FOR l_dup_spc_cur IN dup_spc_cur (l_attr_grp_id)
      LOOP
         FOR l_del_ext_cur IN del_ext_cur (l_dup_spc_cur.n_ext_attr1,
                                           l_attr_grp_id
                                          )
         LOOP
            DELETE FROM xx_cdh_cust_acct_ext_b
                  WHERE extension_id = l_del_ext_cur.extension_id;

            DELETE FROM xx_cdh_cust_acct_ext_tl
                  WHERE extension_id = l_del_ext_cur.extension_id;

            l_rows_deleted := l_rows_deleted + SQL%ROWCOUNT;
         END LOOP;

         IF MOD (l_rows_deleted, 200) = 0 AND p_commit = 'Y'
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Total Rows Deleted : ' || l_rows_deleted
                        );

      IF l_rows_deleted > 0
      THEN
         IF p_commit = 'Y'
         THEN
            l_notify_msg :=
                  'Duplicate SPC Cards Existed In The System and the Duplicates are Removed Successfully. Total Duplicates Deleted:'
               || l_rows_deleted;
         ELSE
            l_notify_msg :=
                  'Duplicate SPC Cards Exist in The System. No action has been taken by the program. Please re run the program with Commit set to ''Y'' to Remove the duplicates. Total Duplicates to Be Deleted:'
               || l_rows_deleted;
         END IF;

         send_data_corr_notif ('Duplicate SPC Cards Alert',
                               l_notify_msg,
                               'SPC_INFO',
                               ret_status,
                               ret_msg
                              );

         IF ret_status = 'E'
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Error During Notification Alert: ' || ret_msg
                              );
         ELSE
            fnd_file.put_line (fnd_file.LOG,
                               'Email Notification Sent Successfully'
                              );
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in FIX_DUP_SPC Procedure: ' || SQLERRM
                           );
         p_retcode := 2;
   END fix_dup_spc;

   PROCEDURE fix_dup_psite_ext_attribs (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      l_site_demo_attr_group_id    NUMBER;
      l_source_aud_attr_group_id   NUMBER;
      l_count1                     NUMBER;
      l_count2                     NUMBER;

      CURSOR c_attr_group_id (
         p_attr_group_name   IN   VARCHAR2,
         p_attr_group_type   IN   VARCHAR2
      )
      IS
         SELECT attr_group_id
           FROM ego_attr_groups_v
          WHERE application_id = 222
            AND attr_group_name = p_attr_group_name     -- 'SITE_DEMOGRAPHICS'
            AND attr_group_type = p_attr_group_type; --'HZ_PARTY_SITES_GROUP';

      CURSOR c1 (p_attr_group_id IN NUMBER)
      IS
         SELECT   /*+ full (a) parallel (a,4) */
                  party_site_id, MIN (extension_id) extension_id
             FROM hz_party_sites_ext_b a
            WHERE attr_group_id = p_attr_group_id
         GROUP BY party_site_id
           HAVING COUNT (1) > 1;
   BEGIN
      OPEN c_attr_group_id ('SOURCE_AUDIT', 'HZ_PARTY_SITES_GROUP');

      FETCH c_attr_group_id
       INTO l_source_aud_attr_group_id;

      CLOSE c_attr_group_id;

      OPEN c_attr_group_id ('SITE_DEMOGRAPHICS', 'HZ_PARTY_SITES_GROUP');

      FETCH c_attr_group_id
       INTO l_site_demo_attr_group_id;

      CLOSE c_attr_group_id;

--remove duplicates in source audit => attr_group_id=168
      l_count1 := 0;

      FOR i IN c1 (l_source_aud_attr_group_id)
      LOOP
         fnd_file.put_line (fnd_file.output,
                               'l_source_aud_attr_group_id: '
                            || l_source_aud_attr_group_id
                            || ', dup party_site_id: '
                            || i.party_site_id
                            || ', extension_id: '
                            || i.extension_id
                           );

         DELETE FROM hz_party_sites_ext_b
               WHERE extension_id = i.extension_id;

         IF (p_commit = 'Y')
         THEN
            COMMIT;
         END IF;

         l_count1 := l_count1 + 1;
      END LOOP;

      fnd_file.put_line (fnd_file.output,
                         'No. of source_audit rows: ' || l_count1
                        );
--remove duplicates in site demographics => attr_group_id=161
      l_count2 := 0;

      FOR j IN c1 (l_site_demo_attr_group_id)
      LOOP
         fnd_file.put_line (fnd_file.output,
                               'l_site_demo_attr_group_id: '
                            || l_site_demo_attr_group_id
                            || ', dup party_site_id: '
                            || j.party_site_id
                            || ', extension_id: '
                            || j.extension_id
                           );

         DELETE FROM hz_party_sites_ext_b
               WHERE extension_id = j.extension_id;

         IF (p_commit = 'Y')
         THEN
            COMMIT;
         END IF;

         l_count2 := l_count2 + 1;
      END LOOP;

      fnd_file.put_line (fnd_file.output,
                         'No. of site_demographics rows: ' || l_count2
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                               'Exception in fix_dup_psite_ext_attribs: '
                            || SQLERRM
                           );
         p_retcode := 2;
   END fix_dup_psite_ext_attribs;

   PROCEDURE fix_invalid_cnt (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   AS
      l_org_contact_cnt    NUMBER;
      l_orig_sys_ref_cnt   NUMBER;
   BEGIN
      fnd_file.put_line (fnd_file.LOG,
                         'Value of commit flag is ' || NVL (p_commit, 'N')
                        );

      SELECT /*+ PARALLEL(hoc,8) */
             COUNT (1)
        INTO l_org_contact_cnt
        FROM hz_org_contacts hoc
       WHERE NOT EXISTS (
                         SELECT 1
                           FROM hz_relationships hzr
                          WHERE hzr.relationship_id =
                                                     hoc.party_relationship_id);

      fnd_file.put_line (fnd_file.LOG,
                            ' Rows To Be deleted from hz_org_contacts is '
                         || l_org_contact_cnt
                        );

      -- Get count from HZ_ORIG_SYS_REFERENCES
      SELECT COUNT (1)
        INTO l_orig_sys_ref_cnt
        FROM hz_orig_sys_references
       WHERE owner_table_name = 'HZ_ORG_CONTACTS'
         AND owner_table_id IN (
                SELECT /*+ PARALLEL(hoc,8) */
                       hoc.org_contact_id
                  FROM hz_org_contacts hoc
                 WHERE NOT EXISTS (
                          SELECT 1
                            FROM hz_relationships hzr
                           WHERE hzr.relationship_id =
                                                     hoc.party_relationship_id));

      fnd_file.put_line
                       (fnd_file.LOG,
                           ' Rows To Be Updated IN hz_orig_sys_references is '
                        || l_orig_sys_ref_cnt
                       );

-- update HZ_ORIG_SYS_REFERENCES
      UPDATE hz_orig_sys_references
         SET status = 'I',
             last_update_date = SYSDATE
       WHERE orig_system_ref_id IN (
                SELECT orig_system_ref_id
                  FROM hz_orig_sys_references
                 WHERE owner_table_name = 'HZ_ORG_CONTACTS'
                   AND owner_table_id IN (
                          SELECT /*+ PARALLEL(hoc,8) */
                                 hoc.org_contact_id
                            FROM hz_org_contacts hoc
                           WHERE NOT EXISTS (
                                    SELECT 1
                                      FROM hz_relationships hzr
                                     WHERE hzr.relationship_id =
                                                     hoc.party_relationship_id)));

      fnd_file.put_line (fnd_file.LOG,
                            ' Rows Updated IN hz_orig_sys_references is '
                         || SQL%ROWCOUNT
                        );

      DELETE FROM hz_org_contacts
            WHERE org_contact_id IN (
                     SELECT /*+ PARALLEL(hoc,8) */
                            hoc.org_contact_id
                       FROM hz_org_contacts hoc
                      WHERE NOT EXISTS (
                               SELECT 1
                                 FROM hz_relationships hzr
                                WHERE hzr.relationship_id =
                                                     hoc.party_relationship_id));

      fnd_file.put_line (fnd_file.LOG,
                            ' Rows Deleted FROM hz_org_contacts is '
                         || SQL%ROWCOUNT
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'Value of commit flag is ' || NVL (p_commit, 'N')
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_invalid_cnt: ' || SQLERRM
                           );
         p_retcode := 2;
   END fix_invalid_cnt;

   PROCEDURE send_data_corr_notif (
      p_subject            VARCHAR2,
      p_body               VARCHAR2,
      p_module             VARCHAR2,
      x_ret_status   OUT   VARCHAR2,
      x_ret_msg      OUT   VARCHAR2
   )
   AS
      l_mail_server    VARCHAR2 (200);
      l_mail_from      VARCHAR2 (100);
      l_mail_to        VARCHAR2 (100);
      l_send_as_page   VARCHAR2 (10);
      l_subject        VARCHAR2 (1000);
      mail_con         UTL_SMTP.connection;
   BEGIN
      x_ret_status := 'S';
      x_ret_msg := NULL;

      SELECT target_value1 mail_server, target_value2 mail_from,
             target_value3 mail_to, target_value4 send_as_page
        INTO l_mail_server, l_mail_from,
             l_mail_to, l_send_as_page
        FROM xx_fin_translatedefinition xxdef, xx_fin_translatevalues xxval
       WHERE xxdef.translation_name = 'XX_CDH_DATA_ALERTER'
         AND xxval.translate_id = xxdef.translate_id
         AND xxval.source_value1 = p_module;

      IF l_mail_server IS NULL OR l_mail_from IS NULL OR l_mail_to IS NULL
      THEN
         x_ret_status := 'E';
         x_ret_msg :=
            'Error In Procedure send_data_corr_notif - One Of The Mandatory Values Missing';
      ELSE
         IF l_send_as_page = 'Y'
         THEN
            l_subject := '***page***' || p_subject;
         ELSE
            l_subject := p_subject;
         END IF;

         mail_con := UTL_SMTP.open_connection (l_mail_server, 25);
         -- SMTP on port 25
         UTL_SMTP.helo (mail_con, l_mail_server);
         UTL_SMTP.mail (mail_con, l_mail_from);
         UTL_SMTP.rcpt (mail_con, TRIM (l_mail_to));
         UTL_SMTP.DATA
                 (mail_con,
                     'From: '
                  || 'CRM CDH Data Alerter'
                  || UTL_TCP.crlf
                  || 'To: '
                  || l_mail_to
                  || UTL_TCP.crlf
                  || 'Subject: '
                  || l_subject
                  || UTL_TCP.crlf
                  || p_body
                  || UTL_TCP.crlf
                  || UTL_TCP.crlf
                  || 'P.S: This is an Auto Generated Email. Please DO NOT Reply.'
                 );
         UTL_SMTP.quit (mail_con);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_ret_status := 'E';
         x_ret_msg := 'Exception in send_data_corr_notif: ' || SQLERRM;
   END send_data_corr_notif;

   PROCEDURE nodes_correction (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      CURSOR c_invalid_nodes
      IS
         SELECT parent_id, child_id
           FROM hz_hierarchy_nodes hn
          WHERE level_number = 1
            AND hierarchy_type = 'OD_FIN_PAY_WITHIN'
            AND (    status = 'A'
                 AND SYSDATE BETWEEN effective_start_date
                                 AND NVL (effective_end_date, SYSDATE + 1)
                )
            AND NOT EXISTS (
                   SELECT 1
                     FROM hz_relationships hzr
                    WHERE hzr.subject_id = hn.parent_id
                      AND hzr.object_id = hn.child_id
                      AND status = 'A'
                      AND SYSDATE < NVL (end_date, SYSDATE + 1)
                      AND relationship_type = 'OD_FIN_PAY_WITHIN');

        -- added for POST PROD TEST
      --  and relationship_id = 27516030;
      CURSOR c_invalid_rels (p_object_id hz_relationships.object_id%TYPE)
      IS
         SELECT relationship_id
           FROM hz_relationships
          WHERE relationship_type = 'OD_FIN_PAY_WITHIN'
            AND status = 'A'
            AND object_id = p_object_id
            AND end_date < SYSDATE;

      l_rows_updated   NUMBER;
   BEGIN
      FOR rec_invalid_nodes IN c_invalid_nodes
      LOOP
         l_rows_updated := l_rows_updated + 1;

         UPDATE hz_hierarchy_nodes hn
            SET effective_end_date = SYSDATE
          WHERE hierarchy_type = 'OD_FIN_PAY_WITHIN'
            AND level_number = 1
            AND parent_id = rec_invalid_nodes.parent_id
            AND child_id = rec_invalid_nodes.child_id;

         FOR rec_invalid_rels IN c_invalid_rels (rec_invalid_nodes.child_id)
         LOOP
            UPDATE hz_relationships
               SET status = 'I'
             WHERE relationship_id = rec_invalid_rels.relationship_id;

            INSERT INTO xxod_hz_summary
                        (summary_id, error_id,
                         party_id,
                         owner_table_id
                        )
                 VALUES (-786786, rec_invalid_rels.relationship_id,
                         rec_invalid_nodes.parent_id,
                         rec_invalid_nodes.child_id
                        );
         END LOOP;

         IF MOD (l_rows_updated, 500) = 0
         THEN
            IF p_commit = 'Y'
            THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;
         END IF;
      END LOOP;

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;

      fnd_file.put_line (fnd_file.LOG, 'REcords updated ' || l_rows_updated);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in nodes_correction: ' || SQLERRM
                           );
         p_errbuf := 'Exception in nodes_correction: ' || SQLERRM;
         p_retcode := 2;
   END nodes_correction;

   PROCEDURE acct_party_name_sync (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      CURSOR mismatch_cur
      IS
         SELECT /*+PARALLEL(B,4)*/
                orig_system_reference, party_id, account_name
           FROM hz_cust_accounts b
          WHERE orig_system_reference LIKE '%A0'
            AND NOT EXISTS (
                   SELECT 'Y'
                     FROM hz_parties
                    WHERE party_name = b.account_name
                          AND party_id = b.party_id);

      l_update_count   NUMBER := 0;
   BEGIN
      FOR l_mismatch_cur IN mismatch_cur
      LOOP
         UPDATE hz_parties
            SET party_name = l_mismatch_cur.account_name
          WHERE party_id = l_mismatch_cur.party_id;

         l_update_count := l_update_count + SQL%ROWCOUNT;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG,
                         'Party Records Updated:' || l_update_count
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in acct_party_name_sync: ' || SQLERRM
                           );
         p_errbuf := 'Exception in acct_party_name_sync: ' || SQLERRM;
         p_retcode := 2;
   END acct_party_name_sync;

   PROCEDURE fix_collect_rec (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      TYPE rec_col IS RECORD (
         col_rel_id   hz_relationships.relationship_id%TYPE,
         col_pty_id   hz_relationships.party_id%TYPE,
         con_rel_id   hz_relationships.relationship_id%TYPE,
         con_pty_id   hz_relationships.party_id%TYPE,
         car_rol_id   hz_cust_account_roles.cust_account_role_id%TYPE
      );

      TYPE t_col_tab IS TABLE OF rec_col
         INDEX BY PLS_INTEGER;

      tab_multi_col   t_col_tab;

      TYPE t_con_tab IS TABLE OF hz_org_contacts.org_contact_id%TYPE
         INDEX BY PLS_INTEGER;

      tab_org_cont    t_con_tab;

      TYPE t_con_cp IS TABLE OF hz_contact_points.contact_point_id%TYPE
         INDEX BY PLS_INTEGER;

      tab_con_cp      t_con_cp;

      TYPE t_col_cp IS TABLE OF hz_contact_points.contact_point_id%TYPE
         INDEX BY PLS_INTEGER;

      tab_col_cp      t_col_cp;
      l_cnt           NUMBER    := 0;

-- only contract customers link old collection with contact.
      CURSOR c_multi_col
      IS
         SELECT /*+PARALLEL(col,4)*/
                col.relationship_id, col.party_id, con.relationship_id,
                con.party_id, car.cust_account_role_id
           FROM hz_relationships col,
                hz_relationships con,
                hz_cust_account_roles car,
                hz_cust_accounts hca
          WHERE col.relationship_type = 'COLLECTIONS'
-- below condition added on 09/29/10
            AND car.cust_acct_site_id IS NOT NULL
            AND col.status = 'A'
            AND col.direction_code = 'P'
            AND con.relationship_type = 'CONTACT'
            AND con.direction_code = 'P'
            AND con.subject_id = col.subject_id
            AND con.object_id = col.object_id
            AND con.status = 'A'
            AND car.party_id = con.party_id
            AND car.role_type = 'CONTACT'
            AND car.cust_account_id = hca.cust_account_id
            AND hca.attribute18 = 'CONTRACT'
            AND car.status = 'A';

-- update hz_org_contacts job_title when no 'DUNNING' contact point
-- and job_title is 'AP' , 'Account Payable Manager' , 'Account Payable'
      CURSOR c_in_job_title
      IS
         SELECT /*+PARALLEL(hoc,4)*/
                hoc.org_contact_id
           FROM hz_org_contacts hoc
          WHERE (job_title = 'AP' OR job_title LIKE 'Account%')
            AND status = 'A'
            AND NOT EXISTS (
                   SELECT 1
                     FROM hz_contact_points hcp,
                                                --lationships hpr Commented for R12 upgrade retrofit
                                                hz_relationships hpr
                    --Added for R12 upgrade retrofit
                   WHERE  hcp.contact_point_purpose = 'DUNNING'
                      AND hcp.owner_table_name = 'HZ_PARTIES'
                      AND hcp.owner_table_id = hpr.party_id
                      AND hcp.status = 'A'
                      AND hpr.status = 'A'
                      --and     hpr.party_relationship_id = hoc.party_relationship_id Commented for R12 upgrade retrofit
                      AND hpr.relationship_id = hoc.party_relationship_id
                                                                         -- Added for R12 upgrade retrofit
                );

      CURSOR c_ap_job_title
      IS
         SELECT /*+PARALLEL(hoc,4)*/
                hoc.org_contact_id
           FROM hz_org_contacts hoc
          WHERE (job_title IS NULL OR job_title <> 'AP')
            AND status = 'A'
            AND EXISTS (
                   SELECT 1
                     FROM hz_contact_points hcp,
                          --hz_party_relationships hpr Commented for R12 upgrade retrofit
                          hz_relationships hpr,
                          --Added for R12 upgrade retrofit
                          hz_cust_account_roles car,
                          hz_role_responsibility hrr
                    WHERE hcp.contact_point_purpose = 'DUNNING'
                      AND hcp.owner_table_name = 'HZ_PARTIES'
                      AND hcp.owner_table_id = hpr.party_id
                      AND hcp.status = 'A'
                      AND hpr.status = 'A'
                      --and     hpr.party_relationship_id = hoc.party_relationship_id Commented for R12 upgrade retrofit
                      AND hpr.relationship_id = hoc.party_relationship_id
                      -- Added for R12 upgrade retrofit
                      AND car.party_id = hpr.party_id
                      AND car.status = 'A'
                      AND car.cust_account_role_id = hrr.cust_account_role_id
                      AND hrr.responsibility_type = 'DUN'
                      -- do not fix for dup account roles at the same site
                      AND (car.cust_account_id, car.cust_acct_site_id) NOT IN (
                             SELECT   /*+PARALLEL(rol,4)*/
                                      rol.cust_account_id,
                                      rol.cust_acct_site_id
                                 FROM hz_cust_account_roles rol,
                                      hz_role_responsibility rsp
                                WHERE rol.cust_account_role_id =
                                                      rsp.cust_account_role_id
                                  AND rol.cust_acct_site_id =
                                                         car.cust_acct_site_id
                                  AND rol.cust_account_id =
                                                           car.cust_account_id
                                  AND rsp.responsibility_type = 'DUN'
                                  AND rol.status = 'A'
                             GROUP BY rol.cust_account_id,
                                      rol.cust_acct_site_id
                               HAVING COUNT (1) > 1));

-- can we change contact point purpose to collections
      CURSOR c_unset_ap_roles
      IS
         SELECT /*+PARALLEL(hoc,4)*/
                hoc.org_contact_id
           FROM hz_org_contacts hoc
          WHERE (   job_title IS NULL
                 OR job_title = 'AP'
                 OR job_title LIKE 'Account%'
                )
            AND status = 'A'
            AND EXISTS (
                   SELECT 1
                     FROM hz_contact_points hcp,
                                                --hz_party_relationships hpr Commented for R12 upgrade retrofit
                                                hz_relationships hpr
                    --Added for R12 upgrade retrofit
                   WHERE  hcp.contact_point_purpose = 'DUNNING'
                      AND hcp.owner_table_name = 'HZ_PARTIES'
                      AND hcp.owner_table_id = hpr.party_id
                      AND hcp.status = 'A'
                      AND hpr.status = 'A'
                      --and     hpr.party_relationship_id = hoc.party_relationship_id Commented for R12 upgrade retrofit
                      AND hpr.relationship_id = hoc.party_relationship_id
                                                                         -- Added for R12 upgrade retrofit
                )
            AND NOT EXISTS (
                   SELECT 1
                     --hz_party_relationships hpr Commented for R12 upgrade retrofit
                   FROM   hz_relationships hpr,
                          --Added for R12 upgrade retrofit
                          hz_cust_account_roles car,
                          hz_role_responsibility hrr
                    WHERE hpr.status = 'A'
                      --and     hpr.party_relationship_id = hoc.party_relationship_id Commented for R12 upgrade retrofit
                      AND hpr.relationship_id = hoc.party_relationship_id
                      -- Added for R12 upgrade retrofit
                      AND car.party_id = hpr.party_id
                      AND car.status = 'A'
                      AND car.cust_account_role_id = hrr.cust_account_role_id
                      AND hrr.responsibility_type = 'DUN');
   BEGIN
      OPEN c_multi_col;

      LOOP
         FETCH c_multi_col
         BULK COLLECT INTO tab_multi_col LIMIT 500;

         FOR i IN 1 .. tab_multi_col.COUNT
         LOOP
            SELECT contact_point_id
            BULK COLLECT INTO tab_con_cp
              FROM hz_contact_points
             WHERE owner_table_id = tab_multi_col (i).con_pty_id
               AND owner_table_name = 'HZ_PARTIES';

            SELECT contact_point_id
            BULK COLLECT INTO tab_col_cp
              FROM hz_contact_points
             WHERE owner_table_id = tab_multi_col (i).col_pty_id
               AND owner_table_name = 'HZ_PARTIES';

            FOR ind IN 1 .. tab_con_cp.COUNT
            LOOP
               UPDATE hz_contact_points
                  SET owner_table_id = tab_multi_col (i).col_pty_id,
                      last_update_date = SYSDATE,
                      last_updated_by = hz_utility_v2pub.last_updated_by
                WHERE contact_point_id = tab_con_cp (ind);
            END LOOP;

            FOR ind IN 1 .. tab_col_cp.COUNT
            LOOP
               UPDATE hz_contact_points
                  SET owner_table_id = tab_multi_col (i).con_pty_id,
                      last_update_date = SYSDATE,
                      last_updated_by = hz_utility_v2pub.last_updated_by
                WHERE contact_point_id = tab_col_cp (ind);
            END LOOP;

            UPDATE hz_cust_account_roles
               SET party_id = tab_multi_col (i).col_pty_id,
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE cust_account_role_id = tab_multi_col (i).car_rol_id;

            l_cnt := l_cnt + 1;

            UPDATE hz_org_contacts
               SET job_title =
                      (SELECT job_title
                         FROM hz_org_contacts
                        WHERE party_relationship_id =
                                                  tab_multi_col (i).con_rel_id
                          AND ROWNUM = 1),
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE party_relationship_id = tab_multi_col (i).col_rel_id;
--                    party_id = tab_multi_col(i).con_pty_id
--                    and        role_type = 'CONTACT'
--                    and     status = 'A';
         END LOOP;

         IF p_commit = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;

         EXIT WHEN tab_multi_col.COUNT < 500;
      END LOOP;

      CLOSE c_multi_col;

      fnd_file.put_line (fnd_file.LOG,
                         ' c_multi_col: Rows Updated: ' || l_cnt);
      l_cnt := 0;

      OPEN c_in_job_title;

      LOOP
         FETCH c_in_job_title
         BULK COLLECT INTO tab_org_cont LIMIT 500;

         FOR i IN 1 .. tab_org_cont.COUNT
         LOOP
            l_cnt := l_cnt + 1;

            UPDATE hz_org_contacts
               SET job_title = 'AP INACTIVE',
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE org_contact_id = tab_org_cont (i);
         END LOOP;

         IF p_commit = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;

         EXIT WHEN tab_org_cont.COUNT < 500;
      END LOOP;

      CLOSE c_in_job_title;

      l_cnt := 0;
      fnd_file.put_line (fnd_file.LOG,
                         ' c_in_job_title: Rows Updated: ' || l_cnt
                        );

      OPEN c_ap_job_title;

      LOOP
         FETCH c_ap_job_title
         BULK COLLECT INTO tab_org_cont LIMIT 500;

         FOR i IN 1 .. tab_org_cont.COUNT
         LOOP
            l_cnt := l_cnt + 1;

            UPDATE hz_org_contacts
               SET job_title = 'AP',
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE org_contact_id = tab_org_cont (i);
         END LOOP;

         IF p_commit = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;

         EXIT WHEN tab_org_cont.COUNT < 500;
      END LOOP;

      CLOSE c_ap_job_title;

      l_cnt := 0;
      fnd_file.put_line (fnd_file.LOG,
                         ' c_ap_job_title: Rows Updated: ' || l_cnt
                        );

      OPEN c_unset_ap_roles;

      LOOP
         FETCH c_unset_ap_roles
         BULK COLLECT INTO tab_org_cont LIMIT 500;

         FOR i IN 1 .. tab_org_cont.COUNT
         LOOP
            l_cnt := l_cnt + 1;

            UPDATE hz_org_contacts
               SET job_title = 'AP INACTIVE',
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE org_contact_id = tab_org_cont (i);

            UPDATE hz_contact_points
               SET contact_point_purpose = 'COLLECTIONS',
                   primary_flag = 'N',
                   last_update_date = SYSDATE,
                   last_updated_by = hz_utility_v2pub.last_updated_by
             WHERE contact_point_id IN (
                      SELECT contact_point_id
                        FROM hz_contact_points hcp,
                             --hz_party_relationships hpr Commented for R12 upgrade retrofit
                             hz_relationships hpr,
                             --Added for R12 upgrade retrofit
                             hz_org_contacts hoc
                       WHERE hcp.contact_point_purpose = 'DUNNING'
                         AND hcp.owner_table_name = 'HZ_PARTIES'
                         AND hcp.owner_table_id = hpr.party_id
                         AND hcp.status = 'A'
                         AND hpr.status = 'A'
                         --and     hpr.party_relationship_id = hoc.party_relationship_id Commented for R12 upgrade retrofit
                         AND hpr.relationship_id = hoc.party_relationship_id
                         --Added for R12 upgrade retrofit
                         AND hoc.org_contact_id = tab_org_cont (i));
         END LOOP;

         IF p_commit = 'Y'
         THEN
            COMMIT;
         ELSE
            ROLLBACK;
         END IF;

         EXIT WHEN tab_org_cont.COUNT < 500;
      END LOOP;

      CLOSE c_unset_ap_roles;

      fnd_file.put_line (fnd_file.LOG,
                         ' c_unset_ap_roles: Rows Updated: ' || l_cnt
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in fix_collect_rec: ' || SQLERRM
                           );
         p_errbuf := 'Exception in fix_collect_rec: ' || SQLERRM;
         p_retcode := 2;
   END fix_collect_rec;

   PROCEDURE seq_issue_alert (
      x_errbuf    OUT NOCOPY      VARCHAR2,
      x_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      ln_old_seq_value   NUMBER;
      ln_last_number     NUMBER;
      ln_max_diff        NUMBER;
      ln_upd_count       NUMBER;
   BEGIN
      SELECT last_number
        INTO ln_last_number
        FROM dba_sequences
       WHERE sequence_name = 'HZ_CUST_ACCT_SITES_S';

      BEGIN
         SELECT NVL (party_id, ln_last_number), owner_table_id
           INTO ln_old_seq_value, ln_max_diff
           FROM xxod_hz_summary
          WHERE summary_id = 220920101240000 AND batch_id = 220920101240000;
      EXCEPTION
         WHEN OTHERS
         THEN
            ln_old_seq_value := ln_last_number;
            ln_max_diff := 50000;
      END;

      UPDATE xxod_hz_summary
         SET party_id = ln_last_number
       WHERE summary_id = 220920101240000 AND batch_id = 220920101240000;

      ln_upd_count := SQL%ROWCOUNT;

      IF ln_upd_count = 0
      THEN
         INSERT INTO xxod_hz_summary
                     (summary_id, batch_id, party_id, owner_table_id
                     )
              VALUES (220920101240000, 220920101240000, NULL, 50000
                     );
      ELSIF ln_upd_count > 1
      THEN
         fnd_file.put_line
               (fnd_file.LOG,
                'Some error with number of records in XXOD_HZ_SUMMARY table.'
               );
         x_retcode := 2;
      END IF;

      IF (ln_last_number - ln_old_seq_value) > ln_max_diff
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Difference is more than ' || ln_max_diff || '.'
                           );
         x_retcode := 2;
      END IF;

      COMMIT;
--        fnd_file.put_line (fnd_file.log,'Testing - Exception in SEQ_ISSUE_ALERT: ' || SQLERRM);
 --        x_retcode := 2;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         fnd_file.put_line (fnd_file.LOG,
                            'Exception in SEQ_ISSUE_ALERT: ' || SQLERRM
                           );
         x_retcode := 2;
   END seq_issue_alert;

   PROCEDURE end_grandparent_rel (
      x_errbuf    OUT NOCOPY      VARCHAR2,
      x_retcode   OUT NOCOPY      VARCHAR2,
      p_commit    IN              VARCHAR2
   )
   IS
      l_rel_rec           hz_relationship_v2pub.relationship_rec_type;
      l_relationship_id   NUMBER;
      l_ovn               NUMBER;
      l_p_ovn             NUMBER;
      x_ret_status        VARCHAR2 (10);
      x_m_count           NUMBER;
      x_m_data            VARCHAR2 (2000);
      l_total             NUMBER                                      := 0;

      CURSOR gp_rel
      IS
         SELECT DISTINCT relationship_id
                    FROM hz_relationships
                   WHERE status = 'A'
                     AND relationship_type = 'OD_CUST_HIER'
                     AND relationship_code = 'GRANDPARENT'
                     AND direction_code = 'P'
                     AND TRUNC (creation_date) <
                                          TO_DATE ('06/01/2011', 'MM/DD/RRRR');
   BEGIN
      FOR l_rel IN gp_rel
      LOOP
         BEGIN
            SELECT object_version_number
              INTO l_ovn
              FROM hz_relationships
             WHERE relationship_id = l_rel.relationship_id AND ROWNUM = 1;

            l_rel_rec.relationship_id := l_rel.relationship_id;
            l_rel_rec.status := 'I';
            l_rel_rec.end_date := TRUNC (SYSDATE - 1);
            hz_relationship_v2pub.update_relationship
                                    (p_relationship_rec                 => l_rel_rec,
                                     p_object_version_number            => l_ovn,
                                     p_party_object_version_number      => l_p_ovn,
                                     x_return_status                    => x_ret_status,
                                     x_msg_count                        => x_m_count,
                                     x_msg_data                         => x_m_data
                                    );

            IF x_ret_status <> 'S'
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'UpdateRel API error for Rel:'
                                  || l_rel.relationship_id
                                  || ':'
                                  || x_m_data
                                 );
            ELSE
               l_total := l_total + 1;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Error for Relationship:'
                                  || l_rel.relationship_id
                                  || ':'
                                  || SQLERRM
                                 );
         END;
      END LOOP;

      fnd_file.put_line (fnd_file.output,
                         'Total Relationships Inactivated:' || l_total
                        );

      IF p_commit = 'Y'
      THEN
         COMMIT;
      ELSE
         ROLLBACK;
      END IF;
   END end_grandparent_rel;

   PROCEDURE xx_cdh_loyalty_code_fix_main (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR new_code_assignment
      IS
         SELECT code_assignment_id, owner_table_id, object_version_number,
                primary_flag
           FROM (SELECT ROW_NUMBER () OVER (PARTITION BY owner_table_id ORDER BY creation_date DESC)
                                                                   AS rownum1,
                        owner_table_id, code_assignment_id,
                        object_version_number, primary_flag, creation_date
                   FROM hz_code_assignments
                  WHERE owner_table_name = 'HZ_PARTIES'
                    AND class_category = 'Customer Loyalty'
                    AND status = 'A'
                    AND end_date_active IS NULL) a
          WHERE a.rownum1 = 1
            AND (a.primary_flag = 'N' OR a.primary_flag IS NULL)
--AND code_assigment_id=27663810
      ;

      TYPE new_code_assignments IS TABLE OF new_code_assignment%ROWTYPE
         INDEX BY BINARY_INTEGER;

      l_new_code_assign_tab   new_code_assignments;
      lr_code_assign_rec      hz_classification_v2pub.code_assignment_rec_type;
      lc_return_status        VARCHAR2 (10);
      ln_msg_count            NUMBER;
      lc_msg_data             VARCHAR2 (4000);
      x_error_message         VARCHAR2 (4000);
      ln_resp_appln_id        NUMBER;
      ln_resp_id              NUMBER;
      ln_user_id              NUMBER;
      ln_t_records            NUMBER                                      := 0;
      ln_e_records            NUMBER                                      := 0;
   BEGIN
      OPEN new_code_assignment;

      LOOP
         FETCH new_code_assignment
         BULK COLLECT INTO l_new_code_assign_tab LIMIT 100;

         ln_t_records := ln_t_records + l_new_code_assign_tab.COUNT;
         EXIT WHEN l_new_code_assign_tab.COUNT = 0;

         FOR ind IN l_new_code_assign_tab.FIRST .. l_new_code_assign_tab.LAST
         LOOP
            BEGIN
               lr_code_assign_rec := NULL;
               lr_code_assign_rec.code_assignment_id :=
                               l_new_code_assign_tab (ind).code_assignment_id;
               lr_code_assign_rec.primary_flag := 'Y';
               hz_classification_v2pub.update_code_assignment
                  (p_init_msg_list              => fnd_api.g_true,
                   p_code_assignment_rec        => lr_code_assign_rec,
                   p_object_version_number      => l_new_code_assign_tab (ind).object_version_number,
                   x_return_status              => lc_return_status,
                   x_msg_count                  => ln_msg_count,
                   x_msg_data                   => lc_msg_data
                  );

               IF lc_return_status <> fnd_api.g_ret_sts_success
               THEN
                  x_error_message := NULL;

                  IF ln_msg_count > 1
                  THEN
                     FOR counter IN 1 .. ln_msg_count
                     LOOP
                        x_error_message :=
                              x_error_message
                           || ' '
                           || fnd_msg_pub.get (counter, fnd_api.g_false);
                     END LOOP;
                  END IF;

                  fnd_msg_pub.delete_msg;
                  ln_e_records := ln_e_records + 1;
                  fnd_file.put_line
                             (fnd_file.LOG,
                                 'Error occured for code_assignment_id :'
                              || l_new_code_assign_tab (ind).code_assignment_id
                              || ','
                              || x_error_message
                             );
               END IF;

               IF (p_commit = 'Y')
               THEN
                  COMMIT;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --dbms_output.put_line('Unexpected error for code_assignment_id :'||l_new_code_assign_tab(ind).code_assignment_id||','||SQLERRM);
                  fnd_file.put_line
                            (fnd_file.LOG,
                                'Unexpected error for code_assignment_id :'
                             || l_new_code_assign_tab (ind).code_assignment_id
                             || ','
                             || SQLERRM
                            );
                  ln_e_records := ln_e_records + 1;
            END;
         END LOOP;
      -- FOR ind in l_new_code_assign_tab.FIRST..l_new_code_assign_tab.LAST
      END LOOP;                     --EXIT WHEN l_new_code_assign_tab.COUNT=0;

      CLOSE new_code_assignment;

      fnd_file.put_line (fnd_file.output,
                         'Total Records processed: ' || ln_t_records
                        );
      fnd_file.put_line (fnd_file.output,
                         'Number of Errors: ' || ln_e_records);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Unexpected error in MAIN procedure: ' || SQLERRM
                           );
   END;

   PROCEDURE sp_fix_cust_account_attribute6 (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_account
      IS
         SELECT /*+ PARALLEL (A,4) */
                ROWID tbl_rowid, attribute6, cust_account_id
           FROM hz_cust_accounts a
          WHERE attribute6 NOT LIKE '%/%'
            AND LENGTH (attribute6) = 8
            AND attribute6 IS NOT NULL;

-- Not checking status
-- using p_commit for restricting records...
      v_total_records   NUMBER          := 0;
      v_total_success   NUMBER          := 0;
      v_message         VARCHAR2 (2000);
      v_attribute6      VARCHAR2 (100);
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;

      FOR rec IN cur_account
      LOOP
         v_total_records := v_total_records + 1;

         BEGIN
            UPDATE hz_cust_accounts
               SET attribute6 =
                      TO_CHAR (TO_DATE (attribute6, 'YYYYMMDD'),
                               'YYYY/MM/DD HH24:MI:SS'
                              )
             WHERE ROWID = rec.tbl_rowid
               AND cust_account_id = rec.cust_account_id;

            IF SQL%ROWCOUNT <> 0
            THEN
               SELECT attribute6
                 INTO v_attribute6
                 FROM hz_cust_accounts
                WHERE ROWID = rec.tbl_rowid
                  AND cust_account_id = rec.cust_account_id;

               -- webcollect - 932255328
               INSERT INTO xxod_hz_summary
                           (batch_id, attribute1, attribute2,
                            attribute3
                           )
                    VALUES (-932255328, rec.cust_account_id, rec.attribute6,
                            v_attribute6
                           );

--            COMMIT;
               v_total_success := v_total_success + 1;
               v_message :=
                     'Cust Account Id successfully updated is '
                  || rec.cust_account_id
                  || ' old attribute6 '
                  || rec.attribute6
                  || ' New attribute6 '
                  || v_attribute6
                  || ' .';
               fnd_file.put_line (fnd_file.LOG, v_message);
            ELSE
               v_message :=
                     'Cust Account Id unsuccessfully updated is '
                  || rec.cust_account_id
                  || ' old attribute6 '
                  || rec.attribute6
                  || ' .';
               fnd_file.put_line (fnd_file.output, v_message);
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_message :=
                     'Cust Account Id unsuccessfully updated is '
                  || rec.cust_account_id
                  || ' old attribute6 '
                  || rec.attribute6
                  || ' Error '
                  || SUBSTR (SQLERRM, 1, 100)
                  || '.';
               fnd_file.put_line (fnd_file.output, v_message);
         END;

         IF (p_commit = 'Y')
         THEN
            COMMIT;
         END IF;
      END LOOP;

      v_message :=
            'Total Records '
         || v_total_records
         || ' Successful '
         || v_total_success
         || ' .';
      fnd_file.put_line (fnd_file.output, v_message);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Customer Update:' || SQLERRM;
   END sp_fix_cust_account_attribute6;

   PROCEDURE sp_ins_account_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_account
      IS
         SELECT          /*+ PARALLEL (A,4) PARALLEL (B,4) */
                DISTINCT b.party_id oracle_party_id
                    FROM xx_crm_exp_site_master a, hz_party_sites b
                   WHERE a.party_site_id = b.party_site_id;

      l_account_id   NUMBER;
      lc_end_date    DATE;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      lc_end_date :=
           TO_DATE (fnd_profile.VALUE ('XX_CRM_SFDC_CUST_CONV_END_DATE'),
                    'MM/DD/YYYY HH24:MI:SS'
                   )
         - (5 / 1440);

      FOR s IN cur_account
      LOOP
         BEGIN
            SELECT party_id
              INTO l_account_id
              FROM xx_crm_exp_account_master
             WHERE party_id = s.oracle_party_id;

            UPDATE xx_crm_exp_account_master
               SET last_update_date = lc_end_date
             WHERE party_id = l_account_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               INSERT INTO xx_crm_exp_account_master
                           (party_id, creation_date, last_update_date,
                            created_by, last_updated_by
                           )
                    VALUES (s.oracle_party_id, lc_end_date, lc_end_date,
                            -1, -1
                           );
         END;

         IF (p_commit = 'Y')
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Customer Update:' || SQLERRM;
   END sp_ins_account_master;

   PROCEDURE sp_del_notaops_site_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      l_account_id     NUMBER;
      l_conv_st_date   DATE;

      CURSOR cur_account
      IS
         SELECT          /*+ PARALLEL (ps,4) PARALLEL (p,4) PARALLEL (ac,4) PARALLEL (asi,4) PARALLEL (master,4) */
                DISTINCT ps.party_id, ps.party_site_id,
                         MASTER.ROWID tmp_rowid
                    FROM hz_party_sites ps,
                         hz_parties p,
                         hz_cust_accounts ac,
                         hz_cust_acct_sites_all asi,
                         xx_crm_exp_site_master MASTER
                   WHERE p.party_id = ps.party_id
                     AND p.attribute13 = 'CUSTOMER'
                     AND ac.party_id = p.party_id
                     AND asi.party_site_id(+) = ps.party_site_id
                     AND ps.party_site_id = MASTER.party_site_id
                     AND asi.party_site_id IS NULL;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;

      FOR rec IN cur_account
      LOOP
         BEGIN
            -- Onetime
            -- sfdcnotaops - 73326682677
            INSERT INTO xxod_hz_summary
                        (batch_id, attribute1, attribute2,
                         attribute3
                        )
                 VALUES (-73326682677, rec.party_id, rec.party_site_id,
                         rec.tmp_rowid
                        );

            DELETE FROM xx_crm_exp_site_master
                  WHERE ROWID = rec.tmp_rowid;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         IF (p_commit = 'Y')
         THEN
            COMMIT;
         END IF;
      END LOOP;

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Customer Update:' || SQLERRM;
   END sp_del_notaops_site_master;

   PROCEDURE sp_ins_del_site_master (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_account (v_summary_id NUMBER)
      IS
         SELECT          /*+ PARALLEL (A,4) PARALLEL (B,4) */
                DISTINCT attribute1 party_site_id, a.ROWID tmp_rowid
                    FROM xxod_hz_summary a
                   WHERE a.summary_id = v_summary_id;

      l_account_id                NUMBER;
      lc_end_date                 DATE;
      v_profile_sfdc_value        VARCHAR2 (100);
      v_profile_sfdc_operation    VARCHAR2 (100);
      v_profile_sfdc_summary_id   VARCHAR2 (100);
      v_cnt                       NUMBER;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      lc_end_date :=
           TO_DATE (fnd_profile.VALUE ('XX_CRM_SFDC_CUST_CONV_END_DATE'),
                    'MM/DD/YYYY HH24:MI:SS'
                   )
         - (5 / 1440);
      v_profile_sfdc_value :=
                         fnd_profile.VALUE ('XX_CRM_SFDC_INS_DEL_SITE_MASTER');
      v_profile_sfdc_operation :=
         TRIM (SUBSTR (v_profile_sfdc_value,
                       INSTR (v_profile_sfdc_value, '|', 1) + 1
                      )
              );
      v_profile_sfdc_summary_id :=
         TRIM (SUBSTR (v_profile_sfdc_value,
                       1,
                       INSTR (v_profile_sfdc_value, '|', 1) - 1
                      )
              );

      IF v_profile_sfdc_operation = 'INSERT'
      THEN
         FOR s IN cur_account (v_profile_sfdc_summary_id)
         LOOP
            SELECT COUNT (*)
              INTO v_cnt
              FROM hz_party_sites a
             WHERE a.party_site_id = s.party_site_id;

            IF v_cnt <> 0
            THEN
               BEGIN
                  SELECT party_site_id
                    INTO l_account_id
                    FROM xx_crm_exp_site_master
                   WHERE party_site_id = s.party_site_id;

                  UPDATE xx_crm_exp_site_master
                     SET last_update_date = lc_end_date
                   WHERE party_site_id = l_account_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     INSERT INTO xx_crm_exp_site_master
                                 (party_site_id, creation_date,
                                  last_update_date, created_by,
                                  last_updated_by
                                 )
                          VALUES (s.party_site_id, lc_end_date,
                                  lc_end_date, -1,
                                  -1
                                 );
               END;
            END IF;

            IF (p_commit = 'Y')
            THEN
               COMMIT;
            END IF;
         END LOOP;
      END IF;

---------------------------
      IF v_profile_sfdc_operation = 'DELETE'
      THEN
         FOR s IN cur_account (v_profile_sfdc_summary_id)
         LOOP
            DELETE FROM xx_crm_exp_site_master MASTER
                  WHERE MASTER.party_site_id = s.party_site_id;

            IF SQL%ROWCOUNT <> 0
            THEN
               UPDATE xxod_hz_summary
                  SET attribute7 = 'COMPLETED'
                WHERE ROWID = s.tmp_rowid;
            END IF;
         END LOOP;
      END IF;

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Customer Update:' || SQLERRM;
   END sp_ins_del_site_master;

   PROCEDURE sp_sfdc_hz_orig_system_ref (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR sfdc_map (summid NUMBER)
      IS
         SELECT ROWID tmp_rowid, account_orig_system_reference, party_id
           FROM xxod_hz_summary
          WHERE summary_id = summid;

      l_orig_system_reference     hz_orig_system_ref_pub.orig_sys_reference_rec_type;
      l_count                     NUMBER;
      l_count_verification        NUMBER;
      l_return_status             VARCHAR2 (20);
      l_msg_count                 NUMBER;
      l_msg_data                  VARCHAR2 (200);
      l_success_count             NUMBER                                 := 0;
      l_error_count               NUMBER                                 := 0;
      l_summid                    NUMBER;
      v_profile_sfdc_value        VARCHAR2 (100);
      v_profile_sfdc_operation    VARCHAR2 (100);
      v_profile_sfdc_summary_id   VARCHAR2 (100);
      v_cnt                       NUMBER;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      v_profile_sfdc_value :=
                        fnd_profile.VALUE ('XX_CRM_SFDC_INS_DEL_SITE_MASTER');
      v_profile_sfdc_summary_id :=
         TRIM (SUBSTR (v_profile_sfdc_value,
                       1,
                       INSTR (v_profile_sfdc_value, '|', 1) - 1
                      )
              );
      fnd_file.put_line (fnd_file.LOG, v_profile_sfdc_summary_id);
      fnd_file.put_line (fnd_file.LOG, v_profile_sfdc_value);

      FOR s IN sfdc_map (v_profile_sfdc_summary_id)
      LOOP
--fnd_file.put_line (fnd_file.log,s.party_id);
         l_orig_system_reference.owner_table_name := 'HZ_PARTIES';
         l_orig_system_reference.owner_table_id := s.party_id;
         l_orig_system_reference.orig_system := 'SFDC';
         l_orig_system_reference.orig_system_reference :=
                                              s.account_orig_system_reference;
         l_orig_system_reference.status := 'A';
         l_orig_system_reference.start_date_active := SYSDATE;
         l_orig_system_reference.created_by_module := 'SFDCDataCorr';

         SELECT COUNT (1)
           INTO l_count
           FROM hz_orig_sys_references
          WHERE orig_system = 'SFDC'
            AND owner_table_name = 'HZ_PARTIES'
            AND status = 'A'
            AND orig_system_reference = s.account_orig_system_reference;

         IF l_count = 0
         THEN
            hz_orig_system_ref_pub.create_orig_system_reference
                        (p_orig_sys_reference_rec      => l_orig_system_reference,
                         x_return_status               => l_return_status,
                         x_msg_count                   => l_msg_count,
                         x_msg_data                    => l_msg_data
                        );

            IF l_return_status = 'S'
            THEN
               l_success_count := l_success_count + 1;
            ELSE
               l_error_count := l_error_count + 1;
            END IF;

            SELECT COUNT (1)
              INTO l_count_verification
              FROM hz_orig_sys_references
             WHERE orig_system = 'SFDC'
               AND owner_table_name = 'HZ_PARTIES'
               AND orig_system_reference = s.account_orig_system_reference;

            IF l_count_verification = 0
            THEN
               UPDATE xxod_hz_summary
                  SET attribute1 = 'Issue- Not Inserted'
                WHERE ROWID = s.tmp_rowid;
            ELSE
               UPDATE xxod_hz_summary
                  SET attribute1 = 'Suceessfuly Inserted'
                WHERE ROWID = s.tmp_rowid;
            END IF;
         ELSE
            UPDATE xxod_hz_summary
               SET attribute1 = 'Do not Process'
             WHERE ROWID = s.tmp_rowid;
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, l_success_count);
      fnd_file.put_line (fnd_file.LOG, l_error_count);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Customer Update:' || SQLERRM;
   END sp_sfdc_hz_orig_system_ref;

   PROCEDURE sp_sfdc_dup_party (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      v_errbuf              VARCHAR2 (4000);
      par_rec               hz_party_v2pub.party_rec_type;
      org_rec               hz_party_v2pub.organization_rec_type;
      l_application_id      NUMBER;
      l_responsibility_id   NUMBER;
      l_user_id             NUMBER;
      ln_error              NUMBER                                       := 0;
      l_dup_osr             hz_orig_sys_references.orig_system_reference%TYPE;
      ln_total              NUMBER                                       := 0;
      l_orig_objs           hz_orig_system_ref_pub.orig_sys_reference_rec_type;
      l_ovn                 hz_orig_sys_references.object_version_number%TYPE;
      l_msg_count           NUMBER;
      l_msg_data            VARCHAR2 (4000);
      l_error_message       VARCHAR2 (4000);
      l_return_status       VARCHAR2 (100);
      l_osr_count           NUMBER                                       := 0;
      v_message             VARCHAR2 (4000);
      v_process             NUMBER                                       := 1;

      CURSOR dup_osr_cur
      IS
         SELECT   /*+ parallel(p,4) */
                  orig_system_reference, COUNT (*) dup_cnt
             FROM hz_orig_sys_references p
            WHERE orig_system = 'SFDC'
              AND owner_table_name = 'HZ_PARTIES'
              AND status = 'A'
              AND end_date_active IS NULL
         GROUP BY orig_system_reference
           HAVING COUNT (*) > 1;

      CURSOR dedup_cur (v_dup_osr VARCHAR2)
      IS
         SELECT orig_system_reference, party_id, object_version_number,
                start_date_active
           FROM (SELECT orig_system_reference, owner_table_id party_id,
                        object_version_number, start_date_active,
                        ROW_NUMBER () OVER (PARTITION BY orig_system_reference ORDER BY party_id DESC)
                                                                    record_id
                   FROM hz_orig_sys_references p
                  WHERE orig_system = 'SFDC'
                    AND owner_table_name = 'HZ_PARTIES'
                    AND status = 'A'
                    AND end_date_active IS NULL
                    AND orig_system_reference = v_dup_osr)
          WHERE record_id <> 1;

      CURSOR sites_cur (v_party_id NUMBER)
      IS
         SELECT party_site_id
           FROM hz_party_sites
          WHERE status = 'A' AND party_id = v_party_id;

      CURSOR profile_cur (v_party_id NUMBER)
      IS
         SELECT organization_profile_id
           FROM hz_organization_profiles
          WHERE status = 'A' AND party_id = v_party_id;
   BEGIN
      BEGIN
         v_errbuf := 'Fetching applnID and respID ';

         SELECT application_id, responsibility_id
           INTO l_application_id, l_responsibility_id
           FROM fnd_responsibility_tl
          WHERE responsibility_name = 'OD (US) Customer Conversion'
            AND LANGUAGE = USERENV ('LANG');

         v_errbuf := 'Fetching userID ';

         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE user_name = 'ODCDH';

         v_errbuf := 'Doing apps init ';
         fnd_global.apps_initialize (l_user_id,
                                     l_responsibility_id,
                                     l_application_id
                                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line ('Error in Apps Initialize');
            RAISE;
      END;

      FOR c_dup_osr IN dup_osr_cur
      LOOP
         BEGIN
            l_dup_osr := c_dup_osr.orig_system_reference;
            l_osr_count := l_osr_count + 1;

            FOR c_dedup IN dedup_cur (l_dup_osr)
            LOOP
               ln_total := ln_total + 1;
               org_rec := NULL;
               par_rec := NULL;
               v_message := NULL;
               v_process := 1;
               ----------------OSR clean up start ------------
               l_orig_objs.owner_table_name := 'HZ_PARTIES';
               l_orig_objs.owner_table_id := c_dedup.party_id;
               l_orig_objs.orig_system := 'SFDC';
               l_orig_objs.orig_system_reference := l_dup_osr;
               l_orig_objs.status := 'I';
               l_orig_objs.start_date_active := c_dedup.start_date_active;
               l_orig_objs.end_date_active := c_dedup.start_date_active;
               l_ovn := c_dedup.object_version_number;
               v_errbuf := ' inactivating wrong OSR ';
               hz_orig_system_ref_pub.update_orig_system_reference
                                    (p_init_msg_list               => fnd_api.g_false,
                                     p_orig_sys_reference_rec      => l_orig_objs,
                                     p_object_version_number       => l_ovn,
                                     x_return_status               => l_return_status,
                                     x_msg_count                   => l_msg_count,
                                     x_msg_data                    => l_msg_data
                                    );

               --dbms_output.put_line(l_dup_osr ||' - Status of Inactivate wrong OSR: '|| l_return_status);
               IF (l_msg_count > 1)
               THEN
                  FOR i IN 1 .. fnd_msg_pub.count_msg
                  LOOP
                     l_error_message :=
                           l_error_message
                        || fnd_msg_pub.get (i, p_encoded => fnd_api.g_false);
                  END LOOP;

                  fnd_file.put_line (fnd_file.LOG, l_error_message);
                  v_message :=
                     SUBSTR (v_message || '-----' || l_error_message, 1, 2000);
               ELSE
                  l_error_message := l_msg_data;
                  v_message :=
                     SUBSTR (v_message || '-----' || l_error_message, 1,
                             2000);
               END IF;

               ----------------party clean up start ------------
               v_errbuf := ' inactivating partyID: ' || c_dedup.party_id;

               UPDATE hz_parties
                  SET status = 'I',
                      last_updated_by = -1,
                      last_update_date = '01-JAN-2001'
                WHERE party_id = c_dedup.party_id
                  AND NVL (attribute13, 'PROSPECT') <> 'CUSTOMER';

               IF SQL%ROWCOUNT = 0
               THEN
                  v_message :=
                     SUBSTR (   v_message
                             || '-----'
                             || 'HZ_PARTIES '
                             || c_dedup.party_id
                             || ' is not Updated',
                             1,
                             2000
                            );
               END IF;

               IF SQL%ROWCOUNT > 0
               THEN
                  v_message :=
                     SUBSTR (   v_message
                             || '-----'
                             || 'HZ_PARTIES '
                             || c_dedup.party_id
                             || ' is Updated',
                             1,
                             2000
                            );
                  v_process := 0;
               END IF;

               IF v_process = 0
               THEN
                  FOR c_sites IN sites_cur (c_dedup.party_id)
                  LOOP
                     UPDATE hz_party_sites
                        SET status = 'I',
                            last_updated_by = -1,
                            last_update_date = '01-JAN-2001'
                      WHERE party_site_id = c_sites.party_site_id
                        AND status = 'A';

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_message :=
                           SUBSTR (   v_message
                                   || '-----'
                                   || 'HZ_PARTY_SITES '
                                   || c_sites.party_site_id
                                   || ' is not Updated',
                                   1,
                                   2000
                                  );
                     END IF;

                     IF SQL%ROWCOUNT > 0
                     THEN
                        v_message :=
                           SUBSTR (   v_message
                                   || '-----'
                                   || 'HZ_PARTY_SITES '
                                   || c_sites.party_site_id
                                   || ' is Updated',
                                   1,
                                   2000
                                  );
                     END IF;
                  END LOOP;
               END IF;

               IF v_process = 0
               THEN
                  FOR c_profile IN profile_cur (c_dedup.party_id)
                  LOOP
                     UPDATE hz_organization_profiles
                        SET status = 'I',
                            last_updated_by = -1,
                            last_update_date = '01-JAN-2001'
                      WHERE organization_profile_id =
                                             c_profile.organization_profile_id
                        AND status = 'A';

                     IF SQL%ROWCOUNT = 0
                     THEN
                        v_message :=
                           SUBSTR (   v_message
                                   || '-----'
                                   || 'HZ_ORGANIZATION_PROFILES '
                                   || c_profile.organization_profile_id
                                   || ' is not Updated',
                                   1,
                                   2000
                                  );
                     END IF;

                     IF SQL%ROWCOUNT > 0
                     THEN
                        v_message :=
                           SUBSTR (   v_message
                                   || '-----'
                                   || 'HZ_ORGANIZATION_PROFILES '
                                   || c_profile.organization_profile_id
                                   || ' is Updated',
                                   1,
                                   2000
                                  );
                     END IF;
                  END LOOP;
               END IF;

               fnd_file.put_line (fnd_file.LOG, v_message);
            END LOOP;

            --dedup_cur thru each OSR record for all associated parties
            fnd_file.put_line (fnd_file.LOG, l_error_message);

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               ln_error := ln_error + 1;
               DBMS_OUTPUT.put_line (   SQLERRM
                                     || ' processing '
                                     || l_dup_osr
                                     || ' at '
                                     || v_errbuf
                                    );
         END;
      END LOOP;                                                  --dup_osr_cur

      INSERT INTO xxod_hz_summary
                  (summary_id, batch_id, creation_date, attribute1,
                   attribute2
                  )
           VALUES (-71717171717171, -717171717171, SYSDATE, l_osr_count,
                   ln_total
                  );

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;

      fnd_file.put_line (fnd_file.LOG, 'Total OSRs: ' || l_osr_count);
      fnd_file.put_line (fnd_file.LOG,
                            'Total Records: '
                         || ln_total
                         || ', '
                         || 'Error Records: '
                         || ln_error
                        );
   END sp_sfdc_dup_party;

   PROCEDURE sp_dup_billdocs (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      v_errbuf          VARCHAR2 (4000);
      l_error_message   VARCHAR2 (4000);
      l_return_status   VARCHAR2 (100);
      v_message         VARCHAR2 (4000);
      v_process         NUMBER          := 1;
      ln_total          NUMBER          := 0;

      CURSOR dup_billdocs_cur
      IS
         SELECT   *
             FROM (SELECT cust_account_id, creation_date, created_by,
                          c_ext_attr3, extension_id,
                          ROW_NUMBER () OVER (PARTITION BY cust_account_id ORDER BY DECODE
                                                                 (created_by,
                                                                  '72319', '999999999',
                                                                  '58590', '999999999',
                                                                  '70959', '999999999',
                                                                  created_by
                                                                 )) record_id
                     -- always clean up record created by Batch process first
                   FROM   xx_cdh_cust_acct_ext_b
                    WHERE cust_account_id IN (
                             SELECT   cust_account_id
                                 FROM xx_cdh_cust_acct_ext_b cae
                                WHERE c_ext_attr2 = 'Y'
                                  AND NVL (c_ext_attr13, 'DB') = 'DB'
                                  AND TRUNC (SYSDATE) BETWEEN NVL
                                                                 (d_ext_attr1,
                                                                  SYSDATE - 1
                                                                 )
                                                          AND NVL
                                                                 (d_ext_attr2,
                                                                  SYSDATE + 1
                                                                 )
                                  AND attr_group_id = 166
                                  AND c_ext_attr16 = 'COMPLETE'
                               HAVING COUNT (*) > 1
                             GROUP BY cust_account_id)
                      AND attr_group_id = 166)
            WHERE record_id <> 1
         ORDER BY cust_account_id;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;

      FOR c_dup_billdocs IN dup_billdocs_cur
      LOOP
         BEGIN
            v_message := NULL;
            v_process := 1;
            v_message :=
               SUBSTR (   v_message
                       || '-----'
                       || 'CUST_ACCOUNT_ID '
                       || c_dup_billdocs.cust_account_id
                       || ' CREATION_DATE '
                       || c_dup_billdocs.creation_date
                       || ' CREATED_BY '
                       || c_dup_billdocs.created_by
                       || ' C_EXT_ATTR3 '
                       || c_dup_billdocs.c_ext_attr3
                       || ' EXTENSION_ID '
                       || c_dup_billdocs.extension_id,
                       1,
                       2000
                      );

            UPDATE xx_cdh_cust_acct_ext_b
               SET attr_group_id = 243                          --OLD_BILLDOCS
             WHERE extension_id = c_dup_billdocs.extension_id;

            IF SQL%ROWCOUNT = 0
            THEN
               v_message :=
                  SUBSTR (   v_message
                          || '-----'
                          || 'XX_CDH_CUST_ACCT_EXT_B '
                          || c_dup_billdocs.extension_id
                          || ' is not Updated',
                          1,
                          2000
                         );
            END IF;

            IF SQL%ROWCOUNT > 0
            THEN
               v_message :=
                  SUBSTR (   v_message
                          || '-----'
                          || 'XX_CDH_CUST_ACCT_EXT_B '
                          || c_dup_billdocs.extension_id
                          || ' is Updated',
                          1,
                          2000
                         );
               v_process := 0;
            END IF;

            IF v_process = 0
            THEN
               UPDATE xx_cdh_cust_acct_ext_tl
                  SET attr_group_id = 243                       --OLD_BILLDOCS
                WHERE extension_id = c_dup_billdocs.extension_id;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_message :=
                     SUBSTR (   v_message
                             || '-----'
                             || 'XX_CDH_CUST_ACCT_EXT_TL '
                             || c_dup_billdocs.extension_id
                             || ' is not Updated',
                             1,
                             2000
                            );
               END IF;

               IF SQL%ROWCOUNT > 0
               THEN
                  v_message :=
                     SUBSTR (   v_message
                             || '-----'
                             || 'XX_CDH_CUST_ACCT_EXT_TL '
                             || c_dup_billdocs.extension_id
                             || ' is Updated',
                             1,
                             2000
                            );
                  v_process := 0;
               END IF;
            END IF;

            fnd_file.put_line (fnd_file.LOG, v_message);

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;

            ln_total := ln_total + 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               x_retcode := 2;
               x_errbuf :=
                       'Unexpected Error during Bill Docs Update:' || SQLERRM;
               fnd_file.put_line (fnd_file.LOG, x_errbuf);
         END;
      END LOOP;    --dedup_cur thru each OSR record for all associated parties

      INSERT INTO xxod_hz_summary
                  (summary_id, batch_id, creation_date, attribute1
                  )
           VALUES (-81818181818181, -818181818181, SYSDATE, ln_total
                  );

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;

      fnd_file.put_line (fnd_file.LOG, 'Total Records: ' || ln_total);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Bill Docs Update:' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END sp_dup_billdocs;

   PROCEDURE sp_wc_collector_id (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_collector_id
      IS
         SELECT acct.cust_account_id, acct.account_number,
                SUBSTR (hcsa.orig_system_reference, 1, 14) aops_number,
                (SELECT NAME
                   FROM ar_collectors
                  WHERE collector_id = prof1.collector_id) acct_collector,
                (SELECT NAME
                   FROM ar_collectors
                  WHERE collector_id = prof2.collector_id) billto_collector,
                prof1.collector_id acct_collector_id,
                prof2.collector_id billto_collector_id,
                prof1.last_update_date acct_last_update_date,
                prof2.last_update_date billto_last_update_date,
                hcus.cust_acct_site_id, hcus.site_use_id,
                prof1.ROWID tmp_rowid
           FROM hz_cust_accounts acct,
                xx_crm_wcelg_cust elg,
                hz_customer_profiles prof1,
                hz_customer_profiles prof2,
                hz_cust_site_uses_all hcus,
                hz_cust_acct_sites_all hcsa
          WHERE acct.cust_account_id = prof1.cust_account_id
            AND acct.cust_account_id = prof2.cust_account_id
            AND acct.cust_account_id = elg.cust_account_id
            AND acct.status = 'A'
            AND prof1.cust_account_id = prof2.cust_account_id
            AND prof1.site_use_id IS NULL
            AND prof2.site_use_id IS NOT NULL
            AND prof2.site_use_id = hcus.site_use_id
            AND hcus.cust_acct_site_id = hcsa.cust_acct_site_id
            AND prof1.collector_id <> prof2.collector_id;

      v_message         VARCHAR2 (2000);
      l_total_count     NUMBER          := 0;
      l_success_count   NUMBER          := 0;
      l_error_count     NUMBER          := 0;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;

      FOR rec_collector_id IN cur_collector_id
      LOOP
         l_total_count := l_total_count + 1;
         v_message :=
               'Cust Account Id'
            || rec_collector_id.cust_account_id
            || 'Account Number '
            || rec_collector_id.account_number
            || ' AOPS Number '
            || rec_collector_id.aops_number
            || 'Acct Collector '
            || rec_collector_id.acct_collector
            || ' Billto Collector '
            || rec_collector_id.billto_collector
            || ' Acct Collector Id '
            || rec_collector_id.acct_collector_id
            || ' Billto Collector Id '
            || rec_collector_id.billto_collector_id;

         UPDATE hz_customer_profiles
            SET collector_id = rec_collector_id.billto_collector_id,
                last_updated_by = -1,
                last_update_date = SYSDATE
          WHERE ROWID = rec_collector_id.tmp_rowid
            AND collector_id = rec_collector_id.acct_collector_id;

         IF SQL%ROWCOUNT = 1
         THEN
            v_message := v_message || ' ---- Successfully updated.';
            l_success_count := l_success_count + 1;
            fnd_file.put_line (fnd_file.LOG, v_message);
         END IF;

         IF SQL%ROWCOUNT = 0
         THEN
            v_message := v_message || ' ---- Already updated.';
            fnd_file.put_line (fnd_file.LOG, v_message);
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, ' Total Records ' || l_total_count);
      fnd_file.put_line (fnd_file.LOG,
                         ' Sucessful Records ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.LOG, ' Error Records ' || l_error_count);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Collector Update:' || SQLERRM;
   END sp_wc_collector_id;

   PROCEDURE sp_insert_epdf (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
/*
l_subject changes by Devendra P as per ePDF enhacement
*/
      v_errbuf                    VARCHAR2 (4000);
      l_error_message             VARCHAR2 (4000);
      l_return_status             VARCHAR2 (100);
      v_message                   VARCHAR2 (4000);
      l_individual_consolidate    VARCHAR2 (1000);
      l_subject                   VARCHAR2 (1000);
      l_subject_invoice           VARCHAR2 (1000);
      l_subject_cons              VARCHAR2 (1000);
      ln_count                    NUMBER          := 0;
      ln_success                  NUMBER          := 0;
      l_field_cons_inv            VARCHAR2 (20);
      l_field_account             VARCHAR2 (20);
      l_field_docid               VARCHAR2 (20);
      l_field_billdate            VARCHAR2 (20);
      l_field_invoice             VARCHAR2 (20);
      l_field_cons                VARCHAR2 (20);

      CURSOR missing_epdf
      IS
         SELECT cust_account_id cust_acc_id, n_ext_attr2 cust_doc_id
           FROM xx_cdh_cust_acct_ext_b
          WHERE attr_group_id = 166
            AND c_ext_attr16 = 'COMPLETE'
            AND SYSDATE BETWEEN d_ext_attr1 AND NVL (d_ext_attr2, SYSDATE + 1)
            AND c_ext_attr3 = 'ePDF'
         MINUS
         SELECT cust_account_id cust_acc_id, cust_doc_id
           FROM xx_cdh_ebl_main;

      ln_ebl_file_name_id         NUMBER;
      l_standard_message          VARCHAR2 (4000);
      l_standard_sign             VARCHAR2 (400);
      l_standard_disclaim         VARCHAR2 (4000);
      lc_individual_consolidate   VARCHAR2 (400);
   BEGIN
      x_retcode := 0;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SUB_CONSOLI'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.'
                )
        INTO l_subject_cons
        FROM DUAL;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SUB_STAND'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.'
                )
        INTO l_subject_invoice
        FROM DUAL;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SUB_STAND'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.'
                )
        INTO l_subject_invoice
        FROM DUAL;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_MSG'),
                 'Dear Customer,<br><br>Attached is your electronic billing for &DATEFROM to &DATETO.<br>For questions regarding billing format, please contact electronicbilling@officedepot.com.<br>For account related questions, please call 1-800-721-6592.'
                )
        INTO l_standard_message
        FROM DUAL;

      SELECT NVL (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SIGN'),
                  'Thank You,<br>Office Depot'
                 )
        INTO l_standard_sign
        FROM DUAL;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_DISCLAIM'),
                 'Disclaimer:  The attached file is construed as a legally binding document between Office DEPOT and  its customer, and is not intended for anyone other than the intended recipient.  If you are not the intended recipient, please forward this'
                )
        INTO l_standard_disclaim
        FROM DUAL;

      SELECT field_id
        INTO l_field_account
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name = 'Account Number';

      SELECT field_id
        INTO l_field_docid
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Customer_DocID';

      SELECT field_id
        INTO l_field_billdate
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Bill To Date';

      SELECT field_id
        INTO l_field_invoice
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Invoice Number';

      SELECT field_id
        INTO l_field_cons
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Consolidated Bill Number';

      FOR l IN missing_epdf
      LOOP
         ln_count := ln_count + 1;

         -- Insert Data into EBIL Main
         BEGIN
            SAVEPOINT cust_start;
            xx_cdh_ebl_main_pkg.insert_row
                                  (p_cust_doc_id                    => l.cust_doc_id
                                                                                    -- Cust_Doc_Id (Using Sequence)
            ,
                                   p_cust_account_id                => l.cust_acc_id
                                                                                    -- Cust_Account_Id
            ,
                                   p_ebill_transmission_type        => 'EMAIL'
                                                                              -- Transmission Method
            ,
                                   p_ebill_associate                => '10'
                                                                           -- eBill Associate
            ,
                                   p_file_processing_method         => '03'
                                                                           -- File Processing Method
            ,
                                   p_file_name_ext                  => 'PDF'
                                                                            -- File Name Extension
            ,
                                   p_max_file_size                  => 10,
                                   p_max_transmission_size          => 10,
                                   p_zip_required                   => 'N',
                                   p_zipping_utility                => NULL,
                                   p_zip_file_name_ext              => NULL,
                                   p_od_field_contact               => NULL,
                                   p_od_field_contact_email         => NULL,
                                   p_od_field_contact_phone         => NULL,
                                   p_client_tech_contact            => NULL,
                                   p_client_tech_contact_email      => NULL,
                                   p_client_tech_contact_phone      => NULL,
                                   p_file_name_seq_reset            => NULL,
                                   p_file_next_seq_number           => NULL,
                                   p_file_seq_reset_date            => SYSDATE,
                                   p_file_name_max_seq_number       => NULL,
                                   p_attribute1                     => 'CORE',
                                   p_last_update_date               => SYSDATE,
                                   p_last_updated_by                => fnd_global.user_id,
                                   p_creation_date                  => SYSDATE,
                                   p_created_by                     => fnd_global.user_id,
                                   p_last_update_login              => fnd_global.login_id
                                  );
            -- Insert Data into Transaction Details
            lc_individual_consolidate := NULL;
            l_field_cons_inv := NULL;

            BEGIN
               SELECT c_ext_attr1
                 INTO l_individual_consolidate
                 FROM xx_cdh_cust_acct_ext_b
                WHERE n_ext_attr2 = l.cust_doc_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  lc_individual_consolidate := NULL;
            END;

            IF l_individual_consolidate = 'Invoice'
            THEN
               l_subject := l_subject_invoice;
               l_field_cons_inv := l_field_invoice;
            ELSIF l_individual_consolidate = 'Consolidated Bill'
            THEN
               l_subject := l_subject_cons;
               l_field_cons_inv := l_field_cons;
            ELSE
               l_subject :=
                  'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.';
               l_field_cons_inv := l_field_invoice;
            END IF;

-- Missing check.. Already present or not...
            xx_cdh_ebl_trans_dtl_pkg.insert_row
                               (p_cust_doc_id                   => l.cust_doc_id,
                                p_email_subject                 => l_subject,
                                p_email_std_message             => l_standard_message,
                                p_email_custom_message          => NULL,
                                p_email_signature               => l_standard_sign,
                                p_email_std_disclaimer          => l_standard_disclaim,
                                p_email_logo_required           => 'Y',
                                p_email_logo_file_name          => 'OFFICEDEPOT',
                                p_ftp_cust_contact_name         => NULL,
                                p_ftp_cust_contact_email        => NULL,
                                p_ftp_cust_contact_phone        => NULL,
                                p_ftp_direction                 => NULL,
                                p_ftp_transfer_type             => NULL,
                                p_ftp_destination_site          => NULL,
                                p_ftp_destination_folder        => NULL,
                                p_ftp_user_name                 => NULL,
                                p_ftp_password                  => NULL,
                                p_ftp_pickup_server             => NULL,
                                p_ftp_pickup_folder             => NULL,
                                p_ftp_notify_customer           => NULL,
                                p_ftp_cc_emails                 => NULL,
                                p_ftp_email_sub                 => NULL,
                                p_ftp_email_content             => NULL,
                                p_ftp_send_zero_byte_file       => NULL,
                                p_ftp_zero_byte_file_text       => NULL,
                                p_ftp_zero_byte_notifi_txt      => NULL,
                                p_cd_file_location              => NULL,
                                p_cd_send_to_address            => NULL,
                                p_comments                      => NULL,
                                p_last_update_date              => SYSDATE,
                                p_last_updated_by               => fnd_global.user_id,
                                p_creation_date                 => SYSDATE,
                                p_created_by                    => fnd_global.user_id,
                                p_last_update_login             => fnd_global.login_id
                               );

            -- Insert Data into File
            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO ln_ebl_file_name_id
              FROM DUAL;

-- Missing check.. Already present or not...
-- Missing sequence number 20, 30, 40...
            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                                   (p_ebl_file_name_id         => ln_ebl_file_name_id
                                                                                     -- Using Sequence
            ,
                                    p_cust_doc_id              => l.cust_doc_id,
                                    p_file_name_order_seq      => 10
                                                                    -- 10 or 20 or 30 -- Sequence_Number
            ,
                                    p_field_id                 => l_field_account
                                                                                 -- 10003(account_number), 10118, 10007
            ,
                                    p_constant_value           => NULL,
                                    p_default_if_null          => NULL,
                                    p_comments                 => NULL,
                                    p_last_update_date         => SYSDATE,
                                    p_last_updated_by          => fnd_global.user_id,
                                    p_creation_date            => SYSDATE,
                                    p_created_by               => fnd_global.user_id,
                                    p_last_update_login        => fnd_global.login_id
                                   );

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO ln_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                                   (p_ebl_file_name_id         => ln_ebl_file_name_id
                                                                                     -- Using Sequence
            ,
                                    p_cust_doc_id              => l.cust_doc_id,
                                    p_file_name_order_seq      => 20
                                                                    -- 10 or 20 or 30 -- Sequence_Number
            ,
                                    p_field_id                 => l_field_docid
                                                                               -- 10003(account_number), 10118, 10007
            ,
                                    p_constant_value           => NULL,
                                    p_default_if_null          => NULL,
                                    p_comments                 => NULL,
                                    p_last_update_date         => SYSDATE,
                                    p_last_updated_by          => fnd_global.user_id,
                                    p_creation_date            => SYSDATE,
                                    p_created_by               => fnd_global.user_id,
                                    p_last_update_login        => fnd_global.login_id
                                   );

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO ln_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                                   (p_ebl_file_name_id         => ln_ebl_file_name_id
                                                                                     -- Using Sequence
            ,
                                    p_cust_doc_id              => l.cust_doc_id,
                                    p_file_name_order_seq      => 30
                                                                    -- 10 or 20 or 30 -- Sequence_Number
            ,
                                    p_field_id                 => l_field_billdate
                                                                                  -- 10003(account_number), 10118, 10007
            ,
                                    p_constant_value           => NULL,
                                    p_default_if_null          => NULL,
                                    p_comments                 => NULL,
                                    p_last_update_date         => SYSDATE,
                                    p_last_updated_by          => fnd_global.user_id,
                                    p_creation_date            => SYSDATE,
                                    p_created_by               => fnd_global.user_id,
                                    p_last_update_login        => fnd_global.login_id
                                   );

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO ln_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                                   (p_ebl_file_name_id         => ln_ebl_file_name_id
                                                                                     -- Using Sequence
            ,
                                    p_cust_doc_id              => l.cust_doc_id,
                                    p_file_name_order_seq      => 40
                                                                    -- 10 or 20 or 30 -- Sequence_Number
            ,
                                    p_field_id                 => l_field_cons_inv
                                                                                  -- 10003(account_number), 10118, 10007
            ,
                                    p_constant_value           => NULL,
                                    p_default_if_null          => NULL,
                                    p_comments                 => NULL,
                                    p_last_update_date         => SYSDATE,
                                    p_last_updated_by          => fnd_global.user_id,
                                    p_creation_date            => SYSDATE,
                                    p_created_by               => fnd_global.user_id,
                                    p_last_update_login        => fnd_global.login_id
                                   );

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;

            ln_success := ln_success + 1;
            fnd_file.put_line (fnd_file.LOG,
                               'Success, cust_account_id:,' || l.cust_acc_id
                              );
         EXCEPTION
            WHEN OTHERS
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                     'Error occurred for cust_account_id:,'
                                  || l.cust_acc_id
                                  || ','
                                  || SQLERRM
                                 );
               ROLLBACK TO cust_start;
               x_retcode := 1;
         END;
      END LOOP;

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;

      fnd_file.put_line (fnd_file.LOG, CHR (13) || 'Summary: ' || CHR (13));
      fnd_file.put_line (fnd_file.LOG,
                         'Total number of accounts corrected :' || ln_count
                        );
      fnd_file.put_line (fnd_file.LOG,
                            'Total number of accounts errored :'
                         || (ln_count - ln_success)
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during Bill Docs Update:' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END sp_insert_epdf;

   PROCEDURE sp_epdf_upd_transmission_dtl (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_upd_transmission_dtl
      IS
         SELECT   xcetd.ROWID tmp_rowid, hca.cust_account_id,
                  hca.account_number,
                  SUBSTR (orig_system_reference, 1, 8) aops_number,
                  xcetd.cust_doc_id,
                  xccaeb.c_ext_attr1 individual_consolidate,
                  xcetd.email_subject
             FROM xx_cdh_cust_acct_ext_b xccaeb,
                  xx_cdh_ebl_transmission_dtl xcetd,
                  hz_cust_accounts hca
            WHERE xccaeb.n_ext_attr2 = xcetd.cust_doc_id
              AND xccaeb.cust_account_id = hca.cust_account_id
              AND xccaeb.c_ext_attr1 IN ('Invoice', 'Consolidated Bill')
              AND xccaeb.attr_group_id = 166
              --AND xccaeb.c_ext_attr2='Y'
              AND SYSDATE BETWEEN xccaeb.d_ext_attr1
                              AND NVL (xccaeb.d_ext_attr2, SYSDATE + 1)
              AND xccaeb.c_ext_attr16 = 'COMPLETE'
              AND xccaeb.c_ext_attr3 IN ('ePDF', 'eXLS', 'eTXT')
         ORDER BY xccaeb.c_ext_attr1;

      l_message             VARCHAR2 (2000);
      l_total_count         NUMBER          := 0;
      l_success_count       NUMBER          := 0;
      l_error_count         NUMBER          := 0;
      l_subject             VARCHAR2 (240);
      l_subject_cons        VARCHAR2 (240);
      l_subject_invoice     VARCHAR2 (240);
      l_already_exist_cnt   NUMBER          := 0;
      l_issue_exist_cnt     NUMBER          := 0;
      l_update_subject      VARCHAR2 (1000)
         := NVL (fnd_profile.VALUE ('XX_UPDATE_BILLDOC_SUBJECT'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO'
                );
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      fnd_file.put_line
              (fnd_file.LOG,
                  'Mismatched Criteria (Profile XX_UPDATE_BILLDOC_SUBJECT) :'
               || l_update_subject
              );

      -- Email Subject
      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SUB_CONSOLI'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.'
                )
        INTO l_subject_cons
        FROM DUAL;

      SELECT NVL
                (fnd_profile.VALUE ('XXOD_EBL_EMAIL_STD_SUB_STAND'),
                 'Your Electronic Billing for the period &DATEFROM to &DATETO for account &AOPSNUMBER.'
                )
        INTO l_subject_invoice
        FROM DUAL;

      FOR rec_transmission_dtl IN cur_upd_transmission_dtl
      LOOP
         l_total_count := l_total_count + 1;
         l_message :=
               'Cust Account Id ,'
            || rec_transmission_dtl.cust_account_id
            || ', Account Number ,'
            || rec_transmission_dtl.account_number
            || ', AOPS Number ,'
            || rec_transmission_dtl.aops_number
            || ', Cust Doc Id ,'
            || rec_transmission_dtl.cust_doc_id
            || ', Individual Consolidate Indicator ,'
            || rec_transmission_dtl.individual_consolidate
            || ', Subject ,'
            || rec_transmission_dtl.individual_consolidate;

         IF rec_transmission_dtl.individual_consolidate = 'Invoice'
         THEN
            l_subject := l_subject_invoice;
         ELSIF rec_transmission_dtl.individual_consolidate =
                                                           'Consolidated Bill'
         THEN
            l_subject := l_subject_cons;
         END IF;

         IF rec_transmission_dtl.email_subject <> l_update_subject
         THEN
            IF rec_transmission_dtl.email_subject = l_subject
            THEN
               l_message := l_message || ', ---- Already updated. ';
               --fnd_file.put_line (fnd_file.log,l_message);
               l_already_exist_cnt := l_already_exist_cnt + 1;
               GOTO do_not_upd_transmission_dtl;
            END IF;

            l_issue_exist_cnt := l_issue_exist_cnt + 1;
            l_message :=
                  l_message
               || ', ---- Issue Records '
               || ' Subject  '
               || rec_transmission_dtl.email_subject;
            fnd_file.put_line (fnd_file.LOG, l_message);
            GOTO do_not_upd_transmission_dtl;
         END IF;

         UPDATE xx_cdh_ebl_transmission_dtl
            SET email_subject = l_subject,
                last_updated_by = -1,
                last_update_date = SYSDATE
          WHERE ROWID = rec_transmission_dtl.tmp_rowid
            AND cust_doc_id = rec_transmission_dtl.cust_doc_id;

         IF SQL%ROWCOUNT <> 0
         THEN
            l_message := l_message || ', ---- Successfully updated.';
            l_success_count := l_success_count + 1;
            fnd_file.put_line (fnd_file.LOG, l_message);
         ELSE
            l_message := l_message || ', ---- Check .';
            fnd_file.put_line (fnd_file.LOG, l_message);
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;

         <<do_not_upd_transmission_dtl>>
         NULL;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, ' Total Records ' || l_total_count);
      fnd_file.put_line (fnd_file.LOG,
                         ' Sucessful Records ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.LOG, ' Error Records ' || l_error_count);
      fnd_file.put_line (fnd_file.LOG,
                         ' Already Present ' || l_already_exist_cnt
                        );
      fnd_file.put_line (fnd_file.LOG, ' Issue Records ' || l_issue_exist_cnt);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf := 'Unexpected Error during subject Update:' || SQLERRM;
   END sp_epdf_upd_transmission_dtl;

   PROCEDURE sp_epdf_ins_file_name_dtl (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_ins_file_name_dtl
      IS
         SELECT   hca.cust_account_id, hca.account_number,
                  SUBSTR (orig_system_reference, 1, 8) aops_number,
                  xccaeb.n_ext_attr2 cust_doc_id,
                  xccaeb.c_ext_attr1 individual_consolidate,
                  DECODE (xccaeb.c_ext_attr1,
                          'Invoice', 10023,
                          'Consolidated Bill', 10005
                         ) field_id,
                  xccaeb.c_ext_attr3 document_type
             FROM xx_cdh_cust_acct_ext_b xccaeb, hz_cust_accounts hca
            WHERE xccaeb.cust_account_id = hca.cust_account_id
              AND xccaeb.c_ext_attr1 IN ('Invoice', 'Consolidated Bill')
              AND xccaeb.attr_group_id = 166
              --AND xccaeb.c_ext_attr2='Y'
              AND SYSDATE BETWEEN xccaeb.d_ext_attr1
                              AND NVL (xccaeb.d_ext_attr2, SYSDATE + 1)
              AND xccaeb.c_ext_attr16 = 'COMPLETE'
              AND xccaeb.c_ext_attr3 IN ('ePDF', 'eXLS', 'eTXT')
         ORDER BY xccaeb.c_ext_attr1;

      l_message                    VARCHAR2 (2000);
      l_total_count                NUMBER          := 0;
      l_success_count              NUMBER          := 0;
      l_error_count                NUMBER          := 0;
      l_already_exist_cnt          NUMBER          := 0;
      l_already_exist_verify_cnt   NUMBER          := 0;
      l_file_name_verify_cnt       NUMBER          := 0;
      l_file_name_order_seq_cnt    NUMBER          := 0;
      l_ebl_file_name_id           NUMBER          := 0;
      l_field_account              VARCHAR2 (20);
      l_field_docid                VARCHAR2 (20);
      l_field_billdate             VARCHAR2 (20);
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;

      SELECT field_id
        INTO l_field_account
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name = 'Account Number';

      SELECT field_id
        INTO l_field_docid
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Customer_DocID';

      SELECT field_id
        INTO l_field_billdate
        FROM xx_cdh_ebilling_fields_v
       WHERE field_name LIKE 'Bill To Date';

      FOR rec_file_name_dtl IN cur_ins_file_name_dtl
      LOOP
         l_total_count := l_total_count + 1;
         l_message :=
               'Cust Account Id ,'
            || rec_file_name_dtl.cust_account_id
            || ', Account Number ,'
            || rec_file_name_dtl.account_number
            || ', AOPS Number ,'
            || rec_file_name_dtl.aops_number
            || ', Cust Doc Id ,'
            || rec_file_name_dtl.cust_doc_id
            || ', Individual Consolidate Indicator ,'
            || rec_file_name_dtl.individual_consolidate
            || ', Document Type ,'
            || rec_file_name_dtl.document_type;

         SELECT COUNT (*)
           INTO l_already_exist_verify_cnt
           FROM xx_cdh_ebl_file_name_dtl
          WHERE cust_doc_id = rec_file_name_dtl.cust_doc_id
            AND (field_id IN (10005, 10023) OR file_name_order_seq = 40);

         -- First time record should not exist.
         SELECT COUNT (DISTINCT file_name_order_seq)
           INTO l_file_name_order_seq_cnt
           FROM xx_cdh_ebl_file_name_dtl
          WHERE cust_doc_id = rec_file_name_dtl.cust_doc_id
            AND file_name_order_seq IN (10, 20, 30);

         -- These checks are to identify data issue...
         IF l_already_exist_verify_cnt > 0 OR l_file_name_order_seq_cnt < 3
         THEN
--            fnd_file.put_line (fnd_file.log,'l_already_exist_verify_cnt '||l_already_exist_verify_cnt||' l_file_name_order_seq_cnt '||l_file_name_order_seq_cnt);
            l_already_exist_cnt := l_already_exist_cnt + 1;
            l_message :=
                  l_message
               || ', ---- As per initial validation already Present or Issue '
               || 'l_already_exist_verify_cnt '
               || l_already_exist_verify_cnt
               || ' l_file_name_order_seq_cnt '
               || l_file_name_order_seq_cnt;
            fnd_file.put_line (fnd_file.LOG, l_message);

            DELETE FROM xx_cdh_ebl_file_name_dtl
                  WHERE cust_doc_id = rec_file_name_dtl.cust_doc_id;

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO l_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                              (p_ebl_file_name_id         => l_ebl_file_name_id
                                                                               -- Using Sequence
            ,
                               p_cust_doc_id              => rec_file_name_dtl.cust_doc_id,
                               p_file_name_order_seq      => 10
                                                               -- Sequence_Number
            ,
                               p_field_id                 => l_field_account,
                               p_constant_value           => NULL,
                               p_default_if_null          => NULL,
                               p_comments                 => NULL,
                               p_last_update_date         => SYSDATE,
                               p_last_updated_by          => fnd_global.user_id,
                               p_creation_date            => SYSDATE,
                               p_created_by               => fnd_global.user_id,
                               p_last_update_login        => fnd_global.login_id
                              );

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO l_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                              (p_ebl_file_name_id         => l_ebl_file_name_id
                                                                               -- Using Sequence
            ,
                               p_cust_doc_id              => rec_file_name_dtl.cust_doc_id,
                               p_file_name_order_seq      => 20
                                                               -- Sequence_Number
            ,
                               p_field_id                 => l_field_docid,
                               p_constant_value           => NULL,
                               p_default_if_null          => NULL,
                               p_comments                 => NULL,
                               p_last_update_date         => SYSDATE,
                               p_last_updated_by          => fnd_global.user_id,
                               p_creation_date            => SYSDATE,
                               p_created_by               => fnd_global.user_id,
                               p_last_update_login        => fnd_global.login_id
                              );

            SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
              INTO l_ebl_file_name_id
              FROM DUAL;

            xx_cdh_ebl_file_name_dtl_pkg.insert_row
                              (p_ebl_file_name_id         => l_ebl_file_name_id
                                                                               -- Using Sequence
            ,
                               p_cust_doc_id              => rec_file_name_dtl.cust_doc_id,
                               p_file_name_order_seq      => 30
                                                               -- Sequence_Number
            ,
                               p_field_id                 => l_field_billdate,
                               p_constant_value           => NULL,
                               p_default_if_null          => NULL,
                               p_comments                 => NULL,
                               p_last_update_date         => SYSDATE,
                               p_last_updated_by          => fnd_global.user_id,
                               p_creation_date            => SYSDATE,
                               p_created_by               => fnd_global.user_id,
                               p_last_update_login        => fnd_global.login_id
                              );
--            GOTO do_not_insert_file_name;
         END IF;

         SELECT xx_cdh_ebl_file_name_id_s.NEXTVAL
           INTO l_ebl_file_name_id
           FROM DUAL;

         xx_cdh_ebl_file_name_dtl_pkg.insert_row
                              (p_ebl_file_name_id         => l_ebl_file_name_id
                                                                               -- Using Sequence
         ,
                               p_cust_doc_id              => rec_file_name_dtl.cust_doc_id,
                               p_file_name_order_seq      => 40
                                                               -- Sequence_Number
         ,
                               p_field_id                 => rec_file_name_dtl.field_id
                                                                                       -- 10005(Cosolidate), 10023 (Invoice)
         ,
                               p_constant_value           => NULL,
                               p_default_if_null          => NULL,
                               p_comments                 => NULL,
                               p_last_update_date         => SYSDATE,
                               p_last_updated_by          => fnd_global.user_id,
                               p_creation_date            => SYSDATE,
                               p_created_by               => fnd_global.user_id,
                               p_last_update_login        => fnd_global.login_id
                              );

         SELECT COUNT (*)
           INTO l_file_name_verify_cnt
           FROM xx_cdh_ebl_file_name_dtl
          WHERE cust_doc_id = rec_file_name_dtl.cust_doc_id
            AND file_name_order_seq IN (10, 20, 30, 40);

         IF l_file_name_verify_cnt = 4
         THEN
            l_message := l_message || ', ---- Successfully updated.';
            l_success_count := l_success_count + 1;
            fnd_file.put_line (fnd_file.LOG, l_message);
         END IF;

         IF l_file_name_verify_cnt = 0
         THEN
            l_message :=
                      l_message || ', ---- Issue in Inserting File Name DTL.';
            fnd_file.put_line (fnd_file.LOG, l_message);
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
--    <<do_not_insert_file_name>>
--    NULL;
      END LOOP;

      fnd_file.put_line (fnd_file.LOG, ' Total Records ' || l_total_count);
      fnd_file.put_line (fnd_file.LOG,
                         ' Sucessful Records ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.LOG,
                         ' Corrected Error Records ' || l_error_count
                        );
      fnd_file.put_line (fnd_file.LOG,
                         ' Already Present ' || l_already_exist_cnt
                        );

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf :=
               'Unexpected Error during File name Details Insert:' || SQLERRM;
   END sp_epdf_ins_file_name_dtl;

--To purge COMPLETED billdocs more than 365 old
   PROCEDURE sp_epdf_purge_billdocs_proc (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_purge_billdocs_proc
      IS
         SELECT   hca.cust_account_id, hca.account_number,
                  SUBSTR (orig_system_reference, 1, 8) aops_number,
                  xccaeb.n_ext_attr2 cust_doc_id, xccaeb.extension_id,
                  xccaeb.c_ext_attr1, xccaeb.c_ext_attr3 document_type
             FROM xx_cdh_cust_acct_ext_b xccaeb, hz_cust_accounts hca
            WHERE xccaeb.cust_account_id = hca.cust_account_id
              AND xccaeb.c_ext_attr1 IN ('Invoice', 'Consolidated Bill')
              AND xccaeb.attr_group_id = 166
              --AND xccaeb.c_ext_attr2='Y'    -- No need to check for paydoc only
              AND xccaeb.d_ext_attr2 < SYSDATE - 365
              AND xccaeb.c_ext_attr16 = 'COMPLETE'
         --AND xccaeb.c_ext_attr3 = 'ePDF'
         ORDER BY xccaeb.n_ext_attr2;

      l_message               VARCHAR2 (2000);
      l_total_count           NUMBER          := 0;
      l_success_count         NUMBER          := 0;
      l_error_count           NUMBER          := 0;
      l_cust_doc_verify_cnt   NUMBER          := 0;
      l_sqlerrm               VARCHAR2 (200);
      ln_attr_grp_id          NUMBER;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      l_message := 'AOPS Customer ID | Cust Doc Id ';

      BEGIN
         SELECT attr_group_id
           INTO ln_attr_grp_id
           FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
            AND attr_group_name = 'BILLDOCS';
      END;

      FOR rec_purge_billdocs_proc IN cur_purge_billdocs_proc
      LOOP
         l_total_count := l_total_count + 1;
         l_message :=
               rec_purge_billdocs_proc.aops_number
            || ' | '
            || rec_purge_billdocs_proc.cust_doc_id;

         BEGIN
            DELETE FROM xx_cdh_ebl_main
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message := l_message || ' |  Deleted from XX_CDH_EBL_MAIN ';
            ELSE
               l_message := l_message || '|  no record in XX_CDH_EBL_MAIN ';
            END IF;

            DELETE FROM xx_cdh_ebl_transmission_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                  l_message
                  || ' |  Deleted from XX_CDH_EBL_TRANSMISSION_DTL ';
            ELSE
               l_message :=
                  l_message || '|  no record in XX_CDH_EBL_TRANSMISSION_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_contacts
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                         l_message || ' |  Deleted from XX_CDH_EBL_CONTACTS ';
            ELSE
               l_message :=
                          l_message || '|  no record in XX_CDH_EBL_CONTACTS ';
            END IF;

            DELETE FROM xx_cdh_ebl_file_name_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                    l_message || ' |  Deleted from XX_CDH_EBL_FILE_NAME_DTL ';
            ELSE
               l_message :=
                     l_message || '|  no record in XX_CDH_EBL_FILE_NAME_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_templ_header
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_EBL_TEMPL_HEADER ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_EBL_TEMPL_HEADER ';
            END IF;

            DELETE FROM xx_cdh_ebl_templ_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                        l_message || ' |  Deleted from XX_CDH_EBL_TEMPL_DTL ';
            ELSE
               l_message :=
                         l_message || '|  no record in XX_CDH_EBL_TEMPL_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_std_aggr_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_EBL_STD_AGGR_DTL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_EBL_STD_AGGR_DTL ';
            END IF;

            DELETE FROM xx_cdh_cust_acct_ext_tl
                  WHERE extension_id = rec_purge_billdocs_proc.extension_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_CUST_ACCT_EXT_TL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_CUST_ACCT_EXT_TL ';
            END IF;

            DELETE FROM xx_cdh_cust_acct_ext_b
                  WHERE extension_id = rec_purge_billdocs_proc.extension_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                      l_message || ' |  Deleted from XX_CDH_CUST_ACCT_EXT_B ';
            ELSE
               l_message :=
                       l_message || '|  no record in XX_CDH_CUST_ACCT_EXT_B ';
            END IF;

            ----- Added for Defect 39789
            BEGIN
               DELETE FROM xx_cdh_acct_site_ext_tl
                     WHERE attr_group_id = ln_attr_grp_id
                       AND extension_id IN (
                              SELECT extension_id
                                FROM xx_cdh_acct_site_ext_b xb
                               WHERE xb.n_ext_attr1 =
                                           rec_purge_billdocs_proc.cust_doc_id
                                 AND attr_group_id = ln_attr_grp_id);
            END;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_ACCT_SITE_EXT_TL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_ACCT_SITE_EXT_TL ';
            END IF;

            DELETE FROM xx_cdh_acct_site_ext_b
                  WHERE n_ext_attr1 = rec_purge_billdocs_proc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                      l_message || ' |  Deleted from XX_CDH_ACCT_SITE_EXT_B ';
            ELSE
               l_message :=
                       l_message || '|  no record in XX_CDH_ACCT_SITE_EXT_B ';
            END IF;
         ----- Added for Defect 39789
         EXCEPTION
            WHEN OTHERS
            THEN
               l_sqlerrm := SUBSTR (SQLERRM, 1, 100);
               l_message := l_message || ' -- ' || l_sqlerrm;
         END;

         SELECT COUNT (*)
           INTO l_cust_doc_verify_cnt
           FROM xx_cdh_cust_acct_ext_b
          WHERE extension_id = rec_purge_billdocs_proc.extension_id;

         IF l_cust_doc_verify_cnt = 0
         THEN
            l_message := l_message || ' ---- Successfully Deleted.';
            l_success_count := l_success_count + 1;
            fnd_file.put_line (fnd_file.LOG, l_message);
         END IF;

         IF l_cust_doc_verify_cnt > 0
         THEN
            l_message := l_message || ' ---- Issue in Delete .';
            fnd_file.put_line (fnd_file.LOG, l_message);
            ROLLBACK;
            l_error_count := l_error_count + 1;
         -- rollback here
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.output, ' Total Records ' || l_total_count);
      fnd_file.put_line (fnd_file.output,
                         ' Sucessful Records ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.output, ' Error Records ' || l_error_count);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf :=
               'Unexpected Error during File name Details Insert:' || SQLERRM;
   END sp_epdf_purge_billdocs_proc;

--To purge IN_PROCESS billdocs more than 365 old
   PROCEDURE sp_epdf_purge_billdocs_inproc (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR cur_purge_billdocs_inproc
      IS
         SELECT   hca.cust_account_id, hca.account_number,
                  SUBSTR (orig_system_reference, 1, 8) aops_number,
                  xccaeb.n_ext_attr2 cust_doc_id, xccaeb.extension_id,
                  xccaeb.c_ext_attr1
             FROM xx_cdh_cust_acct_ext_b xccaeb, hz_cust_accounts hca
            WHERE xccaeb.cust_account_id = hca.cust_account_id
              AND xccaeb.c_ext_attr1 IN ('Invoice', 'Consolidated Bill')
              AND xccaeb.attr_group_id = 166
              --AND xccaeb.c_ext_attr2='Y'    -- No need to check for paydoc only
              AND xccaeb.d_ext_attr9 < SYSDATE - 365
              AND xccaeb.c_ext_attr16 = 'IN_PROCESS'
         --AND xccaeb.c_ext_attr3 = 'ePDF'
         ORDER BY xccaeb.n_ext_attr2;

      l_message               VARCHAR2 (2000);
      l_total_count           NUMBER          := 0;
      l_success_count         NUMBER          := 0;
      l_error_count           NUMBER          := 0;
      l_cust_doc_verify_cnt   NUMBER          := 0;
      l_sqlerrm               VARCHAR2 (200);
      ln_attr_grp_id          NUMBER;
   BEGIN
      x_errbuf := NULL;
      x_retcode := 0;
      l_message := 'AOPS Customer ID | Cust Doc Id ';

      BEGIN
         SELECT attr_group_id
           INTO ln_attr_grp_id
           FROM ego_attr_groups_v
          WHERE attr_group_type = 'XX_CDH_CUST_ACCT_SITE'
            AND attr_group_name = 'BILLDOCS';
      END;

      FOR rec_purge_billdocs_inproc IN cur_purge_billdocs_inproc
      LOOP
         l_total_count := l_total_count + 1;
         l_message :=
               rec_purge_billdocs_inproc.aops_number
            || ' | '
            || rec_purge_billdocs_inproc.cust_doc_id;

         BEGIN
            DELETE FROM xx_cdh_ebl_main
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message := l_message || ' |  Deleted from XX_CDH_EBL_MAIN ';
            ELSE
               l_message := l_message || '|  no record in XX_CDH_EBL_MAIN ';
            END IF;

            DELETE FROM xx_cdh_ebl_transmission_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                  l_message
                  || ' |  Deleted from XX_CDH_EBL_TRANSMISSION_DTL ';
            ELSE
               l_message :=
                  l_message || '|  no record in XX_CDH_EBL_TRANSMISSION_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_contacts
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                         l_message || ' |  Deleted from XX_CDH_EBL_CONTACTS ';
            ELSE
               l_message :=
                          l_message || '|  no record in XX_CDH_EBL_CONTACTS ';
            END IF;

            DELETE FROM xx_cdh_ebl_file_name_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                    l_message || ' |  Deleted from XX_CDH_EBL_FILE_NAME_DTL ';
            ELSE
               l_message :=
                     l_message || '|  no record in XX_CDH_EBL_FILE_NAME_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_templ_header
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_EBL_TEMPL_HEADER ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_EBL_TEMPL_HEADER ';
            END IF;

            DELETE FROM xx_cdh_ebl_templ_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                        l_message || ' |  Deleted from XX_CDH_EBL_TEMPL_DTL ';
            ELSE
               l_message :=
                         l_message || '|  no record in XX_CDH_EBL_TEMPL_DTL ';
            END IF;

            DELETE FROM xx_cdh_ebl_std_aggr_dtl
                  WHERE cust_doc_id = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_EBL_STD_AGGR_DTL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_EBL_STD_AGGR_DTL ';
            END IF;

            DELETE FROM xx_cdh_cust_acct_ext_tl
                  WHERE extension_id = rec_purge_billdocs_inproc.extension_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_CUST_ACCT_EXT_TL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_CUST_ACCT_EXT_TL ';
            END IF;

            DELETE FROM xx_cdh_cust_acct_ext_b
                  WHERE extension_id = rec_purge_billdocs_inproc.extension_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                      l_message || ' |  Deleted from XX_CDH_CUST_ACCT_EXT_B ';
            ELSE
               l_message :=
                       l_message || '|  no record in XX_CDH_CUST_ACCT_EXT_B ';
            END IF;

            ----- Added for Defect 39789
            BEGIN
               DELETE FROM xx_cdh_acct_site_ext_tl
                     WHERE attr_group_id = ln_attr_grp_id
                       AND extension_id IN (
                              SELECT extension_id
                                FROM xx_cdh_acct_site_ext_b xb
                               WHERE xb.n_ext_attr1 =
                                         rec_purge_billdocs_inproc.cust_doc_id
                                 AND attr_group_id = ln_attr_grp_id);
            END;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                     l_message || ' |  Deleted from XX_CDH_ACCT_SITE_EXT_TL ';
            ELSE
               l_message :=
                      l_message || '|  no record in XX_CDH_ACCT_SITE_EXT_TL ';
            END IF;

            DELETE FROM xx_cdh_acct_site_ext_b
                  WHERE n_ext_attr1 = rec_purge_billdocs_inproc.cust_doc_id;

            IF SQL%ROWCOUNT > 0
            THEN
               l_message :=
                      l_message || ' |  Deleted from XX_CDH_ACCT_SITE_EXT_B ';
            ELSE
               l_message :=
                       l_message || '|  no record in XX_CDH_ACCT_SITE_EXT_B ';
            END IF;
         ----- Added for Defect 39789
         EXCEPTION
            WHEN OTHERS
            THEN
               l_sqlerrm := SUBSTR (SQLERRM, 1, 100);
               l_message := l_message || ' -- ' || l_sqlerrm;
         END;

         SELECT COUNT (*)
           INTO l_cust_doc_verify_cnt
           FROM xx_cdh_cust_acct_ext_b
          WHERE extension_id = rec_purge_billdocs_inproc.extension_id;

         IF l_cust_doc_verify_cnt = 0
         THEN
            l_message := l_message || ' ---- Successfully Deleted.';
            l_success_count := l_success_count + 1;
            fnd_file.put_line (fnd_file.LOG, l_message);
         END IF;

         IF l_cust_doc_verify_cnt > 0
         THEN
            l_message := l_message || ' ---- Issue in Delete .';
            fnd_file.put_line (fnd_file.LOG, l_message);
            ROLLBACK;
            l_error_count := l_error_count + 1;
         -- rollback here
         END IF;

         IF (p_commit <> 'Y')
         THEN
            ROLLBACK;
         ELSE
            COMMIT;
         END IF;
      END LOOP;

      fnd_file.put_line (fnd_file.output, ' Total Records ' || l_total_count);
      fnd_file.put_line (fnd_file.output,
                         ' Sucessful Records ' || l_success_count
                        );
      fnd_file.put_line (fnd_file.output, ' Error Records ' || l_error_count);

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf :=
               'Unexpected Error during File name Details Insert:' || SQLERRM;
   END sp_epdf_purge_billdocs_inproc;

--To purge xx_cdh_ebl_log
   PROCEDURE sp_reset_ebl_log (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
   BEGIN
      DELETE FROM xx_cdh_ebl_log;

      COMMIT;
   END sp_reset_ebl_log;

   PROCEDURE sp_purge_ebl_upload_contact (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      l_purge_period   VARCHAR2 (10)
              := NVL (fnd_profile.VALUE ('XX_PURGE_EBL_UPLOAD_CONTACT'), '7');
   BEGIN
      DELETE FROM xxcrm_ebl_cont_uploads
            WHERE TRUNC (creation_date) <= TRUNC (SYSDATE) - l_purge_period;

      fnd_file.put_line (fnd_file.LOG,
                         ' Delete XXCRM_EBL_CONT_UPLOADS : ' || SQL%ROWCOUNT
                        );

      DELETE FROM xxod_cdh_ebl_contacts_stg
            WHERE TRUNC (creation_date) <= TRUNC (SYSDATE) - l_purge_period;

      fnd_file.put_line (fnd_file.LOG,
                            ' Delete XXOD_CDH_EBL_CONTACTS_STG : '
                         || SQL%ROWCOUNT
                        );

      IF (p_commit <> 'Y')
      THEN
         ROLLBACK;
      ELSE
         COMMIT;
      END IF;
   END sp_purge_ebl_upload_contact;

   PROCEDURE xxcdh_update_null_pt (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_details
      IS
         SELECT   hca.orig_system_reference aops_number,
                  hca.account_number oracle_acc_number, hca.cust_account_id,
                  cons_inv_flag, cons_inv_type, profile_class_id,
                  hcp.site_use_id, hcp.cust_account_profile_id,
                  hcp.attribute3, hcp.object_version_number
             FROM hz_customer_profiles hcp, hz_cust_accounts hca
            WHERE 1 = 1                                                     --
              AND hcp.standard_terms IS NULL
              AND hca.cust_account_id = hcp.cust_account_id
              AND hca.status = 'A'
              AND hcp.status = 'A'
         ORDER BY hcp.cust_account_id;

      CURSOR lc_bill_payment_term (
         c_cust_account_id   hz_cust_accounts.cust_account_id%TYPE
      )
      IS
         SELECT n_ext_attr18 payment_term_id
           FROM xx_cdh_cust_acct_ext_b b
          WHERE attr_group_id = 166                                     -- 166
            AND c_ext_attr2 = 'Y'                       -- BILLDOCS_PAYDOC_IND
            AND c_ext_attr16 = 'COMPLETE'                   -- BILLDOCS_STATUS
            AND SYSDATE BETWEEN d_ext_attr1 AND NVL (d_ext_attr2, SYSDATE + 1)
            AND cust_account_id = c_cust_account_id
            AND ROWNUM = 1;

      --DECLARE
      v_errbuf                   VARCHAR2 (4000);
      par_rec                    hz_party_v2pub.party_rec_type;
      org_rec                    hz_party_v2pub.organization_rec_type;
      l_application_id           NUMBER;
      l_responsibility_id        NUMBER;
      l_user_id                  NUMBER;
      ln_error                   NUMBER                                   := 0;
      ln_total                   NUMBER                                   := 0;
      l_msg_count                NUMBER;
      l_msg_data                 VARCHAR2 (4000);
      l_error_message            VARCHAR2 (4000);
      l_msg_count_amt            NUMBER;
      l_msg_data_amt             VARCHAR2 (4000);
      l_error_message_amt        VARCHAR2 (4000);
      l_g_start_date             DATE;
      l_init_msg_list            VARCHAR2 (1000)             := fnd_api.g_true;
      l_return_status            VARCHAR2 (10);
      l_return_status_amt        VARCHAR2 (10);
      --- give the object version number from hz_cust_accounts table for the customer
      lrec_hz_customer_profile   hz_customer_profile_v2pub.customer_profile_rec_type;
      l_profile_class_id         hz_customer_profiles.profile_class_id%TYPE;
      ln_object_version_number   NUMBER;
      l_payment_term_id          hz_customer_profiles.standard_terms%TYPE;
      l_profile_standard_terms   hz_customer_profiles.standard_terms%TYPE;
      l_cust_count               NUMBER                                   := 0;
      l_error_count              NUMBER                                   := 0;
      lp_ret_status              VARCHAR2 (10);
      lp_msg_count               NUMBER;
      lp_msg_data                VARCHAR2 (1000);
      lp_msg_text                VARCHAR2 (4000);
   BEGIN
      BEGIN
         BEGIN
            v_errbuf := 'Fetching applnID and respID ';

            SELECT application_id, responsibility_id
              INTO l_application_id, l_responsibility_id
              FROM fnd_responsibility_tl
             WHERE responsibility_name = 'OD (US) Customer Conversion'
               AND LANGUAGE = USERENV ('LANG');

            v_errbuf := 'Fetching userID ';

            SELECT user_id
              INTO l_user_id
              FROM fnd_user
             WHERE user_name = 'ODCDH';

            v_errbuf := 'Doing apps init ';
            fnd_global.apps_initialize (l_user_id,
                                        l_responsibility_id,
                                        l_application_id
                                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line ('Error in Apps Initialize');
               RAISE;
         END;

         fnd_file.put_line
                      (fnd_file.LOG,
                          'Updation of Null Payment Terms Program Started  : '
                       || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
                      );

         FOR lr_cust_details IN lcu_cust_details
         LOOP
            IF (lr_cust_details.site_use_id IS NULL)
            THEN
               l_cust_count := l_cust_count + 1;
               fnd_file.put_line
                  (fnd_file.LOG,
                   '----------------------------------------------------------------------'
                  );
               DBMS_OUTPUT.put_line
                  ('----------------------------------------------------------------------'
                  );
            END IF;

            fnd_file.put_line (fnd_file.LOG,
                                  'Updating Customer Number/ID/Site use ID : '
                               || lr_cust_details.aops_number
                               || '  /  '
                               || lr_cust_details.cust_account_id
                               || '  /  '
                               || lr_cust_details.site_use_id
                              );

            OPEN lc_bill_payment_term (lr_cust_details.cust_account_id);

            FETCH lc_bill_payment_term
             INTO l_payment_term_id;

            fnd_file.put_line (fnd_file.LOG,
                                  'Bill Docs Payment Term ID  : '
                               || l_payment_term_id
                              );

            CLOSE lc_bill_payment_term;

            BEGIN
-- -----------------------------------------------------------------------
-- API to get Customer Default Profile details.
-- -----------------------------------------------------------------------
               lrec_hz_customer_profile := NULL;
               hz_customer_profile_v2pub.get_customer_profile_rec
                  (p_init_msg_list                => fnd_api.g_true,
                   p_cust_account_profile_id      => lr_cust_details.cust_account_profile_id,
                   x_customer_profile_rec         => lrec_hz_customer_profile,
                   x_return_status                => lp_ret_status,
                   x_msg_count                    => lp_msg_count,
                   x_msg_data                     => lp_msg_data
                  );

               IF lp_msg_count >= 1
               THEN
                  FOR i IN 1 .. lp_msg_count
                  LOOP
                     lp_msg_text :=
                           lp_msg_text
                        || ' '
                        || fnd_msg_pub.get (i, fnd_api.g_false);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error - '
                                        || fnd_msg_pub.get (i,
                                                            fnd_api.g_false)
                                       );
                  END LOOP;

                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Error while getting the Customer Profile Record for Customer AOPS Number||Cust Account ID  : '
                      || lr_cust_details.aops_number
                      || '-'
                      || lr_cust_details.cust_account_id
                      || CHR (10)
                     );
               END IF;
            END;

            BEGIN
               SELECT standard_terms
                 INTO l_profile_standard_terms
                 FROM ar_customer_profile_classes_v
                WHERE customer_profile_class_id =
                                              lr_cust_details.profile_class_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_profile_standard_terms := l_payment_term_id;
            END;

            fnd_file.put_line (fnd_file.LOG,
                                  'Profile Class ID / Payment Term ID :  '
                               || lr_cust_details.profile_class_id
                               || '-'
                               || NVL (l_payment_term_id,
                                       l_profile_standard_terms
                                      )
                               || CHR (10)
                              );
            lrec_hz_customer_profile.cust_account_id :=
                                               lr_cust_details.cust_account_id;
            lrec_hz_customer_profile.standard_terms :=
                             NVL (l_payment_term_id, l_profile_standard_terms);
            lrec_hz_customer_profile.cust_account_profile_id :=
                                       lr_cust_details.cust_account_profile_id;
            hz_customer_profile_v2pub.update_customer_profile
               (p_init_msg_list              => fnd_api.g_false,
                p_customer_profile_rec       => lrec_hz_customer_profile,
                p_object_version_number      => lr_cust_details.object_version_number,
                x_return_status              => l_return_status,
                x_msg_count                  => l_msg_count,
                x_msg_data                   => l_msg_data
               );

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;

            IF (l_msg_count > 1)
            THEN
               FOR i IN 1 .. fnd_msg_pub.count_msg
               LOOP
                  l_error_message :=
                        l_error_message
                     || fnd_msg_pub.get (i, p_encoded => fnd_api.g_false);
               END LOOP;

               DBMS_OUTPUT.put_line (l_error_message);
            ELSE
               l_error_message := l_msg_data;
            END IF;

            IF (l_return_status <> 'S')
            THEN
               l_error_count := l_error_count + 1;
            END IF;
         END LOOP;

         IF l_error_count <> 0
         THEN
            x_retcode := 1;
         ELSE
            x_retcode := 0;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
               (fnd_file.LOG,
                   'Unexpected Error in Updation of Null Payment Terms Program Error - '
                || SQLERRM
               );
            x_errbuf :=
                  'Unexpected Error in Updation of Null Payment Terms Program - '
               || SQLERRM;
            x_retcode := 2;
      END;

      fnd_file.put_line
         (fnd_file.LOG,
          '----------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.LOG,
                         'Total Customers Updated : ' || l_cust_count
                        );
      fnd_file.put_line
                     (fnd_file.LOG,
                         'Updation of Null Payment Terms Program Completed : '
                      || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
                     );
--  end;
   END xxcdh_update_null_pt;

   PROCEDURE xxcdh_update_override_terms (
      x_errbuf    OUT      VARCHAR2,
      x_retcode   OUT      VARCHAR2,
      p_commit    IN       VARCHAR2
   )
   AS
      CURSOR lcu_cust_details (p_attr_grp_id IN NUMBER)
      IS
         SELECT   *
             FROM (SELECT hc.cust_account_id, cust_account_profile_id,
                          hcp.object_version_number,
                          hc.orig_system_reference aops_number,
                          hcp.site_use_id, hcp.standard_terms
                     FROM xx_cdh_cust_acct_ext_b xb,
                          hz_cust_accounts hc,
                          hz_customer_profiles hcp
                    WHERE 1 = 1
                      AND hc.cust_account_id = xb.cust_account_id
                      AND hc.cust_account_id = hcp.cust_account_id
                      AND hc.status = 'A'
                      AND attr_group_id = p_attr_grp_id                 -- 166
                      AND c_ext_attr2 = 'Y'
                      AND c_ext_attr1 = 'Consolidated Bill'
                      AND c_ext_attr16 = 'COMPLETE'
                      AND NVL (hcp.override_terms, 'N') <> 'Y'
                      AND SYSDATE BETWEEN d_ext_attr1
                                      AND NVL (d_ext_attr2, SYSDATE + 1)) ab
            WHERE 1 = 1
         ORDER BY 1;

      --DECLARE
      v_errbuf                   VARCHAR2 (4000);
      par_rec                    hz_party_v2pub.party_rec_type;
      org_rec                    hz_party_v2pub.organization_rec_type;
      l_application_id           NUMBER;
      l_responsibility_id        NUMBER;
      l_user_id                  NUMBER;
      ln_error                   NUMBER                                   := 0;
      ln_total                   NUMBER                                   := 0;
      l_msg_count                NUMBER;
      l_msg_data                 VARCHAR2 (4000);
      l_msg_count1               NUMBER;
      l_msg_data1                VARCHAR2 (4000);
      l_return_status1           VARCHAR2 (10);
      --l_error_message            VARCHAR2 (4000);
	  l_error_message            VARCHAR2 (32767);--Changed the size for NAIT-156165 to avoid program ending in error due to insufficient size
      l_msg_count_amt            NUMBER;
      l_msg_data_amt             VARCHAR2 (4000);
      l_error_message_amt        VARCHAR2 (4000);
      l_g_start_date             DATE;
      l_init_msg_list            VARCHAR2 (1000)             := fnd_api.g_true;
      l_return_status            VARCHAR2 (10);
      l_return_status_amt        VARCHAR2 (10);
      --- give the object version number from hz_cust_accounts table for the customer
      lrec_hz_customer_profile   hz_customer_profile_v2pub.customer_profile_rec_type;
      l_profile_class_id         hz_customer_profiles.profile_class_id%TYPE;
      ln_object_version_number   NUMBER;
      l_payment_term_id          hz_customer_profiles.standard_terms%TYPE;
      l_profile_standard_terms   hz_customer_profiles.standard_terms%TYPE;
      l_cust_count               NUMBER                                   := 0;
      l_error_count              NUMBER                                   := 0;
      lp_ret_status              VARCHAR2 (10);
      lp_msg_count               NUMBER;
      lp_msg_data                VARCHAR2 (1000);
      lp_msg_text                VARCHAR2 (4000);
      ln_attr_group_id           NUMBER;
      l_pmt_count                NUMBER;
   BEGIN
      BEGIN
         BEGIN
            v_errbuf := 'Fetching applnID and respID ';

            SELECT application_id, responsibility_id
              INTO l_application_id, l_responsibility_id
              FROM fnd_responsibility_tl
             WHERE responsibility_name = 'OD (US) Customer Conversion'
               AND LANGUAGE = USERENV ('LANG');

            v_errbuf := 'Fetching userID ';

            SELECT user_id
              INTO l_user_id
              FROM fnd_user
             WHERE user_name = 'ODCDH';

            v_errbuf := 'Doing apps init ';
            fnd_global.apps_initialize (l_user_id,
                                        l_responsibility_id,
                                        l_application_id
                                       );
         EXCEPTION
            WHEN OTHERS
            THEN
               DBMS_OUTPUT.put_line ('Error in Apps Initialize');
               RAISE;
         END;

         fnd_file.put_line
                          (fnd_file.LOG,
                              'Updation of Override Terms Program Started  : '
                           || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
                          );

         BEGIN
            SELECT attr_group_id
              INTO ln_attr_group_id
              FROM ego_attr_groups_v
             WHERE attr_group_type = 'XX_CDH_CUST_ACCOUNT'
               AND attr_group_name = 'BILLDOCS';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_attr_group_id := 166;
         END;

         FOR lr_cust_details IN lcu_cust_details (ln_attr_group_id)
         LOOP
            IF (lr_cust_details.site_use_id IS NULL)
            THEN
               l_cust_count := l_cust_count + 1;
               fnd_file.put_line
                  (fnd_file.LOG,
                   '----------------------------------------------------------------------'
                  );
               DBMS_OUTPUT.put_line
                  ('----------------------------------------------------------------------'
                  );
            END IF;

            fnd_file.put_line (fnd_file.LOG,
                                  'Updating Customer Number/ID/Site use ID : '
                               || lr_cust_details.aops_number
                               || '  /  '
                               || lr_cust_details.cust_account_id
                               || '  /  '
                               || lr_cust_details.site_use_id
                              );

            BEGIN
-- -----------------------------------------------------------------------
-- API to get Customer Default Profile details.
-- -----------------------------------------------------------------------
               lrec_hz_customer_profile := NULL;
               hz_customer_profile_v2pub.get_customer_profile_rec
                  (p_init_msg_list                => fnd_api.g_true,
                   p_cust_account_profile_id      => lr_cust_details.cust_account_profile_id,
                   x_customer_profile_rec         => lrec_hz_customer_profile,
                   x_return_status                => lp_ret_status,
                   x_msg_count                    => lp_msg_count,
                   x_msg_data                     => lp_msg_data
                  );

               IF lp_msg_count >= 1
               THEN
                  FOR i IN 1 .. lp_msg_count
                  LOOP
                     lp_msg_text :=
                           lp_msg_text
                        || ' '
                        || fnd_msg_pub.get (i, fnd_api.g_false);
                     fnd_file.put_line (fnd_file.LOG,
                                           'Error - '
                                        || fnd_msg_pub.get (i,
                                                            fnd_api.g_false)
                                       );
                  END LOOP;

                  fnd_file.put_line
                     (fnd_file.LOG,
                         'Error while getting the Customer Profile Record for Customer AOPS Number||Cust Account ID  : '
                      || lr_cust_details.aops_number
                      || '-'
                      || lr_cust_details.cust_account_id
                      || CHR (10)
                     );
               END IF;
            END;

            lrec_hz_customer_profile.cust_account_id :=
                                               lr_cust_details.cust_account_id;
            lrec_hz_customer_profile.cust_account_profile_id :=
                                       lr_cust_details.cust_account_profile_id;
            lrec_hz_customer_profile.cons_inv_flag := 'Y';
            lrec_hz_customer_profile.cons_inv_type := 'DETAIL';
            lrec_hz_customer_profile.cons_bill_level := 'SITE';
            lrec_hz_customer_profile.override_terms := 'Y';
            lrec_hz_customer_profile.standard_terms :=
                                                lr_cust_details.standard_terms;
            hz_customer_profile_v2pub.update_customer_profile
               (p_init_msg_list              => fnd_api.g_false,
                p_customer_profile_rec       => lrec_hz_customer_profile,
                p_object_version_number      => lr_cust_details.object_version_number,
                x_return_status              => l_return_status,
                x_msg_count                  => l_msg_count,
                x_msg_data                   => l_msg_data
               );

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;

            IF (l_msg_count > 1)
            THEN
               FOR i IN 1 .. fnd_msg_pub.count_msg
               LOOP
                  l_error_message :=
                        SUBSTR(l_error_message
                     || fnd_msg_pub.get (i, p_encoded => fnd_api.g_false),1,32000); --Added Substr to limit the error message data for NAIT-156165
               END LOOP;

               DBMS_OUTPUT.put_line (l_error_message);
            ELSE
               l_error_message := l_msg_data;
            END IF;

            BEGIN
               SELECT COUNT (1)
                 INTO l_pmt_count
                 FROM hz_customer_profiles
                WHERE cust_account_profile_id =
                                       lr_cust_details.cust_account_profile_id
                  AND standard_terms IS NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_error_message := 'No profile record found';
            END;

            IF l_pmt_count <> 0
            THEN
               lrec_hz_customer_profile.cust_account_id :=
                                              lr_cust_details.cust_account_id;
               lrec_hz_customer_profile.cust_account_profile_id :=
                                      lr_cust_details.cust_account_profile_id;
               lrec_hz_customer_profile.standard_terms :=
                                               lr_cust_details.standard_terms;
               hz_customer_profile_v2pub.update_customer_profile
                  (p_init_msg_list              => fnd_api.g_false,
                   p_customer_profile_rec       => lrec_hz_customer_profile,
                   p_object_version_number      => lr_cust_details.object_version_number,
                   x_return_status              => l_return_status1,
                   x_msg_count                  => l_msg_count1,
                   x_msg_data                   => l_msg_data1
                  );

               IF (l_msg_count1 > 1)
               THEN
                  FOR i IN 1 .. fnd_msg_pub.count_msg
                  LOOP
                     l_error_message :=
                           SUBSTR(l_error_message
                        || fnd_msg_pub.get (i, p_encoded => fnd_api.g_false),1,32000); --Added Substr to limit the error message data for NAIT-156165
                  END LOOP;

                  DBMS_OUTPUT.put_line (l_error_message);
               ELSE
                  l_error_message := l_msg_data;
               END IF;
            END IF;

            IF (p_commit <> 'Y')
            THEN
               ROLLBACK;
            ELSE
               COMMIT;
            END IF;

            IF (l_return_status1 <> 'S')
            THEN
               l_error_count := l_error_count + 1;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line
               (fnd_file.LOG,
                   'Unexpected Error in Updation of Override Terms Program Error - '
                || SQLERRM
               );
            x_errbuf :=
                  'Unexpected Error in Updation of Override Terms Program - '
               || SQLERRM;
            x_retcode := 2;
      END;

      fnd_file.put_line
         (fnd_file.LOG,
          '----------------------------------------------------------------------'
         );
      fnd_file.put_line (fnd_file.LOG,
                         'Total Customers Updated : ' || l_cust_count
                        );
      fnd_file.put_line (fnd_file.LOG,
                            'Updation of Override Terms Program Completed : '
                         || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
                        );
--  end;
   END xxcdh_update_override_terms;
END xx_cdh_data_correction_pkg;
/

SHOW errors;