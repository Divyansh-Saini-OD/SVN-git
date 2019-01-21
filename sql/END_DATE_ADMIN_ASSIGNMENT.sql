REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :E1309_AutoNamed_Account_Creation                                                                            |--
--|                                                                                             |--
--| Program Name   : END_DATE_ADMIN_ASSIGNMENT.sql                                                             |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Jeevan babu             Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script UPDATE_ASSIGNMENTS....
PROMPT

update xx_tm_nam_terr_entity_dtls 
set status='I', end_date_active=sysdate
where named_acct_terr_id in ( 3000,3001,3002);




SET FEEDBACK ON
SET HEAD     ON

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================