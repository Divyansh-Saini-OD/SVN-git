CREATE OR REPLACE PACKAGE BODY XX_CS_MPS_VEN_PKG AS

gc_action     varchar2(100);
gc_vendor     varchar2(250);
gn_msg_id     number;
gn_sr_id      number;
gc_user_name  varchar2(150) ;
gc_type       varchar2(25);

---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_CS_MPS_VEN_PKG                                                     |
---|                                                                                            |
---|    Description     : MPS Vendor pkg                                                        |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR               DESCRIPTION                      |
---|    ------------    ----------------- ---------------      ---------------------            |
---|    1.0             03-Jan-2014      Arun Gannarapu        Updated the SKU rec              |
---|    2.0             13-FEB-2014      Arun Gannarapu        Made changes to fix the address  |
---|                                                           issue ..Defect # 28200           |
---|    3.0             28-MAY-2014      Arun Gannarapu        Made changes to fix defect 28202 |
---|    4.0             03-NOV-2015      Havish Kasina         Removed the Schema references in |
---|                                                           the existing code as per R12.2   |
---|                                                           Retrofit changes                 |
---+============================================================================================+

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
     ,p_program_name            => 'XX_CS_MPS_VEN_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'MPS'
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
   lr_service_request_rec      CS_ServiceRequest_PUB.service_request_rec_type;
   lt_notes_table              CS_SERVICEREQUEST_PUB.notes_table;
   lt_contacts_tab             CS_SERVICEREQUEST_PUB.contacts_table;
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

   --   dbms_output.put_line(soap_request);
      req := utl_http.begin_request(url,'POST','HTTP/1.1');
     --  UTL_HTTP.SET_AUTHENTICATION (HTTP_REQ, 'G016D01/S0162114', 'Xenios02', 'Basic',true);
      utl_http.set_header(req,'Content-Type', 'text/xml'); --; charset=utf-8');
      utl_http.set_header(req,'Content-Length', length(soap_request));
      utl_http.set_header(req  , 'SOAPAction'  , 'process');
      utl_http.write_text(req, soap_request);

        resp := utl_http.get_response(req);
        utl_http.read_text(resp, soap_respond);


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

    --  dbms_output.put_line('Output '|| soap_respond);
          l_msg_data := 'Res '||soap_respond;

          Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.HTTP_POST'
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

                   Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.HTTP_POST'
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
PROCEDURE CUSTOMER_REC (P_PARTY_ID     IN NUMBER,
                        P_serial_num   IN VARCHAR2 DEFAULT NULL ,
                        x_initStr      IN OUT NOCOPY VARCHAR2)
IS
 lc_add1        varchar2(250);
 lc_add2        varchar2(250);
 lc_city        varchar2(250);
 lc_state       varchar2(250);
 lc_country     varchar2(100);
 lc_postal_code varchar2(250);
 lc_msg_data    varchar2(2000);
 lc_contact     varchar2(150);
 lc_alternate_contact   varchar2(150);
 lc_phone_number    VARCHAR2(50);
 lc_email_id      VARCHAR2(250);
 lc_aops_cust_id  VARCHAR2(50);
 lc_alternate_no  VARCHAR2(25);
BEGIN

  -- Select Customer Address
   Begin

     IF p_serial_num IS NOT NULL
     THEN 
       select site_address_1,
              site_address_2,
              site_city,
              site_state,
              lpad(site_zip_code,5,0),
              site_contact,
              'USA' country,
              site_contact_phone,
              aops_cust_number
       into   lc_add1,
              lc_add2,
              lc_city,
              lc_state,
              lc_postal_code,
              lc_contact,
              lc_country,
              lc_phone_number,
              lc_aops_cust_id
        from xx_cs_mps_device_b
        where party_id    = p_party_id
        AND   device_id   = p_serial_num
        and rownum < 2;

     ELSE 
       select site_address_1,
              site_address_2,
              site_city,
              site_state,
              lpad(site_zip_code,5,0),
              site_contact,
              'USA' country,
              site_contact_phone,
              aops_cust_number
       into   lc_add1,
              lc_add2,
              lc_city,
              lc_state,
              lc_postal_code,
              lc_contact,
              lc_country,
              lc_phone_number,
              lc_aops_cust_id
        from xx_cs_mps_device_b
        where party_id    = p_party_id
        and rownum < 2;
     END IF;
  exception
    when others then
      LC_MSG_DATA := 'error while selecting address '||sqlerrm;
      Log_Exception ( p_error_location      =>  'XX_CS_MPS_VEN_PKG.CUSTOMER_REC'
                     ,p_error_message_code  =>   'XX_CS_SR02_ERR_LOG'
                     ,p_error_msg           =>  lc_msg_data);
   end;

          -- email and contact

                BEGIN
                  SELECT NVL(INCIDENT_ATTRIBUTE_7,LC_CONTACT),
                         NVL(INCIDENT_ATTRIBUTE_8,LC_PHONE_NUMBER),
                         INCIDENT_ATTRIBUTE_15,
                         INCIDENT_ATTRIBUTE_9
                  INTO LC_CONTACT,
                        LC_PHONE_NUMBER,
                        LC_ALTERNATE_NO,
                        LC_ALTERNATE_CONTACT
                  FROM CS_INCIDENTS_ALL_B
                  WHERE INCIDENT_ID = GN_SR_ID;


                  SELECT fnd_profile.value('XX_CS_MPS_SHIPTO_ADDR') 
                  INTO LC_EMAIL_ID
                  FROM dual;

              EXCEPTION
                WHEN OTHERS THEN
                  LC_EMAIL_ID := 'odgomps@officedepot.com';
               END;

         /**************************************************************
           -- Customer String
         **************************************************************/
           x_initStr := x_initStr||'<ns1:customer>';

           x_initStr := x_initStr||Make_Param_Str
                        ('customerNumber',lc_aops_cust_id);
           x_initStr := x_initStr||Make_Param_Str
                        ('firstName',lc_contact);
           x_initStr := x_initStr||Make_Param_Str
                        ('lastName',lc_alternate_contact);
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
                         ('phoneNumber',lc_phone_number);
           x_initStr := x_initStr||Make_Param_Str
                         ('alternatePhoneNumber',null);
           x_initStr := x_initStr||Make_Param_Str
                         ('faxNumber',lc_alternate_no);
           x_initStr := x_initStr||Make_Param_Str
                         ('email',lc_email_id);

          x_initStr := x_initStr||'</ns1:customer>';

    EXCEPTION
      WHEN OTHERS THEN
           LC_MSG_DATA := 'error while building customer string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.CUSTOMER_REC'
                       ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);

 END CUSTOMER_REC;

/*******************************************************************************/
/*******************************************************************************/
PROCEDURE SKU_REC  (P_LINES_TBL    IN XX_CS_ORDER_LINES_TBL,
                   x_sku_initStr  IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
lc_store_code   varchar2(200);

BEGIN

    IF p_lines_tbl.COUNT > 0 THEN

       x_sku_initStr := '<ns1:skus>';

       FOR i in p_lines_tbl.first..p_lines_tbl.last
       LOOP
                  x_sku_initStr := x_sku_initStr||'<ns1:skuData>';

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('deliveryLocation',lc_store_code);

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('skuId',NVL( p_lines_tbl(i).serial_number , p_lines_tbl(i).sku));

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('quantity', NVL(p_lines_tbl(i).attribute5, p_lines_tbl(i).order_qty));

                  x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('description',p_lines_tbl(i).comments);

                  x_sku_initStr := x_sku_initStr||'</ns1:skuData>';

         END LOOP;
               x_sku_initStr := x_sku_initStr||'</ns1:skus>';
         END IF;

EXCEPTION
  WHEN OTHERS THEN
    LC_MSG_DATA := 'error while building SKU string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.SKU_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
END SKU_REC;

/******************************************************************************/
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

      x_msg_count              NUMBER;
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
                                    Log_Exception ( p_error_location => 'XX_CS_MPS_VEN_PKG.UPDATE_REQUEST'
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
          where responsibility_name = 'OD (US) MARS Support Dashboard';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 53389;
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
     WHERE  incident_number = p_request_number;
    EXCEPTION
      WHEN OTHERS THEN
           x_return_status := 'F';
           x_msg_data := 'Invalid Request Id';
    END;

    lc_in_status := p_status;


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
         AND LOOKUP_TYPE = 'XX_CS_MPS_VEN_LOOPUP';
        EXCEPTION
          WHEN OTHERS THEN
              LC_LOOKUP_TYPE := 'XX_CS_MPS_VEN_STATUS';
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
                  Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.UPDATE_REQUEST'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  lc_message);
        END;

      END IF; -- Status parameter verification.


            /*************************************************************************
                  -- Update Service Request and notes
             ************************************************************************/
             IF LN_STATUS_ID IS NOT NULL THEN
                  x_return_status := null;


                      LC_COMMENTS := P_COMMENTS;

                   BEGIN
                           lr_service_request_rec.status_id := ln_status_id;

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
                         Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.UPDATE_REQUEST'
                                ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  X_MSG_DATA);
                    END IF;
                 EXCEPTION
                   WHEN OTHERS THEN
                      x_msg_data := 'error while calling ipdate status ';
                         Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.UPDATE_REQUEST'
                                ,p_error_message_code =>   'XX_CS_SR02a_ERR_LOG'
                                 ,p_error_msg          =>  X_MSG_DATA);
                END;
               END IF;
        END IF;
    end if; -- incident_id check
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
          Log_Exception ( p_error_location => 'XX_CS_MPS_VEN_PKG.UPDATE_REQUEST'
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

      x_msg_count                    NUMBER;
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
      lc_parts_flag               varchar2(1) := 'N';

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
          where responsibility_name = 'OD (US) MARS Support Dashboard';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 53389;
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
     WHERE  incident_number = p_request_number;
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

                    /*************************************************************************
                     -- Add notes
                      ************************************************************************/
                      If upper(p_comments) = 'TRUE' THEN
                          lc_message := 'Request transmitted successfully ';
                      else
                          lc_message := p_comments;
                      end if;
                      lt_notes_table(1).note        := lc_message ;
                      lt_notes_table(1).note_detail := lc_message;
                      lt_notes_table(1).note_type   := 'GENERAL';

                    /**************************************************************************
                          -- Update SR
                    *************************************************************************/

                   /*     cs_servicerequest_pub.Update_ServiceRequest (
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
                         END IF; */

                      -- update comments only.

                      Begin
                         XX_CS_MPS_VEN_PKG.UPDATE_COMMENTS (P_REQUEST_NUMBER,
                                           P_VENDOR,
                                           P_COMMENTS,
                                           X_RETURN_STATUS,
                                           X_MSG_DATA);

                      end;

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
                            Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.UPDATE_ACK'
                                            ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                             ,p_error_msg          =>  lc_message);
                  end;
              end if;
        END IF;
      END IF;
  EXCEPTION
      WHEN OTHERS THEN
           LC_MESSAGE := X_MSG_DATA;
                Log_Exception ( p_error_location => 'XX_CS_MPS_VEN_PKG.UPDATE_ACK'
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
ln_api_version                  number;
lc_init_msg_list              varchar2(1);
ln_validation_level            number;
lc_commit                        varchar2(1);
lc_return_status              varchar2(1);
ln_msg_count                    number;
lc_msg_data                      varchar2(2000);
ln_jtf_note_id                  number;
ln_source_object_id            number;
lc_source_object_code          varchar2(8);
lc_note_status              varchar2(8);
lc_note_type                    varchar2(80);
lc_notes                        varchar2(2000);
lc_notes_detail                  varchar2(8000);
ld_last_update_date            Date;
ln_last_updated_by            number;
ld_creation_date              Date;
ln_created_by                    number;
ln_entered_by               number;
ld_entered_date             date;
ln_last_update_login        number;
lt_note_contexts              JTF_NOTES_PUB.jtf_note_contexts_tbl_type;
ln_msg_index                    number;
ln_msg_index_out              number;
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
          where responsibility_name = 'OD (US) MARS Support Dashboard';
        EXCEPTION
          WHEN OTHERS THEN
            ln_resp_appl_id  :=  514;
            ln_resp_id       := 53389;
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
     WHERE  incident_number = p_request_number;
    EXCEPTION
      WHEN OTHERS THEN
           x_return_status := 'F';
           x_msg_data := 'Invalid Request Id';
    END;

   IF ln_incident_id is not NULL then

      /************************************************************************
       --Initialize the Notes parameter to create
       **************************************************************************/
              ln_api_version        := 1.0;
              lc_init_msg_list        := FND_API.g_true;
              ln_validation_level    := FND_API.g_valid_level_full;
              lc_commit            := FND_API.g_true;
              ln_msg_count        := 0;

              /****************************************************************************/
              ln_source_object_id    := ln_incident_id;
              lc_source_object_code    := 'SR';
              lc_note_status        := 'I';  -- (P-Private, E-Publish, I-Public)
              lc_note_type        := 'GENERAL';
              IF length(p_comments) < 2000 then
                lc_notes    := p_comments;
              else
                lc_notes    := p_vendor||' updates ';
              end if;
              lc_notes_detail        := p_comments;

              ln_entered_by            := ln_user_id;
              ln_created_by            := ln_user_id;
              ld_entered_date            := SYSDATE;
              ld_last_update_date       := SYSDATE;
              ln_last_updated_by        := ln_user_id;
              ld_creation_date        := SYSDATE;
              ln_last_update_login    := FND_GLOBAL.LOGIN_ID;
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
                                      p_jtf_note_id          => ln_jtf_note_id,
                                      p_entered_by            => ln_entered_by,
                                      p_entered_date          => ld_entered_date,
                                      p_source_object_id      => ln_source_object_id,
                                      p_source_object_code    => lc_source_object_code,
                                      p_notes              => lc_notes,
                                      p_notes_detail          => lc_notes_detail,
                                      p_note_type          => lc_note_type,
                                      p_note_status          => lc_note_status,
                                      p_jtf_note_contexts_tab => lt_note_contexts,
                                      x_jtf_note_id          => ln_jtf_note_id,
                                      p_last_update_date      => ld_last_update_date,
                                      p_last_updated_by          => ln_last_updated_by,
                                      p_creation_date          => ld_creation_date,
                                      p_created_by          => ln_created_by,
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
         Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.UPDATE_COMMENTS'
                              ,p_error_message_code =>   'XX_CS_SR02_SUCCESS_LOG'
                               ,p_error_msg          =>  lc_message);


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
                Log_Exception ( p_error_location => 'XX_CS_MPS_VEN_PKG.UPDATE_COMMENTS'
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
                   Log_Exception ( p_error_location     =>  'XX_CS_MPS_VEN_PKG.CAN_PROC'
                               ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                               ,p_error_msg          =>  x_return_message);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;



           lc_message := 'Cancellation Of subscription '||p_action||'-'||p_incident_number;
           Log_Exception ( p_error_location     => 'XX_CS_MPS_VEN_PKG.CAN_PROC'
                          ,p_error_message_code => 'XX_CS_SR01_SUCCESS_LOG'
                          ,p_error_msg          =>  lc_message);

  END CAN_PROC;

/*****************************************************************************/
/*****************************************************************************/
 PROCEDURE OUTBOUND_PROC (P_INCIDENT_ID IN NUMBER,
                           P_ACTION       IN VARCHAR2,
                           P_TYPE         IN VARCHAR2,
                           P_PARTY_ID     IN NUMBER,
                           P_HDR_REC      IN XX_CS_PO_HDR_REC,
                           P_LINES_TBL    IN XX_CS_ORDER_LINES_TBL,
                           X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MSG   IN OUT NOCOPY VARCHAR2)

IS

l_incident_id            NUMBER ;
l_user_id                NUMBER := null ;
l_audit_id                   NUMBER ;
l_return_status            VARCHAR2(30);
l_msg_count                   NUMBER ;
l_msg_data                     VARCHAR2(32767) ;
l_initStr                VARCHAR2(30000);
l_sku_initStr            VARCHAR2(30000);
lc_comments              varchar2(3000);
lc_ven_status            varchar2(50);
l_object_version_number     cs_incidents_all_b.object_version_number%TYPE;
l_notes                         CS_SERVICEREQUEST_PVT.notes_table;
l_contacts                      CS_SERVICEREQUEST_PVT.contacts_table;
l_service_request_rec       CS_ServiceRequest_pvt.service_request_rec_type;
l_sr_update_out_rec         CS_ServiceRequest_pvt.sr_update_out_rec_type;
l_incident_number            VARCHAR2(100);
ld_date                   date;
lc_serial_no                VARCHAR2(25);
lc_device_location        varchar2(50);
lc_problem_descr          varchar2(250);
l_last_updated_by            NUMBER;
l_url                     varchar2(2000);
l_api_version             number;
l_workflow_process_id     NUMBER;

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

       BEGIN
          SELECT INCIDENT_NUMBER,
                 INCIDENT_ATTRIBUTE_3,
                 PROBLEM_DESCRIPTION,
                 CREATION_DATE
          INTO L_INCIDENT_NUMBER,
                LC_SERIAL_NO,
                LC_PROBLEM_DESCR,
                LD_DATE
          FROM CS_INCIDENTS_ALL_B
          WHERE INCIDENT_ID = P_INCIDENT_ID;
       END;

       IF l_incident_number is not null then

              IF p_action = 'Update' then
                gc_action   := 'Update';
              else
                gc_action := 'Create';
              end if;
              IF p_hdr_rec.attribute1 like 'BARRISTER%' then
                gc_vendor               := 'Barrister';
              ELSIF p_hdr_rec.attribute1 like 'XEROX%' then
               gc_vendor               := 'Xerox';
              END IF;
              gn_sr_id                := p_incident_id;
              ld_date                 := Sysdate;

              begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;

              l_initStr := l_initStr||'<ns1:ODTechService>';

              l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);
                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',gc_action);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',l_incident_number);

                     lc_comments    := p_hdr_rec.comments;
                          l_initStr := l_initStr||Make_Param_Str
                                    ('comments',lc_comments);

                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',lc_ven_status);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('author',lc_serial_no);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryLocation',lc_device_location);

                    -- Customer String
                     CUSTOMER_REC (P_PARTY_ID  => p_party_id,
                                   p_serial_num => NULL,
                                  x_initStr       => l_initStr);

                      -- Problem Descr
                      IF P_TYPE = 'PO' then
                        lc_comments := p_hdr_rec.comments;
                      ELSE
                        BEGIN
                          select b.notes
                          into lc_comments
                          from jtf_notes_b a,
                               JTF_NOTES_TL b
                          where b.jtf_note_id = a.jtf_note_id
                          and b.language = 'US'
                          and b.source_lang = 'US'
                          and a.source_object_code = 'SR'
                          and a.source_object_id = p_incident_id;
                        exception
                          when others then
                             lc_comments := lc_problem_descr;
                        end;
                      END IF;
                     -- Device string
                      l_initStr := l_initStr||'<ns1:device>';
                        l_initStr := l_initStr||Make_Param_Str
                                        ('serialNumber',lc_serial_no);
                        l_initStr := l_initStr||Make_Param_Str
                                         ('problemDescription',lc_comments);
                     l_initStr := l_initStr||'</ns1:device>';

                   IF P_LINES_TBL.COUNT > 0 then
                    -- lines String
                     SKU_REC (P_LINES_TBL    => P_LINES_TBL,
                                   x_sku_initStr  => l_sku_initStr);

                        l_initStr := l_initStr||l_sku_initStr;
                   end if;


                        l_initStr := l_initStr||'</ns1:ODTechService>';

              begin
                l_msg_data := http_post (l_url,l_initStr) ;

                LC_COMMENTS := 'Vendor transimission completed';

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm ;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;

              IF lc_comments is not null then
               /****************************************************
                   -- Update comments
                   ****************************************************/
                   UPDATE_COMMENTS (P_HDR_REC.REQUEST_NUMBER,
                                   GC_USER_NAME,
                                   LC_COMMENTS,
                                   L_RETURN_STATUS,
                                   L_MSG_DATA);
             end if;
      END IF;

END;
/********************************************************************************************/
PROCEDURE CASE_OUTBOUND_PROC(P_INCIDENT_ID IN NUMBER,
                           P_ACTION       IN VARCHAR2,
                           P_TYPE         IN VARCHAR2,
                           P_PARTY_ID     IN NUMBER,
                           X_RETURN_STATUS IN OUT NOCOPY VARCHAR2,
                           X_RETURN_MSG   IN OUT NOCOPY VARCHAR2)

IS

l_incident_id               NUMBER ;
l_user_id                   NUMBER := null ;
l_audit_id                      NUMBER ;
l_return_status               VARCHAR2(30);
l_msg_count                      NUMBER ;
l_msg_data                        VARCHAR2(32767) ;
l_initStr                   VARCHAR2(30000);
l_sku_initStr                VARCHAR2(30000);
lc_comments                 varchar2(3000);
lc_ven_status               varchar2(50);
l_object_version_number     cs_incidents_all_b.object_version_number%TYPE;
l_notes                         CS_SERVICEREQUEST_PVT.notes_table;
l_contacts                      CS_SERVICEREQUEST_PVT.contacts_table;
l_service_request_rec       CS_ServiceRequest_pvt.service_request_rec_type;
l_sr_update_out_rec         CS_ServiceRequest_pvt.sr_update_out_rec_type;
l_incident_number            VARCHAR2(100);
ld_date                   date;
lc_serial_no                VARCHAR2(25);
lc_device_location        varchar2(50);
lc_problem_descr          varchar2(250);
l_last_updated_by            NUMBER;
l_url                     varchar2(2000);
l_api_version             number;
l_workflow_process_id     NUMBER;

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

       BEGIN
          SELECT INCIDENT_NUMBER,
                 INCIDENT_ATTRIBUTE_3,
                 PROBLEM_DESCRIPTION,
                 CREATION_DATE
          INTO L_INCIDENT_NUMBER,
                LC_SERIAL_NO,
                LC_PROBLEM_DESCR,
                LD_DATE
          FROM CS_INCIDENTS_ALL_B
          WHERE INCIDENT_ID = P_INCIDENT_ID;
       END;

       IF l_incident_number is not null then

              IF p_action = 'Update' then
                gc_action   := 'Update';
              else
                gc_action := 'Create';
              end if;

              gc_vendor               := 'Barrister';
              gn_sr_id                := p_incident_id;
              IF ld_date is null then
               ld_date                 := Sysdate;
              end if;

              begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;

              l_initStr := l_initStr||'<ns1:ODTechService>';

              l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);
                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',gc_action);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',l_incident_number);

                          l_initStr := l_initStr||Make_Param_Str
                                    ('comments',lc_problem_descr);

                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',lc_ven_status);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('author',lc_serial_no);

                      l_initStr := l_initStr||Make_Param_Str
                                    ('deliveryLocation',lc_device_location);

                    -- Customer String
                     CUSTOMER_REC (P_PARTY_ID  => p_party_id,
                                   p_serial_num => LC_SERIAL_NO,
                                  x_initStr       => l_initStr);

                      -- Problem Descr

                        BEGIN
                          select b.notes
                          into lc_comments
                          from jtf_notes_b a,
                                JTF_NOTES_TL b
                          where b.jtf_note_id = a.jtf_note_id
                          and b.language = 'US'
                          and b.source_lang = 'US'
                          and a.source_object_code = 'SR'
                          and a.source_object_id = p_incident_id;
                        exception
                          when others then
                             lc_comments := lc_problem_descr;
                        end;

                     -- Device string
                      l_initStr := l_initStr||'<ns1:device>';
                        l_initStr := l_initStr||Make_Param_Str
                                        ('serialNumber',lc_serial_no);
                        l_initStr := l_initStr||Make_Param_Str
                                         ('problemDescription',lc_comments);
                     l_initStr := l_initStr||'</ns1:device>';

                    l_initStr := l_initStr||'</ns1:ODTechService>';

              begin
                l_msg_data := http_post (l_url,l_initStr) ;

                LC_COMMENTS := 'Vendor transimission completed';

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm ;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.SR_TASK'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;

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
      END IF;

END;
/*********************************************************************************************/

END XX_CS_MPS_VEN_PKG;
/