CREATE OR REPLACE
PACKAGE BODY XX_ORG_IMP_ERR_NOTI_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |
  -- +===================================================================+
  -- | Name  : XXINTERRORNOTIFYPKG.PKB                                   |
  -- | Description      : Package Body                                   |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version    Date          Author           Remarks                  |
  -- |=======    ==========    =============    ======================== |
  -- |DRAFT 1A   16-MAR-2015   Saritha M        Initial draft version    |
  -- |                                                                   |
  -- +===================================================================+
  -- int_interface procedure will extract the Locations stuck in interface
PROCEDURE org_interface(
    retcode OUT NUMBER,
    errbuf OUT VARCHAR2,
    p_email_list in varchar2)
IS
  l_master_item       VARCHAR2 (1000) := NULL;
  l_org_code         VARCHAR2 (5000) := NULL;
  l_count             NUMBER          := 0;
  p_status            VARCHAR2 (10);
  lc_error_message    VARCHAR2 (1000);
  l_loc_cnt           NUMBER          := 0;
  l_child_item        VARCHAR2 (1000) := NULL;
  l_loc               VARCHAR2 (1000) := NULL;
  l_organization_name VARCHAR2 (1000) := NULL;
  l_child_item_code CLOB              := NULL;
  l_check        VARCHAR2(1)                 :='Y';
  l_email_list   VARCHAR2(2000)              := NULL;
  l_check_status VARCHAR2(20)                :='Y';
  l_org_name VARCHAR2 (1000) := NULL;
  L_LOC_NAME VARCHAR2 (1000) := NULL;
  CURSOR Org_stuck
  IS
    SELECT ORGANIZATION_ID,
      org_name_sw,
      LOCATION_NAME,
      ERROR_CODE,
      ERROR_MESSAGE
    FROM XX_INV_ORG_LOC_DEF_STG
    WHERE process_flag=6;
BEGIN
  FOR org_stuck_rec IN org_stuck
  LOOP
    l_org_name := org_stuck_rec.org_name_sw;
    l_loc_name := org_stuck_rec.LOCATION_NAME ;
    fnd_file.put_line (fnd_file.LOG, 'Org information..' || l_org_name );
    SELECT COUNT (1)
    INTO l_count
    FROM XX_INV_ORG_LOC_DEF_STG
    WHERE org_name_sw = l_org_name
    AND process_flag  =6;
    IF l_count        = 0 THEN
      l_check_status :='N';
      l_org_code    := l_org_code || CHR (10);
    END IF;
  END LOOP;
  IF l_check_status='Y' THEN
    l_org_code   :='No Action Required to trigger the Org details';
  END IF;
  IF l_check     ='N' THEN
    l_email_list:= p_email_list;
    int_error_mail_msg (l_org_name, l_loc_name, l_email_list, p_status );
    IF p_status  = 'Y' THEN
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
  p_status := 'N';
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
  p_status := 'N';
END;
-- Procedure  to send Email notification to RMS team to trigger the items
PROCEDURE int_error_mail_msg(
    p_org_name   IN VARCHAR2,
    p_loc_name   IN CLOB,
    p_email_list IN VARCHAR2,
    x_mail_sent_status OUT VARCHAR2 )
IS
  lc_mail_from      VARCHAR2 (100);
  lc_mail_recipient VARCHAR2 (1000);
  lc_mail_subject   VARCHAR2 (1000) ;
  lc_mail_host      VARCHAR2 (100) ;
  lc_mail_conn UTL_SMTP.connection;
  crlf        VARCHAR2 (10) := CHR (13) || CHR (10);
  slen        NUMBER        := 1;
  v_addr      VARCHAR2 (1000);
  lc_instance VARCHAR2 (100);
  l_text      VARCHAR2(2000) := NULL;
BEGIN
begin
select target_value1,target_value2,target_value3 
into lc_mail_from,lc_mail_subject,lc_mail_host  
from XX_FIN_TRANSLATEVALUES 
where translate_id= 56330;
exception
when others then
fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
end;
  lc_mail_conn      := UTL_SMTP.open_connection (lc_mail_host, 25);
  lc_mail_recipient := p_email_list;
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
    l_text      := 'Organizations not imported Sucessfully ';
  ELSE
    l_text :='Please Ignore this email: Organizations not imported Sucessfully ';
  END IF;
  lc_mail_subject := l_text || ' ' || lc_instance;
  UTL_SMTP.DATA (lc_mail_conn, 'From:' || lc_mail_from || UTL_TCP.crlf || 'To: ' || v_addr || UTL_TCP.crlf || 'Subject: ' || lc_mail_subject || UTL_TCP.crlf || 'RMS Team,' || crlf || crlf || crlf || 'Inv Orgs import stuck in EBS as below Orgs are either not created or assigned to their corresponding location.' || crlf || crlf ||'Current Impact: Revenue Impact - Unable to create Sales orders' || crlf || crlf || '-------------------------------------------------------------------------------------------------' || crlf || 'Organization Creation Request for EBS - '||lc_instance || crlf || '-------------------------------------------------------------------------------------------------' || crlf || p_org_name || crlf || crlf || '-------------------------------------------------------------------------------------------------' || crlf || 'Location assignment Request for EBS - '||lc_instance || crlf ||
  '-------------------------------------------------------------------------------------------------' || crlf || p_loc_name );
  UTL_SMTP.quit (lc_mail_conn);
  x_mail_sent_status := 'Y';
EXCEPTION
WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
  raise_application_error (-20000, 'Unable to send mail: ' || SQLERRM);
WHEN OTHERS THEN
  fnd_file.put_line (fnd_file.LOG,'Unable to send mail..:'|| SQLERRM);
END int_error_mail_msg;
END XX_ORG_IMP_ERR_NOTI_PKG;
/
show errors;