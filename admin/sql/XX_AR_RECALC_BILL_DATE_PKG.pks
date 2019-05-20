CREATE OR REPLACE PACKAGE XX_AR_RECALC_BILL_DATE_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AR_RECALC_BILL_DATE_PKG                                                      |
-- |  RICE ID 	 : I3126      			                                                        |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author          Remarks                                           |
-- | =========   ===========  =============   ==================================================|
-- | 1.0         18-OCT-2018  Havish Kasina   Initial version                                   |    
-- | 1.1         21-JAN-2019  Havish Kasina   Added new parameter p_billing_date                |              
-- +============================================================================================+

PROCEDURE log_exception ( p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		                 ,p_error_msg          IN  VARCHAR2);
						               
PROCEDURE update_new_bill_date(p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  VARCHAR2
                              ,p_debug          IN   VARCHAR2
							  ,p_billing_date   IN   VARCHAR2);

PROCEDURE insert_new_bill_signal(p_debug          IN   VARCHAR2
							  ,p_billing_date   IN   DATE
							  ,p_customer_id	IN   NUMBER
							  );                         	  
END XX_AR_RECALC_BILL_DATE_PKG;
/
SHOW ERRORS;