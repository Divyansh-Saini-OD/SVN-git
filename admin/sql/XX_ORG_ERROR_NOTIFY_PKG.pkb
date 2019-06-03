CREATE OR REPLACE
PACKAGE BODY XX_ORG_ERROR_NOTIFY_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |
  -- +===================================================================+
  -- | Name  : XX_ORG_ERROR_NOTIFY_PKG.PKB                               |
  -- | Description      : Package Body                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   17-Apr-2015   saikiran S        Initial draft version   |
  -- |                                                                   |
  -- +===================================================================+
  -- Organization_interface procedure will extract the Organizations stuck in interface
PROCEDURE org_interface(
    retcode OUT NUMBER,
    errbuf OUT VARCHAR2,
    P_days IN NUMBER)
IS
  l_status        VARCHAR2 (10);
  l_email_list    VARCHAR2 (1000);
  l_count         NUMBER      :=0;
  l_check         VARCHAR2(1) :='Y';
  l_string        VARCHAR2(2000);
  l_org_name      VARCHAR2 (1000) := NULL;
  l_loc_name      VARCHAR2 (1000) := NULL;
  l_error_message VARCHAR2 (1000);
  l_loc_code      VARCHAR2 (1000);
  l_loc_num       VARCHAR2 (1000);
  -- Cursor to fetch the Organization import errors
  CURSOR Org_stuck
  IS
    SELECT xx_stg.org_name_sw,
      xx_stg.LOCATION_NAME,
      Nvl(xx_stg.ERROR_MESSAGE,'Organization not created Sucessfully') ERROR_MESSAGE,
      xx_stg.location_number_sw
    FROM XX_INV_ORG_LOC_DEF_STG xx_stg
    WHERE xx_stg.location_number_sw NOT IN
      (SELECT haou.attribute1
      FROM hr_all_organization_units haou
      WHERE haou.attribute1 IS NOT NULL
      )
  AND xx_stg.update_date BETWEEN TRUNC(sysdate-p_days) AND TRUNC(sysdate);
BEGIN
  FOR org_stuck_rec IN org_stuck
  LOOP
    l_org_name     := org_stuck_rec.org_name_sw;
    l_loc_name     := org_stuck_rec.LOCATION_NAME ;
    l_loc_num      := org_stuck_rec.location_number_sw ;
    l_error_message:= org_stuck_rec.ERROR_MESSAGE;
    fnd_file.put_line (fnd_file.LOG, 'Org information..' || l_org_name );
    l_check  :='N';
    l_string := l_string || CHR (10)||'Location Name :'||l_loc_num||':'||l_loc_name|| CHR (10)||'Organization Name  :'||l_org_name|| CHR (10)||'Error Message  :'||l_error_message||CHR (10);
    l_count  :=l_count+1;
  END LOOP;
  fnd_file.put_line (fnd_file.LOG,'l_count'||l_count );
  IF l_check ='N' THEN
    --calling the Email notification trigger procedure
    int_error_mail_msg (l_count,l_string,l_status,l_email_list );
    IF l_status = 'Y' THEN
      fnd_file.put_line(fnd_file.log,'Email Notification Successfully Sent To:' || NVL(l_email_list,'NO MAIL ADDRESS SETUP'));
    ELSE
      fnd_file.put_line(fnd_file.log,'Error during Email Notification:'|| SQLERRM);
    END IF;
  ELSE
    fnd_file.put_line (fnd_file.LOG, 'Email notification not required - No data to be triggered from RMS.....');
  END IF;
  retcode := 0;
  errbuf  := 'Y';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  fnd_file.put_line (fnd_file.LOG,'No Data found');
  l_status := 'N';
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
  l_status := 'N';
END;
-- Procedure  to send Email notification to RMS team to trigger the items
PROCEDURE int_error_mail_msg(
    P_count  IN NUMBER,
    p_string IN CLOB,
    x_mail_sent_status OUT VARCHAR2,
    x_email_list OUT VARCHAR2)
IS
  lc_mail_from      VARCHAR2 (100);
  lc_mail_recipient VARCHAR2 (1000);
  lc_mail_subject   VARCHAR2 (1000) ;
  lc_mail_host      VARCHAR2 (100):= fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
  lc_email_list     VARCHAR2 (1000) ;
  lc_mail_conn UTL_SMTP.connection;
  crlf        VARCHAR2 (10) := CHR (13) || CHR (10);
  slen        NUMBER        := 1;
  v_addr      VARCHAR2 (1000);
  lc_instance VARCHAR2 (100);
  l_text      VARCHAR2(2000) := NULL;
BEGIN
  lc_mail_from   :=NULL;
  lc_mail_subject:=NULL;
  lc_email_list  :=NULL;

  BEGIN
    SELECT target_value2,
      target_value3,
      target_value4
    INTO lc_email_list,
      lc_mail_from,
      lc_mail_subject
    FROM xx_fin_translatedefinition def,
      xx_fin_translatevalues val
    WHERE def.translate_id   =val.translate_id
    AND def.translation_name = 'XX_OM_INV_NOTIFICATION';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
  END;
  lc_mail_conn      := UTL_SMTP.open_connection (lc_mail_host, 25);
  lc_mail_recipient := lc_email_list;
  UTL_SMTP.helo (lc_mail_conn, lc_mail_host);
  UTL_SMTP.mail (lc_mail_conn, lc_mail_from);
  IF (INSTR (lc_mail_recipient, ',') = 0) THEN
    v_addr                          := lc_mail_recipient;
    UTL_SMTP.rcpt (lc_mail_conn, v_addr);
  ELSE
    lc_mail_recipient                          := REPLACE (lc_mail_recipient, ' ', '_') || ',';
    WHILE (INSTR (lc_mail_recipient, ',', slen) > 0)
    LOOP
      v_addr := SUBSTR (lc_mail_recipient, slen, INSTR (SUBSTR (lc_mail_recipient, slen), ',') - 1 );
      slen   := slen                                                                           + INSTR (SUBSTR (lc_mail_recipient, slen), ',');
      UTL_SMTP.rcpt (lc_mail_conn, v_addr);
    END LOOP;
  END IF;
  SELECT NAME INTO lc_instance FROM v$database;
  IF lc_instance = 'GSIPRDGB' THEN
    l_text      := 'Organizations not created Sucessfully ';
  ELSE
    l_text :='Please Ignore this email: Organizations not created Sucessfully ';
  END IF;
  lc_mail_subject := l_text || ' ' || lc_instance;
  UTL_SMTP.DATA (lc_mail_conn, 'From:' || lc_mail_from || UTL_TCP.crlf || 'To: ' || v_addr || UTL_TCP.crlf || 'Subject: ' || lc_mail_subject || UTL_TCP.crlf || crlf ||'AMS SCM Team,' || crlf || crlf || 'AMS SCM team will review the issue and assign it to respective team.' || crlf || crlf || '-------------------------------------------------------------------------------------------------' || crlf || 'Organization creation errors from EBS - '||lc_instance || crlf || '-------------------------------------------------------------------------------------------------' || crlf || p_string || '-------------------------------------------------------------------------------------------------'||crlf ||'Total Error Records :'||p_count||crlf ||'-------------------------------------------------------------------------------------------------' );
  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'Y';
  x_email_list       :=lc_email_list;
EXCEPTION
WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
  raise_application_error (-20000, 'Unable to send mail: ' || SQLERRM);
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Unable to send mail..:'|| SQLERRM);
END int_error_mail_msg;
END XX_ORG_ERROR_NOTIFY_PKG;
/
EXIT;