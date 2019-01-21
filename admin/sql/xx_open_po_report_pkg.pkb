create or replace 
PACKAGE BODY xx_open_po_report_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           
-- +===================================================================+
-- | Name  : xx_open_po_report_pkg.PKB                                 |
-- | Description      : Package Body                                   |
-- |                                                                   |
-- |This API will be used to send email notification OD Open 3 Way 
-- |Unreceived Standard POs and BPA Releases                                                                |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |
-- |1.0       17-JAN-2019   Veera Reddy  Automation of OPEN PO Report  |
-- |                        to notify the Requestors to Receive the PO |
-- +===================================================================+

--open_po_report

   PROCEDURE open_po_report_procedure 
   (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2,
	  P_number_of_days in NUMBER
       )
   IS
     
       LC_MAIL_FROM        VARCHAR2 (100)      := 'noreply@officedepot.com';
       LC_MAIL_CONN        UTL_SMTP.CONNECTION;
       LC_INSTANCE         VARCHAR2 (100);
       L_TEXT              VARCHAR2(2000)  := NULL;
       l_email_list        VARCHAR2(2000) :='svc-rpa5@officedepot.com';
       
    L_MESSAGE VARCHAR2(2000) := 'Attached are the OPEN Standard PO and Open BPA PO Reports';
    V_FILENAME1      VARCHAR2(2000) :='STANDARD_PO';
	V_FILENAME2      VARCHAR2(2000) :='BPA_RELEASES';
    
    V_FILEHANDLE      UTL_FILE.FILE_TYPE;
    V_LOCATION        VARCHAR2 (200) := 'XXFIN_OUTBOUND_GLEXTRACT';
    V_MODE            VARCHAR2 (1)       := 'W'; 
    v_connection             UTL_SMTP.connection;
       c_mime_boundary CONSTANT VARCHAR2(256) := 'the boundary can be almost anything'; --'-----AABCDEFBBCCC0123456789DE';
       v_clob                   CLOB := EMPTY_CLOB();
       v_len                    INTEGER;
       V_INDEX                  INTEGER;
       lc_mail_host        VARCHAR2 (100)      := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER'); 
       slen                NUMBER              := 1;
       V_ADDR              VARCHAR2 (1000);
       l_stylesheet CLOB := '
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
                              font-size       : 10pt;
                              padding         : 2px;}

                   th       { background      : #EEEEEE;
                              border          : solid 1px #444444;
                              font-size       : 10pt;
                              padding         : 2px;}

                   dt       { font-weight     : bold; }

                  </style>
                 </head>
                 <body>';
    CRLF        VARCHAR2(2)  := CHR(13)||CHR(10);
    
 /* Query for Standard po open report*/

      CURSOR Open_Standard_report
      IS
      select distinct
pha.segment1 po_number
,pha.type_lookup_code po_type
,aia.invoice_num
,prha.segment1 requisition_number
,aha.hold_reason invoice_hold_reason
,papf2.full_name preparer_name
,papf2.email_address
,papf1.full_name buyer_name
,aps.vendor_name supplier_name
,pha.creation_date po_date
,DECODE( plla.inspection_required_flag,'N',(DECODE(plla.receipt_required_flag,'N','2-WAY','3-WAY')),'4-WAY') matching_type
,plla.need_by_date
,pla.line_num
,pla.quantity
,plla.quantity_received
,round(nvl(pda.amount_ordered,(pla.unit_price*pla.quantity)),2) final_line_amount
,plla.amount_received
,plla.amount_billed matched_amount
,nvl(plla.amount,(select sum(round((pla2.unit_price*pla2.quantity),2)) from PO_LINES_ALL pla2 where 1=1 and pla2.po_header_id = pha.po_header_id)) final_po_amount
,pha.closed_code header_closed_code
,pla.closed_code line_closed_code  
from  PO_HEADERS_ALL pha
     ,PO_LINES_ALL pla
     ,PO_DISTRIBUTIONS_ALL pda
     ,PO_LINE_LOCATIONS_ALL plla
     ,AP_SUPPLIERS aps
     ,PO_REQ_DISTRIBUTIONS_ALL prda
     ,PO_REQUISITION_LINES_ALL prla
     ,PO_REQUISITION_HEADERS_ALL prha
     ,AP_INVOICE_LINES_ALL aila
     ,AP_INVOICES_ALL aia
     ,AP_HOLDS_ALL aha
     ,PER_ALL_PEOPLE_F papf1
     ,PER_ALL_PEOPLE_F papf2     
where 1=1
and pla.po_header_id = pha.po_header_id
and plla.po_header_id = pha.po_header_id
and plla.po_header_id = pla.po_header_id
and plla.po_line_id = pla.po_line_id
and pda.po_header_id = pla.po_header_id
and pda.po_line_id = pla.po_line_id
and pda.line_location_id = plla.line_location_id
and pda.req_distribution_id = prda.distribution_id
and prla.requisition_line_id = prda.requisition_line_id 
and prha.requisition_header_id = prla.requisition_header_id
and aila.po_header_id(+) = pla.po_header_id
and aila.po_line_id(+) = pla.po_line_id
and aia.invoice_id(+) = aila.invoice_id
and aha.invoice_id(+) = aila.invoice_id
and aps.vendor_id = pha.vendor_id
and papf1.person_id = pha.agent_id
and nvl(papf1.effective_end_date, sysdate+1)> sysdate
and papf2.person_id = prha.preparer_id
and nvl(papf2.effective_end_date, sysdate+1)> sysdate
--and pha.segment1 in ('20130652','20127592')
and aps.vendor_id not in (5879424,5849351)
and plla.receipt_required_flag != 'N'
and plla.inspection_required_flag = 'N'
and pha.type_lookup_code in ('STANDARD')
and pla.quantity != plla.quantity_received
and round(nvl(pda.amount_ordered,(pla.unit_price*pla.quantity)),2) > plla.amount_billed
and nvl(plla.amount,(select sum(round((pla2.unit_price*pla2.quantity),2)) from PO_LINES_ALL pla2 where 1=1 and pla2.po_header_id = pha.po_header_id))> 5000
and pha.creation_date >= nvl(sysdate-P_number_of_days,sysdate-30)
order by pha.segment1, pla.line_num
;
       
	   
	/* Query for Blanket po open report*/   
	   
	   cursor open_Blanket_po
is 

select

pra.creation_date requistion_created
,pha.segment1 po_number
,pra.release_num
,pla.line_num
,pha.type_lookup_code po_type
,pra.release_type
, prha.segment1 requisition_number
, prha.preparer_id preparer_id  
,papf2.full_name preparer_name
,papf2.email_address
,papf1.full_name buyer_name
,pra.agent_id buyer_id
,aps.vendor_name supplier_name
,aia.invoice_num
,aha.hold_reason invoice_hold_reason
,DECODE( plla.inspection_required_flag,'N',(DECODE(plla.receipt_required_flag,'N','2-WAY','3-WAY')),'4-WAY') matching_type
,plla.need_by_date
,pla.unit_price PO_unit_price
,prla.unit_price req_unit_price
,pla.last_update_date
,plla.quantity
,plla.quantity_received
,round(nvl(pda.amount_ordered,(pla.unit_price*plla.quantity)),2) release_line_amount
,nvl(plla.amount,(select sum(plla2.quantity*pla.unit_price) from PO_LINE_LOCATIONS_ALL plla2 where 1=1 and plla2.po_release_id = pra.po_release_id)) release_total_amount
,pda.amount_ordered
,pda.amount_billed
,pda.quantity_ordered
,pda.quantity_delivered
,pda.quantity_billed
,pda.quantity_cancelled
,pra.authorization_status rel_auth_status
,pha.authorization_status bpa_auth_status
,pra.closed_code rel_closed_code
,plla.closed_code rel_line_closed_code
,pha.closed_code bpa_closed_code
,pla.closed_code bpa_line_closed_code
,pha.blanket_total_amount bpa_total_amount
,pha.amount_limit bpa_amount_limit
,pra.cancel_flag rel_cancel_flag
,plla.cancel_flag rel_line_cancel_flag
,pha.cancel_flag bpa_cancel_flag
,pla.cancel_flag bpa_line_cancel_flag
from PO_RELEASES_ALL pra
     ,PO_HEADERS_ALL pha
     ,PO_LINES_ALL pla
     ,PO_LINE_LOCATIONS_ALL plla
     ,PO_DISTRIBUTIONS_ALL pda
     ,AP_SUPPLIERS aps
     ,PO_REQ_DISTRIBUTIONS_ALL prda
     ,PO_REQUISITION_LINES_ALL prla
     ,PO_REQUISITION_HEADERS_ALL prha
     ,AP_INVOICE_LINES_ALL aila
     ,AP_INVOICES_ALL aia
     ,AP_HOLDS_ALL aha
     ,PER_ALL_PEOPLE_F papf1
     ,PER_ALL_PEOPLE_F papf2     
where 1=1
and pha.po_header_id = pra.po_header_id
and pla.po_header_id = pha.po_header_id
and pla.po_line_id = plla.po_line_id
and plla.po_header_id = pra.po_header_id
and plla.po_release_id = pra.po_release_id
and pda.po_release_id = pra.po_release_id
and pda.po_header_id = pha.po_header_id
and pda.po_line_id = pla.po_line_id
and pda.line_location_id = plla.line_location_id
and aps.vendor_id = pha.vendor_id
and pda.req_distribution_id = prda.distribution_id(+)
and plla.receipt_required_flag != 'N'
and plla.inspection_required_flag = 'N'
and pda.req_distribution_id = prda.distribution_id
and prla.requisition_line_id = prda.requisition_line_id 
and prha.requisition_header_id = prla.requisition_header_id
and aila.po_header_id(+) = pla.po_header_id
and aila.po_line_id(+) = pla.po_line_id
and aia.invoice_id(+) = aila.invoice_id
and aha.invoice_id(+) = aila.invoice_id
and aps.vendor_id = pha.vendor_id
and papf1.person_id = pha.agent_id
and nvl(papf1.effective_end_date, sysdate+1)> sysdate
and papf2.person_id = prha.preparer_id
and nvl(papf2.effective_end_date, sysdate+1)> sysdate --and plla.quantity != plla.quantity_received
--and plla.quantity_received = 0
and nvl(plla.amount,(select sum(plla2.quantity*pla.unit_price) from PO_LINE_LOCATIONS_ALL plla2 where 1=1 and plla2.po_release_id = pra.po_release_id)) > 5000
--and pra.po_header_id in (149)
--and plla.closed_code not in ('CLOSED','CLOSED FOR RECEIVING','CLOSED FOR INVOICE')
--and pha.segment1 in ('20040684')
--and pra.release_num in (644)
and pra.creation_date >= nvl(sysdate-P_number_of_days,sysdate-30)
order by pra.creation_date, pha.segment1,pra.release_num,pla.line_num desc
;


   BEGIN
    SELECT NAME
	  INTO LC_INSTANCE
    FROM v$database; 
    
    V_FILENAME1   :=  V_FILENAME1||'_'||LC_INSTANCE||'.csv' ;  
   
    
     
      
 V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME1, 'W');
 
 UTL_FILE.PUT_LINE (V_FILEHANDLE, 'po_number'||','||'po_type'||','||'invoice_num'||','||'requisition_number'||','||'invoice_hold_reason'||','||'preparer_name'||','||'email_address'||','||'buyer_name'||','||'supplier_name'||','||'po_date'||','||'matching_type'||','||'need_by_date'||','||'line_num'||','||'quantity'||','||'quantity_received'||','||'final_line_amount'||','||'amount_received'||','||'matched_amount'||','||'final_po_amount'||','||'header_closed_code'||','||'line_closed_code' );
     
	  FOR i IN Open_Standard_report
      LOOP
      
              
                          
         
      UTL_FILE.PUT_LINE (V_FILEHANDLE, i.po_number||','||i.po_type||','||i.invoice_num||','||i.requisition_number||','||i.invoice_hold_reason||',"'||i.preparer_name||'",'||i.email_address||',"'||i.buyer_name||'","'||i.supplier_name||'",'||i.po_date||','||i.matching_type||','||i.need_by_date||','||i.line_num||','||i.quantity||','||i.quantity_received||','||i.final_line_amount||','||i.amount_received||','||i.matched_amount||','||i.final_po_amount||','||i.header_closed_code||','||i.line_closed_code );
	  
      END LOOP;     
           UTL_FILE.FCLOSE (V_FILEHANDLE);             
     
	V_FILENAME2   :=  V_FILENAME2||'_'||LC_INSTANCE||'.csv' ;    
    V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME2, 'W');	 
	
	UTL_FILE.PUT_LINE (V_FILEHANDLE,'requistion_create'||','||'po_number'||','||'release_num'||','||'line_num'||','||'po_type'||','||'release_type'||','||'requisition_number'||','||'preparer_id'||','||'preparer_name'||','||'email_address'||','||'buyer_name'||','||'buyer_id'||','||'supplier_name'||','||'invoice_num'||','||'ainvoice_hold_reason'||','||'matching_type'||','||'need_by_date'||','||'PO_unit_price'||','||'req_unit_price'||','||'last_update_date'||','||'quantity'||','||'quantity_received'||','||'release_line_amount'||','||'release_total_amount'||','||'amount_ordered'||','||'amount_billed'||','||'quantity_ordered'||','||'quantity_delivered'||','||'quantity_billed'||','||'quantity_cancelled'||','||'rel_auth_status'||','||'bpa_auth_status'||','||'rel_closed_code'||','||'rel_line_closed_code'||','||'bpa_closed_code'||','||'bpa_line_closed_code'||','||'bpa_total_amount'||','||'bpa_amount_limit'||','||'rel_cancel_flag'||','||'rel_line_cancel_flag'||','||'bpa_cancel_flag'||','||'bpa_line_cancel_flag');
	
	FOR i IN open_Blanket_po
      LOOP
      
          
                          
       UTL_FILE.PUT_LINE (V_FILEHANDLE,i.requistion_created||','||i.po_number||','||i.release_num||','||i.line_num||','||i.po_type||','||i.release_type||','||i.requisition_number||','||i.preparer_id||',"'||i.preparer_name||'",'||i.email_address||',"'||i.buyer_name||'",'||i.buyer_id||',"'||i.supplier_name||'",'||i.invoice_num||','||i.invoice_hold_reason||','||i.matching_type||','||i.need_by_date||','||i.PO_unit_price||','||i.req_unit_price||','||i.last_update_date||','||i.quantity||','||i.quantity_received||','||i.release_line_amount||','||i.release_total_amount||','||i.amount_ordered||','||i.amount_billed||','||i.quantity_ordered||','||i.quantity_delivered||','||i.quantity_billed||','||i.quantity_cancelled||','||i.rel_auth_status||','||i.bpa_auth_status||','||i.rel_closed_code||','||i.rel_line_closed_code||','||i.bpa_closed_code||','||i.bpa_line_closed_code||','||i.bpa_total_amount||','||i.bpa_amount_limit||','||i.rel_cancel_flag||','||i.rel_line_cancel_flag||','||i.bpa_cancel_flag||','||i.bpa_line_cancel_flag);  
     
      END LOOP;     
           UTL_FILE.FCLOSE (V_FILEHANDLE); 

        
        FND_FILE.PUT_LINE(FND_FILE.LOG,' Before calling Email Notification ' );
     
        IF lc_instance = 'GSIPRDGB' 
        THEN
      
         l_text := 'OD Open 3 Way Unreceived Standard POs and BPA Releases from production';
        ELSE
        L_TEXT :='OD Open 3 Way Unreceived Standard POs and BPA Releases from test instance';
        END IF;
 fnd_file.put_line(fnd_file.log,'Before sending mail');        
    SEND_MAIL_PRC (
      LC_MAIL_FROM ,
      l_email_list,
      L_TEXT,
      L_MESSAGE
      || CHR (13),
      V_FILENAME1||','||V_FILENAME2,
      V_LOCATION                               --default null
   ) ; 
 fnd_file.put_line(fnd_file.log,' After calling Email Notification ' );      
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Notification Successfully Sent To:' || NVL(L_EMAIL_LIST,'NO MAIL ADDRESS SETUP'));


     
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG,'No Data found');
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
   END;

  PROCEDURE send_mail_prc (
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
        FROM TABLE (xx_open_po_report_pkg.SPLIT (attachlist, NULL));

      IF attachlist IS NOT NULL AND DIRECTORY IS NOT NULL
      THEN
         FOR I IN (SELECT LTRIM (RTRIM (COLUMN_VALUE)) AS ATTACHMENT
                     FROM TABLE (xx_open_po_report_pkg.SPLIT (attachlist, NULL)))
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
                              || REPLACE (i.attachment, '.req', '.csv')
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

END xx_open_po_report_pkg;
/
