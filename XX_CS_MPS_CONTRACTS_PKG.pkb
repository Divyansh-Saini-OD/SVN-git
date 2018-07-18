create or replace
PACKAGE BODY XX_CS_MPS_CONTRACTS_PKG AS
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
-- |2.0        03-NOV-2015   Havish Kasina      Removed the schema references in the existing code|
-- |                                            as per R12.2 Retrofit                             |
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
                                  , p_program_name            => 'XX_CS_MPS_CONTRACTS_PKS'
                                  , P_PROGRAM_ID              => P_OBJECT_ID
                                  , p_module_name             => 'MPS'
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
    --  dbms_output.put_line(' When Others Raised at log_exception : '||SQLERRM);
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
  l_url                  VARCHAR2(240) := fnd_profile.value('XX_CS_MPS_APRIMO_URL');
  --http://soafmwdev01app02.na.odcorp.net:7052/GetMPSContractAprimoProviderABCS/Services/GetMpsContractEBS
  lr_sr_rec             XX_CS_SR_REC_TYPE;
  lc_request_type       VARCHAR2(150);
  ln_party_id           NUMBER;
  lc_vendor             VARCHAR2(50) := 'APRIMO';
  ln_incident_id        number;


  BEGIN

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


    --DBMS_OUTPUT.PUT_LINE('PARTY ID '||LN_PARTY_ID||' '||X_RETURN_STATUS);

    IF nvl(x_return_status,'S') = 'S' THEN

      BEGIN
          SELECT cust_account_id,SUBSTR(orig_system_reference,1,8)
            INTO ln_customer,lc_aops_id
            FROM hz_cust_accounts
           WHERE party_id = p_party_id;
        EXCEPTION
		  WHEN OTHERS THEN
		   	Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                         , p_error_message_code => 'XX_CS_REQ02_ERR_LOG'
                         , p_error_msg          => 'CUST ACCOUNT NOT CREATED FOR PARTY ID : '|| p_party_id
                         );

        END;

        -- Get Incident Id
    BEGIN
        SELECT CB.INCIDENT_ID
        INTO LN_INCIDENT_ID
        FROM CS_INCIDENTS_ALL_B CB,
             CS_INCIDENT_TYPES_TL CT
        WHERE CT.INCIDENT_TYPE_ID = CB.INCIDENT_TYPE_ID
        AND   CB.CUSTOMER_ID = LN_PARTY_ID
        AND   CT.NAME = 'MPS Contract Request'
        AND   CB.INCIDENT_STATUS_ID = 1
        AND   ROWNUM < 2;
    EXCEPTION
       WHEN OTHERS THEN
          LN_INCIDENT_ID := NULL;
    END;


     IF ln_incident_id is null then
      BEGIN
        lr_sr_rec := XX_CS_SR_REC_TYPE(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                       NULL,NULL,NULL,NULL);

        lc_request_type := 'MPS Contract Request';
        lc_comments     := 'Contract creation for '||p_party_id;
        lc_summary      := 'Contract creation for '||p_party_id;

        BEGIN
          SELECT incident_type_id , name
            INTO lr_sr_rec.type_id, lr_sr_rec.type_name
            FROM cs_incident_types_tl
           WHERE name = lc_request_type;
        EXCEPTION
          WHEN OTHERS THEN
                x_return_status := 'F';
                x_return_msg := 'Req Type Not Defind';
                Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                         , p_error_message_code => 'XX_CS_REQ04_ERR_LOG'
                         , p_error_msg          => 'Req Type NOT DEFINED'
                         );
        END;

       IF nvl(x_return_status,'S') = 'S' then
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

         XX_CS_MPS_UTILITIES_PKG.CREATE_SR (P_PARTY_ID => p_party_id,
                       P_SALES_NUMBER   => p_sales_rep,
                       P_REQUEST_TYPE   => LC_REQUEST_TYPE,
                       P_COMMENTS       => LC_COMMENTS,
                       p_sr_req_rec     => lr_sr_rec,
                       x_return_status  => x_return_status,
                       X_RETURN_MSG     => x_return_msg);

        IF NVL(X_RETURN_STATUS,'S') <> 'S'THEN

            lc_msg_data := 'Error while creating SR '||x_return_msg;
            x_return_status := 'F';
            x_return_msg := lc_msg_data;

              Log_Exception( p_object_id          => p_party_id
                           , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                           , p_error_message_code => 'XX_CS_MPS01_ERR_LOG'
                           , p_error_msg          => lc_msg_data
                           );
        END IF;

       END IF;
      END;
     else
           x_return_status := 'W';
           x_return_msg    := 'Duplicate Request for this Party '||p_party_id;
           Log_Exception( p_object_id          => p_party_id
                         , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                         , p_error_message_code => 'XX_CS_MPS_REQ_LOG'
                         , p_error_msg          => x_return_msg
                         );

     end if; -- incident_id check
     /************************************************************************
       -- Aprimo Call
      ************************************************************************/
      IF nvl(x_return_status,'S') = 'S' then
        IF ln_customer IS NOT NULL THEN
          -- APRIMO WEB SERVICE CALL
          l_initstr := l_initstr||'<sch:InputParameters xmlns:sch="http://officedepot.com/MPS/CCP/GetContract/Schema">';
          l_initstr := l_initstr||'<!--Optional:-->';
          l_initstr := l_initstr||'<sch:CUSTOMER>'||lc_aops_id||'</sch:CUSTOMER>';
          l_initstr := l_initstr||'<sch:VENDOR>'||lc_vendor||'</sch:VENDOR>';
          l_initstr := l_initstr||'</sch:InputParameters>';


          --DBMS_OUTPUT.PUT_LINE('XML STR '||L_INITSTR);

          BEGIN
            lc_msg_data := xx_cs_mps_utilities_pkg.http_post(l_url,l_initstr) ;

          EXCEPTION
            WHEN OTHERS THEN
              lc_msg_data := 'Error while calling APRIMO API  '||SQLERRM;
           --   dbms_output.put_line('error at aprimo service '||lc_msg_data);
              Log_Exception( p_object_id          => p_party_id
                           , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                           , p_error_message_code => 'XX_CS_REQ05_ERR_LOG'
                           , p_error_msg          => lc_msg_data
                           );
          END;

          ln_customer     := ln_customer;
          x_return_status := fnd_api.g_ret_sts_success;
        END IF;
      END IF;
      /***********************************************************************/

        IF x_return_status = fnd_api.g_ret_sts_success THEN
            x_return_msg := 'Success';
        END IF;

    END IF; -- status

  EXCEPTION
      WHEN OTHERS THEN
        lc_msg_data     := 'Error '||SQLERRM;
        x_return_status := 'F';
        x_return_msg    := lc_msg_data;
       -- dbms_output.put_line(lc_msg_data);
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
   lc_request_type   varchar2(50) := 'MPS Contract Request';
   lc_comments       varchar2(1000);
   lc_summary        varchar2(250);
   lr_request_rec     xx_cs_sr_rec_type;
  ln_user_id        number;

 BEGIN
      --lr_cont_rec := xx_cs_mps_contract_rec_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);


       SELECT user_id
      INTO ln_user_id
      FROM fnd_user
     WHERE user_name = g_user_name;

	  BEGIN
        SELECT party_id
          INTO ln_party_id
          FROM hz_cust_accounts
         WHERE orig_system_reference = p_customer||'-00001-A0';

	  EXCEPTION
	    WHEN OTHERS THEN
		      Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_REQ01_ERR_LOG'
                       , p_error_msg          => 'PARTY ID NOT FOUND FOR OSR : '|| p_customer||'-00001-A0'
                       );
      END;
--dbms_output.put_line('party Id '||ln_party_id);
      Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_REQ01_LOG'
                       , p_error_msg          => 'Contract Request '|| p_customer||'-00001-A0'
                       );

      BEGIN
        SELECT CB.INCIDENT_ID,CB.EMPLOYEE_ID
          INTO ln_incident_id,lc_sales_rep
          FROM cs_incidents_all_b cb,
               cs_incident_types_tl ct
         WHERE ct.incident_type_id = cb.incident_type_id
           AND ct.name             = 'MPS Contract Request'
           AND cb.customer_id      = ln_party_id;
      EXCEPTION
	    WHEN OTHERS THEN
		  NULL;
		  Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.CONTRACT_PROC'
                       , p_error_message_code => 'XX_CS_REQ02_ERR_LOG'
                       , p_error_msg          => 'INCIDENT ID NOT FOUND FOR PARTY ID : '||  ln_party_id
                       );
      END;

    begin

    /* Commented out due to Contracts implemented in SFDC. 
      -- Call Contract create API
      xx_cs_contracts_pkg.create_contract ( p_party_id       => ln_party_id
                                          , p_sales_rep_id   => lc_sales_rep
                                          , p_contract_type  => 'MPS-Contract'
                                          , p_contract_rec   => p_cont_rec--lr_cont_rec
                                          , x_contract_num   => ln_contract_hdr_id
                                          , x_return_status  => lc_return_status
                                          , x_return_mesg    => lc_return_message
                                          ); */
                                          
          update xx_cs_mps_device_b
          set contract_number = p_cont_rec.contract_id,
               expired_date = p_cont_rec.Expiration_date , 
               period_covered_st_date = p_cont_rec.Sign_date  
          where party_id = ln_party_id;
          
          commit;

    exception
      when others then
          Log_Exception( p_object_id          => ln_party_id
                       , p_error_location     => 'XX_CS_MPS_CONTRACTS_PKG.SFDC_PROC'
                       , p_error_message_code => 'XX_CS_REQ03_ERR_LOG'
                       , p_error_msg          => 'Error while create contract '|| lc_return_message|| 'for '||p_customer||'-00001-A0'
                       );
    end;

      IF ln_contract_hdr_id IS NULL THEN
        x_return_status := lc_return_status;
        x_return_msg    := lc_return_message;
        -- log table
      ELSE
        x_return_status := lc_return_status;
        x_return_msg    := 'Sucess';

       LC_COMMENTS := 'Contract# '||ln_contract_hdr_id||' for this request';
       lr_request_rec.global_ticket_number := ln_contract_hdr_id;
       lr_request_rec.description := 'Contract# '||ln_contract_hdr_id||' for this request';
       lr_request_rec.status_name := 'In Progress';

       xx_cs_mps_utilities_pkg.update_sr (P_REQUEST_ID    => LN_INCIDENT_ID,
                                        P_COMMENTS      => LC_COMMENTS,
                                        P_REQ_TYPE      => LC_REQUEST_TYPE,
                                        P_SR_REQ_REC    => LR_REQUEST_REC,
                                        X_RETURN_STATUS  => LC_RETURN_STATUS,
                                        X_RETURN_MSG     => LC_RETURN_MESSAGE);
      END IF;

        x_return_status := 'S';
        x_return_msg    := 'Success';

END CONTRACT_PROC;
  /*****************************************************************************/

  --PROCEDURE for pending status request
END XX_CS_MPS_CONTRACTS_PKG;

/
show errors;
exit;