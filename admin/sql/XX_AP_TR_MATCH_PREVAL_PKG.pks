CREATE OR REPLACE PACKAGE XX_AP_TR_MATCH_PREVAL_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_AP_TR_MATCH_PREVAL_PKG                                                       |
-- |  RICE ID 	 :  E3522_OD Trade Match Foundation     			                            |
-- |  Description:         								                                        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/06/2017   Havish Kasina    Initial version                                  |
-- | 1.1         11/20/2017   Paddy Sanjeevi   Added p_invoice_id parameter                     |
-- | 1.2         02/26/2018   Paddy Sanjeevi   Added xx_hold_invoices                           |
-- +============================================================================================+
              
PROCEDURE main(p_errbuf       OUT  VARCHAR2
              ,p_retcode      OUT  VARCHAR2
			  ,p_source		  IN   VARCHAR2			  
              ,p_debug        IN   VARCHAR2
			  ,p_invoice_id   IN   NUMBER);
			  
PROCEDURE xx_hold_invoices(p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2);			  
                      	  
END XX_AP_TR_MATCH_PREVAL_PKG;
/
SHOW ERRORS;