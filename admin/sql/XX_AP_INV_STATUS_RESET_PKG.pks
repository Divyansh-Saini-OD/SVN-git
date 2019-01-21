CREATE OR REPLACE PACKAGE xx_ap_inv_status_reset_pkg AS
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 		:  XX_AP_INV_STATUS_RESET_PKG                                                |
-- |  Description	:  PLSQL Package to reset event_status_code to 'U' for AP Trade Invoices    |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         19/APR/2017  M K Pramod Kumar Initial version                                  |
-- +============================================================================================+
    PROCEDURE invoice_event_status_reset (
        p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 
	 );

END xx_ap_inv_status_reset_pkg;
/
