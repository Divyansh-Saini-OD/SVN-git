CREATE OR REPLACE PACKAGE BODY XX_AR_VPS_CORE_OPEN_TRXS_PKG
-- +============================================================================================+
-- |                      Office Depot - Project Simplify                                       |
-- +============================================================================================+
-- |  Name              :  XX_AR_VPS_CORE_OPEN_TRXS_PKG                                         |
-- |  Description       :  Package to Extract VPS CORE Open Transactions       				    |
-- |  Change Record     :                                                                       |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    =================================================|
-- | 1.0         30-JAN-2020  Havish Kasina    Initial draft version                            |
-- +============================================================================================+
AS
    gc_debug       VARCHAR2(2)                               := 'N';
    gn_request_id  fnd_concurrent_requests.request_id%TYPE;
    gn_user_id     fnd_concurrent_requests.requested_by%TYPE;
    gn_login_id    NUMBER;

    /*********************************************************************
    * Procedure used to log based on gb_debug value or if p_force is TRUE.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program log file.  Will prepend
    * time stamp to each message logged.  This is useful for determining
    * elapse times.
    *********************************************************************/
    PROCEDURE print_debug_msg( p_message  IN  VARCHAR2,
                               p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        IF ( gc_debug = 'Y' OR p_force)
        THEN
            lc_message := p_message;
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_message);

            IF ( FND_GLOBAL.CONC_REQUEST_ID = 0
                OR FND_GLOBAL.CONC_REQUEST_ID = -1)
            THEN
                DBMS_OUTPUT.PUT_LINE(lc_message);
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
    PROCEDURE print_out_msg( p_message  IN  VARCHAR2)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        lc_message := p_message;
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_message);

        IF ( FND_GLOBAL.CONC_REQUEST_ID = 0
            OR FND_GLOBAL.CONC_REQUEST_ID = -1)
        THEN
            DBMS_OUTPUT.PUT_LINE(lc_message);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_out_msg;

-- +======================================================================+
-- | Name        :  vps_netting_extract                                   |
-- | Description :  This procedure will be called from the concurrent prog|
-- |                "OD : US VPS Vendor Compliance Invoices Extract"      |
-- |                to extract AR Vendor Compliance Invoice Extract       |
-- |                                                                      |
-- | Parameters  :  Period Name, Debug Flag                               |
-- |                                                                      |
-- | Returns     :  x_errbuf, x_retcode                                   |
-- |                                                                      |
-- +======================================================================+
    PROCEDURE get_core_trxs( p_errbuf       OUT     VARCHAR2,
                             p_retcode      OUT     VARCHAR2,
                             p_debug        IN      VARCHAR2)
    AS
        CURSOR vps_core_open_trxs_cur(p_org_id NUMBER)
        IS
		  SELECT  rcta.attribute14            program_id
                 ,rctt.name                   transaction_type
                 ,rcta.attribute1             vendor_number
                 ,rcta.trx_number             invoice_number
                 ,apsa.amount_due_remaining   amount_due
            FROM ar_payment_schedules_all apsa,
                 ra_customer_trx_all rcta,
                 ra_cust_trx_types_all rctt,
		  	     xx_fin_translatevalues vals,
                 xx_fin_translatedefinition defn
           WHERE 1 = 1
             AND rcta.attribute14 IS NOT NULL
             AND apsa.status = 'OP'
             AND apsa.amount_due_remaining > 0
		     AND apsa.org_id = p_org_id
             AND apsa.customer_trx_id = rcta.customer_trx_id
             AND apsa.customer_id = rcta.bill_to_customer_id
             AND rcta.cust_trx_type_id  = rctt.cust_trx_type_id
		     AND rctt.name = vals.source_value1
		     AND vals.TRANSLATE_ID = defn.TRANSLATE_ID  
             AND defn.TRANSLATION_NAME  = 'OD_VPS_CORE_TRX_TYPES' 
           ORDER BY rcta.creation_date;

        TYPE vps_core_open_trxs_tab_type IS TABLE OF vps_core_open_trxs_cur%ROWTYPE;

        CURSOR get_dir_path
        IS
          SELECT directory_path
            FROM dba_directories
           WHERE directory_name = 'XXFIN_OUTBOUND';
        
		ln_org_id                     hr_operating_units.organization_id%TYPE;
        l_vps_core_open_trxs_tab      vps_core_open_trxs_tab_type;
        lf_trxs_extract_file          UTL_FILE.file_type;
        lc_trxs_file_header           VARCHAR2(32000)            := NULL;
        lc_trxs_file_content          VARCHAR2(32000)            := NULL;
        ln_chunk_size                 BINARY_INTEGER             := 32767;
        lc_trxs_file_name             VARCHAR2(250)              := 'od_vps_core_open_transactions_'||TO_CHAR(SYSDATE,'yyyymmddhh24mmss')||'.txt';
        lc_dest_file_name             VARCHAR2(200);
        ln_conc_file_copy_request_id  NUMBER;
        lc_dirpath                    VARCHAR2(500);
        lc_file_name_instance         VARCHAR2(250);
        lc_instance_name              VARCHAR2(30);
        lb_complete                   BOOLEAN;
        lc_phase                      VARCHAR2(100);
        lc_status                     VARCHAR2(100);
        lc_dev_phase                  VARCHAR2(100);
        lc_dev_status                 VARCHAR2(100);
        lc_message                    VARCHAR2(100);
        lc_delimeter                  VARCHAR2(1)                := '|';
        lc_error_msg                  VARCHAR2(2000)             := NULL;
        data_exception                EXCEPTION;
        lc_file_handle                UTL_FILE.file_type;
    
	BEGIN
        xla_security_pkg.set_security_context(602);
        gc_debug := p_debug;
        gn_request_id := fnd_global.conc_request_id;
        gn_user_id := fnd_global.user_id;
        gn_login_id := fnd_global.login_id;
		print_debug_msg('Begin - get_core_trxs_extract',TRUE);

        --To get the file dir path
        OPEN  get_dir_path;
        FETCH get_dir_path INTO lc_dirpath;
        CLOSE get_dir_path;
		
		SELECT organization_id
          INTO ln_org_id
          FROM hr_all_organization_units
         WHERE name='OU_US_VPS'
       ;

        SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV','DB_NAME') ),1,8)
          INTO lc_instance_name
          FROM DUAL;

        OPEN  vps_core_open_trxs_cur(ln_org_id);
        FETCH vps_core_open_trxs_cur BULK COLLECT INTO l_vps_core_open_trxs_tab;
        CLOSE vps_core_open_trxs_cur;

        print_debug_msg('VPS CORE Open Transactions Extract Count :'|| l_vps_core_open_trxs_tab.COUNT,TRUE);
        print_out_msg('VPS CORE Open Transactions Extract Count :'|| l_vps_core_open_trxs_tab.COUNT);

        IF l_vps_core_open_trxs_tab.COUNT > 0
        THEN
            BEGIN
				print_out_msg(' ');
				print_debug_msg(' ');
				print_out_msg('Extracting VPS CORE Open Transactions Data into file :' || lc_trxs_file_name);
				print_debug_msg('Extracting VPS CORE Open Transactions Data into file :'|| lc_trxs_file_name,TRUE);
                lf_trxs_extract_file := UTL_FILE.FOPEN('XXFIN_OUTBOUND',lc_trxs_file_name,'W',ln_chunk_size);
				lc_trxs_file_header :=      'PROGRAM_ID'
                                           || lc_delimeter
                                           || 'TRANSACTION_TYPE'
                                           || lc_delimeter
                                           || 'VENDOR_NUMBER'
						                   || lc_delimeter
						                   || 'INVOICE_NUMBER'
										   || lc_delimeter
						                   || 'AMOUNT_DUE';
               UTL_FILE.PUT_LINE(lf_trxs_extract_file,
					             lc_trxs_file_header);

                FOR i IN 1 .. l_vps_core_open_trxs_tab.COUNT
                LOOP
				    lc_trxs_file_content := NULL;
                    lc_trxs_file_content :=   l_vps_core_open_trxs_tab(i).program_id
                                           || lc_delimeter
                                           || l_vps_core_open_trxs_tab(i).transaction_type
                                           || lc_delimeter
                                           || l_vps_core_open_trxs_tab(i).vendor_number
						                   || lc_delimeter
						                   || l_vps_core_open_trxs_tab(i).invoice_number
										   || lc_delimeter
						                   || l_vps_core_open_trxs_tab(i).amount_due;
                    UTL_FILE.PUT_LINE(lf_trxs_extract_file,
                                      lc_trxs_file_content);
                END LOOP;

                UTL_FILE.FCLOSE(lf_trxs_extract_file);
                print_out_msg('VPS CORE Open Transactions File Created: '|| lc_trxs_file_name);
                print_debug_msg('VPS CORE Open Transactions File Created: '|| lc_trxs_file_name);
                -- copy to Vendor Compliance invoice file to xxfin_data/VPS dir
                lc_dest_file_name :=    '/app/ebs/ct'
                                     || lc_instance_name
                                     || '/xxfin/ftp/out/vps/'
                                     || lc_trxs_file_name;
                ln_conc_file_copy_request_id :=
                    fnd_request.submit_request('XXFIN',
                                               'XXCOMFILCOPY',
                                               '',
                                               '',
                                               FALSE,
                                                  lc_dirpath
                                               || '/'
                                               || lc_trxs_file_name,   -- Source File Name
                                               lc_dest_file_name,      -- Dest File Name
                                               '',
                                               '',
                                               'Y'   --Deleting the Source File
                                               );

                IF ln_conc_file_copy_request_id > 0
                THEN
                    COMMIT;
                    -- wait for request to finish
                    lb_complete :=
                        fnd_concurrent.wait_for_request(request_id =>      ln_conc_file_copy_request_id,
                                                        INTERVAL =>        10,
                                                        max_wait =>        0,
                                                        phase =>           lc_phase,
                                                        status =>          lc_status,
                                                        dev_phase =>       lc_dev_phase,
                                                        dev_status =>      lc_dev_status,
                                                        MESSAGE =>         lc_message);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    fnd_file.put_line(fnd_file.LOG,
                                         SQLCODE
                                      || SQLERRM);
            END;
        END IF;

        print_debug_msg('End - get_core_trxs_extract', TRUE);
    EXCEPTION
        WHEN data_exception
        THEN
            p_retcode := 2;
            p_errbuf := lc_error_msg;
        WHEN UTL_FILE.access_denied
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' access_denied :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.delete_failed
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' delete_failed :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.file_open
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' file_open :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.internal_error
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' internal_error :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filehandle
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_filehandle :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filename
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_filename :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_maxlinesize
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_maxlinesize :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_mode
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_mode :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_offset
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_offset :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_operation
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_operation :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_path
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' invalid_path :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.read_error
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' read_error :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.rename_failed
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' rename_failed :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN UTL_FILE.write_error
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' write_error :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
        WHEN OTHERS
        THEN
            lc_error_msg := ('VPS CORE Open Transactions Extract Errored :- '|| ' OTHERS :: '|| SUBSTR(SQLERRM,1,3800)|| SQLCODE);
            print_debug_msg(   'End - populate_gl_out_file - '|| lc_error_msg,TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_trxs_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,1,150);
            p_retcode := 2;
    END get_core_trxs;
END XX_AR_VPS_CORE_OPEN_TRXS_PKG;
/
SHOW ERRORS;