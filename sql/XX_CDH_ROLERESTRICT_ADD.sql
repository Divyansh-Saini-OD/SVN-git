SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

  -- +====================================================================================+
  -- |                  Office Depot - Project Simplify                                   |
  -- |                 Oracle NAIO Consulting Organization                                |
  -- +====================================================================================+
  -- |                                                                                    |
  -- | Name             :  XX_CDH_ROLE_RESTRICT_ADD_POLICY                                |
  -- | Rice ID          :  E0266_RoleRestrictionsMerges                                   |
  -- | Description      :  This custom block shall be executed to apply a policy to the   |
  -- |                     tables. The package returning predicate should also be         |
  -- |                     installed.  Policy is applied on INSERT, UPDATE and DELETE     |
  -- |                     operations.This shall be run by DB Administrators.             |
  -- |                                                                                    |
  -- | Change Record:                                                                     |
  -- |===============                                                                     |
  -- |Version   Date        Author           Remarks                                      |
  -- |=======   ==========  =============    =============================================|
  -- |Draft 1a  12-Jul-07   Prem Kumar       Initial draft version                        |
  -- |1.0       31-Aug-07   Hema Chikkanna   Baselined after review                       |
  -- |1.1       18-Sep-07   Rajeev Kamath    Added termination for ITG execution          |
  -- |1.2       01-Aug-13   Pratesh Shukla   Updated for R12 RETROFIT  for RICE E0266
  --                                         , changes made are table 'AP_BANK_ACCOUNT_USES' 
  --                                         replaced with 'IBY_PMT_INSTR_USES_ALL', table 
  --                                         'AP_BANK_ACCOUNTS' replaced with 'IBY_EXT_BANK_ACCOUNTS'
  -- |1.3       25-Oct-16	Madhu Bolli		 Removing the 2 policies on 'HZ_CODE_ASSIGNMENTS' |
  -- |										  for defect#39493							  |			
  -- +====================================================================================+

PROMPT
PROMPT 'Apply policy on TCA tables...'
PROMPT

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTIES#'
                        ,'XX_CDH_INS_PLCY_HZ_PARTIES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_CREATE'
                        ,'INSERT'
                        );
END;
/


BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTIES#'
                        ,'XX_CDH_UPD_PLCY_HZ_PARTIES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_UPDATE'
                        ,'UPDATE'
                       );
END;
/


BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES#'
                        ,'XX_CDH_INS_PLCY_HZ_PARTY_SITES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTYSITE_CREATE'
                        ,'INSERT'
                       );
END;
/


BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES#'
                        ,'XX_CDH_UPD_PLCY_HZ_PARTY_SITES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTYSITE_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITE_USES#'
                        ,'XX_CDH_INS_PLCY_HZ_PS_USES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PTYSITE_USES_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITE_USES#'
                        ,'XX_CDH_UPD_PLCY_HZ_PS_USES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PTYSITE_USES_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORGANIZATION_PROFILES#'
                        ,'XX_CDH_INS_PLCY_HZ_ORG_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORGANIZATION_PROFILES#'
                        ,'XX_CDH_UPD_PLCY_HZ_ORG_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PERSON_PROFILES#'
                        ,'XX_CDH_INS_PLCY_HZ_PER_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PERSON_PROFILE_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PERSON_PROFILES#'
                        ,'XX_CDH_UPD_PLCY_HZ_PER_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PERSON_PROFILE_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_RELATIONSHIPS#'
                        ,'XX_CDH_INS_PLCY_HZ_RELNS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_RELATIONSHIPS_CREATE'
                        ,'INSERT'
                        ,TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_RELATIONSHIPS#'
                        ,'XX_CDH_UPD_PLCY_HZ_RELNS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_RELATIONSHIPS_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CONTACT_POINTS#'
                        ,'XX_CDH_INS_PLCY_HZ_CNCT_PNT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CONTACT_PNT_CREATE'
                        ,'INSERT'
                        ,TRUE
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CONTACT_POINTS#'
                        ,'XX_CDH_UPD_PLCY_HZ_CNCT_PNT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CONTACT_PNT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_CONTACTS#'
                        ,'XX_CDH_INS_PLCY_HZ_ORG_CNCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_CONTACT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_CONTACTS#'
                        ,'XX_CDH_UPD_PLCY_HZ_ORG_CNCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_CONTACT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_CONTACT_ROLES#'
                        ,'XX_CDH_INS_PLCY_HZ_ORGCNT_RLS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_CNTS_RLS_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_CONTACT_ROLES#'
                        ,'XX_CDH_UPD_PLCY_HZ_ORGCNT_RLS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_CNTS_RLS_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCOUNTS#'
                        ,'XX_CDH_INS_PLCY_HZ_CUST_ACCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_CREATE'
                        ,'INSERT'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCOUNTS#'
                        ,'XX_CDH_UPD_PLCY_HZ_CUST_ACCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUSTOMER_PROFILES#'
                        ,'XX_CDH_INS_PLCY_HZ_CUST_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUSTOMER_PRF_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUSTOMER_PROFILES#'
                        ,'XX_CDH_UPD_PLCY_HZ_CUST_PRF'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUSTOMER_PRF_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCT_SITES_ALL#'
                        ,'XX_CDH_INS_PLCY_HZ_CUST_SITES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_SITES_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCT_SITES_ALL#'
                        ,'XX_CDH_UPD_PLCY_HZ_CUST_SITES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_SITES_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   dbms_output.put_line('Apply policy on TCA tables... Before Account Site Uses');
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_SITE_USES_ALL#'
                        ,'XX_CDH_INS_PLCY_HZ_CS_USES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_SITE_USES_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_SITE_USES_ALL#'
                        ,'XX_CDH_UPD_PLCY_HZ_CS_USES'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_SITE_USES_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCOUNT_ROLES#'
                        ,'XX_CDH_INS_PLCY_HZ_CACT_RLS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_RLS_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCOUNT_ROLES#'
                        ,'XX_CDH_UPD_PLCY_HZ_CACT_RLS'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_RLS_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_PROFILE_AMTS#'
                        ,'XX_CDH_INS_PLCY_HZ_CST_PRF_AMT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_PROFILE_AMT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_PROFILE_AMTS#'
                        ,'XX_CDH_UPD_PLCY_HZ_CST_PRF_AMT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_PROFILE_AMT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCT_RELATE_ALL#'
                        ,'XX_CDH_INS_PLCY_HZ_CA_RLT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_RLT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_CUST_ACCT_RELATE_ALL#'
                        ,'XX_CDH_UPD_PLCY_HZ_CA_RLT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_RLT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'IBY'
                        ,'IBY_EXT_BANK_ACCOUNTS#'
                        ,'XX_CDH_INS_PLCY_AP_BANK_ACCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.AP_BANK_ACCT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'IBY'
                        ,'IBY_EXT_BANK_ACCOUNTS#'
                        ,'XX_CDH_UPD_PLCY_AP_BANK_ACCT'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.AP_BANK_ACCT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'IBY'
                        ,'IBY_PMT_INSTR_USES_ALL#'
                        ,'XX_CDH_INS_PLCY_AP_BNK_ACT_USE'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.AP_BANK_ACCT_USE_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'IBY'
                        ,'IBY_PMT_INSTR_USES_ALL#'
                        ,'XX_CDH_UPD_PLCY_AP_BNK_ACT_USE'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.AP_BANK_ACCT_USE_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'RA_CUST_RECEIPT_METHODS#'
                        ,'XX_CDH_INS_PLCY_RA_CST_REC'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.RA_CUST_RECEIPT_MTDS_CREATE'
                        ,'INSERT'
                        ,TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'RA_CUST_RECEIPT_METHODS#'
                        ,'XX_CDH_UPD_PLCY_RA_CST_REC'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.RA_CUST_RECEIPT_MTDS_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_B#'
                        ,'XX_CDH_INS_PLCY_ORGPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_ORGPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_B#'
                        ,'XX_CDH_UPD_PLCY_ORGPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_ORGPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_ORGPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ORG_PROFILES_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_ORGPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ORG_PROFILE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_B#'
                        ,'XX_CDH_INS_PLCY_PERPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_PERPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_CREATE'
                        ,'INSERT'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_PERPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_PERPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_UPDATE'
                        ,'UPDATE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_PERPRF_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PER_PROFILES_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_PERPRF_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PER_PROFILE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_B#'
                        ,'XX_CDH_INS_PLCY_CUST_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_B#'
                        ,'XX_CDH_UPD_PLCY_CUST_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_CUST_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_CUST_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_CUST_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_CUST_ACCT_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_CUST_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_CUST_ACCT_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   dbms_output.put_line('Apply policy on TCA tables... Before Account Site Ext B');
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_B#'
                        ,'XX_CDH_INS_PLCY_ACTSITE_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_B#'
                        ,'XX_CDH_UPD_PLCY_ACTSITE_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_ACTSITE_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_ACTSITE_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_ACTSITE_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_ACCT_SITE_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_ACTSITE_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   dbms_output.put_line('Apply policy on TCA tables... Before Account Site Use Ext B');
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_B#'
                        ,'XX_CDH_INS_PLCY_AS_USES_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_B#'
                        ,'XX_CDH_UPD_PLCY_AS_USES_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_UPDATE'
                        ,'UPDATE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_AS_USES_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_DELETE'
                        ,'DELETE'
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_AS_USES_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_CREATE'
                        ,'INSERT'
                        , TRUE
                       );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_AS_USES_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_UPDATE'
                        ,'UPDATE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'XXCRM'
                        ,'XX_CDH_SITE_USES_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_AS_USES_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_ACCT_SITE_USE_EXT_DELETE'
                        ,'DELETE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_B#'
                        ,'XX_CDH_INS_PLCY_PS_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_CREATE'
                        ,'INSERT'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_TL#'
                        ,'XX_CDH_INS_PLCY_PS_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_CREATE'
                        ,'INSERT'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_B#'
                        ,'XX_CDH_UPD_PLCY_PS_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_UPDATE'
                        ,'UPDATE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_TL#'
                        ,'XX_CDH_UPD_PLCY_PS_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_UPDATE'
                        ,'UPDATE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_B#'
                        ,'XX_CDH_DEL_PLCY_PS_EXT_B'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_DELETE'
                        ,'DELETE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_PARTY_SITES_EXT_TL#'
                        ,'XX_CDH_DEL_PLCY_PS_EXT_TL'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.HZ_PARTY_SITE_EXT_DELETE'
                        ,'DELETE'
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ROLE_RESPONSIBILITY#'
                        ,'XX_CDH_INS_PLCY_ROLE_RESP'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.hz_role_resp_create'
                        ,'INSERT'
                        ,TRUE
                        );
END;
/

BEGIN
   FND_ACCESS_CONTROL_UTIL.ADD_POLICY (
                         'AR'
                        ,'HZ_ROLE_RESPONSIBILITY#'
                        ,'XX_CDH_UPD_PLCY_ROLE_RESP'
                        ,'APPS'
                        ,'XX_CDH_ROLE_RESTRICT_PKG.hz_role_resp_update'
                        ,'UPDATE'
                        );
END;
/
