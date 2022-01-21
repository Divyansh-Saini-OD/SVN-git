SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_LONG_RUN_ALERT_PKG
PROMPT Program exits IF the creation is not successful

CREATE OR REPLACE PACKAGE BODY APPS.XX_LONG_RUN_ALERT_PKG 
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_LONG_RUN_ALERT_PKG                                     |
-- | Description      :  This PKG is used for long running alert       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 19-Oct-2010  Sundaram S       Initial draft version       |
-- +===================================================================+
PROCEDURE RUN_ALERT (x_errmsg                 OUT   NOCOPY  VARCHAR2
                    ,x_retcode              OUT   NOCOPY  NUMBER
		    )
IS
      lc_error_details     VARCHAR2(32000):= NULL;
      lc_error_location    VARCHAR2(4000) := NULL;
      mailhost             VARCHAR2 (100)           := 'USCHMSX85.na.odcorp.net';
      mail_conn            UTL_SMTP.connection;
      v_date               VARCHAR2 (25);
      ln_min_time number := NULL;
      ln_max_time number := NULL;
      lc_short_name varchar2(400) := null;
      lc_prog_name varchar2(400) := null;
      ln_count               Number := 0;
      lc_rec_rowcount        Number :=0;
      lc_rec_rowcount1       Number :=0;
      EX_MAIN_EXCEPTION    EXCEPTION;
      Cursor ln_curr_running_header IS SELECT  XFTV.source_value1 concurrent_program_id
                                          FROM   xxfin.xx_fin_translatedefinition XFTD
                                                 ,xxfin.xx_fin_translatevalues XFTV
                                         WHERE   XFTD.translate_id = XFTV.translate_id
                                          AND     XFTD.translation_name = 'XX_LONG_RUNNING_PGM'
                                          AND     XFTV.enabled_flag = 'Y'
                                          AND     XFTD.enabled_flag = 'Y'
                                          AND EXISTS ( SELECT concurrent_program_id
                                                          FROM fnd_concurrent_requests
                                                         WHERE phase_code = 'R'
							 AND trunc(request_date) = trunc(SYSDATE)
                                                         AND concurrent_program_id =  XFTV.source_value1);
      lc_curr_var ln_curr_running_header%rowtype;
BEGIN
      SELECT SYSDATE
       --TO_CHAR (SYSDATE , 'DD-Mon-YYYY HH24:MI')
      INTO v_date
      FROM DUAL;
      mail_conn := UTL_SMTP.open_connection (mailhost);
      UTL_SMTP.helo (mail_conn, mailhost);
      UTL_SMTP.mail (mail_conn, 'sundaram-senthilnanthan@officedepot.com');
      UTL_SMTP.rcpt (mail_conn, 'sundaram-senthilnanthan@officedepot.com');
      --UTL_SMTP.rcpt (mail_conn, 'ebs_admin212@officedepot.com');
      UTL_SMTP.open_data (mail_conn);
      UTL_SMTP.write_data (mail_conn,
                              'From:'
                           || 'sundaram-senthilnanthan@officedepot.com'
                           || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (mail_conn,
                              'To:'
                           || 'sundaram-senthilnanthan@officedepot.com'
                           || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (mail_conn,
                              'Subject:'
                           || 'Long Running Alert '||TO_CHAR (SYSDATE,'MON/DD/RRRR')
                           || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (mail_conn,
                           'Cc:' || 'sundaram-senthilnanthan@officedepot.com'
                           || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (mail_conn, 'MIME-version: 1.0' || UTL_TCP.crlf);
      UTL_SMTP.write_data (mail_conn,
                           'Content-Type: text/html' || UTL_TCP.crlf
                          );
      UTL_SMTP.write_data (mail_conn, '<HTML>');
      UTL_SMTP.write_data (mail_conn, '<BODY>');
      UTL_SMTP.write_data
         (mail_conn,
             '<P ALIGN="center"><B><FONT FACE="Verdana" SIZE="5" color="#153E7E"> LONG RUNNING PROGRAMS ALERT </FONT></B></P>'
         );
      UTL_SMTP.write_data
                       (mail_conn,
                        '<P><B><FONT FACE="Verdana" SIZE="1" color="#336899">'
                       );
      UTL_SMTP.write_data (mail_conn, '<HR>');
      UTL_SMTP.write_data (mail_conn, '</B></P>');
      UTL_SMTP.write_data
         (mail_conn,
             '<P ALIGN="left"><B><FONT FACE="Verdana" SIZE="3" color="#153E7E">  Alert Status as of   '
          ||  TO_CHAR (SYSDATE , 'DD-Mon-YYYY HH24:MI')
          || ' </FONT></B></P>'
         );
      UTL_SMTP.write_data
                       (mail_conn,
                        '<BR>'
                       );
      lc_error_location := 'ALRT-001';
      lc_error_details := 'Derive the Running concurrent Program';

      OPEN ln_curr_running_header;
      LOOP
      FETCH ln_curr_running_header
      INTO lc_curr_var;
      EXIT WHEN ln_curr_running_header%NOTFOUND;
       lc_rec_rowcount := 1;
       ln_count := 0;
       BEGIN
      lc_error_location := 'ALRT-002';
      lc_error_details := 'Derive the program details';
	   SELECT  XFTV.target_value1
                  ,XFTV.target_value2
                  ,XFTV.target_value3
                  ,XFTV.target_value4
             INTO lc_prog_name,
                  lc_short_name,
                  ln_min_time,
                  ln_max_time
           FROM xxfin.xx_fin_translatedefinition XFTD
                ,xxfin.xx_fin_translatevalues XFTV
             WHERE   XFTD.translate_id = XFTV.translate_id
               AND   XFTD.translation_name = 'XX_LONG_RUNNING_PGM'
               AND   XFTV.enabled_flag = 'Y'
               AND   XFTD.enabled_flag = 'Y'
               AND   xftv.source_value1 = lc_curr_var.concurrent_program_id;
           lc_error_location := 'ALRT-002';
           lc_error_details := 'Derive the Request details';
	   FOR ln_curr_running_lines IN (SELECT a.request_id request_id
                                          ,a.parent_Request_id Parent_id
                                          ,TO_CHAR((NVL(a.actual_completion_date,SYSDATE)-NVL(a.actual_start_date,SYSDATE))*60*24,'999999999999.99') Minutes
                                           FROM fnd_concurrent_requests a
                                         WHERE a.concurrent_program_id = lc_curr_var.concurrent_program_id
				          AND a.phase_code = 'R'
					  AND trunc(a.request_date) = trunc(SYSDATE))
                LOOP
		  IF ((ln_curr_running_lines.minutes BETWEEN ln_min_time AND ln_max_time) OR ln_curr_running_lines.minutes >= ln_max_time) THEN
		  lc_rec_rowcount1 := 1;
		  DBMS_OUTPUT.put_line (lc_rec_rowcount);
                    IF ln_count = 0 THEN
		    	DBMS_OUTPUT.put_line (ln_count);
                       UTL_SMTP.write_data
                                (mail_conn,
                                 '<BR>'
                                 );
                       UTL_SMTP.write_data (mail_conn, '<table border=1 width = "700" ');
                       UTL_SMTP.write_data (mail_conn, '<tbody>');
                       UTL_SMTP.write_data 
                              (mail_conn,'<th colspan="6" align="left" bgcolor="#6CC417"><font FACE="Calibri" color="#000000" size="2"><B> PROGRAM DETAILS </B></font></th>');
                       UTL_SMTP.write_data (mail_conn, '<tr>');
                       UTL_SMTP.write_data
                              (mail_conn,
                               '<th width = "400" bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2" > Program Name </font></b></th>'
                               );
                       UTL_SMTP.write_data
                               (mail_conn,
                                '<th width = "150" bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2" > Min Run Time </font></b></th>'
                               );
                       UTL_SMTP.write_data
                               (mail_conn,
                                '<th width = "150" bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2" > Max Run Time </font></b></th>'
                               );
                       UTL_SMTP.write_data (mail_conn, '</tr>');
                       UTL_SMTP.write_data (mail_conn, '<tr>');
                       UTL_SMTP.write_data (mail_conn,
                               '<td bgColor="#f7f7e7"><b><Font FACE="Calibri" size="2">'
                               || NVL(lc_prog_name,'')
                               || '</font></b></td>'
                               );
                       UTL_SMTP.write_data (mail_conn,
                               '<td bgColor="#f7f7e7"><Font FACE="Calibri" size="2">'
                               || NVL(ln_min_time,'')
                               || '</font></td>'
                               );
                       UTL_SMTP.write_data (mail_conn,
                              '<td bgColor="#f7f7e7"><Font FACE="Calibri" size="2">'
                               || NVL(ln_max_time,'')
                               || '</font></td>'
                               );
                       UTL_SMTP.write_data (mail_conn, '</tr>');
                       ln_count := 1;
                    UTL_SMTP.write_data (mail_conn, '<tr>');
                    UTL_SMTP.write_data (mail_conn, '</tr>');
                    UTL_SMTP.write_data (mail_conn, '<tr>');
                    UTL_SMTP.write_data
                          (mail_conn,
                            '<th bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2"> Request Id</font></b></th>'
                           );
                    UTL_SMTP.write_data
                        (mail_conn,
                        '<th bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2"> Parent Id  </font></b></th>'
                         );
                    UTL_SMTP.write_data
                        (mail_conn,
                       '<th bgColor="#C3FDB8" align="left"><b><font FACE="Calibri" color="#000000" size="2"> Run Time </font></b></th>'
                        );
                    END IF;
                    UTL_SMTP.write_data (mail_conn, '</tr>');
                    IF ln_curr_running_lines.minutes BETWEEN ln_min_time AND ln_max_time THEN
                    lc_error_location := 'ALRT-003';
                    lc_error_details := 'Min threshold';
                           UTL_SMTP.write_data (mail_conn, '<tr>');
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="Yellow"><b><font FACE="Calibri" size="2">'
                                               || NVL(ln_curr_running_lines.request_id,'')
                                               || '</font></b></td>'
                                                );
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="#f7f7e7"><font FACE="Calibri" size="2">'
                                               || NVL(ln_curr_running_lines.Parent_id,'')
                                               || '</font></td>'
                                                );
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="#f7f7e7"><font FACE="Calibri" size="2">'
                                               || NVL(ln_curr_running_lines.minutes,'')
                                               || '</font></td>'
                                                );
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'MIN TIME');
                    ELSIF ln_curr_running_lines.minutes > ln_max_time THEN
                    lc_error_location := 'ALRT-003';
                    lc_error_details := 'Max threshold';
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="#DF0101"><b><font FACE="Calibri" size="2">'
                                                || NVL(ln_curr_running_lines.request_id,'')
                                                || '</font></b></td>'
                                                );
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="#f7f7e7"><font FACE="Calibri" size="2">'
                                               || NVL(ln_curr_running_lines.Parent_id,'')
                                               || '</font></td>'
                                               );
                           UTL_SMTP.write_data (mail_conn,
                                               '<td bgColor="#f7f7e7"><font FACE="Calibri" size="2">'
                                               || NVL(ln_curr_running_lines.minutes,'')
                                               || '</font></td>'
                                                );
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'MAX TIME');
                    END IF;
		  END IF;
                END LOOP;
       
       END;
             UTL_SMTP.write_data (mail_conn, '</tbody>');
             UTL_SMTP.write_data (mail_conn, '</table>');

      END LOOP;
      CLOSE ln_curr_running_header;

      UTL_SMTP.write_data (mail_conn, '</FONT></B></P>');
      UTL_SMTP.write_data (mail_conn, '</FONT></B>');
      UTL_SMTP.write_data (mail_conn, '</HTML>');
      UTL_SMTP.write_data (mail_conn, '</BODY>');
		  DBMS_OUTPUT.put_line (lc_rec_rowcount1);
      IF lc_rec_rowcount1 = 0 THEN
         RAISE EX_MAIN_EXCEPTION;
      END IF;
      		  DBMS_OUTPUT.put_line (lc_rec_rowcount);
      IF lc_rec_rowcount = 0 THEN
         RAISE EX_MAIN_EXCEPTION;
      END IF;
      UTL_SMTP.close_data (mail_conn);
      UTL_SMTP.quit (mail_conn);
 EXCEPTION
   WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
   THEN
      UTL_SMTP.quit (mail_conn);
      raise_application_error
                       (-20000,
                           'Failed to send mail due to the following error: '
                        || SQLERRM
                       );
   WHEN EX_MAIN_EXCEPTION
   THEN
    NULL;
   WHEN OTHERS
   THEN
      raise_application_error (-20001,'The following error has occured: ' || SQLERRM ||lc_error_location
                              );
END RUN_ALERT;
END XX_LONG_RUN_ALERT_PKG;
/
SHO ERR;