SET SERVEROUTPUT ON
DECLARE
-- +=====================================================================================+
-- |                        Office Depot Inc.                                            |
-- +=====================================================================================+
-- | Script Name :  XX_C2T_CC_RETURNS_HISTORY.sql                                        |
-- | Description :  Script to NULL credit cards in History table for Returns             |
-- | Rice Id     :  C0705                                                                |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date         Author             Remarks                                    |
-- |=======   ===========  =================  ===========================================|
-- |1.0       16-Sep-2015  Manikant Kasu      Initial draft version                      |
-- |2.0       29-Oct-2015  Manikant Kasu      Added Schema Name gsi_history to the table |
-- |3.0       30-Oct-2015  Manikant Kasu      Added SET SERVEROUTPUT ON                  |
-- +=====================================================================================+

	gc_sql_stmt          VARCHAR2(32767) := NULL;
	gc_error_loc         VARCHAR2(2000)  := NULL;   
	gc_chunk_sql         VARCHAR2(32767) := NULL;      
	gc_total_chunks_cnt  NUMBER          := 0;
	gc_error_chunks_cnt  NUMBER          := 0;   
BEGIN
			
		------------------------------------------------------------------------
		-- STEP #1 - Drop task XX_C2T_UPDATE_RETURNS_HIST                     --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_UPDATE_RETURNS_HIST - '||SYSDATE);   
			
		BEGIN
			gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
			DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_UPDATE_RETURNS_HIST');
			
			DBMS_OUTPUT.PUT_LINE('XX_C2T_UPDATE_RETURNS_HIST was dropped from previous run.');
    EXCEPTION
			WHEN OTHERS 
      THEN 
			   gc_error_loc := 'XX_C2T_UPDATE_RETURNS_HIST did not exist.Drop was not required.';
			   DBMS_OUTPUT.PUT_LINE(gc_error_loc);
		END;
			
		------------------------------------------------------------------------
    -- STEP #2 - Create task XX_C2T_UPDATE_RETURNS_HIST.                  --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_UPDATE_RETURNS_HIST. - '||SYSDATE); 
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
		DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_UPDATE_RETURNS_HIST');
			   
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');
			
		------------------------------------------------------------------------
		-- STEP #3 - Create Chunks for task XX_C2T_UPDATE_RETURNS_HIST.       --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_UPDATE_RETURNS_HIST. - '||SYSDATE); 
			
		gc_error_loc := 'Set SQL Statement for creating chunks.';
			
		gc_chunk_sql := 'SELECT MIN(X.header_id)    MIN_HEADER_ID
                           ,MAX(X.header_id)    MAX_HEADER_ID
	                     FROM (SELECT /*+ full(XORTA) parallel(XORTA) */ 
				                            XORTA.header_id
				                           ,NTILE(128) OVER(ORDER BY XORTA.header_id) THREAD_NUM
				                       FROM gsi_history.xx_om_return_tenders_all XORTA
				                      WHERE payment_type_code =  ''CREDIT_CARD''
				                        AND credit_card_number IS NOT NULL) X
                      GROUP BY X.thread_num
                      ORDER BY X.thread_num';                                               
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 128 chunks.';
		DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_UPDATE_RETURNS_HIST', gc_chunk_sql, FALSE);
			
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');
			
		------------------------------------------------------------------------
		-- STEP #4 - Run Task XX_C2T_UPDATE_RETURNS_HIST.                     --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_UPDATE_RETURNS_HIST. - '||SYSDATE); 
			
    gc_error_loc := 'Generating SQL Statement.';
		gc_sql_stmt  :=  'UPDATE gsi_history.xx_om_return_tenders_all 
                         SET credit_card_number = NULL
                            ,identifier         = NULL
                       WHERE header_id BETWEEN :start_id AND :end_id
                         AND payment_type_code =  ''CREDIT_CARD''
                         AND credit_card_number IS NOT NULL';
			
		gc_error_loc := 'Executing dbms_parallel_execute.run_task using 64 parallel threads';
		DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_UPDATE_RETURNS_HIST',
                                    sql_stmt => gc_sql_stmt,
                               language_flag => DBMS_SQL.NATIVE,
                              parallel_level => 64);
			                             
    DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);
			
    ------------------------------------------------------------------------
    -- STEP #5 - Verify Status of Chunks XX_C2T_UPDATE_RETURNS_HIST       --
    ------------------------------------------------------------------------
		gc_error_loc := 'Getting total number of chunks';
		SELECT COUNT(1)
			INTO gc_total_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_UPDATE_RETURNS_HIST';
			    
    DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    
			
    gc_error_loc := 'Getting total number of chunks in ERROR';    
		SELECT COUNT(1)
			INTO gc_error_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_UPDATE_RETURNS_HIST'
       AND status = 'PROCESSED_WITH_ERROR';    
			
    DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    
			
    gc_error_loc := 'Checking total number of chunks in ERROR';  
		IF gc_error_chunks_cnt > 0 
    THEN
			 DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
			 DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_UPDATE_RETURNS_HIST');
			
			 gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
			 SELECT COUNT(1)
			   INTO gc_error_chunks_cnt
			   FROM dba_parallel_execute_chunks
			  WHERE task_name = 'XX_C2T_UPDATE_RETURNS_HIST'
			    AND status = 'PROCESSED_WITH_ERROR';    
			
			  DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR after RETRY: '||gc_error_chunks_cnt);  
			
			  IF gc_error_chunks_cnt > 0 
        THEN
			     DBMS_OUTPUT.PUT_LINE('*****************************************************************************');         
			     DBMS_OUTPUT.PUT_LINE('***** RETRY WAS NOT SUCCESSFUL.  PLEASE CONTACT IT_ERP_SYSTEMS (APPDEV) *****');
			     DBMS_OUTPUT.PUT_LINE('***** DO NOT RELEASE THE ENVRIONMENT UNTIL THIS ISSUE IS RESOLVED       *****');
			     DBMS_OUTPUT.PUT_LINE('*****************************************************************************');         
			  END IF;
			
		ELSE
			DBMS_OUTPUT.PUT_LINE('No chunks in error.....reprocessing not required.');           
		END IF;
			
		DBMS_OUTPUT.PUT_LINE('XX_C2T_UPDATE_RETURNS_HIST has been completed - '||SYSDATE);
			                             
EXCEPTION
		WHEN OTHERS THEN
			 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
			 DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/