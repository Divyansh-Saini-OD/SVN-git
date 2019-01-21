REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :I0405_Territories                                                                            |--
--|                                                                                             |--
--| Program Name   : UPDATE_TERRITORY.sql                                                             |--        
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
attribute10 = orig_system_reference,
ORIG_SYSTEM_REFERENCE=NULL ,
PARENT_TERRITORY_ID = -1 * PARENT_TERRITORY_ID
WHERE PARENT_TERRITORY_ID IN 
(
SELECT TERR_ID FROM
(select terr_id,name,PARENT_TERRITORY_ID,LEVEL LEVEL1 from apps.JTF_TERR_ALL
START WITH TERR_ID = 1802
CONNECT BY PRIOR TERR_ID = PARENT_TERRITORY_ID) WHERE LEVEL1 =4
);

SET FEEDBACK ON
SET HEAD     ON

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================