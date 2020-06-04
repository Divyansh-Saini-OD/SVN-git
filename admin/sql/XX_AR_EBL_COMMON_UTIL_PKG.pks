create or replace PACKAGE XX_AR_EBL_COMMON_UTIL_PKG
AS
	-- +===================================================================================+
	-- |                  Office Depot - Project Simplify                                  |
	-- |                       WIPRO Technologies                                          |
	-- +===================================================================================+
	-- | Name        : XX_AR_EBL_COMMON_UTIL                                               |
	-- | Description : This Package will contain all the common functions and utilities    |
	-- |               used by the eBilling application                                    |
	-- |                                                                                   |
	-- |Change Record:                                                                     |
	-- |===============                                                                    |
	-- |Version   Date          Author                 Remarks                             |
	-- |=======   ==========   =============           ====================================|
	-- |DRAFT 1.0 10-MAR-2010  Ranjith Prabu           Initial draft version               |
	-- +===================================================================================+
	-- +===================================================================================+
	-- |                  Office Depot - Project Simplify                                  |
	-- |                       WIPRO Technologies                                          |
	-- +===================================================================================+
	-- | Name        : PUT_LOG_LINE                                                        |
	-- | Description : This Procedure is used to print the log lines based on the debug    |
	-- |               and the p_force flag                                                |
	-- |Parameters   :  p_debug                                                            |
	-- |               ,p_force                                                            |
	-- |               ,p_buffer                                                           |
	-- |                                                                                   |
	-- |Change Record:                                                                     |
	-- |===============                                                                    |
	-- |Version   Date          Author                 Remarks                             |
	-- |=======   ==========   =============           ====================================|
	-- |DRAFT 1.0 10-MAR-2010  Ranjith Prabu           Initial draft version               |
	-- |1.1       12-MAR-2013  Rajeshkumar M R         Moved department description        |
	-- |                                               to header Defect# 15118             |
	-- |1.2       04-NOV-2013  Arun Gannarapu          Made changes to fix the bill_From_date|
	-- |                                                with R12 changes                   |
	-- |1.3       20-NOV-2013  Arun Gannarapu          Made changes to fix the CA tax issue|
	-- |                                               Defect # 26548                      |
	-- |1.4       19-DEC-2013  Arun Gannarapu          Made changes to fix the bill from date|
	-- |                                                issue defect # 27239               |
	-- |1.5       17-FEB-2014  Arun Gannarapu          Made changes to fix the CA tax issue|
	-- |                                              for migrated transactions  # 26781   |
	-- |1.6       17-Aug-2015  Suresh Naragam          Added bill to location column       |
	-- |                                              (Module 4B Release 2)                |
	-- |1.7       15-Oct-2015  Suresh Naragam          Removed Schema References           |
	-- |                                               (R12.2 Global standards)            |
	-- |1.8       04-DEC-2015  Havish Kasina          Added new Function GET_HEADER_DISCOUNT|
	-- |                                              (Module 4B Release 3)                |
	-- |1.2       08-DEC-2015  Havish Kasina          Added new column dept_code in        |
	-- |                                              xx_ar_ebl_cons_dtl_hist,             |
	-- |                                              xx_ar_ebl_cons_hdr_hist,             |
	-- |                                              xx_ar_ebl_ind_dtl_hist and           |
	-- |                                              xx_ar_ebl_ind_hdr_hist tables        |
	-- |                                              -- Defect 36437                      |
	-- |                                              (MOD 4B Release 3)                   |
	-- |2.0		  24-MAY-2016  Rohit Gupta			  Changed the logic for 			   |
	-- |											  GET_HEADER_DISCOUNT for defect #37807|
	-- |2.1       23-JUN-2016  Havish Kasina          Added a new procedure                 |
	-- |                                              GET_KIT_EXTENDED_AMOUNT to get the    |
	-- |                                              KIT extended amount and KIT Unit Price|
	-- |                                              (Defect 37670 for Kitting)            |
	-- |2.2       23-JUN-2016  Havish Kasina          Added new column kit_sku in           |
	-- |                                              xx_ar_ebl_cons_dtl_hist,              |
	-- |                                              xx_ar_ebl_ind_dtl_hist                |
	-- |                                              Defect 37675 (Kitting Changes)        |
	-- |2.3       22-FEB-2018  Yashwanth SC           Added order by in get_email_details   |
	-- |                                                   (Defect#44275 )                  |
	-- |2.4       23-MAR-2018   Aniket J CG             Defect 22772  (Combo Type Changes)  |
	-- |2.5       12-SEP-2018   Aarthi                NAIT - 58403 Added SKU level columns  |
	-- |                                              to the history tables                 |
	-- |2.6       23-OCT-2018   SravanKumar           NAIT- 65564 Added new function to     |
	-- |                                              display custom message for bill       |
	-- |                                              complete customer for delivery        |
	-- |                                              method ePDF and ePRINT.               |
	-- |2.7       14-NOV-2018   Pjadhav               NAIT- 65564: updated GET_CONS_MSG_BCC |
	-- |                                              display  message for bill complete    |
	-- |                                              customer and Paydoc method only  	    |
    -- |2.8       11-MAR-2019   Aarthi                NAIT- 80452: Adding POD related blurb |
	-- |                                              messages to individual reprint reports|
  -- |2.9       27-MAY-2020   Divyansh              Added new functions for Tariff Changes|
  -- |                                              JIRA NAIT-129167                      | 
	-- +===================================================================================+
PROCEDURE PUT_LOG_LINE
  (
    p_debug  IN BOOLEAN ,
    p_force  IN BOOLEAN ,
    p_buffer IN VARCHAR2 DEFAULT ' ' );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD_PROG                                                   |
-- | Description : This Procedure is used to divide the total population of eXLS       |
-- |               or eTXT or eXLS (Individual) customers to be processed              |
-- |               by the associated child process.                                    |
-- |Parameters   : p_debug_flag                                                        |
-- |              ,p_batch_size                                                        |
-- |              ,p_del_mthd                                                          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
   PROCEDURE MULTI_THREAD( p_batch_size    IN NUMBER
                          ,p_thread_count  IN NUMBER
                          ,p_debug_flag    IN VARCHAR2
                          ,p_del_mthd      IN VARCHAR2   -- ( ePDF, eTXT, eXLS )
                          ,p_request_id    IN NUMBER
                          ,p_doc_type      IN VARCHAR2
                          ,p_status        IN VARCHAR2
                          ,p_cycle_date    IN VARCHAR2
                          );
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : GET_AMOUNT                                                          |
  -- | Description : This procedure is used to get the following amounts of the          |
  -- |               transation.                                                         |
  -- |               1. Total Amount                                                     |
  -- |               2. SKU lines Amount                                                 |
  -- |               3. Delivery/Miscellaneous Amount                                    |
  -- |               4. Disocunt Amount(Association, Bulk, Coupon, Tiered)               |
  -- |               5. Gift Card Amount                                                 |
  -- |                                                                                   |
  -- |Parameters   : p_inv_source                                                        |
  -- |              ,p_trx_id                                                            |
  -- |              ,p_trx_type                                                          |
  -- |              ,p_header_id                                                         |
  -- |              ,x_sku_line_amt                                                      |
  -- |              ,x_delivery_amt                                                      |
  -- |              ,x_misc_amt                                                          |
  -- |              ,x_assoc_disc_amt                                                    |
  -- |              ,x_bulk_disc_amt                                                     |
  -- |              ,x_coupon_disc_amt                                                   |
  -- |              ,x_tiered_disc_amt                                                   |
  -- |              ,x_gift_card_amt                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
  -- +===================================================================================+
PROCEDURE GET_AMOUNT
  (
    p_inv_source IN VARCHAR2 ,
    p_trx_id     IN NUMBER ,
    p_trx_type   IN VARCHAR2 ,
    p_header_id  IN NUMBER ,
    x_trx_amt OUT NUMBER ,
    x_sku_line_amt OUT NUMBER ,
    x_delivery_amt OUT NUMBER ,
    x_misc_amt OUT NUMBER ,
    x_assoc_disc_amt OUT NUMBER ,
    x_bulk_disc_amt OUT NUMBER ,
    x_coupon_disc_amt OUT NUMBER ,
    x_tiered_disc_amt OUT NUMBER ,
    x_gift_card_amt OUT NUMBER ,
    x_line_count    OUT NUMBER
    );
  -- +===================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : GET_TAX_AMOUNT                                                      |
  -- | Description : This procedure is used to get the tax amount and tax rate for the   |
  -- |               transaction.                                                        |
  -- |Parameters   :                                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
  -- +===================================================================================+
PROCEDURE GET_TAX_AMOUNT
  (
    p_trx_id   IN NUMBER ,
    p_country  IN VARCHAR2 ,
    p_province IN VARCHAR2 ,
    x_us_tax_amount OUT NUMBER ,
    x_us_tax_rate OUT NUMBER ,
    x_gst_tax_amount OUT NUMBER ,
    x_gst_tax_rate OUT NUMBER ,
    x_pst_tax_amount OUT NUMBER ,
    x_pst_tax_rate OUT NUMBER );
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        : GET_REMIT_ADDRESS                                                   |
    -- | Description : This procedure is used to get the remit to address.                 |
    -- |               transaction.                                                        |
    -- |Parameters   :                                                                     |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author                 Remarks                             |
    -- |=======   ==========   =============           ====================================|
    -- |DRAFT 1.0 11-MAR-2010  Gokila Tamilselvam      Initial draft version               |
    -- +===================================================================================+
  PROCEDURE GET_REMIT_ADDRESS
    (
      p_remit_control_id IN NUMBER ,
      x_remit_addr1 OUT VARCHAR2 ,
      x_remit_addr2 OUT VARCHAR2 ,
      x_remit_addr3 OUT VARCHAR2 ,
      x_remit_addr4 OUT VARCHAR2 ,
      x_remit_city OUT VARCHAR2 ,
      x_remit_state OUT VARCHAR2 ,
      x_remit_zip OUT VARCHAR2 ,
      x_remit_desc OUT VARCHAR2,
      x_remit_country OUT VARCHAR2);
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        : GET_ADDRESS                                                         |
    -- | Description : This procedure is used to get the BILL TO address details  for the  |
    -- |               given site_use_id.                                                  |
    -- |Parameters   :                                                                     |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author                 Remarks                             |
    -- |=======   ==========   =============           ====================================|
    -- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
    -- +===================================================================================+
  PROCEDURE GET_ADDRESS
    (
      p_site_use_id IN NUMBER ,
      x_address1 OUT VARCHAR2 ,
      x_address2 OUT VARCHAR2 ,
      x_address3 OUT VARCHAR2 ,
      x_address4 OUT VARCHAR2 ,
      x_city OUT VARCHAR2 ,
      x_country OUT VARCHAR2 ,
      X_STATE OUT VARCHAR2 ,
      X_POSTAL_CODE OUT VARCHAR2 ,
      X_LOCATION OUT VARCHAR2 ,
      X_SHIP_TO_NAME OUT VARCHAR2 ,
      x_ship_to_sequence OUT VARCHAR2 ,
      x_province OUT VARCHAR2 ,
      x_site_id OUT NUMBER ,
      x_site_sequence OUT VARCHAR2 ,
      x_customer_name OUT VARCHAR2 );
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        : GET_TERM_DETAILS                                                    |
    -- | Description : This procedure is used to fetch the required columns from the       |
    -- |               ra_terms table.                                                     |
    -- |Parameters   :                                                                     |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author                 Remarks                             |
    -- |=======   ==========   =============           ====================================|
    -- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
    -- +===================================================================================+
   PROCEDURE GET_TERM_DETAILS (p_billing_term           IN  VARCHAR2
                              ,x_term                   OUT VARCHAR2
                              ,x_term_description       OUT VARCHAR2
                              ,x_term_discount          OUT VARCHAR2
                              ,x_term_frequency         OUT VARCHAR2
                              ,x_term_report_day OUT VARCHAR2
                              );
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        :  GET_HDR_ATTR_DETAILS                                               |
    -- | Description : This procedure is used to fetch the required columns from the       |
    -- |               xx_om_header_attributes_all table.                                  |
    -- |Parameters   :                                                                     |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author                 Remarks                             |
    -- |=======   ==========   =============           ====================================|
    -- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
    -- +===================================================================================+
PROCEDURE GET_HDR_ATTR_DETAILS (p_header_id            IN  NUMBER
                                  ,p_spc_source_id        IN NUMBER
                                  ,x_contact_email        OUT VARCHAR2
                                  ,x_contact_name         OUT VARCHAR2
                                  ,x_contact_phone        OUT VARCHAR2
                                  ,x_contact_phone_ext    OUT VARCHAR2
                                  ,x_order_level_comment  OUT VARCHAR2
                                  ,x_order_type_code      OUT VARCHAR2
                                  ,x_order_source_code      OUT VARCHAR2
                                  ,x_ordered_by           OUT VARCHAR2
                                  ,X_Order_Date          Out DATE
                                  ,X_Spc_Info             OUT VARCHAR2
                                  ,x_cost_center_sft_data   OUT VARCHAR2
                                  ,x_release_data          OUT VARCHAR2
                                  ,x_desk_data             OUT VARCHAR2
                                  ,x_ship_to_addr1         OUT VARCHAR2
                                  ,X_ship_to_addr2         OUT VARCHAR2
                                  ,X_ship_to_city          OUT VARCHAR2
                                  ,x_ship_to_state         OUT VARCHAR2
                                  ,x_ship_to_country       OUT VARCHAR2
                                  ,x_ship_to_zip           OUT VARCHAR2
                                  ,x_tax_rate              OUT NUMBER
                                 );
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        :  GET_CUST_TRX_LINE_DETAILS                                          |
    -- | Description : This procedure is used to fetch the required columns from the       |
    -- |               ra_customer_trx_lines table.                                        |
    -- |Parameters   :                                                                     |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author                 Remarks                             |
    -- |=======   ==========   =============           ====================================|
    -- |DRAFT 1.0 17-MAR-2010  Vinaykumar S            Initial draft version               |
    -- +===================================================================================+
  PROCEDURE GET_CUST_TRX_LINE_DETAILS
    (
      p_cust_trx_line_id IN NUMBER ,
      p_trx_type         IN VARCHAR2 ,
      x_cont_plan_id OUT VARCHAR2 ,
      x_cont_seq_number OUT VARCHAR2 ,
      x_ext_price OUT VARCHAR2 ,
      x_item_desc OUT VARCHAR2 ,
      x_qty_ordered OUT VARCHAR2 ,
      x_qty_shipped OUT VARCHAR2 ,
      x_amt_tax_flag OUT VARCHAR2 ,
      x_cust_trx_id OUT VARCHAR2 ,
      x_cust_trx_line_id OUT VARCHAR2 ,
      x_line_number OUT VARCHAR2 ,
      x_link_to_cust_trx_line_id OUT VARCHAR2 ,
      x_sales_order OUT VARCHAR2 ,
      x_sales_order_date OUT VARCHAR2 ,
      x_sales_tax_id OUT VARCHAR2 ,
      x_tax_exempt_id OUT VARCHAR2 ,
      x_tax_precedence OUT VARCHAR2 ,
      x_unit_selling_price OUT VARCHAR2 );
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        : ADDR_EXCP_HANDLING (Address Exception Handling)                     |
    -- | Description : To Handle address exceptions                                        |
    -- |                                                                                   |
    -- |                                                                                   |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author              Remarks                                |
    -- |=======   ==========   =============        =======================================|
    -- |DRAFT 1.0 18-MAR-2010  Vinaykumar S            Initial draft version               |
    -- +===================================================================================+
  FUNCTION ADDR_EXCP_HANDLING
    (
      p_cust_account_id     NUMBER ,
      p_cust_doc_id         NUMBER ,
      p_ship_to_site_use_id NUMBER ,
      p_direct_flag         VARCHAR2,
      p_site_attr_id         NUMBER)
    RETURN NUMBER;
    -- +===================================================================================+
    -- |                  Office Depot - Project Simplify                                  |
    -- |                       WIPRO Technologies                                          |
    -- +===================================================================================+
    -- | Name        : GET_SOFT_HEADER (Soft Headers)                                      |
    -- | Description : To get soft header values                                           |
    -- |                                                                                   |
    -- |                                                                                   |
    -- |                                                                                   |
    -- |Change Record:                                                                     |
    -- |===============                                                                    |
    -- |Version   Date          Author              Remarks                                |
    -- |=======   ==========   =============        =======================================|
    -- |DRAFT 1.0 18-MAR-2010  Ranjith Thangasamy      Initial draft version               |
    -- +===================================================================================+
 PROCEDURE GET_SOFT_HEADER ( p_cust_acct_id      IN NUMBER
                              ,p_report_soft_header_id IN NUMBER
                              ,x_cost_center_dept  OUT VARCHAR2
                              ,x_desk_del_addr     OUT VARCHAR2
                              ,x_Om_Release_Number OUT VARCHAR2
                              ,x_purchase_order    OUT VARCHAR2
                              );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : xx_fin_check_digit                                                  |
-- | Description : This function is used to get the FLO code for remittance stub.      |
-- |                                                                                   |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Bhuvaneswary S            Initial draft version             |
-- |1.1       12-MAR-2013  Rajeshkumar M R         Moved department description        |
-- |                                               to header Defect# 15118             |
-- |1.2       04-NOV-2013  Arun Gannarapu          Made changes to fix the bill_From_date|
-- |                                                with R12 changes                   |
-- |1.3       20-NOV-2013  Arun Gannarapu          Made changes to fix the CA tax issue|
-- |                                               Defect # 26548                      |
-- |1.4       19-DEC-2013  Arun Gannarapu          Made changes to fix the bill from date|
-- |                                                issue defect # 27239               |
-- |1.5       17-FEB-2014  Arun Gannarapu          Made changes to fix the CA tax issue|
-- |                                              for migrated transactions  # 26781   |
-- |1.6       17-Aug-2015  Suresh Naragam          Added bill to location column       |
-- |                                              (Module 4B Release 2)                |
-- |1.7       15-Oct-2015  Suresh Naragam          Removed Schema References           |
-- |                                               (R12.2 Global standards)            |
-- |1.8       04-DEC-2015  Havish Kasina          Added new Function GET_HEADER_DISCOUNT|
-- |                                              (Module 4B Release 3)                |
-- |1.2       08-DEC-2015  Havish Kasina          Added new column dept_code in        |
-- |                                              xx_ar_ebl_cons_dtl_hist,             |
-- |                                              xx_ar_ebl_cons_hdr_hist,             |
-- |                                              xx_ar_ebl_ind_dtl_hist and           |
-- |                                              xx_ar_ebl_ind_hdr_hist tables        |
-- |                                              -- Defect 36437                      |
-- |                                              (MOD 4B Release 3)                   |
-- |2.0		  24-MAY-2016  Rohit Gupta			  Changed the logic for 			   |
-- |											  GET_HEADER_DISCOUNT for defect #37807|
-- |2.1       23-JUN-2016  Havish Kasina          Added a new procedure                 |
-- |                                              GET_KIT_EXTENDED_AMOUNT to get the    |
-- |                                              KIT extended amount and KIT Unit Price|
-- |                                              (Defect 37670 for Kitting)            |
-- |2.2       23-JUN-2016  Havish Kasina          Added new column kit_sku in           |
-- |                                              xx_ar_ebl_cons_dtl_hist,              |
-- |                                              xx_ar_ebl_ind_dtl_hist                |
-- |                                              Defect 37675 (Kitting Changes)        |
-- |2.3       22-FEB-2018  Yashwanth SC           Added order by in get_email_details   |
-- |                                                   (Defect#44275 )                  |
-- |2.4       23-MAR-2018   Aniket J CG             Defect 22772  (Combo Type Changes)  |
-- |2.5       12-SEP-2018   Aarthi                NAIT - 58403 Added SKU level columns  |
-- |                                              to the history tables                 |
-- +===================================================================================+
   FUNCTION xx_fin_check_digit (p_account_number  VARCHAR2
                               ,p_invoice_number  VARCHAR2
                               ,p_amount          VARCHAR2
                               )
   RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_CONCAT_ADDR                                                     |
-- | Description : This function is used to get concated address.               .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Bhuvaneswary S            Initial draft version             |
-- +===================================================================================+
   FUNCTION GET_CONCAT_ADDR (p_addr1   VARCHAR2
                            ,p_addr2   VARCHAR2
                            ,p_addr3   VARCHAR2
                            ,p_addr4   VARCHAR2
                            ,p_city    VARCHAR2
                            ,p_state   VARCHAR2
                            ,p_postal  VARCHAR2
                            ,p_country VARCHAR2
                             )
   RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : gsa_comments                                                        |
-- | Description : This function is used to get the gsa comments                .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
   FUNCTION gsa_comments (p_gsa_flag IN NUMBER)
   return varchar2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_site_mail_attention                                                        |
-- | Description : This function is used to get the mail to attention           .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
   function get_site_mail_attention ( p_cust_doc_id NUMBER
                                   ,p_cust_site_id number
                                   ,p_attr_id      NUMBER
                                   )
   return varchar2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_extract_status                                                  |
-- | Description : This function is used to get theectract status               .      |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
   FUNCTION get_extract_status (p_as_of_date DATE,p_cust_doc_id IN NUMBER)
   RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_misc_values                                                     |
-- | Description : This function is used to get the misc values                        |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 05-APR-2010  Ranjith Thangasamy        Initial draft version             |
-- +===================================================================================+
   PROCEDURE get_misc_values(p_order_header_id IN NUMBER
                         ,p_reason_code     IN VARCHAR2
                         ,p_sold_to_customer_id IN NUMBER
                         ,p_invoice_type     IN VARCHAR2
                         ,x_orgordnbr       OUT VARCHAR2
                         ,x_reason_code     OUT VARCHAR2
                         ,x_sold_to_customer OUT VARCHAR2
                         ,x_reconcile_date   OUT DATE
                         );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_BILL_STATUS                                                  |
-- | Description : This function is used to updated standard table and delete and      |
-- |               and insert data into frequency and frequency history table          |
-- |               respectively.                                                       |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date            Author                  Remarks                          |
-- |=======   ===========     =============           =================================|
-- |DRAFT 1.0 29-APR-2010     Gokila Tamilselvam      Initial draft version            |
-- +===================================================================================+
      PROCEDURE UPDATE_BILL_STATUS ( p_batch_id            NUMBER
                                    ,p_doc_type            VARCHAR2
                                    ,p_delivery_meth       VARCHAR2
                                    ,p_request_id          NUMBER
                                    ,p_debug_flag          VARCHAR2
                                    );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_BILL_STATUS_eXLS                                             |
-- | Description : This procedure is used to updated standard table and delete and     |
-- |               and insert data into frequency and frequency history table          |
-- |               respectively for the delivery method eXLS                           |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version   Date            Author                  Remarks                          |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    PROCEDURE UPDATE_BILL_STATUS_eXLS ( p_file_id             NUMBER
                                       ,p_doc_type            VARCHAR2
                                       ,p_delivery_meth       VARCHAR2 DEFAULT 'eXLS'
                                       ,p_request_id          NUMBER DEFAULT fnd_global.conc_request_id
                                       ,p_debug_flag          VARCHAR2 DEFAULT 'N'
                                       );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_REMIT_ADDRESSID                                                 |
-- | Description : This Function  is used to get the remit to address id               |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 03-MAY-2010  Vinaykumar S            Initial draft version               |
-- +===================================================================================+
   FUNCTION GET_REMIT_ADDRESSID (
                                 p_bill_to_site_use_id NUMBER
                                ,p_debug_flag          VARCHAR2
                                )
      RETURN NUMBER;
FUNCTION get_email_details(p_cust_doc_id IN NUMBER
                              , p_site_id IN VARCHAR2
                              )
     RETURN VARCHAR;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : INSERT_BLOB_FILE                                                    |
-- | Description : This procedure is used to insert BLOB file into the table.          |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 16-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE insert_blob_file ( p_dir             IN    VARCHAR2
                                ,p_file            IN    VARCHAR2
                                ,p_file_type       IN    VARCHAR2
                                ,p_trans_id        IN    NUMBER
                                ,p_file_id         IN    NUMBER
                                ,p_debug_flag      IN    VARCHAR2
                                ,x_err_count       OUT   NUMBER
                                );
    -- +=================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : BILL_FROM_DATE                                                      |
  -- | Description : This function is used to get the bill from date for the current     |
  -- |               cycle.                                                              |
  -- |Parameters   :                                                                     |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy      Initial draft version               |
  -- +===================================================================================+
  FUNCTION bill_from_date(
                                    --p_extension_id              IN    NUMBER    --Commented for the Defect# 9632
                                    p_payment_term   IN VARCHAR2 --Added for the Defect# 9632
                                   ,p_invoice_creation_date     IN    DATE
                                   )  RETURN DATE;
FUNCTION GET_BILLING_ASSOCIATE_NAME (p_associate_code IN NUMBER)
RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : update_Data_extract_status                                          |
-- | Description : This procedure is used by exls render to update error status.       |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    PROCEDURE update_Data_extract_status ( p_file_id             NUMBER
                                          ,p_doc_type            VARCHAR2
                                          ,p_status              VARCHAR2 :='ERROR'
                                          ,p_request_id          NUMBER   :=fnd_global.conc_request_id
                                          ,p_debug_flag          VARCHAR2 :='N'
                                         );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_IND_SUM_AMOUNT                                                |
-- | Description : This function is used to get the total amount for all the individual|
-- |               method based on the transaction ID that is passed.                  |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    FUNCTION  XX_AR_IND_SUM_AMOUNT (p_trx_id      IN NUMBER
                                   ,p_paydoc_flag IN VARCHAR2
                                    ) RETURN NUMBER;
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |                       WIPRO Technologies                                             |
-- +======================================================================================+
-- | Name        : XX_AR_CONS_SUM_AMOUNT                                                  |
-- | Description : This function is used to get the total amount for all the consolidated |
-- |               method based on the consolidated invoice ID that is passed.            |
-- | Parameters  :                                                                        |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date          Author                 Remarks                                |
-- |=======   ==========   =============           =======================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -     |
-- |                                               Defect 2811                            |
-- +======================================================================================+
    FUNCTION  XX_AR_CONS_SUM_AMOUNT (p_cbi_id IN    NUMBER
                                     ) RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_OD_EBL_DEL_MTD                                                   |
-- | Description : This function returns a value 1 if the given delivery method exists |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 10-Jun-2010  Parameswaran SN         Initial draft version for CR 586 -  |
-- |                                               Defect 2811                         |
-- +===================================================================================+
    FUNCTION XX_OD_EBL_DEL_MTD(p_del_mtd IN VARCHAR2
                              ,lc_del_mtd IN VARCHAR2) RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_FILE_TABLE                                                   |
-- | Description : Procedure to reset file_status                                      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+
   PROCEDURE UPDATE_FILE_TABLE ( x_errbuf OUT VARCHAR2
                                ,x_retcode OUT VARCHAR2
                                ,p_type VARCHAR2
                                ,p_cust_doc_id VARCHAR2
                                ,p_batch_id VARCHAR2
                                ,p_file_id  VARCHAR2
                                ,p_transmission_id VARCHAR2
                                ,p_status VARCHAR2
                                );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : UPDATE_HDR_TABLE                                                    |
-- | Description : Procedure to reset status in HDR tables                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+
    PROCEDURE UPDATE_HDR_TABLE ( x_errbuf OUT VARCHAR2
                                ,x_retcode OUT VARCHAR2
                                ,p_type VARCHAR2
                                ,p_batch_id VARCHAR2
                                );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_parent_details                                                  |
-- | Description : Procedure to get the parent customer details                        |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+

    PROCEDURE get_parent_details(p_customer_id IN NUMBER
                           ,p_account_number OUT VARCHAR2
                           ,p_aops_acct_number OUT VARCHAR2
                           ,p_customer_name OUT VARCHAR2
                           );
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_discount_date                                                   |
-- | Description : Procedure to get the discount date if the term is a discount term   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 19-Jun-2010  Ranjith Thangasamay     Initial draft version               |
-- +===================================================================================+

    FUNCTION get_discount_date (p_trx_id IN NUMBER)
    RETURN  DATE;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_HEADER_DISCOUNT                                                 |
-- | Description : To get the Discount Information                                     |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 30-NOV-2015  Havish Kasina        Initial draft version                  |
-- +===================================================================================+
  FUNCTION GET_HEADER_DISCOUNT
    (
      p_customer_trx_id IN    NUMBER )
    RETURN VARCHAR2;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_HEADER_DISCOUNT                                                 |
-- | Description : To get the Discount Information                                     |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 16-DEC-2015  Suresh N             Initial draft version                  |
-- +===================================================================================+
  FUNCTION GET_HEADER_DISCOUNT
    (
      p_cons_inv_id     IN    NUMBER,
      p_customer_trx_id IN    NUMBER )
    RETURN VARCHAR2;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_KIT_EXTENDED_AMOUNT                                             |
-- | Description : To get the KIT extended amount and KIT Unit Price                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- |DRAFT 1.0 23-JUN-2016  Havish Kasina        Initial draft version                  |
-- +===================================================================================+
   Procedure get_kit_extended_amount ( p_customer_trx_id      IN  NUMBER ,
		                               p_sales_order_line_id  IN  VARCHAR2 ,
									   p_kit_quantity         IN  NUMBER ,
								       x_kit_extended_amt     OUT NUMBER ,
									   x_kit_unit_price       OUT NUMBER
								     );

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_CONS_MSG_BCC                                                    |
-- | Description : To display custom message for bill complete customer for delivery   |
-- | 			   method ePDF and ePRINT.							                   |
-- |                                                                                   |
-- |===============                                                                    |
-- |Version     Date         Author              Remarks                               |
-- |=========   ==========   =============       ======================================|
-- |DRAFT 1.0   23-OCT-2018  SravanKumar		Initial draft version        	       |
-- |1.1        	14-Nov-2018	 Pjadhav            NAIT- 65564: updated GET_CONS_MSG_BCC  |
-- |										  	display  message for bill complete     |
-- |                                            customer and Paydoc method only        |
-- +===================================================================================+
	FUNCTION get_cons_msg_bcc
		(
		p_cust_doc_id 		IN NUMBER,
		p_cust_account_id 	IN NUMBER,
		p_billing_number  	IN VARCHAR2
		)
    RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : GET_POD_MSG_IND_REPRINT                                             |
-- | Description : To get the blurb message for Individual Reprint report              |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-JUN-2016  Aarthi               Initial draft version for adding Blurb |
-- |                                            message for POD Ind Reprint report     |
-- +===================================================================================+
	FUNCTION get_pod_msg_ind_reprint ( p_customer_trx_id      IN  NUMBER ,
		                               p_bill_to_customer_id  IN  NUMBER
							         )
    RETURN VARCHAR2;
    
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_line_fee_amount                                                      |
-- | Description : To get fee amount for particular transaction                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
	FUNCTION get_line_fee_amount ( p_customer_trx_id      IN  NUMBER)
    RETURN NUMBER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_hea_fee_amount                                                      |
-- | Description : To get fee amount for particular transaction                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+
	FUNCTION get_hea_fee_amount ( p_customer_trx_id      IN  NUMBER)
    RETURN NUMBER;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_fee_line_number                                                      |
-- | Description : To get line number for particular transaction                        |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author              Remarks                                |
-- |=======   ==========   =============        =======================================|
-- | 1.0      23-MAR-2020  Divyansh Saini       Initial draft version                  |
-- +===================================================================================+ 
  FUNCTION get_fee_line_number(p_customer_trx_id NUMBER,
                               p_description IN VARCHAR2,
                               p_organization IN NUMBER,
                               p_line_number IN NUMBER) 
    RETURN NUMBER ;
 END XX_AR_EBL_COMMON_UTIL_PKG;
 /