REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Customer Assignments Conversion                                      |--
--|                                                                                             |--
--| Program Name   : Runtime Execution Scripts                                                  |--
--|                                                                                             |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              11-Jun-2008       Sathya Prabha Rani      Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script - Total Number of Customer Assignments in Staging Table
PROMPT

SELECT count(*) 
FROM   apps.xxod_hz_imp_parties_int  
WHERE  batch_id = :batchId;


PROMPT
PROMPT Script - Total Number of Customer Assignments in Interface  Table
PROMPT

SELECT count(*) 
FROM   hz_imp_parties_int  
WHERE  batch_id = :batchId;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
