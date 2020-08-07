SET SERVEROUTPUT ON
BEGIN
        apps.ad_zd_table.upgrade('XXFIN', 'XX_PO_LINES_CONV_STG');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/
