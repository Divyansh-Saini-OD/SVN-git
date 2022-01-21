DECLARE
    CURSOR hdr_details(p_in_date DATE) 
	IS
        SELECT hdr.invoice_id stg_invoice_id,
               hdr.invoice_number stg_invoice_num,
			   hdr.default_po||'-'||LPAD(hdr.location_id,4,'0') po_number,
               aia.invoice_num
          FROM xx_ap_trade_inv_hdr hdr,
	           ap_invoices_all aia
         WHERE 1 =1 
           AND hdr.record_status = 'N'
		   AND hdr.source = 'US_OD_TRADE_EDI'
		   AND hdr.creation_date BETWEEN TO_DATE(:p_in_date||' 00:00:00','DD-MON-RR HH24:MI:SS') 
                                     AND TO_DATE(:p_in_date||' 23:59:59','DD-MON-RR HH24:MI:SS')
		   AND LTRIM(regexp_replace(hdr.invoice_number , '(*[[:punct:]])', ''),'0') = aia.invoice_num
		   AND EXISTS ( SELECT 1
		                  FROM po_headers_all
						 WHERE segment1 = hdr.default_po||'-'||LPAD(hdr.location_id,4,'0')
						   AND vendor_id = aia.vendor_id
                           AND attribute_category LIKE 'DropShip%');
						   
	ln_hdr_count    NUMBER := 0;
	ln_lines_count  NUMBER := 0;
 
BEGIN

    dbms_output.put_line('Begin process to update the invoice status to Completed');
	FOR hdr_cur IN hdr_details
    LOOP
       dbms_output.put_line('Processing Invoice Number :'||hdr_cur.invoice_num);
	   
	   BEGIN
		   UPDATE xx_ap_trade_inv_hdr
		      SET record_status = 'C',
			      error_description = 'This DROPSHIP Invoice is already processed in EBS',
			      last_update_date = SYSDATE,
				  last_updated_by = 3523831
		    WHERE invoice_id = hdr_cur.stg_invoice_id; 
	   EXCEPTION
	   WHEN OTHERS
	   THEN
		    dbms_output.put_line('Unable to update the record status in the Pre-Staging Header Table for the Invoice ID :'||hdr_cur.stg_invoice_id,FALSE);
	   END;
	   
	   ln_count := SQL%ROWCOUNT;
	   
	   IF ln_count >0
	   THEN
	       ln_hdr_count := ln_hdr_count+ln_count;
	   END IF;    
	    	   
	   BEGIN
		   UPDATE xx_ap_trade_inv_lines
		      SET record_status = 'C',
			      error_description = 'This DROPSHIP Invoice is already processed in EBS',
			      last_update_date = SYSDATE,
				  last_updated_by = 3523831
		    WHERE invoice_id = hdr_cur.stg_invoice_id; 
	   EXCEPTION
	   WHEN OTHERS
	   THEN
		    dbms_output.put_line('Unable to update the record status in the Pre-Staging Lines Table for the Invoice ID :'||hdr_cur.stg_invoice_id,FALSE);
	   END;
	   
	   ln_count1 := SQL%ROWCOUNT;
	   
	   IF ln_count1 >0
	   THEN
	       ln_lines_count := ln_lines_count + ln_count1;
	   END IF; 
	   
	END LOOP;
	COMMIT;
	dbms_output.put_line('# of Header Records Updated :'||ln_hdr_count);
    dbms_output.put_line('# of Lines Records Updated :'||ln_lines_count);

EXCEPTION
WHEN OTHERS
THEN
    ROLLBACK;
    dbms_output.put_line('Error while processing the pre-staging records :'||SUBSTR(SQLERRM,1,255));
END;
	
    