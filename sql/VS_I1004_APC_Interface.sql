REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : I1004_APC_Interface                                                        |--
--|                                                                                             |--
--| Program Name   : XX_APC_VALIDATE.sql                                                        |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object I1004_APC_Interface                       |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-Dec-2007      Abhradip Ghosh           Original                         |--
--| 1.1              13-Mar-2008      Abhradip Ghosh           Included the latest files        |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for I1004_APC_Interface....
PROMPT

PROMPT
PROMPT
PROMPT Validating whether the required lookups are present....
PROMPT

SELECT 'The Lookup MTL_FUNCTIONAL_AREAS for Inventory '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                       ELSE 'Does Not Exists'
                                                         END
FROM  mfg_lookups MFL
WHERE MFL.lookup_type = 'MTL_FUNCTIONAL_AREAS'
AND   MFL.meaning = 'Inventory'
AND   MFL.enabled_flag = 'Y'; 

SELECT 'The Lookup MTL_FUNCTIONAL_AREAS for Product Reporting '||CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                               ELSE 'Does Not Exists'
                                                                 END
FROM  mfg_lookups MFL
WHERE MFL.lookup_type = 'MTL_FUNCTIONAL_AREAS'
AND   MFL.meaning = 'Product Reporting'
AND   MFL.enabled_flag = 'Y'; 

PROMPT
PROMPT
PROMPT Validating whether the custom packages are compiled in database....
PROMPT

SELECT 'The package specification XX_APC_ITEM_CATEGORY_PKG.pks '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_APC_ITEM_CATEGORY_PKG'
AND   DBO.object_type = 'PACKAGE'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS'; 

SELECT 'The package body XX_APC_ITEM_CATEGORY_PKG.pkb '||
                                         CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                       ELSE 'Does Not Exists'
                                         END
FROM  dba_objects DBO
WHERE DBO.object_name = 'XX_APC_ITEM_CATEGORY_PKG'
AND   DBO.object_type = 'PACKAGE BODY'
AND   DBO.status      = 'VALID' 
AND   DBO.owner       = 'APPS';  

PROMPT
PROMPT
PROMPT Validating whether the required concurrent programs are present....
PROMPT

SELECT 'The concurrent program OD: APC Synchronize Product Hierarchies '||
                                                               CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                                             ELSE 'Does Not Exists'
                                                               END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'XXAPCPRODCAT'
AND   FCP.enabled_flag = 'Y';

SELECT 'The concurrent program Load Catalog Hierarchy '||
                                              CASE COUNT(1) WHEN 1 THEN 'Exists'
                                                            ELSE 'Does Not Exists'
                                              END
FROM  fnd_concurrent_programs FCP
WHERE FCP.concurrent_program_name = 'ENI_DEN_INIT'
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
