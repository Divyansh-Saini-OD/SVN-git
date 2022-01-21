create or replace
PACKAGE XX_AR_CREATE_ACCT_CHILD_PKG AUTHID CURRENT_USER
AS
   -- +=====================================================================+
   -- |                  Office Depot - Project Simplify                    |
   -- |                       WIPRO Technologies                            |
   -- +=====================================================================+
   -- | Name       : XX_AR_CREATE_ACCT_CHILD_PKG                            |
   -- | RICE ID    : E0080                                                  |
   -- | Description: Child package to extend the existing Oracle process    |
   -- |              of creating accounting segments based on the           |
   -- |              business rules of office depot                         |
   -- |                                                                     |
   -- |Change Record:                                                       |
   -- |===============                                                      |
   -- |Version    Date         Author         Remarks                       |
   -- |=========  ===========  =============  ============================= |
   -- |1.0 - 3.2  Various      Various        See Code revision #?????      |
   -- |                                                                     |
   -- |3.3        27-MAR-2011                 R11.3 - Summarization of      |
   -- |                                       POS invoices                  |                                      
   -- |                                                                     |
   -- |4.0        10/24/2012   R.Aldridge     Defect 20687 - New batch group|
   -- |                                       to faciliate new batch source |
   -- +=====================================================================+

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_CREATE_ACCT_PROC                                       |
-- | RICE ID: E0080                                                      |
-- | Description : Proceudure to extend the existing Oracle process      |
-- |               of  creating accounting segments based on the         |
-- |               business rules of office depot                        |
-- |                                                                     |
-- | Parameters : p_run_flag, p_email_address,p_sales_order_low          |
-- |             ,p_sales_order_high,p_display_log,p_invoice_source      |
-- |             ,p_default_date,p_error_message                         |
-- | Returns   : x_error_buff, x_ret_code                                |
-- +=====================================================================+
PROCEDURE  XX_AR_CREATE_ACCT_CHILD_PROC(
                                  x_err_buff        OUT  VARCHAR2
                                 ,x_ret_code        OUT  NUMBER
                                 ,p_org_id           IN  NUMBER
                                 ,p_run_flag         IN  VARCHAR2 DEFAULT 'B'
                                 ,p_email_address    IN  VARCHAR2 DEFAULT NULL
                                 ,p_sales_order_low  IN  VARCHAR2
                                 ,p_sales_order_high IN  VARCHAR2
                                 ,p_display_log      IN  VARCHAR2 DEFAULT 'N'  -- Defect 3418
                                 ,p_batch_group      IN  VARCHAR2 DEFAULT NULL -- Defect 20687 V4.0
                                 ,p_invoice_source   IN  VARCHAR2 DEFAULT NULL -- Defect 3679
                                 ,p_default_date     IN  VARCHAR2              -- Defect 3679
                                 ,p_error_message    IN  VARCHAR2  DEFAULT 'N' -- Defect 3944
                                 ,p_request_id       IN  NUMBER --Defect 4609 - Defect#2569, post updates used only for updating Interface Status to NULL
  );
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_GET_GL_COA                                                |
-- | Description : proceudure to derive segments                         |
-- | Parameters : p_oloc,p_sloc,p_line_id,p_acc_class,p_rev_account      |
-- | Returns    : x_company,x_costcenter,x_account,x_location,           |
-- |              x_intercompany,x_lob,x_future,x_ccid,x_error_message   |
-- +=====================================================================+
PROCEDURE XX_GET_GL_COA(
   p_oloc         IN VARCHAR2
  ,p_sloc         IN VARCHAR2
  ,p_oloc_type    IN VARCHAR2
  ,p_sloc_type    IN VARCHAR2
  ,p_line_id      IN NUMBER
  ,p_acc_class    IN VARCHAR2
  ,p_rev_account  IN VARCHAR2
  ,p_cust_type    IN VARCHAR2
  ,p_trx_type     IN VARCHAR2
  ,p_log_flag     IN VARCHAR2
  ,p_tax_state    IN VARCHAR2
  ,p_tax_loc      IN VARCHAR2
  ,p_description  IN VARCHAR2
  ,x_company      OUT VARCHAR2
  ,x_costcenter   OUT VARCHAR2
  ,x_account      OUT VARCHAR2
  ,x_location     OUT VARCHAR2
  ,x_intercompany OUT VARCHAR2
  ,x_lob          OUT VARCHAR2
  ,x_future       OUT VARCHAR2
  ,x_ccid         OUT VARCHAR2
  ,x_error_message OUT VARCHAR2
  );
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- | Name : XX_AR_CREATE_ACCT_SLEEP_PROC                                 |
-- +=====================================================================+
-- | Description : This Procedure is used for preventing E0080B Child    |
-- |               from releasing extra records for Auto invoice Master  |
-- |               program                                               |
-- | Parameters :  p_master_req_id,p_inv_source                          |
-- +=====================================================================+
PROCEDURE  XX_AR_CREATE_ACCT_SLEEP_PROC(
                                        p_master_req_id   IN NUMBER
                                       ,p_inv_source      IN VARCHAR2
                                       );


/* Defect #2569 - Prakash Sankaran - New Procedure created to insert tax lines
/************************************************************************************/
/*  Name:  XX_AR_INSERT_TAX_LINES                                                   */
/*  Description: This procedure introduces tax lines to the RA_INTERFACE_LINES_ALL  */
/*               table by reading tax values from the OM tables.                    */
/*               In addition, this procedure will introduce TAX lines only for      */
/*               REVENUE lines that have a transaction type with the TAX_CALCULATION*/
/*               flag set to 'N'.                                                   */
/*  Parameters: p_sales_order_low, p_sales_order_high, p_country, p_request_id      */
/*              ,p_invoice_source                                                   */
/************************************************************************************/
PROCEDURE XX_AR_INSERT_TAX_LINES( p_sales_order_low  IN VARCHAR2
				 ,p_sales_order_high IN VARCHAR2
				 ,p_country          IN VARCHAR2
				 ,p_request_id       NUMBER
				 ,p_invoice_source   IN VARCHAR2   DEFAULT NULL -- Added for Defect#2569-V-2.84
				 ,x_error_msg        OUT VARCHAR2 -- Added for Defect#2569-V-2.84
                                );

END XX_AR_CREATE_ACCT_CHILD_PKG;
/
SHOW ERROR;