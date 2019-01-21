CREATE OR REPLACE PACKAGE BODY XX_AR_VENDOR_COMP_INV_EXTRACT
-- +============================================================================================+
-- |                      Office Depot - Project Simplify                                       |
-- +============================================================================================+
-- |  Name              :  XX_AR_VENDOR_COMP_INV_EXTRACT                                        |
-- |  Description       :  Package to extract AR Vendor Compliance Invoice Extract				|
-- |  Change Record     :                                                                       |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
AS
    gc_debug       VARCHAR2(2)                                 := 'N';
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
    PROCEDURE print_debug_msg(
        p_message  IN  VARCHAR2,
        p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        IF (   gc_debug = 'Y'
            OR p_force)
        THEN
            lc_message := p_message;
            fnd_file.put_line(fnd_file.LOG,
                              lc_message);

            IF (   fnd_global.conc_request_id = 0
                OR fnd_global.conc_request_id = -1)
            THEN
                DBMS_OUTPUT.put_line(lc_message);
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
    PROCEDURE print_out_msg(
        p_message  IN  VARCHAR2)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    BEGIN
        lc_message := p_message;
        fnd_file.put_line(fnd_file.output,
                          lc_message);

        IF (   fnd_global.conc_request_id = 0
            OR fnd_global.conc_request_id = -1)
        THEN
            DBMS_OUTPUT.put_line(lc_message);
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
    PROCEDURE vps_netting_extract(
        p_errbuf       OUT     VARCHAR2,
        p_retcode      OUT     VARCHAR2,
		p_run_date	   IN      DATE,
        p_debug        IN      VARCHAR2)
    AS
        CURSOR netting_extract_cur(
            p_start_date   DATE,
            p_end_date     DATE)
        IS
			SELECT  Acr.Receipt_Number Receipt_Number,
					Rct.Trx_Number Trx_Number,
					TO_CHAR(Acr.Receipt_Date,'YYYYMMDD') Receipt_Date
			FROM  Ra_Customer_Trx_All Rct,
				  Ar_Cash_Receipts_All Acr,
				  Ar_Receivable_Applications_All Ara
			WHERE 1             =1
			AND Rct.Attribute5 IN ('VCM' ,'ASN')
			AND Rct.Trx_Date BETWEEN p_start_date AND p_end_date
			--AND RCT.TRX_NUMBER  = '474881104001'
			AND Ara.Applied_Customer_Trx_Id   = Rct.Customer_Trx_Id
			AND Ara.Status                    = 'APP'
			AND Amount_Applied                > 0
			AND Ara.Cash_Receipt_Id           = Acr.Cash_Receipt_Id
			AND Ara.receivable_application_id =
			  (SELECT MAX(receivable_application_id)
			  FROM Ar_Receivable_Applications_All
			  WHERE 1                    =1
			  AND Cash_Receipt_Id        = Ara.Cash_Receipt_Id
			  AND Applied_Customer_Trx_Id=Rct.Customer_Trx_Id
			  );

        TYPE netting_extract_tab_type IS TABLE OF netting_extract_cur%ROWTYPE;

        CURSOR get_dir_path
        IS
            SELECT directory_path
            FROM   dba_directories
            WHERE  directory_name = 'XXFIN_OUTBOUND';

        l_netting_extract_tab         netting_extract_tab_type;
        lf_netting_file               UTL_FILE.file_type;
		lf_control_file               UTL_FILE.file_type;
        lc_netting_file_header        VARCHAR2(32000);
        lc_netting_file_content       VARCHAR2(32000);
        lc_control_file_header        VARCHAR2(32000);
        lc_control_file_content       VARCHAR2(32000);
        ln_chunk_size                 BINARY_INTEGER             := 32767;
        lc_netting_file_name          VARCHAR2(250)              := TO_CHAR(SYSDATE,'yyyymmddhh24mmss')||'_NETTING';
		lc_control_file_name          VARCHAR2(250)              := TO_CHAR(SYSDATE,'yyyymmdd')||'_NETTING_MARKER';
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
        p_start_date                  DATE;	--VARCHAR2(20);
        p_end_date                    DATE;	--VARCHAR2(20);
        lc_error_msg                  VARCHAR2(2000)             := NULL;
        data_exception                EXCEPTION;
        lc_file_handle                UTL_FILE.file_type;
		lc_rec_count				  NUMBER;
		lc_cur_time	        		  VARCHAR2(100);
    BEGIN
        xla_security_pkg.set_security_context(602);
        gc_debug := p_debug;
        gn_request_id := fnd_global.conc_request_id;
        gn_user_id := fnd_global.user_id;
        gn_login_id := fnd_global.login_id;
		print_debug_msg('Begin - vps_netting_extract',
                        TRUE);

        --get file dir path
        OPEN get_dir_path;

        FETCH get_dir_path
        INTO  lc_dirpath;

        CLOSE get_dir_path;

        SELECT SUBSTR(LOWER(SYS_CONTEXT('USERENV',
                                        'INSTANCE_NAME') ),
                      1,
                      8)
        INTO   lc_instance_name
        FROM   DUAL;

        lc_netting_file_name :=    lc_netting_file_name
                                   || '.dat';
        
		print_out_msg(   'Processing for Date :'
                      || p_run_date);
        print_debug_msg(   'Processing for Date :'
                        || p_run_date,
                        TRUE);
        SELECT NAME
        INTO   lc_file_name_instance
        FROM   v$database;

        BEGIN
			SELECT start_date,	--	TO_CHAR(start_date,'YYYY-MM-DD') start_date,
				   end_date		--	TO_CHAR(end_date,'YYYY-MM-DD') end_date
			INTO   p_start_date,
                   p_end_date
			FROM GL_PERIODS gp
			WHERE 1=1
			AND (Period_Num, period_year)                       IN
				(SELECT EXTRACT (MONTH FROM (ADD_MONTHS (end_date, -1))) xx_temp,
					 period_year
				FROM GL_PERIODS gp
				WHERE 1=1
				AND p_run_date BETWEEN START_DATE AND END_DATE
				);
		
        EXCEPTION
            WHEN OTHERS
            THEN
                lc_error_msg :=
                    (   'Exception Raised while getting start date and end date for Run Date '
                     || SUBSTR(SQLERRM,
                               1,
                               3800)
                     || SQLCODE);
                print_debug_msg(lc_error_msg,
                                TRUE);
        END;
		print_out_msg(   'Extracting for Period Start Date : '
                      || p_start_date||' End Date : '||p_end_date);
        print_debug_msg( 'Extracting for Period Start Date : '
                      || p_start_date||' and End Date : '||p_end_date,
                        TRUE);
        OPEN netting_extract_cur(  p_start_date,
                                   p_end_date);

        FETCH netting_extract_cur
        BULK COLLECT INTO l_netting_extract_tab;

        CLOSE netting_extract_cur;

        print_debug_msg(   'Vendor Compliance Invoice Extract Count :'
                        || l_netting_extract_tab.COUNT,
                        TRUE);
        print_out_msg(   'Vendor Compliance Invoice Extract Count :'
                      || l_netting_extract_tab.COUNT);

        IF l_netting_extract_tab.COUNT > 0
        THEN
            BEGIN
				print_out_msg(' ');
				print_debug_msg(' ');
				print_out_msg(   'Extracting Vendor Compliance Invoice Data into file :'
									|| lc_netting_file_name);
				print_debug_msg(   'Extracting Vendor Compliance Invoice Data into file :'
									|| lc_netting_file_name,
									TRUE);
				lc_control_file_name :=    lc_control_file_name
											|| '.dat';
                lf_netting_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
                                               lc_netting_file_name,
                                               'w',
                                               ln_chunk_size);

                FOR i IN 1 .. l_netting_extract_tab.COUNT
                LOOP
                    lc_netting_file_content :=
                           l_netting_extract_tab(i).Receipt_Number
                        || lc_delimeter
                        || l_netting_extract_tab(i).Trx_Number
                        || lc_delimeter
                        || l_netting_extract_tab(i).Receipt_Date
						|| lc_delimeter
						|| 'X';
                    UTL_FILE.put_line(lf_netting_file,
                                      lc_netting_file_content);
                END LOOP;

                UTL_FILE.fclose(lf_netting_file);
                print_out_msg(   'Vendor Compliance Invoice File Created: '
                              || lc_netting_file_name);
                print_debug_msg(   'Vendor Compliance Invoice File Created: '
                                || lc_netting_file_name);
                -- copy to Vendor Compliance invoice file to xxfin_data/Vendor_Comp dir
                lc_dest_file_name :=    '/app/ebs/ct'
                                     || lc_instance_name
                                     || '/xxfin/ftp/out/Vendor_Comp/'
                                     || lc_netting_file_name;
                ln_conc_file_copy_request_id :=
                    fnd_request.submit_request('XXFIN',
                                               'XXCOMFILCOPY',
                                               '',
                                               '',
                                               FALSE,
                                                  lc_dirpath
                                               || '/'
                                               || lc_netting_file_name,   --Source File Name
                                               lc_dest_file_name,   --Dest File Name
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
		
		lc_rec_count	:=	l_netting_extract_tab.COUNT	;
		lc_cur_time		:=	TO_CHAR(sysdate,'HH24MISS');
						
		IF l_netting_extract_tab.COUNT > 0
        THEN
            BEGIN
				print_out_msg(' ');
				print_debug_msg(' ');
				print_out_msg(   'Extracting Control File Data :'
								|| lc_control_file_name);
				print_debug_msg(   'Extracting Control File Data :'
								|| lc_control_file_name,
								TRUE);
                lf_control_file := UTL_FILE.fopen('XXFIN_OUTBOUND',
                                               lc_control_file_name,
                                               'w',
                                               ln_chunk_size);
                    lc_control_file_content :=
                           RPAD(lc_netting_file_name, 50)
                        || RPAD(lc_rec_count, 13)
                        || TO_CHAR(SYSDATE,'yyyymmdd')
                        || lc_cur_time
                        || 'X';
                    UTL_FILE.put_line(lf_control_file,
                                      lc_control_file_content);

                UTL_FILE.fclose(lf_control_file);
                print_out_msg(   'Vendor Compliance Control File Created: '
                              || lc_control_file_name);
                print_debug_msg(   'Vendor Compliance Control File Created: '
                                || lc_control_file_name);
                -- copy to Vendor Compliance invoice file to xxfin_data/Vendor_Comp dir
                lc_dest_file_name :=    '/app/ebs/ct'
                                     || lc_instance_name
                                     || '/xxfin/ftp/out/Vendor_Comp/'
                                     || lc_control_file_name;
                ln_conc_file_copy_request_id :=
                    fnd_request.submit_request('XXFIN',
                                               'XXCOMFILCOPY',
                                               '',
                                               '',
                                               FALSE,
                                                  lc_dirpath
                                               || '/'
                                               || lc_control_file_name,   --Source File Name
                                               lc_dest_file_name,   --Dest File Name
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

        print_debug_msg('End - vps_netting_extract',
                        TRUE);
    EXCEPTION
        WHEN data_exception
        THEN
            p_retcode := 2;
            p_errbuf := lc_error_msg;
        WHEN UTL_FILE.access_denied
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' access_denied :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.delete_failed
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' delete_failed :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.file_open
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' file_open :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.internal_error
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' internal_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filehandle
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_filehandle :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_filename
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_filename :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_maxlinesize
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_maxlinesize :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_mode
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_mode :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_offset
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_offset :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_operation
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_operation :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.invalid_path
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' invalid_path :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.read_error
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' read_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.rename_failed
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' rename_failed :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN UTL_FILE.write_error
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' write_error :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
        WHEN OTHERS
        THEN
            lc_error_msg :=
                (   'AR Vendor Compliance Invoice Extract Errored :- '
                 || ' OTHERS :: '
                 || SUBSTR(SQLERRM,
                           1,
                           3800)
                 || SQLCODE);
            print_debug_msg(   'End - populate_gl_out_file - '
                            || lc_error_msg,
                            TRUE);
            UTL_FILE.fclose_all;
            lc_file_handle := UTL_FILE.fopen(lc_dirpath,
                                             lc_netting_file_name,
                                             'W',
                                             32767);
            UTL_FILE.fclose(lc_file_handle);
            p_errbuf := SUBSTR(SQLERRM,
                               1,
                               150);
            p_retcode := 2;
    END vps_netting_extract;
END XX_AR_VENDOR_COMP_INV_EXTRACT;
/