SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE xxod_ap_supplier_audit_pkg AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    IT Convergence/Office Depot                    |
-- +===================================================================+
-- | Name             :  xxod_ap_supplier_audit_pkg                    |
-- | Description      :  This Package is used by Financial Reports     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 31-AUG-2007  Kantharaja       Initial draft version       |
-- |V1.1      13-JAN-08   Aravind A.       Fixed defect 4345           |
-- +===================================================================+
PROCEDURE ap_flash_back(p_begin_date DATE
			,p_end_date DATE);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Wirpo / Office Depot                             |
-- +===================================================================+
-- | Name             :  ap_flash_back  			                       |
-- | Description      :  This Procedure is used to Populate the        |
-- |                     vendor, vendor sites and audit details        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1.0 31-AUG-2007  Kantharaja      Initial draft version       |
-- +===================================================================+

FUNCTION GET_TERMS_NAME(P_TERMS_ID NUMBER)
RETURN VARCHAR2;
 
FUNCTION GET_LIABILITY_ACCT_NUM(P_CC_ID NUMBER)
RETURN VARCHAR2;

PROCEDURE PROCESS_VENDORS(p_begin_date DATE,p_end_date DATE);

PROCEDURE PROCESS_VENDOR_SITES(p_begin_date DATE,p_end_date DATE);

/*Function Added By Ganesan For showing the data in New Supplier and Existing Supplier Changes in order,
for defect 4878*/

FUNCTION VENDOR_SEQ(P_TRANSLATION_NAME IN VARCHAR2,P_SRC_VALUE IN VARCHAR2)
RETURN VARCHAR2;

END xxod_ap_supplier_audit_pkg;
/
SHOW ERROR