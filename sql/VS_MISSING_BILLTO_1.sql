REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_MISSING_BILLTO_1.sql                                                      |--        
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
PROMPT Script VS_MISSING_BILLTO_1....
PROMPT


select /*+ parallel (hca, 4) */
hca.orig_system_reference 
from apps.hz_cust_accounts hca
where orig_system_reference like '%A0'
and not exists (
select  1
from apps.hz_cust_acct_sites_all hcas
, apps.hz_cust_site_uses_all hsua
where 
hcas.cust_acct_Site_id = hsua.cust_acct_Site_id
and hsua.site_use_code = 'BILL_TO'
and hcas.cust_account_id = hca.cust_account_id);


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
