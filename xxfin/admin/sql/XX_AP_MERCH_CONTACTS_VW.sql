SET SERVEROUTPUT ON
BEGIN
        ad_zd_table.upgrade('XXFIN', 'XX_AP_MERCH_CONTACTS');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/