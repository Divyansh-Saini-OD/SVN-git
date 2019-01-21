REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E0255_CDHAdditionalAttributes                                              |--
--|                                                                                             |--
--| Program Name   : XX_CDH_ADDTNL_ATTRIBUTES_VALIDATE.sql                                      |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object E0255_CDHAdditionalAttributes             |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              12-Mar-2008      Abhradip Ghosh           Updated with the latest files    |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E0255_CDHAdditionalAttributes....
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_CDH_ACCT_SITE_EXT_B '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_ACCT_SITE_EXT_B'
AND   ALT.owner      = 'XXCRM'; 

SELECT 'The table XX_CDH_ACCT_SITE_EXT_TL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_ACCT_SITE_EXT_TL'
AND   ALT.owner      = 'XXCRM'; 

SELECT 'The table XX_CDH_SITE_USES_EXT_B '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_SITE_USES_EXT_B'
AND   ALT.owner      = 'XXCRM'; 

SELECT 'The table XX_CDH_SITE_USES_EXT_TL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_SITE_USES_EXT_TL'
AND   ALT.owner      = 'XXCRM'; 

SELECT 'The table XX_CDH_CUST_ACCT_EXT_B '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_CUST_ACCT_EXT_B'
AND   ALT.owner      = 'XXCRM'; 

SELECT 'The table XX_CDH_CUST_ACCT_EXT_TL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_CDH_CUST_ACCT_EXT_TL'
AND   ALT.owner      = 'XXCRM'; 

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index XX_CDH_CUST_ACCT_EXT_B_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_CUST_ACCT_EXT_B_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_CUST_ACCT_EXT_B_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_CUST_ACCT_EXT_B_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_CUST_ACCT_EXT_TL_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_CUST_ACCT_EXT_TL_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_CUST_ACCT_EXT_TL_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_CUST_ACCT_EXT_TL_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_ACCT_SITE_EXT_B_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_ACCT_SITE_EXT_B_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_ACCT_SITE_EXT_B_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_ACCT_SITE_EXT_B_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_ACCT_SITE_EXT_TL_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_ACCT_SITE_EXT_TL_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_ACCT_SITE_EXT_TL_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_ACCT_SITE_EXT_TL_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_SITE_USES_EXT_B_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_SITE_USES_EXT_B_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_SITE_USES_EXT_B_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_SITE_USES_EXT_B_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_SITE_USES_EXT_TL_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_SITE_USES_EXT_TL_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_CDH_SITE_USES_EXT_TL_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_CDH_SITE_USES_EXT_TL_N1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

PROMPT
PROMPT
PROMPT Validating whether the required views are present....
PROMPT

SELECT 'The view XX_CDH_CUST_ACCT_EXT_VL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_CDH_CUST_ACCT_EXT_VL'
AND   ALV.owner     = 'APPS';

SELECT 'The view XX_CDH_ACCT_SITE_EXT_VL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_CDH_ACCT_SITE_EXT_VL'
AND   ALV.owner     = 'APPS';

SELECT 'The view XX_CDH_SITE_USES_EXT_VL '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_CDH_SITE_USES_EXT_VL'
AND   ALV.owner     = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required sequences are present....
PROMPT

SELECT 'The sequence XX_CDH_CUST_DOC_ID_S '||
                                       CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                     ELSE 'Does Not Exists'
                                       END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_CDH_CUST_DOC_ID_S'
AND   ALS.sequence_owner = 'XXCRM';

PROMPT
PROMPT
PROMPT Validating whether the required synonyms are created in APPS schema....
PROMPT

SELECT 'The synonym XX_CDH_CUST_ACCT_EXT_B '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_CUST_ACCT_EXT_B'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_CUST_ACCT_EXT_TL '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_CUST_ACCT_EXT_TL'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_ACCT_SITE_EXT_B '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_ACCT_SITE_EXT_B'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_ACCT_SITE_EXT_TL '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_ACCT_SITE_EXT_TL'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_SITE_USES_EXT_B '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_SITE_USES_EXT_B'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_SITE_USES_EXT_TL '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_SITE_USES_EXT_TL'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_CDH_CUST_DOC_ID_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_CDH_CUST_DOC_ID_S'
AND   ALS.owner = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required value sets are present....
PROMPT

SELECT 'The value set XXOD_CDH_BILLDOCS_COMBO_TYPE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_BILLDOCS_COMBO_TYPE';

SELECT 'The value set XXOD_CDH_BILLDOCS_DELIVERY_METHOD '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_BILLDOCS_DELIVERY_METHOD';

SELECT 'The value set XXOD_CDH_BILLDOCS_DOCUMENT_ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_BILLDOCS_DOCUMENT_ID';

SELECT 'The value set XXOD_CDH_BILLDOCS_DOC_TYPE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_BILLDOCS_DOC_TYPE';

SELECT 'The value set XXOD_CDH_SPC_CREDIT_CODE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_SPC_CREDIT_CODE';

SELECT 'The value set XXOD_CDH_SPC_TENDER_CODE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XXOD_CDH_SPC_TENDER_CODE';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_CDH_HZ_EXTENSIBILITY_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CDH_HZ_EXTENSIBILITY_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_CDH_HZ_EXTENSIBILITY_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CDH_HZ_EXTENSIBILITY_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package specification XX_CDH_ADD_ATTR_ENT_REG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CDH_ADD_ATTR_ENT_REG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_CDH_ADD_ATTR_ENT_REG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_CDH_ADD_ATTR_ENT_REG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: Register Entity for Extended Attributes '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                             ELSE 'Does Not Exists'
                                                                               END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXCDHADDATTRENTREG'
AND   FCP.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the dependencies are present....
PROMPT

PROMPT
PROMPT
PROMPT Validating whether the table names are present in EGO_OBJECT_EXT_TABLES_B....
PROMPT

PROMPT Validating whether XX_CDH_CUST_ACCT_EXT_B and XX_CDH_CUST_ACCT_EXT_TL exists
PROMPT

SELECT 'Of the two tables '||
                             CASE COUNT(1) WHEN 2 THEN 'all of them exists'
                                           WHEN 1 THEN 'only one of them exists'
                                           ELSE 'none of them exists'
                             END
FROM  ego_object_ext_tables_b EET
WHERE EET.ext_table_name IN ('XX_CDH_CUST_ACCT_EXT_B','XX_CDH_CUST_ACCT_EXT_TL');

PROMPT
PROMPT Validating whether XX_CDH_ACCT_SITE_EXT_B and XX_CDH_ACCT_SITE_EXT_TL exists
PROMPT

SELECT 'Of the two tables '||
                             CASE COUNT(1) WHEN 2 THEN 'all of them exists'
                                           WHEN 1 THEN 'only one of them exists'
                                           ELSE 'none of them exists'
                             END
FROM  ego_object_ext_tables_b EET
WHERE EET.ext_table_name IN ('XX_CDH_ACCT_SITE_EXT_B','XX_CDH_ACCT_SITE_EXT_TL');

PROMPT
PROMPT Validating whether XX_CDH_SITE_USES_EXT_B and XX_CDH_SITE_USES_EXT_TL exists
PROMPT

SELECT 'Of the two tables '||
                             CASE COUNT(1) WHEN 2 THEN 'all of them exists'
                                           WHEN 1 THEN 'only one of them exists'
                                           ELSE 'none of them exists'
                             END
FROM  ego_object_ext_tables_b EET
WHERE EET.ext_table_name IN ('XX_CDH_SITE_USES_EXT_B','XX_CDH_SITE_USES_EXT_TL');

PROMPT
PROMPT
PROMPT Validating whether the lookup codes are present in the lookup type EGO_EF_DATA_LEVEL....
PROMPT

PROMPT Validating whether Accounts Level, Account Sites Level and Account Site Uses Level exists
PROMPT

SELECT 'Of the three lookup codes '||
                             CASE COUNT(1) WHEN 3 THEN 'all of them exists'
                                           WHEN 2 THEN 'only two of them exists'
                                           WHEN 1 THEN 'only one of them exists'
                                           ELSE 'none of them exists'
                             END
FROM  fnd_lookup_values FLV
WHERE FLV.lookup_type = 'EGO_EF_DATA_LEVEL' 
AND   FLV.lookup_code IN ('XX_CDH_CUST_ACCOUNT','XX_CDH_CUST_ACCT_SITE','XX_CDH_ACCT_SITE_USES')
AND   FLV.enabled_flag = 'Y';

PROMPT
PROMPT
PROMPT Validating whether the objects are present in the fnd_objects table....
PROMPT

PROMPT Validating whether XX_CDH_CUST_ACCOUNT, XX_CDH_CUST_ACCT_SITE and XX_CDH_ACCT_SITE_USES exists
PROMPT

SELECT 'Of the three objects '||
                             CASE COUNT(1) WHEN 3 THEN 'all of them exists'
                                           WHEN 2 THEN 'only two of them exists'
                                           WHEN 1 THEN 'only one of them exists'
                                           ELSE 'none of them exists'
                             END
FROM  fnd_objects FOB
WHERE FOB.obj_name IN ('XX_CDH_CUST_ACCOUNT','XX_CDH_CUST_ACCT_SITE','XX_CDH_ACCT_SITE_USES');

PROMPT
PROMPT
PROMPT Validating whether the referenced packages are compiled in database....
PROMPT

SELECT 'The package specification EGO_USER_ATTRS_DATA_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'EGO_USER_ATTRS_DATA_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body EGO_USER_ATTRS_DATA_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'EGO_USER_ATTRS_DATA_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
