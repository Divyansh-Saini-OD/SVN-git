SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CRM_NET_PRICER_PKG AS

PROCEDURE get_net_sku_price
(
 PICST         IN      NUMBER
,PIADRSEQ      IN      NUMBER
,PIADRKEY      IN      VARCHAR2
,PILOC         IN      VARCHAR2 
,PISK          IN      VARCHAR2
,PIQTY         IN      NUMBER 
,POPCUS        IN OUT  NUMBER 
,POPSAD        IN OUT  NUMBER 
,POPRDC        IN OUT  VARCHAR2 
,POCPRD        IN OUT  VARCHAR2
,POSELLPCK     IN OUT  NUMBER
,POORDU        IN OUT  VARCHAR2
,POIDES        IN OUT  VARCHAR2
,POQTYAVAIL    IN OUT  NUMBER
,POPALS        IN OUT  NUMBER
,POACP         IN OUT  NUMBER
,POLOCAT       IN OUT  VARCHAR2
,POCDVN        IN OUT  VARCHAR2
,POVPRD        IN OUT  VARCHAR2
,POVNDID       IN OUT  VARCHAR2
,POMETASKU     IN OUT  VARCHAR2  
,POIMPRTSKU    IN OUT  VARCHAR2
,POSTDASSORT   IN OUT  VARCHAR2
,POTDCCOST     IN OUT  NUMBER
,PORETURNSKU   IN OUT  VARCHAR2
,PODEPT        IN OUT  VARCHAR2
,POWEIGHT      IN OUT  VARCHAR2
,POADDDLVCHG   IN OUT  NUMBER
,POASSORTFLG   IN OUT  VARCHAR2
,POBUNDLEFLG   IN OUT  VARCHAR2
,POPREMIUMFLG  IN OUT  VARCHAR2
,POCLAS        IN OUT  VARCHAR2 
,POSCLAS       IN OUT  VARCHAR2
,PODROPSHIP    IN OUT  VARCHAR2
,POGSASKU      IN OUT  VARCHAR2
,POFURNITURE   IN OUT  VARCHAR2
,POOVERSIZE    IN OUT  VARCHAR2
,POSELLBRAND   IN OUT  VARCHAR2
,POBULKPRICE   IN OUT  VARCHAR2
,POCOSTUP      IN OUT  VARCHAR2
,POOFFCAT      IN OUT  VARCHAR2
,POOFFLIST     IN OUT  VARCHAR2
,POOFFRETAIL   IN OUT  VARCHAR2
,PORETCONT     IN OUT  VARCHAR2
,POPROPRIETARY IN OUT  VARCHAR2  
,POHAZARD      IN OUT  VARCHAR2
,POPRCTYP      IN OUT  VARCHAR2
,POPPRMD       IN OUT  VARCHAR2
,POCONTPLANID  IN OUT  NUMBER
,POCONTPLANSEQ IN OUT  NUMBER
,POMETHODPCT   IN OUT  NUMBER
,PODELONLY     IN OUT  VARCHAR2
,POCOSTTOUSE   IN OUT  VARCHAR2  
,POERROR       IN OUT  VARCHAR2 
)
AS
  l_request      xx_crm_soap_api.t_request;
  l_response     xx_crm_soap_api.t_response;
  l_return       VARCHAR2(32767);
  l_url          VARCHAR2(32767);
  l_namespace    VARCHAR2(32767);
  l_method       VARCHAR2(32767);
  l_soap_action  VARCHAR2(32767);
  l_result_name  VARCHAR2(32767);
  l_jndi_name    VARCHAR2(400);
  FIN_EXCEPTION  EXCEPTION;
BEGIN

  BEGIN
    SELECT source_value2 INTO l_url
    FROM XX_FIN_TRANSLATEDEFINITION xdef, XX_FIN_TRANSLATEVALUES xval
    WHERE xdef.translate_id = xval.translate_id
    AND xdef.translation_name = 'XX_CRM_NET_PRICER_SETUP'
    AND xval.source_value1 = 'URL';
    
    SELECT source_value2 INTO l_namespace
    FROM XX_FIN_TRANSLATEDEFINITION xdef, XX_FIN_TRANSLATEVALUES xval
    WHERE xdef.translate_id = xval.translate_id
    AND xdef.translation_name = 'XX_CRM_NET_PRICER_SETUP'
    AND xval.source_value1 = 'NAMESPACE';
    
    SELECT source_value2 INTO l_method
    FROM XX_FIN_TRANSLATEDEFINITION xdef, XX_FIN_TRANSLATEVALUES xval
    WHERE xdef.translate_id = xval.translate_id
    AND xdef.translation_name = 'XX_CRM_NET_PRICER_SETUP'
    AND xval.source_value1 = 'METHOD';
    
    SELECT source_value2 INTO l_soap_action
    FROM XX_FIN_TRANSLATEDEFINITION xdef, XX_FIN_TRANSLATEVALUES xval
    WHERE xdef.translate_id = xval.translate_id
    AND xdef.translation_name = 'XX_CRM_NET_PRICER_SETUP'
    AND xval.source_value1 = 'SOAP_ACTION';
    
    SELECT source_value2 INTO l_jndi_name
    FROM XX_FIN_TRANSLATEDEFINITION xdef, XX_FIN_TRANSLATEVALUES xval
    WHERE xdef.translate_id = xval.translate_id
    AND xdef.translation_name = 'XX_CRM_NET_PRICER_SETUP'
    AND xval.source_value1 = 'JNDI_NAME';
    
  EXCEPTION WHEN NO_DATA_FOUND THEN
    POERROR := 'Error During FIN Translation Setup - Please check values for XX_CRM_NET_PRICER_SETUP';
    RAISE FIN_EXCEPTION; 
  END;


  l_request := xx_crm_soap_api.new_request(p_method       => l_method,
                                    p_namespace    => l_namespace);
                                    
  xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'jndi_db2',
                         p_type    => 'xsd:string',
                         p_value   => l_jndi_name);

  xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'picst',
                         p_type    => 'xsd:decimal',
                         p_value   => PICST);

  xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'piadrseq',
                         p_type    => 'xsd:decimal',
                         p_value   => PIADRSEQ);

  xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'piadrkey',
                         p_type    => 'xsd:string',
                         p_value   => PIADRKEY);

  xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'piloc',
                         p_type    => 'xsd:string',
                         p_value   => PILOC);
                                                  
    xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'pisk',
                         p_type    => 'xsd:string',
                         p_value   => PISK);
                         
    xx_crm_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'piqty',
                         p_type    => 'xsd:decimal',
                         p_value   => PIQTY);

  l_response := xx_crm_soap_api.invoke(p_request => l_request,
                                p_url     => l_url,
                                p_action  => l_soap_action);


  l_result_name := 'popcus';


  POPCUS := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'popsad';


  POPSAD := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poprdc';


  POPRDC := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pocprd';


  POCPRD := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'posellpck';


  POSELLPCK := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poordu';


  POORDU := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poides';


  POIDES := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poqtyavail';


  POQTYAVAIL := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'popals';


  POPALS := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poacp';


  POACP := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'polocat';


  POLOCAT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pocdvn';


  POCDVN := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'povprd';


  POVPRD := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'povndid';


  POVNDID := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pometasku';


  POMETASKU := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poimprtsku';


  POIMPRTSKU := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'postdassort';


  POSTDASSORT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'potdccost';


  POTDCCOST := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poreturnsku';


  PORETURNSKU := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'podept';


  PODEPT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poweight';


  POWEIGHT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poadddlvchg';


  POADDDLVCHG := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poassortflg';


  POASSORTFLG := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pobundleflg';


  POBUNDLEFLG := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'popremiumflg';


  POPREMIUMFLG := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poclas';


  POCLAS := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'posclas'; --Yusuf updated value to correct output from SOAP message

  POSCLAS := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'podropship';


  PODROPSHIP := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pogsasku';


  POGSASKU := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pofurniture';


  POFURNITURE := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pooversize';


  POOVERSIZE := TRIM(xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace));
                                             
  l_result_name := 'posellbrand';


  POSELLBRAND := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pobulkprice';


  POBULKPRICE := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pocostup';


  POCOSTUP := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pooffcat';


  POOFFCAT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poofflist';


  POOFFLIST := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pooffretail';


  POOFFRETAIL := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poretcont';


  PORETCONT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poproprietary';


  POPROPRIETARY := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pohazard';


  POHAZARD := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poprctyp';


  POPRCTYP := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'popprmd';


  POPPRMD := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  
                                             
  l_result_name := 'pocontplanid';


  POCONTPLANID := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pocontplanseq';


  POCONTPLANSEQ := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pomethodpct';


  POMETHODPCT := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'podelonly';


  PODELONLY := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'pocosttouse';


  POCOSTTOUSE := xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace);
                                             
  l_result_name := 'poerror';


  POERROR := TRIM(xx_crm_soap_api.get_return_value(p_response  => l_response,
                                             p_name      => l_result_name,
                                             p_namespace => l_namespace));
                                             

EXCEPTION 
WHEN FIN_EXCEPTION THEN
  NULL;
WHEN OTHERS THEN
POERROR := 'Unexpected Excetpion:' || SQLERRM;

END get_net_sku_price;

END XX_CRM_NET_PRICER_PKG;
/
SHOW ERRORS;
