REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_MISSING_AS.sql                                                             |--        
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
PROMPT Script VS_MISSING_AS....
PROMPT

select a.aops_batch_id AOPS, e.batch_id EBS, s.ACCT_SITE_ORIG_SYS_REFERENCE, s.org_id ORG_ID, s.interface_status STA, e.exception_log error
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_SITES_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id (+) = e.batch_id
and s.record_id (+) = e.record_control_id
and s.interface_status <> 7
and e.exception_id = (select /*+ parallel (ilog, 4) */ max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_SITES_STG')
and s.ACCT_SITE_ORIG_SYS_REFERENCE in (
        select AOPS_REFERENCE from
        (
            select * from (select 'AOPS_ACCOUNT_SITE' ENTITY, ACCT_SITE_ORIG_SYS_REFERENCE AOPS_REFERENCE from apps.XXOD_HZ_IMP_ACCT_SITES_STG where batch_id in (select ebs_batch_id from apps.XX_OWB_CRMBATCH_STATUS)
            minus
            select 'AOPS_ACCOUNT_SITE' ENTITY, orig_system_reference AOPS_REFERENCE from apps.hz_orig_sys_references where owner_table_name = 'HZ_CUST_ACCT_SITES_ALL' and orig_system = 'A0'
        )
    )
)
and e.batch_id = (select /*+ parallel (istg, 4) */ max(batch_id) from apps.XXOD_HZ_IMP_ACCT_SITES_STG istg where istg.ACCT_SITE_ORIG_SYS_REFERENCE = s.ACCT_SITE_ORIG_SYS_REFERENCE)
order by 1, 2, 3;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
