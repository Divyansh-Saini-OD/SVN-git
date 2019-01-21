SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON



CREATE OR REPLACE VIEW XX_AR_HZ_CUST_ACCOUNTS_V AS 
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                            Office Depot                            |
-- +====================================================================+
-- | Name  : XX_AR_HZ_CUST_ACCOUNTS_V                                   |
-- | Description: Custom view for the Value set to fetch the customer   |
-- |              details for QC Defect ID 3261 (CR 622)                |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date         Author            Remarks                    |
-- |=======   ==========   =============     ===========================|
-- |1.0       16-DEC-2009  Vinaykumar S       Initial version           |
-- +===================================================================+|
SELECT  HCA.cust_account_id
       ,HCA.account_name
       ,HCA.account_number
       ,ARSC.statement_cycle_id
FROM  HZ_CUST_ACCOUNTS HCA
     ,AR_STATEMENT_CYCLES ARSC
WHERE HCA.status  = 'A'
AND  EXISTS (
               SELECT 1
               FROM  HZ_CUSTOMER_PROFILES HCP
               WHERE HCA.cust_account_id     = HCP.cust_account_id
               AND   HCP.statement_cycle_id  = ARSC.statement_cycle_id
               AND   HCP.status              = 'A'
               AND   HCP.send_statements     = 'Y'
             )

/