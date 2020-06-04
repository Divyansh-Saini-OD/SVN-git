create or replace PACKAGE BODY XX_AR_EBL_RENDER_XLS_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_XLS_PKG                                                             |
-- | Description : Package body for eBilling eXLS bill generation                                       |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Apr-2010 Bushrod Thomas     Initial draft version.                                     |
-- |1.1       06-NOV-2014 RajeshKumar M      Changes made for Deect#31246                               |
-- |1.2       22-Jun-2015 Suresh Naragam     Done Changes to get the additional                         |
-- |                                         Columns data (Module 4B Relase 1) (Proc : XLS_FILE_HEADER) |
-- |1.3       29-Jul-2015 Suresh Naragam     Changes done related to defect#1595                        |
-- |1.4       20-Aug-2015 Suresh Naragam     Module 4B Release 2 Changes                                |
-- |                                         (Proc : GET_XL_TABS_INFO)                                  |
-- |1.5       25-Aug-2015 Suresh Naragam     Module 4B Release 2 Changes                                |
-- |                                         (Proc : RENDER_XLS_P, Logic to delete custom tables data)  |
-- |1.6       03-Dec-2015 Suresh Naragam     Module 4B Release 3 Changes                                |
-- |1.7       27-MAY-2020 Divyansh           Added logic for JIRA NAIT-129167                           |
-- +====================================================================================================+
*/

-- ===========================================================================
-- procedure for printing to the output
-- ===========================================================================
PROCEDURE PUT_OUT_LINE
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to output file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.OUTPUT,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END PUT_OUT_LINE;


-- ===========================================================================
-- procedure for printing to the log
-- ===========================================================================
PROCEDURE PUT_LOG_LINE
( p_buffer     IN      VARCHAR2      DEFAULT ' ' )
IS
BEGIN
  -- if in concurrent program, print to log file
  IF (FND_GLOBAL.CONC_REQUEST_ID > 0) THEN
    FND_FILE.put_line(FND_FILE.LOG,NVL(p_buffer,' '));
  -- else print to DBMS_OUTPUT
  ELSE
    DBMS_OUTPUT.put_line(SUBSTR(NVL(p_buffer,' '),1,255));
  END IF;
END PUT_LOG_LINE;

-- ===========================================================================
-- procedure for logging errors
-- ===========================================================================
PROCEDURE PUT_ERR_LINE (
  p_error_message IN VARCHAR2 := ' '
 ,p_attribute1   IN VARCHAR2 := null
 ,p_attribute2   IN VARCHAR2 := null
 ,p_attribute3   IN VARCHAR2 := null
) IS
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error(p_module_name   => 'AR'
                                ,p_program_name  => 'XX_AR_EBL_RENDER_ZIP_PKG'
                                ,p_attribute1    => p_attribute1
                                ,p_attribute2    => p_attribute2
                                ,p_attribute3    => p_attribute3
                                ,p_attribute4    => fnd_global.user_name
                                ,p_error_message => p_error_message
                                ,p_created_by    => fnd_global.user_id);
END PUT_ERR_LINE;


PROCEDURE GET_TRANSLATION(
  p_translation_name IN VARCHAR2
 ,p_source_value1    IN VARCHAR2
 ,p_source_value2    IN VARCHAR2
 ,x_target_value1    IN OUT NOCOPY VARCHAR2
)
IS
  ls_target_value1  VARCHAR2(240);
  ls_target_value2  VARCHAR2(240);
  ls_target_value3  VARCHAR2(240);
  ls_target_value4  VARCHAR2(240);
  ls_target_value5  VARCHAR2(240);
  ls_target_value6  VARCHAR2(240);
  ls_target_value7  VARCHAR2(240);
  ls_target_value8  VARCHAR2(240);
  ls_target_value9  VARCHAR2(240);
  ls_target_value10 VARCHAR2(240);
  ls_target_value11 VARCHAR2(240);
  ls_target_value12 VARCHAR2(240);
  ls_target_value13 VARCHAR2(240);
  ls_target_value14 VARCHAR2(240);
  ls_target_value15 VARCHAR2(240);
  ls_target_value16 VARCHAR2(240);
  ls_target_value17 VARCHAR2(240);
  ls_target_value18 VARCHAR2(240);
  ls_target_value19 VARCHAR2(240);
  ls_target_value20 VARCHAR2(240);
  ls_error_message  VARCHAR2(240);
BEGIN
  XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC(
    p_translation_name => p_translation_name
   ,p_source_value1    => p_source_value1
   ,p_source_value2    => p_source_value2
   ,x_target_value1    => x_target_value1
   ,x_target_value2    => ls_target_value2
   ,x_target_value3    => ls_target_value3
   ,x_target_value4    => ls_target_value4
   ,x_target_value5    => ls_target_value5
   ,x_target_value6    => ls_target_value6
   ,x_target_value7    => ls_target_value7
   ,x_target_value8    => ls_target_value8
   ,x_target_value9    => ls_target_value9
   ,x_target_value10   => ls_target_value10
   ,x_target_value11   => ls_target_value11
   ,x_target_value12   => ls_target_value12
   ,x_target_value13   => ls_target_value13
   ,x_target_value14   => ls_target_value14
   ,x_target_value15   => ls_target_value15
   ,x_target_value16   => ls_target_value16
   ,x_target_value17   => ls_target_value17
   ,x_target_value18   => ls_target_value18
   ,x_target_value19   => ls_target_value19
   ,x_target_value20   => ls_target_value20
   ,x_error_message    => ls_error_message
  );
END GET_TRANSLATION;



PROCEDURE CHECK_CHILD_REQUEST (
   p_request_id  IN OUT  NOCOPY  NUMBER
) IS
  call_status     boolean;
  rphase          varchar2(80);
  rstatus         varchar2(80);
  dphase          varchar2(30);
  dstatus         varchar2(30);
  message         varchar2(240);
BEGIN
  call_status := FND_CONCURRENT.get_request_status(
                        p_request_id,
                        '',
                        '',
                        rphase,
                        rstatus,
                        dphase,
                        dstatus,
                        message);
  IF ((dphase = 'COMPLETE') and (dstatus = 'NORMAL')) THEN
      put_log_line( 'child request id: ' || p_request_id || ' completed successfully');
  ELSE
      put_log_line( 'child request id: ' || p_request_id || ' did not complete successfully');
  END IF;
END CHECK_CHILD_REQUEST;


  -- Parent concurrent program; purges old data and starts Java child threads
PROCEDURE RENDER_XLS_P (
    Errbuf            OUT NOCOPY VARCHAR2
   ,Retcode           OUT NOCOPY VARCHAR2
   ,p_billing_dt      IN VARCHAR2
)
IS
  ln_thread_count     NUMBER;
  n_conc_request_id   NUMBER := NULL;
  ls_req_data         VARCHAR2(240);
  ln_request_id       NUMBER;        -- parent request id
  cnt_warnings        INTEGER := 0;
  cnt_errors          INTEGER := 0;
  request_status      BOOLEAN;
  ln_purge_days       NUMBER;
BEGIN
  ls_req_data := fnd_conc_global.request_data;
  ln_request_id := fnd_global.conc_request_id;

  IF ls_req_data IS NOT NULL THEN
    put_log_line( ' Back at beginning after spawing ' || ls_req_data || ' threads.');
    ln_thread_count := ls_req_data;

    IF ln_thread_count > 0 THEN
      put_log_line ( 'Checking child threads...');

      -- Check all child requests to see how they finished...
      FOR child_request_rec IN (SELECT request_id, status_code
                                  FROM fnd_concurrent_requests
                                 WHERE parent_request_id = ln_request_id) LOOP
         check_child_request(child_request_rec.request_id);
        IF ( child_request_rec.status_code = 'G' OR child_request_rec.status_code = 'X'
          OR child_request_rec.status_code ='D' OR child_request_rec.status_code ='T'  ) THEN
            cnt_warnings := cnt_warnings + 1;
        ELSIF ( child_request_rec.status_code = 'E' ) THEN
            cnt_errors := cnt_errors + 1;
        END IF;
      END LOOP; -- FOR child_request_rec

      IF cnt_errors > 0 THEN
        put_log_line( 'Setting completion status to ERROR.');
        request_status := fnd_concurrent.set_completion_status('ERROR', '');
      ELSIF cnt_warnings > 0 THEN
        put_log_line( 'Setting completion status to WARNING.');
        request_status := fnd_concurrent.set_completion_status('WARNING', '');
      ELSE
        put_log_line( 'Setting completion status to NORMAL.');
        request_status := fnd_concurrent.set_completion_status('NORMAL', '');
      END IF;
    END IF;

    RETURN; -- end of parent
  END IF;

  get_translation('AR_EBL_CONFIG','RENDER_XLS','PURGE_STG_AFTER_N_DAYS',ln_purge_days);
  IF ln_purge_days IS NOT NULL THEN
    IF ln_purge_days>0 THEN
      DELETE FROM XX_AR_EBL_XLS_STG WHERE creation_date<(SYSDATE-ln_purge_days);
    --Deleting the custom tables data when we delete data from _stg table Start.
      DELETE FROM XX_AR_EBL_XL_TAB_SPLIT_HDR WHERE creation_date<(SYSDATE-ln_purge_days);
      DELETE FROM XX_AR_EBL_XL_TAB_SPLIT_DTL WHERE creation_date<(SYSDATE-ln_purge_days);
    --Deleting the custom tables data when we delete data from _stg table End.
      COMMIT;
    END IF;
  END IF;

  get_translation('AR_EBL_CONFIG','RENDER_XLS','N_THREADS',ln_thread_count);
  IF ln_thread_count IS NULL THEN
    ln_thread_count := 1;
  END IF;

  put_log_line('spawning ' || ln_thread_count || ' thread(s)');

  FOR i IN 1..ln_thread_count LOOP
    put_log_line('thread: ' || i);

    n_conc_request_id :=
      FND_REQUEST.submit_request
      ( application    => 'XXFIN'                      -- application short name
       ,program        => 'XX_AR_EBL_RENDER_XLS_C'     -- concurrent program name
       ,sub_request    => TRUE                         -- is this a sub-request?
       ,argument1      => i                            -- thread_id
       ,argument2      => ln_thread_count);

    -- ===========================================================================
    -- if request was successful
    -- ===========================================================================
    IF (n_conc_request_id > 0) THEN
      -- ===========================================================================
      -- if a child request, then update it for concurrent mgr to process
      -- ===========================================================================
/*    -- Instead of doing the following Update, use FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count)) -- See below
      -- This program will then restart when the child programs are done, so if fnd_conc_global.request_data is NOT NULL at start of proc, check child statuses and end.
      -- If either this Update, or the set_req_globals approach, is not done, the child programs will hang in Invalid, No Manager status.

        UPDATE fnd_concurrent_requests
           SET phase_code = 'P',
               status_code = 'I'
         WHERE request_id = n_conc_request_id;
*/
      -- ===========================================================================
      -- must commit work so that the concurrent manager polls the request
      -- ===========================================================================
      COMMIT;

      put_log_line( ' Concurrent Request ID: ' || n_conc_request_id || '.' );

    -- ===========================================================================
    -- else errors have occured for request
    -- ===========================================================================
    ELSE
      -- ===========================================================================
      -- retrieve and raise any errors
      -- ===========================================================================
      FND_MESSAGE.raise_error;
    END IF;

  END LOOP;

  FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => to_char(ln_thread_count));

END RENDER_XLS_P;


PROCEDURE XLS_FILES_TO_RENDER (
    p_thread_id             IN NUMBER
   ,p_thread_count          IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
  ) IS
BEGIN
    OPEN x_cursor FOR

    SELECT F.file_id, F.invoice_type
      FROM XX_AR_EBL_FILE F
     WHERE F.status='RENDER'
       AND F.file_type='XLS'
       --AND MOD(F.file_id,p_thread_count)=p_thread_id --Commented for defect 31246
       AND MOD(F.transmission_id,p_thread_count)=p_thread_id--Added for defect 31246
       AND F.org_id=FND_GLOBAL.org_id
     ORDER BY file_id;

END XLS_FILES_TO_RENDER;


PROCEDURE SHOW_XLS_FILES_TO_RENDER (
    p_thread_id             IN NUMBER
   ,p_thread_count          IN NUMBER
  ) IS
    lc_files           SYS_REFCURSOR;
    ln_file_id         XX_AR_EBL_FILE.file_id%TYPE;
    ls_invoice_type    XX_AR_EBL_FILE.invoice_type%TYPE;
BEGIN
    XLS_FILES_TO_RENDER(p_thread_id,p_thread_count,lc_files);
    LOOP
      FETCH lc_files INTO ln_file_id,ls_invoice_type;
      EXIT WHEN lc_files%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('file_id=' || ln_file_id || ' invoice_type=' || ls_invoice_type);
    END LOOP;
    CLOSE lc_files;
END SHOW_XLS_FILES_TO_RENDER;


PROCEDURE XLS_FILE_HEADER (
    p_file_id               IN NUMBER
   ,x_cell_total_due        OUT VARCHAR2
   ,x_description           OUT VARCHAR2
   ,x_cell_cons_bill_number OUT VARCHAR2
   ,x_cell_billing_period   OUT VARCHAR2
   ,x_cell_pay_terms        OUT VARCHAR2
   ,x_cell_due_date         OUT VARCHAR2
   ,x_billing_for           OUT VARCHAR2
   ,x_billing_id            OUT VARCHAR2
   ,x_aops_id               OUT VARCHAR2
   ,x_include_header        OUT VARCHAR2
   ,x_logo_hyperlink_url    OUT VARCHAR2
   ,x_logo_alt_text         OUT VARCHAR2
   ,x_logo_path             OUT VARCHAR2
   ,x_total_merchandise_label  OUT VARCHAR2
   ,x_total_merchandise_amt OUT VARCHAR2
   ,x_total_salestax_label  OUT VARCHAR2
   ,x_total_salestax_amt    OUT VARCHAR2
   ,x_total_misc_label      OUT VARCHAR2
   ,x_total_misc_amt        OUT VARCHAR2
   ,x_total_gift_card_label OUT VARCHAR2
   ,x_total_gift_card_amt   OUT VARCHAR2
   ,x_split_tabs_by         OUT VARCHAR2
   ,x_enable_xl_subtotal    OUT VARCHAR2
   ,x_fee_label             OUT VARCHAR2-- Added for 1.7
   ,x_fee_amount            OUT VARCHAR2-- Added for 1.7
) IS
-- Added for 1.7
ln_fee_amt  NUMBER:=0;
lv_inv_type VARCHAR2(20);
-- Ended for 1.7
BEGIN
--- Tariff changes start by 1.7
   BEGIN
      SELECT invoice_type 
	    INTO lv_inv_type
		FROM xx_ar_ebl_file 
       WHERE file_id = p_file_id;
   EXCEPTION WHEN OTHERS THEN
      lv_inv_type := NULL;
   END;
   fnd_file.put_line(fnd_file.log,'lv_inv_type : '||lv_inv_type);
   BEGIN
	   IF lv_inv_type= 'IND' THEN
		  
		  SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id ) + XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)),
			     MAX(NVL((SELECT fee_option 
					FROM xx_cdh_cust_acct_ext_b
				   WHERE cust_account_id = a.cust_account_id
					 AND N_EXT_ATTR1 = a.MBS_DOC_ID
					 AND N_EXT_ATTR2 = a.CUST_DOC_ID 
					 AND rownum =1),'X'))
			INTO ln_fee_amt,g_fee_option
			FROM xx_ar_ebl_ind_hdr_main a
           WHERE file_id = p_file_id;
	   ELSIF lv_inv_type= 'CONS' THEN
		  SELECT SUM(XX_AR_EBL_COMMON_UTIL_PKG.get_hea_fee_amount(customer_trx_id ) + XX_AR_EBL_COMMON_UTIL_PKG.get_line_fee_amount(customer_trx_id)),
			     MAX(NVL((SELECT fee_option 
					FROM xx_cdh_cust_acct_ext_b
				   WHERE cust_account_id = a.cust_account_id
					 AND N_EXT_ATTR1 = a.MBS_DOC_ID
					 AND N_EXT_ATTR2 = a.CUST_DOC_ID 
					 AND rownum =1),'X'))
			INTO ln_fee_amt,g_fee_option
			FROM xx_ar_ebl_cons_hdr_main a
           WHERE file_id = p_file_id;
	   END IF;
   EXCEPTION WHEN OTHERS THEN
      ln_fee_amt := NULL;
   END;
   
   fnd_file.put_line(fnd_file.log,'ln_fee_amt : '||ln_fee_amt);
--- Tariff changes end by 1.7
    SELECT TRIM(P.label_total_due || ' ' || F.total_due) cell_total_due, F.description,
           CASE WHEN F.invoice_type='IND' THEN P.label_cons_bill_number || ' ' || P.value_null_cons_bill_number ELSE P.label_cons_bill_number || ' ' || NVL(F.cons_billing_number, P.value_mult_cons_bills) END cell_cons_bill_number,
           TRIM(P.label_for_billing_period || ' ' || TO_CHAR(T.billing_dt_from,NVL(P.date_format,'MM/DD/RRRR')) || ' - ' || TO_CHAR(T.billing_dt,NVL(P.date_format,'MM/DD/RRRR'))) cell_billing_period,
           TRIM(P.label_pay_terms || ' ' || T.pay_terms) cell_pay_terms,
           TRIM(P.label_bill_due_date || ' ' || TO_CHAR(T.bill_due_dt,NVL(P.date_format,'MM/DD/RRRR'))) cell_due_date,
           TRIM(label_billing_for || ' ' || F.customer_name) billing_for, TRIM(label_billing_id || ' ' || F.account_number) billing_id,
           TRIM(label_account_number || ' ' || F.aops_customer_number) aops_id,
           H.include_header,
           L.logo_hyperlink_url, L.logo_alt_text, L.logo_path,
           --Module 4B Release 1 Start
           TRIM(P.label_total_merchandise_amt || ' ') total_merchandise_label,
           --TRIM(LTRIM(TO_CHAR(F.total_merchandise_amt,'$999,999,999,999.00'))) total_merchandise_amt,
           --F.total_merchandise_amt total_merchandise_amt,  -- Commented for 1.7
           F.total_merchandise_amt - NVL(ln_fee_amt,0) total_merchandise_amt,  -- Added for 1.7
           TRIM(P.label_total_sales_tax_amt || ' ') total_sales_tax_label,
           --TRIM(LTRIM(TO_CHAR(F.total_sales_tax_amt,'$999,999,999,999.00'))) total_sales_tax_amt,
           F.total_sales_tax_amt total_sales_tax_amt,
           TRIM(P.label_total_misc_amt || ' ') total_misc_label,
           --TRIM(LTRIM(TO_CHAR(F.total_misc_amt,'$999,999,999,999.00'))) total_misc_amt,
--           F.total_misc_amt total_misc_amt,-- Commented for 1.7
           DECODE(g_fee_option,'Detail',F.total_misc_amt,F.total_misc_amt + NVL(ln_fee_amt,0)) total_misc_amt,  -- Added for 1.7
           DECODE(F.TOTAL_GIFT_CARD_AMT,0,NULL,NULL,NULL,LTRIM(P.label_total_gift_card_amt || ' ' )) total_gift_card_label,
           --DECODE(F.TOTAL_GIFT_CARD_AMT,0,NULL,NULL,NULL,LTRIM(TO_CHAR(F.total_gift_card_amt,'$999,999,999,999.00'))) total_gift_card_amt
           DECODE(F.TOTAL_GIFT_CARD_AMT,0,NULL,NULL,NULL,F.total_gift_card_amt) total_gift_card_amt
           --Module 4B Release 1 End
           ,SPLIT_TABS_BY
           ,NVL(ENABLE_XL_SUBTOTAL,'N')
		       ,label_fee_amt -- Added for 1.7
		       ,DECODE(g_fee_option,'Detail',NVL(ln_fee_amt,0),NULL)-- Added for 1.7
      INTO X_CELL_TOTAL_DUE, X_DESCRIPTION, X_CELL_CONS_BILL_NUMBER, X_CELL_BILLING_PERIOD, X_CELL_PAY_TERMS, X_CELL_DUE_DATE
          ,X_BILLING_FOR, X_BILLING_ID, X_AOPS_ID, X_INCLUDE_HEADER, X_LOGO_HYPERLINK_URL, X_LOGO_ALT_TEXT, X_LOGO_PATH,
          X_TOTAL_MERCHANDISE_LABEL, X_TOTAL_MERCHANDISE_AMT,
          X_TOTAL_SALESTAX_LABEL, X_TOTAL_SALESTAX_AMT,
          X_TOTAL_MISC_LABEL, X_TOTAL_MISC_AMT,
          X_TOTAL_GIFT_CARD_LABEL, X_TOTAL_GIFT_CARD_AMT,
          X_SPLIT_TABS_BY,
          X_ENABLE_XL_SUBTOTAL,
          x_fee_label,
		      x_fee_amount
      FROM XX_AR_EBL_FILE F
      JOIN XX_AR_EBL_TRANSMISSION T
        ON F.transmission_id=T.transmission_id
      JOIN XX_CDH_EBL_TEMPL_HEADER H
        ON T.customer_doc_id=H.cust_doc_id
    LEFT OUTER JOIN
               (SELECT target_value1 label_billing_for, target_value2 label_account_number, target_value3 label_billing_id, target_value4 label_cons_bill_number,
                       target_value5 value_null_cons_bill_number, target_value6 label_for_billing_period, target_value7 label_pay_terms,
                       target_value8 label_bill_due_date, target_value9 label_total_due, target_value10 date_format, target_value11 value_mult_cons_bills,
                       target_value12 label_total_merchandise_amt, target_value13 label_total_sales_tax_amt,
                       target_value14 label_total_misc_amt, target_value15 label_total_gift_card_amt
                       ,target_value16 label_fee_amt-- Added for 1.7
                  FROM XX_FIN_TRANSLATEDEFINITION D
                  JOIN XX_FIN_TRANSLATEVALUES V
                    ON D.translate_id=V.translate_id
                 WHERE D.translation_name = 'AR_EBL_XLS_HEADER'
                   AND source_value1=FND_GLOBAL.current_language
                   AND V.enabled_flag='Y'
                   AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) P
        ON 1=1
    LEFT OUTER JOIN
               (SELECT V.source_value1 logo_key, V.target_value2 logo_hyperlink_url, V.target_value3 logo_alt_text, V.target_value4 logo_path
                  FROM XX_FIN_TRANSLATEDEFINITION D
                  JOIN XX_FIN_TRANSLATEVALUES V
                    ON D.translate_id=V.translate_id
                 WHERE D.translation_name = 'AR_EBL_LOGOS'
                   AND V.enabled_flag='Y'
                   AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) L
        ON H.logo_file_name=L.logo_key
     WHERE F.file_id=P_FILE_ID;

END XLS_FILE_HEADER;


PROCEDURE XLS_FILE_COLS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN x_cursor FOR

    SELECT rownum column_number,Q.* FROM (
      SELECT C.field_id,
             NVL(C.data_format,TL.format) format,TL.data_type,
             CASE WHEN C.field_id=10025 THEN NVL(INITCAP(SH.po_report_header),NVL(C.label,'Purchase Order'))
                  WHEN C.field_id=10027 THEN NVL(INITCAP(SH.dept_report_header),NVL(C.label,'Department'))
                  WHEN C.field_id=10028 THEN NVL2(SH.dept_report_header,INITCAP(SH.dept_report_header) || ' Description',NVL(C.label,'Department Description'))
                  WHEN C.field_id=10029 THEN NVL(INITCAP(SH.release_report_header),NVL(C.label,'Release'))
                  WHEN C.field_id=10030 THEN NVL(INITCAP(SH.desktop_report_header),NVL(C.label,'Desktop')) ELSE C.label END header,
             SEQ
        FROM XX_CDH_EBL_TEMPL_DTL C
        JOIN XX_AR_EBL_TRANSMISSION TM
          ON C.cust_doc_id=TM.customer_doc_id
         AND C.attribute20 = 'Y' -- Module 4B Release 3 Changes
        JOIN XX_AR_EBL_FILE F
          ON TM.transmission_id=F.transmission_id
        JOIN
             (SELECT V.source_value1 field_id, V.target_value1 data_type, V.target_value2 format
                FROM XX_FIN_TRANSLATEDEFINITION D
                 JOIN XX_FIN_TRANSLATEVALUES V
                   ON D.translate_id=V.translate_id
                WHERE D.translation_name='XX_CDH_EBILLING_FIELDS'
                  AND target_value19='DT'
                  AND V.enabled_flag='Y'
                  AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) TL
          ON TL.field_id=C.field_id
      LEFT OUTER JOIN XX_CDH_A_EXT_RPT_SOFTH_V SH
          ON SH.cust_account_id=TM.customer_id
       WHERE F.file_id=p_file_id
         AND seq>0
      UNION  -- Query to get the concatenated Columns
      SELECT xcecf.CONC_FIELD_ID
            ,NULL
            ,'VARCHAR2'
            ,xcecf.conc_field_label
            ,seq
       FROM XX_CDH_EBL_TEMPL_DTL xcetd,
           XX_CDH_EBL_CONCAT_FIELDS xcecf,
           XX_AR_EBL_FILE xaef
       WHERE xcetd.FIELD_ID = xcecf.CONC_FIELD_ID
       AND xcetd.cust_doc_id = xcecf.cust_doc_id
       AND xcecf.cust_doc_id = xaef.cust_doc_id
       AND xaef.file_id = p_file_id
       AND xcetd.attribute20 = 'Y'
       UNION  -- Query to get the Split Columns Columns
       SELECT xcetd.FIELD_ID
             ,NULL
             ,'VARCHAR2'
             ,label
             ,seq
       FROM XX_CDH_EBL_TEMPL_DTL xcetd,
            XX_AR_EBL_FILE xaef
       WHERE xcetd.cust_doc_id = xaef.cust_doc_id
       AND xaef.file_id = p_file_id
       AND base_field_id IS NOT NULL
       AND attribute20 = 'Y'
       ORDER BY 5) Q;

END XLS_FILE_COLS;


PROCEDURE SHOW_XLS_FILE_COLS (
    p_file_id               IN NUMBER
) IS
  lc_cols                   SYS_REFCURSOR;
  ln_column_number          NUMBER;
  ln_file_id                XX_AR_EBL_FILE.file_id%TYPE;
  ls_field_id               VARCHAR2(30);
  ls_format                 XX_CDH_EBL_TEMPL_DTL.data_format%TYPE;
  ls_data_type              VARCHAR2(240);
  ls_header                 VARCHAR2(240);
BEGIN
  XLS_FILE_COLS(p_file_id,lc_cols);
  LOOP
    FETCH lc_cols INTO ls_field_id,ln_column_number,ls_format,ls_data_type,ls_header;
    EXIT WHEN lc_cols%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('column_number=' || ln_column_number || ' field_id=' || ls_field_id || ' format=' || ls_format || ' data_type=' || ls_data_type || ' header=' || ls_header);
  END LOOP;
  CLOSE lc_cols;
END SHOW_XLS_FILE_COLS;


PROCEDURE XLS_FILE_SORT_COLS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
) IS
BEGIN
  OPEN x_cursor FOR

  SELECT column_number, sort_order, sort_type, data_type FROM
   (SELECT rownum column_number, sort_order, sort_type, data_type
      FROM (SELECT C.sort_order, C.sort_type, TL.data_type, C.seq
                  ,CASE WHEN C.seq>0 THEN 0 ELSE 1 END hide
              FROM XX_CDH_EBL_TEMPL_DTL C
              JOIN XX_AR_EBL_TRANSMISSION TM
                ON C.cust_doc_id=TM.customer_doc_id
               AND C.attribute20 = 'Y' -- Module 4B Release 3 Changes
              JOIN XX_AR_EBL_FILE F
                ON TM.transmission_id=F.transmission_id
              JOIN (SELECT V.source_value1 field_id, V.target_value1 data_type
                      FROM XX_FIN_TRANSLATEDEFINITION D
                      JOIN XX_FIN_TRANSLATEVALUES V
                        ON D.translate_id=V.translate_id
                     WHERE D.translation_name='XX_CDH_EBILLING_FIELDS'
                       AND target_value19='DT'
                       AND V.enabled_flag='Y'
                       AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) TL
                ON TL.field_id=C.field_id
             WHERE F.file_id=p_file_id
             UNION  -- Query to get the concatenated Columns
             SELECT  xcetd.SORT_ORDER, xcetd.SORT_TYPE, 'VARCHAR2' data_type, xcetd.seq
                    ,CASE WHEN xcetd.seq>0 THEN 0 ELSE 1 END hide
               FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                    XX_CDH_EBL_CONCAT_FIELDS xcecf,
                    XX_AR_EBL_FILE xaef
              WHERE xcetd.FIELD_ID = xcecf.CONC_FIELD_ID
                AND xcetd.cust_doc_id = xcecf.cust_doc_id
                AND xcecf.cust_doc_id = xaef.cust_doc_id
                AND xaef.file_id = p_file_id
                AND XCETD.ATTRIBUTE20 = 'Y'
             UNION  -- Query to get the Split Columns Columns
             SELECT xcetd.SORT_ORDER, xcetd.SORT_TYPE, 'VARCHAR2' data_type, xcetd.seq
                   ,CASE WHEN xcetd.seq>0 THEN 0 ELSE 1 END hide
               FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                    XX_AR_EBL_FILE xaef
              WHERE xcetd.cust_doc_id = xaef.cust_doc_id
                AND xaef.file_id = p_file_id
                AND BASE_FIELD_ID is not null
                AND ATTRIBUTE20 = 'Y'
             ORDER BY hide,4))
     WHERE sort_order IS NOT NULL
     ORDER BY sort_order;

END XLS_FILE_SORT_COLS;


PROCEDURE SHOW_XLS_FILE_SORT_COLS (
    p_file_id               IN NUMBER
) IS
  lc_cols                   SYS_REFCURSOR;
  ln_column_number          NUMBER;
  ln_sort_order             XX_CDH_EBL_TEMPL_DTL.sort_order%TYPE;
  ls_sort_type              XX_CDH_EBL_TEMPL_DTL.sort_type%TYPE;
  ls_data_type              VARCHAR2(240);
BEGIN
  XLS_FILE_SORT_COLS(p_file_id,lc_cols);
  LOOP
    FETCH lc_cols INTO ln_column_number, ln_sort_order, ls_sort_type, ls_data_type;
    EXIT WHEN lc_cols%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('column_number='  || ln_column_number || ' sort_order=' || ln_sort_order || ' sort_type=' || ls_sort_type || ' data_type=' || ls_data_type);
  END LOOP;
  CLOSE lc_cols;
END SHOW_XLS_FILE_SORT_COLS;


PROCEDURE XLS_FILE_AGGS (
    p_file_id               IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN X_CURSOR FOR

    SELECT /*+ index(A XX_CDH_EBL_STD_AGGR_DL__IDX01) */ Q.column_number aggr_col, Q.aggr_data_type, NVL(AA.data_format,Q.aggr_format) aggr_format, A.aggr_fun, R.column_number group_col, A.label_on_file agg_label, C.sort_order
      FROM XX_CDH_EBL_STD_AGGR_DTL A
      JOIN XX_AR_EBL_FILE F
        ON A.cust_doc_id=F.cust_doc_id
      JOIN (SELECT rownum column_number,Q.field_id, Q.data_type aggr_data_type, Q.format aggr_format
              FROM (SELECT C.field_id, TL.data_type, TL.format, C.seq, CASE WHEN C.seq>0 THEN 0 ELSE 1 END hide
                      FROM XX_CDH_EBL_TEMPL_DTL C
                      JOIN XX_AR_EBL_TRANSMISSION TM
                        ON C.cust_doc_id=TM.customer_doc_id
                      JOIN XX_AR_EBL_FILE F
                        ON TM.transmission_id=F.transmission_id
                      JOIN (SELECT V.source_value1 field_id, V.target_value1 data_type, V.target_value2 format
                              FROM XX_FIN_TRANSLATEDEFINITION D
                              JOIN XX_FIN_TRANSLATEVALUES V
                                ON D.translate_id=V.translate_id
                             WHERE D.translation_name='XX_CDH_EBILLING_FIELDS'
                               AND target_value19='DT'
                               AND V.enabled_flag='Y'
                               AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) TL
                        ON TL.field_id=C.field_id
                     WHERE F.file_id=p_file_id
                       AND c.attribute20 = 'Y'
                     UNION  -- Query to get the concatenated Columns
                     SELECT XCECF.CONC_FIELD_ID
                          ,'VARCHAR2'
                          ,NULL
                          ,SEQ
                          ,CASE WHEN seq>0 THEN 0 ELSE 1 END hide
                     FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                         XX_CDH_EBL_CONCAT_FIELDS xcecf,
                         XX_AR_EBL_FILE xaef
                     WHERE xcetd.FIELD_ID = xcecf.CONC_FIELD_ID
                     AND xcetd.cust_doc_id = xcecf.cust_doc_id
                     AND xcecf.cust_doc_id = xaef.cust_doc_id
                     AND xaef.file_id = p_file_id
                     AND xcetd.attribute20 = 'Y'
                     UNION  -- Query to get the Split Columns Columns
                     SELECT XCETD.FIELD_ID
                          ,'VARCHAR2'
                           ,NULL
                           ,SEQ
                           ,CASE WHEN seq>0 THEN 0 ELSE 1 END hide
                     FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                          XX_AR_EBL_FILE xaef
                     WHERE xcetd.cust_doc_id = xaef.cust_doc_id
                     AND xaef.file_id = p_file_id
                     and BASE_FIELD_ID is not null
                     AND attribute20 = 'Y'
                     ORDER BY hide, seq) Q) Q
        ON A.aggr_field_id=Q.field_id
      JOIN (SELECT rownum column_number,Q.field_id
              FROM (SELECT C.field_id, C.seq, CASE WHEN C.seq>0 THEN 0 ELSE 1 END hide
                      FROM XX_CDH_EBL_TEMPL_DTL C
                      JOIN XX_AR_EBL_TRANSMISSION TM
                        ON C.cust_doc_id=TM.customer_doc_id
                      JOIN XX_AR_EBL_FILE F
                        ON TM.transmission_id=F.transmission_id
                      JOIN (SELECT V.source_value1 field_id
                              FROM XX_FIN_TRANSLATEDEFINITION D
                              JOIN XX_FIN_TRANSLATEVALUES V
                                ON D.translate_id=V.translate_id
                             WHERE D.translation_name='XX_CDH_EBILLING_FIELDS'
                               AND target_value19='DT'
                               AND V.enabled_flag='Y'
                               AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE)) TL
                        ON TL.field_id=C.field_id
                     WHERE F.file_id=p_file_id
                     AND c.attribute20 = 'Y'
                     UNION  -- Query to get the concatenated Columns
                     SELECT XCECF.CONC_FIELD_ID
                          ,seq
                          ,CASE WHEN seq>0 THEN 0 ELSE 1 END hide
                     FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                         XX_CDH_EBL_CONCAT_FIELDS xcecf,
                         XX_AR_EBL_FILE xaef
                     WHERE xcetd.FIELD_ID = xcecf.CONC_FIELD_ID
                     AND xcetd.cust_doc_id = xcecf.cust_doc_id
                     AND xcecf.cust_doc_id = xaef.cust_doc_id
                     AND xaef.file_id = p_file_id
                     AND xcetd.attribute20 = 'Y'
                     UNION  -- Query to get the Split Columns Columns
                     SELECT XCETD.FIELD_ID
                           ,seq
                           ,CASE WHEN seq>0 THEN 0 ELSE 1 END hide
                     FROM XX_CDH_EBL_TEMPL_DTL xcetd,
                          XX_AR_EBL_FILE xaef
                     WHERE xcetd.cust_doc_id = xaef.cust_doc_id
                     AND xaef.file_id = p_file_id
                     and BASE_FIELD_ID is not null
                     AND attribute20 = 'Y'
                     ORDER BY hide, seq) Q) R
        ON A.change_field_id=R.field_id
      LEFT OUTER JOIN XX_CDH_EBL_TEMPL_DTL C
        ON A.cust_doc_id=C.cust_doc_id
       AND C.field_id=R.field_id
       AND c.attribute20 = 'Y'
      LEFT OUTER JOIN XX_CDH_EBL_TEMPL_DTL AA
        ON A.cust_doc_id=AA.cust_doc_id
       AND AA.field_id=Q.field_id
     WHERE F.file_id=p_file_id
       AND aa.attribute20 = 'Y'
       AND A.aggr_fun IS NOT NULL
     ORDER BY C.sort_order, group_col, aggr_col, A.aggr_fun;

END XLS_FILE_AGGS;

PROCEDURE SHOW_XLS_FILE_AGGS (
    p_file_id               IN NUMBER
) IS
  lc_aggr                   SYS_REFCURSOR;
  ln_aggr_col               NUMBER;
  ls_aggr_fun               XX_CDH_EBL_STD_AGGR_DTL.aggr_fun%TYPE;
  ls_aggr_data_type         VARCHAR2(240);
  ls_aggr_format            VARCHAR2(240);
  ln_group_col              NUMBER;
  ls_agg_label              XX_CDH_EBL_STD_AGGR_DTL.label_on_file%TYPE;
  ln_sort_order             NUMBER;
BEGIN
  XLS_FILE_AGGS(p_file_id,lc_aggr);
  LOOP
    FETCH lc_aggr INTO ln_aggr_col, ls_aggr_data_type, ls_aggr_format, ls_aggr_fun, ln_group_col, ls_agg_label, ln_sort_order;
    EXIT WHEN lc_aggr%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(ls_aggr_fun || ' col'  || ln_aggr_col || ' for col' || ln_group_col || ' groups.  agg_label=' || ls_agg_label || ' sort_order=' || ln_sort_order || ' aggr_data_type=' || ls_aggr_data_type || ' aggr_format=' || ls_aggr_format);
  END LOOP;
  CLOSE lc_aggr;
END SHOW_XLS_FILE_AGGS;


PROCEDURE GET_XL_TABS_INFO (
    p_file_id               IN NUMBER
   ,p_cust_doc_id           IN NUMBER
   ,x_cursor                OUT SYS_REFCURSOR
   ,x_maxtabs               OUT NUMBER
) IS

ln_max_tabs   fnd_profile_option_values.profile_option_value%type := FND_PROFILE.VALUE('XXOD_AR_EBL_XL_MAX_TABS');
lc_spl_chars     VARCHAR2(20);
lc_replace_with  VARCHAR2(30);

BEGIN
  BEGIN
    SELECT V.source_value2, V.target_value1
    INTO lc_spl_chars, lc_replace_with
    FROM XX_FIN_TRANSLATEDEFINITION D
    JOIN XX_FIN_TRANSLATEVALUES V
    ON D.translate_id=V.translate_id
    WHERE D.translation_name='XX_CDH_EBL_SPL_CHAR_LIST'
    AND V.source_value1 = 'TAB_NAME'
    AND V.ENABLED_FLAG='Y'
    AND TRUNC(SYSDATE) BETWEEN V.start_date_active AND NVL(V.end_date_active,SYSDATE);
  EXCEPTION WHEN OTHERS THEN
    lc_spl_chars := NULL;
    lc_replace_with := NULL;
  END;

  OPEN x_cursor FOR

  SELECT DISTINCT tab_num, TRANSLATE(tab_name,lc_spl_chars,lc_replace_with) tab_name
  FROM XX_AR_EBL_XL_TAB_SPLIT_HDR H
  WHERE H.file_id = p_file_id
  AND H.cust_doc_id = NVL(p_cust_doc_id,H.cust_doc_id)
  ORDER BY tab_num;

  x_maxtabs := ln_max_tabs;

END GET_XL_TABS_INFO;

END XX_AR_EBL_RENDER_XLS_PKG;
/