create or replace 
PACKAGE BODY  XXOD_REASSIGNED_SR_DETAILS_PKG AS

/**************************************************************************
MODULE NAME:     XXOD_REASSIGNED_SR_DETAILS_PKG.pks
ORIGINAL AUTHOR: Venkateshwar Panduga
DATE:            29-MAR-2019
DESCRIPTION:

This package is used for to automate the Case Management Weekly DOB Report

CHANGE HISTORY:

VERSION DATE        AUTHOR         		DESCRIPTION
------- ---------   -------------- 		-------------------------------------
1.0     29-MAR-2019   Venkateshwar Panduga    Initial version
2.0     08-JUL-2019   Venkateshwar Panduga    Change file generation path
                                               for LNS

**************************************************************************/
 e_error                    EXCEPTION;
----------------------------------------------------------------------
-- FUNCTION: out
--
--   Procedure to print a message to the concurrent request out
----------------------------------------------------------------------


PROCEDURE out (p_message IN VARCHAR2) IS

BEGIN
  APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.OUTPUT, p_message);
EXCEPTION
  WHEN others THEN
    RAISE e_error;
END out;

----------------------------------------------------------------------------------
-- FUNCTION: put
--
--   Procedure to print a message without new line to the concurrent request out
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- FUNCTION: log
--
--   Procedure to print a message to the concurrent request log
------------------------------------------------------------------------------------
PROCEDURE log (p_message          IN VARCHAR2) IS

BEGIN
  APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG,  p_message);
  --APPS.FND_FILE.PUT_LINE(APPS.FND_FILE.LOG, TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || ' '||p_message);
EXCEPTION
  WHEN others THEN
    RAISE E_ERROR;
end log;
-----------------------------------------------------------------------------------
-- Procedure: XXOD_REASSIGNED_SR_DETAILS_PRC
--
--   This procedure is used for to extract data for Reassigned SR Details.
--   and sent mail to users.
------------------------------------------------------------------------------------
procedure XXOD_REASSIGNED_SR_DETAILS_PRC (ERRBUF OUT varchar2 , RETCODE OUT varchar2 , P_FROM_DATE   varchar2, ----date,
                                        P_TO_DATE   varchar2, ----date,
                                        p_problem_code varchar2)
as
cursor SR_CUR (p_from_date varchar2,p_to_date varchar2,p_problem_code varchar2)
is
SELECT  ciab.creation_date SR_CREATION_DATE
      ,ciab.incident_number
      ,ciab.incident_context
      ,CIAB.INCIDENT_ATTRIBUTE_1 ORIGINAL_ORDER_NUMBER
      ,ciab.incident_attribute_9 customer_account_number
      ,ciab.incident_attribute_11 dc_number
      ,ciab.external_attribute_1 sku
      ,CIAB.EXTERNAL_ATTRIBUTE_5 QUANTITY
      ,CIAB.RESOLUTION_CODE
       ,(SELECT NAME
        FROM CS_INCIDENT_STATUSES_TL CIS
        WHERE CIS.INCIDENT_STATUS_ID =CAUDIT.OLD_INCIDENT_STATUS_ID) OLD_STATUS
      ,(SELECT NAME
        FROM CS_INCIDENT_STATUSES_TL CIS
        WHERE  CIS.INCIDENT_STATUS_ID =CAUDIT.INCIDENT_STATUS_ID) NEW_STATUS
     ,(SELECT NAME
        FROM CS_INCIDENT_TYPES_TL CIT
        WHERE CIT.INCIDENT_TYPE_ID =CAUDIT.OLD_INCIDENT_TYPE_ID) OLD_INCIDENT_TYPE   
    ,(SELECT NAME
        FROM CS_INCIDENT_TYPES_TL CIT
        WHERE CIT.INCIDENT_TYPE_ID =CAUDIT.INCIDENT_TYPE_ID) NEW_INCIDENT_TYPE
     ,(SELECT GROUP_NAME||'-'||GROUP_DESC 
        FROM JTF_RS_GROUPS_TL JRG
        where CAUDIT.OLD_GROUP_ID= jrg.group_id ) OLD_GROUP_NAME       
     ,(SELECT GROUP_NAME||'-'||GROUP_DESC 
        FROM JTF_RS_GROUPS_TL JRG
        WHERE CAUDIT.GROUP_ID= JRG.GROUP_ID ) NEW_GROUP_NAME
        ,(SELECT RESOURCE_NAME
          FROM JTF_RS_RESOURCE_EXTNS_TL 
          where resource_id = CAUDIT.OLD_INCIDENT_OWNER_ID) OLD_RESOURCE_NAME
        ,(SELECT RESOURCE_NAME
          FROM JTF_RS_RESOURCE_EXTNS_TL 
          WHERE RESOURCE_ID = CIAB.INCIDENT_OWNER_ID) NEW_RESOURCE_NAME
         
  FROM CS_INCIDENTS_AUDIT_B CAUDIT
      ,cs_incidents_all_b ciab
  WHERE 1=1
  AND CAUDIT.INCIDENT_ID= CIAB.INCIDENT_ID
  AND CAUDIT.OLD_GROUP_ID in (100000255,100000256)
  and CAUDIT.GROUP_ID = 100000061  
  AND UPPER(CIAB.PROBLEM_CODE) = upper(p_problem_code) -----IN ('DELIVERY ONLY REQUEST')
    and CIAB.CREATION_DATE > TO_DATE(P_FROM_DATE,'YYYY/MM/DD HH24:MI:SS')  ---P_FROM_DATE  
   and CIAB.CREATION_DATE < TO_DATE(P_TO_DATE,'YYYY/MM/DD HH24:MI:SS')  ---P_TO_DATE 
 order by INCIDENT_NUMBER;
 
 cursor ITEM_QTY_SPILT_CUR(p_item varchar2,p_qty varchar2)
 is
select item,qty  from (
select REGEXP_SUBSTR(P_ITEM,'[^;]+', 1, level) ITEM ,REGEXP_SUBSTR(P_QTY,'[^;]+', 1, level) QTY   from DUAL
connect by REGEXP_SUBSTR(p_item, '[^;]+', 1, level) is not null 
connect by REGEXP_SUBSTR(p_qty, '[^;]+', 1, level) is not null)  
;
TYPE SR_CUR_REC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
is                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
  table of SR_CUR%ROWTYPE index by PLS_INTEGER; 
  
 P_SR_REC_TAB SR_CUR_REC; 
 
  L_FROM_DATE   varchar2(30);
  L_TO_DATE   varchar2(30);
  L_CNT number :=0;
  L_ITEM        varchar2(50);
  l_qty         varchar2(10);
  V_FILEHANDLE      UTL_FILE.FILE_TYPE;
V_LOCATION        VARCHAR2 (200) ;--------- := 'XXFIN_OUTBOUND_GLEXTRACT';
V_MODE            varchar2 (1)       := 'W'; 
V_FILENAME        varchar2(100) := 'REASSIGNED_SR_DETAILS' ;
L_SUBJECT         varchar2(2000) ;
LC_INSTANCE         varchar2 (100);
L_MESSAGE varchar2(2000) := 'Attached report for the Case Management Weekly DOB Report for the week';
LC_MAIL_FROM        VARCHAR2 (100)      := 'noreply@officedepot.com';
gn_user_id fnd_concurrent_requests.requested_by%TYPE;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
GN_RESP_ID FND_RESPONSIBILITY.RESPONSIBILITY_ID%type;
GN_RESP_APPL_ID FND_RESPONSIBILITY.APPLICATION_ID%type;
l_email_list          VARCHAR2(2000) := NULL;
begin

log('Starting of the program');

--select (trunc(sysdate-7 , 'Day')+5)+8/24 +29/1440 into L_FROM_DATE from DUAL ;
--
--dbms_output.put_line('l_from_Date: '|| L_FROM_DATE);
--
--select (trunc(sysdate-1 , 'Day')+4)+8/24 +31/1440 into L_TO_DATE from DUAL ;
--
--DBMS_OUTPUT.PUT_LINE('L_TO_DATE: '|| L_TO_DATE);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
FND_GLOBAL.APPS_INITIALIZE (GN_USER_ID, GN_RESP_ID, GN_RESP_APPL_ID); 

--L_FROM_DATE := FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
--L_TO_DATE := fnd_date.canonical_to_date(P_TO_DATE) ;

log('P_FROM_DATE: '|| P_FROM_DATE);
log('P_TO_DATE: '|| P_TO_DATE);  
log('Problem Code : '|| P_PROBLEM_CODE); 
--L_FROM_DATE :=FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
--log('L_FROM_DATE: '|| L_FROM_DATE); 
--L_TO_DATE :=FND_DATE.CANONICAL_TO_DATE(P_TO_DATE);
--log('L_TO_DATE: '|| L_TO_DATE); 

begin
--- Commented for V2.0
 /*   SELECT NAME
--	  into LC_INSTANCE
--    from V$DATABASE; 
--    */
 --- Added for V2.0
 SELECT sys_context('userenv','DB_NAME')
		into LC_INSTANCE
		FROM dual;   
 end; 
  IF lc_instance = 'GSIPRDGB' 
        then
         L_SUBJECT   := lc_instance||' Case Management Weekly DOB Report';
        else
        L_SUBJECT :=lc_instance||' Please Ignore this email: Case Management Weekly DOB Report ';
 end if;
 begin
     select TARGET_VALUE1 ,TARGET_VALUE10
     INTO l_email_list ,V_LOCATION
	   FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
	   where DEF.TRANSLATE_ID=VAL.TRANSLATE_ID
	     AND   def.translation_name = 'XX_OD_REASSIGN_LIST' ;
 EXCEPTION
 WHEN OTHERS THEN
	 null;
  END;
 
    V_FILENAME := V_FILENAME||'_'||LC_INSTANCE ||'.csv';

--V_FILENAME := V_FILENAME||'_'||LC_INSTANCE||'_'||TO_CHAR(sysdate,'DD-MON-YYYY')||'.csv';

log('File Name : '|| V_FILENAME);
------Added for V2.0
log('File location : '||V_LOCATION);
-----End for V2.0

 V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME, V_MODE);
 
UTL_FILE.PUT_LINE (V_FILEHANDLE,'SR_CREATION_DATE'||','||	'INCIDENT_NUMBER'||','||'INCIDENT_CONTEXT'||','||'ORIGINAL_ORDER_NUMBER'||','||
'CUSTOMER_ACCOUNT_NUMBER'||','||'DC_NUMBER'||','||	'SKU'||','||'QUANTITY'||','||
'RESOLUTION_CODE'||','||	'OLD_STATUS'||','||'NEW_STATUS'||','||	'OLD_INCIDENT_TYPE'||','||	'NEW_INCIDENT_TYPE'||','||	'OLD_GROUP_NAME'||','||'NEW_GROUP_NAME'
||','||'OLD_RESOURCE_NAME'||','||'NEW_RESOURCE_NAME');

out('SR_CREATION_DATE'||','||	'INCIDENT_NUMBER'||','||'INCIDENT_CONTEXT'||','||'ORIGINAL_ORDER_NUMBER'||','||
'CUSTOMER_ACCOUNT_NUMBER'||','||'DC_NUMBER'||','||	'SKU'||','||'QUANTITY'||','||
'RESOLUTION_CODE'||','||	'OLD_STATUS'||','||'NEW_STATUS'||','||	'OLD_INCIDENT_TYPE'||','||	'NEW_INCIDENT_TYPE'||','||	'OLD_GROUP_NAME'||','||'NEW_GROUP_NAME'
||','||'OLD_RESOURCE_NAME'||','||'NEW_RESOURCE_NAME');



open SR_CUR (P_FROM_DATE,P_TO_DATE,p_problem_code);  ------(L_FROM_DATE,L_TO_DATE,p_problem_code);    --(P_FROM_DATE,P_TO_DATE) ;----- 
LOOP
FETCH SR_CUR BULK COLLECT INTO P_SR_REC_TAB;
--dbms_output.put_line('inside loop: ');
  EXIT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
  when P_SR_REC_TAB.COUNT = 0; 
for I in P_SR_REC_TAB.first..P_SR_REC_TAB.last  
 LOOP 

for J in ITEM_QTY_SPILT_CUR(P_SR_REC_TAB(I).SKU,P_SR_REC_TAB(I).QUANTITY)
LOOP

DBMS_OUTPUT.PUT_LINE('l_item :'||J.ITEM);
DBMS_OUTPUT.PUT_LINE('l_qty :'||j.QTY);

UTL_FILE.PUT_LINE (V_FILEHANDLE, P_SR_REC_TAB(I).SR_CREATION_DATE             ||','||
                                 P_SR_REC_TAB(I).INCIDENT_NUMBER              ||','||
                                 P_SR_REC_TAB(I).INCIDENT_CONTEXT             ||','||
                                 P_SR_REC_TAB(I).ORIGINAL_ORDER_NUMBER        ||','||
                                 P_SR_REC_TAB(I).CUSTOMER_ACCOUNT_NUMBER      ||','||
                                 P_SR_REC_TAB(I).DC_NUMBER                    ||','||
                                  '''' ||J.ITEM                         ||','||
                                 J.QTY                          ||','||
                                 P_SR_REC_TAB(I).RESOLUTION_CODE              ||','||
                                 P_SR_REC_TAB(I).OLD_STATUS                   ||','||
                                 P_SR_REC_TAB(I).NEW_STATUS                   ||','||
                                 P_SR_REC_TAB(I).OLD_INCIDENT_TYPE            ||','||
                                 P_SR_REC_TAB(I).NEW_INCIDENT_TYPE            ||','||
                                 P_SR_REC_TAB(I).OLD_GROUP_NAME               ||','||
                                 P_SR_REC_TAB(I).NEW_GROUP_NAME               ||','||
                                 replace(P_SR_REC_TAB(I).OLD_RESOURCE_NAME,',', ' ')            ||','||
                                 replace(P_SR_REC_TAB(I).NEW_RESOURCE_NAME ,',', ' ') 
                                );

                            out( P_SR_REC_TAB(I).SR_CREATION_DATE             ||','||
                                 P_SR_REC_TAB(I).INCIDENT_NUMBER              ||','||
                                 P_SR_REC_TAB(I).INCIDENT_CONTEXT             ||','||
                                 P_SR_REC_TAB(I).ORIGINAL_ORDER_NUMBER        ||','||
                                 P_SR_REC_TAB(I).CUSTOMER_ACCOUNT_NUMBER      ||','||
                                 P_SR_REC_TAB(I).DC_NUMBER                    ||','||
                                 J.ITEM                         ||','||
                                 J.QTY                          ||','||
                                 P_SR_REC_TAB(I).RESOLUTION_CODE              ||','||
                                 P_SR_REC_TAB(I).OLD_STATUS                   ||','||
                                 P_SR_REC_TAB(I).NEW_STATUS                   ||','||
                                 P_SR_REC_TAB(I).OLD_INCIDENT_TYPE            ||','||
                                 P_SR_REC_TAB(I).NEW_INCIDENT_TYPE            ||','||
                                 P_SR_REC_TAB(I).OLD_GROUP_NAME               ||','||
                                 P_SR_REC_TAB(I).NEW_GROUP_NAME               ||','||
                                 replace(P_SR_REC_TAB(I).OLD_RESOURCE_NAME,',', ' ')            ||','||
                                 replace(P_SR_REC_TAB(I).NEW_RESOURCE_NAME ,',', ' ') 
                                );                                

L_CNT :=L_CNT+1;
end loop;
end LOOP;
end LOOP;
CLOSE SR_CUR;
UTL_FILE.FCLOSE (V_FILEHANDLE); 
DBMS_OUTPUT.PUT_LINE('Count :'||L_CNT);

log('Before sending mail');        
    SEND_MAIL_PRC (
      LC_MAIL_FROM ,
      l_email_list,
      L_SUBJECT,
      L_MESSAGE ||' from '||P_FROM_DATE|| ' A.M. to '  || P_TO_DATE ||' A.M. '
      ||CHR (13),
      V_FILENAME,
      V_LOCATION                               --default null
   ) ; 
   
log(' After calling Email Notification ' ); 

---- Added logic for 2.0
begin
log(' Before removing file ' ); 

UTL_FILE.FREMOVE (
location => V_LOCATION       ,    -----in varchar2,
FILENAME =>V_FILENAME         -----IN VARCHAR2
);

log(' After removing file ' ); 
exception
when OTHERS then
log('Error while removing file: '||SQLERRM);
end;

--- End logic for 2.0
	  
EXCEPTION
when OTHERS then
log('Error in main proc: '||SQLERRM);
dbms_output.put_line('error :'||SQLERRM);
end XXOD_REASSIGNED_SR_DETAILS_PRC;

-- --------------------------------------------------------------------------------------------------------------
-- -------   send_mail_prc Procedure is used for mailing functionality
-- --------------------------------------------------------------------------------------------------------------
 PROCEDURE SEND_MAIL_PRC (
      p_sender      IN   VARCHAR2,
      p_recipient   IN   VARCHAR2,
      p_subject     IN   VARCHAR2,
      p_message     IN   CLOB,
      attachlist    IN   VARCHAR2,                            -- default null,
      DIRECTORY     IN   VARCHAR2                               --default null
   )
   AS
      --l_mailhost     VARCHAR2 (255)          := 'gwsmtp.usa.net';
      l_mailhost     VARCHAR2 (100)  := fnd_profile.VALUE ('XX_COMN_SMTP_MAIL_SERVER');
                                                                        --2.0
      l_mail_conn    UTL_SMTP.connection;
      v_add_src      VARCHAR2 (4000);
      v_addr         VARCHAR2 (4000);
      slen           NUMBER                  := 1;
      crlf           VARCHAR2 (2)            := CHR (13) || CHR (10);
      i              NUMBER (12);
      j              NUMBER (12);
      len            NUMBER (12);
      len1           NUMBER (12);
      part           NUMBER (12)             := 16384;
      /*extraashu start*/
      smtp           UTL_SMTP.connection;
      reply          UTL_SMTP.reply;
      file_handle    BFILE;
      file_exists    BOOLEAN;
      block_size     NUMBER;
      file_len       NUMBER;
      pos            NUMBER;
      total          NUMBER;
      read_bytes     NUMBER;
      DATA           RAW (200);
      my_code        NUMBER;
      my_errm        VARCHAR2 (32767);
      mime_type      VARCHAR2 (50);
      myhostname     VARCHAR2 (255);
      att_table      DBMS_UTILITY.uncl_array;
      att_count      NUMBER;
      tablen         BINARY_INTEGER;
      loopcount      NUMBER;
      /*extraashu end*/
      l_stylesheet   CLOB
         := '
       <html><head>
       <style type="text/css">
                   body     { font-family     : Verdana, Arial;
                              font-size       : 10pt;}

                   .green   { color           : #00AA00;
                              font-weight     : bold;}

                   .red     { color           : #FF0000;
                              font-weight     : bold;}

                   pre      { margin-left     : 10px;}

                   table    { empty-cells     : show;
                              border-collapse : collapse;
                              width           : 100%;
                              border          : solid 2px #444444;}

                   td       { border          : solid 1px #444444;
                              font-size       : 12pt;
                              padding         : 2px;}

                   th       { background      : #EEEEEE;
                              border          : solid 1px #444444;
                              font-size       : 12pt;
                              padding         : 2px;}

                   dt       { font-weight     : bold; }

                  </style>
                 </head>
                 <body>';
               /*EXTRAASHU START*/
--    Procedure WriteLine(
--          line          in      varchar2 default null
--       ) is
--       Begin
--          utl_smtp.Write_Data( smtp, line||utl_tcp.CRLF );
--       End;
   BEGIN
      l_mail_conn := UTL_SMTP.open_connection (l_mailhost, 25);
      UTL_SMTP.helo (l_mail_conn, l_mailhost);
      UTL_SMTP.mail (l_mail_conn, p_sender);

      IF (INSTR (p_recipient, ',') = 0)
      THEN
         fnd_file.put_line (fnd_file.LOG, 'rcpt ' || p_recipient);
         UTL_SMTP.rcpt (l_mail_conn, p_recipient);
      ELSE
         v_add_src := p_recipient || ',';

         WHILE (INSTR (v_add_src, ',', slen) > 0)
         LOOP
            v_addr :=
               SUBSTR (v_add_src,
                       slen,
                       INSTR (SUBSTR (v_add_src, slen), ',') - 1
                      );
            slen := slen + INSTR (SUBSTR (v_add_src, slen), ',');
             fnd_file.put_line (fnd_file.LOG, 'rcpt ' || v_addr);
            UTL_SMTP.rcpt (l_mail_conn, v_addr);
         END LOOP;
      END IF;
     --UTL_SMTP.write_data (l_mail_conn, crlf);
      --utl_smtp.rcpt(l_mail_conn, p_recipient);
      UTL_SMTP.open_data (l_mail_conn);
      UTL_SMTP.write_data (l_mail_conn,
                              'MIME-version: 1.0'
                           || crlf
                           || 'Content-Type: text/html; charset=ISO-8859-15'
                           || crlf
                           || 'Content-Transfer-Encoding: 8bit'
                           || crlf
                           || 'Date: '
                           || TO_CHAR ((SYSDATE - 1 / 24),
                                       'Dy, DD Mon YYYY hh24:mi:ss',
                                       'nls_date_language=english'
                                      )
                           || crlf
                           || 'From: '
                           || p_sender
                           || crlf
                           || 'Subject: '
                           || p_subject
                           || crlf
                           || 'To: '
                           || p_recipient
                           || crlf
                          );
      UTL_SMTP.write_data
         (l_mail_conn,
             'Content-Type: multipart/mixed; boundary="gc0p4Jq0M2Yt08jU534c0p"'
          || crlf
         );
      UTL_SMTP.write_data (l_mail_conn, 'MIME-Version: 1.0' || crlf);
      UTL_SMTP.write_data (l_mail_conn, crlf);
--              UTL_SMTP.write_data (l_mail_conn,'--gc0p4Jq0M2Yt08jU534c0p'||crlf);
--              UTL_SMTP.write_data (l_mail_conn,'Content-Type: text/plain'||crlf);
--              UTL_SMTP.write_data (l_mail_conn,crlf);
            -- UTL_SMTP.write_data (l_mail_conn,  Body ||crlf);
      UTL_SMTP.write_data (l_mail_conn, crlf);
      UTL_SMTP.write_data (l_mail_conn, '--gc0p4Jq0M2Yt08jU534c0p' || crlf);
      UTL_SMTP.write_data (l_mail_conn,
                              'Content-Type: text/html; charset=ISO-8859-15'
                           || crlf
                          );
      UTL_SMTP.write_data (l_mail_conn,
                           'Content-Transfer-Encoding: 8bit' || crlf || crlf
                          );
      UTL_SMTP.write_raw_data (l_mail_conn,
                               UTL_RAW.cast_to_raw (l_stylesheet));
      i := 1;
      len := DBMS_LOB.getlength (p_message);

      WHILE (i < len)
      LOOP
         UTL_SMTP.write_raw_data
                            (l_mail_conn,
                             UTL_RAW.cast_to_raw (DBMS_LOB.SUBSTR (p_message,
                                                                   part,
                                                                   i
                                                                  )
                                                 )
                            );
         i := i + part;
      END LOOP;

      /*j:= 1;
      len1 := DBMS_LOB.getLength(p_message1);
      WHILE (j < len1) LOOP
          utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw(DBMS_LOB.SubStr(p_message1,part, i)));
          j := j + part;
      END LOOP;*/
      UTL_SMTP.write_raw_data (l_mail_conn,
                               UTL_RAW.cast_to_raw ('</body></html>')
                              );
          /*EXTRAASHU START*/
--        WriteLine;
      UTL_SMTP.write_data (l_mail_conn, crlf);
      --  WriteLine( '--gc0p4Jq0M2Yt08jU534c0p' );
      UTL_SMTP.write_data (l_mail_conn, '--gc0p4Jq0M2Yt08jU534c0p' || crlf);
      -- Split up the attachment list
      loopcount := 0;

      SELECT COUNT (*)
        INTO ATT_COUNT
        FROM TABLE (xx_int_err_notificatn_pkg.SPLIT (attachlist, NULL));

      IF attachlist IS NOT NULL AND DIRECTORY IS NOT NULL
      THEN
         FOR I IN (SELECT LTRIM (RTRIM (COLUMN_VALUE)) AS ATTACHMENT
                     FROM TABLE (xx_int_err_notificatn_pkg.SPLIT (attachlist, NULL)))
         LOOP
            loopcount := loopcount + 1;
            fnd_file.put_line (fnd_file.LOG,
                               'Attaching: ' || DIRECTORY || '/'
                               || i.attachment
                              );
            UTL_FILE.fgetattr (DIRECTORY,
                               i.attachment,
                               file_exists,
                               file_len,
                               block_size
                              );

            IF file_exists
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Getting mime_type for the attachment'
                                 );


              mime_type := 'text/plain';
               --  WriteLine( 'Content-Type: '||mime_type );
               UTL_SMTP.write_data (l_mail_conn,
                                    'Content-Type: ' || mime_type || crlf
                                   );
               --    WriteLine( 'Content-Transfer-Encoding: base64');
               UTL_SMTP.write_data (l_mail_conn,
                                    'Content-Transfer-Encoding: base64'
                                    || crlf
                                   );
               --WriteLine( 'Content-Disposition: attachment; filename="'||i.attachment||'"' );
               UTL_SMTP.write_data
                             (l_mail_conn,
                                 'Content-Disposition: attachment; filename="'
                              || REPLACE (i.attachment, '.req', '.txt')
                              || '"'
                              || crlf
                             );
               --   WriteLine;
               UTL_SMTP.write_data (l_mail_conn, crlf);
               file_handle := BFILENAME (DIRECTORY, i.attachment);
               pos := 1;
               total := 0;
               file_len := DBMS_LOB.getlength (file_handle);
               DBMS_LOB.OPEN (file_handle, DBMS_LOB.lob_readonly);

               LOOP
                  IF pos + 57 - 1 > file_len
                  THEN
                     read_bytes := file_len - pos + 1;
                     fnd_file.put_line (fnd_file.LOG,
                                        'Last read - Start: ' || pos
                                       );
                  ELSE
                     fnd_file.put_line (fnd_file.LOG,
                                        'Reading - Start: ' || pos
                                       );
                     read_bytes := 57;
                  END IF;

                  total := total + read_bytes;
                  DBMS_LOB.READ (file_handle, read_bytes, pos, DATA);
                  UTL_SMTP.write_raw_data (l_mail_conn,
                                           UTL_ENCODE.base64_encode (DATA)
                                          );
                  --utl_smtp.write_raw_data(smtp,data);
                  pos := pos + 57;

                  IF pos > file_len
                  THEN
                     EXIT;
                  END IF;
               END LOOP;

               fnd_file.put_line (fnd_file.LOG, 'Length was ' || file_len);
               DBMS_LOB.CLOSE (file_handle);

               IF (loopcount < att_count)
               THEN
                  --WriteLine;
                  UTL_SMTP.write_data (l_mail_conn, crlf);
                  --WriteLine( '--gc0p4Jq0M2Yt08jU534c0p' );
                  UTL_SMTP.write_data (l_mail_conn,
                                       '--gc0p4Jq0M2Yt08jU534c0p' || crlf
                                      );
               ELSE
                  --WriteLine;
                  UTL_SMTP.write_data (l_mail_conn, crlf);
                  -- WriteLine( '--gc0p4Jq0M2Yt08jU534c0p--' );
                  UTL_SMTP.write_data (l_mail_conn,
                                       '--gc0p4Jq0M2Yt08jU534c0p--' || crlf
                                      );
                  fnd_file.put_line (fnd_file.LOG, 'Writing end boundary');
               END IF;
            ELSE
               fnd_file.put_line (fnd_file.LOG,
                                     'Skipping: '
                                  || DIRECTORY
                                  || '/'
                                  || i.attachment
                                  || 'Does not exist.'
                                 );
            END IF;
         END LOOP;
      END IF;

      /*EXTRAASHU END*/
      UTL_SMTP.close_data (l_mail_conn);
      UTL_SMTP.QUIT (L_MAIL_CONN);
   END SEND_MAIL_PRC;
    Function split
   (
      p_list varchar2,
      p_del varchar2 --:= ','
   ) return split_tbl pipelined
   is
      p_del1 varchar2(1):= ',';
      l_idx    pls_integer;
      l_list    varchar2(32767) := p_list;
      l_value    varchar2(32767);
   begin
   p_del1 := ',';
      loop
         l_idx := instr(l_list,p_del1);
         if l_idx > 0 then
            pipe row(substr(l_list,1,l_idx-1));
            l_list := substr(l_list,l_idx+length(p_del1));
         else
            pipe row(l_list);
            exit;
         end if;
      end loop;
      RETURN;
   end split;


END XXOD_REASSIGNED_SR_DETAILS_PKG;
/
