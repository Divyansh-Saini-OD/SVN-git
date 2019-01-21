REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : I0809_LeadInterface                                                        |--
--|                                                                                             |--
--| Program Name   : XX_LEAD_VALIDATE.sql                                                       |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object I0809_LeadInterface                       |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              13-Mar-2008      Abhradip Ghosh           Updated with the lastest files   |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for I0809_LeadInterface....
PROMPT

PROMPT
PROMPT Validating whether the required tables are present....
PROMPT

SELECT 'The table XX_AS_LEAD_IMP_OSR_STG '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                          ELSE 'Does Not Exists'
                                            END
FROM  all_tables ALT
WHERE ALT.table_name = 'XX_AS_LEAD_IMP_OSR_STG'
AND   ALT.owner      = 'XXCRM'; 

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index XX_AS_LEAD_IMP_OSR_STG_U1 '||
                                     CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                   ELSE 'Does Not Exists'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'XX_AS_LEAD_IMP_OSR_STG_U1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID'; 

PROMPT
PROMPT
PROMPT Validating whether the required synonyms are created in APPS schema....
PROMPT

SELECT 'The synonym XX_AS_LEAD_IMP_OSR_STG '||
                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                    ELSE 'Does Not Exists'
                                      END
FROM  all_synonyms ALS
WHERE ALS.synonym_name = 'XX_AS_LEAD_IMP_OSR_STG'
AND   ALS.owner = 'APPS'; 

PROMPT
PROMPT
PROMPT Validating whether the required profiles are present....
PROMPT

SELECT 'The profile OD: Show Debug Messages for Sales Lead Interface '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                                      ELSE 'Does Not Exists'
                                                                        END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_LEADS_IMPORT_DEBUG';

SELECT 'The profile OD: Purge leads interface import errors '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                             ELSE 'Does Not Exists'
                                                               END
FROM  fnd_profile_options_tl FPO
WHERE FPO.profile_option_name = 'XX_LEADS_IMPORT_PURGE_ERRORS';

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_SFA_LEADS_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEADS_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_SFA_LEADS_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_SFA_LEADS_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: SFA Import Sales Leads Inbound '||
                                                      CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                    ELSE 'Does Not Exists'
                                                      END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXSFALEADSINT'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program Import Sales Leads '||
                                           CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                         ELSE 'Does Not Exists'
                                           END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'ASXSLIMP'
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