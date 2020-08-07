-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        : XX_FIN_CASH_ACCOUNT_V                                       |
-- | Description : View created to be used for as value set for the parameter  |
-- |               "Cash Natural Account"for the concurrent program            |
-- |               "OD: CM General Ledger Reconciliation"                      | 
-- |  Rice ID    : R0465                                                       |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                 Remarks                 |
-- |=======    ==========     =============            ======================  |
-- |  1.0      21-AUG-2013    Deepak V       	       R0465 - Initial version |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE



CREATE or REPLACE VIEW XX_FIN_CASH_ACCOUNT_V AS
SELECT DISTINCT segment3
  FROM gl_code_combinations g
  WHERE EXISTS
    (
    SELECT 1
    FROM ce_bank_accounts a
       , (
          select default_legal_context_id from hr_operating_units
          where organization_id      = FND_PROFILE.VALUE('ORG_ID')
         ) b       
    WHERE g.code_combination_id=a.asset_code_combination_id
      AND a.account_owner_org_id = b.default_legal_context_id
    );

