CREATE OR REPLACE PACKAGE BODY xx_crm_cust_delta_pkg
AS
--+================================================================================+
--|      Office Depot - Project FIT                                                |
--|   Capgemini Consulting Organization                                            |
--+================================================================================+
--|Name        :XX_CRM_CUST_ELG_PKG                                                |
--| BR #       :106313                                                             |
--|Description :This Package is for identifying incremental data                   |
--|                                                                                |
--|            The STAGING Procedure will perform the following steps              |
--|                                                                                |
--|             1. Identify incremental datafor each customer based on             |
--|                 last upadte date  and insert into common delat ta_oble         |
--|             2. For each table we have one saperate procedure                   |
--|                  to get the incremental data into common delta table           |
--|                                                                                |
--|Change Record:                                                                  |
--|==============                                                                  |
--|Version    Date           Author                       Remarks                  |
--|=======   ======        ====================          =========                 |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version               |
--|1.1      11-Nov-2015   Havish Kasina              Removed the Schema References |
--|                                                  as per R12.2 Retrofit Changes |
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
-- | Description: This procedure is used to to display detailed                    |
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
         fnd_stats.gather_table_stats (ownname      => p_schema
                                      ,tabname => p_tablename);
      END IF;
   END compute_stats;

-- +====================================================================+
-- | Name       : get_delta_parties                                     |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_parties table                                 |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
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
   )
   IS
      -- variable declaration
      ln_batch_limit        NUMBER;
      --table type declaration
      party_full_tbl_type   lt_common_delta;

      --Cursor declaration
      CURSOR lcu_party_delta
      IS
         SELECT 'HZ_PARTIES'
               ,HP.party_id
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM hz_parties HP
               ,xx_crm_wcelg_cust EC
          WHERE HP.party_id = EC.party_id
            AND HP.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HP.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_mast_head_ext = 'Y';

      CURSOR lcu_cust_hier_delta
	IS
         SELECT /*+ LEADING(HOC) INDEX(EC XX_CRM_WCELG_CUST_N2) USE_NL(EC) */
                'HZ_RELATIONSHIPS_HIER'
               ,REL.object_id
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,REL.relationship_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_relationships REL
          WHERE EC.party_id = REL.subject_id
            AND REL.subject_type = 'ORGANIZATION'
            AND REL.OBJECT_TABLE_NAME = 'HZ_PARTIES'
	    AND REL.RELATIONSHIP_TYPE in ('OD_FIN_PAY_WITHIN','OD_FIN_HIER')
            AND REL.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND REL.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_cont_ext = 'Y';

   BEGIN
      gc_error_debug := 'Start of the get_delta_parties procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting parties data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Parties Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      OPEN lcu_party_delta;

      --cm_fulldata curosr Loop started here
      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_party_delta
         BULK COLLECT INTO party_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. party_full_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES party_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_party_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_party_delta;



      OPEN lcu_cust_hier_delta;

      --cm_fulldata curosr Loop started here
      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_cust_hier_delta
         BULK COLLECT INTO party_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. party_full_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES party_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_cust_hier_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_cust_hier_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_parties procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_parties procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_parties procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_parties
   END get_delta_parties;

-- +====================================================================+
-- | Name       : get_delta_cust_accounts                               |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_cust_accounts table                           |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
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
   )
   IS
      --variable declaration
      ln_batch_limit           NUMBER;
      --table type declaration
      cust_accounts_tbl_type   lt_common_delta;

      --Cursor declaration
      CURSOR lcu_cust_accounts_delta
      IS
         SELECT 'HZ_CUST_ACCOUNTS'
               ,HCA.party_id
               ,HCA.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM hz_cust_accounts HCA
          WHERE HCA.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCA.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND HCA.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EXISTS (SELECT '1'
                          FROM xx_crm_wcelg_cust EC
                         WHERE EC.cust_account_id = HCA.cust_account_id AND EC.cust_mast_head_ext = 'Y');
   BEGIN
      gc_error_debug := 'Start of the get_delta_cust_accounts procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting accounts data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Cust Accounts Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_cust_accounts_delta cursor Loop started here
      OPEN lcu_cust_accounts_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_cust_accounts_delta
         BULK COLLECT INTO cust_accounts_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cust_accounts_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES cust_accounts_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_cust_accounts_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_cust_accounts_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_cust_accounts procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_cust_accounts procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_cust_accounts procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_cust_accounts
   END get_delta_cust_accounts;

-- +====================================================================+
-- | Name       : get_delta_contact_points                              |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_contact_points table                          |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_contact_points (
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
   )
   IS
      --variable declaration
      ln_batch_limit            NUMBER;
      --table type declaration
      contpoint_full_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_contact_point_delta
      IS
         SELECT /*+ leading(hcp) index(hcp XX_HZ_CONTACT_POINTS_N1) use_nl(ec) */
		       'HZ_CONTACT_POINTS'
               ,''
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,HCP.contact_point_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_relationships  REL
               ,hz_contact_points HCP
          WHERE EC.party_id = REL.subject_id
            AND REL.directional_flag = 'B'
            AND REL.party_id = HCP.owner_table_id
            AND HCP.owner_table_name = 'HZ_PARTIES'
            AND HCP.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCP.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_cont_ext = 'Y';

      v_batchlimit              NUMBER;
      lc_error_loc              VARCHAR2 (240)  := NULL;
   BEGIN
      gc_error_debug := 'Start of the get_delta_CONTACT_POINTS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting contacts data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Cust Contacts Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_contact_point_delta cursor Loop started here
      OPEN lcu_contact_point_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_contact_point_delta
         BULK COLLECT INTO contpoint_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. contpoint_full_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES contpoint_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_contact_point_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_contact_point_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_CONTACT_POINTS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_CONTACT_POINTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_CONTACT_POINTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_CONTACT_POINTS
   END get_delta_contact_points;

-- +====================================================================+
-- | Name       : get_delta_cust_acct_sites                             |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_cust_acct_sites_all table                     |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_cust_acct_sites (
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
   )
   IS
      --variable declaration
      ln_batch_limit        NUMBER;
      -- table type declaration
      acct_sites_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_acct_sites_delta
      IS
         SELECT 'HZ_CUST_ACCT_SITES_ALL'
               ,''
               ,HCAS.cust_account_id
               ,''
               ,''
               ,''
               ,HCAS.party_site_id
               ,''
               ,''
               ,HCAS.cust_acct_site_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_acct_sites_all HCAS
          WHERE EC.cust_account_id = HCAS.cust_account_id
            AND HCAS.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCAS.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_addr_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_CUST_ACCT_SITES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting account sites data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Cust Acct Sites Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_acct_sites_delta cursor Loop started here
      OPEN lcu_acct_sites_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_acct_sites_delta
         BULK COLLECT INTO acct_sites_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. acct_sites_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES acct_sites_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_acct_sites_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_acct_sites_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_CUST_ACCT_SITES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_CUST_ACCT_SITES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_CUST_ACCT_SITES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_cust_acct_sites
   END get_delta_cust_acct_sites;

-- +====================================================================+
-- | Name       : get_delta_cust_site_uses                              |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_cust_site_uses_all table                      |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_cust_site_uses (
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
   )
   IS
      --variable declaration
      ln_batch_limit       NUMBER;
      --table type declaration
      site_uses_tbl_type   lt_common_delta;

      --Cursor declaration
      CURSOR lcu_site_uses_delta
      IS
         SELECT 'HZ_CUST_SITE_USES_ALL'
               ,''
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,HCSU.cust_acct_site_id
               ,HCSU.site_use_id
               ,HCSU.site_use_code
               ,HCSU.orig_system_reference
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_acct_sites_all HCAS
               ,hz_cust_site_uses_all HCSU
          WHERE EC.cust_account_id = HCAS.cust_account_id
            AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
            AND HCSU.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCSU.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_addr_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_CUST_SITE_USES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting site uses data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Cust Site Uses Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_site_uses_delta cursor Loop started here
      OPEN lcu_site_uses_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_site_uses_delta
         BULK COLLECT INTO site_uses_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. site_uses_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES site_uses_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_site_uses_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_site_uses_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_CUST_SITE_USES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_CUST_SITE_USES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_CUST_SITE_USES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_CUST_SITE_USES
   END get_delta_cust_site_uses;

-- +====================================================================+
-- | Name       : get_delta_customer_profiles                           |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_customer_profiles table                       |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_customer_profiles (
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
   )
   IS
      --variable declaration
      ln_batch_limit      NUMBER;
      --table type declaration
      profiles_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_profiles_delta
      IS
         SELECT 'HZ_CUSTOMER_PROFILES'
               ,''
               ,HCP.cust_account_id
               ,HCP.cust_account_profile_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_customer_profiles HCP
          WHERE EC.cust_account_id = HCP.cust_account_id
            AND HCP.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HCP.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_mast_head_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_CUSTOMER_PROFILES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting profiles data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Customer Profiles Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_profiles_delta cursor Loop started here
      OPEN lcu_profiles_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_profiles_delta
         BULK COLLECT INTO profiles_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. profiles_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES profiles_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_profiles_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_profiles_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_CUSTOMER_PROFILES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_CUSTOMER_PROFILES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_CUSTOMER_PROFILES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_customer_profiles
   END get_delta_customer_profiles;

-- +====================================================================+
-- | Name       : get_delta_org_contacts                                |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_org_contacts table                            |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_org_contacts (
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
   )
   IS
      --variable declaration
      ln_batch_limit          NUMBER;
      --table type declaration
      org_contacts_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_org_contacts_delta
      IS
         SELECT /*+ LEADING(HOC) INDEX(EC XX_CRM_WCELG_CUST_N2) USE_NL(EC) */
                'HZ_ORG_CONTACTS'
               ,''
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,HOC.org_contact_id
               ,''
               ,''
               ,''
               ,''
               ,REL.relationship_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_relationships REL
               ,hz_org_contacts HOC
          WHERE EC.party_id = REL.subject_id
            AND REL.subject_type = 'ORGANIZATION'
            AND REL.OBJECT_TABLE_NAME = 'HZ_PARTIES'
            AND REL.relationship_id = HOC.party_relationship_id
            AND HOC.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HOC.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_cont_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_ORG_CONTACTS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting contacts data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Org Contacts Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_org_contacts_delta cursor Loop started here
      OPEN lcu_org_contacts_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_org_contacts_delta
         BULK COLLECT INTO org_contacts_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. org_contacts_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES org_contacts_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_org_contacts_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_org_contacts_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_ORG_CONTACTS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_ORG_CONTACTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_ORG_CONTACTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_ORG_CONTACTS
   END get_delta_org_contacts;

-- +====================================================================+
-- | Name       : get_delta_party_sites                                 |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_party_sites table                             |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_party_sites (
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
   )
   IS
      --variable declaration
      ln_batch_limit         NUMBER;
      --table type declaration
      party_sites_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_party_sites_delta
      IS
         SELECT 'HZ_PARTY_SITES'
               ,HPS.party_id
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,HPS.party_site_id
               ,HPS.location_id
               ,HPS.party_site_number
               ,''
               ,''
               ,''
               ,HPS.orig_system_reference
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_party_sites HPS
          WHERE EC.party_id = HPS.party_id
            AND HPS.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HPS.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_addr_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_PARTY_SITES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting partie sites data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Party Sites Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_party_sites_delta cursor Loop started here
      OPEN lcu_party_sites_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_party_sites_delta
         BULK COLLECT INTO party_sites_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. party_sites_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES party_sites_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_party_sites_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      --cm_fulldata curosr Loop ended here
      CLOSE lcu_party_sites_delta;

      gc_error_debug := 'End of the get_delta_PARTY_SITES procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_PARTY_SITES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_PARTY_SITES procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_PARTY_SITES
   END get_delta_party_sites;

-- +====================================================================+
-- | Name       : get_locations_delta                                   |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_locations table                               |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
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
   )
   IS
      --variable declaration
      ln_batch_limit       NUMBER;
      -- table type declaration
      locations_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_locations_delta
      IS
         SELECT 'HZ_LOCATIONS'
               ,''
               ,EC.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,HL.location_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_party_sites HPS
               ,hz_locations HL
          WHERE EC.party_id = HPS.party_id
            AND HPS.location_id = HL.location_id
            AND HL.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HL.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_addr_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_locations_delta procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting locations data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Locations Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_group_members_delta cursor Loop started here
      OPEN lcu_locations_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_locations_delta
         BULK COLLECT INTO locations_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. locations_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES locations_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_locations_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_locations_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_locations_delta procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_locations_delta procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_locations_delta procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_locations_delta
   END get_locations_delta;

-- +====================================================================+
-- | Name       : get_account_roles_delta                               |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_cust_account_roles table                      |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
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
   )
   IS
      --variable declaration
      ln_batch_limit           NUMBER;
      -- table type declaration
      account_roles_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_account_roles_delta
      IS
         SELECT 'HZ_CUST_ACCOUNT_ROLES'
               ,''
               ,ACCT_ROLE.cust_account_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,ACCT_ROLE.cust_acct_site_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,ACCT_ROLE.cust_account_role_id
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_accounts HCA
               ,hz_cust_account_roles ACCT_ROLE
          WHERE EC.cust_account_id = HCA.cust_account_id
            AND HCA.cust_account_id = ACCT_ROLE.cust_account_id
            AND ACCT_ROLE.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND ACCT_ROLE.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_addr_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_account_roles_delta procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting account roles data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Account Roles Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_account_roles_delta cursor Loop started here
      OPEN lcu_account_roles_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_account_roles_delta
         BULK COLLECT INTO account_roles_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. account_roles_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES account_roles_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_account_roles_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_account_roles_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_account_roles_delta procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_account_roles_delta procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_account_roles_delta procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_account_roles_delta
   END get_account_roles_delta;

-- +====================================================================+
-- | Name       : get_delta_rs_group_members                            |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for jtf_rs_group_members table                       |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_rs_group_members (
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
   )
   IS
      --variable declaration
      ln_batch_limit           NUMBER;
      -- table type declaration
      group_members_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_group_members_delta
      IS
         SELECT 'JTF_RS_GROUP_MEMBERS'
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,group_member_id
               ,GROUP_ID
               ,resource_id
               ,person_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM jtf_rs_group_members
          WHERE last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date) AND last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date);
   BEGIN
      gc_error_debug := 'Start of the get_delta_RS_GROUP_MEMBERS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting group members data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** RS Groups Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_group_members_delta cursor Loop started here
      OPEN lcu_group_members_delta;

      LOOP
         gc_error_debug := 'Loop Started here';
         write_log (gc_debug_flag, gc_error_debug);

         FETCH lcu_group_members_delta
         BULK COLLECT INTO group_members_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. group_members_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES group_members_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_group_members_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_group_members_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_RS_GROUP_MEMBERS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_RS_GROUP_MEMBERS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_RS_GROUP_MEMBERS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_rs_group_members
   END get_delta_rs_group_members;

-- +====================================================================+
-- | Name       : get_delta_rs_resource_extns                           |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for jtf_rs_resource_extns table                      |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_rs_resource_extns (
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
   )
   IS
      --variable declaration
      ln_batch_limit            NUMBER;
      --table type declaration
      resource_extns_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_resource_extns_delta
      IS
         SELECT 'JTF_RS_RESOURCE_EXTNS'
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,resource_id
               ,''
               ,''
               ,person_party_id
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM jtf_rs_resource_extns
          WHERE last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date) AND last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date);
   BEGIN
      gc_error_debug := 'Start of the get_delta_rs_resource_extns procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting sourceres data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Resource Extn Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_resource_extns_delta cursor Loop started here
      OPEN lcu_resource_extns_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_resource_extns_delta
         BULK COLLECT INTO resource_extns_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. resource_extns_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES resource_extns_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_resource_extns_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_resource_extns_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_rs_resource_extns procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_RS_RESOURCE_EXTNS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_RS_RESOURCE_EXTNS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_rs_resource_extns
   END get_delta_rs_resource_extns;

-- +====================================================================+
-- | Name       : get_delta_xx_tm_nam_terr                              |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for xx_tm_nam_terr_entity_dtls table                 |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_xx_tm_nam_terr (
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
   )
   IS
      --variable declaration
      ln_batch_limit       NUMBER;
      -- table type declaration
      terr_dtls_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_terr_dtls_delta
      IS
         SELECT 'XX_TM_NAM_TERR_ENTITY_DTLS'
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,named_acct_terr_entity_id
               ,named_acct_terr_id
               ,entity_type
               ,entity_id
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_tm_nam_terr_entity_dtls
          WHERE last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date) AND last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date);

      v_batchlimit         NUMBER;
      lc_error_loc         VARCHAR2 (240)  := NULL;
   BEGIN
      gc_error_debug := 'Start of the get_delta_rs_resource_extns procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting entities data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Territories Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_terr_dtls_delta cursor Loop started here
      OPEN lcu_terr_dtls_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_terr_dtls_delta
         BULK COLLECT INTO terr_dtls_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. terr_dtls_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES terr_dtls_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_terr_dtls_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      CLOSE lcu_terr_dtls_delta;

      --cm_fulldata curosr Loop ended here
      gc_error_debug := 'End of the get_delta_RS_RESOURCE_EXTNS procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_XX_TM_NAM_TERR procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_XX_TM_NAM_TERR procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_xx_tm_nam_terr
   END get_delta_xx_tm_nam_terr;

-- +====================================================================+
-- | Name       : get_delta_cust_profile_amts                           |
-- |                                                                    |
-- | Description: This procedure is used get the incremental data       |
-- |               for hz_cust_profile_amts table                       |
-- |                                                                    |
-- | Parameters : p_last_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_from_cust_account_id                                |
-- |              p_to_cust_account_id                                  |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_thread_num                                          |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE get_delta_cust_profile_amts (
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
   )
   IS
      --variable declaration
      ln_batch_limit          NUMBER;
      --table type declaration
      profile_amts_tbl_type   lt_common_delta;

      --cursor declaration
      CURSOR lcu_profile_amts_delta
      IS
         SELECT 'HZ_CUST_PROFILE_AMTS'
               ,''
               ,EC.cust_account_id
               ,HPA.cust_account_profile_id
               ,HPA.cust_acct_profile_amt_id
               ,HPA.currency_code
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,''
               ,gd_last_update_date
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_created_by
               ,gn_request_id
               ,gn_program_id
           FROM xx_crm_wcelg_cust EC
               ,hz_cust_profile_amts HPA
          WHERE EC.cust_account_id = HPA.cust_account_id
            AND HPA.last_update_date > FND_DATE.CANONICAL_TO_DATE (p_last_run_date)
            AND HPA.last_update_date <= FND_DATE.CANONICAL_TO_DATE (p_to_run_date)
            AND EC.cust_account_id BETWEEN p_from_cust_account_id AND p_to_cust_account_id
            AND EC.cust_mast_head_ext = 'Y';
   BEGIN
      gc_error_debug := 'Start of the get_delta_cust_profile_amts procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before deleting profile amounts data in the commom delta table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      write_log (gc_debug_flag, gc_error_debug);
      ln_batch_limit := p_batch_limit;
      fnd_file.put_line (fnd_file.LOG, '********** Profile Amounts Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is: ' || p_last_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is: ' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is: ' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   From Cust Account Id is: ' || p_from_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   To Cust Account is: ' || p_to_cust_account_id);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is: ' || p_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   Thread number is: ' || p_thread_num);

      --lcu_profile_amts_delta cursor Loop started here
      OPEN lcu_profile_amts_delta;

      gc_error_debug := 'Loop Started here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_profile_amts_delta
         BULK COLLECT INTO profile_amts_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. profile_amts_tbl_type.COUNT
            INSERT INTO xx_crm_common_delta
                 VALUES profile_amts_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_profile_amts_delta%NOTFOUND;
      END LOOP;

      gc_error_debug := 'Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      --cm_fulldata curosr Loop ended here
      CLOSE lcu_profile_amts_delta;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_COMMON_DELTA'
                    );
      gc_error_debug := 'End of the get_delta_cust_profile_amts procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the get_delta_CUST_PROFILE_AMTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in get_delta_CUST_PROFILE_AMTS procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of get_delta_cust_profile_amts
   END get_delta_cust_profile_amts;

-- +====================================================================+
-- | Name       : main                                                  |
-- |                                                                    |
-- | Description: This procedure is used call all child progarms        |
-- |                                                                    |
-- | Parameters : p_from_run_date                                       |
-- |              p_to_run_date                                         |
-- |              p_batch_limit                                         |
-- |              p_no_of_threads                                       |
-- |              p_content_type                                        |
-- |              p_compute_stats                                       |
-- |              p_debug_flag                                          |
-- |              p_program_name                                        |
-- |                                                                    |
-- | Returns    : p_errbuf                                              |
-- |              p_retcode                                             |
-- +====================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_from_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_no_of_threads   IN       NUMBER
     ,p_content_type    IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug_flag      IN       VARCHAR2
   )
   AS
      --variable declaration
      ln_conc_id                fnd_concurrent_requests.request_id%TYPE   := -1;
      ln_from_cust_account_id   hz_cust_accounts.cust_account_id%TYPE;
      ln_to_cust_account_id     hz_cust_accounts.cust_account_id%TYPE;
      ln_thread_num             NUMBER (15);
      lc_child_program_name     VARCHAR2 (60);
      ln_child_program_id       NUMBER;
      ln_threads                NUMBER;
      ln_batch_limit            NUMBER;
      ln_no_of_threads          NUMBER;
      ln_batch                  NUMBER;
      lc_from_run_date          VARCHAR2 (25);
      lc_to_run_date            VARCHAR2 (25);
      ln_parent_program_id      NUMBER;
      ln_parent_request_id      NUMBER;
      ln_batch_id               NUMBER;
      lc_phase                  VARCHAR2 (200);
      lc_status                 VARCHAR2 (200);
      lc_dev_phase              VARCHAR2 (200);
      lc_dev_status             VARCHAR2 (20);
      lc_message                VARCHAR2 (200);
      ln_idx                    NUMBER;
      lc_table_name             VARCHAR2 (30);
      ln_retcode                NUMBER                                    := 0;
      --table type declaration
      req_id_tbl_type           lt_req_id;

	ln_delta_cnt NUMBER := 0;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);
	ln_nextval	    NUMBER  DEFAULT 0;


      --cursor declaration
      CURSOR lcu_cust_accts (
         ln_threads   NUMBER
      )
      IS
         SELECT   MIN (x.cust_account_id) "from_cust_account_id"
                 ,MAX (x.cust_account_id) "to_cust_account_id"
                 ,x.thread_num
             FROM DUAL
                 , (SELECT cust_account_id
                          ,NTILE (ln_threads) OVER (ORDER BY cust_account_id ASC) AS thread_num
                      FROM xx_crm_wcelg_cust) x
         GROUP BY x.thread_num
         ORDER BY x.thread_num;
   BEGIN
      ln_idx := 1;
      gc_debug_flag := p_debug_flag;
      gc_compute_stats := p_compute_stats;

      BEGIN
         SELECT xx_crm_common_multithread_s.NEXTVAL
           INTO ln_batch_id
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while generating sequence values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         WHEN OTHERS
         THEN
            gc_error_debug := SQLERRM || ' Others exception raised while generating sequence values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT XFTV.target_value1
               ,XFTV.target_value3
           INTO ln_batch
               ,ln_no_of_threads
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = p_content_type
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while getting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT DECODE (p_content_type
                       ,'XX_CRM_PARTY_DELTA', 'HZ_PARTIES'
                       ,'XX_CRM_CUST_ACCOUNTS_DELTA', 'HZ_CUST_ACCOUNTS'
                       ,'XX_CRM_CUST_PROFILE_AMTS_DELTA', 'HZ_CUST_PROFILE_AMTS'
                       ,'XX_CRM_CUSTOMER_PROFILES_DELTA', 'HZ_CUSTOMER_PROFILES'
                       ,'XX_CRM_CUST_ACCT_SITES_DELTA', 'HZ_CUST_ACCT_SITES_ALL'
                       ,'XX_CRM_CUST_SITE_USES_DELTA', 'HZ_CUST_SITE_USES_ALL'
                       ,'XX_CRM_PARTY_SITES_DELTA', 'HZ_PARTY_SITES'
                       ,'XX_CRM_ORG_CONTACTS_DELTA', 'HZ_ORG_CONTACTS'
                       ,'XX_CRM_LOCATIONS_DELTA', 'HZ_LOCATIONS'
                       ,'XX_CRM_ACCOUNT_ROLES_DELTA', 'HZ_CUST_ACCOUNT_ROLES'
                       ,'XX_CRM_CONTPOINT_DELTA', 'HZ_CONTACT_POINTS'
                       ,'XX_CRM_RS_GROUP_MEMBERS_DELTA', 'JTF_RS_GROUP_MEMBERS'
                       ,'XX_CRM_RS_RESOURCE_EXTNS', 'JTF_RS_RESOURCE_EXTNS'
                       ,'XX_CRM_TM_NAM_DTLS_DELTA', 'XX_TM_NAM_TERR_ENTITY_DTLS'
                       ,'UNKNOWN'
                       )
           INTO lc_table_name
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            gc_error_debug := SQLERRM || ' Others exception raised  while fetching table names for respective procedure';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      DELETE FROM xx_crm_common_delta
            WHERE content_type = lc_table_name;

     IF lc_table_name = 'HZ_PARTIES' THEN
	DELETE FROM xx_crm_common_delta
            WHERE content_type = 'HZ_RELATIONSHIPS_HIER';
     END IF;

      BEGIN
         IF p_from_run_date IS NULL AND p_to_run_date IS NULL
         THEN
            XX_CRM_CUST_ELG_PKG.from_to_date (lc_from_run_date
                                             ,lc_to_run_date
                                             ,ln_retcode
                                             );

            IF ln_retcode != 0
            THEN
               gc_error_debug := 'Exception raised while getting from and to dates';
               fnd_file.put_line (fnd_file.LOG, gc_error_debug);
               ln_retcode := 2;
            END IF;
         ELSE
            lc_from_run_date := p_from_run_date;
            lc_to_run_date := p_to_run_date;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found in the Customer Address main procedure';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      IF p_no_of_threads IS NULL
      THEN
         ln_threads := ln_no_of_threads;
      ELSE
         ln_threads := p_no_of_threads;
      END IF;

      IF p_batch_limit IS NULL
      THEN
         ln_batch_limit := ln_batch;
      ELSE
         ln_batch_limit := p_batch_limit;
      END IF;

      gc_error_debug := 'Start of main procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '********** Customer Delta Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Last Run date is:' || lc_from_run_date);
      fnd_file.put_line (fnd_file.LOG, '   To Run date is:' || lc_to_run_date);
      fnd_file.put_line (fnd_file.LOG, '   Program Name is:' || P_content_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '     ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is:' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   No of threads are:' || ln_threads);

      OPEN lcu_cust_accts (ln_threads);

      gc_error_debug := 'lcu_cust_accts Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_cust_accts
          INTO ln_from_cust_account_id
              ,ln_to_cust_account_id
              ,ln_thread_num;

         EXIT WHEN lcu_cust_accts%NOTFOUND;
         ln_conc_id :=
            FND_REQUEST.SUBMIT_REQUEST (application      => 'xxcrm'
                                       ,program          => p_content_type
                                       ,description      => ln_thread_num
                                       ,start_time       => SYSDATE
                                       ,sub_request      => FALSE
                                       ,argument1        => lc_from_run_date
                                       ,argument2        => lc_to_run_date
                                       ,argument3        => ln_batch_limit
                                       ,argument4        => ln_from_cust_account_id
                                       ,argument5        => ln_to_cust_account_id
                                       ,argument6        => p_compute_stats
                                       ,argument7        => p_debug_flag
                                       ,argument8        => ln_thread_num
                                       );
         COMMIT;

         IF ln_conc_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Child Program is not submitted');
            p_retcode := 2;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            req_id_tbl_type (ln_idx) := ln_conc_id;
            ln_idx := ln_idx + 1;
         END IF;

         BEGIN
            SELECT FCPL.concurrent_program_id
                  ,FCPL.user_concurrent_program_name
              INTO ln_child_program_id
                  ,lc_child_program_name
              FROM fnd_concurrent_programs FCP
                  ,fnd_concurrent_programs_tl FCPL
             WHERE FCP.concurrent_program_id = FCPL.concurrent_program_id AND FCP.concurrent_program_name = p_content_type;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               gc_error_debug := 'NO data found while getting progarm name in main ';
               fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         END;

         BEGIN
            SELECT FCR.parent_request_id
                  ,FCR.concurrent_program_id
              INTO ln_parent_request_id
                  ,ln_parent_program_id
              FROM fnd_concurrent_requests FCR
             WHERE FCR.request_id = ln_conc_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               gc_error_debug := 'NO data found while getting parent program id in main';
               fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         END;

         INSERT INTO xx_crm_common_delta_details
              VALUES (ln_batch_id
                     ,ln_parent_program_id
                     ,ln_parent_request_id
                     ,ln_thread_num
                     ,lc_child_program_name
                     ,ln_child_program_id
                     ,ln_conc_id
                     ,ln_from_cust_account_id
                     ,ln_to_cust_account_id
                     ,lc_from_run_date
                     ,lc_to_run_date
                     ,'Inserted'
                     ,'-1'
                     ,SYSDATE
                     ,'-1'
                     ,SYSDATE
                     );

         COMMIT;
      END LOOP;

      CLOSE lcu_cust_accts;

      --lcu_cust_accts Loop Ended here
      gc_error_debug := 'lcu_cust_accts Loop Ended here';
      write_log (gc_debug_flag, gc_error_debug);

      --ln_req_id Loop started here
      FOR i IN req_id_tbl_type.FIRST .. req_id_tbl_type.LAST
      LOOP
         IF fnd_concurrent.wait_for_request (req_id_tbl_type (i)
                                            ,30
                                            ,0
                                            ,lc_phase
                                            ,lc_status
                                            ,lc_dev_phase
                                            ,lc_dev_status
                                            ,lc_message
                                            )
         THEN
            IF UPPER (lc_status) = 'ERROR'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with error');
               p_retcode := 2;
            ELSIF UPPER (lc_status) = 'WARNING'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed with warning');
               p_retcode := 1;
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Thread ' || i || ' completed normal');
               p_retcode := 0;
            END IF;

            UPDATE xx_crm_common_delta_details
               SET status = UPPER (lc_status)
             WHERE child_request_id = req_id_tbl_type (i);

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         END IF;
      END LOOP;

      p_retcode := ln_retcode;
      --ln_req_id Loop Ended here



	IF p_content_type = 'XX_CRM_PARTY_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type IN ('HZ_PARTIES','HZ_RELATIONSHIPS_HIER') ;

	ELSIF p_content_type = 'XX_CRM_CUST_ACCOUNTS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUST_ACCOUNTS' ;

	ELSIF p_content_type = 'XX_CRM_CUST_PROFILE_AMTS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUST_PROFILE_AMTS' ;

	ELSIF p_content_type = 'XX_CRM_CUSTOMER_PROFILES_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUSTOMER_PROFILES' ;

	ELSIF p_content_type = 'XX_CRM_CUST_ACCT_SITES_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUST_ACCT_SITES_ALL' ;

	ELSIF p_content_type = 'XX_CRM_CUST_SITE_USES_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUST_SITE_USES_ALL' ;

	ELSIF p_content_type = 'XX_CRM_PARTY_SITES_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_PARTY_SITES' ;

	ELSIF p_content_type = 'XX_CRM_ORG_CONTACTS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_ORG_CONTACTS' ;

	ELSIF p_content_type = 'XX_CRM_LOCATIONS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_LOCATIONS' ;

	ELSIF p_content_type = 'XX_CRM_ACCOUNT_ROLES_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CUST_ACCOUNT_ROLES' ;

	ELSIF p_content_type = 'XX_CRM_CONTPOINT_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'HZ_CONTACT_POINTS' ;

	ELSIF p_content_type = 'XX_CRM_RS_GROUP_MEMBERS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'JTF_RS_GROUP_MEMBERS' ;

	ELSIF p_content_type = 'XX_CRM_RS_RESOURCE_EXTNS' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'JTF_RS_RESOURCE_EXTNS' ;

	ELSIF p_content_type = 'XX_CRM_TM_NAM_DTLS_DELTA' THEN

		SELECT COUNT(*) INTO ln_delta_cnt FROM xx_crm_common_delta WHERE content_type = 'XX_TM_NAM_TERR_ENTITY_DTLS' ;

	END IF;




      BEGIN
	 SELECT xx_crmar_int_log_s.NEXTVAL
	   INTO ln_nextval
	   FROM DUAL;
      EXCEPTION
	 WHEN OTHERS
	 THEN
	    gc_error_debug := SQLERRM || 'Exception raised while getting sequence value';
	    fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;



      ln_request_id_p := fnd_global.conc_request_id ();

	SELECT  a.program, a.program_short_name
		INTO ln_program_name, ln_program_short_name
	FROM FND_CONC_REQ_SUMMARY_V A
	WHERE a.request_id = ln_request_id_p;

         INSERT INTO xx_crmar_int_log
                     (Program_Run_Id
                     ,program_name
                     ,program_short_name
                     ,module_name
                     ,program_run_date
                     ,filename
                     ,total_files
                     ,total_records
                     ,status
                     ,MESSAGE
                     ,request_id -- V1.1, Added request_id
                     )
              VALUES (ln_nextval
                     ,ln_program_name
                     ,ln_program_short_name
                     ,gc_module_name
                     ,SYSDATE
                     ,''
                     ,0
                     ,ln_delta_cnt
                     ,'SUCCESS'
                     ,'Processed'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

	COMMIT;

      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||ln_delta_cnt;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');


      gc_error_debug := 'End of main procedure' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' NO data found in the main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of main
   END main;
--End of XX_CRM_CUST_DELTA_PKG
END xx_crm_cust_delta_pkg;
/

SHOW errors;