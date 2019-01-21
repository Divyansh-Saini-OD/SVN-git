REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_COUNTRY_UPDATE.sql                                                      |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Nabarun Ghosh           Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script COUNTRY_UPDATE....
PROMPT


select 'update hz_locations set country = '''||l.country||'''where location_id = (select location_id from hz_party_sites where orig_system_reference = '''||ps.orig_system_reference||''');'
from apps.hz_locations l, apps.hz_party_sites ps
where ps.location_id = l.location_id
and l.country not in ('US', 'CA')
and ps.orig_system_reference like '%A0';


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
