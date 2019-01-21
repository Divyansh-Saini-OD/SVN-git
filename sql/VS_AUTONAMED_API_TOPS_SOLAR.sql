REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E1309B_Autonamed_Account_Creation                                          |--
--|                                                                                             |--
--| Program Name   : XX_AUTONAMED_API_TOPS_SOLAR.sql                                            |--
--|                                                                                             |--
--| Purpose        : Validating script for the object E1309B_Autonamed_Account_Creation         |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              26-Dec-2007      Nabarun Ghosh           Original                          |--
--| 1.1              13-Mar-2008      Abhradip ghosh          Updated with the latest files     |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E1309B_Autonamed_Account_Creation....
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_TM_NAM_TERR_DEFN '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_DEFN'; 

SELECT 'The table XX_TM_NAM_TERR_RSC_DTLS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                           ELSE 'Does Not Exists'
                                             END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_RSC_DTLS';  

SELECT 'The table XX_TM_NAM_TERR_ENTITY_DTLS '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_TM_NAM_TERR_ENTITY_DTLS'; 

PROMPT
PROMPT
PROMPT Validating whether the required sequences are present....
PROMPT

SELECT 'The sequence XX_TM_NAM_TERR_DEFN_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                              END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_DEFN_S'; 

SELECT 'The sequence XX_TM_NAM_TERR_ENTITY_DTLS_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                   ELSE 'Does Not Exists'
                                                     END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_ENTITY_DTLS_S'; 

SELECT 'The sequence XX_TM_NAM_TERR_RSC_DTLS_S '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                ELSE 'Does Not Exists'
                                                  END
FROM  all_sequences ALS
WHERE ALS.sequence_name = 'XX_TM_NAM_TERR_RSC_DTLS_S'; 

PROMPT
PROMPT
PROMPT Validating whether the required views are present....
PROMPT

SELECT 'The view XX_TM_NAM_TERR_CURR_ASSIGN_V '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_TM_NAM_TERR_CURR_ASSIGN_V';

SELECT 'The view XX_TM_NAM_TERR_DATE_ASSIGN_V '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                               ELSE 'Does Not Exists'
                                                 END
FROM  all_views ALV
WHERE ALV.view_name = 'XX_TM_NAM_TERR_DATE_ASSIGN_V';

PROMPT
PROMPT
PROMPT Validating whether the required profiles are present....
PROMPT

SELECT 'The profile OD: TM Validate Division and Role Code '||
                            CASE COUNT(1) WHEN 1 THEN 'Exists'
                                          ELSE 'Does Not Exists'
                            END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_TM_VALIDATE_DIV_ROLE';

PROMPT
PROMPT
PROMPT Validating whether the required value sets are present....
PROMPT

SELECT 'The value set XX_TM_GROUP_ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_GROUP_ID';

SELECT 'The value set XX_TM_ROLE_ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_ROLE_ID';

SELECT 'The value set XX_TM_RESOURCE_ID '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_RESOURCE_ID';

SELECT 'The value set XX_TM_NAMED_ACCT_TERRITORY '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                      ELSE 'Does Not Exists'
                                        END
FROM  fnd_flex_value_sets FFV
WHERE FFV.flex_value_set_name = 'XX_TM_NAMED_ACCT_TERRITORY';

PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_JTF_RS_NAMED_ACC_TERR_PUB.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package body XX_JTF_RS_NAMED_ACC_TERR_PUB.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_RS_NAMED_ACC_TERR_PUB'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package specification XX_JTF_NMDACC_CREATE_TERR.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_NMDACC_CREATE_TERR'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' ; 

SELECT 'The package body XX_JTF_NMDACC_CREATE_TERR.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_JTF_NMDACC_CREATE_TERR'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' ; 

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: TM Named Account Move Party Sites '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXNMACCTMVPARTYSITES'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Named Account Move Resource Territories '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXNMACCTMVRSTERR'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: TM Named Account Synchronize Status Flag '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXNAMACCTSYNCSTATUS'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program OD: IC Named Account Create Territory '||
                                                CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                              ELSE 'Does Not Exists'
                                                END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXNMACTCREATERR'
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

