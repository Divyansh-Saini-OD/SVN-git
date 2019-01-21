SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  IEX_F_OD_GOVT_FAX_V.vw                           |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |                                                                   | 
-- +===================================================================+
CREATE OR REPLACE FORCE VIEW IEX_F_OD_GOVT_FAX_V(CUSTOMER_SITE_USE_ID) AS 
  SELECT DEL.customer_site_use_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT HCA.cust_account_id
              FROM   hz_cust_accounts_all HCA
                    ,hz_cust_acct_sites_all HCAS
                    ,hz_cust_site_uses_all HCU
                    ,hz_cust_account_roles HCR
                    ,hz_parties HP
                    ,hz_role_responsibility HRR
                    ,iex_contact_points_v HCP
                    ,iex_contact_points_v HCP1
              WHERE  HCA.cust_account_id        = DEL.cust_account_id
              AND    HCU.site_use_id           = DEL.customer_site_use_id
              AND    HCA.cust_account_id        = HCAS.cust_account_id
              AND    HCAS.cust_acct_site_id     = HCU.cust_acct_site_id
              AND    HCU.site_use_code          = 'BILL_TO'
              AND    HCU.status                 = 'A'
              AND    HCU.cust_acct_site_id      = HCR.cust_acct_site_id
              AND    HCR.party_id               = HCP.owner_table_id
              AND    HCR.party_id               = HCP1.owner_table_id
              AND    HCR.cust_account_role_id   = HRR.cust_account_role_id
  -- Start for Defect 6902
   /* Added conditions for Contact role and Business purpose  */
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.phone_line_type        = 'FAX'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902
              AND    UPPER(HP.category_code) in
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_GOVT'
                                       AND    FFV.ENABLED_FLAG = 'Y'));
/
SHOW ERRORS;
EXIT;



