  CREATE OR REPLACE PACKAGE BODY xx_ap_sua_pmnt_intf_pkg
    -- +=========================================================================+
    -- |                  Office Depot - Project Simplify                        |
    -- |                  Office Depot                                           |
    -- +=========================================================================+
    -- | Name             : XX_AP_SUA_PMNT_INTF_PKG                              |
    -- | Description      : This plsql package has procedure processing          |
    -- |                    SUA Payments to JPM                                  |
    -- |                                                                         |
    -- |Change Record:                                                           |
    -- |===============                                                          |
    -- |Version    Date          Author            Remarks                       |
    -- |=======  ==========    =============     ==============================  |
    -- | 1.0      25-JAN-2021   Paddy Sanjeevi    Initial code                   |
    -- | 1.1      03-FEB-2021   Mayur Palsokar    Modified submit_payment_process|
    -- |                                          and xx_process_payment         |
    -- | 1.2      03-FEB-2021   Manjush D H       Added load_recon_data          |
    -- | 1.3      12-FEB-2021   Mayur Palsokar    Added process_recon_data       |
    -- | 1.4      16-FEB-2021   Manjush D H       Added xx_purge_recon_staging   |
    -- | 1.5      17-FEB-2021   Mayur Palsokar    Added encryption logic to xx_process_payment|
    -- +=========================================================================+
  AS
    gb_debug        BOOLEAN         := FALSE;
    gc_max_log_size CONSTANT NUMBER := 2000;
	
  TYPE gt_input_parameters
  IS
    TABLE OF VARCHAR2(32000) INDEX BY VARCHAR2(255);
	
  TYPE varchar2_table
  IS
    TABLE OF VARCHAR2(32767) INDEX BY binary_integer;
	
    -- +============================================================================================+
    -- | Name  : print_debug_msg                                                               |
    -- | * Procedure used to log based on gb_debug value or if p_force is TRUE.
    -- | Will log to dbms_output if request id is not set,
    -- | else will log to concurrent program log file.  Will prepend
    -- | timestamp to each message logged.  This is useful for determining
    -- | elapse times.                 |
    -- =============================================================================================|
  PROCEDURE print_debug_msg(
      p_message IN VARCHAR2,
      p_force   IN BOOLEAN DEFAULT FALSE )
  IS
    lc_message VARCHAR2(4000) := NULL;
  BEGIN
    IF (gb_debug OR p_force) THEN
      lc_message :=p_message;
      fnd_file.put_line(fnd_file.LOG,lc_message);
      IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
        dbms_output.put_line(lc_message);
      END IF;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END print_debug_msg;
  
  
  -- +============================================================================================+
  -- |  Name  : print_out_msg                                                               |
  -- |  * Procedure used to out the text to the concurrent program.
  -- |* Will log to dbms_output if request id is not set,
  -- |* else will log to concurrent program output file.
  -- =============================================================================================|
  PROCEDURE print_out_msg(
      p_message IN VARCHAR2)
  IS
    lc_message VARCHAR2(4000) := NULL;
  BEGIN
    lc_message :=p_message;
    fnd_file.put_line(fnd_file.output, lc_message);
    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line(lc_message);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END print_out_msg;
  
  
  -- +============================================================================================+
  -- |  Name  : logit                                                               |
  -- |  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  -- |* Will log to dbms_output if request id is not set,
  -- |* else will log to concurrent program log file.  Will prepend
  -- |* timestamp to each message logged.  This is useful for determining
  -- |* elapse times.
  -- =============================================================================================|
  PROCEDURE logit(
      p_message IN VARCHAR2,
      p_force   IN BOOLEAN DEFAULT TRUE)
  IS
    lc_message VARCHAR2(2000) := NULL;
  BEGIN
    --if debug is on (defaults to true)
    IF (gb_debug OR p_force) THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF') || ' => ' || p_message, 1, gc_max_log_size);
      -- if in concurrent program, print to log file
      IF (fnd_global.conc_request_id > 0) THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
        -- else print to DBMS_OUTPUT
      ELSE
        dbms_output.put_line(lc_message);
      END IF;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    NULL;
  END logit;
  
  
  -- +============================================================================================+
  -- |  Name  : INSERT_FILE_REC                                                               |
  -- |  * file record creation for uplicate Check
  -- |* Table : xx_ap_sua_intf_files
  -- =============================================================================================|
  PROCEDURE insert_file_rec(
      p_process_name VARCHAR2,
      p_file_name    VARCHAR2,
      p_request_id   NUMBER,
      p_error_msg    VARCHAR2,
      p_user_id      NUMBER)
  IS
    lc_procedure_name CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'INSERT_FILE_REC';
  BEGIN
    logit(p_message =>'Inside Procedure call INSERT_FILE_REC');
    INSERT
    INTO xx_ap_sua_intf_files
      (
        process_name,
        file_name,
        creation_date,
        created_by,
        last_updated_by,
        last_update_date,
        request_id,
        error_description
      )
      VALUES
      (
        p_process_name,
        p_file_name,
        SYSDATE,
        p_user_id,
        p_user_id,
        SYSDATE,
        p_request_id,
        p_error_msg
      );
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    logit(p_message => 'ERROR-SQLCODE:'|| SQLCODE || ' SQLERRM: ' || sqlerrm, p_force => TRUE);
  END insert_file_rec;
  
  
  -- +============================================================================+
  -- | Procedure Name : xx_process_payments                                       |
  -- |                                                                            |
  -- | Description    : Procedure to transfer payment file to outbound dir,       |
  -- |                  archieve dir                                              |
  -- |                                                                            |
  -- +============================================================================+
  PROCEDURE xx_process_payment
    (
      p_request_id IN NUMBER
    )
  IS
    ln_request_id        NUMBER:= p_request_id;
    lc_fpi_output_file   VARCHAR2(500);
    ln_conc_request_id   NUMBER DEFAULT NULL;
    lb_sub_request       BOOLEAN DEFAULT FALSE;
    lc_dest_file         VARCHAR2(500);
    lc_out_dir           VARCHAR2(200);
    lc_encr_out_dir      VARCHAR2(200);
    lc_archive_dir       VARCHAR2(200);
    lc_file_name         VARCHAR2(200);
    l_filedir            VARCHAR2(20) ;
    l_dirpath            VARCHAR2(500);
    l_user_id            NUMBER         := fnd_global.user_id;
    l_login_id           NUMBER         := fnd_global.login_id;
    l_error_msg          VARCHAR2(1000) := NULL;
    l_retcode            VARCHAR2(3)    := NULL;
    lb_req_return_status BOOLEAN;
    lc_phase             VARCHAR2(100);
    lc_status            VARCHAR2(100);
    lc_dev_phase         VARCHAR2(100);
    lc_dev_status        VARCHAR2(100);
    b_sub_request        BOOLEAN:= FALSE;
    lc_message           VARCHAR2 (1000);
    lb_result            BOOLEAN;
    lc_key               VARCHAR2 (100);
    lc_encrypt_file_flag VARCHAR2 (1);
    ln_encr_request_id   NUMBER;
    ln_conc_request_id1  NUMBER;
    ln_conc_request_id2  NUMBER;
  
  -- Cursor to get xml output file of Format Payment Instructions program using request id of PPR
    CURSOR c_get_outfile ( cp_request_id IN NUMBER )
    IS
      SELECT fcr.outfile_name
      FROM fnd_concurrent_requests fcr
      WHERE fcr.request_id = cp_request_id
      AND fcr.phase_code   = 'C'
      AND fcr.status_code  = 'C';
	  
  BEGIN
    -- get FPI program output file name
    OPEN c_get_outfile ( cp_request_id => ln_request_id );
    FETCH c_get_outfile INTO lc_fpi_output_file;
    CLOSE c_get_outfile;
	
    -- Cursor to get translation details
    SELECT xftv.target_value1,
      xftv.target_value1
      ||'/encrpt',
      xftv.target_value2,
      xftv.target_value3
      ||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
      ||'.xml'
    INTO lc_out_dir,
      lc_encr_out_dir,
      lc_archive_dir,
      lc_file_name
    FROM xx_fin_translatedefinition xftd,
      xx_fin_translatevalues xftv
    WHERE 1               =1
    AND xftd.translate_id = xftv.translate_id
    AND xftd.enabled_flag = 'Y'
    AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
    AND xftd.translation_name = 'OD_AP_SUA_INTF'
    AND xftv.source_value1    = 'PAYMENT';
	
    -- Tranfer XML file to un-encrypted $XXFIN_DATA/ftp/out/sua/encrpt using common copy program
    ln_conc_request_id := fnd_request.submit_request ( application => 'XXFIN', -- application short name
    PROGRAM => 'XXCOMFILCOPY',                                                 -- concurrent program name
    description => NULL,                                                       -- additional request description
    start_time => NULL,                                                        -- request submit time
    sub_request => b_sub_request,                                              -- is this a sub-request?
    argument1 => lc_fpi_output_file,                                           -- Source file
    argument2 => lc_encr_out_dir||'/'||lc_file_name,                           -- Destination file
    argument3 => '',                                                           -- Source string
    argument4 => '',                                                           -- Destination string
    argument5 => 'N',                                                          -- Delete Flag
    argument6 => NULL);                                                        -- Archive File Path
    COMMIT;
	
    -- Wait for copy to complete
    IF ln_conc_request_id > 0 THEN
      LOOP
        lb_result := fnd_concurrent.wait_for_request (ln_conc_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
        EXIT
      WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      END LOOP;
    END IF;
	
    -- Encrypt the file and place in $XXFIN_DATA/ftp/out/sua/encrpt
    IF lc_status != 'Normal' THEN
      fnd_file.put_line (fnd_file.LOG, 'Error:  File is not copied ' || SQLERRM () );
    ELSE
      BEGIN
        SELECT xftv.target_value1,
          xftv.target_value2
        INTO lc_key,
          lc_encrypt_file_flag
        FROM xx_fin_translatedefinition xftd,
          xx_fin_translatevalues xftv
        WHERE xftv.translate_id = xftd.translate_id
        AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
        AND xftv.source_value1    = 'I0438_BOA_EFT_EXP_EFT_NACHA'
        AND xftd.translation_name = 'OD_PGP_KEYS'
        AND xftv.enabled_flag     = 'Y'
        AND xftd.enabled_flag     = 'Y';
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG, 'Key not found ' || SQLERRM () );
      END;
	  
      IF (lc_key           IS NOT NULL AND NVL (lc_encrypt_file_flag, 'N') = 'Y') THEN
        ln_encr_request_id := fnd_request.submit_request (application => 'XXFIN', program => 'XXCOMENPTFILE', argument1 => lc_encr_out_dir||'/'||lc_file_name, argument2 => lc_key, argument3 => 'Y' );
        COMMIT;
        IF ln_encr_request_id > 0 THEN
          LOOP
            lb_result := fnd_concurrent.wait_for_request (ln_encr_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
            EXIT
          WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
          END LOOP;
          IF lc_status != 'Normal' THEN
            fnd_file.put_line (fnd_file.LOG, 'Error:  File is not Encrypted ' || SQLERRM () );
          ELSE
            fnd_file.put_line (fnd_file.LOG, 'File is Encrypted ');
          END IF;
        END IF;
		
        -- Copy file to $XXFIN_DATA/archive/outbound from $XXFIN_DATA/ftp/out/sua/encrypt
        ln_conc_request_id1 := fnd_request.submit_request ( application => 'XXFIN', -- application short name
        PROGRAM => 'XXCOMFILCOPY',                                                  -- concurrent program name
        description => NULL,                                                        -- additional request description
        start_time => NULL,                                                         -- request submit time
        sub_request => b_sub_request,                                               -- is this a sub-request?
        argument1 => lc_encr_out_dir||'/'||lc_file_name||'.gpg',                    -- Source file
        argument2 => lc_archive_dir||'/'||lc_file_name||'.gpg',                     -- Destination file
        argument3 => '',                                                            -- Source string
        argument4 => '',                                                            -- Destination string
        argument5 => 'N',                                                           -- Delete Flag
        argument6 => NULL);                                                         -- Archive File Path
        COMMIT;
		
        IF ln_conc_request_id1 > 0 THEN
          LOOP
            lb_result := fnd_concurrent.wait_for_request (ln_conc_request_id1, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
            EXIT
          WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
          END LOOP;
          IF lc_status != 'Normal' THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while copying encrpted file to $XXFIN_DATA/archive/outbound. ' || SQLERRM () );
          ELSE
            fnd_file.put_line (fnd_file.LOG, 'Encrpted file copied to $XXFIN_DATA/archive/outbound');
          END IF;
        END IF;
		
        -- Copy file to $XXFIN_DATA/archive/outbound from $XXFIN_DATA/ftp/out/sua/encrypt
        ln_conc_request_id1 := fnd_request.submit_request ( application => 'XXFIN', -- application short name
        PROGRAM => 'XXCOMFILCOPY',                                                  -- concurrent program name
        description => NULL,                                                        -- additional request description
        start_time => NULL,                                                         -- request submit time
        sub_request => b_sub_request,                                               -- is this a sub-request?
        argument1 => lc_encr_out_dir||'/'||lc_file_name||'.gpg',                    -- Source file
        argument2 => lc_out_dir||'/'||lc_file_name||'.gpg',                         -- Destination file
        argument3 => '',                                                            -- Source string
        argument4 => '',                                                            -- Destination string
        argument5 => 'Y',                                                           -- Delete Flag
        argument6 => NULL);                                                         -- Archive File Path
        COMMIT;
		
        IF ln_conc_request_id1 > 0 THEN
          LOOP
            lb_result := fnd_concurrent.wait_for_request (ln_conc_request_id1, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
            EXIT
          WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
          END LOOP;
          IF lc_status != 'Normal' THEN
            fnd_file.put_line (fnd_file.LOG, 'Error while copying encrpted file to $XXFIN_DATA/ftp/out/sua. ' || to_char(SQLERRM) );
          ELSE
            fnd_file.put_line (fnd_file.LOG, 'Encrpted file copied to $XXFIN_DATA/ftp/out/sua');
          END IF;
        END IF;
      END IF;
    END IF;
	
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message => 'While Waiting Report Request to Finish :'||to_char(sqlerrm));
  END xx_process_payment;
  
  
  -- +============================================================================+
  -- | Procedure Name : get_format_request_id                                     |
  -- |                                                                            |
  -- | Description    : Procedure to get request id of the 'Format Payment        |
  -- |                  Instructions with Text Output'                            |
  -- |                                                                            |
  -- +============================================================================+
  PROCEDURE get_format_request_id(
      p_template_name IN VARCHAR2 ,
      p_request_id    IN NUMBER ,
      p_fmt_req_id OUT NUMBER ,
      p_child_status OUT VARCHAR2 )
  IS
  
    CURSOR c1(p_request_id NUMBER)
    IS
      SELECT A.user_concurrent_program_name ,
        A.concurrent_program_name ,
        b.request_id
      FROM fnd_concurrent_programs_vl A ,
        fnd_concurrent_requests b
      WHERE b.parent_request_id  =p_request_id
      AND b.concurrent_program_id=A.concurrent_program_id
      ORDER BY b.request_id;
	  
    v_phase          VARCHAR2(100) ;
    v_status         VARCHAR2(100) ;
    v_dphase         VARCHAR2(100) ;
    v_dstatus        VARCHAR2(100) ;
    x_dummy          VARCHAR2(2000) ;
    v_sel_request_id NUMBER;
    v_bld_request_id NUMBER;
    v_for_request_id NUMBER;
    v_sel_status     VARCHAR2(1);
    v_bld_status     VARCHAR2(1);
	
  BEGIN
    IF (fnd_concurrent.wait_for_request(p_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
      IF v_dphase = 'COMPLETE' THEN
        dbms_output.put_line( 'Format Payment Instructions with Text Output Completed, Request id :' ||TO_CHAR(v_for_request_id));
      END IF;
    END IF;
    FOR cur IN c1(p_request_id)
    LOOP
      v_phase                      :=NULL;
      v_status                     :=NULL;
      v_dphase                     :=NULL;
      v_dstatus                    :=NULL;
      x_dummy                      :=NULL;
      IF cur.concurrent_program_name='APINVSEL' THEN
        v_sel_request_id           :=cur.request_id;
        IF (fnd_concurrent.wait_for_request(v_sel_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
          IF v_dphase    = 'COMPLETE' THEN
            v_sel_status:='Y';
            fnd_file.put_line(fnd_file.log, 'Scheduled Payment Selection Report Completed, Request id :'||TO_CHAR (v_sel_request_id));
          END IF;
        END IF;
      elsif cur.concurrent_program_name='IBYBUILD' THEN
        v_bld_request_id              :=cur.request_id;
        IF (fnd_concurrent.wait_for_request(v_bld_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
          IF v_dphase    = 'COMPLETE' THEN
            v_bld_status:='Y';
            fnd_file.put_line(fnd_file.log, 'Build Payments Completed, Request id :'||TO_CHAR(v_bld_request_id));
          END IF;
        END IF;
      END IF;
    END LOOP;
    IF v_bld_status ='Y' THEN
      v_phase      :=NULL;
      v_status     :=NULL;
      v_dphase     :=NULL;
      v_dstatus    :=NULL;
      x_dummy      :=NULL;
      FOR cur IN c1(v_bld_request_id)
      LOOP
        IF cur.concurrent_program_name='IBY_FD_PAYMENT_FORMAT_TEXT' THEN
          v_for_request_id           :=cur.request_id;
          IF (fnd_concurrent.wait_for_request(v_for_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
            IF v_dphase = 'COMPLETE' THEN
              fnd_file.put_line(fnd_file.log, 'Format Payment Instructions with Text Output Completed, Request id :' ||TO_CHAR(v_for_request_id));
              p_fmt_req_id   :=v_for_request_id;
              p_child_status :='Y';
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF ; 
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'When others in get_format_request_id :'|| sqlerrm);
    p_fmt_req_id   :=NULL;
    p_child_status :='N';
  END get_format_request_id;
  
  
  -- +============================================================================+
  -- | Procedure Name : submit_payment_process                                    |
  -- |                                                                            |
  -- | Description    : Procedure to Payment Process Request Program              |
  -- |                                                                            |
  -- +============================================================================+
  PROCEDURE submit_payment_process(
      p_errbuf        IN OUT VARCHAR2 ,
      p_retcode       IN OUT NUMBER ,
      p_template_name IN VARCHAR2 ,
      p_payment_date  IN VARCHAR2 ,
      p_pay_from_date IN VARCHAR2 ,
      p_pay_thru_date IN VARCHAR2 )
  IS
    ln_org_id        NUMBER;
    v_request_id     NUMBER;
    v_template_id    NUMBER;
    lc_err_msg       VARCHAR2(250);
    lc_error_loc     VARCHAR2(2000) := NULL;
    lc_error_count   NUMBER         :=0;
    v_child_status   VARCHAR2(1);
    v_fmt_request_id NUMBER;
    lc_user_conc_prog_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
	
  BEGIN
    ln_org_id := fnd_profile.VALUE('ORG_ID');
    BEGIN
      mo_global.set_policy_context('S', ln_org_id);
    END;
    BEGIN
      SELECT template_id
      INTO v_template_id
      FROM ap_payment_templates
      WHERE ltrim(rtrim(template_name))=ltrim(rtrim(p_template_name));
    EXCEPTION
    WHEN OTHERS THEN
      v_template_id:=NULL;
    END;
	
    IF v_template_id IS NOT NULL THEN
      v_request_id   :=fnd_request.submit_request( 'SQLAP' , 'APXPBASL' , 'Payment Process Request Program' , NULL , FALSE , NULL, v_template_id , p_payment_date , p_pay_thru_date , p_pay_from_date );
      COMMIT;
      IF v_request_id>0 THEN
        lc_err_msg  := 'Payment Process Request Program Request id  : '|| TO_CHAR(v_request_id);
        print_debug_msg(p_message => lc_err_msg, p_force => TRUE);
		
        -- Get request id of the 'Format Payment Instructions with Text Output'
        get_format_request_id ( p_template_name,v_request_id,v_fmt_request_id, v_child_status);
        lc_err_msg := 'Format Request :'||TO_CHAR(v_fmt_request_id);
        print_debug_msg(p_message => lc_err_msg, p_force => TRUE);
		
        -- Copy XML payment file to FTP outbound and archive folder
        lc_err_msg := 'Copy XML payment file to FTP outbound and archive folder';
        print_debug_msg(p_message => lc_err_msg, p_force => TRUE);
        xx_process_payment( v_fmt_request_id );
      ELSE
        lc_err_msg := 'Error submitting Payment Process Request Program for : '|| to_char(p_template_name);
        print_debug_msg(p_message =>'File Record Created Successfully.', p_force => TRUE);
      END IF;
    ELSE
      print_debug_msg(p_message =>'Template id not found. Unable to submit Payment process : '|| TO_CHAR(p_template_name), p_force => TRUE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message =>'Erorr in submit_payment_process : '||TO_CHAR(sqlerrm), p_force => TRUE);
  END submit_payment_process;
  
  
  --/**********************************************************************
  --* Procedure Name : xx_purge_recon_staging
  --* Procedure to automatically purge data in staging tables after 90 days
  --***********************************************************************/
  PROCEDURE xx_purge_recon_staging
  IS
  BEGIN
    DELETE FROM xx_ap_sua_recon WHERE creation_date < sysdate-90;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message => 'error in xx_purge_staging procedure '||to_char(sqlerrm) , p_force => true);
  END xx_purge_recon_staging;
  
  
  -- +============================================================================+
  -- | Procedure Name : load_recon_data                                           |
  -- |                                                                            |
  -- | Description    : Procedure to load response data in xx_ap_sua_recon        |
  -- |                  custom table via utl                                      |
  -- +============================================================================+
  PROCEDURE load_recon_data(
      p_file_name  VARCHAR2,
      p_debug_flag VARCHAR2,
      p_request_id NUMBER,
      p_user_id    NUMBER)
  AS
    l_filehandle utl_file.file_type;
    l_filedir VARCHAR2(20):= 'XXFIN_SUA_IN';
    l_dirpath VARCHAR2(500);
    l_newline VARCHAR2(4000);
    l_max_linesize binary_integer := 32767;
    l_user_id    NUMBER              := fnd_global.user_id;
    l_login_id   NUMBER              := fnd_global.login_id;
    l_request_id NUMBER              := fnd_global.conc_request_id;
    l_rec_cnt    NUMBER              := 0;
    l_table varchar2_table;
    l_nfields           INTEGER;
    l_error_msg         VARCHAR2(1000)        := NULL;
    l_error_loc         VARCHAR2(2000)        := 'XX_AP_SUA_PMNT_INTF_PKG.load_recon_data';
    lc_procedure_name   CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'load_recon_data';
    l_retcode           VARCHAR2(3)           := NULL;
    parse_exception     EXCEPTION;
    dup_file_exception  EXCEPTION;
    l_dup_settlement_id NUMBER;
    /*staging table columns*/
    l_response_file_name xx_ap_sua_recon.recon_file_name%TYPE;
    l_record_type xx_ap_sua_recon.RECORD_TYPE%TYPE;
    l_payable_identifier xx_ap_sua_recon.PAYABLE_IDENTIFIER%TYPE;
    l_payment_group_id xx_ap_sua_recon.payment_group_id%TYPE;
    l_merchant_name xx_ap_sua_recon.merchant_name%TYPE;
    l_post_date xx_ap_sua_recon.post_date%TYPE;
    l_payable_amount xx_ap_sua_recon.payable_amount%TYPE;
    l_txn_amount xx_ap_sua_recon.txn_amount%TYPE;
    l_txn_id xx_ap_sua_recon.txn_id%TYPE;
    l_vendor_no xx_ap_sua_recon.vendor_no%TYPE;
    l_vendor_site_code xx_ap_sua_recon.vendor_site_code%TYPE;
    l_debit_count xx_ap_sua_recon.debit_count%TYPE;
    l_debit_total xx_ap_sua_recon.debit_total%TYPE;
    l_credit_count xx_ap_sua_recon.credit_count%TYPE;
    l_credit_total xx_ap_sua_recon.credit_total%TYPE;
    l_record_count xx_ap_sua_recon.record_count%TYPE;
    l_process_flag xx_ap_sua_recon.process_flag%TYPE;
    l_error_flag xx_ap_sua_recon.error_flag%TYPE;
    l_error_description xx_ap_sua_recon.error_description%TYPE;
    l_creation_date xx_ap_sua_recon.creation_date%TYPE;
    l_created_by xx_ap_sua_recon.created_by%TYPE;
    l_last_update_date xx_ap_sua_recon.last_update_date%TYPE;
    l_last_updated_by xx_ap_sua_recon.last_updated_by%TYPE;
    l_currency_code xx_ap_sua_recon.currency_code%TYPE;
    l_order_id         VARCHAR2(100);
    l_total_order_amt  NUMBER;
    l_account_pool_id  VARCHAR2(100);
    l_file_name        VARCHAR2(200);
    l_rec_type         VARCHAR2(10);
    l_txn_type         VARCHAR2(50);
    l_insert_err_flag  VARCHAR2(10) := 'N';
    p_process_name     VARCHAR2(10) := 'RECON';
    l_val_debit_cnt    NUMBER:=0;
    l_val_debit_total  NUMBER:=0;
    l_val_credit_cnt   NUMBER:=0;
    l_val_credit_total NUMBER:=0;
    l_dbt_txn_total    NUMBER:=0;
    l_dbt_txn_cnt      NUMBER:=0;
    l_cre_txn_total    NUMBER:=0;
    l_cre_txn_cnt      NUMBER:=0;
    lc_xx_ap_sua_recon_STG xx_ap_sua_recon%ROWTYPE;
    lv_filerec_count       NUMBER;
    lv_datafile_rec_number NUMBER:=0;
	
    CURSOR cur_sua_process_recon
    IS
      SELECT xftv.target_value1 inbound_path,
        xftv.target_value2 archival_path,
        xftv.target_value3 file_name,
        xftv.target_value4 dba_directory_name
      FROM xx_fin_translatedefinition xftd,
        xx_fin_translatevalues xftv
      WHERE xftd.translation_name ='OD_AP_SUA_INTF'
      AND xftv.source_value1      = p_process_name
      AND xftd.translate_id       =xftv.translate_id
      AND xftd.enabled_flag       ='Y'
      AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate);
	  
  BEGIN
    -- purge xx_ap_sua_recon
    xx_purge_recon_staging;
	
    SELECT COUNT(1)
    INTO lv_filerec_count
    FROM xx_ap_sua_intf_files
    WHERE FILE_NAME     =p_file_name
    AND process_name    =p_process_name;
	
    IF lv_filerec_count =0 THEN
      insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name, p_request_id=>p_request_id, p_error_msg =>NULL, p_user_id=> p_user_id) ;
      print_debug_msg(p_message =>'File Record Created Successfully.', p_force => true);
    ELSE
      insert_file_rec( p_process_name => p_process_name, p_file_name => p_file_name, p_request_id=>p_request_id, p_error_msg =>'Duplicate File', p_user_id=>p_user_id) ;
      print_debug_msg(p_message =>'Duplicate File-This file is already processed.', p_force => true);
      RAISE dup_file_exception;
    END IF;
    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
    print_debug_msg(p_message => 'Loading File:'||p_file_name , p_force => true);
	
    FOR rec IN cur_sua_process_recon
    LOOP
      l_filedir    := NVL(rec.dba_directory_name,'XXFIN_SUA_IN');
      l_file_name  := p_file_name;
      l_filehandle := utl_file.fopen(l_filedir, l_file_name ,'r',l_max_linesize);
      LOOP
        BEGIN
          utl_file.get_line(l_filehandle,l_newline);
          IF l_newline IS NULL THEN
            EXIT;
          END IF;
          lv_datafile_rec_number :=lv_datafile_rec_number+1;
          -- skip 1st header
          IF regexp_count(l_newline, ',', 1, 'i') = 3 THEN
            CONTINUE ;
            -- skip 2nd header
          ELSIF REPLACE(SUBSTR(l_newline, 1, 5),chr(34),'') = 'Order' THEN
            CONTINUE ;
            -- Insert summary record
          ELSIF regexp_count(l_newline, ',', 1, 'i') = 4 THEN
            BEGIN
              l_rec_type         := 'S';
              l_debit_count      := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 1);
              l_debit_total      := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 2);
              l_credit_count     := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 3);
              l_credit_total     := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 4);
              l_record_count     := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 5);
              l_process_flag     := 'N';
              l_creation_date    := sysdate ;
              l_created_by       := fnd_global.user_id;
              l_last_update_date := sysdate;
              l_last_updated_by  := fnd_global.user_id;
            EXCEPTION
            WHEN value_error THEN
              l_insert_err_flag:='Y';
              l_error_msg      := 'value_error while parsing summary record. Error: '|| TO_CHAR(SQLERRM);
              print_debug_msg(p_message => l_error_msg , p_force => true);
            END;
            BEGIN
              INSERT
              INTO xx_ap_sua_recon
                (
                  recon_file_name,
                  record_type,
                  debit_count ,
                  debit_total ,
                  credit_count ,
                  credit_total ,
                  record_count ,
                  process_flag,
                  creation_date ,
                  created_by ,
                  last_update_date,
                  last_updated_by
                )
                VALUES
                (
                  DECODE(l_file_name, ' ', NULL, l_file_name),
                  DECODE(l_rec_type, ' ', NULL, l_rec_type),
                  l_debit_count,
                  l_debit_total,
                  l_credit_count,
                  l_credit_total,
                  l_record_count,
                  l_process_flag ,
                  l_creation_date ,
                  l_created_by ,
                  l_last_update_date,
                  l_last_updated_by
                );
            EXCEPTION
            WHEN OTHERS THEN
              l_insert_err_flag:='Y';
              l_error_msg      := 'Error while parsing the Summary record'|| to_char(SQLERRM);
              print_debug_msg(p_message =>l_error_msg , p_force => true);
            END;
            BEGIN
              SELECT payment_group_id
              INTO l_account_pool_id
              FROM xx_ap_sua_recon
              WHERE recon_file_name =l_file_name
              AND payment_group_id IS NOT NULL
              AND ROWNUM            = 1;
              UPDATE xx_ap_sua_recon
              SET payment_group_id  = l_account_pool_id
              WHERE recon_file_name = l_file_name;
            EXCEPTION
            WHEN OTHERS THEN
              l_insert_err_flag:='Y';
              l_error_msg      := 'Error in getting payment_group_id'|| to_char(SQLERRM);
              print_debug_msg(p_message =>l_error_msg , p_force => true);
            END;
            -- Insert detail records
          ELSE
            BEGIN
              l_rec_type         := 'D';
              l_txn_id           := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 10));
              l_order_id         := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 1));
              l_post_date        := trim(to_date(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 2), 'MMDDYYYY'));
              l_txn_amount       := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 3);
              l_payable_amount   := regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 4);
              l_merchant_name    := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 5));
              l_vendor_no        := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 6));
              l_vendor_site_code := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 7));
              l_account_pool_id  := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 8));
              l_currency_code    := trim(regexp_substr(REPLACE(l_newline, ',',', '), '[^,]+', 1, 9));
              l_process_flag     := 'N';
              l_creation_date    := sysdate ;
              l_created_by       := fnd_global.user_id;
              l_last_update_date := sysdate;
              l_last_updated_by  := fnd_global.user_id;
              IF l_txn_amount    >= 0 THEN
                l_txn_type       := 'DEBIT';
              ELSIF l_txn_amount  < 0 THEN
                l_txn_type       := 'CREDIT';
              END IF;
            EXCEPTION
            WHEN value_error THEN
              l_insert_err_flag:='Y';
              l_error_msg      := 'value_error for Transactio_id-'|| TO_CHAR(l_txn_id)||'. Error: '|| TO_CHAR(SQLERRM);
              print_debug_msg(p_message => l_error_msg , p_force => true);
            END;
			
            BEGIN
              INSERT
              INTO xx_ap_sua_recon
                (
                  recon_file_name,
                  record_type,
                  payable_identifier,
                  post_date,
                  txn_amount,
                  payable_amount,
                  merchant_name,
                  vendor_no,
                  vendor_site_code,
                  payment_group_id,
                  currency_code,
                  txn_id,
                  process_flag,
                  creation_date ,
                  created_by ,
                  last_update_date,
                  last_updated_by,
                  txn_type
                )
                VALUES
                (
                  DECODE(l_file_name, ' ', NULL, l_file_name),
                  DECODE(l_rec_type, ' ', NULL, l_rec_type),
                  DECODE(l_order_id, ' ', NULL, l_order_id),
                  DECODE(l_post_date, ' ', NULL, l_post_date),
                  l_txn_amount,
                  l_payable_amount,
                  DECODE(l_merchant_name, ' ', NULL, l_merchant_name),
                  DECODE(l_vendor_no, ' ', NULL, l_vendor_no),
                  DECODE(l_vendor_site_code, ' ', NULL, l_vendor_site_code),
                  DECODE(l_account_pool_id, ' ', NULL, l_account_pool_id),
                  DECODE(l_currency_code, ' ', NULL, l_currency_code),
                  DECODE(l_txn_id, ' ', NULL, l_txn_id),
                  l_process_flag ,
                  l_creation_date ,
                  l_created_by ,
                  l_last_update_date,
                  l_last_updated_by,
                  l_txn_type
                );
            EXCEPTION
            WHEN OTHERS THEN
              l_insert_err_flag:='Y';
              l_error_msg      := 'Error while inserting data for Transactio_id-'|| TO_CHAR(l_txn_id)||'. Error: '|| TO_CHAR(SQLERRM);
              print_debug_msg(p_message => l_error_msg , p_force => true);
            END;
          END IF;
          l_rec_cnt := l_rec_cnt + 1;
        EXCEPTION
        WHEN no_data_found THEN
          EXIT;
        END;
      END LOOP;
	  
      -- validate trailer and detail records --
      -- get trailer record data
      IF l_insert_err_flag = 'N' THEN
        BEGIN
          SELECT debit_count,
            debit_total,
            credit_count,
            credit_total
          INTO l_val_debit_cnt,
            l_val_debit_total,
            l_val_credit_cnt,
            l_val_credit_total
          FROM xx_ap_sua_recon
          WHERE 1             = 1
          AND record_type     = 'S'
          AND recon_file_name = l_file_name;
        EXCEPTION
        WHEN no_data_found THEN
          l_val_debit_cnt   := 0;
          l_val_debit_total := 0;
          l_val_credit_cnt  := 0;
          l_val_credit_total:= 0;
          l_error_msg       := 'No data found while validating transaction and sumary records';
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        WHEN OTHERS THEN
          l_val_debit_cnt   := 0;
          l_val_debit_total := 0;
          l_val_credit_cnt  := 0;
          l_val_credit_total:= 0;
          l_error_msg       := 'Error while validating transaction and sumary records. Error:'|| TO_CHAR(sqlerrm) ;
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        END;
        -- get sum transaction amount and count for debit
        BEGIN
          SELECT NVL(SUM(txn_amount),0),
            COUNT(1)
          INTO l_dbt_txn_total,
            l_dbt_txn_cnt
          FROM xx_ap_sua_recon
          WHERE 1             = 1
          AND record_type     = 'D'
          AND txn_type        = 'DEBIT'
          AND recon_file_name = l_file_name;
        EXCEPTION
        WHEN no_data_found THEN
          l_dbt_txn_total:= 0;
          l_dbt_txn_cnt  := 0;
          l_error_msg    := 'No data found while validating transaction and sumary records';
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        WHEN OTHERS THEN
          l_dbt_txn_total:= 0;
          l_dbt_txn_cnt  := 0;
          l_error_msg    := 'Error while validating transaction and sumary records. Error:'|| TO_CHAR(sqlerrm) ;
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        END;
        -- get sum transaction amount and count for credit
        BEGIN
          SELECT NVL(SUM(txn_amount),0),
            COUNT(1)
          INTO l_cre_txn_total,
            l_cre_txn_cnt
          FROM xx_ap_sua_recon
          WHERE 1             = 1
          AND record_type     = 'D'
          AND txn_type        = 'CREDIT'
          AND recon_file_name = l_file_name;
        EXCEPTION
        WHEN no_data_found THEN
          l_cre_txn_total:= 0;
          l_cre_txn_cnt  := 0;
          l_error_msg    := 'No data found while validating transaction and sumary records';
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        WHEN OTHERS THEN
          l_cre_txn_total:= 0;
          l_cre_txn_cnt  := 0;
          l_error_msg    := 'Error while validating transaction and sumary records. Error:'|| TO_CHAR(sqlerrm) ;
          print_debug_msg(p_message => l_error_msg , p_force => TRUE);
        END;
        IF l_val_debit_total  IS NOT NULL THEN
          IF l_val_debit_total = l_dbt_txn_total AND l_val_debit_cnt = l_dbt_txn_cnt THEN
            l_error_msg       := 'Transaction debit total and count is validated against summary debit total and count for file '||l_file_name;
            print_debug_msg(p_message => l_error_msg , p_force => TRUE);
          ELSE
            l_insert_err_flag := 'Y';
            l_error_msg       := 'Transaction debit total and count does not validate against summary debit total and count for file '||l_file_name;
            print_debug_msg(p_message => l_error_msg , p_force => TRUE);
          END IF;
        END IF;
        IF l_val_credit_total  IS NOT NULL THEN
          IF l_val_credit_total = l_cre_txn_total AND l_val_credit_cnt = l_cre_txn_cnt THEN
            l_error_msg        := 'Transaction credit total and count is validated against summary credit total and count for file '||l_file_name;
            print_debug_msg(p_message => l_error_msg , p_force => TRUE);
          ELSE
            l_insert_err_flag := 'Y';
            l_error_msg       := 'Transaction credit total and count does not validate against summary credit total and count for file '||l_file_name;
            print_debug_msg(p_message => l_error_msg , p_force => TRUE);
          END IF;
        END IF;
        utl_file.fclose(l_filehandle);
      END IF;
    END LOOP;
    IF l_insert_err_flag='N' THEN
      print_debug_msg(p_message =>TO_CHAR(l_rec_cnt)||' records successfully loaded into staging', p_force => true);
      print_debug_msg(p_message => 'File Processed Successfully:'||p_file_name , p_force => true);
      COMMIT;
    ELSIF l_insert_err_flag = 'Y' THEN
      ROLLBACK;
      UPDATE xx_ap_sua_intf_files
      SET error_description=l_error_msg
      WHERE file_name      =p_file_name;
      COMMIT;
      print_debug_msg(p_message =>l_error_msg , p_force => true);
    END IF;
  EXCEPTION
  WHEN dup_file_exception THEN
    print_debug_msg(p_message =>'location-XX_AP_SUA_PMNT_INTF_PKG.load_recon_data.Error Message-'||sqlerrm , p_force => true);
  WHEN parse_exception THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data- Error while parsing record number: '||lv_datafile_rec_number||' in the data file. SQLERRM-'||l_error_msg||'~'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.invalid_operation THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When invalid_operation Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.invalid_filehandle THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When invalid_filehandle Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.read_error THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When read_error Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.invalid_path THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When invalid_path Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.invalid_mode THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When invalid_mode Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN utl_file.internal_error THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When internal_error at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  WHEN value_error THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When Value_Error at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
  WHEN OTHERS THEN
    ROLLBACK;
    utl_file.fclose(l_filehandle);
    l_error_msg:='XX_AP_SUA_PMNT_INTF_PKG.load_recon_data-When Others Exception at Processing Line Number-'||lv_datafile_rec_number||' in datafile.SQLERRM-'||sqlerrm;
    UPDATE xx_ap_sua_intf_files
    SET error_description=l_error_msg
    WHERE file_name      =p_file_name;
    COMMIT;
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  END load_recon_data;
  
  
  -- +============================================================================+
  -- | Procedure Name : get_Update_Txn_Status                                     |
  -- | Description    :                                                           |
  -- +============================================================================+
  PROCEDURE get_update_txn_status(
      p_request_id IN NUMBER ,
      p_update_txn_req_id OUT NUMBER ,
      p_child_status OUT VARCHAR2 )
  IS
    l_error_msg VARCHAR2(1000) := NULL;
	
    CURSOR c1(p_request_id NUMBER)
    IS
      SELECT A.user_concurrent_program_name ,
        A.concurrent_program_name ,
        b.request_id
      FROM fnd_concurrent_programs_vl A ,
        fnd_concurrent_requests b
      WHERE b.parent_request_id  =p_request_id
      AND b.concurrent_program_id=A.concurrent_program_id
      ORDER BY b.request_id;
	  
    v_phase           VARCHAR2(100) ;
    v_status          VARCHAR2(100) ;
    v_dphase          VARCHAR2(100) ;
    v_dstatus         VARCHAR2(100) ;
    x_dummy           VARCHAR2(2000) ;
    v_bsl_request_id  NUMBER;
    v_rql_request_id  NUMBER;
    v_lbs_request_id  NUMBER;
    v_bsle_request_id NUMBER;
    v_ocut_request_id NUMBER;
    v_bsl_status      VARCHAR2(1);
    v_rql_status      VARCHAR2(1);
    v_lbs_status      VARCHAR2(1);
    v_bsle_status     VARCHAR2(1);
    v_ocut_status     VARCHAR2(1);
	
  BEGIN
    IF (fnd_concurrent.wait_for_request(p_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
      IF v_dphase   = 'COMPLETE' THEN
        l_error_msg:= 'OD: CE Bank statment loader program Completed, Request id :' ||TO_CHAR(p_request_id);
        print_debug_msg(p_message =>l_error_msg , p_force => TRUE);
      END IF;
    END IF;
    FOR cur IN c1(p_request_id)
    LOOP
      v_phase                      :=NULL;
      v_status                     :=NULL;
      v_dphase                     :=NULL;
      v_dstatus                    :=NULL;
      x_dummy                      :=NULL;
      IF cur.concurrent_program_name='CESQLLDR' THEN
        v_bsl_request_id           :=cur.request_id;
        IF (fnd_concurrent.wait_for_request(v_bsl_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
          IF v_dphase    = 'COMPLETE' THEN
            v_bsl_status:='Y';
            l_error_msg := 'Bank Statement Loader completed, Request id :'||TO_CHAR (v_bsl_request_id);
            print_debug_msg(p_message =>l_error_msg , p_force => TRUE);
          END IF;
        END IF;
      elsif cur.concurrent_program_name='XX_CE_BNK_STMT_PKG_UPD_TRX_TXT' THEN
        v_ocut_request_id             :=cur.request_id;
        IF (fnd_concurrent.wait_for_request(v_ocut_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
          IF v_dphase           = 'COMPLETE' THEN
            v_rql_status       :='Y';
            p_child_status     := v_rql_status;
            p_update_txn_req_id:= v_ocut_request_id;
            l_error_msg        := 'OD: CE Update Transaction Text, Request id :'|| TO_CHAR(p_update_txn_req_id)||'. Status : '||TO_CHAR(p_child_status);
            print_debug_msg(p_message =>l_error_msg , p_force => TRUE);
          END IF;
        END IF;
      END IF;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    l_error_msg:= 'When others in get_update_txn_status :'||TO_CHAR(sqlerrm);
    print_debug_msg(p_message =>l_error_msg , p_force => TRUE);
    p_update_txn_req_id :=NULL;
    p_child_status      :='N';
  END get_update_txn_status;
  
   -- +============================================================================+
  -- | Procedure Name : process_recon_data                                        |
  -- | Description    :                                                           |
  -- +============================================================================+
  PROCEDURE process_recon_data(
      p_errbuf  IN OUT VARCHAR2 ,
      p_retcode IN OUT NUMBER )
  IS
    file_handle utl_file.file_type;
    lc_file_creation_date   VARCHAR2(50);
    lc_file_creation_time   VARCHAR2(50);
    lc_currency_code        VARCHAR2(10);
    ln_opening_bal          NUMBER;
    ln_closing_bal          NUMBER;
    ln_txn_amt              NUMBER;
    ln_total_txn_amt        NUMBER;
    ln_txn_id               VARCHAR2(100);
    ln_cnt1                 NUMBER;
    ln_cnt2                 NUMBER;
    lc_out_dir              VARCHAR2(50);
    lc_archive_dir          VARCHAR2(50);
    lc_file_name            VARCHAR2(100);
    b_sub_request           BOOLEAN;
    lc_err_msg              VARCHAR2(250);
    ln_bnk_state_ldr_req_id NUMBER := 0;
    ln_update_txn_req_id    NUMBER := 0;
    lc_child_status         VARCHAR2(100);
    ln_loop_count           NUMBER;
    ln_com_cpy_request_id   NUMBER;
    lc_out_dir_abs          VARCHAR2(200);
    ln_cust_ref             NUMBER;
    l_error_msg             VARCHAR2(1000) := NULL;
    ln_org_id               NUMBER;
    v_phase                 VARCHAR2(100) ;
    v_status                VARCHAR2(100) ;
    v_dphase                VARCHAR2(100) ;
    v_dstatus               VARCHAR2(100) ;
    x_dummy                 VARCHAR2(2000) ;
    ln_bnk_imp_recon_req_id NUMBER:= 0;
    l_bank_account_id       NUMBER;
    l_bank_branch_id        NUMBER;
	
    CURSOR c_get_recon_detail(p_recon_file_name varchar2)
    IS
      SELECT ROWID,
        txn_amount,
        payable_identifier,
        txn_id
      FROM xx_ap_sua_recon
      WHERE 1             = 1
      AND process_flag    = 'N'
      AND reconciled_flag = 'N'
      AND record_type     = 'D'
	  AND recon_file_name = p_recon_file_name;
	  
    CURSOR c_get_total_amount
    IS
      SELECT (SUM(txn_amount) + 1500)*100 opening_bal,
        (SUM(txn_amount))     *100 total_txn_amount,
        recon_file_name
      FROM xx_ap_sua_recon
      WHERE 1              = 1
      AND process_flag     = 'N'
      AND reconciled_flag IS NULL
      AND record_type      = 'D'
      GROUP BY recon_file_name;
  BEGIN
     ln_org_id := fnd_profile.VALUE('ORG_ID');
     mo_global.set_policy_context('S', ln_org_id);
	 
    FOR g_rec IN c_get_total_amount
    LOOP
      BEGIN
        UPDATE xx_ap_sua_recon
        SET reconciled_flag = 'N'
        WHERE 1 = 1
		and process_flag  = 'N'
        AND recon_file_name = g_rec.recon_file_name;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        l_error_msg:= 'Error while updating xx_ap_sua_recon. Error :'||TO_CHAR(SQLERRM);
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      END;
      BEGIN
        SELECT xftv.target_value1 ,
          xftv.target_value2 ,
          xftv.target_value3
          ||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')
          ||'.txt'
        INTO lc_out_dir,
          lc_archive_dir,
          lc_file_name
        FROM xx_fin_translatedefinition xftd,
          xx_fin_translatevalues xftv
        WHERE 1               =1
        AND xftd.translate_id = xftv.translate_id
        AND xftd.enabled_flag = 'Y'
        AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
        AND xftd.translation_name = 'OD_AP_SUA_INTF'
        AND xftv.source_value1    = 'BANK_STATEMENT';
      EXCEPTION
      WHEN no_data_found THEN
        l_error_msg:= 'No records found in OD_AP_SUA_INTF translation for BANK_STATEMENT.';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      WHEN OTHERS THEN
        l_error_msg:= 'Error while getting translation values in OD_AP_SUA_INTF. Error: '||TO_CHAR(sqlerrm);
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      END;
	  
      -- Initialize variables
      lc_file_creation_date := TO_CHAR(SYSDATE,'YYMMDD');
      lc_file_creation_time := TO_CHAR(SYSDATE,'HH24MI');
      lc_currency_code      := 'USD';
      ln_cnt1               := 0;
      ln_cnt2               := 0;
      ln_loop_count         := 0;
      b_sub_request         := FALSE;
      ln_opening_bal        := g_rec.opening_bal;
      ln_total_txn_amt      := g_rec.total_txn_amount;
      ln_closing_bal        := ln_opening_bal - ln_total_txn_amt;
	  
      /* STEP NO: 1 - Logic to write Bank Statement file in outbound directory */
      file_handle := utl_file.fopen(lc_out_dir, lc_file_name, 'w');
      utl_file.put(file_handle, '01,121000248,OFFIC952,'||lc_file_creation_date||','||lc_file_creation_time||',01,080,,2/'|| chr(10));
      utl_file.put(file_handle, '02,OFFIC952,061209756,1,'||lc_file_creation_date||',,,/'|| chr(10));
      utl_file.put(file_handle, '03,2079900589996,'||lc_currency_code||',010'||','||ln_opening_bal||',,,015,'||ln_closing_bal||',,,040,0,,/'|| chr(10));
      utl_file.put(file_handle, '88,040,0,,,045,'||ln_total_txn_amt||',,,050,0,,,072,0,,/'|| chr(10));
      utl_file.put(file_handle, '88,074,0,,,100,0,,,400,'||ln_total_txn_amt||',2,/'|| chr(10));
      FOR rec IN c_get_recon_detail(g_rec.recon_file_name)
      LOOP
        ln_cust_ref:= rec.payable_identifier;
        ln_txn_amt := rec.txn_amount*100;
        ln_txn_id  := trim(rec.txn_id);
        utl_file.put(file_handle, '16,475,'||ln_txn_amt||',1,,'||ln_cust_ref||'/'|| chr(10)); 
        utl_file.put(file_handle, '88,OTHER REFERENCE: IA'||ln_cust_ref||' TXN ID: '||ln_txn_id||'/'|| chr(10));
        utl_file.put(file_handle, '88,Check Paid '||ln_cust_ref||' DEPOSIT 1/'|| chr(10));
        BEGIN
          UPDATE xx_ap_sua_recon
          SET reconciled_flag = 'Y'
          WHERE 1             = 1
          AND ROWID           = rec.ROWID;
        EXCEPTION
        WHEN OTHERS THEN
          l_error_msg:= 'Error while writing bank statement for transaction: '||TO_CHAR(ln_txn_id)||' Error: '||TO_CHAR(sqlerrm);
          print_debug_msg(p_message =>l_error_msg , p_force => true);
        END;
        ln_loop_count := ln_loop_count + 3;
      END LOOP;
      ln_cnt1 := ln_loop_count + 4;
      ln_cnt2 := ln_cnt1       + 2;
      utl_file.put(file_handle, '49,'||ln_closing_bal||','||ln_cnt1||'/'|| chr(10));
      utl_file.put(file_handle, '98,'||ln_closing_bal||',1/'|| chr(10));
      utl_file.put(file_handle, '99,'||ln_closing_bal||',1,'||ln_cnt2||'/'|| chr(10));
      utl_file.fclose(file_handle);
	  
      --get absolute path for directory
      BEGIN
        SELECT directory_path
        INTO lc_out_dir_abs
        FROM dba_directories
        WHERE directory_name = lc_out_dir;
      EXCEPTION
      WHEN no_data_found THEN
        l_error_msg:= 'No data found error while getting directory path.';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      END;
	  
      /* STEP NO: 2 - Tranfer Bank statement file to archive directory using common copy program */
      ln_com_cpy_request_id := fnd_request.submit_request ( application => 'XXFIN', -- application short name
      PROGRAM => 'XXCOMFILCOPY',                                                    -- concurrent program name
      description => NULL,                                                          -- additional request description
      start_time => NULL,                                                           -- request submit time
      sub_request => b_sub_request,                                                 -- is this a sub-request?
      argument1 => lc_out_dir_abs||'/'||lc_file_name,                               -- Source file
      argument2 => lc_archive_dir||'/'||lc_file_name,                               -- Destination file
      argument3 => '',                                                              -- Source string
      argument4 => '',                                                              -- Destination string
      argument5 => 'N',                                                             -- Delete Flag
      argument6 => NULL);                                                           -- Archive File Path
      COMMIT;
      IF ln_com_cpy_request_id > 0 THEN
        IF (fnd_concurrent.wait_for_request(ln_com_cpy_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
          IF v_dphase = 'COMPLETE' THEN
            BEGIN
              UPDATE xx_ap_sua_recon
              SET reconciled_flag = 'B'
              WHERE 1             = 1 
              AND process_flag    = 'N'
              AND recon_file_name = g_rec.recon_file_name;
              COMMIT;
            EXCEPTION
            WHEN OTHERS THEN
              l_error_msg:= 'Error while writing bank statement. Error: '||TO_CHAR(sqlerrm);
              print_debug_msg(p_message =>l_error_msg , p_force => true);
              UPDATE xx_ap_sua_recon
              SET reconciled_flag = 'E',
                process_flag      = 'E'
              WHERE 1             = 1 
              AND process_flag    = 'N'
              AND recon_file_name = g_rec.recon_file_name;
              COMMIT;
            END;
            l_error_msg:= 'Tranfer Bank statement file to archive directory is successful. Request ID: '||TO_CHAR(ln_com_cpy_request_id);
            print_debug_msg(p_message =>l_error_msg , p_force => true);
          END IF;
        END IF;
      END IF;
	  
      /* STEP NO: 3 - Submit 'OD: CE Bank statment loader program' conc request */
      ln_bnk_state_ldr_req_id :=fnd_request.submit_request( 'XXFIN' , 'XX_CE_BNK_STMT_LDR_PKG_SUB_REQ' , 'OD: CE Bank statment loader program' , NULL , FALSE , 'LOAD' , 1002 , -- BAI2
      lc_file_name , lc_out_dir_abs, TO_CHAR(SYSDATE,'YYYY/MM/DD HH:MM:SS'));
      COMMIT;
      /* STEP NO: 3.1 - Wait for 'OD: CE Update Transaction Text' program to complete */
      IF ln_bnk_state_ldr_req_id>0 THEN
        l_error_msg            := 'Submitted OD: CE Bank statment loader program Request id : '|| TO_CHAR(ln_bnk_state_ldr_req_id);
        print_debug_msg(p_message =>l_error_msg , p_force => true);
		
        l_error_msg:= 'Wait for OD: CE Update Transaction Text program to complete ';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
        get_update_txn_status(ln_bnk_state_ldr_req_id, ln_update_txn_req_id, lc_child_status);
      ELSE
        l_error_msg := 'Error submitting OD: CE Bank statment loader program : ';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      END IF;
      /* STEP NO: 4 - Submit Bank Statement Import and auto reconciliation */
      IF lc_child_status = 'Y' THEN
        l_error_msg     := 'OD: CE Update Transaction Text success. Req ID: '||TO_CHAR(ln_update_txn_req_id);
        print_debug_msg(p_message =>l_error_msg , p_force => true);
		
        -- update reconciled_flag in xx_ap_sua_recon to B
        BEGIN
          UPDATE xx_ap_sua_recon
          SET reconciled_flag = 'B'
          WHERE 1             = 1
          AND recon_file_name = g_rec.recon_file_name;
        EXCEPTION
        WHEN OTHERS THEN
          l_error_msg:= 'Error while writing bank statement. Error: '||TO_CHAR(sqlerrm);
          print_debug_msg(p_message =>l_error_msg , p_force => true);
        END;
        l_error_msg := 'Submitting Bank Statement Import and auto reconciliation.';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
		
        -- Getting bank branch id and bank account id
        BEGIN
          SELECT
            cba.BANK_ACCOUNT_ID,
            bb.BANK_BRANCH_ID
          INTO l_bank_account_id,
            l_bank_branch_id
          FROM ce_bank_accounts cba,
            cefv_bank_branches bb
          WHERE 1                = 1
          AND cba.bank_branch_id = bb.bank_branch_id
          AND cba.BANK_ACCOUNT_NAME = 'WELLS FARGO DUMMY - JPMSUA';
        EXCEPTION
        WHEN no_data_found THEN
          l_error_msg:= 'Bank branch or account id not found for bank account name ~ WELLS FARGO DUMMY - JPMSUA';
          print_debug_msg(p_message =>l_error_msg , p_force => true);
        END;
        ln_bnk_imp_recon_req_id := fnd_request.submit_request( 'CE' , 'ARPLABIR' , 'Bank Statement Import and AutoReconciliation' , NULL , FALSE , 'ZALL', l_bank_branch_id, --339253421, -- bank branch id -- WELLS FARGO BANK, N.A.
        l_bank_account_id,                                                                                                                                                   -- 22205,     -- bank account id -- WELLS FARGO DUMMY - JPMSUA
        NULL, NULL, NULL, NULL, TO_CHAR(SYSDATE,'YYYY/MM/DD HH:MM:SS'), NULL, NULL, NULL, NULL, 'NO_ACTION', 'N', NULL, NULL );
        COMMIT;
        IF ln_bnk_imp_recon_req_id>0 THEN
          l_error_msg            := 'Submitted Bank Statement Import and auto reconciliation. Request id : '|| TO_CHAR(ln_bnk_imp_recon_req_id);
          print_debug_msg(p_message =>l_error_msg , p_force => true);
		  
          -- update reconciled_flag in xx_ap_sua_recon to A and process flag to Y
          BEGIN
            UPDATE xx_ap_sua_recon
            SET reconciled_flag = 'A',
              process_flag      = 'Y'
            WHERE 1             = 1
            AND recon_file_name = g_rec.recon_file_name;
          EXCEPTION
          WHEN OTHERS THEN
            l_error_msg:= 'Error while writing bank statement. Error: '||TO_CHAR(sqlerrm);
            print_debug_msg(p_message =>l_error_msg , p_force => true);
          END;
        ELSE
          l_error_msg := 'Error submitting Bank Statement Import and auto reconciliation: '||TO_CHAR(sqlerrm);
          print_debug_msg(p_message =>l_error_msg , p_force => true);
        END IF;
      ELSE
        l_error_msg := 'OD: CE Update Transaction Text success completed in Error';
        print_debug_msg(p_message =>l_error_msg , p_force => true);
      END IF;
    END LOOP;
	
  EXCEPTION
  WHEN OTHERS THEN
    l_error_msg:= 'ERROR in process_recon_data: '||l_error_msg||' - '|| TO_CHAR(sqlerrm);
    print_debug_msg(p_message =>l_error_msg , p_force => true);
  END process_recon_data;
  
  END xx_ap_sua_pmnt_intf_pkg;