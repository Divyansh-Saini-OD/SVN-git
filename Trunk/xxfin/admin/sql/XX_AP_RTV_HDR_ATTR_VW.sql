SET SERVEROUTPUT ON
BEGIN
        ad_zd_table.upgrade('XXFIN', 'XX_AP_RTV_HDR_ATTR');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/