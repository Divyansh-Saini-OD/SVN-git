REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_ALL_ERRORS.sql                                                             |--        
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
PROMPT Script VS_ALL_ERRORS....
PROMPT

select * from 
(
select 0 SEQ, a.interface_table_name TABLE_NAME, a.message_name||'.'||a.token1_name||'.'||a.token1_value ERROR, count(*) ct
from   apps.hz_imp_errors a,
       apps.xx_owb_crmbatch_status b
where  a.batch_id = b.ebs_batch_id
group by a.interface_table_name, a.message_name||'.'||a.token1_name||'.'||a.token1_value
UNION
select 1 SEQ, 'XXOD_HZ_IMP_ACCOUNTS_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCOUNTS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCOUNTS_STG')
group by e.exception_log
UNION
select 4 SEQ, 'XXOD_HZ_IMP_ACCOUNT_PROF_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCOUNT_PROF_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.INTERFACE_STATUS = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCOUNT_PROF_STG')
group by e.exception_log
UNION
select 2 SEQ, 'XXOD_HZ_IMP_ACCT_SITES_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_SITES_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_SITES_STG')
group by e.exception_log
UNION
select 3 SEQ, 'XXOD_HZ_IMP_ACCT_SITE_USES_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_SITE_USES_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_SITE_USES_STG')
group by e.exception_log
UNION
select 5 SEQ, 'XXOD_HZ_IMP_CUSTOMER_BANKS_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_CUSTOMER_BANKS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.INTERFACE_STATUS = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_CUSTOMER_BANKS_STG')
group by e.exception_log
UNION
select 7 SEQ, 'XXOD_HZ_IMP_ACCT_CONTACT_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_CONTACT_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.ROLE_INTERFACE_STATUS = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_CONTACT_STG')
group by e.exception_log
UNION
select 9 SEQ, 'XXOD_HZ_IMP_CONTACTPTS_STG' TABLE_NAME, e.exception_log error, count(1) Ct
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
group by e.exception_log
UNION
select 8 SEQ, 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_CNTTROLES_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG')
group by e.exception_log
UNION
select 11 SEQ, 'XXOD_HZ_IMP_EXT_ATTRIBS_STG' TABLE_NAME, e.exception_log error, count(1) Ct
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
group by e.exception_log
UNION
select 6 SEQ, 'XXOD_HZ_IMP_ACCT_PAYMETH_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_ACCT_PAYMETH_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_ACCT_PAYMETH_STG')
group by e.exception_log
UNION
select 10 SEQ, 'XXOD_HZ_IMP_RELSHIPS_STG' TABLE_NAME, e.exception_log error, count(1) Ct
from apps.XX_COM_EXCEPTIONS_LOG_CONV e
, apps.XXOD_HZ_IMP_RELSHIPS_STG s
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and s.record_id = e.record_control_id
and s.interface_status = 6
and e.exception_id = (select max(exception_id) from xxcomn.XX_COM_EXCEPTIONS_LOG_CONV ilog
                      where ilog.batch_id = e.batch_id
                      and ilog.record_control_id = e.record_control_id
                      and ilog.STAGING_TABLE_NAME = 'XXOD_HZ_IMP_RELSHIPS_STG')
group by e.exception_log
)
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
