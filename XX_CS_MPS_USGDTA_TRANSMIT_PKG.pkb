CREATE OR REPLACE
PACKAGE BODY XX_CS_MPS_USGDTA_TRANSMIT_PKG 
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_USGDTA_TRANSMIT_PKG.pkb                                                    |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        21-MAY-2013   Sreedhar Mohan	    Send Usage Data to Vendor periodically            |
-- |2.0        02-NOV-2015   Havish Kasina	    Removed the schema references in the existing code|
-- +==============================================================================================+
AS

--Procedure for logging debug log
PROCEDURE log_debug_msg ( 
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  lc_debug_enabled     VARCHAR2(1)  := FND_PROFILE.VALUE('XX_CS_MPS_COMMON_LOG_ENABLE');
BEGIN
  IF NVL(lc_debug_enabled,'N')='Y' THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => p_debug_pkg          --------index exists on attribute15
      ,p_program_id              => 0                    
      ,p_module_name             => 'MPS'                --------index exists on module_name
      ,p_error_message           => p_debug_msg
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  END IF;
END log_debug_msg;

--Procedure for logging Errors/Exceptions
PROCEDURE log_error ( 
                      p_error_pkg          IN  VARCHAR2
                     ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
BEGIN
    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'ERROR'              --------index exists on program_type
      ,p_attribute15             => p_error_pkg          --------index exists on attribute15
      ,p_program_id              => 0                    
      ,p_module_name             => 'MPS'                --------index exists on module_name
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_error;

--Create xml element 
FUNCTION get_xml_element(  p_attr_name     IN VARCHAR2
                         , p_attr_value    IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
    IF p_attr_name IS NOT NULL THEN
        RETURN '<req:'||p_attr_name||'>'||p_attr_value||'</req:'||p_attr_name||'>';
    ELSE
        RETURN '</req:'||p_attr_name||'>';
        --RETURN '<req:'||p_attr_name||'></req:'||p_attr_name||'>';  
        --Check what is correct way to send null values
        --check if we should skip if there are null values?
    END IF;

END get_xml_element;

FUNCTION get_header_xml_element
RETURN VARCHAR2
IS
   l_dealerID            VARCHAR2(60) := FND_PROFILE.VALUE('XX_CS_MPS_USAGE_DEALER_ID');
   l_webserv_uname   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_USG_WS_AUTH_NAME');
   l_webserv_pword   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_USG_WS_AUTH_STR');
BEGIN    
        RETURN '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:req="http://officedepot.com/MPS/SendMeterData/Schema/Request">
                <soapenv:Header xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
                <wsse:UsernameToken>
                <wsse:Username>' || l_webserv_uname || '</wsse:Username>' ||
                '<wsse:Password>' || l_webserv_pword || '</wsse:Password>' ||
                '</wsse:UsernameToken>
                </wsse:Security>
                </soapenv:Header>
                <soapenv:Body><req:Meters xmlns:req="http://officedepot.com/MPS/SendMeterData/Schema/Request">' || get_xml_element('DealerID', l_dealerID);
END get_header_xml_element;

FUNCTION get_trailer_xml_element
RETURN VARCHAR2
IS
BEGIN
        RETURN '</req:Meters></soapenv:Body></soapenv:Envelope>';
END get_trailer_xml_element;

FUNCTION get_vendor_invoice_number
RETURN VARCHAR2
IS
BEGIN

   --Check how to get Invoice Number
        RETURN RA_CUSTOMER_TRX_LINES_S.nextval;
END get_vendor_invoice_number;

FUNCTION is_valid_reading_values (   p_device_id        IN VARCHAR2
                                   , p_aops_cust_number IN VARCHAR2
                                   , p_reading_date     IN DATE
                                   , p_prev_read_date   IN DATE
                                   , p_reading_value    IN NUMBER
                                   , p_prev_read_value  IN NUMBER
                                 )
RETURN VARCHAR2
IS
  is_valid    VARCHAR2(1) := 'T';
BEGIN
   IF p_reading_value < p_prev_read_value THEN
     is_valid := 'N';
     --insert into data exceptions table
     insert into XX_CS_MPS_DATA_EXCEPTIONS (
                                              EXCEPTION_ID       
                                             ,DEVICE_ID          
                                             ,AOPS_CUST_NUMBER   
                                             ,EXCEPTION          
                                             ,EXCEPTION_DATE     
                                             ,EXCEPTION_LOGGED_BY
                                           )
                                 values    (
                                              XX_CS_MPS_DATA_EXCEPTION_S.nextval       
                                             ,p_device_id
                                             ,p_aops_cust_number             
                                             ,'Reading Value is Less Than Previuos Reading Value:' ||
                                              'Reading_Value=' || p_reading_value ||
                                              ', Previous_Reading_Value=' || p_prev_read_value                                                      
                                             ,sysdate     
                                             ,FND_GLOBAL.User_ID
                                           );
   --Raise SR
   ELSE
    is_valid := 'T'; 
   END IF;

   RETURN is_valid;
EXCEPTION
  WHEN OTHERS THEN
    LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.is_valid_reading_values', 'Exception: ' || SQLERRM);
    return 'N';
    --RAISE;
END is_valid_reading_values;

PROCEDURE p_soap_request(p_username IN VARCHAR2, p_password IN VARCHAR2, p_proxy IN VARCHAR2) IS
    soap_request  VARCHAR2(30000);
    soap_respond  CLOB;
    http_req      utl_http.req;
    http_resp     utl_http.resp;
    resp          XMLType;
    soap_err      exception;
    v_code        VARCHAR2(200);
    v_msg         VARCHAR2(1800);
    v_len number;
    v_txt Varchar2(32767);
  BEGIN
    IF p_proxy IS NOT NULL THEN
      UTL_HTTP.SET_PROXY(p_proxy);
    END IF;
    -- Define the SOAP request according the the definition of the web service being called
    soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
                   '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">'||
                   '  <SOAP-ENV:Body>'||
                   '    <m:DownloadRequest xmlns:m="http://www.website.net/messages/GetDetails">'||
                   '      <m:UserName>'||p_username||'</m:UserName>'||
                   '      <m:Password>'||p_password||'</m:Password>'||
                   '    </m:DownloadRequest>'||
                   '  </SOAP-ENV:Body>'||
                   '</SOAP-ENV:Envelope>';
    http_req:= utl_http.begin_request
              ( 'http://www.website.net/webservices/GetDetailsService.asmx'
              , 'POST'
              , 'HTTP/1.1'
              );
    utl_http.set_header(http_req, 'Content-Type', 'text/xml');
    utl_http.set_header(http_req, 'Content-Length', length(soap_request));
    utl_http.set_header(http_req, 'Download', ''); -- header requirements of particular web service
    utl_http.write_text(http_req, soap_request);
    http_resp:= utl_http.get_response(http_req);
    utl_http.get_header_by_name(http_resp, 'Content-Length', v_len, 1); -- Obtain the length of the response
    FOR i in 1..CEIL(v_len/32767) -- obtain response in 32K blocks just in case it is greater than 32K
    LOOP
        utl_http.read_text(http_resp, v_txt, case when i < CEIL(v_len/32767) then 32767 else mod(v_len,32767) end);
        soap_respond := soap_respond || v_txt; -- build up CLOB
    END LOOP;
    utl_http.end_response(http_resp);
    resp:= XMLType.createXML(soap_respond); -- Convert CLOB to XMLTYPE
  END;




FUNCTION post_content ( p_service_url  VARCHAR2
                      , p_req_msg_body VARCHAR2)
RETURN VARCHAR2  
AS

  soap_request      VARCHAR2(30000);
  soap_respond      VARCHAR2(30000);
  req               utl_http.req;
  resp              utl_http.resp;
  v_response_text   VARCHAR2(32767);
  x_resp            XMLTYPE;
  lc_resp_code      VARCHAR2(255);
  l_msg_data        varchar2(30000);
  l_webserv_uname   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_USG_WS_AUTH_NAME');
  l_webserv_pword   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_USG_WS_AUTH_STR');


begin

   l_msg_data := p_req_msg_body;

   --log the msg

   req := utl_http.begin_request(p_service_url,'POST','HTTP/1.1');
   --utl_http.set_authentication(req, l_webserv_uname, l_webserv_pword, 'Basic',true); 
   --utl_http.set_authentication(req, l_webserv_uname, l_webserv_pword); 
   utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
   utl_http.set_header(req,'Content-Length', length(l_msg_data));
   utl_http.set_header(req,'SOAPAction'  , 'process');
   utl_http.write_text(req, l_msg_data);

   resp := utl_http.get_response(req);
   utl_http.read_text(resp, soap_respond);

   lc_resp_code := 'Response Received '||resp.status_code;
   
   --log the response

   utl_http.end_response(resp);

   x_resp := XMLType.createXML(soap_respond);

   l_msg_data := soap_respond;
   v_response_text := l_msg_data;

   --Log the response

   return v_response_text;
EXCEPTION
    WHEN OTHERS THEN
      --log_exception
    LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.post_content', 'Exception: ' || SQLERRM);
      --RAISE;      
      return null;
end post_content;

PROCEDURE insert_usg_history(  p_device_id           IN VARCHAR2    
                             , p_aops_cust_number    IN VARCHAR2    
                             , p_request_number      IN VARCHAR2    
                             , p_prev_read_value     IN NUMBER      
                             , p_prev_reading_date   IN DATE        
                             , p_reading_value       IN NUMBER      
                             , p_reading_date        IN DATE        
                             , p_reading_type        IN NUMBER    
                             , p_req_str             IN VARCHAR2    
                             , p_resp_str            IN VARCHAR2    
                        )                                           
IS

BEGIN  
  insert into XX_CS_MPS_USG_DATA_HISTORY (   USAGE_DATA_HISTORY_ID 
                                           , DEVICE_ID       
                                           , AOPS_CUST_NUMBER
                                           , REQUEST_NUMBER                           
                                           , PREV_READ_VALUE   
                                           , PREV_READING_DATE 
                                           , READING_VALUE     
                                           , READING_DATE      
                                           , READING_TYPE      
                                           , USAGE_DATA_REQ_PAYLOAD       
                                           , USAGE_DATA_RESP_PAYLOAD
                                           , CREATION_DATE
                                           , CREATED_BY
                                         )
                               values    (   XX_CS_MPS_USG_DATA_HIST_ID_S.nextval
                                           , p_device_id                       
                                           , p_aops_cust_number
                                           , p_request_number                           
                                           , p_prev_read_value   
                                           , p_prev_reading_date 
                                           , p_reading_value     
                                           , p_reading_date      
                                           , p_reading_type      
                                           , XMLTYPE(p_req_str)       
                                           , XMLTYPE(p_resp_str)
                                           , SYSDATE
                                           , FND_GLOBAL.User_Id 
                                         );     
  COMMIT;
  --Log SR
EXCEPTION
    WHEN OTHERS THEN
      --log_exception
      LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.insert_usg_history', 'Exception: ' || SQLERRM);
      --RAISE;      
END insert_usg_history;

--Send Usage Data to a Customer                   
PROCEDURE TRANSMIT_USAGE_DATA(    p_errbuf            OUT NOCOPY VARCHAR2
                                , p_retcode           OUT NOCOPY VARCHAR2
                                , p_party_id          IN         NUMBER
                                , p_sr_number         IN         VARCHAR2)
IS

    ln_party_id           NUMBER(15);
    l_po_number           XX_CS_MPS_DEVICE_B.PO_NUMBER%TYPE;
    l_aops_customer_id    HZ_CUST_ACCOUNTS.ORIG_SYSTEM_REFERENCE%TYPE;
    l_usg_dflt_lead_days  VARCHAR2(3) := FND_PROFILE.VALUE('XX_CS_MPS_USG_DFLT_LEAD_DAYS');    
    l_usg_vendor_url      VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_USG_VENDOR_URL');
    l_dealerID            VARCHAR2(60) := FND_PROFILE.VALUE('XX_CS_MPS_USAGE_DEALER_ID');
    l_black_meter_code    VARCHAR2(60) := FND_PROFILE.VALUE('XX_CS_MPS_BLACK_METER_CODE');
    l_color_meter_code    VARCHAR2(60) := FND_PROFILE.VALUE('XX_CS_MPS_COLOR_METER_CODE');
    l_readType            VARCHAR2(60) := FND_PROFILE.VALUE('XX_CS_MPS_USG_PROVIDER_READ_TYPE');
    l_reading_date        VARCHAR2(60);
    l_prev_reading_date   VARCHAR2(60);
    l_vendor_invoice_number NUMBER;
    l_black_final_read    NUMBER;
    l_color_final_read    NUMBER;

    is_valid              VARCHAR2(1) := 'T';
    l_msg_str             VARCHAR2(4000) := '';
    
    l_response_text       VARCHAR2(1000);

    --Cursor for Black Count Meter Reading
    cursor c1
    is
    select   dev.DEVICE_ID  
           , dev.PARTY_ID
           , dev.PARTY_NAME
           , dev.AOPS_CUST_NUMBER
           , dev.PROGRAM_TYPE
           , dev.SERIAL_NO
           , dev.MODEL
           , dev.GROUP_ID
           , dev.GROUP_NAME
           , det.PREVIOUS_BLACK_COUNT
           , det.BLACK_COUNT
           , dev.USAGE_SEND_LEAD_DAYS
           , det.REQUEST_NUMBER
           , det.SERVICE_CREDIT
           , dev.PERIOD_COVERED_ST_DATE
           , dev.PERIOD_COVERED_END_DATE
    from     XX_CS_MPS_DEVICE_B        dev
           , XX_CS_MPS_DEVICE_DETAILS  det
    where  dev.device_id  = det.device_id
    and    det.supplies_label = 'USAGE'
    and    det.black_count is not null
    and    dev.party_id = p_party_id
    and    det.request_number   = p_sr_number;

    --Cursor for Color Count Meter Reading
    cursor c2
    is
    select   dev.DEVICE_ID  
           , dev.PARTY_ID
           , dev.PARTY_NAME
           , dev.AOPS_CUST_NUMBER
           , dev.PROGRAM_TYPE
           , dev.SERIAL_NO
           , dev.MODEL
           , dev.GROUP_ID
           , dev.GROUP_NAME
           , det.PREVIOUS_COLOR_COUNT
           , det.COLOR_COUNT  
           , dev.USAGE_SEND_LEAD_DAYS
           , det.REQUEST_NUMBER
           , det.SERVICE_CREDIT
           , dev.PERIOD_COVERED_ST_DATE
           , dev.PERIOD_COVERED_END_DATE
    from     XX_CS_MPS_DEVICE_B        dev
           , XX_CS_MPS_DEVICE_DETAILS  det
    where  dev.device_id  = det.device_id
    and    det.supplies_label = 'USAGE'
    and    det.Color_count is not null
    and    dev.party_id = p_party_id
    and    det.request_number   = p_sr_number;

BEGIN
    log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date', 'Start');   
    log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date', 'p_sr_number: ' || p_sr_number || 'p_party_id: '  || p_party_id);   
    l_reading_date  := to_char(sysdate, 'YYYY-MM-DD');
    l_prev_reading_date  := to_char(sysdate-30, 'YYYY-MM-DD');

    for black_meters_rec in c1
    loop

      --Prep-up XML message for transmission
      --prep_up_msg;      
      l_msg_str := get_header_xml_element;

      l_msg_str := l_msg_str || '<req:Meter>';
      l_msg_str := l_msg_str || get_xml_element('SerialNumber', black_meters_rec.SERIAL_NO);
      l_msg_str := l_msg_str || get_xml_element('MeterCode', l_black_meter_code);
      l_msg_str := l_msg_str || get_xml_element('ModelNumber', black_meters_rec.MODEL); -- Check with Darry if MODEL and GALC ModelNumber are same
      --l_msg_str := l_msg_str || get_xml_element('VendorMeterGroupID', black_meters_rec.GROUP_ID); -- Check with Darry if GROUP_ID and GALC VendorMeterGroupID are same
      l_msg_str := l_msg_str || get_xml_element('VendorMeterGroupID', black_meters_rec.AOPS_CUST_NUMBER); -- Check with Darry if GROUP_ID and GALC VendorMeterGroupID are same
      --l_msg_str := l_msg_str || get_xml_element('VendorMeterCodeDescription', black_meters_rec.GROUP_NAME); -- check what should we populate for VendorMeterCodeDescription
      l_msg_str := l_msg_str || get_xml_element('VendorMeterCodeDescription', black_meters_rec.PARTY_NAME); -- check what should we populate for VendorMeterCodeDescription
      l_msg_str := l_msg_str || get_xml_element('VendorInvoiceNumber', black_meters_rec.REQUEST_NUMBER);
      l_msg_str := l_msg_str || get_xml_element('PreviousReadingValue', black_meters_rec.PREVIOUS_BLACK_COUNT);
      l_msg_str := l_msg_str || get_xml_element('PreviousReadingDate', l_prev_reading_date); -- Check with Darryl what is PreviousReadingDate --previus_usage_date
      l_msg_str := l_msg_str || get_xml_element('ReadingValue', black_meters_rec.BLACK_COUNT);
      l_msg_str := l_msg_str || get_xml_element('ReadingDate', l_reading_date);  -- Check with Darryl what is reading date
      
      If black_meters_rec.program_type = 'REMOVED' Then
        l_readType := 88;
      Else
        l_readType := 86;
      End If;

      l_msg_str := l_msg_str || get_xml_element('ReadingType', l_readType); -- Reading Type -85-Start 86-Actual 87-Estimated 88-Final
      l_msg_str := l_msg_str || get_xml_element('PeriodCoveredStart', to_char(black_meters_rec.PERIOD_COVERED_ST_DATE, 'YYYY-MM-DD')); 
      l_msg_str := l_msg_str || get_xml_element('PeriodCoveredEnd', to_char(black_meters_rec.PERIOD_COVERED_END_DATE, 'YYYY-MM-DD')); 
      l_msg_str := l_msg_str || get_xml_element('ChargeAmount', 0); -- Optional
      l_msg_str := l_msg_str || get_xml_element('ServiceCredit', nvl(black_meters_rec.SERVICE_CREDIT,0)); -- Optional

      --If program type is removed, then usage_current_count will be set to null; and final_read will be the current count
      If black_meters_rec.program_type = 'REMOVED' Then
        l_black_final_read := black_meters_rec.BLACK_COUNT;
      Else
        l_black_final_read := 0;
      END If;

      l_msg_str := l_msg_str || get_xml_element('FinalRead', l_black_final_read); -- Optional

      l_msg_str := l_msg_str || '</req:Meter>';

      l_msg_str := l_msg_str || get_trailer_xml_element;
      
      log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','black meters - l_msg_str: ' || l_msg_str);      
      --Call Web Service to post the content
      --Validate the meter readings before posting the data
      IF is_valid_reading_values (   black_meters_rec.SERIAL_NO       
                                   , black_meters_rec.AOPS_CUST_NUMBER
                                   , to_date(l_reading_date,'YYYY-MM-DD')    
                                   , to_date(l_prev_reading_date,'YYYY-MM-DD')   
                                   , black_meters_rec.BLACK_COUNT   
                                   , black_meters_rec.PREVIOUS_BLACK_COUNT 
                                 ) = 'T' THEN

        l_response_text := post_content(l_usg_vendor_url, l_msg_str);
        log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','black meters - l_response_text: ' || l_response_text);      
        
        --insert the xml in usage data history table
        insert_usg_history(  black_meters_rec.DEVICE_ID
                            ,black_meters_rec.AOPS_CUST_NUMBER
                            ,black_meters_rec.REQUEST_NUMBER
                            ,black_meters_rec.PREVIOUS_BLACK_COUNT  
                            ,to_date(l_prev_reading_date, 'YYYY-MM-DD')
                            ,black_meters_rec.BLACK_COUNT    
                            ,to_date(l_reading_date, 'YYYY-MM-DD')     
                            ,l_readType     
                            ,l_msg_str
                            ,l_response_text
                          );
        --Update SR with TRANSMITTED status
        log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','After inserting into history');      
      END IF;
    end loop;


    for color_meters_rec in c2
    loop

      --Prep-up XML message for transmission
      --prep_up_msg;      
      l_msg_str := get_header_xml_element;

      l_msg_str := l_msg_str || '<req:Meter>';
      l_msg_str := l_msg_str || get_xml_element('SerialNumber', color_meters_rec.SERIAL_NO);
      l_msg_str := l_msg_str || get_xml_element('MeterCode', l_color_meter_code);
      l_msg_str := l_msg_str || get_xml_element('ModelNumber', color_meters_rec.MODEL); -- Check with Darry if MODEL and GALC ModelNumber are same
      --l_msg_str := l_msg_str || get_xml_element('VendorMeterGroupID', color_meters_rec.GROUP_ID); -- Check with Darry if GROUP_ID and GALC VendorMeterGroupID are same
      l_msg_str := l_msg_str || get_xml_element('VendorMeterGroupID', color_meters_rec.AOPS_CUST_NUMBER); -- Check with Darry if GROUP_ID and GALC VendorMeterGroupID are same
      --l_msg_str := l_msg_str || get_xml_element('VendorMeterCodeDescription', color_meters_rec.GROUP_NAME); -- check what should we populate for VendorMeterCodeDescription
      l_msg_str := l_msg_str || get_xml_element('VendorMeterCodeDescription', color_meters_rec.PARTY_NAME); -- check what should we populate for VendorMeterCodeDescription
      l_msg_str := l_msg_str || get_xml_element('VendorInvoiceNumber', color_meters_rec.REQUEST_NUMBER);
      l_msg_str := l_msg_str || get_xml_element('PreviousReadingValue', color_meters_rec.PREVIOUS_COLOR_COUNT);
      l_msg_str := l_msg_str || get_xml_element('PreviousReadingDate', l_prev_reading_date); -- Check with Darryl what is PreviousReadingDate --previus_usage_date
      l_msg_str := l_msg_str || get_xml_element('ReadingValue', color_meters_rec.COLOR_COUNT);
      l_msg_str := l_msg_str || get_xml_element('ReadingDate', l_reading_date);  -- Check with Darryl what is reading date
      
      If color_meters_rec.program_type = 'REMOVED' Then
        l_readType := 88;
      Else
        l_readType := 86;
      End If;

      l_msg_str := l_msg_str || get_xml_element('ReadingType', l_readType); -- Reading Type -85-Start 86-Actual 87-Estimated 88-Final
      l_msg_str := l_msg_str || get_xml_element('PeriodCoveredStart', to_char(color_meters_rec.PERIOD_COVERED_ST_DATE, 'YYYY-MM-DD')); 
      l_msg_str := l_msg_str || get_xml_element('PeriodCoveredEnd', to_char(color_meters_rec.PERIOD_COVERED_END_DATE, 'YYYY-MM-DD')); 
      l_msg_str := l_msg_str || get_xml_element('ChargeAmount', 0); -- Optional
      l_msg_str := l_msg_str || get_xml_element('ServiceCredit', nvl(color_meters_rec.SERVICE_CREDIT,0)); -- Optional

      --If program type is removed, then usage_current_count will be set to null; and final_read will be the current count
      If color_meters_rec.program_type = 'REMOVED' Then
        l_color_final_read := color_meters_rec.COLOR_COUNT;
      Else
        l_color_final_read := 0;
      END If;

      l_msg_str := l_msg_str || get_xml_element('FinalRead', l_color_final_read); -- Optional

      l_msg_str := l_msg_str || '</req:Meter>';

      l_msg_str := l_msg_str || get_trailer_xml_element;
      
      log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','color meters - l_msg_str: ' || l_msg_str);      
      --Call Web Service to post the content
      --Validate the meter readings before posting the data
      IF is_valid_reading_values (   color_meters_rec.SERIAL_NO       
                                   , color_meters_rec.AOPS_CUST_NUMBER
                                   , to_date(l_reading_date,'YYYY-MM-DD')    
                                   , to_date(l_prev_reading_date,'YYYY-MM-DD')   
                                   , color_meters_rec.COLOR_COUNT   
                                   , color_meters_rec.PREVIOUS_COLOR_COUNT 
                                 ) = 'T' THEN

        l_response_text := post_content(l_usg_vendor_url, l_msg_str);
        log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','color meters - l_response_text: ' || l_response_text);      
        
        --insert the xml in usage data history table
        insert_usg_history(  color_meters_rec.DEVICE_ID
                            ,color_meters_rec.AOPS_CUST_NUMBER
                            ,color_meters_rec.REQUEST_NUMBER
                            ,color_meters_rec.PREVIOUS_COLOR_COUNT  
                            ,to_date(l_prev_reading_date, 'YYYY-MM-DD')
                            ,color_meters_rec.COLOR_COUNT    
                            ,to_date(l_reading_date, 'YYYY-MM-DD')
                            ,l_readType     
                            ,l_msg_str
                            ,l_response_text
                          );
        --Update SR with TRANSMITTED status
        log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','After inserting into history');      
      END IF;

    end loop;

    log_debug_msg('XX_CS_MPS_USGDTA_TRANSMIT_PKG.transmit_usage_date','End');   

EXCEPTION 
    WHEN OTHERS THEN
      LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.TRANSMIT_USAGE_DATA', 'Exception: ' || SQLERRM);
      --log_exception
      p_retcode := 2;
END TRANSMIT_USAGE_DATA;

--Update Usage Parameters to MPS Devices
PROCEDURE UPDATE_USAGE_PARAMS(    p_errbuf                  OUT NOCOPY VARCHAR2
                                , p_retcode                 OUT NOCOPY VARCHAR2
                                , p_aops_cust_id            IN         NUMBER  
                                , p_notification_date       IN         VARCHAR2 
                                , p_period_covered_st_date  IN         VARCHAR2 
                                , p_period_covered_end_date IN         VARCHAR2 
                                , p_usage_send_lead_days    IN         NUMBER )
IS

BEGIN
   
  update XX_CS_MPS_DEVICE_B
  set    notification_date         = to_date(p_notification_date,'DD-MON-YYYY')
       , period_covered_st_date    = to_date(p_period_covered_st_date,'DD-MON-YYYY')
       , period_covered_end_date   = to_date(p_period_covered_end_date,'DD-MON-YYYY')
       , usage_send_lead_days      = p_usage_send_lead_days
  where  aops_cust_number          = p_aops_cust_id;

  COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      --log_exception
      LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.UPDATE_USAGE_PARAMS', 'Exception: ' || SQLERRM);
      p_retcode := 2;
END UPDATE_USAGE_PARAMS;

--Update Usage Parameters -req number and service_credit to MPS Device Details
PROCEDURE UPDATE_REQ_NUMBER(      p_errbuf                  OUT NOCOPY VARCHAR2
                                , p_retcode                 OUT NOCOPY VARCHAR2
                                , p_aops_cust_id            IN         NUMBER  
                                , p_request_number          IN         VARCHAR2 
                                , p_service_credit          IN         NUMBER )
IS

BEGIN
   
  update XX_CS_MPS_DEVICE_DETAILS
  set    request_number            = p_request_number
       , service_credit            = nvl(p_service_credit,0)
  where  device_id in (select device_id 
                         from xx_cs_mps_device_b 
                        where aops_cust_number = p_aops_cust_id
                       )
  and    supplies_label            = 'USAGE';

  COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      --log_exception
      LOG_ERROR('XX_CS_MPS_USGDTA_TRANSMIT_PKG.UPDATE_REQ_NUMBER', 'Exception: ' || SQLERRM);
      p_retcode := 2;
END UPDATE_REQ_NUMBER;

  
END XX_CS_MPS_USGDTA_TRANSMIT_PKG;
/
show errors;