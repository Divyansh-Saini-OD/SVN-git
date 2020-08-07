create or replace
PACKAGE BODY XX_COM_BATCH_ALERT AS
gc_volume_type   fnd_profile_option_values.profile_option_value%type     := FND_PROFILE.VALUE('OD_VOLUME_TYPE');
  PROCEDURE send_alert(x_errbuf                   OUT NOCOPY      VARCHAR2
                      ,x_retcode                  OUT NOCOPY      NUMBER
                      ,p_from_time                                VARCHAR2 
                      ,p_batch                                    VARCHAR2
                      ,p_pgm                                      VARCHAR2) AS
CURSOR failure_alert_email
IS
SELECT DISTINCT target_value11 email_id
      ,target_value10 alert_type
FROM xx_fin_translatedefinition    XFTD
    ,xx_fin_translatevalues       XFTV
WHERE   XFTV.translate_id     = XFTD.translate_id
AND     XFTD.translation_name = 'OD_BATCH_EVENT_ALERT'
AND     XFTV.enabled_flag     = 'Y'
AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND     XFTV.target_value10 <> 'NO'
AND     xftv.target_value3 = NVL(p_batch,xftv.target_value3)
AND     xftv.target_value1 = NVL(p_pgm,xftv.target_value1);
CURSOR long_run_alert_email
IS
SELECT DISTINCT target_value13 email_id
      ,target_value12 alert_type
FROM xx_fin_translatedefinition    XFTD
    ,xx_fin_translatevalues       XFTV
WHERE   XFTV.translate_id     = XFTD.translate_id
AND     XFTD.translation_name = 'OD_BATCH_EVENT_ALERT'
AND     XFTV.enabled_flag     = 'Y'
AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND     xftv.target_value3 = NVL(p_batch,xftv.target_value3)
AND     xftv.target_value1 = NVL(p_pgm,xftv.target_value1);
CURSOR long_run_programs(p_fail_alert_email varchar2
                      ,p_alert_type varchar2)
IS 
SELECT FCR.request_id           REQUEST_ID               
      ,FCP.user_concurrent_program_name  pgm_name
      ,FCR.actual_start_date                    START_DATE
       ,FCR.actual_completion_date               END_DATE
       ,FR.responsibility_name responsibility_name
       ,(NVL(FCR.actual_completion_date,SYSDATE)-FCR.actual_start_date)*24*60*60 dur_sec
       , NVL(gc_volume_type,xftv.target_value17)  volume_type
       ,xftv.target_value4 normal_duration
       ,xftv.target_value6 peak_duration
       ,xftv.target_value5 normal_threshold
       ,xftv.target_value7 peak_threshold
       ,xftv.target_value3 batch
       ,FLS.meaning STATUS_CODE
       ,FLP.meaning PHASE_CODE
FROM    xx_fin_translatedefinition       XFTD
       ,xx_fin_translatevalues           XFTV
       ,fnd_concurrent_requests          FCR
       ,fnd_concurrent_programs_vl       FCP
       ,fnd_responsibility_tl            FR
        ,fnd_lookups                      FLS
        ,fnd_lookups                      FLP
WHERE   XFTV.translate_id     = XFTD.translate_id
AND     XFTD.translation_name = 'OD_BATCH_EVENT_ALERT'
AND     XFTV.enabled_flag     = 'Y'
AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND     FCP.concurrent_program_id = fcr.concurrent_program_id
AND     FLS.lookup_type                   = 'CP_STATUS_CODE'
AND     FLS.lookup_code                   = FCR.status_code
AND     FLP.lookup_type                   = 'CP_PHASE_CODE'
AND     FLP.lookup_code                   = FCR.phase_code
AND     XFTV.target_value12 = p_alert_type
AND     XFTV.target_value13 = p_fail_alert_email
AND     FCP.concurrent_program_name = UPPER(target_value1)
AND     FCP.concurrent_program_id = FCR.concurrent_program_id
AND     xftv.target_value3 = NVL(p_batch,xftv.target_value3)
AND     xftv.target_value1 = NVL(p_pgm,xftv.target_value1)
AND     (NVL(FCR.actual_completion_date,SYSDATE)-FCR.actual_start_date)*24*60*60 > DECODE(NVL(gc_volume_type,xftv.target_value17)
                                                                                  ,'Normal',xftv.target_value5
                                                                                  ,'Peak',xftv.target_value7)
AND     FCR.PHASE_CODE <> 'C'
AND     FCR.responsibility_id         = FR.responsibility_id
AND     DECODE(SUBSTR(FR.responsibility_name,1,7)
                       ,'OD (US)',404
                       ,'OD (CA)',403
                       )  = FND_PROFILE.VALUE('ORG_ID')
AND     DECODE(XFTV.target_value2
              ,'US',404
              ,'CA',403)= FND_PROFILE.VALUE('ORG_ID');
CURSOR failure_progams(p_fail_alert_email varchar2
                      ,p_alert_type varchar2
                      ,p_prev_prog_start_time DATE
                      ,p_curr_prog_start_time DATE)
IS 
SELECT FCR.request_id           REQUEST_ID               
      ,FCR.status_code          STATUS_CODE
      ,FCP.user_concurrent_program_name  pgm_name
      ,FCR.actual_start_date                    START_DATE
       ,FCR.actual_completion_date               END_DATE
       ,FR.responsibility_name responsibility_name
       , xftv.target_value10  alert_type
       , xftv.target_value3  batch
FROM    xx_fin_translatedefinition       XFTD
       ,xx_fin_translatevalues           XFTV
       ,fnd_concurrent_requests          FCR
       ,fnd_concurrent_programs_vl       FCP
       ,fnd_responsibility_tl            FR
WHERE   XFTV.translate_id     = XFTD.translate_id
AND     XFTD.translation_name = 'OD_BATCH_EVENT_ALERT'
AND     XFTV.enabled_flag     = 'Y'
AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND     FCP.concurrent_program_id = fcr.concurrent_program_id
AND     XFTV.target_value10 = p_alert_type
AND     XFTV.target_value11 = p_fail_alert_email
AND     FCR.actual_completion_date > p_prev_prog_start_time
AND     FCR.actual_completion_date <= p_curr_prog_start_time
AND     FCP.concurrent_program_name = UPPER(target_value1)
AND     FCP.concurrent_program_id = FCR.concurrent_program_id
AND     xftv.target_value3 = NVL(p_batch,xftv.target_value3)
AND     xftv.target_value1 = NVL(p_pgm,xftv.target_value1)
AND     FCR.STATUS_CODE = 'E'
AND     FCR.responsibility_id         = FR.responsibility_id
AND     DECODE(SUBSTR(FR.responsibility_name,1,7)
                       ,'OD (US)',404
                       ,'OD (CA)',403
                       )  = FND_PROFILE.VALUE('ORG_ID')
AND     DECODE(XFTV.target_value2
              ,'US',404
              ,'CA',403)= FND_PROFILE.VALUE('ORG_ID');
ld_curr_start_time DATE;
ld_prev_start_time DATE;
lc_html_file VARCHAR2(4000);
lc_mail_id_file VARCHAR2(4000);
lc_attach_file VARCHAR2(4000);
ln_org_id NUMBER;
lt_file_html              UTL_FILE.FILE_TYPE;
lt_file_mail_id           UTL_FILE.FILE_TYPE;
lt_file_attachment        UTL_FILE.FILE_TYPE;
ln_master_request_id      NUMBER       := fnd_profile.value('CONC_REQUEST_ID');
lc_color VARCHAR2(4000);
lc_db_name VARCHAR2(4000);
lc_directory_path                VARCHAR2(400);
ln_conc_request_id NUMBER;
v_req_data   VARCHAR2(400);
lc_subject   VARCHAR2(4000);

ld_from_time  DATE:= to_date(p_from_time,'YYYY/MM/DD HH24:MI:SS'); ---2010/07/12 12:00:00
  BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_from_time' ||ld_from_time); 
     v_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
          SELECT sys_context('USERENV','DB_NAME')
          INTO lc_db_name
          FROM dual;
     IF ( NVL(v_req_data, 'FIRST') = 'FIRST') THEN
     BEGIN
     ln_org_id := FND_PROFILE.VALUE('ORG_ID');
     FND_FILE.PUT_LINE(FND_FILE.LOG,'org id ' ||ln_org_id);     
     SELECT actual_start_date
     INTO ld_curr_start_time
     FROM fnd_concurrent_requests 
     WHERE request_id = FND_GLOBAL.CONC_REQUEST_ID;
     SELECT to_date(target_value1,'DD-MON-YYYY HH24:MI:SS')
     INTO ld_prev_start_time
     FROM   xx_fin_translatedefinition       XFTD
           ,xx_fin_translatevalues           XFTV 
     WHERE   XFTV.translate_id     = XFTD.translate_id
     AND     XFTD.translation_name = 'OD_MONITOR_PROG_TIMES'
     AND    XFTV.target_value3=ln_org_id;
     UPDATE xx_fin_translatevalues xft
     SET xft.target_value1 = to_char(ld_curr_start_time,'DD-MON-YYYY HH24:MI:SS')
     where xft.translate_value_id = (SELECT xftv.translate_value_id FROM   xx_fin_translatedefinition       XFTD
           ,xx_fin_translatevalues           XFTV 
     WHERE   XFTV.translate_id     = XFTD.translate_id
     AND     XFTD.translation_name = 'OD_MONITOR_PROG_TIMES'
     AND    XFTV.target_value3=ln_org_id);
     FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_prev_start_time '||to_char(ld_prev_start_time,'DD-MON-YYYY HH24:MI:SS'));
     FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_curr_start_time '||to_char(ld_curr_start_time,'DD-MON-YYYY HH24:MI:SS'));
     FOR email IN failure_alert_email
     LOOP
      FND_FILE.PUT_LINE(FND_FILE.LOG,'email ID '||email.email_id);
        lc_html_file         := ln_master_request_id||email.email_id||'_HTML'||'.html';
          lc_mail_id_file      := ln_master_request_id||email.email_id||'_MAIL_ID'||'.txt';
          lc_attach_file       := ln_master_request_id||email.email_id||'_ATTACH'||'.txt';
          --Opening the HTML, attachment and mail id files
          lt_file_html         := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
          lt_file_mail_id      := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
          lt_file_attachment   := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');
          lc_color := '<td bgColor="red"><font size="1"> ';
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin Writing html file');
           UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                                        || '<P><B><FONT FACE="Verdana" SIZE="4" color="#336899"><center> Job Failures </center><HR></B></P>'
                                        || '<table cellPadding="3" border="1"> <tbody> <tr>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">INSTANCE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">REQ ID</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Org</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Batch</font></b></th>');
         UTL_FILE.PUT_LINE(lt_file_html, '<th bgColor="#cccc99"><b><font color="#336699" size="1">PROGRAM NAME</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">START DATE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">END DATE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">PHASE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">STATUS</font></b></th>'
                                        || '</tr>'
                                        );   
FND_FILE.PUT_LINE(FND_FILE.LOG,'End Writing html file');                                        
        FOR pgm_details in failure_progams(email.email_id
                                          ,email.alert_type
                                          ,GREATEST(ld_prev_start_time,ld_from_time)
                                          ,ld_curr_start_time
                                          )
          LOOP
             FND_FILE.PUT_LINE(FND_FILE.LOG,'req_id '||pgm_details.REQUEST_ID);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'pgm '||pgm_details.pgm_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'START_DATE '||pgm_details.START_DATE);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'END_DATE '||pgm_details.END_DATE);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'FR.responsibility_name '||pgm_details.responsibility_name); 
                      UTL_FILE.PUT_LINE(lt_file_html,'<tr>'
                                        ||lc_color|| lc_db_name || '</font></td>'
                                        ||lc_color|| pgm_details.REQUEST_ID || '</font></td>'
                                        ||lc_color|| (SUBSTR(pgm_details.responsibility_name,5,2))|| '</font></td>'
                                        ||lc_color|| pgm_details.batch || '</font></td>'
                                        ||lc_color|| pgm_details.pgm_name || '</font></td>'
                                        ||lc_color|| TO_CHAR(pgm_details.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| TO_CHAR(pgm_details.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| 'Completed'|| '</font></td>'
                                        ||lc_color|| 'Error'|| '</font></td>'
                                        );
         END LOOP;
          UTL_FILE.PUT_LINE(lt_file_html,'</table>'); 
          -- Print_Batch_Param;
             --Write the mail ids in the mail file
             UTL_FILE.PUT_LINE(lt_file_mail_id,email.email_id);
             UTL_FILE.fclose(lt_file_mail_id);
             UTL_FILE.fclose(lt_file_html);
             UTL_FILE.fclose(lt_file_attachment);
             BEGIN
                SELECT directory_path
                INTO lc_directory_path
                FROM dba_directories
                WHERE directory_name = 'XXFIN_OUTBOUND';
                IF (email.alert_type = 'PAGE') THEN
                 lc_subject := '***page*** '||'Failure Alert -  As of: '|| to_char(Sysdate,'DD-MON-YYYY HH24:MI');
                ELSE
                 lc_subject := 'Failure Alert -  As of: '|| to_char(Sysdate,'DD-MON-YYYY HH24:MI');
                END IF;
                --Call the shell script program to send the mail with attachment.
                ln_conc_request_id := fnd_request.submit_request ('XXCOMN'
                                                                  ,'XXCOMHTMLMAIL'
                                                                  ,''
                                                                  ,''
                                                                  ,TRUE
                                                                  ,lc_directory_path||'/'||lc_mail_id_file
                                                                  , lc_subject
                                                                  ,'Concurrent_request_status_mailer'
                                                                  ,lc_directory_path||'/'||lc_html_file
                                                                  ,lc_directory_path||'/'||lc_attach_file
                                                                  ,99999999999
                                                                  );
                COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);
             END;
      END LOOP;
             fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                             ,request_data => 'OVER');
          EXCEPTION
          WHEN others THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is:' || SQLERRM);
             RAISE;
          END;
       END IF;      
 ------ long running alert -----
IF ( NVL(v_req_data, 'FIRST') = 'OVER') THEN
    BEGIN
     FOR email IN long_run_alert_email
     LOOP
      FND_FILE.PUT_LINE(FND_FILE.LOG,'email ID '||email.email_id);
        lc_html_file         := ln_master_request_id||email.email_id||'_HTML'||'.html';
          lc_mail_id_file      := ln_master_request_id||email.email_id||'_MAIL_ID'||'.txt';
          lc_attach_file       := ln_master_request_id||email.email_id||'_ATTACH'||'.txt';
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Opeing file in long');
          --Opening the HTML, attachment and mail id files
          lt_file_html       := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
          lt_file_mail_id    := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
          lt_file_attachment   := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');
          lc_color := '<td bgColor="green"><font size="1"> ';
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'write file in long');
           UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                                        || '<P><B><FONT FACE="Verdana" SIZE="4" color="#336899" ><center>Long Running Requests</center> <HR></B></P>'
                                        || '<table cellPadding="3" border="1"> <tbody> <tr>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">INSTANCE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">REQ ID</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Org</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Batch</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">PROGRAM NAME</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">START DATE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">END DATE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">PHASE</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">STATUS</font></b></th>');
              UTL_FILE.PUT_LINE(lt_file_html,'<th bgColor="#cccc99"><b><font color="#336699" size="1">Run Time (Sec)</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Volume Type</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Average Runtime (Sec)</font></b></th>'
                                        || '<th bgColor="#cccc99"><b><font color="#336699" size="1">Threshold Runtime (Sec)</font></b></th>'
                                        || '</tr>'
                                        );           
        FOR pgm_details in long_run_programs(email.email_id
                                          ,email.alert_type
                                          )
          LOOP
             FND_FILE.PUT_LINE(FND_FILE.LOG,'req_id '||pgm_details.REQUEST_ID);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'pgm '||pgm_details.pgm_name);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'START_DATE '||pgm_details.START_DATE);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'END_DATE '||pgm_details.END_DATE);
             FND_FILE.PUT_LINE(FND_FILE.LOG,'FR.responsibility_name '||pgm_details.responsibility_name); 
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'write file in long 2');
                      UTL_FILE.PUT_LINE(lt_file_html,'<tr>'
                                        ||lc_color|| lc_db_name || '</font></td>'
                                        ||lc_color|| pgm_details.REQUEST_ID || '</font></td>'
                                        ||lc_color|| (SUBSTR(pgm_details.responsibility_name,5,2))|| '</font></td>'
                                        ||lc_color|| pgm_details.batch || '</font></td>'
                                        ||lc_color|| pgm_details.pgm_name || '</font></td>'
                                        ||lc_color|| TO_CHAR(pgm_details.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| TO_CHAR(pgm_details.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| pgm_details.PHASE_CODE|| '</font></td>'
                                        ||lc_color|| pgm_details.STATUS_CODE|| '</font></td>'
                                        ||'<td bgColor="yellow"><font size="1">' || pgm_details.dur_sec|| '</font></td>'
                                        ||lc_color|| pgm_details.volume_type|| '</font></td>'
                                        );
               FND_FILE.PUT_LINE(FND_FILE.LOG,'write file in long 3');
               IF (pgm_details.volume_type = 'Normal') THEN  
               UTL_FILE.PUT_LINE(lt_file_html,lc_color|| pgm_details.normal_duration|| '</font></td>'
                                 ||lc_color|| pgm_details.normal_threshold|| '</font></td>'
                                 );
                ELSE
                 UTL_FILE.PUT_LINE(lt_file_html,lc_color|| pgm_details.Peak_duration|| '</font></td>'
                                 ||lc_color|| pgm_details.peak_threshold|| '</font></td>'
                                 );
                END IF;
         END LOOP;
          UTL_FILE.PUT_LINE(lt_file_html,'</table>'); 
            -- Print_Batch_Param;
             --Write the mail ids in the mail file
             UTL_FILE.PUT_LINE(lt_file_mail_id,email.email_id);
             UTL_FILE.fclose(lt_file_mail_id);
             UTL_FILE.fclose(lt_file_html);
             UTL_FILE.fclose(lt_file_attachment);
             BEGIN
                SELECT directory_path
                INTO lc_directory_path
                FROM dba_directories
                WHERE directory_name = 'XXFIN_OUTBOUND';
                IF (email.alert_type = 'PAGE') THEN
                 lc_subject := '***page*** '||'Long running request Alert - As of: ' || to_char(Sysdate,'DD-MON-YYYY HH24:MI');
                ELSE
                 lc_subject := 'Long running request Alert - As of: ' || to_char(Sysdate,'DD-MON-YYYY HH24:MI');
                END IF;
                --Call the shell script program to send the mail with attachment.
                ln_conc_request_id := fnd_request.submit_request ('XXCOMN'
                                                                  ,'XXCOMHTMLMAIL'
                                                                  ,''
                                                                  ,''
                                                                  ,TRUE
                                                                  ,lc_directory_path||'/'||lc_mail_id_file
                                                                  , lc_subject
                                                                  ,'Concurrent_request_status_mailer'
                                                                  ,lc_directory_path||'/'||lc_html_file
                                                                  ,lc_directory_path||'/'||lc_attach_file
                                                                  ,99999999999
                                                                  );
                COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);
             END;
      END LOOP;
 ------ long running alert ------
      /* TODO implementation required */
    NULL;
             fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                             ,request_data => 'OVER2');
          EXCEPTION
          WHEN others THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is:' || SQLERRM);
          END;
       END IF;
  END send_alert;
END XX_COM_BATCH_ALERT;
/