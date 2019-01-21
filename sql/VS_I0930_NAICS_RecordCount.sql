REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : VS_I0930_NAICS_RecordCount.sql                                             |--
--|                                                                                             |--
--| Program Name   :                                                                            |--        
--|                                                                                             |--   
--| Purpose        : Validating script for the object I0930 NAICS                               |--
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              12-Apr-2008       Rajeev Kamath           Original                         |--
--| 2.0              10-Nov-2016	   Vasu Raparla            Removed Schema references for    |--
--|                                                            R.12.2                           |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF
SET TIME     ON
SET TIMING   ON

PROMPT
PROMPT Validation Script for I0930 NAICS
PROMPT

PROMPT
PROMPT Estimating total count of records staged
PROMPT

select count(1) from XX_CDH_CLASSIFICATION_CODES;


SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
