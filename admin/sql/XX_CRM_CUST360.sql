create or replace PROCEDURE cust360 (
acctid          IN  VARCHAR2,
lid             IN  VARCHAR2,
pnum            IN  VARCHAR2,
bsname          OUT VARCHAR2,
pphone          OUT VARCHAR2,
ad1             OUT VARCHAR2,
ad2             OUT VARCHAR2,
city            OUT VARCHAR2,
state           OUT VARCHAR2,
wlrorderdt	    OUT VARCHAR2,
wlrorderid	    OUT VARCHAR2,
wlrpuramt	      OUT VARCHAR2,
wlrcatrwd	      OUT VARCHAR2,
wlrfname	      OUT VARCHAR2,
wlrlname	      OUT VARCHAR2,
wlrcomp	        OUT VARCHAR2,
wlraddr	        OUT VARCHAR2,
wlraddrcont     OUT VARCHAR2,
wlrcity	        OUT VARCHAR2,
wlrstate        OUT VARCHAR2,
wlrzip          OUT VARCHAR2,
wlrphone        OUT VARCHAR2,
wlremail        OUT VARCHAR2,
wlrmemtype      OUT VARCHAR2,
wlrmemid        OUT VARCHAR2,
wlrenrltype     OUT VARCHAR2,
wlractivated    OUT VARCHAR2,
wlrsegid        OUT VARCHAR2,
csdesc          OUT VARCHAR2,
csindt          OUT VARCHAR2,
csresdt         OUT VARCHAR2,
csclosedt       OUT VARCHAR2,
cscasecsr       OUT VARCHAR2,
cssumm          OUT VARCHAR2,
csstatus        OUT VARCHAR2,
reposr          OUT VARCHAR2,
repcity         OUT VARCHAR2,
repstate        OUT VARCHAR2,
reprsname       OUT VARCHAR2,
repid           OUT VARCHAR2,
reprolecode     OUT VARCHAR2,
repstdt         OUT VARCHAR2,
repaccttype     OUT VARCHAR2,
orderinfo       OUT XX_ORDER_DET_OBJ_TBL,
caseinfo        OUT XX_CASE_DET_OBJ_TBL,
priceinfo       OUT XX_PRICE_DET_OBJ_TBL,
loyinfo         OUT XX_LOY_DET_OBJ_TBL,
finpinfo        OUT XX_FIN_PARENT_OBJ_TBL,
fincinfo        OUT XX_FIN_CHILD_OBJ_TBL,
abflag          OUT VARCHAR2,
raterm          OUT VARCHAR2,
terms           OUT VARCHAR2,
collectorid     OUT VARCHAR2,
billingfreq     OUT VARCHAR2,
expseg          OUT VARCHAR2,
custtype        OUT VARCHAR2,
campinfo        OUT XX_EMAIL_CAMP_OBJ_TBL,
bckorderinfo    OUT XX_BACK_ORDER_OBJ_TBL,
billinginfo     OUT XX_BILLING_INFO_OBJ_TBL,
pastdueinfo     OUT XX_PAST_DUE_OBJ_TBL,
taxexemptinfo   OUT XX_TAX_EXEMPT_OBJ_TBL,
p_search        IN  VARCHAR2,
ps_custname     IN  VARCHAR2,
ps_sareacode    IN  VARCHAR2,
ps_phoneprefix  IN  VARCHAR2,
ps_phonenumber  IN  VARCHAR2,
s_custloy       OUT XX_CUST_FROM_LOY_OBJ_TBL,
s_custaops      OUT XX_CUST_FROM_AOPS_OBJ_TBL,
s_custcdh       OUT XX_CUST_FROM_CDH_OBJ_TBL,
s_custphone     OUT XX_CUST_BY_PHONE_OBJ_TBL,
custinfometa    OUT XX_CUST_INFO_META_OBJ_TBL
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
  orderobj        XX_ORDER_DET_OBJ;
  caseobj         XX_CASE_DET_OBJ;
  priceobj        XX_PRICE_DET_OBJ;
  loyobj          XX_LOY_DET_OBJ;
  finpobj         XX_FIN_PARENT_OBJ;
  fincobj         XX_FIN_CHILD_OBJ;
  campobj         XX_EMAIL_CAMP_OBJ;
  bckorderobj     XX_BACK_ORDER_OBJ;
  billingobj      XX_BILLING_INFO_OBJ;
  pastdueobj      XX_PAST_DUE_OBJ;
  taxexemptobj    XX_TAX_EXEMPT_OBJ;
  s_custloyobj    XX_CUST_FROM_LOY_OBJ;
  s_custaopsobj   XX_CUST_FROM_AOPS_OBJ;
  s_custcdhobj    XX_CUST_FROM_CDH_OBJ;
  s_custphoneobj  XX_CUST_BY_PHONE_OBJ;
  custinfometa_obj XX_CUST_INFO_META_OBJ;
  order_num       VARCHAR2(100);
  order_tot       VARCHAR2(100);
  shipto_ref      VARCHAR2(100);
  salesrep_id     VARCHAR2(100);
  order_dt        VARCHAR2(100);
  cnter           NUMBER;
  IncidentNumber  VARCHAR2(100);
  PartyName       VARCHAR2(300);
  Description     VARCHAR2(2000);
  IncidentDate    VARCHAR2(100);
  CloseDate       VARCHAR2(100);
  ResolvedDate    VARCHAR2(100);
  Status          VARCHAR2(100);
  CSR             VARCHAR2(100);
  Sumary          VARCHAR2(1500);
  Creator         VARCHAR2(100);
  ProductCode     VARCHAR2(100);
  ProductName     VARCHAR2(300);
  SkuPrice        VARCHAR2(100);
  ContractId      VARCHAR2(100);
  AddressSeq      VARCHAR2(100);
  custaccountid   VARCHAR2(100);
  accountname     VARCHAR2(500);
  custstatus      VARCHAR2(10);
  OrgPartyNum                   VARCHAR2(100);
  CustTypeCode                  VARCHAR2(50);
  OrgName                       VARCHAR2(300);
  PersonPartyNum                VARCHAR2(100);
  FirstName                     VARCHAR2(100);
  LastName                      VARCHAR2(100);
  EmailAdd                      VARCHAR2(100);
  EmailCampDt                   VARCHAR2(100);
  EmailCampSegCode              VARCHAR2(50);
  EmailCampZoneCode             VARCHAR2(50);
  TelCountryCd                  VARCHAR2(50);
  TelAreaCd                     VARCHAR2(50);
  TelNum                        VARCHAR2(50);
  CampMsg                       VARCHAR2(200);
  b_OrderId                   VARCHAR2(100);
  b_TotalOrderAmt             VARCHAR2(50);
  b_BackOrderQty              VARCHAR2(300);
  b_ItemId                    VARCHAR2(100);
  b_UnitListPriceAmt          VARCHAR2(100);
  b_UnitOriginalPriceAmt      VARCHAR2(100);
  b_UnitPoCostAmt             VARCHAR2(100);
  b_UnitSellingPriceAmt       VARCHAR2(100);
  
  REPORTING_LOC                 VARCHAR2(100);
  SALESPERSON_ID                VARCHAR2(50);
  AR_FLAG                       VARCHAR2(300);
  BILL_TO_LIMIT                 VARCHAR2(100);
  BILL_TO_DOLLARS               VARCHAR2(100);
  BILL_TO_DOLLAR_EXPIRE         VARCHAR2(100);
  ORDER_LIMIT                   VARCHAR2(100);
  LINE_LIMIT                    VARCHAR2(100);
  ORDER_REST_IND                VARCHAR2(50);
  ADDR_ORDER_REST_IND           VARCHAR2(50);
  BACKORDER_ALLOW_FLAG          VARCHAR2(50);
  FREIGHT_CHG_REQ_FLAG          VARCHAR2(50);
  CONTRACT_CODE                 VARCHAR2(50);
  ADDR_CONTRACT_CODE            VARCHAR2(200);
  PRODUCT_XREF_NBR              VARCHAR2(100);
  PRICE_PLAN                    VARCHAR2(100);
  PRICE_PLAN_SEQ                VARCHAR2(100);
  FILLER                        VARCHAR2(100);
  
  DueDate                     VARCHAR2(50);
  AmountDueOriginal           VARCHAR2(20);
  AmountDueRemaining          VARCHAR2(20);
  AcctdAmoundDueRemaining     VARCHAR2(100);
  AmountApplied               VARCHAR2(40);
  AmountAdjusted              VARCHAR2(300);
  AmountInDispute             VARCHAR2(20);
  AmountCredited              VARCHAR2(40);
  InCollection                VARCHAR2(40);
  ActiveClaimFlag             VARCHAR2(20);
  DiscountOriginal            VARCHAR2(30);
  DiscountRemaining           VARCHAR2(30);
  DiscountTakenEarned         VARCHAR2(30);
  
  ADDRESS_SEQ            VARCHAR2(50);
  ADDRESS_STATE          VARCHAR2(20);
  COUNTRY_CODE           VARCHAR2(20);
  TAX_CERTIF_NBR         VARCHAR2(100);
  EXP_DATE               VARCHAR2(40);
  GST_EXEMPT_COMMENT     VARCHAR2(300);
  TAX_STATUS             VARCHAR2(20);
  ADDR_SEQ_DENLET        VARCHAR2(40);
  DENIAL_SEND_DATE       VARCHAR2(40);
  LETTER_NOTIF           VARCHAR2(100);
  FEDERAL_EXEMPT         VARCHAR2(100);
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
  contract_DataSource    VARCHAR2(100);
  contract_fetchtime     VARCHAR2(100);
  AopsCustInfoDataSource              VARCHAR2(100);
  AopsCustInfoFetchTime               VARCHAR2(100);
  AopsCustOrderInfoDataSource         VARCHAR2(100);
  AopsCustOrderInfoFetchTime          VARCHAR2(100);
  AopsCustBillingInfoDataSource       VARCHAR2(100);
  AopsCustBillingInfoFetchTime        VARCHAR2(100);
  GetBillingFreqDataSource            VARCHAR2(100);
  GetBillingFreqFetchTime             VARCHAR2(100);
  GetCustFinInfoDataSource            VARCHAR2(100);
  GetCustFinInfoFetchTime             VARCHAR2(100);
  GetCustPastDueInfoDataSource        VARCHAR2(100);
  GetCustPastDueInfoFetchTime         VARCHAR2(100);
  GetFinHierChildrenDataSource        VARCHAR2(100);
  GetFinHierChildrenFetchTime         VARCHAR2(100);
  GetParentAcctFinInfoDataSource      VARCHAR2(100);
  GetParentAcctFinInfoFetchTime       VARCHAR2(100);
  GetRepAssignmentsDataSource         VARCHAR2(100);
  GetRepAssignmentsFetchTime          VARCHAR2(100);
  GetTaxExemptInfoDataSource          VARCHAR2(100);
  GetTaxExemptInfoFetchTime           VARCHAR2(100);
  GetTeraDataCustInfoDataSource       VARCHAR2(100);
  GetTeraDataCustInfoFetchTime        VARCHAR2(100);
  LoyaltyMbrEnrollDataSource          VARCHAR2(100);
  LoyaltyMbrEnrollFetchTime           VARCHAR2(100);
  LoyaltyMbrPurchaseDataSource        VARCHAR2(100);
  LoyaltyMbrPurchaseFetchTime            VARCHAR2(100); 
  GetAOPS_ContractDataSource            VARCHAR2(100); 
  GetAOPS_ContractFetchTime              VARCHAR2(100); 
  GetCDH_CustOrderInfoDataSource         VARCHAR2(100); 
  GetCDH_CustOrderInfoFetchTime          VARCHAR2(100); 
  GetOpenCasesDataSource                 VARCHAR2(100); 
  GetOpenCasesFetchTime                  VARCHAR2(100); 
  cases_datasource                VARCHAR2(100);
  cases_fetchtime                 VARCHAR2(100);
BEGIN
  -- Set proxy details if no direct net connection.
  --UTL_HTTP.set_proxy('myproxy:4480', NULL);
  --UTL_HTTP.set_persistent_conn_support(TRUE);

  -- Set proxy authentication if necessary.
  --soap_api.set_proxy_authentication(p_username => 'myusername',
  --                                  p_password => 'mypassword');

IF p_search = 'N' THEN

  l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/GetCustInfo/d20100507_t14.31.25_r00101615_p38724.56';
  l_namespace    := 'xmlns="http://TargetNamespace.com/OD_CUSTOMER"';
  l_method       := 'OD_CUSTOMER';
  l_soap_action  := 'process';


  l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


  soap_api.add_parameter(p_request => l_request,
                         p_name    => 'ACCOUNT_OSR',
                         p_type    => 'xsd:long',
                         p_value   => acctid);

    soap_api.add_parameter(p_request => l_request,
                         p_name    => 'PHONE_NUMBER',
                         p_type    => 'xsd:string',
                         p_value   => pnum);

    soap_api.add_parameter(p_request => l_request,
                         p_name    => 'LOYALTY_ID',
                         p_type    => 'xsd:long',
                         p_value   => lid);

 l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);
                                
 --- Custinfo Meta Data
 
     cnter := 1;
     AopsCustInfoDataSource := 'X';
     custinfometa := XX_CUST_INFO_META_OBJ_TBL();
     l_namespace   := 'xmlns="http://xmlns.oracle.com/GetCustInfo"';
     
     
     
  WHILE 1 = 1 LOOP
  
     l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustInfoDataSource';
     
     AopsCustInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
     
     l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustInfoFetchTime';
     
     AopsCustInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustOrderInfoDataSource';
     
     AopsCustOrderInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
      l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustOrderInfoFetchTime';
     
     AopsCustOrderInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustBillingInfoDataSource';
     
     AopsCustBillingInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/AopsCustBillingInfoFetchTime';
     
     AopsCustBillingInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 

     l_result_name := 'MetaDatInfo[' || cnter || ']/GetBillingFreqDataSource';
     
     GetBillingFreqDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetBillingFreqFetchTime';
     
     GetBillingFreqFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCustFinInfoDataSource';
     
     GetCustFinInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCustFinInfoFetchTime';
     
     GetCustFinInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCustPastDueInfoDataSource';
     
     GetCustPastDueInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCustPastDueInfoFetchTime';
     
     GetCustPastDueInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
                                
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetFinHierChildrenDataSource';
     
     GetFinHierChildrenDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetFinHierChildrenFetchTime';
     
     GetFinHierChildrenFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetParentAcctFinInfoDataSource';
     
     GetParentAcctFinInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetParentAcctFinInfoFetchTime';

     GetParentAcctFinInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
     
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetRepAssignmentsDataSource';
     
     GetRepAssignmentsDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetRepAssignmentsFetchTime';
     
     GetRepAssignmentsFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
      l_result_name := 'MetaDatInfo[' || cnter || ']/GetTaxExemptInfoDataSource';
     
     GetTaxExemptInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetTaxExemptInfoFetchTime';
     
     GetTaxExemptInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetTeraDataCustInfoDataSource';
     
     GetTeraDataCustInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 

     l_result_name := 'MetaDatInfo[' || cnter || ']/GetTeraDataCustInfoFetchTime';
     
     GetTeraDataCustInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/LoyaltyMbrEnrollmentInfoDataSource';
     
     LoyaltyMbrEnrollDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/LoyaltyMbrEnrollmentInfoFetchTime';
     
     LoyaltyMbrEnrollFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/LoyaltyMemberPurchaseHistoryDataSource';
     
     LoyaltyMbrPurchaseDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/LoyaltyMemberPurchaseHistoryFetchTime';
     
     LoyaltyMbrPurchaseFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetAOPS_ContractPricingDataSource';
     
     GetAOPS_ContractDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetAOPS_ContractPricingFetchTime';
     
     GetAOPS_ContractFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCDH_CustOrderInfoDataSource';
     
     GetCDH_CustOrderInfoDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetCDH_CustOrderInfoFetchTime';
     
     GetCDH_CustOrderInfoFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetOpenCasesDataSource';
     
     GetOpenCasesDataSource  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetOpenCasesFetchTime';
     
     GetOpenCasesFetchTime  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace); 
                                        
     l_result_name := 'MetaDatInfo[' || cnter || ']/GetAOPS_ContractPricingDataSource';
  
  
    IF AopsCustInfoDataSource IS NULL THEN
          EXIT;
    END IF;
         custinfometa_obj := XX_CUST_INFO_META_OBJ(
                          AopsCustInfoDataSource              
                         ,AopsCustInfoFetchTime               
                         ,AopsCustOrderInfoDataSource         
                         ,AopsCustOrderInfoFetchTime          
                         ,AopsCustBillingInfoDataSource       
                         ,AopsCustBillingInfoFetchTime        
                         ,GetBillingFreqDataSource            
                         ,GetBillingFreqFetchTime             
                         ,GetCustFinInfoDataSource            
                         ,GetCustFinInfoFetchTime             
                         ,GetCustPastDueInfoDataSource        
                         ,GetCustPastDueInfoFetchTime         
                         ,GetFinHierChildrenDataSource        
                         ,GetFinHierChildrenFetchTime         
                         ,GetParentAcctFinInfoDataSource      
                         ,GetParentAcctFinInfoFetchTime       
                         ,GetRepAssignmentsDataSource         
                         ,GetRepAssignmentsFetchTime          
                         ,GetTaxExemptInfoDataSource          
                         ,GetTaxExemptInfoFetchTime           
                         ,GetTeraDataCustInfoDataSource       
                         ,GetTeraDataCustInfoFetchTime        
                         ,LoyaltyMbrEnrollDataSource  
                         ,LoyaltyMbrEnrollFetchTime   
                         ,LoyaltyMbrPurchaseDataSource 
                         ,LoyaltyMbrPurchaseFetchTime   
                         ,GetAOPS_ContractDataSource       
                         ,GetAOPS_ContractFetchTime        
                         ,GetCDH_CustOrderInfoDataSource          
                         ,GetCDH_CustOrderInfoFetchTime           
                         ,GetOpenCasesDataSource                  
                         ,GetOpenCasesFetchTime                   
                    );
         custinfometa.extend;
         custinfometa(cnter) := custinfometa_obj;
         cnter := cnter + 1;
  END LOOP;  
  

  l_namespace   := 'xmlns="http://xmlns.oracle.com/GetCustInfo"';

  l_result_name := 'CustInfoBusinessName';


  bsname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'CustInfoPrimaryPhone';


  pphone := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);



  l_result_name := 'CustInfoStreetAddress1';


  ad1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'CustInfoStreetAddress2';


  ad2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'CustInfoCity';


  city := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'CustInfoState';


  state := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
    l_result_name := 'AbFlag';


  abflag := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
    l_result_name := 'RA_TermDescription';


  raterm := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
    l_result_name := 'Terms';


  terms := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
      l_result_name := 'CollectorId';


  collectorid := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
    
  l_result_name := 'BillingFrequency';


  billingfreq := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
     l_result_name := 'ExposureSegment';


  expseg := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
      l_result_name := 'CustInfoContRetailCode';


  custtype := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     cnter := 1;
     custaccountid := 'X';
     finpinfo := XX_FIN_PARENT_OBJ_TBL();
     l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetParentAcctFinInfo"';
  WHILE 1 = 1 LOOP
  
     l_result_name := 'GetParentAcctFinInfoOutput[' || cnter || ']/CustAccountId';


  custaccountid  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetParentAcctFinInfoOutput[' || cnter || ']/AccountName';


  accountname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetParentAcctFinInfoOutput[' || cnter || ']/Status';

  custstatus := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  IF custaccountid IS NULL THEN
          EXIT;
        END IF;
         finpobj := XX_FIN_PARENT_OBJ(custaccountid,accountname,custstatus);
         finpinfo.extend;
         finpinfo(cnter) := finpobj;
         cnter := cnter + 1;
  END LOOP;
  
  -- Billing Info
  
     cnter := 1;
     REPORTING_LOC := 'X';
     billinginfo := XX_BILLING_INFO_OBJ_TBL();
     l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetAOPS_CustBillingInfo"';
     
  WHILE 1 = 1 LOOP
  
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/REPORTING_LOC';


  REPORTING_LOC  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/SALESPERSON_ID';


  SALESPERSON_ID := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/AR_FLAG';


  AR_FLAG    := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/BILL_TO_LIMIT';

  BILL_TO_LIMIT := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/BILL_TO_DOLLARS';

  BILL_TO_DOLLARS := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/BILL_TO_DOLLAR_EXPIRE';

  BILL_TO_DOLLAR_EXPIRE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/ORDER_LIMIT';

  ORDER_LIMIT := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/LINE_LIMIT';

  LINE_LIMIT := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/ORDER_REST_IND';

  ORDER_REST_IND := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/ADDR_ORDER_REST_IND';

  ADDR_ORDER_REST_IND := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/BACKORDER_ALLOW_FLAG';

  BACKORDER_ALLOW_FLAG := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/FREIGHT_CHG_REQ_FLAG';

  FREIGHT_CHG_REQ_FLAG := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/CONTRACT_CODE';

  CONTRACT_CODE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/ADDR_CONTRACT_CODE';

  ADDR_CONTRACT_CODE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/PRODUCT_XREF_NBR';

  PRODUCT_XREF_NBR := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
   l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/PRICE_PLAN'; 
                                        
  PRICE_PLAN := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
   l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/PRICE_PLAN_SEQ';
   
  PRICE_PLAN_SEQ := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
    l_result_name := 'GetAOPS_CustBillingInfoOutput[' || cnter || ']/FILLER';
    
  FILLER := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        

                                        
  

  IF REPORTING_LOC IS NULL THEN
          EXIT;
        END IF;
         billingobj := XX_BILLING_INFO_OBJ(REPORTING_LOC,SALESPERSON_ID,AR_FLAG,BILL_TO_LIMIT,BILL_TO_DOLLARS,BILL_TO_DOLLAR_EXPIRE,ORDER_LIMIT,LINE_LIMIT,ORDER_REST_IND,ADDR_ORDER_REST_IND,BACKORDER_ALLOW_FLAG,FREIGHT_CHG_REQ_FLAG,CONTRACT_CODE,ADDR_CONTRACT_CODE,PRODUCT_XREF_NBR,PRICE_PLAN,PRICE_PLAN_SEQ,FILLER);
         billinginfo.extend;
         billinginfo(cnter) := billingobj;
         cnter := cnter + 1;
  END LOOP;
  
  
  -- Tax Exempt Info
  
     cnter := 1;
     ADDRESS_SEQ := 'X';
     taxexemptinfo := XX_TAX_EXEMPT_OBJ_TBL();
     l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetTaxExemptInfo';
     
  WHILE 1 = 1 LOOP
  
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/ADDRESS_SEQ';


  ADDRESS_SEQ  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/ADDRESS_STATE';


  ADDRESS_STATE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/COUNTRY_CODE';


  COUNTRY_CODE    := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/TAX_CERTIF_NBR';

  TAX_CERTIF_NBR := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/EXP_DATE';

  EXP_DATE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/GST_EXEMPT_COMMENT';

  GST_EXEMPT_COMMENT := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/TAX_STATUS';

  TAX_STATUS := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/ADDR_SEQ_DENLET';

  ADDR_SEQ_DENLET := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/DENIAL_SEND_DATE';

  DENIAL_SEND_DATE := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/LETTER_NOTIF';

  LETTER_NOTIF := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetTaxExemptInfoOutput[' || cnter || ']/FEDERAL_EXEMPT';

  FEDERAL_EXEMPT := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
 
  IF ADDRESS_SEQ IS NULL THEN
          EXIT;
  END IF;
         taxexemptobj := XX_TAX_EXEMPT_OBJ(ADDRESS_SEQ,ADDRESS_STATE,COUNTRY_CODE,TAX_CERTIF_NBR,EXP_DATE,GST_EXEMPT_COMMENT,TAX_STATUS,ADDR_SEQ_DENLET,DENIAL_SEND_DATE,LETTER_NOTIF,FEDERAL_EXEMPT);
         taxexemptinfo.extend;
         taxexemptinfo(cnter) := taxexemptobj;
         cnter := cnter + 1;
  END LOOP;

  -- Past Due Info
  
     cnter := 1;
     DueDate := 'X';
     pastdueinfo   := XX_PAST_DUE_OBJ_TBL();
    l_namespace   := 'xmlns:ns1="http://xmlns.oracle.com/GetCustInfo"';
     
  WHILE 1 = 1 LOOP
  
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/DueDate';


  DueDate  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountDueOriginal';


  AmountDueOriginal := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountDueRemaining';


  AmountDueRemaining    := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AcctdAmoundDueRemaining';

  AcctdAmoundDueRemaining := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountApplied';

  AmountApplied := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
  
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountAdjusted';

  AmountAdjusted := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountInDispute';

  AmountInDispute := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/AmountCredited';

  AmountCredited := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/InCollection';

  InCollection := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/ActiveClaimFlag';

  ActiveClaimFlag := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/DiscountOriginal';

  DiscountOriginal := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/DiscountRemaining';

  DiscountRemaining := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCustPastDueInfoOutput[' || cnter || ']/DiscountTakenEarned';

  DiscountTakenEarned := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
 
  IF DueDate IS NULL THEN
          EXIT;
  END IF;
         pastdueobj := XX_PAST_DUE_OBJ(DueDate,AmountDueOriginal,AmountDueRemaining,AcctdAmoundDueRemaining,AmountApplied,AmountAdjusted,AmountInDispute,AmountCredited,InCollection,ActiveClaimFlag,DiscountOriginal,DiscountRemaining,DiscountTakenEarned);
         pastdueinfo.extend;
         pastdueinfo(cnter) := pastdueobj;
         cnter := cnter + 1;
  END LOOP;



     cnter := 1;
     custaccountid := 'X';
     fincinfo := XX_FIN_CHILD_OBJ_TBL();
     l_namespace   := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetFinHierChildren"';
  WHILE 1 = 1 LOOP
  
     l_result_name := 'GetFinHierChildrenOutput[' || cnter || ']/CustAccountId';


  custaccountid  := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetFinHierChildrenOutput[' || cnter || ']/AccountName';


  accountname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'GetFinHierChildrenOutput[' || cnter || ']/Status';

  custstatus := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  IF custaccountid IS NULL THEN
          EXIT;
        END IF;
         fincobj := XX_FIN_CHILD_OBJ(custaccountid,accountname,custstatus);
         fincinfo.extend;
         fincinfo(cnter) := fincobj;
         cnter := cnter + 1;
  END LOOP;

  l_namespace    := 'xmlns="http://TargetNamespace.com/OD_CUSTOMER"';

 --------------- WorkLife Reward Details --------------------

     cnter := 1;
     wlrorderid := 'X';
     loyinfo := XX_LOY_DET_OBJ_TBL();

  WHILE 1 = 1 LOOP
  l_result_name := 'LoyaltyMemberPurchaseHistory[' || cnter || ']/LoyaltyMemberPurchaseHistoryOrderDt';


  wlrorderdt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMemberPurchaseHistory[' || cnter || ']/LoyaltyMemberPurchaseHistoryOrderId';


  wlrorderid := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMemberPurchaseHistory[' || cnter || ']/LoyaltyMemberPurchaseHistoryPurchaseAmt';

  wlrpuramt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMemberPurchaseHistory[' || cnter || ']/LoyaltyMemberPurchaseHistoryCat1Reward';

  wlrcatrwd := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

       IF wlrorderid IS NULL THEN
          EXIT;
        END IF;
         loyobj := XX_LOY_DET_OBJ(wlrorderdt,wlrorderid,wlrpuramt,wlrcatrwd);
         loyinfo.extend;
         loyinfo(cnter) := loyobj;
         cnter := cnter + 1;
  END LOOP;

  l_result_name := 'LoyaltyMbrEnrollmentInfoFirst_name';

  wlrfname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoLast_name';

  wlrlname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoCompany';

  wlrcomp := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoAd1';

  wlraddr := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoAd2';

  wlraddrcont := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   l_result_name := 'LoyaltyMbrEnrollmentInfoCity';

  wlrcity := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   l_result_name := 'LoyaltyMbrEnrollmentInfoState';

  wlrstate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   l_result_name := 'LoyaltyMbrEnrollmentInfoZip';

  wlrzip := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   l_result_name := 'LoyaltyMbrEnrollmentInfoPhone';

  wlrphone := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   l_result_name := 'LoyaltyMbrEnrollmentInfoEmail';

  wlremail := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);


    l_result_name := 'LoyaltyMbrEnrollmentInfoMembershipType';

  wlrmemtype := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'LoyaltyMbrEnrollmentInfoMemberId';

  wlrmemid := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoEnrollmentType';

  wlrenrltype := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoActivated';

  wlractivated := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

  l_result_name := 'LoyaltyMbrEnrollmentInfoSegmentId';

  wlrsegid := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);


   --------------- Case Management Details --------------------

    l_result_name := 'GetOpenCasesDescription';

    csdesc := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetOpenCasesIncidentDate';

    csindt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetOpenCasesResolvedDate';

    csresdt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetOpenCasesCloseDate';

    csclosedt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     l_result_name := 'GetOpenCasesCsr';

    cscasecsr := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetOpenCasesSummary';

    cssumm := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetOpenCasesStatus';

    csstatus := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);



    --------------- REP Assignment Details --------------------

    l_result_name := 'GetRepAssignmentsOrigSystemReference';

    reposr := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetRepAssignmentsCity';

    repcity := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

    l_result_name := 'GetRepAssignmentsState';

    repstate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     l_result_name := 'GetRepAssignmentsResourceName';

    reprsname := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

      l_result_name := 'GetRepAssignmentsRepId';

    repid := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     l_result_name := 'GetRepAssignmentsRoleCode';

    reprolecode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     l_result_name := 'GetRepAssignmentsassignmentStartDt';

    repstdt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

     l_result_name := 'GetRepAssignmentsCustAcctType';

    repaccttype := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

   --- Order Info Details

     l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/GetCustOrderInfo/d20100302_t16.42.53_r00095022_p38724.47';
     l_namespace    := 'xmlns="http://xmlns.oracle.com/GetCustOrderInfo"';
     l_method       := 'GetCustOrderInfoProcessRequest';
     l_soap_action  := 'process';


       l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'AOPS_CustID',
                         p_type    => 'xsd:string',
                         p_value   => acctid);

      soap_api.add_parameter(p_request => l_request,
                         p_name    => 'LoyaltyID',
                         p_type    => 'xsd:string',
                         p_value   => lid);

       l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);
       cnter := 1;
       order_num := 'X';
       orderinfo := XX_ORDER_DET_OBJ_TBL();

       --l_namespace := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetCustOrders"';

       WHILE 1 = 1 LOOP
        l_result_name := 'GetCustOrderInfoProcessResponse/OrderResultSet[' || cnter || ']/OrderNumber';
        order_num := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetCustOrderInfoProcessResponse/OrderResultSet[' || cnter || ']/OrderTotal';
        order_tot := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetCustOrderInfoProcessResponse/OrderResultSet[' || cnter || ']/ShipToRef';
        shipto_ref := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetCustOrderInfoProcessResponse/OrderResultSet[' || cnter || ']/SalesRepId';
        salesrep_id := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetCustOrderInfoProcessResponse/OrderResultSet[' || cnter || ']/OrderedDate';
        order_dt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        order_dt := SUBSTR(order_dt,0,10) || ' ' || SUBSTR(order_dt,12,8);
        IF order_num IS NULL THEN
          EXIT;
        END IF;
         orderobj := XX_ORDER_DET_OBJ(order_num,order_tot,shipto_ref,salesrep_id,order_dt);
         orderinfo.extend;
         orderinfo(cnter) := orderobj;
         cnter := cnter + 1;
       END LOOP;
       
       -- back order
       
       cnter := 1;
       b_OrderId := 'X';
       bckorderinfo := XX_BACK_ORDER_OBJ_TBL();

      l_namespace := 'xmlns="http://xmlns.oracle.com/pcbpel/adapter/db/GetBackOrderInfo"';

       WHILE 1 = 1 LOOP
        l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/OrderId';
        b_OrderId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/TotalOrderAmt';
        b_TotalOrderAmt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/BackOrderQty';
        b_BackOrderQty := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/ItemId';
        b_ItemId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/UnitListPriceAmt';
        b_UnitListPriceAmt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

         l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/UnitOriginalPriceAmt';
        b_UnitOriginalPriceAmt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/UnitPoCostAmt';
        b_UnitPoCostAmt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'GetBackOrderInfoOutput[' || cnter || ']/UnitSellingPriceAmt';
        b_UnitSellingPriceAmt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
        
        IF b_OrderId IS NULL THEN
          EXIT;
        END IF;
         bckorderobj := XX_BACK_ORDER_OBJ(b_OrderId,b_TotalOrderAmt,b_BackOrderQty,b_ItemId,b_UnitListPriceAmt,b_UnitOriginalPriceAmt,b_UnitPoCostAmt,b_UnitSellingPriceAmt);
         bckorderinfo.extend;
         bckorderinfo(cnter) := bckorderobj;
         cnter := cnter + 1;
       END LOOP;

       ---- Case Mgmt Details

     l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/GetCustOpenCases/d20100505_t17.38.04_r00101347_p38724.51';
     l_namespace    := 'xmlns="http://xmlns.oracle.com/GetCustOpenCases"';
     l_method       := 'GetCustOpenCasesProcessRequest';
     l_soap_action  := 'process';


       l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'AOPS_CustID',
                         p_type    => 'xsd:string',
                         p_value   => acctid);

       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'LoyaltyID',
                         p_type    => 'xsd:string',
                         p_value   => lid);

       l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);
       cnter := 1;
       IncidentNumber := 'X';
       caseinfo := XX_CASE_DET_OBJ_TBL();

       WHILE 1 = 1 LOOP
        l_result_name := 'OpenCasesResultSet[' || cnter || ']/PartyName';
        PartyName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/IncidentNumber';
        IncidentNumber := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/Description';
        Description := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/IncidentDate';
        IncidentDate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        IncidentDate := SUBSTR(IncidentDate,0,10) || ' ' || SUBSTR(IncidentDate,12,8);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/CloseDate';
        CloseDate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        CloseDate := SUBSTR(CloseDate,0,10) || ' ' || SUBSTR(CloseDate,12,8);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/ResolvedDate';
        ResolvedDate := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        ResolvedDate := SUBSTR(ResolvedDate,0,10) || ' ' || SUBSTR(ResolvedDate,12,8);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/Status';
        Status := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/CSR';
        CSR := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/Summary';
        Sumary := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'OpenCasesResultSet[' || cnter || ']/Creator';
        Creator := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'OpenCasesResultSet[' || cnter || ']/DataSource';
        cases_datasource := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'OpenCasesResultSet[' || cnter || ']/FetchTime';
        cases_fetchtime := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        IF IncidentNumber IS NULL THEN
          EXIT;
        END IF;
         caseobj := XX_CASE_DET_OBJ(PartyName,IncidentNumber,Description,IncidentDate,CloseDate,ResolvedDate,Status,CSR,Sumary,Creator,cases_datasource,cases_fetchtime);
         caseinfo.extend;
         caseinfo(cnter) := caseobj;
         cnter := cnter + 1;
       END LOOP;

    -- Contract Pricing Details


     l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/GetCustContractInfo/d20100505_t18.19.07_r00101357_p38724.50';
     l_namespace    := 'xmlns="http://xmlns.oracle.com/GetCustContractInfo"';
     l_method       := 'GetCustContractInfoProcessRequest';
     l_soap_action  := 'process';


       l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'AOPS_CustID',
                         p_type    => 'xsd:string',
                         p_value   => acctid);


       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'LoyaltyID',
                         p_type    => 'xsd:string',
                         p_value   => lid);

       l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);
       cnter := 1;
       ProductCode := 'X';
       priceinfo := XX_PRICE_DET_OBJ_TBL();

       WHILE 1 = 1 LOOP
        l_result_name := 'ContractPriceResultSet[' || cnter || ']/ProductCode';
        ProductCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ContractPriceResultSet[' || cnter || ']/ProductName';
        ProductName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ContractPriceResultSet[' || cnter || ']/SkuPrice';
        SkuPrice := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ContractPriceResultSet[' || cnter || ']/ContractId';
        ContractId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ContractPriceResultSet[' || cnter || ']/AddressSeq';
        AddressSeq := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ContractPriceResultSet[' || cnter || ']/DataSource';
        contract_DataSource := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ContractPriceResultSet[' || cnter || ']/fetchTime';
        contract_fetchTime := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);


        IF ProductCode IS NULL THEN
          EXIT;
        END IF;
         priceobj := XX_PRICE_DET_OBJ(ProductCode,ProductName,SkuPrice,ContractId,AddressSeq,contract_DataSource,contract_fetchTime);
         priceinfo.extend;
         priceinfo(cnter) := priceobj;
         cnter := cnter + 1;
       END LOOP;
       
       /* cnter := 1;
       ContractId := 'X';
       contractinfo := XX_ACTIVE_CONTRACT_OBJ_TBL();

       WHILE 1 = 1 LOOP
        l_result_name := 'ActiveContractsOutput[' || cnter || ']/LinkSeq';
        LinkSeq := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ActiveContractsOutput[' || cnter || ']/ContractId';
        ContractId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ActiveContractsOutput[' || cnter || ']/ContractSeq';
        ContractSeq := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ActiveContractsOutput[' || cnter || ']/StatusCode';
        StatusCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

        l_result_name := 'ActiveContractsOutput[' || cnter || ']/PriorityCode';
        PriorityCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ActiveContractsOutput[' || cnter || ']/PriceCode';
        PriceCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ActiveContractsOutput[' || cnter || ']/AddressSeq';
        OffPricePriceCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ActiveContractsOutput[' || cnter || ']/WholesalePriceCode';
        WholesalePriceCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
        l_result_name := 'ActiveContractsOutput[' || cnter || ']/WholesalePricePriceCode';
        WholesalePricePriceCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);


        IF ContractId IS NULL THEN
          EXIT;
        END IF;
         contractobj := XX_ACTIVE_CONTRACT_OBJ(ProductCode,ProductName,SkuPrice,ContractId,AddressSeq);
         contractinfo.extend;
         contractinfo(cnter) := contractobj;
         cnter := cnter + 1;
       END LOOP; */
       
       
       --- Email Campaign Details
       
     l_url          := 'http://esbsit01.na.odcorp.net/orabpel/sfsync/ReqCustEmailCampaignInfo/d20100223_t18.05.40_r00094441_p38724.37';
     l_namespace    := 'xmlns="http://xmlns.oracle.com/ReqCustEmailCampaignInfo"';
     l_method       := 'ReqCustEmailCampaignInfoProcessRequest';
     l_soap_action  := 'process';


       l_request := soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);


       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'acctId',
                         p_type    => 'xsd:string',
                         p_value   => acctid);
                         
       soap_api.add_parameter(p_request => l_request,
                         p_name    => 'partyId',
                         p_type    => 'xsd:string',
                         p_value   => null);



       l_response := soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);
       cnter := 1;
       OrgPartyNum := 'X';
       campinfo := XX_EMAIL_CAMP_OBJ_TBL();

       WHILE 1 = 1 LOOP
        l_result_name := 'CampaignResultSet[' || cnter || ']/ORGANIZATION_PARTY_NUMBER';
        OrgPartyNum := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/CUSTOMER_TYPE_CODE';
        CustTypeCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/ORGANIZATION_NAME';
        OrgName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);

          l_result_name := 'CampaignResultSet[' || cnter || ']/PERSON_PARTY_NUMBER';
        PersonPartyNum := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/FIRST_NAME';
        FirstName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/LAST_NAME';
        LastName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
           l_result_name := 'CampaignResultSet[' || cnter || ']/EMAIL_ADDRESS';
        EmailAdd := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
           l_result_name := 'CampaignResultSet[' || cnter || ']/EMAIL_CAMPAIGN_DATE';
        EmailCampDt := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/EMAIL_CAMPAIGN_SEGMENT_CODE';
        EmailCampSegCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/EMAIL_CAMPAIGN_ZONE_CODE';
        EmailCampZoneCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/G_TELEPHONE_COUNTRY_CD';
        TelCountryCd := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/G_TELEPHONE_AREA_CD';
        TelAreaCd := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/G_TELEPHONE_NBR';
        TelNum := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
         l_result_name := 'CampaignResultSet[' || cnter || ']/MESSAGE';
        CampMsg := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
        

        IF OrgPartyNum IS NULL THEN
          EXIT;
        END IF;
         campobj := XX_EMAIL_CAMP_OBJ(OrgPartyNum,CustTypeCode,OrgName,PersonPartyNum,FirstName,LastName,EmailAdd,EmailCampDt,EmailCampSegCode,EmailCampZoneCode,TelCountryCd,TelAreaCd,TelNum,CampMsg);
         campinfo.extend;
         campinfo(cnter) := campobj;
         cnter := cnter + 1;
       END LOOP;
       
ELSE
   
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
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/FindCustService"';
  
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
  
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/CustomerId';
  cdh_CustomerId := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/BusinessName';
  cdh_BusinessName := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/StreetAddress1';
  cdh_StreetAddress1 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/StreetAddress2';
  cdh_StreetAddress2 := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/City';
  cdh_City := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/State';
  cdh_State := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/Province';
  cdh_Province := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/ZipCode';
  cdh_ZipCode := soap_api.get_return_value(p_response  => l_response,
                                        p_name      => l_result_name,
                                        p_namespace => l_namespace);
                                        
  l_result_name := 'GetCDH_CustByNameOutput[' || cnter || ']/Country';
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
  
  l_namespace   := 'xmlns="http://xmlns.oracle.com/FindCustService"';
  
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
   
END IF;
       
END cust360;
/