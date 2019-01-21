SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_cdh_role_restrict_pkg AUTHID CURRENT_USER

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CDH_ROLE_RESTRICT_PKG                                   |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package part of the VPD Implementation. Contains the|
-- |               functions to return the predicate for Tables during Insert,|
-- |               Update or Delete, based on the Profile Values. Profile     |
-- |               'XX_CDH_SEC_BYPASS_SEC_RULES' shall determine if VPD can be|
-- |               bypassed.                                                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 12-Jul-2007 Prem Kumar             Initial draft version         |
-- |Draft 1b 13-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      XX-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |2.0      27-Dev-2007 Rajeev Kamath          Bug Fixes - Profiles not used |
-- +==========================================================================+

AS

-- ----------------------------
-- Global Variable Declarations
-- ----------------------------

        gc_step_number            NUMBER       := 0;

-- ---------------------
-- Function Declarations
-- ---------------------

    -- -----------------------------
    -- HZ_PARTIES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_party_create ( p_obj_schema  IN VARCHAR2
                                  ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTIES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_party_update ( p_obj_schema  IN VARCHAR2
                                  ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_partysite_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_partysite_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITE_USES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_ptysite_uses_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITE_USES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_ptysite_uses_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- HZ_ORGANIZATION_PROFILES Table
    --
    -- Predicate Function for Insert
    -- ------------------------------

        FUNCTION hz_org_profile_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- HZ_ORGANIZATION_PROFILES Table
    --
    -- Predicate Function for Update
    -- ------------------------------

        FUNCTION hz_org_profile_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PERSON_PROFILES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_person_profile_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PERSON_PROFILES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_person_profile_update ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_RELATIONSHIPS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_relationships_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_RELATIONSHIPS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_relationships_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CONTACT_POINTS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_contact_pnt_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CONTACT_POINTS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_contact_pnt_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_CONTACTS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_org_contact_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_CONTACTS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_org_contact_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_CONTACT_ROLES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_org_cnts_rls_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_CONTACT_ROLES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_org_cnts_rls_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCOUNTS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_acct_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCOUNTS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_acct_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUSTOMER_PROFILES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_customer_prf_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUSTOMER_PROFILES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_customer_prf_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCT_SITES_ALL Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_acct_sites_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCT_SITES_ALL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_acct_sites_update ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_SITE_USES_ALL Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_site_uses_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_SITE_USES_ALL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_site_uses_update ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCOUNT_ROLES Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_acct_rls_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCOUNT_ROLES Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_acct_rls_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ROLE_RESPONSIBILITY Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_role_resp_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ROLE_RESPONSIBILITY Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_role_resp_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_PROFILE_AMTS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_profile_amt_create ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_PROFILE_AMTS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_profile_amt_update ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCT_RELATE_ALL Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_cust_acct_rlt_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_CUST_ACCT_RELATE_ALL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_acct_rlt_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- AP_BANK_ACCOUNTS_ALL Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION ap_bank_acct_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- AP_BANK_ACCOUNTS_ALL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION ap_bank_acct_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- AP_BANK_ACCOUNT_USES_ALL Table
    --
    -- Predicate Function for Insert
    -- ------------------------------

        FUNCTION ap_bank_acct_use_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- AP_BANK_ACCOUNT_USES_ALL Table
    --
    -- Predicate Function for Update
    -- ------------------------------

        FUNCTION ap_bank_acct_use_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- RA_CUST_RECEIPT_METHODS Table
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION ra_cust_receipt_mtds_create ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- RA_CUST_RECEIPT_METHODS Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION ra_cust_receipt_mtds_update ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_PROFILES_EXT_B and
    -- HZ_ORG_PROFILES_EXT_TL Tables
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_org_profile_ext_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_PROFILES_EXT_B Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION HZ_ORG_PROFILE_EXT_UPDATE   ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_ORG_PROFILES_EXT_TL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION HZ_ORG_PROFILE_EXT_DELETE    ( p_obj_schema  IN VARCHAR2
                                               ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;


    -- -----------------------------
    -- HZ_PER_PROFILES_EXT_B, TL Tables
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_per_profile_ext_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PER_PROFILES_EXT_B, TL Table
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_per_profile_ext_update ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PER_PROFILES_EXT_B, TL Table
    -- Predicate Function for Delete
    -- -----------------------------

        FUNCTION hz_per_profile_ext_delete ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITES_EXT_B and
    -- HZ_PARTY_SITES_EXT_TL Tables
    --
    -- Predicate Function for Insert
    -- -----------------------------

        FUNCTION hz_party_site_ext_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITES_EXT_B, TL Table
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_party_site_ext_update ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- -----------------------------
    -- HZ_PARTY_SITES_EXT_B, TL Table
    --
    -- Predicate Function for Delete
    -- -----------------------------

        FUNCTION hz_party_site_ext_delete ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;


    -- ------------------------------
    -- XX_CDH_CUST_ACCT_EXT_B and
    -- XX_CDH_CUST_ACCT_EXT_TL Tables
    --
    -- Predicate Function for Insert
    -- ------------------------------

        FUNCTION hz_cust_acct_ext_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_CUST_ACCT_EXT_B and
    -- XX_CDH_CUST_ACCT_EXT_TL Tables
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_cust_acct_ext_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_CUST_ACCT_EXT_B and
    -- XX_CDH_CUST_ACCT_EXT_TL Tables
    --
    -- Predicate Function for Delete
    -- -----------------------------

        FUNCTION hz_cust_acct_ext_delete ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_ACCT_SITE_EXT_B and
    -- XX_CDH_ACCT_SITE_EXT_TL Tables
    --
    -- Predicate Function for Insert
    -- ------------------------------

        FUNCTION hz_acct_site_ext_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_ACCT_SITE_EXT_B and
    -- XX_CDH_ACCT_SITE_EXT_TL Tables
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_acct_site_ext_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_ACCT_SITE_EXT_B and
    -- XX_CDH_ACCT_SITE_EXT_TL Tables
    --
    -- Predicate Function for Delete
    -- -----------------------------

        FUNCTION hz_acct_site_ext_delete ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_SITE_USES_EXT_B and
    -- XX_CDH_SITE_USES_EXT_TL Tables
    --
    -- Predicate Function for Insert
    -- ------------------------------

        FUNCTION hz_acct_site_use_ext_create ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_SITE_USES_EXT_B and
    -- XX_CDH_SITE_USES_EXT_TL Tables
    --
    -- Predicate Function for Update
    -- -----------------------------

        FUNCTION hz_acct_site_use_ext_update ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- XX_CDH_SITE_USES_EXT_B and
    -- XX_CDH_SITE_USES_EXT_TL Tables
    --
    -- Predicate Function for Delete
    -- -----------------------------

        FUNCTION hz_acct_site_use_ext_delete ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- HZ_CODE_ASSIGNMENTS Table
    -- Predicate Function for Insert
    -- -----------------------------
        FUNCTION hz_org_classfn_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

    -- ------------------------------
    -- HZ_CODE_ASSIGNMENTS Table
    -- Predicate Function for Update
    -- -----------------------------
        FUNCTION hz_org_classfn_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2;

END xx_cdh_role_restrict_pkg;
/

SHOW ERRORS;