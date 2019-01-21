REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_NOTLOADED_ACCT_SITE_USE.sql                                                      |--        
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
PROMPT Script VS_NOTLOADED_ACCT_SITE_USE....
PROMPT


select * from 
(select 'AOPS_ACCOUNT_SITE_USE' ENTITY, ACCT_SITE_ORIG_SYS_REFERENCE||'-'||SITE_USE_CODE AOPS_REFERENCE from apps.XXOD_HZ_IMP_ACCT_SITE_USES_STG where account_orig_system = 'A0' and batch_id in (select ebs_batch_id from apps.XX_OWB_CRMBATCH_STATUS)
minus
select 'AOPS_ACCOUNT_SITE_USE' ENTITY, orig_system_reference AOPS_REFERENCE from apps.hz_orig_sys_references where owner_table_name = 'HZ_CUST_SITE_USES_ALL' and orig_system = 'A0')
order by 2;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
