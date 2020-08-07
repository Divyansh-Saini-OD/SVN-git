CREATE OR REPLACE 
PACKAGE XX_AR_OPSTECH_REPRINT_PKG
AS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Provide Consulting                                       |
  ---+============================================================================================+
  ---|    Application     :       AR                                                              |
  ---|                                                                                            |
  ---|    Name           :        XX_AR_OPSTECH_REPRINT_PKG.pks                                   |
  ---|                                                                                            |
  ---|    Description   :        Generate text file from Oracle AR to OD's Ebill Central System   |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             20-AUG-2018       Prashant J           Initial Version                  |
  ---+============================================================================================+
  G_PKG_NAME            VARCHAR2(30) :='XX_AR_OPSTECH_REPRINT_PKG';
  G_PKS_VERSION         NUMBER(2,1)  :='1.1';
  G_AS_OF_DATE          DATE         := NULL; 
  G_DEBUG_FLAG          BOOLEAN;     
  G_DISCOUNT            NUMBER := 0; 
  G_MISC_CHARGES        NUMBER := 0;
  G_DELIVERY            NUMBER := 0;
  G_COUPON              NUMBER := 0;
  ln_write_off_amt_low  NUMBER := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_LOW'); 
  ln_write_off_amt_high NUMBER := FND_PROFILE.VALUE('OD_BILLING_WRITE_OFF_AMT_HIGH'); 


	PROCEDURE xx_ops_update_status (p_errormsg        IN VARCHAR2,
									p_ar_cons_prcss   IN VARCHAR2,
									p_request_id      IN NUMBER,
									p_cust_acct_id    IN NUMBER,
									p_err_level       IN VARCHAR2
								   );                          
							  
							  
	PROCEDURE xx_opstech_reprint_main (x_error_buff    OUT  NOCOPY  VARCHAR2,
									   x_ret_code      OUT  NOCOPY  VARCHAR2,
									   p_file_path     IN VARCHAR2,
									   p_aops_number   IN VARCHAR2,
									   p_trx_date_from IN VARCHAR2,
									   p_trx_date_to   IN VARCHAR2,
									   p_debug_flag    IN VARCHAR2
									  );
									  
-- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- +===================================================================================+
  -- | Name        : get_cust_name                                                       |
  -- | Description : This function is used to build cust name from cust acct id          |
  -- |Parameters   : p_account_id                                                        |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version               |
  -- +===================================================================================+

    FUNCTION get_cust_name(p_account_id IN NUMBER)
      RETURN VARCHAR2; 

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
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+    
	  
	FUNCTION get_orig_inv_num(p_in_ord_hdr_id IN NUMBER)
	  RETURN NUMBER;
	  
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_bill_due_date                                                   |
-- | Description : This function is used to get Bill Due date from STG and HIST tab    |
-- |Parameters   : p_in_cust_trx_id                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+	 
	  
	FUNCTION get_bill_due_date(p_in_cust_trx_id IN NUMBER)
	  RETURN VARCHAR2;
	 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_bill_date                                                       |
-- | Description : This function is used to get Bill to date from STG and HIST tab     |
-- |Parameters   : p_in_cust_trx_id                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+
	 
	FUNCTION get_bill_date(p_in_cust_trx_id IN NUMBER)
	  RETURN VARCHAR2;	  

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_orig_inv_num                                                    |
-- | Description : This function is used to get Orig inv for Credit Memo               |
-- |Parameters   : p_in_cust_trx_id                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-SEP-2018  Prashant J                Initial draft version             |
-- +===================================================================================+  
    FUNCTION get_inv_amounts(p_in_cust_trx_id IN NUMBER,
                             p_in_amt_type    IN VARCHAR2)
    RETURN NUMBER; 


-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_cm_pay_term                                                     |
-- | Description : This function is used to get Pay Term for Credit Memo               |
-- | Parameters  : p_in_cust_acct_id                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-OCT-2018  Prashant J                Initial draft version             |
-- +===================================================================================+    
  
    FUNCTION get_cm_pay_term(p_in_cust_acct_id IN NUMBER)
	  RETURN VARCHAR2;  

--Record types   
  
TYPE HEADER_REC_TYPE
IS
  RECORD
  (
	CUSTOMER_TRX_ID        AR_INVOICE_HEADER_V.CUSTOMER_TRX_ID%TYPE, 
	BILLING_DATE           VARCHAR2(100),
    TRX_NUMBER             AR_INVOICE_HEADER_V.TRX_NUMBER%TYPE ,
	NAME                   RA_TERMS_TL.NAME%TYPE ,
    DUE_DATE               VARCHAR2(100),
	CUST_ACCT_ID 		   HZ_CUST_ACCOUNTS_ALL.CUST_ACCOUNT_ID%TYPE
  );

TYPE LINE_REC_TYPE
IS
  RECORD
  (
  CUSTOMER_TRX_ID                          AR_CONS_INV_TRX_LINES_ALL.CUSTOMER_TRX_ID%TYPE,
  CUSTOMER_TRX_LINE_ID                     AR_CONS_INV_TRX_LINES_ALL.CUSTOMER_TRX_LINE_ID%TYPE,
  LINE_NUMBER                              RA_CUSTOMER_TRX_LINES_ALL.LINE_NUMBER%TYPE,
  PRODUCT_DESCRIPTION                      RA_CUSTOMER_TRX_LINES_ALL.DESCRIPTION %TYPE, 
  PRODUCT_CODE                             RA_CUSTOMER_TRX_LINES_ALL.TRANSLATED_DESCRIPTION%TYPE,
  UNIT_OF_MEASURE                          MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE, 
  SHIPPED_QUANTITY                         RA_CUSTOMER_TRX_LINES_ALL.QUANTITY_INVOICED%TYPE,
  UNIT_SELLING_PRICE                       RA_CUSTOMER_TRX_LINES_ALL.UNIT_SELLING_PRICE%TYPE,
  EXTENDED_AMOUNT                          RA_CUSTOMER_TRX_LINES_ALL.EXTENDED_AMOUNT%TYPE,
  ORG_ID                                   RA_CUSTOMER_TRX_LINES_ALL.ORG_ID%TYPE
  );

END XX_AR_OPSTECH_REPRINT_PKG;
/
SHOW ERRORS;
EXIT;