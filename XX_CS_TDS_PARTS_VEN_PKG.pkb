create or replace
PACKAGE BODY XX_CS_TDS_PARTS_VEN_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_PARTS_VEN_PKG                                  |
-- |                                                                   |
-- | Description: Wrapper package for Vendor Communications.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       18-JUN-11   Raj Jagarlamudi  Initial draft version       |
-- |          13-JUN-13   Raj              Remove PO schema with R12   |
-- |2.0       28-JAN-2016 Vasu Raparla     Removed Schema References   |
-- |                                       for R12.2                   |
-- +===================================================================+

gc_action     varchar2(100);
gc_vendor     varchar2(250);
gn_msg_id     number;
gc_user_name  varchar2(150) := 'CS_ADMIN' ;
gn_incident_id number;

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
     ,p_program_name            => 'XX_CS_TDS_PARTS_VEN_PKG'
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
PROCEDURE UPDATE_STATUS (P_SR_NUMBER      IN VARCHAR2,
                          P_STATUS        IN VARCHAR2,
                          X_RETURN_STATUS IN OUT VARCHAR2,
                          X_RETURN_MSG     IN OUT VARCHAR2) AS

  ln_incident_id      number;
  ln_status_id        number;
  lc_receipt_flag     varchar2(1) := 'N';
  lc_sales_flag       varchar2(1) := 'N';
  ln_user_id          number;
  ln_resp_appl_id     number   :=  514;
  ln_resp_id          number   := 21739;
  ln_obj_ver          number;
  lc_status           varchar2(25);
  x_msg_count	        NUMBER;
  x_interaction_id    NUMBER;
  ln_msg_index        number;
  ln_msg_index_out    number;
  lc_summary          varchar2(1000);
  lc_message          varchar2(2000);
  lc_return_status    varchar2(1) := 'S';

  BEGIN

     BEGIN
        select incident_id ,
              object_version_number
        into   ln_incident_id,
               ln_obj_ver
        from cs_incidents_all_b
        where incident_number = p_sr_number;
     EXCEPTION
       WHEN OTHERS THEN
         lc_return_status := 'F';
         lc_message := 'error while selecting incidentid '||sqlerrm;
         Log_Exception ( p_error_location      =>  'XX_CS_TDS_PARTS_VEN_PKG.UPDATE_STATUS'
                               ,p_error_message_code  =>  'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg           =>  lc_message );
     END;

    IF NVL(LC_RETURN_STATUS, 'S') <> 'F' THEN  -- (1)
     --USER ID

        begin
          select user_id
          into ln_user_id
          from fnd_user
          where user_name = 'CS_ADMIN';
        exception
          when others then
            lc_return_status := 'F';
            lc_message  := 'error while selecting userid '||sqlerrm;
            Log_Exception ( p_error_location      =>  'XX_CS_TDS_PARTS_VEN_PKG.UPDATE_STATUS'
                               ,p_error_message_code  =>  'XX_CS_SR02_ERR_LOG'
                               ,p_error_msg           =>  lc_message );
        end;

    /********************************************************************
    --Apps Initialization
    *******************************************************************/
    fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);

       BEGIN
          SELECT incident_status_id,
                 name
          INTO  ln_status_id, lc_status
          FROM  cs_incident_statuses
          WHERE incident_subtype = 'INC'
          AND   name = p_status ;
        EXCEPTION
          WHEN OTHERS THEN
            lc_return_status := 'F';
            lc_message  := 'error while selecting status id '||sqlerrm;
            Log_Exception ( p_error_location      =>  'XX_CS_TDS_PARTS_VEN_PKG.UPDATE_STATUS'
                               ,p_error_message_code  =>  'XX_CS_SR03_ERR_LOG'
                               ,p_error_msg           =>  lc_message );
        END;

      IF NVL(LC_RETURN_STATUS, 'S') <> 'F' THEN   -- (2)
      /***********************************************************************
       -- Update SR
       ***********************************************************************/
        CS_SERVICEREQUEST_PUB.Update_Status
                (p_api_version		     => 2.0,
                p_init_msg_list	        => FND_API.G_TRUE,
                p_commit		            => FND_API.G_FALSE,
                x_return_status	        => x_return_status,
                x_msg_count	            => x_msg_count,
                x_msg_data		          => x_return_msg,
                p_resp_appl_id	        => ln_resp_appl_id,
                p_resp_id		            => ln_resp_id,
                p_user_id		            => ln_user_id,
                p_login_id		          => NULL,
                p_request_id		        => ln_incident_id,
                p_request_number	        => NULL,
                p_object_version_number   => ln_obj_ver,
                p_status_id	 	          => ln_status_id,
                p_status		            => NULL,
                p_closed_date		        => NULL,
                p_audit_comments	        => NULL,
                p_called_by_workflow	  => NULL,
                p_workflow_process_id	  => NULL,
                p_comments		          => NULL,
                p_public_comment_flag	  => NULL,
                x_interaction_id	       => x_interaction_id );

            COMMIT;
            IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
                IF (FND_MSG_PUB.Count_Msg > 1) THEN
                --Display all the error messages
                  FOR j in 1..FND_MSG_PUB.Count_Msg LOOP
                          FND_MSG_PUB.Get(
                                    p_msg_index => j,
                                    p_encoded => 'F',
                                    p_data => x_return_msg,
                                    p_msg_index_out => ln_msg_index_out);

                       -- DBMS_OUTPUT.PUT_LINE(x_msg_data);
                  END LOOP;
                ELSE
                            --Only one error
                        FND_MSG_PUB.Get(
                                    p_msg_index => 1,
                                    p_encoded => 'F',
                                    p_data => x_return_msg,
                                    p_msg_index_out => ln_msg_index_out);
                        --DBMS_OUTPUT.PUT_LINE(x_msg_data);
                        --DBMS_OUTPUT.PUT_LINE(ln_msg_index_out);
                END IF;

                x_return_msg := x_return_msg;
            END IF;

        END IF;  -- (2)
   END IF; -- (1)
END UPDATE_STATUS;
/**************************************************************************/
FUNCTION http_post ( url VARCHAR2, req_body varchar2)
RETURN VARCHAR2  AS

  soap_request      	VARCHAR2(30000);
  soap_respond      	VARCHAR2(30000);
  req               	utl_http.req;
  resp              	utl_http.resp;
  v_response_text   	VARCHAR2(32767);
  x_resp            	XMLTYPE;
  l_detail          	VARCHAR2(32767);
  i                 	integer;
  l_msg_data        	varchar2(30000);
   --
   v_doc            	dbms_xmldom.DOMDocument;
   v_node_list      	dbms_xmldom.DOMNodeList;
   v_node           	dbms_xmldom.DOMNode;
   v_ele            	dbms_xmldom.DOMElement;
   v_childnode      	dbms_xmldom.DOMNode;
   ndoc             	dbms_xmldom.DOMNode;
   v_nodename       	varchar2(150);
   v_len            	number;
   ln_serviceId     	number;
   lc_status        	varchar2(150);
   lc_return_status 	varchar2(100) := 'false';
   lc_shipping_link   varchar2(3000);
   lc_message       	varchar2(3000);
   lr_sku_tbl       	XX_CS_TDS_SKU_TBL;
   lc_receiver      	varchar2(100);

begin

      --DBMS_OUTPUT.PUT_LINE ('REQ ID : '||GN_INCIDENT_ID);

      ln_serviceId := gn_incident_id;

      --DBMS_OUTPUT.PUT_LINE ('LN_SERVICEiD  : '||ln_serviceId);

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
       Log_Exception ( p_error_location     =>  'XX_CS_TDS_PARTS_VEN_PKG.HTTP_POST'
                      ,p_error_message_code =>  'XX_CS_SR01_SUCCESS_LOG'
                      ,p_error_msg          =>  l_msg_data);

            */
        x_resp := x_resp.extract('/soap:Envelop/soap:Body/child::node()'
                               ,'xmlns:soap="http://TargetNamespace.com/XMLSchema-instance"');

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
                          ln_serviceId,
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

                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_PARTS_VEN_PKG.HTTP_POST'
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
        	  '>'||p_param_value||'</ns1:'||p_param_name||'>';

 END Make_Param_Str;
--------------------------------------------------------------------------------

/******************************************************************************
  -- Customer Procedure
*******************************************************************************/
PROCEDURE CUSTOMER_REC (P_CUSTOMER_ID   IN NUMBER,
                        P_AOPS_CUST_ID  IN NUMBER,
                        P_LOCATION_ID   IN NUMBER,
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
         /*   select address1,
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
            where party_id = p_customer_id; */

           select address_line_1,
                      address_line_2,
                      town_or_city,
                      region_2,
                      postal_code,
                      country
              into lc_add1,
                 lc_add2,
                 lc_city,
                 lc_state,
                 lc_postal_code,
                -- lc_first_name,
                -- lc_last_name,
                 lc_country
              from hr_locations_all
              where location_id = p_location_id ;

         exception
          when others then
               LC_MSG_DATA := 'error while selecting address '||sqlerrm;
                Log_Exception ( p_error_location      =>  'XX_CS_TDS_PARTS_VEN_PKG.CUSTOMER_REC'
                               ,p_error_message_code  =>  'XX_CS_SR02_ERR_LOG'
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
           x_initStr := x_initStr||Make_Param_Str
                         ('zipcode',lc_postal_code);
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
                Log_Exception ( p_error_location  =>  'XX_CS_TDS_PARTS_VEN_PKG.CUSTOMER_REC'
                       ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);

 END CUSTOMER_REC;
/*******************************************************************************/
PROCEDURE PART_REC (p_request_number    IN VARCHAR2,
                    p_request_id	      IN NUMBER,
                    p_header_id         IN NUMBER,
                    p_vendor		        IN VARCHAR2,
                    p_doc_type    	    IN VARCHAR2,
                    x_sku_initStr  	    IN OUT NOCOPY VARCHAR2)
IS

lc_msg_data     varchar2(2000);
lc_store_code   varchar2(200);
lc_pur_price    varchar2(15);
lc_exc_price    varchar2(15);

CURSOR OVER_CUR IS
select  xc.excess_quantity qty,
        xc.item_number,
        xc.item_description,
        xc.item_category,
        xc.purchase_price ,
        xc.line_number
from  xx_cs_tds_parts xc
where nvl(xc.excess_flag,'N') in ( 'Y', 'R')
and  nvl(xc.attribute2,'N') = 'N'
and  nvl(xc.attribute4,'N') = 'Y'
and  xc.request_number = p_request_number;

CURSOR EXE_CUR IS
select  pll.po_header_id,
        xc.excess_quantity qty,
        xc.item_number,
        xc.item_description,
        pll.line_num,
        xc.item_category,
        pll.unit_price purchase_price ,
        xc.line_number
from  po_lines_all pll,
      xx_cs_tds_parts xc
where xc.inventory_item_id = pll.item_id
and  pll.po_header_id = p_header_id
and  nvl(xc.excess_flag,'N') in ( 'Y', 'R')
and  nvl(xc.attribute2,'N') = 'N'
and  nvl(xc.attribute4,'N') <> 'Y'
and  xc.request_number = p_request_number;

CURSOR PO_CUR IS
select distinct pl.quantity,
       xt.Item_number,
       xt.item_description,
       pl.line_num,
       xt.item_category,
      -- pl.unit_price purchase_price,
       xt.purchase_price,
       xt.exchange_price,
       xt.core_flag
from po_lines_all pl,
     po_headers_all ph,
     mtl_system_items_b mt,
     po_line_locations_all pc,
     xx_cs_tds_parts xt
where mt.inventory_item_id = pl.item_id
and   pc.po_line_id = pl.po_line_id
and   pc.ship_to_organization_id = mt.organization_id
and   pl.po_header_id = ph.po_header_id
and   ph.segment1 = xt.request_number
and   mt.attribute2 = xt.item_number
and   mt.inventory_item_id = xt.inventory_item_id
and   mt.organization_id = xt.store_id
and   pl.cancel_flag = 'N'
and   xt.request_number = p_request_number;

BEGIN

      x_sku_initStr := '<ns1:skus>';

	IF P_DOC_TYPE = 'PO' THEN

		For get_po_details_rec IN po_cur
		LOOP

                   IF  (get_po_details_rec.purchase_price - FLOOR(get_po_details_rec.purchase_price)) > 0 THEN
                        IF LENGTH(get_po_details_rec.purchase_price - FLOOR(get_po_details_rec.purchase_price)) < 3 THEN
                            LC_PUR_PRICE := get_po_details_rec.purchase_price||'0';
                        ELSE
                            LC_PUR_PRICE := get_po_details_rec.purchase_price;
                        END IF;
                   ELSE
                      LC_PUR_PRICE := get_po_details_rec.purchase_price||'.00';

                   END IF;

                     IF  (get_po_details_rec.exchange_price - FLOOR(get_po_details_rec.exchange_price)) > 0 THEN
                        IF LENGTH(get_po_details_rec.exchange_price - FLOOR(get_po_details_rec.exchange_price)) < 3 THEN
                            LC_EXC_PRICE := get_po_details_rec.exchange_price||'0';
                        ELSE
                            LC_EXC_PRICE := get_po_details_rec.exchange_price;
                        END IF;
                   ELSE
                      LC_EXC_PRICE := get_po_details_rec.exchange_price||'.00';

                   END IF;

                 --  DBMS_OUTPUT.PUT_LINE('PRICE ' ||LC_PUR_PRICE);

                    x_sku_initStr := x_sku_initStr||'<ns1:skuData>';    -- <Part>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('quantity',get_po_details_rec.quantity);
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('skuId',get_po_details_rec.item_number);   -- Part Number
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('description',get_po_details_rec.item_description);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('poLineNumber',get_po_details_rec.line_num);  -- PO Line Number

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('itemCategory',get_po_details_rec.item_category);   -- <SKUCategory>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('purchasePrice', lc_pur_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangePrice', lc_exc_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangeFlag', get_po_details_rec.core_flag);

                    x_sku_initStr := x_sku_initStr||'</ns1:skuData>';     -- </Part>


		END LOOP;

	ELSIF P_DOC_TYPE = 'EXCESS' THEN

     	For get_excess_rec IN exe_cur
      LOOP
                   IF  (get_excess_rec.purchase_price - FLOOR(get_excess_rec.purchase_price)) > 0 THEN
                        IF LENGTH(get_excess_rec.purchase_price - FLOOR(get_excess_rec.purchase_price)) < 3 THEN
                            LC_PUR_PRICE := get_excess_rec.purchase_price||'0';
                        ELSE
                            LC_PUR_PRICE := get_excess_rec.purchase_price;
                        END IF;
                   ELSE
                      LC_PUR_PRICE := get_excess_rec.purchase_price||'.00';

                   END If;


                      LC_EXC_PRICE := '00.00';

                 --  DBMS_OUTPUT.PUT_LINE('PRICE ' ||LC_PUR_PRICE);

                    x_sku_initStr := x_sku_initStr||'<ns1:skuData>';    -- <Part>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('quantity',get_excess_rec.qty);
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('skuId',get_excess_rec.item_number);   -- Part Number
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('description',get_excess_rec.item_description);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('poLineNumber',get_excess_rec.line_num);  -- PO Line Number

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('itemCategory',get_excess_rec.item_category);   -- <SKUCategory>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('purchasePrice', lc_pur_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangePrice', lc_exc_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangeFlag', 'N');

                    x_sku_initStr := x_sku_initStr||'</ns1:skuData>';     -- </Part>

               begin
                  update xx_cs_tds_parts
                  set attribute2 = 'Y'
                  where request_number = p_request_number
                  and line_number = get_excess_rec.line_number;

                  commit;
               exception
                  when others then
                    LC_MSG_DATA := 'error while updating part line '||sqlerrm;
                     Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_REC'
                       ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
              end;
		END LOOP;

  ELSIF P_DOC_TYPE = 'OVER' THEN

     	For get_over_rec IN over_cur
      LOOP
                   LC_EXC_PRICE := '00.00';

                 --  DBMS_OUTPUT.PUT_LINE('PRICE ' ||LC_PUR_PRICE);

                    x_sku_initStr := x_sku_initStr||'<ns1:skuData>';    -- <Part>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('quantity',get_over_rec.qty);
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('skuId',get_over_rec.item_number);   -- Part Number
                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('description',get_over_rec.item_description);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('poLineNumber',get_over_rec.line_number);  -- PO Line Number

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('itemCategory',get_over_rec.item_category);   -- <SKUCategory>

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('purchasePrice', lc_pur_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangePrice', lc_exc_price);

                    x_sku_initStr := x_sku_initStr||Make_Param_Str
                                    ('exchangeFlag', 'N');

                    x_sku_initStr := x_sku_initStr||'</ns1:skuData>';     -- </Part>

               begin
                  update xx_cs_tds_parts
                  set attribute2 = 'Y'
                  where request_number = p_request_number
                  and line_number = get_over_rec.line_number;

                  commit;
               exception
                  when others then
                    LC_MSG_DATA := 'error while updating part line '||sqlerrm;
                     Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
              end;
		END LOOP;

  ELSIF P_DOC_TYPE = 'CORE' THEN
           NULL;
	END IF;
              x_sku_initStr := x_sku_initStr||'</ns1:skus>';
EXCEPTION
  WHEN OTHERS THEN
    LC_MSG_DATA := 'error while building SKU string '||sqlerrm;
                Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_REC'
                       ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);
END PART_REC;
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
        select nvl(xc.manufacturer,cb.incident_attribute_12) manuf,
           cb.incident_attribute_4 brand,
           nvl(xc.model,cb.incident_attribute_6) model_no,
           cb.incident_attribute_3,
           cb.incident_attribute_7,
           nvl(xc.serial_number,cb.incident_attribute_10) serial_no,
           nvl(xc.problem_descr,cb.external_attribute_7) problem_descr,
           nvl(xc.special_instr, cb.external_attribute_10) special_instr
      into   lc_manuf,
               lc_brand,
               lc_model,
               lc_type,
               lc_os,
               lc_serial,
               lc_descr,
               lc_prob_descr
        from cs_incidents_all_b cb,
             xx_cs_tds_parts xc
        where xc.request_number = cb.incident_number
        and   cb.incident_id = p_incident_id
        and rownum < 2;
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
            x_initStr := x_initStr||Make_Param_Str
                             ('description','<![CDATA['||lc_descr||']]>');

              x_initStr := x_initStr||Make_Param_Str
                             ('problemDescription','<![CDATA['||nvl(lc_prob_descr,p_prob_descr)||']]>');

          end if;
              x_initStr := x_initStr||'</ns1:device>';



   EXCEPTION
      WHEN OTHERS THEN
           LC_MSG_DATA := 'error while building DEVICE string '||sqlerrm;
                Log_Exception ( p_error_location  =>  'XX_CS_TDS_PARTS_VEN_PKG.DEVICE_REC'
                       ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                       ,p_error_msg          =>  lc_msg_data);

end device_rec;
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
/*****************************************************************************/
PROCEDURE PART_OUTBOUND (p_incident_number   	IN VARCHAR2,
                         p_incident_id		    IN NUMBER,
                         p_doc_type          	IN VARCHAR2,
                         p_doc_number        	IN VARCHAR2,
                         x_return_status     	IN OUT NOCOPY VARCHAR2,
                         x_return_msg        	IN OUT NOCOPY VARCHAR2)

  IS

l_incident_id            NUMBER ;
l_user_id                NUMBER := null ;
l_return_status 	       VARCHAR2(30);
l_msg_count 	 	          NUMBER ;
l_msg_data   	 	          VARCHAR2(32767) ;
l_initStr                VARCHAR2(30000);
l_sku_initStr            VARCHAR2(30000);
lc_comments              varchar2(3000);
lc_lookup_type           varchar2(250);
lc_contact_name          varchar2(250);
lc_status                varchar2(50);

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
                  incident_attribute_5 contact_name,
                  external_attribute_11,
                  external_attribute_12
	      FROM cs_incidents_all_vl
            WHERE incident_id  = l_incident_id  ;

    l_object_version_number     cs_incidents_all_b.object_version_number%TYPE;
    l_notes     		            CS_SERVICEREQUEST_PVT.notes_table;
    l_contacts  		            CS_SERVICEREQUEST_PVT.contacts_table;
    l_service_request_rec       CS_ServiceRequest_pvt.service_request_rec_type;
    l_sr_update_out_rec         CS_ServiceRequest_pvt.sr_update_out_rec_type;

ld_date                   date;
l_store_number  	        VARCHAR2(25);
lc_store_code             varchar2(50);
LC_ServicerID              VARCHAR2(25);
LC_ActionCode             VARCHAR2(25);
lc_phone_number		        VARCHAR2(50);
lc_email_id               VARCHAR2(250);
l_customer_id		          NUMBER;
l_aops_cust_id            NUMBER;
l_last_updated_by	        NUMBER;
l_summary		              VARCHAR2(240) ;
l_url                     varchar2(2000);
lc_associate_name         varchar2(150);
lc_doc_number              varchar2(50);
ln_header_id              number;
lc_dbm_num                varchar2(25);
lc_del_loc                varchar2(25);
ln_location_id            number;

cursor dbu_cur is
select  apn.invoice_num,
        poa.segment1 ,
        pll.line_num
from ap_invoices_all apn,
     ap_invoice_distributions_all apd,
     po_distributions_all pod,
     po_headers_all poa,
     po_lines_all pll,
     po_line_locations_all plh,
     xx_cs_tds_parts xc
where xc.inventory_item_id = pll.item_id
and   xc.request_number = poa.segment1
and   poa.po_header_id = pod.po_header_id
and   pod.po_distribution_id = apd.po_distribution_id
and   pll.po_line_id = plh.po_line_id
and   plh.po_header_id = poa.po_header_id
and   apd.invoice_id = apn.invoice_id
and   poa.po_header_id = ln_header_id
and   nvl(xc.excess_flag,'N') in ( 'R','Y')
and   nvl(xc.attribute2,'N') = 'N'
and   apn.invoice_type_lookup_code = 'DEBIT'
and   xc.request_number = p_doc_number;

dbu_rec   dbu_cur%rowtype;

BEGIN

  /** Detect the event raised and determine necessary parameters depending on the event **/
       -- Get BPEL URL
        BEGIN
           select fnd_profile.value('XX_B2B_WEB_URL')
           into l_url
           from dual;
       exception
           when others then
              l_url := null;
              l_msg_data := 'Valid BPEL URL is not setup';
       END;

      l_incident_id := p_incident_id;
      gc_vendor := 'Nexicore';
	-- SELECT INCIDENT_NUMBER
      IF p_incident_id is null then
       BEGIN
        select incident_id
        into l_incident_id
        from cs_incidents_all_b
        where incident_number = p_incident_number;
       exception
        when others then
                  l_msg_data := 'Error while selecting SR id for SRNo '||p_incident_number;
          Log_Exception ( p_error_location     =>  'XX_CS_TDS_PARTS_VEN_PKG.OUTBOUND'
                                  ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                                  ,p_error_msg          =>  l_msg_data);
       end;
      END IF;

	IF l_incident_id is not null then

       gn_incident_id := l_incident_id;

              ld_date                 := Sysdate;
              begin
                  select po_header_id,
                         segment1,
                         ship_to_location_id
                  into  ln_header_id,
                        lc_doc_number,
                        ln_location_id
                  from po_headers_all
                  where segment1 = p_incident_number;
               exception
                 when others then
                    l_msg_data := 'error while selecting po  '||sqlerrm ;
                    Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                               ,p_error_message_code =>   'XX_CS_SR01_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
              end;

              IF p_doc_type = 'PO' THEN
                LC_ServicerID := 'PART';
                LC_ActionCode := 'PartsOrder';
                LC_DEL_LOC  := 'ORD';
                LC_STATUS := 'Waiting for Parts';

                lc_comments := 'PO# '||lc_doc_number||' sent to Vendor ';

              ELSIF P_DOC_TYPE = 'CORE' THEN
                LC_ServicerID := 'CORE';
                LC_ActionCode := 'PartsOrder';
                LC_DEL_LOC  := 'CORE';
              ELSIF P_DOC_TYPE = 'OVER' THEN
                LC_ServicerID := 'RETURN';
                LC_ActionCode := 'PartsOrder';
                LC_DEL_LOC  := 'RET';
                LC_STATUS := 'Return Excess Parts';
               ELSIF P_DOC_TYPE = 'CANCEL' THEN
                LC_ServicerID := 'CAN';
                LC_ActionCode := 'PartsOrder';
                LC_DEL_LOC  := 'CAN';
                lc_comments := 'PO# '||lc_doc_number||' Cancellation sent to Vendor ';

              ELSIF P_DOC_TYPE IN ('EXCESS', 'WAR') THEN
                LC_ServicerID := 'RETURN';
                LC_ActionCode := 'PartsOrder';
                LC_DEL_LOC  := 'RET';
                LC_STATUS := 'Return Excess Parts';
                -- get debit memo number
                --dbms_output.put_line('excess order '||p_doc_number);

                BEGIN
                  open dbu_cur;
                  loop
                  fetch dbu_cur into dbu_rec;
                  exit when dbu_cur%notfound;

                  lc_doc_number := dbu_rec.invoice_num;

                  begin
                    update ap_invoices_all
                    set description = 'PO '||dbu_rec.segment1||' Line '||dbu_rec.line_num
                    where invoice_num = dbu_rec.invoice_num;

                  exception
                    when others then
                      l_msg_data := 'error while updating description : '||p_doc_number||'  '||sqlerrm ;
                      Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                                 ,p_error_message_code =>   'XX_CS_SR01d_ERR_LOG'
                                 ,p_error_msg          =>  l_msg_data);
                   end;

                  end loop;
                  close dbu_cur;

                  lc_comments := 'DM# '||lc_doc_number||' sent to Vendor ';

                EXCEPTION
                  WHEN OTHERS THEN
                      LC_DOC_NUMBER := NULL;
                      l_msg_data := 'error while selecting debit memo number for : '||p_doc_number||'  '||sqlerrm ;
                      Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                                 ,p_error_message_code =>   'XX_CS_SR02_ERR_LOG'
                                 ,p_error_msg          =>  l_msg_data);
                END;

              END IF;

              gc_action := lc_actionCode;

              --DBMS_OUTPUT.PUT_LINE('DOC NUMBER '||LC_DOC_NUMBER);

       IF LC_DOC_NUMBER IS NOT NULL THEN        -- verify the document
          /********************************/
           -- Update the status
          /*******************************/
            IF LC_STATUS IS NOT NULL THEN
            -- update status
              begin
                UPDATE_STATUS (P_SR_NUMBER      => P_INCIDENT_NUMBER,
                               P_STATUS         => LC_STATUS,
                               X_RETURN_STATUS  => L_RETURN_STATUS,
                               X_RETURN_MSG     => L_MSG_DATA);
              exception
                    when others then
                      l_msg_data := 'error while update STATUS  '||sqlerrm ;
                       Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                                   ,p_error_message_code =>   'XX_CS_SR05_ERR_LOG'
                                   ,p_error_msg          =>  l_msg_data);

              end;
            END IF;
             -- get message id
              begin
                SELECT cs_messages_s.NEXTVAL
                into gn_msg_id
                FROM dual;
              end;


              l_initStr := l_initStr||'<ns1:ODTechService>';

              FOR get_inc_details_rec IN get_inc_details (L_incident_id)
              LOOP


                 lc_associate_name := get_inc_details_rec.external_attribute_11;

                 IF get_inc_details_rec.external_attribute_12 is null then
                  lc_comments := lc_comments||'  '||lc_associate_name||' : '||get_inc_details_rec.external_attribute_12;
                 ELSE
                   lc_comments := lc_associate_name||' : '||get_inc_details_rec.external_attribute_12;
                 END IF;


                    l_initStr := l_initStr||Make_Param_Str
                                    ('vendor',gc_vendor);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('action',LC_ActionCode);

                    l_initStr := l_initStr||Make_Param_Str
                                        ('deliveryLocation',LC_DEL_LOC);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('serviceId',P_incident_number);

                    l_store_number  	:= get_inc_details_rec.store_number;

                      l_initStr := l_initStr||Make_Param_Str
                                    ('storeCode',l_store_number);


                        l_initStr := l_initStr||Make_Param_Str
                                    ('comments','<![CDATA['||l_summary||']]>');

                        l_initStr := l_initStr||Make_Param_Str
                                    ('status',null);

                    l_initStr := l_initStr||Make_Param_Str
                                    ('dateTime',ld_date);

                      IF P_DOC_TYPE = 'OVER' THEN
                        l_initStr := l_initStr||Make_Param_Str
                                      ('authorizationNumber','');
                      ELSE
                        l_initStr := l_initStr||Make_Param_Str
                                      ('authorizationNumber',lc_doc_number);
                      END IF;

                      IF P_DOC_TYPE = 'WAR' THEN
                       l_initStr := l_initStr||Make_Param_Str
                                    ('ReworkNumber',lc_doc_number);
                      end if;

                    l_initStr := l_initStr||Make_Param_Str
                                    ('messageId',gn_msg_id);

                        l_customer_id	    := get_inc_details_rec.customer_id;
                        lc_phone_number	    := get_inc_details_rec.phone_number;
                        lc_email_id	          := get_inc_details_rec.email_add;
                        l_aops_cust_id        := get_inc_details_rec.aops_customer_id;
                        lc_contact_name       := get_inc_details_rec.contact_name;

                    -- Customer String
                     CUSTOMER_REC (P_CUSTOMER_ID  => L_CUSTOMER_ID,
                                  P_AOPS_CUST_ID => L_AOPS_CUST_ID,
                                  P_LOCATION_ID  => LN_LOCATION_ID,
                                  P_PHONE_NUMBER  => LC_PHONE_NUMBER,
                                  P_EMAIL_ADDRESS => LC_EMAIL_ID,
                                  P_CONTACT_NAME  => LC_CONTACT_NAME,
                                  x_initStr       => l_initStr);

                      -- Device String
                     DEVICE_REC (P_INCIDENT_ID   => L_INCIDENT_ID,
                                  P_DESCRIPTION   => NULL,
                                  P_PROB_DESCR    => LC_COMMENTS,
                                  P_VENDOR        => GC_VENDOR,
                                  x_initStr   => L_INITSTR);

                       --- Part String
                          PART_REC(p_request_number  => p_incident_number,
                                     p_request_id => l_incident_id,
                                     p_header_id  => ln_header_id,
                                     p_vendor       => gc_vendor,
                                     p_doc_type     => p_doc_type,
                                     x_sku_initStr  => l_sku_initStr);

                          l_initStr := l_initStr||l_sku_initStr;

              END LOOP;

               l_initStr := l_initStr||'</ns1:ODTechService>';

              begin
                l_msg_data := http_post (l_url,l_initStr) ;

              exception
                when others then
                  l_msg_data := 'In event  '||sqlerrm ;
                   Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                               ,p_error_message_code =>   'XX_CS_SR03_ERR_LOG'
                               ,p_error_msg          =>  l_msg_data);
                  -- dbms_output.put_line('error '||l_msg_data);
              end;

            IF lc_comments is not null then
               /****************************************************
                   -- Update comments
                   ****************************************************/
                  begin
                   UPDATE_COMMENTS (P_INCIDENT_NUMBER,
                                   GC_USER_NAME,
                                   LC_COMMENTS,
                                   L_RETURN_STATUS,
                                   L_MSG_DATA);
                  exception
                    when others then
                      l_msg_data := 'error while update comments  '||sqlerrm ;
                       Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                                   ,p_error_message_code =>   'XX_CS_SR04_ERR_LOG'
                                   ,p_error_msg          =>  l_msg_data);
                  end;
            end if;

            -- Cancel the PO
            IF LC_DEL_LOC = 'CAN' THEN
             BEGIN
               PO_Document_Control_PUB.control_document
                 (p_api_version      => 1.0,
                  p_init_msg_list    => FND_API.G_FALSE,
                  p_commit           => FND_API.G_FALSE,
                  x_return_status    => l_return_status,
                  p_doc_type         =>   'PO',
                  p_doc_subtype      =>   'STANDARD',
                  p_doc_id           =>   ln_header_id,
                  p_doc_num          =>   lc_doc_number,
                  p_release_id       =>   null,
                  p_release_num      =>   null,
                  p_doc_line_id      =>   null,
                  p_doc_line_num     =>   null,
                  p_doc_line_loc_id  =>   null,
                  p_doc_shipment_num =>   null,
                  p_action           =>   'CANCEL',
                  p_action_date      =>   sysdate,
                  p_cancel_reason    =>   'PO Cancel due to SR',
                  p_cancel_reqs_flag =>   null,
                  p_print_flag       =>   'N',
                  p_note_to_vendor   =>   null,
                  p_use_gldate       =>   null
                 );

                exception
                    when others then
                      l_msg_data := 'error while cancelling PO  '||sqlerrm ;
                       Log_Exception ( p_error_location     =>  'XX_CS_TDS_VEN_PKG.PART_OUTBOUND'
                                   ,p_error_message_code =>   'XX_CS_SR06_ERR_LOG'
                                   ,p_error_msg          =>  l_msg_data);
              end;
            END IF;

      END IF; -- DOC NUMBER
	END IF; -- incident


  END PART_OUTBOUND;
/*****************************************************************************/
FUNCTION PART_TASK (P_subscription_guid  IN RAW,
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
 lc_type_name             VARCHAR2(250);
 lc_task_name             VARCHAR2(250);
 lc_task_descr            VARCHAR2(250);
 ln_que_ans_id            NUMBER;
 lc_category              VARCHAR2(150);
 ln_status_id             number;
 lc_comments              varchar2(3000);
 lc_core_flag		          varchar2(1);
 -- AQ variables.
  enqueue_options     dbms_aq.enqueue_options_t;
  myParser            dbms_xmlparser.Parser;
  message_properties  dbms_aq.message_properties_t;
  message_handle      RAW(16);

  message             sys.XMLTYPE;
  v_document          dbms_xmldom.DOMDocument;

  l_initStr           VARCHAR2(30000);
  l_sku_initStr       VARCHAR2(30000);
  lc_incident_number  VARCHAR2(25);
  lc_order_number     varchar2(100);
  lc_status           varchar2(250);

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
                  tt.attribute6 core_flag,
                  tt.description,
                  tt.task_name,
                  tt.task_status_id
            FROM jtf_tasks_vl tt,
                 jtf_task_types_tl ty
           WHERE ty.task_type_id = tt.task_type_id
            AND  tt.task_id = p_task_id
            AND  tt.task_status_id = 11; -- Complete Status

   BEGIN

      /** Detect the event raised and determine necessary parameters depending on the event **/

      IF l_event_name  = 'oracle.apps.jtf.cac.task.updateTask'  THEN
          l_source_object_code    := p_event.GetValueForParameter('SOURCE_OBJECT_TYPE_CODE');
          l_source_object_id      := p_event.GetValueForParameter('SOURCE_OBJECT_ID');

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
                       l_user_id               := get_task_dtls_rec.last_updated_by ;
                       gc_vendor               := get_task_dtls_rec.vendor;
                       lc_category             := get_task_dtls_rec.category;
                       lc_task_name            := get_task_dtls_rec.type_name;
                       ln_status_id		     := get_task_dtls_rec.Task_status_id;
                       lc_core_flag		     := get_task_dtls_rec.core_flag;

			IF lc_task_name like 'TDS Core Part Task'
			   and lc_core_flag = 'Y' then

                            l_initStr   := '<?xml version="1.0"  encoding="UTF-8" ?> <Root-Element><ODTDSParts>';
                            l_initStr  := l_initStr||Make_Param_Str
                                        ('request_id',l_incident_id);
                            l_initStr  := l_initStr||Make_Param_Str
                                        ('task_id',l_event_key);
                            l_initStr := l_initStr||'</ODTDSParts></Root-Element>';

				        myParser := dbms_xmlparser.newParser;
                                        dbms_xmlparser.parseBuffer(myParser, l_initStr);
                                        v_document := dbms_xmlparser.getDocument(myParser);
                                        message := DBMS_XMLDOM.GETXMLTYPE(v_document);

                                          BEGIN
                                           dbms_aq.enqueue(queue_name => 'xx_cs_tds_parts_queue',
                                                      enqueue_options => enqueue_options,
                                                      message_properties => message_properties,
                                                      payload => message,
                                                      msgid => message_handle);


                                          L_MSG_DATA  := 'SUCCESS - Message Created in AQ';
                                          EXCEPTION
                                            WHEN OTHERS THEN
                                              L_RETURN_STATUS := 'E';
                                              L_MSG_DATA  := 'Error while enqueue message. '||sqlerrm;

                                          END;

                                    commit;

			end if;
                      end if;
             END LOOP;
        END IF; -- SR
      END IF;  -- event
END;
/********************************************************************************/

PROCEDURE DM_PROC (P_REQUEST_NUMBER    IN VARCHAR2,
                      P_REQUEST_ID        IN NUMBER,
                      X_DOC_NUMBER        IN OUT VARCHAR2,
                      X_RETURN_STATUS     IN OUT NOCOPY VARCHAR2,
                      X_RETURN_MSG        IN OUT NOCOPY VARCHAR2)
IS

ln_task_number    	    number;
lc_task_name      	    varchar2(150);
lc_task_descr     	    varchar2(250);
lc_vendor_site_code	    varchar2(25);
ln_invoice_id           number;
ln_invoice_line_id      number;
lc_invoice_num          varchar2(15);
ln_request_id           number;
lc_accts_pay_ccid       varchar2(50);
lc_dist_code_combination_id varchar2(50);
lv_currency_code        varchar2(5) := 'USD';
ln_org_id               number;
I                       number;

CURSOR PARTS_CUR IS
SELECT JL.TASK_ID,
       JL.TASK_NAME,
       JL.DESCRIPTION,
       JL.ATTRIBUTE7,
       NVL(JL.ATTRIBUTE8,20) AMT
FROM JTF_TASKS_VL JL,
     JTF_TASK_TYPES_TL JT
WHERE JT.TASK_TYPE_ID = JL.TASK_TYPE_ID
AND JT.NAME LIKE 'TDS%Core%'
AND JL.SOURCE_OBJECT_ID = p_request_id
AND JL.SOURCE_OBJECT_TYPE_CODE = 'SR';

parts_rec  parts_cur%rowtype;

BEGIN

         begin
            -- Insert into Header interface table
            SELECT ap_invoices_interface_s.NEXTVAL
              INTO ln_invoice_id
              FROM DUAL;
         exception
          when others then
              x_return_status  := 'E';
              x_return_msg     := 'Error while getting invoice seq '||sqlerrm;
         end;

         lc_invoice_num := 'CR-'||ln_invoice_id;

               SELECT pl.vendor_site_code,  pa.org_id
               into	lc_vendor_site_code, ln_org_id
	                 FROM po_headers_all pa,
	                      po_vendor_sites_all pl
	                 WHERE pl.vendor_site_id = pa.vendor_site_id
	                 and  pa.vendor_id = pl.vendor_id
                   and  pa.segment1 = p_request_number;

          --- dbms_output.put_line('debit_memo '||ln_invoice_id);

           INSERT INTO ap_invoices_interface
                        (invoice_id,
                         invoice_num,
                         invoice_type_lookup_code,
                         vendor_name,
                         vendor_site_code,
                         invoice_amount,
                         org_id,
                         invoice_date,
                         description,
                         invoice_currency_code,
                         source,
                         attribute7,
                         attribute6,
                         terms_name,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by
                        )
                 VALUES (ln_invoice_id,
                          lc_invoice_num,
                          'DEBIT',
                         'NEXICORE SERVICES',
                          lc_vendor_site_code,
                          20,
                          ln_org_id,
                         sysdate,
                         'For core part',
                         lv_currency_code,
                         'US_OD_TDS_CORE_RETURNS',
                         'US_OD_TDS_CORE_RETURNS',
                         p_request_number,
                         '00',
                         SYSDATE,
                         uid,
                         SYSDATE,
                         uid
                        );


            SELECT    segment1
                   || '.'
                   || segment2
                   || '.'
                   || fnd_profile.VALUE ('XX_TDS_PARTS_MAT_ACCOUNT')
                   || '.'
                   || segment4
                   || '.'
                   || segment5
                   || '.'
                   || segment6
                   || '.'
                   || Segment7
              INTO lc_dist_code_combination_id
              FROM gl_code_combinations
             WHERE code_combination_id =
                      (SELECT material_account
                         From Mtl_Parameters
                        Where Organization_Id = ln_org_id
                      );

      -- Derive Line values
      FOR parts_rec IN parts_cur
      LOOP
         I := I + 1;

            SELECT ap_invoice_lines_interface_s.NEXTVAL
              INTO ln_invoice_line_id
              FROM DUAL;

            DBMS_OUTPUT.PUT_LINE('ln_invoice_line_id'||ln_invoice_line_id);
            BEGIN
               -- Insert into Line Interface table
               INSERT INTO ap_invoice_lines_interface
                           (invoice_id,
                            invoice_line_id,
                            line_number,
                            line_type_lookup_code,
                            amount,
                            DIST_CODE_CONCATENATED,
                            task_id,
                            description,
                            creation_date,
                            created_by,
                            last_update_date,
                            last_updated_by)
                    VALUES (ln_invoice_id,
                            ln_invoice_line_id,
                            I,
                            'ITEM',
                            parts_rec.amt,
                            lc_dist_code_combination_id,
                            parts_rec.task_id,
                            parts_rec.description||' Tracking Number '||parts_rec.ATTRIBUTE7,
                            SYSDATE,
                            uid,
                            SYSDATE,
                            uid
                           );
                     DBMS_OUTPUT.PUT_LINE('Inserted INTO ap_invoice_lines_interface');
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_return_status := fnd_api.g_ret_sts_error;
                  x_return_msg :=
                        'Error in inserting into ap_invoice_lines_interface: '
                     || SQLERRM;
                  DBMS_OUTPUT.PUT_LINE('x_msg_data:'||x_return_msg);
                  log_exception
                     (p_error_location          => 'XX_CS_TDS_AP_INVOICE_PKG.INSERT_PROC',
                      p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                      p_error_msg               => x_return_msg
                     );
            END;

      END LOOP;

      IF (x_return_status <>  fnd_api.g_ret_sts_error) THEN
        x_doc_number := lc_invoice_num;
        COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_msg := 'Error in insert procedure ' || SQLERRM;
         ROLLBACK;
         log_exception
                 ( p_error_location          => 'XX_CS_TDS_PARTS_REC_VEN_PKG.DEBIT_PROC',
                  p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                  p_error_msg               => x_return_msg
                 );
END DM_PROC;
/**********************************************************************************
***********************************************************************************/
END XX_CS_TDS_PARTS_VEN_PKG;
/
show errors;
exit;