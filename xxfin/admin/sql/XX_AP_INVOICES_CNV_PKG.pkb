REM ============================================================================
REM Create the package body:
REM ============================================================================
PROMPT Creating package body APPS.XX_AP_INVOICES_CNV_PKG . . .
CREATE OR REPLACE PACKAGE BODY apps.xx_ap_invoices_cnv_pkg -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                        Providge Consulting                        |
  -- +===================================================================+
  -- | Name             :    XX_AP_INVOICES_CNV_PKG                     |
  -- | Description      :    This Package is for Converting all          |
  -- |                       Open Invoices From PeopleSoft to Oracle EBS |
  -- |                                                                   | 
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date         Author              Remarks                 |
  -- |=======   ===========  ================    ========================|
  -- |    1.0   02-JAN-2007  Sarat Uppalapati    Initial version         |
  -- |    1.0   02-JUN-2007  Sarat Uppalapati    Added Validation        |
  -- |    1.0   11-JUN-2007  Sarat Uppalapati    Added Validation        |
  -- |    1.0   19-JUN-2007  Sarat Uppalapati    Code Changed according  |
  -- |                                           to the mapping changes  |
  -- |    1.0   03-JUL-2007  Sarat Uppalapati    Added Error Handling    | 
  -- |    1.0   01-AUG-2007  Sarat Uppalapati    Added Disctiibutin CCID | 
  -- |                                           Logic                   |  
  -- |    1.0   15-AUG-2007  Sarat Uppalapati    Changed value for the   | 
  -- |                                         GL_DATE & ACCOUNTING_DATE |  
  -- |    1.0   21-AUG-2007  Sarat Uppalapati    Added CA Tax Code Logic | 
  -- |    1.0   21-AUG-2007  Sarat Uppalapati    Added CA Tax Code Logic | 
  -- |    1.0   05-SEP-2007  Sarat Uppalapati    Added  Code Logic       |  
  -- |    1.0   23-OCt-2007  Sarat Uppalapati    Commented attribute7,10,11| 
  -- |    1.0   01-NOV-2007  Sarat Uppalapati    Added Defect IDs        |
  -- |    1.0   04-DEC-2007  Sandeep             Added gathering statistics |
  -- +===================================================================+
  IS PROCEDURE get_id_flex_num(p_flex_structure_code IN VARCHAR2 DEFAULT 'OD_GLOBAL_COA',   x_id_flex_num OUT NUMBER,   x_segment_delimiter OUT VARCHAR2,   x_returnmessage OUT VARCHAR2) IS
  -- Retrieve AFF id_flex_num and segment delimiter.
  BEGIN
    SELECT concatenated_segment_delimiter,
      id_flex_num
    INTO x_segment_delimiter,
      x_id_flex_num
    FROM fnd_id_flex_structures
    WHERE application_id = 101
     AND id_flex_code = 'GL#'
     AND id_flex_structure_code = p_flex_structure_code;

  EXCEPTION
  WHEN no_data_found THEN
    x_returnmessage := 'AFF structure not defined: ' || 'OD_GLOBAL_COA';
  END get_id_flex_num;

  -- +===================================================================+
  -- | Name : AP_INVOICES_MASTER                                     |
  -- | Description : To create the batches of AP transactions from the   |
  -- |      custom staging table xxcnv.XX_AP_INV_HDR_INTF_CNV_STG based on the|
  -- |      Invoice type name. It will call the "OD: AP Open Invoices    |
  -- |    Conversion Child Program", "OD Conversion Exception Log        |
  -- |      Report", "OD Conversion Processing Summary Report" for each  |
  -- |      batch. This procedure will be the executable of Concurrent   |
  -- |      program "OD: AP Open Invoices Conversion Master Program"     |
  -- | Parameters : x_error_buff, x_ret_code,p_process_name,             |
  -- |              ,p_validate_only_flag,p_reset_status_flag            |
  -- +===================================================================+ 
  PROCEDURE ap_invoices_master(x_error_buff OUT VARCHAR2,   x_ret_code OUT NUMBER,   p_process_name IN VARCHAR2,   p_validate_only_flag IN VARCHAR2,   p_reset_status_flag IN VARCHAR2) AS
  -- Cursor to create the invoice batches.
  CURSOR c_invoice_type(p_system_code VARCHAR2) IS
  SELECT source
  FROM xxcnv.xx_ap_inv_hdr_intf_cnv_stg
  WHERE source_system_code = p_system_code
   AND process_flag = 1
   AND source NOT LIKE '%1099%'
  GROUP BY source;

  CURSOR c_dist_code IS
  SELECT l.dist_code_concatenated dist_code,
    l.audit_id
  FROM xxcnv.xx_ap_inv_lines_intf_cnv_stg l,
    xxcnv.xx_ap_inv_hdr_intf_cnv_stg h
  WHERE TRIM(l.attribute7) = TRIM(h.voucher_num)
   AND h.source NOT LIKE '%1099%'
   AND h.process_flag = 1
   AND h.audit_id = l.audit_id --AND H.audit_id = -444 
  GROUP BY l.dist_code_concatenated,
    l.audit_id;

  ln_batch_id NUMBER := 0;
  ln_batch_tot NUMBER := 0;
  ln_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_par_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_chi_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_conversion_id xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
  lc_source_system_code xxcomn.xx_com_conversions_conv.system_code%TYPE;
  lc_error_loc VARCHAR2(2000);
  lc_error_msg VARCHAR2(2000);
  lc_error_debug VARCHAR2(2000);
  lb_req_set boolean;
  lb_req_child boolean;
  lb_req_excep boolean;
  lb_req_summary boolean;
  ln_req_submit NUMBER;
  ln_req_id NUMBER;
  ln_control_id NUMBER;
  ln_org_id NUMBER;

  lc_phase VARCHAR2(50);
  lc_status VARCHAR2(50);
  lc_devphase VARCHAR2(50);
  lc_devstatus VARCHAR2(50);
  lc_message VARCHAR2(50);
  lc_req_status boolean;

  lb_valid_result boolean;
  lc_returnmessage VARCHAR2(4000);
  lc_old_concat_segments VARCHAR2(3000);
  -- Old Concat Segments
  lc_old_bu_aff_segment1 fnd_flex_values.flex_value%TYPE;
  -- Old Business Unit 
  lc_old_dt_aff_segment2 fnd_flex_values.flex_value%TYPE;
  -- Old Department 
  lc_old_ac_aff_segment3 fnd_flex_values.flex_value%TYPE;
  -- Old Account
  lc_old_ou_aff_segment4 fnd_flex_values.flex_value%TYPE;
  -- Old Operating Unit 
  lc_old_af_aff_segment5 fnd_flex_values.flex_value%TYPE;
  -- Old Affiliate 
  lc_old_ch_aff_segment6 fnd_flex_values.flex_value%TYPE;
  -- Old Channel 
  lc_new_concat_segments VARCHAR2(3000);
  -- New Concat Segments
  lc_new_cp_aff_segment1 fnd_flex_values.flex_value%TYPE;
  -- New Company
  lc_new_cc_aff_segment2 fnd_flex_values.flex_value%TYPE;
  -- New Cost Center
  lc_new_ac_aff_segment3 fnd_flex_values.flex_value%TYPE;
  -- New Account
  lc_new_lc_aff_segment4 fnd_flex_values.flex_value%TYPE;
  -- New Location
  lc_new_ic_aff_segment5 fnd_flex_values.flex_value%TYPE;
  -- New Inter Company
  lc_new_ch_aff_segment6 fnd_flex_values.flex_value%TYPE;
  -- New Channel 
  lc_new_fu_aff_segment7 fnd_flex_values.flex_value%TYPE;
  -- New Future 
  ln_ccid gl_code_combinations.code_combination_id%TYPE;
  ln_new_aff_ccid gl_code_combinations.code_combination_id%TYPE;
  ln_new_aff_ccid_final gl_code_combinations.code_combination_id%TYPE;
  ln_id_flex_num fnd_id_flex_structures.id_flex_num%TYPE;
  lc_segment_delimiter fnd_id_flex_structures.concatenated_segment_delimiter%TYPE;

  BEGIN

    -- Gathering Statistics
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'XXCNV',   tabname => 'XX_AP_INV_HDR_INTF_CNV_STG',   estimate_percent => 100);
    END;
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'XXCNV',   tabname => 'XX_AP_INV_LINES_INTF_CNV_STG',   estimate_percent => 100);
    END;
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICES_INTERFACE',   estimate_percent => 100);
    END;
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICE_LINES_INTERFACE',   estimate_percent => 100);
    END;
    
    ln_par_conc_request_id := fnd_global.conc_request_id();
    --Printing the Parameters
    fnd_file.PUT_LINE(fnd_file.LOG,   'Parameters');
    fnd_file.PUT_LINE(fnd_file.LOG,   '----------');
    fnd_file.PUT_LINE(fnd_file.LOG,   'Process Name: ' || p_process_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   'Validate Only Flag: ' || p_validate_only_flag);
    fnd_file.PUT_LINE(fnd_file.LOG,   'Reset Status Flag: ' || p_reset_status_flag);
    fnd_file.PUT_LINE(fnd_file.LOG,   '----------');
    --Get the Conversion_id.
    lc_error_loc := 'Get the Conversion id, Source System Code';
    lc_error_debug := 'Process Name: ' || p_process_name;
    SELECT conversion_id,
      system_code
    INTO ln_conversion_id,
      lc_source_system_code
    FROM xxcomn.xx_com_conversions_conv
    WHERE conversion_code = p_process_name;
    fnd_file.PUT_LINE(fnd_file.LOG,   'Conversion Id is ' || ln_conversion_id);
    fnd_file.PUT_LINE(fnd_file.LOG,   'System Code is ' || lc_source_system_code);

    fnd_file.PUT_LINE(fnd_file.LOG,   'Reset Status Flag Value is ' || p_reset_status_flag);

    IF(p_reset_status_flag = 'Y') THEN
      lc_error_loc := 'Updating the Process flag to 1';
      lc_error_debug := 'p_reset_status_flag: ' || p_reset_status_flag;
      fnd_file.PUT_LINE(fnd_file.LOG,   'p_reset_status_flag is ' || p_reset_status_flag);
      fnd_file.PUT_LINE(fnd_file.LOG,   'Resetting the Process Flag to 1 in staging tables.');

      UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
      SET process_flag = '1'
      WHERE source_system_code = lc_source_system_code
       AND source NOT LIKE '%1099%' --AND process_flag IN ('4');
      AND process_flag IN('2',   '3',   '4',   '5');

      /* 
         UPDATE xxcnv.XX_AP_INV_LINES_INTF_CNV_STG
            SET process_flag = '1'
          WHERE source_system_code = lc_source_system_code
            AND process_flag IN ('2', '3', '4', '5', '6');
         */
      COMMIT;
    END IF;

    FOR lcu_dist_code IN c_dist_code
    LOOP
      BEGIN
        get_id_flex_num(x_id_flex_num => ln_id_flex_num,   x_segment_delimiter => lc_segment_delimiter,   x_returnmessage => lc_returnmessage);

        IF(lc_returnmessage IS NOT NULL) THEN
          lc_error_msg := lc_returnmessage;
          xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG',   'AFF structure not defined:OD_GLOBAL_COA',   NULL,   NULL,   NULL,   '',   lc_error_msg,   lc_error_loc);
        ELSE
          lc_old_concat_segments := lcu_dist_code.dist_code;

          lc_old_bu_aff_segment1 := SUBSTR(lc_old_concat_segments,   1,   instr(lc_old_concat_segments,   '.',   1,   1) -1);
          lc_old_dt_aff_segment2 := SUBSTR(lc_old_concat_segments,   instr(lc_old_concat_segments,   '.',   1,   1) + 1,   instr(lc_old_concat_segments,   '.',   1,   2) -instr(lc_old_concat_segments,   '.',   1,   1) -1);
          lc_old_ac_aff_segment3 := SUBSTR(lc_old_concat_segments,   instr(lc_old_concat_segments,   '.',   1,   2) + 1,   instr(lc_old_concat_segments,   '.',   1,   3) -instr(lc_old_concat_segments,   '.',   1,   2) -1);
          lc_old_ou_aff_segment4 := SUBSTR(lc_old_concat_segments,   instr(lc_old_concat_segments,   '.',   1,   3) + 1,   instr(lc_old_concat_segments,   '.',   1,   4) -instr(lc_old_concat_segments,   '.',   1,   3) -1);
          lc_old_af_aff_segment5 := SUBSTR(lc_old_concat_segments,   instr(lc_old_concat_segments,   '.',   1,   4) + 1,   instr(lc_old_concat_segments,   '.',   1,   5) -instr(lc_old_concat_segments,   '.',   1,   4) -1);
          lc_old_ch_aff_segment6 := SUBSTR(lc_old_concat_segments,   instr(lc_old_concat_segments,   '.',   1,   5) + 1);

          xx_cnv_gl_psfin_pkg.translate_ps_values(p_ps_business_unit => lc_old_bu_aff_segment1,   p_ps_department => lc_old_dt_aff_segment2,   p_ps_account => lc_old_ac_aff_segment3,   p_ps_operating_unit => lc_old_ou_aff_segment4,   p_ps_affiliate => lc_old_af_aff_segment5,   p_ps_sales_channel => lc_old_ch_aff_segment6,   p_use_stored_combinations => 'No',   p_convert_gl_history => 'No',   x_seg1_company => lc_new_cp_aff_segment1,   x_seg2_costctr => lc_new_cc_aff_segment2,   x_seg3_account => lc_new_ac_aff_segment3,   x_seg4_location => lc_new_lc_aff_segment4,   x_seg5_interco => lc_new_ic_aff_segment5,   x_seg6_lob => lc_new_ch_aff_segment6,   x_seg7_future => lc_new_fu_aff_segment7,   x_ccid => ln_ccid,   x_error_message => lc_error_msg);

          -- Compose new concatenated account combinations.
          lc_new_concat_segments := lc_new_cp_aff_segment1 || lc_segment_delimiter || lc_new_cc_aff_segment2 || lc_segment_delimiter || lc_new_ac_aff_segment3 || lc_segment_delimiter || lc_new_lc_aff_segment4 || lc_segment_delimiter || lc_new_ic_aff_segment5 || lc_segment_delimiter || lc_new_ch_aff_segment6 || lc_segment_delimiter || lc_new_fu_aff_segment7;
          -- Validate account combination exists.
          lb_valid_result := fnd_flex_keyval.validate_segs(operation => 'CREATE_COMBINATION',   appl_short_name => 'SQLGL',   key_flex_code => 'GL#',   structure_number => ln_id_flex_num,   concat_segments => lc_new_concat_segments);

          IF NOT lb_valid_result THEN
            lc_error_msg := fnd_flex_keyval.error_message;

            UPDATE xxcnv.xx_ap_inv_lines_intf_cnv_stg
            SET global_attribute1 = lc_new_concat_segments,
              global_attribute3 = lc_error_msg
            WHERE dist_code_concatenated = lcu_dist_code.dist_code
             AND audit_id = lcu_dist_code.audit_id;
            COMMIT;
          ELSE
            ln_new_aff_ccid := fnd_flex_keyval.combination_id;

            IF(ln_new_aff_ccid = -1) THEN
              lc_error_msg := 'Invalid account combination: ' || lc_new_concat_segments;

              UPDATE xxcnv.xx_ap_inv_lines_intf_cnv_stg
              SET global_attribute1 = lc_new_concat_segments,
                global_attribute3 = lc_error_msg
              WHERE dist_code_concatenated = lcu_dist_code.dist_code
               AND audit_id = lcu_dist_code.audit_id;
              COMMIT;
            ELSE

              UPDATE xxcnv.xx_ap_inv_lines_intf_cnv_stg
              SET global_attribute1 = lc_new_concat_segments,
                global_attribute2 = ln_new_aff_ccid -- ,global_attribute3 = lc_error_msg
              WHERE dist_code_concatenated = lcu_dist_code.dist_code
               AND audit_id = lcu_dist_code.audit_id;
              COMMIT;
            END IF;

          END IF;

        END IF;

      END;
    END LOOP;

    FOR lcu_invoice_type IN c_invoice_type(lc_source_system_code)
    LOOP
      --Generating the BATCH_ID from the Sequence 
      SELECT xx_ap_invoices_cnv_stg_bt_s.nextval
      INTO ln_batch_id
      FROM sys.dual;

      --fnd_file.put_line (fnd_file.LOG, 'Control id is '   || ln_control_id);
      fnd_file.PUT_LINE(fnd_file.LOG,   'Batch Number is ' || ln_batch_id);
      lc_error_loc := 'Update batch_id and conv_action';
      lc_error_debug := 'Update batch_id and conv_action';

      -- Update the process flag with 3 for unmatched invoice amounts. 

      UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg a
      SET process_flag = 3,
        global_attribute5 = 'Header and Line Amounts Mismatch'
      WHERE invoice_amount !=
        (SELECT SUM(amount)
         FROM xxcnv.xx_ap_inv_lines_intf_cnv_stg b
         WHERE b.attribute7 = a.voucher_num
         AND b.audit_id = a.audit_id
         GROUP BY b.attribute7)
      AND source NOT LIKE '%1099%'
       AND a.process_flag = 1;
      COMMIT;
      -- Update the process flag with 3 for ccid is null . 

      UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg a
      SET process_flag = 3,
        global_attribute5 = 'Distribution Accounts were not created'
      WHERE voucher_num IN
        (SELECT b.attribute7
         FROM xxcnv.xx_ap_inv_lines_intf_cnv_stg b
         WHERE b.attribute7 = a.voucher_num
         AND b.audit_id = a.audit_id
         AND b.global_attribute2 IS NULL
         GROUP BY b.attribute7)
      AND a.source NOT LIKE '%1099%'
       AND a.process_flag = 1;
      COMMIT;

      --Updating the Process_flag, Batch_id 

      UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
      SET batch_id = ln_batch_id,
        process_flag = '2'
      WHERE process_flag = '1'
       AND source_system_code = lc_source_system_code
       AND source = lcu_invoice_type.source;

      ln_batch_tot := SQL % rowcount;
      COMMIT;

      IF ln_batch_tot > 0 THEN
        --Call the Procedure xx_com_conv_elements_pkg.log_control_info_proc API
        lc_error_loc := 'Call the Common Elements API to log the control info';
        lc_error_debug := 'Conversion id: ' || ln_conversion_id || ' Batch id: ' || ln_batch_id;
        fnd_file.PUT_LINE(fnd_file.LOG,   'Calling Log Control Information Procedure for batch ID ' || ln_batch_id);
        xx_com_conv_elements_pkg.log_control_info_proc(ln_conversion_id,   ln_batch_id,   ln_batch_tot);
        ln_req_id := fnd_request.submit_request('XXFIN',   'XXAPINVCNVC',   NULL,   NULL,   FALSE,   p_process_name,   p_validate_only_flag,   p_reset_status_flag,   ln_batch_id);

        /* Start the request */
        COMMIT;
        lc_error_loc := 'Update REQUEST_ID of the Staging table ';
        lc_error_debug := 'Batch ID: ' || ln_batch_id;

        UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
        SET request_id = ln_req_submit
        WHERE batch_id = ln_batch_id;
        COMMIT;

        /* Check that the request submission was OK */

        IF ln_req_id = 0 THEN
          fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Payables Open Child Process''.');
        ELSE
          fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Payables Open Interface Child Process'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
          fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');

          /* Wait for the import request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id -- request_id 
          ,   30 -- interval 
          ,   360000 -- max_wait 
          ,   lc_phase -- phase 
          ,   lc_status -- status 
          ,   lc_devphase -- dev_phase 
          ,   lc_devstatus -- dev_status 
          ,   lc_message -- message 
          );

          /* Submit the 'Conversion Exception Report' process */ ln_req_id := fnd_request.submit_request('XXCOMN',   'XXCOMCONVEXPREP',   NULL,   NULL,   FALSE,   p_process_name,   ln_par_conc_request_id,   ln_chi_conc_request_id,   ln_batch_id);

          /* Start the request */
          COMMIT;

          /* Check that the request submission was OK */

          IF ln_req_id = 0 THEN
            fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Conversion Exception Report Process''.');
          ELSE
            fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Conversion Exception Report Process'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');

            /* Wait for the import request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id -- request_id 
            ,   30 -- interval 
            ,   360000 -- max_wait 
            ,   lc_phase -- phase 
            ,   lc_status -- status 
            ,   lc_devphase -- dev_phase 
            ,   lc_devstatus -- dev_status 
            ,   lc_message -- message 
            );

            /* Submit the 'Conversion Summary Report' process */ 
            ln_req_id := fnd_request.submit_request('XXCOMN',   'XXCOMCONVSUMMREP',   NULL,   NULL,   FALSE,   p_process_name,   ln_par_conc_request_id,   ln_chi_conc_request_id,   ln_batch_id);

            /* Start the request */
            COMMIT;

            /* Check that the request submission was OK */

            IF ln_req_id = 0 THEN
              fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Conversion Summary Report Process''.');
            ELSE
              fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Conversion Summary Report Process'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
              fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');
            END IF;

          END IF;

        END IF;

      END IF;

    END LOOP;

    IF nvl(ln_batch_id,   0) = 0 THEN
      fnd_file.PUT_LINE(fnd_file.LOG,   'No records to process in staging table with PROCESS FLAG = 1');
    END IF;

  EXCEPTION
  WHEN no_data_found THEN
    ROLLBACK;
    fnd_file.PUT_LINE(fnd_file.LOG,   'No Data Found Exception Fired  - Master Program.');
    fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
    lc_error_msg := sqlerrm;
    xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   NULL,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_MASTER_CNV',   'cnv.XX_AP_INV_LINES_INTF_CNV_STG',   'REQUEST_ID',   ln_req_submit,   NULL,   ln_batch_id,   lc_error_msg || ';' || lc_error_debug,   SQLCODE,   sqlerrm);

  WHEN others THEN
    ROLLBACK;
    fnd_file.PUT_LINE(fnd_file.LOG,   'Others Exception Fired - Master Program .');
    fnd_file.PUT_LINE(fnd_file.LOG,   sqlerrm);
    lc_error_msg := sqlerrm;
    xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   NULL,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_MASTER_CNV',   'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG',   'REQUEST_ID',   ln_req_submit,   NULL,   ln_batch_id,   lc_error_msg || ';' || lc_error_debug,   SQLCODE,   sqlerrm);

  END ap_invoices_master;

  PROCEDURE ap_invoices_child(x_error_buff OUT VARCHAR2,   x_ret_code OUT NUMBER,   p_process_name IN VARCHAR2,   p_validate_only_flag IN VARCHAR2,   p_reset_status_flag IN VARCHAR2,   p_batch_id IN NUMBER) AS
  CURSOR c_inv_header IS
  SELECT rowid,
    invoice_id,
    invoice_num,
    invoice_type_lookup_code,
    invoice_date,
    po_number,
    invoice_amount,
    invoice_currency_code,
    terms_name,
    description,
    last_update_date,
    creation_date,
    attribute1,
    attribute2,
    attribute3,
    attribute4,
    attribute5,
    attribute6,
    attribute7,
    attribute8,
    attribute9,
    attribute10,
    attribute11,
    attribute12,
    attribute13,
    attribute14,
    attribute15,
    status,
    source,
    voucher_num,
    gl_date,
    exclusive_payment_flag,
    amount_applicable_to_discount,
    goods_received_date,
    terms_date,
    source_system_ref,
    batch_id,
    control_id,
    audit_id
  FROM xxcnv.xx_ap_inv_hdr_intf_cnv_stg xis
  WHERE xis.batch_id = p_batch_id
   AND source NOT LIKE '%1099%'
   AND xis.process_flag = '2';

  CURSOR c_inv_lines(p_voucher_id IN VARCHAR2,   p_audit_id IN NUMBER) IS
  SELECT rowid,
    invoice_id,
    invoice_line_id,
    line_number,
    line_type_lookup_code,
    amount,
    accounting_date,
    description,
    po_number,
    po_line_number,
    dist_code_concatenated,
    ship_to_location_code,
    last_update_date,
    creation_date,
    attribute1,
    attribute2,
    attribute3,
    attribute4,
    attribute5,
    attribute6,
    attribute7,
    attribute8,
    attribute9,
    attribute10,
    attribute11,
    attribute12,
    attribute13,
    attribute14,
    attribute15,
    global_attribute1,
    global_attribute2,
    source_system_ref,
    control_id
  FROM xxcnv.xx_ap_inv_lines_intf_cnv_stg xiis
  WHERE TRIM(xiis.attribute7) = TRIM(p_voucher_id) --AND XIIS.batch_id = p_batch_id
  AND xiis.audit_id = p_audit_id
   AND xiis.process_flag = '1';

  --Cursor to get the Rejected Records 
  CURSOR c_reject_rec IS
  SELECT xxais.rowid,
    ai.invoice_id,
    ai.status
  FROM xxcnv.xx_ap_inv_hdr_intf_cnv_stg xxais,
    ap_invoices_interface ai
  WHERE xxais.batch_id = p_batch_id
   AND xxais.source NOT LIKE '%1099%'
   AND xxais.invoice_num = ai.invoice_num
   AND xxais.voucher_num = ai.voucher_num
   AND xxais.attribute10 = ai.attribute10;

  lr_target xx_fin_translatevalues % rowtype;
  lr_ap_invoices_interface ap_invoices_interface % rowtype;
  lr_ap_invoice_lines_interface ap_invoice_lines_interface % rowtype;
  ln_par_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_chi_conc_request_id fnd_concurrent_requests.request_id%TYPE;
  ln_conversion_id xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
  lc_source_system_code xxcomn.xx_com_conversions_conv.system_code%TYPE;
  lc_inv_currency_code VARCHAR2(10);
  ln_control_id NUMBER;
  ln_org_id NUMBER;
  lc_error_loc VARCHAR2(2000);
  lc_error_msg VARCHAR2(2000);
  lc_error_debug VARCHAR2(2000);
  lc_error_flag_val VARCHAR2(1) := 'N';
  lc_error_flag_proc VARCHAR2(1) := 'N';
  lc_error_message VARCHAR2(2000);
  ln_interface_line_id NUMBER := NULL;
  ln_req_id NUMBER;
  lc_ap_source VARCHAR2(30);

  ln_count NUMBER := 1;
  ln_tot_batch_count NUMBER := 0;
  ln_failed_val_count NUMBER := 0;
  ln_failed_proc_count NUMBER := 0;
  ln_sucess_count NUMBER := 0;
  ln_line_count NUMBER := 0;
  type stg_tbl_type IS TABLE OF rowid INDEX BY pls_integer;
  lt_stg stg_tbl_type;

  lc_phase VARCHAR2(50);
  lc_status VARCHAR2(50);
  lc_devphase VARCHAR2(50);
  lc_devstatus VARCHAR2(50);
  lc_message VARCHAR2(50);
  lc_req_status boolean;

  --lc_set_completion_status_flag VARCHAR2(10) := 'S';
  --lc_set_completion_status_text VARCHAR2(240);

  ln_rej_count NUMBER := 1;
  ln_accept_count NUMBER := 1;

  l_valid_result boolean;
  l_returnmessage VARCHAR2(4000);

  lc_old_concat_segments VARCHAR2(3000);
  -- Old Concat Segments
  lc_old_bu_aff_segment1 fnd_flex_values.flex_value%TYPE;
  -- Old Business Unit 
  lc_old_dt_aff_segment2 fnd_flex_values.flex_value%TYPE;
  -- Old Department 
  lc_old_ac_aff_segment3 fnd_flex_values.flex_value%TYPE;
  -- Old Account
  lc_old_ou_aff_segment4 fnd_flex_values.flex_value%TYPE;
  -- Old Operating Unit 
  lc_old_af_aff_segment5 fnd_flex_values.flex_value%TYPE;
  -- Old Affiliate 
  lc_old_ch_aff_segment6 fnd_flex_values.flex_value%TYPE;
  -- Old Channel 
  lc_new_concat_segments VARCHAR2(3000);
  -- New Concat Segments
  lc_new_cp_aff_segment1 fnd_flex_values.flex_value%TYPE;
  -- New Company
  lc_new_cc_aff_segment2 fnd_flex_values.flex_value%TYPE;
  -- New Cost Center
  lc_new_ac_aff_segment3 fnd_flex_values.flex_value%TYPE;
  -- New Account
  lc_new_lc_aff_segment4 fnd_flex_values.flex_value%TYPE;
  -- New Location
  lc_new_ic_aff_segment5 fnd_flex_values.flex_value%TYPE;
  -- New Inter Company
  lc_new_ch_aff_segment6 fnd_flex_values.flex_value%TYPE;
  -- New Channel 
  lc_new_fu_aff_segment7 fnd_flex_values.flex_value%TYPE;
  -- New Future 
  ln_ccid gl_code_combinations.code_combination_id%TYPE;
  l_new_aff_ccid gl_code_combinations.code_combination_id%TYPE;
  l_id_flex_num fnd_id_flex_structures.id_flex_num%TYPE;
  l_segment_delimiter fnd_id_flex_structures.concatenated_segment_delimiter%TYPE;
  BEGIN
    ln_org_id := fnd_profile.VALUE('ORG_ID');
    fnd_file.PUT_LINE(fnd_file.LOG,   'Org id: ' || ln_org_id);
    ln_chi_conc_request_id := fnd_global.conc_request_id();

    --Printing the Parameters
    fnd_file.PUT_LINE(fnd_file.LOG,   'Parameters         :- ');
    fnd_file.PUT_LINE(fnd_file.LOG,   '---------------------');
    fnd_file.PUT_LINE(fnd_file.LOG,   'Process Name       : ' || p_process_name);
    fnd_file.PUT_LINE(fnd_file.LOG,   'Validate Only Flag : ' || p_validate_only_flag);
    fnd_file.PUT_LINE(fnd_file.LOG,   'Reset Status Flag  : ' || p_reset_status_flag);
    fnd_file.PUT_LINE(fnd_file.LOG,   'Batch ID           : ' || p_batch_id);
    fnd_file.PUT_LINE(fnd_file.LOG,   '---------------------');

    fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
    fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Conversion Code');
    BEGIN
      SELECT conversion_id,
        system_code
      INTO ln_conversion_id,
        lc_source_system_code
      FROM xxcomn.xx_com_conversions_conv
      WHERE conversion_code = p_process_name;
      fnd_file.PUT_LINE(fnd_file.LOG,   'Conversion ID: ' || ln_conversion_id);

    EXCEPTION
    WHEN no_data_found THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'The Process Name     ' || 'C0046' || ' is not defined in Oracle EBS System';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_conversions_conv',   'CONVERSION_CODE',   p_process_name,   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
    WHEN others THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'Error While Populating the Conversion Code';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_conversions_conv',   'CONVERSION_CODE',   p_process_name,   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
    END;

    -- Get the Master Request ID for the 'OD: AP Open Invoices Conversion Master Program 

    BEGIN
      fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
      fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Master Request ID');
      SELECT master_request_id
      INTO ln_par_conc_request_id
      FROM xxcomn.xx_com_control_info_conv
      WHERE batch_id = p_batch_id
       AND conversion_id = ln_conversion_id;
      fnd_file.PUT_LINE(fnd_file.LOG,   'Master Request ID: ' || ln_par_conc_request_id);

    EXCEPTION
    WHEN no_data_found THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'Master Request ID not found for this batch';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_control_info_conv',   'MASTER_REQUEST_ID',   '',   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
    WHEN others THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'Error while populating Master Request ID';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_control_info_conv',   'MASTER_REQUEST_ID',   '',   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
    END;

    /* < Selecting user information into a local variables from fnd_users table > */
    BEGIN
      fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
      fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Conversion User');
      SELECT user_id
      INTO lr_ap_invoices_interface.created_by
      FROM apps.fnd_user
      WHERE user_name = 'CONVERSION';
      lr_ap_invoices_interface.last_updated_by := lr_ap_invoices_interface.created_by;

    EXCEPTION
    WHEN no_data_found THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'The User     ' || 'CONVERSION' || ' is not defined in Oracle EBS System';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_USER',   'USER_ID',   'CONVERSION',   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
    WHEN others THEN
      lc_error_flag_val := 'Y';
      lc_error_message := 'Error while populating User ID';
      fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
      fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
      xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_USER',   'USER_ID',   'CONVERSION',   '',   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);

    END;

    FOR lcu_inv_header IN c_inv_header
    LOOP
      -- Header Loop Begins
      BEGIN
        -- Header Begin 
        fnd_file.PUT_LINE(fnd_file.LOG,   'Processing Batch ID: ' || p_batch_id);
        --Initialization for each transactions 
        lc_error_flag_val := 'N';
        lc_error_flag_proc := 'N';
        lc_error_message := NULL;
        ln_interface_line_id := NULL;
        --lc_ap_source         := lcu_inv_header.source;

        ln_tot_batch_count := ln_tot_batch_count + 1;

        /* < Validating for invoice currency code > */

        IF(lcu_inv_header.invoice_currency_code IS NOT NULL) THEN
          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Invoice Currency Code');
            SELECT currency_code
            INTO lc_inv_currency_code
            FROM fnd_currencies
            WHERE currency_code = UPPER(lcu_inv_header.invoice_currency_code);

          EXCEPTION
          WHEN no_data_found THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'The Invoice Currency ' || lcu_inv_header.invoice_currency_code || ' is not defined in Oracle EBS System';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_CURRENCIES',   'CURRENCY_CODE',   lcu_inv_header.invoice_currency_code,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);

          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'Error while populating the Invoice Currency Code';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_CURRENCIES',   'CURRENCY_CODE',   lcu_inv_header.invoice_currency_code,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);

          END;

        END IF;

        /* < Check if invoice_number already exists in the table apps.ap_invoices_interface table> */
        BEGIN
          fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
          fnd_file.PUT_LINE(fnd_file.LOG,   'Validating the Invoice Number');
          --ln_count := 0;
          SELECT COUNT(1)
          INTO ln_count
          FROM apps.ap_invoices_interface
          WHERE invoice_num = lcu_inv_header.invoice_num
           AND TRIM(attribute10) = TRIM(lcu_inv_header.attribute10)
           AND TRIM(voucher_num) = TRIM(lcu_inv_header.voucher_num);

          IF(ln_count != 0) THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'The Invoice Number ' || lcu_inv_header.invoice_num || 'is already defined in Oracle EBS';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'AP_INVOICES_INTERFACE',   'INVOICE_NUM',   lcu_inv_header.invoice_num,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
            --ELSE

            /*SELECT COUNT(1)
                      INTO ln_count
                      FROM apps.ap_invoices_all
                     WHERE invoice_num = lcu_inv_header.invoice_num
                       AND trim(attribute10) = trim(lcu_inv_header.attribute10);
                     IF (ln_count != 0)
                      THEN
                      lc_error_flag_val := 'Y';
                      lc_error_message := 'The Invoice Number '|| lcu_inv_header.invoice_num
                                                       || 'is already defined in Oracle EBS';
                      fnd_file.put_line(fnd_file.LOG,'See the OD Conversion Exception Log Report.');
                      fnd_file.put_line(fnd_file.LOG,lc_error_message);
                      xx_com_conv_elements_pkg.log_exceptions_proc
                                               (ln_conversion_id
                                                ,lcu_inv_header.control_id
                                                ,lc_source_system_code
                                                ,'XX_AP_INVOICES_CONV_PKG'
                                                ,'AP_INVOICES_CHILD_CNV'
                                                ,'AP_INVOICES_ALL'
                                                ,'INVOICE_NUM'
                                                ,lcu_inv_header.invoice_num
                                                ,lcu_inv_header.source_system_ref
                                                ,p_batch_id
                                                ,lc_error_message
                                                ,SQLCODE
                                                ,SQLERRM
                                               );     
                                                                  
                     ELSE
                      lr_ap_invoices_interface.invoice_num := lcu_inv_header.invoice_num;
                     END IF;
                     */

          ELSE
            lr_ap_invoices_interface.invoice_num := lcu_inv_header.invoice_num;
            --lr_ap_invoices_interface.invoice_num := lcu_inv_header.invoice_num||'-'||TO_CHAR(sysdate,'YYMMDDHH24MISS');

          END IF;

        END;

        /* Get the Global  Vendor Site ID */

         lr_ap_invoices_interface.vendor_site_id := xx_po_global_vendor_pkg.f_translate_inbound(lcu_inv_header.attribute10);

        IF(lr_ap_invoices_interface.vendor_site_id = -1) THEN
          lc_error_flag_val := 'Y';
          lc_error_message := 'The Global Vendor ID  ' || lcu_inv_header.attribute10 || ' is not defined in Oracle EBS System';
          fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
          fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
          xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'PO_VENDOR_SITES_ALL',   'VENDOR_SITE_ID',   lcu_inv_header.attribute10,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
          --END IF;
        ELSE

          /* < Selecting vendor information into a local variables from po_vendor_sites_all table > */
          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Validating the Vendor');
            SELECT vendor_id --,vendor_site_id
            ,
              vendor_site_code,
              payment_method_lookup_code,
              pay_group_lookup_code,
              org_id
            INTO lr_ap_invoices_interface.vendor_id --,lr_ap_invoices_interface.vendor_site_id
            ,
              lr_ap_invoices_interface.vendor_site_code,
              lr_ap_invoices_interface.payment_method_lookup_code,
              lr_ap_invoices_interface.pay_group_lookup_code,
              lr_ap_invoices_interface.org_id
            FROM apps.po_vendor_sites_all
            WHERE vendor_site_id = lr_ap_invoices_interface.vendor_site_id;

          EXCEPTION
          WHEN no_data_found THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'The Vendor ID  ' || lcu_inv_header.attribute10 || ' is not defined in Oracle EBS System';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);

            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'PO_VENDOR_SITES_ALL',   'VENDOR_SITE_ID',   lr_ap_invoices_interface.vendor_site_id,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'Error while populating the Vendor';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'PO_VENDOR_SITES_ALL',   'VENDOR_SITE_ID',   lcu_inv_header.attribute10,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);

          END;
        END IF;

        /* < Translating Payment Terms > */

        IF(lcu_inv_header.terms_name IS NOT NULL) THEN
          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Tranlating the AP Payment Tersms');
            xx_fin_translate_pkg.xx_fin_translatevalue_proc(p_translation_name => 'AP_PAYMENT_TERMS',   p_source_value1 => lcu_inv_header.terms_name --,x_target_value1      => lr_ap_invoices_interface.terms_name
            --,x_target_value2      => lr_target.target_value2
            ,   x_target_value1 => lr_target.target_value1,   x_target_value2 => lr_ap_invoices_interface.terms_name,   x_target_value3 => lr_target.target_value3,   x_target_value4 => lr_target.target_value4,   x_target_value5 => lr_target.target_value5,   x_target_value6 => lr_target.target_value6,   x_target_value7 => lr_target.target_value7,   x_target_value8 => lr_target.target_value8,   x_target_value9 => lr_target.target_value9,   x_target_value10 => lr_target.target_value10,   x_target_value11 => lr_target.target_value11,   x_target_value12 => lr_target.target_value12,   x_target_value13 => lr_target.target_value13,   x_target_value14 => lr_target.target_value14,   x_target_value15 => lr_target.target_value15,   x_target_value16 => lr_target.target_value16,   x_target_value17 => lr_target.target_value17,   x_target_value18 => lr_target.target_value18,   x_target_value19 => lr_target.target_value19,   x_target_value20 => lr_target.target_value20,   x_error_message => lc_error_message);

          EXCEPTION
          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'Payment Terms: ' || lcu_inv_header.terms_name || ' is not defined in Translation Table';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxfin.XX_FIN_TRANSLATEVALUES',   'AP_PAYMENT_TERMS',   lcu_inv_header.terms_name,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
          END;
        ELSE
          lr_ap_invoices_interface.terms_name := lcu_inv_header.terms_name;
        END IF;

        /* < Translating Sources > */

        IF(lcu_inv_header.source IS NOT NULL) THEN
          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Tranlating the AP Source');
            xx_fin_translate_pkg.xx_fin_translatevalue_proc(p_translation_name => 'AP_INVOICE_SOURCE',   p_source_value1 => lcu_inv_header.source,   x_target_value1 => lr_ap_invoices_interface.source,   x_target_value2 => lr_target.target_value2,   x_target_value3 => lr_target.target_value3,   x_target_value4 => lr_target.target_value4,   x_target_value5 => lr_target.target_value5,   x_target_value6 => lr_target.target_value6,   x_target_value7 => lr_target.target_value7,   x_target_value8 => lr_target.target_value8,   x_target_value9 => lr_target.target_value9,   x_target_value10 => lr_target.target_value10,   x_target_value11 => lr_target.target_value11,   x_target_value12 => lr_target.target_value12,   x_target_value13 => lr_target.target_value13,   x_target_value14 => lr_target.target_value14,   x_target_value15 => lr_target.target_value15,   x_target_value16 => lr_target.target_value16,   x_target_value17 => lr_target.target_value17,   x_target_value18 => lr_target.target_value18,   x_target_value19 => lr_target.target_value19,   x_target_value20 => lr_target.target_value20,   x_error_message => lc_error_message);

            --lc_ap_source := lr_ap_invoices_interface.source;                                    

            EXCEPTION
            WHEN others THEN
              lc_error_flag_val := 'Y';
              lc_error_message := 'Source: ' || lcu_inv_header.source || ' is not defined in Translation Table';
              fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
              fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
              xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxfin.XX_FIN_TRANSLATEVALUES',   'AP_INVOICE_SOURCE',   lcu_inv_header.source,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
            END;
          END IF;

          -- Validating AP Transaction Source

          BEGIN

            SELECT flv.lookup_code
            INTO lc_ap_source
            FROM fnd_application_vl fav,
              fnd_lookup_values_vl flv
            WHERE flv.lookup_type = 'SOURCE'
             AND flv.view_application_id = fav.application_id
             AND fav.application_short_name = 'SQLAP'
             AND enabled_flag = 'Y'
             AND lookup_code = lr_ap_invoices_interface.source;

          EXCEPTION
          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := lc_error_message || 'Payable source is not defined in Oracle EBS system SETUP; ' || sqlerrm;
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_LOOKUP_VALUES_VL',   'LOOKUP_CODE',   lr_ap_invoices_interface.source,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
          END;

          /* < Checking whether header_amount is null, assign to local variable> */

          IF(lcu_inv_header.invoice_amount IS NULL) THEN
            --fnd_file.put_line(fnd_file.LOG,'See the OD Conversion Exception Log Report.');
            lc_error_flag_val := 'Y';
            lc_error_message := 'The Currency Code ' || lcu_inv_header.invoice_amount || 'is null defined in PS';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_header.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcnv.XX_AP_INV_HDR_INTF_CNV_STG',   'INVOICE_AMOUNT',   lcu_inv_header.invoice_amount,   lcu_inv_header.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
          ELSE
            lr_ap_invoices_interface.invoice_amount := lcu_inv_header.invoice_amount;
          END IF;

          --lr_ap_invoices_interface.invoice_amount := lcu_inv_header.invoice_amount;

          /* < Assigning sequence number to a local variable > */
          SELECT apps.ap_invoices_interface_s.nextval
          INTO lr_ap_invoices_interface.invoice_id
          FROM dual;

          /* < Assign Invoice Type Lookup Code > */

          IF(lcu_inv_header.invoice_amount < 0) THEN
            lr_ap_invoices_interface.invoice_type_lookup_code := 'CREDIT';
          ELSE
            lr_ap_invoices_interface.invoice_type_lookup_code := 'STANDARD';
          END IF;

          -- Resolution Starts for Defect 1781 
          --lr_ap_invoices_interface.amount_applicable_to_discount	:= lcu_inv_header.amount_applicable_to_discount;

          /*        
           SELECT SUM (amount)
             INTO lr_ap_invoices_interface.amount_applicable_to_discount
             FROM xxcnv.xx_ap_inv_lines_intf_cnv_stg
            WHERE attribute7 = lcu_inv_header.voucher_num --'QVQAEM' 
              AND line_type_lookup_code = 'ITEM'; 
          */ -- Resolution Ends for Defect 1781  
          -- Resolution Starts for Defect 2325 
          lr_ap_invoices_interface.amount_applicable_to_discount := lcu_inv_header.amount_applicable_to_discount;
          -- Resolution Ends for Defect 2325   
          lr_ap_invoices_interface.invoice_date := lcu_inv_header.invoice_date;
          lr_ap_invoices_interface.po_number := lcu_inv_header.po_number;
          lr_ap_invoices_interface.invoice_currency_code := lcu_inv_header.invoice_currency_code;
          lr_ap_invoices_interface.description := lcu_inv_header.description;
          lr_ap_invoices_interface.attribute8 := lcu_inv_header.attribute8;
          lr_ap_invoices_interface.attribute9 := lcu_inv_header.attribute9;
          lr_ap_invoices_interface.attribute10 := lcu_inv_header.attribute10;
          lr_ap_invoices_interface.attribute13 := lcu_inv_header.attribute13;
          lr_ap_invoices_interface.voucher_num := lcu_inv_header.voucher_num;
          --lr_ap_invoices_interface.voucher_num          		    := lcu_inv_header.voucher_num||'-'||TO_CHAR(sysdate,'YYMMDDHH24MISS');
          --lr_ap_invoices_interface.gl_date          		        := lcu_inv_header.gl_date;
          lr_ap_invoices_interface.gl_date := sysdate;
          lr_ap_invoices_interface.exclusive_payment_flag := lcu_inv_header.exclusive_payment_flag;

          -- Resolution Starts for Defect 1421 
          --lr_ap_invoices_interface.goods_received_date           := sysdate;
          lr_ap_invoices_interface.goods_received_date := lcu_inv_header.goods_received_date;
          -- Resolution end for Defect 1421 
          lr_ap_invoices_interface.terms_date := lcu_inv_header.terms_date;
          lr_ap_invoices_interface.goods_received_date := lcu_inv_header.invoice_date;
          --SYSDATE; -- need a value 
          lr_ap_invoices_interface.creation_date := sysdate;
          lr_ap_invoices_interface.last_update_date := sysdate;

          IF(lc_error_flag_val = 'Y') THEN
            ln_failed_val_count := ln_failed_val_count + SQL % rowcount;
            -- lt_stg(ln_count) := lcu_inv_header.ROWID;
            --ln_count := ln_count+1; 

            UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
            SET process_flag = '3'
            WHERE rowid = lcu_inv_header.rowid --AND audit_id = -333
            AND process_flag = 2;
            COMMIT;
          ELSE

            UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
            SET process_flag = '4'
            WHERE rowid = lcu_inv_header.rowid --AND audit_id = -333
            AND process_flag = 2;
            COMMIT;
          END IF;

          IF(p_validate_only_flag = 'N'
           AND lc_error_flag_val = 'N') THEN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                               ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Validate Only Flag is ' || p_validate_only_flag);
            fnd_file.PUT_LINE(fnd_file.LOG,   'Inserting into ap_invoices_interface table.');
            BEGIN
              INSERT
              INTO apps.ap_invoices_interface
              VALUES lr_ap_invoices_interface;
              COMMIT;

            EXCEPTION
            WHEN others THEN
              fnd_file.PUT_LINE(fnd_file.LOG,   'unable to insert:' || sqlerrm);
            END;
          END IF;

          /* < For Loop for the lines > */

          IF(lc_error_flag_val = 'N') THEN
            ln_line_count := 0;
            FOR lcu_inv_lines IN c_inv_lines(lcu_inv_header.voucher_num,   lcu_inv_header.audit_id)
            LOOP
              -- Line Loop Begins 
              ln_line_count := ln_line_count + SQL % rowcount;
              BEGIN
                -- Begin for lines 

                /* < Generating sequence number for invoice_line_id  > */
                SELECT apps.ap_invoice_lines_interface_s.nextval
                INTO lr_ap_invoice_lines_interface.invoice_line_id
                FROM dual;

                /* < Translating ship to location code> */

                IF(lcu_inv_lines.ship_to_location_code IS NOT NULL) THEN
                  BEGIN
                    fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
                    fnd_file.PUT_LINE(fnd_file.LOG,   'Tranlating the Ship to Location Code');
                    xx_fin_translate_pkg.xx_fin_translatevalue_proc(p_translation_name => 'IPO_SHIP_TO_LOCATION',   p_source_value1 => lcu_inv_lines.ship_to_location_code,   x_target_value1 => lr_ap_invoice_lines_interface.ship_to_location_code,   x_target_value2 => lr_target.target_value2,   x_target_value3 => lr_target.target_value3,   x_target_value4 => lr_target.target_value4,   x_target_value5 => lr_target.target_value5,   x_target_value6 => lr_target.target_value6,   x_target_value7 => lr_target.target_value7,   x_target_value8 => lr_target.target_value8,   x_target_value9 => lr_target.target_value9,   x_target_value10 => lr_target.target_value10,   x_target_value11 => lr_target.target_value11,   x_target_value12 => lr_target.target_value12,   x_target_value13 => lr_target.target_value13,   x_target_value14 => lr_target.target_value14,   x_target_value15 => lr_target.target_value15,   x_target_value16 => lr_target.target_value16,   x_target_value17 => lr_target.target_value17,   x_target_value18 => lr_target.target_value18,   x_target_value19 => lr_target.target_value19,   x_target_value20 => lr_target.target_value20,   x_error_message => lc_error_message);

                  EXCEPTION
                  WHEN others THEN
                    lc_error_flag_val := 'Y';
                    lc_error_message := 'Ship to Location: ' || lcu_inv_lines.ship_to_location_code || ' is not defined in Translation Table';
                    fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
                    fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
                    xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_inv_lines.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxfin.XX_FIN_TRANSLATEVALUES',   'IPO_SHIP_TO_LOCATION',   lcu_inv_lines.ship_to_location_code,   lcu_inv_lines.source_system_ref,   p_batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
                  END;

                END IF;

                /* 
                 BEGIN
                 GET_ID_FLEX_NUM(x_id_flex_num        => l_id_flex_num
		                         ,x_segment_delimiter => l_segment_delimiter
		                         ,x_returnMessage     => l_returnMessage) ;
                     IF (l_returnMessage IS NOT NULL) 
                      THEN
                        lc_error_msg := l_returnMessage;
                        xx_com_conv_elements_pkg.log_exceptions_proc
                                             (ln_conversion_id
                                              ,''
                                              ,lc_source_system_code
                                              ,'XX_AP_INVOICES_CONV_PKG'
                                              ,'AP_INVOICES_CHILD_CNV'
                                              ,'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG'
                                              ,'AFF structure not defined:OD_GLOBAL_COA'
                                              ,NULL
                                              ,NULL
                                              ,NULL
                                              ,''
                                              ,lc_error_msg
                                              ,lc_error_loc
                                             );
                     ELSE
                        lc_old_concat_segments := lcu_inv_lines.dist_code_concatenated;
                        
                        lc_old_bu_aff_segment1 := SUBSTR(lc_old_concat_segments,1,
                                                    INSTR(lc_old_concat_segments,'.',1,1)-1);
                        lc_old_dt_aff_segment2 := SUBSTR(lc_old_concat_segments,INSTR(lc_old_concat_segments,'.',1,1)+1,
                                         INSTR(lc_old_concat_segments,'.',1,2 )-INSTR(lc_old_concat_segments,'.',1,1)-1);
                        lc_old_ac_aff_segment3 := SUBSTR(lc_old_concat_segments,INSTR(lc_old_concat_segments,'.',1,2)+1,
                                         INSTR(lc_old_concat_segments,'.',1,3)-INSTR(lc_old_concat_segments,'.',1,2)-1);
                        lc_old_ou_aff_segment4 := SUBSTR(lc_old_concat_segments,INSTR(lc_old_concat_segments,'.',1,3)+1,
                                         INSTR(lc_old_concat_segments,'.',1,4)-INSTR(lc_old_concat_segments,'.',1,3)-1);
                        lc_old_af_aff_segment5 := SUBSTR(lc_old_concat_segments,INSTR(lc_old_concat_segments,'.',1,4)+1,
                                         INSTR(lc_old_concat_segments,'.',1,5)-INSTR(lc_old_concat_segments,'.',1,4)-1);
                        lc_old_ch_aff_segment6 := SUBSTR(lc_old_concat_segments,INSTR(lc_old_concat_segments,'.',1,5)+1);
                        
                        XX_CNV_GL_PSFIN_PKG.TRANSLATE_PS_VALUES (
                                     p_ps_business_unit        => lc_old_bu_aff_segment1
                                    ,p_ps_department           => lc_old_dt_aff_segment2
                                    ,p_ps_account              => lc_old_ac_aff_segment3
                                    ,p_ps_operating_unit       => lc_old_ou_aff_segment4
                                    ,p_ps_affiliate            => lc_old_af_aff_segment5
                                    ,p_ps_sales_channel        => lc_old_ch_aff_segment6
                                    ,p_use_stored_combinations => 'No'
                                    ,p_convert_gl_history      => 'No' 
                                    ,x_seg1_company            => lc_new_cp_aff_segment1
                                    ,x_seg2_costctr            => lc_new_cc_aff_segment2
                                    ,x_seg3_account            => lc_new_ac_aff_segment3
                                    ,x_seg4_location           => lc_new_lc_aff_segment4
                                    ,x_seg5_interco            => lc_new_ic_aff_segment5
                                    ,x_seg6_lob                => lc_new_ch_aff_segment6
                                    ,x_seg7_future             => lc_new_fu_aff_segment7
                                    ,x_ccid                    => ln_ccid
                                    ,x_error_message           => lc_error_msg);

                        -- Compose new concatenated account combinations.
                        lc_new_concat_segments :=   lc_new_cp_aff_segment1 || l_segment_delimiter
                                                 || lc_new_cc_aff_segment2 || l_segment_delimiter
                                                 || lc_new_ac_aff_segment3 || l_segment_delimiter
                                                 || lc_new_lc_aff_segment4 || l_segment_delimiter
			                                     || lc_new_ic_aff_segment5 || l_segment_delimiter
                                                 || lc_new_ch_aff_segment6 || l_segment_delimiter
                                                 || lc_new_fu_aff_segment7;
                       -- Validate account combination exists.
                       l_valid_result := FND_FLEX_KEYVAL.VALIDATE_SEGS
                                         ( operation        => 'CREATE_COMBINATION'
                                           , appl_short_name  => 'SQLGL'
                                           , key_flex_code    => 'GL#'
                                           , structure_number => l_id_flex_num
                                           , concat_segments  => lc_new_concat_segments
                                         ); 
                           IF NOT l_valid_result THEN
      	                           lc_error_msg   := FND_FLEX_KEYVAL.ERROR_MESSAGE;
                                   lc_error_flag_val  := 'Y';
                                   xx_com_conv_elements_pkg.log_exceptions_proc
                                             (ln_conversion_id
                                              ,''
                                              ,lc_source_system_code
                                              ,'XX_AP_INVOICES_CONV_PKG'
                                              ,'AP_INVOICES_CHILD_CNV'
                                              ,'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG'
                                              ,'Unable to Created Distribution CCID'
                                              ,NULL
                                              ,NULL
                                              ,NULL
                                              ,''
                                              ,lc_error_msg
                                              ,lc_error_loc
                                             );
    	                   ELSE
      	                       l_new_aff_ccid := FND_FLEX_KEYVAL.COMBINATION_ID;

      	 	                   IF ( l_new_aff_ccid = -1 ) THEN
         	                      lc_error_msg   := 'Invalid account combination: ' || lc_new_concat_segments;
       		                      lc_error_flag_val  := 'Y';
                                   xx_com_conv_elements_pkg.log_exceptions_proc
                                             (ln_conversion_id
                                              ,''
                                              ,lc_source_system_code
                                              ,'XX_AP_INVOICES_CONV_PKG'
                                              ,'AP_INVOICES_CHILD_CNV'
                                              ,'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG'
                                              ,'Invalid Account combination'
                                              ,NULL
                                              ,NULL
                                              ,NULL
                                              ,''
                                              ,lc_error_msg
                                              ,lc_error_loc
                                             );                                  
                               ELSE	
        	                      --lc_err_msg := l_new_aff_ccid;
                                  lr_ap_invoice_lines_interface.dist_code_combination_id := l_new_aff_ccid;

        	                   END IF;
                           END IF;
                     END IF; 
                 END;
                 */ -- Resolution Starts for defect 1422 

                IF((lcu_inv_header.invoice_currency_code = 'USD')
                 AND(lcu_inv_lines.line_type_lookup_code = 'TAX')) THEN
                  lr_ap_invoice_lines_interface.tax_code := 'SALES';
                  ELSIF((lcu_inv_header.invoice_currency_code = 'CAD')
                   AND(lcu_inv_lines.line_type_lookup_code = 'TAX')) THEN
                    lr_ap_invoice_lines_interface.tax_code := 'GST_INPUT_CR';
                  ELSE
                    lr_ap_invoice_lines_interface.tax_code := NULL;
                  END IF;

                  -- Resolution end for Defect 1422 
                  lr_ap_invoice_lines_interface.dist_code_concatenated := lcu_inv_lines.global_attribute1;
                  lr_ap_invoice_lines_interface.dist_code_combination_id := lcu_inv_lines.global_attribute2;
                  lr_ap_invoice_lines_interface.invoice_id := lr_ap_invoices_interface.invoice_id;
                  lr_ap_invoice_lines_interface.line_number := lcu_inv_lines.line_number;

                  -- Resolution Starts for defect 1088 
                  --lr_ap_invoice_lines_interface.line_type_lookup_code    := 'ITEM'
                  lr_ap_invoice_lines_interface.line_type_lookup_code := lcu_inv_lines.line_type_lookup_code;
                  -- Resolution end for Defect 1088 

                  lr_ap_invoice_lines_interface.amount := lcu_inv_lines.amount;

                  -- Resolution Starts for Defect 1419 
                  --lr_ap_invoice_lines_interface.accounting_date          := lcu_inv_lines.accounting_date;
                  lr_ap_invoice_lines_interface.accounting_date := sysdate;
                  -- Resolutin Ends for Defect 1419 

                  lr_ap_invoice_lines_interface.description := lcu_inv_lines.description;
                  lr_ap_invoice_lines_interface.po_number := lcu_inv_lines.po_number;
                  lr_ap_invoice_lines_interface.po_line_number := lcu_inv_lines.po_line_number;
                  --lr_ap_invoice_lines_interface.attribute7               := lcu_inv_lines.attribute7;
                  --lr_ap_invoice_lines_interface.attribute7               := lcu_inv_lines.attribute7||'-'||TO_CHAR(sysdate,'YYMMDDHH24MISS');
                  --lr_ap_invoice_lines_interface.attribute10              := lcu_inv_lines.attribute10;
                  --lr_ap_invoice_lines_interface.attribute11              := lcu_inv_lines.attribute11;
                  lr_ap_invoice_lines_interface.org_id := lr_ap_invoices_interface.org_id;
                  lr_ap_invoice_lines_interface.creation_date := lr_ap_invoices_interface.creation_date;
                  lr_ap_invoice_lines_interface.created_by := lr_ap_invoices_interface.created_by;
                  lr_ap_invoice_lines_interface.last_update_date := lr_ap_invoices_interface.last_update_date;
                  lr_ap_invoice_lines_interface.last_updated_by := lr_ap_invoices_interface.last_updated_by;

                  IF(p_validate_only_flag = 'N'
                   AND lc_error_flag_val = 'N') THEN
                    fnd_file.PUT_LINE(fnd_file.LOG,   '                               ');
                    fnd_file.PUT_LINE(fnd_file.LOG,   'Validate Only Flag is ' || p_validate_only_flag);
                    fnd_file.PUT_LINE(fnd_file.LOG,   'Inserting into ap_invoice_lines_interface table.');
                    BEGIN
                      INSERT
                      INTO apps.ap_invoice_lines_interface
                      VALUES lr_ap_invoice_lines_interface;
                      COMMIT;

                    EXCEPTION
                    WHEN others THEN
                      fnd_file.PUT_LINE(fnd_file.LOG,   'unable to insert:' || sqlerrm);
                    END;
                  END IF;

                END;
                -- End for lines 
              END LOOP;

              -- END for line loop 
            END IF;

          END;
          -- END for Header Loop 
        END LOOP;

        -- Header Loop 

        IF(p_validate_only_flag = 'N' --AND lc_error_flag_val = 'N'
        AND(lc_ap_source IS NOT NULL)) THEN
          -- Submitting the Payables Open Interface Program. 
-- Gathering Statistics          
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICES_INTERFACE',   estimate_percent => 100);
    END;
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICE_LINES_INTERFACE',   estimate_percent => 100);
    END;
          fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Starting Imports...');

          /* Submit the 'Payables Open Interface Import' process */ 
          ln_req_id := fnd_request.submit_request('SQLAP',   'APXIIMPT',   NULL,   NULL,   FALSE,   lc_ap_source -- Source 
          ,   NULL,   'N/A',   NULL,   NULL,   NULL,   'N',   'N',   'N',   'N',   1000,   fnd_global.user_id,   fnd_global.login_id);

          /* Start the request */
          COMMIT;

          /* Check that the request submission was OK */

          IF ln_req_id = 0 THEN
            fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Payables Open Interface Import''.');
          ELSE
            fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Payables Open Interface Import'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');

            /* Wait for the import request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id -- request_id 
            ,   30 -- interval 
            ,   360000 -- max_wait 
            ,   lc_phase -- phase 
            ,   lc_status -- status 
            ,   lc_devphase -- dev_phase 
            ,   lc_devstatus -- dev_status 
            ,   lc_message -- message 
            );
          END IF;

        END IF;

        -- Get rejected records from the AP IMPORT PROGRAM 
        FOR lcu_reject_rec IN c_reject_rec
        LOOP

          IF(lcu_reject_rec.status = 'REJECTED') THEN
            ln_failed_proc_count := ln_failed_proc_count + 1;

            UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
            SET process_flag = '6'
            WHERE rowid = lcu_reject_rec.rowid;
            ln_rej_count := ln_rej_count + 1;
            COMMIT;
            ELSIF(lcu_reject_rec.status = 'PROCESSED') THEN
              ln_accept_count := ln_accept_count + 1;

              UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
              SET process_flag = '7'
              WHERE rowid = lcu_reject_rec.rowid;
              ln_accept_count := ln_accept_count + 1;
              COMMIT;
            END IF;

          END LOOP;

          -- Get the total number of records processed sucessfully. 
          ln_sucess_count :=(ln_tot_batch_count -ln_failed_val_count -ln_failed_proc_count);

          -- Updating control information 
          lc_error_loc := 'updating control information';
          lc_error_debug := 'Batch ID: ' || p_batch_id;
          xx_com_conv_elements_pkg.upd_control_info_proc(ln_par_conc_request_id,   p_batch_id,   ln_conversion_id,   ln_failed_val_count,   ln_failed_proc_count,   ln_sucess_count);

          -- Print the Open Invoices Conversion Summary into the log file.
          fnd_file.PUT_LINE(fnd_file.LOG,   'Total Number of Records: ' ||(ln_sucess_count + ln_failed_val_count + ln_failed_proc_count));
          fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Records sucessfully loaded:' || ln_sucess_count);
          fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Records failed by Validation: ' || ln_failed_val_count);
          fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Records failed by Import Program: ' || ln_failed_proc_count);

        EXCEPTION
        WHEN no_data_found THEN
          ROLLBACK;
          fnd_file.PUT_LINE(fnd_file.LOG,   'No Data Found Exception Fired  - Child Program.');
          fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
          lc_error_msg := sqlerrm;
          xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG',   'Oracle Errors Found',   NULL,   NULL,   NULL,   '',   lc_error_msg,   lc_error_loc);
        WHEN others THEN
          ROLLBACK;
          fnd_file.PUT_LINE(fnd_file.LOG,   'Others Exception Fired  - Child Program.');
          fnd_file.PUT_LINE(fnd_file.LOG,   sqlerrm);
          lc_error_msg := sqlerrm;
          xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG',   'Oracle Errors Found',   NULL,   NULL,   NULL,   '',   SQLCODE,   sqlerrm);

        END ap_invoices_child;

        -- +===================================================================+
        -- | Name : AP_INVOICES_HOLD_CNV                                       |
        -- | Description :To perform  validations and Import of Open Invoices  |
        -- |      old information from Peoplesoft to AP systems for each batch.|
        -- |          This procedure will be the executable of Concurrent      |
        -- |          Program "OD : AP Open Invoices Hold Conversion  Program" |
        -- | Parameters : x_error_buff, x_ret_code                             |
        -- |                                                                   |
        -- +===================================================================+ 
        PROCEDURE ap_invoices_hold(x_error_buff OUT VARCHAR2,   x_ret_code OUT NUMBER,   p_process_name IN VARCHAR2) AS
        --Cursor to get the Hold Invoices 
        CURSOR c_hold_rec IS
        SELECT rowid,
          invoice_num,
          attribute14,
          batch_id,
          control_id,
          source_system_ref
        FROM xxcnv.xx_ap_inv_hdr_intf_cnv_stg
        WHERE process_flag = '7'
         AND nvl(hold_process_flag,   1) IN(1,   3)
         AND source NOT LIKE '%1099%'
         AND attribute14 = 'Y';
        -- mapping changed from attribute 12 to 14 on 06/19/07 

        ln_conversion_id xxcomn.xx_com_conversions_conv.conversion_id%TYPE;
        lc_source_system_code xxcomn.xx_com_conversions_conv.system_code%TYPE;
        lc_error_flag_val VARCHAR2(1);
        lc_error_message VARCHAR2(2000);
        ln_user_id NUMBER;
        lr_ap_holds ap_holds % rowtype;
        ln_count NUMBER := 0;
        ln_tot_hold_count NUMBER := 0;
        ln_failed_val_count NUMBER := 0;
        ln_failed_proc_count NUMBER := 0;
        ln_sucess_count NUMBER := 0;
        ln_rej_count NUMBER := 1;
        ln_accept_count NUMBER := 1;
        type stg_tbl_type IS TABLE OF rowid INDEX BY pls_integer;
        lt_stg stg_tbl_type;
        BEGIN
          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Conversion Code');
            SELECT conversion_id,
              system_code
            INTO ln_conversion_id,
              lc_source_system_code
            FROM xxcomn.xx_com_conversions_conv
            WHERE conversion_code = p_process_name;
            fnd_file.PUT_LINE(fnd_file.LOG,   'Conversion ID: ' || ln_conversion_id);

          EXCEPTION
          WHEN no_data_found THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'The Process Name     ' || 'C0046' || ' is not defined in Oracle EBS System';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_conversions_conv',   'CONVERSION_CODE',   p_process_name,   '',   '',   lc_error_message,   SQLCODE,   sqlerrm);
          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'Error While Populating the Conversion Code';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'xxcomn.xx_com_conversions_conv',   'CONVERSION_CODE',   p_process_name,   '',   '',   lc_error_message,   SQLCODE,   sqlerrm);
          END;

          BEGIN
            fnd_file.PUT_LINE(fnd_file.LOG,   '                                                ');
            fnd_file.PUT_LINE(fnd_file.LOG,   'Validating Conversion User');
            SELECT user_id
            INTO ln_user_id
            FROM apps.fnd_user
            WHERE user_name = 'CONVERSION';

          EXCEPTION
          WHEN no_data_found THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'The User     ' || 'CONVERSION' || ' is not defined in Oracle EBS System';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_USER',   'USER_ID',   'CONVERSION',   '',   '',   lc_error_message,   SQLCODE,   sqlerrm);
          WHEN others THEN
            lc_error_flag_val := 'Y';
            lc_error_message := 'Error while populating User ID';
            fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
            fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
            xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   '',   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_CHILD_CNV',   'FND_USER',   'USER_ID',   'CONVERSION',   '',   '',   lc_error_message,   SQLCODE,   sqlerrm);

          END;
          FOR lcu_hold_rec IN c_hold_rec
          LOOP
            --Initialization for each transactions 
            lc_error_flag_val := 'N';
            lc_error_message := NULL;

            ln_tot_hold_count := ln_tot_hold_count + 1;
            BEGIN
              SELECT invoice_id,
                org_id
              INTO lr_ap_holds.invoice_id,
                lr_ap_holds.org_id
              FROM ap_invoices_all
              WHERE invoice_num = lcu_hold_rec.invoice_num;

            EXCEPTION
            WHEN others THEN
              lc_error_flag_val := 'Y';
              lc_error_message := 'The invoice not converted';
              fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
              fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
              xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lc_source_system_code,   lcu_hold_rec.control_id,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_HOLD',   'AP_INVOICES_ALL',   'INVOICE_NUM',   lcu_hold_rec.invoice_num,   lcu_hold_rec.source_system_ref,   lcu_hold_rec.batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
            END;

            /* < check if invoice hold already exists in apps.ap_holds_all table > */
            BEGIN

              IF(lr_ap_holds.invoice_id IS NOT NULL) THEN
                SELECT COUNT(1)
                INTO ln_count
                FROM apps.ap_holds_all
                WHERE invoice_id = lr_ap_holds.invoice_id;

                IF(ln_count != 0) THEN
                  lc_error_flag_val := 'Y';
                  lc_error_message := 'Invoice Hold already exists';
                  fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
                  fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
                  xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_hold_rec.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_HOLD',   'AP_HOLDS_ALL',   'INVOICE_ID',   lr_ap_holds.invoice_id,   lcu_hold_rec.source_system_ref,   lcu_hold_rec.batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
                END IF;

              END IF;

            END;

            BEGIN
              SELECT description
              INTO lr_ap_holds.hold_reason
              FROM ap_hold_codes
              WHERE hold_lookup_code = 'US_OD_PS_PAYMENT_HOLD';

            EXCEPTION
            WHEN others THEN
              lc_error_flag_val := 'Y';
              lc_error_message := 'The hold code not defined';
              fnd_file.PUT_LINE(fnd_file.LOG,   'See the OD Conversion Exception Log Report.');
              fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_message);
              xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   lcu_hold_rec.control_id,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_HOLD',   'AP_HOLD_CODES',   'HOLD_LOOKUP_CODE',   'US_OD_PS_PAYMENT_HOLD',   lcu_hold_rec.source_system_ref,   lcu_hold_rec.batch_id,   lc_error_message,   SQLCODE,   sqlerrm);
            END;

            lr_ap_holds.hold_lookup_code := 'US_OD_PS_PAYMENT_HOLD';
            lr_ap_holds.last_update_date := sysdate;
            lr_ap_holds.last_updated_by := ln_user_id;
            lr_ap_holds.held_by := ln_user_id;
            lr_ap_holds.hold_date := sysdate;
            lr_ap_holds.last_update_login := ln_user_id;
            lr_ap_holds.creation_date := sysdate;
            lr_ap_holds.created_by := ln_user_id;

            IF(lc_error_flag_val = 'Y') THEN
              ln_failed_val_count := ln_failed_val_count + SQL % rowcount;

              UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
              SET hold_process_flag = '3'
              WHERE rowid = lcu_hold_rec.rowid
               AND process_flag = 7;
              COMMIT;
            ELSE

              UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
              SET hold_process_flag = '4'
              WHERE rowid = lcu_hold_rec.rowid
               AND process_flag = 7;
              COMMIT;
            END IF;

            IF(lc_error_flag_val = 'N') THEN
              BEGIN
                INSERT
                INTO apps.ap_holds_all
                VALUES lr_ap_holds;
                COMMIT;

              EXCEPTION
              WHEN others THEN
                fnd_file.PUT_LINE(fnd_file.LOG,   'unable to insert:' || sqlerrm);
              END;
            END IF;

          END LOOP;

          -- Get the total number of records processed sucessfully. 
          ln_sucess_count :=(ln_tot_hold_count -ln_failed_val_count);
          -- Print the Open Invoices Conversion Summary into the log file.
          fnd_file.PUT_LINE(fnd_file.LOG,   'Total Number of Hold Records: ' || ln_tot_hold_count);
          fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Hold Records sucessfully loaded:' || ln_sucess_count);
          fnd_file.PUT_LINE(fnd_file.LOG,   'Number of Hold Records failed:  ' || ln_failed_val_count);

        EXCEPTION
        WHEN others THEN
          ROLLBACK;
          xx_com_conv_elements_pkg.log_exceptions_proc(ln_conversion_id,   NULL,   lc_source_system_code,   'XX_AP_INVOICES_CONV_PKG',   'AP_INVOICES_HOLD',   'xxcnv.XX_AP_INV_LINES_INTF_CNV_STG',   'Oracle Errors Found',   NULL,   NULL,   NULL,   '',   SQLCODE,   sqlerrm);
        END ap_invoices_hold;

        PROCEDURE ap_ca_invoices(x_error_buff OUT VARCHAR2,   x_ret_code OUT NUMBER) IS
        CURSOR c_invoice_type IS
        SELECT source
        FROM apps.ap_invoices_interface
        WHERE org_id = fnd_profile.VALUE('ORG_ID')
         AND created_by =
          (SELECT user_id
           FROM fnd_user
           WHERE user_name = 'CONVERSION')
        AND source NOT LIKE '%1099%'
        GROUP BY source;

        --Cursor to get the Rejected Records 
        CURSOR c_reject_rec IS
        SELECT xxais.rowid,
          ai.invoice_id,
          ai.status
        FROM xxcnv.xx_ap_inv_hdr_intf_cnv_stg xxais,
          ap_invoices_interface ai
        WHERE xxais.source NOT LIKE '%1099%'
         AND xxais.invoice_num = ai.invoice_num
         AND xxais.voucher_num = ai.voucher_num
         AND xxais.attribute10 = ai.attribute10;

        ln_req_id NUMBER;
        lc_phase VARCHAR2(50);
        lc_status VARCHAR2(50);
        lc_devphase VARCHAR2(50);
        lc_devstatus VARCHAR2(50);
        lc_message VARCHAR2(50);
        lc_req_status boolean;
        BEGIN
          FOR lcu_invoice_type IN c_invoice_type
          LOOP
            -- Submitting the Payables Open Interface Program. 
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICES_INTERFACE',   estimate_percent => 100);
    END;
    BEGIN
      dbms_stats.gather_table_stats(ownname => 'AP',   tabname => 'AP_INVOICE_LINES_INTERFACE',   estimate_percent => 100);
    END;
            fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Starting Imports...');

            /* Submit the 'Payables Open Interface Import' process */ 
            ln_req_id := fnd_request.submit_request('SQLAP',   'APXIIMPT',   NULL,   NULL,   FALSE,   lcu_invoice_type.source -- Source 
            ,   NULL,   'N/A',   NULL,   NULL,   NULL,   'N',   'N',   'N',   'N',   1000,   fnd_global.user_id,   fnd_global.login_id);

            /* Start the request */
            COMMIT;

            /* Check that the request submission was OK */

            IF ln_req_id = 0 THEN
              fnd_file.PUT_LINE(fnd_file.LOG,   'Error submitting request for ''Payables Open Interface Import''.');
            ELSE
              fnd_file.PUT_LINE(fnd_file.OUTPUT,   'Started ''Payables Open Interface Import'' at ' || to_char(sysdate,   'DD-MON-YYYY HH24:MI:SS'));
              fnd_file.PUT_LINE(fnd_file.OUTPUT,   ' ');

              /* Wait for the import request to complete */ lc_req_status := fnd_concurrent.wait_for_request(ln_req_id -- request_id 
              ,   30 -- interval 
              ,   360000 -- max_wait 
              ,   lc_phase -- phase 
              ,   lc_status -- status 
              ,   lc_devphase -- dev_phase 
              ,   lc_devstatus -- dev_status 
              ,   lc_message -- message 
              );
            END IF;

            -- Get rejected records from the AP IMPORT PROGRAM 
            FOR lcu_reject_rec IN c_reject_rec
            LOOP

              IF(lcu_reject_rec.status = 'REJECTED') THEN
                -- ln_failed_proc_count := ln_failed_proc_count + 1;

                UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
                SET process_flag = '6'
                WHERE rowid = lcu_reject_rec.rowid;
                -- ln_rej_count := ln_rej_count + 1;
                COMMIT;
                ELSIF(lcu_reject_rec.status = 'PROCESSED') THEN
                  -- ln_accept_count := ln_accept_count + 1;

                  UPDATE xxcnv.xx_ap_inv_hdr_intf_cnv_stg
                  SET process_flag = '7'
                  WHERE rowid = lcu_reject_rec.rowid;
                  --  ln_accept_count := ln_accept_count + 1;
                  COMMIT;
                END IF;

              END LOOP;
            END LOOP;
          END ap_ca_invoices;

        END xx_ap_invoices_cnv_pkg;
/
SHOW ERRORS;