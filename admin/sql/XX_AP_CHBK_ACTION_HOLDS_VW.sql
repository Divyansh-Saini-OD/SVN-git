SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Table View 

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

--+==============================================================================================+--
--|                                                                                              |--
--| Object Name    : OD AP Trade Match Custom Workbench                                          |--
--|                                                                                              |--
--| Program Name   : XX_AP_CHBK_ACTION_HOLDS_VW.sql                                              |--        
--| RICE ID        : E3523                                                                       |--   
--| Purpose        : Create view for the Custom table                                            |--
--|                                                                                              |--
--|                                                                                              |-- 
--| Change History  :                                                                            |--
--| Version           Date             Changed By              Description                       |--
--+==============================================================================================+--
--| 1.0               03-Sep-2017      Paddy Sanjeevi           Baselined                        |
--+==============================================================================================+-- 
                                   
SET SERVEROUTPUT ON
BEGIN
        apps.ad_zd_table.upgrade('XXFIN', 'XX_AP_CHBK_ACTION_HOLDS');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/

SHOW ERR
