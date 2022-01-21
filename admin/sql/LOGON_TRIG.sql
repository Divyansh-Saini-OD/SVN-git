SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET ECHO        OFF

-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Synonym Name:  logon_trig.sql                                     |
-- | Rice Id     :                                                     |
-- |                                                                   |
-- | Change Record:                                                    |
-- | ===============                                                   |
-- | Version   Date         Author             Remarks                 |
-- | =======   ===========  =================  ========================|
-- |   1.0     19-FEB-2016  Manikant Kasu      Initial Version         |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT 'create or replace trigger logon_trig....'
PROMPT   

create or replace trigger logon_trig
after logon
on xxapps_history_stage.schema
begin
 apps.mo_global.set_policy_context('S',404);
 apps.ARP_GLOBAL.conc_program_name := 'ARPURGE';
end;
/

PROMPT
PROMPT 'Exiting....'
PROMPT

SET FEEDBACK ON

SHOW ERRORS;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
