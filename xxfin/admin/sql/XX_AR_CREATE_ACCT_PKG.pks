SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF

SET TERM         ON

PROMPT Creating Package Specification XX_AR_CREATE_ACCT_PKG 
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_AR_CREATE_ACCT_PKG AUTHID CURRENT_USER
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_CREATE_ACCT_PROC                                       |
-- | RICE ID: E0080                                                      |
-- | Description : proceudure to extend the existing Oracle process      |
-- |               of  creating accounting segments based on the         |
-- |               business rules of office depot                        |
-- |                                                                     |
-- | Parameters : p_run_flag, p_email_address,p_sales_order_low          |
-- |             ,p_sales_order_high,p_display_log,p_invoice_source      |
-- |             ,p_default_date,p_error_message                         |
-- | Returns   : x_error_buff, x_ret_code                                |
-- +=====================================================================+
PROCEDURE  XX_AR_CREATE_ACCT_PROC(
                                  x_err_buff      OUT VARCHAR2
                                 ,x_ret_code      OUT NUMBER
                                 ,p_run_flag      IN VARCHAR2 DEFAULT 'B'
                                 ,p_email_address IN VARCHAR2 DEFAULT NULL
                                 ,p_sales_order_low IN VARCHAR2
                                 ,p_sales_order_high IN VARCHAR2
                                 ,p_display_log      IN VARCHAR2 DEFAULT 'N' --Defect 3418
                                 ,p_invoice_source   IN VARCHAR2  --Defect 3679
                                 ,p_default_date     IN VARCHAR2  --Defect 3679
                                 ,p_error_message    IN VARCHAR2  DEFAULT 'N'--Defect 3944
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
END XX_AR_CREATE_ACCT_PKG;
/
SHO ERR;