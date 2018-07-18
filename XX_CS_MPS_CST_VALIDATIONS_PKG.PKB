create or replace
PACKAGE BODY XX_CS_MPS_CST_VALIDATIONS_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_CST_VALIDATIONS_PKG.pkb                                                   |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        21-MAY-2013   Sreedhar Mohan        Validations for MPS Customers                  |
-- /2.0        09-DEC-2013   Arun Gannarapu        Added fnd_log message                          ?
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
      
      fnd_file.put_line(fnd_file.log , p_debug_msg);
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

--check po_number and cost_center are valid for the customer
PROCEDURE  is_cost_ctr_po_nbr_valid(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_aops_customer_id      IN          NUMBER
            , p_cost_center           IN          VARCHAR2
            , p_po_number             IN          VARCHAR2
          ) 
IS
   l_is_valid_cost_center      VARCHAR2(1);
   l_is_valid_po               VARCHAR2(1);
     
BEGIN
          is_cost_ctr_po_nbr_valid(
              p_errbuf                => p_errbuf              
            , p_retcode               => p_retcode             
            , p_aops_customer_id      => p_aops_customer_id    
            , p_cost_center           => p_cost_center         
            , p_po_number             => p_po_number           
            , p_is_valid_cost_center  => l_is_valid_cost_center
            , p_is_valid_po           => l_is_valid_po         
          );

END is_cost_ctr_po_nbr_valid;

--check po_number and cost_center are valid for the customer
PROCEDURE  is_cost_ctr_po_nbr_valid(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_aops_customer_id      IN          NUMBER
            , p_cost_center           IN          VARCHAR2
            , p_po_number             IN          VARCHAR2
            , p_is_valid_cost_center  OUT         VARCHAR2
            , p_is_valid_po           OUT         VARCHAR2
          )  
IS

  l_po_number         XX_CS_MPS_DEVICE_B.PO_NUMBER%TYPE;
  l_cost_center       XX_CS_MPS_DEVICE_B.DEVICE_COST_CENTER%TYPE;
  l_aops_cust_number  NUMBER;
  lc_is_po_valid      VARCHAR2(1) := 'N';
  lc_is_cc_valid      VARCHAR2(1) := 'N';
  l_cc_po_url         VARCHAR2(240) := fnd_profile.value('XX_CS_MPS_COSTCTR_PO_URL');

  l_request      xx_cs_mps_soap_api.t_request;
  l_response     xx_cs_mps_soap_api.t_response;
  l_return       VARCHAR2(32767);
  l_req_namespace    VARCHAR2(32767) := fnd_profile.value('XX_CS_MPS_CC_PO_REQ_NAMESPACE');--'xmlns:ns1="http://www.officedepot.com/MPS/GetOrderRL/Schema/Request"';
  l_resp_namespace    VARCHAR2(32767) := fnd_profile.value('XX_CS_MPS_CC_PO_RESP_NAMESPACE');--'xmlns="http://www.officedepot.com/MPS/GetOrderRL/Schema/Response"';
  l_method       VARCHAR2(32767) := fnd_profile.value('XX_CS_MPS_COSTCTR_PO_METHOD');--'ns1:getOrderRLRequest';
  l_soap_action  VARCHAR2(32767) := fnd_profile.value('XX_CS_MPS_CC_PO_SOAP_ACTION');--'process';
  l_result_name  VARCHAR2(32767);

BEGIN
  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid','Start');      

  l_request := xx_cs_mps_soap_api.new_request(p_method       => l_method,
                                              p_namespace    => l_req_namespace);                                    

  xx_cs_mps_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'custId',
                         p_type    => 'ns1',
                         p_value   => p_aops_customer_id);

  xx_cs_mps_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'poId',
                         p_type    => 'ns1',
                         p_value   => p_po_number);

  xx_cs_mps_soap_api.add_parameter(p_request => l_request,
                         p_name    => 'ccKey',
                         p_type    => 'ns1',
                         p_value   => p_cost_center);

  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'Before call to Web Service');
  l_response := xx_cs_mps_soap_api.invoke(p_request => l_request,
                                          p_url     => l_cc_po_url,
                                          p_action  => l_soap_action);
  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'After call to Web Service');
  l_result_name := 'poVal';

  lc_is_po_valid := xx_cs_mps_soap_api.get_return_value(p_response  => l_response,
                                                        p_name      => l_result_name,
                                                        p_namespace => l_resp_namespace);
  p_is_valid_po := lc_is_po_valid;

  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'l_response: ' || l_response.doc.getStringVal());
  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'lc_is_po_valid: ' || lc_is_po_valid);

  l_result_name := 'ccVal';

  lc_is_cc_valid := xx_cs_mps_soap_api.get_return_value(p_response  => l_response,
                                                        p_name      => l_result_name,
                                                        p_namespace => l_resp_namespace);
  p_is_valid_cost_center := lc_is_cc_valid;
  log_debug_msg('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'lc_is_cc_valid: ' || lc_is_cc_valid);
  
EXCEPTION 
    WHEN OTHERS THEN
        LOG_ERROR('XX_CS_MPS_CST_VALIDATIONS_PKG.is_cost_ctr_po_nbr_valid', 'Exception: ' || SQLERRM);
        p_retcode :=2;
        p_errbuf := SQLERRM;
END is_cost_ctr_po_nbr_valid;

--Update Cost Center and PO Number to MPS Devices 
PROCEDURE UPDATE_CC_PO_NUMBER(  p_errbuf                OUT NOCOPY VARCHAR2
                              , p_retcode               OUT NOCOPY VARCHAR2
                              , p_aops_cust_id          IN         NUMBER  
                              , p_device_cost_center    IN          VARCHAR2
                              , p_po_number             IN          VARCHAR2
                             )
IS
BEGIN   
  update XX_CS_MPS_DEVICE_B
  set    device_cost_center        = p_device_cost_center
       , po_number                 = p_po_number
  where  aops_cust_number          = p_aops_cust_id;

  COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      --log_exception
      LOG_ERROR('XX_CS_MPS_CST_VALIDATIONS_PKG.UPDATE_CC_PO_NUMBER', 'Exception: ' || SQLERRM);
      p_retcode := 2;
END UPDATE_CC_PO_NUMBER;
END XX_CS_MPS_CST_VALIDATIONS_PKG;
/
show errors;