SET SERVEROUTPUT ON
BEGIN
        ad_zd_table.upgrade('XXFIN', 'XX_PO_POM_HDR_INT_STG');   
EXCEPTION
WHEN OTHERS THEN
        dbms_output.put_line('error:'||SQLERRM);
END;
/