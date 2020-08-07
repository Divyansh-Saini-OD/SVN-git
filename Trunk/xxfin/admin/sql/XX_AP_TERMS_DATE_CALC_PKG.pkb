CREATE OR REPLACE PACKAGE BODY XX_AP_TERMS_DATE_CALC_PKG
AS
-- +============================================================================================+
-- |                         Office Depot - Project Simplify                                    |
-- +============================================================================================+
-- |  Name	     :  XX_AP_TERMS_DATE_CALC_PKG                                                   |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:  Custom prevalidation program						                        |
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01/16/2018   Naveen Patha    Initial version                                   |
-- | 1.1         01/18/2018   Naveen Patha    Added Purge                                       |
-- | 1.2         02/01/2018   Naveen Patha    Added org_id parameter                            |
-- | 1.3         02/14/2018   Havish Kasina   Commented the RAISE data_exception block          |
-- | 1.4         02/14/2018   Paddy Sanjeevi  Added exists for rcv_shipment_lines               |
-- | 1.5         04/11/2018   Havish Kasina   Added the code to check whether the vendor is     |
-- |                                          Expense Vendor or Not                             |
-- | 1.6         04/16/2018   Havish Kasina   Added new function get_terms_id to get the terms  |
-- |                                          id from the ap invoices table                     |
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

FUNCTION get_terms_id(p_invoice_id NUMBER)
RETURN NUMBER IS
ln_terms_id NUMBER := NULL;
BEGIN
    SELECT terms_id
	  INTO ln_terms_id
	  FROM ap_invoices_all
	 WHERE invoice_id = p_invoice_id;
RETURN ln_terms_id;
EXCEPTION
WHEN OTHERS 
THEN 
  RETURN NULL;
END;

FUNCTION get_invoice_status(p_creation_date IN DATE,p_invoice_id IN NUMBER) 
RETURN VARCHAR2 IS

CURSOR c1(p_invoice_id NUMBER)
IS
SELECT invoice_amount
       ,payment_status_flag
	   ,invoice_type_lookup_code,
	   validation_request_id
  FROM ap_invoices_all
 WHERE invoice_id=p_invoice_id;

v_status VARCHAR2(100);
BEGIN
     FOR cur1 IN C1(p_invoice_id) LOOP
	     IF (cur1.validation_request_id=-9999999999 OR TRUNC(p_creation_date)=TRUNC(SYSDATE)) THEN
	         v_status := 'NEVER APPROVED';
	     ELSE
	         v_status :=ap_invoices_pkg.get_approval_status(p_invoice_id,
                                                   cur1.invoice_amount,
                                                   cur1.payment_status_flag,
                                                   cur1.invoice_type_lookup_code
                                                  );
	     END IF;
	END LOOP;
	RETURN v_status;
END get_invoice_status;
	    
-- +============================================================================================+
 -- |  Name	  : update_ap_invoices                                                         		 |
 -- |  Description: This procedure updates the Terms Date from AP Invoices Table with latest     |
 -- |               received Date                                                                |
 -- =============================================================================================|
PROCEDURE update_ap_invoices(p_errbuf       OUT  VARCHAR2
                            ,p_retcode      OUT  VARCHAR2
							,p_batch_id     IN   NUMBER)
 IS
	CURSOR c_get_details(p_org_id NUMBER)
	IS 
		SELECT  /*+ LEADING(stg) */
              pha.po_header_id 
             , pha.segment1 po_number
             , pla.po_line_id    
             , pla.unit_price po_unit_price
             , pla.line_num
             , aila.quantity_invoiced
             , aila.unit_price invoice_unit_price
             , aila.line_number as inv_line_num
             , aila.invoice_id
             , assa.terms_date_basis
             , stg.inv_status stg_inv_status
             , stg.invoice_id stg_invoice_id
             , get_invoice_status(aila.creation_date,aila.invoice_id) invoice_status
			 , sysdate invoice_date
			 , sysdate creation_date
          FROM ap_supplier_sites_all assa
              ,ap_invoice_lines_all aila               
              ,po_headers_all pha
              ,po_lines_all pla
              ,xx_ap_preval_invoices_stg stg              
         WHERE stg.batch_id=p_batch_id
           AND aila.creation_date > '31-OCT-17'
		   AND aila.org_id+0=p_org_id
           AND pla.po_line_id = stg.po_line_id 
           AND pha.po_header_id = pla.po_header_id            
           AND aila.po_line_id = pla.po_line_id
           AND aila.po_header_id = pla.po_header_id           
           AND aila.line_type_lookup_code = 'ITEM'    
           AND assa.vendor_site_id = pha.vendor_site_id           
           ORDER BY pla.po_line_id, 
                    aila.invoice_id, 
                    aila.line_number;


	CURSOR c_po_recpt_det(c_po_line_id NUMBER) 
	IS	
        SELECT rsl.po_line_id
		      ,rsh.shipment_header_id
		      ,rsh.receipt_num
		      ,rsl.shipment_line_id
		      ,rsl.quantity_received
		      ,rsl.quantity_received as unmatch_qty_rcv
              ,TO_DATE(rsh.attribute1,'MM/DD/YY') transaction_date
	      FROM rcv_shipment_lines rsl
	          ,rcv_shipment_headers rsh
	     WHERE 1 = 1
		   AND rsl.po_line_id = c_po_line_id
           AND rsl.shipment_header_id = rsh.shipment_header_id  
         ORDER BY rsh.shipment_header_id, 
				  rsl.shipment_line_id asc;
				  
		CURSOR inv_details(p_invoice_id NUMBER) IS
		SELECT invoice_date,
		       creation_date
		  FROM ap_invoices_all
		 WHERE invoice_id=p_invoice_id;
	
	-- Above if same transaction_date then secondary order by shipment_line_id

    TYPE l_po_inv_list_tab IS TABLE OF c_get_details%ROWTYPE INDEX BY PLS_INTEGER; 
	l_po_inv_list   	l_po_inv_list_tab;
	
	TYPE r_latest_rcvd_date 
    IS
      RECORD ( latest_rcvd_date          DATE,
               invoice_id                NUMBER,
			   invoice_date              DATE,
			   terms_date_basis          VARCHAR2(100),
			   inv_creation_date         DATE);
               
    TYPE t_latest_rcvd_date
    IS
      TABLE OF r_latest_rcvd_date INDEX BY PLS_INTEGER;
	  
	l_latest_rcvd_date  t_latest_rcvd_date;
	
	TYPE l_po_line_rcpt_list_tab IS TABLE OF c_po_recpt_det%ROWTYPE INDEX BY PLS_INTEGER; 
	l_po_rcpt_list   l_po_line_rcpt_list_tab;		
 
	l_prev_po_line_id	   NUMBER;
	l_unmatch_inv_qty	   NUMBER;
	l_orig_quant           NUMBER := 0;
	l_new_quant            NUMBER := 0;
	ln_rec_cnt             NUMBER := 0;                           
	ln_err_count           NUMBER := 0;
	ln_error_idx           NUMBER := 0;
	lc_error_msg           VARCHAR2(4000);
	ln_temp			       NUMBER := 0;
	data_exception         EXCEPTION;
	l_prev_inv_line_no	   NUMBER;
	l_prev_inv_no		   VARCHAR2(50);	
	l_is_last_line_of_po   VARCHAR2(1);
	ln_po_inv_cnt          NUMBER;
	ln_cur_rcpt_cnt        NUMBER;
	n                      NUMBER;
	ln_org_id  			   NUMBER;	
	ln_terms_id            NUMBER;
 BEGIN
    --gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id; 
	ln_org_id:=FND_PROFILE.VALUE ('ORG_ID');
	fnd_file.put_line(fnd_file.log,'Batch ID :'||p_batch_id);
	print_debug_msg('Begin - update_ap_invoices', TRUE);
			
	OPEN c_get_details(ln_org_id);
	FETCH c_get_details BULK COLLECT INTO l_po_inv_list;
	BEGIN
	
		ln_po_inv_cnt := l_po_inv_list.count;
		print_debug_msg('Number of records to process is '||ln_po_inv_cnt, TRUE);
					
		FOR i in 1..ln_po_inv_cnt
		LOOP		
			BEGIN											
				-- If different Invoice for the same PO (Cursor is - order by po, invoice and Multiple invoices exist for one PO).
				-- So, if the same Invoice then we should use the same Receipt data so that we can use the updated "unmatch_qty_rcv" 
				-- value, by the previous invoice, to skip those already matched invoices.

				FOR cur1 IN inv_details(l_po_inv_list(i).invoice_id) LOOP
                    l_po_inv_list(i).invoice_date := cur1.invoice_date;
					l_po_inv_list(i).creation_date := cur1.creation_date;
				END LOOP;
 				
				IF l_prev_po_line_id = l_po_inv_list(i).po_line_id 
                THEN 
					-- Use the old Rcpt List so that we can match unMatchedRcptQuant					
					IF ((l_prev_inv_no <> l_po_inv_list(i).invoice_id)
					   OR (l_prev_inv_line_no <> l_po_inv_list(i).inv_line_num)) 
					THEN	
						l_prev_inv_no      := l_po_inv_list(i).invoice_id;
						l_prev_inv_line_no := l_po_inv_list(i).inv_line_num;
						l_unmatch_inv_qty  := l_po_inv_list(i).quantity_invoiced;						
					END IF;				
												
				ELSE
					-- If new po Line,
					l_prev_po_line_id    := l_po_inv_list(i).po_line_id;
					l_prev_inv_no        := l_po_inv_list(i).invoice_id;					
					l_prev_inv_line_no   := l_po_inv_list(i).inv_line_num;
					l_unmatch_inv_qty    := l_po_inv_list(i).quantity_invoiced;
															
					OPEN c_po_recpt_det(l_po_inv_list(i).po_line_id);
					FETCH c_po_recpt_det BULK COLLECT INTO l_po_rcpt_list;
					CLOSE c_po_recpt_det;
				END IF;
				ln_cur_rcpt_cnt := l_po_rcpt_list.COUNT;
				
				IF ln_cur_rcpt_cnt <= 0 
				THEN
					lc_error_msg := 'update_ap_invoices() - No Receipts exist or already matched for po_line_id '||l_po_inv_list(i).po_line_id;
					RAISE data_exception;
				END IF;
				
				FOR r in 1..ln_cur_rcpt_cnt
				LOOP
					BEGIN
						-- This receipt is matched already, so skip this receipt.		
						IF l_po_rcpt_list(r).unmatch_qty_rcv <= 0 
						THEN
							CONTINUE; 
						END IF;
				
						-- if the receipts apply then unmatch_qty_rcvv become zero
						IF l_unmatch_inv_qty <=0
						THEN
							EXIT;   -- Exit from this Receipt Loop
						END IF;	
						
						-- l_orig_quant := l_po_rcpt_list(r).quantity_received;
						
						IF l_po_rcpt_list(r).unmatch_qty_rcv <= l_unmatch_inv_qty 
						THEN
							l_new_quant  := l_po_rcpt_list(r).unmatch_qty_rcv;
							l_unmatch_inv_qty := l_unmatch_inv_qty - l_new_quant;							
							l_po_rcpt_list(r).unmatch_qty_rcv := 0;
							
						ELSE
							l_new_quant  := l_unmatch_inv_qty;
							l_unmatch_inv_qty := 0;
							l_po_rcpt_list(r).unmatch_qty_rcv := l_po_rcpt_list(r).unmatch_qty_rcv - l_new_quant;
						END IF; 	
						
						IF l_po_inv_list(i).invoice_status <> 'APPROVED'
						THEN
						    l_latest_rcvd_date(l_po_inv_list(i).invoice_id).invoice_id := l_po_inv_list(i).invoice_id;
							l_latest_rcvd_date(l_po_inv_list(i).invoice_id).invoice_date := l_po_inv_list(i).invoice_date;
							l_latest_rcvd_date(l_po_inv_list(i).invoice_id).terms_date_basis := l_po_inv_list(i).terms_date_basis;
							l_latest_rcvd_date(l_po_inv_list(i).invoice_id).inv_creation_date := l_po_inv_list(i).creation_date;
                            							
                            IF l_latest_rcvd_date(l_po_inv_list(i).invoice_id).latest_rcvd_date IS NULL
                            THEN	
                                l_latest_rcvd_date(l_po_inv_list(i).invoice_id).latest_rcvd_date := l_po_rcpt_list(r).transaction_date;
							
                            ELSE
                                IF l_latest_rcvd_date(l_po_inv_list(i).invoice_id).latest_rcvd_date < l_po_rcpt_list(r).transaction_date	
                                THEN
							        l_latest_rcvd_date(l_po_inv_list(i).invoice_id).latest_rcvd_date := l_po_rcpt_list(r).transaction_date;
							    END IF;
						    END IF;
							
						END IF;
					    						
					EXCEPTION
					WHEN OTHERS 
					THEN
						lc_error_msg := 'update_ap_invoices() - Error when matching with receipt for po line:'||l_po_inv_list(i).po_line_id||' with invoice quantity as '||l_po_inv_list(i).quantity_invoiced||' and receipt quantity as '||l_po_rcpt_list(r).quantity_received||' with error as: '||substr(SQLERRM,1,500);
						-- raise data_exception;
					END;
					
				END LOOP; -- End of PO Receipt List Loop
										
			EXCEPTION
				WHEN data_exception 
				THEN
					print_debug_msg ('ERROR - '||lc_error_msg, TRUE);
				WHEN OTHERS
				THEN
					print_debug_msg('update_ap_invoices() - Error when doing matching for PO lineId '||l_po_inv_list(i).po_line_id||' is '||substr(SQLERRM,1,500),TRUE);
					lc_error_msg  := 'update_ap_invoices() - Exception when doing matching as '||substr(SQLERRM,1,500);
					-- RAISE data_exception;	
			END;			
		
		END LOOP;  -- End of PO Invoice List Loop
	
	EXCEPTION
		WHEN data_exception
		THEN
			-- RAISE data_exception;
			print_debug_msg ('ERROR - '||lc_error_msg, TRUE);
		WHEN OTHERS
		THEN
			print_debug_msg('update_ap_invoices() - Error when doing matching - '||substr(SQLERRM,1,500),TRUE);
			lc_error_msg  := 'update_ap_invoices() - Exception when doing matching as '||substr(SQLERRM,1,500);
			-- RAISE data_exception;	
	END;
	
	CLOSE c_get_details;
	ln_rec_cnt := l_latest_rcvd_date.count;
	print_debug_msg('Number of invoices to be updated :'||ln_rec_cnt,TRUE);
	print_out_msg(TO_CHAR(ln_rec_cnt)||' records updated');
			
	BEGIN			
		n := l_latest_rcvd_date.FIRST;
		WHILE n IS NOT NULL
		LOOP	
            ln_terms_id := NULL;	    
			-- To get the Terms ID 
			ln_terms_id := get_terms_id(p_invoice_id => l_latest_rcvd_date(n).invoice_id);
			  
		    IF l_latest_rcvd_date(n).terms_date_basis = 'Goods Received'
			THEN
		     UPDATE ap_invoices_all
			    SET terms_date = l_latest_rcvd_date(n).latest_rcvd_date
				   ,goods_received_date = l_latest_rcvd_date(n).latest_rcvd_date
		           ,invoice_received_date = l_latest_rcvd_date(n).inv_creation_date
				   ,last_updated_by = gn_user_id
			       ,last_update_date = sysdate
			       ,last_update_login = gn_login_id
			  WHERE invoice_id = l_latest_rcvd_date(n).invoice_id;
			  
			  -- If calculated terms_date is different than the existing terms_date from ap_invoices_all	
	          XX_AP_TRADE_MATCH_UTL_PKG.xx_ap_update_due_date(p_invoice_id => l_latest_rcvd_date(n).invoice_id, 
	                                                          p_terms_date => l_latest_rcvd_date(n).latest_rcvd_date,
													          p_terms_id   => ln_terms_id); 
			
			ELSIF l_latest_rcvd_date(n).terms_date_basis = 'Invoice'
			THEN
			   UPDATE ap_invoices_all
			    SET terms_date = l_latest_rcvd_date(n).invoice_date
				   ,goods_received_date = l_latest_rcvd_date(n).latest_rcvd_date
		           ,invoice_received_date = l_latest_rcvd_date(n).inv_creation_date
				   ,last_updated_by = gn_user_id
			       ,last_update_date = sysdate
			       ,last_update_login = gn_login_id
			  WHERE invoice_id = l_latest_rcvd_date(n).invoice_id;
			  
			  -- If calculated terms_date is different than the existing terms_date from ap_invoices_all	
	          XX_AP_TRADE_MATCH_UTL_PKG.xx_ap_update_due_date(p_invoice_id => l_latest_rcvd_date(n).invoice_id, 
	                                                          p_terms_date => l_latest_rcvd_date(n).invoice_date,
													          p_terms_id   => ln_terms_id); 
			  
			END IF;
						
			 n := l_latest_rcvd_date.NEXT(n);
		END LOOP;
		    
	EXCEPTION
		WHEN OTHERS 
		THEN
		   print_debug_msg('update_ap_invoices() - Bulk Exception raised',TRUE);
		   ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		   FOR i IN 1..ln_err_count
		   LOOP
			  ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			  lc_error_msg := SUBSTR('Bulk Exception - Failed to Update value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);  
			  print_debug_msg('Invoice_id=['||to_char(l_latest_rcvd_date(ln_error_idx).invoice_id)||'], Error msg=['||lc_error_msg||']',TRUE);
		   END LOOP; -- bulk_err_loop FOR Update
			
			ROLLBACK;			
			lc_error_msg  := 'update_ap_invoices() - Bulk Exception raised while inserting. Pls. check the debug log.';
			raise data_exception;
	END;
	
	COMMIT;
	print_debug_msg('End - update_ap_invoices', TRUE);
	
	EXCEPTION
	WHEN data_exception
	THEN
		print_debug_msg ('ERROR update_ap_invoices - '||lc_error_msg, TRUE);	
	WHEN OTHERS
	THEN
		lc_error_msg := 'update_ap_invoices() - '||substr(sqlerrm,1,250);
		print_debug_msg ('ERROR update_ap_invoices - '||lc_error_msg, TRUE);
 END  update_ap_invoices;
 PROCEDURE terms_date_main(p_errbuf       OUT  VARCHAR2
                         ,p_retcode      OUT  VARCHAR2
						 ,p_threads	  IN   NUMBER)
IS

CURSOR C1(p_org_id NUMBER) IS
SELECT /*+ leading(ai) */
       distinct pll.po_header_id,
       pll.po_line_id	   
  FROM po_line_locations_all pll,
       ap_invoices_all ai
WHERE 1=1
   AND ai.invoice_type_lookup_code = 'STANDARD'
   AND ai.invoice_num NOT LIKE '%ODDBUIA%'
   AND ai.org_id+0=p_org_id
   AND ai.cancelled_date IS NULL
   AND ai.validation_request_id=-9999999999
   AND pll.po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)
   AND pll.receipt_required_flag = 'Y'
   AND (pll.inspection_required_flag = 'N' OR pll.inspection_required_flag IS NULL)
   AND EXISTS (SELECT 'x'
				 FROM rcv_shipment_lines
				WHERE po_line_id=pll.po_line_id
              )
UNION
SELECT /*+ LEADING (nai) */
       distinct pll.po_header_id,
       pll.po_line_id               
 FROM  po_line_locations_all pll,
      ( SELECT ai.invoice_id,
           NVL(ai.po_header_id,ai.quick_po_header_id) po_header_id
          FROM ap_invoices_all ai
         WHERE ai.creation_date>SYSDATE-7
           AND ai.invoice_type_lookup_code = 'STANDARD'
           AND ai.invoice_num NOT LIKE '%ODDBUIA%'
		   AND ai.org_id+0=p_org_id
           AND ai.cancelled_date IS NULL
           AND ai.validation_request_id IS NULL                                                               
           AND 'NEVER APPROVED'=AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          )
          AND EXISTS(SELECT 'x'
                     FROM xx_fin_translatedefinition xftd, 
                          xx_fin_translatevalues xftv,
                          ap_supplier_sites_all site
                    WHERE site.vendor_site_id=ai.vendor_site_id
                      AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES' 
                      AND xftd.translate_id     = xftv.translate_id
                      AND xftv.target_value1    = site.attribute8||''
                      AND xftv.enabled_flag     = 'Y'
                      AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
                  )           
          AND EXISTS(SELECT 'x'
                     FROM xx_fin_translatedefinition xftd, 
                          xx_fin_translatevalues xftv 
                    WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
                      AND xftd.translate_id     = xftv.translate_id
                      AND xftv.target_value1    = ai.source
                      AND xftv.enabled_flag     = 'Y'
                      AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
                  )                                          
      ) nai
WHERE 1=1
  AND pll.po_header_id=nai.po_header_id
  AND pll.receipt_required_flag = 'Y'
  AND (pll.inspection_required_flag = 'N' OR pll.inspection_required_flag IS NULL)					  
  AND EXISTS (SELECT 'x'
  			    FROM rcv_shipment_lines
			   WHERE po_line_id=pll.po_line_id
              )
UNION
SELECT /*+ LEADING(h) */
       distinct pll.po_header_id,
       pll.po_line_id	   
  FROM po_line_locations_all pll,
       ap_invoices_all ai,
	   (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */
			       DISTINCT invoice_id
              FROM ap_holds_all aph
             WHERE aph.creation_date > '01-JAN-11' 
               AND NVL(aph.status_flag,'S')= 'S'			   
			   AND aph.release_lookup_code IS NULL
		   )h 
WHERE 1=1
   AND ai.invoice_type_lookup_code = 'STANDARD'
   AND ai.invoice_num NOT LIKE '%ODDBUIA%'
   AND ai.org_id+0=p_org_id
   AND ai.cancelled_date IS NULL
   AND ai.validation_request_id IS NULL
   AND ai.creation_date > '31-OCT-17'
   AND ai.invoice_id=h.invoice_id                                                                  
   AND pll.po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)
   AND pll.receipt_required_flag = 'Y'
   AND (pll.inspection_required_flag = 'N' OR pll.inspection_required_flag IS NULL)
   AND EXISTS (SELECT 'x'
				 FROM rcv_shipment_lines
				WHERE po_line_id=pll.po_line_id
              )
   AND EXISTS(SELECT 'x'
                     FROM xx_fin_translatedefinition xftd, 
                          xx_fin_translatevalues xftv,
                          ap_supplier_sites_all site
                    WHERE site.vendor_site_id=ai.vendor_site_id
                      AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES' 
                      AND xftd.translate_id     = xftv.translate_id
                      AND xftv.target_value1    = site.attribute8||''
                      AND xftv.enabled_flag     = 'Y'
                      AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
                  )   		
   AND EXISTS(SELECT 'x'
					 FROM xx_fin_translatedefinition xftd, 
			              xx_fin_translatevalues xftv 
					WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
					  AND xftd.translate_id	 = xftv.translate_id
					  AND xftv.target_value1    = ai.source
					  AND xftv.enabled_flag     = 'Y'
					  AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
				  );
CURSOR C4 IS
SELECT DISTINCT po_header_id
  FROM xx_ap_preval_invoices_stg;	
  
CURSOR c_delete 
IS
SELECT rowid drowid
  FROM xx_ap_preval_invoices_stg;	  
  
l_tot_count     	NUMBER;
l_batch_size    	NUMBER;
l_batch_id      	NUMBER;
l_current_count 	NUMBER;
l_request_id    	NUMBER;		
ln_req_count  	    NUMBER:=0;
ln_sleep		    NUMBER:=60;
ln_run_count        NUMBER;							  
i                   NUMBER:=0;
ln_org_id           NUMBER;
ln_cnt              NUMBER;
BEGIN
    ln_org_id:=FND_PROFILE.VALUE('ORG_ID');
    FOR cur1 IN C1(ln_org_id) 
	LOOP
	    i:=i+1;
		ln_cnt := 0;
		BEGIN
		    SELECT COUNT(1)
		      INTO ln_cnt
		      FROM ap_supplier_sites_all b,
		           po_headers_all a
		     WHERE a.po_header_id = cur1.po_header_id
		       AND b.vendor_site_id = a.vendor_site_id
		       AND b.attribute8 LIKE 'EX%';
		EXCEPTION
		  WHEN OTHERS
		  THEN
		      ln_cnt := 0;
		END;
		   
		IF ln_cnt > 0
		THEN
		    CONTINUE;
		ELSE
	        BEGIN
		      INSERT 
		        INTO xx_ap_preval_invoices_stg 
		                (po_header_id,
		    			 po_line_id
		    			 )
		      VALUES
		    	        (cur1.po_header_id,
		    			 cur1.po_line_id
		    			 );
		    EXCEPTION
		        WHEN others THEN
		    	  NULL;
		    END;
		END IF; -- ln_cnt > 0
		IF i>10000 THEN 
		   COMMIT;
		   i:=0;
		END IF;
	END LOOP;
	COMMIT;
	print_debug_msg ('Inserted in xx_ap_preval_invoices_stg ',TRUE);
	
	SELECT COUNT( 1) 
	  INTO l_tot_count
	  FROM xx_ap_preval_invoices_stg;
	print_debug_msg (' Total distinct po_header_id count:'||to_char(l_tot_count),TRUE);
	l_batch_size := ROUND((l_tot_count/p_threads),0);
	l_batch_id   :=1;
	l_current_count :=1;
	
	FOR cur4 IN C4 LOOP
	  UPDATE xx_ap_preval_invoices_stg
		 SET batch_id=l_batch_id
	   WHERE po_header_id=cur4.po_header_id;
	   
	  l_current_count :=l_current_count+SQL%ROWCOUNT;
      IF l_current_count >= l_batch_size THEN
	     COMMIT;
		 l_batch_id:=l_batch_id+1;
		 l_current_count:=0;
      END IF;
	END LOOP;
	COMMIT;
	print_debug_msg (' Batch_id updated '||l_batch_id,TRUE);
	
	FOR i IN 1..p_threads LOOP
	  l_request_id  :=fnd_request.submit_request('XXFIN',
												 'XXAPTRDC',
												 'OD: AP Trade Terms Date Calculation Child',
												 NULL,
												 FALSE,
												 TO_CHAR(i)                                             
                                                );
	
      IF l_request_id>0 THEN
         COMMIT;
         print_debug_msg ('Request id : ' ||TO_CHAR(l_request_id),TRUE);
      END IF;
    END LOOP;
    
    LOOP
      SELECT COUNT(1)
        INTO ln_run_count
        FROM fnd_concurrent_requests
       WHERE concurrent_program_id IN (SELECT concurrent_program_id
										 FROM fnd_concurrent_programs
										WHERE concurrent_program_name='XXAPTRDC'
									      AND application_id=20043
					                      AND enabled_flag='Y')
         AND program_application_id=20043
         AND phase_code IN ('P','R');
	   
  	  IF ln_run_count<>0 THEN
	     DBMS_LOCK.SLEEP(ln_sleep);
	  ELSE
	    EXIT;
	  END IF;
    END LOOP;
	i:=0;
    FOR cur IN c_delete LOOP
   	  DELETE 
	    FROM xx_ap_preval_invoices_stg
	   WHERE rowid=cur.drowid;
	  i:=i+1;
	  IF i>=10000 THEN
	     COMMIT;
	  END IF;
	END LOOP;
	COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    p_errbuf  := 'Unexpected error in Mater Program - '||SQLERRM;
    p_retcode := 2;
END terms_date_main;
END XX_AP_TERMS_DATE_CALC_PKG;
/
SHOW ERRORS;