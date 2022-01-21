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
-- | 1.1         042518       Paddy Sanjeevi   Added Get_location, xx_ap_get_gl_acct function   |
-- +============================================================================================+

FUNCTION get_location(p_po_header_id IN NUMBER) RETURN VARCHAR2;

FUNCTION xx_ap_get_gl_acct
  (p_invoice_id IN NUMBER,
   p_line_no	IN NUMBER,
   p_line_type	IN VARCHAR2
   )
RETURN VARCHAR2;

PROCEDURE invoice_vps_extract(p_errbuf       OUT  VARCHAR2
							 ,p_retcode      OUT  VARCHAR2
							  );
END XX_AP_VPS_EXTRACT_PKG;
/