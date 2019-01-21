REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_BULK_IMP_ERRORS.sql                                                     |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Nabarun Ghosh           Initial version                  |--
--| 2.0              09-Nov-2016       Havish Kasina           Removed schema references for    |--
--|                                                            R12.2 GSCC compliance            |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script VS_BULK_IMP_ERRORS....
PROMPT


select b.aops_batch_id aops,
       a.batch_id ebs,
       a.interface_table_name entity , 
       a.message_name,
       a.token1_name,
       a.token1_value,
       count(*) ct
from   hz_imp_errors a,
       xx_owb_crmbatch_status b
where  a.batch_id = b.ebs_batch_id
and    b.aops_batch_id > 1000
group by b.aops_batch_id, a.batch_id,a.interface_table_name, a.message_name,a.token1_name, a.token1_value
order by b.aops_batch_id;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
