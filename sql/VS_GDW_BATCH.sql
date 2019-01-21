REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_GDW_BATCH.sql                                                           |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              30-Apr-2008       Sarah Maria Justina     Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script VS_GDW_BATCH....
PROMPT


SELECT xhieas.n_ext_attr8, xhieas.c_ext_attr10, xhieas.batch_id,
       xhieas.n_ext_attr20, hosr.owner_table_id
  FROM apps.xxod_hz_imp_ext_attribs_stg xhieas,
       apps.hz_imp_batch_summary hibs,
       apps.hz_orig_sys_references hosr
 WHERE hibs.batch_id = xhieas.batch_id
   AND hibs.original_system = 'GDW'
   AND xhieas.attribute_group_code = 'SITE_DEMOGRAPHICS'
   AND hosr.orig_system_reference = xhieas.orig_system_reference
   AND hosr.orig_system = xhieas.orig_system
   AND hosr.owner_table_name = 'HZ_PARTY_SITES'
   AND hosr.status = 'A'
   AND xhieas.interface_status = '7'
   AND xhieas.batch_id = :1;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
