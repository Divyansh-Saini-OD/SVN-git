SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_OD_BYPASS_ACH_BANKS

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- =====================================================================================
--  Office Depot
--  Name:           XX_OD_BYPASS_ACH_BANKS
--  Description:    This function is designed to be used in VPD policy
--                  XX_OD_BYPASS_ACH_BANKS to prevent lockbox processing from
--                  looking for bank accounts created for making ACH payments.
--
--  Modification Log:
--  ------------------------------------------------------------------------------------
--  Version         Date         Author           Change Description
--  ------------------------------------------------------------------------------------
--  1.0             8/27/2012    P.Sankaran       New version
-- =====================================================================================

begin
dbms_rls.add_policy (object_schema => 'AP',
	                                       object_name => 'AP_BANK_ACCOUNTS_ALL',
	                                       policy_name => 'XX_OD_BYPASS_ACH_BANKS',
	                                       function_schema => 'APPS',
	                                       policy_function => 'XX_OD_BYPASS_ACH_BANKS',
	                                       statement_types => 'select');

end;
/


show errors;
