REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : I0405_Territories                                                          |--
--|                                                                                             |--
--| Program Name   : XX_TERRITORY_VALIDATE.sql                                                  |--
--|                                                                                             |--
--| Purpose        : Validating script for the object I0405_Territories                         |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              13-Mar-2008      Abhradip Ghosh           Updated with the latest files    |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for I0405_Territories....
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_JTF_TERRITORIES_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name  = 'XX_JTF_TERRITORIES_INT'
AND   ALT.owner       = 'XXCRM'; 

SELECT 'The table XX_JTF_TERR_QUALIFIERS_INT '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  all_tables ALT
WHERE ALT.table_name  = 'XX_JTF_TERR_QUALIFIERS_INT'
AND   ALT.owner       = 'XXCRM'; 

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index XX_JTF_TERRITORIES_INT_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name  = 'XX_JTF_TERRITORIES_INT_N1'
AND   ALI.owner       = 'XXCRM'
AND   ALI.status     = 'VALID'; 

SELECT 'The index XX_JTF_TERRITORIES_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name  = 'XX_JTF_TERRITORIES_INT_U1'
AND   ALI.owner       = 'XXCRM'
AND   ALI.status     = 'VALID'; 

SELECT 'The index XX_JTF_TERR_QUALIFIERS_INT_N1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name  = 'XX_JTF_TERR_QUALIFIERS_INT_N1'
AND   ALI.owner       = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index XX_JTF_TERR_QUALIFIERS_INT_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name  = 'XX_JTF_TERR_QUALIFIERS_INT_U1'
AND   ALI.owner       = 'XXCRM'
AND   ALI.status     = 'VALID';

PROMPT
PROMPT
PROMPT Validating whether the required sequences are present....
PROMPT

SELECT 'The sequence XX_JTF_RECORD_ID_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_RECORD_ID_INT_S'
AND   ALS.sequence_owner = 'XXCRM'; 

SELECT 'The sequence XX_JTF_QUAL_RECORD_ID_INT_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                  ELSE 'Does Not Exists'
                                                    END
FROM  all_sequences ALS
WHERE ALS.sequence_name  = 'XX_JTF_QUAL_RECORD_ID_INT_S'
AND   ALS.sequence_owner = 'XXCRM'; 

PROMPT
PROMPT
PROMPT Validating whether the required synonyms are created in APPS schema....
PROMPT

SELECT 'The synonym XX_JTF_TERRITORIES_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_TERRITORIES_INT'
AND   ALS.owner = 'APPS'; 

SELECT 'The synonym XX_JTF_TERR_QUALIFIERS_INT '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_TERR_QUALIFIERS_INT'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_JTF_RECORD_ID_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_RECORD_ID_INT_S'
AND   ALS.owner = 'APPS';

SELECT 'The synonym XX_JTF_QUAL_RECORD_ID_INT_S '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_JTF_QUAL_RECORD_ID_INT_S'
AND   ALS.owner = 'APPS';

PROMPT
PROMPT
PROMPT Validating whether the required value sets are present....
PROMPT

SELECT 'The value set XX_TM_TERRITORY_NAME '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                              END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_TERRITORY_NAME';

SELECT 'The value set XX_TM_ATTRIBUTE_NAME '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                              END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_ATTRIBUTE_NAME';

SELECT 'The value set XX_TM_ATTRIBUTE_VALUE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_ATTRIBUTE_VALUE';

SELECT 'The value set XX_TM_REGION_TAG '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                             ELSE 'Does Not Exists'
                                               END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_REGION_TAG';

PROMPT
PROMPT
PROMPT Validating whether the required lookups are present....
PROMPT

SELECT 'The lookup XX_TM_SALESREP_TYPE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_SALESREP_TYPE';

SELECT 'The lookup XX_TM_BUSINESS_LINE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                        ELSE 'Does Not Exists'
                                          END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_BUSINESS_LINE';

SELECT 'The lookup XX_TM_VERTICAL_MARKET_CODE '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_VERTICAL_MARKET_CODE';

SELECT 'The lookup XX_TM_TERRALIGN_QUALS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_TERRALIGN_QUALS';

SELECT 'The lookup XX_TM_SOURCE_SYSTEMS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_SOURCE_SYSTEMS';

SELECT 'The lookup XX_TM_TERR_CLASSIFICATION '||
                             CASE COUNT(1) WHEN 1 THEN 'Exists'
                                           ELSE 'Does Not Exists'
                             END
FROM  fnd_lookup_types FLT
WHERE FLT.lookup_type = 'XX_TM_TERR_CLASSIFICATION';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_JTF_TERRITORIES_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_TERRITORIES_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_JTF_TERRITORIES_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_TERRITORIES_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID'
AND   DBO.owner       = 'APPS'; 

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: TM Create Update Territory Program '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                       ELSE 'Does Not Exists'
                                                                         END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXTMTERRITORIESIN'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Label Territory Hierarchy Program '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                         ELSE 'Does Not Exists'
                                                                           END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXTMUPDATTR'
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
