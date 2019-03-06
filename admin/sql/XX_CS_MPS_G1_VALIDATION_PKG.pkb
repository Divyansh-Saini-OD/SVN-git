create or replace
PACKAGE BODY XX_CS_MPS_G1_VALIDATION_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_G1_VALIDATION_PKG.pkb                                                   |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        22-NOV-2013   Sreedhar Mohan        Validations for MPS Customers                  |
-- +==============================================================================================+

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

FUNCTION create_request_body (  p_business_name IN  VARCHAR2
                              , p_address1      IN  VARCHAR2
                              , p_address2      IN  VARCHAR2
                              , p_city          IN  VARCHAR2
                              , p_state         IN  VARCHAR2
                              , p_postal_code   IN  VARCHAR2)
RETURN VARCHAR2  
AS

  l_req_msg_body   varchar2(32767) := null;
begin
  l_req_msg_body := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
 	                  <soap:Body xmlns:ns1="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService">
        		       <ns1:AddressValidationServiceRequest>
            			 <ns1:CustomerInformation>
                				<ns1:ClientName></ns1:ClientName>
                				<ns1:ApplicationName></ns1:ApplicationName>
                				<ns1:MiscellaneousDataCleanup>Y</ns1:MiscellaneousDataCleanup>
                				<ns1:ValidateAddress>Y</ns1:ValidateAddress>
                				<ns1:DetailGeographicalCode>Y</ns1:DetailGeographicalCode>
                				<ns1:IfMultipleOriginReturnOrigin>N</ns1:IfMultipleOriginReturnOrigin>
                				<ns1:AddressValidated>N</ns1:AddressValidated>
                				<ns1:AddressOverriden>N</ns1:AddressOverriden>
                				<ns1:BusinessName>' || p_business_name || '</ns1:BusinessName>
                				<ns1:Address>
                    					<ns1:StreetNameOne>' || p_address1 || '</ns1:StreetNameOne>
                    					<ns1:StreetNameTwo>' || p_address2 || '</ns1:StreetNameTwo>
                    					<ns1:PostOfficeBox></ns1:PostOfficeBox>
                    					<ns1:CityName>'      || p_city      || '</ns1:CityName>
                    					<ns1:StateName>'     || p_state     || '</ns1:StateName>
                    					<ns1:ZipCode>'       || p_postal_code || '</ns1:ZipCode>
                    					<ns1:Province></ns1:Province>
                    					<ns1:Country>USA</ns1:Country>
                    					<ns1:CountyName></ns1:CountyName>
                    					<ns1:Urbanization></ns1:Urbanization>
                    					<ns1:DeliveryPointCode></ns1:DeliveryPointCode>
                    					<ns1:ResidentialDeliveryIndicator></ns1:ResidentialDeliveryIndicator>
                                </ns1:Address>
                          </ns1:CustomerInformation>
                       </ns1:AddressValidationServiceRequest>
                      </soap:Body>
                     </soap:Envelope>';
  return l_req_msg_body;  
EXCEPTION
    WHEN OTHERS THEN
      --log_exception
    LOG_ERROR('XX_CS_MPS_G1_VALIDATION_PKG.CREATE_REQUEST_BODY', 'Exception: ' || SQLERRM);
      --RAISE;      
      return null;
end create_request_body;

FUNCTION post_content ( p_req_msg_body VARCHAR2)
RETURN VARCHAR2  
AS

  soap_request      VARCHAR2(32767);
  soap_respond      VARCHAR2(32767);
  req               utl_http.req;
  resp              utl_http.resp;
  x_resp            XMLTYPE;
  lc_resp_code      VARCHAR2(255);
  l_msg_data        varchar2(32767);
  l_webserv_uname   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_G1_WS_AUTH_NAME'); --'sfdcuser'; 
  l_webserv_pword   VARCHAR2(240) := FND_PROFILE.VALUE('XX_CS_MPS_G1_WS_AUTH_STR');  --'sfdcuser123';         
  l_service_url     VARCHAR2(2000) := FND_PROFILE.VALUE('XX_CS_MPS_G1_WS_URL');
  --'http://soasit01.na.odcorp.net/soa-infra/services/cdh_rt/G1AddressValidationProcess/G1AddressValidationService_Client_ep';

begin
   log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.POST_CONTENT','Start');      

   l_msg_data := p_req_msg_body;

   req := utl_http.begin_request(l_service_url,'POST','HTTP/1.1');
   utl_http.set_authentication(req, l_webserv_uname, l_webserv_pword); 
   utl_http.set_header(req,'Content-Type', 'text/xml'); 
   utl_http.set_header(req,'Content-Length', length(l_msg_data));
   utl_http.set_header(req,'SOAPAction'  , 'process');
   utl_http.write_text(req, l_msg_data);

   resp := utl_http.get_response(req);
   utl_http.read_text(resp, soap_respond);

   utl_http.end_response(resp);
   log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.POST_CONTENT','End');      

   return soap_respond;
EXCEPTION
    WHEN OTHERS THEN
      --log_exception
    LOG_ERROR('XX_CS_MPS_G1_VALIDATION_PKG.POST_CONTENT', 'Exception: ' || SQLERRM);
      --RAISE;      
      return null;
end post_content;

--check address is valid for the customer
PROCEDURE  validate_address(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_business_name         IN          VARCHAR2
            , p_address1              IN          VARCHAR2
            , p_address2              IN          VARCHAR2
            , p_city                  IN          VARCHAR2
            , p_state                 IN          VARCHAR2
            , p_postal_code           IN          VARCHAR2
            , p_g1_address1           OUT NOCOPY  VARCHAR2
            , p_g1_address2           OUT NOCOPY  VARCHAR2
            , p_g1_city               OUT NOCOPY  VARCHAR2
            , p_g1_state              OUT NOCOPY  VARCHAR2
            , p_g1_postal_code        OUT NOCOPY  VARCHAR2
            , p_g1_county             OUT NOCOPY  VARCHAR2			
            , p_g1_addr_error         OUT NOCOPY  VARCHAR2
            , p_g1_addr_code          OUT NOCOPY  VARCHAR2
            , p_g1_ws_error           OUT NOCOPY  VARCHAR2
          )
IS

  soap_respond      VARCHAR2(32767);
  x_resp              XMLTYPE;
  
  l_req_msg_body      varchar2(32767) := null;

  WSErrMsg            VARCHAR2(2000) := null;  
  tempErrMsg          VARCHAR2(2000) := null;
  tempRetCodeMsg      VARCHAR2(2000) := null;
  addressError        VARCHAR2(2000) := null;
  tempRetCode         VARCHAR2(30) := null;
  tempRetCode1        VARCHAR2(30) := null;
  addressRetCode      VARCHAR2(30) := null;
                      
  g1_address1         varchar2(255) := null;
  g1_address2         varchar2(255) := null;
  g1_city             varchar2(255) := null;
  g1_state            varchar2(255) := null;
  g1_postal_code      varchar2(255) := null;
  g1_county           varchar2(255) := null;
  

BEGIN
  log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.VALIDATE_ADDRESS','Start');      
  l_req_msg_body := create_request_body(
                                           p_business_name
										 , p_address1     
										 , p_address2     
										 , p_city         
										 , p_state        
										 , p_postal_code  
                                        );
										
  soap_respond := post_content ( l_req_msg_body);
  
  begin
   x_resp := XMLType.createXML(soap_respond);

   WSErrMsg := x_resp.extract('//'||'ErrorMessage'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
   log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.VALIDATE_ADDRESS','WSErrMsg: ' || WSErrMsg);      
   
   addressRetCode :=  x_resp.extract('//'||'AddressReturnCode'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
   log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.VALIDATE_ADDRESS','addressRetCode: ' || addressRetCode);      


  exception
     when others then
     tempRetCodeMsg := substrb(soap_respond, instr(soap_respond, '<tns:AddressReturnCode>') + length('<tns:AddressReturnCode>'));
     tempRetCodeMsg := substrb(tempRetCodeMsg,0, instr(tempRetCodeMsg, '</tns:AddressReturnCode>')-1);
     addressRetCode := tempRetCodeMsg;
     tempErrMsg := substrb(soap_respond, instr(soap_respond, '<tns:AddressErrorMessage>') + length('<tns:AddressErrorMessage>'));
     addressError := trim(substrb(tempErrMsg, 1, instr(tempErrMsg, '</tns:AddressErrorMessage>')-1));
  end;

  begin     
  if (trim(addressRetCode) = '0') then
  
    g1_address1 := x_resp.extract('//'||'StreetNameOne'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
    g1_address2 := x_resp.extract('//'||'StreetNameTwo'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
    g1_city     := x_resp.extract('//'||'CityName'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
    g1_state    := x_resp.extract('//'||'StateName'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
    g1_postal_code := x_resp.extract('//'||'ZipCode'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
    g1_county   := x_resp.extract('//'||'CountyName'||'/child::text()','xmlns="http://xmlns.oracle.com/G1AddressValidation/G1AddressValidationService"').getstringval();
  end if;
  EXCEPTION
    WHEN OTHERS THEN
      --log_exception
      dbms_output.put_line('Exception: ' || SQLERRM);
  end;
    p_g1_address1    := g1_address1;     
    p_g1_address2    := g1_address2; 
    p_g1_city        := g1_city;     
    p_g1_state       := g1_state;    
    p_g1_postal_code := g1_postal_code;
    p_g1_county      := g1_county;
	p_g1_addr_error  := addressError;
	p_g1_addr_code   := addressRetCode;
	p_g1_ws_error    := WSErrMsg;
	
  log_debug_msg('XX_CS_MPS_G1_VALIDATION_PKG.VALIDATE_ADDRESS','End');      

EXCEPTION 
    WHEN OTHERS THEN
        LOG_ERROR('XX_CS_MPS_G1_VALIDATION_PKG.VALIDATE_ADDRESS', 'Exception: ' || SQLERRM);
        p_retcode :=2;
        p_errbuf := SQLERRM;
END validate_address;

END XX_CS_MPS_G1_VALIDATION_PKG;
/
SHOW ERRORS;
