CREATE OR REPLACE 
PACKAGE XX_AP_VPS_EXTRACT_PKG
AS
-- +============================================================================================+
-- |  					Office Depot - Project Simplify                                         |
-- +============================================================================================+
-- |  Name	 		:  XX_AP_VPS_EXTRACT_PKG                                                    |
-- |  Description	:  PLSQL Package to extract Matched and UnMatched Invoiced for VPS          |
-- |  Change Record	:                                                                           |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         012918       Dinesh Nagapuri  Initial version                                  |
-- +============================================================================================+
PROCEDURE invoice_vps_extract(p_errbuf       OUT  VARCHAR2
							 ,p_retcode      OUT  VARCHAR2
							  );
END XX_AP_VPS_EXTRACT_PKG;
/