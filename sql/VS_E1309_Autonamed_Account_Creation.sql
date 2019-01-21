REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E1309_Autonamed_Account_Creation                                           |--
--|                                                                                             |--
--| Program Name   : XX_AUTO_NAMED_VALIDATE.sql                                                 |--
--|                                                                                             |--
--| Purpose        : Validating script for the object E1309_Autonamed_Account_Creation          |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              12-Mar-2008      Abhradip Ghosh           Included the validation for the  |--
--|                                                            latest files                     |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E1309_Autonamed_Account_Creation...
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_TM_NAM_TERR_DEFN '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_DEFN'
AND   ALT.owner      = 'XXCRM';

SELECT 'The table XX_TM_NAM_TERR_RSC_DTLS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                           ELSE 'Does Not Exists'
                                             END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_RSC_DTLS'
AND   ALT.owner      = 'XXCRM';

SELECT 'The table XX_TM_NAM_TERR_ENTITY_DTLS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_ENTITY_DTLS'
AND   ALT.owner      = 'XXCRM';

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index XX_TM_NAM_TERR_DEFN_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_TM_NAM_TERR_DEFN_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_TM_NAM_TERR_ENTITY_DTLS_U1 '||
                                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_TM_NAM_TERR_ENTITY_DTLS_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_TM_NAM_TERR_RSC_DTLS_U1 '||
                                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_TM_NAM_TERR_RSC_DTLS_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_TM_NAM_TERR_RSC_DTLS_N1 '||
                                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_TM_NAM_TERR_RSC_DTLS_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_TM_NAM_TERR_ENTITY_DTLS_N1 '||
                                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_TM_NAM_TERR_ENTITY_DTLS_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

PROMPT
PROMPT
PROMPT Validating whether the required sequences are present....
PROMPT

SELECT 'The sequence XX_TM_NAM_TERR_DEFN_S '||
                                       CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                     ELSE 'Does Not Exists'
                                       END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_DEFN_S'
AND   ALS.sequence_owner = 'XXCRM';

SELECT 'The sequence XX_TM_NAM_TERR_ENTITY_DTLS_S '||
                                             CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                           ELSE 'Does Not Exists'
                                             END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_ENTITY_DTLS_S'
AND   ALS.sequence_owner = 'XXCRM';

SELECT 'The sequence XX_TM_NAM_TERR_RSC_DTLS_S '||
                                          CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_RSC_DTLS_S'
AND   ALS.sequence_owner = 'XXCRM';

PROMPT
PROMPT
PROMPT Validating whether the required synonyms are created in APPS schema....
PROMPT

SELECT 'The synonym XX_TM_NAM_TERR_DEFN '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_DEFN'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_TM_NAM_TERR_ENTITY_DTLS '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_ENTITY_DTLS'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_TM_NAM_TERR_RSC_DTLS '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_RSC_DTLS'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_TM_NAM_TERR_DEFN_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_DEFN_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_TM_NAM_TERR_ENTITY_DTLS_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_ENTITY_DTLS_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_TM_NAM_TERR_RSC_DTLS_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_TM_NAM_TERR_RSC_DTLS_S'
AND   ALS.owner = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required views are present....
PROMPT

SELECT 'The view XX_TM_NAM_TERR_CURR_ASSIGN_V '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_TM_NAM_TERR_CURR_ASSIGN_V'
AND   ALV.owner     = 'APPS';

SELECT 'The view XX_TM_NAM_TERR_DATE_ASSIGN_V '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_TM_NAM_TERR_DATE_ASSIGN_V'
AND   ALV.owner     = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required profiles are present....
PROMPT

SELECT 'The profile OD - Named Account Party Site Assignment Process ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                         ELSE 'Does Not Exists'
                                                                           END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_TM_AUTO_MAX_PARTY_SITE_ID';

SELECT 'The profile OD - Named Account Opportunity Assignment Process ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                          ELSE 'Does Not Exists'
                                                                            END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_TM_AUTO_MAX_OPPTY_ID';

SELECT 'The profile OD - Named Account Lead Assignment Process ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                   ELSE 'Does Not Exists'
                                                                     END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_TM_AUTO_MAX_LEAD_ID';

SELECT 'The profile OD: TM Sales Rep Party Site Assignment Process Batch Size '||
                                   CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                 ELSE 'Does Not Exists'
                                   END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_TM_PARTY_SITE_BATCH_SIZE';

SELECT 'The profile OD: Bulk Fetch Limit for Customer Conversion '||
                                   CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                 ELSE 'Does Not Exists'
                                   END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_CDH_BULK_FETCH_LIMIT';

PROMPT
PROMPT
PROMPT Validating whether the required value sets are present....
PROMPT

SELECT 'The value set XX_OD_TM_DIVISION '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_OD_TM_DIVISION';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_TM_TERRITORY_UTIL_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_TERRITORY_UTIL_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_TM_TERRITORY_UTIL_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_TERRITORY_UTIL_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_RS_NAMED_ACC_TERR.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_RS_NAMED_ACC_TERR.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_TM_JTF_TERR_ASSIGN_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_JTF_TERR_ASSIGN_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_TM_JTF_TERR_ASSIGN_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_JTF_TERR_ASSIGN_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_PTY_SITE_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_PTY_SITE_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_PTY_SITE_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_PTY_SITE_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_BL_SLREP_PST_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_BL_SLREP_PST_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_BL_SLREP_PST_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_BL_SLREP_PST_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_LEAD_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_LEAD_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_LEAD_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_LEAD_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_BL_LEAD_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_BL_LEAD_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_BL_LEAD_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_BL_LEAD_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_OPPTY_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_OPPTY_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_OPPTY_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_OPPTY_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_BL_OPPTY_CRTN.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_BL_OPPTY_CRTN'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_BL_OPPTY_CRTN.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_BL_OPPTY_CRTN'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_LEAD_SYNC.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_LEAD_SYNC'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_LEAD_SYNC.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_LEAD_SYNC'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SALES_REP_OPPTY_SYNC.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_OPPTY_SYNC'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SALES_REP_OPPTY_SYNC.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SALES_REP_OPPTY_SYNC'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SLS_REP_NW_DIV_PTY_SITE.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SLS_REP_NW_DIV_PTY_SITE.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SLS_REP_NW_DIV_PTY_SITE'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification JTF_TERR_LOOKUP_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'JTF_TERR_LOOKUP_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body JTF_TERR_LOOKUP_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'JTF_TERR_LOOKUP_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_SL_REP_UNASSGN_INT_CUST.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SL_REP_UNASSGN_INT_CUST'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_SL_REP_UNASSGN_INT_CUST.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_SL_REP_UNASSGN_INT_CUST'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_JTF_UNASSGN_PST_EXP_REP.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_UNASSGN_PST_EXP_REP'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_JTF_UNASSGN_PST_EXP_REP.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_UNASSGN_PST_EXP_REP'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package specification XX_TM_TERRITORY_UTIL_PKG_W.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_TERRITORY_UTIL_PKG_W'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

SELECT 'The package body XX_TM_TERRITORY_UTIL_PKG_W.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_TM_TERRITORY_UTIL_PKG_W'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the dependent codes are present....

PROMPT
PROMPT In package spec JTF_TERR_ASSIGN_PUB, to check SQUAL_CHAR61 has been added to the record type

SELECT 'The customized code '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                             ELSE 'Does Not Exists'
                               END
FROM   all_source ASO
WHERE  ASO.name = 'JTF_TERR_ASSIGN_PUB'
AND    ASO.type = 'PACKAGE'
AND    ASO.text like '%SQUAL_CHAR61%jtf_terr_char_360list := jtf_terr_char_360list()%';

PROMPT
PROMPT In package body JTF_TERR_LOOKUP_PUB for extending the SQUAL_CHAR61 of record type lp_trans_rec

SELECT 'The customized code '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                             ELSE 'Does Not Exists'
                               END
FROM   all_source ASO
WHERE  ASO.name = 'JTF_TERR_LOOKUP_PUB'
AND    ASO.type = 'PACKAGE BODY'
AND    ASO.text like '%lp_trans_Rec.SQUAL_CHAR61.EXTEND%';

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: TM Party Site Named Account Mass Assignment Master Program '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPPSTCRTNMASTER'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Party Site Named Account Mass Assignment Child Program '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPPSTCRTNCHILD'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Synchronize Lead Named Account '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFSALESREPLEADSYNC'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Synchronize Opportunity Named Account '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFSALESREPOPPTYSYNC'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Unassign Internal Customers '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFSLREPUNASSGNINTCUST'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Unassigned Party Sites Exception Report '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFUNASSGNPSTEXPREP'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM New Division Named Account Mass Assignment Master Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFSLREPNEWDIVPTYSITEMASTER'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM New Division Named Account Mass Assignment Child Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFSLREPNEWDIVPTYSITECHILD'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Lead Named Account Mass Assignment Master Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPLEADCRTNMASTER'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Lead Named Account Mass Assignment Child Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPLEADCRTNCHILD'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Opportunity Named Account Mass Assignment Master Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPOPPTYCRTNMASTER'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Opportunity Named Account Mass Assignment Child Program '||
                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                            ELSE 'Does Not Exists'
                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXJTFBLSLREPOPPTYCRTNCHILD'
AND   FCP.enabled_flag = 'Y';

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================

