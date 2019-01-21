SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_OD_BYPASS_ACH_BANK_USES

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
-- +====================================================================================+
-- |                                  Office Depot                                      |
-- +====================================================================================+
-- | Name:           XX_OD_BYPASS_ACH_BANK_USES                                         |
-- | Description:    This function is designed to be used in VPD policy                 |
-- |                 XX_OD_BYPASS_ACH_BANK_USES to prevent lockbox processing from      |
-- |                 looking for bank accounts created for making ACH payments.         |
-- |                                                                                    |
-- | Modification Log:                                                                  |
-- | -----------------------------------------------------------------------------------|
-- | Version      Date          Author                  Change Description              |
-- | -----------------------------------------------------------------------------------|
-- | 1.0          10-SEP-2012   Bapuji Nanapaneni       New version                     |
-- | 2.0          14-Feb-2014   Avinash			Defect 28191. Added policy on   |
-- |							r12 table                       |
-- | 3.0          03-Nov-2015   Avinash                 R12.2 Compliance Changes        |
-- | 4.0          26-May-2016   Avinash                 Fix for R12.2 Compliance.       |
-- +====================================================================================+

BEGIN
  --For defect 28191
  /*dbms_rls.add_policy ( object_schema   => 'AP'
                      , object_name     => 'AP_BANK_ACCOUNT_USES_ALL'
                      , policy_name     => 'XX_OD_BYPASS_ACH_BANK_USES'
                      , function_schema => 'APPS'
                      , policy_function => 'XX_OD_BYPASS_ACH_BANK_USES'
                      , statement_types => 'select'
                      );*/

  /*dbms_rls.add_policy ( object_schema   => 'IBY'
                      , object_name     => 'IBY_PMT_INSTR_USES_ALL'
                      , policy_name     => 'XX_OD_BYPASS_ACH_BANK_USES'
                      , function_schema => 'APPS'
                      , policy_function => 'XX_OD_BYPASS_ACH_BANK_USES'
                      , statement_types => 'select'
                      );*/
                      
  -- R12.2 Changes - drop the policy if it exists, otherwise ignore any errors
  fnd_access_control_util.drop_policy( p_object_schema => 'IBY',
  				       p_object_name   => 'IBY_PMT_INSTR_USES_ALL',
  				       p_policy_name   => 'XX_OD_BYPASS_ACH_BANK_USES');

  fnd_access_control_util.add_policy ( 	  p_object_schema => 'APPS'
                      			, p_object_name   => 'IBY_PMT_INSTR_USES_ALL'
                      			, p_policy_name   => 'XX_OD_BYPASS_ACH_BANK_USES'
                      			, p_function_schema => 'APPS'
                      			, p_policy_function => 'XX_OD_BYPASS_ACH_BANK_USES'
                      			, p_statement_types => 'SELECT'
                      		     );  

END;
/
SHOW ERRORS;
