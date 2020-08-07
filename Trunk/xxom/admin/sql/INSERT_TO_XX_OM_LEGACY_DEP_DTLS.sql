-- +============================================================================================+
-- |                      Office Depot - Project Simplify                                       |
-- |                    Oracle NAIO Consulting Organization                                     |
-- +============================================================================================+
-- | Name        : DATA_XX_OM_HVOP_SEQ_LOCK                                                     |
-- | Rice Id      : I1272                                                                       | 
-- | Description  : INT-I1272_SalesOrderFrom LegacySystems(HVOP) Data Creation                  |  
-- | Purpose      : Create data in Custom Table XX_OM_HVOP_SEQ_LOCK.tbl.                        |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   11-JUL-2011   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
--SET VERIFY      OFF
--SET TERM        OFF
--SET FEEDBACK    OFF
--SET SHOW        OFF
--SET ECHO        OFF
--SET TAB         OFF
SET SERVEROUTPUT ON

PROMPT
PROMPT Pass 180 for P_days parameter......
PROMPT

DECLARE
ln_days NUMBER := &P_days;
BEGIN

DBMS_OUTPUT.PUT_LINE('Begin Inserting Into xx_om_legacy_dep_dtls');

INSERT INTO xxom.xx_om_legacy_dep_dtls
          ( transaction_number
          , order_source_id
          , orig_sys_document_ref
          , creation_date
          , created_by
          , last_update_date
          , last_updated_by
          ) 
          ( SELECT DISTINCT transaction_number
                 , order_source_id
                 , orig_sys_document_ref
                 , SYSDATE
                 , -1
                 , SYSDATE
                 , -1
              FROM xxom.xx_om_legacy_deposits d
             WHERE creation_date >= (SYSDATE - ln_days)
               AND NOT EXISTS (SELECT 1 FROM xxom.xx_om_legacy_dep_dtls dt
                                WHERE dt.transaction_number = d.transaction_number)
          );
DBMS_OUTPUT.PUT_LINE('Total Number of Rows Inserted :' || SQL%ROWCOUNT);
DBMS_OUTPUT.PUT_LINE('End OF Insert');
END;
/
PROMPT
PROMPT Exiting....
PROMPT

--SET FEEDBACK ON
COMMIT;
--EXIT;