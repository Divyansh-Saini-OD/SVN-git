create or replace
PACKAGE BODY XX_CS_CLOSE_LOOP_BPEL_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_CLOSE_LOOP_BPEL_PKG                                |
-- |                                                                   |
-- | Description: Extension for Close the Request based on Mobile cast |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-Apr-08   Raj Jagarlamudi  Initial draft version       |
-- |1.1       06-Jun-08   B. Penski        Added New Short Message     |
-- |1.2	      05-Jan-10   Raj Jagarlamudi  Added new status and logs   |
-- |1.3       25-Jan-16   Manikant Kasu	   Removed schema references as|
-- |	    	        					             per GSCC R12.2.2 Compliance.|
-- +===================================================================+
--|-------------------------------------------------------------
--| Name: AddToXMLMessage
--| Purpose: Defines the small generic proof of delivery message
--|  to be enqueue onto XX_CS_XML_QUEUE queue. The message has the
--|  following structure:
--| <SHOWDELIVERY>
--|   <ORDER_NUMBER>1234</ORDER_NUMBER>
--|   <SOURCE_CODE>M</SOURCE_CODE>
--|   <STATUS_CODE>50</STATUS_CODE>
--|   <ACTUAL_DELIVERY_DATE>06-02-2008 9:30:00</ACTUAL_DELIVERY_DATE>
--| </SHOWDELIVERY>
--|-------------------------------------------------------------

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
     ,p_program_type            => 'Close Loop Process'
     ,p_program_name            => 'XX_CS_CLOSE_LOOP_BPEL_PKG'
     ,p_program_id              => null
     ,p_module_name             => 'CS'
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
/*******************************************************************************
********************************************************************************/
PROCEDURE AddToXMLMessage(p_node_name IN VARCHAR2,
                          p_node_text IN VARCHAR2,
                          p_message IN OUT NOCOPY DBMS_XMLDOM.DOMdocument) IS

      main_node   DBMS_XMLDOM.domnode;
      root_node   DBMS_XMLDOM.domnode;
      root_elmt   DBMS_XMLDOM.domelement;
      item_elmt   DBMS_XMLDOM.domelement;
      item_node   DBMS_XMLDOM.domnode;
      item_text   DBMS_XMLDOM.DOMText;

    BEGIN

      IF DBMS_XMLDOM.ISNULL(p_message) THEN
        p_message := DBMS_XMLDOM.newdomdocument();

        --Add the root node
        main_node := DBMS_XMLDOM.makenode(p_message);
        root_elmt := DBMS_XMLDOM.createelement(p_message,   'SHOWDELIVERY');
        root_node := DBMS_XMLDOM.appendchild(main_node,   DBMS_XMLDOM.makenode(root_elmt));
      ELSE
        root_elmt := DBMS_XMLDOM.GETDOCUMENTELEMENT(p_message);
        root_node := DBMS_XMLDOM.MAKENODE(root_elmt);
      END IF;

      IF p_node_name IS NOT NULL THEN
          item_elmt := DBMS_XMLDOM.createElement(p_message, p_node_name);
          item_node := DBMS_XMLDOM.appendChild(root_node, DBMS_XMLDOM.makeNode(item_elmt));
          item_text := DBMS_XMLDOM.createTextNode(p_message,p_node_text);
          item_node := DBMS_XMLDOM.appendChild(item_node, DBMS_XMLDOM.makeNode(item_text));
      END IF;

END AddToXMLMessage;
--|----------------------------------------------------------------------------
--| Name: Get_Incident_Number
--| Purpose: checks if the order number provided has Service Request
--| attached.
--| Returns: 0 if SR number not found
--|----------------------------------------------------------------------------
FUNCTION GET_INCIDENT_NUMBER(p_orderNumber in VARCHAR2) return Number is
  ln_sr_num     NUMBER  := 0;
  lc_err_mesg   VARCHAR2(2000);
BEGIN

    /**********************************************************************************
       -- Rekey Order verification
    ***********************************************************************************/
    BEGIN

     SELECT incident_number
     INTO   ln_sr_num
     FROM   cs_incidents_all_b
     WHERE  incident_status_id <> 2
     and    decode(incident_attribute_12, null,incident_attribute_1,incident_attribute_12) = p_OrderNumber
     and    problem_code in ('LATE DELIVERY', 'RETURN NOT PICKED UP')
     and    exists ( select 'x'
                     from cs_incident_types_tl
                     where name = 'Stocked Products'
                     and incident_type_id = cs_incidents_all_b.incident_type_id)
    and    exists (  select 'x'
                      from cs_incident_statuses
                      where name in ('Resolved Future Promise', 'Close Loop')
                      and end_date_active is null
                      and incident_subtype = 'INC'
                      and incident_status_id = cs_incidents_all_b.incident_status_id)
    and   not exists ( select 'x' from cs_lookups
                 where lookup_type = 'XX_CS_CL_RESV_TYPES'
                 and enabled_flag = 'Y'
                 and end_date_active is null
                 and lookup_code = cs_incidents_all_b.resolution_code)
    and  rownum < 2;

   -- dbms_output.put_line('After select statemnet in GET_INCIDENT.. SRNO #'||ln_sr_num );

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         lc_err_mesg := 'No Close Loop SR for this Order '||p_OrderNumber;

      /*    Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.GET_INCIDENT_NUMBER'
                        ,p_error_message_code =>  'XX_CS_0001_SUCCESS_LOG'
                        ,p_error_msg          =>  lc_err_mesg
                        ); */
      WHEN OTHERS THEN
        ln_sr_num := 0;
        lc_err_mesg := 'Error While Selecting Incident no '||sqlerrm ||' for Order '||p_OrderNumber;

         Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.GET_INCIDENT_NUMBER'
                        ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                        ,p_error_msg          =>  lc_err_mesg
                        );
    END;

    return (ln_sr_num);

END GET_INCIDENT_NUMBER;
--|-----------------------------------------------------------
--| Name: Enqueue_Message
--| Purpose: Receive ShowShipment.xml and transforms it into
--| small generic xml message, which enqueues onto the a XX_CS_XML_QUEUE EBS AQ.
--|-----------------------------------------------------------
PROCEDURE ENQUEUE_MESSAGE(P_XML_MESSAGE IN VARCHAR2,
                          P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                          P_RETURN_MSG  IN OUT NOCOPY VARCHAR2) AS


  enqueue_options     dbms_aq.enqueue_options_t;
  myParser            dbms_xmlparser.Parser;
  message_properties  dbms_aq.message_properties_t;
  message_handle      RAW(16);

  doc_short_message   dbms_xmldom.DOMDocument;
  xml_output_message  XMLType;
  xml_show_shipment   sys.XMLTYPE;

  ndoc                dbms_xmldom.DOMNode;
  v_document          dbms_xmldom.DOMDocument;
  v_node_list         dbms_xmldom.DOMNodeList;
  v_node              dbms_xmldom.DOMNode;
  v_ele               dbms_xmldom.DOMElement;
  v_childnode         dbms_xmldom.DOMNode;
  lc_localName        varchar2(200);
  lc_nodeName         varchar2(50);
  lc_order_num        varchar2(100) := 1;
  ln_sr_num           number;
  lc_source_code      VARCHAR2(10);
  lc_status_code      VARCHAR2(10);
  lc_delivery_date    VARCHAR2(100);
  ln_rowid            NUMBER ;

BEGIN

   BEGIN

    xml_show_shipment :=  xmltype.createxml(P_XML_MESSAGE);
    v_document        := DBMS_XMLDOM.newdomdocument(P_XML_MESSAGE);
    ndoc              := DBMS_XMLDOM.makeNode(v_document);

    -- Gets SOURCE_CODE
    v_node_list   := dbms_xslprocessor.selectNodes(ndoc,'/ShowShipment/DataArea/Shipment/ShipmentHeader/CarrierParty/PartyIDs/ID');
    v_node        := dbms_xmldom.item(v_node_list,0);

    v_childnode   := dbms_xmldom.getFirstChild(v_node);
    lc_source_code:= dbms_xmldom.getNodeValue(v_childnode);

    IF lc_source_code IS NULL THEN
      P_RETURN_CODE := 'E';
      P_RETURN_MSG  := 'No Value for the Source Code';
    ELSIF lc_source_code not in ('M','U') THEN
      P_RETURN_CODE := 'E';
      P_RETURN_MSG  := 'Source Code Value is other than M or U';
    END IF;

   EXCEPTION
    WHEN OTHERS THEN
      P_RETURN_CODE := 'E';
      P_RETURN_MSG  := 'Error while getting Source Code. '||sqlerrm;
       Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.ENQUEUE_MESSAGE'
                        ,p_error_message_code =>  'XX_CS_0001_UNEXPECTED_ERR'
                        ,p_error_msg          =>  P_RETURN_MSG
                        );
  END;

    IF NVL(P_RETURN_CODE,'S') <> 'E' THEN
     IF (lc_Source_code in ('M', 'U')) THEN

--      Gets ORDER_NUMBER
        v_node_list := dbms_xslprocessor.selectNodes(ndoc,'/ShowShipment/DataArea/Shipment/ShipmentHeader/DocumentReference/DocumentID/ID');
        v_node      := dbms_xmldom.item(v_node_list,0);
        v_childnode := dbms_xmldom.getFirstChild(v_node);
        lc_order_num := dbms_xmldom.getNodeValue(v_childnode);
        --Check the whether SR attached to this order or not.
   --     dbms_output.put_line('Before calling GET_INCIDENT_NUMBER lc_order_num' || lc_order_num)  ;
        ln_sr_num := GET_INCIDENT_NUMBER(lc_order_num);
    --    dbms_output.put_line('ln_sr_num' || ln_sr_num)  ;
        IF ln_sr_num <> 0 THEN

        BEGIN
--          Gets STATUS_CODE
            v_node_list   := dbms_xslprocessor.selectNodes(ndoc,'/ShowShipment/DataArea/Shipment/ShipmentHeader/Status/Code');
            v_node        := dbms_xmldom.item(v_node_list,0);
            v_childnode   := dbms_xmldom.getFirstChild(v_node);
            lc_status_code:= dbms_xmldom.getNodeValue(v_childnode);
           --  dbms_output.put_line('lc_status_code=' || lc_status_code);
           IF lc_status_code IS NULL THEN
             P_RETURN_CODE := 'E';
             P_RETURN_MSG  := 'No Value for the Status code attributes.';
           END IF;
--          Gets ACTUAL_DELIVERY_DATE
            v_node_list   := dbms_xslprocessor.selectNodes(ndoc,'/ShowShipment/DataArea/Shipment/ShipmentHeader/ActualDeliveryDateTime');
            v_node        := dbms_xmldom.item(v_node_list,0);
            v_childnode   := dbms_xmldom.getFirstChild(v_node);
            lc_delivery_date := dbms_xmldom.getNodeValue(v_childnode);
            lc_delivery_date := replace(lc_delivery_date,'T',' ');
            lc_delivery_date := replace(lc_delivery_date,'-','/');

--          Adds attributes to a short XML Message
            addToxmlMessage('ORDER_NUMBER',lc_order_num,doc_short_message);
            addToxmlMessage('SOURCE_CODE' ,lc_source_code,doc_short_message);
            addToxmlMessage('STATUS_CODE' ,lc_status_code,doc_short_message);
            addToxmlMessage('ACTUAL_DELIVERY_DATE',lc_delivery_date,doc_short_message);
            xml_output_message := DBMS_XMLDOM.GETXMLTYPE(doc_short_message);

          EXCEPTION
           WHEN OTHERS THEN
                P_RETURN_CODE := 'E';
                P_RETURN_MSG  := 'Error while adding attributes. '||sqlerrm;

                  Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.ENQUEUE_MESSAGE'
                        ,p_error_message_code =>  'XX_CS_0002_UNEXPECTED_ERR'
                        ,p_error_msg          =>  P_RETURN_MSG
                        );
          END;
            BEGIN
--          Enqueue the short message onto xx_cs_xml_queue
            dbms_aq.enqueue(queue_name => 'XX_CS_XML_QUEUE',
                        enqueue_options => enqueue_options,
                        message_properties => message_properties,
                        payload => xml_output_message,
                        msgid => message_handle);
              P_RETURN_CODE := 'Y';
              P_RETURN_MSG  := 'SUCCESS - Message Created in AQ';
            EXCEPTION
              WHEN OTHERS THEN
                P_RETURN_CODE := 'E';
                P_RETURN_MSG  := 'Error while enqueue message. '||sqlerrm;

                 Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.ENQUEUE_MESSAGE'
                        ,p_error_message_code =>  'XX_CS_0003_UNEXPECTED_ERR'
                        ,p_error_msg          =>  P_RETURN_MSG
                        );
            END;
          ELSE
           P_RETURN_CODE := 'E';
           P_RETURN_MSG  := 'No SR Created for this Order Number';
         /*    Log_Exception ( p_error_location     =>  'XX_CS_CLOSE_LOOP_BPEL.ENQUEUE_MESSAGE'
                        ,p_error_message_code     =>  'XX_CS_0001_SUCCESS_LOG'
                        ,p_error_msg              =>  P_RETURN_MSG
                        ); */
          END IF;
     END IF;
   END IF;
  commit;
  END ENQUEUE_MESSAGE;

END XX_CS_CLOSE_LOOP_BPEL_PKG;
/
show errors;
exit;