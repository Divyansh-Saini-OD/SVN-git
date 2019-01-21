CREATE OR REPLACE 
PACKAGE XX_AR_VENDOR_COMP_INV_EXTRACT
AS
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 	 	:  XX_AR_VENDOR_COMP_INV_EXTRACT                                             |
-- |  Description	:  PLSQL Package to extract AR Subledger Accounting Information             |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         082318       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
    PROCEDURE vps_netting_extract(
        p_errbuf       OUT     VARCHAR2,
        p_retcode      OUT     VARCHAR2,
		p_run_date	   IN      DATE,
        p_debug        IN      VARCHAR2);
END XX_AR_VENDOR_COMP_INV_EXTRACT;
/