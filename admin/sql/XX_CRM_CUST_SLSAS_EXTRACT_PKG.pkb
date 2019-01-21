CREATE OR REPLACE PACKAGE BODY xx_crm_cust_slsas_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_SLSAS_EXTRACT_PKG                          |
--|RICE        : 106313                                                 |
--|Description :This Package is used for insert data into staging       |
--|             table and fetch data from staging table to flat file    |
--|                                                                     |
--|            The STAGING Procedure will perform the following steps   |
--|                                                                     |
--|             1.It will fetch the records into staging table. The     |
--|               data will be either full or incremental               |
--|                                                                     |
--|             EXTRACT STAGING procedure will perform the following    |
--|                steps                                                |
--|                                                                     |
--|              1.It will fetch the staging table data to flat file    |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author               Remarks               |
--|=======   ======        ====================   ===========           |
--|1.0       30-Aug-2011   Balakrishna Bolikonda  Initial Version       |
--|1.1       10-May-2012   Jay Gupta              Defect 18387 - Add    |
--|                                            Request_id in LOG tables |
--|1.2       11-Nov-2015   Havish Kasina       Removed the Schema References|
--|                                            as per R12.2 Retrofit Changes|
--+=====================================================================+

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
         fnd_stats.gather_table_stats (ownname => p_schema
		                      ,tabname => p_tablename);
      END IF;
   END compute_stats;

--+==================================================================+
--|Name        :insert_fulldata                                      |
--|Description :This procedure is used to fetch the total data       |
--|             from base tables to staging table                    |
--|                                                                  |
--|                                                                  |
--|Parameters : p_batch_limit                                        |
--|                                                                  |
--|                                                                  |
--|Returns    : p_retcode                                            |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE insert_fulldata (
      p_batch_limit   IN       NUMBER
     ,p_retcode       OUT      NUMBER
   )
   IS
      --variable declaration
      ln_batch_limit     NUMBER;
      --Variable declaration of Table type
      cm_full_tbl_type   lt_cust_salesperson;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_fulldata
      IS
       SELECT /*+ INDEX_FFS(XCEC XX_CRM_WCELG_CUST_N1) INDEX_FFS(XCEC XX_CRM_WCELG_CUST_N2) */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
        AND XCEC.sls_per_ext = 'N';
   BEGIN
      gc_error_debug := 'Start Extracting full data from Sales person base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Sales person assignments';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custsls_stg';

      --Cursor Loop started here
      gc_error_debug := NULL;
      ln_batch_limit := p_batch_limit;
      gc_error_debug := 'Loop started here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);

      OPEN lcu_fulldata;

      LOOP
         FETCH lcu_fulldata
         BULK COLLECT INTO cm_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_full_tbl_type.COUNT
            INSERT INTO xx_crm_custsls_stg
                 VALUES cm_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_fulldata%NOTFOUND;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||lcu_fulldata%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      --Curosr Loop ended here
      CLOSE lcu_fulldata;

      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);
      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTSLS_STG'
                    );
      gc_error_debug := 'End of Extracting Full data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' No data found exception is raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_fulldata_proc procedure
   END insert_fulldata;

--+==================================================================+
--|Name        :insert_incrdata                                      |
--|Description :This procedure is used to fetch the incremental data |
--|              from base tables to staging table                   |
--|                                                                  |
--|                                                                  |
--|Parameters : p_batch_limit                                        |
--|                                                                  |
--|                                                                  |
--|Returns    : p_retcode                                            |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE insert_incrdata (
      p_batch_limit   IN       NUMBER
     ,p_retcode       OUT      NUMBER
   )
   IS
      --variable declaration
      ln_batch_limit     NUMBER;
      --Table type declaration
      cm_incr_tbl_type   lt_cust_salesperson;

	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);
	ln_nextval	    NUMBER  DEFAULT 0;
        ln_slsas_cnt		NUMBER := 0;

      --cursor declaration: This is used to fetch the incremental customer master data from base tables
      CURSOR lcu_incremental
      IS
        SELECT /*+  */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_common_delta DELTA
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND DELTA.cust_acct_site_id = HCAS.cust_acct_site_id AND DELTA.content_type = 'HZ_CUST_ACCT_SITES_ALL'
UNION
        SELECT /*+  */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_common_delta DELTA
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND DELTA.party_site_id = HPS.party_site_id AND DELTA.content_type = 'HZ_PARTY_SITES_ALL'
UNION
        SELECT /*+  */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_common_delta DELTA
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND DELTA.group_member_id = XXTPSGM.group_member_id AND DELTA.content_type = 'JTF_RS_GROUP_MEMBERS'
UNION
        SELECT /*+  */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_common_delta DELTA
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND DELTA.resource_id = JRRE.resource_id AND DELTA.content_type = 'JTF_RS_RESOURCE_EXTNS'
UNION
        SELECT /*+  */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_common_delta DELTA
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND DELTA.named_acct_terr_entity_id = TERR_ENT.named_acct_terr_entity_id AND DELTA.content_type = 'XX_TM_NAM_TERR_ENTITY_DTLS'
UNION
        SELECT /*+ LEADING(XCEC_NEW) INDEX(HCP HZ_CUSTOMER_PROFILES_N1) INDEX(TERR_ENT XX_TM_NAM_TERR_ENTITY_DTLS_N1) */
                HCAS.cust_account_id "cust account id"
               ,JRRE.source_number "salesrep number"
               ,XXTPSGM.resource_name "sales rep name"
               ,XXTPSGM.source_email "rep email address"
               ,XXTPSGM.c_resource_name "DSM name"
               ,XXTPSGM.c_source_email "DSM mail address"
               ,HCAS.orig_system_reference "orig system reference"
               ,JTSP.salesrep_id "salesrep_id"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust XCEC
               ,hz_cust_acct_sites_all HCAS
               ,hz_customer_profiles HCP
               ,hz_cust_site_uses_all HCSU
               ,hz_party_sites HPS
               ,xx_tm_nam_terr_entity_dtls TERR_ENT
               ,xx_tm_nam_terr_defn TERR
               ,xx_tm_nam_terr_rsc_dtls TERR_RSC
               ,xxtps_group_mbr_info_mv XXTPSGM
               ,jtf_rs_resource_extns_vl JRRE
               ,JTF_RS_SALESREPS JTSP
	       ,xx_crm_wcelg_cust XCEC_NEW
        WHERE XCEC.cust_account_id = HCAS.cust_account_id
        AND   XCEC.cust_account_id = HCP.cust_account_id
        AND HCAS.party_site_id = HPS.party_site_id
        AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
        AND HCSU.site_use_code = 'BILL_TO'
        AND XCEC.cust_account_id = HCP.cust_account_id
        AND HCP.site_use_id IS NOT NULL
        AND HCAS.party_site_id        = TERR_ENT.entity_id
        AND TERR_ENT.entity_type      = 'PARTY_SITE'
        AND TERR_RSC.resource_id      = XXTPSGM.resource_id
        AND TERR_RSC.resource_role_id = XXTPSGM.role_id
        AND TERR_RSC.group_id         = XXTPSGM.group_id
        AND TERR_RSC.resource_id = JRRE.resource_id
        AND TERR_RSC.resource_id = JTSP.resource_id
        AND SYSDATE BETWEEN JTSP.start_date_active AND NVL(JTSP.end_date_active, SYSDATE +  1)
        AND HCAS.org_id = JTSP.org_id
        AND SYSDATE BETWEEN JRRE.start_date_active AND NVL(JRRE.end_date_active, SYSDATE +  1)
        AND TERR.NAMED_ACCT_TERR_ID   = TERR_RSC.NAMED_ACCT_TERR_ID
        AND TERR_ENT.NAMED_ACCT_TERR_ID = TERR.NAMED_ACCT_TERR_ID
        AND SYSDATE BETWEEN NVL(TERR.START_DATE_ACTIVE,SYSDATE    -1) AND NVL(TERR.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)
        AND SYSDATE BETWEEN NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) AND NVL(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)
        AND NVL(TERR.status,'A')     = 'A'
        AND NVL(TERR_ENT.status,'A') = 'A'
        AND NVL(TERR_RSC.status,'A') = 'A'
        AND HCP.site_use_id = HCSU.site_use_id(+)
        AND HCP.status = 'A'
        AND HPS.status = 'A'
        AND HCSU.status = 'A'
	AND XCEC.cust_account_id = XCEC_NEW.cust_account_id AND XCEC_NEW.sls_per_ext = 'N';

   BEGIN
      gc_error_debug := 'Start Extracting full data from Sales person base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Sales person assignments';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custsls_stg';

      --Loop started here
      ln_batch_limit := p_batch_limit;

      OPEN lcu_incremental;

      LOOP
         FETCH lcu_incremental
         BULK COLLECT INTO cm_incr_tbl_type LIMIT p_batch_limit;

         FORALL i IN 1 .. cm_incr_tbl_type.COUNT
            INSERT INTO xx_crm_custsls_stg
                 VALUES cm_incr_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_incremental%NOTFOUND;
      END LOOP;


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
      ln_slsas_cnt := lcu_incremental%ROWCOUNT;

      SELECT COUNT(*) INTO ln_slsas_cnt FROM xx_crm_custsls_stg;

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
                     ,ln_slsas_cnt
                     ,'SUCCESS'
                     ,'Processed'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

	COMMIT;

      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||lcu_incremental%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      --Loop Ended here
      CLOSE lcu_incremental;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTSLS_STG'
                    );
      gc_error_debug := 'End Extracting Incremental data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || 'No data found while fetching incremental data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || 'Others exception raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_incrdata
   END insert_incrdata;

--+==================================================================+
--|Name        :extract_stagedata                                    |
--|Description :This procedure is used to fetch the staging table    |
--|             data to flat file                                    |
--|                                                                  |
--|                                                                  |
--|Parameters :                                                      |
--|               p_debug_flag                                       |
--|               p_compute_stats                                    |
--|Returns    :   p_errbuf                                           |
--|               p_retcode                                          |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE extract_stagedata (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   IS
      --variable declaration
      lc_filehandle          UTL_FILE.file_type;
      lc_filepath            VARCHAR2 (500);
      lc_filename            VARCHAR2 (100);
      lc_message             VARCHAR2 (32767);
      lc_message1            VARCHAR2 (4000);
      lc_mode                VARCHAR2 (1)        := 'W';
      ln_linesize            NUMBER;
      lc_comma               VARCHAR2 (2);
      ln_batch_limit         NUMBER;
      ln_count               NUMBER              := 0;
      ln_total_count         NUMBER              := 0;
      ln_fno                 NUMBER              := 1;
      ln_no_of_records       NUMBER;
      lc_debug_flag          VARCHAR2 (2);
      lc_compute_stats       VARCHAR2 (2);
      lc_destination_path    VARCHAR2 (500);
      ln_ftp_request_id      NUMBER;
      lc_archive_directory   VARCHAR2 (500);
      lc_source_path         VARCHAR2 (500);
      lc_phase               VARCHAR2 (200);
      lc_status              VARCHAR2 (200);
      lc_dev_phase           VARCHAR2 (200);
      lc_dev_status          VARCHAR2 (200);
      lc_message2            VARCHAR2 (200);
      ln_idx                 NUMBER              := 1;
      ln_idx2                NUMBER              := 1;
      ln_retcode             NUMBER              := 0;
      ln_rec_count           NUMBER              := 0;

      --Table type declaration
      cm_stage_tbl_type      lt_cust_salesperson;
      req_id_tbl_type        lt_req_id;
      file_names_tbl_type    lt_file_names;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);

      --cursor declaration: This is used to fetech the staging table data
      CURSOR lcu_sales_person
      IS
         SELECT SLS.cust_account_id
               ,SLS.salesrep_number
               ,SLS.salesrep_name
               ,SLS.rep_email_address
               ,SLS.dsm_name
               ,SLS.dsm_email_address
               ,SLS.orig_system_reference
               ,SLS.salesrep_id
               ,gn_last_updated_by
               ,gd_creation_date
               ,gn_request_id
               ,gn_created_by
               ,gd_last_update_date
               ,gn_program_id
           FROM xx_crm_custsls_stg SLS;
   BEGIN
      gc_error_debug := 'Start Extracting Staging table data into flat file' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      lc_debug_flag := p_debug_flag;
      lc_compute_stats := P_compute_stats;

      BEGIN
         SELECT XFTV.target_value1
               ,XFTV.target_value2
               , XFTV.target_value4 || '_' || TO_CHAR (SYSDATE, 'YYYYMMDD_HH24MISS')
               ,XFTV.target_value7
               ,XFTV.target_value8
               ,XFTV.target_value9
               ,XFTV.target_value11
               ,XFTV.target_value12
           INTO ln_batch_limit
               ,lc_comma
               ,gc_filename
               ,ln_linesize
               ,lc_filepath
               ,ln_no_of_records
               ,lc_destination_path
               ,lc_archive_directory
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'CUST_SALES_ASSIGNMENT'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := SQLERRM || 'NO data found while selecting translation defination values';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT AD.directory_path
           INTO lc_source_path
           FROM all_directories AD
          WHERE directory_name = lc_filepath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := SQLERRM || 'NO data found while selecting source path from translation defination';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO gn_nextval
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


      fnd_file.put_line (fnd_file.LOG, '********** Sales Person Assignments Stage File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '  ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || lc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '  ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '  ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is :' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   Line Size limit is :' || ln_linesize);
      fnd_file.put_line (fnd_file.LOG, '   Source File Path is :' || lc_source_path);
      fnd_file.put_line (fnd_file.LOG, '   Destination File Path is :' || lc_destination_path);
      fnd_file.put_line (fnd_file.LOG, '   Archive File Path is :' || lc_archive_directory);
      fnd_file.put_line (fnd_file.LOG, '   Delimiter is :' || lc_comma);
      fnd_file.put_line (fnd_file.LOG, '   No of records per File :' || ln_no_of_records);

      SELECT COUNT(*)
      INTO ln_rec_count
      FROM xx_crm_custsls_stg;

      IF ln_rec_count = 0
      THEN
       	  gc_error_debug := 'No record found today';
          fnd_file.put_line (fnd_file.LOG, gc_error_debug);
          ln_retcode := 1;
      END IF;
      lc_filename := gc_filename || '-' || ln_fno || '.dat';
      lc_filehandle := UTL_FILE.fopen (lc_filepath
                                      ,lc_filename
                                      ,lc_mode
                                      ,ln_linesize
                                      );
      file_names_tbl_type (ln_idx) := lc_filename;
      ln_idx2 := ln_idx2 + 1;
      --Gathering table stats
      compute_stats (lc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTSLS_STG'
                    );
      --Loop started here
      gc_error_debug := 'Loop started here for fetching data into flat file ';
      write_log (lc_debug_flag, gc_error_debug);



      OPEN lcu_sales_person;

      LOOP
         FETCH lcu_sales_person
         BULK COLLECT INTO cm_stage_tbl_type LIMIT ln_batch_limit;

         FOR i IN 1 .. cm_stage_tbl_type.COUNT
         LOOP
            lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                  cm_stage_tbl_type (i).salesrep_number
               || lc_comma
               || cm_stage_tbl_type (i).salesrep_name
               || lc_comma
               || cm_stage_tbl_type (i).rep_email_address
               || lc_comma
               || cm_stage_tbl_type (i).dsm_name
               || lc_comma
               || cm_stage_tbl_type (i).dsm_email_address
               || lc_comma
               || cm_stage_tbl_type (i).orig_system_reference
               || lc_comma
               || cm_stage_tbl_type (i).salesrep_id
			   );
            UTL_FILE.put_line (lc_filehandle, lc_message);
            --Incrementing count of records in the file and total records fethed on particular day
            ln_count := ln_count + 1;
            ln_total_count := ln_total_count + 1;

            --updating  cust_mast_head_ext flag to 'Y' in eligibility table after extracing data for customer
            UPDATE xx_crm_wcelg_cust
               SET sls_per_ext = 'Y'
             WHERE cust_account_id = cm_stage_tbl_type (i).cust_account_id AND sls_per_ext = 'N';

            IF ln_count >= ln_no_of_records
            THEN
               lc_message1 := ' ';
               UTL_FILE.put_line (lc_filehandle, lc_message1);
               lc_message1 := 'Total number of records extracted:' || ln_count;

               INSERT INTO xx_crmar_file_log
                           (program_id
                           ,program_name
                           ,program_run_date
                           ,filename
                           ,total_records
                           ,status
                           ,request_id -- V1.1, Added request_id
                           )
                    VALUES (gn_nextval
                           ,ln_program_name
                           ,SYSDATE
                           ,lc_filename
                           ,ln_count
                           ,'SUCCESS'
                           ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                           );

               COMMIT;
               UTL_FILE.put_line (lc_filehandle, lc_message1);
               UTL_FILE.fclose (lc_filehandle);
               ln_count := 0;
               ln_fno := ln_fno + 1;
               lc_filename := gc_filename || '-' || ln_fno || '.dat';
               file_names_tbl_type (ln_idx) := lc_filename;
               ln_idx2 := ln_idx2 + 1;
               lc_filehandle := UTL_FILE.fopen (lc_filepath
                                               ,lc_filename
                                               ,lc_mode
                                               ,ln_linesize
                                               );
            END IF;
         END LOOP;

         COMMIT;
         EXIT WHEN lcu_sales_person%NOTFOUND;
      END LOOP;

      CLOSE lcu_sales_person;

      gc_error_debug := 'Loop Ended here for fetching data into flat file ';
      write_log (lc_debug_flag, gc_error_debug);
      lc_message1 := ' ';
      UTL_FILE.put_line (lc_filehandle, lc_message1);
      lc_message1 := 'Total number of records extracted:' || ln_count;

      INSERT INTO xx_crmar_file_log
                  (program_id
                  ,program_name
                  ,program_run_date
                  ,filename
                  ,total_records
                  ,status
                  ,request_id -- V1.1, Added request_id
                  )
           VALUES (gn_nextval
                  ,ln_program_name
                  ,SYSDATE
                  ,lc_filename
                  ,ln_count
                  ,'SUCCESS'
                  ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                  );

      COMMIT;
      UTL_FILE.put_line (lc_filehandle, lc_message1);
      --Loop ended here
      UTL_FILE.fclose (lc_filehandle);



      --Summary data inserting into log table
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
           VALUES (gn_nextval
                  ,ln_program_name
                  ,ln_program_short_name
                  ,gc_module_name
                  ,SYSDATE
                  ,lc_filename
                  ,ln_fno
                  ,ln_total_count
                  ,'SUCCESS'
                  ,'File generated'
                  ,FND_GLOBAL.CONC_REQUEST_ID -- V1.1, Added request_id
                  );

      FOR i IN file_names_tbl_type.FIRST .. file_names_tbl_type.LAST
      LOOP
         -- Start of FTP Program
         gc_error_debug := 'Calling the Common File Copy to move the output file to ftp directory';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         ln_ftp_request_id :=
            fnd_request.submit_request ('XXFIN'
                                       ,'XXCOMFILCOPY'
                                       ,''
                                       ,''
                                       ,FALSE
                                       , lc_source_path || '/' || file_names_tbl_type (i)                                           --Source File Name
                                       , lc_destination_path || '/' || file_names_tbl_type (i)                                        --Dest File Name
                                       ,''
                                       ,''
                                       ,'Y'                                                                                 --Deleting the Source File
                                       ,lc_archive_directory                                                                  --Archive directory path
                                       );
         COMMIT;

         IF ln_ftp_request_id = 0
         THEN
            fnd_file.put_line (fnd_file.LOG, 'Common File copy Program is not submitted');
            p_retcode := 2;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         ELSE
            req_id_tbl_type (ln_idx) := ln_ftp_request_id;
            ln_idx := ln_idx + 1;
         END IF;
      -- End of FTP Program
      END LOOP;

      --req_id_tbl_type Loop started here
      FOR i IN req_id_tbl_type.FIRST .. req_id_tbl_type.LAST
      LOOP
         IF fnd_concurrent.wait_for_request (req_id_tbl_type (i)
                                            ,30
                                            ,0
                                            ,lc_phase
                                            ,lc_status
                                            ,lc_dev_phase
                                            ,lc_dev_status
                                            ,lc_message2
                                            )
         THEN
            IF UPPER (lc_status) = 'ERROR'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with error');
               p_retcode := 2;
            ELSIF UPPER (lc_status) = 'WARNING'
            THEN
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed with warning');
               p_retcode := 1;
            ELSE
               fnd_file.put_line (fnd_file.LOG, 'Common File copy program for File ' || i || ' completed normal');
               p_retcode := 0;
            END IF;

            SELECT GREATEST (p_retcode, ln_retcode)
              INTO ln_retcode
              FROM DUAL;
         END IF;
      --req_id_tbl_type Loop Ended here
      END LOOP;
      p_retcode := ln_retcode;
      gc_error_debug := 'Total no of records fetched: ' || ln_total_count;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Program run date:' || SYSDATE;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'End Extracting Staging table data into flat file' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN UTL_FILE.invalid_path
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_mode
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_operation
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.read_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.write_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.internal_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error:' || gc_error_debug);
         p_retcode := 2;
   --end of extract_stagedata
   END extract_stagedata;

--+==================================================================+
--|Name        : main                                                |
--|Description : This procedure is used to call the above three      |
--|              procedures. while registering concurrent            |
--|              program this procedure will be used                 |
--|                                                                  |
--|Parameters : p_actiontype                                         |
--|             p_debug_flag                                         |
--|             p_compute_stats                                      |
--|Returns    : p_errbuf                                             |
--|             p_retcode                                            |
--|                                                                  |
--+==================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   )
   IS
      -- Variable Declaration
      lc_action_type   VARCHAR2 (2);
      ln_batch_limit   NUMBER;
      ln_retcode       NUMBER;
   BEGIN
      lc_action_type := p_action_type;
      gc_debug_flag := p_debug_flag;
      gc_compute_stats := p_compute_stats;

      BEGIN
         SELECT xftv.target_value1
           INTO ln_batch_limit
           FROM xx_fin_translatevalues xftv
               ,xx_fin_translatedefinition xftd
          WHERE xftv.translate_id = xftd.translate_id
            AND xftd.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND xftv.source_value1 = 'CUST_SALES_ASSIGNMENT'
            AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
            AND xftv.enabled_flag = 'Y'
            AND xftd.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      gn_count := 0;
      fnd_file.put_line (fnd_file.LOG, '********** Sales Person Assignments Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '   ');
      fnd_file.put_line (fnd_file.LOG, '   Action Type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '   ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '   ');
      fnd_file.put_line (fnd_file.LOG, 'bulk collect batch limit is:' || ln_batch_limit);

      IF lc_action_type = 'F'
      THEN
         insert_fulldata (ln_batch_limit, ln_retcode);
         COMMIT;

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSIF lc_action_type = 'I'
      THEN
         insert_incrdata (ln_batch_limit, ln_retcode);
         COMMIT;

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSE
         gc_error_debug := 'Invalid parameter. Enter either F or I';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLERRM || 'NO data found in the main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || 'Others exception is raised in main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   -- End of the main procedure
   END main;
--End of XX_CRM_CUST_SLSAS_EXTRACT_PKG Package Body
END xx_crm_cust_slsas_extract_pkg;
/

SHOW ERRORS;