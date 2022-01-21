SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body XX_AP_SUBMIT_RTV_CONSIGN_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                                                                          |
  -- +==========================================================================+
  -- | Name             :    XX_AP_SUBMIT_RTV_CONSIGN_PKG                     |
  -- | Description      :    Package for Submit request for Destroyed Merch Rep |
  -- | RICE ID          :    R70                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      23-Feb-2018  Priyam Parmar        Initial                        |
  -- | 1.1      16-Apr-2018  Priyam Parmar   Code Commented for SMTP error NAIT-37610
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
    lc_rtv_file_name :='APRTVCONSIGN';
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
    AND xftv.source_value1    ='XXAPCONSIGNMENTRTV'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active, sysdate+1)
    AND sysdate BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active, sysdate+1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    lc_rtv_file_name :='APRTVCONSIGN';
  END;
  BEGIN
    SELECT instance_name INTO G_INSTANCE FROM v$instance;
    -- IF G_INSTANCE = 'GSIPRDGB' THEN
    SELECT DECODE(G_INSTANCE,'GSIDEV02',lc_email_id,'GSIUATGB',lc_email_id,MIN(pvsa.email_address)) email,
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
    AND pv.vendor_id                                = pvsa.vendor_id;
   --- v_email_list                                   := lc_email_id; Code Commented for SMTP error NAIT-37610
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
      IF v_cdphase = 'COMPLETE' THEN -- child
        fnd_file.put_line(fnd_file.log, 'After OD: RTV Consignment Report' );
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
  -- END IF;
  --DELETE FROM xx_ap_xxaprtvapdm_tmp WHERE request_id = p_request_id;
  -- COMMIT;
END wait_and_submit_rtv;
PROCEDURE SUBMIT_RTV_CONSIGN_REPORT(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER,
    P_START_DATE       IN VARCHAR2,
    P_END_DATE         IN VARCHAR2,
    --P_FREQUENCY        IN VARCHAR2,
    P_VENDOR_SITE_CODE IN VARCHAR2,
    P_SEND_EMAIL VARCHAR2)
AS
  CURSOR c_rtv_consign (lv_start_date IN VARCHAR2, lv_end_date IN VARCHAR2)
  IS
    SELECT DISTINCT asa.org_id,
      asa.vendor_site_id,asa.vendor_site_code 
      --   aia.invoice_num,
      --   TO_CHAR(TRUNC(sysdate),'YYYY/MM/DD HH24:MI:SS') program_date
    FROM XX_PO_VENDOR_SITES_KFF XPVS, 
  XX_AP_RTV_HDR_ATTR XARH,  
  MTL_MATERIAL_TRANSACTIONS MMT,
  AP_SUPPLIERS ASU,
  AP_SUPPLIER_SITES_ALL ASA,
  HR_ORGANIZATION_UNITS HOU
WHERE 1                                 =1
---AND XPVS.SEGMENT43 <> '100'
AND MMT.TRANSACTION_SOURCE_NAME         = 'OD CONSIGNMENT RTV'
AND MMT.ATTRIBUTE1                     IS NOT NULL
AND MMT.ATTRIBUTE2                     IS NOT NULL
--AND MMT.ATTRIBUTE3                     IS NOT NULL
AND LTRIM(ASA.vendor_site_code_alt,'0') = LTRIM(MMT.ATTRIBUTE1,'0')
--AND asa.vendor_Site_ID = nvl(P_VENDOR_SITE_ID,asa.vendor_Site_ID)
AND ASA.PAY_SITE_FLAG                     ='Y'
AND ASU.VENDOR_ID                         = ASA.VENDOR_ID
AND HOU.ORGANIZATION_ID                   = MMT.ORGANIZATION_ID
AND XARH.RTV_NUMBER                       = MMT.ATTRIBUTE2
AND XARH.RECORD_STATUS                    ='C'
AND XARH.RETURN_CODE                      <> '73'
AND ASA.ATTRIBUTE12                       =XPVS.VS_KFF_ID
AND trunc(mmt.transaction_date) BETWEEN fnd_date.canonical_to_date(lv_start_date) AND fnd_date.canonical_to_date(lv_end_date)
--AND XPVS.SEGMENT44       = DECODE(P_FREQUENCY,'WY','WEEKLY','MY','MONTHLY','QY','QUARTERLY')
AND asa.vendor_site_code = NVL(P_VENDOR_SITE_CODE,asa.vendor_site_code);
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
--  lv_start_date DATE;
--  lv_end_date   DATE;
  V_START_DATE  VARCHAR2(50);
  V_END_DATE    VARCHAR2(50);
  V_START_DT    DATE;
  V_END_DT      DATE;
  V_EMAIL VARCHAR2(5);
   lv_frequency  VARCHAR2(50);

  lv_qtr        VARCHAR2(20);
  lv_month      VARCHAR2(20);
BEGIN
  xla_security_pkg.set_security_context(602);
  x_ret_code := 0;
  V_EMAIL:=P_SEND_EMAIL;
  
      V_START_DATE  := p_start_date;
      V_END_DATE    := p_end_date;
      fnd_file.put_line(fnd_file.log, ' After if 2 : ' || V_START_DATE || ' TODATE ' || V_end_DATE);
     
      FOR i IN c_rtv_consign (V_START_DATE,V_END_DATE)
      LOOP
          fnd_file.put_line(fnd_file.log, ' in loop :');
          fnd_file.put_line(fnd_file.log, 'Submiting the RTV Consginment Report with vendor id '|| i.vendor_site_id ) ;
         -- lc_error_loc       := 'Setting the Printer for Destroyed Merch Report';
          --lc_error_debug     := 'Setting the Printer for Destroyed Merch Report: ';
          ln_conc_request_id := fnd_request.submit_request ( 'xxfin' , 'XXAPCONSIGRTV' ,  NULL , NULL , false , 
             --P_FREQUENCY,
             V_START_DATE,V_END_DATE,i.vendor_site_code );
          fnd_file.put_line(fnd_file.log, 'Submitted the RTV Consignment Report with Request ID '||ln_conc_request_id);
          
      
          COMMIT;
          
          IF V_EMAIL='YES' THEN 
       -- IF P_START_DATE is null and P_END_DATE is null then 
              wait_and_submit_rtv(i.vendor_site_id,ln_conc_request_id);
       END IF;
      END LOOP;
 
     --- END IF;
  ln_org_id :=fnd_profile.value ('ORG_ID'); 
  fnd_file.put_line(fnd_file.log, 'Org id :'||TO_CHAR(ln_org_id));
  fnd_file.put_line(fnd_file.log, ' V_START_DATE ' || V_START_DATE);
  fnd_file.put_line(fnd_file.log, ' V_END_DATE ' || V_END_DATE);
  
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_loc || ' - '||sqlerrm);
  fnd_file.put_line(fnd_file.log,'Error in '||lc_error_debug);
  x_ret_code := 2;
END SUBMIT_RTV_CONSIGN_REPORT;
END XX_AP_SUBMIT_RTV_CONSIGN_PKG;
/

SHOW ERRORS;