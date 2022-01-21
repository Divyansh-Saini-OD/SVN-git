SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body XX_AP_SUBMIT_DESTROY_MERCH_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_SUBMIT_DESTROY_MERCH_PKG                     |
  -- | Description      :    Package for Submit request for Destroyed Merch Rep |
  -- | RICE ID          :    R7034                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      20-Feb-2018  Jitendra Atale      Initial
  --  |1.1      16-APR-2018  Priyam P            Code Commented for SMTP error NAIT-37610
  -- | 1.2      30-APR-2018 Priyam P             g_ret_code added to make the parent program complete in warning rather than error.
  -- | 1.3      10-May-2018  Ragni Gupta         Added run date and notify business in case email address is null
  -- | 1.4      28-May-2018  Ragni Gupta         Added "NOTIFY_VENDOR_SITE_EMAIL_NULL" to send email to business
--                                               for vendor site email is NULL
  -- +==========================================================================+
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
PROCEDURE wait_and_submit_dest(
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
  lc_email_id      VARCHAR2(100);
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
  g_instance       VARCHAR2(25);
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
    lc_rtv_file_name :='APDESTROY';
    SELECT xftv.target_value2,
      xftv.target_value3,
      xftv.target_value4
    INTO lc_email_subject,
      lc_email_content,
      lc_email_id
    FROM xx_fin_translatedefinition xftd ,
      xx_fin_translatevalues xftv
    WHERE xftd.translate_id   = xftv.translate_id
    AND xftd.translation_name = 'XX_AP_TRADE_PAY_EMAIL'
    AND xftv.source_value1    ='XXAPDSTROYMERCHREP'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    lc_rtv_file_name :='APDESTROY';
  END;
  BEGIN
    SELECT instance_name INTO G_INSTANCE FROM v$instance;
    -- IF G_INSTANCE = 'GSIPRDGB' THEN
    /*SELECT DECODE(G_INSTANCE,'GSIDEV02',lc_email_id, 'GSIPSTGB',lc_email_id,'GSIUATGB',lc_email_id,MIN(pvsa.email_address)) email,
    COUNT(ai.vendor_site_id)
    INTO v_email_list,
    ln_count
    FROM ap_invoices_all ai ,
    ap_suppliers pv ,
    ap_supplier_sites_all pvsa ,
    xx_fin_translatedefinition def ,
    xx_fin_translatevalues val
    WHERE 1                                         =1
    AND ai.vendor_site_id                           = p_checkrun_id --658023 --663083
    AND NVL(ai.voucher_num, ai.doc_sequence_value) IS NOT NULL
    AND val.target_value1                           =ai.source
    AND def.translate_id                            = val.translate_id
    AND def.translation_name                        = 'AP_INVOICE_SOURCE'
    AND ai.vendor_site_id                           = pvsa.vendor_site_id
    AND pv.vendor_id                                = pvsa.vendor_id;*/
    SELECT DECODE(G_INSTANCE,'GSIDEV02',lc_email_id, 'GSIPSTGB',lc_email_id,'GSIUATGB',lc_email_id,MIN(pvsa.email_address)) email,
      COUNT(pvsa.vendor_site_id)
    INTO v_email_list,
      ln_count
    FROM --ap_invoices_all ai ,
      --ap_suppliers pv ,
      ap_supplier_sites_all pvsa --,
    WHERE 1                 =1
    AND pvsa.vendor_site_id = p_checkrun_id ;--658023 --663083
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
  IF v_email_list IS NULL THEN
    fnd_file.put_line(fnd_file.log, 'No Email list found for vendor_site_id '|| p_checkrun_id );
    G_RET_CODE:=1;
  ELSE
    IF ln_count > 0 THEN
      fnd_file.put_line(fnd_file.log, 'send Email' || v_file_name );
      v_file_name :='o'||TO_CHAR(p_request_id)||'.out';
      v_sfile_name:=lc_rtv_file_name||'_'||TO_CHAR(sysdate,'MMDDYYHH24MI')||'.TXT';
      v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
      fnd_file.put_line(fnd_file.log, 'send Email v_dfile_name' || v_dfile_name ) ;
      v_file_name    :='$APPLCSF/$APPLOUT/'||v_file_name;
      vc_request_id  := fnd_request.submit_request('XXFIN','XXCOMFILCOPY', 'OD: Common File Copy',NULL,false, v_file_name,v_dfile_name,NULL,NULL, NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL ,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL ,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      IF vc_request_id>0 THEN
        COMMIT;
      END IF;
      fnd_file.put_line(fnd_file.log, 'After OD: Common File Copy' );
      IF (fnd_concurrent.wait_for_request(vc_request_id,1,60000,v_cphase, v_cstatus,v_cdphase,v_cdstatus,x_cdummy)) THEN
        IF v_cdphase = 'COMPLETE' AND v_cphase = 'NORMAL' THEN -- child
          fnd_file.put_line(fnd_file.log, 'After OD: Destroyed Merchandise Summary Report' );
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
    END IF;
  END IF;
  --DELETE FROM xx_ap_xxaprtvapdm_tmp WHERE request_id = p_request_id;
  -- COMMIT;
END wait_and_submit_dest;
PROCEDURE SUBMIT_DESTROY_MERCH_REPORT(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE       IN VARCHAR2,
    P_END_DATE         IN VARCHAR2,
    P_FREQUENCY        IN VARCHAR2,
    P_VENDOR_SITE_CODE IN VARCHAR2,
    P_RUN_DATE         IN VARCHAR2)
AS
  CURSOR c_dstroy_merch (lv_start_date IN VARCHAR2, lv_end_date IN VARCHAR2)
  IS
    SELECT DISTINCT aia.org_id,
      aia.vendor_site_id
      --   aia.invoice_num,
      --   TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
    FROM --ap_supplier_sites_all aspa,
      (SELECT ltrim(NVL(attribute9,(NVL(attribute7,NVL(vendor_site_code_alt,vendor_site_id)))),'0') vendor_num,
        vendor_site_id,
        vendor_id,
        vendor_site_code,
        address_line1 ,
        address_line2 ,
        address_line3 ,
        city ,
        state ,
        zip ,
        pay_site_flag
      FROM ap_supplier_sites_all
      WHERE NVL(inactive_date,sysdate) >= TRUNC(sysdate)
      ) aspa,
    ap_suppliers asp ,
    xx_ap_rtv_hdr_attr xarh ,
    ap_invoices_all aia
  WHERE xarh.record_status   !='N'
  AND xarh.return_description ='DESTROY-OPTION 73'
  AND xarh.invoice_num LIKE 'RTV730%'
  AND xarh.invoice_num    = aia.invoice_num
  AND asp.vendor_id       = aia.vendor_id
  AND aspa.vendor_site_id = aia.vendor_site_id
  AND aspa.pay_site_flag  = 'Y'
    --AND NVL(aspa.inactive_date,sysdate)                                                                          >= TRUNC(sysdate)
  AND aspa.vendor_num = ltrim(xarh.vendor_num,'0')
    --   AND (aia.creation_date BETWEEN to_date( fnd_date.canonical_to_date(TO_CHAR(lv_start_date)), 'DD-MON-YY HH24:MI:SS') AND to_date(fnd_date.canonical_to_date(TO_CHAR(lv_end_date)), 'DD-MON-YY HH24:MI:SS'))
  AND (aia.creation_date BETWEEN fnd_date.canonical_to_date(lv_start_date) AND fnd_date.canonical_to_date(lv_end_date))
  AND xarh.frequency_code   = NVL(DECODE(P_FREQUENCY,'Quarterly', 'QY','Monthly','MY','Weekly','WY'),xarh.frequency_code)
  AND aspa.vendor_site_code = NVL(P_VENDOR_SITE_CODE,aspa.vendor_site_code);
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
  l_batch_name  VARCHAR2(50) := fnd_global.conc_request_id ;
  lb_result     BOOLEAN;
  lc_phase      VARCHAR2 (100);
  lc_status     VARCHAR2 (100);
  lc_dev_phase  VARCHAR2 (100) := NULL;
  lc_dev_status VARCHAR2 (100);
  lc_message    VARCHAR2 (100);
  i             NUMBER;
  rec           NUMBER :=1;
  --  lv_start_date DATE;
  --  lv_end_date   DATE;
  V_START_DATE    VARCHAR2(50);
  V_END_DATE      VARCHAR2(50);
  V_START_DT      DATE;
  V_END_DT        DATE;
  lv_qtr          VARCHAR2(20);
  lv_month        VARCHAR2(20);
  ln_month        NUMBER;
  l_date          DATE;
  ld_date         DATE;
  lv_strt_day_sun VARCHAR2(10);
  lv_year         NUMBER;
  lv_wk_day       VARCHAR2(100);
  lv_supplier_name ap_suppliers.vendor_name%TYPE;
  lv_supplier_site ap_supplier_sites_all.vendor_Site_Code%TYPE;
  lv_supplier_num ap_suppliers.segment1%TYPE;
  lv_email    VARCHAR2(1000);
  lv_instance VARCHAR2(50);
TYPE l_email_null_rec_ctt
IS
  TABLE OF XX_AP_SUBMIT_DESTROY_MERCH_PKG.email_null_rec INDEX BY PLS_INTEGER;
  -- L_UNMATCH_DETAIL_REC UNMATCH_DETAIL_CTT;
  l_email_null_rec_tb l_email_null_rec_ctt; --XX_AP_SUBMIT_DESTROY_MERCH_PKG.email_null_rec_tb;
  lc_email_subject VARCHAR2(250);
  lc_email_content VARCHAR2(4000);
  conn utl_smtp.connection;
  v_email_list VARCHAR2(500);
  r            NUMBER:=1;
BEGIN
  xla_security_pkg.set_security_context(602);
  x_ret_code := 0;
  g_ret_code :=0;
  ld_date    := NVL(fnd_date.canonical_to_date(P_RUN_DATE),sysdate);
  SELECT TO_CHAR(TO_DATE(ld_date, 'DD-MON-YY'), 'Q') INTO lv_qtr FROM DUAL;
  SELECT TO_CHAR(ld_date, 'MON-YY') INTO lv_month FROM dual;
  IF P_START_DATE    IS NOT NULL AND P_END_DATE IS NOT NULL THEN
    V_START_DATE     := P_START_DATE;
    V_END_DATE       := P_END_DATE;
  ELSIF P_START_DATE IS NULL AND P_END_DATE IS NULL THEN
    IF P_FREQUENCY    = 'Quarterly' THEN
      SELECT MIN(start_date) ,
        MAX(end_date)
      INTO V_START_DT,
        V_END_DT
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM ld_date)
      AND quarter_num   = NVL(TO_NUMBER(lv_qtr), quarter_num);
      V_START_DATE     :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
      V_END_DATE       :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
    ELSIF P_FREQUENCY   = 'Monthly' THEN
      SELECT MIN(start_date) ,
        MAX(end_date)
      INTO V_START_DT,
        V_END_DT
      FROM gl_periods
      WHERE period_year = EXTRACT (YEAR FROM ld_date)
      AND period_name   = NVL(lv_month, period_name);
      V_START_DATE     :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
      V_END_DATE       :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
    ELSIF P_FREQUENCY   = 'Weekly' THEN
      /*SELECT DECODE (TO_CHAR(ld_date,'dy') ,'sun', ld_date-1,ld_date)
      INTO l_date
      FROM dual;
      SELECT to_date(next_day(l_date-7, 'sun')) ,
      to_date(next_day(l_date     -6, 'sat'))
      INTO V_START_DT,
      V_END_DT
      FROM apps.gl_periods
      WHERE period_year = EXTRACT (YEAR FROM ld_date)
      AND rownum        =1;
      V_START_DATE     :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
      V_END_DATE       :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');*/
      SELECT TO_CHAR(to_date(ld_date), 'DY')
      INTO lv_wk_day
      FROM dual;
      IF lv_wk_day = 'SAT' THEN
        SELECT to_date(next_day(ld_date-7, 'sun')) ,
          to_date(ld_date)
        INTO V_START_DT,
          V_END_DT
        FROM gl_periods
        WHERE period_year = EXTRACT (YEAR FROM ld_date)
        AND rownum        =1;
      ELSE
        SELECT to_date(next_day(ld_date-7, 'sun')) ,
          to_date(next_day(ld_date, 'sat'))
        INTO V_START_DT,
          V_END_DT
        FROM gl_periods
        WHERE period_year = extract (YEAR FROM ld_date)
        AND rownum        =1;
      END IF;
      V_START_DATE :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
      V_END_DATE   :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
    END IF;
  END IF;
  fnd_file.put_line(fnd_file.log,' Start Date: '||V_START_DATE ||' End Date: '||V_END_DATE);
  FOR i IN c_dstroy_merch (V_START_DATE,V_END_DATE)
  LOOP
    lv_email:=NULL;
    fnd_file.put_line(fnd_file.log, ' in loop :');
    fnd_file.put_line(fnd_file.log, 'Submiting the Destroyed Merch Report with vendor id '|| i.vendor_site_id ) ;
    ---  lc_error_loc       := 'Setting the Printer for Destroyed Merch Report';
    ---   lc_error_debug     := 'Setting the Printer for Destroyed Merch Report: ';
    ln_conc_request_id := fnd_request.submit_request ( 'xxfin' , 'XXAPDSTROYMERCH' , NULL , NULL , false --changed to false for Defect 37797
    , P_START_DATE,P_END_DATE,P_FREQUENCY,i.vendor_site_id, P_RUN_DATE );
    fnd_file.put_line(fnd_file.log, 'Submitted the Destroyed Merch Report with Request ID '||ln_conc_request_id);
    COMMIT;
    IF P_START_DATE IS NULL AND P_END_DATE IS NULL THEN
      wait_and_submit_dest(i.vendor_site_id,ln_conc_request_id);
    END IF;
    BEGIN
      SELECT email_address
      INTO lv_email
      FROM ap_supplier_Sites_all
      WHERE vendor_Site_id = i.vendor_site_id;
    EXCEPTION
    WHEN OTHERS THEN
      lv_email:=NULL;
    END;
    fnd_file.put_line(fnd_file.log, ' Email is  '||lv_email);
    IF lv_email IS NULL THEN
      fnd_file.put_line(fnd_file.log, ' Email is  NULL');
      SELECT instance_name INTO lv_instance FROM v$instance;
      SELECT sup.segment1,
        sup.vendor_name,
        sit.vendor_site_code
      INTO lv_supplier_num,
        lv_supplier_name ,
        lv_supplier_Site
      FROM ap_supplier_sites_all sit,
        ap_suppliers sup
      WHERE sit.vendor_Site_id                = i.vendor_site_id
      AND sit.vendor_id                       = sup.vendor_id;
      l_email_null_rec_tb(rec).SUPPLIER_NUM  := lv_supplier_num;
      l_email_null_rec_tb(rec).SUPPLIER_NAME := lv_supplier_name;
      l_email_null_rec_tb(rec).SUPPLIER_SITE := lv_supplier_site;
      rec                                    :=rec+1;
      fnd_file.put_line(fnd_file.log, ' Assignment done');
    END IF;
  END LOOP;
  IF l_email_null_rec_tb.COUNT >=1 THEN
    fnd_file.put_line(fnd_file.log, 'PL/SQL table has count >= 1');
    BEGIN
      SELECT lv_instance
        ||': '
        ||xftv.target_value2,
        xftv.target_value4
      INTO lc_email_subject,
        v_email_list
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftd.translation_name = 'XX_AP_TRADE_PAY_EMAIL'
      AND xftv.source_value1    ='XXAPDSTROYMERCHEXCEPREP'
      AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
      AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
      AND xftv.enabled_flag = 'Y'
      AND xftd.enabled_flag = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      v_email_list    :='ebs_test_notifications@officedepot.com';
      lc_email_subject:=lv_instance||'Needs attention: Missing Supplier Site Email id';
    END;
    
    lc_email_content := 'Hi,'||CHR(13)|| 'Email address for below vendor sites are not defined'||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    lc_email_content := lc_email_content|| rpad('Supplier Num',25)|| rpad('Supplier Name',50)|| rpad('Supplier Site',25)||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    FOR r IN 1 .. l_email_null_rec_tb.count
    LOOP
      lc_email_content:= lc_email_content|| rpad(l_email_null_rec_tb(r).Supplier_num,25,CHR(32))|| rpad(l_email_null_rec_tb(r).Supplier_name,50,CHR(32))|| rpad(l_email_null_rec_tb(r).Supplier_site,25,CHR(32))||CHR(13);
      -- lc_email_content:= lc_email_content|| l_email_null_rec_tb(r).Supplier_num||
      --                l_email_null_rec_tb(r).Supplier_name|| l_email_null_rec_tb(r).Supplier_site||CHR(13);
    END LOOP;
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    lc_email_content := lc_email_content||CHR(13)||'Thank you,'||CHR(13)|| 'IT Team';
    BEGIN
      conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
      dbms_output.put_line('after conn');
      xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
      xx_pa_pb_mail.end_mail( conn => conn );
      COMMIT;
      fnd_file.put_line(fnd_file.log, ' Email sent successfully  ');
    EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Exception caught while sending email for email address not defined');
      fnd_file.put_line(fnd_file.log, 'Exception caught while sending email for email address not defined ');
    END;
  END IF;
  ln_org_id :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, ' V_START_DATE ' || V_START_DATE);
  fnd_file.put_line(fnd_file.log, ' V_END_DATE ' || V_END_DATE);
  x_ret_code:= g_ret_code;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
END SUBMIT_DESTROY_MERCH_REPORT;

PROCEDURE NOTIFY_VENDOR_SITE_EMAIL_NULL(p_start_date DATE, p_end_Date DATE, p_frequency VARCHAR2, p_vendor_site NUMBER)
AS
cursor c_email(lv_start_date VARCHAR2, lv_end_Date VARCHAR2)
IS
SELECT distinct   
  xarh.vendor_num Supplier_num,
  asp.vendor_name Supplier_name,
  aspa.vendor_site_code Supplier_site
FROM  ap_supplier_sites_all aspa, 
     ap_suppliers  asp
     ,xx_ap_rtv_hdr_attr xarh
     , ap_invoices_all aia
where  xarh.record_status !='N'
AND xarh.return_description ='DESTROY-OPTION 73'
AND xarh.invoice_num like 'RTV73%'
AND aspa.pay_site_flag = 'Y'
AND NVL(aspa.inactive_date,sysdate) >= TRUNC(sysdate)
AND aspa.email_address IS  NULL
AND LTRIM(aspa.VENDOR_SITE_CODE_ALT,'0')   = ltrim(xarh.vendor_num,'0')
AND xarh.invoice_num = aia.invoice_num
AND asp.vendor_id       = aia.vendor_id
AND aspa.vendor_site_id = aia.vendor_site_id 
AND aia.cancelled_date IS NULL
AND aspa.vendor_site_id=NVL(P_VENDOR_SITE,aspa.vendor_site_id)
--AND (aia.creation_date BETWEEN fnd_date.canonical_to_date(lv_start_date) AND fnd_date.canonical_to_date(lv_end_date))
AND aia.creation_date BETWEEN to_date(to_char(p_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')
  AND xarh.frequency_code   = NVL(DECODE(P_FREQUENCY,'Quarterly', 'QY','Monthly','MY','Weekly','WY'),xarh.frequency_code);

lv_email    VARCHAR2(1000);
  lv_instance VARCHAR2(50);
lc_email_subject VARCHAR2(250);
  lc_email_content VARCHAR2(4000);
  conn utl_smtp.connection;
  v_email_list VARCHAR2(500);
  V_start_date varchar2(50);
  V_end_date varchar2(50);
  l_send_flag VARCHAR2(1) :='N';
BEGIN
V_START_DATE :=TO_CHAR(p_start_date,'YYYY/MM/DD HH24:MI:SS');
      V_END_DATE   :=TO_CHAR(p_end_date,'YYYY/MM/DD HH24:MI:SS');
      fnd_file.put_line(fnd_file.log, ' Inside XX_AP_SUBMIT_DESTROY_MERCH_PKG.NOTIFY_VENDOR_SITE_EMAIL_NULL procedure  ');
      fnd_file.put_line(fnd_file.log, ' Start Date: '||p_start_date||'---End Date: '||p_end_date||'---Frequency: '||p_frequency);
      fnd_file.put_line(fnd_file.log, ' Email sent successfully  ');
      SELECT instance_name INTO lv_instance FROM v$instance;
      BEGIN
      SELECT lv_instance
        ||': '
        ||xftv.target_value2,
        xftv.target_value4
      INTO lc_email_subject,
        v_email_list
      FROM xx_fin_translatedefinition xftd ,
        xx_fin_translatevalues xftv
      WHERE xftd.translate_id   = xftv.translate_id
      AND xftd.translation_name = 'XX_AP_TRADE_PAY_EMAIL'
      AND xftv.source_value1    ='XXAPDSTROYMERCHEXCEPREP'
      AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
      AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
      AND xftv.enabled_flag = 'Y'
      AND xftd.enabled_flag = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      v_email_list    :='ebs_test_notifications@officedepot.com';
      lc_email_subject:=lv_instance||'Needs attention: Missing Supplier Site Email id';
    END;
    --v_email_list := 'ragni.gupta1@officedepot.com';
    lc_email_content := 'Hi,'||CHR(13)|| 'Email address for below vendor sites are not defined'||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    lc_email_content := lc_email_content|| rpad('Supplier Num',25)|| rpad('Supplier Name',50)|| rpad('Supplier Site',25)||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    FOR r IN c_email(v_start_date, v_end_date)
    LOOP
     
      lc_email_content:= lc_email_content|| rpad(r.Supplier_num,25,CHR(32))|| rpad(r.Supplier_name,50,CHR(32))|| rpad(r.Supplier_site,25,CHR(32))||CHR(13);
      l_send_flag :='Y';
    END LOOP;
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    lc_email_content := lc_email_content||CHR(13)||'Thank you,'||CHR(13)|| 'IT Team';
    IF l_send_flag ='Y' THEN
    BEGIN
      conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
      dbms_output.put_line('after conn');
      xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
      xx_pa_pb_mail.end_mail( conn => conn );
      COMMIT;
      fnd_file.put_line(fnd_file.log, ' Email sent successfully  ');
    EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Exception caught while sending email for email address not defined');
      fnd_file.put_line(fnd_file.log, 'Exception caught while sending email for email address not defined ');
    END;
     END IF;
END NOTIFY_VENDOR_SITE_EMAIL_NULL;
END XX_AP_SUBMIT_DESTROY_MERCH_PKG;
/

SHOW ERROR;