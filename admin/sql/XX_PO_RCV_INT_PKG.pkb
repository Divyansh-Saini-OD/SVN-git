create or replace PACKAGE BODY XX_PO_RCV_INT_PKG
AS
	-- +============================================================================================+
	-- |  Office Depot - Project Simplify                                                           |
	-- |                                                                                            |
	-- +============================================================================================+
	-- |  Name	 :  XX_PO_RCV_INT_PKG                                                               |
	-- |  RICE ID 	 :  I2194_WMS_Receipts_to_EBS_Interface     			                        |
	-- |  Description:  Load RCV Interface Data from file to Staging Tables ,                       |
	-- |                Staging to Interface and import to EBS                                      |
	-- |                                                           				                    |
	-- |		    										                                        |
	-- +============================================================================================+
	-- | Version     Date         Author           Remarks                                          |
	-- | =========   ===========  =============    ===============================================  |
	-- | 1.0         04/24/2017   Avinash Baddam   Initial version                                  |
	-- | 1.1         10/31/2017   Havish Kasina    Added the new parameters in the procedure        |
	-- |                                           mtl_transaction_int                              |
	-- | 1.2         10/31/2017   Uday Jadhav      Added Logic to update the stage table after import Run |
	-- | 1.3         10/31/2017   Uday Jadhav      changed to check misship PO line number 			|
	-- | 1.4         09/12/2018   Veera Reddy      Added unit Cost and extended cost to report      |
	-- |                                            output(NAIT-49797)
	-- | 1.5		 10/05/2018	  Shalu George	   Fixed GSCC Violation bug.						|
	 -- | 1.6         01/24/2019   BIAS             INSTANCE_NAME is replaced with DB_NAME for OCI   |	
	-- |                                           Migration Project   
	-- +============================================================================================+

	-- +============================================================================================+
	-- |  Name	 : Log Exception                                                            	    |
	-- |  Description: The log_exception procedure logs all exceptions				                |
	-- =============================================================================================|
	gc_debug 		VARCHAR2(2);
	gn_request_id   fnd_concurrent_requests.request_id%TYPE;
	gn_user_id      fnd_concurrent_requests.requested_by%TYPE;
	gn_login_id    	NUMBER;
	gn_current_year NUMBER :=substr(EXTRACT(YEAR from sysdate), 4,4);

	PROCEDURE log_exception ( p_program_name       IN  VARCHAR2
							 ,p_error_location     IN  VARCHAR2
							 ,p_error_msg          IN  VARCHAR2)
	IS
	   ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;
	   ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;
	BEGIN
		XX_COM_ERROR_LOG_PUB.log_error(
										 p_return_code             => FND_API.G_RET_STS_ERROR
										,p_msg_count               => 1
										,p_application_name        => 'XXFIN'
										,p_program_type            => 'Custom Messages'
										,p_program_name            => p_program_name
										,p_attribute15             => p_program_name
										,p_program_id              => null
										,p_module_name             => 'PO'
										,p_error_location          => p_error_location
										,p_error_message_code      => null
										,p_error_message           => p_error_msg
										,p_error_message_severity  => 'MAJOR'
										,p_error_status            => 'ACTIVE'
										,p_created_by              => ln_user_id
										,p_last_updated_by         => ln_user_id
										,p_last_update_login       => ln_login
										);

	EXCEPTION
	WHEN OTHERS
	THEN
		fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
	END log_exception;

	/*********************************************************************
	* Procedure used to log based on gb_debug value or if p_force is TRUE.
	* Will log to dbms_output if request id is not set,
	* else will log to concurrent program log file.  Will prepend
	* timestamp to each message logged.  This is useful for determining
	* elapse times.
	*********************************************************************/
	PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
							   p_force     IN BOOLEAN DEFAULT FALSE)
	IS
	   lc_message   VARCHAR2 (4000) := NULL;
	BEGIN
		IF (gc_debug = 'Y' OR p_force)
		THEN
			lc_Message := P_Message;
			fnd_file.put_line (fnd_file.log, lc_Message);
			IF (   fnd_global.conc_request_id = 0
				OR fnd_global.conc_request_id = -1)
			THEN
				dbms_output.put_line (lc_message);
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS
		THEN
			NULL;
	END print_debug_msg;
	/*********************************************************************
	* Procedure used to out the text to the concurrent program.
	* Will log to dbms_output if request id is not set,
	* else will log to concurrent program output file.
	*********************************************************************/
	PROCEDURE print_out_msg (p_message IN VARCHAR2)
	IS
		lc_message   VARCHAR2 (4000) := NULL;
	BEGIN
		lc_message := p_message;
		fnd_file.put_line (fnd_file.output, lc_message);
		IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
		THEN
			dbms_output.put_line (lc_message);
		END IF;
	EXCEPTION
	WHEN OTHERS
	THEN
		NULL;
	END print_out_msg;
	-- +============================================================================================+
	-- |  Name  : send_output_email                                                                 |
	-- |  Description: Sends the CP Request output in email			                				|
	-- =============================================================================================|
	PROCEDURE send_output_email(l_request_id NUMBER, l_ret_code NUMBER)
	AS
		l_email_addr	VARCHAR2(4000);
		ln_request_id 	NUMBER;
		l_instance_name	VARCHAR2(30);
	BEGIN
		print_debug_msg ('Begin - Sending email',TRUE);
		SELECT sys_context('userenv','DB_NAME')
		INTO l_instance_name
		FROM dual;
		BEGIN
			SELECT 	target_value2||','||target_value3 INTO l_email_addr
			FROM  	xx_fin_translatedefinition xtd
				   ,xx_fin_translatevalues xtv
			WHERE 	xtd.translation_name 	= 'XX_AP_TRADE_INV_EMAIL'
			AND 	xtd.translate_id       	=  xtv.translate_id
			AND 	xtv.source_value1 		= 'RECEIPTS';
		EXCEPTION WHEN OTHERS THEN
		l_email_addr :=NULL;
		print_debug_msg ('Email Translation XX_AP_TRADE_INV_EMAIL not setup correctly for source_value1 PURCHASEORDER.'||substr(SQLERRM, 1, 500),TRUE);
		END;
		ln_request_id :=fnd_request.submit_request
												('XXFIN'
												, 'XXODROEMAILER'
												, NULL
												, TO_CHAR (SYSDATE + 1 / (24 * 60)
														  , 'YYYY/MM/DD HH24:MI:SS'
														   )
												 -- schedule 1 minute from now
												, FALSE
												, NULL
												, l_email_addr
												, l_instance_name||':'||TO_CHAR(sysdate,'DD-MON-YY')||':PO Receipt Interface Output'
												, 'Please review the attached program output for details and action items...'
												, 'Y'
												, l_request_id
											);
									   COMMIT;
		print_debug_msg ('End - Sent email for the output of the request_id '||ln_request_id,TRUE);
		EXCEPTION
		WHEN OTHERS THEN
		print_debug_msg ('Error in send_output_email: '||substr(SQLERRM, 1, 500),TRUE);
	END send_output_email;
	-- +============================================================================================+
	-- |  Name	 : mtl_transaction_int - RTV Consignment                                            |
	-- |  Description: Procedure to insert line data into line staging table                        |
	-- =============================================================================================|
	PROCEDURE mtl_transaction_int(p_errbuf       		OUT  VARCHAR2,
								  p_retcode      		OUT  VARCHAR2,
								  p_transaction_type_name 	 VARCHAR2,
								  p_inventory_item_id	     NUMBER,
								  p_organization_id		     NUMBER,
								  p_transaction_qty		     NUMBER,
								  p_transaction_cost	     NUMBER,
								  p_transaction_uom_code 	 VARCHAR2,
								  p_transaction_date	     DATE,
								  p_subinventory_code	     VARCHAR2,
								  p_transaction_source	     VARCHAR2,
								  p_vendor_site		         VARCHAR2,
								  p_original_rtv             VARCHAR2, -- Added as per Version 1.1
								  p_rga_number               VARCHAR2,
								  p_freight_carrier          VARCHAR2,
								  p_freight_bill             VARCHAR2,
								  p_vendor_prod_code         VARCHAR2,
								  p_sku                      VARCHAR2,
								  p_location                 VARCHAR2)
	IS
		CURSOR tran_type_cur(p_transaction_type_name VARCHAR2) IS
			SELECT mtt.transaction_type_id,mtt.transaction_action_id,mtt.transaction_source_type_id
			FROM  mtl_transaction_types mtt
			WHERE mtt.transaction_type_name = p_transaction_type_name;
			tran_type_rec tran_type_cur%ROWTYPE;
		CURSOR get_acct_values(p_organization_id NUMBER) IS
			SELECT segment1,segment2,segment4,segment5,segment6,segment7
			FROM  gl_code_combinations gcc,
				  mtl_parameters mp
			WHERE gcc.code_combination_id 	= mp.material_account
			AND mp.organization_id 			= p_organization_id;
		lc_error_message VARCHAR2(2000):= NULL;
		lc_segment1	  VARCHAR2(25)     := null;
		lc_segment2	  VARCHAR2(25)     := null;
		lc_segment4	  VARCHAR2(25)     := null;
		lc_segment5	  VARCHAR2(25)     := null;
		lc_segment6	  VARCHAR2(25)     := null;
		lc_segment7	  VARCHAR2(25)     := null;
		data_exception EXCEPTION;
	BEGIN
		OPEN tran_type_cur(p_transaction_type_name);
		FETCH tran_type_cur INTO tran_type_rec;
		CLOSE tran_type_cur;
		/*
		IF tran_type_rec.transaction_type_id IS NULL THEN
		  lc_error_message := 'Invalid transaction type name';
		  raise data_exception;
		END IF;
		*/
		OPEN get_acct_values(p_organization_id);
		FETCH get_acct_values
		INTO lc_segment1
			,lc_segment2
			,lc_segment4
			,lc_segment5
			,lc_segment6
			,lc_segment7;
	   CLOSE get_acct_values;
	   /*
		IF lc_segment1 IS NULL THEN
			lc_error_message := 'Error deriving material account for organization_id=['||TO_CHAR(p_organization_id)||']';
			raise data_exception;
		END IF;
	   */
		INSERT INTO mtl_transactions_interface(
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
						,dst_segment1
						,dst_segment2
						,dst_segment3
						,dst_segment4
						,dst_segment5
						,dst_segment6
						,dst_segment7
						,attribute_category
						,attribute1
						,attribute2
						,attribute3
						,attribute4
						,attribute5
						,attribute6
						,attribute7
						,attribute8)
			VALUES 		(mtl_material_transactions_s.nextval  	   	--transaction_header_id
						,'INVENTORY' 				   				--source_code
						,-1  					   					--source_header_id
						,-1  					   					--source_line_id
						,1  					   					--process_flag
						,3  					   					--transaction_mode
						,2  			        	   				--lock_flag
						,sysdate  				   					--last_update_date
						,-1				   	   						--last_updated_by (could filled by user_id)
						,sysdate  				   					--creation_date
						,-1  				   	   					--created_by (could filled by user_id)
						,p_inventory_item_id			   			--inventory_item_id
						,p_organization_id       	   	   			--organization_id 03077
						,p_transaction_qty		           			--transaction_quantity
						,p_transaction_cost          		   		--transaction_cost
						,p_transaction_qty      		   			--primary_quantity
						,p_transaction_uom_code			   			--transaction_uom_code
						,p_transaction_date		     	   			--discuss transaction_date?
						,p_subinventory_code		  	   			--subinventory_code
						,tran_type_rec.transaction_source_type_id  	--transaction_source_type_id
						,tran_type_rec.transaction_action_id  	   	--transaction_action_id
						,tran_type_rec.transaction_type_id   	   	--transaction_type_id
						,p_transaction_source
						,12101000
						,lc_segment1
						,lc_segment2
						,'12102000'
						,lc_segment4
						,lc_segment5
						,lc_segment6
						,lc_segment7
						,'WMS'
						,p_vendor_site
						,p_original_rtv
						,p_rga_number
						,p_freight_carrier
						,p_freight_bill
						,p_vendor_prod_code
						,p_sku
						,p_location);
		p_retcode := '0';
	EXCEPTION
	WHEN data_exception THEN
		p_retcode := '2';
		p_errbuf  := lc_error_message;
	WHEN others THEN
		p_retcode := '2';
		p_errbuf  := SUBSTR(SQLERRM,1,250);
	END mtl_transaction_int;
	-- +============================================================================================+
	-- |  Name	 : insert_line                                                               	|
	-- |  Description: Procedure to insert line data into line staging table                        |
	-- =============================================================================================|
	PROCEDURE insert_line(p_h_table     IN xx_po_pom_int_pkg.varchar2_table
						 ,p_l_table     IN xx_po_pom_int_pkg.varchar2_table
						 ,p_nfields     IN INTEGER
						 ,p_error_msg   OUT VARCHAR2
						 ,p_retcode     OUT VARCHAR2)
	IS
		h_table           xx_po_pom_int_pkg.varchar2_table;
		l_table    	      xx_po_pom_int_pkg.varchar2_table;
		ln_current_year   NUMBER;
	BEGIN
		h_table := p_h_table;
		l_table := p_l_table;
		SELECT SUBSTR(EXTRACT(YEAR FROM SYSDATE), 4,4)
		INTO ln_current_year
		FROM dual;
		INSERT
		INTO xx_po_rcv_trans_int_stg
				(record_id
				,ap_location
				,ap_keyrec
				,ap_po_number
				,ap_po_vendor
				,ap_receipt_num
				,ap_rcvd_date
				,ap_po_date
				,ap_ship_date
				,ap_frt_bill_no
				,ap_buyer_code
				,ap_freight_terms
				,ap_po_line_no
				,ap_sku
				,ap_vendor_item
				,ap_description
				,ap_rcvd_quantity
				,ap_rcvd_cost
				,ap_vendor_prodcd
				,ap_seq_no
				,source_system_ref
				,batch_id
				,record_status
				,error_description
				,request_id
				,created_by
				,creation_date
				,last_updated_by
				,last_update_date
				,last_update_login
				,attribute2
				,attribute3)
		VALUES (xx_po_rcv_trans_int_stg_s.nextval
				,h_table(2)						--ap_location
				,h_table(3)						--ap_keyrec
				,ltrim(h_table(6),'0')||'-'||lpad(ltrim(h_table(2),'0'),4,'0') --ap_po_number + ap_location
				,h_table(7)						--ap_po_vendor
				,h_table(2)||h_table(3)||l_table(14)||ln_current_year
				,h_table(9)						--ap_rcvd_date
				,h_table(10)					--ap_po_date
				,h_table(11)					--ap_ship_date
				,h_table(13)					--ap_frt_bill_no
				,h_table(15)					--ap_buyer_code
				,h_table(16)					--ap_freight_terms
				,l_table(6)						--ap_po_line_no
				,l_table(7)						--ap_sku
				,l_table(8)						--ap_vendor_item
				,l_table(9)						--ap_description
				,l_table(10)					--ap_rcvd_quantity
				,l_table(11)					--ap_rcvd_cost
				,l_table(12)					--ap_vendor_prodcd
				,l_table(14)					--ap_seq_no
				,h_table(6)						--ap_po_number
				,''								--batch_id
				,''								--record_status
				,''								--error_description
				,gn_request_id
				,gn_user_id
				,sysdate
				,gn_user_id
				,sysdate
				,gn_login_id
				,'NEW'
				,h_table(9)						--ap_rcvd_date
				);
	EXCEPTION
	WHEN others THEN
		p_retcode   := '2';
		p_error_msg := 'Error in XX_PO_RCV_INT_PKG.insert_line '||substr(sqlerrm,1,150);
	END insert_line;
	-- +============================================================================================+
	-- |  Name	 : load_staging                                                            	|
	-- |  Description: This procedure reads data from the file and inserts into staging tables      |
	-- |               XXPORCVSTG - XX PO RCV Interface Staging                                     |
	-- =============================================================================================|
	PROCEDURE load_staging(p_errbuf       OUT  VARCHAR2
						  ,p_retcode      OUT  VARCHAR2
						  ,p_filepath          VARCHAR2
						  ,p_file_name 	   VARCHAR2
						  ,p_debug             VARCHAR2)
	AS
		l_filehandle       			 UTL_FILE.FILE_TYPE;
		lc_filedir         			 VARCHAR2(200) 	:= p_filepath;
		lc_filename	      			 VARCHAR2(200)	:= p_file_name;
		lc_dirpath         			 VARCHAR2(500);
		lb_file_exist      			 BOOLEAN;
		ln_size            			 NUMBER;
		ln_block_size      			 NUMBER;
		lc_newline         			 VARCHAR2(4000);  -- Input line
		ln_max_linesize    			 BINARY_INTEGER  := 32767;
		ln_rec_cnt         			 NUMBER := 0;
		l_table 	      			 xx_po_pom_int_pkg.varchar2_table;
		h_table            			 xx_po_pom_int_pkg.varchar2_table;
		l_nfields 	      			 INTEGER;
		lc_error_msg       			 VARCHAR2(2000) := NULL;
		lc_error_loc	      		 VARCHAR2(2000) := 'XX_PO_RCV_INT_PKG.LOAD_STAGING';
		lc_retcode	      			 VARCHAR2(3)    := NULL;
		lc_rec_type        			 VARCHAR2(1)    := NULL;
		ln_count_hdr       			 NUMBER := 0;
		ln_count_lin       			 NUMBER := 0;
		ln_count_err       			 NUMBER := 0;
		ln_count_tot       			 NUMBER := 0;
		ln_conc_file_copy_request_id NUMBER;
		lc_dest_file_name  			 VARCHAR2(200);
		lc_curr_key	      			 VARCHAR2(30) 	:= NULL;
		lc_prev_key	    			 VARCHAR2(30) 	:= NULL;
		nofile             			 EXCEPTION;
		data_exception     			 EXCEPTION;
		lc_instance_name			 VARCHAR2(30);
		lb_complete        		   	 BOOLEAN;
		lc_phase           		   	 VARCHAR2(100);
		lc_status          		   	 VARCHAR2(100);
		lc_dev_phase       		   	 VARCHAR2(100);
		lc_dev_status      		   	 VARCHAR2(100);
		lc_message         		   	 VARCHAR2(100);
		CURSOR get_dir_path IS
			SELECT directory_path
			FROM all_directories
			WHERE directory_name = p_filepath;
	BEGIN
		gc_debug	  := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME')),1,8)
		INTO lc_instance_name
		FROM dual;
		print_debug_msg ('Start load_staging from File:'||p_file_name||' Path:'||p_filepath,TRUE);
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
					exit;
				END IF;
				print_debug_msg ('Processing Line:'||lc_newline,FALSE);
				--parse the line
				xx_po_pom_int_pkg.parse(lc_newline,l_table,l_nfields,'|',lc_error_msg,lc_retcode);
				IF lc_retcode = '2' THEN
					RAISE data_exception;
				END IF;
				print_debug_msg ('Parsing Complete',FALSE);
				FOR I IN 1..L_TABLE.COUNT
				LOOP
					print_debug_msg (l_table(i),FALSE);
				END LOOP;
				lc_curr_key := l_table(3);
				lc_rec_type := l_table(5);
				IF NVL(lc_prev_key,'NN') <> lc_curr_key
				THEN
					IF NVL(lc_rec_type,'N') <> 'A'
					THEN
						print_debug_msg ('ERROR - File data not in sequence, cannot process',TRUE);
						lc_error_msg := 'File data not in sequence, cannot process';
					RAISE data_exception;
				END IF;
				lc_prev_key := lc_curr_key;
				END IF;
				IF lc_rec_type IS NOT NULL
				THEN
					print_debug_msg ('Save header record',FALSE);
					h_table := l_table;
					ln_count_hdr := ln_count_hdr + 1;
				ELSE
					print_debug_msg ('Insert Line',FALSE);
					insert_line(h_table,l_table,l_nfields,lc_error_msg,lc_retcode);
					IF lc_retcode = '2' THEN
						RAISE data_exception;
					END IF;
					ln_count_lin := ln_count_lin + 1;
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
		print_out_msg('OD: PO RCV Interface Staging Program');
		print_out_msg('================================================ ');
		print_out_msg('No. of header records processed:'||TO_CHAR(ln_count_hdr));
		print_out_msg('No. of line records loaded  :'||TO_CHAR(ln_count_lin));
		print_out_msg(' ');
		-- print_out_msg('Total No. of records processed :'||TO_CHAR(ln_count_tot));
		dbms_lock.sleep(5);
		OPEN get_dir_path;
		FETCH get_dir_path
		INTO lc_dirpath;
		CLOSE get_dir_path;
		print_debug_msg('Calling the Common File Copy to move the Inbound file to AP Invoice folder',TRUE);
		lc_dest_file_name := '/app/ebs/ebsfinance/'||lc_instance_name||'/apinvoice/'
												   || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
												   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
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
			lb_complete :=fnd_concurrent.wait_for_request (
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
		lc_dest_file_name := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
													   || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.TXT';
		ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
																   'XXCOMFILCOPY',
																   '',
																   '',
																   FALSE,
																   lc_dirpath||'/'||lc_filename,   --Source File Name
																   lc_dest_file_name,              --Dest File Name
																   '',
																   '',
																   'Y'   --Deleting the Source File
																	);
		COMMIT;
		EXCEPTION
		WHEN nofile
		THEN
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
			print_debug_msg ('ERROR - '||substr(sqlerrm,1,250),TRUE);
			p_retcode := 2;
	END load_staging;
	-- +============================================================================================+
	 -- |  Name	  : report_master_program_stats                                                   |
	 -- |  Description: This procedure print stats of master program                                 |
	 -- =============================================================================================|
	PROCEDURE report_master_program_stats
	AS
		CURSOR c_staging_requests IS
			SELECT distinct request_id
			FROM 	xx_po_rcv_trans_int_stg
			WHERE 	attribute2 = 'NEW';
		CURSOR c_req_date(c_request_id NUMBER) IS
			SELECT 	TO_CHAR(actual_start_date, 'DD-MON-YY')
			FROM 	fnd_concurrent_requests fcr
			WHERE 	fcr.request_id = c_request_id;
		CURSOR req_trans_count_cur(c_request_id NUMBER) IS
			SELECT stg.attribute1 vendor_site_category
				 , stg.attribute5
				 , stg.record_status
				 , count(1) count
			FROM  xx_po_rcv_trans_int_stg stg
			WHERE stg.request_id = c_request_id
			GROUP BY  stg.attribute1
					, stg.attribute5
					, stg.record_status;
		CURSOR trans_count_cur IS
			SELECT stg.attribute1 vendor_site_category
				 , stg.record_status
				 , count(1) count
			FROM  xx_po_rcv_trans_int_stg stg
			WHERE EXISTS (SELECT 'x'
						FROM fnd_concurrent_requests req
						WHERE req.parent_request_id  = gn_request_id
						AND to_number(req.argument1) = stg.batch_id)
			GROUP BY stg.attribute1, stg.record_status;
		TYPE stats IS TABLE OF req_trans_count_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		stats_tab   STATS;
		indx		NUMBER;
		CURSOR trans_detail_cur IS
		SELECT   ap_po_number
				,ap_location
				,ap_keyrec
				,ap_po_date
				,ap_po_line_no
				,ap_sku
				,stg1.UNIT_PRICE unit_cost
				,stg1.EXTENDED_COST line_cost
				,stg.ap_location||stg.ap_keyrec||stg.ap_seq_no||gn_current_year ap_receipt_num
				,stg.error_description
				,stg.attribute1 vendor_site_category
				,stg.ap_po_vendor
				,stg.creation_date
		FROM  xx_po_rcv_trans_int_stg stg, (SELECT unit_price,
  extended_cost,
  po_number,
  line_num,
  MAX(creation_date)
FROM xx_po_pom_lines_int_stg
WHERE record_status='I'
GROUP BY unit_price,
  extended_cost,
  po_number,
  line_num) stg1  --added extra table for NAIT-49797
		WHERE EXISTS (SELECT 'x'
					  FROM fnd_concurrent_requests req
					  WHERE req.parent_request_id  = gn_request_id
					  AND to_number(req.argument1) = stg.batch_id)
		AND stg.record_status ='E'
		and  stg.ap_po_number=stg1.po_number(+)
        and TRIM(LEADING 0 From stg.ap_po_line_no) =stg1.LINE_num(+)

		ORDER BY  stg.creation_date desc
				, stg.ap_po_number  asc
				, stg.ap_location   asc
				, stg.ap_keyrec 	asc
				, ap_po_line_no 	asc;
		TYPE trans_detail IS TABLE OF trans_detail_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		trans_detail_tab   trans_detail;
		t_indx	       NUMBER;
		CURSOR rtv_cur IS
			SELECT rti.group_id
				  ,rhi.receipt_num
				  ,poi.interface_type
				  ,rti.document_num
				  ,rti.attribute1 sku
				  ,NVL(poi.error_message_name,'NULL')
				  ,NVL(poi.error_message,'NULL') error_description
			 FROM  po_interface_errors poi
				  ,rcv_transactions_interface rti
				  ,rcv_headers_interface rhi
			WHERE poi.interface_line_id = rti.interface_transaction_id
			  AND rhi.header_interface_id= rti.header_interface_id
			  AND EXISTS (SELECT 'x'
						  FROM fnd_concurrent_requests req
						  WHERE req.parent_request_id = gn_request_id
							AND to_number(req.argument1) = rti.group_id)
		   ORDER BY rti.document_num,rti.attribute1;
		TYPE rtv IS TABLE OF rtv_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		rtv_tab   		rtv;
		r_indx	       	NUMBER;
		ln_success_cnt          NUMBER;
		ln_error_cnt            NUMBER;
		ln_interface_err_cnt    NUMBER;
		ln_skip_cnt				NUMBER;
		ln_other_err_cnt        NUMBER;
		ln_consg_success_cnt    NUMBER;
		ln_consg_error_cnt      NUMBER;
		ln_consg_skip_cnt       NUMBER;
		ln_consg_other_err_cnt  NUMBER;
		ln_tot_rcv_cnt			NUMBER;
		ln_tot_new_cnt			NUMBER;
		ln_tot_consg_cnt		NUMBER;
		TYPE l_num_tab IS TABLE OF NUMBER;
		l_stage_requests  		l_num_tab;
		ln_new_req_cnt			NUMBER;
		l_stage_request_date	VARCHAR2(10);
	BEGIN
		print_debug_msg ('Report Master Program Stats',FALSE);
		print_out_msg('OD PO Receipt Interface Summary');
		print_out_msg('===============================');
	-- Get the list of request_id's of staging program to use it in report_master_program_stats()
		OPEN c_staging_requests;
		FETCH c_staging_requests BULK COLLECT INTO l_stage_requests;
		CLOSE c_staging_requests;
		ln_new_req_cnt := l_stage_requests.count;
		IF ln_new_req_cnt = 0 THEN
			print_out_msg('No PO Receipt Data, from POM, is loaded recently.');
		END IF;
		FOR i IN 1.. ln_new_req_cnt
		LOOP
			print_debug_msg ('Report for request_id '||l_stage_requests(i),TRUE);
			OPEN c_req_date(l_stage_requests(i));
			FETCH c_req_date
			INTO l_stage_request_date;
			CLOSE c_req_date;
			-- Generally, only one new load request exists. For Exception cases, we will display the request_id to differentiate
			--IF ln_new_req_cnt > 1 THEN
				print_out_msg ('OD PO Receipt Summary Report for the oracle load request '||l_stage_requests(i)||' on '||l_stage_request_date||':');
			--END IF;
			ln_success_cnt          := 0;
			ln_error_cnt            := 0;
			ln_interface_err_cnt    := 0;
			ln_skip_cnt		        := 0;
			ln_other_err_cnt        := 0;
			ln_consg_success_cnt    := 0;
			ln_consg_error_cnt      := 0;
			ln_consg_skip_cnt       := 0;
			ln_consg_other_err_cnt  := 0;
			ln_tot_rcv_cnt			:= 0;
			ln_tot_new_cnt			:= 0;
			ln_tot_consg_cnt		:= 0;
			OPEN req_trans_count_cur(l_stage_requests(i));
			FETCH req_trans_count_cur BULK COLLECT INTO stats_tab;
			CLOSE req_trans_count_cur;
			FOR indx IN 1..stats_tab.COUNT
			LOOP
				IF stats_tab(indx).vendor_site_category = 'NON-CONSG' THEN
					IF stats_tab(indx).attribute5 = 'Internal Vendor - skip PO processing' THEN
						ln_skip_cnt := ln_skip_cnt	+ stats_tab(indx).count;
					ELSE
						ln_tot_new_cnt := ln_tot_new_cnt + stats_tab(indx).count;
						IF stats_tab(indx).record_status = 'I' THEN
							ln_success_cnt := ln_success_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status = 'E' THEN
							ln_error_cnt := ln_error_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status = 'IE' THEN
							ln_interface_err_cnt := ln_interface_err_cnt + stats_tab(indx).count;
						ELSE
							-- Generally, below other status count doesn't come. In case, if it comes, it shows and developers can fix it.
							ln_other_err_cnt := ln_other_err_cnt + stats_tab(indx).count;
							print_debug_msg ('report_master_program_stats()- record exists for other status : '||stats_tab(indx).record_status,TRUE);
						END IF;
					END IF;
				ELSE
					IF stats_tab(indx).attribute5 = 'Internal Vendor - skip PO processing' THEN
						ln_consg_skip_cnt := ln_consg_skip_cnt + stats_tab(indx).count;
					ELSE
						ln_tot_consg_cnt := ln_tot_consg_cnt + stats_tab(indx).count;
						IF stats_tab(indx).record_status = 'I' THEN
							ln_consg_success_cnt := ln_consg_success_cnt + stats_tab(indx).count;
						ELSIF stats_tab(indx).record_status = 'E' THEN
							ln_consg_error_cnt := ln_consg_error_cnt + stats_tab(indx).count;
						ELSE
							-- Generally, below other status count doesn't come. In case, if it comes, it shows and developers can fix it.
							ln_consg_other_err_cnt := ln_consg_other_err_cnt + stats_tab(indx).count;
							print_debug_msg ('report_master_program_stats()- record exists for other status : '||stats_tab(indx).record_status,TRUE);
						END IF;
					END IF;
				END IF;
			END LOOP;
			ln_tot_rcv_cnt 	:= ln_tot_new_cnt + ln_tot_consg_cnt;
			ln_skip_cnt 	:= ln_skip_cnt + ln_consg_skip_cnt;
			ln_tot_rcv_cnt	:= ln_tot_rcv_cnt	+	ln_skip_cnt;
			print_out_msg('');
			print_out_msg(RPAD('Total PO Receipt Transactions(receipt and consignment)', 55)||' '||RPAD(NVL(ln_tot_rcv_cnt,0),10));
			print_out_msg('');
			print_out_msg(RPAD('Total No of Receipts Skipped are ',35)||' '||RPAD(NVL(ln_skip_cnt,0),10));
			print_out_msg('');
			print_out_msg(RPAD('Total New PO Receipt Transactions', 35)||' '||RPAD(NVL(ln_tot_new_cnt,0),10));
			print_out_msg(RPAD('     PO Receipt Transactions - Receipts Created Successfully', 70)||' '||RPAD(NVL(ln_success_cnt,0),10));
			print_out_msg(RPAD('     PO Receipt Transactions - Errors(Custom Validations)', 70)||' '||RPAD(NVL(ln_error_cnt,0),10));
			print_out_msg(RPAD('     PO Receipt Transactions - Errors(Standard Validations)', 70)||' '||RPAD(NVL(ln_interface_err_cnt,0),10));
			IF ln_other_err_cnt <> 0 THEN
				print_out_msg(RPAD('     PO Receipt Transactions - Other Status count', 70)||' '||RPAD(ln_other_err_cnt,10));
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
		print_out_msg('OD PO Receipt Interface Exception Details');
		print_out_msg('=========================================');
		print_out_msg(RPAD('Created On',10)||' '||RPAD('Supplier Type',13)||' '||RPAD('PO Number',15)||' '||RPAD('Key Rec',10)||' '||RPAD('Receipt Num',15)||' '||RPAD('Vendor',12)||' '||RPAD('PO Date',12)||' '||RPAD('Line',4)||' '||RPAD('Sku',15)||' '||RPAD('Cost',10)||''||RPAD('line Cost',10)||''||RPAD('Error Details',150));
		print_out_msg(RPAD('=',10,'=')||' '||RPAD('=',13,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',12,'=')||' '||RPAD('=',12,'=')||' '||RPAD('=',4,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',150,'='));
		OPEN trans_detail_cur;
		FETCH trans_detail_cur BULK COLLECT INTO trans_detail_tab;
		CLOSE trans_detail_cur;
		FOR t_indx IN 1..trans_detail_tab.COUNT
		LOOP
			print_out_msg(RPAD(trans_detail_tab(t_indx).creation_date,10)||' '||
						  RPAD(trans_detail_tab(t_indx).vendor_site_category,13)||' '||
						  RPAD(trans_detail_tab(t_indx).ap_po_number,15)||' '||
						  RPAD(trans_detail_tab(t_indx).ap_keyrec,10)||' '||RPAD(trans_detail_tab(t_indx).ap_receipt_num,15)||' '||
						  RPAD(trans_detail_tab(t_indx).ap_po_vendor,13)||' '||
						  NVL(RPAD(trans_detail_tab(t_indx).ap_po_date,10),CHR(9)||'    ')||'  '||
						  RPAD(trans_detail_tab(t_indx).ap_po_line_no,4,' ')||' '||RPAD(trans_detail_tab(t_indx).ap_sku,15,' ')||' '||
						  RPAD(nvl(to_char(trans_detail_tab(t_indx).unit_cost),' '),10)||' '||
						  RPAD(nvl(to_char(trans_detail_tab(t_indx).line_cost),' '),10)||' '||
						  RPAD(trans_detail_tab(t_indx).error_description,150));
		END LOOP;
		print_out_msg(' ');
		print_out_msg(' ');
		print_out_msg('Receving Transaction Processor Errors');
		print_out_msg('=====================================');
		print_out_msg(RPAD('Supplier Type',13)||' '||RPAD('Receipt Num',15)||' '||RPAD('Document Number',15)||' '||RPAD('Sku',15)||' '||RPAD('Error Details',150));
		print_out_msg(RPAD('=',13,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',150,'='));
		OPEN rtv_cur;
		FETCH rtv_cur BULK COLLECT INTO rtv_tab;
		CLOSE rtv_cur;
		FOR r_indx IN 1..rtv_tab.COUNT
		LOOP
			print_out_msg(RPAD('NON-CONSG',13)||' '||RPAD(rtv_tab(r_indx).receipt_num,15)||' '||RPAD(NVL(rtv_tab(r_indx).document_num,' '),15)||' '||RPAD(NVL(rtv_tab(r_indx).sku,' '),15)||' '||
						  RPAD(rtv_tab(r_indx).error_description,150));
		END LOOP;
		-- Reset to NULL means these records are touched atleast once and these doesn't include in the Summary Report section count.
		UPDATE xx_po_rcv_trans_int_stg
		SET attribute2 = NULL
		WHERE attribute2 = 'NEW'
		AND record_status IS NOT NULL;
		print_debug_msg ('Total no of records to set attribute2 to NULL are '||SQL%ROWCOUNT, TRUE);
		COMMIT;
	EXCEPTION
		WHEN others THEN
			print_debug_msg ('Report Master Program Stats failed'||substr(sqlerrm,1,150),TRUE);
			print_out_msg ('Report Master Program stats failed'||substr(sqlerrm,1,150));
	END report_master_program_stats;
	 -- +============================================================================================+
	 -- |  Name	  : update_staging_record_status                                                 	 |
	 -- |  Description: This procedure updates record_status in staging per po interface status.     |
	 -- =============================================================================================|
	PROCEDURE update_staging_record_status(p_batch_id NUMBER)
	AS
		ln_count NUMBER;
	BEGIN
		print_debug_msg ('Update record_status in staging incase of error in PO Standard Interface',FALSE);
		UPDATE xx_po_rcv_trans_int_stg stg
		SET  stg.record_status = 'IE'
		WHERE EXISTS
				 (SELECT 1
				  FROM rcv_transactions_interface rti
				  WHERE 1=1
					AND rti.attribute8=stg.ap_location||stg.ap_keyrec||stg.ap_seq_no||gn_current_year||'|'||stg.ap_po_number||'|'||to_number(stg.ap_po_line_no)||'|'||stg.record_id||'|'||p_batch_id
				 )
		AND stg.batch_id = p_batch_id
		AND record_status = 'I';
		ln_count:= SQL%ROWCOUNT;
		print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status IE',FALSE);
		/**
		UPDATE xx_po_rcv_trans_int_stg stg
		SET  stg.record_status = 'I'
		WHERE EXISTS
				 (SELECT 1 from rcv_headers_interface rhi
				  WHERE rhi.receipt_num=stg.ap_location||stg.ap_keyrec||stg.ap_seq_no||gn_current_year
				  AND processing_status_code='SUCCESS'
				  AND rhi.group_id=stg.batch_id)
		 AND stg.batch_id = p_batch_id
		 AND record_status is NULL;
		ln_count:= SQL%ROWCOUNT;
		print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status I',FALSE);
		-- MTL or Consignment
		UPDATE xx_po_rcv_trans_int_stg stg
		SET  stg.record_status = 'I'
		WHERE EXISTS
				 (SELECT 1 from mtl_transactions_interface mti
				  WHERE mti.attribute2=p_batch_id||'-'||stg.ap_location||stg.ap_keyrec||stg.ap_seq_no||gn_current_year||'-'||l_header_tab(indx).ap_po_number||'-'||po_line_rec.line_num
				 )
		AND stg.batch_id = p_batch_id
		AND record_status is NULL;
		ln_count:= SQL%ROWCOUNT;
		print_debug_msg(TO_CHAR(ln_count)|| ' header record(s) updated with error status I',FALSE);
		**/
	END update_staging_record_status;
	 -- +============================================================================================+
	 -- |  Name	  : print_child_program_stats                                                    |
	 -- |  Description: This procedure print stats of child program                                  |
	 -- =============================================================================================|
	PROCEDURE report_child_program_stats(p_batch_id 	NUMBER)
	AS
		CURSOR rcv_trans_count_cur IS
			SELECT count(*) count
				  ,DECODE(record_status,'E','Error','I','Interfaced',record_status) record_status
			FROM  xx_po_rcv_trans_int_stg stg
			WHERE batch_id = p_batch_id
			AND EXISTS
					(SELECT 1 from rcv_headers_interface rhi
						WHERE rhi.receipt_num=stg.ap_location||stg.ap_keyrec||stg.ap_seq_no||substr(EXTRACT(YEAR from sysdate), 4,4)
						AND rhi.group_id=stg.batch_id)
			GROUP BY record_status;
		TYPE stats IS TABLE OF rcv_trans_count_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		stats_tab   STATS;
		indx		NUMBER;
	BEGIN
		print_debug_msg ('Report Child Program Stats',FALSE);
		print_out_msg('OD PO RCV Inbound Interface(Child) for Batch '||TO_CHAR(p_batch_id));
		print_out_msg('========================================================== ');
		print_out_msg(RPAD('Record Type',12)||' '||RPAD('Record Status',15)||' '||RPAD('Count',10));
		print_out_msg(RPAD('=',12,'=')||' '||RPAD('=',15,'=')||' '||rpad('=',10,'='));
		OPEN rcv_trans_count_cur;
		FETCH rcv_trans_count_cur BULK COLLECT INTO stats_tab;
		CLOSE rcv_trans_count_cur;
		FOR indx IN 1..stats_tab.COUNT
		LOOP
			print_out_msg(RPAD('RCV Transactions',12)||' '||RPAD(stats_tab(indx).record_status,15)||' '||RPAD(stats_tab(indx).count,10));
		END LOOP;
	EXCEPTION
	WHEN others THEN
		print_debug_msg ('Report Child Program Stats failed'||substr(sqlerrm,1,150),TRUE);
	END report_child_program_stats;
	 -- +============================================================================================+
	 -- |  Name	   : child_request_status                                                        |
	 -- |  Description : This function is used to return the status of the child requests            |
	 -- =============================================================================================|
	FUNCTION child_request_status RETURN VARCHAR2 IS
		CURSOR get_conc_status IS
		SELECT status_code
		FROM fnd_concurrent_requests
		WHERE parent_request_id = gn_request_id
		AND status_code in('E','G');
		lc_status_code VARCHAR2(15) := NULL;
	BEGIN
		print_debug_msg ('Checking child_request_status',FALSE);
		lc_status_code := null;
		OPEN get_conc_status;
		FETCH get_conc_status INTO lc_status_code;
		CLOSE get_conc_status;
		IF lc_status_code IS NOT NULL THEN
			print_debug_msg('One or more child program completed in error or warning.',TRUE);
			RETURN 'G'; -- Warning
		ELSE
			RETURN 'C'; -- Normal
		END IF;
	END child_request_status;
	 -- +============================================================================================+
	 -- |  Name	  : interface_child                                                              |
	 -- |  Description: This procedure reads data from the staging and loads into PO interface       |
	 -- |		    OD PO RCV Inbound Interface(Child) 						 |
	 -- =============================================================================================|
	PROCEDURE interface_child(p_errbuf        OUT  VARCHAR2
							  ,p_retcode       OUT  VARCHAR2
							  ,p_batch_id           NUMBER
							  ,p_debug              VARCHAR2)
	AS
		--Cursor to select all the distinct PO Number for the batch
		CURSOR header_cur IS
			SELECT 	  stg.ap_po_number
					 ,stg.ap_location
					 ,stg.ap_keyrec
					 ,stg.ap_receipt_num
					 ,stg.ap_rcvd_date
					 ,stg.ap_ship_date
					 ,stg.ap_po_vendor
					 ,stg.ap_seq_no
					 ,po.po_header_id
					 ,po.vendor_id
					 ,po.vendor_site_id
					 ,po.org_id
					 ,DECODE(po.org_id,404,'US_USD_P',403,'CA_CAD_P',po.org_id) SOB_NAME
					 ,po.authorization_status
					 ,stg.attribute3
				FROM (SELECT distinct ap_po_number
							 ,ap_keyrec
							 ,ap_seq_no
							 ,ap_location
							 ,ap_po_vendor
							 ,ap_receipt_num
							 ,ap_rcvd_date
							 ,ap_ship_date
							 ,attribute3
						FROM xx_po_rcv_trans_int_stg
					   WHERE batch_id = p_batch_id
						 AND record_status IS NULL) stg
					 ,po_headers_all po
			WHERE stg.ap_po_number = po.segment1(+);
		TYPE header IS TABLE OF header_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		CURSOR trans_cur (p_ap_po_number VARCHAR2
						, p_ap_keyrec 	 VARCHAR2
						, p_ap_seq_no 	 VARCHAR2
						, p_ap_location  VARCHAR2
						, p_ap_po_vendor VARCHAR2
						, p_ap_rcvd_date VARCHAR2
						, p_ap_ship_date VARCHAR2 ) IS
			SELECT 	  to_number(stg.ap_rcvd_quantity) ap_rcvd_quantity
					 ,to_number(stg.ap_rcvd_cost) ap_rcvd_cost
					 ,stg.ap_po_line_no
					 ,stg.record_status
					 ,stg.error_description
					 ,stg.record_id
					 ,stg.ap_sku
				 FROM  xx_po_rcv_trans_int_stg stg
				WHERE stg.batch_id =  p_batch_id
				  AND stg.record_status IS NULL
				  AND stg.ap_po_number = p_ap_po_number
				  AND stg.ap_keyrec = p_ap_keyrec
				  AND stg.ap_seq_no = p_ap_seq_no
				  AND stg.ap_location = p_ap_location
				  AND stg.ap_po_vendor = p_ap_po_vendor
				  AND stg.ap_rcvd_date = p_ap_rcvd_date
				  AND (stg.ap_ship_date is NULL or stg.ap_ship_date = p_ap_ship_date);
		TYPE trans IS TABLE OF trans_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		CURSOR po_line_cur(p_po_header_id NUMBER,p_po_line_num NUMBER) IS
			SELECT pl.org_Id,
				   pl.po_header_id,
				   pl.item_id,
				   pl.item_description,
				   pl.po_line_id,
				   pl.line_num,
				   pll.quantity,
				   pl.unit_meas_lookup_code,
				   NVL(muom.uom_code,pl.unit_meas_lookup_code) uom_code,
				   mp.organization_code,
				   mp.organization_id,
				   pll.line_location_id,
				   pll.closed_code,
				   pll.quantity_received,
				   pll.cancel_flag,
				   pll.shipment_num,
				   pda.destination_type_code,
				   pda.deliver_to_person_id,
				   pda.deliver_to_location_id,
				   pda.destination_subinventory,
				   pda.destination_organization_id
			  FROM   po_lines_all pl,
					 po_line_locations_all pll,
					 mtl_parameters mp,
					 po_distributions_all pda,
					 mtl_units_of_measure muom
			WHERE pl.po_header_id = p_po_header_id
			  AND pl.line_num = p_po_line_num
			  AND pl.unit_meas_lookup_code = muom.unit_of_measure(+)
			  AND pl.po_line_id   = pll.po_line_id
			  AND pll.line_location_id = pda.line_location_id
			  AND pll.ship_to_organization_id = mp.organization_id;
			po_line_rec po_line_cur%ROWTYPE;
		CURSOR po_misship_line_cur(p_po_header_id NUMBER,p_item NUMBER) IS
			SELECT pl.org_Id,
				   pl.po_header_id,
				   pl.item_id,
				   pl.item_description,
				   pl.po_line_id,
				   pl.line_num,
				   pll.quantity,
				   pl.unit_meas_lookup_code,
				   NVL(muom.uom_code,pl.unit_meas_lookup_code) uom_code,
				   mp.organization_code,
				   mp.organization_id,
				   pll.line_location_id,
				   pll.closed_code,
				   pll.quantity_received,
				   pll.cancel_flag,
				   pll.shipment_num,
				   pda.destination_type_code,
				   pda.deliver_to_person_id,
				   pda.deliver_to_location_id,
				   pda.destination_subinventory,
				   pda.destination_organization_id
			FROM   po_lines_all pl,
				   po_line_locations_all pll,
				   mtl_parameters mp,
				   po_distributions_all pda,
				   mtl_units_of_measure muom,
				   mtl_system_items_b msi
			WHERE pl.po_header_id 			= p_po_header_id
			AND pl.unit_meas_lookup_code 	= muom.unit_of_measure(+)
			AND pl.quantity 				= 0.0000000001
			AND pl.po_line_id 				= pll.po_line_id
			AND pll.line_location_id 		= pda.line_location_id
			AND msi.inventory_item_id 		= pl.item_id
			AND msi.organization_id 		= pll.ship_to_organization_id
			AND msi.segment1 				= p_item
			AND pll.ship_to_organization_id = mp.organization_id;
		CURSOR check_vendor_cur(p_vendor_site_code VARCHAR2) IS
			SELECT 	 supa.vendor_id
					,supa.vendor_site_id
					,supa.org_id
					,supa.attribute8 vendor_site_category
			FROM ap_supplier_sites_all supa
			WHERE ltrim(supa.vendor_site_code_alt,'0') 	= ltrim(p_vendor_site_code,'0')
			AND supa.purchasing_site_flag 				= 'Y'
			AND NVL(supa.inactive_date,sysdate) 		>= trunc(sysdate);
		CURSOR check_vendor_site_id_cur(p_vendor_site_id NUMBER) IS
			SELECT 	supa.attribute8 vendor_site_category
				  , vendor_site_code_alt
			FROM ap_supplier_sites_all supa
			WHERE 1=1
			AND supa.vendor_site_id = p_vendor_site_id;
		CURSOR check_item_cur(p_item VARCHAR2
							 ,p_organization_id NUMBER) IS
			SELECT inventory_item_id
			FROM  mtl_system_items_b
			WHERE segment1 			= p_item
			AND organization_id 	= p_organization_id;
		CURSOR check_inv_period_cur(p_organization_id NUMBER
								  , p_rcvd_date DATE) IS
			SELECT oap.open_flag
			FROM org_acct_periods oap ,
				 org_organization_definitions ood
			WHERE oap.organization_id = p_organization_id
			AND oap.organization_id   = ood.organization_id
			AND (p_rcvd_date BETWEEN TRUNC(oap.period_start_date) AND TRUNC (oap.schedule_close_date));
		CURSOR check_period_cur( p_appl_id NUMBER
							   , p_short_name VARCHAR2
							   , p_rcvd_date DATE) IS
			SELECT gps.closing_status
			FROM  gl_period_statuses gps
				, gl_ledgers gl
			WHERE application_id	=p_appl_id
			AND gl.short_name		=p_short_name
			AND gps.ledger_id		=gl.ledger_id
			AND (p_rcvd_date BETWEEN TRUNC(start_date) AND TRUNC (end_date));
		CURSOR get_acct_values(p_organization_id NUMBER) IS
			SELECT 	segment1
				   ,segment2
				   ,segment4
				   ,segment5
				   ,segment6
				   ,segment7
				   ,code_combination_id
			FROM 	gl_code_combinations gcc,
					mtl_parameters mp
			WHERE gcc.code_combination_id 	= mp.material_account
			AND mp.organization_id 			= p_organization_id;
		CURSOR org_cur IS
			SELECT distinct org_id
			FROM rcv_headers_interface
			WHERE group_id 	= p_batch_id
			AND org_id IS NOT NULL;
		TYPE org IS TABLE OF org_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		l_header_tab 				HEADER;
		l_trans_tab 				TRANS;
		l_org_tab 					ORG;
		indx              			NUMBER;
		l_indx              		NUMBER;
		o_indx						NUMBER;
		ln_batch_size				NUMBER := 250;
		lc_trans_validation 		VARCHAR2(30);
		lc_uom_code					VARCHAR2(30);
		ln_item_id					NUMBER;
		lc_error_msg        		VARCHAR2(1000);
		lc_error_loc        		VARCHAR2(100) := 'XX_PO_RCV_INT_PKG.INTERFACE_CHILD';
		lc_req_data         		VARCHAR2(30);
		ln_job_id					NUMBER;
		ln_interface_transaction_id NUMBER;
		ln_header_interface_id		NUMBER;
		ln_child_request_status     VARCHAR2(1) := NULL;
		ln_err_count				NUMBER;
		ln_error_idx				NUMBER;
		ln_seq						NUMBER;
	 -- ln_vendor_id				NUMBER;
	 -- ln_vendor_site_id			NUMBER;
	 -- ln_org_id					NUMBER;
		lc_vendor_site_category     VARCHAR2(150);
		ln_trx_type_id 				NUMBER;
		ln_trx_act_id 				NUMBER;
		ln_trx_source_id 			NUMBER;
		lc_trx_type_name 			VARCHAR2(100);
		lc_segment1					VARCHAR2(25);
		lc_segment2					VARCHAR2(25);
		lc_segment4					VARCHAR2(25);
		lc_segment5					VARCHAR2(25);
		lc_segment6					VARCHAR2(25);
		lc_segment7					VARCHAR2(25);
		data_exception      		EXCEPTION;
		ln_current_year				NUMBER;
		ln_rcpt_cnt					NUMBER;
		ln_ccid         			NUMBER;
		lc_processing_status_code 	VARCHAR2(100);
		lc_po_vendor_site_code 		ap_supplier_sites_all.vendor_site_code_alt%TYPE;
		lc_result 					VARCHAR(1);
		lc_period_stat 				VARCHAR2(10);
		lc_inv_period_stat 			VARCHAR2(10);
	BEGIN
		gc_debug	  := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		print_debug_msg ('Start interface_child' ,TRUE);
		--Get value of global variable. It is null initially.
		lc_req_data   := fnd_conc_global.request_data;
		SELECT SUBSTR(EXTRACT(YEAR FROM SYSDATE), 4,4) INTO ln_current_year FROM dual;
		-- req_date will be null for first time parent scan by concurrent manager.
		IF (lc_req_data IS NULL) THEN
			SELECT 	mtt.transaction_type_id
				   ,mtt.transaction_action_id
				   ,mtt.transaction_source_type_id
			INTO ln_trx_type_id
				,ln_trx_act_id
				,ln_trx_source_id
			FROM mtl_transaction_types mtt
			WHERE mtt.transaction_type_name = 'Miscellaneous receipt';
			OPEN header_cur;
			LOOP
				FETCH header_cur BULK COLLECT INTO l_header_tab LIMIT ln_batch_size;
				EXIT WHEN l_header_tab.COUNT = 0;
				FOR indx IN l_header_tab.FIRST..l_header_tab.LAST
				LOOP
					BEGIN
						--Validate header
						print_debug_msg ('Check if PO exists',FALSE);
						IF l_header_tab(indx).po_header_id IS NULL THEN
							print_debug_msg ('PO does not exists for Receipt# '||l_header_tab(indx).ap_receipt_num, FALSE);
							lc_error_msg := 'PO does not exists for Receipt# '||l_header_tab(indx).ap_receipt_num;
							RAISE data_exception;
						END IF;
						print_debug_msg ('Start Validation - Period Status',FALSE);
						OPEN check_period_cur(101,l_header_tab(indx).sob_name, TO_DATE(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY'));
						FETCH check_period_cur INTO lc_period_stat;
						CLOSE check_period_cur;
						IF lc_period_stat<>'O' THEN
							lc_error_msg := 'GL Period is not Open for '||l_header_tab(indx).sob_name;
						RAISE data_exception;
						END IF;
						OPEN check_period_cur(201,l_header_tab(indx).sob_name, TO_DATE(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY'));
						FETCH check_period_cur INTO lc_period_stat;
						CLOSE check_period_cur;
						IF lc_period_stat<>'O' THEN
							lc_error_msg := 'PO Period is not Open for '||l_header_tab(indx).sob_name;
							RAISE data_exception;
						END IF;
						print_debug_msg ('Start Validation - PO=['||l_header_tab(indx).ap_po_number||']',FALSE);
						--check AP and GL period is open
						---Validate/Derive vendor information
						--	ln_vendor_id 		:= NULL;
						--	ln_vendor_site_id	:= NULL;
						--	ln_org_id		:= NULL;
						lc_vendor_site_category	:= NULL;
						/**
						OPEN check_vendor_cur(l_header_tab(indx).ap_po_vendor);
						FETCH check_vendor_cur INTO ln_vendor_id,ln_vendor_site_id,ln_org_id,lc_vendor_site_category;
						CLOSE check_vendor_cur;
						**/
						OPEN check_vendor_site_id_cur(l_header_tab(indx).vendor_site_id);
						FETCH check_vendor_site_id_cur
						INTO  lc_vendor_site_category
							, lc_po_vendor_site_code;
						CLOSE check_vendor_site_id_cur;
						IF ltrim(lc_po_vendor_site_code,'0') <> ltrim(l_header_tab(indx).ap_po_vendor,'0') THEN
							print_debug_msg('The datafile receipt vendor '||lc_po_vendor_site_code||' and po vendor '||l_header_tab(indx).ap_po_vendor||' are different for PO=['||l_header_tab(indx).ap_po_number||']', TRUE);
						END IF;
						/**
						IF ln_vendor_id IS NULL OR ln_vendor_id <> l_header_tab(indx).vendor_id THEN
						   print_debug_msg ('PO=['||l_header_tab(indx).ap_po_number||'] Invalid Vendor=['||l_header_tab(indx).ap_po_vendor||']',FALSE);
						   lc_error_msg := 'Invalid Vendor=['||l_header_tab(indx).ap_po_vendor||']';
						   RAISE data_exception;
						END IF;
						**/
						print_debug_msg ('Check PO Status',FALSE);
						IF l_header_tab(indx).authorization_status <>'APPROVED' THEN
							print_debug_msg ('PO=['||l_header_tab(indx).ap_po_number||'] is not in approved status', FALSE);
							lc_error_msg := 'PO is not in approved status';
							RAISE data_exception;
						END IF;
					--Added to check receipt number exists.
						SELECT COUNT(1) INTO ln_rcpt_cnt
						FROM   rcv_shipment_headers
						WHERE  receipt_num=l_header_tab(indx).ap_receipt_num;
						IF ln_rcpt_cnt=0 then
							lc_processing_status_code := 'NEW';
						ELSE
							lc_processing_status_code := 'ADD';
						END IF;
					-- For Consignment, we don't create shipment header and we create only in mtl_transactions_interface
						IF lc_vendor_site_category <> 'TR-CON' THEN
							SELECT rcv_headers_interface_s.NEXTVAL
							INTO ln_header_interface_id
							FROM dual;
							print_debug_msg ('Insert into rcv_headers_interface - header_interface_id=['||TO_CHAR(ln_header_interface_id)||']',FALSE);
							INSERT
							INTO rcv_headers_interface
								(header_interface_id
								,group_id
								,processing_status_code
								,receipt_source_code
								,receipt_num
								,transaction_type
								,creation_date
								,created_by
								,last_update_date
								,last_updated_by
								,last_update_login
								,vendor_id
								,expected_receipt_date
								,org_id
								,transaction_date
								,validation_flag
								,waybill_airbill_num --discuss
								,attribute1
								)
							VALUES
								(ln_header_interface_id
								,p_batch_id
								,'PENDING'
								,'VENDOR'
								,l_header_tab(indx).ap_receipt_num --eader_tab(indx).ap_location||l_header_tab(indx).ap_keyrec||l_header_tab(indx).ap_seq_no||ln_current_year
								,lc_processing_status_code --'NEW'
								,sysdate
								,gn_user_id
								,sysdate
								,gn_user_id
								,gn_login_id
								,l_header_tab(indx).vendor_id
								,to_date(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY')  --discuss ??
								,l_header_tab(indx).org_id
								,to_date(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY')  --discuss ??
								,'Y'
								,l_header_tab(indx).ap_keyrec
								,l_header_tab(indx).attribute3);					  -- Original Ap_Rcvd_Date
						END IF;
						--Validate Lines
						lc_trans_validation := NULL;
						OPEN trans_cur(l_header_tab(indx).ap_po_number
									  ,l_header_tab(indx).ap_keyrec
									  ,l_header_tab(indx).ap_seq_no
									  ,l_header_tab(indx).ap_location
									  ,l_header_tab(indx).ap_po_vendor
									  ,l_header_tab(indx).ap_rcvd_date
									  ,l_header_tab(indx).ap_ship_date);
						FETCH trans_cur BULK COLLECT INTO l_trans_tab;
						CLOSE trans_cur;
						FOR l_indx IN 1..l_trans_tab.COUNT
						LOOP
							BEGIN
								print_debug_msg ('Record_id='||TO_CHAR(l_trans_tab(l_indx).record_id)||', Validate Line',FALSE);
								--discuss -one line expected because of one shipment line for po line.
								po_line_rec.line_num := NULL;
								print_debug_msg ('If line number is null check for mis-ship scenario',FALSE);
								IF l_trans_tab(l_indx).ap_po_line_no =000 THEN --IS NULL THEN
									OPEN po_misship_line_cur(l_header_tab(indx).po_header_id,ltrim(l_trans_tab(l_indx).ap_sku,'0'));
									FETCH po_misship_line_cur INTO po_line_rec;
									CLOSE po_misship_line_cur;
								ELSE
									OPEN po_line_cur(l_header_tab(indx).po_header_id,l_trans_tab(l_indx).ap_po_line_no);
									FETCH po_line_cur INTO po_line_rec;
									CLOSE po_line_cur;
								END IF;
								IF po_line_rec.line_num IS NULL THEN
									l_trans_tab(l_indx).record_status 		:= 'E';
									l_trans_tab(l_indx).error_description 	:= 'Invalid Line Number =['||l_trans_tab(l_indx).ap_po_line_no||']';
									print_debug_msg ('Record_id=['||TO_CHAR(l_trans_tab(l_indx).record_id)||
													'] Invalid Line Number =['|| l_trans_tab(l_indx).ap_po_line_no||
														'], for PO=['||l_header_tab(indx).ap_po_number||']',FALSE);
									XX_PO_POM_INT_PKG.valid_and_mark_missed_po_int(p_source => 'NA-RCVINTR' ,
																	  p_source_record_id 	=>l_trans_tab(l_indx).record_id ,
																	  p_po_number 			=> l_header_tab(indx).ap_po_number ,
																	  p_po_line_num 		=> l_trans_tab(l_indx).ap_po_line_no ,
																	  p_result 				=> lc_result);
									RAISE data_exception;
								END IF;
								print_debug_msg ('Record_id='||TO_CHAR(l_trans_tab(l_indx).record_id)||', Check Period Status',FALSE);
								lc_inv_period_stat :=NULL;
								OPEN check_inv_period_cur(po_line_rec.organization_id
														, TO_DATE(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY'));	--l_header_tab(indx).ap_rcvd_date);
								FETCH check_inv_period_cur INTO lc_inv_period_stat;
								CLOSE check_inv_period_cur;
								IF lc_inv_period_stat <>'Y' THEN
									l_trans_tab(l_indx).record_status := 'E';
									l_trans_tab(l_indx).error_description := l_trans_tab(l_indx).error_description||' Inventory Period is not Open for '||TO_CHAR(po_line_rec.organization_id)||']';
									RAISE data_exception;
								END IF;
								print_debug_msg ('Record_id='||TO_CHAR(l_trans_tab(l_indx).record_id)||', Validate Item',FALSE);
								ln_item_id := null;
								OPEN check_item_cur(ltrim(l_trans_tab(l_indx).ap_sku,'0')
												 ,po_line_rec.organization_id);
								FETCH check_item_cur INTO ln_item_id;
								CLOSE check_item_cur;
								IF ln_item_id IS NULL OR ln_item_id <> po_line_rec.item_id THEN
									l_trans_tab(l_indx).record_status := 'E';
									l_trans_tab(l_indx).error_description := l_trans_tab(l_indx).error_description||'Invalid item=['||l_trans_tab(l_indx).ap_sku||
												'], organization_id=['||TO_CHAR(po_line_rec.organization_id)||']';
									print_debug_msg ('Invalid item=['||l_trans_tab(l_indx).ap_sku||
												'], organization_id=['||TO_CHAR(po_line_rec.organization_id)||']',FALSE);
								END IF;
								IF lc_vendor_site_category = 'TR-CON' THEN
									lc_segment1    := null;
									lc_segment2	:= null;
									lc_segment4	:= null;
									lc_segment5	:= null;
									lc_segment6	:= null;
									lc_segment7	:= null;
									OPEN get_acct_values(po_line_rec.organization_id);
									FETCH get_acct_values
									INTO lc_segment1
										,lc_segment2
										,lc_segment4
										,lc_segment5
										,lc_segment6
										,lc_segment7
										,ln_ccid;
									CLOSE get_acct_values;
									IF lc_segment1 IS NULL THEN
										l_trans_tab(l_indx).record_status := 'E';
										l_trans_tab(l_indx).error_description := l_trans_tab(l_indx).error_description||' Error deriving material account for organization_id=['||TO_CHAR(po_line_rec.organization_id)||']';
										print_debug_msg ('Error deriving material account for organization_id=['||TO_CHAR(po_line_rec.organization_id)||']',FALSE);
									END IF;
								END IF;
								IF l_trans_tab(l_indx).record_status = 'E'
								THEN
									RAISE data_exception;
								END IF;
								--Check if any of the lines have errors
								IF lc_trans_validation IS NULL
								THEN
									IF lc_vendor_site_category = 'TR-CON'
									THEN
										print_debug_msg ('Insert into mtl_transactions_interface',FALSE);
										INSERT INTO mtl_transactions_interface(
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
											,attribute9)
										VALUES (mtl_material_transactions_s.nextval  	   	--transaction_header_id
											,'INVENTORY'  				   					--source_code
											,-1  					   						--source_header_id
											,-1  										    --source_line_id
											,1  					   						--process_flag
											,3  					   						--transaction_mode
											,2  			        	   					--lock_flag
											,sysdate  				   						--last_update_date
											,gn_user_id				   						--last_updated_by (could filled by user_id)
											,sysdate  				   						--creation_date
											,gn_user_id  				   					--created_by (could filled by user_id)
											,po_line_rec.item_id			   				--inventory_item_id
											,po_line_rec.organization_id       	   			--organization_id 03077
											,l_trans_tab(l_indx).ap_rcvd_quantity      		--transaction_quantity
											,l_trans_tab(l_indx).ap_rcvd_cost          		--transaction_cost
											,l_trans_tab(l_indx).ap_rcvd_quantity      		--primary_quantity
											,po_line_rec.uom_code			   				--transaction_uom_code
											,to_date(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY') 	--discuss transaction_date?
											,NVL(po_line_rec.destination_subinventory,'STOCK')  	--subinventory_code
											,ln_trx_source_id  			   					--transaction_source_type_id
											,ln_trx_act_id  		 	   					--transaction_action_id
											,ln_trx_type_id  			   					--transaction_type_id
											,'OD CONSIGNMENT RECEIPTS'
											,ln_ccid
											,lc_segment1
											,lc_segment2
											,'12102000'
											,lc_segment4
											,lc_segment5
											,lc_segment6
											,lc_segment7
											,'WMS'
											,lpad(l_header_tab(indx).ap_po_vendor,10,'0')
											,l_header_tab(indx).ap_receipt_num||'|'||l_header_tab(indx).ap_po_number||'|'||po_line_rec.line_num||'|'||l_trans_tab(l_indx).record_id||'|'||p_batch_id
											,l_header_tab(indx).attribute3);

									ELSE
										SELECT rcv_transactions_interface_s.NEXTVAL
										INTO ln_interface_transaction_id
										FROM dual;
										print_debug_msg ('Insert into rcv_transactions_interface',FALSE);
										-- Insert in transactions interface table --
										INSERT
										INTO rcv_transactions_interface
											 (interface_transaction_id
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
											,po_header_id
											,po_line_id
											,item_id
											,quantity
											,unit_of_measure
											,po_line_location_id
											,auto_transact_code
											,receipt_source_code
											,to_organization_code
											,source_document_code
											,document_num
											,destination_type_code
											,deliver_to_person_id
											,deliver_to_location_id
											,subinventory
											,header_interface_id
											,validation_flag
											,org_id
											,item_description
											,attribute1  --discuss if sku needs to be populated here.
											,attribute8
											,attribute9
											)
										VALUES (ln_interface_transaction_id
											,p_batch_id
											,sysdate
											,gn_user_id
											,sysdate
											,gn_user_id
											,gn_login_id
											,'RECEIVE'
											,to_date(l_header_tab(indx).ap_rcvd_date,'MM/DD/YY') --to_date('29-AUG-2016') -- trunc(systimestamp) --discuss ??
											,'PENDING'
											,'BATCH'
											,'PENDING'
											,po_line_rec.po_header_id
											,po_line_rec.po_line_id
											,po_line_rec.item_id
											,l_trans_tab(l_indx).ap_rcvd_quantity
											,po_line_rec.unit_meas_lookup_code
											,po_line_rec.line_location_id
											,'DELIVER'  --'RECEIVE'
											,'VENDOR'
											,po_line_rec.organization_code
											,'PO'
											,l_header_tab(indx).ap_po_number
											,po_line_rec.destination_type_code
											,po_line_rec.deliver_to_person_id
											,po_line_rec.deliver_to_location_id
											,NVL(po_line_rec.destination_subinventory,'STOCK')
											,ln_header_interface_id
											,'Y'
											,po_line_rec.org_id
											,po_line_rec.item_description
											,l_trans_tab(l_indx).ap_sku
											,l_header_tab(indx).ap_receipt_num||'|'||l_header_tab(indx).ap_po_number||'|'||po_line_rec.line_num||'|'||l_trans_tab(l_indx).record_id||'|'||p_batch_id
											,l_header_tab(indx).attribute3
											);
									END IF;
								END IF;
								 /**
								UPDATE xx_po_rcv_trans_int_stg stg
								SET  stg.record_status = 'I'
									,stg.attribute1 = decode(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
								WHERE record_id=l_trans_tab(l_indx).record_id;
								  **/
								l_trans_tab(l_indx).record_status := 'I';
							EXCEPTION
							WHEN data_exception THEN
								print_debug_msg ('Data Exception - Record_id=['||TO_CHAR(l_trans_tab(l_indx).record_id)||'], RB, '||lc_error_msg,TRUE);
								lc_trans_validation := 'E';
								rollback;
							WHEN others THEN
								lc_error_msg := SUBSTR(sqlerrm,1,250);
								print_debug_msg ('Record_id=['||TO_CHAR(l_trans_tab(l_indx).record_id)||'], RB, '||lc_error_msg,TRUE);
								lc_trans_validation := 'E';
								l_trans_tab(l_indx).record_status := 'E';
								l_trans_tab(l_indx).error_description := l_trans_tab(l_indx).error_description ||' '||lc_error_msg;
								rollback;
							END;
						END LOOP;
						BEGIN
							print_debug_msg('Starting update of xx_po_rcv_trans_int_stg #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
						FORALL i IN 1..l_trans_tab.COUNT
							SAVE EXCEPTIONS
							UPDATE xx_po_rcv_trans_int_stg
							SET record_status = decode(lc_trans_validation, 'E', 'E', 'I')
								,error_description = DECODE(lc_trans_validation,'E',NVL(l_trans_tab(i).error_description,'One or more receipt lines failed validation'),'')
								,attribute1 = decode(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
								,last_update_date  = sysdate
								,last_updated_by   = gn_user_id
								,last_update_login = gn_login_id
							WHERE record_id = l_trans_tab(i).record_id;
						EXCEPTION
						WHEN OTHERS THEN
							print_debug_msg('Bulk Exception raised',TRUE);
							ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
						FOR i IN 1..ln_err_count
						LOOP
							ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
							lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
							log_exception ('OD PO RCV Inbound Interface(Child)',lc_error_loc,lc_error_msg);
							print_debug_msg('Record_id=['||TO_CHAR(l_trans_tab(ln_error_idx).record_id)||'], Error msg=['||lc_error_msg||']',TRUE);
						END LOOP; -- bulk_err_loop FOR UPDATE
						END;
						print_debug_msg('Ending Update of xx_po_rcv_trans_int_stg #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
					EXCEPTION
					WHEN data_exception THEN
						print_debug_msg('Data-Exception: Update PO=['||l_header_tab(indx).ap_po_number||'] transactions with error msg', TRUE);
					rollback;
					UPDATE xx_po_rcv_trans_int_stg
					SET record_status 		= 'E'
						,error_description 	= lc_error_msg
						,attribute1 		= DECODE(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
						,last_update_date  	= SYSDATE
						,last_updated_by   	= gn_user_id
						,last_update_login 	= gn_login_id
					WHERE ap_keyrec 		=  l_header_tab(indx).ap_keyrec
					AND ap_seq_no 			= l_header_tab(indx).ap_seq_no
					AND ap_location 		= l_header_tab(indx).ap_location
					AND ap_po_vendor 		= l_header_tab(indx).ap_po_vendor
					AND ap_rcvd_date 		= l_header_tab(indx).ap_rcvd_date
					AND (ap_ship_date IS NULL OR ap_ship_date=l_header_tab(indx).ap_ship_date)
					AND record_status IS NULL;
				WHEN OTHERS THEN
					print_debug_msg('Update PO=['||l_header_tab(indx).ap_po_number||'] transactions with error msg', TRUE);
					lc_error_msg := lc_error_msg||'-'||SUBSTR(sqlerrm,1,250);
					UPDATE xx_po_rcv_trans_int_stg
					SET record_status = 'E'
						,error_description = lc_error_msg
						,attribute1 = DECODE(lc_vendor_site_category, 'TR-CON', 'CONSG', 'NON-CONSG')
						,last_update_date  = SYSDATE
						,last_updated_by   = gn_user_id
						,last_update_login = gn_login_id
					WHERE ap_keyrec 	   =  l_header_tab(indx).ap_keyrec
					AND ap_seq_no 		   = l_header_tab(indx).ap_seq_no
					AND ap_location 	   = l_header_tab(indx).ap_location
					AND ap_po_vendor 	   = l_header_tab(indx).ap_po_vendor
					AND ap_rcvd_date 	   = l_header_tab(indx).ap_rcvd_date
					AND (ap_ship_date IS NULL OR ap_ship_date=l_header_tab(indx).ap_ship_date)
					AND record_status IS NULL;
				END;
				COMMIT;
				print_debug_msg('Commit Complete',FALSE);
			END LOOP; --l_header_tab
		END LOOP; --header_cur
		CLOSE header_cur;
		print_debug_msg('Submitting Receiving Transaction Processor',FALSE);
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
			ln_job_id := fnd_request.submit_request(application  => 'PO'
													  ,program     => 'RVCTP'
													  ,sub_request => TRUE
													  ,argument1   => 'BATCH'        		-- Node
													  ,argument2   => p_batch_id  			-- Group Id
													  ,argument3   => l_org_tab(o_indx).org_id	-- org_id
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
			ln_child_request_status := child_request_status;
			IF ln_child_request_status = 'C' THEN
				report_child_program_stats(p_batch_id);
				p_retcode := '0';
			ELSIF ln_child_request_status = 'G' THEN
				p_retcode := '1'; --Warning
				p_errbuf := 'One or more child program completed in error or warning';
			END IF;
		END IF;
	EXCEPTION
	WHEN others THEN
		lc_error_msg := substr(sqlerrm,1,250);
		print_debug_msg ('ERROR RCV Int Child- '||lc_error_msg,TRUE);
		log_exception ('OD PO RCV Inbound Interface(Child)',
					   lc_error_loc,
					   lc_error_msg);
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
	END interface_child;
	 -- +============================================================================================+
	 -- |  Name	  : submit_int_child_threads                                                     |
	 -- |  Description: This procedure splits PO into batches and submits child process-             |
	 -- |               OD PO RCV Inbound Interface(Child)                                           |
	 -- =============================================================================================|
	PROCEDURE submit_int_child_threads(p_errbuf       	OUT  VARCHAR2
									   ,p_retcode      	OUT  VARCHAR2
									   ,p_child_threads 	 NUMBER
									   ,p_debug              VARCHAR2)
	AS
		CURSOR threads_cur IS
			SELECT MIN(x.ap_po_number) from_po
				  ,MAX(x.ap_po_number) to_po
				  ,x.thread_num
				  ,count(1)
			 FROM (SELECT h.ap_po_number,NTILE(p_child_threads) OVER(ORDER BY h.ap_po_number) thread_num
					 FROM xx_po_rcv_trans_int_stg h
					WHERE h.record_status is null) x
			GROUP BY x.thread_num
			ORDER BY x.thread_num;
		TYPE threads IS TABLE OF threads_cur%ROWTYPE
		INDEX BY PLS_INTEGER;
		l_threads_tab 	threads;
		lc_error_msg        VARCHAR2(1000) := NULL;
		lc_error_loc        VARCHAR2(100) := 'XX_PO_RCV_INT_PKG.SUBMIT_INT_CHILD_THREADS';
		ln_batch_count      NUMBER;
		ln_batch_id         NUMBER;
		ln_request_id       NUMBER;
	BEGIN
		print_debug_msg('Preparing threads for new po/add line',TRUE);
		OPEN threads_cur;
		FETCH threads_cur BULK COLLECT INTO l_threads_tab;
		CLOSE threads_cur;
		print_debug_msg('Update BatchID in headers for import',TRUE);
		FOR indx IN 1..l_threads_tab.COUNT
		LOOP
			SELECT rcv_interface_groups_s.nextval --xx_po_rcv_int_batch_s.nextval
			INTO ln_batch_id
			FROM dual;
			UPDATE xx_po_rcv_trans_int_stg h
			SET h.batch_id = ln_batch_id
				 ,h.last_update_date = sysdate
				 ,h.last_updated_by  = gn_user_id
				 ,h.last_update_login = gn_login_id
			WHERE h.ap_po_number BETWEEN l_threads_tab(indx).from_po
			AND l_threads_tab(indx).to_po
			AND h.record_status is null;
			ln_batch_count := SQL%ROWCOUNT;
			print_debug_msg(TO_CHAR(ln_batch_count)||' rcv trans record(s) updated with batchid '||TO_CHAR(ln_batch_id),TRUE);
			COMMIT;
			ln_request_id := fnd_request.submit_request(application => 'XXFIN'
									  ,program     => 'XXPORCVINTC'
									  ,sub_request => TRUE
									  ,argument1   => ln_batch_id
									  ,argument2   => p_debug);
			COMMIT;
		END LOOP;
		--Check if any child requests submitted.
		IF l_threads_tab.COUNT > 0 THEN
		   p_retcode := '0';
		ELSE
		   p_retcode := '1';
		END IF;
	EXCEPTION
	WHEN others THEN
		lc_error_msg := SUBSTR(sqlerrm,1,250);
		print_debug_msg('ERROR in SUBMIT_INT_CHILD_TREADS'||lc_error_msg,TRUE);
		log_exception ('OD PO RCV Inbound Interface(Master)',lc_error_loc,lc_error_msg);
		p_retcode := '2';
		p_errbuf  := substr(sqlerrm,1,250);
	END submit_int_child_threads;
	 -- +============================================================================================+
	 -- |  Name	  : interface_master                                                             |
	 -- |  Description: This procedure reads data from the staging and loads into RCV interface      |
	 -- |               OD PO RCV Inbound Interface(Master)                                          |
	 -- =============================================================================================|
	PROCEDURE interface_master(p_errbuf       OUT  VARCHAR2
							   ,p_retcode      OUT  VARCHAR2
							   ,p_child_threads     NUMBER
							   ,p_retry_errors      VARCHAR2
							   ,p_debug             VARCHAR2)
	AS
		lc_error_msg       VARCHAR2(1000) := NULL;
		lc_error_loc       VARCHAR2(100)  := 'XX_PO_RCV_INT_PKG.INTERFACE_MASTER';
		ln_retry_count     NUMBER;
		lc_retcode	       VARCHAR2(3)    := NULL;
		lc_iretcode	       VARCHAR2(3)    := NULL;
		lc_uretcode	       VARCHAR2(3)    := NULL;
		lc_req_data        VARCHAR2(30);
		ln_child_request_status     VARCHAR2(1) := NULL;
	BEGIN
		gc_debug	  := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;
		--Get value of global variable. It is null initially.
		lc_req_data   := fnd_conc_global.request_data;
		-- req_date will be null for first time parent scan by concurrent manager.
		IF (lc_req_data IS NULL) THEN
			print_debug_msg('Check Retry Errors',TRUE);
			IF p_retry_errors = 'Y' THEN
			   print_debug_msg('Updating rcv trans staging records for retry',FALSE);
			   UPDATE xx_po_rcv_trans_int_stg
				  SET record_status = null
					 ,error_description = null
					 ,last_update_date = sysdate
					 ,last_updated_by = gn_user_id
					 ,last_update_login = gn_login_id
				WHERE record_status IN ('E','IE');
				ln_retry_count := SQL%ROWCOUNT;
				print_debug_msg(TO_CHAR(ln_retry_count)||' record(s) updated for retry',TRUE);
				COMMIT;
			END IF;
		-- Skip the PO's if they belong to Internal Vendors.
		BEGIN
			UPDATE xx_po_rcv_trans_int_stg hs
			SET record_status = 'I'
				,attribute5 = 'Internal Vendor - skip PO processing'
				,last_update_date  = sysdate
				,last_updated_by   = gn_user_id
				,last_update_login = gn_login_id
			WHERE record_status IS NULL
			AND EXISTS (
					 SELECT '1'
					 FROM  xx_fin_translatedefinition xtd
						 , xx_fin_translatevalues xtv
					WHERE xtd.translation_name = 'PO_POM_INT_VENDOR_EXCL'
					AND xtd.translate_id       = xtv.translate_id
					AND xtv.source_value1 = ltrim(hs.ap_po_vendor, '0')
			);
			print_debug_msg('Internal Vendor Skip - Updated Staged Receipts count is '||SQL%ROWCOUNT,TRUE);
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
				  p_retcode := '2';
				  p_errbuf  := lc_error_msg;
			ELSIF lc_iretcode = '1' THEN
				  print_debug_msg('No Interface Child Requests submitted...',TRUE);
			END IF;
		END IF; --l_req_data IS NULL
		IF (lc_req_data = 'END') THEN
			p_retcode := '0';
			ln_child_request_status := child_request_status;
			IF ln_child_request_status = 'C' THEN
			   report_master_program_stats;
			   p_retcode := '0';
			ELSIF ln_child_request_status = 'G' THEN
			   p_retcode := '1'; --Warning
			   p_errbuf  := 'One or more child program completed in error or warning';
			END IF;
			-- Sends the program output in email
			send_output_email(fnd_global.conc_request_id, p_retcode);
		END IF;
	EXCEPTION
	WHEN others THEN
		lc_error_msg := substr(sqlerrm,1,250);
		print_debug_msg ('ERROR RCV Int Master - '||lc_error_msg,TRUE);
		log_exception ('OD PO RCV Inbound Interface(Master)',
					   lc_error_loc,
			   lc_error_msg);
		p_retcode := 2;
	END interface_master;
END XX_PO_RCV_INT_PKG;
/
SHOW ERRORS;