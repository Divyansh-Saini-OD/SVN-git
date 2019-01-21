create or replace PACKAGE BODY XX_AP_TR_MATCH_PREVAL_PKG
AS
-- +============================================================================================+
-- |                         Office Depot - Project Simplify                                    |
-- +============================================================================================+
-- |  Name	     :  XX_AP_TR_MATCH_PREVAL_PKG                                                   |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:  Custom prevalidation program						                        |
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/06/2017   Havish Kasina    Initial version                                  |
-- | 1.1         09/21/2017   Naveen Patha     Modified version                                 |
-- | 1.2         09/23/2017   Paddy Sanjeevi   Modified main_cur to use nvl for po_header_id    |
-- | 1.3         09/29/2017   Paddy Sanjeevi   Modified to create NO receipt hold for 3-Way Only|
-- | 1.4         10/03/2017   Paddy Sanjeevi   Modified to exclude 6 day restiction in preval   |
-- | 1.5         10/20/2017   Havish Kasina    Added to identify the miscellaneous created for  |
-- |                                           Distribution Variance Tolerance                  |
-- | 1.6         10/25/2017   Havish Kasina    Updating attribute5 to PO Type if attribute5 is  |
-- |                                           NULL and max price variance hold within std tol  |
-- | 1.7         11/09/2017   Havish Kasina    Updating the Source to DROPSHIP if the sources   |
-- |                                           EDI and TDM has DROPSHIP PO                      |
-- | 1.8         11/20/2017   Paddy Sanjeevi   Added p_invoice_id parameter                     |
-- | 1.9         12/20/2017   Havish Kasina    a. Added the new procedure to create the OD MISC |
-- |                                              HOLD for the Miscellaneous lines              |
-- |                                           b. Commented the code for TDM and DCI invoices   |
-- |                                              should not be held for 6 days                 |
-- |                                           c. Added the new logic to find the invoices with |
-- |                                              no receipts to create the OD No Receipt Hold  |
-- | 2.0         01/05/2017   Havish Kasina    Added a new procedure update_ap_invoices to      |
-- |                                           update the Terms Date and Goods Received Date    |
-- | 2.1         02/01/2017   Naveen Patha     Added org_id parameter                           |
-- | 2.2         02/26/2018   Paddy Sanjeevi   Added xx_hold_invoices                           |
-- | 2.3         03/05/2018   Havish Kasina    Modified the lines cursor in the Favorable Cost  |
-- |                                           Variance Procedure                               |
-- | 2.4         03/05/2018   Havish Kasina    Modified the price tolerance procedure           |
-- | 2.5         03/30/2018   Havish Kasina    Added NOT NULL in the favorable_cost_variance    |
-- |                                           procedure                                        |
-- | 2.6         04/11/2018   Havish Kasina    Added the code to check whether the vendor is    |
-- |                                           Expense Vendor or Not                            |
-- | 2.7         04/16/2018   Havish Kasina    Added quick_po_header_id IS NOT NULL             |
-- | 2.8         04/18/2018   Havish Kasina    Modified the code to create OD No Receipt Hold   |
-- |                                           only if all the lines doesn't have receipt       |
-- | 2.9         06/04/2018   Paddy Sanjeevi   Modified not to calculate terms date for 3-Way   |
-- | 2.10        06/05/2018   Vivek Kumar      NAIT-40392 - Exclude PO Type of Dropship for 2   | 
-- |                                           Way matching
-- |  2.11       06/22/2018   Priyam  PArmar   Code added for NAIT-37732         
-- +============================================================================================+
-- +============================================================================================+
-- |  Name	 : Log Exception                                                            	    |
-- |  Description: The log_exception procedure logs all exceptions				                |
-- =============================================================================================|
gc_debug 	    VARCHAR2(2);
gn_request_id   fnd_concurrent_requests.request_id%TYPE;
gn_user_id      fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	NUMBER;
gn_batch_size	NUMBER := 250;
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
			    ,p_program_id              => NULL
			    ,p_module_name             => 'AP'
			    ,p_error_location          => p_error_location
			    ,p_error_message_code      => NULL
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
    fnd_file.put_line(fnd_file.LOG, 'Error while writting to the log ...'|| SQLERRM);
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
       fnd_file.put_line (fnd_file.LOG, lc_Message);
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
   fnd_file.put_line (fnd_file.OUTPUT, lc_message);
   IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
   THEN
      dbms_output.put_line (lc_message);
   END IF;
EXCEPTION
WHEN OTHERS
THEN
   NULL;
END print_out_msg;
-- +===================================================================+
-- | Name        : xx_hold_invoices                                    |
-- |                                                                   |
-- | Description : This procedure is used held EDI invoices for 6 days |
-- |                                                                   |
-- +===================================================================+
PROCEDURE xx_hold_invoices(p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2
						  )
IS
ln_org_id NUMBER;
ln_count NUMBER;
BEGIN
   ln_org_id:=FND_PROFILE.VALUE ('ORG_ID');
           UPDATE ap_invoices_all a
            SET a.validation_request_id = -9999999999
            WHERE a.creation_date BETWEEN TO_DATE(TO_CHAR(SYSDATE)||' 00:00:00','DD-MON-RR HH24:MI:SS') 
            AND TO_DATE(TO_CHAR(SYSDATE)||' 23:59:59','DD-MON-RR HH24:MI:SS')
            AND a.source='US_OD_TRADE_EDI'
            AND a.org_id+0=ln_org_id
            AND a.invoice_type_lookup_code='STANDARD'
            AND NOT EXISTS (SELECT 'x'
                            FROM ap_invoices_all
                            WHERE invoice_num LIKE a.invoice_num||'ODDB%' )
      /*AND EXISTS (SELECT 'x'
   		            FROM po_line_locations_all pll
                   WHERE pll.po_header_id = NVL(a.po_header_id,quick_po_header_id)
   		             AND inspection_required_flag = 'N'
   		             AND receipt_required_flag = 'Y') */			  ----NAIT-40392 - Commented for 2- way matching
			AND EXISTS(SELECT 'x'
                       FROM xx_fin_translatedefinition xftd, 
                       xx_fin_translatevalues xftv,
                       ap_supplier_sites_all site
                       WHERE site.vendor_site_id=a.vendor_site_id
                       AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES' 
                       AND xftd.translate_id = xftv.translate_id
                       AND xftv.target_value1 = site.attribute8
                       AND xftv.enabled_flag = 'Y'
                       AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
                       );
   ln_count := SQL%ROWCOUNT;
   print_debug_msg(TO_CHAR(ln_count)||' invoice(s) updated for wait',TRUE);    		
EXCEPTION
  WHEN OTHERS 
  THEN
    fnd_file.put_line (fnd_file.log, SUBSTR(SQLERRM,1,100));
END xx_hold_invoices;						  
-- +===================================================================+
-- | Name        : xx_insert_ap_tr_match_excepns                       |
-- |                                                                   |
-- | Description : This procedure is used to insert the exception      |
-- |               records into staging table XX_AP_TR_MATCH_EXCEPTIONS|                       
-- |                                                                   |
-- +===================================================================+
PROCEDURE XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            IN  NUMBER,
                                        p_invoice_num           IN  VARCHAR2,
                                        p_vendor_id             IN  NUMBER ,
                                        p_vendor_site_id        IN  NUMBER ,
		                                p_invoice_line_id       IN  NUMBER ,
		                                p_invoice_line_num      IN  NUMBER ,
		                                p_po_num                IN  VARCHAR2,
		                                p_po_header_id          IN  NUMBER,
		                                p_po_line_id            IN  NUMBER,
		                                p_po_line_num           IN  NUMBER,
		                                p_exception_code        IN  VARCHAR2,
		                                p_exception_description IN  VARCHAR2,
		                                p_process_flag          IN  VARCHAR2,
										p_hold_placed_flag      IN  VARCHAR2
										)
IS
     ln_user_id    NUMBER := FND_GLOBAL.USER_ID;
	 ln_login_id   NUMBER := FND_GLOBAL.LOGIN_ID;
BEGIN
  -- Inserting the records into XX_AP_TR_MATCH_EXCEPTIONS table for Trade Match Exceptions
    INSERT INTO XX_AP_TR_MATCH_EXCEPTIONS(INVOICE_ID ,
                                          INVOICE_NUM ,
										  VENDOR_ID ,
										  VENDOR_SITE_ID ,
										  INVOICE_LINE_ID ,
										  INVOICE_LINE_NUM ,
										  PO_NUM ,
										  PO_HEADER_ID ,
										  PO_LINE_ID ,
										  PO_LINE_NUM ,
										  EXCEPTION_CODE ,
										  EXCEPTION_DESCRIPTION ,
										  PROCESS_FLAG ,
										  HOLD_PLACED_FLAG,
										  CREATION_DATE ,
										  CREATED_BY ,
										  LAST_UPDATED_BY ,
										  LAST_UPDATE_LOGIN ,
										  LAST_UPDATE_DATE
										  )
								VALUES   (p_invoice_id ,
                                          p_invoice_num ,
                                          p_vendor_id ,
                                          p_vendor_site_id ,
		                                  p_invoice_line_id ,
		                                  p_invoice_line_num ,
		                                  p_po_num ,
		                                  p_po_header_id ,
		                                  p_po_line_id ,
		                                  p_po_line_num ,
		                                  p_exception_code ,
		                                  p_exception_description ,
		                                  p_process_flag ,
										  p_hold_placed_flag,
										  SYSDATE,             --creation_date
                                          ln_user_id,          --created_by 
										  ln_user_id,          --last_updated_by
										  ln_login_id,         --last_update_login
                                          SYSDATE             --last_update_date                                          
                                          );
	COMMIT;
EXCEPTION
    WHEN OTHERS THEN
	   fnd_file.put_line(fnd_file.LOG,'Insert into XX_AP_TR_MATCH_EXCEPTIONS table for Trade Match Excetpions : '||SQLERRM); 
END;
-- +===================================================================+
-- | Name        : get_match_type                                      |
-- |                                                                   |
-- | Description : This function returns PO type 2-Way or 3-Way        |
-- |               date                                                |                       
-- |                                                                   |
-- +===================================================================+
FUNCTION get_match_type(p_po_header_id IN NUMBER) 
RETURN VARCHAR2 
IS
lc_inspection_req_flag 		VARCHAR2(1);
lc_receipt_req_flag			VARCHAR2(1);
lc_return_match_type		VARCHAR2(10):=NULL;
BEGIN
  IF p_po_header_id IS NOT NULL THEN
     BEGIN
       SELECT DISTINCT inspection_required_flag,receipt_required_flag 
		 INTO lc_inspection_req_flag, lc_receipt_req_flag
         FROM po_line_locations_all 
        WHERE po_header_id = p_po_header_id;
     EXCEPTION
	   WHEN others THEN
	     lc_inspection_req_flag:=NULL;
		 lc_receipt_req_flag   :=NULL;
		 lc_return_match_type  :=NULL;
	 END;
	 IF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'N' THEN
		lc_return_match_type := '2-Way';
     ELSIF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'Y' THEN
		lc_return_match_type := '3-Way';
     END IF;
  END IF;
  RETURN(lc_return_match_type);
END get_match_type;
-- +===================================================================+
-- | Name        : xx_ap_latest_received_date                          |
-- |                                                                   |
-- | Description : This procedure is used to get the latest received   |
-- |               date                                                |                       
-- |                                                                   |
-- +===================================================================+
PROCEDURE XX_AP_LATEST_RECEIVED_DATE(p_po_header_id           IN   NUMBER,
                                     p_invoice_id             IN   NUMBER,
                                     o_latest_received_date   OUT  DATE)
IS
--Get the latest_received_date using the following query
lc_crcv_date  VARCHAR2(15);
ld_crcv_date  DATE;
lc_cnv_flag   VARCHAR2(1):= NULL;
BEGIN
    o_latest_received_date := NULL;
	BEGIN
	  /*
	  SELECT a.attribute1
	    INTO lc_crcv_date
        FROM rcv_shipment_headers a
       WHERE a.shipment_header_id IN (SELECT max(shipment_header_id)
							           FROM  rcv_shipment_lines rsl,
									         ap_invoice_lines_all aila
								      WHERE  rsl.po_header_id = p_po_header_id
									    AND  aila.invoice_id  = p_invoice_id
									    AND  rsl.po_line_id = aila.po_line_id
										); 
	  */
	  SELECT TO_DATE(a.attribute1,'MM/DD/YY')
	    INTO o_latest_received_date
        FROM rcv_shipment_headers a
       WHERE a.shipment_header_id IN (SELECT MAX(shipment_header_id)
							           FROM  rcv_shipment_lines rsl,
									         po_line_locations_all pll,
									         ap_invoice_lines_all aila
								      WHERE  aila.invoice_id  = p_invoice_id
									    AND  aila.po_header_id=p_po_header_id
										AND  pll.po_line_id = aila.po_line_id  
									    AND  NVL(PLL.inspection_required_flag,'N')='N'
                                        AND  PLL.receipt_required_flag = 'Y'
									    AND  rsl.po_header_id = aila.po_header_id
										AND  rsl.po_line_id = aila.po_line_id
									 );
    EXCEPTION
	  WHEN OTHERS
	  THEN
	    o_latest_received_date := NULL;
    END;
	/*
	o_latest_received_date := TO_DATE(lc_crcv_date,'MM/DD/YY');
		SELECT  MAX(RT.transaction_date)
		  INTO  o_latest_received_date
		  FROM  rcv_transactions RT
			   ,po_line_locations_all PLL
			   ,ap_invoice_lines_all  AILA
		WHERE  AILA.invoice_id = p_invoice_id
		  AND  PLL.po_header_id = p_po_header_id
		  AND  PLL.po_line_id = AILA.po_line_id 
          AND  NVL(PLL.inspection_required_flag,'N')='N'
          AND  PLL.receipt_required_flag = 'Y'
          AND  RT.po_header_id = PLL.po_header_id
          AND  RT.po_line_location_id = PLL.line_location_id		  		  
          AND  RT.transaction_type ='DELIVER';
	*/	 		   	
EXCEPTION
	WHEN OTHERS 
	THEN
	   o_latest_received_date := NULL;
END;
-- +===================================================================+
-- | Name        : xx_ap_tr_terms_date                                 |
-- |                                                                   |
-- | Description : This procedure is used to get the terms date, goods |
-- |               received date and invoice received date             |                       
-- |                                                                   |
-- +===================================================================+						
PROCEDURE XX_AP_TR_TERMS_DATE ( p_invoice_num            IN  VARCHAR2,
                                p_invoice_id             IN  NUMBER,
                                p_sup_site_terms_basis   IN  VARCHAR2,
								p_match_type             IN  VARCHAR2,
								p_drop_ship_flag         IN  VARCHAR2,
								p_po_num                 IN  VARCHAR2,
								p_po_header_id           IN  NUMBER,
								p_invoice_date           IN  DATE,
								p_inv_creation_date      IN  DATE,
								p_terms_date             OUT DATE,
								p_goods_received_date    OUT DATE,
								p_invoice_received_date  OUT DATE
							   )
IS
  ld_latest_received_date   DATE;
  ld_invoice_date           DATE;
  ld_invoice_creation_date  DATE;
BEGIN
  ld_latest_received_date  := NULL;
  ld_invoice_date          := p_invoice_date;
  ld_invoice_creation_date := p_inv_creation_date;
	-- To get the Terms Date, Goods Received Date and Invoice received date
	-- Scenario 1 and 2
	  IF ( p_match_type = '3-Way'
		   AND p_sup_site_terms_basis = 'Goods Received'
		   AND p_drop_ship_flag = 'N')
	  THEN
		 -- To get the latest received date
		 XX_AP_LATEST_RECEIVED_DATE(p_po_header_id           =>  p_po_header_id,
		                            p_invoice_id             =>  p_invoice_id,
                                    o_latest_received_date   =>  ld_latest_received_date);
		 IF  ld_latest_received_date IS NOT NULL -- If Receipt exists
		 THEN		     
		    p_terms_date             := ld_latest_received_date;
			p_goods_received_date    := ld_latest_received_date;
			p_invoice_received_date  := ld_invoice_creation_date;
		 ELSE -- If Receipt does not exist
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := NULL;
			p_invoice_received_date  := ld_invoice_creation_date;
			XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => NULL,
										  p_invoice_num           => p_invoice_num,
										  p_vendor_id             => NULL ,
										  p_vendor_site_id        => NULL,
										  p_invoice_line_id       => NULL,
										  p_invoice_line_num      => NULL,
										  p_po_num                => p_po_num,
										  p_po_header_id          => NULL,
										  p_po_line_id            => NULL,
										  p_po_line_num           => NULL,
										  p_exception_code        => 'H001',
										  p_exception_description => 'NO Receipt Exists for the Invoice :'|| p_invoice_num||' '||'and PO :'||p_po_num ,
										  p_process_flag          => 'N',
										  p_hold_placed_flag      => NULL
										 );
		 END IF;
	-- Scenarios 3 and 4	 
	  ELSIF  ( p_match_type = '3-Way'
		       AND p_sup_site_terms_basis = 'Invoice'
		       AND p_drop_ship_flag = 'N')
	     THEN
		 -- To get the latest received date
		 XX_AP_LATEST_RECEIVED_DATE(p_po_header_id           =>  p_po_header_id,
		                            p_invoice_id             =>  p_invoice_id,
                                    o_latest_received_date   =>  ld_latest_received_date);
		 IF  ld_latest_received_date IS NOT NULL -- If Receipt exists
		 THEN		     
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := ld_latest_received_date;
			p_invoice_received_date  := ld_invoice_creation_date;
		 ELSE -- If Receipt does not exist
		    p_terms_date             := ld_invoice_date;
			p_goods_received_date    := NULL;
			p_invoice_received_date  := ld_invoice_creation_date;
			XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => NULL,
										  p_invoice_num           => p_invoice_num,
										  p_vendor_id             => NULL ,
										  p_vendor_site_id        => NULL,
										  p_invoice_line_id       => NULL,
										  p_invoice_line_num      => NULL,
										  p_po_num                => p_po_num,
										  p_po_header_id          => NULL,
										  p_po_line_id            => NULL,
										  p_po_line_num           => NULL,
										  p_exception_code        => 'H001',
										  p_exception_description => 'NO Receipt Exists for the Invoice :'|| p_invoice_num||' '||'and PO :'||p_po_num ,
										  p_process_flag          => 'N',
										  p_hold_placed_flag      => NULL
										 );
	     END IF;
	-- Scenario 5		  
	    ELSIF  (p_match_type = '2-Way'
		        AND p_sup_site_terms_basis = 'Goods Received'
		        AND p_drop_ship_flag IN ('N','Y')
			    )
	     THEN
	         p_terms_date             := ld_invoice_date;
			 p_goods_received_date    := NULL;
			 p_invoice_received_date  := ld_invoice_creation_date;
	-- Scenario 6
	 ELSIF  ( p_match_type = '2-Way'
		      AND p_sup_site_terms_basis = 'Invoice'
		      AND p_drop_ship_flag IN ('N','Y')
			)
	     THEN
	         p_terms_date             := ld_invoice_date;
			 p_goods_received_date    := NULL;
			 p_invoice_received_date  := ld_invoice_creation_date;
	 END IF;
EXCEPTION
  WHEN OTHERS 
  THEN
       p_terms_date             := NULL;
	   p_goods_received_date    := NULL;
	   p_invoice_received_date  := NULL;
	   fnd_file.put_line(fnd_file.LOG,'Unable to get the Terms Date, Goods Received Date and Invoice Received Date :'||SQLERRM);
END XX_AP_TR_TERMS_DATE;
-- +==========================================================================+
-- | Name        :  xx_check_multi                                            |
-- | Description :  To indentify if multiple invoices exists for the po line  |
-- |                                                                          |
-- | Parameters  :  p_invoice_id,p_po_line_id                                 |
-- |                                                                          |
-- | Returns     :  Y/N                                                       |
-- |                                                                          |
-- +==========================================================================+
FUNCTION xx_check_multi_inv(p_invoice_id NUMBER,
                            p_po_line_id IN NUMBER,
							p_po_header_id IN NUMBER) RETURN VARCHAR2
IS
v_multi VARCHAR2(1):='N';
v_cnt   NUMBER;
CURSOR C1
IS
SELECT DISTINCT po_line_id,po_header_id  
  FROM ap_invoice_lines_all l
 WHERE l.invoice_id=p_invoice_id
   AND l.line_type_lookup_code='ITEM'
   AND l.po_line_id=p_po_line_id
   AND l.discarded_flag='N'
UNION
SELECT p_po_line_id po_line_id,
	   p_po_header_id po_header_id
  FROM DUAL;
CURSOR C2(p_po_line_id NUMBER,p_po_header_id NUMBER)   
IS
SELECT DISTINCT l.invoice_id,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) inv_status
 FROM ap_invoices_all ai,
      ap_invoice_lines_all l
WHERE l.po_line_id=p_po_line_id
  AND l.po_header_id=p_po_header_id
  AND l.invoice_id<>p_invoice_id
  AND l.discarded_flag='N'  
  AND ai.invoice_id=l.invoice_id
  AND ai.invoice_num NOT LIKE '%ODDBUIA%';
BEGIN
  FOR cur IN C1 LOOP
    FOR c IN C2(cur.po_line_id,cur.po_header_id) LOOP
      --IF c.inv_status IN ('NEEDS REAPPROVAL','NEVER APPROVED') THEN
         v_multi:='Y';
         EXIT;
      --END IF;
    END LOOP;
  END LOOP;
  RETURN(v_multi);
EXCEPTION
  WHEN OTHERS THEN
    RETURN('X');
END xx_check_multi_inv;
-- +==========================================================================+
-- | Name        :  get_consumed_rcvqty                                       |
-- | Description :  To get consumed received qty                              |
-- |                                                                          |
-- | Parameters  :  p_invoice_id, p_item_id, p_po_header_id                   |
-- |                                                                          |
-- | Returns     :                                                            |
-- |                                                                          |
-- +==========================================================================+
FUNCTION get_consumed_rcvqty(p_po_header_id IN NUMBER, p_item_id IN NUMBER, p_invoice_id IN NUMBER,p_po_line_id IN NUMBER)
RETURN NUMBER
IS
CURSOR C1 IS
SELECT a.invoice_num,
       a.invoice_id,
       b.quantity_invoiced,
       b.po_line_location_id,
	   b.po_line_id,
       b.inventory_item_id,
       b.po_header_id
  FROM ap_invoices_all a,
       ap_invoice_lines_all b
 WHERE b.po_header_id = p_po_header_id
   AND b.inventory_item_id = p_item_id
   AND b.po_line_id=p_po_line_id
   AND b.invoice_id<>p_invoice_id
   AND a.invoice_id=b.invoice_id
   AND a.invoice_num NOT LIKE '%ODDBUIA%'
   AND 'APPROVED'=            AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.INVOICE_ID,
                                                         a.INVOICE_AMOUNT,
                                                         a.PAYMENT_STATUS_FLAG,
                                                         a.INVOICE_TYPE_LOOKUP_CODE
                                                        )
 ORDER BY a.invoice_id;
ln_tot_cons_rcv_qty NUMBER:=0;                                                         
ln_consumed_qty        NUMBER:=0;
ln_qty_rec            NUMBER;
BEGIN
  FOR cur IN C1 LOOP
    ln_qty_rec:=0;
    SELECT COUNT(1)
      INTO ln_qty_rec
      FROM ap_holds_all
     WHERE invoice_id=cur.invoice_id
       AND line_location_id=cur.po_line_location_id
       AND hold_lookup_code='QTY REC';
    IF ln_qty_rec=0 THEN
       ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
    ELSE
         SELECT NVL(SUM(b.quantity_received),0)
         INTO ln_consumed_qty
           FROM ap_holds_all h,
               rcv_shipment_lines b
        WHERE b.po_line_location_id=cur.po_line_location_id
		  AND b.po_line_id=cur.po_line_id
          AND h.invoice_id=cur.invoice_id
          AND h.line_location_id=b.po_line_location_id
          AND h.hold_lookup_code='QTY REC'
          AND b.creation_date<h.last_update_date;
       IF cur.quantity_invoiced>=ln_consumed_qty THEN
          ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+ln_consumed_qty;
       ELSE
          ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
       END IF;
    END IF;
  END LOOP;    
  RETURN(ln_tot_cons_rcv_qty);
  --dbms_output.put_line('Consumed RCV Qty :'||to_char(ln_tot_cons_rcv_qty));
EXCEPTION
  WHEN others THEN
    ln_tot_cons_rcv_qty:=0;
    RETURN(ln_tot_cons_rcv_qty);
END get_consumed_rcvqty;
-- +======================================================================+
-- | Name        :  get_unbilled_qty                                      |
-- | Description :  Return unbilled QTY                                   |
-- |                                                                      |
-- | Parameters  :  p_po_header_id, p_po_line_id,p_item_id                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_unbilled_qty(p_po_header_id IN NUMBER,p_po_line_id IN NUMBER, p_item_id IN NUMBER, p_invoice_id IN NUMBER)
RETURN NUMBER
IS
   v_rct_flag                     VARCHAR2(1);
   ln_quantity_received            NUMBER;
   ln_tot_quantity_billed        NUMBER;   
   ln_inv_quantity_billed        NUMBER;
   ln_oth_inv_qty_billed         NUMBER;
   ln_po_ord_qty                 NUMBER;
   ln_unbilled_qty                NUMBER;
   v_multi                        VARCHAR2(1):='N';
   ln_unaprvd_qty                 NUMBER;
   ln_aprvd_qty                     NUMBER;
   ln_cons_rcv_qty                NUMBER;
BEGIN
  v_multi:=xx_check_multi_inv(p_invoice_id,p_po_line_id,p_po_header_id);
  BEGIN
    SELECT receipt_required_flag
      INTO v_rct_flag
      FROM po_line_locations_all
     WHERE po_line_id=p_po_line_id
       AND ROWNUM<2;
  EXCEPTION
    WHEN others THEN
      v_rct_flag:=NULL;
  END;
  SELECT NVL(SUM(pol.quantity_received),0),
         NVL(SUM(pol.quantity_billed),0),
         NVL(SUM(pol.quantity),0)
    INTO ln_quantity_received,
         ln_tot_quantity_billed,
         ln_po_ord_qty
    FROM po_line_locations_all pol,
         po_lines_all l
   WHERE l.po_header_id = p_po_header_id
     AND l.item_id = p_item_id
	 AND l.po_line_id=p_po_line_id
     AND pol.po_line_id = l.po_line_id;     
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_inv_quantity_billed
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
	 AND po_line_id=p_po_line_id
     AND l.invoice_id=p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_holds_all
                  WHERE invoice_id = l.invoice_id
                    AND line_location_id = l.po_line_location_id);     
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_unaprvd_qty
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
	 AND po_line_id=p_po_line_id
     AND l.invoice_id<>p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_invoices_all ai
                  WHERE ai.invoice_id = l.invoice_id
                    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
                    AND 'APPROVED'<>            AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) 
                );                
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_aprvd_qty
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
	 AND po_line_id=p_po_line_id
     AND l.invoice_id<>p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_invoices_all ai
                  WHERE ai.invoice_id = l.invoice_id
                    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
                    AND 'APPROVED'=            AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) 
                );                 
  IF v_rct_flag='Y' THEN      -- Three Way
     IF v_multi='N' THEN
        ln_unbilled_qty:=ln_quantity_received;
     ELSIF v_multi='Y' THEN
        IF ln_aprvd_qty=0 THEN
           ln_unbilled_qty:=ln_quantity_received ;
        END IF;
        IF ln_aprvd_qty>0 THEN
           ln_cons_rcv_qty:=get_consumed_rcvqty(p_po_header_id,p_item_id,p_invoice_id,p_po_line_id);
           ln_unbilled_qty:=ln_quantity_received-ln_cons_rcv_qty;
        END IF;
     END IF;      
  END IF;
  IF v_rct_flag='N' THEN     -- Two Way
     IF v_multi='N' THEN
        ln_unbilled_qty:=ln_po_ord_qty;
     ELSIF v_multi='Y' THEN
        IF ln_aprvd_qty=0 THEN
           IF (ln_tot_quantity_billed-ln_po_ord_qty < 0) OR (ln_tot_quantity_billed-ln_po_ord_qty > 0) OR  (ln_tot_quantity_billed-ln_po_ord_qty = 0) THEN  
               ln_unbilled_qty:=ln_po_ord_qty;
           END IF;
        END IF;
        IF ln_aprvd_qty>0 THEN
            IF (ln_aprvd_qty-ln_po_ord_qty) >= 0 THEN
               ln_unbilled_qty:=0;
            END IF;
            IF (ln_aprvd_qty-ln_po_ord_qty) < 0 THEN
               ln_unbilled_qty:=ln_po_ord_qty-ln_aprvd_qty;
            END IF;
         END IF;
     END IF; 
  END IF;
  IF ln_unbilled_qty<0 THEN 
     ln_unbilled_qty:=0;
  END IF;
  RETURN(ln_unbilled_qty);
EXCEPTION
  WHEN OTHERS THEN
    RETURN(NULL);
END get_unbilled_qty;
-- +============================================================================================+
-- |  Name	  : update_invoice_validate_wait                                                |
-- |  Description:                                                                              |
-- =============================================================================================|
PROCEDURE update_invoice_validate_wait(p_source IN VARCHAR2,p_err_msg OUT VARCHAR2) 
IS
ln_count NUMBER;
BEGIN
   UPDATE ap_invoices_all a
      SET a.validation_request_id = NULL,
	  attribute4=to_char(sysdate,'DD-MON-YYYY')---Code added for NAIT-37732
    WHERE TRUNC(Creation_date) <= TRUNC(SYSDATE-6)
	  AND a.source=NVL(p_source,a.source)
      AND validation_request_id = -9999999999;
   ln_count := SQL%ROWCOUNT;
   print_debug_msg('Removed wait on '|| to_char(ln_count)||' invoice(s)',TRUE);        
   p_err_msg := NULL;
EXCEPTION
WHEN OTHERS THEN
   p_err_msg := SUBSTR(SQLERRM,1,250);
END update_invoice_validate_wait;    
-- +============================================================================================+
-- |  Name	  : OD Line Variance Check                                                          |
-- |  Description : Checks each line for OD Line Variance and applies holds                     |
-- =============================================================================================|
PROCEDURE od_line_variance_check(p_err_buf             OUT  VARCHAR2,
                                 p_retcode             OUT  VARCHAR2,
								 p_holds_placed        OUT  NUMBER,
								 p_po_header_id		   IN   NUMBER,
								 p_vendor_id           IN   NUMBER,
								 p_vendor_site_id      IN   NUMBER,
								 p_org_id              IN   NUMBER,
								 p_invoice_id          IN   NUMBER,
								 p_invoice_num         IN   VARCHAR2)
IS
    CURSOR get_dist_var_amt (p_supplier_id  NUMBER,
                             p_supp_site_id NUMBER,
                             p_org_id       NUMBER) 
	IS
	SELECT dist_var_neg_amt * -1,
		   dist_var_pos_amt 
      FROM xx_ap_custom_tolerances 
     WHERE supplier_id = p_supplier_id
	   AND supplier_site_id = p_supp_site_id
	   AND org_id=p_org_id;
    CURSOR inv_lines_cur(p_invoice_id NUMBER) 
	IS      
    SELECT l.invoice_id,
	       SUM(NVL(l.amount,0)) amount
      FROM ap_invoice_lines_all l
     WHERE l.invoice_id = p_invoice_id
       AND l.line_type_lookup_code='MISCELLANEOUS'
	   AND l.attribute10 = 'Y' -- Added for Version 1.5
	 GROUP BY l.invoice_id
     ORDER BY 1,2;
    ln_count                    NUMBER;
	ln_dist_var_neg_amt			NUMBER;
    ln_dist_var_pos_amt			NUMBER;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.OD_LINE_VARIANCE_CHECK';  
    lc_hold_type 		        VARCHAR2(70)	:='INVOICE HOLD REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:='OD Line Variance';
    lc_hold_reason 		        VARCHAR2(200)	:='Balancing Line Variance hold for exceeding tolerance';  
    ln_hold_placed_count	    NUMBER		    := 0;
BEGIN
    ln_hold_placed_count   := 0; 
    print_debug_msg('Begin check for OD Line Variance and apply hold if needed',FALSE); 
    print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
	FOR cur IN inv_lines_cur(p_invoice_id) LOOP
        print_debug_msg('Check if max distribution variance amount is defined for the vendor site',FALSE); 
   	    ln_dist_var_neg_amt	:=NULL;
        ln_dist_var_pos_amt :=NULL;			
        OPEN get_dist_var_amt(p_vendor_id,p_vendor_site_id,p_org_id);
        FETCH get_dist_var_amt INTO ln_dist_var_neg_amt,ln_dist_var_pos_amt;
        CLOSE get_dist_var_amt;
		IF (ln_dist_var_neg_amt IS NULL OR ln_dist_var_pos_amt IS NULL )
		THEN 
		   CONTINUE;
		END IF;
		IF (    (cur.amount > 0 AND cur.amount > ln_dist_var_pos_amt)
		     OR (cur.amount < 0 AND cur.amount < ln_dist_var_neg_amt) 
		   ) 
		THEN
           --Check if custom hold exists for this invoice
           print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num,FALSE); 
	       SELECT count(1) 
  	         INTO ln_count
	         FROM ap_holds_all
	        WHERE invoice_id = p_invoice_id
	          AND hold_lookup_code = 'OD Line Variance'
	          AND release_lookup_code IS NULL;   
		   IF ln_count = 0 THEN	
              BEGIN               
				mo_global.set_policy_context ('S',p_org_id);
				mo_global.init ('SQLAP');
				ap_holds_pkg.insert_single_hold
					(	x_invoice_id            => p_invoice_id,
						x_hold_lookup_code      => lc_hold_lookup_code,
						x_hold_type             => lc_hold_type,
						x_hold_reason           => lc_hold_reason,
						x_held_by               => gn_user_id,  
						x_calling_sequence      => NULL);
				ln_hold_placed_count := ln_hold_placed_count + 1;  
				XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
										   p_invoice_num           => p_invoice_num,
										   p_vendor_id             => p_vendor_id ,
										   p_vendor_site_id        => p_vendor_site_id,
										   p_invoice_line_id       => NULL,
										   p_invoice_line_num      => NULL,
										   p_po_num                => NULL,
										   p_po_header_id          => p_po_header_id,
										   p_po_line_id            => NULL,
										   p_po_line_num           => NULL,
										   p_exception_code        => 'H006',
										   p_exception_description => 'Balancing Line Variance hold for exceeding tolerance',
										   p_process_flag          => 'N',
										   p_hold_placed_flag      => 'Y'
										 );
			  EXCEPTION
			    WHEN OTHERS THEN
				print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num,TRUE); 
				XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
										   p_invoice_num           => p_invoice_num,
										   p_vendor_id             => p_vendor_id ,
										   p_vendor_site_id        => p_vendor_site_id,
										   p_invoice_line_id       => NULL,
										   p_invoice_line_num      => NULL,
										   p_po_num                => NULL,
										   p_po_header_id          => p_po_header_id,
										   p_po_line_id            => NULL,
										   p_po_line_num           => NULL,
										   p_exception_code        => 'H006',
										   p_exception_description => 'Balancing Line Variance hold for exceeding tolerance',
										   p_process_flag          => 'N',
										   p_hold_placed_flag      => NULL
										 );
				p_retcode := '2';		                
			  END;		
		   END IF; --ln_count
		END IF;    --IF (    (cur.amount > 0 AND cur.amount > ln_dist_var_pos_amt)
	END LOOP;
    p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
  WHEN OTHERS THEN 
    lc_error_msg := 'ERROR processing invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
    print_debug_msg (lc_error_msg,TRUE);
    log_exception ('OD AP Trade Match Prevalidation Program',
    		           lc_error_loc,
			           lc_error_msg);
    p_retcode := '2';    
END od_line_variance_check;
-- +============================================================================================+
-- |  Name	  : price_tolerance_check                                                           |
-- |  Description : Checks each line for price tolerance and applies/removes holds              |
-- =============================================================================================|
PROCEDURE price_tolerance_check(p_err_buf             OUT  VARCHAR2,
                                p_retcode             OUT  VARCHAR2,
								p_holds_placed        OUT  NUMBER,
								p_holds_released      OUT  NUMBER,
								p_po_header_id        IN   NUMBER,
								p_creation_date       IN   DATE,
								p_vendor_id           IN   NUMBER,
								p_vendor_site_id      IN   NUMBER,
								p_org_id              IN   NUMBER,
								p_invoice_id          IN   NUMBER,
								p_invoice_num         IN   VARCHAR2)
IS
    CURSOR get_max_price_amt(p_supplier_id  NUMBER,
                             p_supp_site_id NUMBER,
                             p_org_id       NUMBER) 
	IS
       SELECT max_price_amt 
         FROM xx_ap_custom_tolerances 
        WHERE supplier_id = p_supplier_id 
          AND supplier_site_id = p_supp_site_id 
          AND org_id = p_org_id;
	CURSOR inv_lines_cur(p_invoice_id NUMBER) 
	IS
	   SELECT l.invoice_id,
              l.line_number,
              l.po_line_location_id line_location_id,
              SUM(NVL(l.quantity_invoiced,0)*NVL(b.unit_price,0)) billed_po_price,
              SUM(NVL(l.quantity_invoiced,0)*NVL(l.unit_price,0)) billed_inv_price
         FROM po_lines_all b,
              ap_invoice_lines_all l
        WHERE l.invoice_id = p_invoice_id
          AND l.line_type_lookup_code='ITEM'
          AND b.po_line_id=l.po_line_id
		  AND b.unit_price <> l.unit_price
     GROUP BY l.invoice_id,
              l.line_number,
              l.po_line_location_id
     ORDER BY 1,2;    
   CURSOR get_std_tolerance_values(p_vendor_id NUMBER,
                                   p_vendor_site_id NUMBER,
                                   p_org_id NUMBER) IS	 
   SELECT b.price_tolerance
	 FROM ap_tolerance_templates b,
	      ap_supplier_sites_all ss
    WHERE ss.vendor_site_id = p_vendor_site_id
	  AND ss.vendor_id = p_vendor_id
	  AND b.tolerance_id = ss.tolerance_id
	  AND ss.org_id = p_org_id;
    TYPE inv_lines IS TABLE OF inv_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;  
    l_inv_lines_tab 		INV_LINES;
    l_indx                 	    NUMBER;
    ln_count                    NUMBER;
    ln_max_price_amt            NUMBER;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.PRICE_TOLERANCE_CHECK';  
    lc_rowid			        VARCHAR2(250);
    ln_hold_id			        NUMBER;
    lc_hold_type 		        VARCHAR2(70)	:='MATCHING RELEASE REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:='OD Max Price';
    lc_hold_reason 		        VARCHAR2(200)	:='Invoice price exceeds PO price by max tolerance';  
    ln_tot_records_processed    NUMBER		    := 0;
    ln_hold_placed_count	    NUMBER		    := 0;
    ln_hold_released_count	    NUMBER		    := 0;
    ln_std_price_tolerance      NUMBER			:= 0;
	ln_inv_price_tol			NUMBER		    := 0;
BEGIN
    ln_hold_released_count := 0;
    ln_hold_placed_count   := 0; 
    OPEN get_std_tolerance_values(p_vendor_id,p_vendor_site_id,p_org_id);
    FETCH get_std_tolerance_values INTO ln_std_price_tolerance;
    CLOSE get_std_tolerance_values;
    print_debug_msg('Begin check for price tolerance and apply hold if needed',FALSE); 
    print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
    --print_debug_msg('Check if max price amt is defined for the vendor site',FALSE); 
    ln_max_price_amt := NULL;
    OPEN get_max_price_amt(p_vendor_id,p_vendor_site_id,p_org_id);
    FETCH get_max_price_amt INTO ln_max_price_amt;
    CLOSE get_max_price_amt;
    IF ln_max_price_amt IS NOT NULL 
	THEN
    --Check each invoice line for price tolerance
    --print_debug_msg('Check each invoice line for price tolerance',FALSE); 
    OPEN inv_lines_cur(p_invoice_id);
    FETCH inv_lines_cur BULK COLLECT INTO l_inv_lines_tab;
    CLOSE inv_lines_cur;       
    FOR l_indx IN 1..l_inv_lines_tab.COUNT
    LOOP
      BEGIN
	    ln_inv_price_tol:=((NVL(l_inv_lines_tab(l_indx).billed_inv_price,0)-NVL(l_inv_lines_tab(l_indx).billed_po_price,0))/NVL(l_inv_lines_tab(l_indx).billed_po_price,0))*100;
	  EXCEPTION
	    WHEN OTHERS
		THEN
	      ln_inv_price_tol:= NULL;
  	  END;
	  IF ln_inv_price_tol IS NULL 
	  THEN
        CONTINUE; -- skip and continue to next invoice line record.
      END IF; 
	  IF ln_inv_price_tol < ln_std_price_tolerance THEN 
	     BEGIN 
          --Check if custom hold exists for this invoice
          --print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num||' Line Num'||l_inv_lines_tab(l_indx).line_number,FALSE); 
           SELECT COUNT(1) 
             INTO ln_count
		     FROM ap_holds_all
		    WHERE invoice_id = p_invoice_id
		      AND hold_lookup_code = 'OD Max Price'
		      AND line_location_id = l_inv_lines_tab(l_indx).line_location_id
		      AND release_lookup_code IS NULL;   
          IF ln_count = 0 AND ((l_inv_lines_tab(l_indx).billed_inv_price - l_inv_lines_tab(l_indx).billed_po_price) > ln_max_price_amt) 
		  THEN	
	        BEGIN
	           --print_debug_msg('Apply the hold',FALSE);
               mo_global.set_policy_context ('S',p_org_id);
               mo_global.init ('SQLAP');
      		   ap_holds_pkg.Insert_Row( X_Rowid 	            => lc_rowid, 
      			                        X_hold_id 	            => ln_hold_id,
      			                        X_Invoice_Id 	        => p_invoice_id,  
						                X_Line_Location_Id 	    => l_inv_lines_tab(l_indx).line_location_id, 
									    X_Hold_Lookup_Code	    => lc_hold_lookup_code,
									    X_Last_Update_Date 	    => SYSDATE, 
										X_Last_Updated_By 	    => gn_user_id,
										X_Held_By	            => gn_user_id, 
										X_Hold_Date 	        => SYSDATE, 
										X_Hold_Reason 	        => lc_hold_reason, 
										X_Release_Lookup_Code 	=> NULL, 
										X_Release_Reason        => NULL,
										X_Status_Flag 	        => 'S', 
										X_Last_Update_Login  	=> gn_login_id,
										X_Creation_Date 	    => SYSDATE, 
										X_Created_By 	        => gn_user_id,
										X_Responsibility_Id  	=> NULL, 
						                X_Attribute1            => NULL, 
										X_Attribute2			=> NULL,
										X_Attribute3            => NULL,
										X_Attribute4            => NULL, 
						                X_Attribute5            => NULL, 
										X_Attribute6            => NULL, 
										X_Attribute7            => NULL, 
										X_Attribute8            => NULL, 
						                X_Attribute9            => NULL,
										X_Attribute10           => NULL,
										X_Attribute11           => NULL,
										X_Attribute12           => NULL, 
						                X_Attribute13           => NULL,
										X_Attribute14           => NULL,
										X_Attribute15           => NULL,
										X_Attribute_Category    => NULL, 
						                X_Org_Id	            => p_org_id, 
						                X_calling_sequence 	    => NULL
									  );  
                ln_hold_placed_count := ln_hold_placed_count + 1;      
			    XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
											  p_invoice_num           => p_invoice_num,
											  p_vendor_id             => p_vendor_id ,
											  p_vendor_site_id        => p_vendor_site_id,
											  p_invoice_line_id       => NULL,
											  p_invoice_line_num      => l_inv_lines_tab(l_indx).line_number,
											  p_po_num                => NULL,
											  p_po_header_id          => p_po_header_id,
											  p_po_line_id            => NULL,
											  p_po_line_num           => NULL,
											  p_exception_code        => 'H002',
											  p_exception_description => 'Invoice Line and PO Line Price greater than Max Price Tolerance',
											  p_process_flag          => 'N',
											  p_hold_placed_flag      => 'Y'
										 );
            EXCEPTION
            WHEN OTHERS
			THEN
                print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num||' Line Num'||l_inv_lines_tab(l_indx).line_number,TRUE); 
			 XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
										   p_invoice_num           => p_invoice_num,
										   p_vendor_id             => p_vendor_id ,
										   p_vendor_site_id        => p_vendor_site_id,
										   p_invoice_line_id       => NULL,
										   p_invoice_line_num      => l_inv_lines_tab(l_indx).line_number,
										   p_po_num                => NULL,
										   p_po_header_id          => p_po_header_id,
										   p_po_line_id            => NULL,
										   p_po_line_num           => NULL,
										   p_exception_code        => 'H002',
										   p_exception_description => 'Invoice Line and PO Line Price greater than Max Price Tolerance',
										   p_process_flag          => 'N',
										   p_hold_placed_flag      => NULL
										 );
                 p_retcode := '2';		                
            END;		
          END IF; --ln_count
          IF ln_count > 0 AND ((l_inv_lines_tab(l_indx).billed_inv_price - l_inv_lines_tab(l_indx).billed_po_price) = 0) 
		  THEN
		    UPDATE ap_holds_all
		       SET release_lookup_code = 'INVOICE QUICK RELEASED',
		    	   release_reason = 'Holds released in Invoice Holds window',
			       last_update_date = SYSDATE, 
			       last_updated_by = gn_user_id
		     WHERE invoice_id = p_invoice_id
		       AND line_location_id = l_inv_lines_tab(l_indx).line_location_id
		       AND hold_lookup_code = 'OD Max Price'
			   AND release_lookup_code IS NULL;
			ln_hold_released_count := ln_hold_released_count + 1;
	        UPDATE xx_ap_tr_match_exceptions
	           SET hold_release_flag = 'Y', --discuss new column added
	               created_by = gn_user_id,
			       creation_date = SYSDATE,
			       last_updated_by = gn_user_id,
			       last_update_date = SYSDATE,
                   last_update_login = gn_login_id
	         WHERE invoice_id = p_invoice_id
	           AND invoice_line_num = l_inv_lines_tab(l_indx).line_number;
          END IF;
      EXCEPTION
      WHEN OTHERS 
	  THEN
    	  lc_error_msg := 'ERROR processing(price_tolerance_check) invoice_num '||p_invoice_num||'line-'||SUBSTR(SQLERRM,1,250);
    	  print_debug_msg (lc_error_msg,TRUE);
    	  log_exception ('OD AP Trade Match Prevalidation Program',
    		             lc_error_loc,
			             lc_error_msg);
          p_retcode := '2';			         
      END;
	  END IF;  --IF ln_inv_price_tol < ln_std_price_tolerance THEN 	  
    END LOOP; --lines l_indx
	END IF; -- ln_max_price_amt IS NOT NULL
    COMMIT;   --discuss commit after each invoice.
    print_debug_msg('Commit Complete',FALSE);
	p_holds_released  := ln_hold_released_count;
    p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
    WHEN OTHERS 
	THEN 
        lc_error_msg := 'ERROR processing invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
        print_debug_msg (lc_error_msg,TRUE);
    	log_exception ('OD AP Trade Match Prevalidation Program',
    		           lc_error_loc,
			           lc_error_msg);
        p_retcode := '2';    
END price_tolerance_check;
-- +============================================================================================+
-- |  Name	  : freight_tolerance_check                                                         |
-- |  Description : Checks each line for freight tolerance and applies/removes holds            |
-- =============================================================================================|
PROCEDURE freight_tolerance_check(p_err_buf             OUT  VARCHAR2,
                                  p_retcode             OUT  VARCHAR2,
								  p_holds_placed        OUT  NUMBER,
								  p_holds_released      OUT  NUMBER,
								  p_po_header_id        IN   NUMBER,
								  p_creation_date       IN   DATE,
								  p_vendor_id           IN   NUMBER,
								  p_vendor_site_id      IN   NUMBER,
								  p_org_id              IN   NUMBER,
								  p_invoice_id          IN   NUMBER,
								  p_invoice_num         IN   VARCHAR2)
IS
    CURSOR get_max_freight_amt(p_supplier_id  NUMBER,
                               p_supp_site_id NUMBER,
                               p_org_id       NUMBER) 
    IS
       SELECT max_freight_amt 
         FROM xx_ap_custom_tolerances 
        WHERE supplier_id = p_supplier_id 
          AND supplier_site_id = p_supp_site_id 
          AND org_id = p_org_id;
    CURSOR inv_freight_amt_cur(p_invoice_id NUMBER) 
	IS      
       SELECT SUM(l.amount)
         FROM ap_invoice_lines_all l
        WHERE l.invoice_id = p_invoice_id
          AND l.line_type_lookup_code='FREIGHT';
    ln_count                    NUMBER;
    ln_max_freight_amt          NUMBER;
    ln_inv_freight_amt		    NUMBER;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.FREIGHT_TOLERANCE_CHECK';  
    lc_hold_type 		        VARCHAR2(70)	:='MATCHING RELEASE REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:='OD Max Freight';
    lc_hold_reason 		        VARCHAR2(200)	:='Freight Amount exceeds Custom Frieght tolerance amount';  
    lc_release_lookup_code      VARCHAR2(100)   :='INVOICE QUICK RELEASED';
    ln_hold_placed_count	    NUMBER;
    ln_hold_released_count	    NUMBER;    
BEGIN
      ln_hold_placed_count	  := 0;
      ln_hold_released_count  := 0;  
      print_debug_msg('Begin check for freight tolerance and apply hold if needed',FALSE);   
      print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
      --print_debug_msg('Check if max price amt is defined for the vendor site',FALSE); 
      ln_max_freight_amt := NULL;
      OPEN get_max_freight_amt(p_vendor_id,p_vendor_site_id,p_org_id);
      FETCH get_max_freight_amt INTO ln_max_freight_amt;
      CLOSE get_max_freight_amt;
      IF ln_max_freight_amt IS NOT NULL 
	  THEN           
	        ln_inv_freight_amt := NULL;   
            OPEN inv_freight_amt_cur(p_invoice_id);
            FETCH inv_freight_amt_cur INTO ln_inv_freight_amt;
            CLOSE inv_freight_amt_cur;
            --Check if custom hold exists for this invoice
            --print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num,FALSE); 
	        SELECT count(1) 
	          INTO ln_count
	          FROM ap_holds_all
	         WHERE invoice_id = p_invoice_id
	           AND hold_lookup_code = 'OD Max Freight'
	           AND release_lookup_code IS NULL;   
            IF ln_count = 0 AND ((ln_inv_freight_amt) > ln_max_freight_amt) 
	        THEN	
               BEGIN               
             	   mo_global.set_policy_context ('S',p_org_id);
             	   mo_global.init ('SQLAP');
		         ap_holds_pkg.insert_single_hold
		      		  (x_invoice_id            => p_invoice_id,
		      		   x_hold_lookup_code      => lc_hold_lookup_code,
		      		   x_hold_type             => lc_hold_type,
		      		   x_hold_reason           => lc_hold_reason,
		      		   x_held_by               => gn_user_id,  --discuss
		      		   x_calling_sequence      => NULL);
		         ln_hold_placed_count := ln_hold_placed_count + 1;  
		         	 XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
		      								       p_invoice_num           => p_invoice_num,
		      								       p_vendor_id             => p_vendor_id ,
		      								       p_vendor_site_id        => p_vendor_site_id,
		      								       p_invoice_line_id       => NULL,
		      								       p_invoice_line_num      => NULL,
		      								       p_po_num                => NULL,
		      								       p_po_header_id          => p_po_header_id,
		      								       p_po_line_id            => NULL,
		      								       p_po_line_num           => NULL,
		      								       p_exception_code        => 'H003',
		      								       p_exception_description => 'Invoice Freight Price greater than Custom Max Freight Amount',
		      								       p_process_flag          => 'N',
		      								       p_hold_placed_flag      => 'Y'
		      								      );
               EXCEPTION
                WHEN OTHERS 
		        THEN
                   print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num,TRUE); 
		         	 XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
		      								       p_invoice_num           => p_invoice_num,
		      								       p_vendor_id             => p_vendor_id ,
		      								       p_vendor_site_id        => p_vendor_site_id,
		      								       p_invoice_line_id       => NULL,
		      								       p_invoice_line_num      => NULL,
		      								       p_po_num                => NULL,
		      								       p_po_header_id          => p_po_header_id,
		      								       p_po_line_id            => NULL,
		      								       p_po_line_num           => NULL,
		      								       p_exception_code        => 'H003',
		      								       p_exception_description => 'Invoice Freight Price greater than Custom Max Freight Amount',
		      								       p_process_flag          => 'N',
		      								       p_hold_placed_flag      => NULL
		      								      );
                 p_retcode := '2';		                
               END;		
            END IF; --ln_count
            IF ln_count > 0 AND (ln_inv_freight_amt = ln_max_freight_amt) 
	        THEN --discuss if this can be less than (<=)
	          BEGIN
                 mo_global.set_policy_context ('S',p_org_id);
                 mo_global.init ('SQLAP');
		         ap_holds_pkg.release_single_hold
		      	 (x_invoice_id               => p_invoice_id,
		      	  x_hold_lookup_code         => lc_hold_lookup_code,
		      	  x_release_lookup_code      => lc_release_lookup_code,
		      	  x_held_by                  => gn_user_id,
		      	  x_calling_sequence         => NULL
		      	 );
		         ln_hold_released_count := ln_hold_released_count + 1;
	             UPDATE xx_ap_tr_match_exceptions
		            SET hold_release_flag = 'Y', --discuss new column added
		                created_by = gn_user_id,
		                creation_date = SYSDATE,
		                last_updated_by = gn_user_id,
		                last_update_date = SYSDATE,
		                last_update_login = gn_login_id
	              WHERE invoice_id = p_invoice_id;
		          --AND invoice_line_num = l_inv_lines_tab(l_indx).line_number;--discuss if this needs to be for that line	
		          ln_hold_released_count := ln_hold_released_count + 1;
  	          EXCEPTION
	          WHEN OTHERS 
		      THEN
    	        lc_error_msg := 'ERROR while releasing max freight hold on invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
    	        print_debug_msg (lc_error_msg,TRUE);
    	        log_exception ('OD AP Trade Match Prevalidation Program',
    	      	              lc_error_loc,
		      	              lc_error_msg
		      				);
              p_retcode := '2';		 
	          END;
            END IF;
        COMMIT; --discuss commit after each invoice.
      END IF;       
   print_debug_msg('Commit Complete',FALSE);
   p_holds_released  := ln_hold_released_count;
   p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
    WHEN OTHERS 
	THEN
      lc_error_msg := 'ERROR processing(freight_tolerance_check) invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception ('OD AP Trade Match Prevalidation Program',
    	             lc_error_loc,
	  	             lc_error_msg
					);
      p_retcode := '2';			            
END freight_tolerance_check;
-- +============================================================================================+
-- |  Name	      : favorable_cost_variance                                                     |
-- |  Description : Create the holds for the Favorable Cost Variance                            |
-- =============================================================================================|
PROCEDURE favorable_cost_variance(p_err_buf             OUT  VARCHAR2,
                                  p_retcode             OUT  VARCHAR2,
								  p_holds_placed        OUT  NUMBER,
								  p_po_header_id        IN   NUMBER,
								  p_creation_date       IN   DATE,
								  p_vendor_id           IN   NUMBER,
								  p_vendor_site_id      IN   NUMBER,
								  p_org_id              IN   NUMBER,
								  p_invoice_id          IN   NUMBER,
								  p_invoice_num         IN   VARCHAR2) 
IS	  
	CURSOR inv_lines_cur(p_invoice_id NUMBER) 
	IS 			
	  SELECT l.line_number,
			 l.quantity_invoiced inv_qty,
			 l.unit_price inv_price,
			 b.quantity po_qty, 
			 b.unit_price po_price,
			 l.po_header_id,
			 l.po_line_id ,
             c.line_location_id			 
		FROM po_lines_all b,
			 po_line_locations_all c,
			 po_distributions_all d,
			 ap_invoice_distributions_all f,
			 ap_invoice_lines_all l
	   WHERE l.invoice_id = p_invoice_id
		 AND f.invoice_id= l.invoice_id
		 AND f.invoice_line_number = l.line_number
		 AND l.line_type_lookup_code = 'ITEM'
		 AND l.unit_price <> b.unit_price
		 AND d.po_distribution_id = f.po_distribution_id
		 AND f.line_type_lookup_code='ACCRUAL'
		 AND (f.cancellation_flag IS NULL OR f.cancellation_flag = 'N')
		 AND c.line_location_id = d.line_location_id
		 AND b.po_header_id = c.po_header_id
		 AND b.po_line_id = c.po_line_id
	   ORDER BY 1;
	TYPE inv_lines IS TABLE OF inv_lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER;  
    l_inv_lines_tab 		INV_LINES;
    l_indx                 	    NUMBER;
    ln_count                    NUMBER;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.FAVORABLE_COST_VARIANCE'; 
    l_fav_cost_var              VARCHAR2(1);	
	ln_favourable_price_pct     NUMBER;
	lc_hold_type 		        VARCHAR2(70)	:='MATCHING RELEASE REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:='OD Favorable';
    lc_hold_reason 		        VARCHAR2(200)	:='Line Variance exceeding Favorable Tolerance Percent';  
    lc_release_lookup_code      VARCHAR2(100)   :='OTHERS';
    ln_hold_placed_count	    NUMBER;
	v_rowid                     VARCHAR2(100);
	v_hold_id                   NUMBER;
	ln_price_tolerance          NUMBER          := 0;
    ln_hold_count               NUMBER;
BEGIN
   ln_hold_placed_count := 0;
   print_debug_msg('Begin check for Favorable Cost Variance',FALSE); 
   print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
      BEGIN
		SELECT favourable_price_pct
	      INTO ln_favourable_price_pct
          FROM xx_ap_custom_tolerances
         WHERE supplier_id = p_vendor_id
           AND supplier_site_id = p_vendor_site_id
           AND org_id = p_org_id;
	  EXCEPTION
	  WHEN OTHERS
	  THEN
	    print_debug_msg('Unable to get the favorable price pct from the xx_ap_custom_tolerances table for Vendor ID :'||p_vendor_id||' and Vendor Site ID :'||p_vendor_site_id,FALSE); 
		ln_favourable_price_pct := NULL;
      END;	
	  IF ln_favourable_price_pct IS NOT NULL 
	  THEN
	--Calculate the price tolerance for the each invoice line 
      --print_debug_msg('Calculate the price tolerance for the each invoice line',FALSE); 
      OPEN inv_lines_cur(p_invoice_id);
      FETCH inv_lines_cur BULK COLLECT INTO l_inv_lines_tab;
      CLOSE inv_lines_cur;       
      FOR l_indx IN 1..l_inv_lines_tab.COUNT
      LOOP
      BEGIN 			   
		  ln_price_tolerance := ((NVL(l_inv_lines_tab(l_indx).inv_price,0)- NVL(l_inv_lines_tab(l_indx).po_price,0))/NVL(l_inv_lines_tab(l_indx).po_price,0)) * 100;
		  IF ln_price_tolerance < 0 
		  THEN
			  IF ABS(ln_price_tolerance) > ln_favourable_price_pct
			  THEN
			  --Check if Favorable hold exists for the invoice line
                  --print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num||' Line Num'||l_inv_lines_tab(l_indx).line_number,FALSE);  
			      SELECT  COUNT(1) 
				    INTO  ln_hold_count
                    FROM  ap_holds_all
                   WHERE  invoice_id = p_invoice_id
					 AND  line_location_id = l_inv_lines_tab(l_indx).line_location_id
                     AND  hold_lookup_code = lc_hold_lookup_code
                     AND  release_lookup_code IS NULL;
				  SELECT COUNT(1) 
				    INTO ln_count
					FROM xx_ap_tr_match_exceptions 
				   WHERE invoice_id = p_invoice_id 
				     AND invoice_line_num = l_inv_lines_tab(l_indx).line_number 
					 AND vendor_id = p_vendor_id 
					 AND vendor_site_id = p_vendor_site_id 
					 AND exception_code = 'H005';
					 IF ln_hold_count = 0
					 THEN
						BEGIN               
						  mo_global.set_policy_context('S',p_org_id);
						  mo_global.init('SQLAP');
						  ap_holds_pkg.Insert_Row
							              (X_Rowid                  => v_rowid,
                                           X_Hold_id                => v_hold_id,
                                           X_Invoice_Id             => p_invoice_id,
										   X_Line_Location_Id       => l_inv_lines_tab(l_indx).line_location_id,
										   X_Hold_Lookup_Code       => lc_hold_lookup_code,
										   X_Last_Update_Date       => SYSDATE,
										   X_Last_Updated_By        => gn_user_id,
										   X_Held_By                => gn_user_id,
										   X_Hold_Date              => SYSDATE,
										   X_Hold_Reason            => lc_hold_reason,
										   X_Release_Lookup_Code    => NULL,
										   X_Release_Reason         => NULL,
										   X_Status_Flag            => 'S',
										   X_Last_Update_Login      => gn_login_id,
										   X_Creation_Date          => SYSDATE,
										   X_Created_By             => gn_user_id,
								           X_Responsibility_Id		=> NULL,
										   X_Attribute1             => NULL,
										   X_Attribute2             => NULL,
										   X_Attribute3             => NULL,
										   X_Attribute4             => NULL,
										   X_Attribute5             => NULL,
										   X_Attribute6             => NULL,
										   X_Attribute7             => NULL,
										   X_Attribute8             => NULL,
										   X_Attribute9             => NULL,
										   X_Attribute10            => NULL,
										   X_Attribute11            => NULL,
										   X_Attribute12            => NULL,
										   X_Attribute13            => NULL,
										   X_Attribute14            => NULL,
										   X_Attribute15            => NULL,
										   X_Attribute_Category     => NULL,
										   X_Org_Id                 => p_org_id,
								           X_calling_sequence		=> NULL
                                          );	   
							  ln_hold_placed_count := ln_hold_placed_count + 1;  
						EXCEPTION
						WHEN OTHERS 
						THEN
							lc_error_msg := 'ERROR while creating the hold on invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
							print_debug_msg (lc_error_msg,TRUE);
							log_exception ('OD AP Trade Match Prevalidation Program',
											lc_error_loc,
											lc_error_msg);			    
						END;
					 END IF; -- ln_hold_count = 0
					 IF ln_count = 0 
					 THEN	
						BEGIN 
							 XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
														   p_invoice_num           => p_invoice_num,
														   p_vendor_id             => p_vendor_id ,
														   p_vendor_site_id        => p_vendor_site_id,
														   p_invoice_line_id       => l_inv_lines_tab(l_indx).line_number,
														   p_invoice_line_num      => NULL,
														   p_po_num                => NULL,
														   p_po_header_id          => p_po_header_id,
														   p_po_line_id            => NULL,
														   p_po_line_num           => NULL,
														   p_exception_code        => 'H005',
														   p_exception_description => 'Line Variance exceeds custom favorable Tolerance %',
														   p_process_flag          => 'N',
														   p_hold_placed_flag      => 'Y'
														 );
						EXCEPTION
						WHEN OTHERS 
						THEN
						   print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num||' Line Num'||l_inv_lines_tab(l_indx).line_number,TRUE); 
							 XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
														   p_invoice_num           => p_invoice_num,
														   p_vendor_id             => p_vendor_id ,
														   p_vendor_site_id        => p_vendor_site_id,
														   p_invoice_line_id       => l_inv_lines_tab(l_indx).line_number,
														   p_invoice_line_num      => NULL,
														   p_po_num                => NULL,
														   p_po_header_id          => p_po_header_id,
														   p_po_line_id            => NULL,
														   p_po_line_num           => NULL,
														   p_exception_code        => 'H005',
														   p_exception_description => 'Line Variance exceeds custom favorable Tolerance %',
														   p_process_flag          => 'N',
														   p_hold_placed_flag      => NULL
														 );
						   p_retcode := '2';		                
						END;		
					 END IF; --ln_count
			  END IF; -- if ABS(ln_price_tolerance) > ln_favourable_price_pct
		  END IF; -- if ln_price_tolerance < 0
      EXCEPTION
      WHEN OTHERS 
	  THEN
    	lc_error_msg := 'ERROR processing invoice_num '||p_invoice_num||'line-'||SUBSTR(SQLERRM,1,250);
    	print_debug_msg (lc_error_msg,TRUE);
    	log_exception ('OD Favorable Variance',
    		            lc_error_loc,
			            lc_error_msg);
        p_retcode := '2';			         
      END;
      END LOOP; --lines l_indx
	END IF; -- ln_favourable_price_pct IS NOT NULL
    COMMIT;   --discuss commit after each invoice.
    print_debug_msg('Commit Complete',FALSE);
	p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
  WHEN OTHERS 
  THEN 
      lc_error_msg := SUBSTR(SQLERRM,1,250);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception ('OD AP Favorable Cost Variance Hold',
    		        lc_error_loc,
			        lc_error_msg);
      p_retcode := '2';
      p_err_buf := lc_error_msg;
END favorable_cost_variance;
-- +============================================================================================+
-- |  Name	      : update_ap_invoices_all                                                      |
-- |  Description : Updating the Goods Received Date, Invoice received date and Terms Date      |
-- =============================================================================================|
PROCEDURE update_ap_invoices_all(p_err_buf             OUT  VARCHAR2,
                                 p_retcode             OUT  VARCHAR2,
								 p_po_header_id        IN   NUMBER,
								 p_creation_date       IN   DATE,
								 p_vendor_id           IN   NUMBER,
								 p_vendor_site_id      IN   NUMBER,
								 p_org_id              IN   NUMBER,
								 p_invoice_id          IN   NUMBER,
								 p_invoice_num         IN   VARCHAR2) 
IS	  
CURSOR inv_hdr (p_invoice_id NUMBER)
IS
   SELECT *
     FROM ap_invoices_all
    WHERE invoice_id = p_invoice_id
	  AND source IN ('US_OD_TDM',
	                 'US_OD_TRADE_EDI',
					 'US_OD_DCI_TRADE',
					 'US_OD_DROPSHIP',
					 'MANUAL INVOICE ENTRY')
	 AND invoice_type_lookup_code = 'STANDARD';
invoices_updt                   inv_hdr%ROWTYPE;
ld_terms_date                   DATE;
ld_goods_received_date          DATE;
ld_invoice_received_date        DATE;
lc_match_type                   VARCHAR2(50);
lc_po_type                      VARCHAR2(30);
lc_closed_code                  VARCHAR2(30);
lc_terms_date_basis             VARCHAR2(30);	
lc_authorization_status         VARCHAR2(30);
lc_drop_ship_flag               VARCHAR2(1);
lc_po_number                    VARCHAR2(30);
lc_inspection_req_flag          VARCHAR2(10);
lc_receipt_req_flag             VARCHAR2(10);
lc_error_msg                    VARCHAR2(1000);
lc_error_loc                    VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.UPDATE_AP_INVOICES_ALL';
lc_source                       VARCHAR2(100); 
lc_attr2                        VARCHAR2(1);
BEGIN
  print_debug_msg('Begin check for Updating the Goods Received Date, Invoice received date and Terms Date',FALSE); 
  print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
  FOR invoices_updt IN inv_hdr (p_invoice_id)
  LOOP
	  ld_terms_date            := NULL;
      ld_goods_received_date   := NULL;
      ld_invoice_received_date := NULL;
	  lc_source                := NULL;
	  lc_attr2                 := NULL;
	  -- To get the terms_date_basis
	  BEGIN 
		lc_terms_date_basis := NULL;
		SELECT terms_date_basis 
		  INTO lc_terms_date_basis
		  FROM ap_supplier_sites_all
		 WHERE vendor_id = p_vendor_id
		   AND vendor_site_id = p_vendor_site_id
		   AND org_id = p_org_id;
	  EXCEPTION
	    WHEN NO_DATA_FOUND
	    THEN
       print_debug_msg ('No data found for the Supplier site match and Terms Data Basis '||SQLERRM,FALSE);
		   lc_terms_date_basis := NULL;
	    WHEN OTHERS
	    THEN
       print_debug_msg ('Unable to get the Supplier site match and Terms Data Basis '||SQLERRM,FALSE);
		   lc_terms_date_basis := NULL;
	  END;
	  -- To derive the Drop ship flag, Authorization status and closed code
	  BEGIN 
		lc_po_type:= NULL;
	    lc_authorization_status := NULL;
	    lc_closed_code := NULL;
		SELECT attribute_category,authorization_status, closed_code,segment1
		  INTO lc_po_type, lc_authorization_status, lc_closed_code,lc_po_number
		  FROM po_headers_all
		 WHERE po_header_id = p_po_header_id;   
	  EXCEPTION
		WHEN NO_DATA_FOUND
	    THEN
			print_debug_msg ('No data found for the Drop ship flag, Authorization status and closed code '||SQLERRM,FALSE);
		    lc_po_type:= NULL;
			lc_authorization_status := NULL;
			lc_closed_code := NULL;
		    lc_po_number := NULL;
		WHEN OTHERS
		THEN
			print_debug_msg ('Unable to get the Drop ship flag, Authorization status and closed code '||SQLERRM,FALSE);
			lc_po_type:= NULL;
			lc_authorization_status := NULL;
			lc_closed_code := NULL;
		    lc_po_number := NULL;
	  END;
	  -- To Intialise the variable to 'Y' if the PO is Dropship
	  IF lc_po_type LIKE 'DropShip%'
	  THEN
		 lc_drop_ship_flag := 'Y';
	  ELSE 
		 lc_drop_ship_flag := 'N';
	  END IF;
	  -- Update the EDI and TDM sources to DROPSHIP source if the PO is Dropship
	  IF lc_drop_ship_flag = 'Y'
	  THEN
	     IF invoices_updt.source = 'US_OD_TDM'
		 THEN
		     lc_source := 'US_OD_DROPSHIP';
			 lc_attr2  := NULL;
		 ELSIF invoices_updt.source = 'US_OD_TRADE_EDI'
		 THEN
		     lc_source := 'US_OD_DROPSHIP';
			 lc_attr2  := 'Y';
		 END IF;
	  END IF;
	  -- To get the 2-Way or 3-Way match
	  BEGIN 
		lc_inspection_req_flag := NULL;
	    lc_receipt_req_flag := NULL;
	    SELECT DISTINCT inspection_required_flag,receipt_required_flag 
		  INTO lc_inspection_req_flag, lc_receipt_req_flag
          FROM po_line_locations_all 
         WHERE po_header_id = p_po_header_id;
	  EXCEPTION
		WHEN NO_DATA_FOUND
	    THEN
			lc_inspection_req_flag := NULL;
			lc_receipt_req_flag := NULL;
		WHEN OTHERS
		THEN
			lc_inspection_req_flag := NULL;
			lc_receipt_req_flag := NULL;
	  END;
	-- To get the 2-Way or 3-Way match
	  IF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'N'
	  THEN
		  lc_match_type := '2-Way';
	  ELSIF lc_inspection_req_flag = 'N' AND lc_receipt_req_flag = 'Y'
	  THEN
		  lc_match_type := '3-Way';
	  END IF;
    -- Invalid PO, Status is CLOSED/ NOT Approved for the Invoice		 
	  IF (lc_closed_code IN ('CLOSED','FINALLY CLOSED') OR lc_authorization_status <> 'APPROVED')
	  THEN
	  XX_INSERT_AP_TR_MATCH_EXCEPNS  (p_invoice_id            => p_invoice_id,
									  p_invoice_num           => p_invoice_num,
									  p_vendor_id             => p_vendor_id ,
									  p_vendor_site_id        => p_vendor_site_id,
									  p_invoice_line_id       => NULL,
									  p_invoice_line_num      => NULL,
									  p_po_num                => lc_po_number,
									  p_po_header_id          => p_po_header_id,
									  p_po_line_id            => NULL,
									  p_po_line_num           => NULL,
									  p_exception_code        => 'E002',
									  p_exception_description => 'Invalid PO, Status is CLOSED/NOT Approved for the Invoice :'|| invoices_updt.invoice_num,
									  p_process_flag          => 'N',
									  p_hold_placed_flag      => NULL
									 );
	  END IF;
      IF lc_match_type  = '2-Way' THEN  -- Modified for Terms Date
	     -- Calling  XX_AP_TR_TERMS_DATE procedure to get the terms_date, goods received date and Invoice received date 
	  XX_AP_TR_TERMS_DATE ( p_invoice_num            =>  p_invoice_num,
	                        p_invoice_id             =>  p_invoice_id,
                            p_sup_site_terms_basis   =>  lc_terms_date_basis,
						    p_match_type             =>  lc_match_type,
						    p_drop_ship_flag         =>  lc_drop_ship_flag,
						    p_po_num                 =>  lc_po_number,
							p_po_header_id           =>  p_po_header_id,
						    p_invoice_date           =>  invoices_updt.invoice_date,
						    p_inv_creation_date      =>  invoices_updt.creation_date,
							p_terms_date             =>  ld_terms_date,
							p_goods_received_date    =>  ld_goods_received_date,
							p_invoice_received_date  =>  ld_invoice_received_date
						  );
    -- If calculated terms_date is different than the existing terms_date from ap_invoices_all	
	  XX_AP_TRADE_MATCH_UTL_PKG.xx_ap_update_due_date(p_invoice_id => invoices_updt.invoice_id, 
	                                                  p_terms_date => ld_terms_date,
													  p_terms_id   => invoices_updt.terms_id); 
	  UPDATE ap_invoices_all
	     SET goods_received_date = NVL(ld_goods_received_date,goods_received_date),
		     invoice_received_date = NVL(ld_invoice_received_date,invoice_received_date),
			 terms_date = NVL(ld_terms_date,terms_date),
			 attribute5 = NVL(attribute5,lc_po_type), -- Added as per version 1.6
			 source  = NVL(lc_source,invoices_updt.source),  -- Added as per version 1.7
			 attribute7 = NVL(lc_source,invoices_updt.source),  -- Added as per version 1.7
			 attribute2	= lc_attr2		  -- Added as per version 1.7
	   WHERE invoice_id = invoices_updt.invoice_id;
     END IF;
	END LOOP; -- inv_hdr loop
    COMMIT;	
EXCEPTION
  WHEN OTHERS 
  THEN
      lc_error_msg := SUBSTR(SQLERRM,1,250);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception ('Updating the Goods Received Date, Invoice received date and Terms Date',
    		        lc_error_loc,
			        lc_error_msg);
      p_retcode := '2';
      p_err_buf := lc_error_msg;
END update_ap_invoices_all;
-- +===============================================================================================+
-- |  Name	      : no_receipt_check                                                               |
-- |  Description : Checks each PO whether the receipt is created or not and applies/removes holds |
-- ================================================================================================|
PROCEDURE no_receipt_check(p_err_buf             OUT  VARCHAR2,
                           p_retcode             OUT  VARCHAR2,
						   p_holds_placed        OUT  NUMBER,
						   p_holds_released      OUT  NUMBER,
						   p_po_header_id        IN   NUMBER,
						   p_creation_date       IN   DATE,
						   p_vendor_id           IN   NUMBER,
						   p_vendor_site_id      IN   NUMBER,
						   p_org_id              IN   NUMBER,
						   p_invoice_id          IN   NUMBER,
						   p_invoice_num         IN   VARCHAR2)
IS
    CURSOR get_inv_line_details(p_invoice_id NUMBER)
    IS
	  SELECT invoice_id,
	         inventory_item_id,
			 po_line_id,
			 po_header_id
        FROM ap_invoice_lines_all
       WHERE invoice_id = p_invoice_id
         AND line_type_lookup_code = 'ITEM'; 
    ln_count                    NUMBER;
    ld_max_receipt_date         DATE;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.NO_RECEIPT_CHECK';  
    lc_hold_type 		        VARCHAR2(70)	:= 'MATCHING RELEASE REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:= 'OD NO Receipt';
    lc_hold_reason 		        VARCHAR2(200)	:= 'No Receipt Exists for the PO';  
	lc_release_lookup_code      VARCHAR2(100)   := 'INVOICE QUICK RELEASED';
    ln_hold_placed_count	    NUMBER;
	ln_hold_released_count	    NUMBER; 
	lc_flag                     VARCHAR2(1);
	ln_calc_rcv_qty             NUMBER;
BEGIN
      ln_hold_placed_count	  := 0;
	  ln_hold_released_count  := 0;
	  lc_flag := 'N';
      print_debug_msg('Begin check for the Receipt Date Exists or not and apply hold if needed',FALSE);   
      print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
      --print_debug_msg('Check if the Receipt Date exists for the PO',FALSE); 
	  FOR cur IN get_inv_line_details(p_invoice_id)
	  LOOP
	      ln_calc_rcv_qty:= get_unbilled_qty(cur.po_header_id,cur.po_line_id,cur.inventory_item_id,cur.invoice_id); 
		  /*
		  IF ln_calc_rcv_qty = 0
		  THEN
		      lc_flag := 'Y';
		  END IF;
		  */
		  IF ln_calc_rcv_qty > 0
		  THEN
		      lc_flag := 'Y';
		  END IF;
	   END LOOP;
      --Check if custom hold exists for this invoice
      --print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num,FALSE); 
	  SELECT COUNT(1) 
	    INTO ln_count
	    FROM ap_holds_all
	   WHERE invoice_id = p_invoice_id
	     AND hold_lookup_code = 'OD NO Receipt'
	     AND release_lookup_code IS NULL;   
     -- IF ln_count = 0 AND lc_flag = 'Y' 
	  IF ln_count = 0 AND lc_flag <> 'Y'
	  THEN	
         BEGIN               
       	   mo_global.set_policy_context ('S',p_org_id);
       	   mo_global.init ('SQLAP');
		   ap_holds_pkg.insert_single_hold
				  (x_invoice_id            => p_invoice_id,
				   x_hold_lookup_code      => lc_hold_lookup_code,
				   x_hold_type             => lc_hold_type,
				   x_hold_reason           => lc_hold_reason,
				   x_held_by               => gn_user_id,  --discuss
				   x_calling_sequence      => NULL);
		   ln_hold_placed_count := ln_hold_placed_count + 1; 
				XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
											  p_invoice_num           => p_invoice_num,
											  p_vendor_id             => p_vendor_id ,
											  p_vendor_site_id        => p_vendor_site_id,
											  p_invoice_line_id       => NULL,
											  p_invoice_line_num      => NULL,
											  p_po_num                => NULL,
											  p_po_header_id          => p_po_header_id,
											  p_po_line_id            => NULL,
											  p_po_line_num           => NULL,
											  p_exception_code        => 'H001',
											  p_exception_description => 'NO Receipt Exists for the Invoice '||p_invoice_num,
											  p_process_flag          => 'N',
											  p_hold_placed_flag      => 'Y'
											 );
         EXCEPTION
          WHEN OTHERS 
		  THEN
              print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num,TRUE); 
				XX_INSERT_AP_TR_MATCH_EXCEPNS(p_invoice_id            => p_invoice_id,
											  p_invoice_num           => p_invoice_num,
											  p_vendor_id             => p_vendor_id ,
											  p_vendor_site_id        => p_vendor_site_id,
											  p_invoice_line_id       => NULL,
											  p_invoice_line_num      => NULL,
											  p_po_num                => NULL,
											  p_po_header_id          => p_po_header_id,
											  p_po_line_id            => NULL,
											  p_po_line_num           => NULL,
											  p_exception_code        => 'H001',
											  p_exception_description => 'NO Receipt Exists for the Invoice '||p_invoice_num,
											  p_process_flag          => 'N',
											  p_hold_placed_flag      => NULL
											 );
			p_retcode := '2';		                
         END;		
      END IF; --ln_count
      -- IF ln_count > 0 AND lc_flag <> 'Y' 
	  IF ln_count > 0 AND lc_flag = 'Y' 
	  THEN 
	    BEGIN
           /*mo_global.set_policy_context ('S',p_org_id);
           mo_global.init ('SQLAP');
		   ap_holds_pkg.release_single_hold
			 (x_invoice_id               => p_invoice_id,
			  x_hold_lookup_code         => lc_hold_lookup_code,
			  x_release_lookup_code      => lc_release_lookup_code,
			  x_held_by                  => gn_user_id,
			  x_calling_sequence         => NULL
			 ); */
		   UPDATE ap_holds_all
		       SET release_lookup_code = 'INVOICE QUICK RELEASED',
		    	   release_reason = 'Holds released in Invoice Holds window',
			       last_update_date = SYSDATE, 
			       last_updated_by = gn_user_id
		     WHERE invoice_id = p_invoice_id
		       AND hold_lookup_code = 'OD NO Receipt'
			   AND release_lookup_code IS NULL;
		   ln_hold_released_count := ln_hold_released_count + 1;
	       UPDATE xx_ap_tr_match_exceptions
		      SET hold_release_flag = 'Y', --discuss new column added
		          created_by = gn_user_id,
		          creation_date = SYSDATE,
		          last_updated_by = gn_user_id,
		          last_update_date = SYSDATE,
		          last_update_login = gn_login_id
	        WHERE invoice_id = p_invoice_id;
  	    EXCEPTION
	    WHEN OTHERS 
		THEN
    	  lc_error_msg := 'ERROR while releasing No Receipt hold on invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
    	  print_debug_msg (lc_error_msg,TRUE);
    	  log_exception ('OD AP Trade Match Prevalidation Program',
    		              lc_error_loc,
			              lc_error_msg
						);
        p_retcode := '2';		 
	    END;
      END IF;
   COMMIT; --discuss commit after each invoice.
   print_debug_msg('Commit Complete',FALSE);
   p_holds_released  := ln_hold_released_count;
   p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
    WHEN OTHERS 
	THEN
      lc_error_msg := 'ERROR processing(no_receipt_check) invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception ('OD AP Trade Match Prevalidation Program',
    	             lc_error_loc,
	  	             lc_error_msg
					);
      p_retcode := '2';			            
END no_receipt_check;
-- +============================================================================================+
-- |  Name	  : miscellaneous_line_check                                                        |
-- |  Description : Checks each miscellaneous line for the respective invoice                   |
-- =============================================================================================|
PROCEDURE miscellaneous_line_check(p_err_buf             OUT  VARCHAR2,
                                   p_retcode             OUT  VARCHAR2,
								   p_holds_placed        OUT  NUMBER,
								   p_po_header_id        IN   NUMBER,
								   p_creation_date       IN   DATE,
								   p_vendor_id           IN   NUMBER,
								   p_vendor_site_id      IN   NUMBER,
								   p_org_id              IN   NUMBER,
								   p_invoice_id          IN   NUMBER,
								   p_invoice_num         IN   VARCHAR2)
IS
    CURSOR get_miscellaneous_line(p_invoice_id  NUMBER) 
    IS
       SELECT COUNT(1) 
         FROM ap_invoice_lines_all aia              		 
        WHERE invoice_id  = p_invoice_id 
          AND line_type_lookup_code = 'MISCELLANEOUS' 
          AND attribute3 = 'Y';
	ln_misc_line_count          NUMBER;
    ln_count                    NUMBER;
    lc_error_msg                VARCHAR2(1000);
    lc_error_loc                VARCHAR2(100) 	:= 'XX_AP_TR_MATCH_PREVAL_PKG.MISCELLANEOUS_LINE_CHECK';    
    lc_hold_type 		        VARCHAR2(70)	:='MATCHING RELEASE REASON';
    lc_hold_lookup_code 	    VARCHAR2(70)	:='OD MISC HOLD';
    lc_hold_reason 		        VARCHAR2(200)	:='Miscellaneous line Hold';  
    lc_release_lookup_code      VARCHAR2(100)   :='INVOICE QUICK RELEASED';
    ln_hold_placed_count	    NUMBER;
    ln_hold_released_count	    NUMBER;    
BEGIN
      ln_hold_placed_count	  := 0;
      ln_hold_released_count  := 0;  
      print_debug_msg('Begin check for the Miscellaneous Line and apply hold if needed',FALSE);   
      print_debug_msg('Processing Invoice '||p_invoice_num,FALSE); 
	  ln_misc_line_count := NULL;   
      OPEN get_miscellaneous_line(p_invoice_id);
      FETCH get_miscellaneous_line INTO ln_misc_line_count;
      CLOSE get_miscellaneous_line;
      --Check if custom hold exists for this invoice
      --print_debug_msg('Check if custom hold exists for invoice_num '||p_invoice_num,FALSE); 
	  SELECT COUNT(1) 
	    INTO ln_count
	    FROM ap_holds_all
	   WHERE invoice_id = p_invoice_id
	     AND hold_lookup_code = 'OD MISC HOLD'
	     AND release_lookup_code IS NULL;   
      IF ln_count = 0
      THEN 
        IF ln_misc_line_count > 0
		THEN	
            BEGIN               
             	mo_global.set_policy_context ('S',p_org_id);
             	mo_global.init ('SQLAP');
		        ap_holds_pkg.insert_single_hold
		      		  (x_invoice_id            => p_invoice_id,
		      		   x_hold_lookup_code      => lc_hold_lookup_code,
		      		   x_hold_type             => lc_hold_type,
		      		   x_hold_reason           => lc_hold_reason,
		      		   x_held_by               => gn_user_id,  --discuss
		      		   x_calling_sequence      => NULL);
		         ln_hold_placed_count := ln_hold_placed_count + 1;  
            EXCEPTION
                WHEN OTHERS 
		        THEN
                   print_debug_msg('ERROR applying hold for invoice_num '||p_invoice_num,TRUE); 
                   p_retcode := '2';		                
               END;		
        END IF; --ln_misc_line_count
        COMMIT; --discuss commit after each invoice.
      END IF; -- ln_count     
   print_debug_msg('Commit Complete',FALSE);
   p_holds_placed    := ln_hold_placed_count; 
EXCEPTION
    WHEN OTHERS 
	THEN
      lc_error_msg := 'ERROR processing(miscellaneous_line_check) invoice_num '||p_invoice_num||SUBSTR(SQLERRM,1,250);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception ('OD AP Trade Match Prevalidation Program',
    	             lc_error_loc,
	  	             lc_error_msg
					);
      p_retcode := '2';			            
END miscellaneous_line_check;
-- +=============================================================================================+
-- |  Name	     : main                                                                          |
-- |  Description: This procedure calls the Price Tolerance, Freight Tolerance and Favorable Cost| 
-- |               variance procedures                                                           |
-- ==============================================================================================|
PROCEDURE main(p_errbuf       OUT  VARCHAR2
              ,p_retcode      OUT  VARCHAR2
			  ,p_source		  IN   VARCHAR2
              ,p_debug        IN   VARCHAR2
			  ,p_invoice_id   IN   NUMBER)
AS
   lc_error_msg                 VARCHAR2(1000) := NULL;
   lc_error_loc                 VARCHAR2(100)  := 'XX_AP_TR_MATCH_PREVAL_PKG.main';
   lc_retcode		            VARCHAR2(3)    := NULL;
   data_exception               EXCEPTION;
   indx                         NUMBER;
   ln_price_tol_holds_placed   	NUMBER;
   ln_price_tol_holds_rel       NUMBER;
   ln_frght_tol_holds_placed   	NUMBER;
   ln_frght_tol_holds_rel       NUMBER;
   ln_fav_cost_var_holds        NUMBER;
   ln_po_no_ref_holds           NUMBER;
   ln_po_no_ref_holds_rel       NUMBER;
   ln_tot_records_processed     NUMBER;
   ln_holds_placed              NUMBER;
   ln_holds_released            NUMBER;
   ln_no_receipt_holds          NUMBER;
   ln_no_receipt_holds_rel      NUMBER;
   ln_lvar_tol_holds_placed     NUMBER;
   lc_match_type				VARCHAR2(10);
   ln_misc_lines_holds          NUMBER;
   CURSOR invoice_cur(p_org_id NUMBER)
   IS
      SELECT a.invoice_id,
             a.invoice_num,
             a.vendor_id,
             a.vendor_site_id,
			 NVL(a.po_header_id,a.quick_po_header_id) po_header_id,
             a.org_id,
             a.creation_date
        FROM ap_invoices_all a
       WHERE a.validation_request_id=-9999999999
	     AND a.source=NVL(p_source,a.source)
		 AND a.org_id+0=p_org_id
		 AND a.invoice_id=NVL(p_invoice_id,a.invoice_id)
		 AND a.quick_po_header_id IS NOT NULL
		 AND a.invoice_type_lookup_code='STANDARD'
		 AND a.invoice_num NOT LIKE '%ODDBUI%'
       UNION
      SELECT a.invoice_id,
             a.invoice_num,
             a.vendor_id,
             a.vendor_site_id,
			 NVL(a.po_header_id,a.quick_po_header_id) po_header_id,
             a.org_id,
             a.creation_date
        FROM ap_invoices_all a
	   WHERE a.creation_date>SYSDATE-7
	     AND a.source=NVL(p_source,a.source)
		 AND a.org_id+0=p_org_id
	     AND a.validation_request_id IS NULL
		 AND a.invoice_num NOT LIKE '%ODDBUI%'
		 AND a.invoice_id=NVL(p_invoice_id,a.invoice_id)
		 AND a.quick_po_header_id IS NOT NULL
         AND a.invoice_type_lookup_code = 'STANDARD'		 
		 AND 'NEVER APPROVED'=AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.invoice_id, 
                                           a.invoice_amount,
                                           a.payment_status_flag,
                                           a.invoice_type_lookup_code
                                          )
	   UNION
      SELECT /*+ LEADING (h) */
			 ai.invoice_id,
             ai.invoice_num, 
             ai.vendor_id,
             ai.vendor_site_id,
             NVL(ai.po_header_id,ai.quick_po_header_id) po_header_id,
             ai.org_id,
             ai.creation_date
       FROM ap_invoices_all ai,
           (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */
			       DISTINCT invoice_id
              FROM ap_holds_all aph
             WHERE aph.creation_date > '01-JAN-11' 
               AND NVL(aph.status_flag,'S')= 'S'
		       AND aph.invoice_id=NVL(p_invoice_id,aph.invoice_id)			   
			   AND aph.release_lookup_code IS NULL
		   )h   
      WHERE ai.invoice_id=h.invoice_id
	    AND ai.source=NVL(p_source,ai.source)
        AND ai.org_id+0=p_org_id		
		AND ai.invoice_id=NVL(p_invoice_id,ai.invoice_id)	
        AND ai.quick_po_header_id IS NOT NULL		
		AND ai.invoice_type_lookup_code='STANDARD'		
		AND ai.invoice_num NOT LIKE '%ODDBUI%'
        AND EXISTS(SELECT 'x'
                     FROM xx_fin_translatedefinition xftd, 
                          xx_fin_translatevalues xftv,
                          ap_supplier_sites_all site
                    WHERE site.vendor_site_id=ai.vendor_site_id
                      AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES' 
                      AND xftd.translate_id     = xftv.translate_id
                      AND xftv.target_value1    = site.attribute8
                      AND xftv.enabled_flag     = 'Y'
                      AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
                  )   		
	    AND EXISTS(SELECT 'x'
					 FROM xx_fin_translatedefinition xftd, 
			              xx_fin_translatevalues xftv 
					WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
					  AND xftd.translate_id	 = xftv.translate_id
					  AND xftv.target_value1    = ai.source
					  AND xftv.enabled_flag     = 'Y'
					  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
				  );	
   TYPE invoice IS TABLE OF invoice_cur%ROWTYPE
   INDEX BY PLS_INTEGER;
   l_invoice_tab 		INVOICE;
   ln_org_id  			NUMBER; 
   ln_cnt               NUMBER;         
BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id; 
	ln_org_id:=FND_PROFILE.VALUE ('ORG_ID');
	ln_tot_records_processed   := 0;
    ln_price_tol_holds_placed  := 0;
    ln_price_tol_holds_rel     := 0;
    ln_frght_tol_holds_placed  := 0;
    ln_frght_tol_holds_rel     := 0;
    ln_fav_cost_var_holds      := 0;   
	ln_po_no_ref_holds         := 0;
	ln_po_no_ref_holds_rel     := 0;
	ln_no_receipt_holds        := 0;
	ln_no_receipt_holds_rel    := 0;
    ln_lvar_tol_holds_placed   := 0;	
    ln_misc_lines_holds        := 0;	
    print_debug_msg('Update invoices in 6 days wait for validation',TRUE); 
	IF p_invoice_id IS NULL THEN
	   IF p_source = 'US_OD_TRADE_EDI'
	   THEN
	      update_invoice_validate_wait(p_source,lc_error_msg);
	   END IF;
	END IF;
	IF lc_error_msg IS NOT NULL 
	THEN
		lc_error_msg := 'Error in call to update_invoice_validate_wait ';
		RAISE data_exception;
	END IF; 
    OPEN invoice_cur(ln_org_id);
    LOOP
      FETCH invoice_cur BULK COLLECT INTO l_invoice_tab LIMIT gn_batch_size;
      EXIT WHEN l_invoice_tab.COUNT = 0;
      FOR indx IN l_invoice_tab.FIRST..l_invoice_tab.LAST 
      LOOP
       BEGIN
	       ln_cnt := 0;
         -- To know whether the Vendor is EXPENSE Vendor or NOT
		  BEGIN
             SELECT COUNT(1)
               INTO ln_cnt
               FROM ap_supplier_sites_all
              WHERE vendor_site_id = 	l_invoice_tab(indx).vendor_site_id
                AND attribute8 LIKE 'EX%';
		  EXCEPTION
		    WHEN OTHERS
		    THEN
		       ln_cnt := 0;
		  END;
          IF ln_cnt > 0
          THEN		
              CONTINUE;
          ELSE			  
              print_debug_msg('Processing Invoice Number: '||l_invoice_tab(indx).invoice_num,TRUE); 	   
		      print_debug_msg('Check for violation of price tolerance and apply hold if needed',TRUE); 
		      ln_holds_placed := 0;
		      ln_holds_released := 0;
		      price_tolerance_check(lc_error_msg,
		                            lc_retcode,
								    ln_holds_placed,
								    ln_holds_released,
								    l_invoice_tab(indx).po_header_id,
								    l_invoice_tab(indx).creation_date,
								    l_invoice_tab(indx).vendor_id,
								    l_invoice_tab(indx).vendor_site_id,
								    l_invoice_tab(indx).org_id,
								    l_invoice_tab(indx).invoice_id,
								    l_invoice_tab(indx).invoice_num);
		      ln_price_tol_holds_placed  := ln_price_tol_holds_placed + ln_holds_placed;
              ln_price_tol_holds_rel     := ln_price_tol_holds_rel + ln_holds_released;
		      IF lc_retcode = '2' THEN --One of the invoice line(s) has errors.
			     p_retcode := '1';
		      END IF;
		      print_debug_msg('Check for violation of freight tolerance and apply hold if needed',TRUE); 
		      ln_holds_placed := 0;
		      ln_holds_released := 0;
		      freight_tolerance_check(  lc_error_msg,
									    lc_retcode,
									    ln_holds_placed,
								        ln_holds_released,
									    l_invoice_tab(indx).po_header_id,
									    l_invoice_tab(indx).creation_date,
									    l_invoice_tab(indx).vendor_id,
									    l_invoice_tab(indx).vendor_site_id,
									    l_invoice_tab(indx).org_id,
									    l_invoice_tab(indx).invoice_id,
									    l_invoice_tab(indx).invoice_num);
			  ln_frght_tol_holds_placed  := ln_frght_tol_holds_placed + ln_holds_placed;
              ln_frght_tol_holds_rel     := ln_frght_tol_holds_rel + ln_holds_released;
		      IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
			     p_retcode := '1';
		      END IF;  
		      print_debug_msg('Check for favorable cost variance',TRUE); 
		      ln_holds_placed := 0;
		      favorable_cost_variance(lc_error_msg,
								      lc_retcode,
								      ln_holds_placed,
								      l_invoice_tab(indx).po_header_id,
								      l_invoice_tab(indx).creation_date,
								      l_invoice_tab(indx).vendor_id,
								      l_invoice_tab(indx).vendor_site_id,
								      l_invoice_tab(indx).org_id,
								      l_invoice_tab(indx).invoice_id,
								      l_invoice_tab(indx).invoice_num);
			  ln_fav_cost_var_holds := ln_fav_cost_var_holds + ln_holds_placed;
		      IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
			     p_retcode := '1';
		      END IF;
		      print_debug_msg('Check for Miscellaneous line check',TRUE); 
		      ln_holds_placed := 0;
		      miscellaneous_line_check(lc_error_msg,
								       lc_retcode,
								       ln_holds_placed,
								       l_invoice_tab(indx).po_header_id,
								       l_invoice_tab(indx).creation_date,
								       l_invoice_tab(indx).vendor_id,
								       l_invoice_tab(indx).vendor_site_id,
								       l_invoice_tab(indx).org_id,
								       l_invoice_tab(indx).invoice_id,
								       l_invoice_tab(indx).invoice_num);
		      ln_misc_lines_holds := ln_misc_lines_holds + ln_holds_placed;
		      IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
			     p_retcode := '1';
		      END IF;
		      print_debug_msg('Updating the Goods Received Date and Invoice Received Date',TRUE);
		      update_ap_invoices_all(lc_error_msg,
								     lc_retcode,
								     l_invoice_tab(indx).po_header_id,
								     l_invoice_tab(indx).creation_date,
								     l_invoice_tab(indx).vendor_id,
								     l_invoice_tab(indx).vendor_site_id,
								     l_invoice_tab(indx).org_id,
								     l_invoice_tab(indx).invoice_id,
								     l_invoice_tab(indx).invoice_num);
		      IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
			     p_retcode := '1';
		      END IF;
		      lc_match_type:=NULL;
		      lc_match_type:=get_match_type(l_invoice_tab(indx).po_header_id);
		      IF lc_match_type='3-Way' THEN
		         print_debug_msg('Check for No Receipt',TRUE); 
		         ln_holds_placed := 0;
		         ln_holds_released := 0;
		         no_receipt_check(lc_error_msg,
					              lc_retcode,
					              ln_holds_placed,
					              ln_holds_released,
					              l_invoice_tab(indx).po_header_id,
					              l_invoice_tab(indx).creation_date,
					              l_invoice_tab(indx).vendor_id,
					              l_invoice_tab(indx).vendor_site_id,
					              l_invoice_tab(indx).org_id,
					              l_invoice_tab(indx).invoice_id,
					              l_invoice_tab(indx).invoice_num);
			     ln_no_receipt_holds         := ln_no_receipt_holds + ln_holds_placed;
			     ln_no_receipt_holds_rel     := ln_no_receipt_holds_rel + ln_holds_released;
		         IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
			        p_retcode := '1';
		         END IF;
 		      END IF;
		      print_debug_msg('Check for violation of OD Line Variance and apply hold if needed',TRUE); 
		      ln_holds_placed := 0;
		      od_line_variance_check(lc_error_msg,
		                             lc_retcode,
							 	     ln_holds_placed,
								     l_invoice_tab(indx).po_header_id,
								     l_invoice_tab(indx).vendor_id,
								     l_invoice_tab(indx).vendor_site_id,
								     l_invoice_tab(indx).org_id,
								     l_invoice_tab(indx).invoice_id,
								     l_invoice_tab(indx).invoice_num);
		      ln_lvar_tol_holds_placed  := ln_lvar_tol_holds_placed + ln_holds_placed;
		      IF lc_retcode = '2' THEN --One of the invoice line(s) has errors.
			     p_retcode := '1';
		      END IF;
		  END IF; -- ln_cnt > 0
       EXCEPTION
            WHEN OTHERS 
			THEN
              ROLLBACK;
   	          lc_error_msg := SUBSTR(SQLERRM,1,250);
              print_debug_msg ('ERROR processing(pre-validation scripts) invoice_num- '||l_invoice_tab(indx).invoice_num||'-'||lc_error_msg,TRUE);
	          log_exception ('OD AP Trade Match Prevalidation Program',
			                 lc_error_loc,
			                 lc_error_msg);
	          p_retcode := '2';				   
       END;
	   ln_tot_records_processed := ln_tot_records_processed + 1;
      END LOOP; --l_invoice_tab
    END LOOP; --invoice_cur
    CLOSE invoice_cur;  
   print_out_msg('Price Tolerance Check Stats');
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_price_tol_holds_placed)||' holds placed');
   print_out_msg(TO_CHAR(ln_price_tol_holds_rel)||' holds released');
   print_out_msg('   ');
   print_out_msg('Freight Tolerance Check Stats');
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_frght_tol_holds_placed)||' holds placed');
   print_out_msg(TO_CHAR(ln_frght_tol_holds_rel)||' holds released');
   print_out_msg('   ');
   print_out_msg('Favorable Cost Variance Hold Check Stats'); 
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_fav_cost_var_holds)||' holds placed');	
   print_out_msg('   ');   
   print_out_msg('No Receipt Check Stats'); 
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_no_receipt_holds)||' holds placed');
   print_out_msg(TO_CHAR(ln_no_receipt_holds_rel)||' holds released');
   print_out_msg('   ');
   print_out_msg('OD Line Variance Check Stats');
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_lvar_tol_holds_placed)||' holds placed');
   print_out_msg('   ');
   print_out_msg('Miscellaneous lines Holds');
   print_out_msg('-------------------------------');
   print_out_msg(TO_CHAR(ln_tot_records_processed)||' records processed');
   print_out_msg(TO_CHAR(ln_misc_lines_holds)||' holds placed');
EXCEPTION
WHEN OTHERS 
THEN
   lc_error_msg := lc_error_msg ||'-'|| SUBSTR(SQLERRM,1,250);
   print_debug_msg ('ERROR AP Trade Match - '||lc_error_msg,TRUE);
   log_exception ('OD AP Trade Match Prevalidation Program',
                   lc_error_loc,
		   lc_error_msg);
   p_retcode := 2;
END main;
END XX_AP_TR_MATCH_PREVAL_PKG;
/