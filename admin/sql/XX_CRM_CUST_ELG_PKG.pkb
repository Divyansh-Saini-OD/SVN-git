create or replace
PACKAGE BODY xx_crm_cust_elg_pkg
AS
--+================================================================================+
--|      Office Depot - Project FIT                                                |
--|   Capgemini Consulting Organization                                            |
--+================================================================================+
--|Name        :XX_CRM_CUST_ELG_PKG                                                |
--| BR #       :106313                                                             |
--|Description :This Package is for identifying eligble customers                  |
--|                                                                                |
--|            The STAGING Procedure will perform the following steps              |
--|                                                                                |
--|             1. Identify eligible customers based on business rules             |
--|                 a. All Active Account Billing Customers                        |
--|                 b. Customers with open Balance exluding internal               |
--|                 c. Parent Customers in hierarchy irrespective of status        |
--|                                                                                |
--|             2. Insert data into customer eligbility table                      |
--|                                                                                |
--|             3. Finds records that have been updated since last run date        |
--|                                                                                |
--|Change Record:                                                                  |
--|==============                                                                  |
--|Version    Date             Author            Remarks                           |
--|=======   ======        ====================  =========                         |
--|1.0       30-Aug-2011   Balakrishna Bolikonda Initial Version                   |
--|1.1       10-May-2012   Jay Gupta             Defect 18387 - Add Request_id in  |
--|                                              LOG tables                        |
--|1.2       14-Jun-2012   Devendra Petkar       Defect 18600 - Email Notification |
--|1.3       23-Oct-2012   Deepti                Defect#19865 - exclude op bal cust|
--|1.4       11-Nov-2015   Havish Kasina         Removed the Schema References as  |
--|                                              per R12.2 Retrofit Changes        |
--|1.5       14-SEP-2017   Uday Jadhav           E7029:Added org_id condition to   |
--|                                              restrict VPS records in 	   |
--|					         find_open_balance cur		   |
--+================================================================================+

-- +===============================================================================+
-- | Name       : write_log                                                        |
-- |                                                                               |
-- | Description: This procedure is used to to display detailed                    |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_debug_flag                                                     |
-- |              p_msg                                                            |
-- |                                                                               |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE write_log (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      END IF;
   END write_log;

-- +===============================================================================+
-- | Name       : compute_stats                                                    |
-- |                                                                               |
-- | Description: This procedure is used to display detailed                       |
-- |                     messages to log file                                      |
-- |                                                                               |
-- | Parameters : p_compute_stats                                                  |
-- |              p_schema                                                         |
-- |              p_tablename                                                      |
-- | Returns    : none                                                             |
-- +===============================================================================+
   PROCEDURE compute_stats (
      p_compute_stats   IN   VARCHAR2
     ,p_schema          IN   VARCHAR2
     ,p_tablename       IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_compute_stats = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Gathering table stats');
         fnd_stats.gather_table_stats (ownname => p_schema
		                              ,tabname => p_tablename);
      END IF;
   END compute_stats;

-- +===============================================================================+
-- | Name       : from_to_date                                                     |
-- |                                                                               |
-- | Description: This procedure is used to  get the to and from dates             |
-- |                                                                               |
-- | Parameters :                                                                  |
-- | Returns    : p_from_date                                                      |
-- |              p_to_date                                                        |
-- |              p_retcode                                                        |
-- +===============================================================================+
   PROCEDURE from_to_date (
      p_from_date   OUT   VARCHAR2
     ,p_to_date     OUT   VARCHAR2
     ,p_retcode     OUT   NUMBER
   )
   IS
      ld_from_date   DATE;
      ld_to_date     DATE;
   BEGIN
      SELECT LOG.previous_run_date
            ,LOG.program_run_date
        INTO ld_from_date
            ,ld_to_date
        FROM xx_crmar_int_log LOG
       WHERE LOG.program_short_name = 'XX_CRM_CUST_ELG_PKG'
         AND LOG.program_run_id = (SELECT MAX (LOG1.program_run_id)
                                     FROM xx_crmar_int_log LOG1
                                    WHERE LOG.program_short_name = LOG1.program_short_name AND LOG1.status = 'SUCCESS');

      p_from_date := TO_CHAR (ld_from_date, 'YYYYMMDD HH24:MI:SS');
      p_to_date := TO_CHAR (ld_to_date, 'YYYYMMDD HH24:MI:SS');
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in from_to_date procedure' || gc_error_debug);
         p_retcode := 2;
   -- End of the procedure from_to_date
   END from_to_date;

-- +===============================================================================+
-- | Name       : find_active_ab_cust                                              |
-- |                                                                               |
-- | Description: This procedure is used to fetch the Active AB                    |
-- |                     customers into eligibility table                          |
-- |                                                                               |
-- | Parameters : p_batch_limit                                                    |
-- |              p_sample_count                                                   |
-- |              P_debug_flag                                                     |
-- | Returns    : p_retcode                                                        |
-- +===============================================================================+
   PROCEDURE find_active_ab_cust (
      p_batch_limit    IN       NUMBER
     ,p_sample_count   IN       NUMBER
     ,p_retcode        OUT      NUMBER
   )
   IS
      --table type declaration
      elg_full_tbl_type   lt_cust_elg;
      -- variable declaration
      ln_batch_limit      NUMBER;

      -- cursor declaration
      CURSOR lcu_active_AB_cust
      IS
         SELECT HCA.party_id "party_id"
               ,HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "account_number"
               ,'AB' "int_source"
               ,NULL "extraction_date"
               ,'N' "cust_mast_head_ext"
               ,'N' "cust_addr_ext"
               ,'N' "cust_cont_ext"
               ,'N' "cust_hier_ext"
               ,'N' "sls_per_ext"
               ,'N' "ar_converted_flag"
               ,'' "ar_conv_from_date_full"
               ,'' "ar_conv_to_date_full"
               ,'N' "notes_processed_to_wc"
               ,gd_last_update_date "last_update_date"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_created_by "created_by"
               ,gn_request_id "request_id"
               ,gn_program_id "program_id"
           FROM hz_customer_profiles HCP
               ,hz_cust_accounts HCA
          WHERE HCP.status = 'A'
            AND HCP.attribute3 = 'Y'
            AND HCP.site_use_id IS NULL
            AND HCP.cust_account_id = HCA.cust_account_id
            AND NOT EXISTS (SELECT '1'
                              FROM xx_ar_intstorecust_otc INT_CUST
                             WHERE INT_CUST.cust_account_id = HCA.cust_account_id)
            AND ROWNUM <= NVL (p_sample_count, ROWNUM);
   BEGIN
      gc_error_debug := 'Start Extracting Active AB Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before Trucating Customer Eligibility Table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);

--      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_wcelg_cust';

      ln_batch_limit := p_batch_limit;

      -- Cursor Loop started here
      OPEN lcu_active_AB_cust;

      gc_error_debug := 'Loop started here for fetching active AB customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_active_AB_cust
         BULK COLLECT INTO elg_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. elg_full_tbl_type.COUNT
            INSERT INTO xx_crm_wcelg_cust
                 VALUES elg_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_active_AB_cust%NOTFOUND;
      END LOOP;

      CLOSE lcu_active_AB_cust;

      --Cursor Loop Ended here
      gc_error_debug := 'Loop ended here for fetching active AB customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);
      gc_error_debug := 'End of Extracting Active AB Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in FIND_ACTIVE_AB_CUST procedure' || gc_error_debug);
         p_retcode := 2;
   -- End of the procedure find_active_ab_cust
   END find_active_ab_cust;

-- +===============================================================================+
-- | Name       : find_open_balance                                                |
-- |                                                                               |
-- | Description: This procedure is used to fetch the open balance                 |
-- |                     customers and insert into eligibility table               |
-- |  Imp Note:    This procedure should run after completion of                   |
-- |                OD: AR - WC - Open Transactions - Repopulate Interim Table     |
-- |                program. So that data will be populated into                   |
-- |                xx_ar_recon_open_itm table before running this procedure       |
-- | Parameters : p_batch_limit                                                    |
-- |              p_sample_count                                                   |
-- |              P_debug_flag                                                     |
-- | Returns    : p_retcode                                                        |
--|Change Record:                                                                 |
--|==============                                                                 |
--|Version    Date           Author                       Remarks                 |
--|=======   ======        ====================          =========                |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version              |
-- +===============================================================================+
   PROCEDURE find_open_balance (
      p_batch_limit    IN       NUMBER
     ,p_sample_count   IN       NUMBER
     ,p_retcode        OUT      NUMBER
   )
   IS
      --Table type declaration
      open_bal_full_tbl_type   lt_cust_elg;
      open_bal_temp_tbl_type   lt_cust_elg;
      -- variable declaration
      ln_batch_limit           NUMBER; 

      --cursor declaration
      CURSOR lcu_open_bal_cust
      IS
         SELECT HCA.party_id "party_id"
               ,HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "account_number"
               ,'OB' "int_source"
               ,NULL "extraction_date"
               ,'N' "cust_mast_head_ext"
               ,'N' "cust_addr_ext"
               ,'N' "cust_cont_ext"
               ,'N' "cust_hier_ext"
               ,'N' "sls_per_ext"
               ,'N' "ar_converted_flag"
               ,'' "ar_conv_from_date_full"
               ,'' "ar_conv_to_date_full"
               ,'N' "notes_processed_to_wc"
               ,gd_last_update_date "last_update_date"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_created_by "created_by"
               ,gn_request_id "request_id"
               ,gn_program_id "program_id"
           FROM xx_ar_recon_open_itm PS
               ,hz_cust_accounts HCA
          WHERE PS.customer_id = HCA.cust_account_id
            AND PS.org_id in (404,403)                    -- Added for E7029
            AND NOT EXISTS (SELECT '1'
                              FROM xx_ar_intstorecust_otc INT_CUST
                             WHERE INT_CUST.cust_account_id = HCA.cust_account_id)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_crm_wcelg_cust EC
                             WHERE EC.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID)
            /* V1.3, Need to exclude the customers which has
               Payment Term 'Immediate' and Chedit_Checking 'N' and AB Customer 'N' */
            AND NOT EXISTS ( SELECT '1' FROM HZ_CUSTOMER_PROFILES HCP WHERE
                             HCP.CUST_ACCOUNT_ID=HCA.CUST_ACCOUNT_ID
                             AND NVL(HCP.ATTRIBUTE3,'N')='N'
                             AND HCP.CREDIT_CHECKING='N'
                             AND HCP.STANDARD_TERMS=(SELECT TERM_ID FROM RA_TERMS WHERE NAME ='IMMEDIATE') )
            -- End for defect#19856
            AND ROWNUM <= NVL (p_sample_count, ROWNUM);

      CURSOR lcu_open_bal_temp
      IS
         SELECT UNIQUE OP_BAL.party_id
                      ,OP_BAL.cust_account_id
                      ,OP_BAL.account_number
                      ,OP_BAL.int_source
                      ,OP_BAL.extraction_date
                      ,OP_BAL.cust_mast_head_ext
                      ,OP_BAL.cust_addr_ext
                      ,OP_BAL.cust_cont_ext
                      ,OP_BAL.cust_hier_ext
                      ,OP_BAL.sls_per_ext
                      ,OP_BAL.ar_converted_flag
                      ,OP_BAL.ar_conv_from_date_full
                      ,OP_BAL.ar_conv_to_date_full
                      ,OP_BAL.notes_processed_to_wc
                      ,OP_BAL.last_update_date
                      ,OP_BAL.last_updated_by
                      ,OP_BAL.creation_date
                      ,OP_BAL.created_by
                      ,OP_BAL.request_id
                      ,OP_BAL.program_id
                  FROM xx_crm_open_bal_temp OP_BAL;
   BEGIN
      ln_batch_limit := p_batch_limit;
      gc_error_debug := 'Start Extracting Open Balance Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before Trucating Open balance temp Table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
       
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_open_bal_temp';

      --lcu_open_bal_cust cursor Loop started here
      OPEN lcu_open_bal_cust;

      gc_error_debug := 'Loop started here for fetching open balance customers into temporary table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_open_bal_cust
         BULK COLLECT INTO open_bal_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. open_bal_full_tbl_type.COUNT
            INSERT INTO xx_crm_open_bal_temp
                 VALUES open_bal_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_open_bal_cust%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop ended here for fetching open balance customers into temporary table';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_open_bal_cust;

      --lcu_open_bal_cust cursor Loop Ended here

      --lcu_open_bal_temp cursor Loop started here
      OPEN lcu_open_bal_temp;

      gc_error_debug := 'Loop started here for fetching open balance customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_open_bal_temp
         BULK COLLECT INTO open_bal_temp_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. open_bal_temp_tbl_type.COUNT
            INSERT INTO xx_crm_wcelg_cust
                 VALUES open_bal_temp_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_open_bal_temp%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop ended here for fetching open balance customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_open_bal_temp;

      --lcu_open_bal_temp cursor Loop Ended here
      gc_error_debug := 'End of Extracting Open Balance Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in FIND_OPEN_BALANCE procedure' || gc_error_debug);
         p_retcode := 2;
   --End of find_open_balance procedure
   END find_open_balance;

-- +===============================================================================+
-- | Name       : find_new_AB                                                      |
-- |                                                                               |
-- | Description: This procedure is used to fetch the new AB                       |
-- |                     customers into eligibility table                          |
-- |                                                                               |
-- | Parameters : p_last_run_date                                                  |
-- |              p_to_run_date                                                    |
-- |              p_batch_limit                                                    |
-- |              p_sample_count                                                   |
-- |              P_debug_flag                                                     |
-- | Returns    : p_retcode                                                        |
-- +===============================================================================+
   PROCEDURE find_new_AB (
      p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_retcode         OUT      NUMBER
   )
   IS
      --Table type declaration
      elg_incr_tbl_type   lt_cust_elg;
      --variable declaration
      ln_batch_limit      NUMBER;

      --Cursor declaration
      CURSOR lcu_new_AB_cust
      IS
         SELECT HCA.party_id "party_id"
               ,HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "account_number"
               ,'AB' "int_source"
               ,TO_DATE ('31-DEC-4712', 'DD-MON-YYYY') "extraction_date"
               ,'N' "cust_mast_head_ext"
               ,'N' "cust_addr_ext"
               ,'N' "cust_cont_ext"
               ,'N' "cust_hier_ext"
               ,'N' "sls_per_ext"
               ,'N' "ar_converted_flag"
               ,'' "ar_conv_from_date_full"
               ,'' "ar_conv_to_date_full"
               ,'N' "notes_processed_to_wc"
               ,gd_last_update_date "last_update_date"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_created_by "created_by"
               ,gn_request_id "request_id"
               ,gn_program_id "program_id"
           FROM hz_customer_profiles HCP
               ,hz_cust_accounts HCA
          WHERE HCP.status = 'A'
            AND HCP.attribute3 = 'Y'
            AND HCP.site_use_id IS NULL
            AND HCP.cust_account_id = HCA.cust_account_id
            AND HCA.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCA.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_ar_intstorecust_otc INT_CUST
                             WHERE INT_CUST.cust_account_id = HCA.cust_account_id)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_crm_wcelg_cust EC
                             WHERE HCA.cust_account_id = EC.cust_account_id)
            AND ROWNUM <= NVL (p_sample_count, ROWNUM);
   BEGIN
      ln_batch_limit := p_batch_limit;
      gc_error_debug := 'Start Extracting new AB Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);

      -- lcu_active_AB_cust cursor Loop started here
      OPEN lcu_new_AB_cust;

      gc_error_debug := 'Loop started here for fetching new AB customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_new_AB_cust
         BULK COLLECT INTO elg_incr_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. elg_incr_tbl_type.COUNT
            INSERT INTO xx_crm_wcelg_cust
                 VALUES elg_incr_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_new_AB_cust%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop started here for fetching new AB customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_new_AB_cust;

      -- lcu_active_AB_cust cursor Loop Ended here
      gc_error_debug := 'End of Extracting new AB Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in FIND_NEW_AB procedure' || gc_error_debug);
         p_retcode := 2;
   -- End of find_new_AB procedure
   END find_new_AB;

-- +===============================================================================+
-- | Name       : find_cust_hierarchy                                              |
-- |                                                                               |
-- | Description: This procedure is used to fetch the parents of                   |
-- |                     customers into eligibility table                          |
-- |                                                                               |
-- | Parameters : p_last_run_date                                                  |
-- |              p_to_run_date                                                    |
-- |              p_batch_limit                                                    |
-- |              p_sample_count                                                   |
-- |              p_action                                                         |
-- | Returns    : p_retcode                                                        |
-- +===============================================================================+
   PROCEDURE find_cust_hierarchy (
      p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_action          IN       VARCHAR2
     ,p_retcode         OUT      NUMBER
   )
   IS
      --Table type declaration
      hier_full_tbl_type   lt_cust_elg;
      hier_incr_tbl_type   lt_cust_elg;
      hier_temp_tbl_type   lt_cust_elg;
      --Variable declaration
      ln_batch_limit       NUMBER;

      --cursor declaration
      CURSOR lcu_cust_hierarchy
      IS
         SELECT HCA.party_id "party_id"
               ,HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "account_number"
               ,'CA' "int_source"
               ,NULL "extraction_date"
               ,'N' "cust_mast_head_ext"
               ,'N' "cust_addr_ext"
               ,'N' "cust_cont_ext"
               ,'N' "cust_hier_ext"
               ,'N' "sls_per_ext"
               ,'N' "ar_converted_flag"
               ,'' "ar_conv_from_date_full"
               ,'' "ar_conv_to_date_full"
               ,'N' "notes_processed_to_wc"
               ,gd_last_update_date "last_update_date"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_created_by "created_by"
               ,gn_request_id "request_id"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_accounts HCA
               ,hz_relationships HZ_RELATE
          WHERE EC.party_id = HZ_RELATE.subject_id
            AND HZ_RELATE.object_id = HCA.party_id
            AND HZ_RELATE.directional_flag = 'F'
            AND HZ_RELATE.relationship_type IN ('OD_FIN_HIER', 'OD_FIN_PAY_WITHIN')
            AND nvl(HZ_RELATE.end_date, sysdate + 1) > FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_crm_wcelg_cust EC_PAR
                             WHERE EC_PAR.cust_account_id = HCA.cust_account_id)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_ar_intstorecust_otc INT_CUST
                             WHERE INT_CUST.cust_account_id = HCA.cust_account_id);

      CURSOR lcu_cust_hierarchy_incr
      IS
         SELECT HCA.party_id "party_id"
               ,HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "account_number"
               ,'CA' "int_source"
               ,NULL "extraction_date"
               ,'N' "cust_mast_head_ext"
               ,'N' "cust_addr_ext"
               ,'N' "cust_cont_ext"
               ,'N' "cust_hier_ext"
               ,'N' "sls_per_ext"
               ,'N' "ar_converted_flag"
               ,'' "ar_conv_from_date_full"
               ,'' "ar_conv_to_date_full"
               ,'N' "notes_processed_to_wc"
               ,gd_last_update_date "last_update_date"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_created_by "created_by"
               ,gn_request_id "request_id"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_accounts HCA
               ,hz_relationships HZ_RELATE
          WHERE EC.party_id = HZ_RELATE.subject_id
            AND HZ_RELATE.object_id = HCA.party_id
            AND HZ_RELATE.directional_flag = 'F'
            AND HZ_RELATE.relationship_type IN ('OD_FIN_HIER', 'OD_FIN_PAY_WITHIN')
            AND HCA.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCA.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_crm_wcelg_cust EC_PAR
                             WHERE EC_PAR.cust_account_id = HCA.cust_account_id)
            AND NOT EXISTS (SELECT '1'
                              FROM xx_ar_intstorecust_otc INT_CUST
                             WHERE INT_CUST.cust_account_id = HCA.cust_account_id);

      CURSOR lcu_cust_hierarchy_temp
      IS
         SELECT UNIQUE HIER.party_id
                      ,HIER.cust_account_id
                      ,HIER.account_number
                      ,HIER.int_source
                      ,HIER.extraction_date
                      ,HIER.cust_mast_head_ext
                      ,HIER.cust_addr_ext
                      ,HIER.cust_cont_ext
                      ,HIER.cust_hier_ext
                      ,HIER.sls_per_ext
                      ,HIER.ar_converted_flag
                      ,HIER.ar_conv_from_date_full
                      ,HIER.ar_conv_to_date_full
                      ,HIER.notes_processed_to_wc
                      ,HIER.last_update_date
                      ,HIER.last_updated_by
                      ,HIER.creation_date
                      ,HIER.created_by
                      ,HIER.request_id
                      ,HIER.program_id
                  FROM xx_crm_hierarchy_temp HIER;
   BEGIN
      ln_batch_limit := p_batch_limit;
      gc_error_debug := 'Start Extracting Hierarchy Parents of Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before Trucating hierarchy temp Table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_hierarchy_temp';

      IF p_action = 'F'
      THEN
         --lcu_customer Hierarchy  cursor Loop started here
         OPEN lcu_cust_hierarchy;

         gc_error_debug := 'Loop started here for fetching immediate parent for existing customers into temporary table';
         write_log (gc_debug_flag, gc_error_debug);

         LOOP
            FETCH lcu_cust_hierarchy
            BULK COLLECT INTO hier_full_tbl_type LIMIT ln_batch_limit;

            FORALL i IN 1 .. hier_full_tbl_type.COUNT
               INSERT INTO xx_crm_hierarchy_temp
                    VALUES hier_full_tbl_type (i);
            COMMIT;
            EXIT WHEN lcu_cust_hierarchy%NOTFOUND;
         END LOOP;

         gc_error_debug := 'Loop ended here for fetching immediate parent for existing customers into temporary table';
         write_log (gc_debug_flag, gc_error_debug);

         --lcu_customer Hierarchy  cursor Loop Ended here
         CLOSE lcu_cust_hierarchy;
      ELSE
         --lcu_customer_hierarchy  cursor Loop started here
         OPEN lcu_cust_hierarchy_incr;

         gc_error_debug := 'Loop started here for fetching incremental immediate parent for existing customers into temporary table';
         write_log (gc_debug_flag, gc_error_debug);

         LOOP
            FETCH lcu_cust_hierarchy_incr
            BULK COLLECT INTO hier_incr_tbl_type LIMIT ln_batch_limit;

            FORALL i IN 1 .. hier_incr_tbl_type.COUNT
               INSERT INTO xx_crm_hierarchy_temp
                    VALUES hier_incr_tbl_type (i);
            COMMIT;
            EXIT WHEN lcu_cust_hierarchy_incr%NOTFOUND;
         END LOOP;

         gc_error_debug := 'Loop ended here for fetching incremental immediate parent for existing customers into temporary table';
         write_log (gc_debug_flag, gc_error_debug);

         --lcu_customer_hierarchy  cursor Loop Ended here
         CLOSE lcu_cust_hierarchy_incr;
      END IF;

      --lcu_cust_hierarchy_temp  cursor Loop started here
      OPEN lcu_cust_hierarchy_temp;

      gc_error_debug := 'Loop started here for fetching immediate parent for existing customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_cust_hierarchy_temp
         BULK COLLECT INTO hier_temp_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. hier_temp_tbl_type.COUNT
            INSERT INTO xx_crm_wcelg_cust
                 VALUES hier_temp_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_cust_hierarchy_temp%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop ended here for fetching immediate parent for existing customers into eligibility table';
      write_log (gc_debug_flag, gc_error_debug);

      --lcu_cust_hierarchy_temp  cursor Loop Ended here
      CLOSE lcu_cust_hierarchy_temp;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_WCELG_CUST'
                    );
      gc_error_debug := 'End of Extracting hierarchy Customers into eligibility table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in FIND_CUST_HIERARCHY procedure' || gc_error_debug);
         p_retcode := 2;
   --End of find_cust_hierarchy
   END find_cust_hierarchy;

PROCEDURE sp_daily_cdh_report (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
   )
   IS
	conn utl_smtp.connection;
	smtp_svr	VARCHAR2(240) ;
	return_name	VARCHAR2(240) ;
	from_name	VARCHAR2(240) ;
	to_name		VARCHAR2(240) ;
	v_smtp_server_port PLS_INTEGER ;
	subject VARCHAR2(240)  ;
	message VARCHAR2(240);
	message_html VARCHAR2(32767);
	message_html_ar VARCHAR2(32767);
	msg VARCHAR2(32767);
	v_reply utl_smtp.reply;


	v_headerstagestart	VARCHAR2(100) := 'NA';
	v_headerstageend	VARCHAR2(100) := 'NA';
	v_headerstagefilen	VARCHAR2(100) := 'NA';
	v_headerstagecount	VARCHAR2(100) := 'NA';
	v_addressesstagestart	VARCHAR2(100) := 'NA';
	v_addressesstageend	VARCHAR2(100) := 'NA';
	v_addressesstagefilen	VARCHAR2(100) := 'NA';
	v_addressesstagecount	VARCHAR2(100) := 'NA';
	v_contactsstagestart	VARCHAR2(100) := 'NA';
	v_contactsstageend	VARCHAR2(100) := 'NA';
	v_contactsstagefilen	VARCHAR2(100) := 'NA';
	v_contactsstagecount	VARCHAR2(100) := 'NA';
	v_assignmentstagestart	VARCHAR2(100) := 'NA';
	v_assignmentstageend	VARCHAR2(100) := 'NA';
	v_assignmentstagefilen	VARCHAR2(100) := 'NA';
	v_assignmentstagecount	VARCHAR2(100) := 'NA';
	v_hierarchystagestart	VARCHAR2(100) := 'NA';
	v_hierarchystageend	VARCHAR2(100) := 'NA';
	v_hierarchystagefilen	VARCHAR2(100) := 'NA';
	v_hierarchystagecount	VARCHAR2(100) := 'NA';
	gc_error_debug		VARCHAR2(100);

	v_reconciliationbatchnum3	VARCHAR2(100) := 'NA';
	v_reconciliationstart3		VARCHAR2(100) := 'NA';
	v_reconciliationend3		VARCHAR2(100) := 'NA';
	v_reconciliationfilen3		VARCHAR2(100) := 'NA';
	v_reconciliationcycle3		VARCHAR2(100) := 'NA';
	v_reconciliationfiles3		VARCHAR2(100) := 'NA';
	v_reconciliationcount3		VARCHAR2(100) := 'NA';

	v_receivablebatchnum3		VARCHAR2(100) := '3';
	v_receivablestart3		VARCHAR2(100) := 'NA';
	v_receivableend3		VARCHAR2(100) := 'NA';
	v_receivablefilen3		VARCHAR2(100) := 'NA';
	v_receivablecycle3		VARCHAR2(100) := 'NA';
	v_receivablefiles3		VARCHAR2(100) := 'NA';
	v_receivablecount3		VARCHAR2(100) := 'NA';
	v_receivablebatchnum2		VARCHAR2(100) := '2';
	v_receivablestart2		VARCHAR2(100) := 'NA';
	v_receivableend2		VARCHAR2(100) := 'NA';
	v_receivablefilen2		VARCHAR2(100) := 'NA';
	v_receivablecycle2		VARCHAR2(100) := 'NA';
	v_receivablefiles2		VARCHAR2(100) := 'NA';
	v_receivablecount2		VARCHAR2(100) := 'NA';
	v_receivablebatchnum1		VARCHAR2(100) := '1';
	v_receivablestart1		VARCHAR2(100) := 'NA';
	v_receivableend1		VARCHAR2(100) := 'NA';
	v_receivablefilen1		VARCHAR2(100) := 'NA';
	v_receivablecycle1		VARCHAR2(100) := 'NA';
	v_receivablefiles1		VARCHAR2(100) := 'NA';
	v_receivablecount1		VARCHAR2(100) := 'NA';




	v_paymentbatchnum3	VARCHAR2(100) := '3';
	v_paymentstart3		VARCHAR2(100) := 'NA';
	v_paymentend3		VARCHAR2(100) := 'NA';
	v_paymentfilen3		VARCHAR2(100) := 'NA';
	v_paymentcycle3		VARCHAR2(100) := 'NA';
	v_paymentfiles3		VARCHAR2(100) := 'NA';
	v_paymentcount3		VARCHAR2(100) := 'NA';
	v_paymentbatchnum2	VARCHAR2(100) := '2';
	v_paymentstart2		VARCHAR2(100) := 'NA';
	v_paymentend2		VARCHAR2(100) := 'NA';
	v_paymentfilen2		VARCHAR2(100) := 'NA';
	v_paymentcycle2		VARCHAR2(100) := 'NA';
	v_paymentfiles2		VARCHAR2(100) := 'NA';
	v_paymentcount2		VARCHAR2(100) := 'NA';
	v_paymentbatchnum1	VARCHAR2(100) := '1';
	v_paymentstart1		VARCHAR2(100) := 'NA';
	v_paymentend1		VARCHAR2(100) := 'NA';
	v_paymentfilen1		VARCHAR2(100) := 'NA';
	v_paymentcycle1		VARCHAR2(100) := 'NA';
	v_paymentfiles1		VARCHAR2(100) := 'NA';
	v_paymentcount1		VARCHAR2(100) := 'NA';



	v_transactionbatchnum3		VARCHAR2(100) := '3';
	v_transactionstart3		VARCHAR2(100) := 'NA';
	v_transactionend3		VARCHAR2(100) := 'NA';
	v_transactionfilen3		VARCHAR2(100) := 'NA';
	v_transactioncycle3		VARCHAR2(100) := 'NA';
	v_transactionfiles3		VARCHAR2(100) := 'NA';
	v_transactioncount3		VARCHAR2(100) := 'NA';
	v_transactionbatchnum2		VARCHAR2(100) := '2';
	v_transactionstart2		VARCHAR2(100) := 'NA';
	v_transactionend2		VARCHAR2(100) := 'NA';
	v_transactionfilen2		VARCHAR2(100) := 'NA';
	v_transactioncycle2		VARCHAR2(100) := 'NA';
	v_transactionfiles2		VARCHAR2(100) := 'NA';
	v_transactioncount2		VARCHAR2(100) := 'NA';
	v_transactionbatchnum1		VARCHAR2(100) := '1';
	v_transactionstart1		VARCHAR2(100) := 'NA';
	v_transactionend1		VARCHAR2(100) := 'NA';
	v_transactionfilen1		VARCHAR2(100) := 'NA';
	v_transactioncycle1		VARCHAR2(100) := 'NA';
	v_transactionfiles1		VARCHAR2(100) := 'NA';
	v_transactioncount1		VARCHAR2(100) := 'NA';



	v_adjustmentbatchnum3		VARCHAR2(100) := '3';
	v_adjustmentstart3		VARCHAR2(100) := 'NA';
	v_adjustmentend3		VARCHAR2(100) := 'NA';
	v_adjustmentfilen3		VARCHAR2(100) := 'NA';
	v_adjustmentcycle3		VARCHAR2(100) := 'NA';
	v_adjustmentfiles3		VARCHAR2(100) := 'NA';
	v_adjustmentcount3		VARCHAR2(100) := 'NA';
	v_adjustmentbatchnum2		VARCHAR2(100) := '2';
	v_adjustmentstart2		VARCHAR2(100) := 'NA';
	v_adjustmentend2		VARCHAR2(100) := 'NA';
	v_adjustmentfilen2		VARCHAR2(100) := 'NA';
	v_adjustmentcycle2		VARCHAR2(100) := 'NA';
	v_adjustmentfiles2		VARCHAR2(100) := 'NA';
	v_adjustmentcount2		VARCHAR2(100) := 'NA';
	v_adjustmentbatchnum1		VARCHAR2(100) := '1';
	v_adjustmentstart1		VARCHAR2(100) := 'NA';
	v_adjustmentend1		VARCHAR2(100) := 'NA';
	v_adjustmentfilen1		VARCHAR2(100) := 'NA';
	v_adjustmentcycle1		VARCHAR2(100) := 'NA';
	v_adjustmentfiles1		VARCHAR2(100) := 'NA';
	v_adjustmentcount1		VARCHAR2(100) := 'NA';


	v_receiptbatchnum3	VARCHAR2(100) := '3';
	v_receiptstart3		VARCHAR2(100) := 'NA';
	v_receiptend3		VARCHAR2(100) := 'NA';
	v_receiptfilen3		VARCHAR2(100) := 'NA';
	v_receiptcycle3		VARCHAR2(100) := 'NA';
	v_receiptfiles3		VARCHAR2(100) := 'NA';
	v_receiptcount3		VARCHAR2(100) := 'NA';
	v_receiptbatchnum2	VARCHAR2(100) := '2';
	v_receiptstart2		VARCHAR2(100) := 'NA';
	v_receiptend2		VARCHAR2(100) := 'NA';
	v_receiptfilen2		VARCHAR2(100) := 'NA';
	v_receiptcycle2		VARCHAR2(100) := 'NA';
	v_receiptfiles2		VARCHAR2(100) := 'NA';
	v_receiptcount2		VARCHAR2(100) := 'NA';
	v_receiptbatchnum1	VARCHAR2(100) := '1';
	v_receiptstart1		VARCHAR2(100) := 'NA';
	v_receiptend1		VARCHAR2(100) := 'NA';
	v_receiptfilen1		VARCHAR2(100) := 'NA';
	v_receiptcycle1		VARCHAR2(100) := 'NA';
	v_receiptfiles1		VARCHAR2(100) := 'NA';
	v_receiptcount1		VARCHAR2(100) := 'NA';


	v_notesbatchnum3	VARCHAR2(100) := '3';
	v_notesstart3		VARCHAR2(100) := 'NA';
	v_notesend3		VARCHAR2(100) := 'NA';
	v_notesfilen3		VARCHAR2(100) := 'NA';
	v_notescycle3		VARCHAR2(100) := 'NA';
	v_notesfiles3		VARCHAR2(100) := 'NA';
	v_notescount3		VARCHAR2(100) := 'NA';
	v_notesbatchnum2	VARCHAR2(100) := '2';
	v_notesstart2		VARCHAR2(100) := 'NA';
	v_notesend2		VARCHAR2(100) := 'NA';
	v_notesfilen2		VARCHAR2(100) := 'NA';
	v_notescycle2		VARCHAR2(100) := 'NA';
	v_notesfiles2		VARCHAR2(100) := 'NA';
	v_notescount2		VARCHAR2(100) := 'NA';
	v_notesbatchnum1	VARCHAR2(100) := '1';
	v_notesstart1		VARCHAR2(100) := 'NA';
	v_notesend1		VARCHAR2(100) := 'NA';
	v_notesfilen1		VARCHAR2(100) := 'NA';
	v_notescycle1		VARCHAR2(100) := 'NA';
	v_notesfiles1		VARCHAR2(100) := 'NA';
	v_notescount1		VARCHAR2(100) := 'NA';

	CURSOR cur_wc_delta
	IS
	SELECT * FROM
		(
			SELECT  a.program_short_name program, to_char(a.actual_start_date,'DD-MON-RRRR HH24:MI:SS') actual_start_date,
				to_char(a.actual_completion_date,'DD-MON-RRRR HH24:MI:SS') actual_completion_date,
				a.request_id, b.filename,
				ROW_NUMBER() OVER (PARTITION BY a.program ORDER BY a.actual_start_date desc  ) RECORD_ID
			FROM fnd_conc_req_summary_v a, xx_crmar_int_log b
			WHERE  a.request_id = b.request_id(+)
				AND   trunc(a.actual_start_date)>trunc(sysdate-7) AND -- Need 1 day records only
				a.program_short_name IN
				(
				'XX_CRM_CUST_HEAD_STAGE_EXTR',
				'XX_CRM_CUST_ADDR_STAGE_EXTR',
				'XX_CRM_CUST_CONT_STAGE_EXTR',
				'XX_CRM_CUST_HIER_STAGE_EXTR',
				'XX_CRM_CUST_SLSAS_STAGE_EXTR',
				'XX_CRM_SCRAMBLER_ACCOUNT',
				'XX_CRM_SCRAMBLER_ADDRESS',
				'XX_CRM_SCRAMBLER_CONTACT'
				)
		)
		WHERE record_id=1
		ORDER BY request_id;

	CURSOR cur_wc_delta_ar
	IS
	SELECT * FROM
	(
	 SELECT
		a.program_short_name ,
		DECODE (a.program_short_name ,'XXARTXNEXTWC','AR Transactions'
				,'XXARCREXTWC','AR Receipts'
				,'XXARADJEXTWC','AR Adjustments'
				,'XXARPSEXTWC','AR Payment Schedules'
				,'XXARRAEXTWC','AR Receivable Applications'
				,'XXIEXEXTWC','IEX Diary Notes'
				,'XXARCDHRECON','AR Reconciliation') Concurrent_Program_Name,
		TO_CHAR(b.actual_start_date,'DD-MON-RRRR HH24:MI:SS') actual_start_date,
		TO_CHAR(b.actual_completion_date,'DD-MON-RRRR HH24:MI:SS') actual_completion_date,
		a.cycle_date         ,
		a.total_files        ,
		a.total_records      ,
		a.batch_num,
		a.filename,
		ROW_NUMBER() OVER (PARTITION BY a.program_name, a.batch_num ORDER BY a.program_run_date DESC  ) RECORD_ID
	  FROM xx_crmar_int_log A, fnd_conc_req_summary_v b
	  WHERE a.request_id = b.request_id
	  AND a.program_short_name IN ('XXIEXEXTWC' ,'XXARRAEXTWC' ,'XXARADJEXTWC' ,'XXARPSEXTWC' ,'XXARCREXTWC' ,'XXARTXNEXTWC','XXARCDHRECON')
	  AND TRUNC(b.actual_start_date)>TRUNC(sysdate-7)  -- Need 1 day records only
	)
	WHERE record_id=1
	ORDER BY actual_completion_date DESC;



	CURSOR cur_wc_emaillist (to_name IN varchar2)
	IS
	SELECT regexp_substr(to_name,'[^;]+', 1, LEVEL) email_list FROM DUAL
	CONNECT BY regexp_substr(to_name, '[^;]+', 1, level) is not null;

BEGIN



      SELECT xftv.target_value1, xftv.target_value2, xftv.target_value3, xftv.target_value4, xftv.target_value5, xftv.target_value6
        INTO smtp_svr, return_name, from_name,  v_smtp_server_port,to_name, subject
        FROM xx_fin_translatedefinition XFTD ,
             xx_fin_translatevalues XFTV
       WHERE XFTV.translate_id = XFTD.translate_id
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
         AND XFTV.source_value1    = 'XX_CRM_OUTBOUND_NOTIFY'
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.enabled_flag     = 'Y'
         AND XFTD.enabled_flag     = 'Y';


--------------------------------------------- CDH Start----------------------------------------------
	FOR cur_wc_delta_rec IN cur_wc_delta
	LOOP


		IF cur_wc_delta_rec.program = 'XX_CRM_CUST_HEAD_STAGE_EXTR' OR cur_wc_delta_rec.program = 'XX_CRM_SCRAMBLER_ACCOUNT' THEN
			v_headerstagestart := cur_wc_delta_rec.actual_start_date;
			v_headerstageend := cur_wc_delta_rec.actual_completion_date;
			v_headerstagefilen := cur_wc_delta_rec.filename;

			SELECT COUNT(*)
			INTO v_headerstagecount
			FROM xx_crm_custmast_head_stg;

		END IF;


		IF cur_wc_delta_rec.program = 'XX_CRM_CUST_ADDR_STAGE_EXTR' OR cur_wc_delta_rec.program = 'XX_CRM_SCRAMBLER_ADDRESS' THEN
			v_addressesstagestart := cur_wc_delta_rec.actual_start_date;
			v_addressesstageend := cur_wc_delta_rec.actual_completion_date;
			v_addressesstagefilen := cur_wc_delta_rec.filename;

			SELECT COUNT(*)
			INTO v_addressesstagecount
			FROM xx_crm_custaddr_stg;

		END IF;


		IF cur_wc_delta_rec.program = 'XX_CRM_CUST_CONT_STAGE_EXTR' OR cur_wc_delta_rec.program = 'XX_CRM_SCRAMBLER_CONTACT' THEN
			v_contactsstagestart := cur_wc_delta_rec.actual_start_date;
			v_contactsstageend := cur_wc_delta_rec.actual_completion_date;
			v_contactsstagefilen := cur_wc_delta_rec.filename;

			SELECT COUNT(*)
			INTO v_contactsstagecount
			FROM xx_crm_custcont_stg;

		END IF;


		IF cur_wc_delta_rec.program = 'XX_CRM_CUST_SLSAS_STAGE_EXTR' THEN
			v_assignmentstagestart := cur_wc_delta_rec.actual_start_date;
			v_assignmentstageend := cur_wc_delta_rec.actual_completion_date;
			v_assignmentstagefilen := cur_wc_delta_rec.filename;

			SELECT COUNT(*)
			INTO v_assignmentstagecount
			FROM xx_crm_custsls_stg;

		END IF;

		IF cur_wc_delta_rec.program = 'XX_CRM_CUST_HIER_STAGE_EXTR' THEN
			v_hierarchystagestart := cur_wc_delta_rec.actual_start_date;
			v_hierarchystageend := cur_wc_delta_rec.actual_completion_date;
			v_hierarchystagefilen := cur_wc_delta_rec.filename;

			SELECT COUNT(*)
			INTO v_hierarchystagecount
			FROM xx_crm_custhier_stg;

		END IF;


	END LOOP;

-- removed format of html code due to datasize limitation
  message_html  :=
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"> <HTML><HEAD> <META content="text/html; charset=us-ascii" http-equiv=Content-Type> <META name=GENERATOR content="MSHTML 8.00.6001.19154"></HEAD> <BODY> <DIV dir=ltr align=left><FONT color=#0000ff size=2 face=Arial></FONT> <FONT color=#0000ff size=2 face=Arial></FONT><BR>;</DIV> <TABLE border=1 cellSpacing=0 cellPadding=0 width=700>   <TBODY>
<TR>
<TD bgColor=lime height=30 width=700 colSpan=5 align=middle nowrap="nowrap"><B><FONT
color=black size=2 face="Trebuchet MS">Webcollect Daily Conversion Report - CDH </FONT></B></TD></TR>
<TR>
<TD bgColor="#BBFFFF" height=25 width="40%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS">        Concurrent Program      </FONT></B></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>     Start Time      </P></FONT></TD>     <TD bgColor="#BBFFFF" height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>     End Time      </P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>    File Name     </P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>Total Count</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS"> Customer Master Header </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_headerstagestart||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_headerstageend||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_headerstagefilen||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_headerstagecount||' </P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS"> Customer Addresses </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_addressesstagestart||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_addressesstageend||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_addressesstagefilen||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_addressesstagecount||' </P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS"> Customer Contacts </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_contactsstagestart||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_contactsstageend||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_contactsstagefilen||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_contactsstagecount||' </P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS"> Sales Person Assignment </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_assignmentstagestart||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_assignmentstageend||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_assignmentstagefilen||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_assignmentstagecount||' </P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap"><B><FONT size=2
face="Trebuchet MS"> Customer Hierarchy </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_hierarchystagestart||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_hierarchystageend||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_hierarchystagefilen||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_hierarchystagecount||'</P></FONT></TD></TR>
</TBODY></TABLE><br><br></BODY></HTML>';

--------------------------------------------- CDH End----------------------------------------------


--------------------------------------------- AR Start----------------------------------------------
	FOR cur_wc_delta_ar_rec IN cur_wc_delta_ar
	LOOP

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Reconciliation'   THEN

			v_reconciliationbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_reconciliationstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_reconciliationend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_reconciliationfilen3 := cur_wc_delta_ar_rec.filename;
			v_reconciliationcycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_reconciliationfiles3 := cur_wc_delta_ar_rec.total_files;
			v_reconciliationcount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receivable Applications' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_receivablebatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_receivablestart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_receivableend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receivablefilen3 := cur_wc_delta_ar_rec.filename;
			v_receivablecycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_receivablefiles3 := cur_wc_delta_ar_rec.total_files;
			v_receivablecount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receivable Applications' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_receivablebatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_receivablestart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_receivableend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receivablefilen2 := cur_wc_delta_ar_rec.filename;
			v_receivablecycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_receivablefiles2 := cur_wc_delta_ar_rec.total_files;
			v_receivablecount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receivable Applications' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_receivablebatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_receivablestart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_receivableend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receivablefilen1 := cur_wc_delta_ar_rec.filename;
			v_receivablecycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_receivablefiles1 := cur_wc_delta_ar_rec.total_files;
			v_receivablecount1 := cur_wc_delta_ar_rec.total_records;

		END IF;



		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Payment Schedules' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_paymentbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_paymentstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_paymentend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_paymentfilen3 := cur_wc_delta_ar_rec.filename;
			v_paymentcycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_paymentfiles3 := cur_wc_delta_ar_rec.total_files;
			v_paymentcount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Payment Schedules' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_paymentbatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_paymentstart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_paymentend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_paymentfilen2 := cur_wc_delta_ar_rec.filename;
			v_paymentcycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_paymentfiles2 := cur_wc_delta_ar_rec.total_files;
			v_paymentcount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Payment Schedules' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_paymentbatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_paymentstart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_paymentend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_paymentfilen1 := cur_wc_delta_ar_rec.filename;
			v_paymentcycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_paymentfiles1 := cur_wc_delta_ar_rec.total_files;
			v_paymentcount1 := cur_wc_delta_ar_rec.total_records;

		END IF;



		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Transactions' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_transactionbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_transactionstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_transactionend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_transactionfilen3 := cur_wc_delta_ar_rec.filename;
			v_transactioncycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_transactionfiles3 := cur_wc_delta_ar_rec.total_files;
			v_transactioncount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Transactions' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_transactionbatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_transactionstart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_transactionend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_transactionfilen2 := cur_wc_delta_ar_rec.filename;
			v_transactioncycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_transactionfiles2 := cur_wc_delta_ar_rec.total_files;
			v_transactioncount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Transactions' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_transactionbatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_transactionstart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_transactionend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_transactionfilen1 := cur_wc_delta_ar_rec.filename;
			v_transactioncycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_transactionfiles1 := cur_wc_delta_ar_rec.total_files;
			v_transactioncount1 := cur_wc_delta_ar_rec.total_records;

		END IF;



		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Adjustments' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_adjustmentbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_adjustmentstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_adjustmentend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_adjustmentfilen3 := cur_wc_delta_ar_rec.filename;
			v_adjustmentcycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_adjustmentfiles3 := cur_wc_delta_ar_rec.total_files;
			v_adjustmentcount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Adjustments' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_adjustmentbatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_adjustmentstart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_adjustmentend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_adjustmentfilen2 := cur_wc_delta_ar_rec.filename;
			v_adjustmentcycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_adjustmentfiles2 := cur_wc_delta_ar_rec.total_files;
			v_adjustmentcount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Adjustments' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_adjustmentbatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_adjustmentstart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_adjustmentend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_adjustmentfilen1 := cur_wc_delta_ar_rec.filename;
			v_adjustmentcycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_adjustmentfiles1 := cur_wc_delta_ar_rec.total_files;
			v_adjustmentcount1 := cur_wc_delta_ar_rec.total_records;

		END IF;



		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receipts' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_receiptbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_receiptstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_receiptend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receiptfilen3 := cur_wc_delta_ar_rec.filename;
			v_receiptcycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_receiptfiles3 := cur_wc_delta_ar_rec.total_files;
			v_receiptcount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receipts' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_receiptbatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_receiptstart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_receiptend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receiptfilen2 := cur_wc_delta_ar_rec.filename;
			v_receiptcycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_receiptfiles2 := cur_wc_delta_ar_rec.total_files;
			v_receiptcount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='AR Receipts' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_receiptbatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_receiptstart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_receiptend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_receiptfilen1 := cur_wc_delta_ar_rec.filename;
			v_receiptcycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_receiptfiles1 := cur_wc_delta_ar_rec.total_files;
			v_receiptcount1 := cur_wc_delta_ar_rec.total_records;

		END IF;


		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='IEX Diary Notes' AND cur_wc_delta_ar_rec.batch_num = '3'  THEN

			v_notesbatchnum3 := cur_wc_delta_ar_rec.batch_num;
			v_notesstart3 := cur_wc_delta_ar_rec.actual_start_date;
			v_notesend3 := cur_wc_delta_ar_rec.actual_completion_date;
			v_notesfilen3 := cur_wc_delta_ar_rec.filename;
			v_notescycle3 := cur_wc_delta_ar_rec.cycle_date;
			v_notesfiles3 := cur_wc_delta_ar_rec.total_files;
			v_notescount3 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='IEX Diary Notes' AND cur_wc_delta_ar_rec.batch_num = '2'  THEN

			v_notesbatchnum2 := cur_wc_delta_ar_rec.batch_num;
			v_notesstart2 := cur_wc_delta_ar_rec.actual_start_date;
			v_notesend2 := cur_wc_delta_ar_rec.actual_completion_date;
			v_notesfilen2 := cur_wc_delta_ar_rec.filename;
			v_notescycle2 := cur_wc_delta_ar_rec.cycle_date;
			v_notesfiles2 := cur_wc_delta_ar_rec.total_files;
			v_notescount2 := cur_wc_delta_ar_rec.total_records;

		END IF;

		IF cur_wc_delta_ar_rec.Concurrent_Program_Name='IEX Diary Notes' AND cur_wc_delta_ar_rec.batch_num = '1'  THEN

			v_notesbatchnum1 := cur_wc_delta_ar_rec.batch_num;
			v_notesstart1 := cur_wc_delta_ar_rec.actual_start_date;
			v_notesend1 := cur_wc_delta_ar_rec.actual_completion_date;
			v_notesfilen1 := cur_wc_delta_ar_rec.filename;
			v_notescycle1 := cur_wc_delta_ar_rec.cycle_date;
			v_notesfiles1 := cur_wc_delta_ar_rec.total_files;
			v_notescount1 := cur_wc_delta_ar_rec.total_records;

		END IF;

	END LOOP;

-- removed format of html code due to datasize limitation
message_html_ar  :=
'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"> <HTML><HEAD> <META content="text/html; charset=us-ascii" http-equiv=Content-Type> <META name=GENERATOR content="MSHTML 8.00.6001.19154"></HEAD> <BODY> <DIV dir=ltr align=left><FONT color=#0000ff size=2 face=Arial></FONT> <FONT color=#0000ff size=2 face=Arial></FONT><BR>;</DIV> <TABLE border=1 cellSpacing=0 cellPadding=0 width=700>   <TBODY>
<TR>
<TD bgColor=lime height=30 width=1000 colSpan=8 align=middle nowrap="nowrap"><B><FONT
color=black size=2 face="Trebuchet MS">Webcollect Daily Conversion Report - AR </FONT></B></TD></TR>
<TR>
<TD bgColor="#BBFFFF" height=25 width="60%" align=middle ><B><FONT size=2
face="Trebuchet MS">Concurrent Program</FONT></B></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>Cycle Date </P></FONT></TD>     <TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>Batch Num</P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
  <P>Start Time</P></FONT></TD>     <TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P> End Date</P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P> File Name </P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>Total Files</P></FONT></TD>
<TD bgColor="#BBFFFF" height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
  <P>Total Records</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Reconciliation </FONT></B></TD>
<TD height=25 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationcycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationbatchnum3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
   <P>'||v_reconciliationstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap"e><FONT size=2 face="Trebuchet MS">
<P>'||v_reconciliationcount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=5 width="25%" align=middle><B><FONT size=2
face="Trebuchet MS">  </FONT></B></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
   <P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap" ><B><FONT size=2
face="Trebuchet MS"> Ar Receivable Applications </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablebatchnum3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receivablestart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivableend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Payment Schedules </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentbatchnum3||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_paymentstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Transactions </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionbatchnum3||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Adjustments </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentbatchnum3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Receipts </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptbatchnum3||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> IEX Diary Notes </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescycle3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesbatchnum3||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesstart3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesend3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfilen3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfiles3||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescount3||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=5 width="25%" align=middle><B><FONT size=2
face="Trebuchet MS">  </FONT></B></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
   <P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap" ><B><FONT size=2
face="Trebuchet MS"> Ar Receivable Applications </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receivablebatchnum2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receivablestart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivableend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Payment Schedules </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_paymentbatchnum2||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_paymentstart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Transactions </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionbatchnum2||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionstart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Adjustments </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentbatchnum2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentstart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Receipts </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptbatchnum2||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptstart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> IEX Diary Notes </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescycle2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesbatchnum2||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesstart2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesend2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfilen2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfiles2||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescount2||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=5 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS">  </FONT></B></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD>
<TD bgColor=cyan height=5 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P></P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle nowrap="nowrap" ><B><FONT size=2
face="Trebuchet MS"> Ar Receivable Applications </FONT></B></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receivablebatchnum1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receivablestart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivableend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablefiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle nowrap="nowrap" ><FONT size=2 face="Trebuchet MS">
<P>'||v_receivablecount1||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Payment Schedules </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_paymentbatchnum1||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_paymentstart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentfiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_paymentcount1||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Transactions </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionbatchnum1||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_transactionstart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactionfiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_transactioncount1||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Adjustments </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentbatchnum1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_adjustmentstart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentfiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_adjustmentcount1||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> AR Receipts </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptbatchnum1||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_receiptstart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptfiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_receiptcount1||'</P></FONT></TD></TR>
<TR>
<TD bgColor=silver height=25 width="25%" align=middle ><B><FONT size=2
face="Trebuchet MS"> IEX Diary Notes </FONT></B></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescycle1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesbatchnum1||'</P></FONT></TD>
   <TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
   <P>'||v_notesstart1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesend1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfilen1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notesfiles1||'</P></FONT></TD>
<TD height=25 width="25%" align=middle ><FONT size=2 face="Trebuchet MS">
<P>'||v_notescount1||'</P></FONT></TD></TR>
   </TBODY></TABLE><br><br></BODY></HTML>';

--------------------------------------------- AR End----------------------------------------------



  v_reply := utl_smtp.open_connection( smtp_svr, v_smtp_server_port, conn );
  v_reply := utl_smtp.helo( conn, smtp_svr );
  v_reply := utl_smtp.mail( conn, from_name );


	FOR cur_wc_emaillist_rec IN cur_wc_emaillist(to_name)
	LOOP
		v_reply := utl_smtp.rcpt(conn, cur_wc_emaillist_rec.email_list);
	END LOOP;


  msg := 'Return-Path: '||return_name|| utl_tcp.CRLF ||
         'Sent: '||TO_CHAR( SYSDATE, 'mm/dd/yyyy hh24:mi:ss' )|| utl_tcp.CRLF ||
         'From: '||from_name|| utl_tcp.CRLF ||
         'Subject: '|| subject || utl_tcp.CRLF ||
         'To: '|| to_name || utl_tcp.CRLF ||
--         'Cc: '|| cc_name || utl_tcp.CRLF ||
         'MIME-Version: 1.0'|| utl_tcp.CRLF || -- Use MIME mail standard
         'Content-Type: multipart/mixed; boundary="MIME.Bound"'|| utl_tcp.CRLF || --MIME.Bound really should be a randomly generated string
         utl_tcp.CRLF ||
         '--MIME.Bound' || utl_tcp.CRLF ||
         'Content-Type: multipart/alternative; boundary="MIME.Bound2"'|| utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         '--MIME.Bound2' || utl_tcp.CRLF ||
         'Content-Type: text/plain; '|| utl_tcp.CRLF ||
         'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         message || utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         '--MIME.Bound2' || utl_tcp.CRLF ||
         'Content-Type: text/html;'|| utl_tcp.CRLF ||
         'Content-Transfer_Encoding: 7bit'|| utl_tcp.CRLF ||
         utl_tcp.CRLF ||
         message_html || utl_tcp.CRLF ||
         message_html_ar || utl_tcp.CRLF ||
         '--MIME.Bound2--' || utl_tcp.CRLF ||
         utl_tcp.CRLF;

  utl_smtp.open_data(conn);
  utl_smtp.write_data( conn, msg );


  utl_smtp.write_data( conn, '--MIME.Bound--'); -- End MIME mail

  utl_smtp.write_data( conn, utl_tcp.crlf );
  utl_smtp.close_data( conn );
  utl_smtp.quit( conn );

 gc_error_debug := ' Email has sent ';
 fnd_file.put_line (fnd_file.LOG, gc_error_debug);

EXCEPTION
WHEN OTHERS
THEN
 gc_error_debug := SQLERRM || ' exception is raised in Email Notification Program';
 fnd_file.put_line (fnd_file.LOG, gc_error_debug);
 p_retcode := 2;
END sp_daily_cdh_report;


--+=====================================================================+
--| Name       : main                                                   |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_action_type                                         |
--|               p_last_run_date                                       |
--|               p_to_run_date                                         |
--|               p_sample_count                                        |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
--|               p_batch_limit                                         |
--|                                                                     |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   IS
      -- Variable Declaration
      lc_last_run_date   VARCHAR2 (20);
      lc_to_run_date     VARCHAR2 (20);
      ln_batch           NUMBER;
      ln_sample_count    NUMBER;
      lc_action_type     VARCHAR2 (1);
      ln_batch_limit     NUMBER;
      ln_retcode         NUMBER := 0;
      ld_previous_date   DATE;
      ln_retcode1        NUMBER := 0;
      ln_request_id_p	 NUMBER := 0;
      ln_wcelg_cnt_bef	NUMBER := 0;
      ln_wcelg_cnt	NUMBER := 0;

   BEGIN
      BEGIN
         SELECT XFTV.target_value1
           INTO ln_batch
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'XX_CRM_ELG'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO gn_nextval
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while generating sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         WHEN OTHERS
         THEN
            gc_error_debug := SQLERRM || ' Others exception raised while generating sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
            ln_retcode1 := 2;
      END;


	SELECT COUNT(*) INTO ln_wcelg_cnt_bef FROM xx_crm_wcelg_cust;


      --Variable assignments
      lc_to_run_date := p_to_run_date;
      ln_sample_count := p_sample_count;
      lc_action_type := p_action_type;
      gc_debug_flag := p_debug_flag;
      gc_compute_stats := p_compute_stats;

      IF p_batch_limit IS NULL
      THEN
         ln_batch_limit := ln_batch;
      ELSE
         ln_batch_limit := p_batch_limit;
      END IF;

      BEGIN
         IF p_last_run_date IS NULL
         THEN
            SELECT TO_CHAR (MAX (program_run_date), 'YYYY-MM-DD HH24:MI:SS')
              INTO lc_last_run_date
              FROM xx_crmar_int_log
             WHERE program_short_name = 'XX_CRM_CUST_ELG_PKG' AND status = 'SUCCESS';
         ELSE
            lc_last_run_date := p_last_run_date;
         END IF;

         IF p_to_run_date IS NULL
         THEN
            SELECT TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
              INTO lc_to_run_date
              FROM dual;
         END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found in the Customer Address main procedure';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT LOG.program_run_date
           INTO ld_previous_date
           FROM xx_crmar_int_log LOG
          WHERE LOG.program_short_name = 'XX_CRM_CUST_ELG_PKG'
            AND LOG.program_run_id = (SELECT MAX (LOG1.program_run_id)
                                        FROM xx_crmar_int_log LOG1
                                       WHERE LOG.program_short_name = LOG1.program_short_name AND LOG1.status = 'SUCCESS');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while getting previous run date';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      fnd_file.put_line (fnd_file.LOG, '********** Customer Master Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In:');
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run Date is:' || lc_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run Date is:' || lc_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Sample count is:' || ln_sample_count);
      fnd_file.put_line (fnd_file.LOG, '   Action type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is:' || ln_batch_limit);

      IF lc_action_type = 'F'
      THEN

      ln_request_id_p := fnd_global.conc_request_id ();

         INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,previous_run_date
                     ,program_run_date
                     ,status
                     ,request_id -- V1.1, Added request_id
                     )
              VALUES (gn_nextval
                     ,gc_Program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,NVL (ld_previous_date, SYSDATE)
                     ,SYSDATE
                     ,'Started'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

         find_active_ab_cust (ln_batch_limit
                             ,ln_sample_count
                             ,ln_retcode
                             );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;

         find_open_balance (ln_batch_limit
                           ,ln_sample_count
                           ,ln_retcode
                           );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;

         find_cust_hierarchy (lc_last_run_date
                             ,lc_to_run_date
                             ,ln_batch_limit
                             ,ln_sample_count
                             ,lc_action_type
                             ,ln_retcode
                             );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;

         UPDATE xx_crmar_int_log
            SET status = 'SUCCESS'
               ,MESSAGE = 'Processed'
          WHERE program_run_id = gn_nextval;

         COMMIT;
      ELSIF lc_action_type = 'I'
      THEN
      ln_request_id_p := fnd_global.conc_request_id ();
         INSERT INTO xx_crmar_int_log
                     (program_run_id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,previous_run_date
                     ,program_run_date
                     ,status
                     ,request_id -- V1.1, Added request_id
                     )
              VALUES (gn_nextval
                     ,gc_Program_name
                     ,gc_program_short_name
                     ,gc_module_name
                     ,NVL (ld_previous_date, SYSDATE)
                     ,SYSDATE
                     ,'Started'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

         find_new_AB (lc_last_run_date
                     ,lc_to_run_date
                     ,ln_batch_limit
                     ,ln_sample_count
                     ,ln_retcode
                     );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;

         find_open_balance (ln_batch_limit
                           ,ln_sample_count
                           ,ln_retcode
                           );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;

         find_cust_hierarchy (lc_last_run_date
                             ,lc_to_run_date
                             ,ln_batch_limit
                             ,ln_sample_count
                             ,lc_action_type
                             ,ln_retcode
                             );

         IF ln_retcode != 0
         THEN
            SELECT GREATEST (ln_retcode1, ln_retcode)
              INTO ln_retcode1
              FROM DUAL;
         END IF;


	SELECT NVL(COUNT(*) - ln_wcelg_cnt_bef,0) INTO ln_wcelg_cnt FROM xx_crm_wcelg_cust;

         UPDATE xx_crmar_int_log
            SET total_records = ln_wcelg_cnt
		,status = 'SUCCESS'
               ,MESSAGE = 'Processed'
          WHERE program_run_id = gn_nextval;

         COMMIT;
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'Invalid Entry, Enter either F or I');
      END IF;

      p_retcode := ln_retcode1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the Eligibility main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in Eligibility main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   -- End of the main procedure
   END main;
-- End of the XX_CRM_CUST_ELG_PKG package
END XX_CRM_CUST_ELG_PKG;
/
