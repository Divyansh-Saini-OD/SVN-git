CREATE OR REPLACE PACKAGE XX_AP_TERMS_DATE_CALC_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_TERMS_DATE_CALC_PKG                                                       |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         01/16/2018   Naveen Patha   Initial version                                  |
-- +============================================================================================+
FUNCTION get_invoice_status(p_creation_date IN DATE,p_invoice_id IN NUMBER) 
RETURN VARCHAR2;              
PROCEDURE update_ap_invoices(p_errbuf       OUT  VARCHAR2
                            ,p_retcode      OUT  VARCHAR2
							,p_batch_id     IN   NUMBER);
PROCEDURE terms_date_main(p_errbuf       OUT  VARCHAR2
                         ,p_retcode      OUT  VARCHAR2
     					 ,p_threads       IN NUMBER);
                      	  
END XX_AP_TERMS_DATE_CALC_PKG;
/
SHOW ERRORS;