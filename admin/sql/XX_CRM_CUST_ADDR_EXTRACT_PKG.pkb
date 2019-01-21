CREATE OR REPLACE PACKAGE BODY xx_crm_cust_addr_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :XX_CRM_CUST_ADDR_EXTRACT_PKG                            |
--|RICE        :106313                                                  |
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
--|Version    Date           Author                Remarks              |
--|=======   ======        ====================    =========            |
--|1.0       30-Aug-2011   Balakrishna Bolikonda   Initial Version      |
--|1.1       10-May-2012   Jay Gupta               Defect 18387 - Add   |
--|                                            Request_id in LOG tables |
--|1.2       14-June-2012   Devendra P         Parallel thread added for|
--|                                            Address query		    |
--|1.3       11-Nov-2015    Havish K           Removed the Schema References|
--|                                            as per R12.2 Retrofit Changes|
--|1.4       02-March-2016  Vasu R             Made code changes to SVN version 240705 |
--|                                            to Include changes in version 199107 to |
--|                                            comment Dunning_letters field           |
-- +===============================================================================+
-- | Name       : WRITE_LOG                                                        |
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

--+==================================================================+
--|Name        :insert_fulldata                                      |
--|Description :This procedure is used to fetch the total data       |
--|               from base tables to staging table                  |
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
      --Variable declaration of Table type
      cm_full_tbl_type   lt_cust_addr;
      --variable declaration
      ln_batch_limit     NUMBER;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_fulldata
      IS
        select  /*+ LEADING (XCEC) index(HCP, HZ_CUSTOMER_PROFILES_N1) index(AC, AR_COLLECTORS_U1) index( HSA,HZ_CUST_ACCT_SITES_U1)*/
		    HCSU.SITE_USE_ID             "site_use_id"
       ,HCSU.ORG_ID                 "org_id"
       ,HCA.CUST_ACCOUNT_ID
       ,HL.ADDRESS1               "address1"
       ,HL.ADDRESS2               "address2"
       ,HL.ADDRESS3               "address3"
       ,HL.ADDRESS4               "address4"
       ,HL.POSTAL_CODE            "postal_code"
       ,HL.CITY                   "city"
       ,HL.STATE                  "state"
       ,HL.PROVINCE               "province"
       ,HL.COUNTRY                "country"
       ,HPS.PARTY_SITE_NUMBER      "party_site_number"
       ,HCSU.PRIMARY_FLAG            "primary_flag"
       ,SUBSTR (HSA.ORIG_SYSTEM_REFERENCE ,10 ,14) "sequence"
       ,HSA.ORIG_SYSTEM_REFERENCE  "orig_system_reference"
       ,HCSU.LOCATION                "location"
       ,AC.NAME              "collector_number"
       ,AC.DESCRIPTION                      "collector_name"
       ,HCP.DUNNING_LETTERS          "dunning_letters"
       ,HCP.SEND_STATEMENTS          "send_statements"
       ,0                            "credit_limit_USD"
       ,0                            "credit_limit_CAD"
       ,HCPC.NAME                    "profile class name"
       ,HCP.CONS_INV_FLAG            "consolidated billing"
       ,HCP.CONS_INV_TYPE            "cons billing formats type"
       ,HCSU.ATTRIBUTE9              "bill in the box"
       ,HCSU.ATTRIBUTE10             "billing currency"
       ,HCSU.ATTRIBUTE12             "dunning delivery"
       ,HCSU.ATTRIBUTE18             "statementdelivery"
       ,HCSU.ATTRIBUTE19             "taxware entity code"
       ,HCSU.ATTRIBUTE25             "remit to sales channel"
       ,HSA.ECE_TP_LOCATION_CODE   "EDI location"
       ,HPS.ADDRESSEE              "address"
       ,HPS.IDENTIFYING_ADDRESS_FLAG "identifyingaddress"
       ,HSA.STATUS                 "acct site status"
       ,HCSU.STATUS                  "site use status"
       ,HCSU.SITE_USE_CODE           "site use code"
       ,gn_last_updated_by "last_updated_by"
       ,gd_creation_date "creation_date"
       ,gn_request_id "request_id"
       ,gn_created_by "created_by"
       ,gd_last_update_date "last_update_date"
       ,gn_program_id "program_id"
FROM    XX_CRM_WCELG_CUST XCEC
       ,HZ_CUST_ACCOUNTS HCA
       ,HZ_CUSTOMER_PROFILES HCP
       ,HZ_CUST_PROFILE_CLASSES HCPC
       ,HZ_CUST_SITE_USES_ALL HCSU
       ,HZ_CUST_ACCT_SITES_ALL HSA
	   ,HZ_PARTY_SITES HPS
	   ,HZ_LOCATIONS HL
       ,AR_COLLECTORS AC
WHERE  XCEC.CUST_ACCOUNT_ID      = HCA.CUST_ACCOUNT_ID
AND    HCA.CUST_ACCOUNT_ID       = HCP.CUST_ACCOUNT_ID
AND    HCP.SITE_USE_ID IS NOT NULL
AND    HCP.SITE_USE_ID           = HCSU.SITE_USE_ID(+)
AND    HCP.STATUS                = 'A'
AND    HCSU.CUST_ACCT_SITE_ID    = HSA.CUST_ACCT_SITE_ID
--AND    HCA.CUST_ACCOUNT_ID       = HCA.CUST_ACCOUNT_ID
AND    HPS.LOCATION_ID           = HL.LOCATION_ID
AND    HPS.PARTY_SITE_ID         = HSA.PARTY_SITE_ID
AND    HCSU.SITE_USE_CODE        = 'BILL_TO'
AND    HCP.PROFILE_CLASS_ID      = HCPC.PROFILE_CLASS_ID(+)
AND    HCP.SITE_USE_ID           = HCSU.SITE_USE_ID(+)
AND    HCP.COLLECTOR_ID          = AC.COLLECTOR_ID(+)
AND    XCEC.CUST_ADDR_EXT        = 'N';

   BEGIN
      gc_error_debug := 'Start Extracting full data from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Addresses';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custaddr_stg';

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
            INSERT INTO xx_crm_custaddr_stg
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
                    ,'XX_CRM_CUSTADDR_STG'
                    );
      gc_error_debug := 'End of Extracting Full data from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' No data found exception is raised while fetching full data from customer Address base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised while fetching full data from customer Address base tables';
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
      --Variable declaration of Table type
      cm_incr_tbl_type   lt_cust_addr;
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
	ln_addr_cnt NUMBER := 0;
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
	  (SELECT  cust_account_id
		 FROM xx_crm_common_DELTA A
		 WHERE content_type IN ('HZ_CUST_ACCOUNTS','HZ_PARTY_SITES','HZ_CUST_ACCT_SITES_ALL','HZ_LOCATIONS','HZ_CUST_SITE_USES_ALL','HZ_CUSTOMER_PROFILES')
         UNION
		SELECT  cust_account_id
		FROM xx_crm_wcelg_cust A WHERE cust_addr_ext = 'N'
	);



   BEGIN
      gc_error_debug := 'Start Extracting Incremental data from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Addresses';
      write_log (gc_debug_flag, gc_error_debug);

      -- Truncating customer address stage table
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custaddr_stg';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custaddr_accountid_stg';


-- Inserting cust_account_id into staging table start
	FOR accountid_address IN lcu_incremental
	LOOP
		    BEGIN
		     INSERT INTO xx_crm_custaddr_accountid_stg
		     (
		     RECORD_ID,
		     CUST_ACCOUNT_ID
		     )
		     VALUES
		     (
		      accountid_address.record_id,
		      accountid_address.cust_account_id
		      );
		     EXCEPTION WHEN OTHERS THEN
		       fnd_file.put_line(fnd_file.log,'Account ID:' || accountid_address.cust_account_id || ' Could Not be Inserted' || '::' || SQLERRM);
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
            AND XFTV.source_value1 = 'CUST_ADDRESSES'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

-- Parallel thread degree and child conc program name end



-- Parallel thread start

      SELECT NVL(MAX(to_number(record_id)),-1)- NVL(MIN(to_number(record_id)),0)+1, NVL(MIN(to_number(record_id)),0) ,  NVL(MAX(to_number(record_id)),0)
            INTO l_count, min_record, max_record
       FROM xx_crm_custaddr_accountid_stg
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

		WHILE v_running_jobs > 0 LOOP
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

	DELETE FROM XX_CRM_CUSTADDR_STG WHERE ROWID IN
	(
	SELECT b.ROWID FROM
	(SELECT MAX(rowid) rowid_1 FROM XX_CRM_CUSTADDR_STG GROUP BY SITE_USE_ID,ORG_ID,CUST_ACCOUNT_ID,ADDRESS1,ADDRESS2,ADDRESS3,
									ADDRESS4,POSTAL_CODE,CITY,STATE,PROVINCE,COUNTRY,PARTY_SITE_NUMBER,PRIMARY_FLAG,
									SEQUENCE,ORIG_SYSTEM_REFERENCE,LOCATION,COLLECTOR_NUMBER,COLLECTOR_NAME,DUNNING_LETTERS,
									SEND_STATEMENTS,CREDIT_LIMIT_USD,CREDIT_LIMIT_CAD,PROFILE_CLASS_NAME,CONSOLIDATED_BILLING,
									CONS_BILLING_FORMATS_TYPE,BILL_IN_THE_BOX,BILLING_CURRENCY,DUNNING_DELIVERY,STATEMENT_DELIVERY,
									TAXWARE_ENTITY_CODE,REMIT_TO_SALES_CHANNEL,EDI_LOCATION,ADDRESSEE,IDENTIFYING_ADDRESS,
									ACCT_SITE_STATUS,SITE_USE_STATUS,SITE_USE_CODE ) A,
	XX_CRM_CUSTADDR_STG B
	WHERE a.ROWID_1(+) = b.ROWID AND a.ROWID_1 IS NULL
	);

	COMMIT;

-- delete taking less than 30 secs

	SELECT COUNT(*) INTO ln_addr_cnt FROM xx_crm_custaddr_stg;


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
                     ,ln_addr_cnt
                     ,'SUCCESS'
                     ,'Processed'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

	COMMIT;

      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||ln_addr_cnt;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);



      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTADDR_STG'
                    );
      gc_error_debug := 'End of Extracting Full data from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' No data found exception is raised while fetching full data from customer Address base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised while fetching full data from customer Address base tables';
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
	v_curr_record_id      xx_crm_custaddr_accountid_stg.record_id%TYPE;
	l_modified_date       DATE;
	v_time_taken          NUMBER;
	v_time_left           NUMBER;
	v_isfirst             BOOLEAN                                := TRUE;
	v_ctr                 NUMBER                                 := 0;
	v_error               NUMBER;
	l_rec_status          VARCHAR2(5);
	l_rec_msg             VARCHAR2(2000);
	l_tot_addr_updated            NUMBER := 0;
        l_batch_id                   NUMBER;

	  CURSOR acct_list_cur
	  IS
	  SELECT cust_account_id, record_id
	  FROM xx_crm_custaddr_accountid_stg
	  WHERE record_id BETWEEN in_low AND in_high;

	CURSOR acct_address (p_account_id   NUMBER)
	IS
	SELECT HCSU.site_use_id site_use_id                    ,
	  HCAS.org_id org_id                                    ,
	  HCA.cust_account_id                                   ,
	  HL.address1 address1                                  ,
	  HL.address2 address2                                  ,
	  HL.address3 address3                                  ,
	  HL.address4 address4                                  ,
	  HL.postal_code postal_code                            ,
	  HL.city city                                          ,
	  HL.state state                                        ,
	  HL.province province                                  ,
	  HL.country country                                    ,
	  HPS.party_site_number party_site_number               ,
	  HCSU.primary_flag primary_flag                        ,
	  SUBSTR (HCAS.orig_system_reference ,10 ,14 ) sequence ,
	  HCAS.orig_system_reference orig_system_reference      ,
	  HCSU.LOCATION location                                ,
	  AC.NAME collector_number                              ,
	  AC.DESCRIPTION collector_name                         ,
	  HCP.dunning_letters dunning_letters                   ,
	  HCP.send_statements send_statements                   ,
	  0 credit_limit_USD                                    ,
	  0 credit_limit_CAD                                    ,
	  HCPC.NAME profile_class_name                          ,
	  HCP.cons_inv_flag consolidated_billing                ,
	  HCP.cons_inv_type cons_billing_formats_type           ,
	  HCSU.attribute9 bill_in_the_box                       ,
	  HCSU.attribute10 billing_currency                     ,
	  HCSU.attribute12 dunning_delivery                     ,
	  HCSU.attribute18 statement_delivery                   ,
	  HCSU.attribute19 taxware_entity_code                  ,
	  HCSU.attribute25 remit_to_sales_channel               ,
	  HCAS.ece_tp_location_code EDI_location                ,
	  HPS.addressee addressee                               ,
	  HPS.identifying_address_flag identifying_address      ,
	  HCAS.status acct_site_status                          ,
	  HCSU.status site_use_status                           ,
	  HCSU.site_use_code site_use_code
	 FROM
		  hz_cust_accounts HCA              ,
		  hz_cust_acct_sites_all HCAS       ,
		  hz_cust_site_uses_all HCSU        ,
		  hz_customer_profiles HCP     ,
		  HZ_CUST_PROFILE_CLASSES HCPC      ,
		  ar_collectors AC                  ,
		  hz_party_sites HPS                ,
		  hz_locations HL
	  WHERE HCA.cust_account_id         = p_account_id
		AND HCAS.cust_account_id        = hca.cust_account_id
		AND HCSU.cust_acct_site_id      = hcas.cust_acct_site_id
		AND HCSU.site_use_code          = 'BILL_TO'
		AND HCSU.site_use_id            = HCP.site_use_id
		AND HCAS.cust_account_id        = hcp.cust_account_id
		AND HCP.STATUS                  = 'A'
		AND HCP.PROFILE_CLASS_ID        = HCPC.PROFILE_CLASS_ID(+)
		AND HCP.collector_id            = AC.collector_id(+)
		AND HCAS.party_site_id          = HPS.party_site_id
		AND HPS.location_id             = HL.location_id
	UNION
	SELECT HCSU.site_use_id site_use_id                    ,
	  HCAS.org_id org_id                                    ,
	  HCA.cust_account_id                                   ,
	  HL.address1 address1                                  ,
	  HL.address2 address2                                  ,
	  HL.address3 address3                                  ,
	  HL.address4 address4                                  ,
	  HL.postal_code postal_code                            ,
	  HL.city city                                          ,
	  HL.state state                                        ,
	  HL.province province                                  ,
	  HL.country country                                    ,
	  HPS.party_site_number party_site_number               ,
	  HCSU.primary_flag primary_flag                        ,
	  SUBSTR (HCAS.orig_system_reference ,10 ,14 ) sequence ,
	  HCAS.orig_system_reference orig_system_reference      ,
	  HCSU.LOCATION location                                ,
	  AC.NAME collector_number                              ,
	  AC.DESCRIPTION collector_name                         ,
	  HCP.dunning_letters dunning_letters                   ,
	  HCP.send_statements send_statements                   ,
	  0 credit_limit_USD                                    ,
	  0 credit_limit_CAD                                    ,
	  HCPC.NAME profile_class_name                          ,
	  HCP.cons_inv_flag consolidated_billing                ,
	  HCP.cons_inv_type cons_billing_formats_type           ,
	  HCSU.attribute9 bill_in_the_box                       ,
	  HCSU.attribute10 billing_currency                     ,
	  HCSU.attribute12 dunning_delivery                     ,
	  HCSU.attribute18 statement_delivery                   ,
	  HCSU.attribute19 taxware_entity_code                  ,
	  HCSU.attribute25 remit_to_sales_channel               ,
	  HCAS.ece_tp_location_code EDI_location                ,
	  HPS.addressee addressee                               ,
	  HPS.identifying_address_flag identifying_address      ,
	  HCAS.status acct_site_status                          ,
	  HCSU.status site_use_status                           ,
	  HCSU.site_use_code site_use_code
	 FROM
	  hz_cust_accounts HCA              ,
	  hz_cust_acct_sites_all HCAS       ,
	  hz_cust_site_uses_all HCSU        ,
	  (SELECT * FROM hz_customer_profiles WHERE status = 'A' ) HCP_SITE,
	  hz_customer_profiles HCP     ,
	  HZ_CUST_PROFILE_CLASSES HCPC      ,
	  ar_collectors AC                  ,
	  hz_party_sites HPS                ,
	  hz_locations HL
	WHERE HCA.cust_account_id         = p_account_id
		AND HCAS.cust_account_id        = hca.cust_account_id
		AND HCSU.cust_acct_site_id      = hcas.cust_acct_site_id
		AND HCSU.site_use_code          = 'BILL_TO'
		AND HCSU.site_use_id            = HCP_SITE.site_use_id(+)
		AND HCP_SITE.site_use_id       IS NULL
		AND HCAS.cust_account_id        = hcp.cust_account_id
		AND HCP.site_use_id            IS NULL
		AND HCP.STATUS                  = 'A'
		AND HCP.PROFILE_CLASS_ID        = HCPC.PROFILE_CLASS_ID(+)
		AND HCP.collector_id            = AC.collector_id(+)
		AND HCAS.party_site_id          = HPS.party_site_id
		AND HPS.location_id             = HL.location_id;

BEGIN

      l_total := in_high - in_low + 1;
      l_start_dt := SYSDATE;


	    FOR csids IN acct_list_cur LOOP
	       v_curr_record_id := csids.record_id;
	       v_curr_dt := SYSDATE;

			FOR cs IN acct_address (csids.cust_account_id) LOOP

			   l_rec_status  := NULL;
			   l_rec_msg     := NULL;



			   BEGIN

				INSERT INTO xx_crm_custaddr_stg
				(
				 site_use_id ,org_id ,cust_account_id ,address1 ,address2 ,address3 ,address4 ,postal_code ,city ,state ,province ,country ,party_site_number ,primary_flag
				 ,sequence ,orig_system_reference ,location ,collector_number ,collector_name ,dunning_letters ,send_statements ,credit_limit_usd ,credit_limit_cad
				 ,profile_class_name ,consolidated_billing ,cons_billing_formats_type ,bill_in_the_box ,billing_currency ,dunning_delivery ,statement_delivery ,taxware_entity_code
				 ,remit_to_sales_channel ,edi_location ,addressee ,identifying_address ,acct_site_status ,site_use_status ,site_use_code ,last_updated_by ,creation_date
				 ,request_id ,created_by ,last_update_date ,program_id
				 ) VALUES
				 (
				 cs.site_use_id , cs.org_id , cs.cust_account_id ,cs.address1 ,cs.address2 ,cs.address3 ,cs.address4 ,cs.postal_code ,cs.city ,cs.state ,cs.province ,cs.country ,cs.party_site_number ,cs.primary_flag
				 ,cs.sequence ,cs.orig_system_reference ,cs.location ,cs.collector_number ,cs.collector_name ,cs.dunning_letters ,cs.send_statements ,cs.credit_limit_usd ,cs.credit_limit_cad
				 ,cs.profile_class_name ,cs.consolidated_billing ,cs.cons_billing_formats_type ,cs.bill_in_the_box ,cs.billing_currency ,cs.dunning_delivery ,cs.statement_delivery ,cs.taxware_entity_code
				 ,cs.remit_to_sales_channel ,cs.edi_location ,cs.addressee ,cs.identifying_address ,cs.acct_site_status ,cs.site_use_status ,cs.site_use_code ,gn_last_updated_by ,gd_creation_date
				 ,gn_request_id ,gn_created_by ,gd_last_update_date ,gn_program_id
				 );


				     l_tot_addr_updated := sql%rowcount + l_tot_addr_updated;

			   EXCEPTION WHEN OTHERS THEN
			     fnd_file.put_line(fnd_file.log,'Error during insert into xx_crm_custaddr_stg for Oracle cust_account_id :' || cs.cust_account_id || '::' || SQLERRM);
			   END;
			END LOOP;

			COMMIT;

	     END LOOP;

	fnd_file.put_line(fnd_file.log,'Total records '|| l_tot_addr_updated ||' are inserted into xx_crm_custaddr_stg ');

			COMMIT;

END insert_incrdata_child;


--+==================================================================+
--|Name        :insert_missingdelta                                  |
--|Description :This procedure is used to fetch the missing delta    |
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

   PROCEDURE insert_missingdelta (
      p_batch_limit   IN       NUMBER
     ,p_retcode       OUT      NUMBER
   )
   IS
      --Variable declaration of Table type
      cm_missing_tbl_type   lt_cust_addr;
      --variable declaration
      ln_batch_limit     NUMBER;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_missingdelta
      IS
        SELECT  /*+ LEADING (XCEC) index(HCP, HZ_CUSTOMER_PROFILES_N1) index(AC, AR_COLLECTORS_U1) index( HSA,HZ_CUST_ACCT_SITES_U1)*/
		    HCSU.SITE_USE_ID             "site_use_id"
       ,HCSU.ORG_ID                 "org_id"
       ,HCA.CUST_ACCOUNT_ID
       ,HL.ADDRESS1               "address1"
       ,HL.ADDRESS2               "address2"
       ,HL.ADDRESS3               "address3"
       ,HL.ADDRESS4               "address4"
       ,HL.POSTAL_CODE            "postal_code"
       ,HL.CITY                   "city"
       ,HL.STATE                  "state"
       ,HL.PROVINCE               "province"
       ,HL.COUNTRY                "country"
       ,HPS.PARTY_SITE_NUMBER      "party_site_number"
       ,HCSU.PRIMARY_FLAG            "primary_flag"
       ,SUBSTR (HSA.ORIG_SYSTEM_REFERENCE ,10 ,14) "sequence"
       ,HSA.ORIG_SYSTEM_REFERENCE  "orig_system_reference"
       ,HCSU.LOCATION                "location"
       ,AC.NAME              "collector_number"
       ,AC.DESCRIPTION                      "collector_name"
       ,HCP.DUNNING_LETTERS          "dunning_letters"
       ,HCP.SEND_STATEMENTS          "send_statements"
       ,0                            "credit_limit_USD"
       ,0                            "credit_limit_CAD"
       ,HCPC.NAME                    "profile class name"
       ,HCP.CONS_INV_FLAG            "consolidated billing"
       ,HCP.CONS_INV_TYPE            "cons billing formats type"
       ,HCSU.ATTRIBUTE9              "bill in the box"
       ,HCSU.ATTRIBUTE10             "billing currency"
       ,HCSU.ATTRIBUTE12             "dunning delivery"
       ,HCSU.ATTRIBUTE18             "statementdelivery"
       ,HCSU.ATTRIBUTE19             "taxware entity code"
       ,HCSU.ATTRIBUTE25             "remit to sales channel"
       ,HSA.ECE_TP_LOCATION_CODE   "EDI location"
       ,HPS.ADDRESSEE              "address"
       ,HPS.IDENTIFYING_ADDRESS_FLAG "identifyingaddress"
       ,HSA.STATUS                 "acct site status"
       ,HCSU.STATUS                  "site use status"
       ,HCSU.SITE_USE_CODE           "site use code"
       ,gn_last_updated_by "last_updated_by"
       ,gd_creation_date "creation_date"
       ,gn_request_id "request_id"
       ,gn_created_by "created_by"
       ,gd_last_update_date "last_update_date"
       ,gn_program_id "program_id"
FROM    XX_CRM_WCELG_CUST XCEC
       ,HZ_CUST_ACCOUNTS HCA
       ,HZ_CUSTOMER_PROFILES HCP
       ,HZ_CUST_PROFILE_CLASSES HCPC
       ,HZ_CUST_SITE_USES_ALL HCSU
       ,HZ_CUST_ACCT_SITES_ALL HSA
	   ,HZ_PARTY_SITES HPS
	   ,HZ_LOCATIONS HL
       ,AR_COLLECTORS AC
,	(
	SELECT aa.CUSTOMER_SITE_USE_ID FROM
	(SELECT /*+ PARALLEL (A,4)  */ DISTINCT bill_to_site_use_id CUSTOMER_SITE_USE_ID
	  FROM xx_ar_trans_wc_stg A
	 WHERE ext_type = 'F'
	 UNION
	 SELECT /*+ PARALLEL (A,4)  */ customer_site_use_id CUSTOMER_SITE_USE_ID
	   FROM xx_ar_cr_wc_stg A
	  WHERE ext_type = 'F') AA, xx_crm_custaddr_stg BB
	WHERE aa.CUSTOMER_SITE_USE_ID = bb.site_use_id (+) AND bb.site_use_id is null
	) missing_delta
WHERE  XCEC.CUST_ACCOUNT_ID      = HCA.CUST_ACCOUNT_ID
AND    HCA.CUST_ACCOUNT_ID       = HCP.CUST_ACCOUNT_ID
AND    HCP.SITE_USE_ID IS NOT NULL
AND    HCP.SITE_USE_ID           = HCSU.SITE_USE_ID(+)
AND    HCP.STATUS                = 'A'
AND    HCSU.CUST_ACCT_SITE_ID    = HSA.CUST_ACCT_SITE_ID
--AND    HCA.CUST_ACCOUNT_ID       = HCA.CUST_ACCOUNT_ID
AND    HPS.LOCATION_ID           = HL.LOCATION_ID
AND    HPS.PARTY_SITE_ID         = HSA.PARTY_SITE_ID
AND    HCSU.SITE_USE_CODE        = 'BILL_TO'
AND    HCP.PROFILE_CLASS_ID      = HCPC.PROFILE_CLASS_ID(+)
AND    HCP.SITE_USE_ID           = HCSU.SITE_USE_ID(+)
AND    HCP.COLLECTOR_ID          = AC.COLLECTOR_ID(+)
AND    HCP.SITE_USE_ID           = missing_delta.CUSTOMER_SITE_USE_ID;


   BEGIN
      gc_error_debug := 'Start Extracting Missing delta from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Addresses';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custaddr_stg';

      --Cursor Loop started here
      gc_error_debug := NULL;
      ln_batch_limit := p_batch_limit;

      OPEN lcu_missingdelta;

      gc_error_debug := 'Loop started here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);

      LOOP
         FETCH lcu_missingdelta
         BULK COLLECT INTO cm_missing_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_missing_tbl_type.COUNT
            INSERT INTO xx_crm_custaddr_stg
                 VALUES cm_missing_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_missingdelta%NOTFOUND;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||lcu_missingdelta%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);

      --Curosr Loop ended here
      CLOSE lcu_missingdelta;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTADDR_STG'
                    );
      gc_error_debug := 'End of Extracting Missing delta from customer Address base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         gc_error_debug := SQLCODE || ' No data found exception is raised while fetching missing delta from customer Address base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised while fetching missing delta from customer Address base tables';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   --End of insert_missingdelta
   END insert_missingdelta;


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
      --Variable declaration
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
      --Variable declaration of Table type
      cm_stage_tbl_type      lt_cust_addr;
      req_id_tbl_type        lt_req_id;
      file_names_tbl_type    lt_file_names;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);



      --cursor declaration: This is used to fetech the staging table data
      CURSOR lcu_customer_address
      IS
         SELECT ADDR.site_use_id
               ,ADDR.org_id
               ,ADDR.cust_account_id
               ,ADDR.address1
               ,ADDR.address2
               ,ADDR.address3
               ,ADDR.address4
               ,ADDR.postal_code
               ,ADDR.city
               ,ADDR.state
               ,ADDR.province
               ,ADDR.country
               ,ADDR.party_site_number
               ,ADDR.primary_flag
               ,ADDR.SEQUENCE
               ,ADDR.orig_system_reference
               ,ADDR.LOCATION
               ,ADDR.collector_number
               ,ADDR.collector_name
               ,ADDR.dunning_letters
               ,ADDR.send_statements
               ,ADDR.credit_limit_usd
               ,ADDR.credit_limit_cad
               ,ADDR.profile_class_name
               ,ADDR.consolidated_billing
               ,ADDR.cons_billing_formats_type
               ,ADDR.bill_in_the_box
               ,ADDR.billing_currency
               ,ADDR.dunning_delivery
               ,ADDR.statement_delivery
               ,ADDR.taxware_entity_code
               ,ADDR.remit_to_sales_channel
               ,ADDR.edi_location
               ,ADDR.addressee
               ,ADDR.identifying_address
               ,ADDR.acct_site_status
               ,ADDR.site_use_status
               ,ADDR.site_use_code
               ,ADDR.last_updated_by
               ,ADDR.creation_date
               ,ADDR.request_id
               ,ADDR.created_by
               ,ADDR.last_update_date
               ,ADDR.program_id
           FROM xx_crm_custaddr_stg ADDR;
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
            AND XFTV.source_value1 = 'CUST_ADDRESSES'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while selecting source path from translation defination';
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
            gc_error_debug := 'Exception raised while getting sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      ln_request_id_p := fnd_global.conc_request_id ();

	SELECT  a.program, a.program_short_name
		INTO ln_program_name, ln_program_short_name
	FROM FND_CONC_REQ_SUMMARY_V A
	WHERE a.request_id = ln_request_id_p;


      gn_count := 0;
      fnd_file.put_line (fnd_file.LOG, '********** Customer Addresses Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '      ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || lc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '      ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '      ');
      fnd_file.put_line (fnd_file.LOG, '   bulk collect batch limit is:' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   Line Size limit is :' || ln_linesize);
      fnd_file.put_line (fnd_file.LOG, '   Source File Path is :' || lc_source_path);
      fnd_file.put_line (fnd_file.LOG, '   Destination File Path is :' || lc_destination_path);
      fnd_file.put_line (fnd_file.LOG, '   Archive File Path is :' || lc_archive_directory);
      fnd_file.put_line (fnd_file.LOG, '   Delimiter is :' || lc_comma);
      fnd_file.put_line (fnd_file.LOG, '   No of records per File :' || ln_no_of_records);

      SELECT COUNT (*)
        INTO ln_rec_count
        FROM xx_crm_custaddr_stg;

      IF ln_rec_count = 0
      THEN
         gc_error_debug := 'No records found today';
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
         gc_error_debug := 'Loop started here for fetching data into flat file ';
         write_log (lc_debug_flag, gc_error_debug);
         --Gathering table stats
         compute_stats (lc_compute_stats
                       ,'XXCRM'
                       ,'XX_CRM_CUSTADDR_STG'
                       );

         --Cursor loop started here
         OPEN lcu_customer_address;

         LOOP
            FETCH lcu_customer_address
            BULK COLLECT INTO cm_stage_tbl_type LIMIT ln_batch_limit;

            FOR i IN 1 .. cm_stage_tbl_type.COUNT
            LOOP
               lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                     cm_stage_tbl_type (i).site_use_id
                  || lc_comma
                  || cm_stage_tbl_type (i).org_id
                  || lc_comma
                  || cm_stage_tbl_type (i).cust_account_id
                  || lc_comma
                  || cm_stage_tbl_type (i).address1
                  || lc_comma
                  || cm_stage_tbl_type (i).address2
                  || lc_comma
                  || cm_stage_tbl_type (i).address3
                  || lc_comma
                  || cm_stage_tbl_type (i).address4
                  || lc_comma
                  || cm_stage_tbl_type (i).postal_code
                  || lc_comma
                  || cm_stage_tbl_type (i).city
                  || lc_comma
                  || cm_stage_tbl_type (i).state
                  || lc_comma
                  || cm_stage_tbl_type (i).province
                  || lc_comma
                  || cm_stage_tbl_type (i).country
                  || lc_comma
                  || cm_stage_tbl_type (i).party_site_number
                  || lc_comma
                  || cm_stage_tbl_type (i).primary_flag
                  || lc_comma
                  || cm_stage_tbl_type (i).SEQUENCE
                  || lc_comma
                  || cm_stage_tbl_type (i).orig_system_reference
                  || lc_comma
                  || cm_stage_tbl_type (i).LOCATION
                  || lc_comma
                  || cm_stage_tbl_type (i).collector_number
                  || lc_comma
                  || cm_stage_tbl_type (i).collector_name
                  || lc_comma
                 -- || cm_stage_tbl_type (i).dunning_letters
                 -- || lc_comma
                  || cm_stage_tbl_type (i).send_statements
                  || lc_comma
                  || cm_stage_tbl_type (i).credit_limit_usd
                  || lc_comma
                  || cm_stage_tbl_type (i).credit_limit_cad
                  || lc_comma
                  || cm_stage_tbl_type (i).profile_class_name
                  || lc_comma
                  || cm_stage_tbl_type (i).consolidated_billing
                  || lc_comma
                  || cm_stage_tbl_type (i).cons_billing_formats_type
                  || lc_comma
                  || cm_stage_tbl_type (i).bill_in_the_box
                  || lc_comma
                  || cm_stage_tbl_type (i).billing_currency
                  || lc_comma
                  || cm_stage_tbl_type (i).dunning_delivery
                  || lc_comma
                  || cm_stage_tbl_type (i).statement_delivery
                  || lc_comma
                  || cm_stage_tbl_type (i).taxware_entity_code
                  || lc_comma
                  || cm_stage_tbl_type (i).remit_to_sales_channel
                  || lc_comma
                  || cm_stage_tbl_type (i).edi_location
                  || lc_comma
                  || cm_stage_tbl_type (i).addressee
                  || lc_comma
                  || cm_stage_tbl_type (i).identifying_address
                  || lc_comma
                  || cm_stage_tbl_type (i).acct_site_status
                  || lc_comma
                  || cm_stage_tbl_type (i).site_use_status
                  || lc_comma
                  || cm_stage_tbl_type (i).site_use_code
				  );
				  fnd_file.put_line (fnd_file.output,'Data File lc_message');-- Added
               fnd_file.put_line (fnd_file.output, lc_message); -- Added
               UTL_FILE.put_line (lc_filehandle, lc_message);
               --Incrementing count of records in the file and total records fethed on particular day
               ln_count := ln_count + 1;
               ln_total_count := ln_total_count + 1;

               --updating  cust_addr_ext flag to 'Y' in eligibility table after extracing data for customer
               UPDATE xx_crm_wcelg_cust
                  SET cust_addr_ext = 'Y'
                WHERE cust_account_id = cm_stage_tbl_type (i).cust_account_id AND cust_addr_ext = 'N';

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
            EXIT WHEN lcu_customer_address%NOTFOUND;
         END LOOP;

         CLOSE lcu_customer_address;

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
                     ,ln_request_id_p -- V1.1, Added request_id
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
                                          , lc_source_path || '/' || file_names_tbl_type (i)                                                                                          --Source File Name
                                          , lc_destination_path || '/' || file_names_tbl_type (i)                                                                                       --Dest File Name
                                          ,''
                                          ,''
                                          ,'Y'                                                                                                                                --Deleting the Source File
                                          ,lc_archive_directory                                                                                                                 --Archive directory path
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
         END LOOP;
      --req_id_tbl_type Loop Ended here
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
   --End of extract_stagedata
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
         SELECT XFTV.target_value1
           INTO ln_batch_limit
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'CUST_ADDRESSES'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      gn_count := 0;
      fnd_file.put_line (fnd_file.LOG, '********** Customer Addresses Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, '   Action Type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect batch limit is:' || ln_batch_limit);

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
      ELSIF lc_action_type = 'M'
      THEN
         insert_missingdelta (ln_batch_limit, ln_retcode);

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
         gc_error_debug := SQLCODE || ' NO data found in the Customer Address main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      WHEN OTHERS
      THEN
         gc_error_debug := SQLERRM || ' Others exception is raised in the Customer Address main procedure';
         fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         p_retcode := 2;
   -- End of the main procedure
   END main;
--End of XX_CRM_CUST_ADDR_EXTRACT_PKG Package Body
END xx_crm_cust_addr_extract_pkg;
/

SHOW ERRORS;