SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
CREATE  oR REPLACE PACKAGE XX_AP_TRIAL_BAL_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :   XXAPTRIALBALPKG.pks                                            |
-- | Rice Id     :  E0453_AP Trial Balance                                          |
-- | Description :  This script creates custom package body required for            |
-- |                AP Trial Balance                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |1.0      02-NOV-2007  Rahul Bagul      Initial draft version                    |
-- |                                                                                |
-- +================================================================================+
AS
-- +================================================================================+
-- | Name        :  get_approval_status                                             |
-- | Description :  This  custom procedure is main procedure.  It will return       |
-- |                approval status of invoice                                      |
-- | Parameters   : p_invoice_id,p_invoice_amount,p_payment_status_flag,            |
-- |                p_invoice_type_lookup_code, p_org_id                            |
-- +================================================================================+
   
FUNCTION get_approval_status (p_invoice_id IN NUMBER
				 , p_invoice_amount IN NUMBER
				 , p_payment_status_flag IN VARCHAR2
				 , p_invoice_type_lookup_code IN VARCHAR2
                                 ,  p_org_id IN NUMBER)
 RETURN VARCHAR2;
        

END XX_AP_TRIAL_BAL_PKG;
/

SHOW ERROR