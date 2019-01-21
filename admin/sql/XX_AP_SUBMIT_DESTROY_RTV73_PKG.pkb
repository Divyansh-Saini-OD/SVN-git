SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE body XX_AP_SUBMIT_DESTROY_RTV73_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_SUBMIT_DESTROY_RTV73_PKG                     |
  -- | Description      :    OD: Destroy RTV73 Consignment Report |
  -- | RICE ID          :                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      21-Feb-2018  Priyam PArmar      Initial                        |
  -- | 1.1      16-APR-2018 Priyam Parmar     Code Commented for SMTP error NAIT-37610
  -- | 1.2      30-APR-2018 Priyam P             g_ret_code added to make the parent program complete in warning rather than error.
  -- | 1.3      31-MAY-2018 Jitendra A           Added procedure xx_AP_RTV73_EMAIL
  -- +==========================================================================+

  procedure xx_ap_rtv73_email(p_start_date DATE, p_end_Date DATE, p_frequency VARCHAR2, p_vendor_site VARCHAR2)
AS
cursor c_email(lv_start_date VARCHAR2, lv_end_Date VARCHAR2)
IS
select 
--DISTINCT TO_CHAR(sysdate,'MM/DD/YYYY') CURRENT_DATE,
  --TO_CHAR(:P_START_DATE,'MM/DD/YYYY') START_DATE,
-- TO_CHAR(:P_END_DATE,'MM/DD/YYYY') END_DATE,
--  :g_rtv_from_to rtv_num,
--  :G_END_DATE END_DATE_ALT,
  distinct asu.vendor_name supplier_name,
  asu.segment1 supplier_number,
  asa.vendor_site_code supplier_site,
  asa.vendor_site_code_alt supplier_site_alt,
  asa.email_address email,
  LTRIM(SUBSTR(ASA.ADDRESS_LINE1,1,30)) ADDRESS1,
  LTRIM(SUBSTR(ASA.ADDRESS_LINE2,1,30)) ADDRESS2,
   LTRIM(SUBSTR(ASA.ADDRESS_LINE3,1,30))address3,
  LTRIM(asa.city)||' '|| asa.state||' '||asa.country||' '|| asa.zip address_concat
FROM mtl_material_transactions mmt,
  ap_suppliers asu,  
  AP_SUPPLIER_SITES_ALL ASA,  
  xx_ap_rtv_hdr_attr xarh
WHERE 1 =1
and xarh.return_code= 73
AND xarh.frequency_code = P_FREQUENCY
AND ltrim(asa.vendor_site_code_alt,'0') = ltrim(xarh.vendor_num, '0')
and asa.pay_site_flag = 'Y'
AND asa.vendor_site_code      = NVL(p_vendor_site,asa.vendor_site_code)
AND asu.vendor_id = asa.vendor_id
AND ltrim(mmt.attribute1,'0') = ltrim(asa.vendor_site_code_alt,'0')
and mmt.transaction_source_name = 'OD CONSIGNMENT RTV'
and MMT.TRANSACTION_DATE BETWEEN  to_date(to_char(p_start_date)||' 00:00:00','DD-MON-RR HH24:MI:SS') AND to_date(to_char(p_end_date)||' 23:59:59','DD-MON-RR HH24:MI:SS')
AND xarh.rtv_number =  mmt.attribute2;

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
      fnd_file.put_line(fnd_file.log, ' Inside xx_ap_rtv73_email procedure  ');
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
      AND xftv.source_value1    ='XXAPRTV73DESTEXCEPREP'
      AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
      AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
      AND xftv.enabled_flag = 'Y'
      AND xftd.enabled_flag = 'Y';
    EXCEPTION
    WHEN OTHERS THEN
      v_email_list    :='ebs_test_notifications@officedepot.com';
      lc_email_subject:=lv_instance||'Needs attention: Missing Supplier Site Email id';
    end;
    v_email_list := 'jitendra.atale@officedepot.com';
    lc_email_content := 'Hi,'||CHR(13)|| 'Email address for below vendor sites are not defined'||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    lc_email_content := lc_email_content|| rpad('Supplier Num',25)|| rpad('Supplier Name',50)|| rpad('Supplier Site',25)||CHR(13);
    lc_email_content := lc_email_content|| rpad('-',100,'-')||CHR(13);
    FOR r IN c_email(v_start_date, v_end_date)
    LOOP
     
      lc_email_content:= lc_email_content|| rpad(r.supplier_number,25,CHR(32))|| rpad(r.Supplier_name,50,CHR(32))|| rpad(r.supplier_site,25,CHR(32))||CHR(13);
      
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
     end if;
END;

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
  G_INSTANCE       VARCHAR2(25);
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
    lc_rtv_file_name :='APDESTROYRTV73';
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
    AND xftv.source_value1    ='XXAPRTV73DEST'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    lc_rtv_file_name :='APDESTROYRTV73';
  END;
  BEGIN
    BEGIN
      SELECT instance_name INTO G_INSTANCE FROM v$instance;
      -- IF G_INSTANCE = 'GSIPRDGB' THEN
      /* SELECT DECODE(G_INSTANCE,'GSIDEV02',lc_email_id,'GSIUATGB',lc_email_id,MIN(pvsa.email_address)) email,
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
      FROM ap_supplier_sites_all pvsa --,
      WHERE 1                 =1
      AND pvsa.vendor_site_id = p_checkrun_id ;
      --- v_email_list                                   := lc_email_id; --Code Commented for SMTP error NAIT-37610
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
          --  IF v_cdphase = 'COMPLETE' THEN -- child
          IF v_cdphase = 'COMPLETE' AND v_cphase = 'NORMAL' THEN -- child
            fnd_file.put_line(fnd_file.log, 'After OD: Destroyed RTV73 Consignment Report' );
            fnd_file.put_line(fnd_file.log, 'Email Address :'||v_email_list);
            conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
            fnd_file.put_line(fnd_file.log, 'before attch ');
            xx_attch_rpt(conn,v_sfile_name);
            xx_pa_pb_mail.end_attachment(conn => conn);
            xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
            xx_pa_pb_mail.end_mail( conn => conn );
            COMMIT;
          END IF;
        END IF;
      END IF;
    END IF;
  END;
END wait_and_submit_dest;
PROCEDURE SUBMIT_DESTROY_RTV73_REPORT(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE IN VARCHAR2,
    P_END_DATE   IN VARCHAR2,
    P_FREQUENCY  IN VARCHAR2,
    p_vendor_site_code VARCHAR2,
    P_RUN_DATE IN VARCHAR2)
AS
  CURSOR c_dstroy_merch73(lv_start_date VARCHAR2,lv_end_date VARCHAR2)
  IS
    SELECT DISTINCT asa.org_id,
      asa.vendor_site_id ,
      asa.vendor_site_code,
      TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
    FROM xx_po_vendor_sites_kff xpvs,
      ap_suppliers asu,
      AP_SUPPLIER_SITES_ALL ASA,
      mtl_material_transactions mmt
    WHERE 1                         =1
    AND asa.pay_site_flag           ='Y'
    AND asu.vendor_id               = asa.vendor_id
    AND ASA.ATTRIBUTE12             = XPVS.VS_KFF_ID
    AND ltrim(mmt.attribute1,'0')   = ltrim(asa.vendor_site_code_alt,'0')
    AND mmt.transaction_source_name = 'OD CONSIGNMENT RTV'
      /*and MMT.TRANSACTION_DATE BETWEEN to_date( fnd_date.canonical_to_date(to_char(lv_start_date)), 'DD-MON-YY HH24:MI:SS') and
      to_date(fnd_date.canonical_to_date(to_char(lv_end_date)), 'DD-MON-YY HH24:MI:SS')*/
    AND TRUNC(MMT.TRANSACTION_DATE) BETWEEN fnd_date.canonical_to_date(lv_start_date) AND fnd_date.canonical_to_date(lv_end_date)
    AND XPVS.SEGMENT44       = DECODE(P_FREQUENCY,'WY','WEEKLY','MY','MONTHLY','QY','QUARTERLY')
    AND asa.vendor_site_code = NVL(p_vendor_site_code,asa.vendor_site_code)
    AND xpvs.segment43       = '100';
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
  l_batch_name     VARCHAR2(50) := fnd_global.conc_request_id ;
  lb_result        BOOLEAN;
  lc_phase         VARCHAR2 (100);
  lc_status        VARCHAR2 (100);
  lc_dev_phase     VARCHAR2 (100) := NULL;
  lc_dev_status    VARCHAR2 (100);
  lc_message       VARCHAR2 (100);
  rec              NUMBER :=1;
  r                NUMBER;
  lv_email         VARCHAR2 (1000);
  lc_email_subject VARCHAR2(250);
  lc_email_content VARCHAR2(4000);
  conn utl_smtp.connection;
  v_email_list VARCHAR2(500);
  i            NUMBER;
  lv_qtr       VARCHAR2(5);
  lv_month     VARCHAR2(20);
  V_START_DATE VARCHAR2(50);
  V_END_DATE   VARCHAR2(50);
  V_START_DT   DATE;
  V_END_DT     DATE;
  lv_frequency VARCHAR2(50);
  ld_date      DATE;
  lv_wk_day    VARCHAR2(100);
  lv_supplier_name ap_suppliers.vendor_name%TYPE;
  lv_supplier_site ap_supplier_sites_all.vendor_Site_Code%TYPE;
  lv_supplier_num ap_suppliers.segment1%type;
  lv_instance VARCHAR2(50);
TYPE l_email_null_rec_ctt
IS
  TABLE OF XX_AP_SUBMIT_DESTROY_RTV73_PKG.email_null_rec INDEX BY PLS_INTEGER;
  l_email_null_rec_tb l_email_null_rec_ctt;
BEGIN
  xla_security_pkg.set_security_context(602);
  x_ret_code := 0;
  g_ret_code :=0;
  ln_org_id  :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, 'Batch Name :'||TO_CHAR(l_batch_name));
  /* fnd_file.put_line(fnd_file.log, ' Before : ' ||
  to_char( fnd_date.canonical_to_date(to_char(P_START_DATE)), 'DD-MON-YY HH24:MI:SS') ||
  ' TODATE ' ||   to_char( fnd_date.canonical_to_date(to_char(P_END_DATE)), 'DD-MON-YY HH24:MI:SS') );*/
  BEGIN
    IF p_start_date IS NULL AND p_end_date IS NULL THEN
      ld_date       := fnd_date.canonical_to_date(P_RUN_DATE);
      SELECT TO_CHAR(to_date(ld_date, 'DD-MON-YY'), 'Q')INTO lv_qtr FROM dual;
      SELECT TO_CHAR(ld_date, 'MON-YY') INTO lv_month FROM dual;
      IF p_frequency = 'QY' THEN
        BEGIN
          SELECT MIN(start_date),
            MAX(end_date)
          INTO V_START_DT,
            V_END_DT
          FROM gl_periods
          WHERE period_year = extract (YEAR FROM ld_date)
          AND quarter_num   = NVL(to_number(lv_qtr), quarter_num);
          lv_frequency     :='QUARTERLY';
          V_START_DATE     :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
          V_END_DATE       :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
        END;
      END IF;
      IF p_frequency = 'MY' THEN
        BEGIN
          SELECT MIN(start_date) ,
            MAX(end_date)
          INTO V_START_DT,
            V_END_DT
          FROM gl_periods
          WHERE period_year = extract (YEAR FROM ld_date)
          AND period_name   = NVL(lv_month, period_name);
          lv_frequency     :='MONTHLY';
          V_START_DATE     :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
          V_END_DATE       :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
        END;
      END IF;
      IF p_frequency = 'WY' THEN
        BEGIN
          SELECT TO_CHAR(to_date(ld_date), 'DY') INTO lv_wk_day FROM dual;
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
          lv_frequency :='WEEKLY';
          V_START_DATE :=TO_CHAR(V_START_DT,'YYYY/MM/DD HH24:MI:SS');
          V_END_DATE   :=TO_CHAR(V_END_DT,'YYYY/MM/DD HH24:MI:SS');
        END;
      END IF;
    END IF;
    fnd_file.put_line(fnd_file.log, ' Before if');
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
      V_START_DATE  := p_start_date;
      V_END_DATE    := p_end_date;
      fnd_file.put_line(fnd_file.log, ' Before 2 : ' || V_START_DATE || ' TODATE ' || V_end_DATE);
      --- lv_frequency := P_FREQUENCY;
    END IF;
  END;
  FOR i IN c_dstroy_merch73(V_START_DATE,V_END_DATE)
  LOOP
    fnd_file.put_line(fnd_file.log, ' Inside Cursor ');
    fnd_file.put_line(fnd_file.log, ' in loop :');
    fnd_file.put_line(fnd_file.log, 'Submiting the Destroy RTV73 Consignment Report with vendor id '|| i.vendor_site_id ) ;
    ---lc_error_loc       := 'Setting the Printer for Destroy RTV73 Consignment Report';
    --- lc_error_debug     := 'Setting the Printer for Destroy RTV73 Consignment Report: ';
    ln_conc_request_id := fnd_request.submit_request ( 'xxfin' , 'XXAPRTV73DEST' , NULL , NULL , false , P_FREQUENCY,V_START_DATE,V_END_DATE,i.vendor_site_code,P_RUN_DATE );
    fnd_file.put_line(fnd_file.log, 'Submitted the Destroy RTV73 Consignment Report with Request ID '||ln_conc_request_id);
    COMMIT;
    IF p_start_date IS NULL AND p_end_date IS NULL THEN
      wait_and_submit_dest(i.vendor_site_id,ln_conc_request_id);---BURSTING SHOULD NOT FIRE WHEN DATE IS GIVEN
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
  IF l_email_null_rec_tb.count >=1 THEN
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
      AND xftv.source_value1    ='XXAPRTV73DESTEXCEPREP'
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
    lc_email_content := lc_email_content|| rpad('-',100,'-')||chr(13);
    lc_email_content := lc_email_content||CHR(13)||'Thank you,'||CHR(13)|| 'IT Team';
    BEGIN
      conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.multipart_mime_type);
      dbms_output.put_line('after conn');
      xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
      xx_pa_pb_mail.end_mail( conn => conn );
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Exception caught while sending email for email address not defined');
      fnd_file.put_line(fnd_file.log, 'Exception caught while sending email for email address not defined ');
    END;
  END IF;
  ln_org_id :=fnd_profile.value ('ORG_ID'); -- Defect 27343
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, ' V_START_DATE ' || v_start_date);
  fnd_file.put_line(fnd_file.log, ' V_END_DATE ' || V_END_DATE);
  x_ret_code:= g_ret_code;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
  --- x_ret_code :=1;
END SUBMIT_DESTROY_RTV73_REPORT;
END XX_AP_SUBMIT_DESTROY_RTV73_PKG;
/

SHOW ERRORS;