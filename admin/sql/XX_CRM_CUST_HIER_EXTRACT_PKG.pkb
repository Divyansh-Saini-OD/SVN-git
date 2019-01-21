CREATE OR REPLACE PACKAGE BODY xx_crm_cust_hier_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_HIER_EXTRACT_PKG                           |
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
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author               Remarks               |
--|=======   ======        ====================   =========             |
--|1.0       30-Aug-2011   Balakrishna Bolikonda  Initial Version       |
--|1.1       10-May-2012   Jay Gupta              Defect 18387 - Add    |
--|                                            Request_id in LOG tables |
--|1.2       10-Jan-2013   Dheeraj V              QC 21778, Fixed relationship|
--|                                               end date format           |
--|1.3       11-Nov-2015   Havish Kasina       Removed the Schema References|
--|                                            as per R12.2 Retrofit Changes|
--+=========================================================================+

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
      cm_full_tbl_type   lt_cust_hier;

      --cursor declaration: This is used to fetch the total customer master data from base tables
      CURSOR lcu_fulldata
      IS
         SELECT EC.account_number "account number"
               ,EC.cust_account_id "cust account id"
               ,HCA_PARENT.account_number "parent account number"
               ,HR.start_date "start date"
               ,HR.end_date "end date"
               ,NVL (FU_CRE.description, FU_CRE.user_name) "created by"
               ,HR.creation_date "CREATION DATE"
               ,NVL (FU_UPD.description, FU_UPD.user_name) "last updated by"
               ,HR.last_update_date "last update date"
               ,HR.subject_type "party type"
               ,HR.relationship_type "relationship type"
               ,HR.relationship_code "relation"
               ,HR.direction_code "direction of relation"
               ,HR.object_type "object type"
               ,gn_last_updated_by "last_updated_by"
               ,gd_creation_date "creation_date"
               ,gn_request_id "request_id"
               ,gn_created_by "created_by"
               ,gd_last_update_date "last_update_date"
               ,gn_program_id "program_id"
           FROM xx_crm_wcelg_cust EC
               ,hz_parties HP1
               ,hz_parties HP_PARENT
               ,hz_relationships HR
               ,hz_cust_accounts HCA_PARENT
               ,fnd_user FU_CRE
               ,fnd_user FU_UPD
          WHERE EC.party_id = HP1.party_id
            AND HP1.party_id = HR.object_id
            AND HR.subject_id = HP_PARENT.party_id
            AND HR.direction_code = 'P'
            AND HR.relationship_type IN ('OD_FIN_HIER', 'OD_FIN_PAY_WITHIN')
            AND SYSDATE BETWEEN NVL (HR.START_DATE, SYSDATE - 1) AND NVL (HR.END_DATE, SYSDATE + 1)
            AND HP_PARENT.party_id = HCA_PARENT.party_id
            AND HR.created_by = FU_CRE.user_id
            AND HR.last_updated_by = FU_UPD.user_id
            AND EC.cust_hier_ext = 'N';
   BEGIN
      gc_error_debug := 'Start Extracting full data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Hierarchy';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custhier_stg';

      --lcu_fulldata cursor Loop started here
      ln_batch_limit := p_batch_limit;

      OPEN lcu_fulldata;

      LOOP
         FETCH lcu_fulldata
         BULK COLLECT INTO cm_full_tbl_type LIMIT ln_batch_limit;

         FORALL i IN 1 .. cm_full_tbl_type.COUNT
            INSERT INTO xx_crm_custhier_stg
                 VALUES cm_full_tbl_type (i);
         COMMIT;
         EXIT WHEN lcu_fulldata%NOTFOUND;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||lcu_fulldata%ROWCOUNT;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      --cm_fulldata curosr Loop ended here
      CLOSE lcu_fulldata;

      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTHIER_STG'
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
   --End of insert_fulldata procedure
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
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);
	ln_nextval	    NUMBER DEFAULT 0;

	TYPE num_array IS TABLE OF NUMBER
	INDEX BY BINARY_INTEGER;
	ln_hier_cnt NUMBER := 0;
	l_child_conc	VARCHAR2(50);
	l_degree	NUMBER;

	req_array num_array;
	ln_request_number NUMBER:=0;

      --Table type declaration
      cm_incr_tbl_type   lt_cust_hier;

      --cursor declaration: This is used to fetch the incremental customer master data from base tables
      CURSOR lcu_incremental
      IS
	SELECT ROWNUM record_id, party_id, record_type FROM
	  (
		SELECT party_id, 'C' record_type FROM xx_crm_wcelg_cust WHERE cust_hier_ext = 'N'
		UNION
		SELECT party_id, 'C' FROM xx_crm_common_delta WHERE content_type IN ( 'HZ_PARTIES')
		UNION
		SELECT party_id, 'P' FROM xx_crm_common_delta WHERE content_type IN ( 'HZ_RELATIONSHIPS_HIER','HZ_CUST_ACCOUNTS')
	  );

   BEGIN
      gc_error_debug := 'Start Extracting Incremental data from customer base tables to staging table' || TO_CHAR (SYSDATE, 'DD-MON-YYYY:HH24:MI:SS');
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      gc_error_debug := 'Before truncating Staging table for Customer Hierarchy';
      write_log (gc_debug_flag, gc_error_debug);

      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custhier_stg';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE xxcrm.xx_crm_custhier_accountid_stg';

-- Inserting party_id into staging table start
	FOR accountid_custhier IN lcu_incremental
	LOOP
		    BEGIN
		     INSERT INTO xx_crm_custhier_accountid_stg
		     (
		     RECORD_ID,
		     PARTY_ID,
		     RECORD_TYPE
		     )
		     VALUES
		     (
		      accountid_custhier.record_id,
		      accountid_custhier.party_id,
		      accountid_custhier.record_type
		      );
		     EXCEPTION WHEN OTHERS THEN
		       fnd_file.put_line(fnd_file.log,'Account ID:' || accountid_custhier.party_id || ' Could Not be Inserted' || '::' || SQLERRM);
		     END;
		COMMIT;
	END LOOP;
-- Inserting party_id into staging table end




-- Parallel thread degree and child conc program name start
         SELECT XFTV.target_value14,
		XFTV.target_value16
           INTO l_degree, l_child_conc
           FROM xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
          WHERE XFTV.translate_id = XFTD.translate_id
            AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
            AND XFTV.source_value1 = 'CUST_RELATIONSHIP'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL (XFTV.end_date_active, SYSDATE + 1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL (XFTD.end_date_active, SYSDATE + 1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

-- Parallel thread degree and child conc program name end


-- Parallel thread start

      SELECT NVL(MAX(to_number(record_id)),-1)- NVL(MIN(to_number(record_id)),0)+1, NVL(MIN(to_number(record_id)),0) ,  NVL(MAX(to_number(record_id)),0)
            INTO l_count, min_record, max_record
       FROM xx_crm_custhier_accountid_stg
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


	DELETE FROM XX_CRM_CUSTHIER_STG WHERE ROWID IN
	(
	SELECT b.ROWID FROM
	(SELECT MAX(rowid) rowid_1 FROM XX_CRM_CUSTHIER_STG GROUP BY ACCOUNT_NUMBER,CUST_ACCOUNT_ID,PARENT_ACCOUNT_NUMBER,
                        START_DATE,END_DATE,"CREATED BY","CREATION DATE","LAST UPDATED BY","LAST UPDATE DATE",PARTY_TYPE,RELATIONSHIP_TYPE,RELATION,
			DIRECTIONAL_FLAG,OBJECT ) A,
	XX_CRM_CUSTHIER_STG B
	WHERE a.ROWID_1(+) = b.ROWID AND a.ROWID_1 IS NULL
	);

	COMMIT;

	SELECT COUNT(*) INTO ln_hier_cnt FROM xx_crm_custhier_stg;


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
                     ,ln_hier_cnt
                     ,'SUCCESS'
                     ,'Processed'
                     ,ln_request_id_p -- V1.1, Added request_id
                     );

	COMMIT;

      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Total number of Records inserted into the Staging table are: '||ln_hier_cnt;
      fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      fnd_file.put_line (fnd_file.LOG, '   ');
      gc_error_debug := 'Loop Ended here for fetching data from base tables to staging table';
      write_log (gc_debug_flag, gc_error_debug);


      --Gathering table stats
      compute_stats (gc_compute_stats
                    ,'XXCRM'
                    ,'XX_CRM_CUSTHIER_STG'
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
   --End of insert_incrdata procedure
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
	l_tot_hier_inserted            NUMBER := 0;
        l_batch_id                   NUMBER;

	  CURSOR acct_list_cur
	  IS
	  SELECT party_id, record_type, record_id
	  FROM xx_crm_custhier_accountid_stg
	  WHERE record_id BETWEEN in_low AND in_high;

	CURSOR acct_hier_child (p_party_id   NUMBER)
	IS
	 SELECT DISTINCT EC.account_number account_number
               ,EC.cust_account_id cust_account_id
               ,HCA_PARENT.account_number  parent_account_number
               ,HR.start_date start_date
               ,HR.end_date end_date
               ,NVL (FU_CRE.description, FU_CRE.user_name) created_by
               ,HR.creation_date creation_date
               ,NVL (FU_UPD.description, FU_UPD.user_name) last_updated_by
               ,HR.last_update_date last_update_date
               ,HR.subject_type party_type
               ,HR.relationship_type relationship_type
               ,HR.relationship_code relationship_code
               ,HR.direction_code  directional_flag
               ,HR.object_type object_type
           FROM xx_crm_wcelg_cust EC
               ,hz_parties HP1
               ,hz_parties HP_PARENT
               ,hz_relationships HR
               ,hz_cust_accounts HCA_PARENT
               ,fnd_user FU_CRE
               ,fnd_user FU_UPD
          WHERE EC.party_id = HP1.party_id
            AND HP1.party_id = HR.object_id
            AND HR.subject_id = HP_PARENT.party_id
            AND HR.direction_code = 'P'
            AND HR.relationship_type IN ('OD_FIN_HIER', 'OD_FIN_PAY_WITHIN')
            AND HP_PARENT.party_id = HCA_PARENT.party_id
            AND HR.created_by = FU_CRE.user_id
            AND HR.last_updated_by = FU_UPD.user_id
	    AND HP1.party_id = p_party_id ;

	CURSOR acct_hier_parent (p_party_id   NUMBER)
	IS
	 SELECT DISTINCT EC.account_number account_number
               ,EC.cust_account_id cust_account_id
               ,HCA_PARENT.account_number  parent_account_number
               ,HR.start_date start_date
               ,HR.end_date end_date
               ,NVL (FU_CRE.description, FU_CRE.user_name) created_by
               ,HR.creation_date creation_date
               ,NVL (FU_UPD.description, FU_UPD.user_name) last_updated_by
               ,HR.last_update_date last_update_date
               ,HR.subject_type party_type
               ,HR.relationship_type relationship_type
               ,HR.relationship_code relationship_code
               ,HR.direction_code  directional_flag
               ,HR.object_type object_type
           FROM xx_crm_wcelg_cust EC
               ,hz_parties HP1
               ,hz_parties HP_PARENT
               ,hz_relationships HR
               ,hz_cust_accounts HCA_PARENT
               ,fnd_user FU_CRE
               ,fnd_user FU_UPD
          WHERE EC.party_id = HP1.party_id
            AND HP1.party_id = HR.object_id
            AND HR.subject_id = HP_PARENT.party_id
            AND HR.direction_code = 'P'
            AND HR.relationship_type IN ('OD_FIN_HIER', 'OD_FIN_PAY_WITHIN')
            AND HP_PARENT.party_id = HCA_PARENT.party_id
            AND HR.created_by = FU_CRE.user_id
            AND HR.last_updated_by = FU_UPD.user_id
	    AND hp_parent.party_id = p_party_id ;


BEGIN

      l_total := in_high - in_low + 1;
      l_start_dt := SYSDATE;


	    FOR csids IN acct_list_cur LOOP
	       v_curr_record_id := csids.record_id;
	       v_curr_dt := SYSDATE;



--- PARENT HIER Start

		IF csids.record_type = 'P' THEN
			FOR cs IN acct_hier_parent (csids.party_id) LOOP

			   l_rec_status  := NULL;
			   l_rec_msg     := NULL;



			   BEGIN

				INSERT INTO xx_crm_custhier_stg
				(
				account_number ,cust_account_id ,parent_account_number ,start_date ,end_date
        ,"CREATED BY" ,"CREATION DATE" ,"LAST UPDATED BY" ,"LAST UPDATE DATE"
				,party_type ,relationship_type ,relation ,directional_flag , object
				,last_updated_by ,creation_date ,request_id ,created_by ,last_update_date,program_id
				 ) VALUES
				 (
				 cs.account_number , cs.cust_account_id , cs.parent_account_number , cs.start_date , cs.end_date
				, cs.created_by , cs.creation_date  , cs.last_updated_by , cs.last_update_date
				,cs.party_type , cs.relationship_type , cs.relationship_code , cs.directional_flag , cs.object_type
				, gn_last_updated_by , gd_creation_date ,gn_request_id ,gn_created_by ,gd_last_update_date ,gn_program_id
				);


				     l_tot_hier_inserted := sql%rowcount + l_tot_hier_inserted;

			   EXCEPTION WHEN OTHERS THEN
			     fnd_file.put_line(fnd_file.log,'Error during insert into xx_crm_custhier_stg for Oracle cust_account_id :' || cs.cust_account_id || '::' || SQLERRM);
			   END;
			END LOOP;

		END IF;
--- PARENT HIER End



--- CHILD HIER Start

		IF csids.record_type = 'C' THEN
			FOR cs IN acct_hier_child (csids.party_id) LOOP

			   l_rec_status  := NULL;
			   l_rec_msg     := NULL;



			   BEGIN

				INSERT INTO xx_crm_custhier_stg
				(
				account_number ,cust_account_id ,parent_account_number ,start_date ,end_date
				,"CREATED BY" ,"CREATION DATE" ,"LAST UPDATED BY" ,"LAST UPDATE DATE"
				,party_type ,relationship_type ,relation ,directional_flag ,object
				,last_updated_by ,creation_date ,request_id ,created_by ,last_update_date,program_id
				 ) VALUES
				 (
				 cs.account_number , cs.cust_account_id , cs.parent_account_number , cs.start_date , cs.end_date
				, cs.created_by , cs.creation_date  , cs.last_updated_by , cs.last_update_date
				,cs.party_type , cs.relationship_type , cs.relationship_code , cs.directional_flag , cs.object_type
				, gn_last_updated_by , gd_creation_date ,gn_request_id ,gn_created_by ,gd_last_update_date ,gn_program_id
				);



				     l_tot_hier_inserted := sql%rowcount + l_tot_hier_inserted;

			   EXCEPTION WHEN OTHERS THEN
			     fnd_file.put_line(fnd_file.log,'Error during insert into xx_crm_custhier_stg for Oracle cust_account_id :' || cs.cust_account_id || '::' || SQLERRM);
			   END;
			END LOOP;

		END IF;
--- CHILD HIER End

			COMMIT;

	     END LOOP;

	fnd_file.put_line(fnd_file.log,'Total records '|| l_tot_hier_inserted ||' are inserted into xx_crm_custhier_stg ');

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
      cm_stage_tbl_type      lt_cust_hier;
      req_id_tbl_type        lt_req_id;
      file_names_tbl_type    lt_file_names;
	ln_request_id_p         NUMBER             DEFAULT 0;
	ln_program_name	    VARCHAR2 (100);
	ln_program_short_name VARCHAR2 (60);


      --cursor declaration: This is used to fetech the staging table data
      CURSOR lcu_customer_hierarchy
      IS
         SELECT HIER.account_number
               ,HIER.cust_account_id
               ,HIER.parent_account_number
               ,HIER.start_date
               ,HIER.end_date
               ,HIER."CREATED BY"
               ,HIER."CREATION DATE"
               ,HIER."LAST UPDATED BY"
               ,HIER."LAST UPDATE DATE"
               ,HIER.party_type
               ,HIER.relationship_type
               ,HIER.relation
               ,HIER.directional_flag
               ,HIER.OBJECT
               ,HIER.last_updated_by
               ,HIER.creation_date
               ,HIER.request_id
               ,HIER.created_by
               ,HIER.last_update_date
               ,HIER.program_id
           FROM xx_crm_custhier_stg HIER;
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
            AND XFTV.source_value1 = 'CUST_RELATIONSHIP'
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
      END;


      ln_request_id_p := fnd_global.conc_request_id ();

	SELECT  a.program, a.program_short_name
		INTO ln_program_name, ln_program_short_name
	FROM FND_CONC_REQ_SUMMARY_V A
	WHERE a.request_id = ln_request_id_p;



      fnd_file.put_line (fnd_file.LOG, '********** Customer Hierarchy Stage File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed in:');
      fnd_file.put_line (fnd_file.LOG, '                ');
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || lc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || lc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '                ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '                ');
      fnd_file.put_line (fnd_file.LOG, '   Bulk collect Limit is :' || ln_batch_limit);
      fnd_file.put_line (fnd_file.LOG, '   Size limit is :' || ln_linesize);
      fnd_file.put_line (fnd_file.LOG, '   Source File Path is :' || lc_source_path);
      fnd_file.put_line (fnd_file.LOG, '   Destination File Path is :' || lc_destination_path);
      fnd_file.put_line (fnd_file.LOG, '   Archive File Path is :' || lc_archive_directory);
      fnd_file.put_line (fnd_file.LOG, '   Delimiter is :' || lc_comma);
      fnd_file.put_line (fnd_file.LOG, '   No of records per File :' || ln_no_of_records);

      SELECT COUNT (*)
        INTO ln_rec_count
        FROM xx_crm_custhier_stg;

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
                       ,'XX_CRM_CUSTHIER_STG'
                       );
         --Loop started here
         gc_error_debug := 'Loop started here for fetching data into flat file ';
         write_log (lc_debug_flag, gc_error_debug);

         OPEN lcu_customer_hierarchy;

         LOOP
            FETCH lcu_customer_hierarchy
            BULK COLLECT INTO cm_stage_tbl_type LIMIT ln_batch_limit;
-- QC 21778, mask applied to end-date, so that year 4712 is not interpreted as 2012. 
            FOR i IN 1 .. cm_stage_tbl_type.COUNT
            LOOP
               lc_message := XX_AR_WC_UTILITY_PKG.remove_special_characters(
                     cm_stage_tbl_type (i).account_number
                  || lc_comma
                  || cm_stage_tbl_type (i).cust_account_id
                  || lc_comma
                  || cm_stage_tbl_type (i).parent_account_number
                  || lc_comma
                  || cm_stage_tbl_type (i).start_date
                  || lc_comma
                  || to_char(cm_stage_tbl_type (i).end_date,'DD-MON-YYYY')
                  || lc_comma
                  || cm_stage_tbl_type (i)."created by"
                  || lc_comma
                  || cm_stage_tbl_type (i)."creation date"
                  || lc_comma
                  || cm_stage_tbl_type (i)."last updated by"
                  || lc_comma
                  || cm_stage_tbl_type (i)."last update date"
                  || lc_comma
                  || cm_stage_tbl_type (i).party_type
                  || lc_comma
                  || cm_stage_tbl_type (i).relationship_type
                  || lc_comma
                  || cm_stage_tbl_type (i).relationship_code
                  || lc_comma
                  || cm_stage_tbl_type (i).directional_flag
                  || lc_comma
                  || cm_stage_tbl_type (i).object_type);
               UTL_FILE.put_line (lc_filehandle, lc_message);
               --Incrementing count of records in the file and total records fethed on particular day
               ln_count := ln_count + 1;
               ln_total_count := ln_total_count + 1;

               --updating  cust_addr_ext flag to 'Y' in eligibility table after extracing data for customer
               UPDATE xx_crm_wcelg_cust
                  SET cust_hier_ext = 'Y'
                WHERE cust_account_id = cm_stage_tbl_type (i).cust_account_id AND cust_hier_ext = 'N';

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

            EXIT WHEN lcu_customer_hierarchy%NOTFOUND;
         END LOOP;

         COMMIT;

         CLOSE lcu_customer_hierarchy;

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
   --End of extract_stagedata procedure
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
--|Returns    : NA                                                   |
--|                                                                  |
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
            AND xftv.source_value1 = 'CUST_RELATIONSHIP'
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
      fnd_file.put_line (fnd_file.LOG, '********** Customer Hierarchy Log File **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In');
      fnd_file.put_line (fnd_file.LOG, '                ');
      fnd_file.put_line (fnd_file.LOG, '   Action Type is:' || lc_action_type);
      fnd_file.put_line (fnd_file.LOG, '   Debug Flag is:' || gc_debug_flag);
      fnd_file.put_line (fnd_file.LOG, '   Compute stats is:' || gc_compute_stats);
      fnd_file.put_line (fnd_file.LOG, '          ');
      fnd_file.put_line (fnd_file.LOG, 'Parameters derived from Translation Definition:');
      fnd_file.put_line (fnd_file.LOG, '                ');
      fnd_file.put_line (fnd_file.LOG, '   bulk collect batch limit is:' || ln_batch_limit);

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
--End of XX_CRM_CUST_HIER_EXTRACT_PKG
END xx_crm_cust_hier_extract_pkg;
/

SHOW errors;