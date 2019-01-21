CREATE OR REPLACE PACKAGE BODY xx_crm_cust_head_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_HEAD_EXTRACT_PKG                           |
--|RICE        : 106313                                                 |
--|Description :This Package is used for insert data into staging       |
--|             table and fetch data from staging table to flat file    |
--|                                                                     |
--|             The STAGING Procedure will perform the following steps  |
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
--|=======   ======        ====================   =========             |
--|1.0       30-Aug-2011   Balakrishna Bolikonda  Initial Version       |
--|1.1       10-May-2012   Jay Gupta              Defect 18387 - Add    |
--|                                            Request_id in LOG tables |
--|2.0       08-Jul-2015   Sridevi K              Mod 5 Changes         |
--|3.0       10-Nov-2015   Havish Kasina          Removed the Schema    |
--|                                               References as per     |
--|                                               R12.2 Retrofit Changes|
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
--|Parameters : P_batch_limit                                        |
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
      --Variable declaration of Table type
      cm_full_tbl_type   lt_cust_master;
      --variable declaration
      ln_batch_limit     NUMBER;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_fulldata
      IS
         SELECT DISTINCT HCA.cust_account_id "cust_account_id"
               ,HCA.account_number "customer number"
               ,HP.party_number "organization number"
               ,SUBSTR (HCA.orig_system_reference ,1 ,8 ) "customer number AOPS"
               ,HP.party_name "customer name"
               ,HCA.status "status"
               ,HCA.attribute18 "customer type"
               ,HCA.customer_class_code "customer class code"
               ,HCA.sales_channel_code "sales channel code"
               ,HP.sic_code "SIC code"
--               ,HP.category_code "cust_category_code"
               ,HP_CAT.meaning "cust_category_code"
               ,HP.duns_number_c "DUNS number"
               ,HP.sic_code_type "SIC code type"
               ,AC.NAME "collector_number"
               ,AC.description  "collector_name"
               ,HCP.attribute3 "credit checking"
               ,HCP.credit_rating "credit rating"
               ,HCA.attribute6 "account established date"
               ,HCPA_USD.overall_credit_limit "account credit limit USD"
               ,HCPA_CAD.overall_credit_limit "account credit limit CAD"
               ,HCPA_USD.trx_credit_limit "order credit limit USD"
               ,HCPA_CAD.trx_credit_limit "order credit limit CAD"
--               ,HCP.credit_classification "credit classification"
	       ,arpt_sql_func_util.get_lookup_meaning('AR_CMGT_CREDIT_CLASSIFICATION',HCP.CREDIT_CLASSIFICATION) "credit classification"
               ,HCP.account_status "exposure analysis segment"
               ,HCP.risk_code "risk code"
               ,HCA.attribute19 "source of creation for credit"
               ,HCA.attribute1 "PO value"
               ,HCA.attribute2 "PO"
               ,HCA.attribute3 "release value"
               ,HCA.attribute4 "release"
               ,HCA.attribute5 "cost center value"
               ,HCA.attribute9 "cost center"
               ,HCA.attribute10 "desktop value"
               ,HCA.attribute11 "desktop"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
               ,CASE 
                WHEN (instr(hp.orig_system_reference,'-OMX') > 0)
                      THEN REGEXP_REPLACE(hp.orig_system_reference,'-OMX', '')
                   ELSE NULL
                END omx_account_number
               ,ext.c_ext_attr3                      billdocs_delivery_method 
           FROM xx_crm_wcelg_cust XCEC
               ,hz_parties HP
               ,hz_cust_accounts HCA
               ,hz_customer_profiles HCP
               ,hz_cust_profile_amts HCPA_USD
               ,hz_cust_profile_amts HCPA_CAD
               ,xx_cdh_cust_acct_ext_b ext 
               ,ar_collectors AC
	       , (
		   SELECT lookup_code, max(meaning) meaning FROM ar_lookups a
		      GROUP BY lookup_code HAVING count(*)=1
		   UNION
		   SELECT lookup_code, meaning FROM ar_lookups where lookup_code IN (
		      SELECT lookup_code FROM ar_lookups a
		        GROUP BY lookup_code HAVING count(*)>1) AND lookup_type='CUSTOMER_CATEGORY'
		) HP_CAT
          WHERE XCEC.party_id = HP.party_id
            AND XCEC.cust_account_id = HCA.cust_account_id
            AND HP.party_id = HCA.party_id
            AND HCA.cust_account_id = HCP.cust_account_id
            AND HCP.site_use_id IS NULL
            AND HCP.cust_account_profile_id = HCPA_USD.cust_account_profile_id(+)
            AND HCPA_USD.currency_code(+) = 'USD'
            AND HCP.cust_account_profile_id = HCPA_CAD.cust_account_profile_id(+)
            AND HCPA_CAD.currency_code(+) = 'CAD'
            AND HCP.collector_id = AC.collector_id
            AND XCEC.cust_mast_head_ext = 'N'
	    AND HP.CATEGORY_CODE = HP_CAT.LOOKUP_CODE(+)
            AND HCA.cust_account_id = ext.cust_account_id (+)
            AND ext.attr_group_id (+)          = 166 
            AND ext.c_ext_attr2 (+)           = 'Y' 
            AND sysdate between nvl(ext.D_EXT_ATTR1,sysdate-1) and nvl(ext.D_EXT_ATTR2, sysdate+1)
            AND ext.c_ext_attr16 (+)           = 'COMPLETE' ;


   BEGIN
      gc_error_debug := 'Start Extracting full data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Header';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custmast_head_stg';

      --Cursor Loop started here
      gc_error_debug := NULL;
      ln_batch_limit := p_batch_limit;

      OPEN lcu_fulldata;

      gc_error_debug := 'Loop started here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_fulldata
         BULK COLLECT INTO cm_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_full_tbl_type.COUNT
            INSERT INTO xx_crm_custmast_head_stg
                 VALUES cm_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_fulldata%NOTFOUND;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||lcu_fulldata%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');

      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);

      --Curosr Loop ended here
      CLOSE lcu_fulldata;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTMAST_HEAD_STG'
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
   --End of insert_fulldata
   END insert_fulldata;

--+==================================================================+
--|Name        :insert_incrdata                                      |
--|Description :This procedure is used to fetch the incremental data |
--|              from base tables to staging table                   |
--|                                                                  |
--|                                                                  |
--|Parameters : P_batch_limit                                        |
--|                                                                  |
--|                                                                  |
--|Returns    : p_retcode                                            |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE insert_incrdata (
      P_batch_limit   IN       NUMBER
     ,p_retcode       OUT      NUMBER
   )
   IS
	--Table type declaration
	cm_incr_tbl_type   lt_cust_master;
	--variable declaration
	ln_batch_limit     NUMBER;
	l_currdt         DATE;
	l_rundt          DATE;
	l_count          NUMBER;
	l_range          NUMBER;
	v_stmt           VARCHAR2 (200);
	l_parent_sid     NUMBER;
	v_jobno          NUMBER;
	v_running_jobs   NUMBER;
	v_expected       NUMBER;
	v_actual         NUMBER;
	v_in_degree      NUMBER;
	min_record       NUMBER;
	max_record       NUMBER;
	l_batch_id       NUMBER;
	lv_phase VARCHAR2(20);
	lv_status VARCHAR2(20);
	lv_dev_phase VARCHAR2(20);
	lv_dev_status VARCHAR2(20);
	lv_message1 VARCHAR2(20);
	ln_request_id NUMBER := 0;
	lb_result BOOLEAN;
	TYPE num_array IS TABLE OF NUMBER
	INDEX BY BINARY_INTEGER;
	ln_header_cnt NUMBER := 0;
	l_child_conc	VARCHAR2(50);
	l_degree	NUMBER;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);
	ln_nextval	    NUMBER  DEFAULT 0;

	req_array num_array;
	ln_request_number NUMBER:=0;


      --cursor declaration: This is used to fetch the incremental customer master data from base tables
      CURSOR lcu_incremental
      IS
	SELECT ROWNUM record_id, cust_account_id FROM
	  (
		SELECT  cust_account_id
			 FROM xx_crm_common_DELTA A
			 WHERE content_type IN ('HZ_PARTIES','HZ_CUST_ACCOUNTS','HZ_CUSTOMER_PROFILES','HZ_CUST_PROFILE_AMTS')
		 UNION
			SELECT  cust_account_id
			FROM xx_crm_wcelg_cust A WHERE cust_mast_head_ext = 'N'
	);

   BEGIN
      gc_error_debug := 'Start Extracting Incremental data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating staging table';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custmast_head_stg';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custmast_accountid_stg';


-- Inserting cust_account_id into staging table start
	FOR accountid_custmast IN lcu_incremental
	LOOP
		    BEGIN
		     INSERT INTO xx_crm_custmast_accountid_stg
		     (
		     RECORD_ID,
		     CUST_ACCOUNT_ID
		     )
		     VALUES
		     (
		      accountid_custmast.record_id,
		      accountid_custmast.cust_account_id
		      );
		     EXCEPTION WHEN OTHERS THEN
		       fnd_file.put_line(fnd_file.log,'Account ID:' || accountid_custmast.cust_account_id || ' Could Not be Inserted' || '::' || SQLERRM);
		     END;
		COMMIT;
	END LOOP;
-- Inserting cust_account_id into staging table end




-- Parallel thread degree and child conc program name start
         SELECT XFTV.target_value14,
		XFTV.target_value16
           INTO l_degree, l_child_conc
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'CUST_HEADER'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

-- Parallel thread degree and child conc program name end


-- Parallel thread start

      SELECT NVL(MAX(to_number(record_id)),-1)- NVL(MIN(to_number(record_id)),0)+1, NVL(MIN(to_number(record_id)),0) ,  NVL(MAX(to_number(record_id)),0)
            INTO l_count, min_record, max_record
       FROM xx_crm_custmast_accountid_stg
       ;

	      l_currdt := SYSDATE;
	      l_range := CEIL (l_count / l_degree);
	      FOR i IN 1 .. ( l_degree - 1)
		LOOP
		    -- ---------------------------------------------------------
		    -- Call the custom concurrent program for parallel execution
		    -- ---------------------------------------------------------
		    ln_request_id := FND_REQUEST.submit_request
		    (
		      application => 'XXCRM' ,program => l_child_conc ,sub_request => FALSE ,argument1 => (TO_CHAR (min_record + (l_range*(i - 1)) )) ,argument2 => ( TO_CHAR (min_record + (l_range*i - 1) ) )
		    )
		    ;
		    req_array (i) := ln_request_id;
		    IF ln_request_id = 0 THEN

		    fnd_file.put_line(fnd_file.log,'could not submit the child request at '||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));

		    END IF; -- ln_request_id = 0

	      ln_request_number:=i;
	      END LOOP;



	    ln_request_id := FND_REQUEST.submit_request
	    (
	      application => 'XXCRM' ,program => l_child_conc ,sub_request => FALSE ,argument1 => (TO_CHAR (min_record + (l_range*(l_degree - 1) - 1) + 1 )) ,argument2 => ( max_record )
	    )
	    ;
		ln_request_number:=ln_request_number+1;
		req_array(ln_request_number) := ln_request_id;

		    IF ln_request_id = 0 THEN

				 fnd_file.put_line(fnd_file.log,'could not submit the child request at '||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS'));

		    END IF;


         COMMIT;

		v_running_jobs:=1;

		WHILE v_running_jobs > 0
			LOOP
				 DBMS_LOCK.sleep (60);
				 v_running_jobs:=0;
				     FOR i           IN req_array.first .. req_array.last
					    LOOP
						lb_result := fnd_concurrent.wait_for_request
						(
						  req_array(i), 10, 0, lv_phase, lv_status, lv_dev_phase, lv_dev_status, lv_message1
						);
							IF lv_dev_phase    = 'COMPLETE' THEN
								NULL;
							ELSE
								v_running_jobs:=v_running_jobs+1;
							END IF;
					     END LOOP;
			END LOOP;


-- Parallel thread end


	SELECT COUNT(*) INTO ln_header_cnt FROM xx_crm_custmast_head_stg;


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
                     ,ln_header_cnt
                     ,'SUCCESS'
                     ,'Processed'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

	COMMIT;


      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||ln_header_cnt;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);


      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTMAST_HEAD_STG'
                    );
      gc_error_debug := 'End Extracting Incremental data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' No data found while fetching incremental data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception raised while fetching full data from customer base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_incrdata
   END insert_incrdata;

PROCEDURE insert_incrdata_child (
      x_errbuf OUT nocopy  VARCHAR2,
      x_retcode OUT nocopy VARCHAR2,
      in_low          NUMBER,
      in_high         NUMBER
   )
   IS
	l_start_dt            DATE;
	v_curr_dt             DATE;
	l_rundt               DATE;
	c_limit_size          NUMBER                                 := 100;
--- should be multiple of c_limit_size.
	l_total               NUMBER;

	v_error_msg           VARCHAR2 (1000);
	v_curr_record_id      xx_crm_custmast_accountid_stg.record_id%TYPE;
	l_modified_date       DATE;
	v_time_taken          NUMBER;
	v_time_left           NUMBER;
	v_isfirst             BOOLEAN                                := TRUE;
	v_ctr                 NUMBER                                 := 0;
	v_error               NUMBER;
	l_rec_status          VARCHAR2(5);
	l_rec_msg             VARCHAR2(2000);
	l_tot_header_updated            NUMBER := 0;
        l_batch_id                   NUMBER;

	  CURSOR acct_list_cur
	  IS
	  SELECT cust_account_id, record_id
	  FROM xx_crm_custmast_accountid_stg
	  WHERE record_id BETWEEN in_low AND in_high;

	CURSOR acct_header (p_account_id   NUMBER)
	IS
         SELECT DISTINCT HCA.cust_account_id cust_account_id
               ,HCA.account_number customer_number
               ,HP.party_number organization_number
               ,SUBSTR (HCA.orig_system_reference ,1 ,8 ) customer_number_AOPS
               ,HP.party_name customer_name
               ,HCA.status status
               ,HCA.attribute18 customer_type
               ,HCA.customer_class_code customer_class_code
               ,HCA.sales_channel_code sales_channel_code
               ,HP.sic_code SIC_code
--               ,HP.category_code "cust_category_code"
               ,HP_CAT.meaning cust_category_code
               ,HP.duns_number_c DUNS_number
               ,HP.sic_code_type SIC_code_type
               ,AC.NAME collector_number
               ,AC.description  collector_name
               ,HCP.attribute3 credit_checking
               ,HCP.credit_rating credit_rating
               ,HCA.attribute6 account_established_date
               ,HCPA_USD.overall_credit_limit account_credit_limit_USD
               ,HCPA_CAD.overall_credit_limit account_credit_limit_CAD
               ,HCPA_USD.trx_credit_limit order_credit_limit_USD
               ,HCPA_CAD.trx_credit_limit order_credit_limit_CAD
--               ,HCP.credit_classification "credit classification"
	       ,arpt_sql_func_util.get_lookup_meaning('AR_CMGT_CREDIT_CLASSIFICATION',HCP.CREDIT_CLASSIFICATION) credit_classification
               ,HCP.account_status exposure_analysis_segment
               ,HCP.risk_code risk_code
               ,HCA.attribute19 source_of_creation_for_credit
               ,HCA.attribute1 PO_value
               ,HCA.attribute2 PO
               ,HCA.attribute3 release_value
               ,HCA.attribute4 release
               ,HCA.attribute5 cost_center_value
               ,HCA.attribute9 cost_center
               ,HCA.attribute10 desktop_value
               ,HCA.attribute11 desktop
               ,CASE 
                WHEN (instr(hp.orig_system_reference,'-OMX') > 0)
                      THEN REGEXP_REPLACE(hp.orig_system_reference,'-OMX', '')
                   ELSE NULL
                END omx_account_number
               ,ext.c_ext_attr3                      billdocs_delivery_method 
           FROM xx_crm_wcelg_cust XCEC
               ,hz_parties HP
               ,hz_cust_accounts HCA
               ,hz_customer_profiles HCP
               ,hz_cust_profile_amts HCPA_USD
               ,hz_cust_profile_amts HCPA_CAD
               ,ar_collectors AC
               ,ar_lookups HP_CAT
               ,xx_cdh_cust_acct_ext_b ext  
          WHERE XCEC.party_id = HP.party_id
            AND XCEC.cust_account_id = HCA.cust_account_id
            AND HP.party_id = HCA.party_id
            AND HCA.cust_account_id = HCP.cust_account_id
            AND HCP.site_use_id IS NULL
            AND HCP.cust_account_profile_id = HCPA_USD.cust_account_profile_id(+)
            AND HCPA_USD.currency_code(+) = 'USD'
            AND HCP.cust_account_profile_id = HCPA_CAD.cust_account_profile_id(+)
            AND HCPA_CAD.currency_code(+) = 'CAD'
            AND HCP.collector_id = AC.collector_id
            AND hca.cust_account_id = p_account_id
            AND HP_CAT.lookup_type(+) ='CUSTOMER_CATEGORY'
            AND HP.CATEGORY_CODE = HP_CAT.LOOKUP_CODE(+)
            AND HCA.cust_account_id = ext.cust_account_id (+)
            AND ext.attr_group_id (+)          = 166 
            AND ext.c_ext_attr2 (+)           = 'Y' 
            AND sysdate between nvl(ext.D_EXT_ATTR1,sysdate-1) and nvl(ext.D_EXT_ATTR2, sysdate+1)
            AND ext.c_ext_attr16 (+)           = 'COMPLETE';

BEGIN

      l_total := in_high - in_low + 1;
      l_start_dt := SYSDATE;


	    FOR csids IN acct_list_cur LOOP
	       v_curr_record_id := csids.record_id;
	       v_curr_dt := SYSDATE;

			FOR cs IN acct_header (csids.cust_account_id) LOOP

			   l_rec_status  := NULL;
			   l_rec_msg     := NULL;



			   BEGIN

				INSERT INTO xx_crm_custmast_head_stg
				(
					cust_account_id, customer_number, organization_number, customer_number_aops,
					customer_name, status, customer_type, customer_class_code, sales_channel_code,
					sic_code, cust_category_code, duns_number, sic_code_type, collector_number,
					collector_name, credit_checking, credit_rating, account_established_date,
					account_credit_limit_usd, account_credit_limit_cad, order_credit_limit_usd,
					order_credit_limit_cad, credit_classification, exposure_analysis_segment,
					risk_code, source_of_creation_for_credit, po, release, cost_center, desktop,
					po_value, release_value, cost_center_value, desktop_value, last_updated_by,
					creation_date, request_id, created_by, last_update_date, program_id, omx_account_number, billdocs_delivery_method
				 ) VALUES
				 (
					cs.cust_account_id, cs.customer_number, cs.organization_number, cs.customer_number_aops,
					cs.customer_name, cs.status, cs.customer_type, cs.customer_class_code, cs.sales_channel_code,
					cs.sic_code, cs.cust_category_code, cs.duns_number, cs.sic_code_type, cs.collector_number,
					cs.collector_name, cs.credit_checking, cs.credit_rating, cs.account_established_date,
					cs.account_credit_limit_usd, cs.account_credit_limit_cad, cs.order_credit_limit_usd,
					cs.order_credit_limit_cad, cs.credit_classification, cs.exposure_analysis_segment,
					cs.risk_code, cs.source_of_creation_for_credit, cs.po_value, cs.po, cs.release_value, cs.release,
					cs.cost_center_value, cs.cost_center, cs.desktop_value, cs.desktop, gn_last_updated_by ,
					gd_creation_date ,gn_request_id ,gn_created_by ,gd_last_update_date ,gn_program_id, cs.omx_account_number, cs.billdocs_delivery_method
				);

-- Issue in last few parameters mapping in Insert statement


				     l_tot_header_updated := l_tot_header_updated + sql%rowcount ;

			   EXCEPTION WHEN OTHERS THEN
			     fnd_file.put_line(fnd_file.log,'Error during insert into xx_crm_custmast_head_stg for Oracle cust_account_id :' || cs.cust_account_id || '::' || SQLERRM);
			   END;
			END LOOP;

			COMMIT;

	     END LOOP;

	fnd_file.put_line(fnd_file.log,'Total records '|| l_tot_header_updated ||' are inserted into xx_crm_custmast_head_stg ');

			COMMIT;

END insert_incrdata_child;



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
      lc_mode                VARCHAR2 (1)       := 'W';
      ln_linesize            NUMBER;
      lc_comma               VARCHAR2 (2);
      ln_batch_limit         NUMBER;
      ln_count               NUMBER             := 0;
      ln_total_count         NUMBER             := 0;
      ln_fno                 NUMBER             := 1;
      ln_no_of_records       NUMBER;
      lc_debug_flag          VARCHAR2 (2);
      lc_compute_stats       VARCHAR2 (2);
      lc_destination_path    VARCHAR2 (500);
      ln_ftp_request_id      NUMBER;
      lc_archive_directory   VARCHAR2 (500);
      lc_source_path         VARCHAR2 (500);
      ln_idx                 NUMBER             := 1;
      ln_idx2                NUMBER             := 1;
      lc_phase               VARCHAR2 (200);
      lc_status              VARCHAR2 (200);
      lc_dev_phase           VARCHAR2 (200);
      lc_dev_status          VARCHAR2 (200);
      lc_message2            VARCHAR2 (200);
      ln_retcode             NUMBER             := 0;
      ln_rec_count           NUMBER             := 0;
      --Table type declaration
      cm_stage_tbl_type      lt_cust_master;
      req_id_tbl_type        lt_req_id;
      file_names_tbl_type    lt_file_names;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);

      --cursor declaration: This is used to fetech the staging table data
      CURSOR lcu_customer_master
      IS
         SELECT CUST.cust_account_id
               ,CUST.customer_number
               ,CUST.organization_number
               ,CUST.customer_number_aops
               ,CUST.customer_name
               ,CUST.status
               ,CUST.customer_type
               ,CUST.customer_class_code
               ,CUST.sales_channel_code
               ,CUST.sic_code
               ,CUST.cust_category_code
               ,CUST.duns_number
               ,CUST.sic_code_type
               ,CUST.collector_number
               ,CUST.collector_name
               ,CUST.credit_checking
               ,CUST.credit_rating
               ,CUST.account_established_date
               ,CUST.account_credit_limit_usd
               ,CUST.account_credit_limit_cad
               ,CUST.order_credit_limit_usd
               ,CUST.order_credit_limit_cad
               ,CUST.credit_classification
               ,CUST.exposure_analysis_segment
               ,CUST.risk_code
               ,CUST.source_of_creation_for_credit
               ,CUST.po_value
               ,CUST.po
               ,CUST.release_value
               ,CUST.release
               ,CUST.cost_center_value
               ,CUST.cost_center
               ,CUST.desktop_value
               ,CUST.desktop
               ,CUST.last_updated_by
               ,CUST.creation_date
               ,CUST.request_id
               ,CUST.created_by
               ,CUST.last_update_date
               ,CUST.program_id
               ,CUST.omx_account_number
               ,CUST.billdocs_delivery_method
           FROM xx_crm_custmast_head_stg CUST;
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
            AND XFTV.source_value1 = 'CUST_HEADER'
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
         SELECT AD.directory_path
           INTO lc_source_path
           FROM all_directories AD
          WHERE directory_name = lc_filepath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while selecting source path from translation defination';
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
            p_retcode := 2;
      END;


      ln_request_id_p := fnd_global.conc_request_id ();

	SELECT  a.program, a.program_short_name
		INTO ln_program_name, ln_program_short_name
	FROM FND_CONC_REQ_SUMMARY_V A
	WHERE a.request_id = ln_request_id_p;


      fnd_file.put_line (fnd_file.LOG, '********** Customer Master Stage File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || lc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '       ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is :' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   Line Size limit is :' || ln_linesize);
      fnd_file.put_line (fnd_file.LOG, '   Source File Path is :' || lc_source_path);
      fnd_file.put_line (fnd_file.LOG, '   Destination File Path is :' || lc_destination_path);
      fnd_file.put_line (fnd_file.LOG, '   Archive File Path is :' || lc_archive_directory);
      fnd_file.put_line (fnd_file.LOG, '   Delimiter is :' || lc_comma);
      fnd_file.put_line (fnd_file.LOG, '   No of records per File :' || ln_no_of_records);

      SELECT COUNT(*)
      INTO ln_rec_count
      FROM xx_crm_custmast_head_stg;

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
                    ,'XX_CRM_CUSTMAST_HEAD_STG'
                    );
      --Cursor loop started here
      gc_error_debug := 'Loop started here for fetching data into flat file ';
      write_log (lc_debug_flag, gc_error_debug);

      OPEN lcu_customer_master;

      LOOP
         FETCH lcu_customer_master
         BULK COLLECT INTO cm_stage_tbl_type LIMIT ln_batch_limit;

         FOR i IN 1 .. cm_stage_tbl_type.COUNT
         LOOP
            lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                  cm_stage_tbl_type (i).cust_account_id
               || lc_comma
               || cm_stage_tbl_type (i).customer_number
               || lc_comma
               || cm_stage_tbl_type (i).organization_number
               || lc_comma
               || cm_stage_tbl_type (i).customer_number_aops
               || lc_comma
               || cm_stage_tbl_type (i).customer_name
               || lc_comma
               || cm_stage_tbl_type (i).status
               || lc_comma
               || cm_stage_tbl_type (i).customer_type
               || lc_comma
               || cm_stage_tbl_type (i).customer_class_code
               || lc_comma
               || cm_stage_tbl_type (i).sales_channel_code
               || lc_comma
               || cm_stage_tbl_type (i).sic_code
               || lc_comma
               || cm_stage_tbl_type (i).cust_category_code
               || lc_comma
               || cm_stage_tbl_type (i).duns_number
               || lc_comma
               || cm_stage_tbl_type (i).sic_code_type
               || lc_comma
               || cm_stage_tbl_type (i).collector_number
               || lc_comma
               || cm_stage_tbl_type (i).collector_name
               || lc_comma
               || cm_stage_tbl_type (i).credit_checking
               || lc_comma
               || cm_stage_tbl_type (i).credit_rating
               || lc_comma
               || cm_stage_tbl_type (i).account_established_date
               || lc_comma
               || cm_stage_tbl_type (i).account_credit_limit_usd
               || lc_comma
               || cm_stage_tbl_type (i).account_credit_limit_cad
               || lc_comma
               || cm_stage_tbl_type (i).order_credit_limit_usd
               || lc_comma
               || cm_stage_tbl_type (i).order_credit_limit_cad
               || lc_comma
               || cm_stage_tbl_type (i).credit_classification
               || lc_comma
               || cm_stage_tbl_type (i).exposure_analysis_segment
               || lc_comma
               || cm_stage_tbl_type (i).risk_code
               || lc_comma
               || cm_stage_tbl_type (i).source_of_creation_for_credit
               || lc_comma
               || cm_stage_tbl_type (i).po_value
               || lc_comma
               || cm_stage_tbl_type (i).po
               || lc_comma
               || cm_stage_tbl_type (i).release_value
               || lc_comma
               || cm_stage_tbl_type (i).release
               || lc_comma
               || cm_stage_tbl_type (i).cost_center_value
               || lc_comma
               || cm_stage_tbl_type (i).cost_center
               || lc_comma
               || cm_stage_tbl_type (i).desktop_value
               || lc_comma
               || cm_stage_tbl_type (i).desktop
               || lc_comma
               || cm_stage_tbl_type (i).omx_account_number
               || lc_comma
               || cm_stage_tbl_type (i).billdocs_delivery_method
			   );
            UTL_FILE.put_line (lc_filehandle, lc_message);
            --Incrementing count of records in the file and total records fethed on particular day
            ln_count := ln_count + 1;
            ln_total_count := ln_total_count + 1;

            --updating  cust_mast_head_ext flag to 'Y' in eligibility table after extracing data for customer
            UPDATE xx_crm_wcelg_cust
               SET cust_mast_head_ext = 'Y'
             WHERE cust_account_id = cm_stage_tbl_type (i).cust_account_id AND cust_mast_head_ext = 'N';

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
         EXIT WHEN lcu_customer_master%NOTFOUND;
      END LOOP;

      CLOSE lcu_customer_master;

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

      UTL_FILE.put_line (lc_filehandle, lc_message1);
      --Cursor loop ended here
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
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_mode
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_filehandle
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.invalid_operation
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.read_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.write_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN UTL_FILE.internal_error
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         gc_error_debug := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Error: ' || gc_error_debug);
         p_retcode := 2;
   --End of extract_stagedata
   END extract_stagedata;

--+==================================================================+
--|Name        : main                                                |
--|Description : This procedure is used to call the above three      |
--|              procedures. while registering concurrent            |
--|              program this procedure will be used                 |
--|                                                                  |
--|Parameters : p_action_type                                        |
--|             p_debug_flag                                         |
--|             p_compute_stats                                      |
--|                                                                  |
--| Returns    : p_errbuf                                            |
--|              p_retcode                                           |
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
         SELECT XFTV.target_value1
           INTO ln_batch_limit
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'CUST_HEADER'
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

      gn_count := 0;
      fnd_file.put_line (fnd_file.LOG, '********** Customer Master Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '    ');
      fnd_file.put_line (fnd_file.LOG, '   Action Type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '    ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '    ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is :' || ln_batch_limit);

      IF lc_action_type = 'F'
      THEN
         insert_fulldata (ln_batch_limit, ln_retcode);

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSIF lc_action_type = 'I'
      THEN
         insert_incrdata (ln_batch_limit, ln_retcode);

         IF ln_retcode != 0
         THEN
            p_retcode := ln_retcode;
         END IF;
      ELSE
         gc_error_debug := 'Invalid parameter. Enter either F or I';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode:= 2;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := 'NO data found in the main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   -- End of the main procedure
   END main;

--End of XX_CRM_CUST_HEAD_EXTRACT_PKG Package Body
END xx_crm_cust_head_extract_pkg;
/

SHOW errors;


