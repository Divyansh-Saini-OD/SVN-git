create or replace PACKAGE BODY XX_PO_RCV_ADJ_INT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_PO_RCV_ADJ_INT_PKG                                                        |
  -- |  RICE ID   :  I2194_WMS_Receipts_to_EBS_Interface                          |
  -- |  Description:  Load PO Receipt adjustments Data from file to Staging Tables,               |
  -- |                Staging to Interface and import to EBS                                      |
  -- |                                                                          |
  -- |                          |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         04/24/2017   Avinash Baddam   Initial version                                  |
  -- | 2.0         01/24/2019   BIAS             INSTANCE_NAME is replaced with DB_NAME for OCI   |
  -- |                                           Migration Project                                |
  -- | 3.0         12/19/2018   Venkateshwar Panduga      Receipt Adjustment Issue                |
  -- | 4.0         01/19/2020   Venkateshwar Panduga      Submiting RTI program for -ve qty and   |
  -- |                                                   removing duplicate condition for CONS rec|
  -- | 5.0         02/26/2020   Venkateshwar Panduga     JIRA#NAIT-124619Added AP adj date,       |
  -- |                                                    AP adj qty and Ap adj cost to report out|  
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name  : Log Exception                                                              |
  -- |  Description: The log_exception procedure logs all exceptions        |
  -- =============================================================================================|
	gc_debug 		VARCHAR2(2);
	gn_request_id 	fnd_concurrent_requests.request_id%TYPE;
	gn_user_id 		fnd_concurrent_requests.requested_by%TYPE;
	gn_login_id     NUMBER;
	gn_current_year NUMBER;
	PROCEDURE log_exception(
		p_program_name   IN VARCHAR2 ,
		p_error_location IN VARCHAR2 ,
		p_error_msg      IN VARCHAR2)
	IS
		ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
		ln_user_id NUMBER := FND_GLOBAL.USER_ID;
	BEGIN
		XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'PO' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
	EXCEPTION
	WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
	END log_exception;
	/*********************************************************************
	* Procedure used to log based on gb_debug value or if p_force is TRUE.
	* Will log to dbms_output if request id is not set,
	* else will log to concurrent program log file.  Will prepend
	* timestamp to each message logged.  This is useful for determining
	* elapse times.
	*********************************************************************/
	PROCEDURE print_debug_msg(
								p_message IN VARCHAR2,
								p_force   IN BOOLEAN DEFAULT FALSE)
	IS
		lc_message VARCHAR2 (4000) := NULL;
	BEGIN
		IF (gc_debug  = 'Y' OR p_force) THEN
			lc_Message := P_Message;
			fnd_file.put_line (fnd_file.log, lc_Message);
			IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
				dbms_output.put_line (lc_message);
			END IF;
		END IF;
	EXCEPTION
	WHEN OTHERS THEN
		NULL;
	END print_debug_msg;
	-- +============================================================================================+
	-- |  Name  : send_output_email                                                                 |
	-- |  Description: Sends the CP Request output in email                       |
	-- =============================================================================================|
	PROCEDURE send_output_email(
								l_request_id NUMBER,
								l_ret_code   NUMBER)
	AS
		l_email_addr    VARCHAR2(4000);
		ln_request_id   NUMBER;
		l_instance_name VARCHAR2(30);
	BEGIN
		print_debug_msg ('Begin - Sending email',TRUE);
		SELECT sys_context('userenv','DB_NAME')
		INTO l_instance_name
		FROM dual;
		BEGIN
			SELECT target_value2
			  ||','
			  ||target_value3
			INTO l_email_addr
			FROM xx_fin_translatedefinition xtd ,
			  xx_fin_translatevalues xtv
			WHERE xtd.translation_name = 'XX_AP_TRADE_INV_EMAIL'
			AND xtd.translate_id       = xtv.translate_id
			AND xtv.source_value1      = 'RECEIPTS';
		EXCEPTION
		WHEN OTHERS THEN
			l_email_addr :=NULL;
			print_debug_msg ('Email Translation XX_AP_TRADE_INV_EMAIL not setup correctly for source_value1 PURCHASEORDER.'||SUBSTR(SQLERRM, 1, 500),TRUE);
		END;
		ln_request_id := fnd_request.submit_request ('XXFIN' , 'XXODROEMAILER' , NULL , TO_CHAR (SYSDATE + 1 / (24 * 60) , 'YYYY/MM/DD HH24:MI:SS' )
		-- schedule 60 seconds from now
													,FALSE , NULL , l_email_addr , l_instance_name||':'||
													  TO_CHAR(sysdate,'DD-MON-YY')||
													  ':PO Receipt Adjustment Interface Output' , 'Please review the attached program output for details and action items...' , 'Y' -- attachment
													, l_request_id );
		COMMIT;
		print_debug_msg ('End - Sent email for the output of the request_id '||ln_request_id,TRUE);
	EXCEPTION
	WHEN OTHERS THEN
		print_debug_msg ('Error in send_output_email: '||SUBSTR(SQLERRM, 1, 500),TRUE);
	END send_output_email;
	-- +============================================================================================+
	-- |  Name   : update_staging_record_status                                                 |
	-- |  Description: This procedure updates record_status in staging per po interface status.     |
	-- =============================================================================================|
	PROCEDURE update_staging_record_status(
											p_batch_id NUMBER)
	AS
		ln_count        NUMBER;
		ln_current_year NUMBER;
	BEGIN
		print_debug_msg ('Update record_status in staging incase of error in RCV TRANSACTION Interface',FALSE);
		SELECT SUBSTR(EXTRACT(YEAR FROM sysdate), 4,4)
		INTO ln_current_year
		FROM dual;
		UPDATE xx_po_rcv_adj_int_stg stg
		SET stg.record_status = 'IE'
		WHERE EXISTS
			(SELECT 1
			FROM  po_interface_errors 		 poe,
				  rcv_transactions_interface rti,
				  rcv_shipment_headers 		 rsh,
				  rcv_shipment_lines 		 rsl,
				  po_lines_all 				 pla
			WHERE 1                   =1
			AND poe.interface_line_id =rti.interface_transaction_id
			AND rti.shipment_header_id=rsh.shipment_header_id
			AND rsh.shipment_header_id=rsl.shipment_header_id
			AND pla.po_line_id        =rsl.po_line_id
			AND pla.po_header_id      =rsl.po_header_id
			AND stg.ap_po_lineno      =pla.line_num
			AND rsh.receipt_num       =stg.ap_receipt_num
			AND rti.group_id          =stg.batch_id
			AND poe.table_name        ='RCV_TRANSACTIONS_INTERFACE'
			)
		AND stg.batch_id      = p_batch_id
		AND stg.record_status ='I'
		AND stg.attribute5    ='NON-CONSG' ;
		ln_count             := SQL%ROWCOUNT;
		print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status IE',FALSE);
	END update_staging_record_status;
	/*********************************************************************
	* Procedure used to out the text to the concurrent program.
	* Will log to dbms_output if request id is not set,
	* else will log to concurrent program output file.
	*********************************************************************/
	PROCEDURE print_out_msg(
							p_message IN VARCHAR2)
	IS
		lc_message VARCHAR2 (4000) := NULL;
	BEGIN
		lc_message := p_message;
		fnd_file.put_line (fnd_file.output, lc_message);
		IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
			dbms_output.put_line (lc_message);
		END IF;
	EXCEPTION
	WHEN OTHERS THEN
		NULL;
	END print_out_msg;
	-- +============================================================================================+
	-- |  Name  : insert_line                                                                |
	-- |  Description: Procedure to insert line data into staging table                             |
	-- =============================================================================================|
	PROCEDURE insert_line(
						p_table   	IN 	xx_po_pom_int_pkg.varchar2_table,
						p_nfields 	IN 	INTEGER,
						p_error_msg OUT VARCHAR2,
						p_retcode 	OUT VARCHAR2)
	IS
		l_table xx_po_pom_int_pkg.varchar2_table;
	BEGIN
		l_table := p_table;
		INSERT
		INTO xx_po_rcv_adj_int_stg
			(
			record_id ,
			ap_location ,
			ap_keyrec ,
			ap_po_number ,
			ap_po_lineno ,
			ap_receipt_num ,
			ap_adj_date ,
			ap_adj_time ,
			ap_adj_qty ,
			ap_adj_cost ,
			ap_sku ,
			ap_sku_desc ,
			ap_vendor_prodcd ,
			ap_seq_no ,
			source_system_ref ,
			batch_id ,
			record_status ,
			error_description ,
			request_id ,
			created_by ,
			creation_date ,
			last_updated_by ,
			last_update_date ,
			last_update_login ,
			attribute2,
			attribute3
			)
			VALUES
			(
			xx_po_rcv_adj_int_stg_s.nextval ,
			l_table(2) --ap_location
			,
			l_table(3) --ap_keyrec
			,
			ltrim(l_table(11),'0')
			||'-'
			||lpad(ltrim(l_table(2),'0'),4,'0') --ap_po_number + ap_location
			,
			l_table(4) ,
			NULL ,      -- l_table(2)||l_table(3)||l_table(10)||gn_current_year -- ap_location + ap_keyrec + ap_seq_no + lastDigit of Sysdate
			l_table(12) --adjustmentdate
			,
			l_table(13) --adjustmenttime
			,
			l_table(6) --ap_adjustment qty
			,
			l_table(5) --ap_adj_cost
			,
			l_table(7) --ap_sku
			,
			l_table(8) --ap_sku_desc
			,
			l_table(9) --ap_vendor_prodcd
			,
			l_table(10) --ap_seq_no
			,
			l_table(11) --source_system_ref
			,
			'' --batch_id
			,
			'' --record_status
			,
			'' --error_description
			,
			gn_request_id ,
			gn_user_id ,
			sysdate ,
			gn_user_id ,
			sysdate ,
			gn_login_id ,
			'NEW',
			l_table(12) 								--Original Adj Date
			);
	EXCEPTION
	WHEN OTHERS THEN
		p_retcode   := '2';
		p_error_msg := 'Error in XX_PO_RCV_ADJ_INT_PKG.insert_line '||SUBSTR(sqlerrm,1,150);
	END insert_line;
	-- +============================================================================================+
	-- |  Name  : load_staging                                                             |
	-- |  Description: This procedure reads data from the file and inserts into staging tables      |
	-- |               XXPORCV_ADJ_STG - XX PO RCV Adjustments Staging                              |
	-- =============================================================================================|
	PROCEDURE load_staging
						(
						p_errbuf OUT VARCHAR2 ,
						p_retcode OUT VARCHAR2 ,
						p_filepath  VARCHAR2 ,
						p_file_name VARCHAR2 ,
						p_debug     VARCHAR2
						)
	AS
		l_filehandle 				 	UTL_FILE.FILE_TYPE;
		lc_filedir    					VARCHAR2(200) := p_filepath;
		lc_filename   					VARCHAR2(200) := p_file_name;
		lc_dirpath  					VARCHAR2(500);
		lb_file_exist 					BOOLEAN;
		ln_size       					NUMBER;
		ln_block_size 					NUMBER;
		lc_newline    					VARCHAR2(4000); -- Input line
		ln_max_linesize 				BINARY_INTEGER := 32767;
		ln_rec_cnt 						NUMBER         := 0;
		l_table 						xx_po_pom_int_pkg.varchar2_table;
		l_nfields                    	INTEGER;
		lc_error_msg                 	VARCHAR2(2000) := NULL;
		lc_error_loc                 	VARCHAR2(2000) := 'XX_PO_RCV_ADJ_INT_PKG.LOAD_STAGING';
		lc_retcode                   	VARCHAR2(3)    := NULL;
		lc_rec_type                  	VARCHAR2(1)    := NULL;
		ln_count_tot                 	NUMBER         := 0;
		ln_conc_file_copy_request_id 	NUMBER;
		lc_dest_file_name            	VARCHAR2(200);
		lc_curr_key                  	VARCHAR2(30)   := NULL;
		lc_prev_key                  	VARCHAR2(30)   := NULL;
		nofile                       	EXCEPTION;
		data_exception               	EXCEPTION;
		lc_instance_name			   	VARCHAR2(30);
		lb_complete        		   		BOOLEAN;
		lc_phase           		   		VARCHAR2(100);
		lc_status          		   		VARCHAR2(100);
		lc_dev_phase       		   		VARCHAR2(100);
		lc_dev_status      		   		VARCHAR2(100);
		lc_message         		   		VARCHAR2(100);
	CURSOR get_dir_path
	IS
		SELECT directory_path
		FROM all_directories
		WHERE directory_name = p_filepath;
	BEGIN
		gc_debug      := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),1,8)
		INTO lc_instance_name
		FROM dual;
		print_debug_msg ('Start load_staging from File:'||p_file_name||' Path:'||p_filepath,TRUE);
		SELECT SUBSTR(EXTRACT(YEAR FROM sysdate), 4,4)
		INTO gn_current_year
		FROM dual;
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF NOT lb_file_exist THEN
			RAISE nofile;
		END IF;
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);
		print_debug_msg ('File open successfull',TRUE);
		LOOP
			BEGIN
				UTL_FILE.GET_LINE(l_filehandle,lc_newline);
				IF lc_newline IS NULL THEN
					EXIT;
				END IF;
				print_debug_msg ('Processing Line:'||lc_newline,FALSE);
				--parse the line
				xx_po_pom_int_pkg.parse(lc_newline,l_table,l_nfields,'|',lc_error_msg,lc_retcode);
				IF lc_retcode = '2' THEN
					RAISE data_exception;
				END IF;
				print_debug_msg ('Parsing Complete',FALSE);
				FOR i IN 1..l_table.count
				LOOP
					print_debug_msg (l_table(i),FALSE);
				END LOOP;
				insert_line(l_table,l_nfields,lc_error_msg,lc_retcode);
				IF lc_retcode = '2' THEN
					RAISE data_exception;
				END IF;
				ln_count_tot := ln_count_tot + 1;
			EXCEPTION
			WHEN no_data_found THEN
				EXIT;
			END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
		COMMIT;
		print_debug_msg(TO_CHAR(ln_count_tot)||' records successfully loaded into staging',TRUE);
		print_out_msg('OD: PO RCV Adjustments Staging Program');
		print_out_msg('================================================ ');
		print_out_msg('Total No. of records processed :'||TO_CHAR(ln_count_tot));
		dbms_lock.sleep(5);
		print_debug_msg('Calling the Common File Copy to move the Inbound file to AP Invoice folder',TRUE);
		OPEN get_dir_path;
		FETCH get_dir_path INTO lc_dirpath;
		CLOSE get_dir_path;
		lc_dest_file_name := '/app/ebs/ebsfinance/'	||lc_instance_name||'/apinvoice/'
													||SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
													||TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
		ln_conc_file_copy_request_id := fnd_request.submit_request(	'XXFIN',
																	'XXCOMFILCOPY',
																	'',
																	'',
																	FALSE,
																	lc_dirpath||'/'||lc_filename, --Source File Name
																	lc_dest_file_name,            --Dest File Name
																	'', '', 'N'                   --Deleting the Source File
																	);
		IF ln_conc_file_copy_request_id > 0
		THEN
		COMMIT;
			print_debug_msg('While Waiting Import Standard Purchase Order Request to Finish');
			-- wait for request to finish
			lb_complete :=fnd_concurrent.wait_for_request 	(
															request_id   => ln_conc_file_copy_request_id,
															interval     => 10,
															max_wait     => 0,
															phase        => lc_phase,
															status       => lc_status,
															dev_phase    => lc_dev_phase,
															dev_status   => lc_dev_status,
															message      => lc_message
															);
			print_debug_msg('Status :'||lc_status);
			print_debug_msg('dev_phase :'||lc_dev_phase);
			print_debug_msg('dev_status :'||lc_dev_status);
			print_debug_msg('message :'||lc_message);
		END IF;
		print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);
		lc_dest_file_name            := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4) || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN', 'XXCOMFILCOPY', '', '', FALSE, lc_dirpath||'/'||lc_filename, --Source File Name
		lc_dest_file_name,                                                                                                               --Dest File Name
		'', '', 'Y'                                                                                                                      --Deleting the Source File
		);
		COMMIT;
	EXCEPTION
	WHEN nofile THEN
		print_debug_msg ('ERROR - File not exists',TRUE);
		p_retcode := 2;
	WHEN data_exception THEN
		ROLLBACK;
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg('Error at line:'||lc_newline,TRUE);
		p_errbuf  := lc_error_msg;
		p_retcode := lc_retcode;
	WHEN UTL_FILE.INVALID_OPERATION THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Invalid Operation',TRUE);
		p_retcode:=2;
	WHEN UTL_FILE.INVALID_FILEHANDLE THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Invalid File Handle',TRUE);
		p_retcode := 2;
	WHEN UTL_FILE.READ_ERROR THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Read Error',TRUE);
		p_retcode := 2;
	WHEN UTL_FILE.INVALID_PATH THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Invalid Path',TRUE);
		p_retcode := 2;
	WHEN UTL_FILE.INVALID_MODE THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Invalid Mode',TRUE);
		p_retcode := 2;
	WHEN UTL_FILE.INTERNAL_ERROR THEN
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - Internal Error',TRUE);
		p_retcode := 2;
	WHEN OTHERS THEN
		ROLLBACK;
		UTL_FILE.FCLOSE(l_filehandle);
		print_debug_msg ('ERROR - '||SUBSTR(sqlerrm,1,250),TRUE);
		p_retcode := 2;
	END load_staging;
	-- +============================================================================================+
	-- |  Name   : print_master_program_stats                                                   |
	-- |  Description: This procedure print stats of master program                                 |
	-- =============================================================================================|
	PROCEDURE report_master_program_stats
	AS
		CURSOR c_staging_requests
		IS
			SELECT 	DISTINCT request_id,
					TO_CHAR(creation_date, 'DD-MON-YY')
			FROM xx_po_rcv_adj_int_stg
			WHERE attribute2 = 'NEW';
		CURSOR req_adj_count_cur(c_request_id NUMBER)
		IS
			SELECT 	COUNT(1) COUNT ,
					record_status
			FROM xx_po_rcv_adj_int_stg stg
			WHERE stg.request_id = c_request_id
			GROUP BY stg.record_status;
		CURSOR req_trans_count_cur(c_request_id NUMBER)
		IS
			SELECT 	stg.attribute1 vendor_site_category,
					stg.attribute5,
					stg.record_status,
					COUNT(1) COUNT
			FROM xx_po_rcv_adj_int_stg stg
			WHERE stg.request_id = c_request_id
			GROUP BY  stg.attribute1,
					  stg.attribute5,
					  stg.record_status;
		CURSOR trans_count_cur
		IS
			SELECT 	stg.attribute1 vendor_site_category,
					stg.record_status,
					COUNT(1) COUNT
			FROM xx_po_rcv_adj_int_stg stg
			WHERE EXISTS
				  (SELECT 'x'
				  FROM fnd_concurrent_requests req
				  WHERE req.parent_request_id  = gn_request_id
				  AND to_number(req.argument1) = stg.batch_id
				  )
			GROUP BY stg.attribute1,
					 stg.record_status;
		TYPE stats
		IS
			TABLE OF req_trans_count_cur%ROWTYPE INDEX BY PLS_INTEGER;
			stats_tab STATS;
		indx NUMBER;
		CURSOR trans_detail_cur
		IS
			SELECT 	 stg.ap_po_number
					,stg.ap_location
					,stg.ap_keyrec
					,stg.ap_receipt_num
					,stg.attribute1 vendor_site_category
					,stg.ap_po_lineno
					,stg.ap_sku
					,stg.AP_ADJ_DATE     ---Added for V 5.0
					,stg.AP_ADJ_QTY      ---Added for V 5.0
					,stg.AP_ADJ_COST     ---Added for V 5.0
					,stg.error_description
					,stg.creation_date
			FROM xx_po_rcv_adj_int_stg stg
			WHERE EXISTS
				  (SELECT 'x'
				  FROM fnd_concurrent_requests req
				  WHERE req.parent_request_id  = gn_request_id
				  AND to_number(req.argument1) = stg.batch_id
				  )
			AND stg.record_status = 'E'
			ORDER BY stg.creation_date 	DESC
					,stg.ap_po_number 	ASC
					,stg.ap_location 	ASC
					,stg.ap_keyrec 		ASC
					,ap_po_lineno 		ASC;
		TYPE trans_detail
		IS
		TABLE OF trans_detail_cur%ROWTYPE INDEX BY PLS_INTEGER;
		trans_detail_tab trans_detail;
		t_indx NUMBER;
		CURSOR rtv_cur
		IS
			SELECT 	 rti.group_id
					,rhi.receipt_num
					,poi.interface_type
					,rti.document_num
					,rti.attribute1 sku
					,NVL(poi.error_message_name,'NULL')
					,NVL(poi.error_message,'NULL') error_description
			FROM 	 po_interface_errors poi
					,rcv_transactions_interface rti
					,rcv_headers_interface rhi
			WHERE poi.interface_line_id = rti.interface_transaction_id
			AND rhi.header_interface_id = rti.header_interface_id
			AND destination_type_code   ='RECEIVING'
			AND EXISTS
					(SELECT 'x'
					 FROM fnd_concurrent_requests req
					 WHERE req.parent_request_id  = gn_request_id
					 AND to_number(req.argument1) = rti.group_id
					)
			ORDER BY rti.document_num
					,rti.attribute1;
		TYPE rtv
		IS
			TABLE OF rtv_cur%ROWTYPE INDEX BY PLS_INTEGER;
			rtv_tab rtv;
			r_indx NUMBER;
		TYPE l_num_tab
		IS
			TABLE OF NUMBER;
			l_stage_requests l_num_tab;
		TYPE l_var_tab
		IS
			TABLE OF VARCHAR2(10);
		l_stage_reqs_date 	   l_var_tab;
		ln_new_req_cnt         NUMBER;
	    ln_tot_rcv_adj_cnt     NUMBER;
	    ln_success_cnt         NUMBER;
	    ln_error_cnt           NUMBER;
	    ln_interface_err_cnt   NUMBER;
	    ln_skip_cnt            NUMBER;
		ln_skip_total_cnt      NUMBER;
	    ln_skip_int_cnt        NUMBER;
	    ln_consg_skip_int_cnt  NUMBER;
	    ln_other_err_cnt       NUMBER;
	    ln_consg_success_cnt   NUMBER;
	    ln_consg_error_cnt     NUMBER;
	    ln_consg_skip_cnt      NUMBER;
	    ln_consg_other_err_cnt NUMBER;
	    ln_tot_rcv_cnt         NUMBER;
	    ln_tot_new_cnt         NUMBER;
	    ln_tot_consg_cnt       NUMBER;
	    ln_tot_skip_adj_zero   NUMBER;
	    ln_tot_skip_int_vndr   NUMBER;
		BEGIN
			print_debug_msg ('Report Master Program Stats',FALSE);
			print_out_msg('OD PO RECEIPT Adjustments Interface');
			print_out_msg('==============================');
			-- Get the list of request_id's of staging program to use it in report_master_program_stats()
			OPEN c_staging_requests;
			FETCH c_staging_requests BULK COLLECT
			INTO l_stage_requests,
				 l_stage_reqs_date;
			CLOSE c_staging_requests;
			ln_new_req_cnt   := l_stage_requests.count;
			IF ln_new_req_cnt = 0 THEN
				print_out_msg('No PO Receipt Adjustment Data, from POM, is loaded recently.');
			END IF;
			FOR i IN 1.. ln_new_req_cnt
			LOOP
				print_debug_msg ('Report for request_id '||l_stage_requests(i),TRUE);
				-- Generally, only one new load request exists. For Exception cases, we will display the request_id to differentiate
				IF ln_new_req_cnt > 1 THEN
					print_out_msg ('');
					print_out_msg ('OD PO Receipt Adjustments Summary Report for the oracle load request '||l_stage_requests(i)||' loaded on '||l_stage_reqs_date(i));
				END IF;
				ln_tot_rcv_adj_cnt     := 0;
				ln_success_cnt         := 0;
				ln_error_cnt           := 0;
				ln_interface_err_cnt   := 0;
				ln_skip_cnt            := 0;
				ln_other_err_cnt       := 0;
				ln_consg_success_cnt   := 0;
				ln_consg_error_cnt     := 0;
				ln_consg_skip_cnt      := 0;
				ln_consg_other_err_cnt := 0;
				ln_consg_skip_int_cnt  := 0;
				ln_tot_new_cnt         := 0;
				ln_tot_consg_cnt       := 0;
				ln_skip_int_cnt		   := 0;
				ln_tot_skip_adj_zero   := 0;
				ln_tot_skip_int_vndr   := 0;
				ln_skip_total_cnt	   := 0;
				OPEN req_trans_count_cur(l_stage_requests(i));
				FETCH req_trans_count_cur BULK COLLECT INTO stats_tab;
				CLOSE req_trans_count_cur;
				FOR indx IN 1..stats_tab.COUNT
				LOOP
					IF stats_tab(indx).vendor_site_category 	= 'NON-CONSG' THEN
						IF stats_tab(indx).attribute5       	= 'Skip Processing - Adjustment Quantity is 0' THEN
							ln_skip_cnt                := ln_skip_cnt	+ stats_tab(indx).count;
						ELSIF stats_tab(indx).attribute5 		= 'Internal Vendor - skip Adjustment processing' THEN
							ln_skip_int_cnt            := ln_skip_int_cnt	+ stats_tab(indx).count;
						END IF;
						ln_tot_new_cnt                 := ln_tot_new_cnt + stats_tab(indx).count;
						IF stats_tab(indx).record_status    	= 'I' THEN
							ln_success_cnt             := ln_success_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status 	= 'E' THEN
							ln_error_cnt               := ln_error_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status 	= 'IE' THEN
							ln_interface_err_cnt       := ln_interface_err_cnt + stats_tab(indx).count;
						ELSE
							-- Generally, below other status count doesn't come. In case, if it comes, it shows and developers can fix it.
							ln_other_err_cnt 		   := ln_other_err_cnt + stats_tab(indx).count;
							print_debug_msg ('report_master_program_stats()- record exists for other status : '||stats_tab(indx).record_status,TRUE);
						END IF;
					ELSE
						IF stats_tab(indx).attribute5 		  	= 'Skip Processing - Adjustment Quantity is 0' THEN
							ln_consg_skip_cnt          	:= ln_consg_skip_cnt +	stats_tab(indx).count;
						ELSIF stats_tab(indx).attribute5 		= 'Internal Vendor - skip Adjustment processing' THEN
							ln_consg_skip_int_cnt      	:= ln_consg_skip_int_cnt + stats_tab(indx).count;
						END IF;
						ln_tot_consg_cnt             	:= ln_tot_consg_cnt + stats_tab(indx).count;
						IF stats_tab(indx).record_status      	= 'I' THEN
							ln_consg_success_cnt        := ln_consg_success_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status 	= 'E' THEN
							ln_consg_error_cnt          := ln_consg_error_cnt + stats_tab(indx).count;
						ELSE
						-- Generally, below other status count doesn't come. In case, if it comes, it shows and developers can fix it.
						ln_consg_other_err_cnt 			:= ln_consg_other_err_cnt + stats_tab(indx).count;
						print_debug_msg ('report_master_program_stats()- record exists for other status : '||stats_tab(indx).record_status,TRUE);
						END IF;
					END IF;
				END LOOP;
				ln_tot_rcv_adj_cnt 	 := ln_tot_new_cnt + ln_tot_consg_cnt;
				ln_tot_skip_adj_zero := ln_consg_skip_cnt + ln_skip_cnt;
				ln_tot_skip_int_vndr := ln_consg_skip_int_cnt	+ ln_skip_int_cnt;
				ln_skip_total_cnt    := ln_tot_skip_int_vndr	+ ln_tot_skip_adj_zero;
				ln_tot_rcv_adj_cnt	 := ln_tot_rcv_adj_cnt		+ ln_skip_total_cnt;
				print_out_msg('');
				print_out_msg(RPAD('Total PO Receipt Adjustments (receipt and consignment) are',55)||' '||RPAD(NVL(ln_tot_rcv_adj_cnt,0),10));
				print_out_msg('');
				print_out_msg(RPAD('Total No of Receipts Skipped are ',35)||' '||RPAD(NVL(ln_skip_total_cnt,0),10));
				print_out_msg(RPAD('     Total No of Receipts Skipped (Internal Vendor) are',70)||' '||RPAD(NVL(ln_tot_skip_int_vndr,0),10));
				print_out_msg(RPAD('     Total No of Receipts Skipped (Adjustment Quantity is 0) are',70)||' '||RPAD(NVL(ln_tot_skip_adj_zero,0),10));
				print_out_msg('');
				print_out_msg(RPAD('Total New PO Adjustment Transactions', 35)||' '||RPAD(NVL(ln_tot_new_cnt,0),10));
				print_out_msg(RPAD('     PO Receipt Adjustment Transactions - Created Successfully', 70)||' '||RPAD(NVL(ln_success_cnt,0),10));
				print_out_msg(RPAD('     PO Receipt Adjustment Transactions - Errors(Custom Validations)', 70)||' '||RPAD(NVL(ln_error_cnt,0),10));
				print_out_msg(RPAD('     PO Receipt Adjustment Transactions - Errors(Standard Validations)', 70)||' '||RPAD(NVL(ln_interface_err_cnt,0),10));
				IF ln_other_err_cnt <> 0 THEN
					print_out_msg(RPAD('     PO Adjustment Transactions - Other Status count', 70)||' '||RPAD(ln_other_err_cnt,10));
				END IF;
				print_out_msg('');
				print_out_msg(RPAD('Total Consignment Transactions', 35)||' '||RPAD(NVL(ln_tot_consg_cnt,0),10));
				print_out_msg(RPAD('     Consignment Transactions - Interfaced', 70)||' '||RPAD(NVL(ln_consg_success_cnt,0),10));
				print_out_msg(RPAD('     Consignment Transactions - Errors(Custom Validations)', 70)||' '||RPAD(NVL(ln_consg_error_cnt,0),10));
				IF ln_consg_other_err_cnt <> 0 THEN
					print_out_msg(RPAD('     Consignment Transactions - Other Status count', 70)||' '||RPAD(ln_consg_other_err_cnt,10));
				END IF;
			END LOOP;
			print_out_msg(' ');
			print_out_msg(' ');
			print_out_msg('OD PO Receipt Adjustment Interface Exception Details');
			print_out_msg('====================================================');
			print_out_msg(RPAD('Created On',10)||' '||RPAD('Supplier Type',13)||' '||RPAD('PO Number',15)||' '||RPAD('Key Rec',10)||' '||RPAD('Receipt Num',15)||' '||RPAD('AP Adjustment Date',19)||' '||RPAD('AP Adjustment Quantity',23)||' '||RPAD('AP Adjustment Cost',19)||' '||RPAD('Line',4,' ')||' '||RPAD('Sku',15,' ')||' '||RPAD('Error Details',150));
			print_out_msg(RPAD('=',10,'=')||' '||RPAD('=',13,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',19,'=')||' '||RPAD('=',23,'=')||' '||RPAD('=',19,'=')||' '||RPAD('=',4,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',150,'='));
			OPEN trans_detail_cur;
			FETCH trans_detail_cur BULK COLLECT INTO trans_detail_tab;
			CLOSE trans_detail_cur;
			FOR t_indx IN 1..trans_detail_tab.COUNT
			LOOP
				print_out_msg(RPAD(trans_detail_tab(t_indx).creation_date,10)||' '||
               				  RPAD(NVL(trans_detail_tab(t_indx).vendor_site_category,' '),13)||' '||
							  RPAD(trans_detail_tab(t_indx).ap_po_number,15)||' '|| 
							  RPAD(trans_detail_tab(t_indx).ap_keyrec,10)||' '||
							  RPAD(NVL(trans_detail_tab(t_indx).ap_receipt_num,' '),15)||' '||
                              RPAD(trans_detail_tab(t_indx).AP_ADJ_DATE,19)||' '||        ---Added for V 5.0	
                              RPAD(trans_detail_tab(t_indx).AP_ADJ_QTY,23)||' '||	      ---Added for V 5.0
                              RPAD(trans_detail_tab(t_indx).AP_ADJ_COST,19)||' '||		  ---Added for V 5.0						  
							  RPAD(trans_detail_tab(t_indx).ap_po_lineno,4,' ')||' '||
							  RPAD(trans_detail_tab(t_indx).ap_sku,15,' ')||' '|| 
							  RPAD(trans_detail_tab(t_indx).error_description,150));
			END LOOP;
			print_out_msg(' ');
			print_out_msg(' ');
			print_out_msg('Receving Transaction Processor Errors');
			print_out_msg('=====================================');
			print_out_msg(RPAD('Supplier Type',13)||' '||RPAD('Receipt Number',15)||' '||RPAD('Document Number',15)||' '||RPAD('Sku',15)||' '||RPAD('Error Details',150));
			print_out_msg(RPAD('=',13,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',150,'='));
			OPEN rtv_cur;
			FETCH rtv_cur BULK COLLECT INTO rtv_tab;
			CLOSE rtv_cur;
			FOR r_indx IN 1..rtv_tab.COUNT
			LOOP
				print_out_msg(RPAD('NON-CONSG',13)||' '||RPAD(rtv_tab(r_indx).receipt_num,15)||' '||RPAD(NVL(rtv_tab(r_indx).document_num,' '),15)||' '||RPAD(NVL(rtv_tab(r_indx).sku,' '),15)||' '|| RPAD(rtv_tab(r_indx).error_description,150));
			END LOOP;
			-- Reset to NULL means these records are touched atleast once and these doesn't include in the Summary Report section count.
			UPDATE xx_po_rcv_adj_int_stg
			SET attribute2     = NULL
			WHERE attribute2   = 'NEW'
			AND record_status IS NOT NULL;
			print_debug_msg ('Total no of records to set attribute2 to NULL are '||SQL%ROWCOUNT, TRUE);
			COMMIT;
		EXCEPTION
		WHEN OTHERS THEN
		print_debug_msg ('Report Master Program Stats failed'||SUBSTR(sqlerrm,1,150),TRUE);
		print_out_msg ('Report Master Program stats failed'||SUBSTR(sqlerrm,1,150));
	END report_master_program_stats;
	-- +============================================================================================+
	-- |  Name   : print_child_program_stats                                                    |
	-- |  Description: This procedure print stats of child program                                  |
	-- =============================================================================================|
	PROCEDURE report_child_program_stats(
										p_batch_id NUMBER)
	AS
		CURSOR adj_count_cur
		IS
			SELECT  COUNT(*) COUNT ,
					DECODE(record_status,'E','Error','I','Interfaced',record_status) record_status
			FROM xx_po_rcv_adj_int_stg
			WHERE batch_id = p_batch_id
			GROUP BY record_status;
		TYPE stats
		IS
		TABLE OF adj_count_cur%ROWTYPE INDEX BY PLS_INTEGER;
		stats_tab STATS;
		indx NUMBER;
	BEGIN
		print_debug_msg ('Report Child Program Stats',FALSE);
		print_out_msg('OD PO RCV Adjustments Interface(Child) for Batch '||TO_CHAR(p_batch_id));
		print_out_msg('========================================================== ');
		print_out_msg(RPAD('Record Type',12)||' '||RPAD('Record Status',15)||' '||RPAD('Count',10));
		print_out_msg(RPAD('=',12,'=')||' '||RPAD('=',15,'=')||' '||rpad('=',10,'='));
		OPEN adj_count_cur;
		FETCH adj_count_cur BULK COLLECT INTO stats_tab;
		CLOSE adj_count_cur;
		FOR indx IN 1..stats_tab.COUNT
		LOOP
			print_out_msg(RPAD('Adjustments',12)||' '||RPAD(stats_tab(indx).record_status,15)||' '||RPAD(stats_tab(indx).count,10));
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		print_debug_msg ('Report Child Program Stats failed'||SUBSTR(sqlerrm,1,150),TRUE);
	END report_child_program_stats;
	-- +============================================================================================+
	-- |  Name    : child_request_status                                                        |
	-- |  Description : This function is used to return the status of the child requests            |
	-- =============================================================================================|
	FUNCTION child_request_status
	RETURN VARCHAR2
	IS
	CURSOR get_conc_status
	IS
		SELECT status_code
		FROM fnd_concurrent_requests
		WHERE parent_request_id    = gn_request_id
		AND status_code           IN('E','G');
	lc_status_code VARCHAR2(15) := NULL;
	BEGIN
		print_debug_msg ('Checking child_request_status',FALSE);
		lc_status_code := NULL;
		OPEN get_conc_status;
		FETCH get_conc_status
		INTO lc_status_code;
		CLOSE get_conc_status;
		IF lc_status_code IS NOT NULL THEN
			print_debug_msg('One or more child program completed in error or warning.',TRUE);
			RETURN 'G'; -- Warning
		ELSE
			RETURN 'C'; -- Normal
		END IF;
	END child_request_status;
	-- +============================================================================================+
	-- |  Name   : interface_child                                                              |
	-- |  Description: This procedure reads data from the staging and loads into PO interface       |
	-- |      OD PO RCV Adjustments Interface(Child)       |
	-- =============================================================================================|
	PROCEDURE interface_child(
							p_errbuf OUT VARCHAR2 ,
							p_retcode OUT VARCHAR2 ,
							p_batch_id NUMBER ,
							p_debug    VARCHAR2)
	AS
		CURSOR adj_cur
		IS
			SELECT 	 stg.record_id
					,stg.ap_location
					,stg.ap_keyrec
					,stg.ap_po_number
					,asp.segment1 ap_po_vendor
					,stg.ap_po_lineno
					,stg.ap_receipt_num
					,stg.ap_adj_date
					,stg.ap_adj_time
					,stg.ap_adj_qty
					,stg.ap_adj_cost
					,stg.ap_sku
					,stg.ap_vendor_prodcd
					,stg.ap_seq_no
					,stg.source_system_ref
					,stg.record_status
					,stg.error_description
					,stg.attribute1
					,stg.attribute5
					,poh.po_header_id
					,poh.org_id
					,DECODE(poh.org_id,404,'US_USD_P',403,'CA_CAD_P',poh.org_id) SOB_NAME
					,poh.vendor_site_id
					,hru.location_id
					,hru.organization_id
					,stg.attribute3
			FROM xx_po_rcv_adj_int_stg stg
				,po_headers_all poh
				,ap_suppliers asp
				,hr_all_organization_units hru
			WHERE 	stg.record_status          IS NULL
			AND 	poh.segment1(+)             = stg.ap_po_number
			AND 	poh.vendor_id               = asp.vendor_id
			AND 	hru.attribute1(+)           = to_number(stg.ap_location)
			AND 	hru.date_from(+)           <= sysdate
			AND   ( hru.date_to(+)    IS NULL OR hru.date_to(+)       >= sysdate)
			AND 	stg.batch_id                = p_batch_id;
		CURSOR po_check_cur
		IS
			SELECT record_id
				 , ap_po_number
				 , ap_po_lineno
			FROM xx_po_rcv_adj_int_stg stg
			WHERE 1=1
			AND NOT EXISTS
					(SELECT 1
					FROM po_headers_all poh
					WHERE 1=1
					AND poh.segment1    = stg.ap_po_number
					)
			AND stg.batch_id      		= p_batch_id
			AND stg.record_status IS NULL;
	TYPE adjustments
	IS
		TABLE OF adj_cur%ROWTYPE INDEX BY PLS_INTEGER;
		CURSOR check_item_cur(p_item VARCHAR2,p_organization_id NUMBER)
		IS
			SELECT inventory_item_id
			FROM mtl_system_items_b
			WHERE segment1      = p_item
			AND organization_id = p_organization_id;
		CURSOR get_item_uom(p_po_header_id NUMBER,p_line_num NUMBER)
		IS
		SELECT uom_code uom
		FROM po_lines_all
			,mtl_units_of_measure mum
		WHERE po_header_id     =p_po_header_id
		AND mum.unit_of_measure=unit_meas_lookup_code
		AND line_num           =p_line_num;
		CURSOR receipt_details_desc_cur( p_header_id 		  NUMBER
										,p_po_lineno 		  VARCHAR2
										,p_receipt_num 		  VARCHAR2
										,p_item_id 			  NUMBER
										,p_shipment_header_id NUMBER
										,p_shipment_line_id   NUMBER
										)
		IS
			SELECT 	 rt.unit_of_measure
					,pl.item_id
					,rt.employee_id
					,rt.shipment_header_id
					,rt.shipment_line_id
					,rt.vendor_id
					,rt.organization_id
					,rt.subinventory
					,rt.locator_id
					,rt.source_document_code
					,rt.transaction_id
					,rt.po_header_id
					,rt.po_line_id
					,rt.po_line_location_id
					,rt.po_distribution_id
					,rt.deliver_to_person_id
					,rt.location_id
					,rt.deliver_to_location_id
					,rt.transaction_type
			FROM 	rcv_transactions 	 rt,
					rcv_shipment_headers rsh,
					po_headers_all 		 ph,
					po_lines_all 		 pl
			WHERE rsh.receipt_num     = p_receipt_num
			AND ph.po_header_id       = p_header_id
			AND pl.line_num           = to_number(p_po_lineno)
			AND ph.po_header_id       = pl.po_header_id
			AND rt.po_header_id       = ph.po_header_id
			AND rt.po_line_id         = pl.po_line_id
			AND rt.shipment_header_id = rsh.shipment_header_id
			AND rt.shipment_header_id =p_shipment_header_id
			AND rt.shipment_line_id   =p_shipment_line_id
			AND pl.item_id            = p_item_id
			AND rt.transaction_type  IN ('DELIVER','RECEIVE')
			ORDER BY rt.transaction_id DESC;
		CURSOR receipt_details_asc_cur( p_header_id 			NUMBER
									   ,p_po_lineno 			VARCHAR2
									   ,p_receipt_num 			VARCHAR2
									   ,p_item_id 				NUMBER
									   ,p_shipment_header_id 	NUMBER
									   ,p_shipment_line_id 		NUMBER
									   )
		IS
			SELECT 	rt.unit_of_measure
					,pl.item_id
					,rt.employee_id
					,rt.shipment_header_id
					,rt.shipment_line_id
					,rt.vendor_id
					,rt.organization_id
					,rt.subinventory
					,rt.locator_id
					,rt.source_document_code
					,rt.transaction_id
					,rt.po_header_id
					,rt.po_line_id
					,rt.po_line_location_id
					,rt.po_distribution_id
					,rt.deliver_to_person_id
					,rt.location_id
					,rt.deliver_to_location_id
					,rt.transaction_type
			FROM 	rcv_transactions rt,
					rcv_shipment_headers rsh,
					po_headers_all ph,
					po_lines_all pl
			WHERE 	rsh.receipt_num       = p_receipt_num
			AND 	ph.po_header_id       = p_header_id
			AND 	pl.line_num           = to_number(p_po_lineno)
			AND 	ph.po_header_id       = pl.po_header_id
			AND 	rt.po_header_id       = ph.po_header_id
			AND 	rt.po_line_id         = pl.po_line_id
			AND 	rt.shipment_header_id = rsh.shipment_header_id
			AND 	pl.item_id            = p_item_id
			AND 	rt.transaction_type  IN ('DELIVER','RECEIVE')
			ORDER BY rt.transaction_id;
  --r1 receipt_details_asc_cur%ROWTYPE;
		TYPE receipt_dtl
		IS
			TABLE OF receipt_details_asc_cur%ROWTYPE INDEX BY PLS_INTEGER;
		CURSOR org_cur
		IS
			SELECT DISTINCT org_id
			FROM rcv_transactions_interface
			WHERE group_id = p_batch_id
			AND org_id    IS NOT NULL;
		TYPE org
		IS
			TABLE OF org_cur%ROWTYPE INDEX BY PLS_INTEGER;
		CURSOR get_shipment_dtls (p_po_hdr_id 	NUMBER
								, p_item_id 	NUMBER
								,p_line_no 		VARCHAR2
								,p_receipt_num 	VARCHAR2
								)
		IS
			SELECT 	rsl.shipment_header_id
				   ,rsl.shipment_line_id
				   ,rsl.quantity_received
			FROM 	rcv_shipment_headers rsh
				   ,rcv_shipment_lines rsl
				   ,po_headers_all ph
				   ,po_lines_all pl
			WHERE 1                   =1
			AND rsh.shipment_header_id=rsl.shipment_header_id
			AND rsh.receipt_num       =p_receipt_num
			AND ph.po_header_id       = p_po_hdr_id
			AND pl.line_num           = to_number(p_line_no)
			AND ph.po_header_id       = pl.po_header_id
			AND rsl.po_header_id      = ph.po_header_id
			AND rsl.po_line_id        = pl.po_line_id
			AND pl.item_id            = p_item_id ;
		CURSOR check_vendor_cur(p_vendor_site_id NUMBER)
		IS
			SELECT supa.attribute8 vendor_site_category
				  ,supa.vendor_site_code
			FROM ap_supplier_sites_all supa
			WHERE supa.vendor_site_id            = p_vendor_site_id
			AND NVL(supa.inactive_date,sysdate) >= TRUNC(sysdate);
		CURSOR check_inv_period_cur(p_organization_id NUMBER, p_adj_date DATE) IS
			SELECT oap.open_flag
			FROM org_acct_periods oap
				,org_organization_definitions ood
			WHERE oap.organization_id 	= p_organization_id
			AND oap.organization_id 	= ood.organization_id
			AND (p_adj_date BETWEEN TRUNC(oap.period_start_date) AND TRUNC (oap.schedule_close_date));
		CURSOR check_period_cur( p_appl_id 	  NUMBER
								,p_short_name VARCHAR2
								,p_adj_date DATE
								)
		IS
			SELECT gps.closing_status
			FROM  gl_period_statuses gps
				, gl_ledgers gl
			WHERE application_id	=p_appl_id
			AND gl.short_name		=p_short_name
			AND gps.ledger_id		=gl.ledger_id
			AND (p_adj_date BETWEEN TRUNC(start_date) AND TRUNC (end_date));
		CURSOR tran_type_cur(p_transaction_type_name VARCHAR2)
		IS
			SELECT 	mtt.transaction_type_id
				   ,mtt.transaction_action_id
				   ,mtt.transaction_source_type_id
			FROM mtl_transaction_types mtt
			WHERE mtt.transaction_type_name = p_transaction_type_name;
		tran_type_rec tran_type_cur%ROWTYPE;
		CURSOR get_acct_values(p_organization_id NUMBER)
		IS
			SELECT segment1
				  ,segment2
				  ,segment4
				  ,segment5
				  ,segment6
				  ,segment7
				  ,code_combination_id
			FROM 	gl_code_combinations gcc
				  , mtl_parameters mp
			WHERE gcc.code_combination_id = mp.material_account
			AND mp.organization_id        = p_organization_id;
		l_adj_tab ADJUSTMENTS;
		l_org_tab ORG;
		l_receipt_tab RECEIPT_DTL;
		indx                        NUMBER;
		o_indx                      NUMBER;
		ln_batch_size               NUMBER      := 5;
		lc_po_exists                VARCHAR2(1) := NULL;
		ld_transaction_date         DATE;
		lc_uom_code                 VARCHAR2(30);
		lc_error_msg                VARCHAR2(1000);
		lc_error_loc                VARCHAR2(100) := 'XX_PO_RCV_ADJ_INT_PKG.INTERFACE_CHILD';
		lc_req_data                 VARCHAR2(30);
		ln_job_id                   NUMBER;
		ln_interface_transaction_id NUMBER;
		ln_header_interface_id      NUMBER;
		ln_child_request_status     VARCHAR2(1) := NULL;
		ln_err_count                NUMBER;
		ln_error_idx                NUMBER;
		ln_item_id                  NUMBER;
		data_exception              EXCEPTION;
		ln_rec_count                NUMBER:=0;
		ln_int_cnt                  NUMBER;
		ln_adj_qty                  NUMBER;
		ln_trx_qty                  NUMBER;
		ln_trx_source_name          VARCHAR2(250);
		lc_vendor_site_category     VARCHAR2(150);
		lc_vendor_site_code	      	VARCHAR2(150);
		lc_segment1                 VARCHAR2(25) := NULL;
		lc_segment2                 VARCHAR2(25) := NULL;
		lc_segment4                 VARCHAR2(25) := NULL;
		lc_segment5                 VARCHAR2(25) := NULL;
		lc_segment6                 VARCHAR2(25) := NULL;
		lc_segment7                 VARCHAR2(25) := NULL;
		ln_ccid                     NUMBER;
		lc_result                   VARCHAR2(1);
		lc_period_stat              VARCHAR2(10);
		lc_inv_period_stat          VARCHAR2(10);
	BEGIN
		gc_debug      := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		SELECT SUBSTR(EXTRACT(YEAR FROM sysdate), 4,4)
		INTO gn_current_year
		FROM dual;
		print_debug_msg ('Start interface_child' ,TRUE);
		--Get value of global variable. It is null initially.
		lc_req_data := fnd_conc_global.request_data;
		-- req_date will be null for first time parent scan by concurrent manager.
		IF (lc_req_data IS NULL) THEN
			FOR p_indx IN po_check_cur
			LOOP
				BEGIN
					UPDATE xx_po_rcv_adj_int_stg stg
					SET    stg.record_status = 'E'
						  ,error_description = 'PO does not exists - Invalid PO Number=['||stg.ap_po_number||']'
						  ,attribute1		 = 'NON-CONSG'
					WHERE 1=1
					AND record_id     			= p_indx.record_id;
					print_debug_msg ('Record_id=['||TO_CHAR(p_indx.record_id)|| '] Invalid PO Number =['||p_indx.ap_po_number||']',FALSE);
					XX_PO_POM_INT_PKG.valid_and_mark_missed_po_int(p_source => 'NA-RCVADJINTR' ,p_source_record_id =>TO_CHAR(p_indx.record_id) ,p_po_number => p_indx.ap_po_number ,p_po_line_num => p_indx.ap_po_lineno ,p_result => lc_result);
					print_debug_msg ('Record_id=['||TO_CHAR(p_indx.record_id)|| '] PO Missing Result =['||lc_result||']',FALSE);
				END;
			END LOOP;
			COMMIT;
			OPEN adj_cur;
			LOOP
				FETCH adj_cur BULK COLLECT INTO l_adj_tab LIMIT ln_batch_size;
				EXIT
				WHEN l_adj_tab.COUNT = 0;
				FOR indx IN l_adj_tab.FIRST..l_adj_tab.LAST
				LOOP
					BEGIN
						IF l_adj_tab(indx).ap_receipt_num   IS NULL THEN
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'Receipt Number does not exists.';
							raise data_exception;
						END IF;
						print_debug_msg ('Start Validation - PO=['||l_adj_tab(indx).ap_po_number||']',FALSE);
						--Validate header
						print_debug_msg ('Check if PO exists',FALSE);
						lc_error_msg                    := NULL;
						IF l_adj_tab(indx).po_header_id IS NULL THEN
							print_debug_msg ('PO does not exists', FALSE);
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := 'PO does not exists - Invalid PO Number=['||l_adj_tab(indx).ap_po_number||']';
							print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] Invalid PO Number =['||l_adj_tab(indx).ap_po_number||']',FALSE);
							XX_PO_POM_INT_PKG.valid_and_mark_missed_po_int(p_source => 'NA-RCVADJINTR' ,p_source_record_id =>TO_CHAR(l_adj_tab(indx).record_id) ,p_po_number => l_adj_tab(indx).ap_po_number ,p_po_line_num => l_adj_tab(indx).ap_po_lineno ,p_result => lc_result);
							print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] PO Missing Result =['||lc_result||']',FALSE);
							raise data_exception;
						END IF;
						print_debug_msg ('Start Validation - GL Period Status',FALSE);
						OPEN check_period_cur(101,l_adj_tab(indx).sob_name, TO_DATE(l_adj_tab(indx).ap_adj_date,'MM/DD/YY'));
						FETCH check_period_cur INTO lc_period_stat;
						CLOSE check_period_cur;
						IF lc_period_stat<>'O' THEN
							l_adj_tab(indx).record_status := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'GL Period is not Open for '||to_char(l_adj_tab(indx).sob_name)||']';
							l_adj_tab(indx).attribute1 := 'NON-CONSG';
							RAISE data_exception;
						END IF;
						print_debug_msg ('Start Validation - PO Period Status',FALSE);
						OPEN check_period_cur(201,l_adj_tab(indx).sob_name, TO_DATE(l_adj_tab(indx).ap_adj_date,'MM/DD/YY'));
						FETCH check_period_cur INTO lc_period_stat;
						CLOSE check_period_cur;
						IF lc_period_stat<>'O' THEN
							l_adj_tab(indx).record_status := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'PO Period is not Open for '||to_char(l_adj_tab(indx).sob_name)||']';
							l_adj_tab(indx).attribute1 := 'NON-CONSG';
							RAISE data_exception;
						END IF;
						print_debug_msg ('Record_id='||to_char(l_adj_tab(indx).record_id)||', INV Period Status',FALSE);
						lc_inv_period_stat :=NULL;
						OPEN check_inv_period_cur(l_adj_tab(indx).organization_id, TO_DATE(l_adj_tab(indx).ap_adj_date,'MM/DD/YY'));
						FETCH check_inv_period_cur INTO lc_inv_period_stat;
						CLOSE check_inv_period_cur;
						IF lc_inv_period_stat <>'Y' THEN
							l_adj_tab(indx).record_status := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'Inventory Period is not Open for '||'['||to_char(l_adj_tab(indx).organization_id)||']';
							l_adj_tab(indx).attribute1 := 'NON-CONSG';
							RAISE data_exception;
						END IF;
						-- 1. Check if the vendor site category to check whether it is a consignment or non-consignment
						lc_vendor_site_category := NULL;
						lc_vendor_site_code	  := NULL;
						OPEN check_vendor_cur(l_adj_tab(indx).vendor_site_id);
						FETCH check_vendor_cur INTO lc_vendor_site_category, lc_vendor_site_code;
						CLOSE check_vendor_cur;
						IF lc_vendor_site_category          IS NULL THEN
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||' Invalid PO Vendor Site Id =['||l_adj_tab(indx).vendor_site_id|| '], of po_number=['||TO_CHAR(l_adj_tab(indx).ap_po_number)||']';
							print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] Invalid PO Vendor Site Id =['||l_adj_tab(indx).vendor_site_id|| '], of po_number=['||TO_CHAR(l_adj_tab(indx).ap_po_number)||']',FALSE);
							raise data_exception;
						END IF;
						SELECT DECODE(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
						INTO l_adj_tab(indx).attribute1
						FROM DUAL; -- to update in staging table
						IF l_adj_tab(indx).location_id      IS NULL THEN
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := 'Invalid location=['||l_adj_tab(indx).ap_location||']';
							print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] Invalid location =['||l_adj_tab(indx).ap_location||']',FALSE);
							raise data_exception;
						END IF;
						print_debug_msg ('Check if item is valid',FALSE);
						ln_item_id := NULL;
						OPEN check_item_cur(ltrim(l_adj_tab(indx).ap_sku,'0'),l_adj_tab(indx).organization_id);
						FETCH check_item_cur INTO ln_item_id;
						CLOSE check_item_cur;
						IF ln_item_id                       IS NULL THEN
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||' Invalid item=['||l_adj_tab(indx).ap_sku|| '], location=['||TO_CHAR(l_adj_tab(indx).location_id)||']';
							print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] Invalid item=['||l_adj_tab(indx).ap_sku|| '],location=['||TO_CHAR(l_adj_tab(indx).location_id)||']',FALSE);
							raise data_exception;
						END IF;
						IF lc_vendor_site_category = 'TR-CON' THEN
							BEGIN
								lc_segment1  := NULL;
								lc_segment2  := NULL;
								lc_segment4  := NULL;
								lc_segment5  := NULL;
								lc_segment6  := NULL;
								lc_segment7  := NULL;
								ln_rec_count := ln_rec_count +1;
								OPEN get_acct_values(l_adj_tab(indx).organization_id);
								FETCH get_acct_values
								INTO lc_segment1
									,lc_segment2
									,lc_segment4
									,lc_segment5
									,lc_segment6
									,lc_segment7
									,ln_ccid;
								CLOSE get_acct_values;
								IF lc_segment1                      IS NULL THEN
									l_adj_tab(indx).record_status     := 'E';
									l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'Error deriving material account for organization_id=['||TO_CHAR(l_adj_tab(indx).organization_id)||']';
									print_debug_msg ('Error deriving material account for organization_id=['||TO_CHAR(l_adj_tab(indx).organization_id)||']',FALSE);
								END IF;
								OPEN get_item_uom(l_adj_tab(indx).po_header_id,l_adj_tab(indx).ap_po_lineno);
								FETCH get_item_uom INTO lc_uom_code;
								CLOSE get_item_uom;
								IF lc_uom_code                      IS NULL THEN
									l_adj_tab(indx).record_status     := 'E';
									l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'Error deriving UOM CODE for item=['||TO_CHAR(l_adj_tab(indx).ap_sku)||']';
									print_debug_msg ('Error deriving UOM CODE for item=['||TO_CHAR(l_adj_tab(indx).ap_sku)||']',FALSE);
								END IF;
								IF l_adj_tab(indx).record_status = 'E' THEN
									RAISE data_exception;
								END IF;
								SELECT COUNT(1)
								INTO ln_int_cnt
								FROM mtl_transactions_interface
								WHERE attribute_category = 'WMS'
								--and transaction_source_name = 'OD CONSIGNMENT RECEIPTS'
								AND inventory_item_id                                = ln_item_id
								AND SUBSTR(attribute8,1,instr(attribute8,'|',1,3)-1) =l_adj_tab(indx).ap_receipt_num
									||'|'
									||l_adj_tab(indx).ap_po_number
									||'|'
									||to_number(l_adj_tab(indx).ap_po_lineno) ;
								--Check records exist in interface
								-----Below code is commented for V 4.0
								/*IF ln_int_cnt                        >0 THEN
									l_adj_tab(indx).record_status     := 'E';
									l_adj_tab(indx).error_description := l_adj_tab(indx).error_description||'Misc Transaction already exist in Interface for PO Number=['||l_adj_tab(indx).ap_po_number||']';
									print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)|| '] PO Number=['||l_adj_tab(indx).ap_po_number||']',FALSE);
									RAISE data_exception;
								END IF;*/
								-----END for V 4.0
								--Get the existing misc transaction qty get first 3 values delimited by |
								BEGIN
									ln_trx_qty := NULL;
									SELECT SUM(transaction_quantity)
									INTO ln_trx_qty
									FROM mtl_material_transactions
									WHERE attribute_category = 'WMS'
									  -- and transaction_source_name = 'OD CONSIGNMENT RECEIPTS'
									AND inventory_item_id                                = ln_item_id
									AND SUBSTR(attribute8,1,instr(attribute8,'|',1,3)-1) =l_adj_tab(indx).ap_receipt_num
									  ||'|'
									  ||l_adj_tab(indx).ap_po_number
									  ||'|'
									  ||l_adj_tab(indx).ap_po_lineno;
								EXCEPTION
								WHEN OTHERS THEN
									ln_trx_qty := 0;
								END;
								--Get the adj qty
								--Get the adj qty
								------------   Below code is commented for V3.0
								/*ln_adj_qty := l_adj_tab(indx).ap_adj_qty-NVL(ln_trx_qty,0); */
								------------------------------End comment for V1.1
								--------------------Below code is added for V1.1
								LN_ADJ_QTY := L_ADJ_TAB(INDX).AP_ADJ_QTY;
								-----------------------------End V3.0
								-- assign transaction type and source based on qty
								IF ln_adj_qty>0 THEN
									OPEN tran_type_cur('Miscellaneous receipt');
									FETCH tran_type_cur INTO tran_type_rec;
									CLOSE tran_type_cur;
									ln_trx_source_name :='OD CONSIGNMENT RECEIPTS';
								ELSIF ln_adj_qty      <0 THEN
									OPEN tran_type_cur('Miscellaneous issue');
									FETCH tran_type_cur INTO tran_type_rec;
									CLOSE tran_type_cur;
									ln_trx_source_name :='OD CONSIGNMENT SALES';
								ELSE -- ln_adj_qty = 0
									l_adj_tab(indx).record_status := 'I';
									l_adj_tab(indx).attribute5    := 'Skip Processing - Adjustment Quantity is 0';
									print_debug_msg('Skip Processing - Adjustment Quantity is 0:Receipt Num=['||l_adj_tab(indx).ap_receipt_num||'], PO Line No=['||l_adj_tab(indx).ap_po_lineno||']', TRUE);
									RAISE data_exception;
								END IF;
								  INSERT
								  INTO mtl_transactions_interface
									(
										transaction_header_id
									  ,source_code
									  ,source_header_id
									  ,source_line_id
									  ,process_flag
									  ,transaction_mode
									  ,lock_flag
									  ,last_update_date
									  ,last_updated_by
									  ,creation_date
									  ,created_by
									  ,inventory_item_id
									  ,organization_id
									  ,transaction_quantity
									  ,transaction_cost
									  ,primary_quantity
									  ,transaction_uom
									  ,transaction_date
									  ,subinventory_code
									  ,transaction_source_type_id
									  ,transaction_action_id
									  ,transaction_type_id
									  ,transaction_source_name
									  ,material_account
									  --,distribution_account_id
									  ,dst_segment1
									  ,dst_segment2
									  ,dst_segment3
									  ,dst_segment4
									  ,dst_segment5
									  ,dst_segment6
									  ,dst_segment7
									  ,attribute_category
									  ,attribute1
									  ,attribute8
									  ,attribute9
									)
									VALUES
									(
									  mtl_material_transactions_s.nextval 						--transaction_header_id
									  ,'INVENTORY' 												--source_code
									  ,-1 														--source_header_id
									  ,-1 														--source_line_id
									  ,1 														--process_flag
									  ,3 														--transaction_mode
									  ,2 														--lock_flag
									  ,sysdate 													--last_update_date
									  ,gn_user_id 												--last_updated_by (could filled by user_id)
									  ,sysdate 													--creation_date
									  ,gn_user_id 												--created_by (could filled by user_id)
									  ,ln_item_id 												--inventory_item_id
									  ,l_adj_tab(indx).organization_id 							--organization_id 03077
									  ,ln_adj_qty 												--l_adj_tab(indx).ap_rcvd_quantity      --transaction_quantity
									  ,l_adj_tab(indx).ap_adj_cost 								--transaction_cost
									  ,ln_adj_qty												--l_adj_tab(indx).ap_rcvd_quantity      --primary_quantity
									  ,lc_uom_code 												--transaction_uom_code
									  ,to_date(l_adj_tab(indx).ap_adj_date,'MM/DD/YY') 			--discuss transaction_date?
									  ,'STOCK' 													--subinventory_code
									  ,tran_type_rec.transaction_source_type_id 				--transaction_source_type_id
									  ,tran_type_rec.transaction_action_id 						--transaction_action_id
									  ,tran_type_rec.transaction_type_id 						--transaction_type_id
									  ,ln_trx_source_name 										--'OD CONSIGNMENT RECEIPTS'
									  ,ln_ccid
									  ,lc_segment1
									  ,lc_segment2
									  ,'12102000'
									  ,lc_segment4
									  ,lc_segment5
									  ,lc_segment6
									  ,lc_segment7
									  ,'WMS'
									  ,lc_vendor_site_code										--LPAD(l_adj_tab(indx).ap_po_vendor,10,'0'),				Check Condition
									  ,l_adj_tab(indx).ap_receipt_num
										  ||'|'
										  ||l_adj_tab(indx).ap_po_number
										  ||'|'
										  ||to_number(l_adj_tab(indx).ap_po_lineno)
										  ||'|'
										  ||l_adj_tab(indx).record_id
										  ||'|'
										  ||p_batch_id
									  ,l_adj_tab(indx).attribute3
									);
								l_adj_tab(indx).record_status := 'I';
							EXCEPTION
							WHEN data_exception THEN
								print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)||']'||l_adj_tab(indx).error_description,FALSE);
								--  l_adj_tab(indx).record_status     := 'E';
								--  l_adj_tab(indx).error_description := l_adj_tab(indx).error_description;
							WHEN OTHERS THEN
								lc_error_msg := SUBSTR(sqlerrm,1,250);
								print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)||']'||l_adj_tab(indx).error_description||' '||lc_error_msg,FALSE);
								l_adj_tab(indx).record_status     := 'E';
								l_adj_tab(indx).error_description := l_adj_tab(indx).error_description ||' '||lc_error_msg;
							END;
						ELSE
						ln_rec_count :=0;
						FOR r IN get_shipment_dtls
							(
							  l_adj_tab(indx).po_header_id, ln_item_id,l_adj_tab(indx).ap_po_lineno,l_adj_tab(indx).ap_receipt_num
							)
						LOOP
------------   Below code is commented for V3.0
           /*
							ln_adj_qty :=(
											l_adj_tab(indx).ap_adj_qty
										 )
										-NVL(
											r.quantity_received,0
										    );
            */
------------------------------End comment for V1.1
--------------------Below code is added for V1.1
ln_adj_qty := l_adj_tab(indx).ap_adj_qty;

-----------------------------End V3.0
						IF ln_adj_qty>0 THEN
							OPEN receipt_details_asc_cur(l_adj_tab(indx).po_header_id
														,l_adj_tab(indx).ap_po_lineno
														,l_adj_tab(indx).ap_receipt_num
														,ln_item_id
														,r.shipment_header_id
														,r.shipment_line_id
														);
							FETCH receipt_details_asc_cur BULK COLLECT INTO l_receipt_tab;
						ELSIF ln_adj_qty < 0 THEN
							OPEN receipt_details_desc_cur(l_adj_tab(indx).po_header_id
														 ,l_adj_tab(indx).ap_po_lineno
														 ,l_adj_tab(indx).ap_receipt_num
														 ,ln_item_id
														 ,r.shipment_header_id
														 ,r.shipment_line_id
														 );
							FETCH receipt_details_desc_cur BULK COLLECT INTO l_receipt_tab;
						ELSE -- ln_adj_qty = 0
							l_adj_tab(indx).record_status := 'I';
							l_adj_tab(indx).attribute5    := 'Skip Processing - Adjustment Quantity is 0';
							print_debug_msg('Skip Processing - Adjustment Quantity is 0:Receipt Num=['||l_adj_tab(indx).ap_receipt_num||'], PO Line No=['||l_adj_tab(indx).ap_po_lineno||'], Shipment Line Id=['||r.shipment_line_id||']', TRUE);
						END IF;
						ln_rec_count          := ln_rec_count+ l_receipt_tab.COUNT;
						IF l_receipt_tab.COUNT > 0 THEN
							FOR i IN l_receipt_tab.FIRST .. l_receipt_tab.LAST
							LOOP
								IF l_receipt_tab(i).shipment_header_id IS NULL THEN
									l_adj_tab(indx).record_status        := 'E';
									l_adj_tab(indx).error_description    := l_adj_tab(indx).error_description||' Receipt Number does not exists - Receipt Num=['||l_adj_tab(indx).ap_receipt_num||']';
								END IF;
								IF l_adj_tab(indx).record_status = 'E' THEN
									RAISE data_exception;
								END IF;
								SELECT rcv_transactions_interface_s.NEXTVAL
								INTO ln_interface_transaction_id
								FROM dual;
								ld_transaction_date := to_date(l_adj_tab(indx).ap_adj_date||' '||l_adj_tab(indx).ap_adj_time,'MM/DD/RRRR HH24:MI:SS');
								-- Insert in transactions interface table --
								print_debug_msg ('Insert into transactions interface id=['||TO_CHAR(ln_interface_transaction_id)||']',FALSE);
								INSERT
								INTO rcv_transactions_interface
								(
									interface_transaction_id
								  ,group_id
								  ,last_update_date
								  ,last_updated_by
								  ,creation_date
								  ,created_by
								  ,last_update_login
								  ,transaction_type
								  ,transaction_date
								  ,processing_status_code
								  ,processing_mode_code
								  ,transaction_status_code
								  ,quantity
								  ,unit_of_measure
								  ,item_id
								  ,employee_id
								  ,shipment_header_id
								  ,shipment_line_id
								  ,receipt_source_code
								  ,vendor_id
								  ,from_organization_id
								  ,from_subinventory
								  ,from_locator_id
								  ,source_document_code
								  ,parent_transaction_id
								  ,po_header_id
								  ,po_line_id
								  ,po_line_location_id
								  ,po_distribution_id
								  ,destination_type_code
								  ,deliver_to_person_id
								  ,location_id
								  ,deliver_to_location_id
								  ,validation_flag
								  ,org_id
								  ,attribute8
								  ,attribute9
								)
								VALUES
								(
								   ln_interface_transaction_id
								  ,p_batch_id
								  ,sysdate
								  ,gn_user_id
								  ,sysdate
								  ,gn_user_id
								  ,gn_login_id
								  ,'CORRECT' 													--transaction_type
								  ,ld_transaction_date
								  ,'PENDING' 													--processing_status_code
								  ,'BATCH' 														--processing_mode_code
								  ,'PENDING' 													--transaction_status_code
								  ,ln_adj_qty 													--quantity
								  ,l_receipt_tab(i).unit_of_measure 							--unit_of_measure
								  ,l_receipt_tab(i).item_id 									--item_id
								  ,l_receipt_tab(i).employee_id 								--employee_id
								  ,l_receipt_tab(i).shipment_header_id 							--shipment_header_id
								  ,l_receipt_tab(i).shipment_line_id 							--shipment_line_id
								  ,'VENDOR' 													--receipt_source_code
								  ,l_receipt_tab(i).vendor_id 									--vendor_id
								  ,l_receipt_tab(i).organization_id 							--from_organization_id
								  ,l_receipt_tab(i).subinventory 								--from_subinventory
								  ,l_receipt_tab(i).locator_id 									--from_locator_id
								  ,l_receipt_tab(i).source_document_code 						--source_document_code
								  ,l_receipt_tab(i).transaction_id 								--parent_transaction_id
								  ,l_receipt_tab(i).po_header_id 								--po_header_id
								  ,l_receipt_tab(i).po_line_id 									--po_line_id
								  ,l_receipt_tab(i).po_line_location_id 						--po_line_location_id
								  ,l_receipt_tab(i).po_distribution_id 							--po_distribution_id
								  ,DECODE(l_receipt_tab(i).transaction_type,'RECEIVE','RECEIVING','DELIVER','INVENTORY',l_receipt_tab(i).transaction_type) --destination_type_code
								  ,l_receipt_tab(i).deliver_to_person_id 						--deliver_to_person_id
								  ,l_receipt_tab(i).location_id 								--location_id
								  ,l_receipt_tab(i).deliver_to_location_id 						--deliver_to_location_id
								  ,'Y' 															--Validation_flag
								  ,l_adj_tab(indx).org_id
										  ,l_adj_tab(indx).ap_receipt_num
										  ||'|'
										  ||l_adj_tab(indx).ap_po_number
										  ||'|'
										  ||to_number(l_adj_tab(indx).ap_po_lineno)
										  ||'|'
										  ||l_adj_tab(indx).record_id
										  ||'|'
										  ||p_batch_id
								  ,l_adj_tab(indx).attribute3
								);
								l_adj_tab(indx).record_status := 'I';
							END LOOP;
						END IF;
						IF (receipt_details_asc_cur%ISOPEN) THEN
							CLOSE receipt_details_asc_cur;
						END IF;
						IF (receipt_details_desc_cur%ISOPEN) THEN
							CLOSE receipt_details_desc_cur;
						END IF;
					END LOOP;
				END IF; -- Consignment or not
						IF ln_rec_count                      =0 THEN
							l_adj_tab(indx).record_status     := 'E';
							l_adj_tab(indx).error_description := 'Unable to find receipt '||l_adj_tab(indx).ap_receipt_num||' with po # '||l_adj_tab(indx).ap_po_number||' and Line No # '||l_adj_tab(indx).ap_po_lineno;
						END IF;
					EXCEPTION
					WHEN data_exception THEN
						print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)||']'||l_adj_tab(indx).error_description,FALSE);
						l_adj_tab(indx).record_status     := 'E';
						l_adj_tab(indx).error_description := l_adj_tab(indx).error_description;
					WHEN OTHERS THEN
						lc_error_msg := SUBSTR(sqlerrm,1,250);
						print_debug_msg ('Record_id=['||TO_CHAR(l_adj_tab(indx).record_id)||']'||l_adj_tab(indx).error_description||' '||lc_error_msg,FALSE);
						l_adj_tab(indx).record_status     := 'E';
						l_adj_tab(indx).error_description := l_adj_tab(indx).error_description ||' '||lc_error_msg;
					END;
				END LOOP; --adj tab
				BEGIN
				print_debug_msg('Starting update of xx_po_rcv_adj_int_stg #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
				FORALL i IN 1..l_adj_tab.COUNT
					SAVE EXCEPTIONS
					UPDATE xx_po_rcv_adj_int_stg
					SET record_status = l_adj_tab(i).record_status--DECODE(l_adj_tab(i).record_status,'E','E','I')
					  ,error_description = l_adj_tab(i).error_description
					  ,attribute1        =l_adj_tab(i).attribute1
					  ,attribute5        =l_adj_tab(i).attribute5
					  ,ap_receipt_num    =l_adj_tab(i).ap_receipt_num
					  ,last_update_date  = sysdate
					  ,last_updated_by   = gn_user_id
					  ,last_update_login = gn_login_id
					WHERE record_id     = l_adj_tab(i).record_id;
				EXCEPTION
				WHEN OTHERS THEN
					print_debug_msg('Bulk Exception raised',TRUE);
					ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
					FOR i IN 1..ln_err_count
					LOOP
						ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
						lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
						log_exception ('OD PO RCV Adjustments Interface(Child)',lc_error_loc,lc_error_msg);
						print_debug_msg('Record_id=['||TO_CHAR(l_adj_tab(ln_error_idx).record_id)||'], Error msg=['||lc_error_msg||']',TRUE);
					END LOOP; -- bulk_err_loop FOR UPDATE
				END;
				print_debug_msg('Ending Update of xx_po_rcv_adj_int_stg #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
				COMMIT;
				print_debug_msg('Commit Complete',FALSE);
			END LOOP; --adj_cur
			CLOSE adj_cur;
			PRINT_DEBUG_MSG('Submitting Receiving Transaction Processor',false);
        ----- Below logic added for V3.0
			update RCV_TRANSACTIONS_INTERFACE
			set GROUP_ID =-p_batch_id
			where group_id =p_batch_id
			and quantity <0 ;
			commit;
    --------- End V3.0
			OPEN org_cur;
			FETCH org_cur BULK COLLECT INTO l_org_tab;
			CLOSE org_cur;
			FOR o_indx IN 1..l_org_tab.COUNT
			LOOP
				print_debug_msg('Submitting Receiving Transaction Processor for batchid=['||p_batch_id||'], Org_id=['||l_org_tab(o_indx).org_id||']',FALSE);
				--user_id SVC_ESP_FIN 90102
				--resp_id Purchasing Super User 20707
				--resp_app_id po - 201
				--fnd_global.apps_initialize (gn_user_id,20707,201);
				mo_global.set_policy_context('S',l_org_tab(o_indx).org_id);
				mo_global.init ('PO');
				ln_job_id := fnd_request.submit_request( application => 'PO'
														,program => 'RVCTP'
														,sub_request => TRUE
														,argument1 => 'BATCH' 		-- Node
														,argument2 => p_batch_id    -- Group Id
														,argument3 => l_org_tab(o_indx).org_id                                                                                     -- org_id
														);
				COMMIT;
			END LOOP;
			--Pause if child request exists
			IF l_org_tab.COUNT > 0 THEN
				-- Set parent program status as 'PAUSED' and set global variable value to 'END'
				print_debug_msg('Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
				fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
				print_debug_msg('Complete Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
			ELSE
				print_debug_msg('No Child Requests submitted...',TRUE);
				--report_child_program_stats(p_batch_id);
				p_retcode := '0';
			END IF;
		END IF; --l_req_data IS NULL
		IF (lc_req_data = 'END') THEN
			update_staging_record_status(p_batch_id);
			ln_child_request_status   := child_request_status;
			IF ln_child_request_status = 'C' THEN
				report_child_program_stats(p_batch_id);
				p_retcode                  := '0';
			ELSIF ln_child_request_status = 'G' THEN
				p_retcode                  := '1'; --Warning
				p_errbuf                   := 'One or more child program completed in error or warning';
			END IF;
		end if;
--  ----- Added for V3.0
--   		update RCV_TRANSACTIONS_INTERFACE
--			set GROUP_ID =p_batch_id
--			where group_id =-p_batch_id
--			and QUANTITY <0 ;
--			commit;
--   ----- End for V3.0
	EXCEPTION
	WHEN OTHERS THEN
		lc_error_msg := SUBSTR(sqlerrm,1,250);
		print_debug_msg ('ERROR RCV Adjustments Int Child- '||lc_error_msg,TRUE);
		log_exception ('OD PO RCV Adjustments Interface(Child)', lc_error_loc, lc_error_msg);
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
	END interface_child;
	-- +============================================================================================+
	-- |  Name   : submit_int_child_threads                                                     |
	-- |  Description: This procedure splits PO into batches and submits child process-             |
	-- |               OD PO RCV Inbound Interface(Child)                                           |
	-- =============================================================================================|
	PROCEDURE submit_int_child_threads(
										p_errbuf 		OUT VARCHAR2
									   ,p_retcode 		OUT VARCHAR2
									   ,p_child_threads NUMBER
									   ,p_debug         VARCHAR2
									  )
	AS
		CURSOR threads_cur
		IS
			SELECT MIN(x.ap_po_number) from_po ,
				   MAX(x.ap_po_number) to_po ,
				   x.thread_num ,
				   COUNT(1)
			FROM
				(SELECT h.ap_po_number
						,NTILE(p_child_threads) OVER(ORDER BY h.ap_po_number) thread_num
				 FROM xx_po_rcv_adj_int_stg h
				 WHERE h.record_status IS NULL
				) x
			GROUP BY x.thread_num
			ORDER BY x.thread_num;
	TYPE threads
	IS
		TABLE OF threads_cur%ROWTYPE INDEX BY PLS_INTEGER;
		l_threads_tab threads;
		lc_error_msg   VARCHAR2(1000) := NULL;
		lc_error_loc   VARCHAR2(100)  := 'XX_PO_RCV_ADJ_INT_PKG.SUBMIT_INT_CHILD_THREADS';
		ln_batch_count NUMBER;
		ln_batch_id    NUMBER;
		ln_request_id  NUMBER;
	BEGIN
		print_debug_msg('Preparing threads for new po/add line',TRUE);
		OPEN threads_cur;
		FETCH threads_cur BULK COLLECT INTO l_threads_tab;
		CLOSE threads_cur;
		print_debug_msg('Update BatchID in headers for import',TRUE);
		FOR indx IN 1..l_threads_tab.COUNT
		LOOP
			SELECT rcv_interface_groups_s.nextval --xx_po_rcv_adj_int_batch_s.nextval
			INTO ln_batch_id
			FROM dual;
			UPDATE xx_po_rcv_adj_int_stg h
			SET h.batch_id        = ln_batch_id ,
				h.last_update_date  = sysdate ,
				h.last_updated_by   = gn_user_id ,
				h.last_update_login = gn_login_id
			WHERE h.ap_po_number BETWEEN l_threads_tab(indx).from_po
			AND l_threads_tab(indx).to_po
			AND h.record_status IS NULL;
			ln_batch_count      := SQL%ROWCOUNT;
			print_debug_msg(TO_CHAR(ln_batch_count)||' rcv adjustment record(s) updated with batchid '||TO_CHAR(ln_batch_id),TRUE);
			COMMIT;
			ln_request_id := fnd_request.submit_request(application => 'XXFIN' ,program => 'XXPORCV_ADJ_INTC' ,sub_request => TRUE ,argument1 => ln_batch_id ,argument2 => p_debug);
			COMMIT;
		END LOOP;
		--Check if any child requests submitted.
		IF l_threads_tab.COUNT > 0 THEN
			p_retcode           := '0';
		ELSE
			p_retcode := '1';
		END IF;
		EXCEPTION
		WHEN OTHERS THEN
			lc_error_msg := SUBSTR(sqlerrm,1,250);
			print_debug_msg('ERROR in SUBMIT_INT_CHILD_TREADS'||lc_error_msg,TRUE);
			log_exception ('OD PO RCV Adjustments Interface(Master)',lc_error_loc,lc_error_msg);
			p_retcode := '2';
			p_errbuf  := SUBSTR(sqlerrm,1,250);
		END submit_int_child_threads;
	PROCEDURE update_receipt_num
	IS
		CURSOR rec_cur
		IS
			SELECT 	stg.record_id
				  , stg.ap_location
				  ,stg.ap_keyrec
				  ,stg.ap_seq_no
				  ,poh.vendor_site_id
				  ,stg.ap_po_number
				  ,stg.ap_po_lineno
				  ,hru.location_id
				  ,hru.organization_id
			FROM 	xx_po_rcv_adj_int_stg stg ,
					po_headers_all poh ,
					hr_all_organization_units hru
			WHERE (	   stg.record_status      IS NULL
					OR stg.record_status      = 'E' )
			AND ap_receipt_num            IS NULL
			AND poh.segment1(+)            = stg.ap_po_number
			AND hru.attribute1             = to_number(stg.ap_location)
			AND hru.date_from             <= sysdate
			AND NVL(hru.date_to,sysdate+1) > sysdate;
		TYPE rec
		IS
			TABLE OF rec_cur%ROWTYPE INDEX BY PLS_INTEGER;
		CURSOR check_vendor_cur(p_vendor_site_id NUMBER)
		IS
			SELECT supa.attribute8 vendor_site_category
			FROM ap_supplier_sites_all supa
			WHERE supa.vendor_site_id            = p_vendor_site_id
			AND NVL(supa.inactive_date,sysdate) >= TRUNC(sysdate);
		l_rec_tab rec;
		ln_batch_size           NUMBER := 1000;
		lc_vendor_site_category VARCHAR2(150);
		ln_receipt_num          VARCHAR2(150);
		ln_stg_receipt_num      VARCHAR2(150);
		ln_mtl_cnt              NUMBER;
		ln_yr_cnt               NUMBER :=0;
		gn_current_year         NUMBER;
	BEGIN
		SELECT SUBSTR(EXTRACT(YEAR FROM sysdate), 4,4)
		INTO gn_current_year
		FROM dual;
		FOR cur IN rec_cur
		LOOP
			BEGIN
				ln_yr_cnt :=0;
				FOR r IN 1..2
				LOOP
					BEGIN
						ln_receipt_num     :=NULL;
						ln_mtl_cnt         := 0;
						ln_stg_receipt_num :=cur.ap_location ||cur.ap_keyrec ||cur.ap_seq_no ||(gn_current_year-ln_yr_cnt);
						print_debug_msg ('RECORD ID :'||cur.record_id ||':'||' ln_stg_receipt_num:'||ln_stg_receipt_num,TRUE);
						OPEN check_vendor_cur(cur.vendor_site_id);
						FETCH check_vendor_cur
						INTO lc_vendor_site_category;
						CLOSE check_vendor_cur;
						IF lc_vendor_site_category = 'TR-CON' THEN
							SELECT COUNT(1)
							INTO ln_mtl_cnt
							FROM mtl_material_transactions
							WHERE attribute_category                             = 'WMS'
							AND SUBSTR(attribute8,1,instr(attribute8,'|',1,3)-1) =ln_stg_receipt_num
									||'|'
									||cur.ap_po_number
									||'|'
									||cur.ap_po_lineno;
							IF ln_mtl_cnt    >= 0 THEN
								ln_receipt_num :=ln_stg_receipt_num;
							ELSE
								SELECT COUNT(1)
								INTO ln_mtl_cnt
								FROM mtl_transactions_interface rhi
								WHERE attribute_category                             = 'WMS'
								AND SUBSTR(attribute8,1,instr(attribute8,'|',1,3)-1) =ln_stg_receipt_num
									||'|'
									||cur.ap_po_number
									||'|'
									||cur.ap_po_lineno;
								IF ln_mtl_cnt    >= 0 THEN
									ln_receipt_num :=ln_stg_receipt_num;
								ELSE
									SELECT COUNT(1)
									INTO ln_mtl_cnt
									FROM xx_po_rcv_trans_int_stg stg
									WHERE ap_receipt_num=ln_stg_receipt_num
									AND rownum          = 1;
									IF ln_mtl_cnt      >= 0 THEN
										ln_receipt_num   :=ln_stg_receipt_num;
									ELSE
										ln_receipt_num := NULL;
									END IF; -- End If of xx_po_rcv_adj_int_stg count
								END IF;   -- End If of mtl_transactions_interface count
							END IF;     -- End If of mtl_material_transactions count
						ELSE
							ln_receipt_num :=NULL;
							BEGIN
								SELECT receipt_num
								INTO ln_receipt_num
								FROM rcv_shipment_headers
								WHERE receipt_num= ln_stg_receipt_num;
							EXCEPTION
							WHEN NO_DATA_FOUND THEN
								BEGIN
									SELECT receipt_num
									INTO ln_receipt_num
									FROM rcv_headers_interface rhi
									WHERE receipt_num= ln_stg_receipt_num
									AND ROWNUM       =1;
								EXCEPTION
								WHEN NO_DATA_FOUND THEN
									BEGIN
										SELECT ap_receipt_num
										INTO ln_receipt_num
										FROM xx_po_rcv_trans_int_stg stg
										WHERE ap_receipt_num=ln_stg_receipt_num
										AND ROWNUM          =1;
									EXCEPTION
									WHEN OTHERS THEN
										ln_receipt_num :=NULL;
									END;
								END;
							END;
						END IF;
						UPDATE xx_po_rcv_adj_int_stg
						SET ap_receipt_num=ln_receipt_num,
							attribute1      = DECODE(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
						WHERE record_id   =cur.record_id;
						COMMIT;
					END;
					IF ln_receipt_num IS NOT NULL THEN
						EXIT;
					END IF;
					ln_yr_cnt :=ln_yr_cnt+1;
				END LOOP;
			EXCEPTION
			WHEN OTHERS THEN
				print_debug_msg ('EXCEPTION in update_receipt_num for location-keyrec-apseqno '||cur.ap_location ||cur.ap_keyrec ||cur.ap_seq_no ||' as '||SUBSTR(SQLERRM, 1, 500),TRUE);
			END;
		END LOOP;
	EXCEPTION
	WHEN OTHERS THEN
		print_debug_msg ('EXCEPTION in update_receipt_num procedure '||SUBSTR(SQLERRM, 1, 500),TRUE);
	END update_receipt_num;
	-- +============================================================================================+
	-- |  Name   : interface_master                                                             |
	-- |  Description: This procedure reads data from the staging and loads into RCV interface      |
	-- |               OD PO RCV Adjustments Interface(Master)                                      |
	-- =============================================================================================|
	PROCEDURE interface_master(
								 p_errbuf OUT VARCHAR2
								,p_retcode OUT VARCHAR2
								,p_child_threads NUMBER
								,p_retry_errors  VARCHAR2
								,p_debug         VARCHAR2
								)
	AS
		lc_error_msg            VARCHAR2(1000) := NULL;
		lc_error_loc            VARCHAR2(100)  := 'XX_PO_RCV_ADJ_INT_PKG.INTERFACE_MASTER';
		ln_retry_count          NUMBER;
		lc_retcode              VARCHAR2(3) := NULL;
		lc_iretcode             VARCHAR2(3) := NULL;
		lc_uretcode             VARCHAR2(3) := NULL;
		lc_req_data             VARCHAR2(30);
		ln_child_request_status VARCHAR2(1) := NULL;
------Below cursor is added for V4.0		
CURSOR RTI_CUR
Is
select distinct group_id,org_id
from rcv_transactions_interface
where 1=1 
---and creation_Date>=sysdate-2
--and transaction_type = 'CORRECT'
and processing_status_code = 'PENDING' 
and quantity <0;
ln_job_id number :=0;
l_adj_date varchar2(10);
-----end V4.0		
	BEGIN
		gc_debug      := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		--Get value of global variable. It is null initially.
		lc_req_data := fnd_conc_global.request_data;
		-- req_date will be null for first time parent scan by concurrent manager.
		IF (lc_req_data IS NULL) THEN
			-- Derive and update the receipt_number if it is not yet derived
			update_receipt_num;
----Commented for V3.0
	/*		BEGIN
				UPDATE xx_po_rcv_adj_int_stg ra
				SET ra.record_status    = 'D' ,
					ra.attribute5         = 'Marked as Duplicate' ,
					ra.last_update_date   = sysdate ,
					ra.last_updated_by    = gn_user_id ,
					ra.last_update_login  = gn_login_id
				WHERE (	   ra.record_status = 'E'
						OR ra.record_status = 'IE'
						OR ra.record_status IS NULL
					   )
				AND ra.ap_receipt_num  IS NOT NULL
				AND EXISTS
					(SELECT '1'
					FROM xx_po_rcv_adj_int_stg rac
					WHERE 1                 =1
					AND rac.ap_receipt_num  = ra.ap_receipt_num
					AND rac.ap_po_lineno    = ra.ap_po_lineno
					AND rac.record_id       > ra.record_id
					AND rac.record_status  IS NULL
					AND rac.ap_receipt_num IS NOT NULL
					) ;
				print_debug_msg ('Marked Duplicate count is '||SQL%ROWCOUNT,TRUE);
			EXCEPTION
			WHEN OTHERS THEN
				lc_error_msg := SUBSTR(SQLERRM, 1, 250);
				print_debug_msg ('Exception - Marked Duplicate count is '||lc_error_msg,TRUE);
				p_retcode := 2;
				p_errbuf  := lc_error_msg;
				RETURN;
			END;
			*/
      
----End for V3.0
---Added for V4.0
BEGIN
SELECT to_char(gps.START_DATE ,'mm/dd/yy') into l_adj_date
			FROM  gl_period_statuses gps
				, gl_ledgers gl
			WHERE application_id	=101 --in(101,201)
			AND gl.short_name		= 'US_USD_P' --p_short_name
			AND gps.ledger_id		=gl.ledger_id 
      and gps.closing_status ='O'
			AND (sysdate BETWEEN TRUNC(start_date) AND TRUNC (end_date))
      and rownum<2; 
      
 update  XX_PO_RCV_ADJ_INT_STG 
SET AP_ADJ_DATE = l_adj_date
    ,RECORD_STATUS = NULL
    ,ERROR_DESCRIPTION  = NULL
WHERE 1=1
and ERROR_DESCRIPTION in ('GL Period is not Open for US_USD_P]','PO Period is not Open for US_USD_P]') ;

COMMIT; 
update  XX_PO_RCV_TRANS_INT_STG 
SET AP_RCVD_DATE = l_adj_date ----'12/30/19'
    ,RECORD_STATUS = NULL
    ,ERROR_DESCRIPTION  = NULL
WHERE (AP_PO_NUMBER,AP_RECEIPT_NUM) in (select distinct  AP_PO_NUMBER, AP_RECEIPT_NUM
										from XX_PO_RCV_TRANS_INT_STG 
										where 1=1
										AND ERROR_DESCRIPTION IN ('GL Period is not Open for US_USD_P','PO Period is not Open for US_USD_P') );
COMMIT;

EXCEPTION
WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log,'Error while updating the adjustment date :');
END;

--end for V4.0
			print_debug_msg('Check Retry Errors',TRUE);
			IF p_retry_errors = 'Y' THEN
				print_debug_msg('Updating rcv adjustment staging records for retry',FALSE);
				UPDATE xx_po_rcv_adj_int_stg
				SET  record_status      = NULL
					,error_description  = NULL
					,last_update_date   = sysdate
					,last_updated_by    = gn_user_id
					,last_update_login  = gn_login_id
				WHERE record_status IN('E','IE') ;
				ln_retry_count      := SQL%ROWCOUNT;
				print_debug_msg(TO_CHAR(ln_retry_count)||' record(s) updated for retry',TRUE);
				COMMIT;
			END IF;
			-- Skip the PO's if they belong to Internal Vendors.
			BEGIN
				UPDATE xx_po_rcv_adj_int_stg hs
				SET  record_status    = 'I'
					,attribute5         = 'Internal Vendor - skip Adjustment processing'
					,last_update_date   = sysdate
					,last_updated_by    = gn_user_id
					,last_update_login  = gn_login_id
				WHERE record_status IS NULL
				AND EXISTS
					(SELECT '1'
					 FROM 	xx_fin_translatedefinition xtd
						  , xx_fin_translatevalues xtv
					 WHERE xtd.translation_name = 'PO_POM_INT_VENDOR_EXCL'
					 AND xtd.translate_id       = xtv.translate_id
					 AND xtv.source_value1      =
											  (SELECT sup.segment1
											   FROM   ap_suppliers sup
													, po_headers_all aha
												WHERE aha.vendor_id=sup.vendor_id
												AND aha.segment1   =hs.ap_po_number
											  )
					);
			  print_debug_msg('Internal Vendor Skip - Updated Staged Receipt Adjustment count is '||SQL%ROWCOUNT,TRUE);
			COMMIT;
		END;
		lc_iretcode := NULL;
		submit_int_child_threads(lc_error_msg,lc_iretcode,p_child_threads,p_debug);
		IF lc_iretcode = '0' THEN
			-- Pause if child request exists
			-- Set parent program status as 'PAUSED' and set global variable value to 'END'
			print_debug_msg('Pausing MASTER Program for interface......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
			fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
			print_debug_msg('Complete Pausing MASTER Program for interface......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE);
		ELSIF lc_iretcode = '2' THEN
			p_retcode      := '2';
			p_errbuf       := lc_error_msg;
		ELSIF lc_iretcode = '1' THEN
			print_debug_msg('No Interface Child Requests submitted...',TRUE);
		END IF;
	END IF; --l_req_data IS NULL
	IF (lc_req_data              = 'END') THEN
		p_retcode                 := '0';
		ln_child_request_status   := child_request_status;
    IF ln_child_request_status = 'C' THEN
		report_master_program_stats;
		p_retcode                  := '0';
    ELSIF ln_child_request_status = 'G' THEN
		p_retcode                  := '1'; --Warning
		p_errbuf                   := 'One or more child program completed in error or warning';
    end if;

      ----- Added for V3.0
   		update RCV_TRANSACTIONS_INTERFACE
			set GROUP_ID = ltrim(GROUP_ID,'-')  -----GROUP_ID
			where  group_id  <0 ;
			commit;
   ----- End for V3.0
 -----Added for V4.0  
   for i in RTI_CUR
   loop
     mo_global.set_policy_context('S',i.org_id);
	 mo_global.init ('PO');
	 ln_job_id := fnd_request.submit_request( application => 'PO'
											 ,program => 'RVCTP'
											 ,sub_request => TRUE
											 ,argument1 => 'BATCH' 		-- Node
											 ,argument2 => i.group_id ----p_batch_id    -- Group Id
											 ,argument3 => i.org_id                                                                                     -- org_id
														);
				COMMIT;
  print_debug_msg('Submitted RTI program for group id...'||i.group_id||', request id : '||ln_job_id ,TRUE); 
   
   end loop;
------ End V4.0   
		-- Sends the program output in email
		send_output_email(fnd_global.conc_request_id, p_retcode);
	END IF;
	EXCEPTION
	WHEN OTHERS THEN
		lc_error_msg := SUBSTR(sqlerrm,1,250);
		print_debug_msg ('ERROR RCV Adjustment Int Master - '||lc_error_msg,TRUE);
		log_exception ('OD PO RCV Inbound Interface(Master)', lc_error_loc, lc_error_msg);
		p_retcode := 2;
	END interface_master;
END XX_PO_RCV_ADJ_INT_PKG;
/
SHOW ERRORS;