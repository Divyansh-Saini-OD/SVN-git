CREATE OR REPLACE 
PACKAGE XX_AR_OPSTECH_EBILL_PKG
AS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Providge Consulting                                      |
  ---+============================================================================================+
  ---|    Application     :       AR                                                              |
  ---|                                                                                            |
  ---|    Name           :        XX_AR_OPSTECH_EBILL_PKG.pks                                     |
  ---|                                                                                            |
  ---|    Description   :        Generate text file from Oracle AR to OD's Ebill Central System   |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             20-AUG-2018       Aniket J           Initial Version                    |
  ---+============================================================================================+
  
  g_pkg_name            VARCHAR2(30) :='XX_AR_OPSTECH_EBILL_PKG';
  g_pks_version         NUMBER(2,1)  :='1.1';
  g_as_of_date          DATE 		 := NULL; 
  g_debug_flag 			BOOLEAN ;     
  g_discount            NUMBER 		 :=0; 
  g_misc_charges        NUMBER       :=0;
  g_delivery            NUMBER       :=0;
  g_coupon              NUMBER       :=0;
  ln_write_off_amt_low  NUMBER       := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW'); 
  ln_write_off_amt_high NUMBER       := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH'); 

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : xx_ops_update_status                                                |
-- | Description : Update the status on stg table                                      |
-- |Parameters   : p_ship_to_site_use_id                                               |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+                               

	PROCEDURE xx_ops_update_status (  p_errormsg        IN  VARCHAR2 ,
									  p_ar_cons_prcss   IN  VARCHAR2 ,
									  p_request_id      IN  NUMBER,
									  p_cust_acct_id    IN  NUMBER,
									  p_err_level       IN  VARCHAR2
								   );
							  
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_ship_to_name                                                    |
-- | Description : This function is used to build the ship to name from site use id    |
-- |Parameters   : p_ship_to_site_use_id                                               |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+                             
                          
	PROCEDURE xx_opstech_ebill_main(    x_error_buff      OUT  NOCOPY    VARCHAR2
									   ,x_ret_code        OUT  NOCOPY    VARCHAR2
									   ,p_file_path       IN             VARCHAR2
									   ,p_as_of_date      IN             VARCHAR2
									   ,p_debug_flag      IN             VARCHAR2
									);

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_ship_to_name                                                    |
-- | Description : This function is used to build the ship to name from site use id    |
-- |Parameters   : p_ship_to_site_use_id                                               |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+    

	FUNCTION get_cust_name(
		p_account_id IN NUMBER)
	  RETURN VARCHAR2 ; 

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_inv_amounts                                                     |
-- | Description : This function is used to get INV amounts from trx id and type       |
-- |Parameters   : p_in_amt_type, p_in_cust_trx_id                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+    
	  
	FUNCTION get_orig_inv_num(
		p_in_ord_hdr_id IN NUMBER )
	  RETURN NUMBER  ;


-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_orig_inv_num                                                    |
-- | Description : This function is used to get Orig inv for Creditt Memo              |
-- |Parameters   : p_in_ord_hdr_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Aniket J                Initial draft version               |
-- +===================================================================================+  

	FUNCTION get_inv_amounts(
		p_in_cust_trx_id IN NUMBER ,
		p_in_amt_type    IN VARCHAR2 )
	  RETURN NUMBER; 

--Record types   
  
	TYPE HEADER_REC_TYPE
	IS
	  RECORD
	  (
		trx_number ar_invoice_header_v.trx_number%TYPE ,
		billing_site_id ar_cons_inv.site_use_id%TYPE ,
		term_id ar_cons_inv.term_id%TYPE ,
		cons_inv_id ar_cons_inv.cons_inv_id%TYPE ,
		cons_billing_number ar_cons_inv.cons_billing_number%TYPE ,
		customer_trx_id ar_invoice_header_v.customer_trx_id%TYPE ,
		orig_system_reference hz_cust_accounts.orig_system_reference%TYPE ,
		site_use_code hz_cust_site_uses.site_use_code%TYPE ,
		purchase_order_number ar_invoice_header_v.purchase_order_number%TYPE ,
		bill_to_customer_number ar_invoice_header_v.bill_to_customer_number%TYPE ,
		cut_off_date ar_cons_inv.cut_off_date%TYPE ,
		bill_to_date varchar2(100) , 
		due_date varchar2(100)  , 
		name ra_terms_tl.name%TYPE ,
		interface_header_attribute2 ar_invoice_header_v.interface_header_attribute2%TYPE ,
		tax_registration_number ar_invoice_header_v.tax_registration_number%TYPE ,     
		ship_to_contact varchar2(50 byte) ,
		trx_date ar_invoice_header_v.trx_date%type ,
		SHIP_TO_LOCATION AR_INVOICE_HEADER_V.SHIP_TO_LOCATION%type ,
		account_name hz_cust_accounts.account_name%type,
		org_id ar_invoice_header_v.org_id%TYPE ,
		extension_id xx_cdh_a_ext_billdocs_v.extension_id%TYPE ,
		customer_id ar_cons_inv.customer_id%TYPE ,
		ordsourcecd ar_invoice_header_v.interface_header_attribute1%TYPE ,
		specl_handlg_cd xx_cdh_a_ext_billdocs_v.BILLDOCS_SPECIAL_HANDLING%TYPE ,
		billing_term xx_cdh_cust_acct_ext_b.c_ext_attr14%TYPE ,
		invoice_date ra_customer_trx_all.trx_date%TYPE ,
		billing_id hz_cust_accounts.account_number%TYPE ,
		cust_doc_id NUMBER   ,
		creation_date DATE   ,
		cust_account_id xx_cdh_cust_acct_ext_b.cust_account_id%TYPE ,
		c_ext_attr14   xx_cdh_cust_acct_ext_b.c_ext_attr14%TYPE ,
		c_ext_attr3    xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE 
	  );

	TYPE LINE_REC_TYPE
	IS
	  RECORD
	(
		customer_trx_id                       ar_cons_inv_trx_lines_all.customer_trx_id%TYPE,
		customer_trx_line_id                  ar_cons_inv_trx_lines_all.customer_trx_line_id%TYPE,
		line_number                           ar_cons_inv_trx_lines_all.line_number%TYPE,
		inventory_item_id                     mtl_system_items_b.segment1%TYPE,
		description                           ar_cons_inv_trx_lines_all.description %TYPE,   
		uom_code                              ar_cons_inv_trx_lines_all.uom_code%TYPE, 
		quantity_invoiced                     ar_cons_inv_trx_lines_all.quantity_invoiced%TYPE,
		unit_selling_price                    ar_cons_inv_trx_lines_all.unit_selling_price%TYPE,
		extended_amount                       ar_cons_inv_trx_lines_all.extended_amount%TYPE,
		tax_amount                            ar_cons_inv_trx_lines_all.tax_amount%TYPE,
		org_id                                ar_cons_inv_trx_lines_all.org_id%TYPE
	);

 	 
  END XX_AR_OPSTECH_EBILL_PKG;
/
SHOW ERRORS;
EXIT;