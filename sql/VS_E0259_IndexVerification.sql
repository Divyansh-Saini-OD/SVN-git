REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : E0259_IndexVerification                                                    |--
--|                                                                                             |--
--| Program Name   :                                                                            |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object E0259_IndexVerification                   |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              24-May-2008       Rajeev kamath           Initial Version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Validation Script for E0259_IndexVerification...
PROMPT

PROMPT
PROMPT
PROMPT Validating whether the required indexes are present....
PROMPT

SELECT 'The index HZ_STAGED_CONTACT_POINTS_N2 '||
                                     CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                   ELSE 'does not exist.'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'HZ_STAGED_CONTACT_POINTS_N2'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index HZ_STAGED_CONTACTS_N2'||
                                     CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                   ELSE 'does not exist.'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'HZ_STAGED_CONTACTS_N2'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index HZ_PARTY_SITES_EXT_B_X1'||
                                     CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                   ELSE 'does not exist.'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'HZ_PARTY_SITES_EXT_B_X1'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';

SELECT 'The index HZ_PARTY_SITES_EXT_B_X2'||
                                     CASE COUNT(1) WHEN 1 THEN 'exists.'
                                                   ELSE 'does not exist.'
                                     END
FROM  all_indexes ALI
WHERE ALI.index_name = 'HZ_PARTY_SITES_EXT_B_X2'
AND   ALI.owner      = 'XXCRM'
AND   ALI.status     = 'VALID';


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
