SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating Package Body XX_COM_MONITOR_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_COM_MONITOR_PKG
 AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_COM_MONITOR_PKG                                        |
-- | Description      :  This PKG will be used to fetch the concurrent |
-- |                     program details                               |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 11-SEP-2008  Gokila           Initial draft version       |
-- |DRAFT 1B 16-SEP-2008  Gokila           Added new procedure         |
-- |                                       REQUESTOR_EMAIL_ALERT to    |
-- |                                       fetch the concurrent request|
-- |                                       submitted by the requestor. |
-- |DRAFT 1C 22-SEP-2008  Gokila           1.Added mail group parameter|
-- |                                       to send mail to the         |
-- |                                       particular mail group       |
-- |                                       selected.                   |
-- |                                       2.Added condition to display|
-- |                                       the row in different colors |
-- |                                       according to the status of  |
-- |                                       the program.                |
-- |                                       3.Added ORDER BY caluse in  |
-- |                                       in all the cursor query     |
-- +===================================================================+
-- +===================================================================+
-- | Name : EMAIL_ALERT                                                |
-- | Description : Procedure to fetch the records matching the given   |
-- |               conditions and call the mailer                      |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: Email Program Alert                                 |
-- |                                                                   |
-- | Parameters : x_error_buff                                         |
-- |              x_ret_code                                           |
-- |              p_prog_appn                                          |
-- |              p_hour_detail                                        |
-- |              p_mail_group                                         |
-- |              p_log_file                                           |
-- |              p_output_file                                        |
-- |              p_hour_default                                       |
-- |              p_log_file_default                                   |
-- |              p_output_file_default                                |
-- +===================================================================+
    PROCEDURE EMAIL_ALERT( x_error_buff              OUT  VARCHAR2
                          ,x_ret_code                OUT  NUMBER
                          ,p_prog_appn               IN   VARCHAR2
                          ,p_hour_detail             IN   NUMBER
                          ,p_mail_group              IN   VARCHAR2
                          ,p_log_file                IN   VARCHAR2
                          ,p_output_file             IN   VARCHAR2
                          ,p_hour_default            IN   NUMBER
                          ,p_log_file_default        IN   VARCHAR2
                          ,p_output_file_default     IN   VARCHAR2
                          ,p_attachment_size         IN   NUMBER
                          )
    AS
        lt_file_html              UTL_FILE.FILE_TYPE;
        lt_file_mail_id           UTL_FILE.FILE_TYPE;
        lt_file_attachment        UTL_FILE.FILE_TYPE;
        lc_html_file              VARCHAR2(200);
        lc_mail_id_file           VARCHAR2(200);
        lc_attach_file            VARCHAR2(200);
        lc_sysdate                VARCHAR2(25);
        lc_db_name                VARCHAR2(200);
        lc_mail_id1               VARCHAR2(4000);
        lc_mail_id2               VARCHAR2(4000);
        lc_mail_id3               VARCHAR2(4000);
        lc_mail_id4               VARCHAR2(4000);
        lc_mail_id5               VARCHAR2(4000);
        lc_mail_id6               VARCHAR2(4000);
        lc_log_flag               VARCHAR2(5) := 'No';
        lc_out_flag               VARCHAR2(5) := 'No';
        ld_sysdate                DATE;
        ln_master_request_id      NUMBER       := fnd_profile.value('CONC_REQUEST_ID');
        lc_recepient_address      VARCHAR2(4000);
        lc_directory_path         VARCHAR2(400);
        ln_conc_request_id        NUMBER;
        ld_from_date              DATE;
        ln_pgm_name_appln_delimit NUMBER;
        lc_conc_pgm_short_name    fnd_concurrent_programs.concurrent_program_name%TYPE;
        lc_conc_pgm_appln_name    fnd_application.application_short_name%TYPE;
        v_req_data                VARCHAR2(4000);
        ln_count_loop1            NUMBER  := 0;
        ln_count_loop2            NUMBER;
        lc_color                  VARCHAR2(4000);

        CURSOR lcu_conc_pgm_detail(p_pgm_name VARCHAR2, p_appln_name VARCHAR2, p_date DATE)
        IS
        SELECT  XFTV.source_value1                      CP_SHORT_NAME
               ,XFTV.source_value2                      CP_NAME
               ,NVL(p_log_file,NVL(XFTV.target_value1,p_log_file_default))       LOG_FILE
               ,NVL(p_output_file,NVL(XFTV.target_value2,p_output_file_default)) OUTPUT_FILE
               ,NVL(p_hour_detail,NVL(XFTV.target_value3,p_hour_default))        HOURS
               ,XFTV.target_value4                      EMAIL_1
               ,XFTV.target_value5                      EMAIL_2
               ,XFTV.target_value6                      EMAIL_3
               ,XFTV.target_value7                      EMAIL_4
               ,XFTV.target_value8                      EMAIL_5
               ,XFTV.target_value9                      EMAIL_6
               ,FCP.concurrent_program_id               CONC_PGM_ID
               ,FA.application_id                       APPLN_ID
        FROM    xx_fin_translatedefinition        XFTD
               ,xx_fin_translatevalues           XFTV
               ,fnd_concurrent_programs          FCP
               ,fnd_application                  FA
        WHERE  XFTD.translate_id                 = XFTV.translate_id
        AND    XFTD.translation_name             = 'OD_MONITORED_PROGRAMS'
        AND    UPPER(XFTV.source_value1)         = NVL(p_pgm_name , UPPER(XFTV.source_value1))
        AND    UPPER(XFTV.source_value3)         = NVL(p_appln_name , UPPER(XFTV.source_value3))
        AND    XFTV.enabled_flag                 = 'Y'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    FCP.concurrent_program_name       = UPPER(XFTV.source_value1)
        AND    FA.application_short_name         = UPPER(XFTV.source_value3);

        CURSOR lcu_conc_req_detail(p_conc_pgm_id NUMBER, p_application_id NUMBER, p_date_from DATE ,p_date_to DATE)
        IS
        SELECT  FCR.request_id                          CONC_REQ_ID
               ,FCR.actual_start_date                   START_DATE
               ,FCR.actual_completion_date              END_DATE
               ,FCR.phase_code                          PHASE_CODE
               ,DECODE(SUBSTR(FR.responsibility_name,1,7)
                       ,'OD (US)','US'
                       ,'OD (CA)','Canada'
                       ,'Other'
                       )                                COUNTRY
               ,FLS.meaning                             STATUS
               ,FLP.meaning                             PHASE
               ,FCR.logfile_name                        LOGFILE_NAME
               ,FCR.outfile_name                        OUTFILE_NAME
        FROM    fnd_concurrent_requests           FCR
               ,fnd_responsibility_tl            FR
               ,fnd_lookups                      FLS
               ,fnd_lookups                      FLP
        WHERE   FCR.concurrent_program_id     = p_conc_pgm_id
        AND     FCR.program_application_id    = p_application_id
        AND     FCR.responsibility_id         = FR.responsibility_id
        AND     ((FCR.actual_completion_date BETWEEN p_date_from AND p_date_to)
                 OR (FCR.phase_code != 'C'))
        AND     FLS.lookup_type                = 'CP_STATUS_CODE'
        AND     FLS.lookup_code                = FCR.status_code
        AND     FLP.lookup_type                = 'CP_PHASE_CODE'
        AND     FLP.lookup_code                = FCR.phase_code
        ORDER BY FCR.request_id;

    BEGIN
        v_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

        IF ( NVL(v_req_data, 'FIRST') = 'FIRST') THEN

           --Query to fetch the instance name
           SELECT sys_context('USERENV','DB_NAME')
           INTO   lc_db_name
           FROM   dual;

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Database Name :'||lc_db_name);
           ld_sysdate := SYSDATE;
           lc_sysdate := TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS');

           BEGIN
              ln_pgm_name_appln_delimit := INSTR(p_prog_appn, ';', -1, 1);
              lc_conc_pgm_short_name    := SUBSTR(p_prog_appn,1,ln_pgm_name_appln_delimit-1);
              lc_conc_pgm_appln_name    := SUBSTR(p_prog_appn,ln_pgm_name_appln_delimit+1);

              FND_FILE.PUT_LINE(FND_FILE.LOG,'Program Short Name: '||lc_conc_pgm_short_name);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Application Short Name: '||lc_conc_pgm_appln_name);

              IF p_mail_group IS NOT NULL THEN

                 --Query to fetch the mail ids if p_mail_group parameter is passed.
                 SELECT  XFTV.target_value1
                        ,XFTV.target_value2
                        ,XFTV.target_value3
                        ,XFTV.target_value4
                        ,XFTV.target_value5
                        ,XFTV.target_value6
                 INTO    lc_mail_id1
                        ,lc_mail_id2
                        ,lc_mail_id3
                        ,lc_mail_id4
                        ,lc_mail_id5
                        ,lc_mail_id6
                 FROM    xx_fin_translatedefinition   XFTD
                        ,xx_fin_translatevalues       XFTV
                 WHERE   XFTD.translate_id      = XFTV.translate_id
                 AND     XFTD.translation_name  = 'OD_MAIL_GROUPS'
                 AND     XFTV.source_value1     = p_mail_group
                 AND     XFTV.enabled_flag      = 'Y'
                 AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                 AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1);

                 lc_recepient_address := lc_mail_id1||' '||lc_mail_id2||' '||lc_mail_id3||' '||lc_mail_id4
                                         ||' '||lc_mail_id5||' '||lc_mail_id6;
              END IF;

              --Opening the concurrent program details cursor
              FOR lr_conc_pgm_detail IN lcu_conc_pgm_detail( lc_conc_pgm_short_name
                                                            ,lc_conc_pgm_appln_name
                                                            ,ld_sysdate
                                                            )
              LOOP
                 ln_count_loop1 := ln_count_loop1 + 1;

                 BEGIN

                    lc_html_file         := lr_conc_pgm_detail.cp_short_name||'_HTML_'||ln_master_request_id||'.html';
                    lc_mail_id_file      := lr_conc_pgm_detail.cp_short_name||'_MAIL_ID_'||ln_master_request_id||'.txt';
                    lc_attach_file       := lr_conc_pgm_detail.cp_short_name||'_ATTACH_'||ln_master_request_id||'.txt';

                    --Opening the HTML, attachment and mail id files
                    lt_file_html         := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
                    lt_file_mail_id      := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
                    lt_file_attachment   := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');

                 EXCEPTION
                 WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while Opening the file. '|| SQLERRM);
                 END;

                 ld_from_date := (ld_sysdate-lr_conc_pgm_detail.hours/24);
                 ln_count_loop2 := 0;

                 --Opening the concurrent program request cursor.
                 FOR lr_conc_req_detail IN lcu_conc_req_detail(lr_conc_pgm_detail.conc_pgm_id
                                                               ,lr_conc_pgm_detail.appln_id
                                                               ,ld_from_date
                                                               ,ld_sysdate
                                                               )
                 LOOP

                    --Writing the column heading of the mail body in HTML file.
                    IF ln_count_loop2 = 0 THEN
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
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Name          : ' || lr_conc_pgm_detail.cp_name);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Start Date    : ' || lr_conc_req_detail.start_date );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' End Date      : ' || lr_conc_req_detail.end_date );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' End Date      : ' || lr_conc_req_detail.phase );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Status        : ' || lr_conc_req_detail.status );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Log File      : ' || lr_conc_pgm_detail.log_file );
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Output File   : ' || lr_conc_pgm_detail.output_file );

                    --Writing the path the file name to be attched in attachment file.
                    IF lr_conc_req_detail.phase_code = 'C' THEN
                       IF UPPER(lr_conc_pgm_detail.LOG_FILE) = 'ERROR' AND lr_conc_req_detail.STATUS = 'Error' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                          lc_log_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.LOG_FILE) = 'WARNING' AND lr_conc_req_detail.STATUS = 'Warning' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                          lc_log_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.LOG_FILE) = 'NORMAL' AND lr_conc_req_detail.STATUS = 'Normal' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                          lc_log_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.LOG_FILE) = 'ALL' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.logfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_logfile.txt');
                          lc_log_flag := 'Yes';
                       END IF;
                       IF UPPER(lr_conc_pgm_detail.OUTPUT_FILE) = 'ERROR' AND lr_conc_req_detail.STATUS = 'Error' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.OUTPUT_FILE) = 'WARNING' AND lr_conc_req_detail.STATUS = 'Warning' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.OUTPUT_FILE) = 'NORMAL' AND lr_conc_req_detail.STATUS = 'Normal' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_conc_pgm_detail.OUTPUT_FILE) = 'ALL' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_conc_req_detail.outfile_name||' '||lr_conc_req_detail.CONC_REQ_ID||'_'||lr_conc_req_detail.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       END IF;
                    END IF;

                    BEGIN

                       IF lr_conc_req_detail.phase = 'Running' OR lr_conc_req_detail.phase = 'Pending' THEN
                          lc_color := '<td bgColor="#00FF00"><font size="1"> ';
                       ELSIF lr_conc_req_detail.phase = 'Inactive' THEN
                          lc_color := '<td bgColor="#FFFF00"><font size="1"> ';
                       ELSE
                          SELECT DECODE(lr_conc_req_detail.status
                                        ,'Warning','<td bgColor="#FFFF00"><font size="1"> '
                                        ,'Error' ,'<td bgColor="#FF0000"><font size="1"> '
                                        ,'<td bgColor="#f7f7e7"><font size="1"> '
                                        )
                          INTO lc_color
                          FROM dual;
                       END IF;

                       --Writing the content of the mail body in the HTML file.
                       UTL_FILE.PUT_LINE(lt_file_html,'<tr>'
                                         ||lc_color|| lc_db_name || '</font></td>'
                                         ||lc_color|| lr_conc_req_detail.CONC_REQ_ID || '</font></td>'
                                         ||lc_color|| lr_conc_req_detail.COUNTRY || '</font></td>'
                                         ||lc_color|| lr_conc_pgm_detail.CP_NAME || '</font></td>'
                                         ||lc_color|| TO_CHAR(lr_conc_req_detail.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                         ||lc_color|| TO_CHAR(lr_conc_req_detail.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                         ||lc_color|| lr_conc_req_detail.phase|| '</font></td>'
                                         ||lc_color|| lr_conc_req_detail.status|| '</font></td>'
                                         ||lc_color|| lc_log_flag|| '</font></td>'
                                         ||lc_color|| lc_out_flag  || '</font></td></tr>'
                                         );

                    EXCEPTION
                    WHEN OTHERS THEN
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

                 IF p_mail_group IS NULL THEN
                    lc_recepient_address := lr_conc_pgm_detail.email_1||' '||lr_conc_pgm_detail.email_2||' '
                                            ||lr_conc_pgm_detail.email_3||' '||lr_conc_pgm_detail.email_4||' '
                                            ||lr_conc_pgm_detail.email_5||' '||lr_conc_pgm_detail.email_6;
                 END IF;

                 UTL_FILE.PUT_LINE(lt_file_mail_id,lc_recepient_address);

                 --Closing all the html, mail and attachment files.
                 UTL_FILE.fclose(lt_file_mail_id);
                 UTL_FILE.fclose(lt_file_html);
                 UTL_FILE.fclose(lt_file_attachment);

                 BEGIN

                    SELECT directory_path
                    INTO   lc_directory_path
                    FROM   dba_directories
                    WHERE  directory_name = 'XXFIN_OUTBOUND';

                    --Calling the shell script to send the mail with attahcment.
                    ln_conc_request_id := fnd_request.submit_request ( 'XXCOMN'
                                                                      ,'XXCOMHTMLMAIL'
                                                                      ,''
                                                                      ,''
                                                                      ,TRUE
                                                                      ,lc_directory_path||'/'||lc_mail_id_file
                                                                      , lr_conc_pgm_detail.CP_NAME||' Details. Program submission time From '||TO_CHAR(ld_from_date,'DD-MON-YYYY HH24:MI:SS')||' To  '||TO_CHAR(ld_sysdate,'DD-MON-YYYY HH24:MI:SS')
                                                                      ,'Concurrent_request_status_mailer'
                                                                      ,lc_directory_path||'/'||lc_html_file
                                                                      ,lc_directory_path||'/'||lc_attach_file
                                                                      ,p_attachment_size
                                                                      );

                    COMMIT;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);
                 END;

              END LOOP;

              IF ln_count_loop1 > 0 THEN
                 fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                                 ,request_data => 'OVER');
              END IF;

           EXCEPTION
           WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is:' || SQLERRM);
           END;

        END IF;

    END EMAIL_ALERT;

-- +===================================================================+
-- | Name : REQUESTOR_EMAIL_ALERT                                      |
-- | Description : Procedure to fetch the records for the particular   |
-- |               requestor and matching the given conditions and call|
-- |               the mailer                                          |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: Email Program Alert - Requestor Level               |
-- |                                                                   |
-- | Parameters : x_error_buff                                         |
-- |              x_ret_code                                           |
-- |              p_req_name                                           |
-- |              p_prog_appn                                          |
-- |              p_hour_detail                                        |
-- |              p_mail_group                                         |
-- |              p_log_file                                           |
-- |              p_output_file                                        |
-- |              p_cutoff_time                                        |
-- |              p_prog_status                                        |
-- |              p_hour_default                                       |
-- |              p_log_file_default                                   |
-- |              p_output_file_default                                |
-- |              p_exclude_mailer                                     |
-- +===================================================================+
    PROCEDURE REQUESTOR_EMAIL_ALERT( x_error_buff              OUT  VARCHAR2
                                    ,x_ret_code                OUT  NUMBER
                                    ,p_req_name                IN   VARCHAR2
                                    ,p_prog_appn               IN   VARCHAR2
                                    ,p_hour_detail             IN   NUMBER
                                    ,p_mail_group              IN   VARCHAR2
                                    ,p_log_file                IN   VARCHAR2
                                    ,p_output_file             IN   VARCHAR2
                                    ,p_cutoff_time             IN   VARCHAR2
                                    ,p_prog_status             IN   VARCHAR2
                                    ,p_hour_default            IN   NUMBER
                                    ,p_log_file_default        IN   VARCHAR2
                                    ,p_output_file_default     IN   VARCHAR2
                                    ,p_exclude_mailer          IN   VARCHAR2
                                    ,p_attachment_size         IN   NUMBER
                                    )
    AS
       v_req_data                       VARCHAR2(4000);
       lc_db_name                       VARCHAR2(200);
       lc_log_flag                      VARCHAR2(5) := 'No';
       lc_out_flag                      VARCHAR2(5) := 'No';
       ld_sysdate                       DATE;
       lt_file_html                     UTL_FILE.FILE_TYPE;
       lt_file_mail_id                  UTL_FILE.FILE_TYPE;
       lt_file_attachment               UTL_FILE.FILE_TYPE;
       lc_html_file                     VARCHAR2(200);
       lc_mail_id_file                  VARCHAR2(200);
       lc_attach_file                   VARCHAR2(200);
       ln_master_request_id             NUMBER       := fnd_profile.value('CONC_REQUEST_ID');
       lc_conc_pgm_short_name           fnd_concurrent_programs.concurrent_program_name%TYPE;
       lc_conc_pgm_appln_name           fnd_application.application_short_name%TYPE;
       lc_directory_path                VARCHAR2(400);
       ln_pgm_name_appln_delimit        NUMBER;
       lc_recepient_address             VARCHAR2(4000);
       ln_conc_request_id               NUMBER;
       lc_email_1                       VARCHAR2(4000);
       lc_email_2                       VARCHAR2(4000);
       lc_email_3                       VARCHAR2(4000);
       lc_email_4                       VARCHAR2(4000);
       lc_email_5                       VARCHAR2(4000);
       lc_email_6                       VARCHAR2(4000);
       ld_cutoff_date                   DATE;
       ln_count_header                  NUMBER  := 0;
       lc_color                         VARCHAR2(4000);
       ln_mailer_conc_program_id        NUMBER;
       ln_mailer_req_program_id         NUMBER;
       ln_script_program_id             NUMBER;
       ln_mailer_conc_appln_id          NUMBER;
       ln_mailer_req_appln_id           NUMBER;
       ln_script_appln_id               NUMBER;

--Cursor to fetch the details of the concurrent program when p_pgm_appln parameter is not passed
       CURSOR lcu_req_pgm_null( p_req_name         VARCHAR2
                               ,p_to_date          DATE
                               ,p_cutoff_time      DATE
                               ,p_hours_detail     NUMBER
                               ,p_hour_default     NUMBER
                               ,p_prog_status      VARCHAR2
                               )
       IS
       SELECT   FCR.requested_by                         USER_NAME
               ,FCR.request_id                           REQUEST_ID
               ,FCP.user_concurrent_program_name         CP_NAME
               ,FCR.actual_start_date                    START_DATE
               ,FCR.actual_completion_date               END_DATE
               ,FLS.meaning                              STATUS
               ,FLP.meaning                              PHASE
               ,FCR.phase_code                           PHASE_CODE
               ,NVL(p_log_file,p_log_file_default)       LOG_FILE
               ,NVL(p_output_file,p_output_file_default) OUTPUT_FILE
               ,FCR.logfile_name                         LOGFILE_NAME
               ,FCR.outfile_name                         OUTFILE_NAME
               ,DECODE(SUBSTR(FR.responsibility_name,1,7)
                       ,'OD (US)','US'
                       ,'OD (CA)','Canada'
                       ,'Other'
                       )                                 COUNTRY
               ,FCP.concurrent_program_id                PROGRAM_ID
               ,FCP.application_id                       APPLICATION_ID
       FROM     fnd_concurrent_requests      FCR
               ,fnd_concurrent_programs_vl   FCP
               ,fnd_user                     FU
               ,fnd_lookups                  FLS
               ,fnd_lookups                  FLP
               ,fnd_responsibility_tl        FR
       WHERE    FU.user_id                        = FCR.requested_by
       AND      FCP.concurrent_program_id         = FCR.concurrent_program_id
       AND      FCR.responsibility_id             = FR.responsibility_id
       AND      FU.user_name                      = p_req_name
       AND      ((FCR.actual_start_date BETWEEN GREATEST(NVL(p_cutoff_time,(p_to_date -NVL(p_hours_detail,p_hour_default)/24)),(p_to_date -NVL(p_hours_detail,p_hour_default)/24)) AND p_to_date)
                 OR (FCR.phase_code != 'C'))
       AND      FLS.lookup_type                   = 'CP_STATUS_CODE'
       AND      FLS.lookup_code                   = FCR.status_code
       AND      FLP.lookup_type                   = 'CP_PHASE_CODE'
       AND      FLP.lookup_code                   = FCR.phase_code
       AND      UPPER(TRIM(FLS.meaning))          = DECODE(p_prog_status
                                                           ,NULL,UPPER(TRIM(FLS.meaning))
                                                           ,'ALL',UPPER(TRIM(FLS.meaning))
                                                           ,'NONE',UPPER(TRIM(FLS.meaning))
                                                           ,p_prog_status
                                                           )
       ORDER BY FCR.request_id;

--Cursor to fetch the details of the concurrent program when p_pgm_appln parameter is passed
       CURSOR lcu_req_pgm_not_null( p_req_name       VARCHAR2
                                   ,p_pgm_name       VARCHAR2
                                   ,p_appln_name     VARCHAR2
                                   ,p_to_date        DATE
                                   ,p_cutoff_time    DATE
                                   ,p_prog_status    VARCHAR2
                                   ,p_hours_detail   NUMBER
                                   ,p_hour_default   NUMBER
                                   )
       IS
       SELECT  XFTV.SOURCE_VALUE1                USER_NAME
              ,FCR.request_id                    REQUEST_ID
              ,FCP.user_concurrent_program_name  CP_NAME
              ,FCR.actual_start_date             START_DATE
              ,FCR.actual_completion_date        END_DATE
              ,FLS.meaning                       STATUS
              ,FLP.meaning                       PHASE
              ,FCR.phase_code                    PHASE_CODE
              ,NVL(p_log_file,NVL(XFTV.target_value1,p_log_file_default))       LOG_FILE
              ,NVL(p_output_file,NVL(XFTV.target_value2,p_output_file_default)) OUTPUT_FILE
              ,FCR.logfile_name                  LOGFILE_NAME
              ,FCR.outfile_name                  OUTFILE_NAME
              ,DECODE(SUBSTR(FR.responsibility_name,1,7)
                      ,'OD (US)','US'
                      ,'OD (CA)','Canada'
                      ,'Other'
                      )                         COUNTRY
       FROM    xx_fin_translatedefinition       XFTD
              ,xx_fin_translatevalues           XFTV
              ,fnd_concurrent_requests          FCR
              ,fnd_concurrent_programs_vl       FCP
              ,fnd_user                         FU
              ,fnd_lookups                      FLS
              ,fnd_lookups                      FLP
              ,fnd_responsibility_tl            FR
       WHERE   XFTD.translate_id                 = XFTV.translate_id
       AND     FCP.concurrent_program_name       = UPPER(XFTV.source_value2)
       AND     FCP.concurrent_program_id         = FCR.concurrent_program_id
       AND     FCR.requested_by                  = FU.user_id
       AND     FCR.responsibility_id             = FR.responsibility_id
       AND     FU.user_name                      = XFTV.source_value1
       AND     XFTD.translation_name             = 'OD_MONITOR_REQUESTOR'
       AND     FLS.lookup_type                   = 'CP_STATUS_CODE'
       AND     FLS.lookup_code                   = FCR.status_code
       AND     FLP.lookup_type                   = 'CP_PHASE_CODE'
       AND     FLP.lookup_code                   = FCR.phase_code
       AND     XFTV.source_value1                = p_req_name
       AND     UPPER(XFTV.source_value2)         = DECODE(p_pgm_name
                                                          ,'ALL',UPPER(XFTV.source_value2)
                                                          ,p_pgm_name
                                                          )
       AND     UPPER(XFTV.source_value4)         = DECODE(p_appln_name
                                                          ,'ALL',UPPER(XFTV.source_value4)
                                                          ,p_appln_name
                                                          )
       AND     UPPER(TRIM(FLS.meaning))          = DECODE(p_prog_status
                                                          ,NULL,UPPER(TRIM(FLS.meaning))
                                                          ,'ALL',UPPER(TRIM(FLS.meaning))
                                                          ,'NONE',UPPER(TRIM(FLS.meaning))
                                                          ,p_prog_status
                                                          )
       AND     XFTV.enabled_flag                 = 'Y'
       AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
       AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
       AND     ((FCR.actual_start_date   BETWEEN GREATEST(NVL(p_cutoff_time,(p_to_date -NVL(NVL(p_hours_detail,XFTV.target_value3),p_hour_default)/24)),(p_to_date -NVL(NVL(p_hours_detail,XFTV.target_value3),p_hour_default)/24)) AND p_to_date)
                OR (FCR.phase_code != 'C'))
       ORDER BY FCR.request_id;

    BEGIN
       v_req_data := FND_CONC_GLOBAL.REQUEST_DATA;

       IF ( NVL(v_req_data, 'FIRST') = 'FIRST') THEN

          SELECT sys_context('USERENV','DB_NAME')
          INTO lc_db_name
          FROM dual;

          ld_sysdate := SYSDATE;

          BEGIN

             ld_cutoff_date       := fnd_date.canonical_to_date(p_cutoff_time);
             lc_html_file         := p_req_name||'_HTML_'||ln_master_request_id||'.html';
             lc_mail_id_file      := p_req_name||'_MAIL_ID_'||ln_master_request_id||'.txt';
             lc_attach_file       := p_req_name||'_ATTACH_'||ln_master_request_id||'.txt';

             --Open the html,mail and attachment file.
             lt_file_html         := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_html_file,'w');
             lt_file_mail_id      := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_mail_id_file ,'w');
             lt_file_attachment   := UTL_FILE.fopen('XXFIN_OUTBOUND', lc_attach_file ,'w');

             IF p_prog_appn IS NOT NULL THEN

                IF p_prog_appn = 'ALL' THEN
                   lc_conc_pgm_short_name := 'ALL';
                   lc_conc_pgm_appln_name := 'ALL';
                ELSE
                   ln_pgm_name_appln_delimit := INSTR(p_prog_appn, ';', -1, 1);
                   lc_conc_pgm_short_name    := SUBSTR(p_prog_appn,1,ln_pgm_name_appln_delimit-1);
                   lc_conc_pgm_appln_name    := SUBSTR(p_prog_appn,ln_pgm_name_appln_delimit+1);
                END IF;

                FOR lr_req_pgm_not_null IN lcu_req_pgm_not_null( p_req_name
                                                                ,lc_conc_pgm_short_name
                                                                ,lc_conc_pgm_appln_name
                                                                ,ld_sysdate
                                                                ,ld_cutoff_date
                                                                ,p_prog_status
                                                                ,p_hour_detail
                                                                ,p_hour_default
                                                                )
                LOOP

                   --Write the column heading of the mail body in to html file.
                   IF ln_count_header = 0 THEN
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

                   IF lr_req_pgm_not_null.phase_code = 'C' THEN
                        IF UPPER(lr_req_pgm_not_null.LOG_FILE) = 'ERROR' AND lr_req_pgm_not_null.STATUS = 'Error' THEN
                           UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.logfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_logfile.txt');
                           lc_log_flag := 'Yes';
                        ELSIF UPPER(lr_req_pgm_not_null.LOG_FILE) = 'WARNING' AND lr_req_pgm_not_null.STATUS = 'Warning' THEN
                           UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.logfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_logfile.txt');
                           lc_log_flag := 'Yes';
                        ELSIF UPPER(lr_req_pgm_not_null.LOG_FILE) = 'NORMAL' AND lr_req_pgm_not_null.STATUS = 'Normal' THEN
                           UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.logfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_logfile.txt');
                           lc_log_flag := 'Yes';
                        ELSIF UPPER(lr_req_pgm_not_null.LOG_FILE) = 'ALL' THEN
                           UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.logfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_logfile.txt');
                           lc_log_flag := 'Yes';
                       END IF;
                       IF UPPER(lr_req_pgm_not_null.OUTPUT_FILE) = 'ERROR' AND lr_req_pgm_not_null.STATUS = 'Error' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.outfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_req_pgm_not_null.OUTPUT_FILE) = 'WARNING' AND lr_req_pgm_not_null.STATUS = 'Warning' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.outfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_req_pgm_not_null.OUTPUT_FILE) = 'NORMAL' AND lr_req_pgm_not_null.STATUS = 'Normal' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.outfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       ELSIF UPPER(lr_req_pgm_not_null.OUTPUT_FILE) = 'ALL' THEN
                          UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_not_null.outfile_name||' '||lr_req_pgm_not_null.REQUEST_ID||'_'||lr_req_pgm_not_null.START_DATE||'_output.txt');
                          lc_out_flag := 'Yes';
                       END IF;
                   END IF;

                   BEGIN
                      IF lr_req_pgm_not_null.phase = 'Running' OR lr_req_pgm_not_null.phase = 'Pending' THEN
                          lc_color := '<td bgColor="#00FF00"><font size="1"> ';
                       ELSIF lr_req_pgm_not_null.phase = 'Inactive' THEN
                          lc_color := '<td bgColor="#FFFF00"><font size="1"> ';
                      ELSE
                         SELECT DECODE(lr_req_pgm_not_null.status
                                       ,'Warning','<td bgColor="FFFF00"><font size="1"> '
                                       ,'Error' ,'<td bgColor="#FF0000"><font size="1"> '
                                       ,'<td bgColor="#f7f7e7"><font size="1"> '
                                       )
                         INTO lc_color
                         FROM dual;
                      END IF;

                      --Write the details of the mail body.
                      UTL_FILE.PUT_LINE(lt_file_html,'<tr>'
                                        ||lc_color|| lc_db_name || '</font></td>'
                                        ||lc_color|| lr_req_pgm_not_null.REQUEST_ID || '</font></td>'
                                        ||lc_color|| lr_req_pgm_not_null.COUNTRY || '</font></td>'
                                        ||lc_color|| lr_req_pgm_not_null.CP_NAME || '</font></td>'
                                        ||lc_color|| TO_CHAR(lr_req_pgm_not_null.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| TO_CHAR(lr_req_pgm_not_null.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                        ||lc_color|| lr_req_pgm_not_null.phase|| '</font></td>'
                                        ||lc_color|| lr_req_pgm_not_null.status|| '</font></td>'
                                        ||lc_color|| lc_log_flag|| '</font></td>'
                                        ||lc_color|| lc_out_flag  || '</font></td></tr>'
                                        );

                   EXCEPTION
                   WHEN OTHERS THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
                   END;

                   lc_log_flag     := 'No';
                   lc_out_flag     := 'No';
                   ln_count_header := ln_count_header+1;

                END LOOP;

             END IF;

             IF p_prog_appn IS NULL THEN

                SELECT  FCP.concurrent_program_id
                       ,FA.application_id
                INTO    ln_mailer_conc_program_id
                       ,ln_mailer_conc_appln_id
                FROM    fnd_application   FA
                       ,fnd_concurrent_programs FCP
                WHERE   FA.application_id = FCP.application_id
                AND     FCP.concurrent_program_name = 'XX_COM_MONITOR_PKG_EMAIL_ALERT'
                AND     FA.application_short_name = 'XXCOMN';

                SELECT  FCP.concurrent_program_id
                       ,FA.application_id
                INTO    ln_mailer_req_program_id
                       ,ln_mailer_req_appln_id
                FROM    fnd_application   FA
                       ,fnd_concurrent_programs FCP
                WHERE   FA.application_id = FCP.application_id
                AND     FCP.concurrent_program_name = 'XX_COM_MONITOR_PKG_REQ_EMAIL'
                AND     FA.application_short_name = 'XXCOMN';

                SELECT  FCP.concurrent_program_id
                       ,FA.application_id
                INTO    ln_script_program_id
                       ,ln_script_appln_id
                FROM    fnd_application   FA
                       ,fnd_concurrent_programs FCP
                WHERE   FA.application_id = FCP.application_id
                AND     FCP.concurrent_program_name = 'XXCOMHTMLMAIL'
                AND     FA.application_short_name = 'XXCOMN';

                --Open the cursor when program name is not given.
                FOR lr_req_pgm_null IN lcu_req_pgm_null(p_req_name
                                                        ,ld_sysdate
                                                        ,ld_cutoff_date
                                                        ,p_hour_detail
                                                        ,p_hour_default
                                                        ,p_prog_status
                                                        )
                LOOP

                   --Check for the condition whether the mailer program needs to be displayed.
                   IF (NOT (p_exclude_mailer = 'Y' AND(    (lr_req_pgm_null.program_id = ln_mailer_conc_program_id AND lr_req_pgm_null.application_id = ln_mailer_conc_appln_id)
                                                        OR (lr_req_pgm_null.program_id = ln_mailer_req_program_id AND lr_req_pgm_null.application_id = ln_mailer_req_appln_id)
                                                        OR (lr_req_pgm_null.program_id = ln_script_program_id AND lr_req_pgm_null.application_id = ln_script_appln_id)
                                                      ) 
                            )
                      ) THEN

                      IF ln_count_header = 0 THEN
		        --Write the HTML header.
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

                   BEGIN

                      IF lr_req_pgm_null.phase = 'Running' OR lr_req_pgm_null.phase = 'Pending' THEN
                          lc_color := '<td bgColor="#00FF00"><font size="1"> ';
                      ELSIF lr_req_pgm_null.phase = 'Inactive' THEN
                          lc_color := '<td bgColor="#FFFF00"><font size="1"> ';
                      ELSE
                         SELECT DECODE(lr_req_pgm_null.status
                                       ,'Warning','<td bgColor="#FFFF33"><font size="1"> '
                                       ,'Error' ,'<td bgColor="#FF0000"><font size="1"> '
                                       ,'<td bgColor="#f7f7e7"><font size="1"> '
                                       )
                         INTO lc_color
                         FROM dual;

                      END IF;

                         --Write the path of the file needs to be attached in attachment file.
                         IF lr_req_pgm_null.phase_code = 'C' THEN
                            IF UPPER(lr_req_pgm_null.LOG_FILE) = 'ERROR' AND lr_req_pgm_null.STATUS = 'Error' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.logfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_logfile.txt');
                               lc_log_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.LOG_FILE) = 'WARNING' AND lr_req_pgm_null.STATUS = 'Warning' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.logfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_logfile.txt');
                               lc_log_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.LOG_FILE) = 'NORMAL' AND lr_req_pgm_null.STATUS = 'Normal' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.logfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_logfile.txt');
                               lc_log_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.LOG_FILE) = 'ALL' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.logfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_logfile.txt');
                               lc_log_flag := 'Yes';
                            END IF;
                            IF UPPER(lr_req_pgm_null.OUTPUT_FILE) = 'ERROR' AND lr_req_pgm_null.STATUS = 'Error' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.outfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_output.txt');
                               lc_out_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.OUTPUT_FILE) = 'WARNING' AND lr_req_pgm_null.STATUS = 'Warning' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.outfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_output.txt');
                               lc_out_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.OUTPUT_FILE) = 'NORMAL' AND lr_req_pgm_null.STATUS = 'Normal' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.outfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_output.txt');
                               lc_out_flag := 'Yes';
                            ELSIF UPPER(lr_req_pgm_null.OUTPUT_FILE) = 'ALL' THEN
                               UTL_FILE.PUT_LINE(lt_file_attachment,lr_req_pgm_null.outfile_name||' '||lr_req_pgm_null.REQUEST_ID||'_'||lr_req_pgm_null.START_DATE||'_output.txt');
                               lc_out_flag := 'Yes';
                            END IF;
                         END IF;

                        --Write the content of the html.
                         UTL_FILE.PUT_LINE(lt_file_html,'<tr>'
                                           ||lc_color|| lc_db_name || '</font></td>'
                                           ||lc_color|| lr_req_pgm_null.REQUEST_ID || '</font></td>'
                                           ||lc_color|| lr_req_pgm_null.COUNTRY || '</font></td>'
                                           ||lc_color|| lr_req_pgm_null.CP_NAME || '</font></td>'
                                           ||lc_color|| TO_CHAR(lr_req_pgm_null.START_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                           ||lc_color|| TO_CHAR(lr_req_pgm_null.END_DATE,'DD-MON-YYYY HH24:MI:SS') || '</font></td>'
                                           ||lc_color|| lr_req_pgm_null.phase|| '</font></td>'
                                           ||lc_color|| lr_req_pgm_null.status|| '</font></td>'
                                           ||lc_color|| lc_log_flag|| '</font></td>'
                                           ||lc_color|| lc_out_flag  || '</font></td></tr>'
                                           );

                         ln_count_header := ln_count_header+1;

                   EXCEPTION
                   WHEN OTHERS THEN
                       DBMS_OUTPUT.PUT_LINE(SQLERRM);
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing into Text file. '|| SQLERRM);
                   END;

                   lc_log_flag     := 'No';
                   lc_out_flag     := 'No';

                   END IF;

                END LOOP;

             END IF;

             IF ln_count_header > 0 THEN
                UTL_FILE.PUT_LINE(lt_file_html,'</tbody></table></FONT></B></P> </BODY> </HTML>');
             ELSE
                UTL_FILE.PUT_LINE(lt_file_html,'<html><body><font size="4"  align="center"> <b>No Requests submitted for the Requestor.</b></font></body></html>');
             END IF;

             BEGIN

                IF p_mail_group IS NOT NULL THEN

                   --Query to fetch the mail ids if mail group is passed.
                   SELECT  XFTV.target_value1
                          ,XFTV.target_value2
                          ,XFTV.target_value3
                          ,XFTV.target_value4
                          ,XFTV.target_value5
                          ,XFTV.target_value6
                   INTO    lc_email_1
                          ,lc_email_2
                          ,lc_email_3
                          ,lc_email_4
                          ,lc_email_5
                          ,lc_email_6
                   FROM    xx_fin_translatedefinition    XFTD
                          ,xx_fin_translatevalues       XFTV
                   WHERE   XFTV.translate_id     = XFTD.translate_id
                   AND     XFTD.translation_name = 'OD_MAIL_GROUPS'
                   AND     XFTV.enabled_flag     = 'Y'
                   AND     SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                   AND     SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                   AND     XFTV.source_value1    = p_mail_group;

                ELSE

                   --Query to fetch the mail ids if mail group is not passed.
                   SELECT DISTINCT  XFTV.target_value4
                                   ,XFTV.target_value5
                                   ,XFTV.target_value6
                                   ,XFTV.target_value7
                                   ,XFTV.target_value8
                                   ,XFTV.target_value9
                   INTO  lc_email_1
                        ,lc_email_2
                        ,lc_email_3
                        ,lc_email_4
                        ,lc_email_5
                        ,lc_email_6
                   FROM  xx_fin_translatedefinition    XFTD
                        ,xx_fin_translatevalues       XFTV
                   WHERE XFTV.translate_id     = XFTD.translate_id
                   AND   XFTD.translation_name = 'OD_MONITOR_REQUESTOR'
                   AND   XFTV.source_value1    = p_req_name
                   AND   XFTV.enabled_flag     = 'Y'
                   AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                   AND   SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1);

                END IF;

             END;

             lc_recepient_address := lc_email_1||' '||lc_email_2||' '||lc_email_3
                                     ||' '||lc_email_4||' '||lc_email_5||' '||lc_email_6;

             --Write the mail ids in the mail file
             UTL_FILE.PUT_LINE(lt_file_mail_id,lc_recepient_address);

             --Close the mail,html and attachment file.
             UTL_FILE.fclose(lt_file_mail_id);
             UTL_FILE.fclose(lt_file_html);
             UTL_FILE.fclose(lt_file_attachment);

             BEGIN
                SELECT directory_path
                INTO lc_directory_path
                FROM dba_directories
                WHERE directory_name = 'XXFIN_OUTBOUND';

                --Call the shell script program to send the mail with attachment.
                ln_conc_request_id := fnd_request.submit_request ('XXCOMN'
                                                                  ,'XXCOMHTMLMAIL'
                                                                  ,''
                                                                  ,''
                                                                  ,TRUE
                                                                  ,lc_directory_path||'/'||lc_mail_id_file
                                                                  , 'Program submission For the Requestor: '||p_req_name
                                                                  ,'Concurrent_request_status_mailer'
                                                                  ,lc_directory_path||'/'||lc_html_file
                                                                  ,lc_directory_path||'/'||lc_attach_file
                                                                  ,p_attachment_size
                                                                  );

                COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request ID(OD: HTML Mailer): '||ln_conc_request_id);

             END;

             fnd_conc_global.set_req_globals(conc_status => 'PAUSED'
                                             ,request_data => 'OVER');
          EXCEPTION
          WHEN others THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is:' || SQLERRM);
          END;

       END IF;

    END REQUESTOR_EMAIL_ALERT;

 END XX_COM_MONITOR_PKG;
/