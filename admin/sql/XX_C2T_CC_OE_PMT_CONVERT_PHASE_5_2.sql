-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_OE_PMT_CONVERT_PHASE_5_2.sql                   |
-- | Description :    Convert OE Payments Credit cards to Tokens               |
-- | Rice ID     :    C0705                                                    |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-21-2015   Havish Kasina         Initial Version                |
-- | 2.0     10-30-2015   Havish Kasina         Added SET SERVEROUTPUT ON      |
-- | 3.0     13-01-2016   Manikant Kasu         Changed Cryptovault index N1   |
-- +===========================================================================+
SET SERVEROUTPUT ON
DECLARE
	gc_sql_stmt          VARCHAR2(32767) := NULL;
	gc_error_loc         VARCHAR2(2000)  := NULL;   
	gc_chunk_sql         VARCHAR2(32767) := NULL;      
	gc_total_chunks_cnt  NUMBER          := 0;
	gc_error_chunks_cnt  NUMBER          := 0;   
BEGIN
			
		------------------------------------------------------------------------
		-- STEP #1 - Drop task XX_C2T_CONVERT_OE_PMT                          --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #1 - Drop task XX_C2T_CONVERT_OE_PMT - '||SYSDATE);   
			
		BEGIN
			gc_error_loc := 'Executing dbms_parallel_execute.drop_task.';
			DBMS_PARALLEL_EXECUTE.DROP_TASK('XX_C2T_CONVERT_OE_PMT');
			
			DBMS_OUTPUT.PUT_LINE('XX_C2T_CONVERT_OE_PMT was dropped from previous run.');
    EXCEPTION
			WHEN OTHERS 
      THEN 
			   gc_error_loc := 'XX_C2T_CONVERT_OE_PMT did not exist.  Drop was not required.';
			   DBMS_OUTPUT.PUT_LINE(gc_error_loc);
		END;
			
		------------------------------------------------------------------------
    -- STEP #2 - Create task XX_C2T_CONVERT_OE_PMT.                       --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #2 - Create task XX_C2T_CONVERT_OE_PMT. - '||SYSDATE); 
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_task.';
		DBMS_PARALLEL_EXECUTE.CREATE_TASK(TASK_NAME => 'XX_C2T_CONVERT_OE_PMT');
			   
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_task.');
			
		------------------------------------------------------------------------
		-- STEP #3 - Create Chunks for task XX_C2T_CONVERT_OE_PMT.            --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #3 - Create Chunks for task XX_C2T_CONVERT_OE_PMT. - '||SYSDATE); 
			
		gc_error_loc := 'Set SQL Statement for creating chunks.';
			
		gc_chunk_sql := 'SELECT  min_oe_payment_id
                            ,max_oe_payment_id
                       FROM xx_c2t_conv_threads_oe_pmt
                      ORDER BY min_oe_payment_id';                                                
			
		gc_error_loc := 'Executing dbms_parallel_execute.create_chunks_by_sql to create 128 chunks.';
		DBMS_PARALLEL_EXECUTE.CREATE_CHUNKS_BY_SQL('XX_C2T_CONVERT_OE_PMT', gc_chunk_sql, FALSE);
			
		DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.create_chunks_by_sql.');
			
		------------------------------------------------------------------------
		-- STEP #4 - Run Task XX_C2T_CONVERT_OE_PMT.                          --
		------------------------------------------------------------------------
		DBMS_OUTPUT.PUT_LINE('STEP #4 - Run Task XX_C2T_CONVERT_OE_PMT. - '||SYSDATE); 
			
    gc_error_loc := 'Generating SQL Statement.';
		gc_sql_stmt  := 'MERGE /*+ LEADING(STG) */ 
                      INTO oe_payments ORDT
                     USING (SELECT /*+ LEADING(XOR) USE_NL(XOR XCV) INDEX(XCV XX_C2T_CC_TOKEN_CRYPTOVAULT_N1) */
                                   XOR.header_id
								                  ,XOR.line_id
								                  ,XOR.payment_number
                                  ,XCV.token_number_new 
                                  ,XCV.token_key_label_new
                              FROM xx_c2t_cc_token_stg_oe_pmt    XOR
                                  ,xx_c2t_cc_token_crypto_vault  XCV
                             WHERE XOR.oe_payment_id BETWEEN :start_id AND :end_id
                               AND XOR.re_encrypt_status  = ''C''
                               AND XOR.convert_status    <> ''C''
                               AND XOR.credit_card_number_new = XCV.credit_card_number_new ) STG
                        ON (   ORDT.header_id = STG.header_id
                            AND NVL(ORDT.line_id,1) = NVL(STG.line_id,1)
                            AND ORDT.payment_number = STG.payment_number)
                      WHEN MATCHED THEN UPDATE 
                                           SET ORDT.attribute4         = STG.token_number_new
                                              ,ORDT.attribute5         = STG.token_key_label_new
                                              ,ORDT.attribute3         = ''Y''  ';
			
		gc_error_loc := 'Executing dbms_parallel_execute.run_task using 64 parallel threads';
		DBMS_PARALLEL_EXECUTE.RUN_TASK(task_name => 'XX_C2T_CONVERT_OE_PMT',
                                    sql_stmt => gc_sql_stmt,
                               language_flag => DBMS_SQL.NATIVE,
                              parallel_level => 64);
			                             
    DBMS_OUTPUT.PUT_LINE('Completed dbms_parallel_execute.run_task. - '||SYSDATE);
			
    ------------------------------------------------------------------------
    -- STEP #5 - Verify Status of Chunks XX_C2T_CONVERT_OE_PMT            --
    ------------------------------------------------------------------------
		gc_error_loc := 'Getting total number of chunks';
		SELECT COUNT(1)
			INTO gc_total_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_CONVERT_OE_PMT';
			    
    DBMS_OUTPUT.PUT_LINE('Total Chunks         : '||gc_total_chunks_cnt);    
			
    gc_error_loc := 'Getting total number of chunks in ERROR';    
		SELECT COUNT(1)
			INTO gc_error_chunks_cnt
			FROM dba_parallel_execute_chunks
		 WHERE task_name = 'XX_C2T_CONVERT_OE_PMT'
       AND status = 'PROCESSED_WITH_ERROR';    
			
    DBMS_OUTPUT.PUT_LINE('Total Chunks in ERROR: '||gc_error_chunks_cnt);    
			
    gc_error_loc := 'Checking total number of chunks in ERROR';  
		IF gc_error_chunks_cnt > 0 
    THEN
			 DBMS_OUTPUT.PUT_LINE('Attempting to reprocess errors 1 time');       
			 DBMS_PARALLEL_EXECUTE.RESUME_TASK ('XX_C2T_CONVERT_OE_PMT');
			
			 gc_error_loc := 'Getting total number of chunks in ERROR for 2nd time.';    
			 SELECT COUNT(1)
			   INTO gc_error_chunks_cnt
			   FROM dba_parallel_execute_chunks
			  WHERE task_name = 'XX_C2T_CONVERT_OE_PMT'
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
			
		DBMS_OUTPUT.PUT_LINE('XX_C2T_CONVERT_OE_PMT has been completed - '||SYSDATE);
			                             
EXCEPTION
		WHEN OTHERS THEN
			 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '||gc_error_loc);
			 DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
