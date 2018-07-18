create or replace 
PACKAGE BODY XX_CS_TDS_VEN_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_VEN_PKG                                        |
-- |                                                                   |
-- | Description: Wrapper package for Vendor Communications.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-Apr-10   Raj Jagarlamudi  Initial draft version       |
-- |2.0       12-Aug-10   Raj Jagarlamudi  Separate the responses      |
-- |3.0       27-APR-12   Raj Jagarlamudi  Info updates for vendor     |
-- |                                       comments update             |
-- |          25-SEP-13   Raj Jagarlamudi  New vendor Integration      |
-- |          27-nov-13   Raj J            MPS calls redirected        |
-- |4.0       09-Sep-2015 Arun G           Changes for Digital Locker SKUs |
-- |5.0       01-Oct-2015 Arun G           Made changes for digial     |
-- |6.0       22-Jan-16   Vasu Raparla     Removed schema References   |
-- |                                       for R.12.2                  |
-- +===================================================================+

gc_action     varchar2(100);
gc_vendor     varchar2(250);
gn_msg_id     number;
gn_sr_id      number;
gc_user_name  varchar2(150) ;

/*****************************************************************************
-- Log Messages
****************************************************************************/
PROCEDURE Log_Exception ( p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XX_CRM'
     ,p_program_type            => 'Custom Messages'
     ,p_program_name            => 'XX_CS_TDS_VEN_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'CSF'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     );

END Log_Exception;
/**************************************************************************/
/*****************************************************************************
-- Update Service Request
*****************************************************************************/
PROCEDURE UPDATE_SR(P_SR_REQUEST_ID IN NUMBER,
                    P_SR_REQ_REC    IN CS_ServiceRequest_PUB.service_request_rec_type,
                    P_NOTES_HDR     IN VARCHAR2,
                    P_COMMENTS      IN VARCHAR2,
                    P_VENDOR        IN VARCHAR2,
                    P_OBJ_VER       IN NUMBER,
                    X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                    X_MSG_DATA      IN OUT NOCOPY VARCHAR2)
IS

   lx_msg_count                NUMBER;
   lx_msg_data                 VARCHAR2(2000);
   lx_request_id               NUMBER;
   lx_request_number           VARCHAR2(50);
   lx_interaction_id           NUMBER;
   lx_workflow_process_id      NUMBER;
   lx_msg_index_out            NUMBER;
   lx_return_status            VARCHAR2(1);
   ln_obj_ver                  NUMBER ;
   ln_type_id                  NUMBER;
   ln_status_id                number;
   ln_category_id              number;
   lr_service_request_rec       CS_ServiceRequest_PUB.service_request_rec_type;
   lt_notes_table               CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab              CS_SERVICEREQUEST_PUB.contacts_table;
   lc_message                  VARCHAR2(2000);
   ln_user_id                  number;
   ln_resp_appl_id             number;
   ln_resp_id                  number;

begin

      cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
      lr_service_request_rec := p_sr_req_rec;

     /************************************************************************
      -- Get Object version
      *********************************************************************/
      BEGIN
       SELECT object_version_number
       INTO ln_obj_ver
       FROM   cs_incidents_all_b
       WHERE  incident_id = p_sr_request_id;
      EXCEPTION
        WHEN OTHERS THEN
          ln_obj_ver := 2;
      END;
   /*************************************************************************
     -- Add notes
    ************************************************************************/

      lt_notes_table(1).note        := p_notes_hdr ;
      lt_notes_table(1).note_detail := p_comments;
      lt_notes_table(1).note_type   := 'GENERAL';

   /**************************************************************************
       -- Update SR
    *************************************************************************/

   cs_servicerequest_pub.Update_ServiceRequest (
                    p_api_version            => 2.0,
                    p_init_msg_list          => FND_API.G_TRUE,
                    p_commit                 => FND_API.G_FALSE,
                    x_return_status          => lx_return_status,
                    x_msg_count              => lx_msg_count,
                    x_msg_data               => lx_msg_data,
                    p_request_id             => p_sr_request_id,
                    p_request_number         => NULL,
                    p_audit_comments         => NULL,
                    p_object_version_number  => ln_obj_ver,
                    p_resp_appl_id           => NULL,
                    p_resp_id                => NULL,
                    p_last_updated_by        => NULL,
                    p_last_update_login      => NULL,
                    p_last_update_date       => sysdate,
                    p_service_request_rec    => p_sr_req_rec,
                    p_notes                  => lt_notes_table,
                    p_contacts               => lt_contacts_tab,
                    p_called_by_workflow     => FND_API.G_FALSE,
                    p_workflow_process_id    => NULL,
                    x_workflow_process_id    => lx_workflow_process_id,
                    x_interaction_id         => lx_interaction_id   );

      commit;

   IF (lx_return_status <> FND_API.G_RET_STS_SUCCESS) then
      IF (FND_MSG_PUB.Count_Msg > 1) THEN
         --Display all the error messages
         FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
            FND_MSG_PUB.Get(p_msg_index     => j,
                            p_encoded       => 'F',
                            p_data          => lx_msg_data,
                            p_msg_index_out => lx_msg_index_out);
         END LOOP;
      ELSE      --Only one error
         FND_MSG_PUB.Get(
            p_msg_index     => 1,
            p_encoded       => 'F',
            p_data          => lx_msg_data,
            p_msg_index_out => lx_msg_index_out);

      END IF;
      x_return_status := lx_return_status;
      x_msg_data := substr(lx_msg_data,1,200);
   END IF;

   x_return_status := lx_return_status;

  EXCEPTION
   WHEN OTHERS THEN
       X_RETURN_STATUS := 'F';
       X_MSG_DATA  := 'Error while updating SR '||SQLERRM;

END UPDATE_SR;
/**************************************************************************/
FUNCTION http_post ( url VARCHAR2, req_body varchar2)
RETURN VARCHAR2  AS

  soap_request      VARCHAR2(30000);
  soap_respond      VARCHAR2(30000);
  req               utl_http.req;
  resp              utl_http.resp;
  v_response_text   VARCHAR2(32767);
  x_resp            XMLTYPE;
  l_detail          VARCHAR2(32767);
  i                 integer;
  l_msg_data        varchar2(30000);
   --
   v_doc            dbms_xmldom.DOMDocument;
   v_node_list      dbms_xmldom.DOMNodeList;
   v_node           dbms_xmldom.DOMNode;
   v_ele            dbms_xmldom.DOMElement;
   v_childnode      dbms_xmldom.DOMNode;
   ndoc             dbms_xmldom.DOMNode;
   v_nodename       varchar2(150);
   v_len            number;
   ln_serviceId     number;
   lc_status        varchar2(150);
   lc_return_status varchar2(100) := 'false';
   lc_conn_link     varchar2(3000);
   lc_message       varchar2(3000);
   lr_sku_tbl       XX_CS_TDS_SKU_TBL;
   lc_receiver      varchar2(100);

begin

      soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>'||
                      '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'||
                      '<soap:Body xmlns:ns1="http://TargetNamespace.com/ServiceB2BOutbound">'||req_body||
                      '</soap:Body>'||'</soap:Envelope>';

     -- dbms_output.put_line(soap_request);
      req := utl_http.begin_request(url,'POST','HTTP/1.1');
     --  UTL_HTTP.SET_AUTHENTICATION (HTTP_REQ, 'G016D01/S0162114', 'Xenios02', 'Basic',true);
      utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
      utl_http.set_header(req,'Content-Length', length(soap_request));
      utl_http.set_header(req  , 'SOAPAction'  , 'process');
      utl_http.write_text(req, soap_request);

        resp := utl_http.get_response(req);
        utl_http.read_text(resp, soap_respond);
    --    utl_http.read_text(resp, v_response_text, 32767);

    --  dbms_output.put_line('Response Received');
    --  dbms_output.put_line('--------------------------');
    --  dbms_output.put_line ( 'Status code: ' || resp.status_code );
    --  dbms_output.put_line ( 'Reason phrase: ' || resp.reason_phrase );

        lc_message := 'Response Received '||resp.status_code;

      utl_http.end_response(resp);

      x_resp := XMLType.createXML(soap_respond);


      l_msg_data := 'Req '||soap_request;
     /*
       Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.HTTP_POST'
                              ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                              ,p_error_msg          =>  l_msg_data);

            */
        x_resp := x_resp.extract('/soap:Envelop/soap:Body/child::node()'
                               ,'xmlns:soap="http://TargetNamespace.com/XMLSchema-instance"');
                       --   ,'xmlns:soap="http://esbdev01.na.odcorp.net/XMLSchema-instance"');

     -- dbms_output.put_line('Output '|| soap_respond);
          l_msg_data := 'Res '||soap_respond;

          Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.HTTP_POST'
                          ,p_error_message_code =>  'XX_CS_SR01_SUCCESS_LOG'
                          ,p_error_msg          =>  l_msg_data);

          l_detail   := substr(req_body,1,2000);
          lc_receiver := gc_vendor;

          l_msg_data := lc_message;
         /************************************************************
            -- insert message
          ************************************************************/

           BEGIN
             INSERT INTO cs_messages (
                          message_id,
                          notification_id,
                          date_sent,
                          last_update_date,
                          last_updated_by,
                          creation_date,
                          created_by,
                          last_update_login,
                          source_object_type_code,
                          source_object_int_id,
                          source_object_ext_id,
                          sender,
                          receiver,
                          priority,
                          expand_roles,
                          action_code,
                          confirmation,
                          message )
                  VALUES (
                          gn_msg_id,
                          gn_msg_id,
                          sysdate,
                          sysdate,
                          uid,
                          sysdate,
                          uid,
                          uid,
                          'INC',
                          gn_sr_id,
                          ln_serviceId,
                          'CS_ADMIN',
                          lc_receiver,
                          'HIGH',
                          'N',
                          gc_action,
                          'N',
                          l_detail);

                  commit;

              exception
                  when others then
                    l_msg_data  :=  l_msg_data||' Error while inserting into CS_MESSAGES '||SQLERRM;

                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.HTTP_POST'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERROR_LOG'
                                  ,p_error_msg          =>  l_msg_data);
              end;

         v_response_text := l_msg_data;

    return v_response_text;
end;

/*------------------------------------------------------------------------
  Procedure Name : Make_Param_Str
  Description    : concatenates parameters for XML message
--------------------------------------------------------------------------*/

FUNCTION Make_Param_Str(p_param_name IN VARCHAR2,
                         p_param_value IN VARCHAR2)
 RETURN VARCHAR2
 IS
 BEGIN
   	RETURN '<ns1:'||p_param_name||
        	  '>'||'<![CDATA['||p_param_value||']]>'||'</ns1:'||p_param_name||'>';

 END Make_Param_Str;
--------------------------------------------------------------------------------

/******************************************************************************
  -- Customer Procedure
*******************************************************************************/
PROCEDURE CUSTOMER_REC (P_CUSTOMER_ID   IN NUMBER,
                        P_AOPS_CUST_ID  IN NUMBER,
                        P_PHONE_NUMBER  IN VARCHAR2,
                        P_EMAIL_ADDRESS IN VARCHAR,
                        P_CONTACT_NAME  IN VARCHAR2,
                        x_initStr       IN OUT NOCOPY VARCHAR2)
IS
 lc_add1        varchar2(250);
 lc_add2        varchar2(250);
 lc_city        varchar2(250);
 lc_state       varchar2(250);
 lc_country     varchar2(100);
 lc_postal_code varchar2(250);
 lc_msg_data    varchar2(2000);
 lc_first_name  varchar2(250);
 lc_last_name   varchar2(250);

BEGIN
         -- Select Customer Address
         Begin
            select address1,
                   address2,
                   city,
                   decode(country,'CA',province,state) state,
                   postal_code,
                   nvl(person_first_name,party_name),
                   nvl(person_last_name,party_name),
                   country
            into lc_add1,
                 lc_add2,
                 lc_city,
                 lc_state,
                 lc_postal_code,
                 lc_first_name,
                 lc_last_name,
                 lc_country
            from hz_parties
            where party_id = p_customer_id;
         exception
          when others then
               LC_MSG_DATA := 'error while selecting address '||sqlerrm;
                Log_Exception ( p_error_location      =>  'XX_CS_TDS_VEN_PKG.CUSTOMER_REC'
                               ,p_error_message_code  =>   'XX_CS_SR02_ERR_LOG'
                               ,p_error_msg           =>  lc_msg_data);
        end;
        -- Select first name
        BEGIN
          select hp.person_first_name,
                 hp.person_last_name
          into   lc_first_name,
                 lc_last_name
          from   hz_person_profiles hp,
                 hz_relationships hr
          where  hp.party_id = hr.object_id
          and    hr.relationship_code = 'CONTACT'
          and    hr.subject_id = p_customer_id
          and    hp.person_name = p_contact_name;
        EXCEPTION
          WHEN OTHERS THEN
              lc_first_name := substr(p_contact_name,1,instr(p_contact_name,' '));
              lc_last_name := substr(p_contact_name,instr(p_contact_name,' '));
        END;

         /**************************************************************
           -- Customer String
         **************************************************************/
           x_initStr := x_initStr||'<ns1:customer>';

           x_initStr := x_initStr||Make_Param_Str
                        ('customerNumber',p_aops_cust_id);
           x_initStr := x_initStr||Make_Param_Str
                        ('firstName',lc_first_name);
           x_initStr := x_initStr||Make_Param_Str
                        ('lastName',lc_last_name);
           x_initStr := x_initStr||Make_Param_Str
                        ('address1',lc_add1);
           x_initStr := x_initStr||Make_Param_Str
                        ('address2',lc_add2);
           x_initStr := x_initStr||Make_Param_Str
                        ('city',lc_city);
           x_initStr := x_initStr||Make_Param_Str
                         ('state',lc_state);
        IF lc_country <> 'US' then
           x_initStr := x_initStr||Make_Param_Str
                         ('zipcode',lc_postal_code);
        else
           x_initStr := x_initStr||Make_Param_Str
                         ('zipcode',substr(lc_postal_code,1,5));
        end if;

           x_initStr := x_initStr||Make_Param_Str
                         ('country',lc_country);
           x_initStr := x_initStr||Make_Param_Str
                         ('phoneNumber',p_phone_number);
           x_initStr := x_initStr||Make_Param_Str
                         ('alternatePhoneNumber',null);
           x_initStr := x_initStr||Make_Param_Str
                         ('faxNumber',null);
           x_initStr := x_initStr||Make_Param_Str
                         ('email',p_email_address);

          x_initStr := x_initStr||'</ns1:customer>';

    EXCEPTION
      WHEN OTHERS THEN
           LC_MSG_DATA := 'error while building customer string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.CUSTOMER_REC'
                       ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);

 END CUSTOMER_REC;
 /************************************************************************/
/*******************************************************************************/
PROCEDURE NEXICORE_QA_REC (p_incident_id  IN NUMBER,
                           p_sku         IN VARCHAR2,
                           p_que_ans_id   IN NUMBER,
                          x_sku_initStr  IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
i               number := 0;

CURSOR qa_details IS
select qp.question_label qus,
       qp.node_name tag,
       qd.freeform_string ans
from   ies_question_data qd,
       ies_questions qp,
       ies_panels ip
where  ip.panel_id = qp.panel_id
and    qp.question_id = qd.question_id
and    ip.panel_label in ('H','C')
and    qd.transaction_id = p_que_ans_id;

BEGIN

              FOR qa_details_rec IN qa_details LOOP
               I := I + 1;
                  /************************************************************/
                  -- Sku questions Data

                    x_sku_initStr := x_sku_initStr||' '||qa_details_rec.qus||':'||qa_details_rec.ans;
                   /*   x_sku_initStr := x_sku_initStr||'<ns1:QuestionData>';

                          x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('answer',qa_details_rec.ans);
                          x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('question',qa_details_rec.qus);


                      x_sku_initStr := x_sku_initStr||'</ns1:QuestionData>'; */

                 /*************************************************************/
              END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    LC_MSG_DATA := 'error while building QA string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.NEXICORE_QA_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
END NEXICORE_QA_REC;
/************************************************************************/
/*******************************************************************************/
PROCEDURE QA_REC (p_incident_id  IN NUMBER,
                   p_sku         IN VARCHAR2,
                   p_que_ans_id   IN NUMBER,
                   x_sku_initStr  IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
i               number := 0;

CURSOR qa_details IS
select qp.question_label qus,
       qp.node_name tag,
       qd.freeform_string ans
from   ies_question_data qd,
       ies_questions qp,
       ies_panels ip
where  ip.panel_id = qp.panel_id
and    qp.question_id = qd.question_id
and    ip.panel_label = p_sku
and    qd.transaction_id = p_que_ans_id;

BEGIN

      x_sku_initStr := x_sku_initStr||'<ns1:skuQuestions>';

              FOR qa_details_rec IN qa_details LOOP
               I := I + 1;
                  /************************************************************/
                  -- Sku questions Data

                      x_sku_initStr := x_sku_initStr||'<ns1:skuQuestionData>';

                          x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('answer',qa_details_rec.ans);
                          x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('question',qa_details_rec.qus);
                           x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('tag',qa_details_rec.tag);

                      x_sku_initStr := x_sku_initStr||'</ns1:skuQuestionData>';

                 /*************************************************************/
              END LOOP;
              x_sku_initStr := x_sku_initStr||'</ns1:skuQuestions>';
EXCEPTION
  WHEN OTHERS THEN
    LC_MSG_DATA := 'error while building QA string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.QA_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
END QA_REC;
/*******************************************************************************/
PROCEDURE SKU_REC (p_incident_id  IN NUMBER,
                   p_vendor       IN VARCHAR2,
                   p_que_ans_id   IN NUMBER,
                   p_status_id    IN NUMBER,
                   x_sku_initStr  IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
lc_store_code   varchar2(200);

CURSOR get_sku_details IS
select vl.attribute6 item_number,
       vl.attribute7 item_description,
       vl.attribute8 quantity,
       tl.name type_name
from jtf_tasks_vl vl,
     jtf_task_types_tl tl
where tl.task_type_id = vl.task_type_id
and   vl.source_object_id = p_incident_id
and vl.attribute1 = P_vendor
and vl.task_status_id = p_status_id;

BEGIN

      x_sku_initStr := '<ns1:skus>';

              FOR get_sku_details_rec IN get_sku_details
              LOOP

              -- Select Store code
                   BEGIN
                          SELECT DESCRIPTION
                          INTO LC_STORE_CODE
                          FROM FND_LOOKUP_VALUES
                          WHERE LOOKUP_TYPE =  'XX_CS_TDS_TASK_CODE'
                          AND MEANING = get_sku_details_rec.type_name
                          AND END_DATE_ACTIVE IS NULL;
                      EXCEPTION
                        WHEN OTHERS THEN
                            LC_STORE_CODE := 'Store';
                            LC_MSG_DATA := 'Error while selecting store code '||sqlerrm;
                            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SKU_REC'
                                  ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                  ,p_error_msg          =>  lc_msg_data);
                      END;

                  x_sku_initStr := x_sku_initStr||'<ns1:skuData>';

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('deliveryLocation',lc_store_code);

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('skuId',get_sku_details_rec.item_number);

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('quantity',get_sku_details_rec.quantity);

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('description',get_sku_details_rec.item_description);

                  /************************************************************/
                  -- Sku questions Data
                      QA_REC (p_incident_id  => p_incident_id,
                               p_sku         => get_sku_details_rec.item_number,
                               p_que_ans_id  => p_que_ans_id,
                               x_sku_initStr => x_sku_initStr);
                 /*************************************************************/

                  x_sku_initStr := x_sku_initStr||'</ns1:skuData>';

              END LOOP;
              x_sku_initStr := x_sku_initStr||'</ns1:skus>';
EXCEPTION
  WHEN OTHERS THEN
    LC_MSG_DATA := 'error while building SKU string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SKU_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
END SKU_REC;
/******************************************************************************
  -- Device Procedure
*******************************************************************************/
PROCEDURE DEVICE_REC (P_INCIDENT_ID   IN NUMBER,
                      P_DESCRIPTION   IN VARCHAR2,
                      P_PROB_DESCR    IN VARCHAR2,
                      P_VENDOR        IN VARCHAR2,
                      x_initStr       IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
lc_manuf        varchar2(250);
lc_brand        varchar2(250);
lc_model        varchar2(250);
lc_type         varchar2(250);
lc_os           varchar2(250);
lc_serial       varchar2(250);
lc_login        varchar2(250);
lc_passwd       varchar2(250);
lc_descr        varchar2(250);
lc_prob_descr   varchar2(2000);
lc_device_flag  varchar2(1) := 'Y';
lc_panel        varchar2(25);
l_que_id        number;

BEGIN

     BEGIN
        select incident_attribute_12,
               incident_attribute_4,
               incident_attribute_6,
               incident_attribute_3,
               incident_attribute_7,
               incident_attribute_10,
               external_attribute_7,
               external_attribute_10,
               external_attribute_8,
               external_attribute_9,
               tier
        into   lc_manuf,
               lc_brand,
               lc_model,
               lc_type,
               lc_os,
               lc_serial,
               lc_descr,
               lc_prob_descr,
               lc_login,
               lc_passwd,
               l_que_id
        from cs_incidents_all_b
        where incident_id = p_incident_id;
     EXCEPTION
        WHEN OTHERS THEN
           lc_device_flag := 'N';
     END;

     IF LC_DEVICE_FLAG = 'N' THEN
            x_initStr := x_initStr||'<ns1:device>';
            x_initStr := x_initStr||Make_Param_Str
                            ('manufacturer','eMachines');
            x_initStr := x_initStr||Make_Param_Str
                            ('brand','Lifebook (Fujitsu)');
            x_initStr := x_initStr||Make_Param_Str
                            ('model','Latest');
            x_initStr := x_initStr||Make_Param_Str
                            ('deviceType','Laptop');
            x_initStr := x_initStr||Make_Param_Str
                            ('operatingSystem','Windows Vista');
            x_initStr := x_initStr||Make_Param_Str
                            ('serialNumber','1234567');
            x_initStr := x_initStr||Make_Param_Str
                             ('systemLogin','test');
            x_initStr := x_initStr||Make_Param_Str
                             ('systemPassword','test');
            x_initStr := x_initStr||Make_Param_Str
                             ('description','New');
            x_initStr := x_initStr||Make_Param_Str
                             ('problemDescription','New');
              x_initStr := x_initStr||'</ns1:device>';
     ELSE
            x_initStr := x_initStr||'<ns1:device>';
            x_initStr := x_initStr||Make_Param_Str
                            ('manufacturer',lc_manuf);
            x_initStr := x_initStr||Make_Param_Str
                            ('brand',lc_brand);
            x_initStr := x_initStr||Make_Param_Str
                            ('model',lc_model);
            x_initStr := x_initStr||Make_Param_Str
                            ('deviceType',lc_type);
            x_initStr := x_initStr||Make_Param_Str
                            ('operatingSystem',lc_os);
            x_initStr := x_initStr||Make_Param_Str
                            ('serialNumber',lc_serial);
            x_initStr := x_initStr||Make_Param_Str
                             ('systemLogin',lc_login);
            x_initStr := x_initStr||Make_Param_Str
                             ('systemPassword',lc_passwd);
          IF P_VENDOR = 'Support.com' then
             x_initStr := x_initStr||Make_Param_Str
                             ('description',lc_descr);
             x_initStr := x_initStr||Make_Param_Str
                             ('problemDescription',lc_prob_descr);
          else
              x_initStr := x_initStr||Make_Param_Str
                             ('description',p_description);

               IF P_VENDOR <> 'Support.com' then
                  lc_panel := 'C,H';
              /************************************************************/
                  -- questions Data
                      NEXICORE_QA_REC (p_incident_id  => p_incident_id,
                                      p_sku         => lc_panel,
                                      p_que_ans_id  => l_que_id,
                                      x_sku_initStr => lc_prob_descr);
                 /*************************************************************/
               END IF;

                x_initStr := x_initStr||Make_Param_Str
                             ('problemDescription',nvl(lc_prob_descr,p_prob_descr));

          end if;
              x_initStr := x_initStr||'</ns1:device>';

      END IF;


   EXCEPTION
      WHEN OTHERS THEN
           LC_MSG_DATA := 'error while building DEVICE string '||sqlerrm;
                Log_Exception ( p_error_location  =>  'XX_CS_TDS_VEN_PKG.DEVICE_REC'
                       ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);

end device_rec;
/******************************************************************************/
FUNCTION SR_TASK (P_subscription_guid  IN RAW,
                  P_event              IN OUT NOCOPY WF_EVENT_T) RETURN VARCHAR2 AS

 l_event_key              NUMBER ;
 l_event_name 	          VARCHAR2(240) := p_event.getEventName();
 l_updated_entity_code    VARCHAR2(40) ;
 l_updated_entity_id      NUMBER;
 l_entity_update_date     DATE ;
 l_entity_activity_code   VARCHAR2(30) ;
 l_source_object_code     VARCHAR2(240);
 l_source_object_id       NUMBER ;
 l_incident_id            NUMBER ;
 l_user_id                NUMBER := null ;
 l_audit_id		            NUMBER ;
 l_return_status 	        VARCHAR2(30);
 l_msg_count 	 	          NUMBER ;
 l_msg_data   	 	        VARCHAR2(32767) ;
 l_initStr                VARCHAR2(30000);
 l_sku_initStr            VARCHAR2(30000);
 lc_type_name             VARCHAR2(250);
 lc_task_name             VARCHAR2(250);
 lc_task_descr            VARCHAR2(250);
 ln_que_ans_id            NUMBER;
 lc_category              VARCHAR2(150);
 ln_status_id             number;
 lc_status                varchar2(250);
 lc_ven_status            varchar2(250);
 lc_comments              varchar2(3000);
 lc_contact_name          varchar2(250);

 -- Cursors to get Task Details

    CURSOR get_Task_Dtls (p_task_id IN NUMBER) IS
           SELECT tt.Attribute1 Vendor,
                  tt.task_id ,
                  ty.name type_name,
                  tt.last_update_date,
                  tt.creation_date ,
                  tt.last_updated_by,
                  tt.source_object_type_code ,
                  tt.source_object_id,
                  tt.attribute5 category,
                  tt.attribute6 item,
                  tt.description,
                  tt.task_name
            FROM jtf_tasks_vl tt,
                 jtf_task_types_tl ty
           WHERE ty.task_type_id = tt.task_type_id
            AND  tt.task_id = p_task_id
            AND  tt.task_status_id = 14
            AND  tt.Attribute1 <> 'OD';

 -- Cursor to get Note details

    CURSOR get_Note_Dtls (p_jtf_note_id IN NUMBER) IS
           SELECT notes ,
                  source_object_code source_object_type_code,
                  source_object_id ,
                  creation_date ,
                  last_update_date,
                  last_updated_by,
                  entered_by_name,
                  note_type
             FROM jtf_notes_vl
            WHERE jtf_note_id = p_jtf_note_id
             AND  entered_by_name NOT IN (SELECT UPPER(MEANING)
                                           FROM FND_LOOKUP_VALUES
                                           WHERE LOOKUP_TYPE = 'XX_CS_TDS_VENDOR_LINK');

  -- Cursor to Get Incident Details
   CURSOR get_inc_details (p_incident_id IN NUMBER) IS
           SELECT incident_number	,
                  customer_id, incident_status_id,
                  lpad(incident_attribute_11,5,0) store_number,
                  incident_attribute_9 aops_customer_id,
                  incident_attribute_1 order_number,
                  incident_attribute_14 phone_number,
                  incident_attribute_8 email_add,
                  last_updated_by, summary,tier qa_id,
                  incident_attribute_5 contact_name,
                  external_attribute_10 prob_descr
	      FROM cs_incidents_all_vl
            WHERE incident_id  = p_incident_id  ;

-- Get Rejected Tasks
CURSOR get_rej_task_dtls (P_TASK_ID IN NUMBER) IS
 SELECT tt.Attribute1 Vendor,
                  tt.task_id ,
                  ty.name type_name,
                  tt.last_update_date,
                  tt.creation_date ,
                  tt.last_updated_by,
                  tt.source_object_type_code ,
                  tt.source_object_id,
                  tt.attribute5 category,
                  tt.attribute6 item,
                  tt.description,
                  tt.task_name
            FROM jtf_tasks_vl tt,
                 jtf_task_types_tl ty
           WHERE ty.task_type_id = tt.task_type_id
            AND  tt.task_id = p_task_id
            AND  tt.task_status_id = 4
            AND  tt.Attribute1 <> 'OD'
            AND  nvl(tt.attribute3,'N') = 'N';

-- Cursor to Get SKU Details;
CURSOR get_sku_details  IS
select item_number,
       item_description,
       quantity,
       substr(attribute5,1,1) sku_category
from xx_cs_sr_items_link
where service_request_id = l_incident_id
--and   substr(attribute5,1,1) = lc_category
and   attribute4 like upper('%'||gc_vendor||'%')
and   attribute4 not in (select meaning from fnd_lookup_values
                          where lookup_type = 'XX_TDS_EXC_VENDORS')
order by attribute5;

get_sku_details_rec get_sku_details%rowtype;


    e_event_updates EXCEPTION ;

    l_object_version_number     cs_incidents_all_b.object_version_number%TYPE;
    l_notes     		            CS_SERVICEREQUEST_PVT.notes_table;
    l_contacts  		            CS_SERVICEREQUEST_PVT.contacts_table;
    l_service_request_rec       CS_ServiceRequest_pvt.service_request_rec_type;
    l_sr_update_out_rec         CS_ServiceRequest_pvt.sr_update_out_rec_type;

l_incident_number	              VARCHAR2(100);
ld_date                         date;
l_store_number  	              VARCHAR2(25);
lc_store_code                   varchar2(50);
l_order_number  	              NUMBER;
lc_phone_number		              VARCHAR2(50);
lc_email_id                     VARCHAR2(250);
l_incident_urgency_id	          NUMBER;
l_incident_owner_id	            NUMBER;
l_owner_group_id	              NUMBER;
l_customer_id		                NUMBER;
l_aops_cust_id                  NUMBER;
l_last_updated_by	              NUMBER;
l_summary		                    VARCHAR2(240) ;
l_url                           varchar2(2000);
l_api_version                   number;
l_workflow_process_id           NUMBER;
lc_rej_flag                     VARCHAR2(1) := 'N';
lc_sub_flag                     VARCHAR2(1) := 'N';
lc_item_number                  VARCHAR2(50);
lc_sr_status                    VARCHAR2(50);
ln_sr_status_id                 number;
I                               NUMBER;
lc_ext_attribute_11             VARCHAR2(250);
lc_ext_attribute_12             VARCHAR2(250);

BEGIN

  /** Detect the event raised and determine necessary parameters depending on the event **/
       -- Get B2B URL
        BEGIN
           select fnd_profile.value('XX_B2B_WEB_URL')
           into l_url
           from dual;
       exception
           when others then
              l_url := null;
              l_msg_data := 'Valid B2B URL is not setup';
              raise e_event_updates;
       END;


   IF l_event_name  = 'oracle.apps.jtf.cac.task.createTask'  THEN

          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_TYPE_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');
          gc_action               := 'Create';
        --  l_user_id              := p_event.GetValueForParameter('USER_ID');

    IF ((l_source_object_code = 'SR') AND (l_source_object_id IS NOT NULL ) ) THEN

             l_event_key  := p_event.GetValueForParameter('TASK_ID');

               FOR get_task_dtls_rec IN get_task_dtls(l_event_key)
               LOOP
                       l_updated_entity_id     := l_event_key ;
                       l_updated_entity_code   := 'SR_TASK' ;
                       l_entity_update_date    := get_task_dtls_rec.creation_date;
                       l_entity_activity_code  := 'C';
                       l_incident_id           := get_task_dtls_rec.source_object_id ;
                       gn_sr_id                := l_incident_id;
                       l_user_id               := get_task_dtls_rec.last_updated_by ;
                       gc_vendor               := get_task_dtls_rec.vendor;
                       ld_date                 := get_task_dtls_rec.creation_date;
                       lc_category             := get_task_dtls_rec.category;
                       lc_task_name            := get_task_dtls_rec.type_name;
                       l_summary               := get_task_dtls_rec.description;
                       lc_task_descr           := get_task_dtls_rec.task_name;

                  If l_incident_id is not null then
                  -- Determine Type
                    BEGIN
                    select ct.name,incident_status_id
                    into lc_type_name, ln_status_id
                    from cs_incidents_all_b cb,
                          cs_incident_types_tl ct
                    where ct.incident_type_id = cb.incident_type_id
                    and   cb.incident_id = l_incident_id;
                  EXCEPTION
                    WHEN OTHERS THEN
                        l_msg_data := 'Error while selecting type for Incident :'||l_incident_id||'; '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                              ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                              ,p_error_msg          =>  l_msg_data);
                  END;
                  end if;
              END LOOP;

            IF LC_TYPE_NAME LIKE 'TDS%' THEN

              l_msg_data := 'In Create event Inicdent Id '||l_incident_id||' Type '||lc_type_name ;

              Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                        ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                        ,p_error_msg          =>  l_msg_data);

              begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;

              -- Determine store code
              BEGIN
                SELECT DESCRIPTION
                INTO LC_STORE_CODE
                FROM FND_LOOKUP_VALUES
                WHERE LOOKUP_TYPE =  'XX_CS_TDS_TASK_CODE'
                AND MEANING = LC_TASK_NAME
                AND END_DATE_ACTIVE IS NULL;
            EXCEPTION
              WHEN OTHERS THEN
                  LC_STORE_CODE := 'Store';
                  L_MSG_DATA := 'Error while selecting store code '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                        ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                        ,p_error_msg          =>  l_msg_data);
            END;

              l_initStr := l_initStr||'<ns1:ODTechService>';

              FOR get_inc_details_rec IN get_inc_details (l_incident_id)
              LOOP
                    IF gc_vendor is null then
                      gc_vendor := 'Support.com';
                    end if;

                    l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',gc_action);
                    l_incident_number	:= get_inc_details_rec.incident_number;
                      l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',l_incident_number);
                    l_store_number  	:= get_inc_details_rec.store_number;
                      l_initStr := l_initStr||Make_Param_Str
                                    ('storeCode',l_store_number);

                        l_initStr := l_initStr||Make_Param_Str
                                    ('comments',l_summary);

                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',null);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                        l_customer_id	    := get_inc_details_rec.customer_id;
                        lc_phone_number	    := get_inc_details_rec.phone_number;
                        lc_email_id	    := get_inc_details_rec.email_add;
                        l_aops_cust_id      := get_inc_details_rec.aops_customer_id;
                        ln_que_ans_id       := get_inc_details_rec.qa_id;
                        lc_contact_name     := get_inc_details_rec.contact_name;

                    -- Customer String
                     CUSTOMER_REC (P_CUSTOMER_ID  => L_CUSTOMER_ID,
                                  P_AOPS_CUST_ID  => L_AOPS_CUST_ID,
                                  P_PHONE_NUMBER  => LC_PHONE_NUMBER,
                                  P_EMAIL_ADDRESS => LC_EMAIL_ID,
                                  P_CONTACT_NAME  => LC_CONTACT_NAME,
                                  x_initStr       => l_initStr);

                      -- Device String
                      DEVICE_REC (P_INCIDENT_ID   => L_INCIDENT_ID,
                                  P_DESCRIPTION   => LC_TASK_DESCR,
                                  P_PROB_DESCR    => l_summary,
                                  P_VENDOR        => GC_VENDOR,
                                  x_initStr   => L_INITSTR);

              END LOOP;

              --dbms_output.put_line('before SKUs '||L_INITSTR);

              l_sku_initStr := '<ns1:skus>';

              BEGIN
                OPEN get_sku_details;
                LOOP
                FETCH get_sku_details INTO get_sku_details_rec;
                EXIT WHEN get_sku_details%NOTFOUND;

                  l_sku_initStr := l_sku_initStr||'<ns1:skuData>';

                  IF gc_vendor = 'Support.com'
                     and get_sku_details_rec.sku_category <> 'R' then

                       l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('deliveryLocation','Home');

                      l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryParty','None');
                  else
                      l_sku_initStr := l_sku_initStr||Make_Param_Str
                                        ('deliveryLocation',lc_store_code);

                      l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryParty','SprtSE');
                  end if;


                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('skuId',get_sku_details_rec.item_number);

                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('quantity',get_sku_details_rec.quantity);

                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('description',get_sku_details_rec.item_description);

                  /************************************************************/
                  -- Sku questions Data
                      QA_REC (p_incident_id  => l_incident_id,
                               p_sku         => get_sku_details_rec.item_number,
                               p_que_ans_id  => ln_que_ans_id,
                               x_sku_initStr => l_sku_initStr);
                 /*************************************************************/

                  l_sku_initStr := l_sku_initStr||'</ns1:skuData>';

                END LOOP;
                CLOSE get_sku_details;
              END;

              l_sku_initStr := l_sku_initStr||'</ns1:skus>';

              l_initStr := l_initStr||l_sku_initStr;

               l_initStr := l_initStr||'</ns1:ODTechService>';

              begin
                l_msg_data := http_post (l_url,l_initStr) ;

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;

           Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                          ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                          ,p_error_msg          =>  l_msg_data);

          END IF; -- Type verification
      -- SR Task Create event

     END IF; -- SR
    /***********************************************************************
        -- Update Task
    ************************************************************************/
    ELSIF l_event_name  = 'oracle.apps.jtf.cac.task.updateTask'  THEN
          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_TYPE_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');
      --    l_user_id              := p_event.GetValueForParameter('USER_ID');

        IF ((l_source_object_code = 'SR') AND (l_source_object_id IS NOT NULL ) ) THEN

             l_event_key  := p_event.GetValueForParameter('TASK_ID');

             FOR get_task_dtls_rec IN get_task_dtls(l_event_key)
                 LOOP
                    IF ((get_task_dtls_rec.source_object_type_code = 'SR') AND
                        (get_task_dtls_rec.source_object_id IS NOT NULL ) ) THEN

                       l_updated_entity_id     := l_event_key ;
                       l_updated_entity_code   := 'SR_TASK' ;
                       l_entity_update_date    := get_task_dtls_rec.last_update_date ;
                       l_entity_activity_code  := 'U' ;
                       l_incident_id           := get_task_dtls_rec.source_object_id ;
                       gn_sr_id                := l_incident_id;
                       l_user_id               := get_task_dtls_rec.last_updated_by ;
                       gc_vendor               := get_task_dtls_rec.vendor;
                       ld_date                 := get_task_dtls_rec.creation_date;
                       lc_category             := get_task_dtls_rec.category;
                       lc_task_name            := get_task_dtls_rec.type_name;
                       l_summary               := get_task_dtls_rec.description;
                       lc_task_descr           := get_task_dtls_rec.task_name;
                    END IF ;

                 BEGIN
                    select ct.name,incident_status_id
                    into lc_type_name, ln_status_id
                    from cs_incidents_all_b cb,
                          cs_incident_types_tl ct
                    where ct.incident_type_id = cb.incident_type_id
                    and   cb.incident_id = l_incident_id;
                  EXCEPTION
                    WHEN OTHERS THEN
                        l_msg_data := 'Error while selecting type name '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                              ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                              ,p_error_msg          =>  l_msg_data);
                  END;
              END LOOP;

            -- Cancel tasks
             FOR get_task_rej_dtls_rec IN get_rej_task_dtls(l_event_key)
                 LOOP
                    IF ((get_task_rej_dtls_rec.source_object_type_code = 'SR') AND
                        (get_task_rej_dtls_rec.source_object_id IS NOT NULL ) ) THEN

                       l_updated_entity_id     := l_event_key ;
                       l_updated_entity_code   := 'SR_TASK' ;
                       l_entity_update_date    := get_task_rej_dtls_rec.last_update_date ;
                       l_entity_activity_code  := 'U' ;
                       l_incident_id           := get_task_rej_dtls_rec.source_object_id ;
                       gn_sr_id                := l_incident_id;
                       l_user_id               := get_task_rej_dtls_rec.last_updated_by ;
                       gc_vendor               := get_task_rej_dtls_rec.vendor;
                       ld_date                 := get_task_rej_dtls_rec.creation_date;
                       lc_category             := get_task_rej_dtls_rec.category;
                       lc_task_name            := get_task_rej_dtls_rec.type_name;
                       l_summary               := get_task_rej_dtls_rec.description;
                       lc_task_descr           := get_task_rej_dtls_rec.task_name;
                       lc_rej_flag             := 'Y';

                       IF gc_vendor = 'Support.com'
                          and LC_CATEGORY = 'S' then
                          lc_item_number    := get_task_rej_dtls_rec.item;
                          IF lc_item_number = '630252' THEN
                            lc_sub_flag := 'Y';
                          END IF;
                       END IF;
                    END IF ;

                 BEGIN
                    select ct.name,cb.incident_status_id,
                           cb.incident_number,
                           lpad(cb.incident_attribute_11,5,0)
                    into lc_type_name, ln_status_id,
                         l_incident_number,
                         l_store_number
                    from cs_incidents_all_b cb,
                          cs_incident_types_tl ct
                    where ct.incident_type_id = cb.incident_type_id
                    and   cb.incident_id = l_incident_id;
                  EXCEPTION
                    WHEN OTHERS THEN
                        l_msg_data := 'Error while selecting type name '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                              ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                              ,p_error_msg          =>  l_msg_data);
                  END;
              END LOOP;


          IF LC_TYPE_NAME LIKE 'TDS%' THEN

              l_msg_data := 'In Update event Inicdent Id '||l_incident_id||' Type '||lc_type_name ;

            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  l_msg_data);

               begin
                  SELECT cs_messages_s.NEXTVAL
                  into gn_msg_id
                  FROM dual;
                end;

                IF lc_rej_flag = 'Y' then
                  gc_action := 'Update';
                else
                  gc_action := 'Create';
                end if;

          IF NVL(LC_REJ_FLAG,'N') = 'N' then
                 -- Determine store code
              BEGIN
                SELECT DESCRIPTION
                INTO LC_STORE_CODE
                FROM FND_LOOKUP_VALUES
                WHERE LOOKUP_TYPE =  'XX_CS_TDS_TASK_CODE'
                AND MEANING = LC_TASK_NAME
                AND END_DATE_ACTIVE IS NULL;
            EXCEPTION
              WHEN OTHERS THEN
                  LC_STORE_CODE := 'Store';
                  L_MSG_DATA := 'Error while selecting store code '||sqlerrm;
                  Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                        ,p_error_message_code =>   'XX_CS_SR04_ERR_LOG'
                        ,p_error_msg          =>  l_msg_data);
            END;

                l_initStr := l_initStr||'<ns1:ODTechService>';

              FOR get_inc_details_rec IN get_inc_details (l_incident_id)
              LOOP
                    IF gc_vendor is null then
                      gc_vendor := 'Support.com';
                    end if;

                    l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',gc_action);
                    l_incident_number		:= get_inc_details_rec.incident_number;
                      l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',l_incident_number);
                    l_store_number  		:= get_inc_details_rec.store_number;
                      l_initStr := l_initStr||Make_Param_Str
                                    ('storeCode',l_store_number);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('comments',l_summary);

                      IF lc_rej_flag = 'Y' THEN
                        l_initStr := l_initStr||Make_Param_Str
                                    ('status', 'Cancel');
                            gc_action := 'Update';

                             -- Comments
                              BEGIN
                                  SELECT  entered_by_name||': '||notes
                                  INTO l_summary
                                  FROM   jtf_notes_vl
                                  WHERE source_object_code = 'SR'
                                  AND   source_object_id = l_incident_id
                                  AND   note_status <> 'P'
                                  AND   rownum < 2
                                  AND   Entered_by_name not in (SELECT UPPER(MEANING)
                                                                 FROM FND_LOOKUP_VALUES
                                                                 WHERE LOOKUP_TYPE = 'XX_CS_TDS_VENDOR_LINK')
                                  order by creation_date desc;
                              EXCEPTION
                                WHEN OTHERS THEN
                                   null;
                              END;

                               l_initStr := l_initStr||Make_Param_Str
                                    ('comments',l_summary);

                      ELSE
                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',null);
                      END IF;

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                        l_customer_id	    := get_inc_details_rec.customer_id;
                        lc_phone_number	    := get_inc_details_rec.phone_number;
                        lc_email_id	    := get_inc_details_rec.email_add;
                        l_aops_cust_id      := get_inc_details_rec.aops_customer_id;
                        ln_que_ans_id       := get_inc_details_rec.qa_id;
                        lc_contact_name     := get_inc_details_rec.contact_name;

                    -- Customer String
                     CUSTOMER_REC (P_CUSTOMER_ID  => L_CUSTOMER_ID,
                                  P_AOPS_CUST_ID  => L_AOPS_CUST_ID,
                                  P_PHONE_NUMBER  => LC_PHONE_NUMBER,
                                  P_EMAIL_ADDRESS => LC_EMAIL_ID,
                                  P_CONTACT_NAME  => LC_CONTACT_NAME,
                                  x_initStr       => l_initStr);

                      -- Device String
                     DEVICE_REC (P_INCIDENT_ID   => L_INCIDENT_ID,
                                  P_DESCRIPTION   => LC_TASK_DESCR,
                                  P_PROB_DESCR    => l_summary,
                                  P_VENDOR        => GC_VENDOR,
                                  x_initStr   => L_INITSTR);
              END LOOP;

              l_sku_initStr := '<ns1:skus>';

              BEGIN
                OPEN get_sku_details;
                LOOP
                FETCH get_sku_details INTO get_sku_details_rec;
                EXIT WHEN get_sku_details%NOTFOUND;
                  I := I + 1;

                  l_sku_initStr := l_sku_initStr||'<ns1:skuData>';

                  IF gc_vendor = 'Support.com'
                     and get_sku_details_rec.sku_category = 'S' then

                       l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('deliveryLocation','Home');

                      l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryParty','None');
                  else
                      l_sku_initStr := l_sku_initStr||Make_Param_Str
                                        ('deliveryLocation',lc_store_code);

                      l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryParty','SprtSE');
                  end if;

                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('skuId',get_sku_details_rec.item_number);

                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('quantity',get_sku_details_rec.quantity);

                  l_sku_initStr := l_sku_initStr||Make_Param_Str
                                    ('description',get_sku_details_rec.item_description);

                  /************************************************************/
                  -- Sku questions Data
                   IF nvl(lc_rej_flag,'N') = 'N' then

                       QA_REC (p_incident_id  => l_incident_id,
                               p_sku         => get_sku_details_rec.item_number,
                               p_que_ans_id  => ln_que_ans_id,
                               x_sku_initStr => l_sku_initStr);
                  END IF;
                 /*************************************************************/

                  l_sku_initStr := l_sku_initStr||'</ns1:skuData>';
                END LOOP;
                close get_sku_details;
              END;

              l_sku_initStr := l_sku_initStr||'</ns1:skus>';
              l_initStr := l_initStr||l_sku_initStr;
              l_initStr := l_initStr||'</ns1:ODTechService>';

              begin
                l_msg_data := http_post (l_url,l_initStr) ;

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;

          /**********************************************************************
           -- Pending (auto rework) tasks
           *********************************************************************/
           BEGIN
              SELECT SOURCE_OBJECT_ID,
                     ATTRIBUTE5
              INTO  L_INCIDENT_ID,
                    LC_CATEGORY
              FROM JTF_TASKS_B
              WHERE TASK_ID = L_EVENT_KEY
              AND  TASK_STATUS_ID = 1;  -- In Planning
          EXCEPTION
             WHEN OTHERS THEN
                L_INCIDENT_ID := NULL;
          END;

           IF l_incident_id is not null and
              lc_category IN ('H','O') THEN

              l_msg_data := 'Before Rework Inicdent Id '||l_incident_id||' Category '||lc_category ;

            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                       ,p_error_message_code =>   'XX_CS_SR011_SUCCESS_LOG'
                       ,p_error_msg          =>  l_msg_data);

             BEGIN
                  SELECT NAME, INCIDENT_STATUS_ID
                  INTO LC_SR_STATUS, LN_SR_STATUS_ID
                  FROM CS_INCIDENT_STATUSES_VL
                  WHERE INCIDENT_SUBTYPE = 'INC'
                  AND NAME  = 'Rework';
                EXCEPTION
                  WHEN OTHERS THEN
                       L_MSG_DATA := 'error while SELECTING status id for Rework ';
                          Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                          ,p_error_message_code =>   'XX_CS_SR010_ERR_LOG'
                                           ,p_error_msg          =>  l_msg_data);
                END;


               IF LN_SR_STATUS_ID IS NOT NULL THEN
                  BEGIN
                      XX_CS_SR_UTILS_PKG.Update_SR_status(p_sr_request_id  => l_incident_id,
                                              p_user_id        => fnd_global.user_id,
                                              p_status_id      => ln_sr_status_id,
                                              p_status         => lc_sr_status,
                                              x_return_status  => l_return_status,
                                              x_msg_data      => l_msg_data);

                            commit;
                   EXCEPTION
                        WHEN OTHERS THEN
                          l_msg_data := 'Error while updating SR status '||sqlerrm ||l_msg_data;
                          Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                          ,p_error_message_code =>   'XX_CS_SR011_ERR_LOG'
                                          ,p_error_msg          =>  l_msg_data);
                   END;
                END IF;  -- SR Status check
          END IF;
              /*************************************************************
              -- End of Rework Tasks
              **************************************************************/

        ELSE -- Reject (cancel subscription).
          -- Subscription Cancellations
            IF lc_sub_flag = 'Y' then

                 CAN_PROC (P_INCIDENT_NUMBER  => L_INCIDENT_NUMBER,
                            P_INCIDENT_ID     => L_INCIDENT_ID,
                            P_STORE_NUMBER    => L_STORE_NUMBER,
                            P_ACTION          => 'CANCEL',
                            X_RETURN_STATUS   => L_RETURN_STATUS,
                            X_RETURN_MESSAGE  => L_MSG_DATA);

                  l_msg_data := 'Subscription Cancellation '||l_msg_data;
                          Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                          ,p_error_message_code =>   'XX_CS_SR012_LOG'
                                          ,p_error_msg          =>  l_msg_data);
            end if;

        END IF; -- Reject.
     END IF; -- Type verification.
     END IF;  -- SR Object
    /**************************************************************************
         Cancellation
     *************************************************************************/
    ELSIF l_event_name  = 'oracle.apps.jtf.cac.task.deleteTask'  THEN

          l_event_key     := p_event.GetValueForParameter('TASK_ID');

          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');
     --     l_user_id              := p_event.GetValueForParameter('USER_ID');

        IF ((l_source_object_code = 'SR') AND (l_source_object_id IS NOT NULL ) ) THEN

          FOR get_task_dtls_rec IN get_task_dtls(l_event_key)
              LOOP
                 IF ((get_task_dtls_rec.source_object_type_code = 'SR') AND
                     (get_task_dtls_rec.source_object_id IS NOT NULL )) THEN

                    l_updated_entity_id     := l_event_key ;
                    l_updated_entity_code   := 'SR_TASK' ;
                    l_entity_update_date    := get_task_dtls_rec.last_update_date ;
                    l_entity_activity_code  := 'D' ;
                    l_incident_id           := get_task_dtls_rec.source_object_id ;
                    gn_sr_id                := l_incident_id;
                    l_user_id               := get_task_dtls_rec.last_updated_by ;

                 END IF ;
              END LOOP ;


            BEGIN
              select ct.name
              into lc_type_name
              from cs_incidents_all_b cb,
                    cs_incident_types_tl ct
              where ct.incident_type_id = cb.incident_type_id
              and   cb.incident_id = l_incident_id;
            END;

            l_msg_data := 'In event Inicdent Id '||l_incident_id||' Type '||lc_type_name ;

            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                       ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                       ,p_error_msg          =>  l_msg_data);

            IF LC_TYPE_NAME LIKE 'TDS%' THEN

                 begin
                    SELECT cs_messages_s.NEXTVAL
                    into gn_msg_id
                    FROM dual;
                  end;

                l_initStr := '<ODTechService>';

                FOR get_inc_details_rec IN get_inc_details (l_incident_id)
                LOOP

                        l_initStr := l_initStr||Make_Param_Str
                                      ('vendor',gc_vendor);

                        l_initStr := l_initStr||Make_Param_Str
                                      ('action','Cancelled');
                        l_incident_number	 := get_inc_details_rec.incident_number;
                        l_initStr := l_initStr||Make_Param_Str
                                      ('serviceId',l_incident_number);
                        l_store_number  := get_inc_details_rec.store_number;
                        l_initStr := l_initStr||Make_Param_Str
                                      ('storeCode',l_store_number);
                        l_summary	:= get_inc_details_rec.summary;

                          l_initStr := l_initStr||Make_Param_Str
                                      ('comments',l_summary);
                          l_initStr := l_initStr||Make_Param_Str
                                      ('status',null);

                           l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                          l_customer_id		:= get_inc_details_rec.customer_id;
                          lc_phone_number	:= get_inc_details_rec.phone_number;
                          lc_email_id		:= get_inc_details_rec.email_add;

                      -- Customer String
                       CUSTOMER_REC (P_CUSTOMER_ID  => L_CUSTOMER_ID,
                                    P_AOPS_CUST_ID  => L_AOPS_CUST_ID,
                                    P_PHONE_NUMBER  => LC_PHONE_NUMBER,
                                    P_EMAIL_ADDRESS => LC_EMAIL_ID,
                                    P_CONTACT_NAME  => NULL,
                                    x_initStr       => l_initStr);

                        -- Device String
                        DEVICE_REC (P_INCIDENT_ID   => L_INCIDENT_ID,
                                  P_DESCRIPTION   => NULL,
                                  P_PROB_DESCR    => NULL,
                                  P_VENDOR        => GC_VENDOR,
                                  x_initStr   => L_INITSTR);

                END LOOP;

                l_sku_initStr := '<skus>';
                BEGIN
                  OPEN get_sku_details;
                  LOOP
                  FETCH get_sku_details INTO get_sku_details_rec;
                  EXIT WHEN get_sku_details%NOTFOUND;

                    l_sku_initStr := l_sku_initStr||'<sku>';
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('skuId',get_sku_details_rec.item_number);
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('name',null);
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('quantity',get_sku_details_rec.quantity);
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('deliveryLocation',l_store_number);
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('status',null);
                    l_sku_initStr := l_sku_initStr||Make_Param_Str
                                      ('description',get_sku_details_rec.item_description);
                    l_sku_initStr := l_sku_initStr||'</sku>';

                  END LOOP;
                  CLOSE get_sku_details;
                END;

                l_sku_initStr := l_sku_initStr||'</skus>';
                l_initStr := l_initStr||l_sku_initStr;
                l_initStr := l_initStr||'</ODTechService>';

                begin
                  l_msg_data := http_post (l_url,l_initStr) ;
                exception
                  when others then
                    l_msg_data := 'In event  '||sqlerrm ;
                     Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                 ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                 ,p_error_msg          =>  l_msg_data);
                end;

            END IF; -- Type verification
        END IF; -- SR object
    /**************************************************************************
       -- Information Update
    ***************************************************************************/
    ELSIF l_event_name  = 'oracle.apps.jtf.cac.notes.create'  THEN

          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');

          IF ((l_source_object_code = 'SR') AND
              (l_source_object_id IS NOT NULL ) ) THEN

              l_event_key     := p_event.GetValueForParameter('NOTE_ID') ;

              FOR get_note_dtls_rec IN get_note_dtls (l_event_key)
              LOOP
                    l_updated_entity_id     := l_event_key ;
                    l_updated_entity_code   := 'SR_NOTE' ;
                    l_entity_update_date    := get_note_dtls_rec.creation_date ;
                    l_entity_activity_code  := 'C' ;
                    l_incident_id           := l_source_object_id ;
                    gn_sr_id                := l_incident_id;
                    l_user_id               := get_note_dtls_rec.last_updated_by ;
                    l_incident_id           := get_note_dtls_rec.source_object_id;
                    lc_comments             := lc_comments||' '||get_note_dtls_rec.notes;

             If l_incident_id is not null then
                  BEGIN
                    select ct.name,cb.incident_status_id,
                            cb.external_attribute_11,
                            cb.external_attribute_12
                    into lc_type_name, ln_status_id,
                          lc_ext_attribute_11,
                          lc_ext_attribute_12
                    from cs_incidents_all_b cb,
                          cs_incident_types_tl ct
                    where ct.incident_type_id = cb.incident_type_id
                    and   cb.incident_id = l_incident_id;
                  EXCEPTION
                    WHEN OTHERS THEN
                        l_msg_data := 'Error while selecting type name '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                      ,p_error_message_code =>   'XX_CS_SR09_ERR_LOG'
                                      ,p_error_msg          =>  l_msg_data);
                  END;
              END if;

              END LOOP;

          IF l_incident_id is not null THEN
           IF LC_TYPE_NAME LIKE 'TDS%' THEN

              l_msg_data := 'In note event Inicdent Id '||l_incident_id||' Type '||lc_type_name ;
               Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                              ,p_error_message_code =>   'XX_CS_SR01_SUCCESS_LOG'
                              ,p_error_msg          =>  l_msg_data);

            IF lc_ext_attribute_11 is not null
               or lc_ext_attribute_12 is not null then
              begin
                update cs_incidents_all_b
                set external_attribute_11 = null,
                    external_attribute_12 = null
                where incident_id = l_incident_id;

                commit;
              exception
                  when others then
                        l_msg_data := 'Error while updating SR '||l_incident_id||' '||sqlerrm;
                        Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                                      ,p_error_message_code =>   'XX_CS_SR09_ERR_LOG'
                                      ,p_error_msg          =>  l_msg_data);
              end;

            end if; -- attribute check
           END IF; -- Type verification.
          END IF; -- incident Id
      END IF ;

    END IF ;      -- end if detect event

RETURN 'SUCCESS';

EXCEPTION
     WHEN e_event_updates THEN
           Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
          WF_CORE.CONTEXT('XX_CS_TDS_VEN_PKG', 'SR_TASK',
                          l_event_name , p_subscription_guid);
          WF_EVENT.setErrorInfo(p_event, 'WARNING');
          return 'WARNING';
     WHEN others THEN
          L_MSG_DATA := 'error in event '||sqlerrm;
            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                             ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                             ,p_error_msg          =>  l_msg_data);
          WF_CORE.CONTEXT('XX_CS_TDS_VEN_PKG', 'SR_TASK',
                          l_event_name , p_subscription_guid);
          WF_EVENT.setErrorInfo(p_event, 'WARNING');
          return 'WARNING';
END SR_TASK;

/*****************************************************************************/
PROCEDURE UPDATE_REQUEST (P_REQUEST_NUMBER  IN VARCHAR2,
                          P_STATUS          IN VARCHAR2,
                          P_VENDOR          IN VARCHAR2,
                          P_COMMENTS        IN VARCHAR2,
                          P_SERVICE_LINK    IN VARCHAR2,
                          P_MESSAGE_ID      IN NUMBER,
                          P_SKU_TBL         IN XX_CS_TDS_SKU_TBL,
                          X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                          X_MSG_DATA        OUT NOCOPY VARCHAR2)
IS

      x_msg_count	          NUMBER;
      x_interaction_id            NUMBER;
      x_workflow_process_id       NUMBER;
      x_msg_index_out             NUMBER;
      ln_obj_ver                  NUMBER;
      ln_object_version           NUMBER;
      lc_sr_status                VARCHAR2(150);
      lc_in_status                varchar2(150);
      ln_status_id                number;  -- update status
      ln_ex_status_id             number; -- existing status
      ln_incident_id              number;
      ln_msg_index                number;
      ln_msg_index_out            number;
      ln_user_id                  number;
      ln_resp_appl_id             number :=  514;
      ln_resp_id                  number := 21739;  -- Customer Support
      i                           number;
      j                           number;
      lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
      lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
      lt_task_notes               jtf_tasks_pub.task_notes_tbl;
      ln_task_status_id           number;
      lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
      lc_message                  VARCHAR2(2000);
      ln_task_id                  NUMBER;
      ln_message_id               number;
      lc_response                 varchar2(250);
      lc_lookup_type              varchar2(250);
      lc_gmil_sku_code            varchar2(25);
      lc_complete_flag            varchar2(25) := 'N';
      lc_comments                 varchar2(2000);
      lc_parts_flag               varchar2(1000);

BEGIN
    BEGIN
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = upper(p_vendor);
    EXCEPTION
      WHEN OTHERS THEN
        ln_user_id := null;
         LC_MESSAGE := 'error while selecting '||p_vendor||' userid '||sqlerrm;
                                    Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                         ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                         ,p_error_msg          =>  LC_MESSAGE);
    END;

    IF ln_user_id is not null then
    -- Responsibility and application id
        BEGIN
          select application_id,
                 responsibility_id
          into ln_resp_appl_id, ln_resp_id
          from fnd_responsibility_tl
          where responsibility_name = 'OD (US) Tech Depot Portal';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 21739;
        END;
    ELSE
      begin
        select user_id
        into ln_user_id
        from fnd_user
        where user_name = 'CS_ADMIN';
      exception
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecting userid '||sqlerrm;
      end;
    END IF;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
   /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number, incident_id,
            external_attribute_6, incident_status_id
     INTO   ln_obj_ver, ln_incident_id, lc_parts_flag, ln_ex_status_id
     FROM   cs_incidents_all_b
     WHERE  incident_number = p_request_number
     AND    incident_context = 'TDS Addl.';
    EXCEPTION
      WHEN OTHERS THEN
           x_return_status := 'F';
           x_msg_data := 'Invalid Request Id';
    END;

    lc_in_status := p_status;

    IF LC_PARTS_FLAG IS NOT NULL AND LC_IN_STATUS = 'PartShipped' THEN
        LC_PARTS_FLAG := 'Parts Shipped '||substr(p_comments,1,60);
    ELSE
        LC_PARTS_FLAG := NULL;
    END IF;

   IF nvl(x_return_status,'S') = 'S' then

     IF ln_incident_id is not NULL then

      IF ln_ex_status_id not in (2,9100) then

      IF LC_IN_STATUS IS NOT NULL THEN
        /********************************************************************
          -- Get status lookup
        *********************************************************************/
        BEGIN
         SELECT DESCRIPTION
         INTO LC_LOOKUP_TYPE
         FROM FND_LOOKUP_VALUES
         WHERE MEANING = P_VENDOR
         AND LOOKUP_TYPE = 'XX_CS_TDS_VEN_LOOPUP';
        EXCEPTION
          WHEN OTHERS THEN
              LC_LOOKUP_TYPE := 'XX_CS_TDS_VEN_STATUS';
        END;
        /*********************************************************************
          -- Get Status
        **********************************************************************/
        BEGIN
           SELECT CL.NAME, CL.INCIDENT_STATUS_ID, FL.TAG
            INTO LC_SR_STATUS, LN_STATUS_ID, LC_COMPLETE_FLAG
            FROM CS_INCIDENT_STATUSES_VL CL,
                 FND_LOOKUP_VALUES FL
            WHERE FL.MEANING = CL.NAME
            AND  CL.INCIDENT_SUBTYPE = 'INC'
            AND  FL.LOOKUP_TYPE = LC_LOOKUP_TYPE
            AND  FL.DESCRIPTION = LC_IN_STATUS
            AND ROWNUM < 2;
        EXCEPTION
          WHEN OTHERS THEN
               LC_MESSAGE := 'error while SELECTING MAPPED STATUS '||LC_IN_STATUS;
                  Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  lc_message);
        END;

      END IF; -- Status parameter verification.


            /*************************************************************************
                  -- Update Service Request and notes
             ************************************************************************/
             IF LN_STATUS_ID IS NOT NULL THEN
                  x_return_status := null;

                    IF P_COMMENTS IS NULL THEN
                    IF LC_IN_STATUS = 'Verifying' then
                      LC_COMMENTS := 'Pending for Associate Wrap Up';
                    else
                     LC_COMMENTS := P_VENDOR||' Updated the Request ';
                    END IF;
                   ELSE
                     IF LC_PARTS_FLAG IS NOT NULL THEN
                       LC_COMMENTS := LC_PARTS_FLAG;
                     ELSE
                      LC_COMMENTS := P_COMMENTS;
                     END IF;
                   END IF;

                   BEGIN
                           lr_service_request_rec.status_id := ln_status_id;
                           lr_service_request_rec.summary := substr(lc_comments,1,60);

                     /*************************************************************************
                     -- Add notes
                      ************************************************************************/

                      lt_notes_table(1).note        := LC_MESSAGE ;
                      lt_notes_table(1).note_detail := P_COMMENTS;
                      lt_notes_table(1).note_type   := 'GENERAL';

                    /**************************************************************************
                          -- Update SR
                    *************************************************************************/

                    cs_servicerequest_pub.Update_ServiceRequest (
                                p_api_version            => 3.0,
                                --p_init_msg_list          => FND_API.G_TRUE,
                               --p_commit                 => FND_API.G_FALSE,
                              --  x_return_status          => x_return_status,
                              --  x_msg_count              => x_msg_count,
                              --  x_msg_data               => x_msg_data,
                                p_request_id             => ln_incident_id,
                                p_service_request_rec    => lr_service_request_rec,
                             --   p_request_number         => NULL,
                             --   p_audit_comments         => NULL,
                                p_object_version_number  => ln_obj_ver,
                                 p_notes                  => lt_notes_table,
                                p_contacts               => lt_contacts_tab,
                               -- p_resp_appl_id           => NULL,
                               -- p_resp_id                => NULL,
                                p_last_updated_by        => NULL,
                                p_last_update_login      => NULL,
                                p_last_update_date       => sysdate,
                                p_resp_appl_id           => NULL,
                                p_resp_id                => NULL,
                                x_return_status          => x_return_status,
                                x_msg_count              => x_msg_count,
                                x_msg_data               => x_msg_data,
                           --     p_service_request_rec    => lr_service_request_rec,
                             --   p_notes                  => lt_notes_table,
                             --   p_contacts               => lt_contacts_tab,
                               -- p_called_by_workflow     => FND_API.G_FALSE,
                              --  p_workflow_process_id    => NULL,
                                x_workflow_process_id    => x_workflow_process_id,
                                x_interaction_id         => x_interaction_id   );

                                  commit;

                  -- Check errors
                   IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                      IF (FND_MSG_PUB.Count_Msg > 1) THEN
                        --Display all the error messages
                          FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                  FND_MSG_PUB.Get(
                                            p_msg_index => j,
                                            p_encoded => 'F',
                                            p_data => x_msg_data,
                                            p_msg_index_out => ln_msg_index_out);

                                --DBMS_OUTPUT.PUT_LINE(x_msg_data);
                          END LOOP;
                        ELSE
                                    --Only one error
                                FND_MSG_PUB.Get(
                                            p_msg_index => 1,
                                            p_encoded => 'F',
                                            p_data => x_msg_data,
                                            p_msg_index_out => ln_msg_index_out);
                        END IF;
                        x_msg_data := 'error while update sr '||x_msg_data;
                         Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  X_MSG_DATA);
                    END IF;
                 EXCEPTION
                   WHEN OTHERS THEN
                      x_msg_data := 'error while calling ipdate status ';
                         Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                ,p_error_message_code =>   'XX_CS_SR02a_ERR_LOG'
                                 ,p_error_msg          =>  X_MSG_DATA);
                END;
               END IF;
             /***************************************************************
                 Task Update with SKU information
             ***************************************************************/
                   I := p_sku_tbl.first;
                     IF I IS NOT NULL THEN
                     LOOP
                                  /**********************************************
                                      -- Get SKU task id
                                  **********************************************/
                                    BEGIN
                                      SELECT TASK_ID
                                      INTO  LN_TASK_ID
                                      FROM JTF_TASKS_B
                                      WHERE SOURCE_OBJECT_TYPE_CODE = 'SR'
                                      AND   SOURCE_OBJECT_ID = LN_INCIDENT_ID
                                      AND   ATTRIBUTE1 = P_VENDOR
                                      AND   TASK_STATUS_ID NOT IN (8,11)
                                      AND   ATTRIBUTE6 = P_SKU_TBL(I).SKU_ID
                                      AND   ROWNUM < 2;
                                    EXCEPTION
                                      WHEN OTHERS THEN
                                        LN_TASK_ID := NULL;
                                    END;
                                    -- Update SKU Task ----
                                    IF LN_TASK_ID IS NOT NULL THEN
                                     -- Get task status id
                                      BEGIN
                                        select jt.task_status_id, fl.tag
                                        into  ln_task_status_id,lc_gmil_sku_code
                                        from fnd_lookup_values fl,
                                             jtf_task_statuses_tl jt
                                        where fl.lookup_type = 'XX_CS_TDS_SKU_STATUS'
                                        and   jt.name = fl.description
                                        and   fl.meaning = p_sku_tbl(i).attribute1;
                                      EXCEPTION
                                        WHEN OTHERS THEN
                                          ln_task_status_id := 15;
                                          lc_gmil_sku_code  := 'NS';
                                           LC_MESSAGE := 'error while selecting task status '||p_sku_tbl(i).attribute1||' ; '||sqlerrm;
                                           Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                                         ,p_error_message_code =>   'XX_CS_SR05_ERR_LOG'
                                                         ,p_error_msg          =>  LC_MESSAGE);
                                      END;

                                      -- Update task
                                     IF LN_TASK_STATUS_ID IS NOT NULL THEN

                                     IF LENGTH(P_SKU_TBL(I).ATTRIBUTE2) > 4000 THEN
                                        LT_TASK_NOTES(1).NOTES_DETAIL := P_SKU_TBL(I).ATTRIBUTE2;
                                        LT_TASK_NOTES(1).NOTES := 'SKU Report Details';
                                     ELSE
                                        LT_TASK_NOTES(1).NOTES := P_SKU_TBL(I).ATTRIBUTE2;
                                     END IF;
                                       /**********************************************************************
                                         -- Update Task
                                       ************************************************************************/
                                       x_msg_data := 'before task update for SKU : '||P_SKU_TBL(I).SKU_ID||' R_id '||ln_incident_id||' S_id '||ln_task_status_id||'Att: '||substr(LT_TASK_NOTES(1).NOTES,1,50);
                                          Log_Exception ( p_error_location      => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                                         ,p_error_message_code =>  'XX_CS_SR01_SUCCESS_LOG'
                                                         ,p_error_msg          =>  X_MSG_DATA);

                                        x_msg_data := null;

                                       XX_CS_SR_TASK.Update_TDS_Task ( P_REQUEST_ID  => LN_INCIDENT_ID,
                                                                       P_TASK_ID     => LN_TASK_ID,
                                                                       P_VENDOR       => NULL,
                                                                       P_STATUS       => LN_TASK_STATUS_ID,
                                                                       P_NOTES_TBL    => LT_TASK_NOTES,
                                                                       X_RETURN_STATUS => X_RETURN_STATUS,
                                                                       X_MSG_DATA      => X_MSG_DATA);

                                      END IF; -- TASK STATUS ID
                                   END IF; -- Task id
                                    -- end of SKU Task update --
                              /******************************************
                              -- update GMill SKU table
                              ******************************************/
                              begin
                                update xx_cs_ies_sku_relations
                                set status = lc_gmil_sku_code
                                where sku = p_sku_tbl(i).sku_id
                                and request_id = ln_incident_id;
                                commit;
                              exception
                                when others then
                                    LC_MESSAGE := 'error while updating xx_cs_ies_sku_relations '||sqlerrm;
                                    Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                         ,p_error_message_code =>   'XX_CS_SR06_ERR_LOG'
                                         ,p_error_msg          =>  LC_MESSAGE);
                              end;

                              /******************************************
                              -- update SKU table if service rejected
                              ******************************************/
                              IF LN_TASK_STATUS_ID = 4 THEN
                                begin
                                  update xx_cs_sr_items_link
                                  set quantity = 0
                                  where item_number = p_sku_tbl(i).sku_id
                                  and service_request_id = ln_incident_id;
                                  commit;
                                exception
                                  when others then
                                      LC_MESSAGE := 'error while updating xx_cs_sr_items_link '||sqlerrm;
                                      Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                           ,p_error_message_code =>   'XX_CS_SR08_ERR_LOG'
                                           ,p_error_msg          =>  LC_MESSAGE);
                                end;
                              end if;
                              --------
                          EXIT WHEN I = p_sku_tbl.last;
                          I := p_sku_tbl.NEXT(I);
                          end loop;
                     END IF;  -- end of SKU check
                  /****************************************************
                     -- Update SKU Status;
                  ****************************************************/
                  IF LC_COMPLETE_FLAG = 'Y' THEN
                         LN_TASK_STATUS_ID := 14; -- Assigned
                       /**********************************************************************
                         -- Update SR
                       ************************************************************************/
                         XX_CS_SR_TASK.Update_TDS_Task ( P_REQUEST_ID  => LN_INCIDENT_ID,
                                                         P_TASK_ID     => NULL,
                                                         P_VENDOR      => P_VENDOR,
                                                         P_STATUS      => LN_TASK_STATUS_ID,
                                                         P_NOTES_TBL   => LT_TASK_NOTES,
                                                         X_RETURN_STATUS => X_RETURN_STATUS,
                                                         X_MSG_DATA      => X_MSG_DATA);
                  END IF;

              end if; -- Close Status check
                  /****************************************************
                   -- Update comments
                   ****************************************************/

                 /*  UPDATE_COMMENTS (P_REQUEST_NUMBER,
                                   P_VENDOR,
                                   LC_COMMENTS,
                                   X_RETURN_STATUS,
                                   X_MSG_DATA);
                   COMMIT;    */
                  -----------------End of update comments --------------

    end if; -- incident_id check

   ELSE -- NOT TDS REQUEST
       IF upper(p_vendor) = 'BARRISTER' THEN

         X_MSG_DATA      := NULL;
         X_RETURN_STATUS := NULL;
         XX_CS_MPS_VEN_PKG.UPDATE_REQUEST (P_REQUEST_NUMBER,
                                            P_STATUS ,
                                            P_VENDOR,
                                            P_COMMENTS,
                                            P_SERVICE_LINK,
                                            P_MESSAGE_ID,
                                            P_SKU_TBL,
                                            X_RETURN_STATUS,
                                            X_MSG_DATA);
      END IF;
   END IF; --x_status check

   /********************************************************************
   ********************************************************************/
    IF nvl(x_return_status,'S') = 'S' then
        X_MSG_DATA      := 'Request Updated Successfully';
        X_RETURN_STATUS := 'S';
    END IF;


 EXCEPTION
   WHEN OTHERS THEN
      LC_MESSAGE := X_MSG_DATA;
          Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                       ,p_error_message_code =>   'XX_CS_SR07_ERR_LOG'
                       ,p_error_msg          =>  LC_MESSAGE);

END;
/****************************************************************************/
/*****************************************************************************/
PROCEDURE OUTBOUND_ACK (P_REQUEST_NUMBER  IN VARCHAR2,
                        P_VENDOR          IN VARCHAR2,
                        P_COMMENTS        IN VARCHAR2,
                        P_SERVICE_LINK    IN VARCHAR2,
                        P_MESSAGE_ID      IN NUMBER,
                        X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                        X_MSG_DATA        OUT NOCOPY VARCHAR2)
IS

      x_msg_count	                NUMBER;
      x_interaction_id            NUMBER;
      x_workflow_process_id       NUMBER;
      x_msg_index_out             NUMBER;
      ln_obj_ver                  NUMBER;
      ln_incident_id              number;
      ln_msg_index                number;
      ln_msg_index_out            number;
      ln_user_id                  number;
      ln_resp_appl_id             number :=  514;
      ln_resp_id                  number := 21739;  -- Customer Support
      i                           number;
      j                           number;
      lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
      lt_task_notes               jtf_tasks_pub.task_notes_tbl;
      ln_task_status_id           number;
      lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
      lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
      lc_message                  VARCHAR2(2000);
      lc_task_flag                VARCHAR2(1) := 'N';
      ln_message_id               number;
      lc_response                 varchar2(2000);
      lc_link                     varchar2(250);
      lc_url                      varchar2(500);
      ln_status_id                number;
      lc_status                   varchar2(250);
      lc_support_url              varchar2(250);
      lc_nexicore_url             varchar2(250);
      ln_type_id                  number;
      lc_type_name                varchar2(250);
      lc_task_type                varchar2(1);
      lc_parts_link               varchar2(1000);
      LC_PARTS_FLAG               varchar2(1) := 'N';
      L_ESD_SKU_COUNT             number;
      LN_TASK_ID                  number;
      ln_esd_task_status_id           number;

BEGIN
    -- VENDOR USER ID
    BEGIN
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = upper(p_vendor);
    EXCEPTION
      WHEN OTHERS THEN
        ln_user_id := null;
    END;

    IF ln_user_id is not null then
    -- Responsibility and application id
        BEGIN
          select application_id,
                 responsibility_id
          into ln_resp_appl_id, ln_resp_id
          from fnd_responsibility_tl
          where responsibility_name = 'OD (US) Tech Depot Portal';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 21739;
        END;
    ELSE
      begin
        select user_id
        into ln_user_id
        from fnd_user
        where user_name = 'CS_ADMIN';
      exception
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecting userid '||sqlerrm;
      end;
    END IF;

   /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT object_version_number,
            incident_id,
            incident_status_id,
            incident_type_id,
            external_attribute_6
     INTO   ln_obj_ver,
            ln_incident_id,
            ln_status_id,
            ln_type_id,
            lc_parts_link
     FROM   cs_incidents_all_b
     WHERE  incident_number = p_request_number
     AND    incident_context = 'TDS Addl.';
    EXCEPTION
      WHEN OTHERS THEN
           x_return_status := 'F';
           x_msg_data := 'Invalid Request Id';
    END;

    /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    cs_servicerequest_pub.initialize_rec( lr_service_request_rec );

    /*******************************************************************/

   IF nvl(x_return_status,'S') = 'S' then

    IF ln_incident_id is not NULL then

          IF p_comments is null then
             lc_message := 'Response received from '||p_vendor;
          ELSE
            IF lc_parts_link is not null then
                lc_parts_flag := 'Y';
                IF p_comments like 'Dispatch%' then
                    lc_message := 'Parts Ordered successfully';
                  IF p_comments like '%Cancellation%' then
                    lc_message := 'Parts Order Cancelled successfully';
                  END IF;
                elsif p_comments like 'Return%' then
                   lc_message       := 'Parts Returned successfully';
                   LC_NEXICORE_URL  := 'http://depot.nexicore.com/labels/od/'||p_request_number||'.html';
                   /**********************************************************
                      -- Update shipping label link for return items
                    **********************************************************/
                    lr_service_request_rec.external_attribute_15 := lc_nexicore_url;

                    /*********************************************************/
                else
                  lc_message := ' Response, '||p_comments;
                end if;
            else
                lc_message := ' Response, '||p_comments;
            end if;

          end if;
            lc_response := lc_message;
            lr_service_request_rec.summary := lc_message;
                   -- Update links
               IF nvl(x_return_status,'S') = 'S' then
                  IF p_service_link is not null then
                      --
                        IF p_vendor = 'Support.com' then
                            -- Selecting link
                            BEGIN
                              SELECT DESCRIPTION||P_SERVICE_LINK||TAG
                              INTO LC_SUPPORT_URL
                              FROM FND_LOOKUP_VALUES
                              WHERE LOOKUP_TYPE = 'XX_CS_TDS_VENDOR_LINK'
                              AND MEANING = P_VENDOR;
                            EXCEPTION
                              WHEN OTHERS THEN
                               LC_SUPPORT_URL := 'https://officedepot.support.com/rang/download?tid='||p_service_link||'&view=chat&isassociate=true';
                               LC_MESSAGE := 'Error while SELECTING connection url '||sqlerrm;
                                    Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                           ,p_error_message_code =>   'XX_CS_SR06A_ERR_LOG'
                                           ,p_error_msg          =>  LC_MESSAGE);
                            END;
                              lr_service_request_rec.external_attribute_14 := lc_support_url;
                              lr_service_request_rec.summary := lc_message;

                        else
                           IF NVL(LC_PARTS_FLAG,'N') = 'N' THEN
                               begin
                                select attribute5
                                into lc_task_type
                                from jtf_tasks_b
                                where source_object_id = ln_incident_id
                                and task_status_id = 14
                                and attribute1 = p_vendor
                                and rownum < 2;
                               exception
                                 when others then
                                    LC_MESSAGE := 'Error while SELECTING task name '||p_request_number||' '||sqlerrm;
                                        Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                               ,p_error_message_code =>   'XX_CS_SR06C_ERR_LOG'
                                               ,p_error_msg          =>  LC_MESSAGE);
                                end;
                            END IF;

                                IF NVL(LC_TASK_TYPE,'N') = 'C' THEN
                                    BEGIN
                                      SELECT DESCRIPTION||P_SERVICE_LINK||TAG
                                      INTO LC_NEXICORE_URL
                                      FROM FND_LOOKUP_VALUES
                                      WHERE LOOKUP_TYPE = 'XX_CS_TDS_VENDOR_LINK'
                                      AND MEANING = P_VENDOR;
                                    EXCEPTION
                                      WHEN OTHERS THEN
                                       LC_NEXICORE_URL := 'http://66.179.191.204/odpshiplabel/'||p_service_link||'.gif';
                                       LC_MESSAGE := 'Error while SELECTING SHIPPING url '||sqlerrm;
                                            Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                                   ,p_error_message_code =>   'XX_CS_SR06B_ERR_LOG'
                                                   ,p_error_msg          =>  LC_MESSAGE);
                                    END;

                                   lr_service_request_rec.external_attribute_15 := lc_nexicore_url;
                                   lr_service_request_rec.summary := lc_message;

                                END IF;  -- Task type
                        end if;  -- Vendor
                      ----
                  END IF;
               END IF;

                ---------------------------------------------
                -- Update with links to request
                ---------------------------------------------

                    /*************************************************************************
                     -- Add notes
                      ************************************************************************/

                      lt_notes_table(1).note        := LC_MESSAGE ;
                      lt_notes_table(1).note_detail := P_COMMENTS;
                      lt_notes_table(1).note_type   := 'GENERAL';

                    /**************************************************************************
                          -- Update SR
                    *************************************************************************/

                        cs_servicerequest_pub.Update_ServiceRequest (
                                p_api_version            => 3.0,
                                p_request_id             => ln_incident_id,
                                p_service_request_rec    => lr_service_request_rec,
                                p_object_version_number  => ln_obj_ver,
                                p_notes                  => lt_notes_table,
                                p_contacts               => lt_contacts_tab,
                                p_last_updated_by        => NULL,
                                p_last_update_login      => NULL,
                                p_last_update_date       => sysdate,
                                p_resp_appl_id           => NULL,
                                p_resp_id                => NULL,
                                x_return_status          => x_return_status,
                                x_msg_count              => x_msg_count,
                                x_msg_data               => x_msg_data,
                                x_workflow_process_id    => x_workflow_process_id,
                                x_interaction_id         => x_interaction_id   );

                                  commit;

                         IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                            IF (FND_MSG_PUB.Count_Msg > 1) THEN
                               --Display all the error messages
                               FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
                                  FND_MSG_PUB.Get(p_msg_index     => j,
                                                  p_encoded       => 'F',
                                                  p_data          => x_msg_data,
                                                  p_msg_index_out => x_msg_index_out);
                               END LOOP;
                            ELSE      --Only one error
                               FND_MSG_PUB.Get(
                                  p_msg_index     => 1,
                                  p_encoded       => 'F',
                                  p_data          => x_msg_data,
                                  p_msg_index_out => x_msg_index_out);

                            END IF;
                            x_return_status := x_return_status;
                            x_msg_data := substr(x_msg_data,1,200);
                         END IF;


                         IF NVL(X_RETURN_STATUS,'S')  <> 'S' THEN
                                 begin
                                      update cs_incidents_all_b
                                      set external_attribute_14 = lc_support_url,
                                          external_attribute_15 = lc_nexicore_url
                                      where incident_id = ln_incident_id;
                                        commit;
                                    exception
                                      when others then
                                       LC_MESSAGE := 'Error while update with shipping label link '||sqlerrm;
                                       Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_REQUEST'
                                                      ,p_error_message_code =>   'XX_CS_SR07_ERR_LOG'
                                                      ,p_error_msg          =>  LC_MESSAGE);

                                    end;
                                  --- Log original error message from API call
                                   Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                                    ,p_error_message_code =>   'XX_CS_SR06F_LOG_LOG'
                                                    ,p_error_msg          => X_MSG_DATA);

                         END IF;
        ----------------------------------------------
            -- Update messages table
        ----------------------------------------------
              IF p_message_id is not null then
                  -- update response to message table
                  begin
                    update cs_messages
                    set responder = p_vendor,
                        response_date = sysdate,
                        response = 'ACKNOWLEDGE',
                        responder_comment = nvl(lc_support_url,p_comments)
                    where message_id = p_message_id;

                    commit;
                  exception
                    when others then
                      LC_MESSAGE := 'error while updating cs_messages '||sqlerrm;
                            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                            ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                             ,p_error_msg          =>  lc_message);
                  end;
              end if;
          ---------------------------------------
            -- Status verification
          ---------------------------------------
          begin
            select name
            into lc_status
            from cs_incident_statuses_vl
            where incident_status_id = ln_status_id
            and   incident_subtype = 'INC';
         exception
            when others then
              LC_MESSAGE := 'error while selecting status '||sqlerrm;
                            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                            ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                             ,p_error_msg          =>  lc_message);
        end;

/* Digital Locker Code Change */
    IF NVL(X_RETURN_STATUS,'S') = 'S' THEN
      IF P_SERVICE_LINK is not null then
        BEGIN
          SELECT COUNT(TASK_ID), TASK_ID
          INTO l_esd_sku_count, ln_task_id 
          FROM JTF_TASKS_VL VL
          WHERE 1            =1
          AND VL.ATTRIBUTE1  ='Image Micro'
          AND vl.attribute6 IN
            (SELECT XFTV.SOURCE_VALUE1
            FROM XX_FIN_TRANSLATEDEFINITION XFTD ,
              XX_FIN_TRANSLATEVALUES XFTV
            WHERE XFTD.TRANSLATE_ID   = XFTV.TRANSLATE_ID
            AND XFTD.TRANSLATION_NAME = 'ESD_SKU_DETAILS'
            AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1)
            AND SYSDATE BETWEEN XFTD.START_DATE_ACTIVE AND NVL(XFTD.END_DATE_ACTIVE,SYSDATE+1)
            AND XFTV.ENABLED_FLAG = 'Y'
            AND XFTD.ENABLED_FLAG = 'Y'
            )
          and VL.TASK_STATUS_ID <> 14
          and VL.SOURCE_OBJECT_ID = LN_INCIDENT_ID
          AND ROWNUM             <2 
          GROUP BY task_id;
          EXCEPTION
            WHEN OTHERS THEN
              LC_MESSAGE := 'Error while selecting Digital SKU Image Micro Task '||sqlerrm;
                            Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                                            ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                             ,p_error_msg          =>  lc_message);
        END;
        
        IF L_ESD_SKU_COUNT   > 0 THEN
          LN_ESD_TASK_STATUS_ID := 14; -- Assigned
          XX_CS_SR_TASK.Update_TDS_Task ( P_REQUEST_ID  => LN_INCIDENT_ID,
                                                   P_TASK_ID     => ln_task_id,
                                                   P_VENDOR      => P_VENDOR,
                                                   P_STATUS      => LN_ESD_TASK_STATUS_ID,
                                                   P_NOTES_TBL   => LT_TASK_NOTES,
                                                   X_RETURN_STATUS => X_RETURN_STATUS,
                                                   X_MSG_DATA      => X_MSG_DATA);
        END IF;
     END IF;
  END IF;
  /* End of Digital Locker Code Change */
                

        if LC_STATUS = 'Verified' then
        -- Release other tasks at verified status
                LN_TASK_STATUS_ID := 14; -- Assigned
                ln_task_id := null;
                /**********************************************************************
                     -- Update SR
                 ************************************************************************/
                   XX_CS_SR_TASK.Update_TDS_Task ( P_REQUEST_ID  => LN_INCIDENT_ID,
                                                   P_TASK_ID     => ln_task_id,
                                                   P_VENDOR      => P_VENDOR,
                                                   P_STATUS      => LN_TASK_STATUS_ID,
                                                   P_NOTES_TBL   => LT_TASK_NOTES,
                                                   X_RETURN_STATUS => X_RETURN_STATUS,
                                                   X_MSG_DATA      => X_MSG_DATA);

        END IF;  -- Verified status

    end if; -- incident_id check

      IF nvl(x_return_status,'S') = 'S' then
         X_MSG_DATA      := 'Acknowledgment updated Successfully';
         X_RETURN_STATUS := 'S';
      END IF;

   ELSE -- not TDS request
       -- Mps Case Calls separated.
    IF upper(p_vendor) = 'BARRISTER' THEN

         X_MSG_DATA      := NULL;
         X_RETURN_STATUS := NULL;
         XX_CS_MPS_VEN_PKG.OUTBOUND_ACK (P_REQUEST_NUMBER,
                                          P_VENDOR,
                                          P_COMMENTS,
                                          P_SERVICE_LINK,
                                          P_MESSAGE_ID,
                                          X_RETURN_STATUS,
                                          X_MSG_DATA );
    END IF;

  END IF;
  EXCEPTION
      WHEN OTHERS THEN
           LC_MESSAGE := X_MSG_DATA;
                Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_ACK'
                       ,p_error_message_code =>   'XX_CS_SR05_ERR_LOG'
                       ,p_error_msg          =>  LC_MESSAGE);

END;
/*****************************************************************************
/*****************************************************************************/
PROCEDURE UPDATE_COMMENTS (P_REQUEST_NUMBER  IN VARCHAR2,
                           P_VENDOR          IN VARCHAR2,
                           P_COMMENTS        IN VARCHAR2,
                           X_RETURN_STATUS   OUT NOCOPY VARCHAR2,
                           X_MSG_DATA        OUT NOCOPY VARCHAR2)
IS

ln_user_id                  number;
ln_incident_id              number;
ln_resp_appl_id             number :=  514;
ln_resp_id                  number := 21739;  -- Customer Support
ln_api_version		          number;
lc_init_msg_list	          varchar2(1);
ln_validation_level	        number;
lc_commit		                varchar2(1);
lc_return_status	          varchar2(1);
ln_msg_count		            number;
lc_msg_data		              varchar2(2000);
ln_jtf_note_id		          number;
ln_source_object_id	        number;
lc_source_object_code	      varchar2(8);
lc_note_status              varchar2(8);
lc_note_type		            varchar2(80);
lc_notes		                varchar2(2000);
lc_notes_detail		          varchar2(8000);
ld_last_update_date	        Date;
ln_last_updated_by	        number;
ld_creation_date	          Date;
ln_created_by		            number;
ln_entered_by               number;
ld_entered_date             date;
ln_last_update_login        number;
lt_note_contexts	          JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
ln_msg_index		            number;
ln_msg_index_out	          number;
lc_message                  varchar2(150);

BEGIN
    BEGIN
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = upper(p_vendor);
    EXCEPTION
      WHEN OTHERS THEN
        ln_user_id := null;
    END;

    IF ln_user_id is not null then
    -- Responsibility and application id
        BEGIN
          select application_id,
                 responsibility_id
          into ln_resp_appl_id, ln_resp_id
          from fnd_responsibility_tl
          where responsibility_name = 'OD (US) Tech Depot Portal';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 21739;
        END;
    ELSE
      begin
        select user_id
        into ln_user_id
        from fnd_user
        where user_name = 'CS_ADMIN';
      exception
        when others then
          x_return_status := 'F';
          x_msg_data := 'Error while selecting userid '||sqlerrm;
      end;
    END IF;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

   /************************************************************************
    -- Get Object version
    *********************************************************************/
    BEGIN
     SELECT incident_id
     INTO   ln_incident_id
     FROM   cs_incidents_all_b
     WHERE  incident_number = p_request_number
     AND    incident_context = 'TDS Addl.';
    EXCEPTION
      WHEN OTHERS THEN
           x_return_status := 'F';
           x_msg_data := 'Invalid Request Id';
    END;

   IF ln_incident_id is not NULL then

      /************************************************************************
       --Initialize the Notes parameter to create
       **************************************************************************/
              ln_api_version		:= 1.0;
              lc_init_msg_list		:= FND_API.g_true;
              ln_validation_level	:= FND_API.g_valid_level_full;
              lc_commit			:= FND_API.g_true;
              ln_msg_count		:= 0;

              /****************************************************************************/
              ln_source_object_id	:= ln_incident_id;
              lc_source_object_code	:= 'SR';
              lc_note_status		:= 'I';  -- (P-Private, E-Publish, I-Public)
              lc_note_type		:= 'GENERAL';
              IF length(p_comments) < 2000 then
                lc_notes	:= p_comments;
              else
                lc_notes	:= p_vendor||' updates ';
              end if;
              lc_notes_detail		:= p_comments;

              ln_entered_by	        := ln_user_id;
              ln_created_by	        := ln_user_id;
              ld_entered_date	        := SYSDATE;
              ld_last_update_date       := SYSDATE;
              ln_last_updated_by        := ln_user_id;
              ld_creation_date		:= SYSDATE;
              ln_last_update_login	:= FND_GLOBAL.LOGIN_ID;
              /******************************************************************************
              -- Call Create Note API
              *******************************************************************************/
              JTF_NOTES_PUB.create_note (p_api_version        => ln_api_version,
                                      p_init_msg_list         => lc_init_msg_list,
                                      p_commit                => lc_commit,
                                      p_validation_level      => ln_validation_level,
                                      x_return_status         => lc_return_status,
                                      x_msg_count             => ln_msg_count ,
                                      x_msg_data              => lc_msg_data,
                                      p_jtf_note_id	      => ln_jtf_note_id,
                                      p_entered_by            => ln_entered_by,
                                      p_entered_date          => ld_entered_date,
                                      p_source_object_id      => ln_source_object_id,
                                      p_source_object_code    => lc_source_object_code,
                                      p_notes		      => lc_notes,
                                      p_notes_detail	      => lc_notes_detail,
                                      p_note_type	      => lc_note_type,
                                      p_note_status	      => lc_note_status,
                                      p_jtf_note_contexts_tab => lt_note_contexts,
                                      x_jtf_note_id	      => ln_jtf_note_id,
                                      p_last_update_date      => ld_last_update_date,
                                      p_last_updated_by	      => ln_last_updated_by,
                                      p_creation_date	      => ld_creation_date,
                                      p_created_by	      => ln_created_by,
                                      p_last_update_login     => ln_last_update_login );

                  -- check for errors
                    IF (lc_return_status <> FND_API.G_RET_STS_SUCCESS) then
                        IF (FND_MSG_PUB.Count_Msg > 1) THEN
                        --Display all the error messages
                          FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                                  FND_MSG_PUB.Get(
                                            p_msg_index => j,
                                            p_encoded => 'F',
                                            p_data => lc_msg_data,
                                            p_msg_index_out => ln_msg_index_out);
                          END LOOP;
                        ELSE
                                    --Only one error
                                FND_MSG_PUB.Get(
                                            p_msg_index => 1,
                                            p_encoded => 'F',
                                            p_data => lc_msg_data,
                                            p_msg_index_out => ln_msg_index_out);
                        END IF;
                    END IF;

         LC_MESSAGE := 'after NOTES update '||ln_incident_id;
         Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.UPDATE_COMMENTS'
                              ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                               ,p_error_msg          =>  lc_message);


     ELSE -- NOT TDS REQUEST
       IF upper(p_vendor) = 'BARRISTER' THEN

         X_MSG_DATA      := NULL;
         X_RETURN_STATUS := NULL;
         XX_CS_MPS_VEN_PKG.UPDATE_COMMENTS (P_REQUEST_NUMBER,
                                           P_VENDOR,
                                           P_COMMENTS,
                                           X_RETURN_STATUS,
                                           X_MSG_DATA);
        END IF;


    end if; -- incident_id check

      IF nvl(lc_return_status,'S') = 'S' then
              x_return_status := 'S';
              X_MSG_DATA := 'Request Updated Successfully';
      else
            x_return_status := lc_return_status;
            x_msg_data      := lc_msg_data;
      END IF;


  EXCEPTION
      WHEN OTHERS THEN
           X_MSG_DATA := lc_msg_data;
                Log_Exception ( p_error_location => 'XX_CS_TDS_VEN_PKG.UPDATE_COMMENTS'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  LC_msg_data);

END;
/*****************************************************************************/
 PROCEDURE CAN_PROC (P_INCIDENT_NUMBER IN VARCHAR2,
                     P_INCIDENT_ID     IN NUMBER,
                     P_STORE_NUMBER    IN VARCHAR2,
                       P_ACTION          IN VARCHAR2,
                       X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                       X_RETURN_MESSAGE  IN OUT NOCOPY VARCHAR2) AS

  l_initStr         VARCHAR2(30000);
  l_url             VARCHAR2(2000);
  LC_SUB_STATUS     VARCHAR2(100);
  LC_SUB_KEY_TYPE   VARCHAR2(100);
  ln_sub_id         NUMBER;
  lc_action         VARCHAR2(50);
  lc_message        varchar2(1000);
  lc_order_flag     varchar2(1) := 'N';

  BEGIN

     BEGIN
           select fnd_profile.value('XX_B2B_WEB_URL')
           into l_url
           from dual;
       exception
           when others then
              l_url := null;
              x_return_message := 'Valid B2B URL is not setup';
              x_return_status  := 'E';
       END;

            begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;

     GN_SR_ID   := P_INCIDENT_ID;
     GC_VENDOR  := 'Support.com';

     -- Finding remaining tasks.
     BEGIN
        SELECT 'Y'
        INTO lc_order_flag
        FROM jtf_tasks_vl tt
        WHERE tt.source_object_id = p_incident_id
        AND  tt.attribute5 = 'R'
        AND  tt.source_object_type_code = 'SR'
        AND  tt.Attribute1 = 'Support.com'
        AND  rownum <2;
     EXCEPTION
       WHEN OTHERS THEN
         LC_ORDER_FLAG := 'N';
    END;

    -- Build InitStr
     l_initStr := l_initStr||'<ns1:ODTechService>';

     l_initStr := l_initStr||Make_Param_Str
                     ('vendor',gc_vendor);

     l_initStr := l_initStr||Make_Param_Str
                     ('serviceId',p_incident_number);

     l_initStr := l_initStr||Make_Param_Str
                     ('storeCode',p_store_number);

      l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

      l_initStr := l_initStr||Make_Param_Str
                                    ('status','Cancel');

    IF NVL(LC_ORDER_FLAG,'N') = 'N' THEN

              LC_ACTION  := 'Update';

                 l_initStr := l_initStr||Make_Param_Str
                       ('action',lc_action);

                   l_initStr := l_initStr||Make_Param_Str
                                    ('comments','Order Cancelled');

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',sysdate);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('author',p_store_number);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryLocation','Store');

                      l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryParty','SprtSE');

    ELSE
             LC_ACTION  := 'Subscription';

             l_initStr := l_initStr||Make_Param_Str
                       ('action',lc_action);

             l_initStr := l_initStr||'<ns1:subscription>';

             l_initStr := l_initStr||Make_Param_Str
                                  ('subscriptionKey',p_incident_number);

              lc_sub_key_type := 'WorkOrder';
             l_initStr := l_initStr||Make_Param_Str
                                  ('subscriptionKeyType',lc_sub_key_type);


            l_initStr := l_initStr||Make_Param_Str
                                  ('status','Cancelled');

            l_initStr := l_initStr||Make_Param_Str
                                  ('message','Subscription is Cancelled.');


            l_initStr := l_initStr||'</ns1:subscription>';


    END IF;

          l_initStr := l_initStr||'</ns1:ODTechService>';

           begin
                x_return_message := http_post (l_url,l_initStr) ;

              exception
                when others then
                  x_return_message := 'In event  '||sqlerrm;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.CAN_PROC'
                               ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                               ,p_error_msg          =>  x_return_message);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;



           lc_message := 'Cancellation Of subscription '||p_action||'-'||p_incident_number;
           Log_Exception ( p_error_location     => 'XX_CS_TDS_VEN_PKG.CAN_PROC'
                          ,p_error_message_code => 'XX_CS_SR01_SUCCESS_LOG'
                          ,p_error_msg          =>  lc_message);

  END CAN_PROC;

/*****************************************************************************/
/*****************************************************************************/
PROCEDURE VEN_OUTBOUND (p_incident_id   IN NUMBER,
                        p_sr_type       IN VARCHAR2,
                        p_user_id       IN NUMBER,
                        p_status_id     IN NUMBER,
                        x_return_status IN OUT NOCOPY VARCHAR2,
                        x_return_msg    IN OUT NOCOPY VARCHAR2)
IS

l_incident_id            NUMBER ;
l_user_id                NUMBER := null ;
l_audit_id		           NUMBER ;
l_return_status 	       VARCHAR2(30);
l_msg_count 	 	         NUMBER ;
l_msg_data   	 	         VARCHAR2(32767) ;
l_initStr                VARCHAR2(30000);
l_sku_initStr            VARCHAR2(30000);
ln_que_ans_id            NUMBER;
lc_category              VARCHAR2(150);
lc_status                varchar2(250);
lc_ven_status            varchar2(250);
lc_comments              varchar2(3000);
lc_lookup_type           varchar2(250);
lc_contact_name          varchar2(250);
lc_item_number           varchar2(250);

 -- Cursor to Get Incident Details
   CURSOR get_inc_details (p_incident_id IN NUMBER) IS
           SELECT incident_number	,
                  customer_id, incident_status_id,
                  lpad(incident_attribute_11,5,0) store_number,
                  incident_attribute_9 aops_customer_id,
                  incident_attribute_1 order_number,
                  incident_attribute_14 phone_number,
                  incident_attribute_8 email_add,
                  last_updated_by, summary,
                  tier qa_id,
                  incident_attribute_5 contact_name,
                  external_attribute_11,
                  external_attribute_12
	      FROM cs_incidents_all_vl
            WHERE incident_id  = p_incident_id  ;

    -- Cursors to get Task Details

    CURSOR get_Task_Dtls (p_incident_id IN NUMBER) IS
           SELECT tt.Attribute1 Vendor,
                  tt.task_id ,
                  ty.name type_name,
                  tt.last_update_date,
                  tt.creation_date ,
                  tt.last_updated_by,
                  tt.attribute5 category,
                  tt.attribute6 item,
                  tt.task_name,
                  tt.task_status_id
            FROM jtf_tasks_vl tt,
                 jtf_task_types_tl ty
           WHERE ty.task_type_id = tt.task_type_id
            and  tt.source_object_type_code = 'SR'
            and   tt.source_object_id = p_incident_id
            and   tt.task_status_id not in (11,7)
            and   tt.attribute_category = 'Tech Depot Services'
            and   tt.Attribute1 <> 'OD'
            and   rownum < 2;

    l_object_version_number     cs_incidents_all_b.object_version_number%TYPE;
    l_notes     		            CS_SERVICEREQUEST_PVT.notes_table;
    l_contacts  		            CS_SERVICEREQUEST_PVT.contacts_table;
    l_service_request_rec       CS_ServiceRequest_pvt.service_request_rec_type;
    l_sr_update_out_rec         CS_ServiceRequest_pvt.sr_update_out_rec_type;

l_incident_number	        VARCHAR2(100);
ld_date                   date;
l_store_number  	        VARCHAR2(25);
lc_store_code             varchar2(50);
l_order_number  	        NUMBER;
lc_phone_number		        VARCHAR2(50);
lc_email_id               VARCHAR2(250);
l_incident_urgency_id	    NUMBER;
l_incident_owner_id	      NUMBER;
l_owner_group_id	        NUMBER;
l_customer_id		          NUMBER;
l_aops_cust_id            NUMBER;
l_last_updated_by	        NUMBER;
l_summary		              VARCHAR2(240) ;
l_url                     varchar2(2000);
l_api_version             number;
l_workflow_process_id     NUMBER;
l_que_ans_id              NUMBER;
lc_task_name              VARCHAR2(250);
ln_task_status_id         number;
lc_associate_name         varchar2(150);
lc_sub_flag               varchar2(1);

BEGIN

  /** Detect the event raised and determine necessary parameters depending on the event **/
       -- Get B2B URL
        BEGIN
           select fnd_profile.value('XX_B2B_WEB_URL')
           into l_url
           from dual;
       exception
           when others then
              l_url := null;
              l_msg_data := 'Valid B2B URL is not setup';
       END;

              gc_action               := 'Update';
              gc_vendor               := null;
              -- Subscription
              gn_sr_id                := p_incident_id;
              l_user_id               := p_user_id ;
              ld_date                 := Sysdate;

              begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;

              -- Comments
              BEGIN
                  SELECT  entered_by_name||': '||notes
                  INTO lc_comments
                  FROM   jtf_notes_vl
                  WHERE source_object_code = 'SR'
                  AND   source_object_id = p_incident_id
                  AND   note_status <> 'P'
                  AND   rownum < 2
                  AND   created_by not in (SELECT USER_ID FROM FND_USER
                                            WHERE USER_NAME IN ('IMAGEMICROSYS','NEXICORE','SUPPORT.COM','CS_ADMIN'))
                  order by creation_date desc;
              EXCEPTION
                WHEN OTHERS THEN
                    lc_comments := null;
              END;


              l_initStr := l_initStr||'<ns1:ODTechService>';

              FOR get_inc_details_rec IN get_inc_details (p_incident_id)
              LOOP

                 lc_associate_name := get_inc_details_rec.external_attribute_11;
                 IF get_inc_details_rec.external_attribute_12 is null then
                    lc_comments := lc_comments||'  '||lc_associate_name||' : '||get_inc_details_rec.external_attribute_12;
                 ELSE
                    lc_comments := lc_associate_name||' : '||get_inc_details_rec.external_attribute_12;
                 END IF;

                 FOR get_task_dtls_rec IN get_task_dtls (p_incident_id)
                 Loop
                    gc_vendor         := get_task_dtls_rec.vendor;
                    lc_task_name      := get_task_dtls_rec.task_name;
                    ln_task_status_id := get_task_dtls_rec.task_status_id;
                    lc_category       := get_task_dtls_rec.category;
                    IF LC_CATEGORY = 'S' then
                      lc_item_number    := get_task_dtls_rec.item;
                      IF lc_item_number = '630252' THEN
                        lc_sub_flag := 'Y';
                       end if;
                    END IF;
                       -- Determine store code
                      BEGIN
                            SELECT DESCRIPTION
                            INTO LC_STORE_CODE
                            FROM FND_LOOKUP_VALUES
                            WHERE LOOKUP_TYPE =  'XX_CS_TDS_TASK_CODE'
                            AND MEANING = get_task_dtls_rec.type_name
                            AND END_DATE_ACTIVE IS NULL;
                         EXCEPTION
                           WHEN OTHERS THEN
                              LC_STORE_CODE := 'Store';
                              L_MSG_DATA := 'Error while selecting store code '||sqlerrm;
                              Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.VEN_OUTBOUND'
                                    ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                    ,p_error_msg          =>  l_msg_data);
                         END;
                 END LOOP;

              /*    L_MSG_DATA := 'SR Status '||p_status_id||'  '||gc_vendor;
                  Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.VEN_OUTBOUND'
                                 ,p_error_message_code =>  'XX_CS_SR02_SUCCESS_LOG'
                                 ,p_error_msg          =>  l_msg_data);  */

                IF GC_VENDOR IS NOT NULL THEN
                  -- Vendor Lookup
                 BEGIN
                      SELECT DESCRIPTION
                      INTO LC_LOOKUP_TYPE
                      FROM FND_LOOKUP_VALUES
                      WHERE MEANING = GC_VENDOR
                      AND LOOKUP_TYPE = 'XX_CS_TDS_VEN_LOOPUP'
                      AND END_DATE_ACTIVE IS NULL;
                  EXCEPTION
                       WHEN OTHERS THEN
                           LC_LOOKUP_TYPE := 'XX_CS_TDS_VEN_STATUS';
                  END;
                 -- Determine Vendor Status
                BEGIN
                    SELECT DESCRIPTION , MEANING
                    INTO LC_VEN_STATUS, LC_STATUS
                    FROM FND_LOOKUP_VALUES
                    WHERE LOOKUP_TYPE = LC_LOOKUP_TYPE
                    AND MEANING = (SELECT NAME FROM CS_INCIDENT_STATUSES
                                   WHERE INCIDENT_SUBTYPE = 'INC'
                                   AND INCIDENT_STATUS_ID = P_STATUS_ID
                                   AND END_DATE_ACTIVE IS NULL)
                    AND END_DATE_ACTIVE IS NULL;
                EXCEPTION
                   WHEN OTHERS THEN
                        LC_STATUS := NULL;
               END;
                END IF;

               -- Pickup schedule status.
                 IF LC_VEN_STATUS = 'Done' then
                   LC_STORE_CODE := 'Store';
                   gc_vendor := 'Support.com';
                 end if;

                 l_que_ans_id   := get_inc_details_rec.qa_id;

                 IF LC_VEN_STATUS IS NOT NULL THEN
                    l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);
                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',gc_action);
                    l_incident_number := get_inc_details_rec.incident_number;
                      l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',l_incident_number);
                    l_store_number  := get_inc_details_rec.store_number;

                    gc_user_name := fnd_global.user_name;

                      l_initStr := l_initStr||Make_Param_Str
                                    ('storeCode',l_store_number);
                     l_summary	:= get_inc_details_rec.summary;
                          l_initStr := l_initStr||Make_Param_Str
                                    ('comments',lc_comments);

                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',lc_ven_status);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('author',l_store_number);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryLocation',lc_store_code);

                   IF LC_STORE_CODE = 'Home'
                      AND LC_CATEGORY = 'S' then
                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryParty','None');
                    ELSE
                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryParty','SprtSE');
                    END IF;

                       l_initStr := l_initStr||Make_Param_Str
                                    ('isBreakFix','false');

                        IF LC_CATEGORY = 'C' then

                        -- Rework Process
                          IF lc_status = 'Rework' then
                              l_initStr := l_initStr||Make_Param_Str
                                        ('ActionCode','RSC');
                              l_initStr := l_initStr||Make_Param_Str
                                        ('ReworkFlag','TRUE');
                              l_initStr := l_initStr||Make_Param_Str
                                        ('ReworkNumber',l_incident_number);
                          END IF;

                          IF lc_status = 'Cancelled' then
                             l_initStr := l_initStr||Make_Param_Str
                                        ('ActionCode','CAN');
                           END IF;

                       END IF; -- Vendor

                        l_customer_id	    := get_inc_details_rec.customer_id;
                        lc_phone_number	    := get_inc_details_rec.phone_number;
                        lc_email_id	    := get_inc_details_rec.email_add;
                        l_aops_cust_id      := get_inc_details_rec.aops_customer_id;
                        ln_que_ans_id       := get_inc_details_rec.qa_id;
                        lc_contact_name     := get_inc_details_rec.contact_name;

                    -- Customer String
                     CUSTOMER_REC (P_CUSTOMER_ID  => L_CUSTOMER_ID,
                                  P_AOPS_CUST_ID  => L_AOPS_CUST_ID,
                                  P_PHONE_NUMBER  => LC_PHONE_NUMBER,
                                  P_EMAIL_ADDRESS => LC_EMAIL_ID,
                                  P_CONTACT_NAME  => LC_CONTACT_NAME,
                                  x_initStr       => l_initStr);

                      -- Device String
                     DEVICE_REC (P_INCIDENT_ID   => P_INCIDENT_ID,
                                  P_DESCRIPTION   => LC_TASK_NAME,
                                  P_PROB_DESCR    => LC_COMMENTS,
                                  P_VENDOR        => GC_VENDOR,
                                  x_initStr   => L_INITSTR);

                       IF lc_status = 'Rework' then
                          -- SKU rec for rework
                          SKU_REC (p_incident_id  => p_incident_id,
                                   p_vendor       => gc_vendor,
                                   p_que_ans_id   => l_que_ans_id,
                                   p_status_id     => ln_task_status_id,
                                   x_sku_initStr  => l_sku_initStr);

                          l_initStr := l_initStr||l_sku_initStr;
                       end if;

               END IF; -- Vendor Status
              END LOOP;

               l_initStr := l_initStr||'</ns1:ODTechService>';

           IF LC_VEN_STATUS IS NOT NULL THEN
              begin
                l_msg_data := http_post (l_url,l_initStr) ;

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm ;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;
            END IF;

            IF lc_comments is not null then
               /****************************************************
                   -- Update comments
                   ****************************************************/
                   UPDATE_COMMENTS (L_INCIDENT_NUMBER,
                                   GC_USER_NAME,
                                   LC_COMMENTS,
                                   L_RETURN_STATUS,
                                   L_MSG_DATA);
            end if;


           L_MSG_DATA := L_MSG_DATA||LC_STATUS||' '||LC_VEN_STATUS;
           Log_Exception ( p_error_location     => 'XX_CS_TDS_VEN_PKG.VEN_OUTBOUND'
                          ,p_error_message_code => 'XX_CS_SR01_SUCCESS_LOG'
                          ,p_error_msg          =>  l_msg_data);


END VEN_OUTBOUND;

/*****************************************************************************/
/*****************************************************************************/


/***************************************************************************/
END XX_CS_TDS_VEN_PKG;
/
