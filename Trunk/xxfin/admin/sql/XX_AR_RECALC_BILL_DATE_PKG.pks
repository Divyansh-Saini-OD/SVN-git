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
-- +============================================================================================+

PROCEDURE log_exception ( p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		                 ,p_error_msg          IN  VARCHAR2);
						               
PROCEDURE update_new_bill_date(p_errbuf         OUT  VARCHAR2
                              ,p_retcode        OUT  VARCHAR2
                              ,p_debug          IN   VARCHAR2);
                         	  
END XX_AR_RECALC_BILL_DATE_PKG;
/
SHOW ERRORS;