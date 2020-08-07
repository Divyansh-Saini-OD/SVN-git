create or replace
PACKAGE BODY "XX_CS_CLOSE_LOOP_PKG" AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_CLOSE_LOOP_PKG.pkb                                                      |
-- |                                                                                         |
-- | Description      : Package Body containing Close Loop procedures                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       28-Jul-08        Raj Jagarlamudi        Initial draft version                  |
-- |                                                                                         |
-- +=========================================================================================+
/***********************************************************************
  -- Get AQ MESSAGES
************************************************************************/
--| <SHOWDELIVERY>
--|   <ORDER_NUMBER>1234</ORDER_NUMBER>
--|   <SOURCE_CODE>M</SOURCE_CODE>
--|   <STATUS_CODE>50</STATUS_CODE>
--|   <ACTUAL_DELIVERY_DATE>06-02-2008 9:30:00</ACTUAL_DELIVERY_DATE>
--| </SHOWDELIVERY>  
--|----------------------------------------------------------------------
PROCEDURE GET_AQ_MESSAGE (P_RETURN_CODE OUT NOCOPY NUMBER,
                          P_ERROR_MSG OUT NOCOPY VARCHAR2)
AS

 v_document dbms_xmldom.DOMDocument; 
  v_node_list dbms_xmldom.DOMNodeList; 
  v_node dbms_xmldom.DOMNode; 
  v_ele dbms_xmldom.DOMElement; 
  v_childnode dbms_xmldom.DOMNode; 
  ndoc dbms_xmldom.DOMNode; 

  v_nodename        varchar2(50);
  v_xml             XMLType; 
  v_len             number; 
  lc_order_num      varchar2(50);
  lc_status_code    varchar2(3);
  lc_source_code    varchar2(1);
  lc_return_status  varchar2(50);
  lc_return_msg     varchar2(1000);
  ld_delivery_date  Date;
  lc_comments       varchar2(2000);
  lc_status_msg     varchar2(100);
  
  dequeue_options      dbms_aq.dequeue_options_t;
  message_properties   dbms_aq.message_properties_t;
  message_handle       RAW(16);
  message              sys.XMLTYPE; 
  ln_status_code       number;
  cnt                  NUMBER := 0;
  cnt_max              NUMBER := 1000;
  no_messages          EXCEPTION;
  pragma  EXCEPTION_INIT (no_messages, -25228);
  
cursor c_msg_ids is
select msgid 
from xx_cs_xml_qtab
where upper(q_name) = upper('xx_cs_xml_queue');
  
BEGIN 
   dequeue_options.wait := DBMS_AQ.NO_WAIT;
   dequeue_options.navigation := DBMS_AQ.FIRST_MESSAGE;
   --dequeue_options.dequeue_mode := dbms_aq.remove_nodata;
   --cnt := 0;
  
 For v_msg_id in c_msg_ids loop
 
   lc_return_msg := 'MSGID '||v_msg_id.msgid||' Count :'||cnt;
   fnd_file.put_line(fnd_file.log,lc_return_msg); 
   dequeue_options.msgid := v_msg_id.msgid;
   cnt := 0;
   begin        
    dbms_aq.dequeue(
    queue_name            => 'XX_CS_XML_QUEUE',
    dequeue_options       => dequeue_options,
    message_properties    => message_properties,
    payload               => message,
    msgid                 => message_handle);
    COMMIT;
    v_xml   := message; 
    --dbms_output.put_line('Message id : '||v_msg_id.msgid||' removed');

    cnt := cnt + 1;
    dequeue_options.msgid := null;
    dequeue_options.navigation := DBMS_AQ.NEXT_MESSAGE;
    
    EXCEPTION
      when others then
        lc_return_msg := 'error while dequeue message '||sqlerrm; 
        p_error_msg := lc_return_msg;
        p_return_code := 2;
        fnd_file.put_line(fnd_file.log,lc_return_msg);
    end;
    
   v_document := dbms_xmldom.newdomdocument(v_xml); 
   ndoc := dbms_xmldom.makeNode(v_document); 
   v_node_list := dbms_xslprocessor.selectNodes(ndoc,'/SHOWDELIVERY/*'); 
   --dbms_output.put_line('node list '|| dbms_xmldom.getLength(v_node_list));
  
   v_len := dbms_xmldom.getLength(v_node_list); 

    FOR j IN 1..dbms_xmldom.getLength(v_node_list) LOOP 

      v_node      := dbms_xmldom.item(v_node_list, j-1); 
      v_ele       := dbms_xmldom.makeElement(v_node); 
      v_nodename  := dbms_xmldom.getTagName(v_ele);
      v_childnode := dbms_xmldom.getFirstChild(v_node); 

  --dbms_output.put_line('node name '||v_nodename);
  
      If v_nodename = 'ORDER_NUMBER' then 
        lc_order_num := dbms_xmldom.getNodeValue(v_childnode) ;
      elsif v_nodename = 'SOURCE_CODE' then 
        lc_source_code := dbms_xmldom.getNodeValue(v_childnode); 
      elsif v_nodename = 'STATUS_CODE' then 
        lc_status_code := dbms_xmldom.getNodeValue(v_childnode);
      elsif v_nodename = 'ACTUAL_DELIVERY_DATE' then 
        ld_delivery_date := to_date(dbms_xmldom.getNodeValue(v_childnode),'yyyy/mm/dd hh24:mi:ss');
      end if;
                        
    END LOOP; 
   
   lc_return_msg := 'Source Code '||lc_source_code;
   fnd_file.put_line(fnd_file.log,lc_return_msg); 
   
   --dbms_output.put_line('Source Code '||lc_source_code);
   
   If lc_source_code = 'M' then  -- Mobile cast message
    
       if lc_status_code = 50 then
          lc_status_msg := 'Completed';
       else 
          lc_status_msg := 'Not Completed';
       end if;
        lc_comments := ' Delivery status: '||lc_status_msg||'  through Mobile cast. at: '||ld_delivery_date;
     
    else  -- UPS message
      lc_comments := ' Delivery status: '||lc_status_code||' through UPS. at: '||ld_delivery_date;
    end if;
    
    lc_return_msg := 'Order Number: '||lc_order_num;
    fnd_file.put_line(fnd_file.log,lc_return_msg);
    --dbms_output.put_line('Order Number '||ln_order_num);
    If lc_order_num is not null then
        -- Update Service Request
        begin
          update_sr_status( p_order_number => lc_order_num,
                            p_message => lc_comments,
                            p_status_code => lc_status_code,
                            x_return_status => lc_return_status,
                            x_return_msg => lc_return_msg);
                            
            p_error_msg := lc_return_msg;
            p_return_code := 0;
            
        exception
          when others then
            p_error_msg := lc_return_msg;
            p_return_code := 2;
            fnd_file.put_line(fnd_file.log,lc_return_msg);
        end;
    else
         p_error_msg := 'No Orders to Process';
         p_return_code := 0;
    end if;
    
  end loop;
   EXCEPTION
       WHEN no_messages then
         lc_return_msg := 'No of Messages Removed: '||cnt;
         fnd_file.put_line(fnd_file.log,lc_return_msg);
                        
END GET_AQ_MESSAGE;

/***********************************************************************
  -- Update SR status
************************************************************************/

PROCEDURE UPDATE_SR_STATUS (P_ORDER_NUMBER    IN VARCHAR2,
                            P_MESSAGE         IN VARCHAR2,
                            P_STATUS_CODE     IN VARCHAR2,
                            X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MSG      IN OUT NOCOPY VARCHAR2)
AS

      x_msg_count	 NUMBER;
      x_interaction_id   NUMBER;
      ln_obj_ver         NUMBER;
      lc_sr_status       VARCHAR2(25);
      ln_status_id       number;
      ln_msg_index       number;
      ln_msg_index_out   number;
      ln_user_id         number; 
      ln_resp_appl_id    number :=  514;
      ln_resp_id         number := 21739;  
      ln_request_id      number;
      LT_SR_NOTES        XX_CS_SR_NOTES_REC;
BEGIN

    begin
      select user_id
      into ln_user_id
      from fnd_user
      where user_name = 'CS_ADMIN';
    exception
      when others then
        x_return_status := 'F';
        x_return_msg := 'Error while selecting userid '||sqlerrm;
    end;
   /********************************************************************
    --Apps Initialization
    *******************************************************************/
    apps.fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_appl_id);
    lt_sr_notes := XX_CS_SR_NOTES_REC(null,null,null,null);
   /************************************************************************
    -- Get IncidentId and Object version
    *********************************************************************/
    --dbms_output.put_line('Order Number' ||p_order_number);
    begin
      SELECT incident_id, object_version_number
      into ln_request_id , ln_obj_ver
      FROM   cs_incidents_all_b 
      WHERE  incident_status_id <> 2
      and    decode(incident_attribute_12, null,incident_attribute_1, incident_attribute_12) = p_order_number
      and    problem_code in ('LATE DELIVERY', 'RETURN NOT PICKED UP')
      and    exists ( select 'x' 
                     from cs_incident_types_tl
                     where name = 'Stocked Products'
                     and incident_type_id = cs_incidents_all_b.incident_type_id) 
      and  rownum < 2;
    exception
      when others then
        x_return_status := 'F';
        x_return_msg := 'Error while Request Id '||sqlerrm;
    end;
    
      /*********************************************************************
        -- Get Status 
      **********************************************************************/
      BEGIN
        SELECT NAME, INCIDENT_STATUS_ID
        INTO LC_SR_STATUS, LN_STATUS_ID
        FROM CS_INCIDENT_STATUSES_VL
        WHERE INCIDENT_SUBTYPE = 'INC'
        AND NAME  = 'Closed';  -- Closed Status
      EXCEPTION
        WHEN OTHERS THEN
          x_return_status := 'F';
          x_return_msg := 'Error while Status Id '||sqlerrm;
      END;
    
    IF NVL(X_RETURN_STATUS,'S') <> 'F' THEN
    /***********************************************************************
     -- Update SR
     ***********************************************************************/
    IF ln_request_id IS NOT NULL THEN
      IF P_STATUS_CODE = 50 THEN
            BEGIN
             CS_SERVICEREQUEST_PUB.Update_Status
              (p_api_version		=> 2.0,
              p_init_msg_list	        => FND_API.G_TRUE,
              p_commit		=> FND_API.G_FALSE,
              x_return_status	        => x_return_status,
              x_msg_count	        => x_msg_count,
              x_msg_data		=> x_return_msg,
              p_resp_appl_id	        => ln_resp_appl_id,
              p_resp_id		=> ln_resp_id,
              p_user_id		=> ln_user_id,
              p_login_id		=> NULL,
              p_request_id		=> ln_request_id,
              p_request_number	=> NULL,
              p_object_version_number => ln_obj_ver,
              p_status_id	 	=> ln_status_id,
              p_status		=> lc_sr_status,
              p_closed_date		=> SYSDATE,
              p_audit_comments	=> NULL,
              p_called_by_workflow	=> NULL,
              p_workflow_process_id	=> NULL,
              p_comments		=> NULL,
              p_public_comment_flag	=> NULL,
              x_interaction_id	=> x_interaction_id);
      
              commit;
              
            EXCEPTION
              WHEN OTHERS THEN
                 x_return_status := 'F';
                 x_return_msg := x_return_msg;
            END;
    
    END IF;
    
      --Add note
        lt_sr_notes.notes          := 'Close Loop Process ';
        lt_sr_notes.note_details   := p_message;
       BEGIN
                                         
            XX_CS_SR_UTILS_PKG.CREATE_NOTE (p_request_id   => ln_request_id,
                                             p_sr_notes_rec => lt_sr_notes,
                                             p_return_status => x_return_status,
                                             p_msg_data => x_return_msg);
            commit;
         exception
           when others then
              x_return_msg := 'Error while ADDING notes '||sqlerrm;
         END ; 
         
      end if;  -- Request Id Check
    END IF; -- Status Check
END UPDATE_SR_STATUS;

END XX_CS_CLOSE_LOOP_PKG;
/
SHOW ERRORS;
EXIT;