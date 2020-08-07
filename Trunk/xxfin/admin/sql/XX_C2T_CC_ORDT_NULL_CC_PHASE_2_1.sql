	-- +===========================================================================+
	-- |                  Office Depot - Project Simplify                          |
	-- +===========================================================================+
	-- | Name        : XX_C2T_CC_ORDT_NULL_CC_PHASE_2_1.sql                        |
	-- | Description : Script to NULL the credit card information in ORDT Table    |
	-- |Change Record:                                                             |
	-- |===============                                                            |
	-- |Version  Date         Author                Remarks                        |
	-- |=======  ===========  ==================    ===============================|
	-- |v1.0     13-OCT-2015  Harvinder Rakhra      Initial version                | 
	-- |v2.0     06-DEC-2016  Avinash Baddam        Defect#40315 - Amex Conversio  |
	-- +===========================================================================+
	DECLARE
	   gc_sql_stmt          VARCHAR2(32767) := NULL;
	   gc_error_loc         VARCHAR2(2000)  := NULL;   
	   gc_chunk_sql         VARCHAR2(32767) := NULL;      
	   gc_total_chunks_cnt  NUMBER          := 0;
	   gc_error_chunks_cnt  NUMBER          := 0;   
	BEGIN

	   ------------------------------------------------------------------------
	   -- STEP #1 - Drop task XX_C2T_NULL_CC_ORDT                            --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_NULL_CC_ORDT - '||SYSDATE);   

	   BEGIN
		  gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
		  DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_NULL_CC_ORDT');

		  DBMS_OUTPUT.PUT_LINE('XX_C2T_NULL_CC_ORDT was dropped from previous run.');
	   EXCEPTION
		  WHEN OTHERS THEN 
			 gc_error_loc := 'XX_C2T_NULL_CC_ORDT did not exist.  Drop was not required.';
			 DBMS_OUTPUT.PUT_LINE(gc_error_loc);
	   END;

	   ------------------------------------------------------------------------
	   -- STEP #2 - Create task XX_C2T_NULL_CC_ORDT.                         --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_NULL_CC_ORDT. - '||SYSDATE); 

	   gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
	   DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_NULL_CC_ORDT');
	   
	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');

	   ------------------------------------------------------------------------
	   -- STEP #3 - Create Chunks for task XX_C2T_NULL_CC_ORDT.              --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_NULL_CC_ORDT. - '||SYSDATE); 

	   gc_error_loc := 'Set SQL Statement for creating chunks.';

	   gc_chunk_sql := 'SELECT MIN(X.order_payment_id)    MIN_ORDER_PAYMENT_ID
                              ,MAX(X.order_payment_id)    MAX_ORDER_PAYMENT_ID
                          FROM (SELECT /*+ full(ORDT) parallel(ORDT) */ 
                                        ORDT.order_payment_id
                                       ,NTILE(1000) OVER(ORDER BY ORDT.order_payment_id) THREAD_NUM
                                FROM xx_ar_order_receipt_dtl ORDT
                                WHERE payment_type_code =  ''CREDIT_CARD''
                                  AND NVL(TOKEN_FLAG,''N'')   = ''N''
                                  AND credit_card_number is NOT NULL
                                  AND credit_card_code = ''AMEX''
                                  AND TRUNC(creation_date) < add_months(TRUNC(sysdate),-9)) X
                                GROUP BY X.thread_num
                        ORDER BY X.thread_num';                                                

	   gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 1000 chunks.';
	   DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_NULL_CC_ORDT', gc_chunk_sql, FALSE);

	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');

	   ------------------------------------------------------------------------
	   -- STEP #4 - Run Task XX_C2T_NULL_CC_ORDT.                            --
	   ------------------------------------------------------------------------
	   DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_NULL_CC_ORDT. - '||SYSDATE); 

	   gc_error_loc := 'Generating SQL Statement.';
										 
       gc_sql_stmt := 'UPDATE xx_ar_order_receipt_dtl ORDT
                          SET credit_card_number = NULL
                             ,identifier         = NULL
                        WHERE ORDT.order_payment_id BETWEEN :start_id AND :end_id
                          AND ORDT.payment_type_code =  ''CREDIT_CARD''
                          AND NVL(TOKEN_FLAG,''N'')   = ''N''
                          AND credit_card_number is NOT NULL
                          AND credit_card_code = ''AMEX''
                          AND TRUNC(ORDT.creation_date) < add_months(TRUNC(sysdate),-9)';


	   gc_error_loc := 'Executing dbms_parallel_execute.run_task using 10 parallel threads';
	   DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_NULL_CC_ORDT',
									   sql_stmt => gc_sql_stmt,
								  language_flag => DBMS_SQL.NATIVE,
								 parallel_level => 10);
								 
	   DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);

	   ------------------------------------------------------------------------
	   -- STEP #5 - Verify Status of Chunks XX_C2T_NULL_CC_ORDT              --
	   ------------------------------------------------------------------------
	   gc_error_loc := 'Getting total number of chunks';
	   SELECT COUNT(1)
		 INTO gc_total_chunks_cnt
		 FROM dba_parallel_execute_chunks
		WHERE task_name = 'XX_C2T_NULL_CC_ORDT';
		
	   DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    

	   gc_error_loc := 'Getting total number of chunks in ERROR';    
	   SELECT COUNT(1)
		 INTO gc_error_chunks_cnt
		 FROM dba_parallel_execute_chunks
		WHERE task_name = 'XX_C2T_NULL_CC_ORDT'
		  AND status = 'PROCESSED_WITH_ERROR';    

	   DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    

	   gc_error_loc := 'Checking total number of chunks in ERROR';  
	   IF gc_error_chunks_cnt > 0 THEN
		  DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
		  DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_NULL_CC_ORDT');

		  gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
		  SELECT COUNT(1)
			INTO gc_error_chunks_cnt
			FROM dba_parallel_execute_chunks
		   WHERE task_name = 'XX_C2T_NULL_CC_ORDT'
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

	   DBMS_OUTPUT.PUT_LINE('XX_C2T_NULL_CC_ORDT has been completed - '||SYSDATE);
								 
	EXCEPTION
	   WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
		  DBMS_OUTPUT.PUT_LINE(SQLERRM);
	END;
/
