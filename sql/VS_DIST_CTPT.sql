REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_DIST_CTPT.sql                                                      |--        
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
PROMPT Script VS_DIST_CTPT....
PROMPT

select a.aops_batch_id AOPS, e.batch_id EBS, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_CONTACTPTS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.INTERFACE_STATUS = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_CONTACTPTS_STG')
group by a.aops_batch_id, e.batch_id, e.exception_log
order by 1;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
