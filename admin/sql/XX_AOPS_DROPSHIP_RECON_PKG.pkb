create or replace 
PACKAGE BODY XX_AOPS_DROPSHIP_RECON_PKG                                                                                                                                                              
-- +=========================================================================+                                                                                                                          
-- |                  Office Depot - Project Simplify                        |                                                                                                                          
-- +=========================================================================+                                                                                                                          
-- | Name             : XX_AOPS_DROPSHIP_RECON_PKG                           |                                                                                                                          
-- | RICE ID 	      : AOPS DropShip Recon  		             	         |                                                                                                                                   
-- | Description      : 						                             |                                                                                                                                            
-- |                                                                         |                                                                                                                          
-- |                                                                         |                                                                                                                          
-- |Change Record:                                                           |                                                                                                                          
-- |===============                                                          |                                                                                                                          
-- |Version    Date          Author            Remarks                       |                                                                                                                          
-- |=======    ==========    =============     ==============================|                                                                                                                          
-- |    1.0    08/09/2017    Avinash Baddam    Initial code                  |                                                                                                                          
-- |    1.1    04/20/2018    Havish Kasina     Added Regular expression      |                                                                                                                          
-- |                                           function to remove the special|                                                                                                                          
-- |                                           characters                    |                                                                                                                          
-- |    1.2    05/17/2018    Suresh Ponnambalam Correct sub order number     | 
-- |    1.3    06/14/2018    Venkateshwar Panduga  Defect#45046 - Data sent  | 
-- |                                               to AOPS by the program OD |
-- |                                               AOPS DropShip Recon is not|
-- |                                                 closing Orders in AOPS  |
-- +=========================================================================+                                                                                                                          
AS                                                                                                                                                                                                      
                                                                                                                                                                                                        
-- +============================================================================================+                                                                                                       
-- |  Name	 : Log Exception                                                            	    |                                                                                                           
-- |  Description: The log_exception procedure logs all exceptions				                |                                                                                                                 
-- =============================================================================================|                                                                                                       
gc_debug 	VARCHAR2(2);                                                                                                                                                                                  
gn_request_id   fnd_concurrent_requests.request_id%TYPE;                                                                                                                                                
gn_user_id      fnd_concurrent_requests.requested_by%TYPE;                                                                                                                                              
gn_login_id    	NUMBER;                                                                                                                                                                                 
                                                                                                                                                                                                        
PROCEDURE log_exception (p_program_name       IN  VARCHAR2                                                                                                                                              
                         ,p_error_location     IN  VARCHAR2                                                                                                                                             
		         ,p_error_msg          IN  VARCHAR2)                                                                                                                                                          
IS                                                                                                                                                                                                      
   ln_login     NUMBER                :=  FND_GLOBAL.LOGIN_ID;                                                                                                                                          
   ln_user_id   NUMBER                :=  FND_GLOBAL.USER_ID;                                                                                                                                           
BEGIN                                                                                                                                                                                                   
XX_COM_ERROR_LOG_PUB.log_error(                                                                                                                                                                         
			     p_return_code             => FND_API.G_RET_STS_ERROR                                                                                                                                            
			    ,p_msg_count               => 1                                                                                                                                                                  
			    ,p_application_name        => 'XXFIN'                                                                                                                                                            
			    ,p_program_type            => 'Custom Messages'                                                                                                                                                  
			    ,p_program_name            => p_program_name                                                                                                                                                     
			    ,p_attribute15             => p_program_name                                                                                                                                                     
			    ,p_program_id              => null                                                                                                                                                               
			    ,p_module_name             => 'PO'                                                                                                                                                               
			    ,p_error_location          => p_error_location                                                                                                                                                   
			    ,p_error_message_code      => null                                                                                                                                                               
			    ,p_error_message           => p_error_msg                                                                                                                                                        
			    ,p_error_message_severity  => 'MAJOR'                                                                                                                                                            
			    ,p_error_status            => 'ACTIVE'                                                                                                                                                           
			    ,p_created_by              => ln_user_id                                                                                                                                                         
			    ,p_last_updated_by         => ln_user_id                                                                                                                                                         
			    ,p_last_update_login       => ln_login                                                                                                                                                           
			    );                                                                                                                                                                                               
                                                                                                                                                                                                        
EXCEPTION                                                                                                                                                                                               
WHEN OTHERS                                                                                                                                                                                             
THEN                                                                                                                                                                                                    
    fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);                                                                                                                   
END log_exception;                                                                                                                                                                                      
                                                                                                                                                                                                        
/*********************************************************************                                                                                                                                  
* Procedure used to log based on gb_debug value or if p_force is TRUE.                                                                                                                                  
* Will log to dbms_output if request id is not set,                                                                                                                                                     
* else will log to concurrent program log file.  Will prepend                                                                                                                                           
* timestamp to each message logged.  This is useful for determining                                                                                                                                     
* elapse times.                                                                                                                                                                                         
*********************************************************************/                                                                                                                                  
PROCEDURE print_debug_msg(                                                                                                                                                                              
   P_Message  In  Varchar2,                                                                                                                                                                             
   p_force    IN  BOOLEAN DEFAULT FALSE)                                                                                                                                                                
IS                                                                                                                                                                                                      
   lc_message  VARCHAR2(32500) := NULL;                                                                                                                                                                 
BEGIN                                                                                                                                                                                                   
   IF (gc_debug = 'Y' OR p_force)                                                                                                                                                                       
   THEN                                                                                                                                                                                                 
      lc_Message := P_Message;                                                                                                                                                                          
      Fnd_File.Put_Line(Fnd_File.log,lc_Message);                                                                                                                                                       
      IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)                                                                                                                            
      Then                                                                                                                                                                                              
  	 DBMS_OUTPUT.put_line(lc_message);                                                                                                                                                                   
      END IF;                                                                                                                                                                                           
   END IF;                                                                                                                                                                                              
EXCEPTION                                                                                                                                                                                               
WHEN OTHERS                                                                                                                                                                                             
THEN                                                                                                                                                                                                    
   NULL;                                                                                                                                                                                                
END print_debug_msg;                                                                                                                                                                                    
                                                                                                                                                                                                        
/*********************************************************************                                                                                                                                  
* Procedure used to out the text to the concurrent program.                                                                                                                                             
* Will log to dbms_output if request id is not set,                                                                                                                                                     
* else will log to concurrent program output file.                                                                                                                                                      
*********************************************************************/                                                                                                                                  
PROCEDURE print_out_msg(                                                                                                                                                                                
   P_Message  In  Varchar2)                                                                                                                                                                             
IS                                                                                                                                                                                                      
   lc_message  VARCHAR2(32500) := NULL;                                                                                                                                                                 
BEGIN                                                                                                                                                                                                   
   Lc_Message :=P_Message;                                                                                                                                                                              
   Fnd_File.Put_Line(Fnd_File.output, Lc_Message);                                                                                                                                                      
   IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)                                                                                                                               
   Then                                                                                                                                                                                                 
      DBMS_OUTPUT.put_line(lc_message);                                                                                                                                                                 
   END IF;                                                                                                                                                                                              
EXCEPTION                                                                                                                                                                                               
WHEN OTHERS                                                                                                                                                                                             
THEN                                                                                                                                                                                                    
   NULL;                                                                                                                                                                                                
END print_out_msg;                                                                                                                                                                                      
                                                                                                                                                                                                        
-- +============================================================================================+                                                                                                       
-- |  Name	 : load_staging                                                            	|                                                                                                                
-- |  Description: This procedure inserts into staging tables      				|                                                                                                                                
-- =============================================================================================|                                                                                                       
PROCEDURE load_staging(p_date_from    IN   DATE,                                                                                                                                                        
                       p_errbuf       OUT  VARCHAR2,                                                                                                                                                    
                       p_retcode      OUT  VARCHAR2)                                                                                                                                                    
IS                                                                                                                                                                                                      
   ln_count	NUMBER := 0;                                                                                                                                                                                
BEGIN                                                                                                                                                                                                   
   print_debug_msg('Load New dropship POs in staging from date:'||to_char(p_date_from,'DD-MON-YYYY'),TRUE);                                                                                             
   INSERT INTO xx_aops_dropship_recon_stg                                                                                                                                                               
		(po_header_id                                                                                                                                                                                         
		,request_id                                                                                                                                                                                           
		,created_by                                                                                                                                                                                           
		,creation_date                                                                                                                                                                                        
		,last_updated_by                                                                                                                                                                                      
		,last_update_date                                                                                                                                                                                     
		,last_update_login)                                                                                                                                                                                   
        (SELECT poh.po_header_id                                                                                                                                                                        
               ,gn_request_id                                                                                                                                                                           
               ,gn_user_id                                                                                                                                                                              
               ,sysdate                                                                                                                                                                                 
               ,gn_user_id                                                                                                                                                                              
               ,sysdate                                                                                                                                                                                 
               ,gn_login_id                                                                                                                                                                             
           FROM  po_headers_all poh                                                                                                                                                                     
          WHERE --poh.closed_date >= TO_DATE((TO_CHAR(p_date_from,'DD-MON-YYYY')||' 00:00:00'), 'DD-MON-YYYY HH24:MI:SS')                                                                               
                poh.closed_date >= p_date_from                                                                                                                                                          
            AND poh.attribute_category like 'DropShip%'                                                                                                                                                 
            AND poh.type_lookup_code = 'STANDARD'                                                                                                                                                       
            --AND poh.po_header_id in(210062,210057,210061,210210) --,210215,210212,210217,210067                                                                                                       
            AND NOT EXISTS(SELECT 'x'                                                                                                                                                                   
                             FROM xx_aops_dropship_recon_stg stg                                                                                                                                        
                            WHERE stg.po_header_id = poh.po_header_id));                                                                                                                                
   ln_count := SQL%ROWCOUNT;                                                                                                                                                                            
   print_debug_msg(to_char(ln_count)||' records loaded into aops drop ship staging',TRUE);                                                                                                              
EXCEPTION                                                                                                                                                                                               
WHEN others THEN                                                                                                                                                                                        
 p_retcode := '2';                                                                                                                                                                                    
   p_errbuf  := 'Error in load_staging-'||substr(sqlerrm,1,500);                                                                                                                                        
   print_debug_msg(p_errbuf,TRUE);                                                                                                                                                                      
END load_staging;                                                                                                                                                                                       
                                                                                                                                                                                                        
--+============================================================================+                                                                                                                        
--| Name          : main                                                       |                                                                                                                        
--| Description   : main procedure will be called from the concurrent program  |                                                                                                                        
--|                 for Suppliers Interface                                    |                                                                                                                        
--| Parameters    : p_debug_level          IN       VARCHAR2                   |                                                                                                                        
--| Returns       :                                                            |                                                                                                                        
--|                 x_errbuf                  OUT      VARCHAR2                |                                                                                                                        
--|                 x_retcode                 OUT      NUMBER                  |                                                                                                                        
--|                                                                            |                                                                                                                        
--|                                                                            |                                                                                                                        
--+============================================================================+                                                                                                                        
PROCEDURE Invoke_webservice(p_retry_errors IN 	VARCHAR2                                                                                                                                                 
                           ,p_errbuf       OUT  VARCHAR2                                                                                                                                                
                           ,p_retcode      OUT  VARCHAR2)                                                                                                                                               
IS                                                                                                                                                                                                      
   lv_soap_request      VARCHAR2 (32500);                                                                                                                                                               
   lv_soap_respond      VARCHAR2 (32500);                                                                                                                                                               
   lr_http_request      UTL_HTTP.req;                                                                                                                                                                   
   lr_http_response     UTL_HTTP.resp;                                                                                                                                                                  
   lv_hosturl           VARCHAR2 (2000);                                                                                                                                                                
   lv_username	        VARCHAR2(25) := NULL;                                                                                                                                                            
   lv_password	        VARCHAR2(25) := NULL;                                                                                                                                                            
   ln_consumer_transaction_id NUMBER;                                                                                                                                                                   
   resp                 XMLTYPE;                                                                                                                                                                        
   ln_batch_size	NUMBER := 500;                                                                                                                                                                         
   indx                 NUMBER;                                                                                                                                                                         
   ln_total_records_processed  NUMBER := 0;                                                                                                                                                             
   ln_success_records          NUMBER := 0;                                                                                                                                                             
   ln_failed_records           NUMBER := 0;                                                                                                                                                             
   ln_retry_count	       NUMBER := 0;                                                                                                                                                                   
   lv_item		VARCHAR2(25);                                                                                                                                                                               
   lv_error_message     VARCHAR2(2000);                                                                                                                                                                 
   lv_site_terms_name   AP_TERMS_TL.NAME%TYPE;                                                                                                                                                          
   lc_loc               VARCHAR2(100) := '0';                                                                                                                                                           
   ln_user_id  	        NUMBER := fnd_global.user_id;                                                                                                                                                   
   ln_login_id 	        NUMBER := fnd_global.login_id;                                                                                                                                                  
   ln_request_id        NUMBER := fnd_global.conc_request_id;                                                                                                                                           
   lv_resp_statuscode   VARCHAR2(2000) := null;                                                                                                                                                         
   lv_lines_msg		VARCHAR2(32500);                                                                                                                                                                       
   data_exception       EXCEPTION;                                                                                                                                                                      
                                                                                                                                                                                                        
CURSOR headers_cur IS                                                                                                                                                                                   
   SELECT stg.po_header_id                                                                                                                                                                              
         ,xpha.po_number                                                                                                                                                                                
         ,xpha.cust_order_nbr                                                                                                                                                                           
         ,xpha.cust_order_sub_nbr                                                                                                                                                                       
         ,xpha.cust_id                                                                                                                                                                                  
   	 ,stg.record_status                                                                                                                                                                                 
   	 ,stg.error_description                                                                                                                                                                             
    FROM   xx_aops_dropship_recon_stg stg,                                                                                                                                                              
           po_headers_all poh,                                                                                                                                                                          
           xx_po_header_attributes xpha                                                                                                                                                                 
   WHERE stg.record_status IS NULL                                                                                                                                                                      
     AND stg.po_header_id = poh.po_header_id                                                                                                                                                            
     AND poh.segment1 = xpha.po_number(+);                                                                                                                                                              
                                                                                                                                                                                                        
TYPE headers IS TABLE OF headers_cur%ROWTYPE                                                                                                                                                            
INDEX BY PLS_INTEGER;                                                                                                                                                                                   
l_headers_tab headers;                                                                                                                                                                                  
                                                                                                                                                                                                        
CURSOR lines_cur(p_po_header_id NUMBER) IS                                                                                                                                                              
   SELECT line_num,                                                                                                                                                                                     
          item_id,                                                                                                                                                                                      
		  regexp_replace(vendor_product_num , '(*[[:punct:]])', '') vendor_product_num, -- Modified as per Version 1.1                                                                                        
          quantity quantity_ord,                                                                                                                                                                        
          unit_price,                                                                                                                                                                                   
          attribute1 quantity_rcvd                                                                                                                                                                      
     FROM  po_lines_all                                                                                                                                                                                 
    where PO_HEADER_ID = P_PO_HEADER_ID
      and quantity not in (0.00000000001, 0.0000000001);   ----Added to supress fraction quantity as per Defect# 45046                                                                                                                                                             
TYPE lines IS TABLE OF lines_cur%ROWTYPE                                                                                                                                                                
INDEX BY PLS_INTEGER;                                                                                                                                                                                   
l_lines_tab lines;                                                                                                                                                                                      
                                                                                                                                                                                                        
CURSOR get_item_cur(p_item_id NUMBER) IS                                                                                                                                                                
   SELECT segment1                                                                                                                                                                                      
     FROM  mtl_system_items_b                                                                                                                                                                           
    WHERE inventory_item_id = p_item_id;                                                                                                                                                                
                                                                                                                                                                                                        
CURSOR get_service_params_cur IS                                                                                                                                                                        
   SELECT  XFTV.source_value1,                                                                                                                                                                          
           XFTV.target_value1                                                                                                                                                                           
     FROM   xx_fin_translatedefinition XFTD                                                                                                                                                             
  	   ,xx_fin_translatevalues XFTV                                                                                                                                                                      
    WHERE   XFTD.translate_id = XFTV.translate_id                                                                                                                                                       
      AND   XFTD.translation_name = 'OD_AOPS_DROPSHIP_RECON_WS'                                                                                                                                         
      AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)                                                                                                              
      AND   SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)                                                                                                              
      AND   XFTV.enabled_flag = 'Y'                                                                                                                                                                     
      AND   XFTD.enabled_flag = 'Y';                                                                                                                                                                    
                                                                                                                                                                                                        
BEGIN                                                                                                                                                                                                   
                                                                                                                                                                                                        
   print_debug_msg('Check Retry Errors',TRUE);                                                                                                                                                          
   IF p_retry_errors = 'Y' THEN                                                                                                                                                                         
      print_debug_msg('Updating header records for retry',FALSE);                                                                                                                                       
      UPDATE xx_aops_dropship_recon_stg                                                                                                                                                                 
         SET record_status = null                                                                                                                                                                       
            ,error_description = null                                                                                                                                                                   
            ,last_update_date = sysdate                                                                                                                                                                 
            ,last_updated_by = gn_user_id                                                                                                                                                               
            ,last_update_login = gn_login_id                                                                                                                                                            
      WHERE record_status = 'E';                                                                                                                                                                        
      ln_retry_count := SQL%ROWCOUNT;                                                                                                                                                                   
      print_debug_msg(to_char(ln_retry_count)||' record(s) updated for retry',TRUE);                                                                                                                    
      COMMIT;                                                                                                                                                                                           
   END IF;                                                                                                                                                                                              
                                                                                                                                                                                                        
   print_debug_msg(p_message=> 'Getting Service Details', p_force=>FALSE);                                                                                                                              
   FOR get_service_params_rec IN get_service_params_cur                                                                                                                                                 
   LOOP                                                                                                                                                                                                 
     IF get_service_params_rec.source_value1 = 'URL' THEN                                                                                                                                               
        lv_hosturl := get_service_params_rec.target_value1;                                                                                                                                             
     ELSIF get_service_params_rec.source_value1 = 'USERNAME' THEN                                                                                                                                       
        lv_username := get_service_params_rec.target_value1;                                                                                                                                            
     ELSIF get_service_params_rec.source_value1 = 'PASSWORD' THEN                                                                                                                                       
        lv_password := xx_encrypt_decryption_toolkit.decrypt(get_service_params_rec.target_value1);                                                                                                     
     END IF;                                                                                                                                                                                            
   END LOOP;                                                                                                                                                                                            
                                                                                                                                                                                                        
   OPEN headers_cur;                                                                                                                                                                                    
   LOOP                                                                                                                                                                                                 
      FETCH headers_cur BULK COLLECT INTO l_headers_tab LIMIT ln_batch_size;                                                                                                                            
      EXIT WHEN l_headers_tab.COUNT = 0;                                                                                                                                                                
                                                                                                                                                                                                        
      FOR indx IN l_headers_tab.FIRST..l_headers_tab.LAST                                                                                                                                               
      LOOP                                                                                                                                                                                              
         ln_total_records_processed := ln_total_records_processed + 1;                                                                                                                                  
         BEGIN                                                                                                                                                                                          
            print_debug_msg(p_message => 'Prepare Request Message for PO'||l_headers_tab(indx).po_number, p_force => FALSE);                                                                            
            print_debug_msg(p_message => 'Get Line Details for PO'||l_headers_tab(indx).po_number, p_force => FALSE);                                                                                   
            OPEN lines_cur(l_headers_tab(indx).po_header_id);                                                                                                                                           
            FETCH lines_cur BULK COLLECT INTO l_lines_tab;                                                                                                                                              
            CLOSE lines_cur;                                                                                                                                                                            
            lv_lines_msg := NULL;                                                                                                                                                                       
            FOR l_indx IN 1..l_lines_tab.COUNT                                                                                                                                                          
            LOOP                                                                                                                                                                                        
               OPEN get_item_cur(l_lines_tab(l_indx).item_id);                                                                                                                                          
               FETCH get_item_cur INTO lv_item;                                                                                                                                                         
               CLOSE get_item_cur;                                                                                                                                                                      
               lv_lines_msg := lv_lines_msg||'<inv:AOPS-DETAIL-DATA>                                                                                                                                    
						    <inv:AOPS-OD-SKU>'||lpad(lv_item,8,'0')||'</inv:AOPS-OD-SKU>                                                                                                                                  
						    <inv:AOPS-OD-LINE-SEQ-NBR>00</inv:AOPS-OD-LINE-SEQ-NBR>                                                                                                                                       
						    <inv:AOPS-VENDOR-CD></inv:AOPS-VENDOR-CD>                                                                                                                                                     
						    <inv:AOPS-VENDOR-LINE-SEQ>00</inv:AOPS-VENDOR-LINE-SEQ>                                                                                                                                       
						    <inv:AOPS-VENDOR-PROD-CD>'||l_lines_tab(l_indx).vendor_product_num||'</inv:AOPS-VENDOR-PROD-CD>                                                                                               
						    <inv:AOPS-ORDERED-QTY>'||lpad(l_lines_tab(l_indx).quantity_ord,9,'0')||'</inv:AOPS-ORDERED-QTY>                                                                                               
						    <inv:AOPS-SHIP-QTY>'||l_lines_tab(l_indx).quantity_rcvd||'</inv:AOPS-SHIP-QTY>                                                                                                                
						    <inv:AOPS-BACK-ORDER-QTY>00</inv:AOPS-BACK-ORDER-QTY>                                                                                                                                         
						    <inv:AOPS-DTL-MATCHED-FLG>Y</inv:AOPS-DTL-MATCHED-FLG>                                                                                                                                        
					        </inv:AOPS-DETAIL-DATA>';                                                                                                                                                                  
            END LOOP;                                                                                                                                                                                   
            print_debug_msg(p_message => 'PO Lines Message:'||lv_lines_msg, p_force => FALSE);                                                                                                          
                                                                                                                                                                                                        
            lv_soap_request := '<x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:inv="http://eai.officedepot.com/service/InvoiceTradeMatch">                                       
	    			    <x:Header/>                                                                                                                                                                                 
				    <x:Body>                                                                                                                                                                                        
					<inv:InvoiceTrade>                                                                                                                                                                                 
					    <inv:WS-AOPS-AOSERVER-REQ-DATA>                                                                                                                                                                
						<inv:WS-MQPUT-AOPS-CONTROL-DATA>                                                                                                                                                                  
						    <inv:AP2828AO-PUT-CONTROL-DATA>                                                                                                                                                               
							<inv:AP2828AO-INPUT-AREA>                                                                                                                                                                        
							    <inv:AP2828AO-MSGTYPE>1</inv:AP2828AO-MSGTYPE>                                                                                                                                               
							    <inv:AP2828AO-REQUEST-MQMGR>CSQ1</inv:AP2828AO-REQUEST-MQMGR>                                                                                                                                
							    <inv:AP2828AO-REQUEST-QUEUE>AOPS_AUTO_RECON</inv:AP2828AO-REQUEST-QUEUE>                                                                                                                     
							    <inv:AP2828AO-REPLY-MQMGR>CSQ1</inv:AP2828AO-REPLY-MQMGR>                                                                                                                                    
							    <inv:AP2828AO-REPLY-QUEUE>APS_GENERAL_REPLY_Q</inv:AP2828AO-REPLY-QUEUE>                                                                                                                     
							    <inv:AP2828AO-MESSAGE-LENGTH></inv:AP2828AO-MESSAGE-LENGTH>                                                                                                                                  
							    <inv:AP2828AO-SYNCPOINT-FLAG>Y</inv:AP2828AO-SYNCPOINT-FLAG>                                                                                                                                 
							    <inv:AP2828AO-CORRELID-FLAG></inv:AP2828AO-CORRELID-FLAG>                                                                                                                                    
							    <inv:AP2828AO-CORRELID></inv:AP2828AO-CORRELID>                                                                                                                                              
							    <inv:AP2828AO-CONNECT-FLAG>N</inv:AP2828AO-CONNECT-FLAG>                                                                                                                                     
							    <inv:AP2828AO-HCONN>0</inv:AP2828AO-HCONN>                                                                                                                                                   
							</inv:AP2828AO-INPUT-AREA>                                                                                                                                                                       
							<inv:AP2828AO-OUTPUT-AREA>                                                                                                                                                                       
							    <inv:AP2828AO-CONDITION-CODE>0</inv:AP2828AO-CONDITION-CODE>                                                                                                                                 
							    <inv:AP2828AO-REASON-CODE>0000</inv:AP2828AO-REASON-CODE>                                                                                                                                    
							    <inv:AP2828AO-ERROR-MESSAGE></inv:AP2828AO-ERROR-MESSAGE>                                                                                                                                    
							</inv:AP2828AO-OUTPUT-AREA>                                                                                                                                                                      
						    </inv:AP2828AO-PUT-CONTROL-DATA>                                                                                                                                                              
						</inv:WS-MQPUT-AOPS-CONTROL-DATA>                                                                                                                                                                 
						<inv:WS-AOSERVER-MSG>                                                                                                                                                                             
						    <inv:AOHDR-HDR-HEADER-AREA>                                                                                                                                                                   
							<inv:AOHDR-HDR-LENGTH>400</inv:AOHDR-HDR-LENGTH>                                                                                                                                                 
							<inv:AOHDR-HDR-VERSION>1</inv:AOHDR-HDR-VERSION>                                                                                                                                                 
							<inv:AOHDR-HDR-RELEASE>0</inv:AOHDR-HDR-RELEASE>                                                                                                                                                 
							<inv:AOHDR-HDR-PROGRAM>AOSERVER</inv:AOHDR-HDR-PROGRAM>                                                                                                                                          
							<inv:AOHDR-HDR-METHOD>AOMAINT</inv:AOHDR-HDR-METHOD>                                                                                                                                             
							<inv:AOHDR-HDR-SYNC-ROLLB-SW>N</inv:AOHDR-HDR-SYNC-ROLLB-SW>                                                                                                                                     
							<inv:AOHDR-HDR-CONDITION-CODE>0</inv:AOHDR-HDR-CONDITION-CODE>                                                                                                                                   
							<inv:FILLER.38>                                                                                                                                                                                  
							    <inv:AOHDR-HDR-REASON-CODE>0000</inv:AOHDR-HDR-REASON-CODE>                                                                                                                                  
							</inv:FILLER.38>                                                                                                                                                                                 
<inv:AOHDR-HDR-CLIENT-PROGRAM></inv:AOHDR-HDR-CLIENT-PROGRAM>                                                                                                                                    
							<inv:AOHDR-HDR-PLATFORM></inv:AOHDR-HDR-PLATFORM>                                                                                                                                                
							<inv:AOHDR-HDR-USER-ID></inv:AOHDR-HDR-USER-ID>                                                                                                                                                  
							<inv:AOHDR-HDR-MESSAGE></inv:AOHDR-HDR-MESSAGE>                                                                                                                                                  
							<inv:AOHDR-HDR-SAVE-AREA></inv:AOHDR-HDR-SAVE-AREA>                                                                                                                                              
							<inv:AOHDR-HDR-USER-AREA></inv:AOHDR-HDR-USER-AREA>                                                                                                                                              
							<inv:AOHDR-HDR-PASSWORD></inv:AOHDR-HDR-PASSWORD>                                                                                                                                                
							<inv:AOHDR-HDR-MORE-SW></inv:AOHDR-HDR-MORE-SW>                                                                                                                                                  
							<inv:AOHDR-HDR-RESERVED></inv:AOHDR-HDR-RESERVED>                                                                                                                                                
						    </inv:AOHDR-HDR-HEADER-AREA>                                                                                                                                                                  
						    <inv:AOPS-INVOICE-RECORD>                                                                                                                                                                     
							<inv:AOPS-HEADER-DATA>                                                                                                                                                                           
							    <inv:AOPS-CUST-ORDER-NBR>'||lpad(l_headers_tab(indx).cust_order_nbr,10,'0')||'</inv:AOPS-CUST-ORDER-NBR>                                                                                     
							    <inv:AOPS-CUST-ORDER-SUB-NBR>'||NVL(substr(l_headers_tab(indx).cust_order_sub_nbr,-3),'001')||'</inv:AOPS-CUST-ORDER-SUB-NBR>                                                                
							    <inv:AOPS-CUST-NBR>'||l_headers_tab(indx).cust_id||'</inv:AOPS-CUST-NBR>                                                                                                                     
							    <inv:AOPS-RECON-SOURCE-CD>V</inv:AOPS-RECON-SOURCE-CD>                                                                                                                                       
							    <inv:AOPS-RECON-STATUS-CD>C</inv:AOPS-RECON-STATUS-CD>                                                                                                                                       
							    <inv:AOPS-DELIV-STATUS>50</inv:AOPS-DELIV-STATUS>                                                                                                                                            
							    <inv:AOPS-PAYMENT-EXCP>00</inv:AOPS-PAYMENT-EXCP>                                                                                                                                            
							    <inv:AOPS-RECON-SEQ-NBR>00</inv:AOPS-RECON-SEQ-NBR>                                                                                                                                          
							    <inv:AOPS-TRANS-DATE></inv:AOPS-TRANS-DATE>                                                                                                                                                  
							    <inv:AOPS-TRANS-TIME></inv:AOPS-TRANS-TIME>                                                                                                                                                  
							    <inv:AOPS-HEADER-MATCHED-FLG>Y</inv:AOPS-HEADER-MATCHED-FLG>                                                                                                                                 
							    <inv:AOPS-PO-NBR>'||substr(l_headers_tab(indx).po_number,1,instr(l_headers_tab(indx).po_number,'-')-1)||'</inv:AOPS-PO-NBR>                                                                  
							</inv:AOPS-HEADER-DATA>'||lv_lines_msg||'                                                                                                                                                        
						    </inv:AOPS-INVOICE-RECORD>                                                                                                                                                                    
						</inv:WS-AOSERVER-MSG>                                                                                                                                                                            
					    </inv:WS-AOPS-AOSERVER-REQ-DATA>                                                                                                                                                               
					</inv:InvoiceTrade>                                                                                                                                                                                
				    </x:Body>                                                                                                                                                                                       
				</x:Envelope>';                                                                                                                                                                                     
                                                                                                                                                                                                        
		print_debug_msg(p_message=> 'Request Message:'|| lv_soap_request, p_force=>TRUE);                                                                                                                     
                                                                                                                                                                                                        
		lr_http_request :=  UTL_HTTP.begin_request (lv_hosturl, 'POST', 'HTTP/1.1');                                                                                                                          
                                                                                                                                                                                                        
		IF lv_username IS NOT NULL THEN                                                                                                                                                                       
  		   print_out_msg('HTTP authenication');                                                                                                                                                             
  		   UTL_HTTP.set_authentication(lr_http_request,lv_username,lv_password);                                                                                                                            
		END IF;                                                                                                                                                                                               
                                                                                                                                                                                                        
		UTL_HTTP.set_header (lr_http_request, 'Content-Type', 'text/xml');                                                                                                                                    
                                                                                                                                                                                                        
		-- since we are dealing with plain text in XML documents                                                                                                                                              
		UTL_HTTP.set_header(lr_http_request,'Content-Length',LENGTH (lv_soap_request));                                                                                                                       
		UTL_HTTP.set_header(lr_http_request, 'SOAPAction', '');                                                                                                                                               
		-- required to specify this is a SOAP communication                                                                                                                                                   
		UTL_HTTP.write_text(lr_http_request, lv_soap_request);                                                                                                                                                
		print_debug_msg(p_message=> 'Invoking the service', p_force=>FALSE);                                                                                                                                  
		lr_http_response := UTL_HTTP.get_response (lr_http_request);                                                                                                                                          
		UTL_HTTP.read_text (lr_http_response, lv_soap_respond);                                                                                                                                               
                                                                                                                                                                                                        
		print_debug_msg(p_message=> 'lr_http_response.status_code='|| lr_http_response.status_code, p_force=>FALSE);                                                                                          
		print_debug_msg(p_message=> 'response:'||lv_soap_respond, p_force=>TRUE);                                                                                                                             
                                                                                                                                                                                                        
		UTL_HTTP.end_response(lr_http_response);                                                                                                                                                              
		resp := XMLTYPE.createxml (lv_soap_respond);                                                                                                                                                          
                                                                                                                                                                                                        
		print_debug_msg(p_message=> 'Message converted to xml', p_force=>FALSE);                                                                                                                              
                                                                                                                                                                                                        
		/* Check if invoke is success */                                                                                                                                                                      
		IF (lr_http_response.status_code = 200)                                                                                                                                                               
		THEN                                                                                                                                                                                                  
		   BEGIN                                                                                                                                                                                              
		      lv_resp_statuscode := null;                                                                                                                                                                     
		      SELECT EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/ns0:Response/ns0:OUTPUT',                                                                                                              
			     'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns0="http://eai.officedepot.com/service/InvoiceTradeMatch"                                                                     
			      xmlns:inv="http://eai.officedepot.com/service/InvoiceTradeMatch"')                                                                                                                             
		        INTO  lv_resp_statuscode                                                                                                                                                                      
		        FROM dual;                                                                                                                                                                                    
		   EXCEPTION                                                                                                                                                                                          
		   WHEN others THEN                                                                                                                                                                                   
		      lv_error_message := substr('Error occured while deriving status code from response message'||sqlerrm,1,2000);                                                                                   
		      RAISE data_exception;                                                                                                                                                                           
		   END;                                                                                                                                                                                               
                                                                                                                                                                                                        
		   print_debug_msg(p_message=> 'Response status code:'||lv_resp_statuscode, p_force=>FALSE);                                                                                                          
                                                                                                                                                                                                        
		   IF lv_resp_statuscode = 'Success' THEN                                                                                                                                                             
		      UPDATE xx_aops_dropship_recon_stg                                                                                                                                                               
		         SET record_status = 'I',                                                                                                                                                                     
		             error_description = null,                                                                                                                                                                
		             last_updated_by = gn_user_id,                                                                                                                                                            
		             last_update_date = sysdate                                                                                                                                                               
		       WHERE po_header_id = l_headers_tab(indx).po_header_id;                                                                                                                                         
		       ln_success_records := ln_success_records + 1;                                                                                                                                                  
		   ELSE                                                                                                                                                                                               
		       lv_error_message := SUBSTR('Response message status code validation failed(status code is not equal to Success)'||lv_soap_respond,1,2000);                                                     
		       RAISE data_exception;                                                                                                                                                                          
		   END IF;                                                                                                                                                                                            
	        ELSE                                                                                                                                                                                           
		   lv_error_message := substr('Message Code:'||to_char(lr_http_response.status_code)                                                                                                                  
		   			||' Reason Phrase:'||lr_http_response.reason_phrase||' Response Message'||lv_soap_respond,1,2000);                                                                                              
		   RAISE data_exception;                                                                                                                                                                              
	        END IF;                                                                                                                                                                                        
                                                                                                                                                                                                        
         EXCEPTION                                                                                                                                                                                      
         WHEN data_exception THEN                                                                                                                                                                       
            print_debug_msg(p_message=> lv_error_message, p_force=>TRUE);                                                                                                                               
            UPDATE xx_aops_dropship_recon_stg                                                                                                                                                           
               SET record_status     = 'E',                                                                                                                                                             
                   error_description = lv_error_message,                                                                                                                                                
                   last_updated_by   = gn_user_id,                                                                                                                                                      
                   last_update_date  = sysdate                                                                                                                                                          
             WHERE po_header_id = l_headers_tab(indx).po_header_id;                                                                                                                                     
             ln_failed_records := ln_failed_records + 1;                                                                                                                                                
         WHEN others THEN                                                                                                                                                                               
             lv_error_message := substr(sqlerrm,1,2000);                                                                                                                                                
             print_debug_msg(p_message=> lv_error_message, p_force=>TRUE);                                                                                                                              
             UPDATE xx_aops_dropship_recon_stg                                                                                                                                                          
                SET record_status     = 'E',                                                                                                                                                            
                    error_description = lv_error_message,                                                                                                                                               
                    last_updated_by   = gn_user_id,                                                                                                                                                     
                    last_update_date  = sysdate                                                                                                                                                         
              WHERE po_header_id = l_headers_tab(indx).po_header_id;                                                                                                                                    
              ln_failed_records := ln_failed_records + 1;                                                                                                                                               
         END;                                                                                                                                                                                           
      END LOOP; --l_headers_tab                                                                                                                                                                         
      COMMIT;                                                                                                                                                                                           
                                                                                                                                                                                                        
   END LOOP;                                                                                                                                                                                            
   CLOSE headers_cur;                                                                                                                                                                                   
                                                                                                                                                                                                        
   --========================================================================                                                                                                                           
   -- Updating the OUTPUT FILE                                                                                                                                                                          
   --========================================================================                                                                                                                           
   print_out_msg('TOTAL Records Processed :: '||ln_total_records_processed);                                                                                                                            
   print_out_msg('TOTAL Records Processed Successfully :: '||ln_success_records);                                                                                                                       
   print_out_msg('TOTAL Records Failed :: '||ln_failed_records);                                                                                                                                        
   IF ln_failed_records > 0 THEN                                                                                                                                                                        
      p_retcode := '1';                                                                                                                                                                                 
      p_errbuf  := 'Some records in xx_aops_dropship_recon_stg completed in error';                                                                                                                     
      print_out_msg('ErrBuf :'||p_errbuf || 'Retcode:'|| to_char(p_retcode));                                                                                                                           
   ELSE                                                                                                                                                                                                 
      p_retcode := '0';                                                                                                                                                                                 
      print_out_msg('ErrBuf :'||p_errbuf || 'Retcode:'|| to_char(p_retcode));                                                                                                                           
   END IF;                                                                                                                                                                                              
EXCEPTION                                                                                                                                                                                               
WHEN others THEN                                                                                                                                                                                        
   p_retcode := '2';                                                                                                                                                                                    
   p_errbuf  := SUBSTR(sqlerrm,1,240);                                                                                                                                                                  
   print_out_msg('ErrBuf :'||p_errbuf || 'Retcode:'|| to_char(p_retcode));                                                                                                                              
END Invoke_webservice;                                                                                                                                                                                  
                                                                                                                                                                                                        
-- +============================================================================================+                                                                                                       
-- |  Name	  : main                                                                        |                                                                                                            
-- |  Description : main procedure will be called from the concurrent program			|                                                                                                                       
-- =============================================================================================|                                                                                                       
PROCEDURE main(p_errbuf       OUT  VARCHAR2                                                                                                                                                             
              ,p_retcode      OUT  VARCHAR2                                                                                                                                                             
              ,p_from_date         VARCHAR2                                                                                                                                                             
              ,p_retry_errors      VARCHAR2                                                                                                                                                             
              ,p_debug             VARCHAR2)                                                                                                                                                            
AS                                                                                                                                                                                                      
   ld_from_date	      DATE	     := NULL;                                                                                                                                                                
   lc_error_msg       VARCHAR2(1000) := NULL;                                                                                                                                                           
   lc_error_loc       VARCHAR2(100)  := 'XX_AOPS_DROPSHIP_RECON_PKG.main';                                                                                                                              
   lc_retcode	      VARCHAR2(3)    := NULL;                                                                                                                                                             
   data_exception     EXCEPTION;                                                                                                                                                                        
                                                                                                                                                                                                        
BEGIN                                                                                                                                                                                                   
   gc_debug	 := p_debug;                                                                                                                                                                                
   gn_request_id := fnd_global.conc_request_id;                                                                                                                                                         
   gn_user_id    := fnd_global.user_id;                                                                                                                                                                 
   gn_login_id   := fnd_global.login_id;                                                                                                                                                                
                                                                                                                                                                                                        
   ld_from_date := fnd_date.canonical_to_date (p_from_date);                                                                                                                                            
   print_debug_msg('Load POs that needs to be sent to AOPS for recon',TRUE);                                                                                                                            
   load_staging(ld_from_date,lc_error_msg,lc_retcode);                                                                                                                                                  
   IF lc_retcode = '2' THEN                                                                                                                                                                             
      RAISE data_exception;                                                                                                                                                                             
   END IF;                                                                                                                                                                                              
   COMMIT;                                                                                                                                                                                              
                                                                                                                                                                                                        
   lc_error_msg := NULL;                                                                                                                                                                                
   lc_retcode   := NULL;                                                                                                                                                                                
   print_debug_msg('Invoke Service for new POs in staging',TRUE);                                                                                                                                       
   Invoke_webservice(p_retry_errors,lc_error_msg,lc_retcode);                                                                                                                                           
   IF lc_retcode = '1' THEN --atleast one PO(s) has errors.                                                                                                                                             
      p_retcode := '1';                                                                                                                                                                                 
   ELSIF lc_retcode = '2' THEN                                                                                                                                                                          
      RAISE data_exception;                                                                                                                                                                             
   END IF;                                                                                                                                                                                              
                                                                                                                                                                                                        
EXCEPTION                                                                                                                                                                                               
WHEN data_exception THEN                                                                                                                                                                                
   print_debug_msg ('ERROR XX_AOPS_DROPSHIP_RECON_PKG.main - '||lc_error_msg,TRUE);                                                                                                                     
   log_exception ('AOPS DropShip Recon Program',                                                                                                                                                        
                   lc_error_loc,                                                                                                                                                                        
		   lc_error_msg);                                                                                                                                                                                     
   p_retcode := '2';                                                                                                                                                                                    
   p_errbuf  := lc_error_msg;                                                                                                                                                                           
WHEN others THEN                                                                                                                                                                                        
   lc_error_msg := substr(sqlerrm,1,250);                                                                                                                                                               
   print_debug_msg ('ERROR XX_AOPS_DROPSHIP_RECON_PKG.main - '||lc_error_msg,TRUE);                                                                                                                     
   log_exception ('AOPS DropShip Recon Program',                                                                                                                                                        
                   lc_error_loc, lc_error_msg);                                                                                                                                                                                     
   p_retcode := '2';                                                                                                                                                                                    
   p_errbuf  := lc_error_msg;                                                                                                                                                                           
END main;                                                                                                                                                                                               
                                                                                                                                                                                                        
END XX_AOPS_DROPSHIP_RECON_PKG;
/
