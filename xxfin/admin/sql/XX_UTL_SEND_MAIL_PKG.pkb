CREATE OR REPLACE
PACKAGE BODY XX_UTL_SEND_MAIL_PKG
AS
PROCEDURE CONTENT  (mail_conn      IN OUT NOCOPY utl_smtp.connection
                   ,p_flag         IN VARCHAR2
                   ,p_issue           CLOB
                   ,p_subject      IN VARCHAR2
                   ,p_bgcolor_t    IN VARCHAR2
                   ,p_bgcolor_h    IN VARCHAR2
                   ,p_bgcolor_f    IN VARCHAR2
                   ,p_fcolor       IN VARCHAR2
                   ,p_colspan      IN VARCHAR2
                   ,p_lockbox      IN VARCHAR2
                   ,p_settlement   IN VARCHAR2
                   ,p_mail_status  IN VARCHAR2
                   ,p_cycle_date   IN VARCHAR2
                   );


PROCEDURE SPLIT_ADDRESS (mail_conn  IN OUT NOCOPY utl_smtp.connection
                        ,P_ADDRESS  IN CLOB 
                        ,P_DETAILS  VARCHAR2
                        );

/*-- +============================================================================+
  -- | PROCEDURE NAME : SPLIT_ADDRESS                                             |
  -- |                                                                            |
  -- | DESCRIPTION    : This Procedure is used to split the Address               |
  -- |                                                                            |
  -- |                                                                            |
  -- |                                                                            |
  -- | PARAMETERS     : mail_conn,p_address,p_details                             |
  -- |                                                                            |
  -- |                                                                            |
  -- |Version   Date         Author               Remarks                         |
  -- |========  ===========  ===================  ================================|
  -- |1.0       17-AUG-2010  A.JUDE FELIX ANTONY  initial draft                   |
  -- |                                                                            |
  -- +===========================================================================+*/

PROCEDURE SPLIT_ADDRESS (mail_conn  IN OUT NOCOPY utl_smtp.connection
                        ,P_ADDRESS  IN CLOB 
                        ,P_DETAILS  VARCHAR2
                        )
AS
lv_length_str NUMBER;
lv_append     CLOB;
lv_start      NUMBER;
lv_instr      NUMBER;
in_str2       NUMBER;
lv_str        VARCHAR2(300) := NULL;
BEGIN
lv_start      := 1;
lv_append     := RPAD(P_ADDRESS,(LENGTH(P_ADDRESS)+1),';');
lv_length_str := LENGTH(lv_append);
in_str2       := 0;
WHILE (lv_length_str > lv_start) LOOP
lv_instr := INSTR(lv_append,';',lv_start);
lv_str   := SUBSTR(lv_append,lv_start,lv_instr-lv_start);
       IF lv_str <> ';' THEN
                
                in_str2 := INSTR(lv_str,'@',1);
                
                IF in_str2 <> 0 THEN

                      IF P_DETAILS = 'RCPT' THEN
                        
                      UTL_SMTP.RCPT(mail_conn,lv_str);

                      ELSIF P_DETAILS = 'TO' THEN

                      UTL_SMTP.WRITE_DATA(mail_conn,'To:'|| lv_str|| UTL_TCP.crlf);

                      END IF;

                END IF;
        END IF;
in_str2  := 0;
lv_start := lv_instr+1;
END LOOP;
END SPLIT_ADDRESS;

/*-- +============================================================================+
  -- | PROCEDURE NAME : CONTENT                                                   |
  -- |                                                                            |
  -- | DESCRIPTION    : This Procedure is use to write the Body and Attachment    |
  -- |                                                                            |
  -- |                                                                            |
  -- |                                                                            |
  -- | PARAMETERS     : mail_conn,p_flag,p_issue,p_subject,p_bgcolor_t            |
  -- |                  p_bgcolor_h,p_bgcolor_f,p_fcolor,p_colspan                |
  -- |                                                                            |
  -- |Version   Date         Author               Remarks                         |
  -- |========  ===========  ===================  ================================|
  -- |1.0       17-AUG-2010  A.JUDE FELIX ANTONY  initial draft                   |
  -- |                                                                            |
  -- +===========================================================================+*/

PROCEDURE CONTENT  (mail_conn      IN OUT NOCOPY utl_smtp.connection
                   ,p_flag         IN VARCHAR2
                   ,p_issue           CLOB
                   ,p_subject      IN VARCHAR2
                   ,p_bgcolor_t    IN VARCHAR2
                   ,p_bgcolor_h    IN VARCHAR2
                   ,p_bgcolor_f    IN VARCHAR2
                   ,p_fcolor       IN VARCHAR2
                   ,p_colspan      IN VARCHAR2
                   ,p_lockbox      IN VARCHAR2
                   ,p_settlement   IN VARCHAR2
                   ,p_mail_status  IN VARCHAR2
                   ,p_cycle_date   IN VARCHAR2
                   )
AS
CURSOR wave_mail1
IS
SELECT   s_order,
         wave,
         program_name,
         us_status,
         us_volume,
         us_start_time,
         us_end_time,
         CA_STATUS
FROM     xxfin.xx_cycle_wave_setup
WHERE    rownum=0;

TYPE lc_cur_typ IS REF CURSOR;
wave_mail lc_cur_typ;
sgl_wave_mail  wave_mail1%ROWTYPE;
lc_query_Statement  VARCHAR2(1000) := NULL;

BEGIN
UTL_SMTP.write_data (mail_conn,'<HTML>');
UTL_SMTP.write_data (mail_conn,'<BODY>');

--+--------------------------------------------+
--BODY DESCRIPTION-----------------------------+
--+--------------------------------------------+

IF P_FLAG = 'B' THEN

UTL_SMTP.WRITE_DATA
         (mail_conn,
         '<P ALIGN="center"><B><FONT FACE="Verdana" SIZE="5" color="#153E7E">'
         ||P_SUBJECT||
         '</FONT></B></P>'
         );
UTL_SMTP.WRITE_DATA
         (mail_conn,
         '<P><B><FONT FACE="Verdana" SIZE="1" color="#336899">'
         );
UTL_SMTP.WRITE_DATA (mail_conn,'<HR>');
UTL_SMTP.WRITE_DATA (mail_conn,'</B></P>');
UTL_SMTP.WRITE_DATA
         (mail_conn,
         '<P ALIGN="left"><B><FONT FACE="Verdana" SIZE="3" color="#153E7E">
         Cycle Status as of  '||TO_CHAR (SYSDATE , 'DD/MM HH24:MI')||
         ' </FONT></B></P>'
         );
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA
         (mail_conn,
         '<P ALIGN="left"><B><U><FONT FACE="Verdana" SIZE="3" color="#153E7E">
         Issues and Updates
         </FONT></U></B></P>'
         );
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA
         (mail_conn,
         '<P ALIGN="left"><FONT FACE="Verdana" SIZE="2" color="#000000">'
         ||P_ISSUE||
         '</FONT></P>'
         );
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');

END IF;

--+--------------------------------------------+
--ATTACHMENT DESCRIPTION-----------------------+
--+--------------------------------------------+

IF P_FLAG = 'A' THEN

UTL_SMTP.WRITE_DATA(mail_conn,'<table cellPadding="1" border="1">');
UTL_SMTP.WRITE_DATA(mail_conn,'<tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'<tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA
         (mail_conn,'<td colspan="6" align="left" bgcolor="#C9C299"><font color="#000000" size="3"><B>'
         ||P_SUBJECT||
         '</B></font></td>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'</table>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');

END IF;

--+-------------------------------------------+
--CONTENT START-------------------------------+
--+-------------------------------------------+

FOR wave1 IN (SELECT DISTINCT(wave) wave FROM  xxfin.xx_cycle_wave_setup ORDER BY wave)
LOOP
UTL_SMTP.WRITE_DATA(mail_conn,'<table cellPadding="1" border="1">');
UTL_SMTP.WRITE_DATA(mail_conn,'<tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'<tr>');

IF wave1.wave = 'Wave5' THEN 
UTL_SMTP.WRITE_DATA
    (mail_conn,'<td colspan='||P_COLSPAN||'align="center" bgcolor='||P_BGCOLOR_T||'font color='||P_FCOLOR||' size="2"><B> Adv. Collections and Credit Check
</B></font></td>');
ELSE
UTL_SMTP.WRITE_DATA
    (mail_conn,'<td colspan='||P_COLSPAN||'align="center" bgcolor='||P_BGCOLOR_T||'font color='||P_FCOLOR||' size="2"><B>'||wave1.wave||'</B></font></td>');
END IF;

UTL_SMTP.WRITE_DATA(mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'<tr>');
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'PROGRAM_NAME'
    WHEN P_FLAG = 'A' THEN 'PROCESS'
    END)
    ||
    '</font></b></th>'
   );
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'US_STATUS'
    WHEN P_FLAG = 'A' THEN 'US'
    END)
    ||
    '</font></b></th>'
   );
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'US_VOLUME'
    WHEN P_FLAG = 'A' THEN 'VOL'
    END)
    ||
    '</font></b></th>'
   );
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'US_START_TIME'
    WHEN P_FLAG = 'A' THEN 'START'
    END)
    ||
    '</font></b></th>'
   );
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'US_END_TIME'
    WHEN P_FLAG = 'A' THEN 'END'
    END)
    ||
    '</font></b></th>'
   );
UTL_SMTP.WRITE_DATA
   (mail_conn,
    '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
    ||
    (CASE
    WHEN P_FLAG = 'B' THEN 'CA_STATUS'
    WHEN P_FLAG = 'A' THEN 'CA'
    END)
    ||
    '</font></b></th>'
   );
 UTL_SMTP.WRITE_DATA (mail_conn,'</tr>');

IF P_MAIL_STATUS = 'HISTORY' THEN

OPEN wave_mail FOR SELECT  s_order
                               ,wave
                               ,program_name
                               ,us_status
                               ,us_volume
                               ,us_start_time
                               ,us_end_time
                               ,CA_STATUS
                       FROM     xxfin.xx_cycle_wave_setup_history
                       WHERE    enable_flag = 'Y'
                       AND      cycle_date  = p_cycle_date
                       ORDER BY wave,s_order;

ElSIF P_MAIL_STATUS = 'CURRENT' THEN

OPEN wave_mail FOR SELECT  s_order
                               ,wave
                               ,program_name
                               ,us_status
                               ,us_volume
                               ,us_start_time
                               ,us_end_time
                               ,CA_STATUS
                       FROM     xxfin.xx_cycle_wave_setup
                       WHERE    enable_flag = 'Y'
                       AND      cycle_date  = p_cycle_date
                       ORDER BY wave,s_order;

END IF;

LOOP
   FETCH wave_mail
   INTO sgl_wave_mail;
   EXIT WHEN wave_mail%NOTFOUND;
        IF sgl_wave_mail.wave = wave1.wave THEN
           UTL_SMTP.WRITE_DATA (mail_conn,'<tr>');
           UTL_SMTP.WRITE_DATA (mail_conn,
                               '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                               || NVL(sgl_wave_mail.program_name,'-')||
                               '</font></td>'
                               );
           IF sgl_wave_mail.US_STATUS IS NOT NULL THEN

                   IF sgl_wave_mail.us_status = 'R' THEN

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_T||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
                   ELSE

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
                   END IF;
           ELSE
                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           END IF;


           IF sgl_wave_mail.us_volume IS NOT NULL THEN

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_volume,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_volume,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           ELSE
                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_volume,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_volume,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           END IF;

           IF sgl_wave_mail.us_start_time IS NOT NULL THEN

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_start_time,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_start_time,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           ELSE
                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_start_time,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_start_time,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           END IF;

           IF sgl_wave_mail.us_end_time IS NOT NULL THEN

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_end_time,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_end_time,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           ELSE
                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.us_end_time,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.us_end_time,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           END IF;

           IF sgl_wave_mail.ca_status IS NOT NULL THEN


                   IF sgl_wave_mail.ca_status = 'R' THEN

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_T||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.ca_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.ca_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
                   ELSE

                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td align="center" bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.ca_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.ca_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
                   END IF;


           ELSE
                   UTL_SMTP.WRITE_DATA (mail_conn,
                                       '<td bgColor='||P_BGCOLOR_F||'><font size="2">'
                                       ||
                                       (CASE
                                       WHEN P_FLAG = 'B' THEN (NVL(sgl_wave_mail.ca_status,'-'))
                                       WHEN P_FLAG = 'A' THEN (NVL(sgl_wave_mail.ca_status,' '))
                                       END)
                                       ||
                                       '</font></td>'
                                       );
           END IF;

           UTL_SMTP.WRITE_DATA (mail_conn, '</tr>');
        END IF;
END LOOP;
CLOSE WAVE_MAIL;
UTL_SMTP.WRITE_DATA(mail_conn,'</tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'</table>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
END LOOP;

--+---------------------------------------------+
--+LOCKBOX STATUS-------------------------------+
--+---------------------------------------------+

UTL_SMTP.WRITE_DATA(mail_conn,'<table cellPadding="1" border="1">');
UTL_SMTP.WRITE_DATA(mail_conn,'<tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'<tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA
         (mail_conn,'<td colspan="3" align="center" bgcolor='||P_BGCOLOR_T||'font color="#000000" size="2"><B>'
         ||'Lockbox'||
         '</B></font></td>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA
        (mail_conn,
        '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
        ||'Processed Files'||
        '</font></b></th>'
        );
UTL_SMTP.WRITE_DATA
       (mail_conn,
       '<th colspan="2" bgColor='||P_BGCOLOR_F||'><b><font color='||P_FCOLOR||' size="2">'
       ||P_LOCKBOX||
       '</font></b></th>'
       );
UTL_SMTP.WRITE_DATA (mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'</table>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');

--+---------------------------------------------+
--+SETTLEMENT STATUS----------------------------+
--+---------------------------------------------+

UTL_SMTP.WRITE_DATA(mail_conn,'<table cellPadding="1" border="1">');
UTL_SMTP.WRITE_DATA(mail_conn,'<tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'<tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA
         (mail_conn,'<td colspan="3" align="center" bgcolor='||P_BGCOLOR_T||'font color="#000000" size="2"><B>'
         ||'Settlement'||
         '</B></font></td>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA
        (mail_conn,
        '<th bgColor='||P_BGCOLOR_H||'><b><font color='||P_FCOLOR||' size="2">'
        ||'Settlement Time'||
        '</font></b></th>'
        );
UTL_SMTP.WRITE_DATA
       (mail_conn,
       '<th colspan="2" bgColor='||P_BGCOLOR_F||'><b><font color='||P_FCOLOR||' size="2">'
       ||P_SETTLEMENT||
       '</font></b></th>'
       );
UTL_SMTP.WRITE_DATA (mail_conn,'</tr>');
UTL_SMTP.WRITE_DATA(mail_conn,'</tbody>');
UTL_SMTP.WRITE_DATA(mail_conn,'</table>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');


UTL_SMTP.WRITE_DATA( mail_conn, UTL_TCP.crlf );

--+--------------------------------------------+
--BODY DESCRIPTION-----------------------------+
--+--------------------------------------------+

IF P_FLAG = 'B' THEN

UTL_SMTP.WRITE_DATA(mail_conn,'</FONT></B></P>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>Regards,<BR> Finance Production Support');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA(mail_conn,'<BR>');
UTL_SMTP.WRITE_DATA(mail_conn,
                  '<HR><B><FONT FACE="Verdana" SIZE="2" color="#336699">'
                   || UTL_TCP.crlf
                   );
UTL_SMTP.WRITE_DATA(mail_conn,'This is a System Generated mail . Please do not reply');
UTL_SMTP.WRITE_DATA(mail_conn,
                  '<HR><B><FONT FACE="Verdana" SIZE="2" color="#336699">'
                   || UTL_TCP.crlf
                   );
UTL_SMTP.WRITE_DATA(mail_conn,'<BR><BR>For any Queries , please mail : IT_FIN_Offshore@OFFICEDEPOT.COM ');
UTL_SMTP.WRITE_DATA(mail_conn,'</FONT></B>');

END IF;

UTL_SMTP.WRITE_DATA(mail_conn,'</HTML>');
UTL_SMTP.WRITE_DATA(mail_conn,'</BODY>');

END CONTENT;

/*-- +============================================================================+
  -- | PROCEDURE NAME : SENDING_MAIL                                              |
  -- |                                                                            |
  -- | DESCRIPTION    : This Procedure is use to Send Wave Status Mail            |
  -- |                                                                            |
  -- | PARAMETERS     : p_issues,p_cycle_date,p_mail_address                      |
  -- |                  p_mail_type,p_lockbox,p_settlement,p_mail_status          |
  -- |                                                                            |
  -- |Version   Date         Author               Remarks                         |
  -- |========  ===========  ===================  ================================|
  -- |1.0       17-AUG-2010  A.JUDE FELIX ANTONY  initial draft                   |
  -- |                                                                            |
  -- +============================================================================+*/

PROCEDURE SENDING_MAIL  (p_issues            CLOB     DEFAULT 'No Issues'
                        ,p_cycle_date   IN   VARCHAR2
                        ,p_mail_address IN   VARCHAR2 DEFAULT ''
                        ,p_mail_type         VARCHAR2 DEFAULT 'DEF'
                        ,p_lockbox      IN   VARCHAR2 DEFAULT '-'
                        ,p_settlement   IN   VARCHAR2 DEFAULT '-'
                        ,p_mail_status  IN   VARCHAR2
                        )
AS
   mailhost             VARCHAR2(100) := 'USCHMSX85.na.odcorp.net';
   mail_conn                              utl_smtp.connection;
   v_date               VARCHAR2(25);
   l_boundary           VARCHAR2(255)     default 'a1b2c3d4e3f2g1';
   lc_subject           VARCHAR2(100) := 'PROD OTS - Cycle Date '||TO_CHAR(TO_DATE(P_CYCLE_DATE,'DD-MON-RRRR'),'MM/DD')||' Wave Status';
   lc_attachment        VARCHAR2(100) := 'Cycle Date '||TO_CHAR(TO_DATE(P_CYCLE_DATE,'DD-MON-RRRR'),'MM-DD')||' - Wave Status.xls';
   CRLF                 VARCHAR2(10)  :=  CHR(10);
   lc_mail_address      CLOB          := ' ';
   lc_mail_address_temp CLOB          := ' ';
   lc_datafound         VARCHAR2(1)   := 'N';
CURSOR mail_address
IS
SELECT XFTV.target_value1
FROM apps.xx_fin_translatedefinition XFTD
    ,apps.xx_fin_translatevalues XFTV
WHERE XFTD.translate_id = XFTV.translate_id 
AND   XFTD.translation_name = 'XX_OD_WAVE_MAIL_ADDRESS'
AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
AND   SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
AND   XFTV.enabled_flag = 'Y'
AND   XFTD.enabled_flag = 'Y';

BEGIN

OPEN mail_address;
     LOOP
     FETCH mail_address
         INTO      lc_mail_address_temp;

         EXIT WHEN mail_address%NOTFOUND;

         lc_datafound := 'Y';

         lc_mail_address := lc_mail_address || ';' || lc_mail_address_temp;

END LOOP;

CLOSE mail_address;

IF lc_datafound = 'N' THEN

FND_FILE.PUT_LINE(FND_FILE.LOG, '***** No Mail Address Found *****' );

ELSE

FND_FILE.PUT_LINE(FND_FILE.LOG, 'MAIL_ADDRESS : ' || lc_mail_address);

END IF;


IF p_mail_type = 'ALL' THEN

      lc_mail_address := lc_mail_address||';'||p_mail_address;

ELSIF p_mail_type = 'SEL'  THEN

      lc_mail_address := p_mail_address;

END IF;

mail_conn := UTL_SMTP.open_connection (mailhost);
UTL_SMTP.HELO(mail_conn,mailhost);
UTL_SMTP.MAIL(mail_conn,'IT_FIN_Offshore@officedepot.com');
--+--------------------------------------------+
--CALLING PROC CONTENT FOR RCPT ADDRESS--------+
--+--------------------------------------------+
SPLIT_ADDRESS(
mail_conn     =>  mail_conn,
P_ADDRESS     =>  lc_mail_address,
P_DETAILS     =>  'RCPT');

UTL_SMTP.OPEN_DATA(mail_conn);
UTL_SMTP.WRITE_DATA(mail_conn,'From:'|| 'noreply@officedepot.com'|| UTL_TCP.crlf);

--+--------------------------------------------+
--CALLING PROC CONTENT FOR DISPLAY ADDRESS-----+
--+--------------------------------------------+
SPLIT_ADDRESS(
mail_conn     =>  mail_conn,
P_ADDRESS     =>  lc_mail_address,
P_DETAILS     =>  'TO');

--UTL_SMTP.WRITE_DATA(mail_conn,'Cc:'|| ''|| UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,'Subject:' || lc_subject || UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,'Content-Type: multipart/mixed; ' ||UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,' boundary= "' || l_boundary || '"' ||UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,UTL_TCP.crlf);

--+--------------------------------------------+
--BODY-----------------------------------------+
--+--------------------------------------------+

UTL_SMTP.WRITE_DATA(mail_conn,'--' || l_boundary || UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,'Content-Type: text/html;' ||UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,' charset=US-ASCII' || UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,UTL_TCP.crlf);

--+--------------------------------------------+
--CALLING PROC CONTENT FOR BODY----------------+
--+--------------------------------------------+

CONTENT(
mail_conn     =>  mail_conn,
p_flag        =>  'B',
p_issue       =>  p_issues,
p_subject     =>  lc_subject,
p_bgcolor_t   =>  '"#C9C299"',
p_bgcolor_h   =>  '"#ECE5B6"',
p_bgcolor_f   =>  '"#f7f7e7"',
p_fcolor      =>  '"#000000"',
p_colspan     =>  '"8"',
p_lockbox     =>  p_lockbox,        
p_settlement  =>  p_settlement,     
p_mail_status =>  p_mail_status,    
p_cycle_date  =>  p_cycle_date      
);

UTL_SMTP.WRITE_DATA( mail_conn, UTL_TCP.crlf );

--+--------------------------------------------+
--ATTACHMENT-----------------------------------+
--+--------------------------------------------+

UTL_SMTP.WRITE_DATA(mail_conn,'--' || l_boundary || UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,'Content-Type: text/html;' || UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,' name='||lc_attachment|| UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,'Content-Transfer_Encoding: 16bit'|| UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,'Content-Disposition: attachment;'|| UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,' filename='|| lc_attachment || UTL_TCP.crlf);
UTL_SMTP.WRITE_DATA(mail_conn,UTL_TCP.crlf);

--+--------------------------------------------+
--CALLING PROC CONTENT FOR ATTACHMENT----------+
--+--------------------------------------------+

CONTENT(
mail_conn     =>  mail_conn,
p_flag        =>  'A',
p_issue       =>  p_issues,
p_subject     =>  lc_subject,
p_bgcolor_t   =>  '"#6CC417"',
p_bgcolor_h   =>  '"#C3FDB8"',
p_bgcolor_f   =>  '"#f7f7e7"',
p_fcolor      =>  '"#000006"',
p_colspan     =>  '"6"',
p_lockbox     =>  p_lockbox,
p_settlement  =>  p_settlement,
p_mail_status =>  p_mail_status,
p_cycle_date  =>  p_cycle_date
);

UTL_SMTP.WRITE_DATA(mail_conn,UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,'--' || l_boundary || '--' ||UTL_TCP.crlf );
UTL_SMTP.WRITE_DATA(mail_conn,UTL_TCP.crlf || '.' || UTL_TCP.crlf );
UTL_SMTP.CLOSE_DATA(mail_conn );
UTL_SMTP.QUIT( mail_conn );

EXCEPTION
   WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
   THEN
      UTL_SMTP.quit (mail_conn);
      raise_application_error
                       (-20000,
                       'Failed to send mail due to the following error: '
                       || SQLERRM
                       );
   WHEN OTHERS
   THEN
      raise_application_error
                       (-20001,
                       'The following error has occured: '
                       || SQLERRM
                       );
END SENDING_MAIL;
END XX_UTL_SEND_MAIL_PKG;
/
show err;
/