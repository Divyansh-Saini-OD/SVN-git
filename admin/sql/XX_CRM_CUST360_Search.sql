create or replace PROCEDURE custSearch360 (
ps_custname     IN  VARCHAR2,
ps_sareacode    IN  VARCHAR2,
ps_phoneprefix  IN  VARCHAR2,
ps_phonenumber  IN  VARCHAR2,
s_custloy       OUT XX_CUST_FROM_LOY_OBJ_TBL,
s_custaops      OUT XX_CUST_FROM_AOPS_OBJ_TBL,
s_custcdh       OUT XX_CUST_FROM_CDH_OBJ_TBL,
s_custphone     OUT XX_CUST_BY_PHONE_OBJ_TBL
)
as
  l_request   soap_api.t_request;
  l_response  soap_api.t_response;
  l_return    VARCHAR2(32767);
  l_return2    VARCHAR2(32767);
  l_return3    VARCHAR2(32767);
  l_url          VARCHAR2(32767);
  l_namespace    VARCHAR2(32767);
  l_method       VARCHAR2(32767);
  l_soap_action  VARCHAR2(32767);
  l_result_name  VARCHAR2(32767);  
  cnter           NUMBER;
  

  s_custloyobj    XX_CUST_FROM_LOY_OBJ;
  s_custaopsobj   XX_CUST_FROM_AOPS_OBJ;
  s_custcdhobj    XX_CUST_FROM_CDH_OBJ;
  s_custphoneobj  XX_CUST_BY_PHONE_OBJ;

  ph_CustomerId         VARCHAR2(50);
  ph_BusinessName       VARCHAR2(300);
  ph_StreetAddress1     VARCHAR2(100);
  ph_StreetAddress2     VARCHAR2(100);
  ph_City               VARCHAR2(40);
  ph_State              VARCHAR2(20);
  ph_Province           VARCHAR2(20);
  ph_ZipCode            VARCHAR2(20);
  ph_Country            VARCHAR2(20);
  
  cdh_CustomerId         VARCHAR2(50);
  cdh_BusinessName       VARCHAR2(300);
  cdh_StreetAddress1     VARCHAR2(100);
  cdh_StreetAddress2     VARCHAR2(100);
  cdh_City               VARCHAR2(40);
  cdh_State              VARCHAR2(20);
  cdh_Province           VARCHAR2(20);
  cdh_ZipCode            VARCHAR2(20);
  cdh_Country            VARCHAR2(20);
  
  aops_CustomerId         VARCHAR2(50);
  aops_BusinessName       VARCHAR2(300);
  aops_StreetAddress1     VARCHAR2(100);
  aops_StreetAddress2     VARCHAR2(100);
  aops_City               VARCHAR2(40);
  aops_State              VARCHAR2(20);
  aops_Province           VARCHAR2(20);
  aops_ZipCode            VARCHAR2(20);
  aops_Country            VARCHAR2(20);
  
  loy_MemberId           VARCHAR2(50);
  loy_FirstName          VARCHAR2(200);
  loy_LastName           VARCHAR2(200);
  loy_Company            VARCHAR2(300);
  loy_Address1           VARCHAR2(100);
  loy_Address2           VARCHAR2(100);
  loy_City               VARCHAR2(40);
  loy_State              VARCHAR2(20);
  loy_ZipCode            VARCHAR2(20);
  loy_Country            VARCHAR2(200);
  loy_Phone              VARCHAR2(60);
  loy_Email              VARCHAR2(100);
  loy_AddedDate          VARCHAR2(50);
  loy_ActivatedDate      VARCHAR2(50);
  
BEGIN
  -- Set proxy details if no direct net connection.
  --UTL_HTTP.set_proxy('myproxy:4480', NULL);
  --UTL_HTTP.set_persistent_conn_support(TRUE);

  -- Set proxy authentication if necessary.
  --soap_api.set_proxy_authentication(p_username => 'myusername',
  --                                  p_password => 'mypassword');


   
  l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/FindCustService/d20100315_t15.34.25_r00096085_p38936.12';
  l_namespace    := 'xmlns="http://xmlns.oracle.com/FindCustService"';
  l_method       := 'FindCustServiceProcessRequest';
  l_soap_action  := 'process';


  l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


  soap_api.add_parameter(p_request => l_request,
                         p_name    => 'CustomerName',
                         p_type    => 'xsd:string',
                         p_value   => ps_custname);

    soap_api.add_parameter(p_request => l_request,
                         p_name    => 'AreaCode',
                         p_type    => 'xsd:string',
                         p_value   => ps_sareacode);

    soap_api.add_parameter(p_request => l_request,
                         p_name    => 'PhonePrefix',
                         p_type    => 'xsd:string',
                         p_value   => ps_phoneprefix
                        );
                         
    soap_api.add_parameter(p_request => l_request,
                         p_name    => 'PhoneNumber',
                         p_type    => 'xsd:string',
                         p_value   => ps_phonenumber);

 l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);

  
  
  cnter := 1;
  ph_CustomerId := 'X';
  s_custphone := XX_CUST_BY_PHONE_OBJ_TBL();
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/FindCustService"';
  
  WHILE 1=1 LOOP
  
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/CustomerId';
  ph_CustomerId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/BusinessName';
  ph_BusinessName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/StreetAddress1';
  ph_StreetAddress1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/StreetAddress2';
  ph_StreetAddress2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/City';
  ph_City := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/State';
  ph_State := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/Province';
  ph_Province := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/ZipCode';
  ph_ZipCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'QueryCustByPhoneNumOutput[' || cnter || ']/Country';
  ph_Country := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
    IF ph_CustomerId IS NULL THEN
       EXIT;
    END IF;
    
     s_custphoneobj := XX_CUST_BY_PHONE_OBJ(ph_CustomerId,ph_BusinessName,ph_StreetAddress1,ph_StreetAddress2,ph_City,ph_State,ph_Province,ph_ZipCode,ph_Country);
     s_custphone.extend;
     s_custphone(cnter) := s_custphoneobj;
     cnter := cnter + 1;
                                        
  END LOOP;
  
  
  cnter := 1;
  aops_CustomerId := 'X';
  s_custaops := XX_CUST_FROM_AOPS_OBJ_TBL();
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/FindCustFromAOPS"';
  
  WHILE 1=1 LOOP
  
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/CustomerId';
  aops_CustomerId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/BusinessName';
  aops_BusinessName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/StreetAddress1';
  aops_StreetAddress1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/StreetAddress2';
  aops_StreetAddress2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/City';
  aops_City := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/State';
  aops_State := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/Province';
  aops_Province := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/ZipCode';
  aops_ZipCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustFromAOPSOutput[' || cnter || ']/Country';
  aops_Country := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
    IF aops_CustomerId IS NULL THEN
       EXIT;
    END IF;
    
     s_custaopsobj := XX_CUST_FROM_AOPS_OBJ(aops_CustomerId,aops_BusinessName,aops_StreetAddress1,aops_StreetAddress2,aops_City,aops_State,aops_Province,aops_ZipCode,aops_Country);
     s_custaops.extend;
     s_custaops(cnter) := s_custaopsobj;
     cnter := cnter + 1;
                                        
  END LOOP;
  
  
  cnter := 1;
  cdh_CustomerId := 'X';
  s_custcdh := XX_CUST_FROM_CDH_OBJ_TBL();
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/FindCustService"';
  
  WHILE 1=1 LOOP
  
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/ORIG_SYSTEM_REFERENCE';
  cdh_CustomerId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  cdh_CustomerId := substr(cdh_CustomerId,0,8);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/PartyName';
  cdh_BusinessName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/ADDRESS1';
  cdh_StreetAddress1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/ADDRESS2';
  cdh_StreetAddress2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/CITY';
  cdh_City := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/STATE';
  cdh_State := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/PROVINCE';
  cdh_Province := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/POSTAL_CODE';
  cdh_ZipCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'FindCustServiceProcessResponse/GetCDH_CustByNameOutput[' || cnter || ']/COUNTRY';
  cdh_Country := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
    IF cdh_CustomerId IS NULL THEN
       EXIT;
    END IF;
    
     s_custcdhobj := XX_CUST_FROM_CDH_OBJ(cdh_CustomerId,cdh_BusinessName,cdh_StreetAddress1,cdh_StreetAddress2,cdh_City,cdh_State,cdh_Province,cdh_ZipCode,cdh_Country);
     s_custcdh.extend;
     s_custcdh(cnter) := s_custcdhobj;
     cnter := cnter + 1;
                                        
  END LOOP;
  
  
  cnter := 1;
  loy_MemberId := 'X';
  s_custloy := XX_CUST_FROM_LOY_OBJ_TBL();
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetCustInfoFromLoyaltyByName"';
  
  WHILE 1=1 LOOP
  
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/MemberId';
  loy_MemberId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/FirstName';
  loy_FirstName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/LastName';
  loy_LastName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Company';
  loy_Company := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Address1';
  loy_Address1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Address2';
  loy_Address2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/City';
  loy_City := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/State';
  loy_State := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/ZipCode';
  loy_ZipCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Country';
  loy_Country := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Phone';
  loy_Phone := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/Email';
  loy_Email := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/AddedDate';
  loy_AddedDate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
  l_result_name := 'GetCustInfoFromLoyaltyByNameOutput[' || cnter || ']/ActivatedDate';                                      
  loy_ActivatedDate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
    IF loy_MemberId IS NULL THEN
       EXIT;
    END IF;
    
     s_custloyobj := XX_CUST_FROM_LOY_OBJ(loy_MemberId,loy_FirstName,loy_LastName,loy_Company,loy_Address1,loy_Address2,loy_City,loy_State,loy_ZipCode,loy_Country,loy_Phone,loy_Email,loy_AddedDate,loy_ActivatedDate);
     s_custloy.extend;
     s_custloy(cnter) := s_custloyobj;
     cnter := cnter + 1;
                                        
  END LOOP;
   
END custSearch360;
/