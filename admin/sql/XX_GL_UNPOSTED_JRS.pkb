create or replace package body XX_GL_UNPOSTED_JRS IS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_GL_UNPOSTED_JRS                                                         |
-- |  RICE ID 	 :                                                 			                        |
-- |  Description:                                                                            	|
-- |                                                                				                    |
-- +============================================================================================+
-- | Version     Date         Author              Remarks                                       |
-- | =========   ===========  =============       ==============================================|
-- | 1.0         24/10/2019   Divyansh Saini      Initial version                               |
-- +============================================================================================+


/*********************************************************************
* After report trigger for unposted journals report
*********************************************************************/
FUNCTION after_report RETURN BOOLEAN IS
   P_CONC_REQUEST_ID NUMBER;
   l_request_id NUMBER;
BEGIN

   P_SMTP_SERVER:= FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
   P_MAIL_FROM:='noreply@officedepot.com';
   Fnd_File.PUT_LINE (Fnd_File.LOG,'In parameter : P_SEND_EMAIL = '||P_SEND_EMAIL||chr(13)||'P_SMTP_SERVER = '||P_SMTP_SERVER||chr(13)||'P_MAIL_FROM = '||P_MAIL_FROM||chr(13));

   IF P_SEND_EMAIL ='Y' THEN

      P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
      Fnd_File.PUT_LINE (Fnd_File.LOG,'Submitting : XML Publisher Report Bursting Program');
      l_request_id := FND_REQUEST.SUBMIT_REQUEST ('XDO',
                                 'XDOBURSTREP',
                                 NULL,
                                 NULL,
                                 FALSE,
                                 'Y',
                                 P_CONC_REQUEST_ID,
                                 'Y');

   END IF;

   RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Unexpected error while submitting bursting program '||SQLERRM);
   RETURN FALSE;
END ;

/*********************************************************************
* Procedure used to send email as per parameter provided.
*********************************************************************/
Procedure send_email(p_email_to IN VARCHAR2,
                     p_email_cc IN VARCHAR2,
                     p_email_body IN VARCHAR2,
                     p_subject IN VARCHAR2,
                     x_status OUT VARCHAR2,
                     x_error OUT VARCHAR2) IS
   conn utl_smtp.connection;
BEGIN
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Sending email procedure start');
   conn := xx_pa_pb_mail.begin_mail(sender => gc_email_from,
                                 recipients => p_email_to,
                                 cc_recipients=>p_email_cc,
                                 subject =>p_subject,
                                 mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
   xx_pa_pb_mail.attach_text( conn => conn,
                                       data => p_email_body,
                                       mime_type =>'text/html'
                                                );

   xx_pa_pb_mail.end_mail( conn => conn );
   x_status := 'S';
   COMMIT;
  
EXCEPTION WHEN OTHERS THEN
   x_status:='E';
   x_error := 'Error while sending mail '||SQLERRM;
END send_email;

/*******************************************************************************


*******************************************************************************/
PROCEDURE od_send_approval_mail(p_batch_ids IN NUMBER,p_sep IN VARCHAR2 DEFAULT ',')
IS

--l_batch_tab   g_batch_tab:=g_batch_tab();
lv_email_body VARCHAR2(4000) :='<p></p>';
lv_subject    VARCHAR2(400); 
lv_status     VARCHAR2(4000);
lv_error      VARCHAR2(4000);

CURSOR c_fetchemp_details(c_batch_id NUMBER) IS
    select papf.first_name||' '||papf.last_name employee_name,
           papf_sup.first_name||' '||papf_sup.last_name supervisor,
           papf.EMAIL_ADDRESS  employee_email,
           papf_sup.EMAIL_ADDRESS supvisor_email,
         papf.employee_number,
         fu.user_id,
         (select initcap(global_name) from global_name) DB_NAME
      from per_all_assignments_f paaf,per_all_people_f papf,per_all_people_f papf_sup,fnd_user fu
     where paaf.supervisor_id = papf_sup.person_id
       and papf.person_id = paaf.person_id
       and fu.employee_id=papf.person_id
       and sysdate between paaf.EFFECTIVE_START_DATE and paaf.EFFECTIVE_END_DATE
       and sysdate between papf.EFFECTIVE_START_DATE and papf.EFFECTIVE_END_DATE
       and sysdate between papf_sup.EFFECTIVE_START_DATE and papf_sup.EFFECTIVE_END_DATE
       and paaf.PRIMARY_FLAG = 'Y'
       and exists (select 1 from gl_je_headers
                    where STATUS     ='U'
                      AND JE_SOURCE IN ('Spreadsheet','Manual')
                      and created_by = fu.user_id
                      AND je_batch_id = c_batch_id
       );
       
CURSOR c_fetch_jdr_data(c_batch_id NUMBER,c_user_id NUMBER) IS
    SELECT gjh.RUNNING_TOTAL_DR,
           gjh.RUNNING_TOTAL_CR,
           gjb.name BATCH_NAME,
           gjh.created_by,
           gjh.NAME JOURNAL_NAME,
           gjh.description,
           gle.name ledger_name,
           gjh.CURRENCY_CODE,
           gjh.DATE_CREATED
     FROM gl_je_batches gjb,
         gl_je_headers gjh,
       gl_ledgers gle
    WHERE gjb.je_batch_id = gjh.je_batch_id
      AND gjh.STATUS     ='U'
      AND gjh.JE_SOURCE IN ('Spreadsheet','Manual')
      AND gle.ledger_id =gjh.ledger_id
      AND gjh.created_by =c_user_id
      AND gjh.je_batch_id =c_batch_id;

BEGIN

--   l_batch_tab:=convert_batches(p_batch_ids,p_sep);
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Start fetching data');
   FOR rec_fetchemp_details IN c_fetchemp_details(p_batch_ids) LOOP
      FOR rec_fetch_jdr_data IN c_fetch_jdr_data(p_batch_ids,rec_fetchemp_details.user_id) LOOP
         lv_subject :='Please Approve '||'&'||' Post '||rec_fetch_jdr_data.journal_name||'/'||rec_fetch_jdr_data.batch_name--||' – '||rec_fetch_jdr_data.description 
                      ||' in '||rec_fetchemp_details.db_name;
         lv_email_body:= lv_email_body||'Journal/Batch <B>'||rec_fetch_jdr_data.journal_name||'/'||rec_fetch_jdr_data.batch_name||' – '||rec_fetch_jdr_data.description
                         ||'</B> submitted by <B>'||rec_fetchemp_details.employee_name||'</B> on <B>'||rec_fetch_jdr_data.date_created||'</B> is awaiting your Review '||'&'||' Approval.'||chr(13);
      END LOOP;
      lv_email_body:= lv_email_body||chr(13)||'<p>To Approve:  Review '||'&'||' Post Journal/Batch in Oracle EBS in a timely manner. </p>'||chr(13)|| 
      '<p>To Reject:   Notify Accountant via this email to delete original Journal/Batch and resubmit with the correct support.</p>'||chr(13)||chr(13)||
      '<p></p><p>Thank you!</p>'; 

      Fnd_File.PUT_LINE (Fnd_File.LOG,'Calling Send_email procedure');
      send_email(rec_fetchemp_details.supvisor_email,
                 rec_fetchemp_details.employee_email,
                 lv_email_body,
                 lv_subject,
                 lv_status,
                 lv_error);
      IF lv_status != 'S' THEN
         Fnd_File.PUT_LINE (Fnd_File.LOG,'Erro while sending mail for employee '||rec_fetchemp_details.employee_name || ' Error: '||SQLERRM);
      ELSE
         Fnd_File.PUT_LINE (Fnd_File.LOG,'Email sent successfully');
      END IF;
   END LOOP;
EXCEPTION WHEN OTHERS THEN
   Fnd_File.PUT_LINE (Fnd_File.LOG,'Unexpected error while fetching batch ids '||SQLERRM);
END od_send_approval_mail;

END XX_GL_UNPOSTED_JRS;
/