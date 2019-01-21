REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_MISSING_EXT.sql                                                      |--        
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
PROMPT Script VS_MISSING_EXT....
PROMPT


select a.aops_batch_id AOPS, e.batch_id EBS, s.INTERFACE_ENTITY_NAME, s.ATTRIBUTE_GROUP_CODE, s.interface_status STA, e.exception_log error
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_EXT_ATTRIBS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id (+) = e.batch_id
and s.record_id (+) = e.record_control_id
and s.interface_status <> 7
and e.exception_id = (select /*+ parallel (ilog, 4) */ max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_EXT_ATTRIBS_STG')
and s.ACCT_SITE_ORIG_SYS_REFERENCE||'-'||SITE_USE_CODE in (
        select AOPS_REFERENCE from
        (
            select * from (select 'AOPS_ACCOUNT_SITE_USE' ENTITY, ACCT_SITE_ORIG_SYS_REFERENCE||'-'||SITE_USE_CODE AOPS_REFERENCE from apps.XXOD_HZ_IMP_ACCT_SITE_USES_STG where batch_id in (select ebs_batch_id from apps.XX_OWB_CRMBATCH_STATUS)
            minus
            select 'AOPS_ACCOUNT_SITE_USE' ENTITY, orig_system_reference AOPS_REFERENCE from apps.hz_orig_sys_references where owner_table_name = 'HZ_CUST_SITE_USES_ALL' and orig_system = 'A0'
        )
    )
)
and e.batch_id = (select /*+ parallel (istg, 4) */ max(batch_id) from apps.XXOD_HZ_IMP_ACCT_SITES_STG istg where istg.ACCT_SITE_ORIG_SYS_REFERENCE||'-'||SITE_USE_CODE = s.ACCT_SITE_ORIG_SYS_REFERENCE||'-'||SITE_USE_CODE)
order by 1, 2, 3;
EOF
select a.aops_batch_id AOPS, e.batch_id EBS, INTERFACE_ENTITY_NAME, ATTRIBUTE_GROUP_CODE, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_EXT_ATTRIBS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.INTERFACE_STATUS = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_EXT_ATTRIBS_STG')
group by a.aops_batch_id, e.batch_id, INTERFACE_ENTITY_NAME, ATTRIBUTE_GROUP_CODE, e.exception_log
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
