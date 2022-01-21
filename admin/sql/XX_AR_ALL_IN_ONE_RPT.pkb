CREATE OR REPLACE
PACKAGE BODY XX_AR_ALL_IN_ONE_RPT
AS
  -- +====================================================================+
  -- |                  Office Depot - Project Simplify                   |
  -- +====================================================================+
  -- | Name         : XX_AR_ALL_IN_ONE_RPT                                |
  -- | Description  : This package is used to get the Daily Invoices count|
  -- |                and amount for all billing methods in single report |
  -- |                                                                    |
  -- |Change Record:                                                      |
  -- |===============                                                     |
  -- |Version  Date         Author         Remarks                        |
  -- |=======  ===========  =============  ===============================|
  -- | 1       28-AUG-2012  Ankit Arora    Initial version                |
  -- |                                     Created for Defect 24869       |
  -- | 1.1     13-NOV-2015  Vasu Raparla   Removed Schema References      |
  -- |                                     for R12.2                      |
  -- | 1.2     01-JUN-2016  Suresh Naragam Changes related Mod 4B         |
  -- |                                     Release 4 (Defect#2185)        |
  -- | 1.3     25-MAY-2018  Punit Gupta CG Retrofit R1390 - OD AR         |
  -- |                                     Billing All in one Report      |
  -- |                                     Defect NAIT-43451              |
  -- +====================================================================+
  -- +====================================================================+
  -- | Name        : XX_AR_ALL_IN_ONE_RPT.MAIN                            |
  -- | Description : This procedure is used to trigger all other procedure|
  -- |               for all delivery methods                             |
  -- |                                                                    |
  -- | Parameters  : 1. p_print_date                                      |
  -- |               2  p_email_address                                   |
  -- |               3. p_sender_address                                  |
  -- |                                                                    |
  -- | Returns     :   x_errbuf, x_ret_code                               |
  -- |                                                                    |
  -- |                                                                    |
  -- +====================================================================+
  -----------------------------------
  --- Global Variable Declaration ---
  -----------------------------------
  lc_error_loc VARCHAR2(2000);
TYPE t_reqid
IS
  TABLE OF NUMBER;
  ln_req_id t_reqid;
TYPE t_req_date
IS
  TABLE OF VARCHAR2(30);
  lv_req_start t_req_date;
  lv_req_end t_req_date;
TYPE t_conc_prog
IS
  TABLE OF VARCHAR2(240);
  lv_conc_name t_conc_prog;
TYPE t_threadid
IS
  TABLE OF VARCHAR2(30);
  lv_thread_id t_threadid;
  lc_prog_name fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
  lc_child_prog_name1 fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
  lc_child_prog_name2 fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
  lc_child_prog_name3 fnd_concurrent_programs_vl.concurrent_program_name%TYPE;
  

  
PROCEDURE xx_send_email(
    p_print_date      IN VARCHAR2 ,
    p_email_address   IN VARCHAR2 ,
    p_sender_address  IN VARCHAR2,
    p_request_id      IN NUMBER,
    p_delivery_method IN VARCHAR2 ,
    P_START_TIME      IN VARCHAR2 ,
    P_END_TIME        IN VARCHAR2 ,
	p_org_id          IN VARCHAR2
    
  )
AS
  lc_email_subject  VARCHAR2(100)   := NULL ;
  lc_email_body     VARCHAR2(10000) := NULL ;
  lc_sender_address VARCHAR2(100)   := NULL ;
  lc_email_address  VARCHAR2(100)   := NULL ;
  lc_REQUEST_ID      NUMBER := P_REQUEST_ID;
  ln_conc_request_id NUMBER ;
  ln_this_request_id NUMBER        := NULL ;
  lc_mail_host       VARCHAR2(100) := NULL ;
  v_mail_conn utl_smtp.connection;
  lc_instance      VARCHAR2(100) := NULL;
  lc_host_name     VARCHAR2(100) := NULL;
  lc_source_field1 VARCHAR2(100) := NULL ;
  lc_file_name     VARCHAR2(150) := 'Daily_Billing_Summary_for_' || SUBSTR(p_print_date,1,10)||'.csv';
  lc_email_attachment CLOB       := NULL;
  ln_org_id VARCHAR2(10)         := p_org_id ;
  lc_paydoc_count_total        VARCHAR2(100) := NULL ; 
  lc_paydoc_amount_total       VARCHAR2(100) := NULL;
  lc_infodoc_count_total       VARCHAR2(100) := NULL;
  lc_infodoc_amount_total      VARCHAR2(100) := NULL;
  lc_total_count               VARCHAR2(100) := NULL;
  lc_total_amount              VARCHAR2(100) := NULL;
  lc_attachment_record_details VARCHAR2(1000) := NULL;
  
  lc_doc_type              VARCHAR2(100) := NULL;
  --CURSOR lcu_header ( P_START_TIME IN VARCHAR2, P_END_TIME IN VARCHAR2 )
  
  CURSOR lcu_header ( P_START_TIME IN VARCHAR2  , P_ORG_ID IN VARCHAR2 )
  IS
     SELECT PROGRAM_NAME, DATE_PARAMETER,  to_char(START_TIME,'DD-MON-YYYY HH24:MI:SS') START_TIME,  to_char(END_TIME,'DD-MON-YYYY HH24:MI:SS') END_TIME FROM
      (
	    SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME ,FCR.ARGUMENT2 DATE_PARAMETER, actual_start_date START_TIME , actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR, FND_CONCURRENT_PROGRAMS_TL FCP, fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR Invoice Manage Frequencies Master'
         AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) =TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
        UNION ALL
        SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME, FCR.ARGUMENT5 DATE_PARAMETER, actual_start_date START_TIME , actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR,FND_CONCURRENT_PROGRAMS_TL FCP,fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR Validate Print New Consolidated Billing Invoices'
        AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) =TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
        UNION ALL
        SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME , FCR.ARGUMENT1 DATE_PARAMETER,actual_start_date START_TIME ,actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR, FND_CONCURRENT_PROGRAMS_TL FCP, fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR EBL Individual Data Extraction Engine Master'
         AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) =TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
      )
    ORDER BY START_TIME;
	
    --CURSOR lcu_attach_header ( P_START_TIME IN VARCHAR2, P_END_TIME IN VARCHAR2 )
    CURSOR lcu_attach_header ( P_START_TIME IN VARCHAR2, ln_org_id IN VARCHAR2)
    IS
      SELECT PROGRAM_NAME
        ||','
        || DATE_PARAMETER
        ||','
        || to_char(START_TIME,'DD-MON-RRRR HH24:MI:SS')
        ||','
        || to_char(NVL(END_TIME,sysdate),'DD-MON-RRRR HH24:MI:SS') attachment_prog_details,
        Start_time
      FROM
        (
	    SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME ,FCR.ARGUMENT2 DATE_PARAMETER, actual_start_date START_TIME , actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR, FND_CONCURRENT_PROGRAMS_TL FCP, fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR Invoice Manage Frequencies Master'
        AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) =TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
        UNION ALL
        SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME, FCR.ARGUMENT5 DATE_PARAMETER, actual_start_date START_TIME , actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR,FND_CONCURRENT_PROGRAMS_TL FCP,fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR Validate Print New Consolidated Billing Invoices'
        AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) =TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
        UNION ALL
        SELECT FCP.USER_CONCURRENT_PROGRAM_NAME PROGRAM_NAME , FCR.ARGUMENT1 DATE_PARAMETER,actual_start_date START_TIME ,actual_completion_date END_TIME
        FROM FND_CONCURRENT_REQUESTS FCR, FND_CONCURRENT_PROGRAMS_TL FCP, fnd_profile_option_values fpv
        WHERE FCR.PROGRAM_APPLICATION_ID     = FCP.APPLICATION_ID
        AND FCR.CONCURRENT_PROGRAM_ID        = FCP.CONCURRENT_PROGRAM_ID
        AND fpv.level_value                  =fcr.responsibility_id
        AND profile_option_value             = P_ORG_ID
        AND FCP.USER_CONCURRENT_PROGRAM_NAME ='OD: AR EBL Individual Data Extraction Engine Master'
        AND TRUNC(fnd_conc_date.string_to_date(FCR.ACTUAL_START_DATE)) = TRUNC(fnd_conc_date.string_to_date(P_START_TIME))
      )
      ORDER BY START_TIME;
	  
	  
      CURSOR lcu_tail (P_REQUEST_ID IN NUMBER )
      IS
        SELECT BILLING_DATE,
          MEDIA_TYPE,
          BILL_TYPE,
          DOC_TYPE,
          OU,
          LPAD(to_char(SUM(INV_COUNT),'9,999,999') ,15,' ') INV_COUNT,
          LPAD(Decode(nvl(SUM(AMOUNT),0),0,'0.00',to_char(nvl(SUM(AMOUNT),0),'9,999,999,999.99')) ,20,' ') AMOUNT
        FROM XX_BILLING_ALL_DELIVERY_DET
        WHERE REQUEST_ID = P_REQUEST_ID
        GROUP BY BILLING_DATE,
          MEDIA_TYPE,
          BILL_TYPE,
          DOC_TYPE,
          OU
        ORDER BY DOC_TYPE DESC ,
            BILL_TYPE ASC,
            MEDIA_TYPE ASC;
		  
      CURSOR lcu_attach_tail (P_REQUEST_ID IN NUMBER , P_DOC_TYPE IN VARCHAR2 )
      IS
        SELECT SUBSTR(BILLING_DATE,1,10)
          ||','
          || MEDIA_TYPE
          ||','
          || BILL_TYPE
          ||','
          || DOC_TYPE
          ||','
          || OU
          ||','
          || INV_COUNT
          ||','
          || AMOUNT attachment_record_details
        FROM
          (SELECT BILLING_DATE,
            media_type,
            bill_type,
            doc_type,
            ou,
            SUM(inv_count) INV_COUNT,
            nvl(SUM(AMOUNT),0) AMOUNT
          FROM XX_BILLING_ALL_DELIVERY_DET
          WHERE REQUEST_ID = P_REQUEST_ID
		  AND DOC_TYPE = P_DOC_TYPE
          GROUP BY BILLING_DATE,
            MEDIA_TYPE,
            BILL_TYPE,
            DOC_TYPE,
            OU
          ORDER BY DOC_TYPE DESC ,
            BILL_TYPE ASC,
            MEDIA_TYPE ASC
          );
		  
		  Cursor lcu_email_cursor is
		  SELECT XFTV.target_value1
           --  INTO lc_email_address
             FROM   xx_fin_translatedefinition XFTD
                     ,xx_fin_translatevalues XFTV
             WHERE  XFTD.translate_id = XFTV.translate_id
             AND    XFTD.translation_name = 'OD_AR_ALL_IN_ONE_BILLING'
             AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag = 'Y'
             AND    XFTD.enabled_flag = 'Y';
    
	
	
	PROCEDURE send_mail(
        p_to          IN VARCHAR2,
        p_from        IN VARCHAR2,
        p_subject     IN VARCHAR2,
        p_text_msg    IN VARCHAR2 DEFAULT NULL,
        p_attach_name IN VARCHAR2 DEFAULT NULL,
        p_attach_mime IN VARCHAR2 DEFAULT NULL,
        p_attach_clob IN CLOB DEFAULT NULL,
        p_smtp_host   IN VARCHAR2,
        p_smtp_port   IN NUMBER DEFAULT 25)
    AS
      l_mail_conn UTL_SMTP.connection;
      l_boundary VARCHAR2(50) := '----=*#abc1234321cba#*=';
      l_step PLS_INTEGER      := 12000; -- make sure you set a multiple of 3 not higher than 24573
    BEGIN
      l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
      UTL_SMTP.helo(l_mail_conn, p_smtp_host);
      UTL_SMTP.mail(l_mail_conn, p_from);
      UTL_SMTP.rcpt(l_mail_conn, p_to);
      UTL_SMTP.open_data(l_mail_conn);
      UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
      UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
      IF p_text_msg IS NOT NULL THEN
        UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
        UTL_SMTP.write_data(l_mail_conn, 'Content-Type: text/html; charset="iso-8859-1"' || UTL_TCP.crlf || UTL_TCP.crlf);
        UTL_SMTP.write_data(l_mail_conn, p_text_msg);
        UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      END IF;
      IF p_attach_name IS NOT NULL THEN
        UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
        UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_attach_mime || '; name="' || p_attach_name || '"' || UTL_TCP.crlf);
        UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_attach_name || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
        FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_attach_clob) - 1 )/l_step)
        LOOP
          UTL_SMTP.write_data(l_mail_conn, DBMS_LOB.substr(p_attach_clob, l_step, i * l_step + 1));
        END LOOP;
        UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
      END IF;
      UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || '--' || UTL_TCP.crlf);
      UTL_SMTP.close_data(l_mail_conn);
      UTL_SMTP.quit(l_mail_conn);
    END send_mail;
    BEGIN
      --**** Variable Initialization ****
      lc_email_subject  := 'Daily Billing Summary for ' || SUBSTR(p_print_date,1,10) ;
      lc_sender_address := p_sender_address;
      --**** If email address not passed , program will take recipient email address from OD_AR_SOX_BILLING translation ****
      IF p_email_address IS NOT NULL THEN
        lc_email_address := p_email_address ;
      ELSE
        
		for email_cursor in lcu_email_cursor loop
		lc_email_address := email_cursor.target_value1;
		end loop;
		
      END IF;
      -- **** Output File Formatting ****
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Email Subject - ' || lc_email_subject||CHR(13) );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'From          - ' || lc_sender_address||CHR(13));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'To            - ' || lc_email_address||CHR(13));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(13)||CHR(13)||CHR(13));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('*',10,'*')||CHR(13));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_email_subject);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('*',10,'*')||CHR(13));
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the emailer program');
	  
	  
      --************************ Preparing the E-Mail Body Part *****************************
      lc_email_body := '<html><body><table border="1" cellspacing="0" cellpadding="2" > <tr bgcolor="#22DDF2">' || '<th>'||'PROGRAM NAME'||'</th>'|| '<th>'|| 'DATE PARAMETER'||'</th>'|| '<th>'|| 'START TIME'||'</th>'|| '<th>'|| 'END TIME'||'</th>'|| '</tr>';
      --FOR hdr_rec IN lcu_header ( lc_START_TIME , lc_END_TIME)
      FOR hdr_rec IN lcu_header ( P_START_TIME  , ln_org_id )
      LOOP
        lc_email_body := lc_email_body || '<tr><td>'||hdr_rec.PROGRAM_NAME||'</td>' ||'<td>'||hdr_rec.DATE_PARAMETER||'</td>' ||'<td>'||hdr_rec.START_TIME||'</td>' ||'<td>'||hdr_rec.END_TIME||'</td>' ||'</tr>' ;
      END LOOP;
      lc_email_body := lc_email_body || '</body></html>';
      lc_email_body := lc_email_body||'<html><body> <br> <br > </body></html>';
      lc_email_body := lc_email_body || '<html><body><table border="1" cellspacing="0" cellpadding="2" > <tr bgcolor="#22DDF2">'|| '<th>'||'BILLING DATE'||'</th>'|| '<th>'|| 'MEDIA TYPE'||'</th>'|| '<th>'|| 'BILL TYPE'||'</th>'|| '<th>'|| 'DOC TYPE'||'</th>'|| '<th>'|| 'OU'||'</th>'|| '<th>'|| 'COUNT'||'</th>'|| '<th>'|| 'AMOUNT'||'</th></hr>';
      
	  
	  FOR tail_rec  IN lcu_tail ( lc_REQUEST_ID )
      LOOP
      If tail_rec.doc_type = 'Paydoc' then
        lc_email_body := lc_email_body|| '<tr><td>'||tail_rec.BILLING_DATE||'</td>'|| '<td>'||tail_rec.MEDIA_TYPE||'</td>'|| '<td>'||tail_rec.BILL_TYPE||'</td>'|| '<td>'||tail_rec.DOC_TYPE||'</td>'|| '<td>'||tail_rec.OU||'</td>'|| '<td align="right">'||tail_rec.INV_COUNT||'</td>'|| '<td align="right">'||tail_rec.AMOUNT||'</td></tr>' ;
        end if;  
      END LOOP;
	  
	    Begin 
		 
		   SELECT LPAD(to_char(SUM(INV_COUNT),'9,999,999') ,15,' ') INV_COUNT,
                  LPAD(Decode(nvl(SUM(AMOUNT),0),0,'0.00',to_char(nvl(SUM(AMOUNT),0),'9,999,999,999.99')) ,20,' ') AMOUNT
             INTO lc_paydoc_count_total,
                  lc_paydoc_amount_total
             FROM XX_BILLING_ALL_DELIVERY_DET
             WHERE REQUEST_ID = P_REQUEST_ID
             AND DOC_TYPE     ='Paydoc';
	  
	    End;
		
	  lc_email_body := lc_email_body|| '<tr><td></td><td></td><td></td><td></td>'||'<td>Sub-Total:</td>'|| '<td align="right">'||lc_paydoc_count_total||'</td>'|| '<td>'||lc_paydoc_amount_total||'</td></tr>' ;
	   
	  FOR tail_rec  IN lcu_tail ( lc_REQUEST_ID )
      LOOP
      If tail_rec.doc_type = 'Infodoc' then
        lc_email_body := lc_email_body|| '<tr><td>'||tail_rec.BILLING_DATE||'</td>'|| '<td>'||tail_rec.MEDIA_TYPE||'</td>'|| '<td>'||tail_rec.BILL_TYPE||'</td>'|| '<td>'||tail_rec.DOC_TYPE||'</td>'|| '<td>'||tail_rec.OU||'</td>'|| '<td align="right">'||tail_rec.INV_COUNT||'</td>'|| '<td align="right">'||tail_rec.AMOUNT||'</td></tr>' ;
        end if;  
      END LOOP;
	  
	    Begin 
		 
		   SELECT LPAD(to_char(SUM(INV_COUNT),'9,999,999') ,15,' ') INV_COUNT,
                  LPAD(Decode(nvl(SUM(AMOUNT),0),0,'0.00',to_char(nvl(SUM(AMOUNT),0),'9,999,999,999.99')) ,20,' ') AMOUNT
             INTO lc_infodoc_count_total,
                  lc_infodoc_amount_total
             FROM XX_BILLING_ALL_DELIVERY_DET
             WHERE REQUEST_ID = P_REQUEST_ID
             AND DOC_TYPE     ='Infodoc';
	  
	    End;
	    
		lc_email_body := lc_email_body|| '<tr><td></td><td></td><td></td><td></td>'||'<td>Sub-Total:</td>'|| '<td align="right">'||lc_infodoc_count_total||'</td>'|| '<td align="right">'||lc_infodoc_amount_total||'</td></tr>' ;
		
		 Begin 
		 
		   SELECT LPAD(to_char(SUM(INV_COUNT),'9,999,999') ,15,' ') INV_COUNT,
                  LPAD(Decode(nvl(SUM(AMOUNT),0),0,'0.00',to_char(nvl(SUM(AMOUNT),0),'9,999,999,999.99')) ,20,' ') AMOUNT
             INTO lc_total_count,
                  lc_total_amount
             FROM XX_BILLING_ALL_DELIVERY_DET
             WHERE REQUEST_ID = P_REQUEST_ID;
             
	  
	    End;
		
		lc_email_body := lc_email_body|| '<tr><td></td><td></td><td></td><td></td>'||'<td>Total:</td>'|| '<td align="right">'||lc_total_count||'</td>'|| '<td align="right">'||lc_total_amount||'</td></tr>' ;
      
	  
	  lc_email_body := lc_email_body || '</body></html>';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_email_body);
	  
	  
	  
      --************************ Preparing the E-Mail Attachment Part *****************************
      lc_email_attachment := 'PROGRAM_NAME'||','||'DATE_PARAMETER'||','||'START_TIME'||','||'END_TIME'||CHR(13);
      --FOR attachment_hdr_rec IN lcu_attach_header ( lc_START_TIME , lc_END_TIME)
      
	  FOR attachment_hdr_rec IN lcu_attach_header ( P_START_TIME ,ln_org_id )
      LOOP
        lc_email_attachment := lc_email_attachment || attachment_hdr_rec.attachment_prog_details||CHR(13);
      END LOOP;
      lc_email_attachment     :=lc_email_attachment||chr(13)||chr(13)||chr(13)||'BILLING_DATE'||','||'MEDIA_TYPE'||','||'BILL_TYPE'||','||'DOC_TYPE'||','||'OU'||','||'COUNT'||','||'AMOUNT'||CHR(13);
      
	  lc_doc_type := 'Paydoc' ;
	  If lc_doc_type = 'Paydoc' Then
	  FOR attachment_tail_rec IN lcu_attach_tail ( lc_REQUEST_ID , lc_doc_type)
      LOOP
        lc_email_attachment := lc_email_attachment || attachment_tail_rec.attachment_record_details || chr(13) ;
      END LOOP;
	  end if;
	  
	  BEGIN
	  
	  SELECT NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || 'Sub-Total'
          ||','
          || INV_COUNT
          ||','
          || AMOUNT attachment_record_details
		INTO lc_attachment_record_details
        FROM
          (SELECT NULL,
            NULL,
            NULL,
            NULL,
            'Sub-Total',
            SUM(inv_count) INV_COUNT,
            nvl(SUM(AMOUNT),0) AMOUNT
          FROM XX_BILLING_ALL_DELIVERY_DET
          WHERE REQUEST_ID = P_REQUEST_ID
		  AND DOC_TYPE = lc_doc_type
          );
          
     	  
	  END;
	  
	  lc_email_attachment := lc_email_attachment || lc_attachment_record_details  || chr(13);
	  
	  lc_doc_type := 'Infodoc';
	  If lc_doc_type = 'Infodoc' Then
	  FOR attachment_tail_rec IN lcu_attach_tail ( lc_REQUEST_ID , lc_doc_type)
      LOOP
        lc_email_attachment := lc_email_attachment || attachment_tail_rec.attachment_record_details || chr(13) ;
      END LOOP;
	  end if;
	  
	  BEGIN
	  
	  SELECT NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || 'Sub-Total'
          ||','
          || INV_COUNT
          ||','
          || AMOUNT attachment_record_details
		  INTO lc_attachment_record_details
        FROM
          (SELECT NULL,
            NULL,
            NULL,
            NULL,
            'Sub-Total',
            SUM(inv_count) INV_COUNT,
            nvl(SUM(AMOUNT),0) AMOUNT
          FROM XX_BILLING_ALL_DELIVERY_DET
          WHERE REQUEST_ID = P_REQUEST_ID
		  AND DOC_TYPE = lc_doc_type
          );
          
     	  
	  END;
	  
	  lc_email_attachment := lc_email_attachment || lc_attachment_record_details  || chr(13);
	  
	  BEGIN
	  
	  SELECT NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || NULL
          ||','
          || 'Total'
          ||','
          || INV_COUNT
          ||','
          || AMOUNT attachment_record_details
		  INTO lc_attachment_record_details
        FROM
          (SELECT NULL,
            NULL,
            NULL,
            NULL,
            'Total',
            SUM(inv_count) INV_COUNT,
            nvl(SUM(AMOUNT),0) AMOUNT
          FROM XX_BILLING_ALL_DELIVERY_DET
          WHERE REQUEST_ID = P_REQUEST_ID
          );
          
     	  
	  END;
	  
	  lc_email_attachment := lc_email_attachment || lc_attachment_record_details  || chr(13);
     
      Begin
	  
	  SELECT def.target_field1,
          val.target_value1
        INTO lc_source_field1,
          lc_mail_host
        FROM xx_fin_translatedefinition def,
          xx_fin_translatevalues val
        WHERE def.translate_id   = val.translate_id
        AND def.translation_name = 'AR_EBL_EMAIL_CONFIG'
        AND def.target_field1    = 'SMTP_SERVER'
        AND def.enabled_flag     = 'Y'
        AND val.enabled_flag     = 'Y'
        AND SYSDATE BETWEEN def.start_date_active AND NVL (def.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN val.start_date_active AND NVL (val.end_date_active, SYSDATE + 1);
		
		end;

	 --******************** PREPARING MAIL PART USING SMTP  ********************
      IF lc_email_address IS NOT NULL THEN
        
		--**** Calling send_mail procedure ****
		send_mail(p_to => lc_email_address, p_from => lc_sender_address, p_subject => lc_email_subject, p_text_msg => lc_email_body, p_attach_name => lc_file_name, p_attach_mime => 'text/plain', p_attach_clob => lc_email_attachment, p_smtp_host => lc_mail_host);
	        
        
      END IF;
	  
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Mail is succeffully sent to ' || lc_email_address);
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
      FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
    END xx_send_email;
    --PROCEDURE PUBLISH_REPORT(RPT_REQUEST_ID1 IN NUMBER,P_START_TIME1 IN VARCHAR2, P_END_TIME1 IN VARCHAR2)
  
  
  
 /* PROCEDURE PUBLISH_REPORT(
      RPT_REQUEST_ID1 IN NUMBER,
      P_START_TIME1   IN VARCHAR2,
	 -- P_END_TIME1     IN VARCHAR2,
      P_ORG_ID1       IN VARCHAR2)
  IS
    -- Local Variable declaration
    x_errbuf        VARCHAR2(1000);
    x_ret_code      VARCHAR2(1000);
    ln_request_id   NUMBER := 0;
    lc_phase        VARCHAR2 (200);
    lc_status       VARCHAR2 (200);
    lc_dev_phase    VARCHAR2 (200);
    lc_dev_status   VARCHAR2 (200);
    lc_message      VARCHAR2 (200);
    lb_wait         BOOLEAN;
    lb_layout       BOOLEAN;
    lc_request_data VARCHAR2(120);
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the program OD: AR Billing All In One Report');
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameter values in PUBLISH_REPORT procedure');
    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID =' || RPT_REQUEST_ID1 ||' START_TIME = ' || P_START_TIME1 || ' END_TIME = '||P_END_TIME1);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID =' || RPT_REQUEST_ID1 ||' START_TIME = ' || P_START_TIME1||' ORG_ID = '||P_ORG_ID1);
    lb_layout    := fnd_request.add_layout( 'XXFIN' ,'XXODARALLINONEEBL' ,'en' ,'US' ,'EXCEL' );
    ln_request_id:=FND_REQUEST.SUBMIT_REQUEST ( 'XXFIN' --application name
    ,'XXODARALLINONEEBL'                                --short name of the AP concurrent program
    ,''                                                 -- description
    ,SYSDATE                                           --- start time
    ,FALSE                                              -- sub request
    ,RPT_REQUEST_ID1                                    --parameter1
    ,P_START_TIME1                                      --parameter2
	--,P_END_TIME1                                      --parameter3
    ,P_ORG_ID1                                          --parameter4
    );
    COMMIT;
    lb_wait          := fnd_concurrent.wait_for_request (ln_request_id, 20, 0, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
    IF ln_request_id <> 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OD: AR Billing All In One Report has been submitted and the request id is: '||ln_request_id);
      IF lc_dev_status    ='E' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN ERROR';
        x_ret_code       := 2;
      ELSIF lc_dev_status ='G' THEN
        x_errbuf         := 'PROGRAM COMPLETED IN WARNING';
        x_ret_code       := 1;
      ELSE
        x_errbuf   := 'PROGRAM COMPLETED NORMAL';
        x_ret_code := 0;
      END IF;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');
    END IF;
  END PUBLISH_REPORT; */

  
  
  PROCEDURE MAIN(
    x_errbuf OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_print_date     IN VARCHAR2 ,
    p_email_address  IN VARCHAR2 ,
    p_sender_address IN VARCHAR2)
AS
  p_delivery_method VARCHAR2(20);
  ld_print_date DATE;
  ln_org_id    NUMBER(10);
  l_temp       VARCHAR2(200);
  l_request_id NUMBER(20);
  P_ORG_ID     NUMBER(10);
  P_START_TIME VARCHAR2(30);
  P_END_TIME VARCHAR2(30);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters passed in:');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Report Date     : '||p_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Address   : '||p_email_address);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Sender Address  : '||p_sender_address);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'*****************************************************************************');
  ld_print_date := FND_DATE.CANONICAL_TO_DATE(p_print_date);
  FND_PROFILE.GET('ORG_ID',ln_org_id);
  l_request_id                                  := fnd_global.conc_request_id;
  IF ( SUBSTR(to_Date(SYSDATE,'DD-MON-YYYY'),1,2)=30) THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Truncating table XXFIN.XX_BILLING_ALL_DELIVERY_DET on ' || SYSDATE);
    l_temp := 'Truncate table XXFIN.XX_BILLING_ALL_DELIVERY_DET';
    EXECUTE immediate l_temp;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Truncating table - COMPLETED');
  END IF;
  --Assigning delivery method ePDF | Calling procedure xx_get_epdf )
  p_delivery_method := 'ePDF';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "ePDF" | Calling procedure xx_get_epdf ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_epdf procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_epdf(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_epdf procedure');
  --Assigning delivery method eXLS | Calling procedure xx_get_exls )
  p_delivery_method := 'eXLS';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "eXLS" | Calling procedure xx_get_exls ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_exls procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_exls(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_exls procedure');
  
  --Assigning delivery method eTXT | Calling procedure xx_get_etxt )
  p_delivery_method := 'eTXT';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "eTXT" | Calling procedure xx_get_etxt ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_etxt procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_etxt(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_etxt procedure');
  
  --Assigning delivery method EDI | Calling procedure xx_get_edi )
  p_delivery_method := 'EDI';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "EDI" | Calling procedure xx_get_edi ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_edi procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_edi(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_epdi procedure');
  --Assigning delivery method ELEC | Calling procedure xx_get_elec )
  p_delivery_method := 'EBill';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "ELEC" | Calling procedure xx_get_elec ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_elec procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_elec(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_elec procedure');
  --Assigning delivery method Certegy | Calling procedure xx_get_certegy )
  p_delivery_method := 'Certegy';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "Certegy" | Calling procedure xx_get_certegy ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_certegy procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_certegy(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_certegy procedure');
  --Assigning delivery method Special Handling | Calling procedure xx_get_spl_handling )
  p_delivery_method := 'Special Handling';
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Assigning delivery method "Special Handling" | Calling procedure xx_get_spl_handling ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Parameters passed to xx_get_elec procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ld_print_date     = ' || ld_print_date);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_delivery_method = ' || p_delivery_method);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ln_org_id         = ' || ln_org_id);
  --calling
  xx_get_spl_handling(ld_print_date,p_delivery_method,ln_org_id,l_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Returned Back from xx_get_certegy procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Assigning Request ID, START_TIME, ORG_ID to the report');
  RPT_REQUEST_ID :=l_request_id;
  P_ORG_ID       := ln_org_id;
  --select min(start_time),max(end_time) into P_START_TIME, P_END_TIME from XXFIN.XX_BILLING_ALL_DELIVERY_DET where request_id = RPT_REQUEST_ID;
 
  
  SELECT DISTINCT to_char((to_Date(billing_date)+1/2),'DD-MON-YYYY HH24:MI:SS'), to_char((to_Date(billing_date)+3/2),'DD-MON-YYYY HH24:MI:SS')
  INTO P_START_TIME , P_END_TIME
  FROM XX_BILLING_ALL_DELIVERY_DET
  WHERE request_id = RPT_REQUEST_ID;
  
 /* --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID =' || RPT_REQUEST_ID ||' START_TIME = ' || P_START_TIME || ' END_TIME = '||P_END_TIME);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Request ID =' || RPT_REQUEST_ID ||' START_TIME = ' || P_START_TIME || ' ORG_ID = '||P_ORG_ID);
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling PUBLISH_REPORT Procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  --PUBLISH_REPORT(RPT_REQUEST_ID,P_START_TIME,P_END_TIME);
  PUBLISH_REPORT(RPT_REQUEST_ID,P_START_TIME,P_ORG_ID);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'PUBLISH_REPORT Procedure Call completed');*/
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling xx_send_email Procedure');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  --xx_send_email(p_print_date,p_email_address,p_sender_address,l_request_id,p_delivery_method,P_START_TIME,P_END_TIME);
  --P_START_TIME := to_char(P_START_TIME,'DD-MON-YYYY');
  xx_send_email(p_print_date,p_email_address,p_sender_address,l_request_id,p_delivery_method,P_START_TIME,P_END_TIME,ln_org_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'xx_send_email Procedure Call completed');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Program Completed ********** ');
END main;


PROCEDURE xx_get_epdf(
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER)
AS
  ---- Cursor to fetch ePDF Individual data
  CURSOR lcu_ePDF_inv (p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'ePDF' media_type ,
      'Invoice' bill_type ,
      'Paydoc' doc_type ,
      --  DECODE(HIST.org_id,403,'CA',404,'US','N/A') OU ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(HIST.customer_Trx_id) tot_inv ,
      SUM(HIST.original_invoice_amount-total_gift_card_amount) tot_amount
    FROM xx_ar_ebl_ind_hdr_hist HIST
    WHERE HIST.request_id             = p_request_id
    AND HIST.org_id                   = p_org_id
    AND HIST.billdocs_delivery_method = 'ePDF'
    AND HIST.document_type            ='Paydoc' -- GROUP BY HIST.org_id
  UNION ALL
  SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
    'ePDF' media_type ,
    'Invoice' bill_type ,
    'Infodoc' doc_type ,
    -- DECODE(HIST.org_id,403,'CA',404,'US','N/A') OU ,
    DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
    COUNT(HIST.document_type) tot_inv ,
    0 tot_amount
  FROM xx_ar_ebl_ind_hdr_hist HIST
  WHERE HIST.request_id             = p_request_id
  AND HIST.org_id                   = p_org_id
  AND HIST.billdocs_delivery_method = 'ePDF'
  AND HIST.document_type            ='Infocopy' ;-- GROUP BY HIST.org_id;
  ---- Cursor to fetch ePDF Consolidated data
  CURSOR lcu_ePDF_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_print_date IN DATE )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'ePDF' media_type ,
      'Consolidated' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
      SUM(HIST.original_invoice_amount-total_gift_card_amount) tot_amount
    FROM xx_ar_ebl_cons_hdr_hist HIST
    WHERE HIST.request_id             = p_request_id
    AND HIST.org_id                   = p_org_id
    AND HIST.billdocs_delivery_method = 'ePDF'
    AND HIST.document_type            ='Paydoc'
  UNION ALL
  SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
    'ePDF' media_type ,
    'Consolidated' bill_type ,
    'Infodoc' doc_type ,
    DECODE(p_org_id,403,'CA',404,'US','N/A') OU,
    --,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust,
    COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
    0 tot_amount
  FROM xx_ar_ebl_cons_hdr_hist HIST
  WHERE HIST.request_id             = p_request_id
  AND HIST.org_id                   = p_org_id
  AND HIST.billdocs_delivery_method = 'ePDF'
  AND HIST.document_type            ='Infocopy';
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_epdf ********** ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Individual ePDF **********');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  -- Get the exact name of the billing program for ePDF
  lc_error_loc:='Getting the name of the billing program for ePDF-individual';
  SELECT XFTV.target_value2 ,
    XFTV.target_value3
  INTO lc_prog_name ,
    lc_child_prog_name1
  FROM xx_fin_translatedefinition XFTD ,
    xx_fin_translatevalues XFTV
  WHERE XFTD.translate_id   = XFTV.translate_id
  AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
  AND XFTV.source_value2    = p_delivery_method
  AND XFTV.source_value3    = 'INV'
  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
  AND XFTV.enabled_flag = 'Y'
  AND XFTD.enabled_flag = 'Y';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for ePDF-individual ' );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child  = ' || lc_child_prog_name1 );
  -- Get the request id of all the billing programs run for ePDF in today's run
  lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the request details of all the billing programs run for ePDF-individual' );
  SELECT FCR1.request_id ,
    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
    FCP1.user_concurrent_program_name BULK COLLECT
  INTO ln_req_id ,
    lv_req_start ,
    lv_req_end ,
    lv_conc_name
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_requests FCR1 ,
    fnd_concurrent_programs_vl FCP ,
    fnd_concurrent_programs_vl FCP1 ,
    fnd_application FA ,
    fnd_profile_options FLO ,
    fnd_profile_option_values FLOV
  WHERE FCR.argument5              =TO_CHAR(p_print_date,'YYYY/MM/DD HH24:MI:SS')
  AND FCR.concurrent_program_id    = FCP.concurrent_program_id
  AND FCR1.concurrent_program_id   = FCP1.concurrent_program_id
  AND FCP.concurrent_program_name  = lc_prog_name
  AND FCP1.concurrent_program_name = lc_child_prog_name1
  AND FCP.application_id           = FA.application_id
  AND FA.application_short_name    = 'XXFIN'
  AND FLOV.level_value             = fcr.responsibility_id
  AND FLOV.profile_option_id       = FLO.profile_option_id
  AND FLO.profile_option_name      = 'ORG_ID'
  AND FLOV.profile_option_value    = TO_CHAR(p_org_id)
  AND FCR1.parent_request_id       = FCR.request_id;
  lc_error_loc                    :='Getting the details for ePDF-individual';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
  IF (ln_req_id.COUNT <> 0) THEN
    FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
    LOOP
      FOR lc_qry IN lcu_ePDF_inv(ln_req_id(i),p_org_id,p_print_date)
      LOOP
        IF( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Infodoc' ) THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              lc_qry.tot_inv,
              lc_qry.tot_amount,
              ln_req_id(i)
            );
          --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XX_BILLING_ALL_DELIVERY_DET for ePDF Invoice Infodocs' );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        ELSIF ( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Paydoc' ) THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              lc_qry.tot_inv,
              lc_qry.tot_amount,
              ln_req_id(i)
            );
          --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for ePDF Invoice Paydocs' );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        END IF;
      END LOOP;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for ePDF-Invoice for Date : ' || p_print_date );
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consoldated ePDF **********');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  lc_error_loc:='Getting the name of the billing program for ePDF-consolidated';
  SELECT XFTV.target_value2 ,
    XFTV.target_value3 ,
    XFTV.target_value4 ,
    XFTV.target_value5
  INTO lc_prog_name ,
    lc_child_prog_name1 ,
    lc_child_prog_name2 ,
    lc_child_prog_name3
  FROM xx_fin_translatedefinition XFTD ,
    xx_fin_translatevalues XFTV
  WHERE XFTD.translate_id   = XFTV.translate_id
  AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
  AND XFTV.source_value2    = p_delivery_method
  AND XFTV.source_value3    = 'CBI'
  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
  AND XFTV.enabled_flag = 'Y'
  AND XFTD.enabled_flag = 'Y';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for ePDF-Consolidated ' );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child  = ' || lc_child_prog_name1 );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child  = ' || lc_child_prog_name2 );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Child  = ' || lc_child_prog_name3 );
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
  lc_error_loc := 'Getting the request details of all the billing programs run for ePDF- Consolidated';
  SELECT FCR1.request_id ,
    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
    FCP1.user_concurrent_program_name BULK COLLECT
  INTO ln_req_id ,
    lv_req_start ,
    lv_req_end ,
    lv_conc_name
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_requests FCR1 ,
    fnd_concurrent_programs_vl FCP ,
    fnd_concurrent_programs_vl FCP1 ,
    fnd_application FA ,
    fnd_profile_options FLO ,
    fnd_profile_option_values FLOV
  WHERE FCR.argument12              =TO_CHAR(p_print_date,'YYYY/MM/DD HH24:MI:SS')
  AND FCR.concurrent_program_id     = FCP.concurrent_program_id
  AND FCR1.concurrent_program_id    = FCP1.concurrent_program_id
  AND FCP.concurrent_program_name   = lc_prog_name
  AND FCP1.concurrent_program_name IN (lc_child_prog_name1,lc_child_prog_name2,lc_child_prog_name3)
  AND FCP.application_id            = FA.application_id
  AND FA.application_short_name     = 'XXFIN'
  AND FLOV.level_value              = fcr.responsibility_id
  AND FLOV.profile_option_id        = FLO.profile_option_id
  AND FLO.profile_option_name       = 'ORG_ID'
  AND FLOV.profile_option_value     = TO_CHAR(p_org_id)
  AND FCR1.parent_request_id        = FCR.request_id;
  lc_error_loc                     := 'Getting the details for ePDF-Consolidated';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
  IF (ln_req_id.COUNT <> 0) THEN
    FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
    LOOP
      FOR lc_qry IN lcu_ePDF_cbi(ln_req_id(i),p_org_id,p_print_date)
      LOOP
        IF(lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              lc_qry.tot_inv,
              lc_qry.tot_amount,
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        ELSIF (lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              lc_qry.tot_inv,
              lc_qry.tot_amount,
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        END IF;
      END LOOP;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for ePDF-Consolidated for Date : ' || p_print_date );
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_epdf ********** ');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
END xx_get_epdf;


PROCEDURE xx_get_exls
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch eXLS Individual data
  CURSOR lcu_eXLS_inv
    (
      p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE
    )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'eXLS' media_type ,
      'Invoice' bill_type ,
      'Paydoc' doc_type ,
      --  DECODE(HIST.org_id,403,'CA',404,'US','N/A') OU ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(HIST.customer_Trx_id) tot_inv ,
      SUM(HIST.original_invoice_amount-total_gift_card_amount) tot_amount
    FROM xx_ar_ebl_ind_hdr_hist HIST
    WHERE HIST.request_id             = p_request_id
    AND HIST.org_id                   = p_org_id
    AND HIST.billdocs_delivery_method = 'eXLS'
    AND HIST.document_type            ='Paydoc' -- GROUP BY HIST.org_id
  UNION ALL
  SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
    'eXLS' media_type ,
    'Invoice' bill_type ,
    'Infodoc' doc_type ,
    -- DECODE(HIST.org_id,403,'CA',404,'US','N/A') OU ,
    DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
    COUNT(HIST.document_type) tot_inv ,
    0 tot_amount
  FROM xx_ar_ebl_ind_hdr_hist HIST
  WHERE HIST.request_id             = p_request_id
  AND HIST.org_id                   = p_org_id
  AND HIST.billdocs_delivery_method = 'eXLS'
  AND HIST.document_type            ='Infocopy' ;-- GROUP BY HIST.org_id;
  ---- Cursor to fetch eXLS Consolidated data
  CURSOR lcu_eXLS_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_print_date IN DATE )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'eXLS' media_type ,
      'Consolidated' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
      SUM(HIST.original_invoice_amount-total_gift_card_amount) tot_amount
    FROM xx_ar_ebl_cons_hdr_hist HIST
    WHERE HIST.request_id             = p_request_id
    AND HIST.org_id                   = p_org_id
    AND HIST.billdocs_delivery_method = 'eXLS'
    AND HIST.document_type            ='Paydoc'
  UNION ALL
  SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
    'eXLS' media_type ,
    'Consolidated' bill_type ,
    'Infodoc' doc_type ,
    DECODE(p_org_id,403,'CA',404,'US','N/A') OU,
    --,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust,
    COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
    0 tot_amount
  FROM xx_ar_ebl_cons_hdr_hist HIST
  WHERE HIST.request_id             = p_request_id
  AND HIST.org_id                   = p_org_id
  AND HIST.billdocs_delivery_method = 'eXLS'
  AND HIST.document_type            ='Infocopy';
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_eXLS ********** ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Individual eXLS **********');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  -- Get the exact name of the billing program for eXLS
  lc_error_loc:='Getting the name of the billing program for eXLS-individual';
  SELECT XFTV.target_value2
  INTO lc_prog_name
  FROM xx_fin_translatedefinition XFTD ,
    xx_fin_translatevalues XFTV
  WHERE XFTD.translate_id   = XFTV.translate_id
  AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
  AND XFTV.source_value2    = p_delivery_method
  AND XFTV.source_value3    = 'INV'
  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
  AND XFTV.enabled_flag = 'Y'
  AND XFTD.enabled_flag = 'Y';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for eXLS-Individual ' );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
  -- Get the request id of all the billing programs run for certegy in today's run
  lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';
  SELECT FCR1.request_id ,
    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
    FCP1.user_concurrent_program_name BULK COLLECT
  INTO ln_req_id ,
    lv_req_start ,
    lv_req_end ,
    lv_conc_name
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_requests FCR1 ,
    fnd_concurrent_programs_vl FCP ,
    fnd_concurrent_programs_vl FCP1 ,
    fnd_application FA ,
    fnd_profile_options FLO ,
    fnd_profile_option_values FLOV
  WHERE FCR.argument1             =TO_CHAR(p_print_Date,'YYYY/MM/DD HH24:MI:SS')
  AND FCR.concurrent_program_id   = FCP.concurrent_program_id
  AND FCR1.concurrent_program_id  = FCP1.concurrent_program_id
  AND FCP.concurrent_program_name = lc_prog_name
  AND FCP.application_id          = FA.application_id
  AND FA.application_short_name   = 'XXFIN'
  AND FLOV.level_value            = fcr.responsibility_id
  AND FLOV.profile_option_id      = FLO.profile_option_id
  AND FLO.profile_option_name     = 'ORG_ID'
  AND FLOV.profile_option_value   = TO_CHAR(p_org_id)
  AND FCR1.parent_request_id      = FCR.request_id;
  lc_error_loc                   :='Getting the details for eXLS-individual';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
  IF (ln_req_id.COUNT <> 0) THEN
    FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
    LOOP
      FOR lc_qry IN lcu_eXLS_inv(ln_req_id(i),p_org_id,p_print_date)
      LOOP
        IF( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Infodoc' ) THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for eXLS Invoice Infodocs' );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        ELSIF ( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Paydoc' ) THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for eXLS Invoice Paydocs' );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        END IF;
      END LOOP;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for eXLS-Invoice for Date : ' || p_print_date );
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consoldated eXLS **********');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  lc_error_loc:='Getting the name of the billing program for eXLS-consolidated';
  SELECT XFTV.target_value2
  INTO lc_prog_name
  FROM xx_fin_translatedefinition XFTD ,
    xx_fin_translatevalues XFTV
  WHERE XFTD.translate_id   = XFTV.translate_id
  AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
  AND XFTV.source_value2    = p_delivery_method
  AND XFTV.source_value3    = 'CBI'
  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
  AND XFTV.enabled_flag = 'Y'
  AND XFTD.enabled_flag = 'Y';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for eXLS-Consolidated ' );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
  lc_error_loc := 'Getting the request details of all the billing programs run for eXLS- Consolidated';
  SELECT FCR1.request_id ,
    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
    FCP1.user_concurrent_program_name BULK COLLECT
  INTO ln_req_id ,
    lv_req_start ,
    lv_req_end ,
    lv_conc_name
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_requests FCR1 ,
    fnd_concurrent_programs_vl FCP ,
    fnd_concurrent_programs_vl FCP1 ,
    fnd_application FA ,
    fnd_profile_options FLO ,
    fnd_profile_option_values FLOV
  WHERE FCR.argument1             =TO_CHAR(p_print_date,'YYYY/MM/DD HH24:MI:SS')
  AND FCR.concurrent_program_id   = FCP.concurrent_program_id
  AND FCR1.concurrent_program_id  = FCP1.concurrent_program_id
  AND FCP.concurrent_program_name = lc_prog_name
  AND FCP.application_id          = FA.application_id
  AND FA.application_short_name   = 'XXFIN'
  AND FLOV.level_value            = fcr.responsibility_id
  AND FLOV.profile_option_id      = FLO.profile_option_id
  AND FLO.profile_option_name     = 'ORG_ID'
  AND FLOV.profile_option_value   = TO_CHAR(p_org_id)
  AND FCR1.parent_request_id      = FCR.request_id;
  lc_error_loc                   := 'Getting the details for eXLS-Consolidated';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
  IF (ln_req_id.COUNT <> 0) THEN
    FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
    LOOP
      FOR lc_qry IN lcu_eXLS_cbi(ln_req_id(i),p_org_id,p_print_date)
      LOOP
        IF(lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        ELSIF (lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        END IF;
      END LOOP;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for eXLS-Consolidated for Date : ' || p_print_date );
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_exls ********** ');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
END xx_get_exls;

PROCEDURE xx_get_etxt
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch eTXT Consolidated data
  CURSOR lcu_eTXT_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_print_date IN DATE )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'eTXT' media_type ,
      'Consolidated' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
      SUM(HIST.original_invoice_amount-total_gift_card_amount) tot_amount
    FROM xx_ar_ebl_cons_hdr_hist HIST
    WHERE HIST.request_id             = p_request_id
    AND HIST.org_id                   = p_org_id
    AND HIST.billdocs_delivery_method = 'eTXT'
    AND HIST.document_type            ='Paydoc'
  UNION ALL
  SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
    'eTXT' media_type ,
    'Consolidated' bill_type ,
    'Infodoc' doc_type ,
    DECODE(p_org_id,403,'CA',404,'US','N/A') OU,
    --,COUNT( DISTINCT HIST.cust_account_id)                          tot_cust,
    COUNT(DISTINCT HIST.cons_inv_id) tot_inv ,
    0 tot_amount
  FROM xx_ar_ebl_cons_hdr_hist HIST
  WHERE HIST.request_id             = p_request_id
  AND HIST.org_id                   = p_org_id
  AND HIST.billdocs_delivery_method = 'eTXT'
  AND HIST.document_type            ='Infocopy';
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_eTXT ********** ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consoldated eTXT **********');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
  lc_error_loc:='Getting the name of the billing program for eTXT-consolidated';
  SELECT XFTV.target_value2
  INTO lc_prog_name
  FROM xx_fin_translatedefinition XFTD ,
    xx_fin_translatevalues XFTV
  WHERE XFTD.translate_id   = XFTV.translate_id
  AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
  AND XFTV.source_value2    = p_delivery_method
  AND XFTV.source_value3    = 'CBI'
  AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
  AND XFTV.enabled_flag = 'Y'
  AND XFTD.enabled_flag = 'Y';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for eTXT-Consolidated ' );
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
  FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
  lc_error_loc := 'Getting the request details of all the billing programs run for eTXT- Consolidated';
  SELECT FCR1.request_id ,
    TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
    TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
    FCP1.user_concurrent_program_name BULK COLLECT
  INTO ln_req_id ,
    lv_req_start ,
    lv_req_end ,
    lv_conc_name
  FROM fnd_concurrent_requests FCR ,
    fnd_concurrent_requests FCR1 ,
    fnd_concurrent_programs_vl FCP ,
    fnd_concurrent_programs_vl FCP1 ,
    fnd_application FA ,
    fnd_profile_options FLO ,
    fnd_profile_option_values FLOV
  WHERE FCR.argument1             =TO_CHAR(p_print_date,'YYYY/MM/DD HH24:MI:SS')
  AND FCR.concurrent_program_id   = FCP.concurrent_program_id
  AND FCR1.concurrent_program_id  = FCP1.concurrent_program_id
  AND FCP.concurrent_program_name = lc_prog_name
  AND FCP.application_id          = FA.application_id
  AND FA.application_short_name   = 'XXFIN'
  AND FLOV.level_value            = fcr.responsibility_id
  AND FLOV.profile_option_id      = FLO.profile_option_id
  AND FLO.profile_option_name     = 'ORG_ID'
  AND FLOV.profile_option_value   = TO_CHAR(p_org_id)
  AND FCR1.parent_request_id      = FCR.request_id;
  lc_error_loc                   := 'Getting the details for eTXT-Consolidated';
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
  IF (ln_req_id.COUNT <> 0) THEN
    FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
    LOOP
      FOR lc_qry IN lcu_eTXT_cbi(ln_req_id(i),p_org_id,p_print_date)
      LOOP
        IF(lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        ELSIF (lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc') THEN
          INSERT
          INTO XX_BILLING_ALL_DELIVERY_DET VALUES
            (
              p_request_id,
              lv_conc_name(i),
              lv_req_start(i),
              lv_req_end(i),
              lc_qry.bill_date,
              lc_qry.media_type,
              lc_qry.bill_type,
              lc_qry.doc_type,
              lc_qry.ou,
              NVL(lc_qry.tot_inv,0),
              NVL(lc_qry.tot_amount,0),
              ln_req_id(i)
            );
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
        END IF;
      END LOOP;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for eTXT-Consolidated for Date : ' || p_print_date );
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_etxt ********** ');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
END xx_get_etxt;

PROCEDURE xx_get_edi
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch EDI Individual data
  CURSOR lcu_EDI_inv
    (
      p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE
    )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'EDI' media_type ,
      'Invoice' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(EDI.paydoc) tot_inv ,
      SUM(
      (SELECT SUM(extended_amount)
      FROM ra_customer_trx_lines_all RCTL
      WHERE RCTL.customer_trx_id = EDI.invoice_id
      )                                                            +
    (SELECT NVL(SUM(DECODE(RCTT.type ,'CM', EDI.attribute4 , 'INV',-1*EDI.attribute4 ) ) ,0) amount
    FROM ra_customer_trx_all RCT ,
      ra_cust_trx_types_all RCTT
    WHERE RCT.customer_trx_id = EDI.invoice_id
    AND RCT.cust_trx_type_id  = RCTT.cust_trx_type_id
    ) ) tot_amount
    FROM
      (SELECT
        /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N3) */
        -- Added hint on 15-APR-10,Corrected Hint syntax for Defect 11836
        XAIF.paydoc_flag paydoc ,
        XAIF.bill_to_customer_id bill_to_customer_id ,
        XAIF.invoice_id ,
        XAIF.attribute4
      FROM xx_ar_invoice_freq_history XAIF
      WHERE XAIF.request_id        = p_request_id
      AND XAIF.org_id              = p_org_id
      AND XAIF.doc_delivery_method = 'EDI'
      AND XAIF.paydoc_flag         = 'Y'
      ) EDI
    UNION ALL
    SELECT
      /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N3) */
      -- Added hint on 15-APR-10,Corrected Hint syntax for Defect 11836
      to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'EDI' media_type ,
      'Invoice' bill_type ,
      'Infodoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(paydoc_flag) tot_inv ,
      0 tot_amount
    FROM xx_ar_invoice_freq_history XAIF
    WHERE XAIF.request_id        = p_request_id
    AND XAIF.org_id              = p_org_id
    AND XAIF.paydoc_flag         = 'N'
    AND XAIF.doc_delivery_method = 'EDI';
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_edi ********** ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Individual EDI **********');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    -- Get the exact name of the billing program for EDI
    lc_error_loc:='Getting the name of the billing program for EDI-individual';
    SELECT XFTV.target_value2
    INTO lc_prog_name
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTD.translate_id   = XFTV.translate_id
    AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
    AND XFTV.source_value2    = p_delivery_method
    AND XFTV.source_value3    = 'INV'
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for EDI-Individual ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
    -- Get the request id of all the billing programs run for EDI in today's run
    lc_error_loc:='Getting the request details of all the billing programs run for EDI-individual';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the request details of all the billing programs run for EDI-individual' );
    SELECT FCR.request_id ,
      TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
      TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
      FCP.user_concurrent_program_name BULK COLLECT
    INTO ln_req_id ,
      lv_req_start ,
      lv_req_end ,
      lv_conc_name
    FROM fnd_concurrent_requests FCR ,
      fnd_concurrent_programs_vl FCP ,
      fnd_application FA ,
      fnd_profile_options FLO -- Added on 15-APR-10
      ,
      fnd_profile_option_values FLOV -- Added on 15-APR-10
    WHERE SUBSTR(FCR.argument6,1,10)= TO_CHAR(p_print_date,'RRRR/MM/DD')
    AND FCR.concurrent_program_id   = FCP.concurrent_program_id
    AND FCP.concurrent_program_name = lc_prog_name
    AND FCP.application_id          = FA.application_id
    AND FA.application_short_name   = 'XXFIN'
    AND FLOV.level_value            = fcr.responsibility_id
    AND FLOV.profile_option_id      = FLO.profile_option_id
    AND FLO.profile_option_name     = 'ORG_ID'
    AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
    lc_error_loc        :='Getting the details for EDI-individual';
    IF (ln_req_id.COUNT <> 0) THEN
      FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
      LOOP
        FOR lc_qry IN lcu_EDI_inv(ln_req_id(i),p_org_id,p_print_date)
        LOOP
          IF( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Infodoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount ,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for EDI Invoice Infodocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          ELSIF ( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Paydoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for EDI Invoice Paydocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          END IF;
        END LOOP;
      END LOOP;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for EDI-Invoice for Date : ' || p_print_date );
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_edi ********** ');
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
  END xx_get_edi;

  
 
 PROCEDURE xx_get_elec
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch EDI Individual data
  CURSOR lcu_ELEC_cbi
    (
      p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE
    )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'ELEC' media_type ,
      'Consolidated' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(EBILL.cons_inv_id) tot_inv ,
      SUM(
      (SELECT SUM(extended_amount)
      FROM ra_customer_trx_lines_all RCTL,
        ar_cons_inv_trx_all ACIT
      WHERE ACIT.cons_inv_id   = EBILL.cons_inv_id
      AND RCTL.customer_trx_id = ACIT.customer_trx_id
      )-
    (SELECT NVL(SUM(OP.payment_amount),0)
    FROM xx_oe_payments_v OP, -- Commented and Changed by Punit CG on 25-MAY-2018 for Defect NAIT-43451
	  --oe_payments OP ,
      ra_customer_trx_all RCT ,
      ar_cons_inv_trx_all ACIT
    WHERE OP.header_id      = RCT.attribute14
    AND RCT.customer_trx_id = ACIT.customer_trx_id
    AND ACIT.cons_inv_id    = EBILL.cons_inv_id
    ) +
    (SELECT NVL(SUM(ORT.credit_amount),0)
    FROM xx_om_return_tenders_all ORT ,
      ra_customer_trx_all RCT ,
      ar_cons_inv_trx_all ACIT
    WHERE ORT.header_id     = RCT.attribute14
    AND RCT.customer_trx_id = ACIT.customer_trx_id
    AND ACIT.cons_inv_id    = EBILL.cons_inv_id
    ) ) tot_amount
    FROM
      (SELECT ACI.customer_id ,
        ACI.cons_inv_id
      FROM ar_cons_inv_all ACI
      WHERE SUBSTR(ACI.attribute4,INSTR(ACI.attribute4,'|')+1) = p_request_id
      AND ACI.org_id                                           = p_org_id
      ) EBILL
    UNION ALL
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'ELEC' media_type ,
      'Consolidated' bill_type ,
      'Infodoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(1) tot_inv ,
      0 tot_amount
    FROM xx_ar_gen_bill_temp_all XAGB
    WHERE XAGB.request_id = p_request_id
    AND XAGB.org_id       = p_org_id;
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_elec ********** ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consolidated ELEC **********');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    -- Get the exact name of the billing program for ELEC
    lc_error_loc:='Getting the name of the billing program for ELEC-Consolidated';
    SELECT XFTV.target_value2
    INTO lc_prog_name
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTD.translate_id   = XFTV.translate_id
    AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
    AND XFTV.source_value2    = p_delivery_method
    AND XFTV.source_value3    = 'CBI'
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for ELEC-Consolidated ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
    -- Get the request id of all the billing programs run for ELEC in today's run
    lc_error_loc:='Getting the request details of all the billing programs run for ELEC-Consolidated';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Getting the request details of all the billing programs run for ELEC-Consolidated' );
    SELECT FCR.request_id ,
      TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
      TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
      FCP.user_concurrent_program_name BULK COLLECT
    INTO ln_req_id ,
      lv_req_start ,
      lv_req_end ,
      lv_conc_name
    FROM fnd_concurrent_requests FCR ,
      fnd_concurrent_programs_vl FCP ,
      fnd_application FA ,
      fnd_profile_options FLO -- Added on 15-APR-10
      ,
      fnd_profile_option_values FLOV -- Added on 15-APR-10
    WHERE SUBSTR(FCR.argument2,1,10)= TO_CHAR(p_print_date,'RRRR/MM/DD')
    AND FCR.concurrent_program_id   = FCP.concurrent_program_id
    AND FCP.concurrent_program_name = lc_prog_name
    AND FCP.application_id          = FA.application_id
    AND FA.application_short_name   = 'XXFIN'
    AND FLOV.level_value            = fcr.responsibility_id
    AND FLOV.profile_option_id      = FLO.profile_option_id
    AND FLO.profile_option_name     = 'ORG_ID'
    AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
    lc_error_loc        :='Getting the details for ELEC-Consolidated';
    IF (ln_req_id.COUNT <> 0) THEN
      FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
      LOOP
        FOR lc_qry IN lcu_ELEC_cbi(ln_req_id(i),p_org_id,p_print_date)
        LOOP
          IF( lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for ELEC Consolidated Infodocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          ELSIF ( lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for ELEC Consolidated Paydocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          END IF;
        END LOOP;
      END LOOP;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for ELEC-Consolidated for Date : ' || p_print_date );
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_elec ********** ');
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
  END xx_get_elec;

  
  
 PROCEDURE xx_get_certegy
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch certegy Individual data
  CURSOR lcu_certegy_inv
    (
      p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE
    )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'Certegy' media_type ,
      'Invoice' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(CERT_IND.paydoc_flag) tot_inv ,
      SUM(
      (SELECT SUM(RCTL.extended_amount )
      FROM ra_customer_trx_lines_all RCTL
      WHERE RCTL.customer_trx_id =CERT_IND.invoice_id
      )                                                                 +
    (SELECT NVL(SUM(DECODE(RCTT.type ,'CM', CERT_IND.attribute4 , 'INV',-1*CERT_IND.attribute4 ) ) ,0 )
    FROM ra_customer_trx_all RCT ,
      ra_cust_trx_types_all RCTT
    WHERE RCT.customer_trx_id = CERT_IND.invoice_id
    AND RCT.cust_trx_type_id  = RCTT.cust_trx_type_id
    ) ) tot_amount
    FROM
      (SELECT
        /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */
        -- Added hint on 15-APR-10, Corrected Hint syntax for Defect 11836
        XAIF.invoice_id ,
        XAIF.attribute4 ,
        XAIF.bill_to_customer_id ,
        XAIF.paydoc_flag
      FROM xx_ar_invoice_freq_history XAIF
      WHERE XAIF.attribute1               = TO_CHAR(p_request_id) -- Added to_char so that index is used -- Defect 11836
      AND XAIF.org_id                     = p_org_id
      AND XAIF.doc_delivery_method        = 'PRINT'
      AND XAIF.printed_flag               = 'Y'
      AND XAIF.paydoc_flag                ='Y'
      AND XAIF.billdocs_special_handling IS NULL
      )CERT_IND
    UNION ALL
    SELECT
      /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */
      -- Added hint on 15-APR-10, Corrected Hint syntax for Defect 11836
      to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'Certegy' media_type ,
      'Invoice' bill_type ,
      'Infodoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(paydoc_flag) tot_inv ,
      0 tot_amount
    FROM xx_ar_invoice_freq_history XAIF
    WHERE XAIF.attribute1 = TO_CHAR(p_request_id) -- Added to_char so that index is used -- Defect 11836
      -- AND    XAIF.org_id               = p_org_id
    AND XAIF.doc_delivery_method        = 'PRINT'
    AND XAIF.printed_flag               = 'Y'
    AND XAIF.paydoc_flag                ='N'
    AND XAIF.billdocs_special_handling IS NULL;
    ---- Cursor to fetch certegy Consolidated data
    CURSOR lcu_certegy_cbi (p_thread_id IN NUMBER,p_org_id IN NUMBER,p_print_date IN DATE )
    IS
      SELECT
        /*+ INDEX (XACB XX_AR_CONS_BILLS_HISTORY_N7) */
        -- Added hint on 15-apr-10
        to_date(p_print_date,'DD-MON-RRRR') bill_date,
        'Certegy' media_type ,
        'Consolidated' bill_type ,
        'Paydoc' doc_type ,
        DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
        COUNT(XACB.paydoc) tot_inv ,
        NVL(SUM(XACB.attribute14),0) tot_amount
      FROM xx_ar_cons_bills_history_all XACB
      WHERE XACB.thread_id  = p_thread_id
      AND XACB.org_id       = p_org_id
      AND XACB.delivery     = 'PRINT'
      AND XACB.process_flag = 'Y'
      AND XACB.paydoc       = 'Y'
      AND XACB.thread_id    > 0
    UNION ALL
    SELECT
      /*+ INDEX (XACB XX_AR_CONS_BILLS_HISTORY_N7) */
      -- Added hint on 15-apr-10
      to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'Certegy' media_type ,
      'Consolidated' bill_type ,
      'Infodoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(DISTINCT XACB.cons_inv_id) tot_inv ,
      0 tot_amount
    FROM xx_ar_cons_bills_history_all XACB
    WHERE XACB.thread_id  = p_thread_id
    AND XACB.org_id       = p_org_id
    AND XACB.delivery     = 'PRINT'
    AND XACB.process_flag = 'Y'
    AND XACB.paydoc       = 'N'
    AND XACB.thread_id    > 0;
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_certegy ********** ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Individual certegy **********');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    -- Get the exact name of the billing program for certegy
    lc_error_loc:='Getting the name of the billing program for certegy-individual';
    SELECT XFTV.target_value2
    INTO lc_prog_name
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTD.translate_id   = XFTV.translate_id
    AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
    AND XFTV.source_value2    = p_delivery_method
    AND XFTV.source_value3    = 'INV'
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for certegy-Individual ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
    -- Get the request id of all the billing programs run for certegy in today's run
    lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';
    SELECT FCR.request_id ,
      TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
      TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
      FCP.user_concurrent_program_name BULK COLLECT
    INTO ln_req_id ,
      lv_req_start ,
      lv_req_end ,
      lv_conc_name
    FROM fnd_concurrent_requests FCR ,
      fnd_concurrent_programs_vl FCP ,
      fnd_application FA ,
      fnd_profile_options FLO -- Added on 15-APR-10
      ,
      fnd_profile_option_values FLOV -- Added on 15-APR-10
    WHERE SUBSTR(FCR.argument9,1,10)=TO_CHAR(p_print_date,'RRRR/MM/DD')
    AND FCR.concurrent_program_id   = FCP.concurrent_program_id
    AND FCP.concurrent_program_name = lc_prog_name
    AND FCP.application_id          = FA.application_id
    AND FA.application_short_name   = 'XXFIN'
    AND FLOV.level_value            = fcr.responsibility_id
    AND FLOV.profile_option_id      = FLO.profile_option_id
    AND FLO.profile_option_name     = 'ORG_ID'
    AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
    lc_error_loc                   :='Getting the details for certegy-individual';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
    IF (ln_req_id.COUNT <> 0) THEN
      FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
      LOOP
        FOR lc_qry IN lcu_certegy_inv(ln_req_id(i),p_org_id,p_print_date)
        LOOP
          IF( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Infodoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for certegy Invoice Infodocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          ELSIF ( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Paydoc' ) THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for certegy Invoice Paydocs' );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          END IF;
        END LOOP;
      END LOOP;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for certegy-Invoice for Date : ' || p_print_date );
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consoldated certegy **********');
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
    lc_error_loc:='Getting the name of the billing program for certegy-consolidated';
    SELECT XFTV.target_value2
    INTO lc_prog_name
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTD.translate_id   = XFTV.translate_id
    AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
    AND XFTV.source_value2    = p_delivery_method
    AND XFTV.source_value3    = 'CBI'
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for certegy-Consolidated ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
    FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
    lc_error_loc := 'Getting the request details of all the billing programs run for certegy- Consolidated';
    SELECT FCR.argument1 ,
      fcr.request_id ,
      TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
      TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
      FCP.user_concurrent_program_name BULK COLLECT
    INTO lv_thread_id ,
      ln_req_id ,
      lv_req_start ,
      lv_req_end ,
      lv_conc_name
    FROM fnd_concurrent_requests FCR ,
      fnd_concurrent_programs_vl FCP ,
      fnd_application FA ,
      fnd_profile_options FLO -- Added on 15-APR-10
      ,
      fnd_profile_option_values FLOV -- Added on 15-APR-10
    WHERE SUBSTR(FCR.argument2,1,10)=TO_CHAR(p_print_date,'RRRR/MM/DD')
    AND FCR.concurrent_program_id   = FCP.concurrent_program_id
    AND FCP.concurrent_program_name = lc_prog_name
    AND FCP.application_id          = FA.application_id
    AND FA.application_short_name   = 'XXFIN'
    AND FLOV.level_value            = fcr.responsibility_id
    AND FLOV.profile_option_id      = FLO.profile_option_id
    AND FLO.profile_option_name     = 'ORG_ID'
    AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
    lc_error_loc                   := 'Getting the details for certegy-Consolidated';
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || lv_thread_id.COUNT);
    IF (lv_thread_id.COUNT <> 0) THEN
      FOR i                IN lv_thread_id.FIRST .. lv_thread_id.LAST
      LOOP
        FOR lc_qry IN lcu_certegy_cbi(lv_thread_id(i),p_org_id,p_print_date)
        LOOP
          IF(lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc') THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          ELSIF (lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc') THEN
            INSERT
            INTO XX_BILLING_ALL_DELIVERY_DET VALUES
              (
                p_request_id,
                lv_conc_name(i),
                lv_req_start(i),
                lv_req_end(i),
                lc_qry.bill_date,
                lc_qry.media_type,
                lc_qry.bill_type,
                lc_qry.doc_type,
                lc_qry.ou,
                lc_qry.tot_inv,
                lc_qry.tot_amount,
                ln_req_id(i)
              );
            FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
          END IF;
        END LOOP;
      END LOOP;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for certegy-Consolidated for Date : ' || p_print_date );
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_certegy ********** ');
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
  END xx_get_certegy;

  
PROCEDURE xx_get_spl_handling
  (
    p_print_date      IN DATE ,
    p_delivery_method IN VARCHAR2 ,
    p_org_id          IN NUMBER,
    p_request_id      IN NUMBER
  )
AS
  ---- Cursor to fetch Special Handling Individual data
  CURSOR lcu_spl_handling_inv
    (
      p_request_id IN NUMBER,p_org_id IN NUMBER ,p_print_date IN DATE
    )
  IS
    SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'Special Handling' media_type ,
      'Invoice' bill_type ,
      'Paydoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(SPL_INV.paydoc_flag) tot_inv ,
      SUM(
      (SELECT SUM(extended_amount)
      FROM ra_customer_trx_lines_all RCTL
      WHERE RCTL.customer_trx_id = SPL_INV.invoice_id
      )                                                                +
    (SELECT NVL(SUM(DECODE(RCTT.type ,'CM', SPL_INV.attribute4 , 'INV',-1*SPL_INV.attribute4 ) ) ,0) amount
    FROM ra_customer_trx_all RCT ,
      ra_cust_trx_types_all RCTT
    WHERE RCT.customer_trx_id = SPL_INV.invoice_id
    AND RCT.cust_trx_type_id  = RCTT.cust_trx_type_id
    ) ) tot_amount
    FROM
      (SELECT
        /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */
        -- Added hint on 15-APR-10,Corrected Hint Syntax for Defect 11836
        XAIF.paydoc_flag paydoc_flag ,
        XAIF.bill_to_customer_id bill_to_customer_id ,
        XAIF.invoice_id ,
        XAIF.attribute4
      FROM xx_ar_invoice_freq_history XAIF
      WHERE XAIF.attribute1               = TO_CHAR(p_request_id) -- Added to_char so that index is used -- Defect 11836
      AND XAIF.org_id                     = p_org_id
      AND XAIF.doc_delivery_method        = 'PRINT'
      AND XAIF.paydoc_flag                = 'Y'
      AND XAIF.printed_flag               = 'Y'
      AND XAIF.billdocs_special_handling IS NOT NULL
      ) SPL_INV
    UNION ALL
    SELECT
      /*+ INDEX(XAIF XX_AR_INVOICE_FREQ_HISTORY_N2) */
      -- Added hint on 15-APR-10,Corrected Hint Syntax for Defect 11836
      to_date(p_print_date,'DD-MON-RRRR') bill_date,
      'Special Handling' media_type ,
      'Invoice' bill_type ,
      'Infodoc' doc_type ,
      DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
      COUNT(XAIF.paydoc_flag) tot_inv ,
      0 tot_amount
    FROM xx_ar_invoice_freq_history XAIF
    WHERE XAIF.attribute1               = TO_CHAR(p_request_id) -- Added to_char so that index is used -- Defect 11836
    AND XAIF.org_id                     = p_org_id
    AND XAIF.doc_delivery_method        = 'PRINT'
    AND XAIF.paydoc_flag                = 'N'
    AND XAIF.printed_flag               = 'Y'
    AND XAIF.billdocs_special_handling IS NOT NULL ;
    ---- Cursor to fetch Special Handling Consolidated data
    CURSOR lcu_spl_handling_cbi (p_request_id IN NUMBER,p_org_id IN NUMBER,p_print_date IN DATE )
    IS
      SELECT to_date(p_print_date,'DD-MON-RRRR') bill_date,
        'Special Handling' media_type ,
        'Consolidated' bill_type ,
        'Paydoc' doc_type ,
        DECODE(p_org_id,403,'CA',404,'US','N/A') OU ,
        COUNT(SPL_CBI.cons_inv_id) tot_inv ,
        SUM(
        (SELECT SUM(extended_amount)
        FROM ra_customer_trx_lines_all RCTL,
          ar_cons_inv_trx_all ACIT
        WHERE ACIT.cons_inv_id   = SPL_CBI.cons_inv_id
        AND RCTL.customer_trx_id = ACIT.customer_trx_id
        )-
      (SELECT NVL(SUM(OP.payment_amount),0)
      FROM xx_oe_payments_v OP, -- Commented and Changed by Punit CG on 25-MAY-2018 for Defect NAIT-43451
	    --oe_payments OP ,
        ra_customer_trx_all RCT ,
        ar_cons_inv_trx_all ACIT
      WHERE OP.header_id      = RCT.attribute14
      AND RCT.customer_trx_id = ACIT.customer_trx_id
      AND ACIT.cons_inv_id    = SPL_CBI.cons_inv_id
      ) +
      (SELECT NVL(SUM(ORT.credit_amount),0)
      FROM xx_om_return_tenders_all ORT ,
        ra_customer_trx_all RCT ,
        ar_cons_inv_trx_all ACIT
      WHERE ORT.header_id     = RCT.attribute14
      AND RCT.customer_trx_id = ACIT.customer_trx_id
      AND ACIT.cons_inv_id    = SPL_CBI.cons_inv_id
      ) ) tot_amount
      FROM
        (SELECT ACI.cons_inv_id ,
          ACI.customer_id
        FROM ar_cons_inv_all ACI
        WHERE ACI.org_id                                         = p_org_id
        AND SUBSTR(ACI.attribute10,INSTR(ACI.attribute10,'|')+1) = TO_CHAR(p_request_id) -- Added to_char so that index is used -- Defect 11836
        )SPL_CBI;
    BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Inside xx_get_spl_handling ********** ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Individual Special Handling **********');
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
      -- Get the exact name of the billing program for Special Handling
      lc_error_loc:='Getting the name of the billing program for Special Handling-individual';
      SELECT XFTV.target_value2
      INTO lc_prog_name
      FROM xx_fin_translatedefinition XFTD ,
        xx_fin_translatevalues XFTV
      WHERE XFTD.translate_id   = XFTV.translate_id
      AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
      AND XFTV.source_value2    = p_delivery_method
      AND XFTV.source_value3    = 'INV'
      AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND XFTV.enabled_flag = 'Y'
      AND XFTD.enabled_flag = 'Y';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for Special Handling-Individual ' );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
      -- Get the request id of all the billing programs run for Special Handling in today's run
      lc_error_loc:='Getting the request details of all the billing programs run for ePDF-individual';
      SELECT FCR.request_id ,
        TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
        TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
        FCP.user_concurrent_program_name BULK COLLECT
      INTO ln_req_id ,
        lv_req_start ,
        lv_req_end ,
        lv_conc_name
      FROM fnd_concurrent_requests FCR ,
        fnd_concurrent_programs_vl FCP ,
        fnd_application FA ,
        fnd_profile_options FLO -- Added on 15-APR-10
        ,
        fnd_profile_option_values FLOV -- Added on 15-APR-10
      WHERE SUBSTR(FCR.argument9,1,10)=TO_CHAR(p_print_date,'RRRR/MM/DD')
      AND FCR.concurrent_program_id   = FCP.concurrent_program_id
      AND FCP.concurrent_program_name = lc_prog_name
      AND FCP.application_id          = FA.application_id
      AND FA.application_short_name   = 'XXFIN'
      AND FLOV.level_value            = fcr.responsibility_id
      AND FLOV.profile_option_id      = FLO.profile_option_id
      AND FLO.profile_option_name     = 'ORG_ID'
      AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
      lc_error_loc                   :='Getting the details for Special Handling-individual';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
      IF (ln_req_id.COUNT <> 0) THEN
        FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
        LOOP
          FOR lc_qry IN lcu_spl_handling_inv(ln_req_id(i),p_org_id,p_print_date)
          LOOP
            IF( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Infodoc' ) THEN
              INSERT
              INTO XX_BILLING_ALL_DELIVERY_DET VALUES
                (
                  p_request_id,
                  lv_conc_name(i),
                  lv_req_start(i),
                  lv_req_end(i),
                  lc_qry.bill_date,
                  lc_qry.media_type,
                  lc_qry.bill_type,
                  lc_qry.doc_type,
                  lc_qry.ou,
                  lc_qry.tot_inv,
                  lc_qry.tot_amount,
                  ln_req_id(i)
                );
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for Special Handling Invoice Infodocs' );
              FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
            ELSIF ( lc_qry.bill_type='Invoice' AND lc_qry.doc_type='Paydoc' ) THEN
              INSERT
              INTO XX_BILLING_ALL_DELIVERY_DET VALUES
                (
                  p_request_id,
                  lv_conc_name(i),
                  lv_req_start(i),
                  lv_req_end(i),
                  lc_qry.bill_date,
                  lc_qry.media_type,
                  lc_qry.bill_type,
                  lc_qry.doc_type,
                  lc_qry.ou,
                  lc_qry.tot_inv,
                  lc_qry.tot_amount,
                  ln_req_id(i)
                );
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, ' Inserted into XXFIN.XX_BILLING_ALL_DELIVERY_DET for Special Handling Invoice Paydocs' );
              FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
            END IF;
          END LOOP;
        END LOOP;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for Special Handling-Invoice for Date : ' || p_print_date );
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Starting  Process for Consoldated Special Handling **********');
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ');
      lc_error_loc:='Getting the name of the billing program for Special Handling-consolidated';
      SELECT XFTV.target_value2
      INTO lc_prog_name
      FROM xx_fin_translatedefinition XFTD ,
        xx_fin_translatevalues XFTV
      WHERE XFTD.translate_id   = XFTV.translate_id
      AND XFTD.translation_name = 'OD_AR_SOX_BILLING'
      AND XFTV.source_value2    = p_delivery_method
      AND XFTV.source_value3    = 'CBI'
      AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
      AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
      AND XFTV.enabled_flag = 'Y'
      AND XFTD.enabled_flag = 'Y';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Billing programs for Special Handling-Consolidated ' );
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent = ' || lc_prog_name );
      FND_FILE.PUT_LINE(FND_FILE.LOG, '  ' );
      lc_error_loc := 'Getting the request details of all the billing programs run for Special Handling- Consolidated';
      SELECT FCR.argument1 ,
        fcr.request_id ,
        TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') ,
        TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') ,
        FCP.user_concurrent_program_name BULK COLLECT
      INTO lv_thread_id ,
        ln_req_id ,
        lv_req_start ,
        lv_req_end ,
        lv_conc_name
      FROM fnd_concurrent_requests FCR ,
        fnd_concurrent_programs_vl FCP ,
        fnd_application FA ,
        fnd_profile_options FLO -- Added on 15-APR-10
        ,
        fnd_profile_option_values FLOV -- Added on 15-APR-10
      WHERE SUBSTR(FCR.argument2,1,10)=TO_CHAR(p_print_date,'RRRR/MM/DD')
      AND FCR.concurrent_program_id   = FCP.concurrent_program_id
      AND FCP.concurrent_program_name = lc_prog_name
      AND FCP.application_id          = FA.application_id
      AND FA.application_short_name   = 'XXFIN'
      AND FLOV.level_value            = fcr.responsibility_id
      AND FLOV.profile_option_id      = FLO.profile_option_id
      AND FLO.profile_option_name     = 'ORG_ID'
      AND FLOV.profile_option_value   = TO_CHAR(p_org_id);
      lc_error_loc                   := 'Getting the details for Special Handling-Consolidated';
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Count of Request IDs = ' || ln_req_id.COUNT);
      IF (ln_req_id.COUNT <> 0) THEN
        FOR i             IN ln_req_id.FIRST .. ln_req_id.LAST
        LOOP
          FOR lc_qry IN lcu_spl_handling_cbi(ln_req_id(i),p_org_id,p_print_date)
          LOOP
            IF(lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Infodoc') THEN
              INSERT
              INTO XX_BILLING_ALL_DELIVERY_DET VALUES
                (
                  p_request_id,
                  lv_conc_name(i),
                  lv_req_start(i),
                  lv_req_end(i),
                  lc_qry.bill_date,
                  lc_qry.media_type,
                  lc_qry.bill_type,
                  lc_qry.doc_type,
                  lc_qry.ou,
                  lc_qry.tot_inv,
                  lc_qry.tot_amount,
                  ln_req_id(i)
                );
              FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry.tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
            ELSIF (lc_qry.bill_type='Consolidated' AND lc_qry.doc_type='Paydoc') THEN
              INSERT
              INTO XX_BILLING_ALL_DELIVERY_DET VALUES
                (
                  p_request_id,
                  lv_conc_name(i),
                  lv_req_start(i),
                  lv_req_end(i),
                  lc_qry.bill_date,
                  lc_qry.media_type,
                  lc_qry.bill_type,
                  lc_qry.doc_type,
                  lc_qry.ou,
                  lc_qry.tot_inv,
                  lc_qry.tot_amount,
                  ln_req_id(i)
                );
              FND_FILE.PUT_LINE(FND_FILE.LOG, lc_qry.bill_date || chr(9) || lc_qry.media_type || chr(9) || lc_qry.bill_type || chr(9) || lc_qry.doc_type || chr(9) || lc_qry.ou || chr(9) || lc_qry. tot_inv || chr(9) || lc_qry.tot_amount || chr (9) || ln_req_id(i));
            END IF;
          END LOOP;
        END LOOP;
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO DATA FOUND for Special Handling-Consolidated for Date : ' || p_print_date );
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ********** Exit xx_get_spl_handling ********** ');
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while '||lc_error_loc);
      FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
    END xx_get_spl_handling;
  END XX_AR_ALL_IN_ONE_RPT;
/