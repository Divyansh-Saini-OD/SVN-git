create or replace PACKAGE BODY XX_AP_TRADE_INV_CONV_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_TRADE_INV_CONV_PKG                                                        |
-- |  RICE ID 	 :                                           			                        |
-- |  Description:                                                                          	|
-- |                                                           				                    |        
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         14-JUL-2017  Havish Kasina    Initial version                                  |
-- | 1.1         24-OCT-2017  Havish Kasina    SIT03 testing changes                            |
-- | 1.2         03-NOV-2017  Havish Kasina    Populating the Reason code value in the          |
-- |                                           Attribute11 in the lines staging table           |
-- +============================================================================================+

-- +============================================================================================+
-- |  Name	 : Log Exception                                                            	    |
-- |  Description: The log_exception procedure logs all exceptions				                |
-- =============================================================================================|

gc_debug 	    VARCHAR2(2);
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
			    ,p_module_name             => 'AP'
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
       lc_Message := p_message;
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
-- |  Name	 : get_po_terms_id                                                                  |
-- |  Description: Procedure to get the PO Terms ID                                             |
-- =============================================================================================|
PROCEDURE get_po_terms_id(p_po_number         IN   VARCHAR2
						 ,o_terms_id          OUT  NUMBER
						 ,o_vendor_id         OUT  NUMBER
						 ,o_vendor_site_id    OUT  NUMBER
						 ,o_attr_category     OUT  VARCHAR2
						 ,o_terms_name        OUT  VARCHAR2)
IS
lc_error_loc VARCHAR2(100);
lc_error_msg VARCHAR2(300);
BEGIN
   	SELECT pha.terms_id,
	       pha.vendor_id,
		   pha.vendor_site_id,
		   pha.attribute_category,
	       att.name		   
	  INTO o_terms_id,
	       o_vendor_id,
		   o_vendor_site_id,
		   o_attr_category,
	       o_terms_name
	  FROM po_headers_all pha,
	       ap_terms_tl att
	 WHERE 1 =1
	   AND pha.segment1 = p_po_number
	   AND pha.terms_id = att.term_id;
EXCEPTION
    WHEN OTHERS
    THEN
        o_terms_id := NULL;
		o_terms_name := NULL;
		o_vendor_id := NULL;
		o_vendor_site_id := NULL;
		o_attr_category  := NULL;
        lc_error_msg := substr(sqlerrm,1,250);
        print_debug_msg ('Unable to get the PO Terms ID for the PO Number :'||p_po_number||' - '||substr(sqlerrm,1,250),TRUE);
        log_exception ('XX_AP_INVOICE_INTEGRAL_PKG.get_po_terms_id',
                       lc_error_loc,
		               lc_error_msg); 
END get_po_terms_id;

-- +============================================================================================+
-- |  Name	 : parse                                                                	|
-- |  Description: Procedure to parse delimited string and load them into table                 |
-- =============================================================================================|
PROCEDURE parse(p_delimstring IN  VARCHAR2
               ,p_table       OUT varchar2_table
               ,p_nfields     OUT INTEGER
               ,p_delim       IN  VARCHAR2 DEFAULT '|'
               ,p_error_msg   OUT VARCHAR2
               ,p_retcode     OUT VARCHAR2) IS
               
   l_string   VARCHAR2(32767) := p_delimstring;
   l_nfields  PLS_INTEGER := 1;
   l_table    varchar2_table;
   l_delimpos PLS_INTEGER := INSTR(p_delimstring, p_delim);
   l_delimlen PLS_INTEGER := LENGTH(p_delim);               
BEGIN
   WHILE l_delimpos > 0
   LOOP
      l_table(l_nfields) := TRIM(SUBSTR(l_string,1,l_delimpos-1));
      l_string 	 := SUBSTR(l_string,l_delimpos+l_delimlen);
      l_nfields  := l_nfields+1;
      l_delimpos := INSTR(l_string, p_delim);
   END LOOP;
   l_table(l_nfields) := TRIM(l_string);
   p_table 	:= l_table;
   p_nfields	:= l_nfields;
EXCEPTION
WHEN others THEN
   p_retcode   := '2';
   p_error_msg := 'Error in XX_AP_TRADE_INV_CONV_PKG.parse - record:'||substr(sqlerrm,1,150);   
END parse;

-- +============================================================================================+
-- |  Name	 : insert_header                                                                 	|
-- |  Description: Procedure to insert data into header staging table                           |
-- =============================================================================================|
PROCEDURE insert_header(p_table       IN varchar2_table
                       ,p_error_msg   OUT VARCHAR2
                       ,p_errcode     OUT VARCHAR2) 
IS
   l_table    	       varchar2_table ;
   ln_terms_id        NUMBER;
   lc_terms_name      VARCHAR2(30);
   
BEGIN
  l_table.delete;
  ln_terms_id     := NULL;
  lc_terms_name   := NULL;
  
  l_table := p_table;
		
	print_debug_msg(' Vendor Site is :'||l_table(5),FALSE); 
 
   INSERT 
     INTO xx_ap_trade_inv_conv_hdr
   	(invoice_id
	,record_type
	,company
	,bth              
	,vendor_name      
	,vendor_number    
	,invoice_number   
	,po_voucher       
	,invoice_date     
	,po_number        
	,location         
	,due_date         
	,invoice_amount  
    ,invoice_amount_sign	
	,invoice_quantity
    ,source                    
    ,voucher_type              
    ,terms_date                
    ,terms_id                  
    ,terms_name                
    ,dcn_number                
    ,pay_group                 
    ,payment_method_lookup_code
    ,ap_liab_acct
    ,vendor_id
    ,vendor_site_id	
    ,org_id	
	,record_status
	,error_description
	,error_code
	,error_flag
	,request_id
	,created_by
	,creation_date
	,last_updated_by
	,last_update_date
	,last_update_login)
    VALUES
    (TO_NUMBER(l_table(1)) -- invoice_id 
    ,'H' -- record_type
	,l_table(2)  -- company
	,l_table(3)  -- bth
	,l_table(4)  -- vendor_name
	,l_table(5)  -- vendor_number
	,l_table(6)  -- invoice_number
	,l_table(7)  -- po_voucher
	,TO_DATE(l_table(8),'MM/DD/YYYY') -- invoice_date 
	,l_table(9)  -- po_number
	,l_table(10) -- location
	,TO_DATE(l_table(11),'MM/DD/YYYY') -- due_date
	,TO_NUMBER(l_table(12)) -- invoice_amount
	,l_table(14) -- invoice_amount_sign
	,TO_NUMBER(l_table(13)) -- invoice_quantity
    ,l_table(16) -- source                    
    ,NULL -- voucher_type              
    ,TO_DATE(l_table(8),'MM/DD/YYYY') -- terms_date                
    ,NULL -- ln_terms_id -- terms_id                  
    ,TRIM(l_table(15)) -- lc_terms_name -- terms_name                
    ,l_table(17) -- dcn_number                
    ,NULL -- pay_group                 
    ,NULL -- payment_method_lookup_code
    ,NULL -- ap_liab_acct  
    ,NULL -- vendor_id,
    ,NULL -- vendor_site_id	
    ,NULL -- org_id	
	,'N'  -- record_status
	,''	  -- error_description
	,NULL -- error_code
	,'N'  -- error_flag
	,gn_request_id
	,gn_user_id
	,sysdate
	,gn_user_id
	,sysdate
	,gn_login_id);
	
EXCEPTION
WHEN others THEN
   p_errcode   := '2';
   p_error_msg := 'Error in XX_AP_TRADE_INV_CONV_PKG.insert_header '||substr(sqlerrm,1,150); 
   print_debug_msg('Error Message :'||p_error_msg,FALSE); 
END insert_header;	

-- +============================================================================================+
-- |  Name	 : insert_line                                                               	    |
-- |  Description: Procedure to insert line data into line staging table                        |
-- =============================================================================================|
PROCEDURE insert_line(p_table       IN varchar2_table
                     ,p_invoice_id  IN NUMBER
                     ,p_error_msg   OUT VARCHAR2
                     ,p_errcode     OUT VARCHAR2) 
IS
   l_table    	    varchar2_table;
   lc_company       VARCHAR2(30);
   lc_cost_center   VARCHAR2(30);
   lc_account       VARCHAR2(30);
   lc_location      VARCHAR2(30);
   lc_lob           VARCHAR2(30);
   lc_inter_company VARCHAR2(30);
   lc_future        VARCHAR2(30);
   lc_line_type     VARCHAR2(30);
   ln_invoice_amt   NUMBER;

BEGIN
  l_table            := p_table;   
  lc_company         := NULL;
  lc_cost_center     := NULL;
  lc_account         := NULL;
  lc_location        := NULL;
  lc_lob             := NULL;
  lc_inter_company   := NULL;
  lc_future          := NULL;
  lc_line_type       := NULL;
  ln_invoice_amt     := 0;
    
	ln_invoice_amt := TO_NUMBER(SUBSTR(l_table(11),1, LENGTH(l_table(11))-1)); -- Invoice amount
  
  	-- To get the Line Type
	IF l_table(33) IS NULL AND l_table(12) IS NOT NULL AND l_table(13) IS NOT NULL  AND l_table(16) IS NOT NULL-- Reason code is null and Quantity is not null and Unit Price is not null and SKU is not null
	THEN 
	    lc_line_type := 'ITEM';
		
	ELSE
		IF l_table(33) IN ('FR','FS','FP') AND l_table(34) IS NOT NULL -- Reason code = 'FR' and Invoice Line Amount is not null
	    THEN
	        lc_line_type := 'FREIGHT';
	        l_table(12) := NULL;      -- Invoice Quantity
	        l_table(13) := NULL;      -- Unit Price
	        l_table(16) := NULL;      -- SKU		
	    ELSIF l_table(33) IS NULL AND l_table(16) IS NULL AND (l_table(12) = '000000000' OR l_table(12) IS NULL) AND l_table(34) IS NOT NULL -- Reason Code is Null and SKU is null and Quantity is neither null or zero and Invoice Line amount is not null
	    THEN
		    lc_line_type := 'MISCELLANEOUS';
		    l_table(12) := NULL;      -- Invoice Quantity
	        l_table(13) := NULL;      -- Unit Price
	        l_table(16) := NULL;      -- SKU
			l_table(33) := 'DEFAULT'; -- Reason Code
	    ELSIF l_table(16) IS NULL AND l_table(13) IS NULL AND (l_table(12) = '000000000' OR l_table(12) IS NULL) AND l_table(34) IS NULL AND ln_invoice_amt > 0 -- SKU is null and Unit Price is NULL and Quantity is neither null or zero and invoice line amount is null and invoice amount is greater than 0
	    THEN 
	        -- To create the Penny line for the "MISCELLANEOUS" line type
	        lc_line_type := 'MISCELLANEOUS';
		    l_table(34) := '0.01+';   -- Invoice Line Amount
	        l_table(33) := 'DEFAULT'; -- Reason Code
	        l_table(12) := NULL;      -- Invoice Quantity
	        l_table(13) := NULL;      -- Unit Price
	        l_table(16) := NULL;      -- SKU		
	    ELSIF l_table(33) NOT IN ('FR','FS','FP') AND l_table(33) IS NOT NULL -- Reason code not in ('FR','FS','FP') and Reason Code is not null
	    THEN
	        lc_line_type := 'MISCELLANEOUS';
		    l_table(12) := NULL;      -- Invoice Quantity
	        l_table(13) := NULL;      -- Unit Price
	        l_table(16) := NULL;      -- SKU
	    ELSE
	        lc_line_type := 'MISCELLANEOUS';
		    l_table(12) := NULL;      -- Invoice Quantity
	        l_table(13) := NULL;      -- Unit Price
	        l_table(16) := NULL;      -- SKU
			l_table(33) := 'DEFAULT'; -- Reason Code
		END IF;
		
	END IF;
	
	print_debug_msg('Line Type is :'||lc_line_type,FALSE);  
	           
   INSERT 
     INTO xx_ap_trade_inv_conv_lines
	(invoice_line_id
	,invoice_id
	,record_type
	,line_number  
	,line_type    
	,company          
	,bth              
	,vendor_name      
	,vendor_number    
	,invoice_number   
	,po_voucher       
	,invoice_date     
	,po_number        
	,location         
	,due_date         
	,invoice_amount  
	,invoice_line_amount
	,invoice_line_amount_sign
    ,invoice_amount_sign	
	,invoice_quantity 
	,invoice_quantity_sign
	,unit_price       
	,uom              
	,po_line_number   
	,sku       
    ,gl_company        
    ,gl_location       
    ,gl_cost_center    
    ,gl_lob            
    ,gl_account        
    ,gl_inter_company  
    ,gl_future         
    ,line_description  
    ,source            
    ,reason_code       
    ,reason_code_desc	
	,terms
	,dcn_number
	,uap
	,record_status
	,error_description
	,error_code
	,error_flag
	,request_id
	,created_by
	,creation_date
	,last_updated_by
	,last_update_date
	,last_update_login)
     VALUES
    (ap_invoice_lines_interface_s.NEXTVAL  -- invoice_line_id
	,p_invoice_id  -- invoice_id
    ,'D'  -- record_type
	,NULL         -- line_number 
	,lc_line_type  -- line_type  
    ,l_table(1)   -- company         
    ,l_table(2)	  -- bth             
	,l_table(3)   -- vendor_name     
	,l_table(4)   -- vendor_number   
	,l_table(5)   -- invoice_number  
	,l_table(6)   -- po_voucher      
	,l_table(7)   -- invoice_date    
	,l_table(8)   -- po_number       	
	,l_table(9)   -- location        
	,l_table(10)  -- due_date        
	,ln_invoice_amt -- TO_NUMBER(SUBSTR(l_table(11),1, LENGTH(l_table(11))-1))  -- invoice_amount 
    ,TO_NUMBER(SUBSTR(l_table(34),1, LENGTH(l_table(34))-1)) -- invoice_line_amount	
	,SUBSTR(l_table(34),LENGTH(l_table(34)))     -- invoice_line_amount_sign
	,SUBSTR(l_table(11), LENGTH(l_table(11))) -- invoice_amount_sign
	,TO_NUMBER(l_table(12))  -- invoice_quantity
	,NULL         -- invoice_quantity_sign
	,TO_NUMBER(SUBSTR(l_table(13),1, LENGTH(l_table(13))-1))  -- unit_price      
	,l_table(14)  -- uom             
	,LTRIM(l_table(15),'0')  -- po_line_number  
	,LTRIM(l_table(16),'0')  -- sku  
    ,NULL -- lc_company -- gl_company        
    ,NULL -- lc_location -- gl_location       
    ,NULL -- lc_cost_center -- gl_cost_center    
    ,NULL -- lc_lob -- gl_lob            
    ,NULL -- lc_account -- gl_account        
    ,NULL -- lc_inter_company   -- gl_inter_company  
    ,NULL -- lc_future  -- gl_future         
    ,l_table(21)  --line_description  
    ,TRIM(l_table(30))  -- source            
    ,DECODE(l_table(33),'DEFAULT',NULL,l_table(33))  -- reason_code       
    ,NULL         -- reason_code_desc  
    ,l_table(22)  -- terms
    ,l_table(17)  -- dcn_number
	,l_table(18)  -- uap
	,'N'		  -- record_status
	,''			  -- error_description
	,NULL         -- error_code
	,'N'          -- error_flag
	,gn_request_id
	,gn_user_id
	,sysdate
	,gn_user_id
	,sysdate
	,gn_login_id); 

EXCEPTION
WHEN others THEN
   p_errcode   := '2';
   p_error_msg := 'Error in XX_AP_TRADE_INV_CONV_PKG.insert_line '||substr(sqlerrm,1,150);   
   print_debug_msg('Error Message :'||p_error_msg,FALSE); 
END insert_line; 

-- +===============================================================================================+
-- |  Name	 : load_data_to_interface_table                                                        |                 	
-- |  Description: This procedure reads data from the pre-staging and inserts into interface tables|
-- ================================================================================================|
PROCEDURE load_data_to_interface_table(p_errbuf         OUT  VARCHAR2
                                      ,p_retcode        OUT  VARCHAR2
									  ,p_debug          IN   VARCHAR2
									  ,p_status         IN   VARCHAR2)
AS 

   -- Cursor to select all the header information
    CURSOR header_cur 
	IS
	WITH vendor AS
    (
     SELECT /*+ cardinality(ven,10) */
            ven.vendor_id
           ,ven.vendor_site_id
		   ,ven.pay_group_lookup_code 
		   ,ven.payment_method_lookup_code
		   ,ven.org_id
		   ,ven.terms_id terms_id_sup
		   ,ven.attribute9
		   ,ven.attribute7
		   ,ven.vendor_site_code_alt
       FROM ap_supplier_sites_all ven
      WHERE ven.pay_site_flag = 'Y'
        AND NVL(ven.inactive_date,sysdate) >= trunc(sysdate)
		AND ven.attribute8 LIKE 'TR%'
    )
    SELECT stg.invoice_id             
	      ,stg.vendor_name      
	      ,stg.vendor_number    
	      ,stg.invoice_number   
	      ,stg.po_voucher       
	      ,stg.invoice_date     
	      ,stg.po_number        
	      ,stg.location         
	      ,stg.due_date         
	      ,stg.invoice_amount  
	      ,stg.invoice_amount_sign	
	      ,stg.invoice_quantity
	      ,stg.source                    
	      ,stg.voucher_type              
	      ,stg.terms_date                
	      ,stg.terms_id                  
	      ,stg.terms_name                
	      ,stg.dcn_number   
          ,stg.record_status
          ,stg.error_description
          ,stg.error_code
          ,stg.error_flag		  
	      ,ven1.vendor_id vendor_id_sup
          ,ven1.vendor_site_id vendor_site_id_sup
		  ,ven1.pay_group_lookup_code 
		  ,ven1.payment_method_lookup_code
		  ,ven1.org_id
		  ,ven1.terms_id_sup	  
	  FROM xx_ap_trade_inv_conv_hdr stg
	       LEFT JOIN vendor ven1
		   ON ltrim(NVL(ven1.attribute9,(NVL(ven1.vendor_site_code_alt,NVL(ven1.attribute7,ven1.vendor_site_id)))),'0') = ltrim(stg.vendor_number,'0')
		   -- ON ltrim(vendor_site_code_alt,'0') = ltrim(stg.vendor_number,'0')
	 WHERE stg.record_status = p_status
	 ORDER BY stg.invoice_id;
                  
    TYPE header IS TABLE OF header_cur%ROWTYPE
    INDEX BY PLS_INTEGER;
   				 
   -- Cursor to select all the lines information
    CURSOR lines_cur IS				 
	WITH po_info AS
    (
     SELECT pol.item_id,
            pol.item_description,
            poh.segment1,
            poh.po_header_id,
            pol.line_num,
			poh.ship_to_location_id,
			poh.attribute_category,
			pol.unit_meas_lookup_code
       FROM po_headers_all poh
           ,po_lines_all  pol
      WHERE 1 = 1
        AND poh.po_header_id = pol.po_header_id
		AND poh.attribute1 = 'NA-POCONV'
        --AND (pol.closed_code = 'OPEN' OR pol.closed_code IS NULL)
        AND poh.last_update_date >= SYSDATE-7
    )
	,locations AS
    (
    SELECT hru.location_id
          ,hrl.location_code
          ,hru.attribute1
          ,hru.organization_id
      FROM hr_all_organization_units hru,
           hr_locations_all hrl
     WHERE hrl.location_id = hru.location_id
       AND hru.attribute1 IS NOT NULL
    )
    SELECT stg.*,
           po_in.item_id,
           po_in.item_description,
           po_in.segment1,
           po_in.po_header_id,
           po_in.line_num,
		   po_in.attribute_category,
		   po_in.unit_meas_lookup_code
	  FROM xx_ap_trade_inv_conv_lines stg
		  LEFT JOIN locations hrl
               ON ltrim(hrl.attribute1,'0') = ltrim(stg.location,'0')
		  LEFT JOIN mtl_system_items_b itm
               ON itm.segment1 = ltrim(stg.sku,'0')
               AND hrl.organization_id = itm.organization_id 
		  LEFT JOIN po_info po_in
               ON ltrim(stg.po_number,'0')||'-'||lpad(ltrim(stg.location,'0'),4,'0') = po_in.segment1
               AND itm.inventory_item_id = po_in.item_id
			   AND hrl.location_id = po_in.ship_to_location_id
	  WHERE stg.record_status = p_status
	    AND stg.invoice_id IS NOT NULL
	ORDER BY stg.invoice_id,
		     stg.invoice_line_id; 
       
    TYPE lines IS TABLE OF lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER; 
	
	l_header_tab 		         HEADER; 
    l_lines_tab 		         LINES; 
    indx                 	     NUMBER;
    l_indx                       NUMBER;
    o_indx			             NUMBER;
    ln_batch_size		         NUMBER := 250;
    lc_error_msg                 VARCHAR2(1000);
    lc_error_loc                 VARCHAR2(100) := 'XX_AP_TRADE_INV_CONV_PKG.load_data_to_interface_table';    
    ln_err_count		         NUMBER;
    ln_error_idx		         NUMBER;
    data_exception               EXCEPTION;
	ln_line_number               NUMBER;
	ln_invoice_id                NUMBER;
    ln_total_records_processed   NUMBER;
    ln_success_records           NUMBER;
    ln_failed_records            NUMBER;
	lc_coa_id                    NUMBER;
	v_ccid                       NUMBER;
	ln_terms_id                  NUMBER;
	lc_terms_name                VARCHAR2(30);
	lc_gl_string                 VARCHAR2(100);
	lc_line_type                 VARCHAR2(100);
	lc_drop_ship_flag            VARCHAR2(1);
	ln_po_terms_id               NUMBER;
	ln_vendor_id                 NUMBER;
	ln_vendor_site_id            NUMBER;
	lc_attr_category             VARCHAR2(100);
	lc_attr_2                    VARCHAR2(10);
	lc_unit_of_measure           VARCHAR2(100);
  	  
BEGIN

    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id; 
    ln_total_records_processed:= 0;
	ln_success_records := 0;
	ln_failed_records := 0;
	lc_unit_of_measure := NULL;
    print_debug_msg ('Start the loading data into Staging table' ,TRUE);

     OPEN header_cur;
       LOOP
	      l_header_tab.DELETE;  --- Deleting the data in the Table type
          FETCH header_cur BULK COLLECT INTO l_header_tab LIMIT ln_batch_size;
          EXIT WHEN l_header_tab.COUNT = 0;
		  
		  ln_total_records_processed := ln_total_records_processed + l_header_tab.COUNT;
		  FOR indx IN l_header_tab.FIRST..l_header_tab.LAST 
          LOOP
             BEGIN                
              -- print_debug_msg ('Insert into ap_invoices_interface - Invoice_id=['||to_char(l_header_tab(indx).invoice_id)||']',FALSE); 
			    
				-- To get the PO Terms ID, Vendor ID and Vendor Site ID
			  	get_po_terms_id(p_po_number      => LTRIM(l_header_tab(indx).po_number,'0')||'-'||LPAD(LTRIM(l_header_tab(indx).location,'0'),4,'0')
						       ,o_terms_id       => ln_po_terms_id
							   ,o_vendor_id      => ln_vendor_id
							   ,o_vendor_site_id => ln_vendor_site_id
							   ,o_attr_category  => lc_attr_category
							   ,o_terms_name     => lc_terms_name
							   );
							   
				-- To check whether the PO is Dropship or not
				IF lc_attr_category IS NULL
				THEN
				    l_header_tab(indx).source     := l_header_tab(indx).source;
					lc_attr_2                     := NULL;
					
				ELSIF lc_attr_category LIKE 'DropShip%'
				THEN
				    IF l_header_tab(indx).source = 'US_OD_TDM'
			        THEN
                        l_header_tab(indx).source     := 'US_OD_DROPSHIP';
			        	lc_attr_2                     := NULL;						
                    ELSIF l_header_tab(indx).source = 'US_OD_TRADE_EDI'
                    THEN
			            l_header_tab(indx).source     := 'US_OD_DROPSHIP';
    		            lc_attr_2                     := 'Y';						
					ELSE
					    l_header_tab(indx).source     := l_header_tab(indx).source;
						lc_attr_2                     := NULL;
			        END IF;
					
				ELSE
				    l_header_tab(indx).source     := l_header_tab(indx).source;
					lc_attr_2                     := NULL;
				END IF;
			  	
                -- To get the Terms ID				
				IF ln_po_terms_id IS NOT NULL
				THEN
					l_header_tab(indx).terms_id := ln_po_terms_id;
				ELSE
					l_header_tab(indx).terms_id := l_header_tab(indx).terms_id_sup;
                END IF;
				
				-- To get the Vendor ID				
				IF ln_vendor_id IS NULL
				THEN
					ln_vendor_id := l_header_tab(indx).vendor_id_sup;
                END IF;
				
				IF l_header_tab(indx).source IS NULL
				THEN
				    l_header_tab(indx).record_status:= 'E';
	       		    l_header_tab(indx).error_description:= 'Source is NULL for the Invoice Number :'||l_header_tab(indx).invoice_number; 
					l_header_tab(indx).error_code := 'Invalid Source';
					l_header_tab(indx).error_flag := 'Y';
				    CONTINUE;
				END IF;
								
				-- Validate the Terms ID
				IF l_header_tab(indx).terms_id IS NULL
				THEN
				    l_header_tab(indx).error_code := 'Invalid Terms :'||' '||lc_terms_name;
					l_header_tab(indx).error_flag := 'Y';
				END IF;
				
				-- Validate the Vendor ID
				IF ln_vendor_id IS NULL
				THEN
				    l_header_tab(indx).error_code := l_header_tab(indx).error_code||' '||'Invalid Vendor';
					l_header_tab(indx).error_flag := 'Y';
				END IF;
				
				-- Validate the Vendor Site ID
				IF l_header_tab(indx).vendor_site_id_sup IS NULL
				THEN
				    l_header_tab(indx).error_code := l_header_tab(indx).error_code||' '||'Invalid Vendor Site :'||' '||l_header_tab(indx).vendor_number;
					l_header_tab(indx).error_flag := 'Y';
				END IF;
				
				-- Validate the Org ID
				IF l_header_tab(indx).org_id <> 404
				THEN
				    l_header_tab(indx).error_code := l_header_tab(indx).error_code||' '||'Invalid Org ID:'||' '||l_header_tab(indx).org_id;
					l_header_tab(indx).error_flag := 'Y';
				END IF;
   
				INSERT INTO ap_invoices_interface( invoice_id ,     
												   invoice_num ,   
												   invoice_type_lookup_code ,  
												   invoice_date ,           
												   po_number ,  
												   vendor_id ,    
												   vendor_num ,  
												   vendor_name , 
												   vendor_site_id ,    
												   vendor_site_code ,  
												   invoice_amount ,        
												   invoice_currency_code,            
												   terms_id ,    
												   terms_name,  
												   description,   
												   last_update_date ,          
												   last_updated_by ,    
												   last_update_login ,     
												   creation_date ,        
												   created_by ,    
												   attribute_category , 
												   attribute1, 
												   attribute2, 
												   attribute3,
												   attribute4,
												   attribute5, 
												   attribute6, 
												   attribute7, 
												   attribute8, 
												   attribute9, 
												   attribute10, 
												   attribute11,
												   attribute12,  
												   attribute13, 
												   attribute14, 
												   attribute15, 
												   global_attribute20, 
												   status,  
												   source,  
												   group_id,   
												   request_id ,           
												   voucher_num,   
												   payment_method_code,   
												   pay_group_lookup_code, 
												   goods_received_date,         
												   invoice_received_date,          
												   gl_date,          
												   accts_pay_code_combination_id,     
												   exclusive_payment_flag,    
												   org_id,    
												   amount_applicable_to_discount,              
												   vendor_email_address,
												   terms_date,         
												   external_doc_ref)
										  VALUES ( l_header_tab(indx).invoice_id,  
												   LTRIM(regexp_replace(l_header_tab(indx).invoice_number , '(*[[:punct:]])', ''),'0'),   
												   DECODE(l_header_tab(indx).invoice_amount_sign,'+','STANDARD','-','CREDIT') ,  -- invoice_type_lookup_code
												   NVL(l_header_tab(indx).invoice_date , SYSDATE), -- invoice_date          
												   LTRIM(l_header_tab(indx).po_number,'0')||'-'||LPAD(LTRIM(l_header_tab(indx).location,'0'),4,'0'), -- po_number
												   ln_vendor_id,  -- vendor_id 
												   null,  -- vendor_num  
												   null, -- l_header_tab(indx).vendor_name,  -- vendor_name 
												   l_header_tab(indx).vendor_site_id_sup,  -- vendor_site_id     
												   null,  -- vendor_site_code  
                                                   DECODE(l_header_tab(indx).invoice_amount_sign,'+',ROUND(l_header_tab(indx).invoice_amount,2),'-', ROUND((-l_header_tab(indx).invoice_amount),2)),	--invoice_amount 											 
												   DECODE(l_header_tab(indx).org_id,404,'USD',NULL),  -- invoice_currency_code           
												   l_header_tab(indx).terms_id ,-- NVL(ln_terms_id,l_header_tab(indx).terms_id_sup),  -- terms_id     
												   NULL, -- lc_terms_name,  -- terms_name  
                                                   LTRIM(l_header_tab(indx).po_number,'0')||' '||LPAD(LTRIM(l_header_tab(indx).location,'0'),4,'0'),	 -- description 
												   sysdate, -- last_update_date           
												   gn_user_id, -- last_updated_by     
												   gn_login_id, -- last_update_login      
												   sysdate, -- creation_date         
												   gn_user_id, -- created_by     
												   null,  -- attribute_category  
												   null,  -- attribute1
												   lc_attr_2,  -- attribute2 
												   null,  -- attribute3
												   null,  -- attribute4
												   null,  -- attribute5 
												   null,  -- attribute6 
												   l_header_tab(indx).source,  -- attribute7 
												   null,  -- attribute8 
												   null, --  DCN Number
                                                   LPAD(l_header_tab(indx).vendor_number,10,'0'),	--  Vendor Site Code											   
												   l_header_tab(indx).po_number, --  PO Number
												   null,  -- attribute12  
												   l_header_tab(indx).voucher_type ,  -- attribute13 
												   null,  -- attribute14 
												   null, --attribute15, -- Release Number 
												   l_header_tab(indx).invoice_amount_sign,  -- global_attribute20 
												   null,  -- status  
												   l_header_tab(indx).source, -- source 
												   DECODE(l_header_tab(indx).source,'US_OD_TDM','TDM-TRADE',null),  --group_id,   
												   gn_request_id,  -- request_id           
												   l_header_tab(indx).po_voucher,  -- voucher_num 
												   l_header_tab(indx).payment_method_lookup_code,  -- payment_method_code ?  
												   l_header_tab(indx).pay_group_lookup_code,  
												   null, -- goods_received_date  ?       
												   null, -- invoice_received_date ?        
												   null, -- gl_date ?         
												   null, -- TO_NUMBER(l_header_tab(indx).ap_liab_acct), -- accts_pay_code_combination_id     
												   null, -- exclusive_payment_flag    
												   l_header_tab(indx).org_id, -- org_id    
												   null, -- amount_applicable_to_discount             
												   null, -- vendor_email_address 
												   l_header_tab(indx).terms_date, -- terms_date     
												   null -- external_doc_ref  
												);
													 
			    ln_success_records  := ln_success_records + 1;
				
				l_header_tab(indx).record_status := 'C';
				l_header_tab(indx).error_description := NULL;	
            EXCEPTION
			  WHEN OTHERS
			  THEN
			    ROLLBACK;
				ln_failed_records := ln_failed_records +1;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
                print_debug_msg ('Invoice_id=['||to_char(l_header_tab(indx).invoice_id)||'], RB, '||lc_error_msg,FALSE);
                l_header_tab(indx).record_status := 'E';
                l_header_tab(indx).error_description :='Unable to insert the record into ap_invoices_interface table for the invoice_id :'||l_header_tab(indx).invoice_id||' '||lc_error_msg;
			END;
          END LOOP; --l_header_tab
		  
          BEGIN
	        print_debug_msg('Starting update of xx_ap_trade_inv_hdr #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	  FORALL indx IN 1..l_header_tab.COUNT
	       	  SAVE EXCEPTIONS
   		        UPDATE xx_ap_trade_inv_conv_hdr
	       		   SET record_status = l_header_tab(indx).record_status
	       		      ,error_description = l_header_tab(indx).error_description 
					  ,error_code = l_header_tab(indx).error_code 
					  ,error_flag = l_header_tab(indx).error_flag 
	     		      ,last_update_date  = sysdate
	                  ,last_updated_by   = gn_user_id
	                  ,last_update_login = gn_login_id
	       	     WHERE invoice_id = l_header_tab(indx).invoice_id;
				COMMIT;
	       EXCEPTION
	          WHEN OTHERS 
			  THEN
	          print_debug_msg('Bulk Exception raised',FALSE);
	          ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	          FOR i IN 1..ln_err_count
	          LOOP
	             ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	             lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	             print_debug_msg('Invoice_id=['||to_char(l_header_tab(ln_error_idx).invoice_id)||'], Error msg=['||lc_error_msg||']',TRUE);
	          END LOOP; -- bulk_err_loop FOR UPDATE
	       END;
	       print_debug_msg('Ending Update of xx_ap_trade_inv_conv_hdr #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
		   		   
      END LOOP; --header_cur
    COMMIT;   
    CLOSE header_cur;
	
	--========================================================================
		-- Updating the OUTPUT FILE
	--========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed for Header Table:: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully for Header Table :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed for Header Table:: '||ln_failed_records);
	    FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));

	-- Processing records for lines table
	ln_total_records_processed:= 0;
	ln_success_records := 0;
	ln_failed_records := 0;
	
	ln_line_number := 0;
	ln_invoice_id  := NULL;
	lc_coa_id      := NULL;
	lc_drop_ship_flag := NULL;
	
    OPEN lines_cur;
       LOOP
	      l_lines_tab.DELETE;  --- Deleting the data in the Table type
          FETCH lines_cur BULK COLLECT INTO l_lines_tab LIMIT ln_batch_size;
          EXIT WHEN l_lines_tab.COUNT = 0;
		  
		  ln_total_records_processed := ln_total_records_processed + l_lines_tab.COUNT;
		  FOR l_indx IN l_lines_tab.FIRST..l_lines_tab.LAST 
          LOOP
             BEGIN  
			 IF ln_invoice_id = l_lines_tab(l_indx).invoice_id
             THEN
			    ln_line_number := ln_line_number+1;
			 ELSE
			    ln_line_number := 1;
				ln_invoice_id := l_lines_tab(l_indx).invoice_id;
			 END IF;	   
			
			IF l_lines_tab(l_indx).source IS NULL
				THEN
				    l_lines_tab(l_indx).record_status:= 'E';
	       		    l_lines_tab(l_indx).error_description:= 'Source is NULL for the Invoice Number :'||l_lines_tab(l_indx).invoice_number; 
					l_lines_tab(l_indx).error_code := 'Invalid Source';
					l_lines_tab(l_indx).error_flag := 'Y';
				    CONTINUE;
			END IF;

			-- Validate PO Number
			IF l_lines_tab(l_indx).segment1 IS NULL 
			THEN
				l_lines_tab(l_indx).error_code := 'Invalid PO Number :'||ltrim(l_lines_tab(l_indx).po_number,'0')||'-'||lpad(ltrim(l_lines_tab(l_indx).location,'0'),4,'0');
				l_lines_tab(l_indx).error_flag := 'Y';
			END IF;
			
			-- SKU is missing in the PO
			IF    l_lines_tab(l_indx).item_id IS NULL 
			  AND l_lines_tab(l_indx).line_type = 'ITEM'
			THEN
				l_lines_tab(l_indx).error_code := l_lines_tab(l_indx).error_code ||' '||'SKU is missing in the PO';
				l_lines_tab(l_indx).error_flag := 'Y';
			END IF;
						
			-- PO Line Number is missing in the PO
			IF    l_lines_tab(l_indx).line_num IS NULL 
			  AND l_lines_tab(l_indx).line_type = 'ITEM'
			THEN
			    l_lines_tab(l_indx).error_code := l_lines_tab(l_indx).error_code ||' '||'PO Line Number is missing in the PO ';
				l_lines_tab(l_indx).error_flag := 'Y';
				l_lines_tab(l_indx).line_type := 'MISCELLANEOUS';
				l_lines_tab(l_indx).reason_code := 'ND';
				l_lines_tab(l_indx).item_id := NULL;
				l_lines_tab(l_indx).invoice_quantity := NULL;
				l_lines_tab(l_indx).unit_price := NULL;
			END IF;
									
			
            -- To get the GL Account for the below lines
            IF l_lines_tab(l_indx).line_type <> 'ITEM' -- Line Type is not an "ITEM" line type
	        THEN
			    -- Checking if the PO is Dropship or not			
			    BEGIN
		            SELECT attribute_category
		              INTO l_lines_tab(l_indx).attribute_category
		              FROM po_headers_all
			         WHERE segment1 = ltrim(l_lines_tab(l_indx).po_number,'0')||'-'||lpad(ltrim(l_lines_tab(l_indx).location,'0'),4,'0');
		        EXCEPTION
		        WHEN OTHERS
		        THEN
		            l_lines_tab(l_indx).attribute_category := NULL;
		        END;
			    		
			    IF l_lines_tab(l_indx).attribute_category LIKE 'DropShip%'
	            THEN
		            lc_drop_ship_flag := 'Y';
	            ELSE 
		            lc_drop_ship_flag := 'N';
	            END IF;
			    
				-- To get the GL Account for the below lines
                BEGIN
	        	 l_lines_tab(l_indx).gl_inter_company  := '0000';
	        	 l_lines_tab(l_indx).gl_future         := '000000' ;
                 SELECT target_value4,
                        target_value5,
                        target_value6,
                        target_value7,
                        target_value8,
						target_value2
                   INTO l_lines_tab(l_indx).gl_company,
                        l_lines_tab(l_indx).gl_cost_center,
                        l_lines_tab(l_indx).gl_account,
                        l_lines_tab(l_indx).gl_location,
                        l_lines_tab(l_indx).gl_lob,
						l_lines_tab(l_indx).line_description
                  FROM xx_fin_translatevalues
                 WHERE translate_id IN (SELECT translate_id 
                						  FROM xx_fin_translatedefinition 
                						 WHERE translation_name = 'OD_AP_REASON_CD_ACCT_MAP' 
                							   AND enabled_flag = 'Y')
                	   AND target_value1 = DECODE(l_lines_tab(l_indx).reason_code,'FR',DECODE(lc_drop_ship_flag,'Y','FS','FR'),l_lines_tab(l_indx).reason_code);
					   
                EXCEPTION
                WHEN OTHERS
                THEN
                    l_lines_tab(l_indx).gl_company        := NULL;
                    l_lines_tab(l_indx).gl_cost_center    := NULL;
                    l_lines_tab(l_indx).gl_account        := NULL;
                    l_lines_tab(l_indx).gl_location       := NULL;
                    l_lines_tab(l_indx).gl_lob            := NULL;
	        		l_lines_tab(l_indx).gl_inter_company  := NULL;
	        		l_lines_tab(l_indx).gl_future         := NULL;
                END;
	        END IF; 
			
			-- To get the GL String for the below lines
			v_ccid := NULL;
			lc_gl_string := NULL;
			IF l_lines_tab(l_indx).line_type <> 'ITEM' -- Line Type is not an "ITEM" line type
	        THEN
			    BEGIN
				   SELECT /*+ cardinality(poh 1) INDEX(GL_CODE_COMBINATIONS XX_GL_CODE_COMBINATIONS_N8) */
				          gcck.code_combination_id, 
                          gcck.concatenated_segments 
                     INTO v_ccid,
                          lc_gl_string
                     FROM po_headers_all poh,
                          po_lines_all pol,
                          po_distributions_all pod,
                          gl_code_combinations_kfv gcck
                    WHERE poh.po_header_id = pol.po_header_id
                      AND poh.po_header_id = pod.po_header_id
                      AND pol.po_line_id = pod.po_line_id
                      AND pod.code_combination_id = gcck.code_combination_id 
                      AND poh.segment1 = ltrim(l_lines_tab(l_indx).po_number,'0')||'-'||lpad(ltrim(l_lines_tab(l_indx).location,'0'),4,'0')
                      AND rownum = 1;
			    EXCEPTION
				   WHEN NO_DATA_FOUND
				   THEN
				       v_ccid := NULL;
				       lc_gl_string := NULL;
					   print_debug_msg ('No GL String found :',FALSE); 
				   WHEN OTHERS 
                   THEN
				       v_ccid := NULL;
				       lc_gl_string := NULL;
				       print_debug_msg ('Error Message :'||SUBSTR(SQLERRM,1,255),FALSE); 
                END;
			END IF;	
			
			-- To get the Invoice Unit of Measure
			IF l_lines_tab(l_indx).uom IS NOT NULL
			THEN
                BEGIN
					SELECT unit_of_measure
                      INTO lc_unit_of_measure
                      FROM mtl_units_of_measure
                     WHERE uom_code = l_lines_tab(l_indx).uom;
				EXCEPTION
				WHEN OTHERS
				THEN
					lc_unit_of_measure := NULL;
				END;
            END IF;								
            print_debug_msg ('Insert into ap_invoice_lines_interface - Invoice_id=['||l_lines_tab(l_indx).invoice_line_id||']',FALSE); 
	        INSERT INTO ap_invoice_lines_interface(   invoice_id                   ,  
													  invoice_line_id              ,  
													  line_number                  ,  
													  line_type_lookup_code        ,  
													  line_group_number            ,  
													  amount                       ,  
													  accounting_date              ,  
													  description                  , 
													  prorate_across_flag          ,  
													  tax_code                     ,  
													  po_header_id                 ,  
													  po_number                    ,  
													  po_line_id                   ,  
													  po_line_number               ,  
													  po_distribution_num          ,  
													  po_unit_of_measure           ,  
													  inventory_item_id            ,  
													  item_description             ,
													  quantity_invoiced            ,  
													  ship_to_location_code        ,  
													  unit_price                   ,   
													  dist_code_concatenated       ,
													  dist_code_combination_id     ,  
													  last_updated_by              ,  
													  last_update_date             ,  
													  last_update_login            ,  
													  created_by                   ,  
													  creation_date                ,  
													  attribute_category           , 
													  attribute1                   , 
													  attribute2                   , 
													  attribute3                   , 
													  attribute4                   , 
													  attribute5                   , 
													  attribute6                   , 
													  attribute7                   , 
													  attribute8                   , 
													  attribute9                   , 
													  attribute10                  , 
													  attribute11                  , 
													  attribute12                  , 
													  attribute13                  , 
													  attribute14                  , 
													  attribute15                  , 
													  unit_of_meas_lookup_code     ,
													  account_segment              ,  
													  balancing_segment            ,  
													  cost_center_segment          ,  
													  project_id                   ,  
													  task_id                      ,  
													  expenditure_type             ,  
													  expenditure_item_date        ,  
													  expenditure_organization_id  ,  
													  org_id                       ,  
													  receipt_number               ,  
													  receipt_line_number          ,  
													  match_option                 ,  
													  tax_code_id                  ,  
													  external_doc_line_ref        )
                                          VALUES     (l_lines_tab(l_indx).invoice_id, -- invoice_id                     
												      l_lines_tab(l_indx).invoice_line_id, -- invoice_line_id         
													  ln_line_number, --line_number    
													  l_lines_tab(l_indx).line_type, -- lc_line_type, -- , -- line_type_lookup_code          
													  null, -- line_group_number     
													  DECODE(l_lines_tab(l_indx).invoice_line_amount_sign,'+',ROUND(TO_NUMBER(l_lines_tab(l_indx).invoice_line_amount),2),'-',ROUND( -TO_NUMBER(l_lines_tab(l_indx).invoice_line_amount),2)),	--invoice_line_amount 	
													  null, -- accounting_date 
													  l_lines_tab(l_indx).line_description, -- description  
													  null, -- prorate_across_flag           
													  null, -- tax_code                       
													  null, -- po_header_id                   
													  null, -- po_number                      
													  null, -- po_line_id                     
													  DECODE(l_lines_tab(l_indx).line_type,'ITEM',NVL(l_lines_tab(l_indx).line_num, TO_NUMBER(l_lines_tab(l_indx).po_line_number)),NULL), -- po_line_number                            
													  null, -- po_distribution_num            
													  null, -- po_unit_of_measure             
													  l_lines_tab(l_indx).item_id, -- inventory_item_id              
													  l_lines_tab(l_indx).item_description, -- item_description             
													  TO_NUMBER(l_lines_tab(l_indx).invoice_quantity), -- quantity_invoiced              
													  null, -- ship_to_location_code          
													  TO_NUMBER(l_lines_tab(l_indx).unit_price), -- unit_price 
                                                    /* DECODE(l_lines_tab(l_indx).line_type,
                                                             'ITEM',
                                                             null,															 
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_company,1,4), SUBSTR(lc_gl_string,1,4))||'.'||  
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_cost_center,1,5), SUBSTR(lc_gl_string,6,5))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_account,1,8), SUBSTR(lc_gl_string,12,8))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_location,1,6), SUBSTR(lc_gl_string,21,6))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_inter_company,1,4), SUBSTR(lc_gl_string,28,4))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_lob,1,2), SUBSTR(lc_gl_string,33,2))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_future,1,6), SUBSTR(lc_gl_string,36,6))
															 ), --dist_code_concatenated 
													*/ -- Commented as per Version 1.1
                                                      DECODE(l_lines_tab(l_indx).line_type,
                                                             'ITEM',
                                                             null,															 
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_company,1,4),SUBSTR(lc_gl_string,1,4))||'.'||  
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_cost_center,1,5),SUBSTR(lc_gl_string,6,5))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_account,1,8),SUBSTR(lc_gl_string,12,8))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_location,1,6),SUBSTR(lc_gl_string,21,6))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_inter_company,1,4),SUBSTR(lc_gl_string,28,4))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_lob,1,2),SUBSTR(lc_gl_string,33,2))||'.'||
															 NVL(SUBSTR(l_lines_tab(l_indx).gl_future,1,6),SUBSTR(lc_gl_string,36,6))
															 ), --dist_code_concatenated 
													  -- v_ccid, -- dist_code_combination_id -- Commented as per Version 1.1	 
													  NULL, --  dist_code_combination_id                   
													  gn_user_id, -- last_updated_by               
													  sysdate,    -- last_update_date              
													  gn_user_id, -- last_update_login             
													  gn_user_id, -- created_by              
													  sysdate, -- creation_date            
													  null, -- attribute_category            
													  null, -- attribute1                    
													  null, -- attribute2                    
													  null, -- attribute3                    
													  DECODE(l_lines_tab(l_indx).line_type,'ITEM',lc_unit_of_measure,NULL), -- attribute4 -- Invoice Unit of Measure                   
													  null, -- attribute5                    
													  null, -- attribute6                    
													  null, -- attribute7                    
													  null, -- attribute8                    
													  null, -- attribute9                    
													  null, -- attribute10                   
													  l_lines_tab(l_indx).reason_code, -- attribute11                   
													  null, -- attribute12                   
													  null, -- attribute13                   
													  null, -- attribute14                   
													  null, -- attribute15 
													  l_lines_tab(l_indx).unit_meas_lookup_code, -- PO Unit of Measure
													  null, -- account_segment           
													  null, -- balancing_segment     
													  null, -- cost_center_segment  
													  null, -- project_id   
													  null, -- task_id     
													  null, -- expenditure_type   
													  null, -- expenditure_item_date          
													  null, -- expenditure_organization_id           
													  null, -- org_id                         
													  null, -- receipt_number                 
													  null, -- receipt_line_number            
													  null, -- match_option                         
													  null, -- tax_code_id                             
													  null  -- external_doc_line_ref													  
											         );								
	            ln_success_records  := ln_success_records + 1;
				
				l_lines_tab(l_indx).record_status := 'C';
				l_lines_tab(l_indx).error_description := NULL;	
            EXCEPTION
			  WHEN OTHERS
			  THEN
			    ROLLBACK;
				ln_failed_records  := ln_failed_records + 1;
                lc_error_msg := SUBSTR(sqlerrm,1,100);
                print_debug_msg ('Invoice_line_id=['||to_char(l_lines_tab(l_indx).invoice_line_id)||'], RB, '||lc_error_msg,FALSE);
                l_lines_tab(l_indx).record_status := 'E';
                l_lines_tab(l_indx).error_description :='Unable to insert the record into ap_invoice_lines_interface table for the invoice_line_id :'||l_lines_tab(l_indx).invoice_line_id||' '||lc_error_msg;
			END;
          END LOOP; --l_lines_tab
		  
          BEGIN
	        print_debug_msg('Starting update of xx_ap_trade_inv_conv_lines #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
	       	  FORALL l_indx IN 1..l_lines_tab.COUNT
	       	  SAVE EXCEPTIONS
   		        UPDATE xx_ap_trade_inv_conv_lines
	       		   SET record_status = l_lines_tab(l_indx).record_status
	       		      ,error_description = l_lines_tab(l_indx).error_description 
					  ,error_code = l_lines_tab(l_indx).error_code 
					  ,error_flag = l_lines_tab(l_indx).error_flag
	     		      ,last_update_date  = sysdate
	                  ,last_updated_by   = gn_user_id
	                  ,last_update_login = gn_login_id
	       	     WHERE invoice_line_id = l_lines_tab(l_indx).invoice_line_id;
				COMMIT;
	       EXCEPTION
	          WHEN OTHERS 
			  THEN
	          print_debug_msg('Bulk Exception raised',FALSE);
	          ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
	          FOR i IN 1..ln_err_count
	          LOOP
	             ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
	             lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
	             print_debug_msg('Invoice_line_id=['||to_char(l_lines_tab(ln_error_idx).invoice_line_id)||'], Error msg=['||lc_error_msg||']',TRUE);
	          END LOOP; -- bulk_err_loop FOR UPDATE
	       END;
	       print_debug_msg('Ending Update of xx_ap_trade_inv_conv_lines #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'),FALSE);
		   		   
      END LOOP; --lines_cur
    COMMIT;   
    CLOSE lines_cur;
	
	--========================================================================
		-- Updating the OUTPUT FILE
	--========================================================================
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed for Line Table:: '||ln_total_records_processed);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully for Line Table :: '||ln_success_records);
    FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed for Line Table:: '||ln_failed_records);

EXCEPTION
WHEN OTHERS
THEN
    p_retcode := 2;
  	lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('ERROR Loading data to staging procedure - '||lc_error_msg,TRUE);
    log_exception ('XX_AP_TRADE_INV_CONV_PKG.load_data_to_staging',
                   lc_error_loc,
		           lc_error_msg);
END load_data_to_interface_table; 
    
-- +============================================================================================+
-- |  Name	 : load_staging                                                                     |                 	
-- |  Description: This procedure reads data from the file and inserts into staging tables      |
-- =============================================================================================|
PROCEDURE load_staging(p_errbuf         OUT  VARCHAR2
                      ,p_retcode        OUT  VARCHAR2
                      ,p_filepath       IN   VARCHAR2
                      ,p_file_name 	    IN   VARCHAR2
                      ,p_debug          IN   VARCHAR2)
AS

-- Cursor to get the lines details from the Lines staging table 			 
  CURSOR lines_cur
  IS
    SELECT invoice_id ,           
	       vendor_name ,    
	       vendor_number ,  
	       invoice_number , 
	       po_voucher ,     
	       invoice_date ,   
	       po_number ,      
	       location ,       
		   invoice_amount,
           invoice_amount_sign,
           -- terms,
		   null dcn_number,
           source          	       
	  FROM xx_ap_trade_inv_conv_lines a
	 WHERE record_status = 'N'
	GROUP BY invoice_id ,         
	         vendor_name ,    
	         vendor_number ,  
	         invoice_number , 
	         po_voucher ,     
	         invoice_date ,   
	         po_number ,      
	         location ,       
			 invoice_amount_sign,
			 invoice_amount,
			-- terms,
			-- dcn_number
             source
;
			 
   TYPE lines IS TABLE OF lines_cur%ROWTYPE
    INDEX BY PLS_INTEGER; 
	
   l_lines_tab 		  LINES; 
   l_indx             NUMBER;
   ln_batch_size	  NUMBER := 250;
   ln_err_count		  NUMBER;
   ln_error_idx		  NUMBER;      
   l_filehandle       UTL_FILE.FILE_TYPE;
   lc_filedir         VARCHAR2(30) := p_filepath;
   lc_filename	      VARCHAR2(200):= p_file_name;
   lc_dirpath         VARCHAR2(500);
   lb_file_exist      BOOLEAN;
   ln_size            NUMBER;
   ln_block_size      NUMBER;
   lc_newline         VARCHAR2(4000);  -- Input line
   ln_max_linesize    BINARY_INTEGER  := 32767;
   ln_rec_cnt         NUMBER := 0;
   l_table 	          varchar2_table;
   l_hdr_table        varchar2_table;
   l_line_table       varchar2_table;
   lc_error_msg       VARCHAR2(1000) := NULL;
   lc_error_loc	      VARCHAR2(2000) := 'XX_AP_TRADE_INV_CONV_PKG.LOAD_STAGING';
   lc_errcode	      VARCHAR2(3)    := NULL;
   lc_rec_type        VARCHAR2(1)    := NULL;
   ln_count_hdr       NUMBER := 0;
   ln_count_lin       NUMBER := 0;
   ln_count_err       NUMBER := 0;
   ln_count_tot       NUMBER := 0; 
   ln_conc_file_copy_request_id  NUMBER;
   lc_dest_file_name  VARCHAR2(200);
   nofile             EXCEPTION;
   data_exception     EXCEPTION;
   ln_invoice_id      NUMBER;
   l_nfields          NUMBER;
   lc_prev_inv_num    VARCHAR2(30);
   lc_invoice_number  VARCHAR2(30);
   lc_vendor_number   VARCHAR2(30);
   lc_prev_vendor_num VARCHAR2(30);
   lc_source          VARCHAR2(30);
   lc_prev_source     VARCHAR2(30);
   lc_po_voucher      VARCHAR2(30);
   lc_prev_po_voucher VARCHAR2(30);
      
   CURSOR get_dir_path
   IS
      SELECT directory_path
        FROM all_directories
       WHERE directory_name = p_filepath;
   
BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;
	 
	  print_debug_msg ('Start reading the data from File:'||p_file_name||' Path:'||p_filepath,TRUE);
		-- To check whether the file exists or not
		UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
		IF NOT lb_file_exist THEN
		   RAISE nofile;
		END IF;
        
		-- Open the Invoice lines file
		l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',ln_max_linesize);
		
		print_debug_msg ('File open successfull',TRUE);
		
		lc_prev_inv_num    := '-1';
		lc_prev_vendor_num := '-1';
		lc_prev_source     := '-1';
		lc_prev_po_voucher := '-1';
		ln_invoice_id      := NULL;

		LOOP
		   BEGIN
			  UTL_FILE.GET_LINE(l_filehandle,lc_newline);
			  IF lc_newline IS NULL THEN
				 exit;
              END IF;
		  
		   print_debug_msg ('Processing Line:'||lc_newline,FALSE);
		   
		  --parse the line
		   parse(lc_newline,l_table,l_nfields,'|',lc_error_msg,lc_errcode);
		   IF lc_errcode = '2' THEN
			  RAISE data_exception;
		   END IF;
		   ln_count_tot := ln_count_tot +1;
		   		   
		   lc_invoice_number := l_table(5);
		   lc_vendor_number  := l_table(4);
		   lc_source         := l_table(30);
		   lc_po_voucher     := l_table(6);
	
		   IF lc_prev_inv_num <> lc_invoice_number OR lc_prev_vendor_num <> lc_vendor_number OR  lc_prev_source <> lc_source OR lc_prev_po_voucher <> lc_po_voucher
		   THEN
              lc_prev_inv_num    := lc_invoice_number;
			  lc_prev_vendor_num := lc_vendor_number;
			  lc_prev_source     := lc_source;
			  lc_prev_po_voucher := lc_po_voucher;
			  
			  SELECT ap_invoices_interface_s.nextval
				INTO ln_invoice_id
				FROM DUAL;						   
		   END IF;
		   
		   print_debug_msg ('Insert Line',FALSE);
		   
			insert_line(l_table,ln_invoice_id,lc_error_msg,lc_errcode);
   	         IF lc_errcode = '2' 
			 THEN
	           RAISE data_exception;
	         END IF;
			ln_count_lin := ln_count_lin + 1;
			  
		   EXCEPTION
		   WHEN no_data_found THEN
			  exit;
		   END;
		END LOOP;
		UTL_FILE.FCLOSE(l_filehandle);
	 COMMIT; 
	 
	-- Creating the header record
	 OPEN lines_cur;
	 LOOP
	   l_lines_tab.DELETE;  --- Deleting the data in the Table type
	   FETCH lines_cur BULK COLLECT INTO l_lines_tab LIMIT ln_batch_size;
       EXIT WHEN l_lines_tab.COUNT = 0;
	   FOR l_indx IN l_lines_tab.FIRST..l_lines_tab.LAST 
       LOOP
           BEGIN
			 
		      l_table(1) := l_lines_tab(l_indx).invoice_id;
		      l_table(2) := NULL; -- l_lines_tab(l_indx).company;
		      l_table(3) := NULL; -- l_lines_tab(l_indx).bth;
		      l_table(4) := l_lines_tab(l_indx).vendor_name;
		      l_table(5) := l_lines_tab(l_indx).vendor_number;
		      l_table(6) := l_lines_tab(l_indx).invoice_number;
		      l_table(7) := l_lines_tab(l_indx).po_voucher;
		      l_table(8) := l_lines_tab(l_indx).invoice_date;
		      l_table(9) := l_lines_tab(l_indx).po_number;
		      l_table(10):= LTRIM(l_lines_tab(l_indx).location,'0');
		      l_table(11):= NULL; -- l_lines_tab(l_indx).due_date;
		      l_table(12):= to_char(l_lines_tab(l_indx).invoice_amount);
		      l_table(13):= NULL;
		      l_table(14):= l_lines_tab(l_indx).invoice_amount_sign;
		      l_table(15):= NULL; -- l_lines_tab(l_indx).terms;
		      l_table(16):= l_lines_tab(l_indx).source;
		      l_table(17):= l_lines_tab(l_indx).dcn_number;
			  
		   print_debug_msg ('Insert Header',FALSE);
		   insert_header(l_table,lc_error_msg,lc_errcode);
   	         IF lc_errcode = '2' 
			 THEN
	           RAISE data_exception;
	         END IF;
			 ln_count_hdr := ln_count_hdr + 1;

		   EXCEPTION
		   WHEN OTHERS 
		   THEN
		       print_debug_msg ('Error Message:'||SQLERRM,FALSE);
		   END;
	   END LOOP; --l_lines_tab

	 END LOOP; --lines_cur
     COMMIT;   
     CLOSE lines_cur;
    
	print_out_msg(' ');
    print_debug_msg(to_char(ln_count_tot)||' records successfully loaded into the Header Table',TRUE); 
    
    print_out_msg('============================================================================== ');
    print_out_msg('No. of header records loaded in the Prestaging table:'||to_char(ln_count_hdr));
    print_out_msg('No. of line records loaded in the Prestaging table :'||to_char(ln_count_lin));
    print_out_msg(' ');
    print_out_msg('Total No. of records loaded in the Prestaging table:'||to_char(ln_count_tot));  
    dbms_lock.sleep(5);
    
    /*	
    print_debug_msg('Calling the Common File Copy to move the Inbound file to Archive folder',TRUE);
    OPEN get_dir_path;
    FETCH get_dir_path INTO lc_dirpath;
    CLOSE get_dir_path;
    
    lc_dest_file_name := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
                                               || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.csv';
                                               
    ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
      					                       'XXCOMFILCOPY',
      					   		       '',
      							       '',
      							       FALSE,
      							       lc_dirpath||'/'||lc_filename,   --Source File Name
      							       lc_dest_file_name,              --Dest File Name
      							       '',
      							       '',
      							       'Y'   --Deleting the Source File
							      );    
    
    COMMIT; 
    */

EXCEPTION
   WHEN nofile 
   THEN
       print_debug_msg ('ERROR - File not exists',TRUE);
       p_retcode := 2;
   WHEN data_exception
   THEN
       ROLLBACK;
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg('Error at line:'||lc_newline,TRUE);
       p_errbuf  := lc_error_msg;
       p_retcode := lc_errcode;
   WHEN UTL_FILE.INVALID_OPERATION
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Invalid Operation',TRUE);
       p_retcode:=2;
   WHEN UTL_FILE.INVALID_FILEHANDLE
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Invalid File Handle',TRUE);
       p_retcode := 2;
   WHEN UTL_FILE.READ_ERROR
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Read Error',TRUE);
       p_retcode := 2;
   WHEN UTL_FILE.INVALID_PATH
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Invalid Path',TRUE);
       p_retcode := 2;
   WHEN UTL_FILE.INVALID_MODE
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Invalid Mode',TRUE);
       p_retcode := 2;
   WHEN UTL_FILE.INTERNAL_ERROR
   THEN
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - Internal Error',TRUE);
       p_retcode := 2;
   WHEN OTHERS
   THEN
       ROLLBACK;
       UTL_FILE.FCLOSE(l_filehandle);
       print_debug_msg ('ERROR - '||substr(sqlerrm,1,250),TRUE);
       p_retcode := 2;
 END load_staging; 
 
END XX_AP_TRADE_INV_CONV_PKG;
/
SHOW ERRORS;