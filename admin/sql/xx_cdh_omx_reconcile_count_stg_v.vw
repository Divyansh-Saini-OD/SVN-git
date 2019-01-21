SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +===================================================================+
-- |                        Office Depot                               |
-- +===================================================================+
-- | View Name  :  xx_cdh_omx_reconcile_stg_v.vw                       |
-- | Description :  xx_cdh_omx_reconcile_stg table                     |
-- | Rice Id     :  700                                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       30-MAR-2015  Havish Kasina      Initial draft version    |
-- +===================================================================+

WHENEVER SQLERROR CONTINUE;

SET TERM ON

PROMPT
PROMPT Create or Replace View xx_cdh_omx_reconcile_stg_v 
PROMPT

CREATE OR REPLACE VIEW xxcrm.xx_cdh_omx_reconcile_stg_v 
AS        
   SELECT  batch_id,
           MAX(no_of_omx_ebill_docs) as no_of_omx_ebill_docs,
           MAX(no_of_omx_ebill_contacts) as no_of_omx_ebill_contacts,
           MAX(no_of_omx_ap_contacts) as no_of_omx_ap_contacts,
           MAX(no_of_omx_addr_exceptions) as no_of_omx_addr_exceptions,
           MAX(no_of_omx_credits) as no_of_omx_credits,
           MAX(no_of_omx_dunning) as no_of_omx_dunning,
           MAX(no_of_ods_ebill_docs) as no_of_ods_ebill_docs,
           MAX(no_of_ods_ebill_contacts) as no_of_ods_ebill_contacts,
           MAX(no_of_ods_ap_contacts) as no_of_ods_ap_contacts,
           MAX(no_of_ods_addr_exceptions) as no_of_ods_addr_exceptions,
           MAX(no_of_ods_credits) as no_of_ods_credits,
           MAX(no_of_ods_dunning) as no_of_ods_dunning,
           status,
           error_message,
           TRUNC(creation_date) as creation_date,
           created_by,
           trunc(last_update_date) as last_update_date
      FROM xx_cdh_omx_reconcile_count_stg
     GROUP BY status,
              batch_id,
              error_message,
              TRUNC(creation_date),
              created_by,
              TRUNC(last_update_date);

PROMPT
PROMPT Grant xxcrm.xx_cdh_omx_reconcile_stg_v TO ERP_SYSTEM_TABLE_SELECT_ROLE
PROMPT   
GRANT SELECT ON xxcrm.xx_cdh_omx_reconcile_stg_v TO ERP_SYSTEM_TABLE_SELECT_ROLE
/

PROMPT
PROMPT Grant xxcrm.xx_cdh_omx_reconcile_stg_v to APPS
PROMPT   
GRANT ALL ON xxcrm.xx_cdh_omx_reconcile_stg_v TO APPS
/
            
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

SHOW ERRORS;
EXIT;

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
