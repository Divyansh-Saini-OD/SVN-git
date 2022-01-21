	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_STG_PHASE_3_1.sql                            |
	-- | Description : Script to Update Token Number in table XX_IBY_BATCH_TRXNS_HISTORY|
	-- |                                                                           |
	-- |Change Record:                                                             |
	-- |===============                                                            |
	-- |Version  Date         Author                Remarks                        |
	-- |=======  ===========  ==================    ===============================|
	-- |v1.0     13-OCT-2015  Harvinder Rakhra      Initial version                |  
	-- |v1.1     22-JAN-2016  Harvinder Rakhra      Added 64 threads               |  
	-- +===========================================================================+
		DECLARE
		   gc_sql_stmt          VARCHAR2(32767) := NULL;
		   gc_error_loc         VARCHAR2(2000)  := NULL;   
		   gc_chunk_sql         VARCHAR2(32767) := NULL;      
		   gc_total_chunks_cnt  NUMBER          := 0;
		   gc_error_chunks_cnt  NUMBER          := 0;   
		BEGIN

		   ------------------------------------------------------------------------
		   -- STEP #1 - Drop task XX_C2T_CONVERT_IBY_HIST                            --
		   ------------------------------------------------------------------------
		   DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_CONVERT_IBY_HIST - '||SYSDATE);   

		   BEGIN
			  gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
			  DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_CONVERT_IBY_HIST');

			  DBMS_OUTPUT.PUT_LINE('XX_C2T_CONVERT_IBY_HIST was dropped from previous run.');
		   EXCEPTION
			  WHEN OTHERS THEN 
				 gc_error_loc := 'XX_C2T_CONVERT_IBY_HIST did not exist.  Drop was not required.';
				 DBMS_OUTPUT.PUT_LINE(gc_error_loc);
		   END;

		   ------------------------------------------------------------------------
		   -- STEP #2 - Create task XX_C2T_CONVERT_IBY_HIST.                         --
		   ------------------------------------------------------------------------
		   DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_CONVERT_IBY_HIST. - '||SYSDATE); 

		   gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
		   DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_CONVERT_IBY_HIST');
		   
		   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');

		   ------------------------------------------------------------------------
		   -- STEP #3 - Create Chunks for task XX_C2T_CONVERT_IBY_HIST.              --
		   ------------------------------------------------------------------------
		   DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_CONVERT_IBY_HIST. - '||SYSDATE); 

		   gc_error_loc := 'Set SQL Statement for creating chunks.';

		   gc_chunk_sql := 'SELECT min_hist_id
								  ,max_hist_id
							  FROM xx_c2t_conv_threads_iby_hist
							ORDER BY min_hist_id';                                                

		   gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 1000 chunks.';
		   DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_CONVERT_IBY_HIST', gc_chunk_sql, FALSE);

		   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');

		   ------------------------------------------------------------------------
		   -- STEP #4 - Run Task XX_C2T_CONVERT_IBY_HIST.                            --
		   ------------------------------------------------------------------------
		   DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_CONVERT_IBY_HIST. - '||SYSDATE); 

		   gc_error_loc := 'Generating SQL Statement.';
		   gc_sql_stmt  := 'MERGE /*+ LEADING(STG)*/ 
							 INTO xx_iby_batch_trxns_history IBY_HIST
							USING (SELECT /*+ LEADING(XOR) USE_NL(XOR XCV) INDEX(XCV XX_C2T_CC_TOKEN_CRYPTOVAULT_N1) */
										  XOR.hist_id
										 ,XCV.token_number_new 
										 ,XCV.token_key_label_new
										 ,XOR.order_payment_id
										 ,XOR.ixreceiptnumber
										 ,XOR.ixipaymentbatchnumber
									 FROM xx_c2t_cc_token_stg_iby_hist  XOR
										 ,xx_c2t_cc_token_crypto_vault  XCV
									WHERE XOR.hist_id BETWEEN :start_id AND :end_id
									  AND NVL (XOR.re_encrypt_status, ''-1'')  = ''C''
									  AND NVL (XOR.convert_status , ''-1'')   <> ''C''
									  AND XOR.credit_card_number_new = XCV.credit_card_number_new ) STG
							   ON (IBY_HIST.ixreceiptnumber = STG.ixreceiptnumber
                                  AND IBY_HIST.ixipaymentbatchnumber = STG.ixipaymentbatchnumber)
							 WHEN MATCHED THEN
							 UPDATE 
									SET IBY_HIST.ixaccount          = DECODE (IBY_HIST.ixaccount, NULL, NULL, STG.token_number_new)
									   ,IBY_HIST.ixswipe            = DECODE (IBY_HIST.ixaccount, NULL, STG.token_number_new, IBY_HIST.ixswipe)	
									   ,IBY_HIST.attribute8         = STG.token_key_label_new   
									   ,IBY_HIST.ixtokenflag        = ''Y''';

		   gc_error_loc := 'Executing dbms_parallel_execute.run_task using 64 parallel threads';
		   DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_CONVERT_IBY_HIST',
										   sql_stmt => gc_sql_stmt,
									  language_flag => DBMS_SQL.NATIVE,
									 parallel_level => 64);
									 
		   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);

		   ------------------------------------------------------------------------
		   -- STEP #5 - Verify Status of Chunks XX_C2T_CONVERT_IBY_HIST              --
		   ------------------------------------------------------------------------
		   gc_error_loc := 'Getting total number of chunks';
		   SELECT COUNT(1)
			 INTO gc_total_chunks_cnt
			 FROM dba_parallel_execute_chunks
			WHERE task_name = 'XX_C2T_CONVERT_IBY_HIST';
			
		   DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    

		   gc_error_loc := 'Getting total number of chunks in ERROR';    
		   SELECT COUNT(1)
			 INTO gc_error_chunks_cnt
			 FROM dba_parallel_execute_chunks
			WHERE task_name = 'XX_C2T_CONVERT_IBY_HIST'
			  AND status = 'PROCESSED_WITH_ERROR';    

		   DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    

		   gc_error_loc := 'Checking total number of chunks in ERROR';  
		   IF gc_error_chunks_cnt > 0 THEN
			  DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
			  DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_CONVERT_IBY_HIST');

			  gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
			  SELECT COUNT(1)
				INTO gc_error_chunks_cnt
				FROM dba_parallel_execute_chunks
			   WHERE task_name = 'XX_C2T_CONVERT_IBY_HIST'
				 AND status = 'PROCESSED_WITH_ERROR';    

			  DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR after RETRY: '||gc_error_chunks_cnt);  

			  IF gc_error_chunks_cnt > 0 THEN
				 DBMS_OUTPUT.PUT_LINE('*****************************************************************************');         
				 DBMS_OUTPUT.PUT_LINE('***** RETRY WAS NOT SUCCESSFUL.  PLEASE CONTACT IT_ERP_SYSTEMS (APPDEV) *****');
				 DBMS_OUTPUT.PUT_LINE('***** DO NOT RELEASE THE ENVRIONMENT UNTIL THIS ISSUE IS RESOLVED       *****');
				 DBMS_OUTPUT.PUT_LINE('*****************************************************************************');         
			  END IF;

		   ELSE
			  DBMS_OUTPUT.PUT_LINE('No chunks in error.....reprocessing not required.');           
		   END IF;

		   DBMS_OUTPUT.PUT_LINE('XX_C2T_CONVERT_IBY_HIST has been completed - '||SYSDATE);
									 
		EXCEPTION
		   WHEN OTHERS THEN
			  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
			  DBMS_OUTPUT.PUT_LINE(SQLERRM);
		END;
	/
