-- +===========================================================================+
-- |                              Office Depot                                 |
-- |                                                                           |
-- +===========================================================================+
-- | Name         : XX_DEFECT28686_DEL.sql                                     |
-- | Rice Id      : DEFECT 28686                                               | 
-- | Description  :                                                            |  
-- | Purpose      : To remove customizations on PO Change History              |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version    Date          Author               Remarks                      | 
-- |=======    ==========    =================    =============================+
-- |1.0        24-Jul-2014   Sridevi K            Initial Version              |
-- +===========================================================================+
SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT SETTING CONTEXT XX_DEFECT28686_DEL.sql
PROMPT

begin
dbms_output.put_line('***********************/oracle/apps/pos/changeorder/server/customizations/site/0/PosRevisionHistoryVO');
jdr_utils.printdocument('/oracle/apps/pos/changeorder/server/customizations/site/0/PosRevisionHistoryVO');
jdr_utils.deletedocument('/oracle/apps/pos/changeorder/server/customizations/site/0/PosRevisionHistoryVO');
dbms_output.put_line('deleted***********************/oracle/apps/pos/changeorder/server/customizations/site/0/PosRevisionHistoryVO');

dbms_output.put_line('***********************/od/oracle/apps/xxptp/personalizations/oracle/apps/pos/inquiry/webui/customizations/site/0/PosViewComparePG');
jdr_utils.printdocument('/od/oracle/apps/xxptp/personalizations/oracle/apps/pos/inquiry/webui/customizations/site/0/PosViewComparePG');
jdr_utils.deletedocument('/od/oracle/apps/xxptp/personalizations/oracle/apps/pos/inquiry/webui/customizations/site/0/PosViewComparePG');
dbms_output.put_line('deleted***********************/od/oracle/apps/xxptp/personalizations/oracle/apps/pos/inquiry/webui/customizations/site/0/PosViewComparePG');

dbms_output.put_line('***********************/oracle/apps/pos/isp/server/customizations/site/0/CompareResult');
jdr_utils.printdocument('/oracle/apps/pos/isp/server/customizations/site/0/CompareResult');
jdr_utils.deletedocument('/oracle/apps/pos/isp/server/customizations/site/0/CompareResult');
dbms_output.put_line('deleted***********************/oracle/apps/pos/isp/server/customizations/site/0/CompareResult');


dbms_output.put_line('***********************/oracle/apps/pos/isp/server/customizations/site/0/CompareHeaderInfo');
jdr_utils.printdocument('/oracle/apps/pos/isp/server/customizations/site/0/CompareHeaderInfo');
jdr_utils.deletedocument('/oracle/apps/pos/isp/server/customizations/site/0/CompareHeaderInfo');
dbms_output.put_line('deleted***********************/oracle/apps/pos/isp/server/customizations/site/0/CompareHeaderInfo');
commit;

end;
/

SHOW ERR

