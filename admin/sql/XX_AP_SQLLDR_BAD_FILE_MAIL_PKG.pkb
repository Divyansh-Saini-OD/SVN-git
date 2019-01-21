create or replace 
PACKAGE BODY XX_AP_SQLLDR_BAD_FILE_MAIL_PKG
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
  -- +=========================================================================
  -- =+
PROCEDURE Wait_For_Child(
    P_Request_Id IN NUMBER) ------ADDED FOR DEFECT 31288
IS
  Lb_Complete   BOOLEAN;
  Lc_Phase      VARCHAR2 (100);
  Lc_Status     VARCHAR2 (100);
  lc_dev_phase  VARCHAR2 (100);
  Lc_Dev_Status VARCHAR2 (100);
  Lc_Message    VARCHAR2 (100);
  CURSOR CUR_Child_Req(P_Request_Id IN NUMBER)
  IS
    SELECT Request_Id
    FROM Fnd_Concurrent_Requests R
    WHERE PARENT_REQUEST_ID =P_REQUEST_ID;
BEGIN
  FOR C_Child IN Cur_Child_Req(P_Request_Id)
  LOOP
    fnd_file.put_line(FND_FILE.LOG,'Waiting for Child Request :   '|| C_Child.REQUEST_ID||'-'||CURRENT_TIMESTAMP);
    Lb_Complete :=fnd_concurrent.wait_for_request (request_id => C_Child.REQUEST_ID ,Interval => 2 ,max_wait => 0 ,Phase => Lc_Phase ,Status => Lc_Status ,Dev_Phase => Lc_Dev_Phase ,dev_status => lc_dev_status , MESSAGE => Lc_Message );
    LOOP
      EXIT
    WHEN ( Upper(Lc_Dev_Phase) = 'COMPLETE' OR Lc_Phase = 'C' ) ;
    END LOOP;
    Wait_For_Child(C_Child.Request_Id);
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
    conn       IN OUT NOCOPY utl_smtp.connection,
    p_filename IN VARCHAR2)
IS
  fil BFILE;
  file_len PLS_INTEGER;
  buf RAW(2100);
  amt BINARY_INTEGER := 672 * 3;
  /* ensures proper format;  2016 */
  pos PLS_INTEGER := 1;
  /* pointer for each piece */
  filepos PLS_INTEGER := 1;
  /* pointer for the file */
  v_directory_name VARCHAR2(100) := 'XXMER_OUTBOUND';
  v_line           VARCHAR2(1000);
  mesg             VARCHAR2(32767);
  mesg_len         NUMBER;
  crlf             VARCHAR2(2) := chr(13) || chr(10);
  data RAW(2100);
  chunks PLS_INTEGER;
  LEN PLS_INTEGER := 1;
  modulo PLS_INTEGER;
  pieces PLS_INTEGER;
  err_num         NUMBER;
  err_msg         VARCHAR2(100);
  v_mime_type_bin VARCHAR2(30) := 'application/pdf';
BEGIN
  xx_pa_pb_mail.begin_attachment( conn => conn, mime_type => 'application/pdf', inline => TRUE, filename => p_filename, transfer_enc => 'base64');
  fil        := BFILENAME(v_directory_name,p_filename);
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
      chunks   := TRUNC(utl_raw.length(data) / xx_pa_pb_mail.MAX_BASE64_LINE_WIDTH);
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
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in xx_attch_rpt :'||SQLERRM);
END xx_attch_rpt;
--Start changes for Defect 37797
PROCEDURE wait_and_submit_email(
    --p_checkrun_id IN NUMBER,
    p_request_id  IN NUMBER,
    p_conc_prog_appl_short_name IN VARCHAR2,
    p_concurrent_program_name IN VARCHAR2
     )
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
dbms_output.put_line('beforeBEGIN');
IF 
p_concurrent_program_name='XXAPSUPTRAITS'
THEN
lc_email_subject :='Supplier Traits Bad Data File for SQL Loader';
lc_email_content :='Please find attached Bad data file for Supplier Traits for SQL Loader';
END IF;

IF 
p_concurrent_program_name='XXAPSUPTRAITSMATRIX'
THEN
lc_email_subject :='Supplier Traits Matrix Bad Data File for SQL Loader';
lc_email_content :='Please find attached Bad data file for Supplier Traits Matrix for SQL Loader';
END IF;
IF 
p_concurrent_program_name='XXAPSUPADDTYPE'
THEN
lc_email_subject :='Supplier Address Types Bad Data File for SQL Loader';
lc_email_content :='Please find attached Bad data file for Supplier Address Types for SQL Loader';
END IF;
IF 
p_concurrent_program_name='XXAPSUPADDR'
THEN
lc_email_subject :='Vendor Contacts Bad Data File for SQL Loader';
lc_email_content :='Please find attached Bad data file for Vendor Contacts for SQL Loader';
END IF;

  v_email_list  := 'sunil.kalal@officedepot.com';
  ln_count := 1;---HArd coded
  IF ln_count > 0 THEN
    fnd_file.put_line(fnd_file.log, 'Wait for SQL Loader : email' || v_email_list );
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
---
IF 
p_concurrent_program_name='XXAPSUPTRAITS'
THEN
v_sfile_name:='sup_tarits_bad_data_file.txt';
END IF;

IF 
p_concurrent_program_name='XXAPSUPTRAITSMATRIX'
THEN
v_sfile_name:='sup_traits_matrix_bad_data_file.txt';
END IF;
IF 
p_concurrent_program_name='XXAPSUPADDTYPE'
THEN
v_sfile_name:='sup_Add_type_bad_data_file.txt';
END IF;
IF 
p_concurrent_program_name='XXAPSUPADDR'
THEN
v_sfile_name:='vendor_cont_bad_data_file.txt';
END IF;

--
--      v_sfile_name:='supp_traits_bad_file.txt';--lc_rtv_file_name||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')|| '.PDF';
      v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
      fnd_file.put_line(fnd_file.log, 'send Email v_dfile_name' || v_dfile_name ) ;
      --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
      -- v_status,v_dphase,v_dstatus,x_dummy)) THEN
      --  IF v_dphase       = 'COMPLETE' THEN
      v_file_name    :='$APPLCSF/$APPLOUT/'||v_file_name;
      vc_request_id  := FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY', 'OD: Common File Copy',NULL,FALSE, v_file_name,v_dfile_name,NULL,NULL, NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL , NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL, NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL ,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL ,NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

dbms_output.put_line('after loop req id'||vc_request_id);
      IF vc_request_id>0 THEN
        COMMIT;
      END IF;
      fnd_file.put_line(fnd_file.log, 'After OD: Common File Copy' );
      dbms_output.put_line('Before Common FIle COpy');
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,200,v_cphase, v_cstatus,v_cdphase,v_cdstatus,x_cdummy)) THEN
        IF v_cdphase = 'COMPLETE' THEN -- child
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email Address :'||v_email_list);
          conn := xx_pa_pb_mail.begin_mail( sender => 'AccountsPayable@officedepot.com', recipients => v_email_list, cc_recipients=>NULL, subject => lc_email_subject, mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'before attch ');
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
--  IF ln_count  > 0 THEN
  --  ln_req_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN' ,'XXAPDMTRF' ,NULL ,NULL , FALSE ,p_request_id ,lc_rtv_file_name);
 --   COMMIT;
 --   IF ln_req_id                     <> 0 THEN
  --    lc_phase                       := NULL;
  --    lc_status                      := NULL;
  --    lc_dev_phase                   := NULL;
  --    lc_dev_status                  := NULL;
 --     lc_message                     := NULL;
 --     WHILE (NVL(lc_dev_phase,'XXX') <> 'COMPLETE') -- Added loop to call
      -- wait for request till the request is not completed
 --     LOOP
 --       lb_result := fnd_concurrent.wait_for_request (ln_req_id, 10, 200, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message );
  --    END LOOP;
 --   END IF;
 -- END IF;
END wait_and_submit_email;

PROCEDURE xx_ap_sqlloader_send_email 
(
errbuf  OUT VARCHAR2,
retcode OUT VARCHAR2,
p_concurrent_program_name IN VARCHAR2,
p_conc_prog_appl_short_name IN VARCHAR2
)
IS
/*Variable declaration*/
fhandle UTL_FILE.file_type;
vtextout VARCHAR2 (32000);
text VARCHAR2 (32000);
v_request_id NUMBER := NULL;
v_request_status BOOLEAN;
v_phase VARCHAR2 (2000);
v_wait_status VARCHAR2 (2000);
v_dev_phase VARCHAR2 (2000);
v_dev_status VARCHAR2 (2000);
v_message VARCHAR2 (2000);
v_application_id NUMBER;
v_concurrent_program_id NUMBER;
v_conc_prog_short_name VARCHAR2 (100);
v_conc_prog_appl_short_name VARCHAR2 (100);
v_output_file_path VARCHAR2 (200);
v_file_name VARCHAR2 (200);
v_out VARCHAR2(1) :='o';
--
  lb_result        BOOLEAN;  
  lb_result        BOOLEAN;
  lc_phase         VARCHAR2 (100);
  lc_status        VARCHAR2 (100);
  lc_dev_phase     VARCHAR2 (100) := NULL;
  lc_dev_status    VARCHAR2 (100);
  lc_message       VARCHAR2 (100);
  lc_rtv_file_name VARCHAR2(240);
  ln_count         NUMBER := 0;
  ln_req_id        NUMBER;
--  v_file_name      VARCHAR2(100);
  v_dfile_name     VARCHAR2(200);
  v_sfile_name     VARCHAR2(100);
  conn utl_smtp.connection;
  v_email_list     VARCHAR2(2000) := 'sunil.kalal@officedepot.com';
--  v_request_id     NUMBER;
  vc_request_id    NUMBER;
 -- v_phase          VARCHAR2(100) ;
  x_cdummy         VARCHAR2(2000) ;
  v_cdphase        VARCHAR2(100) ;
  v_cdstatus       VARCHAR2(100) ;
  v_cphase         VARCHAR2(100) ;
  v_cstatus        VARCHAR2(100) ;
  lc_email_subject VARCHAR2(250)  := '';
  lc_email_content VARCHAR2(1000) := ''; 
--


BEGIN
fnd_file.put_line (fnd_file.output,
'——————————————————'
);
fnd_file.put_line (fnd_file.output,
'Conc Prog: ' || p_concurrent_program_name
);

dbms_output.put_line('Begin concurrent program name'||p_concurrent_program_name);
dbms_output.put_line('p_concurrent_program_app short name' || p_conc_prog_appl_short_name);

/* Calling fnd_request.submit_request to submit the desired
the concurrent program*/
dbms_output.put_line('v_conc_prog_appl_short_name' || v_conc_prog_appl_short_name);
dbms_output.put_line('v_conc_prog_short_name' || v_conc_prog_short_name);

v_request_id :=
fnd_request.submit_request(p_conc_prog_appl_short_name,--v_conc_prog_appl_short_name,
p_concurrent_program_name,--v_conc_prog_short_name,
NULL,NULL,FALSE
--p_parameter1
);
fnd_file.put_line (fnd_file.LOG,'Concurrent Request Submitted
Successfully: ' || v_request_id
);
dbms_output.put_line('Conc Prog submitted:'|| v_request_id);
COMMIT;
dbms_output.put_line('v_request_id'||v_request_id);
IF v_request_id IS NOT NULL
THEN
/*Calling fnd_concurrent.wait_for_request to wait for the
program to complete */
v_file_name:= v_out || v_request_id || '.out';
dbms_output.put_line('FIle name' ||v_file_name );
v_request_status:=
fnd_concurrent.wait_for_request
(
request_id => v_request_id,
INTERVAL => 10,
max_wait => 0,
phase => v_phase,
status => v_wait_status,
dev_phase => v_dev_phase,
dev_status => v_dev_status,
MESSAGE => v_message
);
dbms_output.put_line('FIle name' ||v_file_name );
dbms_output.put_line('v_request_id'||v_dev_phase);
dbms_output.put_line('v_request_id'||v_dev_status);

--v_dev_phase := NULL;
--v_dev_status := NULL;
--END IF;

IF v_dev_status ='WARNING' THEN
--xx_attch_sqlloader
dbms_output.put_line('EMail Address'||v_email_list);
 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email Address :'||v_email_list);
    --      conn := xx_pa_pb_mail.begin_mail( sender => 'sunil.kalal@officedepot.com', recipients =>v_email_list, cc_recipients=>NULL, subject => 'TEST'--lc_email_subject,
      --    ,mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'before attch ');
          dbms_output.put_line( 'before attch ');
         dbms_output.put_line( 'v_file_name '||v_file_name);
         dbms_output.put_line('REq Id'||v_request_id);
         wait_and_submit_email(v_request_id,p_conc_prog_appl_short_name,p_concurrent_program_name);
--         dbms_output.put_line( 'conn ' || conn) ;
--          xx_pa_pb_mail.xx_attch_sqlloader(conn,v_file_name);--v_sfile_name);
      --    xx_pa_pb_mail.end_attachment(conn => conn);
       --   xx_pa_pb_mail.attach_text( conn => conn, data => lc_email_content );
     --     xx_pa_pb_mail.end_mail( conn => conn );
          COMMIT; 
END IF;
END IF;
END;
END XX_AP_SQLLDR_BAD_FILE_MAIL_PKG;