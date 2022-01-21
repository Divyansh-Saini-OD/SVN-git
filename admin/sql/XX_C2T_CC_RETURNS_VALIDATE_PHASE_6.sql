SET SERVEROUTPUT ON
DECLARE
-- +===========================================================================+
-- |                            Office Depot Inc.                              |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_RETURNS_VALIDATE_PHASE_6.sql                   |
-- | Description :    Returns - Validate Status of Conversion to Tokens        |
-- | Rice Id     :    C0705                                                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-27-2015   Manikant Kasu         Initial Version                |
-- | 2.0     10-30-2015   Manikant Kasu         Added SET SERVEROUTPUT ON      |
-- +===========================================================================+

	gc_sql_stmt          VARCHAR2(32767) := NULL;
	gc_error_loc         VARCHAR2(2000)  := NULL;   
	gc_chunk_sql         VARCHAR2(32767) := NULL;      
	gc_total_chunks_cnt  NUMBER          := 0;
	gc_error_chunks_cnt  NUMBER          := 0;   
BEGIN
			
		------------------------------------------------------------------------
		-- STEP #1 - Drop task XX_C2T_VALIDATE_RETURNS                        --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_VALIDATE_RETURNS - '||SYSDATE);   
			
		BEGIN
			gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
			DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_VALIDATE_RETURNS');
			
			DBMS_OUTPUT.PUT_LINE('XX_C2T_VALIDATE_RETURNS was dropped from previous run.');
    EXCEPTION
			WHEN OTHERS 
      THEN 
			   gc_error_loc := 'XX_C2T_VALIDATE_RETURNS did not exist.  Drop was not required.';
			   DBMS_OUTPUT.PUT_LINE(gc_error_loc);
		END;
			
		------------------------------------------------------------------------
    -- STEP #2 - Create task XX_C2T_VALIDATE_RETURNS.                     --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_VALIDATE_RETURNS. - '||SYSDATE); 
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
		DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_VALIDATE_RETURNS');
			   
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');
			
		------------------------------------------------------------------------
		-- STEP #3 - Create Chunks for task XX_C2T_VALIDATE_RETURNS.          --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_VALIDATE_RETURNS. - '||SYSDATE); 
			
		gc_error_loc := 'Set SQL Statement for creating chunks.';
			
		gc_chunk_sql := 'SELECT  min_return_id
                            ,max_return_id
                       FROM xx_c2t_conv_threads_returns
                      ORDER BY min_return_id';                                                
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 128 chunks.';
		DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_VALIDATE_RETURNS', gc_chunk_sql, FALSE);
			
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');
			
		------------------------------------------------------------------------
		-- STEP #4 - Run Task XX_C2T_VALIDATE_RETURNS.                           --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_VALIDATE_RETURNS. - '||SYSDATE); 
			
    gc_error_loc := 'Generating SQL Statement.';
		gc_sql_stmt  := 'UPDATE /*+ INDEX(STG XX_C2T_CC_TOKEN_RETURNS_U1) */ xx_c2t_cc_token_stg_returns STG
                        SET convert_status = ''C''
                      WHERE STG.return_id BETWEEN :start_id AND :end_id
                        and EXISTS (SELECT /*+ INDEX(XORT XX_OM_RETURN_TENDERS_U1) */ 
                                           1 
                                      FROM xx_om_return_tenders_all XORT
                                     WHERE STG.orig_sys_document_ref = XORT.orig_sys_document_ref
                                       AND STG.payment_number = XORT.payment_number
                                       AND XORT.token_flag = ''Y'' )';
			
		gc_error_loc := 'Executing dbms_parallel_execute.run_task using 64 parallel threads';
		DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_VALIDATE_RETURNS',
                                    sql_stmt => gc_sql_stmt,
                               language_flag => DBMS_SQL.NATIVE,
                              parallel_level => 64);
			                             
    DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);
			
    ------------------------------------------------------------------------
    -- STEP #5 - Verify Status of Chunks XX_C2T_VALIDATE_RETURNS          --
    ------------------------------------------------------------------------
		gc_error_loc := 'Getting total number of chunks';
		SELECT COUNT(1)
			INTO gc_total_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_VALIDATE_RETURNS';
			    
    DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    
			
    gc_error_loc := 'Getting total number of chunks in ERROR';    
		SELECT COUNT(1)
			INTO gc_error_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_VALIDATE_RETURNS'
       AND status = 'PROCESSED_WITH_ERROR';    
			
    DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    
			
    gc_error_loc := 'Checking total number of chunks in ERROR';  
		IF gc_error_chunks_cnt > 0 
    THEN
			 DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
			 DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_VALIDATE_RETURNS');
			
			 gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
			 SELECT COUNT(1)
			   INTO gc_error_chunks_cnt
			   FROM dba_parallel_execute_chunks
			  WHERE task_name = 'XX_C2T_VALIDATE_RETURNS'
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
			
		DBMS_OUTPUT.PUT_LINE('XX_C2T_VALIDATE_RETURNS has been completed - '||SYSDATE);
			                             
EXCEPTION
		WHEN OTHERS THEN
			 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
			 DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/