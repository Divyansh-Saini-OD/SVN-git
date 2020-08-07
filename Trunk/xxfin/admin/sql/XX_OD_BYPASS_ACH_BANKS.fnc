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

Create or replace function XX_OD_BYPASS_ACH_BANKS (p_schema varchar2, p_obj varchar2)
Return varchar2
As 
	lc_add_predicate VARCHAR2(200);
Begin 
	if SYS_CONTEXT('userenv', 'module') = 'XX_ARLPLB' OR
           SYS_CONTEXT('userenv', 'module') = 'ARLPLB' then
	        lc_add_predicate := ' bank_account_type not in  (''BUSINESS CHECKING'', ''BUSINESS SAVINGS'', ''PERSONAL CHECKING'', ''PERSONAL SAVINGS'', ' ||
                                    ' ''BUSINESSCHECKING'', ''BUSINESSSAVINGS'', ''PERSONALCHECKING'', ''PERSONALSAVING'')'; 
	else 
		lc_add_predicate := '';
	end if;
    return lc_add_predicate;
End;
/
show errors;
