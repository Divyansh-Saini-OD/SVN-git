create or replace PACKAGE BODY XX_CNV_AR_DIARY_NOTES_PKG AS
    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |                        Providge Consulting                        |
    -- +===================================================================+
    -- |        Name : AR Collector Diary Notes conversion (FIN-1134)      |
    -- | Description : To convert the Customer Diary Notes                 |
    -- |               from MARS to ORACLE AR                              |
    -- |                                                                   |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date          Author              Remarks                |
    -- |=======   ==========   =============        =======================|
    -- |1.0       23-JAN-2007  Terry Banks,         Initial version        |
    -- |                       Providge Consulting                         |
    -- |          21-MAR-2007  Terry Banks          Added CNV_ in name     |
    -- |          17-APR-2007  Terry Banks          Added error message    |
    -- |                                            when child job sub-    |
    -- |                                            mission fails.         |
    -- |          10-JUL-2007  Terry Banks          Correct program        |
    -- |                                            short name used in     |
    -- |                                            child job submisssion. |
    -- |          13-DEC-2007  Terry Banks          Added creation of      |
    -- |                                            all needed indexes.    |
    -- |          12-DEC-2007  Peter Marco          added gather stats to  |
    -- |          12-FEB-2008  Anamitra Banerjee    added line 268 to      |
    -- |                                            validate process_flag  |
    -- +===================================================================+
    -- +===================================================================+
    -- |        Name : CONVERT_NOTES                                       |
    -- | Description : Convert MARS Customer Diary Notes into Oracle       |
    -- |               Collection Notes in the JTF schema                  |
    -- |  Parameters : x_error_buff, x_ret_code,                           |
    -- |               p_cust_start, p_cust_end                            |
    -- +===================================================================+
    PROCEDURE CONVERT_NOTES_MASTER ( x_error_buff OUT VARCHAR2,
				     x_ret_code OUT NUMBER,
				     p_process_name IN VARCHAR2 ) AS
	DUMMY VARCHAR2 ( 22 );
	ln_note_in_count NUMBER;
	item_count NUMBER;
	ln_batch_id_1 NUMBER;
	ln_batch_id_2 NUMBER;
	ln_batch_id_3 NUMBER;
	ln_batch_id_4 NUMBER;
	ln_batch_id_5 NUMBER;
	lc_loop_batch_id NUMBER;
	ln_conc_request_id NUMBER;
	ln_conversion_id NUMBER;
	lc_source_system_code VARCHAR2 ( 50 );
	lc_error_loc VARCHAR2 ( 100 );
	lc_oracle_error_msg VARCHAR2 ( 256 );
	lc_oracle_error_code VARCHAR2 ( 256 );
	lc_error_msg VARCHAR2 ( 256 );
	lc_print_line VARCHAR2 ( 256 );
	lc_index_text VARCHAR2 ( 2000 );
    BEGIN
	lc_error_loc := 'Retrieving Conversion Info ';
	SELECT conversion_id,
	       system_code
	  INTO ln_conversion_id,
	       lc_source_system_code
	  FROM xxcomn.xx_com_conversions_conv
	 WHERE conversion_code = p_process_name;
	lc_error_loc := 'Creating the indexes';
	--  Get the various indexes set up right
	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTE_CONTEXTS_STG_U1  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE UNIQUE ' || ' INDEX XXCNV.XX_JTF_NOTE_CONTEXTS_STG_U1  ' || ' ON XXCNV.XX_JTF_NOTE_CONTEXTS_STG (NOTE_CONTEXT_ID) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTE_CONTEXTS_STG_N1  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE   ' || ' INDEX XXCNV.XX_JTF_NOTE_CONTEXTS_STG_N1  ' || ' ON XXCNV.XX_JTF_NOTE_CONTEXTS_STG (JTF_NOTE_ID) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTES_B_STG_U1  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE UNIQUE ' || ' INDEX XXCNV.XX_JTF_NOTES_B_STG_U1  ' || ' ON XXCNV.XX_JTF_NOTES_B_STG (JTF_NOTE_ID) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTES_B_STG_N1  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE ' || ' INDEX XXCNV.XX_JTF_NOTES_B_STG_N1  ' || ' ON XXCNV.XX_JTF_NOTES_B_STG (CONTROL_ID) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTES_B_STG_N2  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE ' || ' INDEX XXCNV.XX_JTF_NOTES_B_STG_N2  ' || ' ON XXCNV.XX_JTF_NOTES_B_STG (BATCH_ID, PROCESS_FLAG) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_JTF_NOTES_TL_STG_U1  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    lc_index_text := 'CREATE UNIQUE ' || ' INDEX XXCNV.XX_JTF_NOTES_TL_STG_U1  ' || ' ON XXCNV.XX_JTF_NOTES_TL_STG (JTF_NOTE_ID, LANGUAGE) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    lc_index_text := 'DROP INDEX XXCNV.XX_AR_HZ_CUST_ACCOUNTS_N440305  ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	--  It didn't exist which is OK
	END;

	BEGIN
	    --   Create index on customer accounts for legacy lookup
	    lc_index_text := 'CREATE INDEX XXCNV.XX_AR_HZ_CUST_ACCOUNTS_N440305 ' || 'ON ar.HZ_cust_accounts ' || '(SUBSTR(orig_system_reference,1,8)) ';
	    EXECUTE IMMEDIATE ( lc_index_text );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	-- 12-DEC-2007 Added gather stats for tables and indexes below.
	BEGIN
	    DBMS_STATS.GATHER_TABLE_STATS ( ownname => 'XXCNV',
					    tabname => 'XX_JTF_NOTE_CONTEXTS_STG',
					    estimate_percent => 100 );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    DBMS_STATS.GATHER_TABLE_STATS ( ownname => 'XXCNV',
					    tabname => 'XX_JTF_NOTES_B_STG',
					    estimate_percent => 100 );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    DBMS_STATS.GATHER_TABLE_STATS ( ownname => 'XXCNV',
					    tabname => 'XX_JTF_NOTES_TL_STG',
					    estimate_percent => 100 );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	BEGIN
	    DBMS_STATS.GATHER_INDEX_STATS ( ownname => 'XXCNV',
					    indname => 'XX_AR_HZ_CUST_ACCOUNTS_N440305',
					    estimate_percent => 100 );
	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	lc_error_loc := 'Retrieving Batch IDs ';
	SELECT jtf.jtf_notes_s.nextval
	  INTO ln_batch_id_1
	  FROM SYS.DUAL;
	SELECT jtf.jtf_notes_s.nextval
	  INTO ln_batch_id_2
	  FROM SYS.DUAL;
	SELECT jtf.jtf_notes_s.nextval
	  INTO ln_batch_id_3
	  FROM SYS.DUAL;
	SELECT jtf.jtf_notes_s.nextval
	  INTO ln_batch_id_4
	  FROM SYS.DUAL;
	SELECT jtf.jtf_notes_s.nextval
	  INTO ln_batch_id_5
	  FROM SYS.DUAL;
	lc_error_loc := 'Updating xx_jtf_notes_b_stg ';
	UPDATE xxcnv.xx_jtf_notes_b_stg
	   SET batch_id =
	DECODE ( substr ( jtf_note_id,
			  length ( jtf_note_id ),
			  1 ),
		 1,
		 ln_batch_id_1,
		 2,
		 ln_batch_id_1,
		 3,
		 ln_batch_id_2,
		 4,
		 ln_batch_id_2,
		 5,
		 ln_batch_id_3,
		 6,
		 ln_batch_id_3,
		 7,
		 ln_batch_id_4,
		 8,
		 ln_batch_id_4,
		 9,
		 ln_batch_id_5,
		 0,
		 ln_batch_id_5,
		 ln_batch_id_1 ),
	       process_flag = '1'
	 WHERE nvl(process_flag, 0) != 7;
	-- Anamitra Banerjee
	--  ,control_id = jtf_note_id
	COMMIT;
	lc_loop_batch_id := to_char ( ln_batch_id_1 );
	lc_error_loc := 'Submitting Concurrent Jobs ';
LOOP
	    ln_conc_request_id := fnd_request.submit_request ( 'xxfin',
							       'XX_CNV_AR_DIARY_NOTES_PKG_CHLD',
							       '',
							       '',
							       FALSE,
							       'C0159',
							       'N',
							       lc_loop_batch_id );
	    IF ln_conc_request_id = 0 THEN
		fnd_file.put_line ( fnd_file.LOG,
				    '*******************************************' );
		fnd_file.put_line ( fnd_file.LOG,
				    '*                                         *' );
		fnd_file.put_line ( fnd_file.LOG,
				    '*  Submitting Concurrent Processes Failed *' );
		fnd_file.put_line ( fnd_file.LOG,
				    '*                                         *' );
		fnd_file.put_line ( fnd_file.LOG,
				    '*******************************************' );
		x_ret_code := - 1;
	    END IF;

	    COMMIT;
	    SELECT count ( * )
	      INTO ln_note_in_count
	      FROM xxcnv.xx_jtf_notes_b_stg
	     WHERE 1 = 1
	       AND batch_id = lc_loop_batch_id
	       AND process_flag = 1;
	    XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc ( ln_conversion_id,
							     lc_loop_batch_id,
							     ln_note_in_count );
	    IF lc_loop_batch_id = to_char ( ln_batch_id_1 ) THEN
		lc_loop_batch_id := to_char ( ln_batch_id_2 );
	    ELSIF lc_loop_batch_id = to_char ( ln_batch_id_2 ) THEN
		lc_loop_batch_id := to_char ( ln_batch_id_3 );
	    ELSIF lc_loop_batch_id = to_char ( ln_batch_id_3 ) THEN
		lc_loop_batch_id := to_char ( ln_batch_id_4 );
	    ELSIF lc_loop_batch_id = to_char ( ln_batch_id_4 ) THEN
		lc_loop_batch_id := to_char ( ln_batch_id_5 );
	    ELSIF lc_loop_batch_id = to_char ( ln_batch_id_5 ) THEN
		EXIT;
	    END IF;

	END LOOP;

	EXCEPTION
	    WHEN OTHERS THEN
		lc_oracle_error_msg := SQLERrM;
		lc_oracle_error_code := sqlcode;
		lc_error_msg := ': Oracle Error: ' || lc_oracle_error_code || ': ' || lc_oracle_error_msg;
		lc_print_line := 'Untrapped Program Error in' || lc_error_loc || lc_error_msg;
		fnd_file.put_line ( fnd_file.LOG,
				    lc_print_line );
    END convert_notes_master;

    PROCEDURE CONVERT_NOTES_CHILD ( x_error_buff OUT VARCHAR2,
				    x_ret_code OUT NUMBER,
				    p_process_name IN VARCHAR2,
				    p_validate_only_flag IN VARCHAR2,
				    p_batch_id IN VARCHAR2 ) AS
	lc_error_loc VARCHAR2 ( 2000 );
	lc_error_msg VARCHAR2 ( 2000 );
	lc_error_debug VARCHAR2 ( 2000 );
	lc_oracle_error_code VARCHAR2 ( 256 );
	lc_oracle_error_msg VARCHAR2 ( 256 );
	lc_source_system_code xxcomn.xx_com_conversions_conv.system_code%TYPE;
	lc_source_system_ref VARCHAR2 ( 256 );
	lc_staging_column_name VARCHAR2 ( 256 );
	lc_staging_column_value VARCHAR2 ( 256 );
	lc_staging_table_name VARCHAR2 ( 256 );
	ln_commit_count NUMBER := 0;
	ln_conc_request_id fnd_concurrent_requests.request_id%TYPE;
	ln_control_id NUMBER;
	ln_conversion_id xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
	ln_cust_account_id NUMBER;
	ln_jtf_note_id NUMBER;
	ln_note_fail_count NUMBER := 0;
	ln_note_id_seq NUMBER;
	ln_note_in_count NUMBER := 0;
	ln_note_pass_count NUMBER := 0;
	ln_note_vfail_count NUMBER := 0;
	ln_number NUMBER;
	ln_par_conc_request_id NUMBER;
	lc_print_line VARCHAR2 ( 200 );
	lc_process_flag VARCHAR2 ( 1 );
	lb_req_set_ret BOOLEAN;
	ln_req_submit NUMBER;
	lc_index_text VARCHAR2 ( 2000 );
	ln_jobs_running NUMBER;
	--
	-- Cursor to select the base notes table
	CURSOR c_diary_note_b IS ( SELECT B.*               --  ,B.rowid
				     FROM XXCNV.XX_JTF_NOTES_B_STG B
				    WHERE 1 = 1             --     and    nvl(B.upgrade_status_flag,'N')
							    --                           <> 'Y'
				      AND B.batch_id = p_batch_id
				      AND B.process_flag = 1 );
	--Cursor to select the translated notes and note contexts table data
	CURSOR c_diary_note_tlc IS ( SELECT C.note_context_type_id,
					    C.control_id cid,
					    T.control_id tid,
					    T.notes,
					    T.creation_date
				       FROM xxcnv.XX_JTF_NOTES_TL_STG T,
					    XXCNV.XX_JTF_NOTE_CONTEXTS_STG C
				      WHERE T.jtf_note_id = ln_jtf_note_id
				        AND C.jtf_note_id = ln_jtf_note_id );
	PROCEDURE lp_print_line ( pv_print_line IN VARCHAR2,
				  pv_out_file IN VARCHAR2 ) IS
	    lp_conc_job NUMBER;
	BEGIN
	    lp_conc_job := fnd_global.conc_request_id ( );
	    IF lp_conc_job > 0 THEN
		IF pv_out_file = 'both' THEN
		    fnd_file.put_line ( fnd_file.LOG,
					pv_print_line );
		    fnd_file.put_line ( fnd_file.output,
					pv_print_line );
		ELSE
		    fnd_file.put_line ( fnd_file.LOG,
					pv_print_line );
		END IF;

	    ELSE
		dbms_output.put_line ( pv_print_line );
	    END IF;

	END;

	PROCEDURE lp_update_process_flag ( pv_pf_value IN NUMBER ) IS
	BEGIN
	    UPDATE XXCNV.XX_JTF_NOTES_B_STG B
	       SET B.process_flag = pv_pf_value,
		   B.conv_action = 'UPDATE'
	     WHERE B.jtf_note_id = ln_jtf_note_id;
	END;

	PROCEDURE lp_sub_excp_rept IS
	BEGIN
	    ln_number := fnd_request.submit_request ( 'xxcomn',
						      'XXCOMCONVEXPREP',
						      '',
						      '',
						      FALSE,
						      'C0159',
						      ln_par_conc_request_id,
						      ln_conc_request_id,
						      p_batch_id );
	    COMMIT;
	END;

	PROCEDURE lp_sub_summary_rept IS
	BEGIN
	    ln_number := fnd_request.submit_request ( 'xxcomn',
						      'XXCOMCONVSUMMREP',
						      '',
						      '',
						      FALSE,
						      'C0159',
						      ln_par_conc_request_id,
						      ln_conc_request_id,
						      p_batch_id );
	    COMMIT;
	END;

	PROCEDURE lp_log_errors IS
	BEGIN
	    APPS.XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc ( ln_conversion_id,
								ln_control_id,
								lc_source_system_code,
								'XX_AR_DIARY_NOTES_CNV_PKG',
								'CONVERT_NOTES',
								lc_staging_table_name,
								lc_staging_column_name,
								lc_staging_column_value,
								lc_source_system_ref,
								p_batch_id,
								lc_print_line,
								lc_oracle_error_code,
								lc_oracle_error_msg );
	END;

    BEGIN
	ln_conc_request_id := fnd_global.conc_request_id ( );
	--Print the Output file headers
	lc_print_line := 'Customer Diary Notes Load';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '------ Parameters -------';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := 'Process Name: ' || p_process_name;
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := 'Batch ID: ' || p_batch_id;
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := 'Validate Only Flag: ' || p_validate_only_flag;
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '**********************************************';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := ' ';
	lp_print_line ( lc_print_line,
			'both' );
	lc_error_loc := 'NOTES_B Loop ';
	--Get the Conversion_id, Source_System_Code from the Conversion Code(p_process_name)
	lc_error_loc := 'Get the Conversion id, Source System Code';
	lc_error_debug := 'Process Name: ' || p_process_name;
	SELECT conversion_id,
	       system_code
	  INTO ln_conversion_id,
	       lc_source_system_code
	  FROM xxcomn.xx_com_conversions_conv
	 WHERE conversion_code = p_process_name;
	--Get the Request id of the Conversion Master Program
	lc_error_loc := 'Get the Master Request id';
	lc_error_debug := 'Batch id: ' || p_batch_id || ' Conversion id: ' || ln_conversion_id;
	SELECT master_request_id
	  INTO ln_par_conc_request_id
	  FROM xxcomn.xx_com_control_info_conv
	 WHERE batch_id = p_batch_id
	   AND conversion_id = ln_conversion_id;
	ln_note_in_count := 0;
	<<notes_b>>
	lc_error_loc := 'NOTES_B Loop ';
	FOR nb IN c_diary_note_b LOOP
	    ln_note_in_count := 1 + ln_note_in_count;
	    ln_commit_count := 1 + ln_commit_count;
	    ln_jtf_note_id := nb.jtf_note_id;
	    ln_control_id := nb.control_id;
	    lp_update_process_flag ( 2 );
	    lc_error_loc := 'NOTES_TL-C Loop ';
	    <<notes_tlc>>
	    FOR ntc IN c_diary_note_tlc LOOP
		lc_error_loc := 'NOTES_TL-C Loop ';
		<<Lookup_Customer>>
		BEGIN
		    SELECT HCA.cust_account_id
		      INTO ln_cust_account_id
		      FROM AR.HZ_CUST_ACCOUNTS HCA
		     WHERE substr ( HCA.orig_system_reference,
				    1,
				    8 ) = to_char ( NTC.note_context_type_id );
		    EXCEPTION
			WHEN OTHERS THEN
			    lc_oracle_error_msg := SQLERRM;
			    lc_oracle_error_code := sqlcode;
			    ln_control_id := NTC.cid;
			    lc_error_msg := ': Failure on customer account' || ' lookup for ' || NTC.note_context_type_id;
			    lc_print_line := 'Program Data Error in ' || lc_error_loc || lc_error_msg;
			    --lp_print_line (lc_print_line, 'both') ;
			    lp_print_line ( lc_print_line,
					    'log' );
			    -- Set process flag to failed validation
			    lp_update_process_flag ( 3 );
			    --                              ln_note_fail_count  := 1 + ln_note_fail_count ;
			    ln_note_vfail_count := 1 + ln_note_vfail_count;
			    -- Log error
			    lc_staging_table_name := 'XX_JTF_NOTE_CONTEXTS_STG';
			    lc_staging_column_name := 'note_context_type_id';
			    lc_staging_column_value := 'NTC.note_context_type_id';
			    lp_log_errors;
			    -- Call the local procedure
			    EXIT NOTES_TLC;
		END Lookup_Customer;

		-- Set process flag to successful validation
		lp_update_process_flag ( 4 );
		IF p_validate_only_flag = 'Y' THEN
		    -- Set process flag to validated only
		    lp_update_process_flag ( 5 );
		ELSE
		    <<Insert_Notes_Rows>>
		    lc_error_loc := 'Insert Notes_Rows ';
		    BEGIN
			SELECT JTF_NOTES_S.nextval
			  INTO ln_note_id_seq
			  FROM SYS.DUAL;
			lc_staging_table_name := 'JTF.JTF_NOTES_B';
			INSERT INTO jtf_notes_b ( jtf_note_id,
						  parent_note_id,
						  source_object_id,
						  source_object_code,
						  note_status,
						  creation_date,
						  created_by,
						  entered_date,
						  entered_by,
						  last_update_date,
						  last_updated_by,
						  last_update_login,
						  note_type,
						  orig_system_reference )
			VALUES ( ln_note_id_seq,            -- jtf_note_id
				 NULL,                      -- parent_note_id
				 ln_cust_account_id,        -- source_object_id
				 'IEX_ACCOUNT',             -- source_object_code
				 'I',                       -- note_status
				 NTC.creation_date,         -- creation_date
				 1,                         -- created_by
				 NTC.creation_date,         -- entered_date
				 1,                         -- entered_by
				 SYSDATE,                   -- last_update_date
				 1,                         -- last_updated_by
				 1,                         -- last_updated_by
				 NULL,                      -- note_type
				 NB.source_system_ref       -- original_system_reference
			       );
			lc_staging_table_name := 'JTF.JTF_NOTES_TL';
			INSERT INTO jtf_notes_tl ( jtf_note_id,
						   notes,
						   notes_detail,
						   language,
						   source_lang,
						   creation_date,
						   created_by,
						   last_update_login,
						   last_update_date,
						   last_updated_by )
			VALUES ( ln_note_id_seq,            -- jtf_note_id
				 NTC.notes,                 -- notes
				 NULL,                      -- notes_detail
				 'US',                      -- language
				 'US',                      -- source_lang
				 NTC.creation_date,         -- creation_date
				 1,                         -- created_by
				 1,                         -- last_update_login
				 SYSDATE,                   -- last_update_date
				 1                          -- last_updated_by
			       );
			lc_staging_table_name := 'JTF.JTF_NOTE_CONTEXTS';
			INSERT INTO jtf_note_contexts ( note_context_id,
							jtf_note_id,
							note_context_type,
							note_context_type_id,
							creation_date,
							created_by,
							last_update_login,
							last_update_date,
							last_updated_by )
			VALUES ( jtf_notes_s.nextval,       -- note_context_id
				 ln_note_id_seq,            -- jtf_note_id
				 'IEX_ACCOUNT',             -- note_context_type
				 ln_cust_account_id,        -- note_context_type_id
				 NTC.creation_date,         -- creation_date
				 1,                         -- created_by
				 1,                         -- last_update_login
				 SYSDATE,                   -- last_update_date
				 1                          -- last_updated_by
			       );
			lc_staging_table_name := '';
			EXCEPTION
			    WHEN OTHERS THEN
				lc_oracle_error_msg := SQLERrM;
				lc_oracle_error_code := sqlcode;
				lc_staging_column_name := NULL;
				lc_staging_column_value := NULL;
				lc_error_msg := ': Failure while inserting ' || 'notes for ' || NTC.note_context_type_id;
				lc_print_line := 'Program Data Error in' || lc_error_loc || lc_error_msg;
				--lp_print_line (lc_print_line, 'both') ;
				lp_print_line ( lc_print_line,
						'log' );
				-- Set process flag to failed load process
				lp_update_process_flag ( 6 );
				lp_log_errors;
				-- Call the local procedure
				ln_note_fail_count := 1 + ln_note_fail_count;
		    END Insert_Notes_Rows;

		END IF;

		-- Set process flag to successful load process
		lp_update_process_flag ( 7 );
		ln_note_pass_count := 1 + ln_note_pass_count;
		IF ln_commit_count > 999 THEN
		    COMMIT;
		    ln_commit_count := 0;
		END IF;

	    END LOOP notes_tlc;

	END LOOP notes_b;

	lc_print_line := '**********************************************';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '*               Process Summary               ';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '*                                             ';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '* Customer Diary Notes read: ' || lpad ( to_char ( ln_note_in_count ),
								   16,
								   ' ' );
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '* Customer Diary Notes in error: ' || lpad ( to_char ( ln_note_fail_count + ln_note_vfail_count ),
								       12,
								       ' ' );
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '* Customer Diary Notes loaded: ' || lpad ( to_char ( ln_note_pass_count ),
								     14,
								     ' ' );
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '*  ';
	lp_print_line ( lc_print_line,
			'both' );
	lc_print_line := '***********************************************';
	lp_print_line ( lc_print_line,
			'both' );
	COMMIT;
	xx_com_conv_elements_pkg.upd_control_info_proc ( ln_par_conc_request_id,
							 p_batch_id,
							 ln_conversion_id,
							 ln_note_vfail_count,
							 ln_note_fail_count,
							 ln_note_pass_count );
	COMMIT;
	IF fnd_global.conc_request_id ( ) > 0 THEN
	    IF ( ln_note_vfail_count + ln_note_fail_count ) > 0 THEN
		--      if  ln_note_fail_count > 0
		lb_req_set_ret := fnd_concurrent.set_completion_status ( 'WARNING',
									 '' );
		lp_sub_excp_rept;
	    -- Submit Error Report if had any errors
	    END IF;

	    lp_sub_summary_rept;
	-- Submit Summary Report
	END IF;

	BEGIN
	    --  Now drop the index on HZ_CUST_ACCOUNT when no
	    --  other instances of this job are running.
	    SELECT count ( * )
	      INTO ln_jobs_running
	      FROM fnd_concurrent_requests a,
		   fnd_concurrent_programs_tl B
	     WHERE a.CONCURRENT_PROGRAM_id = b.concurrent_program_id
	       AND a.phase_code <> 'C'
	       AND B.USER_CONCURRENT_PROGRAM_NAME LIKE 'OD%Diary%Chil%';
	    IF ln_jobs_running > 1 THEN
		NULL;
	    ELSE
		lc_index_text := 'DROP INDEX XXCNV.XX_AR_HZ_CUST_ACCOUNTS_N440305  ';
		EXECUTE IMMEDIATE ( lc_index_text );
	    END IF;

	    EXCEPTION
		WHEN OTHERS THEN
		    NULL;
	END;

	EXCEPTION
	    WHEN OTHERS THEN
		lc_oracle_error_msg := SQLERrM;
		lc_oracle_error_code := sqlcode;
		lc_error_msg := ': Oracle Error: ' || lc_oracle_error_code || ': ' || lc_oracle_error_msg;
		lc_print_line := 'Untrapped Program Error in' || lc_error_loc || lc_error_msg;
		--lp_print_line (lc_print_line, 'both') ;
		lp_print_line ( lc_print_line,
				'log' );
		lp_log_errors;
		-- Call the local procedure
		IF fnd_global.conc_request_id ( ) > 0 THEN
		    lb_req_set_ret := fnd_concurrent.set_completion_status ( 'ERROR',
									     '' );
		    lp_sub_excp_rept;
		    -- Submit Error Report
		    lp_sub_summary_rept;
		-- Submit Summary Report
		END IF;

    --
    END;

-- CONV_NOTES;
END;
