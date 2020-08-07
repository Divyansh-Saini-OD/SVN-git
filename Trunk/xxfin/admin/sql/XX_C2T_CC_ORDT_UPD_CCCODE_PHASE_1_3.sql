	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_UPD_CCCODE_PHASE_1_3.sql                     |
	-- | Description : Script to update the Credit Card Code in IBY History Table  |
	-- |               xx_iby_batch_trxns_history                                  |
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
	   -- STEP #1 - Drop task XX_C2T_CC_CODE_HIST                            --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_CC_CODE_HIST - '||SYSDATE);   

	   BEGIN
		  gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
		  DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_CC_CODE_HIST');

		  DBMS_OUTPUT.PUT_LINE('XX_C2T_CC_CODE_HIST was dropped from previous run.');
	   EXCEPTION
		  WHEN OTHERS THEN 
			 gc_error_loc := 'XX_C2T_CC_CODE_HIST did not exist.  Drop was not required.';
			 DBMS_OUTPUT.PUT_LINE(gc_error_loc);
	   END;

	   ------------------------------------------------------------------------
	   -- STEP #2 - Create task XX_C2T_CC_CODE_HIST.                         --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_CC_CODE_HIST. - '||SYSDATE); 

	   gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
	   DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_CC_CODE_HIST');
	   
	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');

	   ------------------------------------------------------------------------
	   -- STEP #3 - Create Chunks for task XX_C2T_CC_CODE_HIST.              --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_CC_CODE_HIST. - '||SYSDATE); 

	   gc_error_loc := 'Set SQL Statement for creating chunks.';

	   gc_chunk_sql := 'SELECT min_order_payment_id
							  ,max_order_payment_id
						  FROM xx_c2t_conv_threads_ordt
						ORDER BY min_order_payment_id';                                                

	   gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 1000 chunks.';
	   DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_CC_CODE_HIST', gc_chunk_sql, FALSE);

	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');

	   ------------------------------------------------------------------------
	   -- STEP #4 - Run Task XX_C2T_CC_CODE_HIST.                            --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_CC_CODE_HIST. - '||SYSDATE); 

	   gc_error_loc := 'Generating SQL Statement.';
										 
       gc_sql_stmt  := 'MERGE /*+ LEADING(STG) USE_NL(HIST) */ 
                         INTO xx_iby_batch_trxns_history HIST
                        USING (SELECT /*+ LEADING(XOR) INDEX(XOR xx_c2t_cc_token_stg_ordt_u1) */
                                      XOR.order_payment_id
                                     ,XOR.credit_card_code
                                     ,XOR.token_flag
                                FROM xx_c2t_cc_token_stg_ordt      XOR
                               WHERE XOR.order_payment_id BETWEEN :start_id AND :end_id ) STG
                                  ON (HIST.order_payment_id = STG.order_payment_id)
                                WHEN MATCHED THEN UPDATE
                                 SET HIST.ixcreditcardcode = STG.credit_card_code 
                                    ,HIST.ixtokenflag = STG.token_flag';

	   gc_error_loc := 'Executing dbms_parallel_execute.run_task using 64 parallel threads';
	   DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_CC_CODE_HIST',
									   sql_stmt => gc_sql_stmt,
								  language_flag => DBMS_SQL.NATIVE,
								 parallel_level => 64);
								 
	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);

	   ------------------------------------------------------------------------
	   -- STEP #5 - Verify Status of Chunks XX_C2T_CC_CODE_HIST              --
	   ------------------------------------------------------------------------
	   gc_error_loc := 'Getting total number of chunks';
	   SELECT COUNT(1)
		 INTO gc_total_chunks_cnt
		 FROM dba_parallel_execute_chunks
		WHERE task_name = 'XX_C2T_CC_CODE_HIST';
		
	   DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    

	   gc_error_loc := 'Getting total number of chunks in ERROR';    
	   SELECT COUNT(1)
		 INTO gc_error_chunks_cnt
		 FROM dba_parallel_execute_chunks
		WHERE task_name = 'XX_C2T_CC_CODE_HIST'
		  AND status = 'PROCESSED_WITH_ERROR';    

	   DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    

	   gc_error_loc := 'Checking total number of chunks in ERROR';  
	   IF gc_error_chunks_cnt > 0 THEN
		  DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
		  DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_CC_CODE_HIST');

		  gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
		  SELECT COUNT(1)
			INTO gc_error_chunks_cnt
			FROM dba_parallel_execute_chunks
		   WHERE task_name = 'XX_C2T_CC_CODE_HIST'
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

	   DBMS_OUTPUT.PUT_LINE('XX_C2T_CC_CODE_HIST has been completed - '||SYSDATE);
								 
	EXCEPTION
	   WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
		  DBMS_OUTPUT.PUT_LINE(SQLERRM);
	END;
/
