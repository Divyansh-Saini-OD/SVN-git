-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Providge Consulting                           |
-- +=====================================================================+
-- | Name :  XX_AR_ORA_LEG_CUST_NUMBER                                   |
-- | Description : view to have both oracle and legacy customers         |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       07-JAN-2010   Tamil Vendhan L  ,   Created Base version    |
-- |                        Wipro Technologies   for R1.2 CR 466 Defect  |
-- |                                             1210                    |
-- |1.1       21-SEP-2010   Sambasiva Reddy D    Removed AB flag for     |
-- |                                             defect # 8037           |
-- +=====================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE VIEW XX_AR_ORA_LEG_CUST_NUMBER 
AS
(
   SELECT HCA.account_number customer_number
         ,HCA.cust_account_id
         ,HCA.account_name
         ,'Oracle Customer Number' cust_num_type
   FROM   hz_cust_accounts     HCA
         ,hz_customer_profiles HCP
   WHERE  HCA.cust_account_id = HCP.cust_account_id
   AND    HCP.site_use_id     IS NULL
   AND    HCA.status          = 'A'
--   AND    HCP.attribute3      = 'Y'  -- Commnented for Defect # 8037
   AND    HCP.status          = 'A'
   UNION ALL
   SELECT substr(HCA.orig_system_reference,1,8) customer_number
         ,HCA.cust_account_id
         ,HCA.account_name
         ,'AOPS Customer Number' cust_num_type
   FROM   hz_cust_accounts     HCA
         ,hz_customer_profiles  HCP
   WHERE  HCA.cust_account_id = HCP.cust_account_id
   AND    HCP.site_use_id IS NULL
   AND    HCA.status          = 'A'
--   AND    HCP.attribute3      = 'Y'    -- Commnented for Defect # 8037
   AND    HCP.status          = 'A'
);
SHOW ERROR