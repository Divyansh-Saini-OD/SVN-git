create or replace procedure XX_CE_ISSUE_JRNLS_PRC( RETCODE OUT  number
                               ,errbuf OUT VARCHAR2)
is 
lc_mail_from varchar2(100):='OM_HVOP';
lc_mail_recipient VARCHAR2(1000);
--lc_mail_subject VARCHAR2(1000) := 'HVOP Pending Sales' ;
--CH ID#34203 Start
--lc_mail_host VARCHAR2(100):= 'USCHMSX83.na.odcorp.net';
lc_mail_host VARCHAR2(100):= fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
--CH ID#34203 End
lc_mail_conn utl_smtp.connection;
crlf  VARCHAR2(10) := chr(13) || chr(10);
slen number :=1;
v_addr Varchar2(1000);
lc_instance varchar2(100);
lc_msg_body CLOB;
lc_mail_subject     VARCHAR2(2000);
-- -- Added as per Ver 1.4
lc_mail_body_det1        VARCHAR2(5000):=NULL;
lc_mail_body_det2       VARCHAR2(5000):=NULL;
lc_mail_header1      VARCHAR2(1000);
lc_mail_body_det3       VARCHAR2(5000):=NULL;
lc_mail_body_det4       VARCHAR2(5000):=NULL;
lc_mail_body_det5       VARCHAR2(5000):=NULL;
lc_mail_body_det6       VARCHAR2(5000):=NULL;
lc_mail_header2         VARCHAR2(1000);
lc_mail_body1        VARCHAR2(5000):=NULL;
lc_mail_body2       VARCHAR2(5000):=NULL;
lc_mail_header      VARCHAR2(1000);
lc_mail_body3       VARCHAR2(5000):=NULL;
lc_mail_body4       VARCHAR2(5000):=NULL;
lc_mail_body5       VARCHAR2(5000):=NULL;
lc_mail_body6       VARCHAR2(5000):=NULL;
LC_MAIL_BODY7       varchar2(5000):=null; 	
begin
lc_mail_conn := utl_smtp.open_connection(lc_mail_host,25);
--lc_mail_recipient := 'bala.edupuganti@officedepot.com,bapuji.nanapaneni@officedepot.com';
lc_mail_recipient := 'l.guravarajapet@officedepot.com';
--lc_mail_recipient := P_email_list;
utl_smtp.helo(lc_mail_conn, lc_mail_host);
utl_smtp.mail(lc_mail_conn, lc_mail_from);
--utl_smtp.rcpt(lc_mail_conn,lc_mail_recipient);
if (instr(lc_mail_recipient,',') = 0) then
v_addr:= lc_mail_recipient;
utl_smtp.rcpt(lc_mail_conn,v_addr);
else
lc_mail_recipient := replace(lc_mail_recipient,' ','_') || ',';
while (instr(lc_mail_recipient,',',slen)> 0) loop
v_addr := substr(lc_mail_recipient,slen,instr(substr(lc_mail_recipient,slen),',')-1);
--lc_mail_recipient := substr(lc_mail_recipient,slen,instr(substr(lc_mail_recipient,slen),',')-1);
slen := slen + instr(substr(lc_mail_recipient,slen),',');
utl_smtp.rcpt(lc_mail_conn,v_addr);
end loop;
end if;
select INSTANCE_NAME into LC_INSTANCE from V$INSTANCE;
LC_MAIL_SUBJECT := 'HVOP ERROR (Pending Sales) IN - ' || LC_INSTANCE;
LC_MAIL_HEADER1 := '<TABLE border="1"><TR align="left"><TH><B>  </B></TH><TH><B>SAS</B></TH><TH><B>OM Interface</B></TH><TH><B>OM</B></TH><TH><B>Total</B></TH><TH><B>ORDT</B></TH></TR>';  
UTL_SMTP.DATA
         (lc_mail_conn,
             'From:'
          || lc_mail_from
          || UTL_TCP.crlf
          || 'To: '
          || v_addr
          || UTL_TCP.crlf
          || 'Subject: '
          || lc_mail_subject
          || UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
	  ||utl_tcp.CRLF
	  ||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR>Hi All,<BR><BR>'
          || crlf
          || crlf
          || crlf
          ||'***********  Order And Receipt Summary  ***********:<BR><BR>'
          ||crlf
          ||crlf
          ||lc_mail_header1          
          ||'</TABLE><BR>'
          || crlf
          || crlf
          || crlf
          ||'***********  Payments Missing IN ORDT  ***********:<BR><BR>'
          ||crlf
          ||crlf          	  
          ||'</TABLE><BR>'
          ||crlf
          ||crlf
          ||crlf
          || '***********  HVOP Errors (Pending Sales) In Dollars By Each Track  ***********:<BR><BR>'
          || crlf
	  || crlf	  
	  ||'</TABLE><BR>'
          || crlf
          || crlf
          || '<BR>----------------------------------------------------------------------------------------------<BR>'
		  || crlf
	      || 'Note: OM will research errors in others category. They  will be adjusted into appropriate track.'
	      || crlf
          || '<BR>----------------------------------------------------------------------------------------------<BR><BR><BR>'
          || crlf||'</BODY></HTML>'
         );
UTL_SMTP.QUIT(LC_MAIL_CONN);
--x_mail_sent_status := 'Y';

EXCEPTION
 when UTL_SMTP.TRANSIENT_ERROR or UTL_SMTP.PERMANENT_ERROR then
   raise_application_error(-20000, 'Unable to send mail: '||sqlerrm);         
end xx_ce_issue_jrnls_prc;