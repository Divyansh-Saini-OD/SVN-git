REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :I0405_Territories                                                                            |--
--|                                                                                             |--
--| Program Name   : UPDATE_TERRITORY1.sql                                                             |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Jeevan babu             Initial version                  |--
--+=============================================================================================+-- 

SET FEEDBACK ON
SET HEAD     ON
SET VERIFY   ON

PROMPT
PROMPT Script UPDATE TERRITORY....
PROMPT

update JTF_TERR_ALL
set 
ORIG_SYSTEM_REFERENCE=attribute10 ,
PARENT_TERRITORY_ID = -1 * PARENT_TERRITORY_ID
WHERE PARENT_TERRITORY_ID <0;

SET FEEDBACK ON
SET HEAD     ON

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================