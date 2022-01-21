SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body xx_ap_iby_pmnt_batch_pkg
AS
  -- +=========================================================================
  -- =+
  -- |                  Office Depot - Project Simplify
  -- |
  -- |                            Providge
  -- |
  -- +=========================================================================
  -- =+
  -- | Name             :    XX_AP_IBY_PMNT_BATCH_PKG
  -- |
  -- | Description      :    Package for AP Open Invoice Conversion
  -- |
  -- | RICE ID          :    E1283
  -- |
  -- |
  -- |
  -- |
  -- |
  -- |Change Record:
  -- |
  -- |===============
  -- |
  -- |Version   Date         Author              Remarks
  -- |
  -- |=======   ===========  ================    ========================
  -- |
  -- | 1.0      22-Jul-2013  Paddy Sanjeevi      Initial
  -- |
  -- | 1.1      23-Dec-2013  Paddy Sanjeevi      Modified for Defect 27343
  -- |
  -- | 1.2      12-Feb-2014  Paddy Sanjeevi      Defect 28104        |
  -- | 1.3      21-Mar-2014  Pravendra Lohiya    Defect 30034
  -- | 1.4      07-aug-2014  Lakshmi Tangirala   DEFECT 31288
  -- |
  -- | 1.5      27-Oct-2014  Harvinder Rakhra    Retrofit R12.2
  -- |
  -- | 1.6      03-May-2016  Avinash Baddam      changes for Defect 37797
  -- |
  -- | 1.7      05-Sep-2017  Digamber            changes for Trade Payables project
  -- | 1.8      29-SEP-2017  Digamber S           Changed Query for performance Issue
  -- | 1.9      26-JAN-2018  M K Pramod           Modified Query for Jira NAIT-21069
  -- | 2.0      01-FEB-2018  Ragni Gupta          Modified mail attachment to go as TXT output instead of PDF and performance tuning for NAIT-23282
  -- | 2.1      19-Mar-2018  Priyam Parmar     Changed for cut off date
  -- | 2.2      24-Aug-2018  Jitendra A     Changed to add DSV dropship invoices for JIRA NAIT-23654  
 -- +=========================================================================
  -- =+
PROCEDURE wait_for_child(
    p_request_id IN NUMBER) ------ADDED FOR DEFECT 31288
IS
  lb_complete   BOOLEAN;
  lc_phase      VARCHAR2 (100);
  lc_status     VARCHAR2 (100);
  lc_dev_phase  VARCHAR2 (100);
  lc_dev_status VARCHAR2 (100);
  lc_message    VARCHAR2 (100);
  CURSOR cur_child_req(p_request_id IN NUMBER)
  IS
    SELECT request_id
    FROM fnd_concurrent_requests r
    WHERE parent_request_id =p_request_id;
BEGIN
  FOR c_child IN cur_child_req(p_request_id)
  LOOP
    fnd_file.put_line(fnd_file.log,'Waiting for Child Request :   '|| c_child.request_id||'-'||CURRENT_TIMESTAMP);
    lb_complete :=fnd_concurrent.wait_for_request (request_id => c_child.request_id ,interval => 2 ,max_wait => 0 ,phase => lc_phase ,status => lc_status ,dev_phase => lc_dev_phase ,dev_status => lc_dev_status , MESSAGE => lc_message );
    LOOP
      EXIT
    WHEN ( upper(lc_dev_phase) = 'COMPLETE' OR lc_phase = 'C' ) ;
    END LOOP;
    wait_for_child(c_child.request_id);
  END LOOP;
END;
-- +======================================================================+
-- | Name        :  xx_attch_rpt                                          |
-- | Description :  This procedure attaching a document to the mail       |
-- |                                                                      |
-- | Parameters  :  conn, p_filename                                      |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_attch_rpt(
    conn       IN OUT nocopy utl_smtp.connection,
    p_filename IN VARCHAR2)
IS
  fil bfile;
  file_len pls_integer;
  buf raw(2100);
  amt binary_integer := 672 * 3;
  /* ensures proper format;  2016 */
  pos pls_integer := 1;
  /* pointer for each piece */
  filepos pls_integer := 1;
  /* pointer for the file */
  v_directory_name VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_line           VARCHAR2(1000);
  mesg             VARCHAR2(32767);
  mesg_len         NUMBER;
  crlf             VARCHAR2(2) := chr(13) || chr(10);
  data raw(2100);
  chunks pls_integer;
  LEN pls_integer := 1;
  modulo pls_integer;
  pieces pls_integer;
  err_num         NUMBER;
  err_msg         VARCHAR2(100);
  v_mime_type_bin VARCHAR2(30) := 'application/pdf';
BEGIN
  xx_pa_pb_mail.begin_attachment( conn => conn, mime_type => 'application/txt', inline => true, filename => p_filename, transfer_enc => 'base64');
  fil        := bfilename(v_directory_name,p_filename);
  file_len   := dbms_lob.getlength(fil);
  modulo     := mod(file_len, amt);
  pieces     := TRUNC(file_len / amt);
  IF (modulo <> 0) THEN
    pieces   := pieces + 1;
  END IF;
  dbms_lob.fileopen(fil, dbms_lob.file_readonly);
  dbms_lob.read(fil, amt, filepos, buf);
  data := NULL;
  FOR i IN 1..pieces
  LOOP
    BEGIN
      filepos  := i        * amt + 1;
      file_len := file_len - amt;
      data     := utl_raw.concat(data, buf);
      chunks   := TRUNC(utl_raw.length(data) / xx_pa_pb_mail.max_base64_line_width);
      IF (i    <> pieces) THEN
        chunks := chunks - 1;
      END IF;
      xx_pa_pb_mail.write_raw( conn => conn, MESSAGE => utl_encode.base64_encode(data ) );
      data        := NULL;
      IF (file_len < amt AND file_len > 0) THEN
        amt       := file_len;
      END IF;
      dbms_lob.read(fil, amt, filepos, buf);
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END LOOP;
  dbms_lob.fileclose(fil);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in xx_attch_rpt :'||sqlerrm);
END xx_attch_rpt;

--wait_and_submit_cons_rtv - called for consolidated RTV 
PROCEDURE wait_and_submit_cons_rtv(
    -- p_checkrun_id IN NUMBER,
    p_request_id IN NUMBER)
IS
  lb_result        BOOLEAN;
  lc_phase         VARCHAR2 (100);
  lc_status        VARCHAR2 (100);
  lc_dev_phase     VARCHAR2 (100) := NULL;
  lc_dev_status    VARCHAR2 (100);
  lc_message       VARCHAR2 (100);
  lc_rtv_file_name VARCHAR2(240);
  ln_count         NUMBER := 0;
  ln_req_id        NUMBER;
  v_file_name      VARCHAR2(100);
  v_dfile_name     VARCHAR2(200);
  v_sfile_name     VARCHAR2(100);
  conn utl_smtp.connection;
  v_email_list     VARCHAR2(2000);
  v_request_id     NUMBER;
  vc_request_id    NUMBER;
  v_phase          VARCHAR2(100) ;
  x_cdummy         VARCHAR2(2000) ;
  v_cdphase        VARCHAR2(100) ;
  v_cdstatus       VARCHAR2(100) ;
  v_cphase         VARCHAR2(100) ;
  v_cstatus        VARCHAR2(100) ;
  lc_email_subject VARCHAR2(250)  := '';
  lc_email_content VARCHAR2(1000) := '';
BEGIN
  IF p_request_id                  <> 0 THEN
    lc_phase                       := NULL;
    lc_status                      := NULL;
    lc_dev_phase                   := NULL;
    lc_dev_status                  := NULL;
    lc_message                     := NULL;
    WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
    -- wait for request till the request is not completed
    LOOP
      lb_result := fnd_concurrent.wait_for_request (p_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
    END LOOP;
  END IF;
  BEGIN
    SELECT SUBSTR(xftv.target_value1,0,instr(xftv.target_value1,'.')-1)
      || TO_CHAR(p_request_id)
      || '.TXT',
      xftv.target_value6,
      xftv.target_value7
    INTO lc_rtv_file_name,
      lc_email_subject,
      lc_email_content
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftd.translation_name = 'APDM_ADDRESS_DTLS'
    AND xftv.source_value1    ='RTV File Name'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    lc_rtv_file_name :=NULL;
  END;
  ln_req_id := fnd_request.submit_request('XXFIN' ,'XXAPDMTRF' ,NULL ,NULL , false ,p_request_id ,lc_rtv_file_name);
  COMMIT;
  IF ln_req_id                     <> 0 THEN
    lc_phase                       := NULL;
    lc_status                      := NULL;
    lc_dev_phase                   := NULL;
    lc_dev_status                  := NULL;
    lc_message                     := NULL;
    WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
    -- wait for request till the request is not completed
    LOOP
      lb_result := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
    END LOOP;
  END IF;
END wait_and_submit_cons_rtv;

--Start changes for Defect 37797
PROCEDURE wait_and_submit_rtv(
    p_checkrun_id IN NUMBER,
    p_request_id  IN NUMBER)
IS
  lb_result        BOOLEAN;
  lc_phase         VARCHAR2 (100);
  lc_status        VARCHAR2 (100);
  lc_dev_phase     VARCHAR2 (100) := NULL;
  lc_dev_status    VARCHAR2 (100);
  lc_message       VARCHAR2 (100);
  lc_rtv_file_name VARCHAR2(240);
  ln_count         NUMBER := 0;
  ln_req_id        NUMBER;
  v_file_name      VARCHAR2(100);
  v_dfile_name     VARCHAR2(200);
  v_sfile_name     VARCHAR2(100);
  conn utl_smtp.connection;
  v_email_list     VARCHAR2(2000);
  v_request_id     NUMBER;
  vc_request_id    NUMBER;
  v_phase          VARCHAR2(100) ;
  x_cdummy         VARCHAR2(2000) ;
  v_cdphase        VARCHAR2(100) ;
  v_cdstatus       VARCHAR2(100) ;
  v_cphase         VARCHAR2(100) ;
  v_cstatus        VARCHAR2(100) ;
  lc_email_subject VARCHAR2(250)  := '';
  lc_email_content VARCHAR2(1000) := '';
BEGIN
  IF p_request_id                  <> 0 THEN
    lc_phase                       := NULL;
    lc_status                      := NULL;
    lc_dev_phase                   := NULL;
    lc_dev_status                  := NULL;
    lc_message                     := NULL;
    WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
    -- wait for request till the request is not completed
    LOOP
      lb_result := fnd_concurrent.wait_for_request (p_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
    END LOOP;
  END IF;
  BEGIN
    SELECT SUBSTR(xftv.target_value1,0,instr(xftv.target_value1,'.')-1)
      || TO_CHAR(p_request_id)
      || '.TXT',
      xftv.target_value6,
      xftv.target_value7
    INTO lc_rtv_file_name,
      lc_email_subject,
      lc_email_content
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftd.translation_name = 'APDM_ADDRESS_DTLS'
    AND xftv.source_value1    ='RTV File Name'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    lc_rtv_file_name :=NULL;
  END;
  BEGIN
    SELECT MIN(pvsa.email_address) email,
      COUNT(ai.vendor_site_id)
    INTO v_email_list,
      ln_count
    FROM ap_invoices_all ai ,
      ap_suppliers pv ,
      ap_supplier_sites_all pvsa ,
      xx_fin_translatedefinition def ,
      xx_fin_translatevalues val
    WHERE 1               =1
    AND ai.vendor_site_id = p_checkrun_id --658023 --663083
      --  AND AI.invoice_num LIKE 'RTV%'
      --  AND AI.SOURCE LIKE '%RTV%'
      --  AND AI.VOUCHER_NUM IS NOT NULL
    AND NVL(ai.voucher_num, ai.doc_sequence_value) IS NOT NULL
      --AND AI.invoice_type_lookup_code = 'DEBIT' -- 'CREDIT'
    AND val.target_value1    =ai.source
    AND def.translate_id     = val.translate_id
    AND def.translation_name = 'AP_INVOICE_SOURCE'
    AND ai.vendor_site_id    = pvsa.vendor_site_id
    AND pv.vendor_id         = pvsa.vendor_id
    AND EXISTS
      (SELECT 1
      FROM xx_ap_confirmed_payment_batch apb
      WHERE 1=1
        -- AND  apb.creation_date   > sysdate -1
      AND apb.checkrun_id   = ai.vendor_site_id
      AND apb.payment_batch = ai.invoice_num
      )
    AND EXISTS
      (SELECT 1
      FROM xx_ap_xxaprtvapdm_tmp t
      WHERE t.vendor_id = ai.vendor_site_id
      AND t.invoice_num = ai.invoice_num
      );
    fnd_file.put_line(fnd_file.log, 'p_checkrun_id - ' || p_checkrun_id );
    fnd_file.put_line(fnd_file.log, 'v_email_list - ' || v_email_list );
    fnd_file.put_line(fnd_file.log, 'ln count  - ' || ln_count );
  EXCEPTION
  WHEN no_data_found THEN
    ln_count := 0;
    fnd_file.put_line(fnd_file.log, 'ln count NO_DATA_FOUND - ' || ln_count );
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Exception in count - ' || sqlerrm );
    ln_count := 0;
  END;
  fnd_file.put_line(fnd_file.log, 'ln count - ' || ln_count );
  --v_email_list := 'ragni.gupta1@officedepot.com';--'rajesh.gupta@officedepot.com';--'digamber.somavanshi@officedepot.com';
  IF ln_count > 0 THEN
    fnd_file.put_line(fnd_file.log, 'Wait for RTV : email' || v_email_list );
    IF p_request_id                  <> 0 THEN
      WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call wait
      -- for request till the request is not completed
      LOOP
        lb_result := fnd_concurrent.wait_for_request (p_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
      END LOOP;
      fnd_file.put_line(fnd_file.log, 'lc_dev_phase' || lc_dev_phase );
      --lc_rtv_file_name := 'ODRTV';
      -- send Email
      fnd_file.put_line(fnd_file.log, 'send Email' || v_file_name );
      v_file_name :='o'||TO_CHAR(p_request_id)||'.out';
      v_sfile_name:=lc_rtv_file_name||'_'||TO_CHAR(sysdate,'MMDDYYHH24MI')||'.TXT';
      v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
      fnd_file.put_line(fnd_file.log, 'send Email v_dfile_name' || v_dfile_name ) ;
      --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
      -- v_status,v_dphase,v_dstatus,x_dummy)) THEN
      --  IF v_dphase       = 'COMPLETE' THEN
      v_file_name    :='$APPLCSF/$APPLOUT/'||v_file_name;
      vc_request_id  := fnd_request.submit_request('XXFIN','XXCOMFILCOPY', 'OD: Common File Copy',NULL,false, v_file_name,v_dfile_name,NULL,NULL, NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL ,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL ,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      IF vc_request_id>0 THEN
        COMMIT;
      END IF;
      fnd_file.put_line(fnd_file.log, 'After OD: Common File Copy' );
      IF (fnd_concurrent.wait_for_request(vc_request_id,1,60000,v_cphase, v_cstatus,v_cdphase,v_cdstatus,x_cdummy)) THEN
        IF v_cdphase = 'COMPLETE' THEN -- child
          fnd_file.put_line(fnd_file.log, 'Email Address :'||v_email_list);
          conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
          fnd_file.put_line(fnd_file.log, 'before attch ');
          xx_attch_rpt(conn,v_sfile_name);
          xx_pa_pb_mail.end_attachment(conn => conn);
          xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
          xx_pa_pb_mail.end_mail( conn => conn );
          COMMIT;
        END IF; --IF v_cdphase = 'COMPLETE' THEN -- child
      END IF;   --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,
      -- v_cphase,
    END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main
  END IF;
  IF ln_count  > 0 THEN
    ln_req_id := fnd_request.submit_request('XXFIN' ,'XXAPDMTRF' ,NULL ,NULL , false ,p_request_id ,lc_rtv_file_name);
    COMMIT;
    IF ln_req_id                     <> 0 THEN
      lc_phase                       := NULL;
      lc_status                      := NULL;
      lc_dev_phase                   := NULL;
      lc_dev_status                  := NULL;
      lc_message                     := NULL;
      WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
      -- wait for request till the request is not completed
      LOOP
        lb_result := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
      END LOOP;
    END IF;
  END IF;
  DELETE FROM xx_ap_xxaprtvapdm_tmp WHERE request_id = p_request_id;
  COMMIT;
END wait_and_submit_rtv;
PROCEDURE wait_and_submit_chargeback(
    p_checkrun_id IN NUMBER,
    p_request_id  IN NUMBER)
IS
  lb_result               BOOLEAN;
  lc_phase                VARCHAR2 (100);
  lc_status               VARCHAR2 (100);
  lc_dev_phase            VARCHAR2 (100) := NULL;
  lc_dev_status           VARCHAR2 (100);
  lc_message              VARCHAR2 (100);
  lc_chargeback_file_name VARCHAR2(240);
  ln_count                NUMBER := 0;
  ln_req_id               NUMBER;
BEGIN
  IF p_request_id                  <> 0 THEN
    WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call wait
    -- for request till the request is not completed
    LOOP
      lb_result := fnd_concurrent.wait_for_request (p_request_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
    END LOOP;
    --Query for fetching Charge Back file
    BEGIN
      SELECT SUBSTR(xftv.target_value1,0,instr(xftv.target_value1,'.')-1)
        || TO_CHAR(p_request_id)
        || '.TXT'
      INTO lc_chargeback_file_name
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftd.translation_name = 'APDM_ADDRESS_DTLS'
      AND xftv.source_value1    = 'Chargeback File Name'
      AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
      AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
      AND xftv.enabled_flag = 'Y'
      AND xftd.enabled_flag = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      lc_chargeback_file_name := NULL;
    END;
    BEGIN
      SELECT COUNT(NVL(ai.voucher_num, ai.doc_sequence_value))--Added for V1.9
      INTO ln_count
      FROM ap_invoices_all ai ,
        ap_invoice_payments_all aip ,
        ap_checks_all ac ,
        ap_inv_selection_criteria_all aisc ,
        ap_suppliers pv ,
        ap_supplier_sites pvsa ,
        hr_locations hl ,
        fnd_lookup_values_vl flv
      WHERE aisc.checkrun_id                          = p_checkrun_id
      AND ac.checkrun_name                            = aisc.checkrun_name
      AND aisc.status                                IN ('CONFIRMED','SELECTED') -- Defect 30544
      AND aip.check_id                                = ac.check_id
   --   AND ai.attribute12                              = 'Y'
    AND (ai.attribute12                               ='Y' OR ai.invoice_num like 'DSV%') 
      AND ai.invoice_type_lookup_code                 = 'STANDARD'
      AND NVL(ai.voucher_num, ai.doc_sequence_value) IS NOT NULL--Added for V1.9
        --AND AI.voucher_num                           IS NOT NULL
      AND ai.pay_group_lookup_code                  = flv.lookup_code
      AND flv.lookup_type                           ='APCHARGEBACK_PAYGROUP'
      AND TRUNC(NVL(flv.end_date_active,sysdate+1)) > TRUNC(sysdate)
      AND aip.invoice_id                            = ai.invoice_id
      AND ai.vendor_site_id                         = pvsa.vendor_site_id
      AND pv.vendor_id                              = pvsa.vendor_id
      AND pvsa.bill_to_location_id                  = hl.location_id;
    EXCEPTION
    WHEN OTHERS THEN
      ln_count := 0;
    END;
    IF ln_count  > 0 THEN
      ln_req_id := fnd_request.submit_request('XXFIN' ,'XXAPDMTRF' ,NULL ,NULL ,false ,p_request_id ,lc_chargeback_file_name);
      COMMIT;
      IF ln_req_id                     <> 0 THEN
        lc_phase                       := NULL;
        lc_status                      := NULL;
        lc_dev_phase                   := NULL;
        lc_dev_status                  := NULL;
        lc_message                     := NULL;
        WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
        -- wait for request till the request is not completed
        LOOP
          lb_result := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
        END LOOP;
      END IF;
    END IF;
  END IF;
END wait_and_submit_chargeback;
--End changes for Defect 37797
PROCEDURE get_format_request_id(
    p_template_name IN VARCHAR2 ,
    p_request_id    IN NUMBER ,
    p_fmt_req_id OUT NUMBER ,
    p_child_status OUT VARCHAR2 )
IS
  CURSOR c1(p_request_id NUMBER)
  IS
    SELECT a.user_concurrent_program_name ,
      a.concurrent_program_name ,
      b.request_id
    FROM fnd_concurrent_programs_vl a ,
      fnd_concurrent_requests b
    WHERE b.parent_request_id  =p_request_id
    AND b.concurrent_program_id=a.concurrent_program_id
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
          dbms_output.put_line( 'Scheduled Payment Selection Report Completed, Request id :'||TO_CHAR (v_sel_request_id));
        END IF;
      END IF;
    elsif cur.concurrent_program_name='IBYBUILD' THEN
      v_bld_request_id              :=cur.request_id;
      IF (fnd_concurrent.wait_for_request(v_bld_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
        IF v_dphase    = 'COMPLETE' THEN
          v_bld_status:='Y';
          fnd_file.put_line(fnd_file.log, 'Build Payments Completed, Request id :'||TO_CHAR(v_bld_request_id));
          dbms_output.put_line('Build Payments Completed, Request id :'|| TO_CHAR(v_bld_request_id));
        END IF;
      END IF;
    END IF;
  END LOOP;
  IF p_template_name='ACH DAILY' THEN
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
              dbms_output.put_line( 'Format Payment Instructions with Text Output Completed, Request id :' ||TO_CHAR(v_for_request_id));
              p_fmt_req_id   :=v_for_request_id;
              p_child_status :='Y';
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF ; -- IF v_bld_status='Y' THEN
  ELSE       -- IF p_template_name='ACH DAILY' THEN
    IF v_bld_status   ='Y' THEN
      p_fmt_req_id   :=v_bld_request_id;
      p_child_status :='Y';
    ELSE
      p_fmt_req_id   :=NULL;
      p_child_status :='N';
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'When others in get_format_request_id :'|| sqlerrm);
  p_fmt_req_id   :=NULL;
  p_child_status :='N';
END get_format_request_id;
PROCEDURE submit_eft_reports(
    p_template_name IN VARCHAR2 ,
    p_template_id   IN NUMBER ,
    p_checkrun_name IN VARCHAR2 ,
    p_email_id      IN VARCHAR2 ,
    p_pay_thu_dt    IN VARCHAR2 ,
    p_output_format IN VARCHAR2 )
IS
  lb_temp       BOOLEAN;
  ln_req_id1    NUMBER;
  ln_req_id11   NUMBER;
  ln_req_id2    NUMBER;
  ln_req_id22   NUMBER;
  ln_req_id3    NUMBER;
  ln_req_id33   NUMBER;
  lc_phase      VARCHAR2(50);
  lc_reqstatus  VARCHAR2(50);
  lc_devphase   VARCHAR2(50);
  lc_devstatus  VARCHAR2(50);
  lc_message    VARCHAR2(50);
  lc_req_status BOOLEAN;
  lc_error_loc  VARCHAR2(2000) := NULL;
  lc_err_msg    VARCHAR2(250);
  lc_shor_name  VARCHAR2(250):='OD: AP EFT Payment Batch Process';
BEGIN
  IF p_template_name='EFT MWF' THEN
    /* Sumbit request for EFT NonMatch Expense Report */
    lb_temp    := fnd_request.add_layout('XXFIN','XXAPEFTNME','en','US', p_output_format);
    lb_temp    := fnd_request.set_print_options('XPTR',NULL,'1',true,'N');
    ln_req_id1 := fnd_request.submit_request('XXFIN','XXAPEFTNME',NULL,NULL, false ,p_checkrun_name,'-10000.00','10000.00',chr(0) );
    COMMIT;
    IF ln_req_id1 = 0 THEN
      fnd_file.put_line(fnd_file.log, 'Error submitting request for ''EFT NonMatch Expense Report''.');
      lc_error_loc := 'Error submitting EFT Non Match Expense Report';
      lc_err_msg   := 'Error submitting request for EFT Non Match Expense Report for : '|| p_template_name||' ,'||sqlerrm;
      fnd_file.put_line(fnd_file.log, lc_err_msg);
      xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation' );
    ELSE
      fnd_file.put_line(fnd_file.output, 'Started ''EFT NonMatch Expense Report'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
      fnd_file.put_line(fnd_file.output, ' ');
      /* Wait for the request to complete */
      lc_req_status := fnd_concurrent.wait_for_request(ln_req_id1 -- request_id
      , 30                                                        -- interval
      , 360000                                                    -- max_wait
      , lc_phase                                                  -- phase
      , lc_reqstatus                                              -- status
      , lc_devphase                                               -- dev_phase
      , lc_devstatus                                              -- dev_status
      , lc_message                                                -- message
      );
      /* Submit the 'Common Emailer Program' process */
      ln_req_id11 := fnd_request.submit_request('xxfin','XXODXMLMAILER',NULL, NULL,false,'', p_email_id, 'EFT Non-Match Expense Report', 'Please find the attachment of Output File', 'Y', ln_req_id1, 'XXAPEFTNME');
      COMMIT;
      IF ln_req_id11 = 0 THEN
        fnd_file.put_line(fnd_file.log, 'Error submitting request for ''Email Process''.');
        lc_error_loc := 'Error submitting Email of Non Match Expense Report';
        lc_err_msg   := 'Error submitting Email request for EFT Non Match Expense Report for : ' ||p_template_name||' ,'||sqlerrm;
        fnd_file.put_line(fnd_file.log, lc_err_msg);
        xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
      ELSE
        -- Next Report
        fnd_file.put_line(fnd_file.output, 'Started ''Sending Email'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
        fnd_file.put_line(fnd_file.output, ' ');
        /* Sumbit request for EFT Expense Pay Activity Report */
        lb_temp    := fnd_request.add_layout('XXFIN', 'XXAPEFTPAR', 'en', 'US', p_output_format);
        lb_temp    := fnd_request.set_print_options('XPTR', NULL, '1', true, 'N');
        ln_req_id2 := fnd_request.submit_request('XXFIN','XXAPEFTPAR',NULL,NULL ,false, p_checkrun_name,p_template_id,p_pay_thu_dt);
        COMMIT;
        IF ln_req_id2 = 0 THEN
          fnd_file.put_line(fnd_file.log, 'Error submitting request for ''EFT Expense Pay Activity Report''.');
          lc_error_loc := 'Error submitting EFT Expense Pay Activity Report';
          lc_err_msg   := 'Error submitting EFT Expense Pay Activity Report for : '|| p_template_name||' ,'||sqlerrm;
          fnd_file.put_line(fnd_file.log, lc_err_msg);
          xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
        ELSE
          fnd_file.put_line(fnd_file.output, 'Started ''EFT Expense Pay Activity Report'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
          fnd_file.put_line(fnd_file.output, ' ');
          lc_req_status := fnd_concurrent.wait_for_request(ln_req_id2 --
          -- request_id
          , 30           -- interval
          , 360000       -- max_wait
          , lc_phase     -- phase
          , lc_reqstatus -- status
          , lc_devphase  -- dev_phase
          , lc_devstatus -- dev_status
          , lc_message   -- message
          );
          /* Submit the 'Common Emailer Program' process */
          ln_req_id22 := fnd_request.submit_request('xxfin', 'XXODXMLMAILER', NULL, NULL, false, '', p_email_id, 'EFT Expense Pay Activity Report', 'Please find the attachment of Output File', 'Y', ln_req_id2, 'XXAPEFTPAR');
          COMMIT;
          /* Check that the request submission was OK */
          IF ln_req_id22 = 0 THEN
            fnd_file.put_line(fnd_file.log, 'Error submitting request for ''Email Process''.');
            lc_error_loc := 'Error submitting request for Email Process';
            lc_err_msg   := 'Error submitting Email request for EFT Expense Pay Activity for template : ' ||p_template_name||' ,'||sqlerrm;
            fnd_file.put_line(fnd_file.log, lc_err_msg);
            xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
          ELSE
            fnd_file.put_line(fnd_file.output, 'Started ''Sending Email'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.put_line(fnd_file.output, ' ');
          END IF;
        END IF; -- IF ln_req_id2 = 0 THEN
      END IF;   -- IF ln_req_id11 = 0 THEN
    END IF;     -- IF ln_req_id1 = 0 THEN
    --  Added by Pravendra for defect 30034
    lb_temp    := fnd_request.add_layout('XXFIN', 'XXAPEFTNMT', 'en', 'US', p_output_format);
    lb_temp    := fnd_request.set_print_options('XPTR', NULL, '1', true, 'N');
    ln_req_id3 := fnd_request.submit_request('XXFIN','XXAPEFTNMT',NULL,NULL, false ,p_checkrun_name,'-24999.99','24999.99',chr(0) );
    COMMIT;
    IF ln_req_id3 = 0 THEN
      fnd_file.put_line(fnd_file.log, 'Error submitting request for ''EFT NonMatch Trade Report''.');
      lc_error_loc := 'Error submitting EFT Non Match Trade Report';
      lc_err_msg   := 'Error submitting EFT Non Match Trade Report for template : '|| p_template_name||' ,'||sqlerrm;
      fnd_file.put_line(fnd_file.log, lc_err_msg);
      xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation' );
    ELSE
      fnd_file.put_line(fnd_file.output, 'Started ''EFT NonMatch Trade Report'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
      fnd_file.put_line(fnd_file.output, ' ');
      /* Wait for the request to complete */
      lc_req_status := fnd_concurrent.wait_for_request(ln_req_id3 -- request_id
      , 30                                                        -- interval
      , 360000                                                    -- max_wait
      , lc_phase                                                  -- phase
      , lc_reqstatus                                              -- status
      , lc_devphase                                               -- dev_phase
      , lc_devstatus                                              -- dev_status
      , lc_message                                                -- message
      );
      /* Submit the 'Common Emailer Program' process */
      ln_req_id33 := fnd_request.submit_request('xxfin','XXODXMLMAILER',NULL, NULL,false,'', p_email_id, 'EFT Non-Match Trade Report', 'Please find the attachment of Output File', 'Y',ln_req_id3, 'XXAPEFTNMT' );
      COMMIT;
      /* Check that the request submission was OK */
      IF ln_req_id33 = 0 THEN
        fnd_file.put_line(fnd_file.log, 'Error submitting request for ''Email Process''.');
        lc_error_loc := 'Error submitting request for Email Process';
        lc_err_msg   := 'Error submitting request for Email request EFT Non-Match Trade Report for the tempate : ' ||p_template_name||' ,'||sqlerrm;
        fnd_file.put_line(fnd_file.log, lc_err_msg);
        xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
      ELSE
        fnd_file.put_line(fnd_file.output, 'Started ''Sending Email'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
        fnd_file.put_line(fnd_file.output, ' ');
      END IF; --ln_req_id33
    END IF;   --ln_req_id3
    -- End of changes for defect 30034
  END IF; -- IF p_template_name='EFT MWF' THEN
  IF ( (p_template_name NOT LIKE 'EFT%MWF%') AND ( p_template_name LIKE 'EFT%' ) ) THEN
    --p_template_name IN ('EFT TTH','EFT DAILY') THEN
    /* Sumbit request for EFT NonMatch Trade Report */
    lb_temp    := fnd_request.add_layout('XXFIN', 'XXAPEFTNMT', 'en', 'US', p_output_format);
    lb_temp    := fnd_request.set_print_options('XPTR', NULL, '1', true, 'N');
    ln_req_id1 := fnd_request.submit_request('XXFIN','XXAPEFTNMT',NULL,NULL, false ,p_checkrun_name,'-24999.99','24999.99',chr(0) );
    COMMIT;
    IF ln_req_id1 = 0 THEN
      fnd_file.put_line(fnd_file.log, 'Error submitting request for ''EFT NonMatch Trade Report''.');
      lc_error_loc := 'Error submitting EFT Non Match Trade Report';
      lc_err_msg   := 'Error submitting EFT Non Match Trade Report for template : '|| p_template_name||' ,'||sqlerrm;
      fnd_file.put_line(fnd_file.log, lc_err_msg);
      xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation' );
    ELSE
      fnd_file.put_line(fnd_file.output, 'Started ''EFT NonMatch Trade Report'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
      fnd_file.put_line(fnd_file.output, ' ');
      /* Wait for the request to complete */
      lc_req_status := fnd_concurrent.wait_for_request(ln_req_id1 -- request_id
      , 30                                                        -- interval
      , 360000                                                    -- max_wait
      , lc_phase                                                  -- phase
      , lc_reqstatus                                              -- status
      , lc_devphase                                               -- dev_phase
      , lc_devstatus                                              -- dev_status
      , lc_message                                                -- message
      );
      /* Submit the 'Common Emailer Program' process */
      ln_req_id11 := fnd_request.submit_request('xxfin','XXODXMLMAILER',NULL, NULL,false,'', p_email_id, 'EFT Non-Match Trade Report', 'Please find the attachment of Output File', 'Y',ln_req_id1, 'XXAPEFTNMT' );
      COMMIT;
      /* Check that the request submission was OK */
      IF ln_req_id11 = 0 THEN
        fnd_file.put_line(fnd_file.log, 'Error submitting request for ''Email Process''.');
        lc_error_loc := 'Error submitting request for Email Process';
        lc_err_msg   := 'Error submitting request for Email request EFT Non-Match Trade Report for the tempate : ' ||p_template_name||' ,'||sqlerrm;
        fnd_file.put_line(fnd_file.log, lc_err_msg);
        xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
      ELSE
        fnd_file.put_line(fnd_file.output, 'Started ''Sending Email'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
        fnd_file.put_line(fnd_file.output, ' ');
        /* Sumbit request for EFT Trade Pay Activity Report */
        lb_temp    := fnd_request.add_layout('XXFIN', 'XXAPEFTPAR', 'en', 'US', p_output_format);
        lb_temp    := fnd_request.set_print_options('XPTR', NULL, '1', true, 'N');
        ln_req_id2 := fnd_request.submit_request('XXFIN','XXAPEFTPAR',NULL,NULL ,false,p_checkrun_name,p_template_id,p_pay_thu_dt);
        COMMIT;
        IF ln_req_id2 = 0 THEN
          fnd_file.put_line(fnd_file.log, 'Error submitting request for ''EFT Trade Pay Activity Report''.');
          lc_error_loc := 'Error submitting EFT Trade Pay Activity Report';
          lc_err_msg   := 'Error submitting EFT Trade Pay Activity Report for the template : ' ||p_template_name||' ,'||sqlerrm;
          fnd_file.put_line(fnd_file.log, lc_err_msg);
          xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation' );
        ELSE
          fnd_file.put_line(fnd_file.output, 'Started ''EFT Trade Pay Activity Report'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
          fnd_file.put_line(fnd_file.output, ' ');
          lc_req_status := fnd_concurrent.wait_for_request(ln_req_id2 --
          -- request_id
          , 30           -- interval
          , 360000       -- max_wait
          , lc_phase     -- phase
          , lc_reqstatus -- status
          , lc_devphase  -- dev_phase
          , lc_devstatus -- dev_status
          , lc_message   -- message
          );
          /* Submit the 'Common Emailer Program' process */
          ln_req_id22 := fnd_request.submit_request('xxfin', 'XXODXMLMAILER', NULL, NULL, false, '', p_email_id, 'EFT Trade Pay Activity Report', 'Please find the attachment of Output File', 'Y', ln_req_id2, 'XXAPEFTPAR');
          COMMIT;
          /* Check that the request submission was OK */
          IF ln_req_id22 = 0 THEN
            fnd_file.put_line(fnd_file.log, 'Error submitting request for ''Email Process''.');
            lc_error_loc := 'Error submitting Email Process';
            lc_err_msg   := 'Error submitting Email request for EFT Trade Pay Activity for the template : ' ||p_template_name||' ,'||sqlerrm;
            fnd_file.put_line(fnd_file.log, lc_err_msg);
            xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM', p_program_name => lc_shor_name, p_program_id => fnd_global.conc_program_id, p_module_name => 'AP', p_error_location => 'Error at ' || lc_error_loc, p_error_message_count => 1, p_error_message_code => 'E', p_error_message => lc_err_msg, p_error_message_severity => 'Major', p_notify_flag => 'N', p_object_type => 'Payment Batch Automation');
          ELSE
            fnd_file.put_line(fnd_file.output, 'Started ''Sending Email'' at ' || TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
            fnd_file.put_line(fnd_file.output, ' ');
          END IF;
        END IF ; ---  IF ln_req_id2 = 0 THEN
      END IF;    ---  IF ln_req_id11 = 0 THEN
    END IF;      ---  IF ln_req_id1 = 0 THEN
  END IF;         --     IF p_template_name IN ('EFT TTH','EFT DAILY') THEN
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'When others in submit_eft_reports : '|| sqlerrm);
END submit_eft_reports;
PROCEDURE submit_eft_process(
    p_errbuf        IN OUT VARCHAR2 ,
    p_retcode       IN OUT NUMBER ,
    p_checkrun_id   IN NUMBER ,
    p_template_name IN VARCHAR2 ,
    p_payment_date  IN VARCHAR2 ,
    p_pay_thru_date IN VARCHAR2 ,
    p_pay_from_date IN VARCHAR2 ,
    p_email_id      IN VARCHAR2 ,
    p_output_format IN VARCHAR2 )
IS
  v_request_id     NUMBER;
  v_crequest_id    NUMBER;
  v_user_id        NUMBER:=fnd_global.user_id;
  v_phase          VARCHAR2(100) ;
  v_status         VARCHAR2(100) ;
  v_dphase         VARCHAR2(100) ;
  v_dstatus        VARCHAR2(100) ;
  x_dummy          VARCHAR2(2000) ;
  ln_org_id        NUMBER;
  v_template_id    NUMBER;
  v_timestamp      VARCHAR2(25);
  v_file_name      VARCHAR2(200);
  v_sfile_name     VARCHAR2(200);
  v_dfile_name     VARCHAR2(200);
  v_child_requests NUMBER;
  lc_err_msg       VARCHAR2(250);
  lc_error_loc     VARCHAR2(2000) := NULL;
  v_child_status   VARCHAR2(1);
  v_fmt_request_id NUMBER;
  v_checkrun_name  VARCHAR2(255);
BEGIN
  ln_org_id := fnd_profile.value('ORG_ID');
  BEGIN
    fnd_client_info.set_org_context(ln_org_id);
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
  fnd_file.put_line(fnd_file.log, 'Parameters');
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  fnd_file.put_line(fnd_file.log, '            Checkrun Id : ' || TO_CHAR( p_checkrun_id));
  fnd_file.put_line(fnd_file.log, '          Template Name : ' || p_template_name);
  fnd_file.put_line(fnd_file.log, '           Payment Date : ' || TO_CHAR( p_payment_date));
  fnd_file.put_line(fnd_file.log, '       Pay Through Date : ' || TO_CHAR( p_pay_thru_date));
  fnd_file.put_line(fnd_file.log, '          Pay From Date : ' || TO_CHAR( p_pay_from_date));
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  v_request_id  :=fnd_request.submit_request( 'SQLAP' ,'APXPBASL' , 'Payment Process Request Program' ,NULL ,false ,p_checkrun_id ,v_template_id ,p_payment_date ,p_pay_thru_date ,p_pay_from_date );
  IF v_request_id>0 THEN
    COMMIT;
    dbms_output.put_line('Payment Process Request Program Request id : '|| TO_CHAR(v_request_id));
    fnd_file.put_line(fnd_file.log, 'Payment Process Request Program EFT '|| p_template_name|| ' Request id : '|| TO_CHAR(v_request_id));
    IF (fnd_concurrent.wait_for_request(v_request_id,1,60000,v_phase, v_status, v_dphase,v_dstatus,x_dummy)) THEN
      IF v_dphase = 'COMPLETE' THEN
        fnd_file.put_line(fnd_file.log, 'Payment Process Request Program EFT  ' ||p_template_name|| '  Completed');
      END IF;
    END IF;
  ELSE
    fnd_file.put_line(fnd_file.log, 'Error submitting request for EFT  '|| p_template_name|| ' Payment Process Request Program');
    lc_error_loc := 'Error submitting request for EFT Payment Process Request Program';
    lc_err_msg   := 'Error submitting request for EFT  '||p_template_name|| ' Payment Process Request Program : '|| p_template_name;
    fnd_file.put_line(fnd_file.log, lc_err_msg);
    xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' , p_program_name => 'OD: AP EFT Payment Batch Process' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_err_msg , p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Payment Batch Automation');
  END IF;
  COMMIT;
  SELECT COUNT(1)
  INTO v_child_requests
  FROM fnd_concurrent_programs_vl a ,
    fnd_concurrent_requests b
  WHERE b.parent_request_id      =v_request_id
  AND b.concurrent_program_id    =a.concurrent_program_id
  AND a.concurrent_program_name IN ('APINVSEL','IBYBUILD');
  IF v_child_requests            > 0 THEN
    get_format_request_id ( p_template_name,v_request_id,v_fmt_request_id, v_child_status);
    fnd_file.put_line(fnd_file.log, 'Format Payment Request Id : '||TO_CHAR( v_fmt_request_id));
    fnd_file.put_line(fnd_file.log, 'Build Status : '||v_child_status);
    fnd_file.put_line(fnd_file.log, 'Template Name : '||p_template_name);
    BEGIN
      SELECT checkrun_name
      INTO v_checkrun_name
      FROM ap_inv_selection_criteria_all
      WHERE request_id=v_fmt_request_id;
    EXCEPTION
    WHEN OTHERS THEN
      v_checkrun_name :=NULL;
    END;
    fnd_file.put_line(fnd_file.log, 'Checkrun Name : '||v_checkrun_name);
    IF v_child_status='Y' THEN
      submit_eft_reports(p_template_name,v_template_id,v_checkrun_name, p_email_id,p_pay_thru_date,p_output_format);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'When others in submit_eft_process :'|| sqlerrm);
  dbms_output.put_line('When others in submit_eft_process :'||sqlerrm);
END submit_eft_process;
PROCEDURE submit_ach_process(
    p_errbuf        IN OUT VARCHAR2 ,
    p_retcode       IN OUT NUMBER ,
    p_checkrun_id   IN NUMBER ,
    p_template_name IN VARCHAR2 ,
    p_payment_date  IN VARCHAR2 ,
    p_pay_thru_date IN VARCHAR2 ,
    p_pay_from_date IN VARCHAR2 )
IS
  ln_org_id        NUMBER;
  v_request_id     NUMBER;
  v_crequest_id    NUMBER;
  v_user_id        NUMBER:=fnd_global.user_id;
  v_phase          VARCHAR2(100) ;
  v_status         VARCHAR2(100) ;
  v_dphase         VARCHAR2(100) ;
  v_dstatus        VARCHAR2(100) ;
  x_dummy          VARCHAR2(2000) ;
  v_fmt_request_id NUMBER;
  v_template_id    NUMBER;
  v_timestamp      VARCHAR2(25);
  v_file_name      VARCHAR2(200);
  v_sfile_name     VARCHAR2(200);
  v_dfile_name     VARCHAR2(200);
  v_child_requests NUMBER;
  lc_err_msg       VARCHAR2(250);
  lc_error_loc     VARCHAR2(2000) := NULL;
  v_child_status   VARCHAR2(1);
  v_checkrun_name  VARCHAR2(255);
  v_file_prefix    VARCHAR2(255);
BEGIN
  ln_org_id := fnd_profile.value('ORG_ID');
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
  fnd_file.put_line(fnd_file.log, 'Parameters');
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  fnd_file.put_line(fnd_file.log, '            Checkrun Id : ' || TO_CHAR( p_checkrun_id));
  fnd_file.put_line(fnd_file.log, '          Template Name : ' || p_template_name);
  fnd_file.put_line(fnd_file.log, '           Payment Date : ' || TO_CHAR( p_payment_date));
  fnd_file.put_line(fnd_file.log, '       Pay Through Date : ' || TO_CHAR( p_pay_thru_date));
  fnd_file.put_line(fnd_file.log, '          Pay From Date : ' || TO_CHAR( p_pay_from_date));
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  v_request_id  :=fnd_request.submit_request( 'SQLAP' ,'APXPBASL' , 'Payment Process Request Program' ,NULL ,false ,p_checkrun_id ,v_template_id ,p_payment_date ,p_pay_thru_date ,p_pay_from_date );
  IF v_request_id>0 THEN
    COMMIT;
    dbms_output.put_line('Payment Process Request Program Request id : '|| TO_CHAR(v_request_id));
    fnd_file.put_line(fnd_file.log, 'Payment Process Request Program ACH Request id : '|| TO_CHAR(v_request_id) );
    IF (fnd_concurrent.wait_for_request(v_request_id,1,60000,v_phase, v_status, v_dphase,v_dstatus,x_dummy)) THEN
      IF v_dphase = 'COMPLETE' THEN
        fnd_file.put_line(fnd_file.log, 'Payment Process Request Program ACH Completed');
        BEGIN
          SELECT checkrun_name
          INTO v_checkrun_name
          FROM ap_inv_selection_criteria_all
          WHERE request_id=v_request_id;
        EXCEPTION
        WHEN OTHERS THEN
          v_checkrun_name :=NULL;
        END;
      END IF;
    END IF;
  ELSE
    fnd_file.put_line(fnd_file.log, 'Error submitting request for ACH Payment Process Request Program');
    lc_error_loc := 'Error submitting request for ACH Payment Process Request Program';
    lc_err_msg   := 'Error submitting request for ACH Payment Process Request Program : '|| p_template_name;
    fnd_file.put_line(fnd_file.log, lc_err_msg);
    xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' , p_program_name => 'OD ACH Process' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_err_msg , p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Payment Batch Automation');
  END IF;
  COMMIT;
  SELECT COUNT(1)
  INTO v_child_requests
  FROM fnd_concurrent_programs_vl a ,
    fnd_concurrent_requests b
  WHERE b.parent_request_id      =v_request_id
  AND b.concurrent_program_id    =a.concurrent_program_id
  AND a.concurrent_program_name IN ('APINVSEL','IBYBUILD');
  IF v_child_requests            > 0 THEN
    get_format_request_id ( p_template_name,v_request_id,v_fmt_request_id, v_child_status);
    BEGIN
      SELECT e.outbound_pmt_file_prefix
      INTO v_file_prefix
      FROM iby_sys_pmt_profiles_b e,
        iby_acct_pmt_profiles_b d,
        ap_inv_selection_criteria_all c,
        fnd_concurrent_programs b,
        fnd_concurrent_requests a
      WHERE a.parent_request_id    =24592346
      AND b.concurrent_program_id  =a.concurrent_program_id
      AND b.concurrent_program_name='APINVSEL'
      AND c.checkrun_id            =a.argument1
      AND d.payment_profile_id     =c.payment_profile_id
      AND e.system_profile_code    =d.system_profile_code;
    EXCEPTION
    WHEN OTHERS THEN
      v_file_prefix:='WB_ACH_NACHA';
    END;
    IF v_fmt_request_id>0 THEN
      v_timestamp     :=TO_CHAR(sysdate,'YYYYMMDD_HH24MISS');
      v_file_name     :=v_file_prefix||TO_CHAR(v_fmt_request_id)||'.out';
      v_sfile_name    :='$APPLCSF/$APPLOUT/'||v_file_name;
      v_dfile_name    :='$XXFIN_DATA/ftp/out/nacha/'||v_file_prefix||'_'|| v_timestamp||'.dat';
      fnd_file.put_line(fnd_file.log,'Source File      : '||v_sfile_name);
      fnd_file.put_line(fnd_file.log,'Destination File : '||v_dfile_name);
      v_request_id  :=fnd_request.submit_request('XXFIN','XXCOMFILCOPY', 'OD: Common File Copy',NULL,false, v_sfile_name,v_dfile_name,NULL,NULL, NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      IF v_request_id>0 THEN
        COMMIT;
        dbms_output.put_line('File Transfer request id : '||TO_CHAR( v_request_id));
        fnd_file.put_line(fnd_file.log, 'XXCOMFILCOPY Request id for ACH File Copy : '|| TO_CHAR(v_request_id)) ;
      ELSE
        fnd_file.put_line(fnd_file.log, 'Error submitting request for XXCOMFILCOPY for ACH file');
        lc_error_loc := 'Error submitting request for XXCOMFILCOPY for ACH File';
        lc_err_msg   := 'Error submitting request for XXCOMFILCOPY for ACH File';
        fnd_file.put_line(fnd_file.log, lc_err_msg);
        xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => 'OD ACH Process' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_err_msg , p_error_message_severity => 'Major' ,p_notify_flag => 'N' , p_object_type => 'Payment Batch Automation');
      END IF;
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'When others in submit_ach_process :'|| sqlerrm);
  dbms_output.put_line('When others in submit_ach_process :'||sqlerrm);
END submit_ach_process;
PROCEDURE submit_payment_process(
    p_errbuf        IN OUT VARCHAR2 ,
    p_retcode       IN OUT NUMBER ,
    p_checkrun_id   IN NUMBER ,
    p_template_name IN VARCHAR2 ,
    p_payment_date  IN VARCHAR2 ,
    p_pay_thru_date IN VARCHAR2 ,
    p_pay_from_date IN VARCHAR2 )
IS
  ln_org_id      NUMBER;
  v_request_id   NUMBER;
  v_template_id  NUMBER;
  lc_err_msg     VARCHAR2(250);
  lc_error_loc   VARCHAR2(2000) := NULL;
  lc_error_count NUMBER         :=0;
  lc_user_conc_prog_name fnd_concurrent_programs_tl.user_concurrent_program_name%type;
BEGIN
  ln_org_id := fnd_profile.value('ORG_ID');
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
  BEGIN
    SELECT concurrent_program_name
    INTO lc_user_conc_prog_name
    FROM fnd_concurrent_programs f
    WHERE concurrent_program_id=fnd_global.conc_program_id;
  EXCEPTION
  WHEN OTHERS THEN
    lc_user_conc_prog_name:=NULL;
    fnd_file.put_line(fnd_file.log,'Program name not found ');
  END;
  fnd_file.put_line(fnd_file.log, 'Parameters');
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  fnd_file.put_line(fnd_file.log, '           Started Running : ' || lc_user_conc_prog_name);
  fnd_file.put_line(fnd_file.log, '            Checkrun Id : ' || TO_CHAR( p_checkrun_id));
  fnd_file.put_line(fnd_file.log, '          Template Name : ' || p_template_name);
  fnd_file.put_line(fnd_file.log, '           Payment Date : ' || TO_CHAR( p_payment_date));
  fnd_file.put_line(fnd_file.log, '       Pay Through Date : ' || TO_CHAR( p_pay_thru_date));
  fnd_file.put_line(fnd_file.log, '          Pay From Date : ' || TO_CHAR( p_pay_from_date));
  fnd_file.put_line(fnd_file.log, '------------------------------------------') ;
  v_request_id  :=fnd_request.submit_request( 'SQLAP' ,'APXPBASL' , 'Payment Process Request Program' ,NULL ,false ,p_checkrun_id ,v_template_id ,p_payment_date ,p_pay_thru_date ,p_pay_from_date );
  IF v_request_id>0 THEN
    COMMIT;
    dbms_output.put_line('Payment Process Request Program Request id : '|| TO_CHAR(v_request_id));
    fnd_file.put_line(fnd_file.log, 'Payment Process Request Program Request id : '|| TO_CHAR(v_request_id));
    IF upper(lc_user_conc_prog_name)=upper('XXAPCHECKPROC') THEN-- START DEFECT
      -- 31288
      wait_for_child(fnd_global.conc_request_id);
      BEGIN
        SELECT COUNT(NVL(status_code,'N/A'))
        INTO lc_error_count
        FROM fnd_concurrent_requests fcr1
        WHERE status_code                  ='E'
          START WITH fcr1.request_id       = v_request_id
          CONNECT BY prior fcr1.request_id = fcr1.parent_request_id;
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_count:=0;
      END;
      IF lc_error_count >0 THEN
        p_errbuf       :='One or more child programs completed in error.';
        p_retcode      :=2;
      END IF;
    END IF;--- END DEFECT 31288
  ELSE
    fnd_file.put_line(fnd_file.log, 'Error submitting request for Payment Process Request Program');
    lc_error_loc := 'Error submitting Payment Process Request Program for : '|| p_template_name;
    lc_err_msg   := 'Error submitting Payment Process Request Program for : '|| p_template_name;
    fnd_file.put_line(fnd_file.log, lc_err_msg);
    xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' , p_program_name => 'SUBMIT_PAYMENT_PROCESS' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_err_msg , p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'Payment Batch Automation');
    COMMIT;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'When others in submit_payment_process : '|| sqlerrm);
  dbms_output.put_line('When others in submit_payment_process : '||sqlerrm);
END submit_payment_process;

PROCEDURE ap_tdm_rtv_format(
    x_ret_code OUT NUMBER )
as

  CURSOR lcu_rtv_tdm_format
  is
    select distinct request_id 
 ---     payment_batch ,
  --    checkrun_id
    FROM xx_ap_confirmed_payment_batch xacpb
    WHERE xacpb.rtv = 'F';
  --**********************
  ----- Parameters--------
  --**********************
  ln_conc_request_id NUMBER := 0;
  lb_print_option    BOOLEAN;
  lc_error_loc       VARCHAR2(4000) := NULL;
  lc_error_debug     VARCHAR2(4000) := NULL;
  ln_rtv_app_char    NUMBER;
  ln_chb_app_char    NUMBER;
begin
 -- BEGIN
    SELECT xftv.target_value5
    INTO ln_rtv_app_char
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id                   = xftv.translate_id
    AND xftd.translation_name                 = 'APDM_ADDRESS_DTLS'
    AND upper(SUBSTR(xftv.source_value1,1,3)) = 'RTV'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
    FOR lcr_rtv_tdm_format IN lcu_rtv_tdm_format
    LOOP
      lc_error_loc       := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM';
      lc_error_debug     := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM for the Request ID: '  ||lcr_rtv_tdm_format.request_id;
      ln_conc_request_id := fnd_request.submit_request( 'xxfin' , 'XXAPFORMATAPDM' ,NULL ,NULL ,false ,'RTV' ,ln_rtv_app_char ,lcr_rtv_tdm_format.request_id );
      COMMIT;
      lc_error_loc   := 'Updating the custom table ';
      lc_error_debug := 'Updating the custom table to Y for the Request ID: '|| lcr_rtv_tdm_format.request_id;
      UPDATE xx_ap_confirmed_payment_batch
      set rtv             = 'Y'
      WHERE request_id  = lcr_rtv_tdm_format.request_id
      AND org_id          = fnd_profile.value ('ORG_ID');
      COMMIT;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm) ;
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
    x_ret_code := 2;
  end ap_tdm_rtv_format;
-- The below procedure is added for CR 542
-- +===========================================================================
-- ========+
-- |                  Office Depot - Project Simplify
-- |
-- |                       WIPRO Technologies
-- |
-- +===========================================================================
-- ========+
-- | Name        : OD: AP Format APDM Report for TDM
-- |
-- | Description :  To Format the RTV And Chargeback for TDM file Format
-- |
-- |
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version   Date          Author              Remarks
-- |
-- |=======   ==========   =============        ===============================
-- ========|
-- |1.0       06-Jul-10    Priyanka Nagesh      Initial Version - R1.4
-- |
-- |                                            CR 542  Defect# 3327
-- |
-- +===========================================================================
-- ========+
PROCEDURE ap_tdm_format(
    x_ret_code OUT NUMBER )
AS
 --Commented below for RTV report, since new proceduer is defined for RTV report  - ap_tdm_rtv_format , Ragni Gupta 24-Apr-18
  /*CURSOR lcu_rtv_tdm_format
  IS
    SELECT request_id ,
      payment_batch ,
      checkrun_id
    FROM xx_ap_confirmed_payment_batch xacpb
    WHERE xacpb.rtv = 'F';*/
  CURSOR lcu_chb_tdm_format
  IS
    SELECT chb_request_id ,
      payment_batch ,
      checkrun_id
    FROM xx_ap_confirmed_payment_batch xacpb
    WHERE xacpb.chargeback = 'F';
  --**********************
  ----- Parameters--------
  --**********************
  ln_conc_request_id NUMBER := 0;
  lb_print_option    BOOLEAN;
  lc_error_loc       VARCHAR2(4000) := NULL;
  lc_error_debug     VARCHAR2(4000) := NULL;
  ln_rtv_app_char    NUMBER;
  ln_chb_app_char    NUMBER;
BEGIN
 /* BEGIN
    SELECT xftv.target_value5
    INTO ln_rtv_app_char
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id                   = xftv.translate_id
    AND xftd.translation_name                 = 'APDM_ADDRESS_DTLS'
    AND upper(SUBSTR(xftv.source_value1,1,3)) = 'RTV'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
    FOR lcr_rtv_tdm_format IN lcu_rtv_tdm_format
    LOOP
      lc_error_loc       := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM';
      lc_error_debug     := 'Submiting the OD: AP Format APDM Report for TDM - for RTV to TDM for the Payment Batch : ' ||lcr_rtv_tdm_format.payment_batch||' and Payment Batch ID : '|| lcr_rtv_tdm_format.checkrun_id;
      ln_conc_request_id := fnd_request.submit_request( 'xxfin' , 'XXAPFORMATAPDM' ,NULL ,NULL ,false --changed to false for Defect 37797
      ,'RTV' ,ln_rtv_app_char ,lcr_rtv_tdm_format.request_id );
      COMMIT;
      lc_error_loc   := 'Updating the custom table ';
      lc_error_debug := 'Updating the custom table to Y for the Payment Batch: '|| lcr_rtv_tdm_format.payment_batch;
      UPDATE xx_ap_confirmed_payment_batch
      SET rtv             = 'Y'
      WHERE payment_batch = lcr_rtv_tdm_format.payment_batch
      AND org_id          = fnd_profile.value ('ORG_ID');
      COMMIT;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm) ;
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
    x_ret_code := 2;
  END;*/
  BEGIN
    --*************************************************************************
    -- ******
    -- Selecting the number of characters to be appended to have fixed width
    -- contents
    --*************************************************************************
    -- ******
    SELECT xftv.target_value5
    INTO ln_chb_app_char
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id                   = xftv.translate_id
    AND xftd.translation_name                 = 'APDM_ADDRESS_DTLS'
    AND upper(SUBSTR(xftv.source_value1,1,3)) = 'CHA'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
    FOR lcr_chb_tdm_format IN lcu_chb_tdm_format
    LOOP
      lc_error_loc       := 'Submiting the OD: AP Format APDM Report for TDM - for CHARGEBACK to TDM' ;
      lc_error_debug     := 'Submiting the OD: AP Format APDM Report for TDM - for CHARGEBACK to TDM for the Payment Batch : ' ||lcr_chb_tdm_format.payment_batch||' and Payment Batch ID : '|| lcr_chb_tdm_format.checkrun_id;
      ln_conc_request_id := fnd_request.submit_request( 'xxfin' , 'XXAPFORMATAPDM' ,NULL ,NULL ,false --changed to false for Defect 37797
      ,'CHARGEBACK' ,ln_chb_app_char ,lcr_chb_tdm_format.chb_request_id );
      COMMIT;
      lc_error_loc   := 'Updating the custom table ';
      lc_error_debug := 'Updating the custom table  to Y for the Payment Batch: '|| lcr_chb_tdm_format.payment_batch;
      UPDATE xx_ap_confirmed_payment_batch
      SET chargeback      = 'Y'
      WHERE payment_batch = lcr_chb_tdm_format.payment_batch
      AND org_id          = fnd_profile.value ('ORG_ID');
      COMMIT;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm) ;
    fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
    x_ret_code := 2;
  END;
END ap_tdm_format;
-- +===========================================================================
-- ========+
-- |                  Office Depot - Project Simplify
-- |
-- |                       WIPRO Technologies
-- |
-- +===========================================================================
-- ========+
-- | Name        : OD: AP APDM Reports
-- |
-- | Description : Submit RTV and Chagrgeback APDM report.
-- |
-- |
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version   Date          Author              Remarks
-- |
-- |=======   ==========   =============        ===============================
-- ========|
-- |1.0       29-Sep-09    Gokila Tamilselvam   Initial Version
-- |
-- |                                            Defect# 1431 R1.1
-- |
-- |1.1       06-Jul-10    Priyanka Nagesh      Modified For R1.4 CR 542 Defect
-- 3327   |
-- |1.2       12-Aug-13    Paddy Sanjeevi       Modified for R12
-- |1.3       19-Dec-17    Digamber Somavanshi  Commented all part for RTV, defined separate procedure for RTV
-- +===========================================================================
-- ========+
PROCEDURE submit_apdm_reports(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER )
AS
-- Separate program defined Submit_rtv_reports, asa part of Trade Payables Project 
  /* Modified CURSOR c_rtv_APDM and c_chargeback_APDM for R12
  CURSOR c_rtv_APDM
  IS
  SELECT  DISTINCT AISCA.checkrun_id
  ,AISCA.checkrun_name
  FROM    xx_ap_confirmed_payment_batch        XACPB
  ,ap_inv_selection_criteria_all             AISCA
  ,ap_checks                                 ACA
  ,ap_invoices                               AIA
  ,xx_fin_translatedefinition                XFTD
  ,xx_fin_translatevalues                    XFTV
  ,ap_invoice_payments                       AIPA
  WHERE   AISCA.checkrun_name                     = XACPB.payment_batch
  AND     XACPB.RTV                                 IS NULL
  AND     XACPB.ORG_ID                            = FND_PROFILE.VALUE ('ORG_ID'
  )
  AND     AIA.invoice_type_lookup_code            = 'CREDIT'
  AND     XFTV.target_value1                      = AIA.SOURCE
  AND     XFTD.translate_id                       = XFTV.translate_id
  AND     XFTD.translation_name                   = 'AP_INVOICE_SOURCE'
  AND     ACA.checkrun_id                         = AISCA.checkrun_id
  AND     AISCA.status                            = 'CONFIRMED'
  AND     AIPA.check_id                           = ACA.check_id
  AND     AIPA.invoice_id                         = AIA.invoice_id
  AND     AIPA.reversal_inv_pmt_id                  IS NULL
  AND     AIA.invoice_num                           LIKE 'RTV%'
  AND     AIA.SOURCE                                LIKE '%RTV%'
  AND     AIA.voucher_num                           IS NOT NULL;
  CURSOR  c_chargeback_APDM
  IS
  SELECT  DISTINCT AISCA.checkrun_id
  ,AISCA.checkrun_name
  FROM    xx_ap_confirmed_payment_batch        XACPB
  ,ap_inv_selection_criteria_all             AISCA
  ,ap_checks                                 ACA
  ,ap_invoices                               AIA
  ,fnd_lookup_values_vl                      FLV
  ,ap_invoice_payments                       AIPA
  WHERE   AISCA.checkrun_name                     = XACPB.payment_batch
  AND     XACPB.chargeback                          IS NULL
  AND     XACPB.ORG_ID                            = FND_PROFILE.VALUE ('ORG_ID'
  )
  AND     ACA.checkrun_id                         = AISCA.checkrun_id
  AND     AISCA.status                            = 'CONFIRMED'
  AND     AIPA.check_id                           = ACA.check_id
  AND     AIA.attribute12                         = 'Y'
  AND     AIA.invoice_type_lookup_code            = 'STANDARD'
  AND     AIA.voucher_num                           IS NOT NULL
  AND     AIA.pay_group_lookup_code               = FLV.lookup_code
  AND     FLV.lookup_type                         = 'APCHARGEBACK_PAYGROUP'
  AND     TRUNC(NVL(FLV.end_date_active
  ,SYSDATE+1))                    > TRUNC(SYSDATE)
  AND     AIPA.invoice_id                         = AIA.invoice_id;
  */
  -- start Separate program defined Submit_rtv_reports
  /*CURSOR c_rtv_APDM_r12  IS
  SELECT  DISTINCT aisc.checkrun_name,AISC.checkrun_id,aca.org_id
  FROM
  xx_fin_translatedefinition                XFTD
  ,xx_fin_translatevalues                    XFTV
  ,ap_invoices_all aia
  ,ap_invoice_payments_all aipa
  ,iby_pay_instructions_all ipia
  ,ap_checks_all aca
  ,ap_inv_selection_criteria_all aisc
  WHERE aisc.template_id IN (SELECT c.template_id
  FROM ap_payment_templates c
  ,fnd_flex_values b
  ,fnd_flex_value_sets a
  WHERE a.flex_value_set_name='XX_AP_RTV_TEMPLATES'
  AND b.flex_value_set_id=a.flex_value_set_id
  AND b.enabled_flag='Y'
  AND c.template_name=b.flex_value)
  AND aisc.creation_date>SYSDATE-30
  AND aca.checkrun_id=aisc.checkrun_id
  AND aca.org_id=FND_PROFILE.VALUE ('ORG_ID')
  AND ipia.payment_instruction_id=aca.payment_instruction_id
  AND ipia.payment_instruction_status IN ('FORMATTED_ELECTRONIC','PRINTED')
  AND aipa.check_id= aca.check_id
  AND aipa.reversal_inv_pmt_id IS NULL
  AND aia.invoice_id=aipa.invoice_id
  AND aia.invoice_type_lookup_code='CREDIT'
  AND aia.voucher_num IS NOT NULL
  AND AIA.invoice_num||''                       LIKE 'RTV%'
  AND AIA.SOURCE                                LIKE '%RTV%'
  AND XFTV.target_value1                      = AIA.SOURCE
  AND XFTD.translate_id                       = XFTV.translate_id
  AND XFTD.translation_name                   = 'AP_INVOICE_SOURCE'
  AND EXISTS (SELECT 'X'
  FROM  iby_applicable_pmt_profs pprof
  ,iby_payment_methods_vl pm
  ,iby_acct_pmt_profiles_b c
  WHERE c.payment_profile_id=ipia.payment_profile_id
  AND c.inactive_date IS NULL
  AND pprof.system_profile_code=c.system_profile_code
  AND pprof.applicable_type_code = 'PAYMENT_METHOD'
  AND pm.payment_method_code=pprof.applicable_value_to
  AND pm.payment_method_code in ('EFT','CHECK')
  )
  AND NOT EXISTS (SELECT 'x'
  FROM xx_ap_confirmed_payment_batch
  WHERE payment_batch=aisc.checkrun_name
  AND rtv IN ('F','Y')  -- Defect 28104
  AND checkrun_id=aisc.checkrun_id
  );
  */
  -- End Separate program defined Submit_rtv_reports
  CURSOR c_chargeback_apdm
  IS
    SELECT DISTINCT aisc.checkrun_name,
      aisc.checkrun_id,
      aca.org_id
    FROM fnd_lookup_values_vl flv ,
      ap_invoices_all aia ,
      ap_invoice_payments_all aipa ,
      iby_pay_instructions_all ipia ,
      ap_checks_all aca ,
      ap_inv_selection_criteria_all aisc
    WHERE aisc.template_id IN
      (SELECT c.template_id
      FROM ap_payment_templates c ,
        fnd_flex_values b ,
        fnd_flex_value_sets a
      WHERE a.flex_value_set_name ='XX_AP_RTV_TEMPLATES'
      AND b.flex_value_set_id     =a.flex_value_set_id
      AND b.enabled_flag          ='Y'
      AND c.template_name         =b.flex_value
      )
  AND aisc.creation_date                            >sysdate-30
  AND aca.checkrun_id                               =aisc.checkrun_id
  AND aca.org_id                                    =fnd_profile.value ('ORG_ID')
  AND ipia.payment_instruction_id                   =aca.payment_instruction_id
  AND ipia.payment_instruction_status              IN ('FORMATTED_ELECTRONIC','PRINTED')
  AND aipa.check_id                                 = aca.check_id
  AND aia.invoice_id                                =aipa.invoice_id
 -- AND aia.attribute12                               ='Y'
  AND (aia.attribute12                               ='Y' OR aia.invoice_num like 'DSV%')
  AND aia.invoice_type_lookup_code                  ='STANDARD'
  AND NVL(aia.voucher_num, aia.doc_sequence_value) IS NOT NULL --Added for V1.9
    --AND aia.voucher_num                          IS NOT NULL
  AND aia.pay_group_lookup_code                 = flv.lookup_code
  AND flv.lookup_type                           = 'APCHARGEBACK_PAYGROUP'
  AND TRUNC(NVL(flv.end_date_active,sysdate+1)) > TRUNC(sysdate)
  AND EXISTS
    (SELECT 'X'
    FROM iby_applicable_pmt_profs pprof ,
      iby_payment_methods_vl pm ,
      iby_acct_pmt_profiles_b c
    WHERE c.payment_profile_id     =ipia.payment_profile_id
    AND c.inactive_date           IS NULL
    AND pprof.system_profile_code  =c.system_profile_code
    AND pprof.applicable_type_code = 'PAYMENT_METHOD'
    AND pm.payment_method_code     =pprof.applicable_value_to
    AND pm.payment_method_code    IN ('EFT','CHECK')
    )
  AND NOT EXISTS
    (SELECT 'x'
    FROM xx_ap_confirmed_payment_batch
    WHERE payment_batch =aisc.checkrun_name
    AND chargeback     IN ('F','Y') -- Defect 28104
    AND checkrun_id     =aisc.checkrun_id
    );
  --------Parameters---------
  ln_conc_request_id   NUMBER := 0;
  lb_print_option      BOOLEAN;
  lc_error_loc         VARCHAR2(4000) := NULL;
  lc_error_debug       VARCHAR2(4000) := NULL;
  lc_req_data          VARCHAR2(100)  := NULL;
  lc_rtv_error_status  VARCHAR2(1)    := 'N';
  lc_chbk_error_status VARCHAR2(1)    := 'N';
  ln_org_id            NUMBER;
BEGIN
  --Remove PAUSE for Defect 37797
  --lc_req_data                                       :=
  -- fnd_conc_global.request_data;               -- Added for CR 542 Defect
  -- 3327
  x_ret_code := 0;
  ln_org_id  :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  -- Added for CR 542 Defect 3327
  --IF lc_req_data IS NULL THEN
  -- Start Separate program defined Submit_rtv_reports
  /*
  FOR lcu_rtv_APDM IN c_rtv_APDM_r12
  LOOP
  fnd_file.PUT_LINE(fnd_file.LOG, 'Checkrun of RTV :' ||
  lcu_rtv_APDM.checkrun_name);
  lc_error_loc        := 'Setting the Printer for RTV APDM Report';
  lc_error_debug      := 'Setting the Printer for the Payment Batch : '||
  lcu_rtv_APDM.checkrun_name;
  lb_print_option     := fnd_request.set_print_options( printer   => 'XPTR'
  ,copies    => 1
  );
  lc_error_loc        := 'Submitting the RTV APDM Report';
  lc_error_debug      := 'Submiting the RTV APDM Report : '||
  lcu_rtv_APDM.checkrun_name||' and Payment Batch ID : '||
  lcu_rtv_APDM.checkrun_id;
  ln_conc_request_id  := fnd_request.submit_request   ( 'xxfin'
  ,'XXAPRTVAPDM'
  , NULL
  , NULL
  , FALSE --changed to false for Defect 37797
  , lcu_rtv_APDM.checkrun_id
  );
  COMMIT;
  fnd_file.PUT_LINE(fnd_file.LOG, 'RTV Report Request id :' ||TO_CHAR(
  ln_conc_request_id));
  --Defect 37797
  wait_and_submit_rtv(lcu_rtv_APDM.checkrun_id,ln_conc_request_id);
  --Defect 37797 End
  lc_error_loc        := 'Inserting into custom table for RTV Batch' ;
  lc_error_debug      := 'Inserting the custom table for the Payment Batch : '|
  |lcu_rtv_APDM.checkrun_name;
  --***************************************************************************
  *
  -- Inserting in the custom table with RTV to 'F' to indicate Formatting
  status
  --***************************************************************************
  *
  BEGIN
  INSERT
  INTO xx_ap_confirmed_payment_batch
  ( payment_batch
  ,rtv
  ,chargeback
  ,last_update_date
  ,last_updated_by
  ,creation_date
  ,created_by
  ,last_update_login
  ,request_id
  ,checkrun_id
  ,org_id
  ,chb_request_id
  )
  VALUES
  (
  lcu_rtv_APDM.checkrun_name
  ,'F'
  ,'N'
  ,SYSDATE
  ,fnd_global.user_id
  ,SYSDATE
  ,fnd_global.user_id
  ,fnd_global.user_id
  ,ln_conc_request_id
  ,lcu_rtv_APDM.checkrun_id
  ,lcu_rtv_APDM.org_id
  ,NULL
  );
  EXCEPTION
  WHEN others THEN
  lc_rtv_error_status:='Y';
  fnd_file.PUT_LINE(fnd_file.LOG,   lc_error_debug||' ,'||SQLERRM);
  xx_com_error_log_pub.log_error(    p_program_type => 'CONCURRENT PROGRAM'
  ,p_program_name => 'SUBMIT_APDM_REPORTS'
  ,p_program_id => fnd_global.conc_program_id
  ,p_module_name => 'AP'
  ,p_error_location => 'Error at ' || lc_error_loc
  ,p_error_message_count => 1
  ,p_error_message_code => 'E'
  ,p_error_message => lc_error_debug||' ,'||SQLERRM
  ,p_error_message_severity => 'Major'
  ,p_notify_flag => 'N'
  ,p_object_type => 'Payment RTV Batch');
  END;
  COMMIT;
  END LOOP;  */
  -- End Separate program defined Submit_rtv_reports
  /*  Commented for R12
  UPDATE xx_ap_confirmed_payment_batch
  SET--rtv                   = 'Y'
  --Commented for CR 542 Defect 3327
  rtv                   = 'F'
  --Added for CR 542 Defect 3327
  ,last_update_date      = SYSDATE
  ,last_updated_by       = FND_PROFILE.VALUE ('USER_ID')
  ,last_update_login     = FND_PROFILE.VALUE ('USER_ID')
  ,checkrun_id           = lcu_rtv_APDM.checkrun_id
  ,request_id            = ln_conc_request_id
  WHERE payment_batch         = lcu_rtv_APDM.checkrun_name
  AND org_id                  = FND_PROFILE.VALUE ('ORG_ID');
  COMMIT;
  END LOOP;
  lc_error_loc   := 'Updating the custom table rtv = N';
  lc_error_debug := '';
  UPDATE xx_ap_confirmed_payment_batch
  SET   rtv                   = 'N'
  ,last_update_date      = SYSDATE
  ,last_updated_by       = FND_PROFILE.VALUE ('USER_ID')
  ,last_update_login     = FND_PROFILE.VALUE ('USER_ID')
  ,request_id            = ln_conc_request_id
  WHERE  rtv                  IS NULL
  AND org_id                   = FND_PROFILE.VALUE ('ORG_ID');
  EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
  x_ret_code := 2;
  END;
  */
  FOR lcu_chargeback_apdm IN c_chargeback_apdm
  LOOP
    lc_error_loc       := 'Setting the Printer for ChargeBack APDM Report';
    lc_error_debug     := 'Setting the Printer for the Payment Batch : '|| lcu_chargeback_apdm.checkrun_name;
    lb_print_option    := fnd_request.set_print_options( printer => 'XPTR' ,copies => 1 );
    lc_error_loc       := 'Submitting the ChargeBack APDM Report';
    lc_error_debug     := 'Submitting the ChargeBack APDM Report : '|| lcu_chargeback_apdm.checkrun_name||' and Payment Batch ID : '|| lcu_chargeback_apdm.checkrun_id;
    ln_conc_request_id := fnd_request.submit_request ( 'xxfin' ,'XXAPCHBKAPDM' ,NULL ,NULL ,false --changed to false for Defect 37797
    ,lcu_chargeback_apdm.checkrun_id );
    COMMIT;
    --Defect 37797
    wait_and_submit_chargeback(lcu_chargeback_apdm.checkrun_id, ln_conc_request_id);
    ----Defect 37797 End
    lc_error_loc   := 'Inserting into custom table for Chargeback Batch' ;
    lc_error_debug := 'Inserting the custom table for the Payment Batch : '|| lcu_chargeback_apdm.checkrun_name;
    --*************************************************************************
    -- **********
    -- Inserting in the custom table with Chargeback to 'F' to indicate
    -- Formatting status
    --*************************************************************************
    -- **********
    BEGIN
      INSERT
      INTO xx_ap_confirmed_payment_batch
        (
          payment_batch ,
          rtv ,
          chargeback ,
          last_update_date ,
          last_updated_by ,
          creation_date ,
          created_by ,
          last_update_login ,
          request_id ,
          checkrun_id ,
          org_id ,
          chb_request_id
        )
        VALUES
        (
          lcu_chargeback_apdm.checkrun_name ,
          'N' ,
          'F' ,
          sysdate ,
          fnd_global.user_id ,
          sysdate ,
          fnd_global.user_id ,
          fnd_global.user_id ,
          NULL ,
          lcu_chargeback_apdm.checkrun_id ,
          lcu_chargeback_apdm.org_id ,
          ln_conc_request_id
        );
    EXCEPTION
    WHEN OTHERS THEN
      lc_chbk_error_status:='Y';
      fnd_file.put_line(fnd_file.log, lc_error_debug||' ,'||sqlerrm);
      xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' , p_program_name => 'SUBMIT_APDM_REPORTS' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_error_debug||' ,'|| sqlerrm ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' , p_object_type => 'Payment Chargeback Batch');
    END;
    COMMIT;
  END LOOP;
  /*  Commented for R12
  --***********************************************************
  -- Updating Chargeback to 'F' to indicate Formatting status
  --***********************************************************
  UPDATE xx_ap_confirmed_payment_batch
  SET --chargeback               = 'Y'
  --Commented for CR 542 Defect 3327
  chargeback               = 'F'
  --Added for CR 542 Defect 3327
  ,last_update_date         = SYSDATE
  ,last_updated_by          = FND_PROFILE.VALUE ('USER_ID')
  ,last_update_login        = FND_PROFILE.VALUE ('USER_ID')
  ,checkrun_id              = lcu_chargeback_APDM.checkrun_id
  ,chb_request_id           = ln_conc_request_id
  WHERE payment_batch            = lcu_chargeback_APDM.checkrun_name
  AND org_id                     = FND_PROFILE.VALUE ('ORG_ID');
  COMMIT;
  END LOOP;
  lc_error_loc   := 'Updating the custom table chargeback = N';
  lc_error_debug := '';
  UPDATE xx_ap_confirmed_payment_batch
  SET   chargeback               = 'N'
  ,last_update_date         = SYSDATE
  ,last_updated_by          = FND_PROFILE.VALUE ('USER_ID')
  ,last_update_login        = FND_PROFILE.VALUE ('USER_ID')
  ,chb_request_id           = ln_conc_request_id
  WHERE  chargeback                IS NULL
  AND    org_id                  = FND_PROFILE.VALUE ('ORG_ID');
  EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_loc || ' - '||SQLERRM);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in '||lc_error_debug);
  x_ret_code := 2;
  END;
  */
  --commented for Defect 37797
  /*IF ln_conc_request_id  <>  0   THEN
  FND_CONC_GLOBAL.SET_REQ_GLOBALS( conc_status  => 'PAUSED'
  ,request_data => 'Restarting'
  );
  END IF;*/
  IF lc_chbk_error_status='Y' OR lc_rtv_error_status='Y' THEN
    fnd_file.put_line(fnd_file.log, 'Error while inserting in the custom table for RTV Chbk Batch');
    x_ret_code := 2;
  END IF;
  --*****************************************************************
  --            Code added for CR 542 Defect #3327 starts
  --*****************************************************************
  --commented for Defect 37797
  --ELSIF lc_req_data = 'Restarting' THEN
  --***************************************************************************
  -- *****************************
  --   Calling the AP_TDM_FORMAT Procedure to submit the "OD: AP Format APDM
  -- Report for TDM" for Formatting
  -- **************************************************************************
  -- *****************************
  ap_tdm_format (x_ret_code);
  --commented for Defect 37797
  /*IF x_ret_code = 0 THEN
  FND_CONC_GLOBAL.SET_REQ_GLOBALS( conc_status  => 'PAUSED'
  ,request_data => 'Completed'
  );
  END IF;*/
  --*****************************************************************
  --            Code added for CR 542 Defect #3327 ends
  --*****************************************************************
  --END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
END submit_apdm_reports;
/*Below is the wrapper for consolidated RTV report, it does below steps:
1. This procedure sets printer to XPTR
2. Then call RTV report 
3. Copy the file to exporter location (wait_and_submit_cons_rtv)
4. Format the report in TDM (ap_tdm_rtv_format)*/
PROCEDURE submit_rtv_cons_reports
  (
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER
  )
AS
  --------Parameters---------
  ln_conc_request_id   NUMBER := 0;
  lb_print_option      BOOLEAN;
  lc_error_loc         VARCHAR2(4000) := NULL;
  lc_error_debug       VARCHAR2(4000) := NULL;
  lc_req_data          VARCHAR2(100)  := NULL;
  lc_rtv_error_status  VARCHAR2(1)    := 'N';
  lc_chbk_error_status VARCHAR2(1)    := 'N';
  ln_org_id            NUMBER;
BEGIN
  x_ret_code := 0;
  ln_org_id  :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, 'Start of RTV');
  lc_error_loc := 'Setting the Printer for RTV APDM Report';
  fnd_file.put_line(fnd_file.log, lc_error_loc);
  -- Set XPTR output
  lb_print_option := fnd_request.set_print_options( printer => 'XPTR' ,copies => 1 );
  fnd_file.put_line(fnd_file.log, 'Printer Option set for XPTR');
  lc_error_loc := 'Submitting the RTV APDM Report - XXAPRTVAPDM ';
  fnd_file.put_line(fnd_file.log, lc_error_loc);
  fnd_file.put_line(fnd_file.log, 'Calling RTV Report');
  -- **********************************************************************************************8
  -- Calling the XXAPRTVAPDM RTV Report Payment batch table will populated in Before Report
  -- Table : xx_ap_confirmed_payment_batch
  -- *********************************************************************************************
  ln_conc_request_id := fnd_request.submit_request ( 'xxfin' , 'XXAPRTVAPDM' , NULL , NULL , false , NULL );
  COMMIT;
  fnd_file.put_line(fnd_file.log, 'RTV Report Request id :' ||TO_CHAR( ln_conc_request_id));
  fnd_file.put_line(fnd_file.log, 'Wait and Submit for  Request id :' ||TO_CHAR( ln_conc_request_id));
  wait_and_submit_cons_rtv(ln_conc_request_id);
  fnd_file.put_line(fnd_file.log, 'Calling AP_TDM_FORMAT');
  -- **********************************************************************************************8
  -- Calling the AP_TDM_FORMAT Procedure to submit the "OD: AP Format APDM
  -- report for TDM" for Formatting
  -- *********************************************************************************************
  ap_tdm_rtv_format (x_ret_code);
  
  -- Purge Data from temp table
  
  DELETE FROM xx_ap_xxaprtvapdm_tmp WHERE request_id = ln_conc_request_id;
  commit;

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
END submit_rtv_cons_reports;

PROCEDURE submit_rtv_reports
  (
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER
  )
AS
  CURSOR c_rtv_apdm_r12
  IS
    SELECT ai.org_id,
      ai.vendor_site_id ,
      ai.invoice_num,
      TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
    FROM ap_invoices_all ai
    WHERE 1                 =1
    AND ai.last_update_date >=  sysdate-7 
    and ai.last_update_date >= XX_AP_IBY_PMNT_BATCH_PKG.CUTOFF_DATE_ELIGIBLE
  
      /*AND EXISTS --Commented after change for cutoff date
      (SELECT 1
      FROM ap_invoice_distributions_all aida
      where 1 =1
      AND aida.last_update_date > sysdate -7
      AND aida.invoice_id       = ai.invoice_id
      )*/
    AND ai.invoice_num LIKE 'RTV%'
    AND ai.org_id =fnd_profile.value ('ORG_ID')
      --AND DECODE(AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, ai.invoice_amount,ai.payment_status_flag,ai.invoice_type_lookup_code), 'NEVER APPROVED', 'Never Validated', 'NEEDS REAPPROVAL', 'Needs Revalidation' , 'CANCELLED', 'Cancelled', 'Validated') = 'Validated'
    AND NOT EXISTS
      (SELECT 'x'
      FROM ap_holds_all
      WHERE invoice_id         =ai.invoice_id
      AND release_lookup_code IS NULL
      )
  AND EXISTS
    (SELECT 'x'
    FROM xla_events xev,
      xla_transaction_entities xte
    WHERE xte.source_id_int_1=ai.invoice_id
    AND xte.application_id   = 200
    AND xte.entity_code      = 'AP_INVOICES'
    AND xev.entity_id        = xte.entity_id
    AND xev.event_type_code LIKE '%VALIDATED%'
    )
  AND ai.source IN
    (SELECT val.target_value1
    FROM xx_fin_translatedefinition def ,
      xx_fin_translatevalues val
    WHERE 1                  = 1
    AND def.translation_name = 'AP_INVOICE_SOURCE'
    AND def.translate_id     = val.translate_id
    AND val.target_value1 LIKE '%RTV%'
    )
  AND ( --AI.VOUCHER_NUM IS NOT NULL
    NVL(ai.voucher_num, ai.doc_sequence_value) IS NOT NULL
  OR EXISTS
    (SELECT 1
    FROM xx_ap_rtv_hdr_attr xarh,
      xx_ap_rtv_lines_attr xarl
    WHERE xarh.header_id    =xarl.header_id
    AND xarh.frequency_code = 'DY'
    AND xarh.invoice_num    = ai.invoice_num
    ))
  AND NOT EXISTS
    (SELECT 'x'
    FROM xx_ap_confirmed_payment_batch
    WHERE payment_batch =ai.invoice_num
    AND rtv            IN ('F','Y') -- Defect 28104
    AND checkrun_id     =ai.vendor_site_id
    )
  ORDER BY ai.vendor_id,
    ai.invoice_num;
  --Commented by Ragni, performance tuning - 01-FEB-18
  /*SELECT ai.org_id,
  ai.vendor_site_id ,
  ai.invoice_num,
  TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
  FROM ap_invoices_all ai
  WHERE 1=1
  AND EXISTS
  (SELECT 1
  FROM ap_invoice_distributions_all aida,
  ap_invoice_lines_all aila
  WHERE 1 =1
  --AND aida.Accounting_date > sysdate -30
  AND aida.last_update_date > sysdate -30
  AND aida.invoice_id       = ai.invoice_id
  AND aila.invoice_id       = aida.invoice_id
  AND aila.line_number      = aida.invoice_line_number
  )
  AND SUBSTR(AI.invoice_num,1,3) LIKE 'RTV'
  AND AI.org_id                                                                                                                                                                                                                                                    =FND_PROFILE.VALUE ('ORG_ID')
  AND DECODE(AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, ai.invoice_amount,ai.payment_status_flag,ai.invoice_type_lookup_code), 'NEVER APPROVED', 'Never Validated', 'NEEDS REAPPROVAL', 'Needs Revalidation' , 'CANCELLED', 'Cancelled', 'Validated') = 'Validated'
  AND AI.SOURCE                                                                                                                                                                                                                                                   IN
  (SELECT VAL.target_value1
  FROM xx_fin_translatedefinition DEF ,
  xx_fin_translatevalues VAL
  WHERE 1                  = 1
  AND DEF.translation_name = 'AP_INVOICE_SOURCE'
  AND DEF.translate_id     = VAL.translate_id
  AND VAL.target_value1 LIKE '%RTV%'
  )
  AND ( AI.VOUCHER_NUM IS NOT NULL
  --NVL(AI.VOUCHER_NUM, AI.doc_sequence_value) IS NOT NULL
  OR EXISTS
  (SELECT 1
  FROM XX_AP_RTV_HDR_ATTR xarh,
  XX_AP_RTV_LINES_ATTR xarl
  WHERE xarh.header_id    =xarl.header_id
  AND xarh.frequency_code = 'DY'
  AND XARH.INVOICE_NUM    = AI.invoice_num
  ))
  AND NOT EXISTS
  (SELECT 'x'
  FROM xx_ap_confirmed_payment_batch
  WHERE payment_batch =ai.invoice_num
  AND rtv            IN ('F','Y') -- Defect 28104
  AND checkrun_id     =ai.vendor_site_id
  )
  ORDER BY ai.vendor_id,
  ai.invoice_num;*/
  CURSOR c_pay_batch (p_request_id VARCHAR2)
  IS
    SELECT DISTINCT checkrun_id vendor_site_id,
      attribute1 request_id
    FROM xx_ap_confirmed_payment_batch
    WHERE 1       =1
    AND rtv      IN ('F','Y')
    AND attribute1= p_request_id;
  --------Parameters---------
  ln_conc_request_id   NUMBER := 0;
  lb_print_option      BOOLEAN;
  lc_error_loc         VARCHAR2(4000) := NULL;
  lc_error_debug       VARCHAR2(4000) := NULL;
  lc_req_data          VARCHAR2(100)  := NULL;
  lc_rtv_error_status  VARCHAR2(1)    := 'N';
  lc_chbk_error_status VARCHAR2(1)    := 'N';
  ln_org_id            NUMBER;
  ---LN_VENDOR_ID         number       := 0;
  l_batch_name VARCHAR2(50) := fnd_global.conc_request_id ;
BEGIN
  --Remove PAUSE for Defect 37797
  --lc_req_data                                       :=
  -- fnd_conc_global.request_data;               -- Added for CR 542 Defect
  -- 3327
  xla_security_pkg.set_security_context(602);
  x_ret_code := 0;
  ln_org_id  :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, 'Batch Name :'||TO_CHAR(l_batch_name));
  -- Added for CR 542 Defect 3327
  --IF lc_req_data IS NULL THEN
  FOR lcu_rtv_apdm IN c_rtv_apdm_r12
  LOOP
    lc_error_loc   := 'Inserting into custom table for RTV Batch' ;
    lc_error_debug := 'Inserting the custom table for the Invoice Number : '|| lcu_rtv_apdm.invoice_num;
    --*************************************************************************
    -- ***
    -- Inserting in the custom table with RTV to 'F' to indicate Formatting
    -- status
    --*************************************************************************
    -- ***
    BEGIN
      INSERT
      INTO xx_ap_confirmed_payment_batch
        (
          payment_batch ,
          rtv ,
          chargeback ,
          last_update_date ,
          last_updated_by ,
          creation_date ,
          created_by ,
          last_update_login ,
          request_id ,
          checkrun_id ,
          org_id ,
          chb_request_id,
          attribute1
        )
        VALUES
        (
          lcu_rtv_apdm.invoice_num ,
          'F' ,
          'N' ,
          sysdate ,
          fnd_global.user_id ,
          sysdate ,
          fnd_global.user_id ,
          fnd_global.user_id ,
          ln_conc_request_id ,
          lcu_rtv_apdm.vendor_site_id ,
          lcu_rtv_apdm.org_id ,
          NULL,
          l_batch_name
        );
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log, 'Error while inserting into xx_ap_confirmed_payment_batch '||' ,'||sqlerrm);
    END ;
  END LOOP;
  FOR i IN c_pay_batch
  (
    l_batch_name
  )
  LOOP
    BEGIN
      --- fnd_file.put_line(fnd_file.log, 'Checkrun of RTV :' || lcu_rtv_apdm.invoice_num);
      fnd_file.put_line(fnd_file.log, 'Submiting the RTV APDM Report with vendor id '|| i.vendor_site_id ) ;
      lc_error_loc    := 'Setting the Printer for RTV APDM Report';
      lc_error_debug  := 'Setting the Printer for the Payment Batch : ';
      lb_print_option := fnd_request.set_print_options( printer => 'XPTR' , copies => 1 );
      lc_error_loc    := 'Submitting the RTV APDM Report';
      lc_error_debug  := 'Submiting the RTV APDM Report with vendor id '|| i.vendor_site_id ;
      --- IF NVL(ln_vendor_id,0) <> lcu_rtv_APDM.vendor_site_id THEN
      ln_conc_request_id := fnd_request.submit_request ( 'xxfin' , 'XXAPRTVAPDM' , NULL , NULL , false --changed to false for Defect 37797
      , NULL, i.vendor_site_id , l_batch_name );
      UPDATE xx_ap_confirmed_payment_batch
      SET request_id    = ln_conc_request_id
      WHERE checkrun_id = i.vendor_site_id
        --AND payment_batch = lcu_rtv_APDM.Invoice_num
      AND attribute1 = l_batch_name ;
      COMMIT;
      fnd_file.put_line(fnd_file.log, 'RTV Report Request id :' ||TO_CHAR( ln_conc_request_id));
      fnd_file.put_line(fnd_file.log, 'lcu_rtv_APDM.vendor_site_id :' ||i.vendor_site_id);
      --Defect 37797
      wait_and_submit_rtv(i.vendor_site_id,ln_conc_request_id);
      --Defect 37797 End
      -- LN_VENDOR_ID := LCU_RTV_APDM.VENDOR_SITE_ID;
      --  FND_FILE.PUT_LINE(FND_FILE.log, 'LN_VENDOR_ID' ||LN_VENDOR_ID);
      /*   delete from XX_AP_XXAPRTVAPDM_TMP
      where REQUEST_ID = LN_CONC_REQUEST_ID;*/
      --- commit;
      -- END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lc_rtv_error_status:='Y';
      fnd_file.put_line(fnd_file.log, lc_error_debug||' ,'||sqlerrm);
      xx_com_error_log_pub.log_error( p_program_type => 'CONCURRENT PROGRAM' , p_program_name => 'SUBMIT_RTV_REPORTS' ,p_program_id => fnd_global.conc_program_id ,p_module_name => 'AP' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 , p_error_message_code => 'E' ,p_error_message => lc_error_debug||' ,'|| sqlerrm ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' , p_object_type => 'Payment RTV Batch');
    END;
    COMMIT;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
END submit_rtv_reports;
FUNCTION cutoff_date_eligible
  RETURN date
AS
 -- l_flag VARCHAR2(1);
 l_date date;
BEGIN
  BEGIN
    SELECT to_date(tv.target_value1,'DD-MON-YYYY')
    INTO l_date
    FROM xx_fin_translatevalues tv ,
      xx_fin_translatedefinition td
    WHERE td.translation_name = 'XXAP_GO_LIVE_DATE'
    AND tv.translate_id       = td.translate_id
    AND tv.enabled_flag       ='Y'
    AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
    AND source_value1 = '3MWTRADEPAYABLE';
   -- AND sysdate      >= to_date(tv.target_value1,'DD-MON-YYYY') ;
  EXCEPTION
  WHEN OTHERS THEN
    l_date := sysdate+1;
  END;
  RETURN l_date;
END cutoff_date_eligible;
END xx_ap_iby_pmnt_batch_pkg;
/

SHOW ERRORS;