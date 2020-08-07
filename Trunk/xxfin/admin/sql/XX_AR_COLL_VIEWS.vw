SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
 
SET TERM ON
 
PROMPT Creating views for US operating Unit and CA operating unit
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- |Name  :  Create Collection Views                                   |
-- |Description      :   This program is used to create Collection     |
-- |                     Views in the apps schema, which work as       |
-- |                     filters to classify the customers of US       |
-- |                     operating unit into six groups based on the   |
-- |                     categories to which they belong.              |
-- |Change Record:                                                     |
-- |==============                                                     |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  ================  ===========================|
-- |DRAFT 1A 13-DEC-2006  Anusha Ramanujam  Initial draft version      |
-- |                                ,WIPRO                             |
-- |                                                                   |
-- |DRAFT 1B 14-DEC-2006  Anusha Ramanujam  Introduced Value Sets to   |
-- |                                ,WIPRO  avoid hardcoding of the    |
-- |                                        categories                 |
-- |                                                                   |
-- |V1.0     06-JUN-2007  Raghunath Ramnath Views updated based on     |
-- |                                ,WIPRO  Customer Site use id in    |
-- |                                        stead of Customer id       |
-- |V1.1     17-DEC-2007  Anitha Devarajulu Views modified based on    |
-- |                                ,WIPRO  Bill To Delivery Email,Fax |
-- |V1.2     22-MAY-2008  Anitha Devarajulu Views modified based on    |
-- |                                ,WIPRO  contact role as Dunning    |
-- |                                        and Business purpose as    |
-- |                                        Dunning for Defect 6902    |
-- |V1.3     30-MAY-2008  Anitha Devarajulu Views added for Direct,    |
-- |                                        Contract for Defect 7390   |
-- |V1.4     11-JUN-2008  Anitha Devarajulu Views modified for         |
-- |                                        Non-Traditional Condition  |
-- |                                        for Defect 6902            |
-- |                                                                   |
-- |V1.5     19-JUN-2008  Anusha Ramanujam  Replaced 'NON-TRADITIONAL' |
-- |                                        with 'NON_TRADITIONAL'     |
-- |                                        everywhere in accordance   |
-- |                                        with the setup             |
-- |                                                                   |
-- |V1.6     24-JUN-2008  Anusha Ramanujam  Modified the Direct Views  |
-- |                                        such that the customers    |
-- |                                        with source 'OTHER' are    |
-- |                                        also defaulted to Direct   |
-- |                                        strategies.                |
-- |                                                                   |
-- |V1.7     30-JUN-2008  Anusha Ramanujam  Renamed US views as generic|
-- |                                        views and commented the CA |
-- |                                        views, for defect 6902     |
-- |                                                                   |
-- +===================================================================+

----------------------IEX_F_OD_MIDLAR_SFA_EMAIL_V----------------------
CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_MIDLAR_SFA_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    HCA.party_id               = hp.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_MIDLAR_SFA_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_MIDLAR_SFA_FAX_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
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
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_MIDLAR_SFA_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_MIDLAR_SFA_TEL_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR    HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_NATIONAL_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NATIONAL_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.party_id               = hp.party_id
              AND    HCA.sales_channel_code     = 'NATIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


----------------------IEX_F_OD_NATIONAL_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NATIONAL_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.sales_channel_code     = 'NATIONAL'
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
);


----------------------IEX_F_OD_NATIONAL_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NATIONAL_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.sales_channel_code     = 'NATIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


 ----------------------IEX_F_OD_SCHOOL_EMAIL_V------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_SCHOOL_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.party_id               = hp.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HP.category_code) in
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_SCHOOL_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_SCHOOL_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_SCHOOL_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_SCHOOL_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
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
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


 ----------------------IEX_F_OD_GOVT_EMAIL_V------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_GOVT_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.party_id               = hp.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HP.category_code) in
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_GOVT'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_GOVT_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_GOVT_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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


----------------------IEX_F_OD_GOVT_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_GOVT_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
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


----------------------IEX_F_OD_DIRECT_CAT_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_DIRECT_CAT_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    HCA.party_id               = hp.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
    --  End for Defect 6902                              
    -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );


----------------------IEX_F_OD_DIRECT_CAT_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_DIRECT_CAT_FAX_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
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
    -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );


----------------------IEX_F_OD_DIRECT_CAT_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_DIRECT_CAT_TEL_V" ("CUSTOMER_SITE_USE_ID") AS
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
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
  -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );


----------------------IEX_F_OD_NONTRAD_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NONTRAD_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.party_id               = hp.party_id
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


----------------------IEX_F_OD_NONTRAD_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NONTRAD_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
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
);


----------------------IEX_F_OD_NONTRAD_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_NONTRAD_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


----------------------IEX_F_OD_US_DIRECT_SITE_V-------------------------
        -- Views added for defect 7390                        

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_DIRECT_SITE_V" ("CUSTOMER_SITE_USE_ID") AS 
SELECT DEL.customer_site_use_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id
              FROM   hz_cust_accounts HCA
              WHERE  HCA.cust_account_id = DEL.cust_account_id
              AND    HCA.attribute18     = 'DIRECT');


----------------------IEX_F_OD_US_CONTRACT_SITE_V-------------------------
        -- Views added for defect 7390                        

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_US_CONTRACT_SITE_V" ("CUSTOMER_SITE_USE_ID") AS 
SELECT DEL.customer_site_use_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id
              FROM   hz_cust_accounts HCA
              WHERE  HCA.cust_account_id = DEL.cust_account_id
              AND    HCA.attribute18     = 'CONTRACT');



--Commented by Anusha on 30-JUN-08 to have generic views instead of US and CA views separately
/*
----------------------CA Operating Unit---------------------------------
----------------------IEX_F_OD_CA_MIDLAR_SFA_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_MIDLAR_SFA_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS
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
  -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = hp.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_CA_MIDLAR_SFA_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_MIDLAR_SFA_FAX_V" ("CUSTOMER_SITE_USE_ID") AS
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
  -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
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
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_CA_MIDLAR_SFA_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_MIDLAR_SFA_TEL_V" ("CUSTOMER_SITE_USE_ID") AS
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
   -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HCA.attribute19)     = 'SFA'       --Source of Creation for Credit info
              -- Not for School and Govt category
              AND   (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
              );


----------------------IEX_F_OD_CA_NATIONAL_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NATIONAL_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCA.sales_channel_code     = 'NATIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


----------------------IEX_F_OD_CA_NATIONAL_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NATIONAL_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCA.sales_channel_code     = 'NATIONAL'
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
);


----------------------IEX_F_OD_CA_NATIONAL_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NATIONAL_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCA.sales_channel_code     = 'NATIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


 ----------------------IEX_F_OD_CA_SCHOOL_EMAIL_V------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_SCHOOL_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = hp.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HP.category_code) in
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_CA_SCHOOL_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_SCHOOL_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose
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
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_CA_SCHOOL_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_SCHOOL_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
   -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
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
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_SCHOOL'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


 ----------------------IEX_F_OD_CA_GOVT_EMAIL_V------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_GOVT_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
 -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = hp.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
              AND    UPPER(HP.category_code) in
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name = 'XX_AR_CUST_GOVT'
                                       AND    FFV.ENABLED_FLAG = 'Y'));


----------------------IEX_F_OD_CA_GOVT_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_GOVT_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose
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


----------------------IEX_F_OD_CA_GOVT_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_GOVT_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
   -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
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


----------------------IEX_F_OD_CA_DIRECT_CAT_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_DIRECT_CAT_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS
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
   -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = hp.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
    -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );


----------------------IEX_F_OD_CA_DIRECT_CAT_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_DIRECT_CAT_FAX_V" ("CUSTOMER_SITE_USE_ID") AS
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
  -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
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
    -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );


----------------------IEX_F_OD_CA_DIRECT_CAT_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_DIRECT_CAT_TEL_V" ("CUSTOMER_SITE_USE_ID") AS
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
   -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    (HCA.sales_channel_code    NOT IN ('NATIONAL','NON_TRADITIONAL')
              OR     HCA.sales_channel_code     IS NULL)
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
    -- Included source of creation 'OTHER' by Anusha on '24-JUN-08' for direct customers
              AND    UPPER(HCA.attribute19)     IN ('CATALOG', 'OTHER')     --Source of Creation for Credit info
              -- Not for School and Govt category
              AND    (UPPER(HP.category_code) NOT IN 
                                      (SELECT UPPER(FFV.FLEX_VALUE)
                                       FROM   FND_FLEX_VALUE_SETS FFVS
                                             ,FND_FLEX_VALUES     FFV
                                       WHERE  FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                                       AND    FFVS.flex_value_set_name IN ('XX_AR_CUST_SCHOOL','XX_AR_CUST_GOVT')
                                       AND    FFV.ENABLED_FLAG = 'Y')
              OR  HP.category_code IS NULL)
             );
*/

----------------------IEX_F_OD_CA_DIRECT_SITE_V-------------------------
        -- Views added for defect 7390                        

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_DIRECT_SITE_V" ("CUSTOMER_SITE_USE_ID") AS 
SELECT DEL.customer_site_use_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id
              FROM   hz_cust_accounts HCA
              WHERE  HCA.cust_account_id = DEL.cust_account_id
              AND    HCA.attribute18     = 'DIRECT');


----------------------IEX_F_OD_CA_CONTRACT_SITE_V-------------------------
        -- Views added for defect 7390                        

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_CONTRACT_SITE_V" ("CUSTOMER_SITE_USE_ID") AS 
SELECT DEL.customer_site_use_id
FROM   iex_f_accounts_V DEL
WHERE  EXISTS(SELECT cust_account_id
              FROM   hz_cust_accounts HCA
              WHERE  HCA.cust_account_id = DEL.cust_account_id
              AND    HCA.attribute18     = 'CONTRACT');


/*
----------------------IEX_F_OD_CA_NONTRAD_EMAIL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NONTRAD_EMAIL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
   -- Added conditions for Contact role and Business purpose 
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = hp.party_id
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'EMAIL'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.phone_line_type       IN ('GEN','FAX')
              AND    (HCP1.contact_point_type    = 'PHONE'
              OR     HCP1.contact_point_type    IS NULL)
              OR     HCP1.phone_line_type       IS NULL)
              AND    (HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);


----------------------IEX_F_OD_CA_NONTRAD_FAX_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NONTRAD_FAX_V" ("CUSTOMER_SITE_USE_ID") AS 
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
  -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
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
);


----------------------IEX_F_OD_CA_NONTRAD_TEL_V----------------------

CREATE OR REPLACE VIEW "APPS"."IEX_F_OD_CA_NONTRAD_TEL_V" ("CUSTOMER_SITE_USE_ID") AS 
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
   -- Added conditions for Contact role and Business purpose
              AND    HRR.primary_flag           = 'Y'
              AND    HRR.responsibility_type    = 'DUN'
              AND    HCA.party_id               = HP.party_id
              AND    HCA.sales_channel_code     = 'NON_TRADITIONAL'
              AND    HCP.status                 = 'A'
              AND    HCP.primary_flag           = 'Y'
              AND    HCP.contact_point_type     = 'PHONE'
              AND    HCP.phone_line_type        = 'GEN'
              AND    HCP.contact_point_purpose  = 'DUNNING'
              AND    (HCP1.contact_point_type    IN ('EMAIL','PHONE')
              OR     HCP1.contact_point_type      IS NULL)
              AND    (HCP1.contact_point_purpose != 'COLLECTIONS'
              OR     HCP1.contact_point_purpose = 'COLLECTIONS'
              OR     HCP1.contact_point_purpose IS NULL)
  --  End for Defect 6902                              
);
*/

SHOW ERROR