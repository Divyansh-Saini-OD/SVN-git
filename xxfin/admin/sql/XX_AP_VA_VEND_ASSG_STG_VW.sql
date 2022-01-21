SET SERVEROUTPUT ON
BEGIN
        apps.ad_zd_table.upgrade('XXFIN', 'XX_AP_VA_VEND_ASSG_STG');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/