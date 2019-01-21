-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT25970_DEL.sql                                     |
-- | Rice Id      : DEFECT 25970                                               | 
-- | Description  :                                                            |  
-- | Purpose      : To remove personalizations                                 |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        27-FEB-2013   Sridevi K            Initial Version              |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT25970_DEL.sql
PROMPT

begin
dbms_output.put_line('delete document /oracle/apps/fnd/framework/webui/customizations/site/0/OADialogPage');
jdr_utils.deletedocument('/oracle/apps/fnd/framework/webui/customizations/site/0/OADialogPage');


commit;
end;
/

SHOW ERR
