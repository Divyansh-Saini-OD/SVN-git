REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_PENDING.sql                                                      |--        
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
PROMPT Script VS_PENDING....
PROMPT

select * from 
(
select 10 Seq, 'XXOD_HZ_IMP_RELSHIPS_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_RELSHIPS_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.interface_status
UNION
select 11 Seq, 'XXOD_HZ_IMP_EXT_ATTRIBS_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_EXT_ATTRIBS_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.interface_status
UNION
select 5 Seq, 'XXOD_HZ_IMP_CUSTOMER_BANKS_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, ''||e.org_id OrgId
from apps.XXOD_HZ_IMP_CUSTOMER_BANKS_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.org_id, e.interface_status
UNION
select 9 Seq, 'XXOD_HZ_IMP_CONTACTPTS_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_CONTACTPTS_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.interface_status
UNION
select 2 Seq, 'XXOD_HZ_IMP_ACCT_SITES_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, ''||e.org_id OrgId
from apps.XXOD_HZ_IMP_ACCT_SITES_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.org_id, e.interface_status
UNION
select 3 Seq, 'XXOD_HZ_IMP_ACCT_SITE_USES_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, ''||e.org_id OrgId
from apps.XXOD_HZ_IMP_ACCT_SITE_USES_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.org_id, e.interface_status
UNION
select 6 Seq, 'XXOD_HZ_IMP_ACCT_PAYMETH_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_ACCT_PAYMETH_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.interface_status
UNION
select 7 Seq, 'XXOD_HZ_IMP_ACCT_CONTACT_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.role_interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_ACCT_CONTACT_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.role_interface_status in (1, 4)
group by a.aops_batch_id, e.batch_id, e.role_interface_status
UNION
select 8 Seq, 'XXOD_HZ_IMP_ACCT_CNTTROLES_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, 'NA' OrgId
from apps.XXOD_HZ_IMP_ACCT_CNTTROLES_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1, 4)
group by a.aops_batch_id, e.batch_id, e.interface_status
UNION
select 1 Seq, 'XXOD_HZ_IMP_ACCOUNTS_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, ''||e.org_id OrgId
from apps.XXOD_HZ_IMP_ACCOUNTS_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.org_id, e.interface_status
UNION
select 4 Seq, 'XXOD_HZ_IMP_ACCOUNT_PROF_STG', a.aops_batch_id AOPS, e.batch_id EBS, e.interface_status STA, count(1) Ct, ''||e.org_id OrgId
from apps.XXOD_HZ_IMP_ACCOUNT_PROF_STG e
, apps.XX_OWB_CRMBATCH_STATUS a
where a.ebs_batch_id = e.batch_id
and e.interface_status in (1)
group by a.aops_batch_id, e.batch_id, e.org_id, e.interface_status
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
