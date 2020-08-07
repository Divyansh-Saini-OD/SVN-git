create or replace 
PACKAGE BODY XX_WSH_TRACKING_NBR_REPROCESS
AS
-- +========================================================================================================================+
-- |                  Office Depot - Project Simplify                                                                       |
-- |                  Office Depot                                                                                          |
-- +========================================================================================================================+
-- | Name  : XX_WSH_TRACKING_NBR_REPROCESS                                                                                  |
-- | Rice ID: I1272                                                                                                         |
-- | Description      : This Program will re-process the tracking number from EBIZ to DB2                                   |
-- |                                                                                                                        |
-- |                                                                                                                        |
-- |Change Record:                                                                                                          |
-- |===============                                                                                                         |
-- |Version     Date          Author                     Remarks                                                            |
-- |=======     ==========    =============              ==============================                                     |
-- |DRAFT 1A    18-OCT-2017   Venkata Battu              Initial draft version                                              |
-- +========================================================================================================================+

-- global variables declaration
g_def_debug    NUMBER  :=0;
g_debug_lvl    NUMBER;         

PROCEDURE write_debug(p_msg IN VARCHAR2)
IS
BEGIN
     IF g_debug_lvl <> g_def_debug
	 THEN
     fnd_file.put_line(fnd_file.LOG,p_msg);
	 END IF;
END;
PROCEDURE write_log(p_mode IN VARCHAR2 
                   ,p_msg IN VARCHAR2)
IS
BEGIN
   IF p_mode ='L'
   THEN 
      fnd_file.put_line(fnd_file.LOG,p_msg);
   ELSE 	  
     fnd_file.put_line(fnd_file.OUTPUT,p_msg);
   END IF;	 
END;
FUNCTION get_loc(p_loc_id IN NUMBER)
RETURN VARCHAR2
IS
lc_loc_code VARCHAR2(100); 
BEGIN
SELECT SUBSTR(hl.location_code,1,6)
  INTO lc_loc_code
  FROM apps.hr_locations hl
 WHERE hl.location_id  = p_loc_id;
RETURN  lc_loc_code;
EXCEPTION 
WHEN OTHERS
THEN 
    lc_loc_code := NULL;
    RETURN  lc_loc_code;	
END;	 
PROCEDURE process_data( p_tracking_id  IN  NUMBER
                       ,p_order_nbr    IN  VARCHAR2
                       ,p_delivery_id  IN  NUMBER
                       ,p_trip_id      IN  NUMBER
                      )
IS                      
-- Variable Declarations
lc_hosturl                     VARCHAR2(2000);
lc_username                    VARCHAR2(30):=NULL;
lc_password                    VARCHAR2(30):=NULL;
ln_consumer_transaction_id     VARCHAR2(250);
lc_soap_request                VARCHAR2 (32500);
lc_soap_respond                VARCHAR2 (32500);
lr_http_request                UTL_HTTP.req;
lr_http_response               UTL_HTTP.resp; 
resp                           XMLTYPE;
lc_resp_statuscode             VARCHAR2(500)  := null;
lc_resp_statusdesc             VARCHAR2(2000) := null;
lc_location_code               VARCHAR2(20);     					  
Invoke_exception                EXCEPTION;  
ln_user_id   	                  NUMBER :=  FND_GLOBAL.USER_ID;
CURSOR tracking_cur                                                                                                         
    IS                                                                                 
    SELECT xt.tracking_id                                   
          ,xt.order_nbr
          ,xt.order_dt
          ,xt.delivery_dt
          ,xt.delivery_id
          ,xt.trip_id
          ,xt.container_id
          ,xt.lane_nbr
          ,xt.src_loc_id
          ,xt.loc_id
          ,xt.statuscode
          ,xt.statusdesc
  FROM apps.xx_wsh_ship_lbl_tracking xt 
 WHERE NVL(xt.statuscode,-2) <>'0'
   AND xt.tracking_id  = NVL(p_tracking_id,xt.tracking_id) 
   AND xt.order_nbr    = NVL(p_order_nbr,xt.order_nbr)     
   AND xt.delivery_id  = NVL(p_delivery_id,xt.delivery_id) 
   AND xt.trip_id      = NVL(p_trip_id,xt.trip_id);
CURSOR get_service_params_cur 
    IS
      SELECT  xftv.source_value1
	         ,xftv.target_value1
        FROM  xx_fin_translatedefinition xftd
	         ,xx_fin_translatevalues xftv
	   WHERE  xftd.translate_id = XFTV.translate_id
	     AND  xftd.translation_name = 'OD_SHIP_OUTBOUND_SERVICE'
	     AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
	     AND  SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
	     AND  xftv.enabled_flag = 'Y'
         AND  xftd.enabled_flag = 'Y';    
BEGIN
     -- -------------------------------------------------------
     -- Get web service values 
     -- -------------------------------------------------------
     FOR get_service_params_rec IN get_service_params_cur 
     LOOP
        IF get_service_params_rec.source_value1 = 'URL' THEN
           lc_hosturl := get_service_params_rec.target_value1;
        ELSIF get_service_params_rec.source_value1 = 'USERNAME' THEN
	       lc_username := get_service_params_rec.target_value1;
        ELSIF get_service_params_rec.source_value1 = 'PASSWORD' THEN
	       lc_password := xx_encrypt_decryption_toolkit.decrypt(get_service_params_rec.target_value1);
        END IF;
     END LOOP;                                                                                                                         
            
     FOR track IN  tracking_cur
     LOOP
     BEGIN  	 
        write_log('L','Procesing tracking_id -'||track.tracking_id);                                                                                                                                                                                               
        ln_consumer_transaction_id := 'EBIZ'||TO_CHAR(track.tracking_id);
		lc_location_code  := get_loc(track.src_loc_id);
        IF lc_location_code IS NULL
        THEN
            lc_resp_statusdesc := 'Unable to derive the location for location_id '|| track.src_loc_id;
            RAISE invoke_exception;
        END IF; 			
             lc_soap_request :='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
		    xmlns:tran="http://www.officedepot.com/model/transaction" 
		    xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		    xmlns:ord="http://eai.officedepot.com/model/Order">
				 <soapenv:Header/>
				 <soapenv:Body>
				   <non:noneTradeShipmentTrackingRequest>
				   <tran:transactionHeader>
				       <tran:consumer>
					   <tran:consumerName>EBIZ</tran:consumerName>
					   <tran:consumerTransactionID>'||ln_consumer_transaction_id||'</tran:consumerTransactionID>
					</tran:consumer>
				    </tran:transactionHeader>
				   <non:trackingNumber>'||to_char(track.tracking_id)||'</non:trackingNumber>
				   <non:locationId>'||lc_location_code||'</non:locationId>
				   <non:orderDate>'||TO_CHAR(track.order_dt,'YYYY-MM-DD')||'</non:orderDate>
				   <non:orderHeader>
				       <ord:orderNumber>'||TO_CHAR(track.order_nbr)||'</ord:orderNumber>
				    </non:orderHeader>
				    <non:deliveryDate>'||TO_CHAR(TO_DATE(track.delivery_dt,'DD-MON-YY'),'RRRR-MM-DD')||'</non:deliveryDate>
				   <non:containerId>'||track.container_id||'</non:containerId>
				   <non:laneNumber>'||track.lane_nbr||'</non:laneNumber>
				   <non:deliveryId>'||TO_CHAR(track.delivery_id)||'</non:deliveryId>
				  </non:noneTradeShipmentTrackingRequest>
				 </soapenv:Body>
				</soapenv:Envelope>';
			write_debug('SOAP Request :');	
            write_debug(lc_soap_request);
			write_log('L','Before SOAP request call' ); 
			lr_http_request :=  UTL_HTTP.begin_request (lc_hosturl, 'POST', 'HTTP/1.1');
			write_debug(' After lr_http_request: ');
            IF lc_username IS NOT NULL THEN
               UTL_HTTP.set_authentication(lr_http_request,lc_username,lc_password);
            END IF;                                                                                                                                                                                           
            UTL_HTTP.set_header (lr_http_request, 'Content-Type', 'text/xml');
			write_debug(' After UTL_HTTP.set_header step-1');
            -- since we are dealing with plain text in XML documents
            UTL_HTTP.set_header(lr_http_request,'Content-Length',LENGTH (lc_soap_request));
			write_debug(' After UTL_HTTP.set_header step-2');
            UTL_HTTP.set_header(lr_http_request, 'SOAPAction', '');
			write_debug(' After UTL_HTTP.set_header step-3');
            -- required to specify this is a SOAP communication
            UTL_HTTP.write_text(lr_http_request, lc_soap_request);
			write_debug(' After UTL_HTTP.write_text step-4');
            lr_http_response := UTL_HTTP.get_response (lr_http_request);
			write_debug(' After UTL_HTTP.get_response step-5');
            UTL_HTTP.read_text (lr_http_response, lc_soap_respond);
            write_debug('Response Message:'||lc_soap_respond);
            UTL_HTTP.end_response(lr_http_response);
			write_debug('UTL_HTTP.end_response Step-6');
            resp := XMLTYPE.createxml (lc_soap_respond);
            lc_resp_statuscode := null;
            lc_resp_statusdesc := null;
             /* Check if invoke is success */
			write_debug('Response code  : '||lr_http_response.status_code ); 
			write_log('L','Response code  : '||lr_http_response.status_code ); 
        IF (lr_http_response.status_code = 200)
	     THEN
		   BEGIN
		    SELECT EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusCode',
		          'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		           xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),
		           SUBSTR(EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusDescription',
		          'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		           xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),1,2000)
		     INTO lc_resp_statuscode,lc_resp_statusdesc
		     FROM dual; 
		     --check statuscode if response from service is fault message
		     IF lc_resp_statuscode IS NULL THEN
		        lc_resp_statuscode := '-2';
		        lc_resp_statusdesc := SUBSTR('statuscode not found(fault message)'||lc_soap_respond,1,2000);
				write_log('L','Tracking ID: '||track.tracking_id ||' '||lc_resp_statusdesc ); 
             END IF;
 	        EXCEPTION
		    WHEN others THEN
		        lc_resp_statuscode := '-2';
		        lc_resp_statusdesc := SUBSTR('Error occured while deriving status code from response message'||SUBSTR(sqlerrm,1,250)||lc_soap_respond,1,2000);
				write_debug(lc_resp_statusdesc);
		    END;
		
		  UPDATE xx_wsh_ship_lbl_tracking
		   SET statuscode = lc_resp_statuscode --need to confirm
		      ,statusdesc = lc_resp_statusdesc
		      ,last_updated_by = ln_user_id
		      ,last_update_date = sysdate                       
		   WHERE tracking_id = track.tracking_id;
		    write_debug('Tracking Number is Sent Successfully for :'||track.tracking_id);
        ELSE --If invoke is not success
	        lc_resp_statuscode := '-2';
	        lc_resp_statusdesc := SUBSTR('Message Code:'||to_char(lr_http_response.status_code)||' Reason Phrase:'||lr_http_response.reason_phrase,1,2000);
	        write_log('L',lc_resp_statusdesc); 
			RAISE invoke_exception;
	     END IF;
	       
	     write_log('L','Response Code :'||lc_resp_statuscode);
	     write_log('L','respstatusdesc:'|| lc_resp_statusdesc);
	     
   EXCEPTION
      WHEN invoke_exception THEN
             UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	           ,statusdesc = lc_resp_statusdesc
	           ,last_updated_by = ln_user_id
	           ,last_update_date = sysdate                       
	      WHERE tracking_id = track.tracking_id; 
	  WHEN others THEN
	     lc_resp_statuscode := '-2'; 
	     lc_resp_statusdesc := SUBSTR('WHEN others'||sqlerrm,1,2000);
		   write_log('L',lc_resp_statusdesc); 
	     UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	 	   ,statusdesc = lc_resp_statusdesc
		   ,last_updated_by = ln_user_id
		   ,last_update_date = sysdate                       
	      WHERE tracking_id = track.tracking_id;
          write_debug('Update the staging table with error code and message'); 		  
          END;     
      END LOOP; 
	  COMMIT;
EXCEPTION
WHEN OTHERS
THEN
	write_log('L','Exception in process data Procedure :'||SQLERRM);  
END;					  
					  
PROCEDURE main( x_error_buff  OUT  VARCHAR2
               ,x_ret_code    OUT  VARCHAR2
               ,p_tracking_id  IN  NUMBER
               ,p_order_nbr    IN  VARCHAR2
               ,p_delivery_id  IN  NUMBER
               ,p_trip_id      IN  NUMBER
               ,p_debug_lvl    IN  NUMBER DEFAULT 0			   
	      )
IS
BEGIN
     write_log('L','Tracking Id    :'||p_tracking_id);
     write_log('L','Order Number   :'||p_order_nbr);
     write_log('L','Delivery Id    :'||p_delivery_id);
     write_log('L','Trip Id        :'||p_trip_id);
     write_log('L','Debug Level    :'||p_debug_lvl);
                                                                                                           
	  g_debug_lvl := p_debug_lvl;                                             
     -- Calling Process data procedure 
     process_data( p_tracking_id => p_tracking_id
                  ,p_order_nbr   => p_order_nbr
                  ,p_delivery_id => p_delivery_id
                  ,p_trip_id     => p_trip_id
                 );
EXCEPTION 
WHEN OTHERS
THEN
   write_log('L','Exception in Main Procedure :'||SQLERRM);
END; --main 			  
END XX_WSH_TRACKING_NBR_REPROCESS;
/
			  