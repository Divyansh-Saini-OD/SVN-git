CREATE OR REPLACE PACKAGE Body XX_PO_RCV_CONV_PKG AS


-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_PO_RCV_CONV_PKG
-- | Description : Package Body
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |=======    ===========   ===============  =================================+
-- |DRAFT 1A   04-Mar-2017   Antonio Morales  Initial draft version  
-- |
-- |Objective: Conversion/Validation of Receipts to PO
-- |
-- |Concurrent Program: OD: PO Receipts Conversion Child Program
-- |                    XXPORCVCNVCH
-- +===========================================================================+

    cn_commit    CONSTANT INTEGER := 10000;  --- Number of transactions per commit and/or bulk limit
	cc_module    CONSTANT VARCHAR2(100) := 'XX_PO_RCV_CONV_PKG';
    cc_procedure CONSTANT VARCHAR2(100) := 'CHILD_MAIN';
    cn_max_loop  CONSTANT INTEGER := 999999999;     --- Max. time in minutes to wait on an infinit loop

PROCEDURE child_main(x_retcode            OUT NOCOPY NUMBER
                    ,x_errbuf             OUT NOCOPY VARCHAR2
                    ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ,p_batch_id            IN        INTEGER   DEFAULT NULL
                    ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N' -- Y/N
                    ) IS

    ln_request_id           INTEGER := fnd_global.conc_request_id();
    ln_debug_level          INTEGER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(4000);
    ln_retcode              INTEGER := 0;
    ln_errors               INTEGER := 0;
    ln_error_hdr            INTEGER := 0;
    ln_error_txs            INTEGER := 0;
    ln_read_hdr             INTEGER := 0;
    ln_read_txs             INTEGER := 0;
    ln_write_hdr            INTEGER := 0;
    ln_write_txs            INTEGER := 0;
    ln_write_dis            INTEGER := 0;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_message              VARCHAR2(100);

    lr_rowid                ROWID;

    ln_conversion_id        INTEGER := 0;
	lc_system_code          VARCHAR2(100);
	ln_error_flag           INTEGER := 0;
	ln_process_flag         INTEGER := 0;
    ln_failed_process       INTEGER := 0;
    ln_last_int_id          INTEGER := 0;
	
    lc_approval_status      VARCHAR2(20);
    lc_closed_code          VARCHAR2(20);
    ld_need_by_date         DATE;
    ld_promised_date        DATE;
    lc_fob                  VARCHAR2(20);
    lc_freight_terms        VARCHAR2(20);
    ld_creation_date        DATE;
    lc_note_to_vendor       VARCHAR2(4000);
    lc_note_to_receiver     VARCHAR2(4000);
    lc_process_flag         VARCHAR2(20);

    ld_sdate                TIMESTAMP := SYSTIMESTAMP;

    --- Cursor to handle headers rows

    CURSOR c_hdr (p_batch_id INTEGER
				 ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
               ) IS
    SELECT rc.header_interface_id
          ,rc.group_id
          ,max(rc.control_id) control_id
          ,rc.ap_rcvd_date expected_receipt_date
          ,rc.process_flag
          ,rc.ap_po_number
          ,rc.batch_id
          ,rc.ap_keyrec
          ,po.po_header_id
          ,po.vendor_id
          ,po.org_id
          ,receipt_num
      FROM xx_po_rcpts_stg rc
           LEFT JOIN po_headers_all  po
                  ON rc.ap_po_number = po.segment1
     WHERE batch_id = p_batch_id
	   AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
	                          END)
       AND process_flag < 6
     GROUP BY rc.header_interface_id
          ,rc.group_id
          ,rc.ap_rcvd_date 
          ,rc.process_flag
          ,rc.ap_po_number
          ,rc.batch_id
          ,rc.ap_keyrec
          ,rc.receipt_num
          ,po.po_header_id
          ,po.vendor_id
          ,po.org_id;


    TYPE thdr IS TABLE OF c_hdr%ROWTYPE;
	
    t_hdr thdr := thdr();

    --- Cursor to handle transaction rows

    CURSOR c_txs (p_batch_id              INTEGER
                 ,p_po_no                 VARCHAR2
                 ,p_po_hdr_id             INTEGER
                 ,p_keyrec                INTEGER
                 ,p_expected_receipt_date VARCHAR2
                 ,p_receipt_num           INTEGER) IS
    SELECT rc.interface_transaction_id
          ,rc.group_id
          ,rc.control_id
          ,to_number(rc.ap_rcvd_quantity) ap_rcvd_quantity
          ,rc.process_flag
          ,rc.ap_sku
          ,rc.receipt_num
          ,NVL(to_number(rc.ap_po_line_no),0) ap_po_line_no
          ,li.po_line_id
          ,li.line_num
          ,li.item_id
          ,li.unit_meas_lookup_code
          ,li.org_id
          ,li.item_description
      FROM xx_po_rcpts_stg rc
           LEFT JOIN po_lines_all li
                  ON li.po_header_id = NVL(p_po_hdr_id,-1)
                 AND li.line_num = to_number(rc.ap_po_line_no)
     WHERE rc.batch_id = p_batch_id
       AND rc.ap_po_number = p_po_no
       AND rc.ap_rcvd_date = p_expected_receipt_date
       AND rc.receipt_num = p_receipt_num
       AND rc.ap_keyrec = p_keyrec
       AND rc.process_flag+0 < 9;
	
    TYPE ttxs IS TABLE OF c_txs%ROWTYPE;
	
    t_txs ttxs := ttxs();

    TYPE teflag IS TABLE OF INTEGER;
	
    t_eflag_hdr teflag := teflag();

    t_eflag_txs teflag := teflag();

PROCEDURE log_errors (p_error_msg         IN VARCHAR2
                     ,p_control_id        IN INTEGER
                     ,p_staging_table     IN VARCHAR2
                     ,p_column            IN VARCHAR2
                     ,p_value             IN VARCHAR2
                     ,p_oracle_code       IN VARCHAR2
                     ,p_oracle_msg        IN VARCHAR2
                     ,p_source_system_ref IN VARCHAR2
                     ) IS

BEGIN
      xx_com_conv_elements_pkg.log_exceptions_proc(p_conversion_id        => ln_conversion_id
                                                  ,p_record_control_id    => p_control_id
                                                  ,p_source_system_code   => ''
                                                  ,p_package_name         => cc_module
                                                  ,p_procedure_name       => cc_procedure
                                                  ,p_staging_table_name   => p_staging_table
                                                  ,p_staging_column_name  => p_column
                                                  ,p_staging_column_value => p_value
                                                  ,p_source_system_ref    => p_source_system_ref
                                                  ,p_batch_id             => p_batch_id
                                                  ,p_exception_log        => p_error_msg
                                                  ,p_oracle_error_code    => p_oracle_code
                                                  ,p_oracle_error_msg     => p_oracle_msg
                                                  );
END log_errors;

PROCEDURE insert_rcvs (p_hdr_index INTEGER) IS

BEGIN

-- Insert in headers interface table

     fnd_file.put_line (fnd_file.LOG,'Insert header= '||p_hdr_index);

  	 BEGIN
         INSERT
           INTO rcv_headers_interface
               (header_interface_id
               ,group_id
               ,processing_status_code
               ,receipt_source_code
               ,transaction_type
               ,last_update_date
               ,last_updated_by
               ,last_update_login
               ,vendor_id
               ,expected_receipt_date
               ,org_id
               ,transaction_date
               ,validation_flag
               ,waybill_airbill_num
               ,receipt_num
               ,attribute1
               ,attribute2
                ) 
         SELECT t_hdr(p_hdr_index).header_interface_id
               ,t_hdr(p_hdr_index).batch_id
               ,'PENDING'
               ,'VENDOR'
               ,'NEW'
               ,systimestamp
               ,fnd_global.user_id
               ,fnd_global.user_id
  			   ,t_hdr(p_hdr_index).vendor_id
               ,trunc(ld_sdate) -- Nisha 5/25/17 t_hdr(p_hdr_index).expected_receipt_date
               ,t_hdr(p_hdr_index).org_id
               ,trunc(ld_sdate)
               ,'Y'
               ,t_hdr(p_hdr_index).ap_keyrec
               ,t_hdr(p_hdr_index).receipt_num
               ,t_hdr(p_hdr_index).expected_receipt_date
               ,'Y' -- is a converted receipt
           FROM dual
  		  WHERE t_eflag_hdr(p_hdr_index) = 0;

         ln_write_hdr := ln_write_hdr + 1;

      EXCEPTION
             WHEN DUP_VAL_ON_INDEX THEN
                  log_errors (p_error_msg     => 'Insert duplicated header id='||t_hdr(p_hdr_index).header_interface_id
                             ,p_control_id    => t_hdr(p_hdr_index).group_id
                             ,p_staging_table => 'RCV_HEADERS_INTERFACE'
                             ,p_column        => NULL
                             ,p_value         => NULL
                             ,p_oracle_code   => sqlcode
                             ,p_oracle_msg    => sqlerrm
                             ,p_source_system_ref => t_hdr(p_hdr_index).ap_po_number
                             );        
  				 t_eflag_hdr(p_hdr_index) := 1;

     END;

     fnd_file.put_line (fnd_file.LOG,'Insert txs= '||t_txs.COUNT);

     IF t_txs.COUNT = 0 THEN
        fnd_file.put_line (fnd_file.LOG,'txs_count=0, Header_interface_id='||t_hdr(p_hdr_index).header_interface_id||
                                        ' po_header_id='||t_hdr(p_hdr_index).po_header_id||
                                        ' po='||t_hdr(p_hdr_index).ap_po_number
                             );
        log_errors (p_error_msg     => 'No txs for header id='||t_hdr(p_hdr_index).header_interface_id
                  ,p_control_id    => t_hdr(p_hdr_index).group_id
                  ,p_staging_table => 'RCV_HEADERS_INTERFACE'
                  ,p_column        => NULL
                  ,p_value         => NULL
                  ,p_oracle_code   => sqlcode
                  ,p_oracle_msg    => sqlerrm
                  ,p_source_system_ref => t_hdr(p_hdr_index).ap_po_number
                  );
        t_eflag_hdr(p_hdr_index) := 1;
     ELSE
        FOR j IN t_txs.FIRST .. t_txs.LAST
        LOOP

               fnd_file.put_line (fnd_file.LOG,'Inserting in transactions interface table, transaction='||t_txs(j).interface_transaction_id||
                                              ' line='||t_txs(j).line_num||' header_interface_id='||t_hdr(p_hdr_index).header_interface_id||
                                              ' po_header_id='||t_hdr(p_hdr_index).po_header_id||' po='||t_hdr(p_hdr_index).ap_po_number
                                );
                -- Insert in transactions interface table --
                BEGIN
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
                         ,auto_transact_code
                         ,receipt_source_code
                         ,source_document_code
                         ,header_interface_id
                         ,validation_flag
                         ,org_id
                         ,item_description
                         ,attribute1
                         ,subinventory
                          ) 
                   SELECT t_txs(j).interface_transaction_id
                         ,t_hdr(p_hdr_index).batch_id --group_id
                         ,systimestamp
                         ,fnd_global.user_id
                         ,systimestamp
                         ,fnd_global.user_id
                         ,fnd_global.user_id
                         ,'RECEIVE'
                         ,trunc(ld_sdate)
                         ,'PENDING'
                         ,'BATCH'
                         ,'PENDING'
                         ,t_hdr(p_hdr_index).po_header_id
                         ,t_txs(j).po_line_id
                         ,t_txs(j).item_id
                         ,t_txs(j).ap_rcvd_quantity
                         ,t_txs(j).unit_meas_lookup_code
                         ,'DELIVER'
                         ,'VENDOR'
                         ,'PO'
                         ,t_hdr(p_hdr_index).header_interface_id
                         ,'Y'
                         ,t_txs(j).org_id
                         ,t_txs(j).item_description
                         ,t_txs(j).ap_sku
                         ,'STOCK'
                     FROM dual
  		            WHERE t_eflag_txs(j) = 0;

                     ln_write_txs := ln_write_txs + 1;

                EXCEPTION
   		          WHEN OTHERS THEN
                          fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                          fnd_file.put_line (fnd_file.LOG,'Insert in transactions interface table, transaction='||t_txs(j).interface_transaction_id||
                                                          ' line='||t_txs(j).line_num||' header_interface_id='||t_hdr(p_hdr_index).header_interface_id||
                                                          ' po_header_id='||t_hdr(p_hdr_index).po_header_id||' po='||t_hdr(p_hdr_index).ap_po_number
                                            );
                          log_errors (p_error_msg     => 'Error transaction='||t_txs(j).interface_transaction_id||
                                                         ' line='||t_txs(j).line_num
                                     ,p_control_id    => t_hdr(p_hdr_index).group_id
                                     ,p_staging_table => 'RCV_TRANSACTIONS_INTERFACE'
                                     ,p_column        => NULL
                                     ,p_value         => NULL
                                     ,p_oracle_code   => sqlcode
                                     ,p_oracle_msg    => sqlerrm
                                     ,p_source_system_ref => t_hdr(p_hdr_index).ap_po_number
                                     );        
                          t_eflag_hdr(p_hdr_index) := 1;
                          RAISE;
                END;

        END LOOP;

        COMMIT;

     END IF;

    EXCEPTION
        WHEN OTHERS THEN
	        fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            lc_error_flag := 'Y';
            ROLLBACK;
            FND_FILE.put_line(FND_FILE.LOG,'Unexpected error in Process Child :'||SQLERRM);
            RAISE;
     
END insert_rcvs;


PROCEDURE set_process_status_flag_hdr(p_batch_id    IN INTEGER
                                     ,p_from_status IN VARCHAR2
								     ,p_to_status   IN INTEGER
								     ,p_reset_flag  IN VARCHAR2 DEFAULT 'N') IS

    CURSOR c_hdrs(p_batch_id INTEGER
				 ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
               ) IS
    SELECT rowid rid
          ,org_id
      FROM xx_po_rcpts_stg stg
     WHERE batch_id = p_batch_id
	   AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
		                      END)
       AND process_flag < 6;

    TYPE thdrs IS TABLE OF c_hdrs%ROWTYPE;

    t_hdrs thdrs := thdrs();

    ln_count INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating header status for batch='||p_batch_id||', from '||p_from_status||' to '||p_to_status);


  OPEN c_hdrs(p_batch_id
             ,p_from_status
			 ,p_reset_flag);

  LOOP
     FETCH c_hdrs
	  BULK COLLECT
	  INTO t_hdrs LIMIT cn_commit;

     EXIT WHEN t_hdrs.COUNT = 0;
  
     FORALL r_hdr IN t_hdrs.FIRST .. t_hdrs.LAST
            UPDATE xx_po_rcpts_stg
		       SET process_flag = p_to_status
                  ,org_id = t_hdrs(r_hdr).org_id
                  ,request_id = ln_request_id
             WHERE rowid = t_hdrs(r_hdr).rid;

     COMMIT;
	 
     ln_count := ln_count + t_hdrs.COUNT;

  END LOOP;

  CLOSE c_hdrs;

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		 IF c_hdrs%ISOPEN THEN
            CLOSE c_hdrs;
         END IF;
         RAISE;

END set_process_status_flag_hdr;

PROCEDURE set_process_status_flag_txs(p_batch_id    IN INTEGER
                                     ,p_from_status IN VARCHAR2
								     ,p_to_status   IN INTEGER
								     ,p_reset_flag  IN VARCHAR2 DEFAULT 'N') IS

    CURSOR c_txss(p_batch_id NUMBER
	             ,p_status   VARCHAR2
                 ,p_reset    VARCHAR2
				 ) IS

	SELECT rowid rid
	  FROM xx_po_rcpts_stg stg
	 WHERE batch_id = p_batch_id
	   AND process_flag LIKE (CASE WHEN p_reset = 'Y' THEN '%'
                                   ELSE p_status
		                      END)
       AND process_flag < 6;

    TYPE tlins IS TABLE OF c_txss%ROWTYPE;

    t_txss tlins := tlins();

    ln_count INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating lines status for batch='||p_batch_id||', from '||p_from_status||' to '||p_to_status);

  OPEN c_txss(p_batch_id
             ,p_from_status
			 ,p_reset_flag);

  LOOP
     FETCH c_txss
	  BULK COLLECT
	  INTO t_txss LIMIT cn_commit;
	 
     EXIT WHEN t_txss.COUNT = 0;
 
     FORALL r_txss IN t_txss.FIRST .. t_txss.LAST
            UPDATE xx_po_rcpts_stg
               SET process_flag = p_to_status
                  ,request_id = ln_request_id
		     WHERE rowid = t_txss(r_txss).rid;
     COMMIT;

     ln_count := ln_count + t_txss.COUNT;

  END LOOP;

  CLOSE c_txss;

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		 IF c_txss%ISOPEN THEN
            CLOSE c_hdr;
         END IF;
         RAISE;

END set_process_status_flag_txs;

FUNCTION submit_po_import_cp RETURN INTEGER IS

    ln_active_jobs INTEGER := 0;
	ln_job_id      INTEGER := 0;
	ln_max_loop    INTEGER := 0;
    ln_orig_org_id VARCHAR2(10);

    lc_phase       VARCHAR2(100);
    lc_status      VARCHAR2(100);
    lc_dev_phase   VARCHAR2(100);
    lc_dev_status  VARCHAR2(100);
    lc_message     VARCHAR2(4000);
	
    CURSOR c_po IS
    SELECT group_id batch_id
          ,header_interface_id
          ,processing_status_code
	  FROM rcv_headers_interface
	 WHERE 1=1
	   AND group_id = p_batch_id;

    TYPE tpo IS TABLE OF c_po%ROWTYPE;

    t_po tpo;

    CURSOR c_org IS
    SELECT DISTINCT
           org_id
      FROM rcv_headers_interface
     WHERE group_id = p_batch_id
       AND org_id IS NOT NULL;

    TYPE torg IS TABLE OF c_org%ROWTYPE;

    t_org torg;

    TYPE rbatch_job IS RECORD
         ( batch_id   INTEGER
          ,job_no     INTEGER
          ,job_status VARCHAR2(100)
         );

    TYPE tbatch_job IS TABLE OF rbatch_job;

    t_batch_job tbatch_job := tbatch_job();

FUNCTION check_completed_jobs RETURN INTEGER IS

  ln_jobs_sub INTEGER:= 0;
  lb_bool     BOOLEAN;

BEGIN

    LOOP

       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP

          IF NVL(t_batch_job(i).job_status,'X') <> 'COMPLETE' THEN
             lb_bool := fnd_concurrent.wait_for_request(request_id => t_batch_job(i).job_no 
                                                       ,interval   => 60
                                                       ,max_wait   => 0
                                                       ,phase      => lc_phase
                                                       ,status     => lc_status
                                                       ,dev_phase  => t_batch_job(i).job_status
                                                       ,dev_status => lc_dev_status
                                                       ,message    => lc_message
                                                       );
             IF t_batch_job(i).job_status = 'COMPLETE' THEN
                ln_jobs_sub := ln_jobs_sub + 1;
                IF ln_jobs_sub = t_batch_job.COUNT THEN
                   RETURN 0;
                END IF;
             END IF;
          ELSE
             ln_max_loop := ln_max_loop + 1;
             IF ln_max_loop > cn_max_loop THEN
                RETURN 1;
             END IF;

          END IF; 

       END LOOP;

    END LOOP;

    RETURN 1;

END check_completed_jobs;

BEGIN


     ln_orig_org_id := FND_PROFILE.VALUE('ORG_ID') ; 

     OPEN c_org;

     FETCH c_org
      BULK COLLECT
      INTO t_org;

     IF t_org.COUNT = 0 THEN
        fnd_file.put_line(fnd_file.log,'Org = 0. Return');
        RETURN 0;
	 END IF;

     FOR i IN t_org.FIRST .. t_org.LAST
     LOOP

           -- set org_id

          dbms_application_info.set_client_info (t_org(i).org_id);

           ---------------------------------------------------------
           -- Submit Concurrent Program for Conversion
           ---------------------------------------------------------
           -- THE XXPOCNVCH concurrent program for Receipts Conversion
       

           ln_job_id := fnd_request.submit_request(application => 'PO'
                                                  ,program     => 'RVCTP'
	                                              ,argument1   => 'BATCH'        -- Node
                                                  ,argument2   => p_batch_id  -- Group Id
                                                  ,argument3   => t_org(i).org_id  --org_id
                                                  );

           COMMIT;

           IF NVL(ln_job_id,0) = 0 THEN
              fnd_file.put_line(fnd_file.log,'Error submitting RVCTP='|| p_batch_id||' '||t_org(i).org_id);
              UPDATE xx_po_rcpts_stg
                 SET process_flag = 6
               WHERE batch_id = p_batch_id
			     AND org_id = t_org(i).org_id
				 AND process_flag = 5;
			  COMMIT;
           ELSE
              fnd_file.put_line(fnd_file.log,'Submitted batch_id='|| p_batch_id ||', job_no='|| ln_job_id||' org_id=['||t_org(i).org_id||']');
              t_batch_job.EXTEND;
              t_batch_job(t_batch_job.LAST).batch_id := p_batch_id;
              t_batch_job(t_batch_job.LAST).job_no := ln_job_id;
              UPDATE xx_po_rcpts_stg
                 SET rvctp_request_id = ln_job_id
               WHERE batch_id = p_batch_id
				 AND process_flag = 5;
              fnd_file.put_line(fnd_file.log,'Updated batch_id='|| p_batch_id ||', rows='|| SQL%ROWCOUNT);
			  COMMIT;
           END IF;

     END LOOP;

     CLOSE c_org;

     -- restore original org_id

     dbms_application_info.set_client_info (ln_orig_org_id);

     IF (NOT t_batch_job.EXISTS(1)) OR t_batch_job.COUNT = 0 THEN
        RETURN 0;
	 END IF;

     -- Loop until all jobs are completed

     IF check_completed_jobs = 1 THEN
        fnd_file.put_line(fnd_file.log,'Loop pass '||cn_max_loop||' iterations');
        RETURN 1;
     ELSE
        fnd_file.put_line(fnd_file.log,'All jobs completed');
	 END IF;

     -- Update accepted PO's

     OPEN c_po;

     LOOP

        FETCH c_po
		 BULK COLLECT
		 INTO t_po LIMIT cn_commit;

        EXIT WHEN t_po.COUNT = 0;

        ---- Headers
        FORALL i IN t_po.FIRST .. t_po.LAST
              UPDATE xx_po_rcpts_stg
                 SET process_flag = DECODE(t_po(i).processing_status_code,'SUCCESS',7,6)
               WHERE header_interface_id = t_po(i).header_interface_id
                 AND batch_id = t_po(i).batch_id
			     AND process_flag = 5;

        ln_failed_process := ln_failed_process + SQL%ROWCOUNT;

        COMMIT;

     END LOOP;

     CLOSE c_po;

     RETURN 0;

END submit_po_import_cp;

-------- MAIN --------
 
BEGIN

    fnd_file.put_line (fnd_file.LOG, 'Parameters ');
    fnd_file.put_line (fnd_file.LOG, ' p_validate_only_flag: ' || p_validate_only_flag);
    fnd_file.put_line (fnd_file.LOG, ' p_batch_id          : ' || p_batch_id);
    fnd_file.put_line (fnd_file.LOG, ' p_reset_status_flag : ' || p_reset_status_flag);
    fnd_file.put_line (fnd_file.LOG, ' p_debug_flag        : ' || p_debug_flag);

    fnd_file.put_line (fnd_file.OUTPUT, 'OD: Receipts Conversion Child Program');
    fnd_file.put_line (fnd_file.OUTPUT, '===================================== ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    BEGIN

       SELECT conversion_id
             ,system_code
	     INTO ln_conversion_id
		     ,lc_system_code
         FROM xx_com_conversions_conv
        WHERE conversion_code = 'CXXXX_PurchaseOrders';
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
           fnd_file.put_line (fnd_file.LOG, 'No data found for CXXXX_PurchaseOrders');
           RAISE;
      WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG, 'Error reading xx_com_conversions_conv, '||sqlerrm);
           RAISE;
    END;

    set_process_status_flag_hdr(p_batch_id
                               ,'1'  -- from
                               ,'2'  -- to
                               );

    set_process_status_flag_txs(p_batch_id
                               ,'1'  -- from
                               ,'2'  -- to
                               );

    ln_read_hdr := 0;
    ln_read_txs := 0;
    ln_write_hdr := 0;
    ln_write_txs := 0;

    ---------- Validate Headers ----------
    fnd_file.put_line(fnd_file.LOG, 'Validate headers=['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');

    IF t_eflag_hdr.EXISTS(1) THEN
	   t_eflag_hdr.DELETE;
	END IF;

    OPEN c_hdr(p_batch_id
              ,2
              ,'N'
              );

    LOOP  -- for header
       FETCH c_hdr
	    BULK COLLECT
	    INTO t_hdr LIMIT cn_commit;

       EXIT WHEN t_hdr.COUNT = 0;

       ln_read_hdr := ln_read_hdr + t_hdr.COUNT;

           --- Validate Derived information

       set_process_status_flag_hdr(p_batch_id
                                  ,'2'  -- from
                                  ,'4'  -- to
                                  );

       FOR i_hdr IN t_hdr.FIRST .. t_hdr.LAST
	   LOOP

          ln_error_flag := 0;  -- no error

          IF t_hdr(i_hdr).vendor_id IS NULL AND t_hdr(i_hdr).process_flag <> 3 THEN
             log_errors (p_error_msg         => 'PO Number not found in po_headers_all'
                        ,p_control_id        => t_hdr(i_hdr).group_id
                        ,p_staging_table     => 'XX_PO_RCPTS_STG'
                        ,p_column            => 'AP_PO_NUMBER'
                        ,p_value             => t_hdr(i_hdr).ap_po_number
                        ,p_oracle_code       => sqlcode
                        ,p_oracle_msg        => sqlerrm
                        ,p_source_system_ref => t_hdr(i_hdr).ap_po_number
                        );
             fnd_file.put_line(fnd_file.LOG,' PO Number not found in po_headers_all=['||t_hdr(i_hdr).ap_po_number||']');
             ln_error_flag := 1;
             UPDATE xx_po_rcpts_stg
                    SET process_flag = 3
              WHERE header_interface_id = t_hdr(i_hdr).header_interface_id
                AND process_flag+0 < 7;
             ln_read_txs := SQL%ROWCOUNT;
             ln_error_txs := SQL%ROWCOUNT;
          END IF;

         -- keep track of invalid rows
         t_eflag_hdr.EXTEND;
         t_eflag_hdr(t_eflag_hdr.COUNT) := ln_error_flag;

         ln_error_hdr := ln_error_hdr + ln_error_flag;

         -------------- Validate Txs
         fnd_file.put_line(fnd_file.LOG, 'Validate Txs=['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');

         IF t_eflag_txs.EXISTS(1) THEN
            t_eflag_txs.DELETE;
         END IF;

         IF c_txs%ISOPEN THEN
            CLOSE c_txs;
         END IF;

--         IF ln_error_flag <> 1 THEN
            OPEN c_txs (p_batch_id
                       ,t_hdr(i_hdr).ap_po_number
                       ,t_hdr(i_hdr).po_header_id
                       ,t_hdr(i_hdr).ap_keyrec
                       ,t_hdr(i_hdr).expected_receipt_date
                       ,t_hdr(i_hdr).receipt_num
                       );

               -- for transaction
            FETCH c_txs
        	 BULK COLLECT
        	 INTO t_txs;

            IF t_txs.COUNT = 0 THEN 
               log_errors (p_error_msg         => 'No valid transactions lines for Header'
                          ,p_control_id        => t_hdr(i_hdr).control_id
                          ,p_staging_table     => 'XX_PO_RCPTS_STG'
                          ,p_column            => 'AP_PO_NUMBER'
                          ,p_value             => t_hdr(i_hdr).ap_po_number
                          ,p_oracle_code       => sqlcode
                          ,p_oracle_msg        => sqlerrm
                          ,p_source_system_ref => t_hdr(i_hdr).ap_po_number
                          );        
               fnd_file.put_line(fnd_file.LOG,'Invalid Header for Transaction='||t_hdr(i_hdr).header_interface_id||', '||
                                              ' Po No=['||t_hdr(i_hdr).ap_po_number||']');
       	       UPDATE xx_po_rcpts_stg
                  SET process_flag = 3
                WHERE header_interface_id = t_hdr(i_hdr).header_interface_id
                  AND process_flag NOT IN (3,7,9);
               t_hdr(i_hdr).process_flag := 3;
            ELSE
               fnd_file.put_line(fnd_file.LOG, 'Txs read='||t_txs.COUNT);

               ln_read_txs := ln_read_txs + t_txs.COUNT;

               FOR i_txs IN t_txs.FIRST .. t_txs.LAST
               LOOP

                  ln_error_flag := 0;  -- no error

                  IF t_eflag_hdr(i_hdr) = 1 THEN
                     log_errors (p_error_msg         => 'Invalid Header for Transaction'
                                ,p_control_id        => t_txs(i_txs).control_id
                                ,p_staging_table     => 'XX_PO_RCPTS_STG'
                                ,p_column            => 'AP_PO_LINE_NO'
                                ,p_value             => t_txs(i_txs).ap_po_line_no
                                ,p_oracle_code       => sqlcode
                                ,p_oracle_msg        => sqlerrm
                                ,p_source_system_ref => t_hdr(i_hdr).ap_po_number
                                );        
                     fnd_file.put_line(fnd_file.LOG,'Invalid Header for Transaction='||t_hdr(i_hdr).header_interface_id||', '||
                                                    ' Po No=['||t_hdr(i_hdr).ap_po_number||'], Line=['||t_txs(i_txs).ap_po_line_no||']');
                     ln_error_flag := 1;
                  ELSIF t_txs(i_txs).line_num IS NULL THEN
                        log_errors (p_error_msg         => 'Transactions for the PO not found'
                                   ,p_control_id        => t_txs(i_txs).control_id
                                   ,p_staging_table     => 'XX_PO_RCPTS_STG'
                                   ,p_column            => 'AP_PO_LINE_NO'
                                   ,p_value             => t_txs(i_txs).ap_po_line_no
                                   ,p_oracle_code       => sqlcode
                                   ,p_oracle_msg        => sqlerrm
                                   ,p_source_system_ref => t_hdr(i_hdr).ap_po_number
                             );        
                        fnd_file.put_line(fnd_file.LOG,'Transactions for the PO not found'||t_hdr(i_hdr).header_interface_id||', '||
                                                       ' Po No=['||t_hdr(i_hdr).ap_po_number||'], Line=['||t_txs(i_txs).ap_po_line_no||']');
                        ln_error_flag := 1;
                  END IF;

                  -- keep track of invalid rows
                  t_eflag_txs.EXTEND;
                  t_eflag_txs(t_eflag_txs.COUNT) := ln_error_flag;

                  ln_error_txs := ln_error_txs + ln_error_flag;

                  IF ln_error_flag = 1 THEN
                     t_hdr(i_hdr).process_flag := 3;
                  END IF;

               END LOOP;

               -- set status to 3 for invalid rows
               FORALL i_txs IN t_txs.FIRST .. t_txs.LAST
           	       UPDATE xx_po_rcpts_stg
                         SET process_flag = 3
                       WHERE header_interface_id = t_hdr(i_hdr).header_interface_id
                         AND process_flag NOT IN (3,7,9)
           		         AND t_eflag_txs(i_txs) = 1;

               COMMIT;

            END IF;

            IF c_txs%ISOPEN THEN
               CLOSE c_txs;
            END IF;

            IF p_validate_only_flag <> 'Y' THEN
               insert_rcvs(i_hdr);
            END IF;

--         END IF;

       END LOOP;  -- header

    END LOOP;

    IF c_hdr%ISOPEN THEN
	   CLOSE c_hdr;
	END IF;

    set_process_status_flag_hdr(p_batch_id
                              ,'4'  -- from
                              ,'5'  -- to
                               );

    -- Mark as an error any unprocessed, transaction

    set_process_status_flag_hdr(p_batch_id
                               ,'2'  -- from
                               ,'3'  -- to
                                       );


    fnd_file.put_line (fnd_file.LOG, 'End of Validation, ['||to_char(sysdate,'mm/dd/yy hh24:mi:ss')||']');

    IF p_validate_only_flag <> 'Y' THEN

       fnd_file.put_line (fnd_file.LOG, 'Calling submit receipts.');

       IF submit_po_import_cp = 1 THEN
       set_process_status_flag_txs(p_batch_id  -- submitted job ends with error
                                  ,'5'  -- from
                                  ,'6'  -- to
                                  );
       END IF;
    END IF;


    fnd_file.put_line (fnd_file.LOG, 'Total no. of Receipts Header Records     - '||lpad(to_char(ln_read_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.LOG, 'No. of Receipts Header Records Processed - '||lpad(to_char(ln_write_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.LOG, 'No. of Receipts Header Records Erroed    - '||lpad(to_char(ln_error_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.LOG, 'Total no. of Receipts Txs Records        - '||lpad(to_char(ln_read_txs,'99,999,990'),12));
    fnd_file.put_line (fnd_file.LOG, 'No. of Receipts Txs Records Processed    - '||lpad(to_char(ln_write_txs,'99,999,990'),12));
    fnd_file.put_line (fnd_file.LOG, 'No. of Receipts Txs Records Erroed       - '||lpad(to_char(ln_error_txs,'99,999,990'),12));

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, 'Total no. of Receipts Header Records     - '||lpad(to_char(ln_read_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of Receipts Header Records Processed - '||lpad(to_char(ln_write_hdr,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of Receipts Header Records Erroed    - '||lpad(to_char(ln_error_hdr,'99,999,990'),12));

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    fnd_file.put_line (fnd_file.OUTPUT, 'Total no. of Receipts Txs Records        - '||lpad(to_char(ln_read_txs,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of Receipts Txs Records Processed    - '||lpad(to_char(ln_write_txs,'99,999,990'),12));
    fnd_file.put_line (fnd_file.OUTPUT, 'No. of Receipts Txs Records Erroed       - '||lpad(to_char(ln_error_txs,'99,999,990'),12));

    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');
    fnd_file.put_line (fnd_file.OUTPUT, ' ');

    xx_com_conv_elements_pkg.upd_control_info_proc(fnd_global.conc_request_id
	                                              ,p_batch_id
												  ,'1.0'
                                                  ,ln_error_hdr + ln_error_txs
												  ,ln_failed_process
												  ,ln_write_hdr+ln_write_txs
                                                  );
    x_retcode := 0;

EXCEPTION

      WHEN OTHERS THEN
	       ROLLBACK;
           fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
           fnd_file.put_line (fnd_file.LOG,sqlerrm);
           fnd_file.put_line (fnd_file.LOG,'Error in process aborted.');

           IF c_hdr%ISOPEN THEN
              CLOSE c_hdr;
           END IF;

           IF c_txs%ISOPEN THEN
              CLOSE c_txs;
           END IF;

           IF NOT (p_validate_only_flag = 'Y' OR p_reset_status_flag = 'Y') THEN
              set_process_status_flag_hdr(p_batch_id
                                         ,'5'  -- from
                                         ,'6'  -- to
                                         );
           END IF;

           x_retcode := 1;

           RAISE;

END child_main;

END xx_po_rcv_conv_pkg;
/