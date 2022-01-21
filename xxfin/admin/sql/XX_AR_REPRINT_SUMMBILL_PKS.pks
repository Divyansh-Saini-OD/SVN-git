CREATE OR REPLACE PACKAGE apps.xx_ar_reprint_summbill AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pks                                       |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                |
---|    1.1             13-AUG-2008       Sarat Uppalapati   Added parameter p_reprint to the function      |
---|                                                         get_bill_from_date for defect 9555             |
---|    1.2             02-DEC-2008       Sambasiva Reddy D  Changed for the Defect # 12223                 |
-- |    1.3             14-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662) -- Applied Credit Memos  |
-- |    1.4             08-SEP-2009       Vinaykumar s       Defect# 1451 (CR# 626)                         |
-- |    1.5             16-DEC-2009       Gokila Tamilselvam Modified for R1.2 Defect# 1210 CR# 466.        |
-- |    1.6             06-MAR-2019	      Sravan Reddy	     Added functions get_cons_msg_bcc,              | 
-- |                                                         get_paydoc_flag,get_pod_msg as part of         |  	
-- |                                                         NAIT-80452.                                    |
-- |    1.7             19-APR-2019	      Visu P         Added function get_cons_msg_bcc_rp                 |
-- |                                                         Added new parameter p_cbi_id to                |
-- |                                                         GET_CONS_MSG_BCC, made a call to               |
-- |                                                         get_cons_msg_bcc_rp instead of                 |
-- |                                                         xx_ar_ebl_common_util_pkg.get_cons_msg_bcc     |
-- |                                                         as part of  NAIT-92137                         |
---+========================================================================================================+


       g_pkg_name            VARCHAR2(30) :='XX_AR_REPRINT_SUMMBILL';
       g_pks_version         NUMBER(2,1)  :='1.3';

       /*        
         Define the number of characters required for certain fields in the report.       
       */
       lc_old_custnum_size NUMBER  :=8;
       ln_custname_size    NUMBER :=40;
       lc_address_size     NUMBER :=40;
       lc_terms_name_size  NUMBER  :=15;       
 

       ln_request_id         NUMBER :=0;
       p_request_id          NUMBER;
       P_SUMM_BILL_NUM       VARCHAR2(30);
       P_SUMM_BILL_NUM_TO    VARCHAR2(30);       
       P_CUST_ACCOUNT_ID     NUMBER;
       P_MBS_DOCUMENT_ID     NUMBER;
       P_MBS_EXTENSION_ID    NUMBER;
       P_SPEC_HANDLING_FLAG  VARCHAR2(10);
       P_ORIGIN              VARCHAR2(20);
       --Start for Defect # 12223
       P_AS_OF_DATE1         VARCHAR2(15);
       P_DOC_DETAIL          VARCHAR2(15);
       P_SEND_TO             VARCHAR2(240);
       --End for Defect # 12223

       P_CM_TEXT1            VARCHAR2(50);   -- Added for Defect # 631 (CR : 662)
       P_CM_TEXT2            VARCHAR2(50);   -- Added for Defect # 631 (CR : 662)

       P_GIFT_CARD_TEXT1     VARCHAR2(50);   -- Added for Defect # 1451 (CR : 626)
       P_GIFT_CARD_TEXT2     VARCHAR2(50);   -- Added for Defect # 1451 (CR : 626)
       P_GIFT_CARD_TEXT3     VARCHAR2(50);   -- Added for Defect # 1451 (CR : 626)

       --Start of changes for R1.2 Defect# 1210 CR# 466.
       P_DATE_FROM           VARCHAR2(15);
       P_DATE_TO             VARCHAR2(15);
       P_EMAIL_OPTION        VARCHAR2(10);
       P_EMAIL_ADDRESS       VARCHAR2(250);
       P_MULTIPLE_BILL       VARCHAR2(250);
       P_INFOCOPY_FLAG       VARCHAR2(5);
       P_VIRTUAL_BILL_FLAG   VARCHAR2(5);
       P_VIRTUAL_BILL_NUM    VARCHAR2(250);
       P_CUST_DOC_ID         NUMBER;
       DataTemplateCode      VARCHAR2(50);
       --End of changes for R1.2 Defect# 1210 CR# 466.


       p_template            VARCHAR2(10);
       lv_outfile            VARCHAR2(255) :=TO_CHAR(NULL);
       lv_certegy_file       VARCHAR2(255) :=TO_CHAR(NULL);

       lv_message_buffer     VARCHAR2(4000) :=TO_CHAR(NULL);

       lc_cp_running         BOOLEAN;
       lc_fndconc_phase      VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_status     VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_dev_phase  VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_dev_status VARCHAR2(2000) :=TO_CHAR(NULL);
       lc_fndconc_message    VARCHAR2(2000) :=TO_CHAR(NULL);

       lt_cons_bill xx_ar_reprint_cons_bill_t := xx_ar_reprint_cons_bill_t();        -- Added for R1.2 Defect# 1210 CR# 466.

       FUNCTION Run_ONE (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION Run_SUMMARIZE (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION Run_DETAIL (p_template IN VARCHAR2) RETURN BOOLEAN;
       
       FUNCTION xx_fin_check_digit (p_account_number VARCHAR2,
                                                      p_invoice_number VARCHAR2,
                                               p_amount         VARCHAR2) RETURN VARCHAR2;
       
       FUNCTION get_bill_from_date( p_customer_id IN NUMBER
                                   ,p_site_id     IN NUMBER
                                   ,p_consinv_id  IN NUMBER                             
                                   ,infocopy_tag  IN VARCHAR2
                                   ,p_spec_handling_flag     IN VARCHAR2
                           ) RETURN DATE;
                           
       FUNCTION get_cbi_amount_due 
              (
               p_cbi_id IN           NUMBER
              ,p_ministmnt_line_type VARCHAR2 --EXTAMT_PLUS_DELVY, DISCOUNT ,TAX and TOTAL...               
             ) RETURN NUMBER;                          
               
       FUNCTION beforereport RETURN BOOLEAN;   
       
       FUNCTION afterreport RETURN BOOLEAN;       
       
       FUNCTION XX_RETURN_ADDRESS return VARCHAR2;
       
       FUNCTION XX_BILL_TO_ADDRESS (p_site_use_id IN NUMBER) return VARCHAR2;
       
       FUNCTION XX_REMIT_TO_ADDRESS (p_site_use_id IN NUMBER) return VARCHAR2;

-- Added the below procedure GET_IND_BILL_NUM for R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name        : GET_IND_BILL_NUM                                    |
-- | Description : To get the individual transactions separately from  |
-- |               the Multiple transactions parameter separated by    |
-- |               commas.                                             |
-- | Parameters  : p_multiple_bills                                    |
-- |               p_virtual_bill_flag                                 |
-- |                                                                   |
-- | Returns     : x_error_buff,x_ret_code                             |
-- +===================================================================+
 PROCEDURE GET_IND_BILL_NUM ( x_error_buff        OUT VARCHAR2
                             ,x_ret_code          OUT NUMBER
                             ,p_multi_trans_num   IN  VARCHAR2
                             ,p_virtual_bill_flag IN  VARCHAR2
                             );

 -- Added the below function GET_BILL_TO_DATE for R1.2 Defect# 1210 CR# 466.
-- +===================================================================+
-- | Name        : GET_BILL_TO_DATE                                    |
-- | Description : To get the bill to date for reprinting the bills.   |
-- |               commas.                                             |
-- | Parameters  : p_customer_id                                       |
-- |              ,p_site_id                                           |
-- |              ,p_consinv_id                                        |
-- |              ,p_infocopy_tag                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns     : x_error_buff,x_ret_code                             |
-- +===================================================================+
 FUNCTION GET_BILL_TO_DATE( p_customer_id  IN NUMBER
                           ,p_consinv_id   IN NUMBER
                           ,infocopy_tag   IN VARCHAR2
                           )
 RETURN DATE;
--Added below function GET_CONS_MSG_BCC as part of NAIT#80452
--+=============================================================================================+
  ---|    Name : GET_CONS_MSG_BCC                                                                 |
  ---|    Description   : This function will perform the following                                |
  ---|                                                                                            |
  ---|                  1. If customer is "Bill complete customer" and document type is           |
  -- |                     "Consolidated" and it is Paydoc then blurb message to be displayed in  |
  ---|                      respective child programs of "OD: AR Reprint Summary Bills".          |                 
  ---|                                                                                            |
  ---|    Parameters : Cons_Inv_Id, Cust_doc_Id, Cust_account_id, Consolidated_billing_number                  |
  --+=============================================================================================+ 
 
 FUNCTION GET_CONS_MSG_BCC 
	     ( p_cbi_id          IN NUMBER
       	  ,p_custdoc_id      IN NUMBER		  
		  ,p_cust_account_id IN NUMBER
		  ,p_billing_number  IN VARCHAR2
	     ) 
 RETURN VARCHAR2;
  --Added below function GET_PAYDOC_FLAG as part of NAIT#80452
  --+=============================================================================================+
  ---|    Name : GET_PAYDOC_FLAG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	  
  
FUNCTION GET_PAYDOC_FLAG (p_cust_doc_id IN NUMBER,p_cust_account_id IN NUMBER)     
RETURN VARCHAR2;
--Added below function GET_POD_MSG as part of NAIT#80452
--+=============================================================================================+
  ---|    Name : GET_POD_MSG                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
  
FUNCTION GET_POD_MSG (p_cust_account_id IN NUMBER , p_customer_trx_id IN NUMBER , p_cust_doc_id IN NUMBER )   
RETURN VARCHAR2;
FUNCTION get_cons_msg_bcc_rp 
	     (     p_cbi_id             IN NUMBER        
		  ,p_cust_doc_id 	IN NUMBER
		  ,p_cust_account_id 	IN NUMBER
		  ,p_billing_number  	IN VARCHAR2
	     ) 
RETURN VARCHAR2;
END xx_ar_reprint_summbill;
/