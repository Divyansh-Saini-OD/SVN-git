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
-- |DRAFT 1A   02-JAN-2008   Manish Chavan        Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
SET SERVEROUTPUT ON

PROMPT
PROMPT Dropping Existing Custom Table Type......
PROMPT

WHENEVER SQLERROR CONTINUE;
declare
begin
FOR i in 1..90000 LOOP
    INSERT INTO xx_om_hvop_seq_lock(SEQ_NUMBER)
    values(i);
END LOOP;

exception
    when others then
    dbms_output.put_line(' The sql error is '||sqlerrm);
end;
/
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
COMMIT;
EXIT;
