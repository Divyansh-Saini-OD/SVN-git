create or replace
PACKAGE BODY XX_FIN_EMAIL_ALERT_PKG
 AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_FIN_HTTP_PKG                                           |
-- | Description      :  This PKG will be used to fetch the concurrent |
-- |                     program details                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 11-SEP-2008  Gokila           Initial draft version       |
-- +===================================================================+ 
 
 PROCEDURE EMAIL_ALERT(x_error_buff               OUT  VARCHAR2
                       ,x_ret_code                OUT  NUMBER
                       ,p_prog_appn               IN   VARCHAR2
                       ,p_hour_detail             IN   NUMBER
                       ,p_mail_group              IN   VARCHAR2
                       ,p_log_file                IN   VARCHAR2
                       ,p_output_file             IN   VARCHAR2
                       ,p_hour_default            IN   NUMBER
                       ,p_log_file_default        IN   VARCHAR2
                       ,p_output_file_default     IN   VARCHAR2
                       )
 AS

 lt_file_html             UTL_FILE.FILE_TYPE;
 lt_file_mail_id          UTL_FILE.FILE_TYPE;
 lt_file_attachment       UTL_FILE.FILE_TYPE;
 lc_html_file             VARCHAR2(50);
 lc_mail_id_file          VARCHAR2(50);
 lc_attach_file           VARCHAR2(50);
 lc_sysdate               VARCHAR2(25);
 lc_db_name               VARCHAR2(25);
 lc_mail_id1              VARCHAR2(4000);
 lc_mail_id2              VARCHAR2(4000);
 lc_mail_id3              VARCHAR2(4000);
 lc_mail_id4              VARCHAR2(4000);
 lc_mail_id5              VARCHAR2(4000);
 lc_mail_id6              VARCHAR2(4000);
 lc_log_flag              VARCHAR2(5) := 'No';
 lc_out_flag              VARCHAR2(5) := 'No';
 ld_sysdate               DATE;
 ln_master_request_id     NUMBER       := fnd_profile.value('CONC_REQUEST_ID');
 lc_recepient_address     VARCHAR2(500);
 lc_directory_path        VARCHAR2(100);
 ln_conc_request_id       NUMBER;
 EX_PARAMETER_VALUE       EXCEPTION;
 ld_from_date             DATE;
 ln_pgm_name_appln_delimit NUMBER;
 lc_conc_pgm_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE;
 lc_conc_pgm_appln_name   fnd_application.application_short_name%TYPE;
 v_req_data               VARCHAR2(4000);
 ln_count_loop1           NUMBER  := 0;
 ln_count_loop2           NUMBER;


 CURSOR lcu_conc_pgm_detail(p_pgm_name VARCHAR2, p_appln_name VARCHAR2, p_date DATE)
 IS
 SELECT  XFTV.source_value1                       CP_SHORT_NAME
        ,XFTV.source_value2                      CP_NAME
        ,NVL(p_log_file,NVL(XFTV.target_value1,p_log_file_default)) LOG_FILE
        ,NVL(p_output_file,NVL(XFTV.target_value2,p_output_file_default)) OUTPUT_FILE
        ,NVL(p_hour_detail,NVL(XFTV.target_value3,p_hour_default))  HOURS
        ,XFTV.target_value4                      EMAIL_1
        ,XFTV.target_value5                      EMAIL_2
        ,XFTV.target_value6                      EMAIL_3
        ,XFTV.target_value7                      EMAIL_4
        ,XFTV.target_value8                      EMAIL_5
        ,XFTV.target_value9                      EMAIL_6
        ,FCP.concurrent_program_id               CONC_PGM_ID
        ,FA.application_id                       APPLN_ID
 FROM xx_fin_translatedefinition        XFTD
      ,xx_fin_translatevalues           XFTV
      ,fnd_concurrent_programs          FCP
      ,fnd_application                  FA
 WHERE XFTD.translate_id                 = XFTV.translate_id
 AND   XFTD.translation_name             = 'OD_MONITORED_PROGRAMS'
 AND   XFTV.source_value1                = NVL(p_pgm_name ,XFTV.source_value1)
 AND   XFTV.source_value3                = NVL(p_appln_name ,XFTV.source_value3)
AND XFTV.enabled_flag = 'Y'
AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND FCP.concurrent_program_name = XFTV.source_value1
AND FA.application_short_name = XFTV.source_value3;

 CURSOR lcu_conc_req_detail(p_conc_pgm_id NUMBER, p_application_id NUMBER, p_date_from DATE ,p_date_to DATE)
 IS
 SELECT FCR.request_id                           CONC_REQ_ID
        ,FCR.actual_start_date                   START_DATE
        ,FCR.actual_completion_date              END_DATE
        ,FCR.phase_code                          PHASE_CODE
        ,DECODE(SUBSTR(FR.responsibility_name,1,7), 'OD (US)', 'US', 'OD (CA)', 'Canada','Other') COUNTRY
        ,FLS.meaning                             STATUS
        ,FLP.meaning                             PHASE
        ,FCR.logfile_name                        LOGFILE_NAME
        ,FCR.outfile_name                        OUTFILE_NAME
 FROM fnd_concurrent_requests           FCR
      ,fnd_responsibility_tl            FR
      ,fnd_lookups                      FLS
      ,fnd_lookups                      FLP
 WHERE FCR.concurrent_program_id = p_conc_pgm_id
 AND   FCR.program_application_id = p_application_id
 AND  FCR.responsibility_id = FR.responsibility_id
 AND  ( (FCR.actual_completion_date BETWEEN p_date_from AND p_date_to)
                 OR (FCR.phase_code != 'C'))
 AND  FLS.lookup_type = 'CP_STATUS_CODE'
 AND  FLS.lookup_code = FCR.status_code
 AND  FLP.lookup_type = 'CP_PHASE_CODE'
 AND  FLP.lookup_code = FCR.phase_code;

 BEGIN

    v_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

    IF ( NVL(v_req_data, 'FIRST') = 'FIRST') THEN

       SELECT sys_context('USERENV','DB_NAME')
       INTO lc_db_name
       FROM dual;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Database Name :'||lc_db_name);

       ld_sysdate := SYSDATE;
       lc_sysdate := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Date :'||ld_sysdate);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Date :'||lc_sysdate);

    BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'BEGIN');

       ln_pgm_name_appln_delimit := instr(p_prog_appn, ';', -1, 1);
       lc_conc_pgm_short_name := substr(p_prog_appn,1,ln_pgm_name_appln_delimit-1);
       lc_conc_pgm_appln_name := substr(p_prog_appn,ln_pgm_name_appln_delimit+1);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Program Short Name: '||lc_conc_pgm_short_name);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Application Short Name: '||lc_conc_pgm_appln_name);

       FOR lr_conc_pgm_detail IN lcu_conc_pgm_detail(lc_conc_pgm_short_name, lc_conc_pgm_appln_name, ld_sysdate)
       LOOP
           ln_count_loop1 := ln_count_loop1 + 1;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Opened first Loop');
           BEGIN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Creating File');
                lc_html_file         := lr_conc_pgm_detail.cp_short_name||'_HTML_'||ln_master_request_id||'.html';
                lc_mail_id_file      := lr_conc_pgm_detail.cp_short_name||'_MAIL_ID_'||ln_master_request_id||'.txt';
                lc_attach_file       := lr_conc_pgm_detail.cp_short_name||'_ATTACH_'||ln_master_request_id||'.txt';
                lt_file_html := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
                lt_file_mail_id := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
                lt_file_attachment  := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');
                FND_FILE.PUT_LINE(FND_FILE.LOG,'File Created');
             EXCEPTION
             WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file. '|| SQLERRM);
             END;
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Finished');
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Conc Program Shor Name: '||lr_conc_pgm_detail.cp_short_name);
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Conc Program ID: '||lr_conc_pgm_detail.conc_pgm_id);
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Conc Program Appln ID: '||lr_conc_pgm_detail.appln_id);
          --FND_FILE.PUT_LINE(FND_FILE.LOG,lr_conc_pgm_detail.hours);
          --FND_FILE.PUT_LINE(FND_FILE.LOG,lc_sysdate);
          ld_from_date := (ld_sysdate-lr_conc_pgm_detail.hours/24);
          ln_count_loop2 := 0;
         FOR lr_conc_req_detail IN lcu_conc_req_detail(lr_conc_pgm_detail.conc_pgm_id
                                                                ,lr_conc_pgm_detail.appln_id
                                                        ,ld_from_date
                                                        ,ld_sysdate)
          LOOP
             IF ln_count_loop2 = 0 THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Write HTML tags in file');
                UTL_FILE.PUT_LINE(lt_file_html,'<HTML><BODY>'
                                  || '<P><B><FONT FACE="Verdana" SIZE="1" color="#336899"><HR></B></P>'
                                  || '<table cellPadding="3" border="1"> <tbody> <tr>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">INSTANCE</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">REQ ID</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">COUNTRY</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">PROGRAM NAME</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">START DATE</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">END DATE</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">PHASE</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">STATUS</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">LOG FILE SENT</font></b></th>'
                                  || '<th bgColor="#cccc99"><b><font color="#336699" size="1">OUT FILE SENT</font></b></th>'
                                  || '</tr>'
                                  );
             END IF;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Opened second Loop');
             --FND_FILE.PUT_LINE(FND_FILE.LOG,' ID            : ' || lr_conc_req_detail.conc_req_id );
             --FND_FILE.PUT_LINE(FND_FILE.LOG,' Country       : ' || lr_conc_req_detail.country);
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Name          : ' || lr_conc_pgm_detail.cp_name);
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Start Date    : ' || lr_conc_req_detail.start_date );
             FND_FILE.PUT_LINE(FND_FILE.LOG,' End Date      : ' || lr_conc_req_detail.end_date );
             FND_FILE.PUT_LINE(FND_FILE.LOG,' End Date      : ' || lr_conc_req_detail.phase );
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Status        : ' || lr_conc_req_detail.status );
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Log File      : ' || lr_conc_pgm_detail.log_file );
             FND_FILE.PUT_LINE(FND_FILE.LOG,' Output File   : ' || lr_conc_pgm_detail.output_file );

             IF lr_conc_req_detail.phase_code = 'C' THEN
                IF lr_conc_pgm_detail.LOG_FILE = 'ERROR' AND lr_conc_req_detail.STATUS = 'Error' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                   lc_log_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.LOG_FILE = 'WARNING' AND lr_conc_req_detail.STATUS = 'Warning' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                   lc_log_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.LOG_FILE = 'NORMAL' AND lr_conc_req_detail.STATUS = 'Normal' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                   lc_log_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.LOG_FILE = 'ALL' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                   lc_log_flag := 'Yes';
                END IF;
                IF lr_conc_pgm_detail.OUTPUT_FILE = 'ERROR' AND lr_conc_req_detail.STATUS = 'Error' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                   lc_out_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.OUTPUT_FILE = 'WARNING' AND lr_conc_req_detail.STATUS = 'Warning' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                   lc_out_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.OUTPUT_FILE = 'NORMAL' AND lr_conc_req_detail.STATUS = 'Normal' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                   lc_out_flag := 'Yes';
                ELSIF lr_conc_pgm_detail.OUTPUT_FILE = 'ALL' THEN
                   UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                   lc_out_flag := 'Yes';
                END IF;

             END IF;
             BEGIN
                UTL_FILE.PUT_LINE(lt_file_html,'<tr><td bgColor="#f7f7e7"><font size="1"> '
                                  || lc_db_name || '</font></td>'
                                  || '<td bgColor="#f7f7e7"><font size="1"> '
                                  || lr_conc_req_detail.CONC_REQ_ID || '</font></td>'
                                  || '<td bgColor="#f7f7e7"><font size="1"> '
                                  || lr_conc_req_detail.COUNTRY || '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || lr_conc_pgm_detail.CP_NAME || '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || TO_CHAR(lr_conc_req_detail.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || TO_CHAR(lr_conc_req_detail.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || lr_conc_req_detail.phase|| '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || lr_conc_req_detail.status|| '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || lc_log_flag|| '</font></td>'
                                  ||'<td bgColor="#f7f7e7"><font size="1"> '
                                  || lc_out_flag  || '</font></td></tr>'
                                  );
             EXCEPTION
             WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE(SQLERRM);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
             END;
             lc_log_flag := 'No';
             lc_out_flag := 'No';
             ln_count_loop2 := ln_count_loop2+1;
         END LOOP;
                IF ln_count_loop2 = 0 THEN
                 UTL_FILE.PUT_LINE(lt_file_html,'<html><body><font size="4"  align="center"> <b>No Requests submitted for the given concurrent Program  for the Date range specified in subject line.</b></font></body></html>');
              ELSE
          UTL_FILE.PUT_LINE(lt_file_html,'</tbody></table></FONT></B></P> </BODY> </HTML>');
        END IF;
       --   IF p_program_name = 'DEFAULT' THEN
             lc_recepient_address := lr_conc_pgm_detail.email_1||' '||lr_conc_pgm_detail.email_2||' '
                                     ||lr_conc_pgm_detail.email_3||' '||lr_conc_pgm_detail.email_4||' '
                                     ||lr_conc_pgm_detail.email_5||' '||lr_conc_pgm_detail.email_6;
             UTL_FILE.PUT_LINE(lt_file_mail_id,lc_recepient_address);
             UTL_FILE.fclose(lt_file_mail_id);

          UTL_FILE.fclose(lt_file_html);
          UTL_FILE.fclose(lt_file_attachment);
          BEGIN
             SELECT directory_path
             INTO lc_directory_path
             FROM dba_directories
             WHERE directory_name = 'XXFIN_OUTBOUND';
             ln_conc_request_id := fnd_request.submit_request ('XXFIN'
                                                               ,'XX_OD_HTML_MAILER'
                                                               ,''
                                                               ,''
                                                               ,TRUE
                                                               ,lc_directory_path||'/'||lc_mail_id_file
                                                               , lr_conc_pgm_detail.CP_NAME||' Details. Program submission time From '||TO_CHAR(ld_from_date,'DD-MON-YYYY HH24:MI:SS')||' To  '||TO_CHAR(ld_sysdate,'DD-MON-YYYY HH24:MI:SS')
                                                               ,'Concurrent request status mailer'
                                                               ,lc_directory_path||'/'||lc_html_file
                                                               ,lc_directory_path||'/'||lc_attach_file
                                                               ,100
                                                               );
             COMMIT;
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);
          END;
        END LOOP;
      -- END LOOP;
            IF ln_count_loop1 > 0 THEN
               fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                               ,request_data => 'OVER');
             END IF;

       EXCEPTION
       WHEN EX_PARAMETER_VALUE THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Please Enter all the parameter Values');
          x_ret_code := 0;
       WHEN others THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is:' || SQLERRM);
       END;
       END IF;
 END;
 END XX_FIN_EMAIL_ALERT_PKG;
/