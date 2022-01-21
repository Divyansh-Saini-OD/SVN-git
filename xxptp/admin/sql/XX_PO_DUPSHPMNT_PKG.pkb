create or replace
PACKAGE BODY XX_PO_DUPSHPMNT_PKG
AS
-- +=======================================================================================+
-- |                  Office Depot - Project Simplify                                      |
-- +=======================================================================================+
-- | Name :XX_PO_DUPSHPMNT_PKG.pkb                                                         |
-- | Description : Created to clear PO duplicate shipments for defect 20551                |
-- | Rice : E3069                                                                          |
-- |                                                                                       |
-- |                                                                                       |
-- |                                                                                       |
-- |Change Record:                                                                         |
-- |===============                                                                        |
-- |Version   Date         Author               Remarks                                    |
-- |=======   ==========   =============        ===========================================|
-- | V1.0     19-NOV-12    Saritha Mummaneni    Intital Draft Version 			           |
-- | 1.1      02-APR-2015   Madhu Bolli      Get SMTP server from profile				   |
-- |                                                                                       |
-- +=======================================================================================+ 
PROCEDURE XX_PO_DUPSHPMNT_RECS( errbuf             OUT VARCHAR2
                              , retcode            OUT NUMBER
                              , p_email_list       IN VARCHAR2                         
                              )                        IS
                               
lc_message_body          CLOB;
lc_email_page            VARCHAR2(1):='N';
l_date      		 VARCHAR2(25);
l_ship_num  		 NUMBER;
l_line_locid		 NUMBER;
lc_mail_host VARCHAR2(100) := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');  -- 1.1 'USCHMSX83.na.odcorp.net';
TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
lc_mail_conn utl_smtp.connection;
v_addr Varchar2(1000);
lc_mail_subject VARCHAR2(1000) := 'PO_Duplicate_Lines' ;
crlf  VARCHAR2(10) := chr(13) || chr(10);
lc_mail_from varchar2(1000):='PO_DUP_SHPMNT';
lc_to_all      VARCHAR2(2000) := p_email_list ;
lc_to          VARCHAR2(2000);
i              BINARY_INTEGER;
lc_to_tbl      T_V100;

CURSOR PO_DUPSHPMNT IS
SELECT /*+ PARALLEL(t,4) */ t.*,ph.segment1, pr.release_num ,ph.po_Header_Id pohdrid,pr.po_Release_Id porlsid
FROM (SELECT 'DUP_SHIP_NUM',
Poll.Line_Location_Id,
Poll.po_Header_Id,
Poll.po_Release_Id,
Poll.Shipment_num
FROM po_Line_Locations_All Poll
WHERE (Poll.po_Header_Id,
Poll.po_Release_Id,
Poll.Shipment_num) IN (SELECT po_Header_Id,
po_Release_Id,
Shipment_num
FROM po_Line_Locations_All
WHERE Shipment_Type = 'BLANKET'
GROUP BY po_Header_Id,
po_Release_Id,
Shipment_num
HAVING COUNT(* ) > 1)
AND Nvl(Poll.Cancel_Flag,'n') <> 'Y'
AND Nvl(Poll.Closed_Code,'OPEN') <> 'FINALLY CLOSED') t, po_headers_all ph, po_releases_all pr
WHERE t.po_header_id=ph.po_header_id
AND t.po_release_id=pr.po_release_id;

CURSOR PO_DUPLLID (p_header_id NUMBER,p_release_id NUMBER) IS
SELECT /*+ PARALLEL(t,4) */ t.*,ph.segment1, pr.release_num 
FROM (SELECT 'DUP_SHIP_NUM',
max(Poll.Line_Location_Id) mxllid,
Poll.po_Header_Id,
Poll.po_Release_Id,
Poll.Shipment_num
FROM po_Line_Locations_All Poll
WHERE (Poll.po_Header_Id,
Poll.po_Release_Id,
Poll.Shipment_num) IN (SELECT po_Header_Id,
po_Release_Id,
Shipment_num
FROM po_Line_Locations_All
WHERE Shipment_Type = 'BLANKET'
GROUP BY po_Header_Id,
po_Release_Id,
Shipment_num
HAVING COUNT(* ) > 1)
AND Nvl(Poll.Cancel_Flag,'n') <> 'Y'
AND Nvl(Poll.Closed_Code,'OPEN') <> 'FINALLY CLOSED' group by 'DUP_SHIP_NUM', Poll.po_Header_Id, Poll.po_Release_Id, Poll.Shipment_num) t, po_headers_all ph, po_releases_all pr
WHERE t.po_header_id=ph.po_header_id
AND t.po_release_id=pr.po_release_id
AND pr.po_header_id =p_header_id
AND pr.po_release_id = p_release_id;



BEGIN

SELECT TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS')
     INTO l_date 
   FROM DUAL;

-- If setup data is missing then return

  IF lc_mail_host IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  lc_mail_conn := UTL_SMTP.open_connection(lc_mail_host, 25);
  UTL_SMTP.helo(lc_mail_conn, lc_mail_host);
  UTL_SMTP.mail(lc_mail_conn, lc_mail_from);

  -- Check how many recipients are present in lc_to_all

  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(lc_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(lc_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;

FOR PO_DUPSHPMNT_REC IN PO_DUPSHPMNT LOOP

lc_email_page := 'Y';

l_line_locid :=0;
l_ship_num :=0;

FND_FILE.PUT_LINE(FND_FILE.LOG,'Duplicate PO shipment Records found' || lc_email_page);


lc_message_body := lc_message_body||rpad(PO_DUPSHPMNT_REC.segment1,20,' ')||rpad(PO_DUPSHPMNT_REC.release_num,30,' ')||rpad(PO_DUPSHPMNT_REC.Shipment_num,30,' ')||PO_DUPSHPMNT_REC.Line_Location_Id ||crlf;


FOR PO_DUPLLID_REC IN PO_DUPLLID(PO_DUPSHPMNT_REC.pohdrid,PO_DUPSHPMNT_REC.porlsid) LOOP

BEGIN

SELECT max(shipment_num) INTO l_ship_num
FROM po_Line_Locations_All poll
WHERE po_release_id = PO_DUPLLID_REC.po_release_id
AND   po_header_id = PO_DUPLLID_REC.po_header_id
AND Nvl(Poll.Cancel_Flag,'n') <> 'Y'
AND Nvl(Poll.Closed_Code,'OPEN') <> 'FINALLY CLOSED' ;

--FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of Shipment number :'||l_ship_num);
EXCEPTION
WHEN no_data_found THEN

FND_FILE.PUT_LINE(FND_FILE.LOG,'No data retrived with the cursor values..');

END;
BEGIN

UPDATE po_Line_Locations_All
SET shipment_num = l_ship_num + 1,
    last_update_date = SYSDATE
WHERE line_location_id = PO_DUPLLID_REC.mxllid;

EXCEPTION
WHEN OTHERS THEN

FND_FILE.PUT_LINE(FND_FILE.LOG,'Not able to update line locations table..');

END;
END LOOP;
Commit;
END LOOP;

IF lc_email_page = 'Y' THEN 
BEGIN


lc_mail_subject := 'PO Duplicate Lines -'|| l_date;

utl_smtp.data(lc_mail_conn,'From:'||  lc_mail_from || utl_tcp.crlf ||
                           'To: ' || v_addr || utl_tcp.crlf ||
                           'Subject: ' || lc_mail_subject ||
                            utl_tcp.crlf ||
 '***********  PO Duplicate Shipment Lines  ***********' || crlf ||crlf ||
  'Date: '   || l_date || crlf ||
  crlf ||
  'PO_NUMBER '||' '|| 'RELEASE_NUMBER'||' '|| 'SHIPMENT_NUMBER'||' '||'LINE_LOCATION_ID'||' '||crlf
  ||crlf||
  lc_message_body  ||crlf
  );

                                            
utl_smtp.Quit(lc_mail_conn);

EXCEPTION
 WHEN utl_smtp.Transient_Error OR utl_smtp.Permanent_Error then
   raise_application_error(-20000, 'Unable to send mail: '||sqlerrm);   
END;   
                                            
END IF;
END;

end;
/