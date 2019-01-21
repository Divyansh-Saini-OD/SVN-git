SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_TRIAL_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
create or replace PACKAGE XX_AP_TRIAL_WRAP_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      AP Trail Report Wrapper Child                         |
-- | Description : To pupulate the invoices according to the vendor    |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       22-DEC-2010  RamyaPriya M        Initial version         |
-- |1.3       04-NOV-13    Veronica            R0453- Modified for     |  
-- |                                           defect # 26068          |
-- +===================================================================+

 PROCEDURE XX_VENDOR_SITES_MASTER (x_error_buff         OUT VARCHAR2
                                  ,x_ret_code           OUT NUMBER
                                  ,p_batch_size         IN  NUMBER
                                  ,p_no_workers         IN  NUMBER
                                  );

 PROCEDURE XX_INV_SITES_CHILD  (x_error_buff         OUT VARCHAR2
                              ,x_ret_code           OUT NUMBER
                              ,p_batch_size         IN  NUMBER
                              ,p_thread_count       IN NUMBER               --Added for Defect#26028
                              --,p_min_site_id        IN  NUMBER     
                              --,p_max_site_id        IN  NUMBER
                              ,p_min_invoice_id    IN  NUMBER                 --Added/Commented for Defect#26028
                              ,p_max_invoice_id    IN  NUMBER
                               );

  FUNCTION XX_AP_TRIAL_APP_STATUS ( p_invoice_id IN NUMBER
                                  ) RETURN VARCHAR2;
  FUNCTION get_posting_status(p_invoice_id IN NUMBER  
                                ,p_acc_met_opt IN VARCHAR2
                                ,p_sacc_met_opt IN VARCHAR2     )
         RETURN VARCHAR2;
  function get_discount_amount(p_invoice_id IN NUMBER) RETURN NUMBER;
  function get_due_date(p_invoice_id IN NUMBER) RETURN VARCHAR2;
		
END XX_AP_TRIAL_WRAP_PKG;
/
