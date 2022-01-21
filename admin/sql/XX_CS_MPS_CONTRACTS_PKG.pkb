SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CS_MPS_CONTRACTS_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_CONTRACTS_PKG.pkb                                                          |
-- | Description  : This package contains procedures related to MPS Contracts                     |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        07-AUG-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

  /*****************************************************************************/
   -- Log Messages
  /****************************************************************************/
  PROCEDURE log_exception( p_object_id          IN  VARCHAR2
                         , p_error_location     IN  VARCHAR2
                         , p_error_message_code IN  VARCHAR2
                         , p_error_msg          IN  VARCHAR2
                         ) IS
    -- local variable declaration
    ln_login     PLS_INTEGER    := fnd_global.login_id;
    ln_user_id   PLS_INTEGER    := fnd_global.user_id;
  BEGIN
    xx_com_error_log_pub.log_error( p_return_code             => FND_API.G_RET_STS_ERROR
                                  , p_msg_count               => 1
                                  , p_application_name        => 'XX_CRM'
                                  , p_program_type            => 'Custom Messages'
                                  , p_program_name            => 'XX_CS_TDS_VEN_PKG'
                                  , p_program_id              => p_object_id
                                  , p_module_name             => 'CS'
                                  , p_error_location          => p_error_location
                                  , p_error_message_code      => p_error_message_code
                                  , p_error_message           => p_error_msg
                                  , p_error_message_severity  => 'MAJOR'
                                  , p_error_status            => 'ACTIVE'
                                  , p_created_by              => ln_user_id
                                  , p_last_updated_by         => ln_user_id
                                  , p_last_update_login       => ln_login
                                  );
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line(' When Others Raised at log_exception : '||SQLERRM);
	  FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised at log_exception : '||SQLERRM);
  END log_exception;
  
  /**************************************************************************/

  /*------------------------------------------------------------------------*/
    --Procedure Name : Make_Param_Str
    --Description    : concatenates parameters for XML message
  /*------------------------------------------------------------------------*/
  FUNCTION make_param_str( p_param_name  IN VARCHAR2
                         , p_param_value IN VARCHAR2
                         ) RETURN VARCHAR2 IS
  BEGIN
    RETURN '<ns1:'||p_param_name||
           '>'||'<![CDATA['||p_param_value||']]>'||'</ns1:'||p_param_name||'>';

  END make_param_str;
  ---------------------------------------------------------------------------
  
  PROCEDURE SFDC_PROC( p_party_id      IN NUMBER
                     , p_sales_rep     IN VARCHAR2
                     , p_contract_type IN VARCHAR2
                     , x_return_status IN OUT NOCOPY VARCHAR2
                     , x_return_msg    IN OUT NOCOPY VARCHAR2
                     ) AS
  -- +=====================================================================+
  -- | Name  : sfdc_proc                                                   |
  -- | Description      : This Procedure will identify customer create     |
  -- |                    request and call web service call if customr not |
  -- |                    found then update request status to pending      |
  -- |                                                                     |
  -- | Parameters:        p_party_id      IN NUMBER party ID               |
  -- |                    p_sales_rep     IN VARCHAR2 Sales Rep Name       |
  -- |                    p_contract_type IN VARCHAR2 Contact Type         |
  -- |                    x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- +=====================================================================+
  -- local variable declaration
  ln_user_id             fnd_user.user_id%TYPE;
  ln_customer            hz_cust_accounts_all.cust_account_id%TYPE;
  lc_return_status       VARCHAR2(1);
  lc_return_mesg         VARCHAR2(2000);
  exc_failed             EXCEPTION;
  lc_msg_data            VARCHAR2(2000);
  lc_summary             VARCHAR2(150);
  lc_comments           VARCHAR2(1000);
  l_initstr              VARCHAR2(2000);
  lc_aops_id             hz_cust_accounts.orig_system_reference%TYPE;
  l_url                  VARCHAR2(240) := fnd_profile.value('XX_APRIMO_WEB_URL');
  --http://soafmwdev01app02.na.odcorp.net:7052/GetMPSContractAprimoProviderABCS/Services/GetMpsContractEbs
  lr_sr_rec             XX_CS_SR_REC_TYPE;
  lc_request_type       VARCHAR2(150);
  ln_party_id           NUMBER;
  
  
  BEGIN
     L_URL := 'http://soafmwdev01app02.na.odcorp.net:7052/GetMPSContractAprimoProviderABCS/Services/GetMpsContractEbs';

	 SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

    BEGIN
      SELECT party_id
        INTO ln_party_id 
        FROM hz_parties
       WHERE party_id = p_party_id;
    EXCEPTION
      WHEN OTHERS THEN
        x_return_status := 'E';
        x_return_msg    := 'No party Id in EBS ';
		Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => x_return_msg
                     );
    END;
    
    DBMS_OUTPUT.PUT_LINE('PARTY ID '||LN_PARTY_ID||' '||X_RETURN_STATUS);
    
    IF nvl(x_return_status,'S') = 'S' THEN
    
      BEGIN
        lr_sr_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);
                                
        lc_request_type := 'MPS-Contract';
        lc_comments     := 'Contract creation for '||p_party_id;
        lc_summary      := 'Contract creation for '||p_party_id;
      
        BEGIN
          SELECT incident_type_id , name
            INTO lr_sr_rec.type_id, lr_sr_rec.type_name
            FROM cs_incident_types_tl
           WHERE name = lc_request_type;
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
			Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                         , p_error_msg          => 'LC_REQUEST_TYPE NOT DEFINED'
                         );
           -- LOG INTO COMMON LOG TABLE
        END;
        
		BEGIN
          SELECT cust_account_id,SUBSTR(orig_system_reference,1,8)
            INTO ln_customer,lc_aops_id
            FROM hz_cust_accounts
           WHERE party_id = p_party_id;
        EXCEPTION
		  WHEN OTHERS THEN
		    NULL;
			Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                         , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                         , p_error_msg          => 'CUST ACCOUNT NOT CREATED FOR PARTY ID : '|| p_party_id
                         );
			
        END;
		
        -- Assign values to rec type
        lr_sr_rec.status_name       := 'Open';
        lr_sr_rec.description       := lc_summary;
        lr_sr_rec.caller_type       := 'MPS-Contract';
        lr_sr_rec.customer_id       := ln_party_id;  
        lr_sr_rec.user_id           := ln_user_id;  
        lr_sr_rec.channel           := 'WEB'; -- setup
        lr_sr_rec.comments          := lc_comments;
        lr_sr_rec.sales_rep_contact := p_sales_rep; 
        lr_sr_rec.customer_number   := lc_aops_id;
        
        -- Create Request.
    
   /*   XX_CS_MPS_FLEET_PKG.CREATE_SR (P_PARTY_ID => p_party_id,
                       P_SALES_NUMBER   => p_sales_rep,
                       P_REQUEST_TYPE   => LC_REQUEST_TYPE,
                       P_COMMENTS       => LC_COMMENTS,
                       p_sr_req_rec     => lr_sr_rec,
                       x_return_status  => x_return_status,
                       X_RETURN_MSG     => x_return_msg);   */
              
               dbms_output.put_line('sr  '||x_return_status||' '||x_return_msg);         
    -- on success call

        IF ln_customer IS NOT NULL THEN
          -- APRIMO WEB SERVICE CALL
        --  l_initstr := l_initstr||'<HTML>';
          l_initstr := l_initstr||'<ns1:ODAprimoService>';
          l_initstr := l_initstr||make_param_str('CUSTOMER',lc_aops_id);
          l_initstr := l_initstr||'</ns1:ODAprimoService>';
        --   l_initstr := l_initstr||'</HTML>';
           
           
          --DBMS_OUTPUT.PUT_LINE('XML STR '||L_INITSTR);

          BEGIN
            lc_msg_data := xx_cs_mps_utilities_pkg.http_post(l_url,l_initstr) ;

          EXCEPTION
            WHEN OTHERS THEN
              lc_msg_data := 'Error while calling APRIMO API  '||SQLERRM;
              dbms_output.put_line('error at aprimo service '||lc_msg_data);
              Log_Exception( p_object_id          => p_party_id
                           , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                           , p_error_message_code => 'XX_CS_MPS01_ERR_LOG'
                           , p_error_msg          => lc_msg_data
                           );
          END;

          ln_customer     := ln_customer;
          x_return_status := fnd_api.g_ret_sts_success;
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          lc_msg_data  := 'When Others Raised While Deriving Customer : '||SQLERRM;
          Log_Exception( p_object_id          => p_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_MPS01_ERR_LOG'
                       , p_error_msg          => lc_msg_data
                       );
      END;

        IF x_return_status = fnd_api.g_ret_sts_success THEN
            x_return_msg := 'Success';
        END IF;
    
    END IF;

  EXCEPTION
      WHEN exc_failed THEN
        lc_msg_data     := ('Failed in creation of contract for party id : ' || p_party_id);
        x_return_status := fnd_api.g_ret_sts_error;
        x_return_msg    := lc_msg_data;
        dbms_output.put_line(lc_msg_data);
        Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => lc_msg_data
                     );

      WHEN NO_DATA_FOUND THEN
        lc_msg_data      := 'NO DATA FOUND ERROR RAISED';
        x_return_status := fnd_api.g_ret_sts_error;
        x_return_msg    := lc_msg_data;
        dbms_output.put_line(lc_msg_data);
        Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => lc_msg_data
                     );

      WHEN OTHERS THEN
        lc_msg_data     := 'WHEN OTHERS RAISED : '||SQLERRM;
        x_return_status := fnd_api.g_ret_sts_error;
        x_return_msg    := lc_msg_data;
        dbms_output.put_line(lc_msg_data);
        Log_Exception( p_object_id          => p_party_id
                     , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                     , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                     , p_error_msg          => lc_msg_data
                     );

  END SFDC_PROC;
  /*****************************************************************************/

  PROCEDURE CONTRACT_PROC ( p_customer       IN OUT NUMBER
                          , p_cont_rec       IN OUT XX_CS_MPS_CONTRACT_REC_TYPE
                          , x_return_status  IN OUT VARCHAR2
                          , x_return_msg     IN OUT NOCOPY VARCHAR2
                          ) AS
  -- +=====================================================================+
  -- | Name  : contract_proc                                               |
  -- | Description      : This Procedure will created a contract lines for |
  -- |                    MPS. This procedure will be invoke by SOA web    |
  -- |                    Service with APRIMO contract details response    |
  -- |                                                                     |
  -- | Parameters:       p_customer      IN OUT NUMBER customer            |
  -- |                   p_cont_rec      IN OUT XX_CS_MPS_CONTRACT_REC_TYPE|
  -- |                   x_return_status IN OUT VARCHAR2 Return status     |
  -- |                   x_return_msg    IN OUT VARCHAR2 Return Message    |
  -- +=====================================================================+


   ln_contract_id         NUMBER;
   lc_title               VARCHAR2(150);
   ln_header_id           NUMBER;
   lc_return_status       VARCHAR2(1);
   lc_return_message      VARCHAR2(2000);
   ln_service_lin_id      NUMBER;
   ln_party_id            NUMBER;
   lc_sales_rep           VARCHAR2(50);
   ln_contract_hdr_id     okc_k_headers_b.id%TYPE;
   lr_cont_rec            xx_cs_mps_contract_rec_type;
   ln_incident_id         NUMBER;
  
    BEGIN
      lr_cont_rec := xx_cs_mps_contract_rec_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      
	  BEGIN
        SELECT party_id 
          INTO ln_party_id
          FROM hz_cust_accounts
         WHERE orig_system_reference = p_customer||'-00001-A0';
      
	  EXCEPTION
	    WHEN OTHERS THEN
		  NULL;
		  Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                       , p_error_msg          => 'PARTY ID NOT FOUND FOR OSR : '|| p_customer||'-00001-A0'
                       );
      END;
	  
      BEGIN	  
        SELECT cb.incident_id
          INTO ln_incident_id
          FROM cs_incidents_all_b cb,
               cs_incident_types_tl ct
         WHERE ct.incident_type_id = cb.incident_type_id
           AND ct.name             = 'MPS-Contract'
           AND cb.customer_id      = ln_party_id; --21323399 -- Party Id
      EXCEPTION
	    WHEN OTHERS THEN
		  NULL;
		  Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                       , p_error_msg          => 'INCIDENT ID NOT FOUND FOR PARTY ID : '||  ln_party_id
                       ); 
      END;	  

      --   SELECT party_id 
      --    INTO ln_party_id
      --    FROM hz_cust_accounts
      --   WHERE orig_system_reference = p_customer||'-00001-A0';
         
      
         
    --lr_cont_rec := p_cont_rec;

      -- Call Contract create API
      xx_cs_contracts_pkg.create_contract ( p_party_id       => ln_party_id
                                          , p_sales_rep_id   => lc_sales_rep
                                          , p_contract_type  => 'MPS-Contract'  
                                          , p_contract_rec   => lr_cont_rec
                                          , x_contract_num   => ln_contract_hdr_id
                                          , x_return_status  => lc_return_status
                                          , x_return_mesg    => lc_return_message
                                          );

      IF ln_contract_hdr_id IS NULL THEN
        x_return_status := lc_return_status;
        x_return_msg    := lc_return_message;
        -- log table
      ELSE
        x_return_status := lc_return_status;
        x_return_msg    := 'Sucess';
      END IF;
    
    
        -- CALL CONTRACT line API
      XX_CS_CONTRACTS_PKG.create_contract_lin( p_header_id        => ln_header_id
                                             , x_return_status    => lc_return_status
                                             , x_return_mesg      => lc_return_message
                                             , x_service_line_id  => ln_service_lin_id
                                             );

        ln_contract_id := p_cont_rec.contract_id;
        lc_title       := p_cont_rec.title;
        dbms_output.put_line('ln_service_lin_id  :::'||ln_service_lin_id);
        x_return_status := 'S';
        x_return_msg    := 'Success';

    END CONTRACT_PROC;
   /*****************************************************************************/

  --PROCEDURE for pending status request
END XX_CS_MPS_CONTRACTS_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CS_MPS_CONTRACTS_PKG;
--EXIT;