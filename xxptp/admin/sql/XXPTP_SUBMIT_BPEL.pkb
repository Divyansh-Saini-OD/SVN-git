CREATE OR REPLACE procedure submit_BPEL(x_errbuf               OUT VARCHAR2,
                                        x_retcode              OUT VARCHAR2,
					  p_process_id            IN VARCHAR2,
					p_url                   IN VARCHAR2
                                       ) IS

soap_request varchar2(30000);
soap_respond varchar2(30000) :='a';
v_temp VARCHAR2(10000);
http_req utl_http.req;
http_resp utl_http.resp;
launch_url varchar2(240) ;
v_error_code VARCHAR2(2000);
v_number NUMBER :=6760239;
begin
FOR i IN 1..250 LOOP

soap_request:='<?xml version="1.0" encoding="UTF-8"?>';

select soap_request||'<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
||'<soap:Body xmlns:ns1="http://www.openapplications.org/officedepot/merchandising/foundation/1">'
||'<ns1:SYNC_ITEM_MASTER_CONFIRM>'
||'<ns1:VERB>'
||'<ns1:PROCESS_NAME>ItemMaster_rms_outb</ns1:PROCESS_NAME>'
||'<ns1:PROCESS_ID>'|| TO_CHAR(v_number)||' </ns1:PROCESS_ID>'
||'<ns1:CREATE_TIMESTAMP></ns1:CREATE_TIMESTAMP>'
||'<ns1:ACTION_TYPE></ns1:ACTION_TYPE>'
||'<ns1:ACTION_CODE></ns1:ACTION_CODE>'
||'</ns1:VERB>'
||'<ns1:NOUN>'
||'<ns1:CONFIRM>'
||'<ns1:CODE></ns1:CODE>'
||'<ns1:MESSAGE></ns1:MESSAGE>'
||'</ns1:CONFIRM>'
||'<ns1:WARNING>'
||'<ns1:CODE></ns1:CODE>'
||'<ns1:MESSAGE></ns1:MESSAGE>'
||'</ns1:WARNING>'
||'<ns1:ERROR>'
||'<ns1:CODE>-1</ns1:CODE>'
||'<ns1:MESSAGE>'||'Item Interface Exception,UOM Mismatch'||'</ns1:MESSAGE>'
||'</ns1:ERROR>'
||'</ns1:NOUN>'
||'</ns1:SYNC_ITEM_MASTER_CONFIRM>'
||'</soap:Body>'
||'</soap:Envelope>'
into soap_request
from dual;

http_req:= utl_http.begin_request(p_url 
,'POST',
'HTTP/1.1'
);
utl_http.set_detailed_excp_support (true);
utl_http.set_header(http_req, 'Content-Type', 'text/xml') ;
utl_http.set_header(http_req, 'Content-Length', length(soap_request)) ;
utl_http.set_header(http_req, 'SOAPAction', 'process');
utl_http.write_text(http_req, soap_request) ;

http_resp:= utl_http.get_response(http_req) ;
  begin
     utl_http.read_text(http_resp, soap_respond);
     dbms_output.put_line('Response - '||substr(soap_respond,1,250));
     dbms_output.put_line('Response - '||substr(soap_respond,251,250));
     dbms_output.put_line('Response - '||substr(soap_respond,501,250));
  exception
   when Utl_Http.End_Of_Body then
    null;
  end;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Response - '||soap_respond);
  utl_http.end_response(http_resp);
 SELECT replace(soap_respond,'env:','')
   INTO soap_respond
   FROM dual;
 SELECT replace(soap_respond,'xmlns="http://xmlns.oracle.com/ItemMaster_rms_confirm_inb_Synch"','')
   INTO soap_respond
   FROM dual;
  SELECT EXTRACTVALUE(xmltype(soap_respond), '/Envelope/Body/ItemMaster_rms_confirm_inb_SynchProcessResponse/result') 
    INTO v_error_code 
    FROM dual ;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Code - '||v_error_code);
--FND_FILE.PUT_LINE(FND_FILE.LOG,substr('-----------------------',1,250));
FND_FILE.PUT_LINE(FND_FILE.LOG,'http_resp.status_code is :'||http_resp.status_code );
--FND_FILE.PUT_LINE(FND_FILE.LOG,'http_resp.reason_phrase is :'||http_resp.reason_phrase);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'http_resp.http_version is :'||http_resp.http_version);
--FND_FILE.PUT_LINE(FND_FILE.LOG,'http_resp.private_hndl is :'||http_resp.private_hndl);

--FND_FILE.PUT_LINE(FND_FILE.LOG,substr('-----------------------',1,250));
--FND_FILE.PUT_LINE(FND_FILE.LOG,substr(soap_respond,1,250));
v_number := v_number +1;
END LOOP;
end;
/
