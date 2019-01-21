SET SERVEROUTPUT ON
BEGIN
        apps.ad_zd_table.upgrade('XXFIN', 'XX_GL_ARCS_BALANCES');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/
