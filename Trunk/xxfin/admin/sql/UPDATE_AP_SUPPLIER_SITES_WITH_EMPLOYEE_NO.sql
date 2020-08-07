SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
SET SERVEROUTPUT ON SIZE 300000
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        : UPDATE_AP_SUPPLIER_SITES_WITH_EMPLOYEE_NO.sql 		   |
-- | Description : Script to update the attribute6 in ap_supplier_sites_all|
-- |               with employee number                                    |
-- | Rice ID     :  E3523                                                  |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     31-Aug-2017  Sridhar G.	   	Initial version		    	   |
-- +=======================================================================+

DECLARE
CURSOR cur_va_assign
  IS
    SELECT *
    FROM XX_AP_VA_VEND_ASSG_STG;
  
  v_tot_count     NUMBER:=0;
  v_process_count NUMBER:=0;
  v_no_data_found NUMBER:=0;
BEGIN
  FOR x IN cur_va_assign
  LOOP
    v_tot_count:=v_tot_count+1;
    BEGIN
      UPDATE
        /*+ parallel (assa,3) */
        ap_supplier_sites_all assa
      SET assa.attribute6  =x.employee_no
      WHERE vendor_site_code = x.vendor_site_code;
      
      
      IF sql%rowcount      > 0 THEN
        v_process_count   := v_process_count+1;
      ELSE
        v_no_data_found:=v_no_data_found+1;
        dbms_output.put_line('no vendor_site_code found: '||x.vendor_site_code);
      END IF;
      
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_no_data_found:=v_no_data_found+1;
      dbms_output.put_line('no vendor_site_code found: '||x.vendor_site_code);
    WHEN OTHERS THEN
      dbms_output.put_line('Error: '||x.vendor_site_code||' : '||SQLERRM);
    END;
  END LOOP;
  commit;
  dbms_output.put_line('v_tot_count: '||v_tot_count||'   v_process_count: '||v_process_count||'  v_no_data_found: '||v_no_data_found);
END;
/

