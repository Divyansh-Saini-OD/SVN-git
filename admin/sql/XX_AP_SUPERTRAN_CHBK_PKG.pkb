CREATE OR REPLACE PACKAGE BODY XX_AP_SUPERTRAN_CHBK_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_SUPERTRAN_CHBK_PKG                                                        |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         09/02/2017   Paddy Sanjeevi   Initial version                                  |
-- | 1.1         09/23/2017   Paddy Sanjeevi   Modified to release hold for answer=INV          |
-- | 1.2         01/04/2018   Paddy Sanjeevi   Modified to removed reason code while insert     |
-- | 1.3         01/11/2018   Paddy Sanjeevi   Modified to add terms_date in invoice interface  |
-- | 1.4         01/18/2018   Naveen Patha     Round amount                                     |
-- | 1.4         01/23/2018   Naveen Patha     Update ap_invoices_all with DM number            |
-- | 1.5         02/01/2018   Naveen Patha     Added org_id parameter                           |
-- | 1.6         02/28/2018   Paddy Sanjeevi   Changed answer code PO -> P O                    |
-- | 1.7         03/15/2018   Paddy Sanjeevi   Modified to populate attribute10 in header       |
-- | 1.8         04/13/2018   Paddy Sanjeevi   Modified to exclude held invoices                |
-- | 1.9         05/22/2018   Paddy Sanjeevi   Modified for defect NAIT-42780                   |
-- | 2.0         12/11/2018   Vivek Kumar      Modified for defect NAIT 64576                   |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name	 : Log Exception                                                            	|
-- |  Description: The log_exception procedure logs all exceptions				|
-- =============================================================================================|
gc_debug 			VARCHAR2(1):='Y';
gn_request_id   	fnd_concurrent_requests.request_id%TYPE;
gn_invoice_num  	VARCHAR2(50);
gn_grp_seq   		NUMBER;

gn_org_id			NUMBER;
gn_source			VARCHAR2(80);
gn_created_by		NUMBER:=fnd_global.user_id;


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


-- +======================================================================+
-- | Name        :  xx_purge_process_records                              |
-- | Description :  Procedure to purge records in custom table            |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE XX_PURGE_PROCESS_RECORDS
IS
BEGIN
  DELETE
    FROM xx_ap_supertran_stg
   WHERE chbk_process_flag='Y'
     AND creation_date<SYSDATE-30;
  COMMIT;
EXCEPTION
  WHEN others THEN
    print_debug_msg ('Error in purging xx_ap_supertran_stg : '||', '||SUBSTR(SQLERRM,1,100),TRUE);
END XX_PURGE_PROCESS_RECORDS;

-- +======================================================================+
-- | Name        :  get_distribution_list                                 |
-- | Description :  This function gets email distribution list from       |
-- |                the translation                                       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_distribution_list 
RETURN VARCHAR2
IS
  lc_first_rec      VARCHAR2(1);
  lc_temp_email     VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL         TYPE_TAB_EMAIL;
BEGIN
     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_AP_TRADE_MATCH_DL'
       AND   source_value1    = 'UI_ACTION_ERRORS';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..10 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
       IF lc_temp_email IS NULL THEN
      lc_temp_email:='padmanaban.sanjeevi@officedepot';
       END IF;
       RETURN(lc_temp_email);
     EXCEPTION
       WHEN others then
         lc_temp_email:='padmanaban.sanjeevi@officedepot';
         RETURN(lc_temp_email);
     END;
END get_distribution_list;


-- +======================================================================+
-- | Name        :  xx_create_chbk_supertran                              |
-- | Description :  Procedure to create chargeback                        |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_create_chbk_supertran(p_invoice_id NUMBER)
IS

CURSOR inv_hdr(p_invoice_id NUMBER)
IS
SELECT a.invoice_num,
       a.invoice_id,
       a.invoice_type_lookup_code,
       a.invoice_date,
       a.vendor_id,
       a.vendor_site_id,
       a.invoice_currency_code,
       a.terms_id,
       a.description,
       a.attribute7,
       a.source,
       a.payment_method_code,
       a.pay_group_lookup_code,
       a.org_id,
       a.goods_received_date,
   	   a.voucher_num,
	   ph.segment1 po_num,
	   a.terms_date,
	   a.attribute1,a.attribute2,a.attribute3,a.attribute4,a.attribute5,a.attribute6,
	   a.attribute8,a.attribute9,a.attribute10,a.attribute11,a.attribute12,a.attribute13,
	   a.attribute14,a.attribute15
  FROM po_headers_all ph,
	   ap_invoices_all a
 WHERE a.invoice_id = p_invoice_id
   AND ph.po_header_id=NVL(a.quick_po_header_id,a.po_header_id);

CURSOR inv_lines(p_invoice_id NUMBER,p_line_no NUMBER)
IS
SELECT a.invoice_id , 
       a.line_number, 
       a.quantity_invoiced, 
       a.unit_price inv_price,
	   a.inventory_item_id,
	   a.item_description,
	   a.org_id,
       c.variance_account_id,
	   b.unit_price po_price
  FROM po_distributions_all c,
       po_lines_all b,
       ap_invoice_lines_all a
 WHERE a.invoice_id=p_invoice_id
   AND a.line_number=p_line_no
   AND b.po_line_id=a.po_line_id
   AND c.po_distribution_id=a.po_distribution_id;
   
CURSOR chbk_line(p_invoice_id NUMBER)		
IS
SELECT a.invoice_id,
       a.line_number
  FROM ap_invoice_lines_all a
 WHERE a.invoice_id=p_invoice_id
   AND EXISTS (SELECT 'X'
                 FROM xx_ap_cost_variance cv,
                      ap_holds_all ah
                WHERE ah.invoice_id=a.invoice_id    
                  AND ah.line_location_id=a.po_line_location_id
                  AND ah.hold_lookup_code='PRICE'
	  	          AND NVL(ah.status_flag,'X')<>'R'	
				  AND ah.release_lookup_code IS NULL
                  AND cv.invoice_id=ah.invoice_id
                  AND cv.po_line_id=a.po_line_id
                  AND cv.inv_line_num=a.line_number
                  AND cv.answer_code='P O'
              );
			  
ln_invoice_id 				NUMBER;
lc_price_desc          		VARCHAR2(200):=NULL;
ln_total_chbk_amt      		NUMBER:=0;
ln_line_chargeback_amt 		NUMBER:=0;
ln_ins_cnt					NUMBER:=0;
lc_line_status				VARCHAR2(10):='SUCCESS';
lc_hdr_status				VARCHAR2(10):='SUCCESS';

BEGIN

  SELECT AP_INVOICES_INTERFACE_S.nextval
	INTO ln_invoice_id
	FROM DUAL;

  FOR cur IN chbk_line(p_invoice_id) LOOP
  
     FOR crl IN inv_lines(cur.invoice_id,cur.line_number) LOOP

  	   ln_line_chargeback_amt	:=0;
	   ln_line_chargeback_amt 	:= ROUND(((crl.inv_price - crl.po_price) * crl.quantity_invoiced),2);
       lc_price_desc     		:= 'Price: (BP '|| crl.inv_price||' - PO PR '|| crl.po_price ||' )* BQ '|| crl.quantity_invoiced||'';	 
	 
	   BEGIN
         INSERT
           INTO ap_invoice_lines_interface
                  (
                    invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    amount,
                    description,
                    dist_code_combination_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    inventory_item_id,
                    item_description,
                    attribute5
                  )
                  VALUES
                  (
                    ln_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    cur.line_number,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chargeback_amt*-1),2),
                    lc_price_desc,
                    crl.variance_account_id,
                    fnd_global.user_id,
                    sysdate,
                    fnd_global.user_id,
                    sysdate,
                    -1,
                    crl.org_id,
                    crl.inventory_item_id,
                    crl.item_description,
                    cur.line_number
                  );
	     ln_ins_cnt:=ln_ins_cnt+1;
	   EXCEPTION
	     WHEN others THEN
	       lc_line_status:='ERROR';
	   END;
	   ln_total_chbk_amt:=ln_total_chbk_amt+ln_line_chargeback_amt;	 
	 END LOOP;
  
  END LOOP;

  IF lc_line_status='SUCCESS' AND ln_ins_cnt<>0 THEN

     FOR hdr IN inv_hdr(p_invoice_id) LOOP

       BEGIN
         INSERT  
	       INTO ap_invoices_interface
		       (invoice_id,
		        invoice_num,
		        invoice_type_lookup_code,
		        invoice_date,
		        vendor_id,
		        vendor_site_id,
		        invoice_amount,
		        invoice_currency_code,
		        terms_id,
		        description,
		        attribute7,
		        source,
		        payment_method_code,
		        pay_group_lookup_code,
		        org_id,
		        goods_received_date,
		        created_by,
		        creation_date,
		        last_updated_by,
		        last_update_date,
		        last_update_login,
			    po_number,
				group_id,
				terms_date,
				attribute12,
				attribute1,attribute2,attribute3,attribute4,attribute5,attribute6,
				attribute8,attribute9,attribute10,attribute11,attribute13,attribute14,attribute15
		       )
		 VALUES
		     (ln_invoice_id,
		      hdr.invoice_num||'DM',
		      'DEBIT',
		      hdr.invoice_date,
		      hdr.vendor_id,
		      hdr.vendor_site_id,
		      ROUND((ln_total_chbk_amt*-1),2), 
		      hdr.invoice_currency_code,
		      hdr.terms_id,   
		      hdr.description,
		      hdr.attribute7,
		      hdr.source,
		      hdr.payment_method_code,
		      hdr.pay_group_lookup_code,
		      hdr.org_id,
		      hdr.goods_received_date,
		      fnd_global.user_id,
		      sysdate,
		      fnd_global.user_id,
		      sysdate,
		      -1,
			  hdr.po_num,
			  gn_grp_seq,
			  hdr.terms_date,
			  'Y',
			  hdr.attribute1,hdr.attribute2,hdr.attribute3,hdr.attribute4,hdr.attribute5,hdr.attribute6,
			  hdr.attribute8,hdr.attribute9,hdr.attribute10,hdr.attribute11,hdr.attribute13,
			  hdr.attribute14,hdr.attribute15
		     );
		UPDATE ap_invoices_all
		   SET attribute3=hdr.invoice_num||'DM'
		 WHERE invoice_id=hdr.invoice_id;
		BEGIN
	     INSERT
	       INTO xx_ap_supertran_stg
		      (invoice_num,
			   invoice_id,
			   vendor_id,
			   vendor_site_id,
			   chbk_process_flag,
			   request_id,
			   creation_date,
			   created_by,
			   last_update_date,
			   last_updated_by
			  )
	     VALUES
		      (hdr.invoice_num||'DM',
			   hdr.invoice_id,
			   hdr.vendor_id,
			   hdr.vendor_site_id,
			   'N',
			   gn_request_id,
			   sysdate,
			   fnd_global.user_id,
			   sysdate,
			   fnd_global.user_id
			  );
        EXCEPTION
		  WHEN others THEN
          NULL;
        END;	 
       EXCEPTION
	     WHEN others THEN
		   lc_hdr_status:='ERROR';
       END;	 
     END LOOP;  --FOR hdr IN inv_hdr(p_invoice_id) LOOP	   
  END IF;  --IF lc_line_status='SUCCESS' AND ln_ins_cnt<>0 THEN    
  
  IF lc_hdr_status='SUCCESS' THEN
	 COMMIT;
  ELSE
     ROLLBACK;
  END IF;
EXCEPTION
  WHEN others THEN			
    print_debug_msg ('Error while inserting in interface table for chargeback Creation : '||gn_invoice_num||', '||SUBSTR(SQLERRM,1,100),TRUE);
END xx_create_chbk_supertran;

-- +======================================================================+
-- | Name        :  xx_intf_stuck_notify                                  |
-- | Description :  To send notification for Interface Stuck Invoice/DM   |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_intf_stuck_notify
IS

lc_temp_email   	     	VARCHAR2(2000);
v_subject    	        	VARCHAR2(500);
conn                	 	utl_smtp.connection;
v_text                		VARCHAR2(2000);
v_smtp_hostname        		VARCHAR2 (120):=FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');

CURSOR C1 
IS
SELECT invoice_num
  FROM xx_ap_supertran_stg
 WHERE request_id=gn_request_id
   AND chbk_process_flag='E';

i NUMBER:=0;   
BEGIN
  v_text :='Please resolve the following Debit Memo in POI before Payment Creation Process today '||chr(10);

  FOR cur IN C1 LOOP
    i:=i+1;
    v_text :=v_text||' Invoice : '||cur.invoice_num||chr(10);
  END LOOP;
  IF i>0 THEN
     lc_temp_email:=get_distribution_list;  
     conn := xx_pa_pb_mail.begin_mail(
				  sender => 'Accounts-Payable@officedepot.com',
                  recipients => lc_temp_email,
				  cc_recipients=>NULL,
                  subject => 'OD AP Supertran Rejected Debit Memo in POI',
                  mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
                  xx_pa_pb_mail.attach_text( conn => conn,
                                             data => v_text
                                            );
                xx_pa_pb_mail.end_mail( conn => conn );
                COMMIT;
     UPDATE xx_ap_supertran_stg
        SET chbk_process_flag='Y'
      WHERE request_id=gn_request_id;
     COMMIT;   
  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_inft_stuck_notify :'||SQLERRM);
END xx_intf_stuck_notify;


-- +======================================================================+
-- | Name        :  xx_rel_ansinv_holds                                   |
-- | Description :  Procedure to release price holds if the answer=INV    |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_rel_ansinv_holds
IS

CURSOR c_rel_inv_holds 
IS
SELECT /*+ LEADING (h) */
	   ai.invoice_id,
       al.po_line_location_id line_location_id,
	   h.hold_lookup_code
  FROM ap_invoice_lines_all al,
       ap_invoices_all ai,
      (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */
			  distinct 
			  aph.invoice_id,
		      aph.hold_lookup_code,
			  aph.line_location_id
         FROM ap_holds_all aph
        WHERE aph.creation_date > '01-JAN-11' 
          AND NVL(aph.status_flag,'S')= 'S'
		  AND aph.release_lookup_code IS NULL
		  AND aph.hold_lookup_code='PRICE'
      )h   
 WHERE ai.invoice_id=h.invoice_id
   AND ai.source=NVL(gn_source,ai.source)
   AND ai.org_id=gn_org_id
   AND al.invoice_id=ai.invoice_id
   AND ai.validation_request_id IS NULL
   AND al.po_line_location_id=h.line_location_id   
   AND EXISTS(SELECT 'x'
                FROM xx_fin_translatedefinition xftd, 
                     xx_fin_translatevalues xftv 
               WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
                 AND xftd.translate_id     = xftv.translate_id
                 AND xftv.target_value1    = ai.source
                 AND xftv.enabled_flag     = 'Y'
                 AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
             )        
   AND EXISTS ( SELECT 'X'
                 FROM xx_ap_cost_variance cv
                WHERE cv.invoice_id=al.invoice_id
                  AND cv.po_line_id=al.po_line_id
                  AND cv.inv_line_num=al.line_number
                  AND cv.answer_code='INV'
			  );
BEGIN
 
  FOR cur IN c_rel_inv_holds LOOP

      UPDATE ap_holds_all
         SET release_lookup_code = 'PD',
		     release_reason = 'PRICING',
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id,
             status_flag='R'
       WHERE invoice_id = cur.invoice_id
         AND line_location_id=cur.line_location_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = cur.hold_lookup_code
		 AND NVL(status_flag,'X')<>'R';					     

  END LOOP;  
  COMMIT;
EXCEPTION
  WHEN others THEN
    print_debug_msg ('Error while Releasing Holds : '||SUBSTR(SQLERRM,1,100),TRUE);
END xx_rel_ansinv_holds;

-- +======================================================================+
-- | Name        :  xx_release_holds                                      |
-- | Description :  Procedure to release price holds after chargeback     |
-- |                                                                      |
-- | Parameters  :                                                        |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_release_holds
IS

CURSOR c_rel_holds 
IS
SELECT a.invoice_id,
       a.po_line_location_id line_location_id,
	   ah.hold_lookup_code
  FROM ap_invoice_lines_all a,
       ap_holds_all ah,
	   xx_ap_supertran_stg s
 WHERE s.request_id=gn_request_id
   AND ah.invoice_id=s.invoice_id
   AND ah.hold_lookup_code='PRICE'
   AND NVL(ah.status_flag,'X')<>'R'				
   AND ah.release_lookup_code IS NULL   
   AND a.invoice_id=ah.invoice_id   
   AND a.po_line_location_id=ah.line_location_id
   AND EXISTS ( SELECT 'X'
                 FROM xx_ap_cost_variance cv
                WHERE cv.invoice_id=a.invoice_id
                  AND cv.po_line_id=a.po_line_id
                  AND cv.inv_line_num=a.line_number
                  AND cv.answer_code='P O'
			  );
			  
 
BEGIN

  UPDATE xx_ap_supertran_stg a
     SET chbk_process_flag='Y'
   WHERE request_id=gn_request_id
     AND EXISTS (SELECT 'x'
                   FROM ap_invoices_all
				  WHERE invoice_num=a.invoice_num
				    AND vendor_id=a.vendor_id
					AND vendor_site_id=a.vendor_site_id
			    );
  COMMIT;			
  
  FOR cur IN c_rel_holds LOOP

      UPDATE ap_holds_all
         SET release_lookup_code = 'PD',
		     release_reason = 'PRICING',
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id,
             status_flag='R'
       WHERE invoice_id = cur.invoice_id
         AND line_location_id=cur.line_location_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = cur.hold_lookup_code
		 AND NVL(status_flag,'X')<>'R';					     

  END LOOP;  
  COMMIT;

  UPDATE xx_ap_supertran_stg a
     SET chbk_process_flag='E'
   WHERE request_id=gn_request_id
     AND NOT EXISTS (SELECT 'x'
			           FROM ap_invoices_all
					  WHERE invoice_num=a.invoice_num
					    AND vendor_id+0=a.vendor_id
						AND vendor_site_id+0=a.vendor_site_id
				    );
  COMMIT;					
  xx_intf_stuck_notify;
EXCEPTION
  WHEN others THEN
    print_debug_msg ('Error while Releasing Holds : '||SUBSTR(SQLERRM,1,100),TRUE);
END xx_release_holds;

-- +======================================================================+
-- | Name        :  xx_call_payables_import                               |
-- | Description :  This function to submit Payables Open Interface       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_call_payables_import RETURN VARCHAR2
IS

    v_request_id           NUMBER;
    x_dummy                VARCHAR2(2000) ;
    v_dphase               VARCHAR2(100) ;
    v_dstatus              VARCHAR2(100) ;
    v_phase                VARCHAR2(100) ;
    v_status               VARCHAR2(100) ;
	v_error				   VARCHAR2(100);

BEGIN

  v_request_id  :=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXIIMPT','Payables Open Interface',NULL,FALSE,
					gn_org_id,gn_source,gn_grp_seq,'N/A',NULL,NULL,NULL,'N','N','N','N',1000,gn_created_by,-1,'N');
  IF v_request_id>0 THEN
     COMMIT;
     print_debug_msg ('Payables Import Request id : '||TO_CHAR(v_request_id),TRUE);	 

 	 IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
  
        IF (v_dphase = 'COMPLETE' AND v_dstatus='NORMAL') THEN
           RETURN('SUCCESS');
		ELSIF (v_dphase = 'COMPLETE' AND v_dstatus<>'NORMAL') THEN
           RETURN('ERROR');		   
        END IF;		

 	 END IF;
  ELSE
    RETURN('ERROR');
  END IF;
EXCEPTION
  WHEN others THEN
    v_error:=SUBSTR(SQLERRM,1,100);
	dbms_output.put_line('Error in xx_call_payables_import : '||SUBSTR(SQLERRM,1,100));
    RETURN('ERROR');
END xx_call_payables_import;  


-- +======================================================================+
-- | Name        :  process_supertran                                     |
-- | Description :  Main Procedure to process Supertran                   |
-- |                                                                      |
-- | Parameters  :  p_errbuf                                              |
-- |                p_retcode                                             |
-- |                p_source                                              |
-- |                                                                      |
-- +======================================================================+

PROCEDURE process_supertran(p_errbuf      OUT  VARCHAR2 
						   ,p_retcode     OUT  VARCHAR2
						   ,p_source      IN   VARCHAR2
						   ) 
IS

CURSOR C_tran IS
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
			       distinct invoice_id
              FROM ap_holds_all aph
             WHERE aph.creation_date > '01-JAN-11' 
               AND NVL(aph.status_flag,'S')= 'S'
			   AND aph.hold_lookup_code='PRICE'
			   AND aph.release_lookup_code IS NULL
		   )h   
      WHERE ai.invoice_id=h.invoice_id
        AND ai.source=NVL(p_source,ai.source)
		AND ai.validation_request_id IS NULL 
		AND ai.org_id+0=gn_org_id
        AND EXISTS(SELECT 'x'
                     FROM xx_fin_translatedefinition xftd, 
                          xx_fin_translatevalues xftv 
                    WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES' 
                      AND xftd.translate_id     = xftv.translate_id
                      AND xftv.target_value1    = ai.source
                      AND xftv.enabled_flag     = 'Y'
                      AND SYSDATE BETWEEN xftv.start_date_active and NVL(xftv.end_date_active,sysdate)
                  )        
        AND EXISTS(SELECT 'x'
                     FROM xx_ap_cost_variance
					WHERE invoice_id=ai.invoice_id
					  AND answer_code='P O'
			      )
ORDER BY ai.invoice_id;			  
			  
ln_pay_po_exists		 	NUMBER:=0;
ln_other_holds_exists 		NUMBER:=0;
ln_dm_exists				NUMBER:=0;
ln_intf_cnt					NUMBER:=0;
lc_import_status			VARCHAR2(20);

BEGIN						   

  SELECT XX_AP_CHBK_IMPORT_SEQ.nextval 
    INTO gn_grp_seq 
	FROM dual;	
   
  gn_request_id:=FND_GLOBAL.CONC_REQUEST_ID;
  gn_source :=p_source;
  gn_org_id :=FND_PROFILE.VALUE('ORG_ID');

  FOR cur IN c_tran LOOP

    gn_invoice_num:=cur.invoice_num;
  
    SELECT COUNT(1)
	  INTO ln_pay_po_exists
      FROM ap_invoice_lines_all a
     WHERE a.invoice_id=cur.invoice_id
       AND EXISTS (SELECT 'X'
                     FROM xx_ap_cost_variance cv,
                          ap_holds_all ah
                    WHERE ah.invoice_id=a.invoice_id    
                      AND ah.line_location_id=a.po_line_location_id
                      AND ah.hold_lookup_code='PRICE'
					  AND NVL(ah.status_flag,'X')<>'R'
                      AND ah.release_lookup_code IS NULL					  
                      AND cv.invoice_id=ah.invoice_id
                      AND cv.po_line_id=a.po_line_id
                      AND cv.inv_line_num=a.line_number
                      AND cv.answer_code='P O'
                  )
	   AND NOT EXISTS (SELECT 'x'
	                     FROM xx_ap_cost_variance
						WHERE invoice_id=a.invoice_id
						  AND answer_code IS NULL
					   )
	   AND NOT EXISTS (SELECT 'x'
	                     FROM xx_ap_cost_variance
						WHERE invoice_id=a.invoice_id
						  AND answer_code IN ('OTH','PP')  ---NAIT 64576
					   );					   
    IF ln_pay_po_exists<>0 THEN

	   SELECT COUNT(1)
	     INTO ln_other_holds_exists
		 FROM ap_holds_all
		WHERE invoice_id=cur.invoice_id
		  AND hold_lookup_code<>'PRICE'
		  AND release_lookup_code IS NULL
		  AND NVL(status_flag,'X')<>'R';

       IF ln_other_holds_exists=0 THEN
	   
		  SELECT COUNT(1)
	        INTO ln_dm_exists
	        FROM ap_invoices_all
	       WHERE invoice_num=cur.invoice_num||'DM';
	  
	     IF ln_dm_exists=0 THEN

	        xx_create_chbk_supertran(cur.invoice_id);

	     END IF;
 
       END IF;	   

    END IF;	
  
  END LOOP;
  
  SELECT COUNT(1)
    INTO ln_intf_cnt
	FROM ap_invoices_interface
   WHERE group_id=TO_CHAR(gn_grp_seq);

   IF ln_intf_cnt<>0 THEN
  
     lc_import_status:=xx_call_payables_import;
	 
	 IF lc_import_status='SUCCESS' THEN
	 
	    xx_release_holds;
	 
	 END IF;
  
  END IF;
  xx_rel_ansinv_holds;
  xx_purge_process_records;
EXCEPTION
  WHEN others THEN  
   print_debug_msg ('ERROR AP Supertran Process - '||SUBSTR(SQLERRM,1,100),TRUE);
   p_errbuf := substr(sqlerrm,1,250);
   p_retcode := '2';   
END process_supertran;						   
				   
END XX_AP_SUPERTRAN_CHBK_PKG;
/
SHOW ERRORS;