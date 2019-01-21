SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  BODY XX_PO_POM_INT_MISSHIP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_PO_POM_INT_MISSHIP_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_POM_INT_MISSHIP_PKG                                                   |
-- |  RICE ID 	 :  I2193_PO to EBS Interface Mis-Ship			                        |
-- |  Description:  OD PO POM Interface Mis-ship                       				| 
-- |		    										|
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08/31/2017   Avinash Baddam   Initial version                                  |
-- | 1.1		 11/16/2017	  Uday Jadhav	   replaced ap_line_no is null to 000				|
-- | 1.2         12/27/2017   Suresh Ponnambalam Modified code to get line num.                 |
-- | 1.3         04/18/2018   Madhu Bolli        Misship-max line number should start from 9001 |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name	 : Log Exception                                                            		|
-- |  Description: The log_exception procedure logs all exceptions								|
-- =============================================================================================|
gc_debug 	VARCHAR2(2);
gn_request_id   fnd_concurrent_requests.request_id%TYPE;
gn_user_id      fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	NUMBER;

PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                        ,p_error_location     IN  VARCHAR2
		        ,p_error_msg          IN  VARCHAR2)
IS
   ln_login     NUMBER   :=  FND_GLOBAL.LOGIN_ID;
   ln_user_id   NUMBER   :=  FND_GLOBAL.USER_ID;
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
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE)
IS
   lc_message   VARCHAR2 (4000) := NULL;
BEGIN
   IF (gc_debug = 'Y' OR p_force)
   THEN
       lc_Message := P_Message;
       fnd_file.put_line (fnd_file.log, lc_Message);

       IF (   fnd_global.conc_request_id = 0
           OR fnd_global.conc_request_id = -1)
       THEN
          dbms_output.put_line (lc_message);
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
PROCEDURE print_out_msg (p_message IN VARCHAR2)
IS
   lc_message   VARCHAR2 (4000) := NULL;
BEGIN
   lc_message := p_message;
   fnd_file.put_line (fnd_file.output, lc_message);

   IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
   THEN
      dbms_output.put_line (lc_message);
   END IF;
EXCEPTION
WHEN OTHERS
THEN
   NULL;
END print_out_msg;

-- +============================================================================================+
 -- |  Name	  : print_master_program_stats                                                   |
 -- |  Description: This procedure print stats of master program                                 |
 -- =============================================================================================|
 PROCEDURE report_master_program_stats
 AS                       		     
    CURSOR po_int_cur IS
        SELECT count(*) count,
               poh.process_code
          FROM  po_headers_interface poh
         WHERE EXISTS (SELECT 'x' 
                         FROM fnd_concurrent_requests req
                        WHERE req.parent_request_id = gn_request_id
                          AND to_number(req.argument8) = poh.batch_id)
         GROUP BY poh.process_code
         ORDER BY poh.process_code;
         
    TYPE stats IS TABLE OF po_int_cur%ROWTYPE
    INDEX BY PLS_INTEGER; 
    stats_tab   STATS;
    indx	NUMBER;
    
    CURSOR trans_detail_cur IS
       SELECT  ap_po_number
	      ,ap_location
	      ,ap_keyrec
	      ,ap_po_date
	      ,ap_po_line_no
	      ,ap_sku
	      ,error_description
         FROM  xx_po_rcv_trans_int_stg stg
        WHERE EXISTS (SELECT 'x' 
                        FROM fnd_concurrent_requests req
                       WHERE req.parent_request_id = gn_request_id
                         AND to_number(req.argument8) = stg.batch_id)
          AND stg.record_status = 'E'                          
        ORDER BY stg.ap_po_number,stg.ap_location,stg.ap_keyrec,ap_po_line_no;  
        
    TYPE trans_detail IS TABLE OF trans_detail_cur%ROWTYPE
    INDEX BY PLS_INTEGER; 
    trans_detail_tab   trans_detail;
    t_indx	       NUMBER;    
    
 BEGIN
    print_debug_msg ('Report Master Program Stats',FALSE);
    
    print_out_msg('Standard Import PO Interface Summary');
    print_out_msg('====================================');
    print_out_msg(RPAD('Process Code',15)||' '||RPAD('Count',10));
    print_out_msg(RPAD('=',15,'=')||' '||RPAD('=',10,'='));
    
    OPEN po_int_cur;
    FETCH po_int_cur BULK COLLECT INTO stats_tab;
    CLOSE po_int_cur;
    
    FOR indx IN 1..stats_tab.COUNT
    LOOP
        print_out_msg(RPAD(stats_tab(indx).process_code,15)||' '||RPAD(stats_tab(indx).count,10));
    END LOOP;   
    
    print_out_msg(' ');
    print_out_msg(' ');
    print_out_msg('Staging Validation Exception Details');
    print_out_msg('=====================================');  
    print_out_msg(RPAD('PO Number',10)||' '||RPAD('Location',4)||' '||RPAD('Key Rec',10)||' '||RPAD('PO Date',12)||' '||RPAD('Line',4)||' '||RPAD('Sku',15)||' '||RPAD('Error Details',150));
    print_out_msg(RPAD('=',10,'=')||' '||RPAD('=',4,'=')||' '||RPAD('=',10,'=')||' '||RPAD('=',12,'=')||' '||RPAD('=',4,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',150,'=')); 
    
    OPEN trans_detail_cur;
    FETCH trans_detail_cur BULK COLLECT INTO trans_detail_tab;
    CLOSE trans_detail_cur;
    
    FOR t_indx IN 1..trans_detail_tab.COUNT
    LOOP
        print_out_msg(RPAD(trans_detail_tab(t_indx).ap_po_number,10)||' '||RPAD(trans_detail_tab(t_indx).ap_location,4)||' '||
                      RPAD(trans_detail_tab(t_indx).ap_keyrec,10)||' '||RPAD(trans_detail_tab(t_indx).ap_po_date,12)||' '||
                      RPAD(trans_detail_tab(t_indx).ap_po_line_no,4)||' '||RPAD(trans_detail_tab(t_indx).ap_sku,15)||' '||
                      RPAD(trans_detail_tab(t_indx).error_description,150));
    END LOOP;  

 EXCEPTION
    WHEN others THEN
       print_debug_msg ('Report Master Program Stats failed'||substr(sqlerrm,1,150),TRUE);
       print_out_msg ('Report Master Program stats failed'||substr(sqlerrm,1,150));
 END report_master_program_stats; 
 
 -- +============================================================================================+
 -- |  Name	  : interface_master                                                             |
 -- |  Description: This procedure reads data from the staging and creates PO Line for misship   |
 -- |               OD PO POM Interface Mis-ship                                                 |
 -- =============================================================================================|
 PROCEDURE interface_master(p_errbuf       OUT  VARCHAR2
                           ,p_retcode      OUT  VARCHAR2
                           ,p_retry_errors	VARCHAR2
                      	   ,p_debug             VARCHAR2)
 AS
    CURSOR trans_cur IS
     SELECT stg.ap_po_number
             ,stg.ap_keyrec
       	     ,to_number(stg.ap_rcvd_quantity) ap_rcvd_quantity
             ,to_number(stg.ap_rcvd_cost)     ap_rcvd_cost
             ,stg.ap_po_line_no
             ,stg.record_status
             ,stg.error_description
             ,stg.record_id
             ,stg.ap_sku
             ,stg.ap_rcvd_date
             ,po.po_header_id
             ,po.segment1 po_number
             ,po.type_lookup_code 
             ,po.org_id
             ,po.currency_code
             ,po.agent_id
             ,po.vendor_id
             ,po.vendor_site_id
             ,po.ship_to_location_id
             ,hou.organization_id
         FROM  xx_po_rcv_trans_int_stg  stg,
               po_headers_all 		po,
               hr_all_organization_units hou
        WHERE stg.ap_po_number = po.segment1
          AND hou.location_id = po.ship_to_location_id
          AND (stg.record_status IS NULL OR stg.record_status='E')
          AND stg.ap_po_line_no =000 --IS NULL
          AND stg.ap_po_number IS NOT NULL 
          AND NOT EXISTS
          (
          SELECT 1 from po_headers_all pha, po_lines_all pla
          WHERE pha.segment1=stg.ap_po_number
          and pha.po_header_id=pla.po_header_id
          and pla.item_id=(select inventory_item_id from mtl_system_items_b where segment1=ltrim(stg.ap_sku,'0')
                                  and organization_id=hou.organization_id 
                                )
          );
          
    TYPE trans IS TABLE OF trans_cur%ROWTYPE
    INDEX BY PLS_INTEGER;    
    
    CURSOR po_line_cur(p_po_header_id NUMBER,p_item NUMBER) IS
	SELECT pl.org_Id, 
	       pl.po_header_id, 
	       pl.item_id, 
	       pl.item_description,
	       pl.po_line_id, 
	       pl.line_num, 
	       pll.quantity,
	       pl.unit_meas_lookup_code, 
	       pll.line_location_id, 
	       pll.closed_code, 
	       pll.quantity_received,
	       pll.cancel_flag, 
	       pll.shipment_num,
	       pll.ship_to_organization_id
	  FROM   po_lines_all pl, 
	         po_line_locations_all pll,
	         mtl_system_items_b msi
	 WHERE pl.po_header_id 	= p_po_header_id
	   AND pl.quantity 	= 0.0000000001
	   AND pl.po_line_id 	= pll.po_line_id
	   AND msi.inventory_item_id = pl.item_id
	   AND msi.organization_id   = pll.ship_to_organization_id
	   AND msi.segment1 	= p_item;
    po_line_rec po_line_cur%ROWTYPE;	
    
    CURSOR check_item_cur(p_item VARCHAR2,p_organization_id NUMBER) IS
       SELECT inventory_item_id,primary_uom_code
         FROM  mtl_system_items_b 
        WHERE segment1 = p_item
          AND organization_id = p_organization_id;     
          
    CURSOR org_cur(p_batch_id NUMBER) IS
       SELECT distinct org_id
         FROM po_headers_interface
        WHERE batch_id = p_batch_id
          AND org_id IS NOT NULL;
          
    TYPE org IS TABLE OF org_cur%ROWTYPE
    INDEX BY PLS_INTEGER;

    l_org_tab 			ORG;          
    l_trans_tab 		TRANS;  
    indx                 	NUMBER;   
    o_indx			NUMBER;
    lc_error_msg       		VARCHAR2(1000) := NULL;
    lc_error_loc       		VARCHAR2(100)  := 'XX_PO_POM_INT_MISSHIP_PKG.INTERFACE_MASTER';
    ln_retry_count     		NUMBER;
    lc_retcode	       		VARCHAR2(3)    := NULL;
    lc_iretcode	       		VARCHAR2(3)    := NULL;
    lc_uretcode	       		VARCHAR2(3)    := NULL;
    lc_req_data        		VARCHAR2(30);
    ln_child_request_status     VARCHAR2(1)    := NULL;    
    ln_batch_id         	NUMBER; 
    ln_item_id			NUMBER;    
    lc_uom_code			VARCHAR2(30);
    ln_job_id			NUMBER;
    ln_line_num			NUMBER;
    data_exception              EXCEPTION;
 BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
    
    --Get value of global variable. It is null initially.
    lc_req_data   := fnd_conc_global.request_data;
        
    -- req_date will be null for first time parent scan by concurrent manager.
    IF (lc_req_data IS NULL) THEN
    
       print_debug_msg('Check Retry Errors',TRUE);
       IF p_retry_errors = 'Y' THEN
          --Retry will process only error records by using request_id
          print_debug_msg('Updating records for retry',FALSE); 
          UPDATE xx_po_rcv_trans_int_stg
             SET record_status = null
                ,error_description = null
                ,last_update_date = sysdate
                ,last_updated_by  = gn_user_id
                ,last_update_login = gn_login_id
           WHERE record_status = 'E'
             AND ap_po_line_no =000 --IS NULL
             AND ap_po_number IS NOT NULL;
          ln_retry_count := SQL%ROWCOUNT;
          print_debug_msg(to_char(ln_retry_count)||' record(s) updated for retry',TRUE); 
          COMMIT;
       END IF;     

       SELECT xx_po_pom_int_batch_s.nextval
         INTO  ln_batch_id
         FROM dual;
    
       OPEN trans_cur;
       FETCH trans_cur BULK COLLECT INTO l_trans_tab;
       CLOSE trans_cur;
       
       FOR indx IN 1..l_trans_tab.COUNT
       LOOP   
          BEGIN
             print_debug_msg ('Processing Record_id='||to_char(l_trans_tab(indx).record_id)||', Validate Line',FALSE);          
             po_line_rec.po_line_id := null;
	     OPEN po_line_cur(l_trans_tab(indx).po_header_id,ltrim(l_trans_tab(indx).ap_sku,'0'));
	     FETCH po_line_cur INTO po_line_rec;
	     CLOSE po_line_cur;  
	     
	     print_debug_msg ('Check if Mis-Ship line exists on PO',FALSE);
	     IF po_line_rec.po_line_id IS NULL THEN
                print_debug_msg ('Record_id='||to_char(l_trans_tab(indx).record_id)||', Validate Item',FALSE);
                ln_item_id := null;
	        OPEN check_item_cur(ltrim(l_trans_tab(indx).ap_sku,'0'),l_trans_tab(indx).organization_id);
	        FETCH check_item_cur INTO ln_item_id,lc_uom_code;
	        CLOSE check_item_cur;                      
	        IF ln_item_id IS NULL THEN
                   l_trans_tab(indx).record_status := 'E';
                   l_trans_tab(indx).error_description := 'Invalid item=['||l_trans_tab(indx).ap_sku||
                                          '], organization_id=['||to_char(l_trans_tab(indx).organization_id)||']';
                   print_debug_msg ('Invalid item=['||l_trans_tab(indx).ap_sku||
                                          '], organization_id=['||to_char(l_trans_tab(indx).organization_id)||']',FALSE);                   
                   RAISE data_exception;
                END IF;  
			
			
			SELECT max(line_num)		      
                  INTO  ln_line_num
                  FROM po_headers_interface phi,
				       po_lines_interface pli
                 WHERE phi.interface_header_id = pli.interface_header_id
				  AND  phi.document_num        = l_trans_tab(indx).po_number;
			
			IF ln_line_num is NULL THEN
			SELECT max(line_num)		      
                  INTO  ln_line_num
                  FROM po_lines_all
                 WHERE po_header_id = l_trans_tab(indx).po_header_id; 
            END IF;
			ln_line_num :=ln_line_num+1;
			
			-- 1.3
			IF ln_line_num < 9001 THEN
				ln_line_num := 9001;
			END IF;
			 
			
	        INSERT INTO po_headers_interface 
		     (interface_header_id, 
		      batch_id, 
		      process_code, 
		      action, 
		      org_id, 
		      document_type_code, 
		      document_num, 
		      currency_code, 
		      agent_id, 
		      vendor_id, 
		      vendor_site_id, 
		      ship_to_location_id) 
	     	VALUES 
		     (po_headers_interface_s.NEXTVAL, 
		      ln_batch_id, 
		      'PENDING', 
		      'UPDATE', 
		      l_trans_tab(indx).org_id, 
		      l_trans_tab(indx).type_lookup_code,
		      l_trans_tab(indx).po_number, 
		      l_trans_tab(indx).currency_code,
		      l_trans_tab(indx).agent_id,
		      l_trans_tab(indx).vendor_id, 
		      l_trans_tab(indx).vendor_site_id, 
		      l_trans_tab(indx).ship_to_location_id);
		      
               
              
	        INSERT INTO po_lines_interface 
		    (interface_line_id, 
		     interface_header_id, 
		     line_num, 
		     shipment_num, 
		     line_type, 
		     item_id, 
		     uom_code, 
		     quantity, 
		     unit_price, 
		     promised_date, 
		     ship_to_organization_id, 
		     ship_to_location_id) 
	    	VALUES 
		    (po_lines_interface_s.nextval, 
		     po_headers_interface_s.currval, 
		     ln_line_num, 
		     1, 
		     'Goods', 
		     ln_item_id, 
		     lc_uom_code, 
		     0.0000000001, 
		     l_trans_tab(indx).ap_rcvd_cost, 
		     to_date(l_trans_tab(indx).ap_rcvd_date,'MM/DD/YY'), 
		     l_trans_tab(indx).organization_id, 
		     l_trans_tab(indx).ship_to_location_id); 
             		     
                INSERT INTO po_distributions_interface 
		   (interface_header_id, 
		    interface_line_id, 
		    interface_distribution_id, 
		    distribution_num, 
		    quantity_ordered, 
		    destination_type_code,
		    destination_subinventory) 
	        VALUES 
		   (po_headers_interface_s.currval, 
		    po_lines_interface_s.currval, 
		    po_distributions_interface_s.nextval, 
		    1, 
		    0.0000000001, 
		    'INVENTORY',
		    'STOCK');
	     END IF;
          EXCEPTION
          WHEN data_exception THEN
             UPDATE xx_po_rcv_trans_int_stg
                SET record_status = 'E'
                   ,error_description = DECODE(record_id,l_trans_tab(indx).record_id,l_trans_tab(indx).error_description,'Other line in the PO receipt not valid')
                   ,batch_id = ln_batch_id
                   ,last_update_date  = sysdate
	           ,last_updated_by   = gn_user_id
	           ,last_update_login = gn_login_id
             WHERE ap_po_number =  l_trans_tab(indx).ap_po_number
               AND record_status IS NULL;             
          WHEN others THEN
             rollback;
             lc_error_msg := 'XX_PO_MISSHIP_RCV_INT_PKG.interface_master-'||SUBSTR(sqlerrm,1,500);
             UPDATE xx_po_rcv_trans_int_stg
                SET record_status = 'E'
                   ,error_description = DECODE(record_id,l_trans_tab(indx).record_id,lc_error_msg,'Other line in the PO receipt not valid')
                   ,batch_id = ln_batch_id
                   ,last_update_date  = sysdate
	           ,last_updated_by   = gn_user_id
	           ,last_update_login = gn_login_id
             WHERE ap_po_number =  l_trans_tab(indx).ap_po_number
               AND record_status IS NULL;           
          END; 
       END LOOP;
       
       print_debug_msg('Submitting Import Standard Purchase Orders',FALSE); 
       OPEN org_cur(ln_batch_id);
       FETCH org_cur BULK COLLECT INTO l_org_tab;
       CLOSE org_cur;
       
       FOR o_indx IN 1..l_org_tab.COUNT 
       LOOP
          print_debug_msg('Submitting Import Standard Purchase Orders for batchid=['||ln_batch_id||'], Org_id=['||l_org_tab(o_indx).org_id||']',FALSE);
          mo_global.set_policy_context('S',l_org_tab(o_indx).org_id); 
          mo_global.init ('PO');
          ln_job_id := fnd_request.submit_request(application => 'PO'
	                                         ,program     => 'POXPOPDOI'
	                                         ,sub_request => TRUE
	                                         ,argument1   => ''        		-- Default Buyer
	                                         ,argument2   => 'STANDARD'  		-- Doc. Type
	                                         ,argument3   => ''			-- Doc. Sub Type
	                                         ,argument4   => 'N'         		-- Create or Update Items
	                                         ,argument5   => ''                     -- Create sourcing Rules flag
	                                         ,argument6   => 'APPROVED' 		-- Approval Status
	                                         ,argument7   => ''			-- Release Generation Method
	                                         ,argument8   => ln_batch_id            -- batch_id
	                                         ,argument9   => l_org_tab(o_indx).org_id 	-- org_id
	                                         );
	   
          COMMIT;
          IF ln_job_id = 0 THEN
	     p_retcode := '2';
	     exit;
	  END IF;           
       END LOOP;
       
       IF p_retcode = '2' THEN
          p_errbuf := 'Sub-Request Submission- Failed';
          return;
       END IF;       
       
       --Pause if child request exists
       IF l_org_tab.COUNT > 0 THEN
          -- Set parent program status as 'PAUSED' and set global variable value to 'END'
          print_debug_msg('Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE); 
          fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data => 'END');
          print_debug_msg('Complete Pausing Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),TRUE); 
       ELSE
          print_debug_msg('No Child Requests submitted...',TRUE); 
          p_retcode := '0';
       END IF;       
  
    END IF; --l_req_data IS NULL 
     
    IF (lc_req_data = 'END') THEN
       report_master_program_stats;
       p_retcode := '0';
    END IF;
    
 EXCEPTION
 WHEN others THEN
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('ERROR PO POM Interface Mis-ship '||lc_error_msg,TRUE);
    log_exception ('OD PO POM Interface Mis-ship',
                   lc_error_loc,
		   lc_error_msg);
    p_retcode := 2;
 END interface_master; 
 
END XX_PO_POM_INT_MISSHIP_PKG;
/
SHOW ERR