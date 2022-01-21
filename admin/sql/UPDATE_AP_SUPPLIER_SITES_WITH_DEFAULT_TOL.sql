SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
SET SERVEROUTPUT ON SIZE 300000
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- +=======================================================================+
-- | Name        : UPDATE_AP_SUPPLIER_SITES_WITH_DEFAULT_TOL.sql 		   |
-- | Description : Script to update the Tolerance_Id in ap_supplier_sites_all|
-- |               						                                   |
-- | Rice ID     :  E3523                                                  |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     31-Aug-2017  Sridhar G.	   	Initial version		    	   |
-- +=======================================================================+
DECLARE
var_tol_id number:=null;
BEGIN
  BEGIN
    select tolerance_id into var_tol_id
    from AP_TOLERANCE_TEMPLATES
    where tolerance_name = 'US_OD_TRADE_DEFAULT';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('US_OD_TRADE_DEFAULT Not set up');
  END;

if var_tol_id is not null then
  UPDATE ap_supplier_sites_all assa
  SET assa.tolerance_id  =var_tol_id
	where attribute8 in ('TR-STK','TR-VW','TR-FRONTDOOR');

	dbms_output.put_line('No of records updated: '||SQL%ROWCOUNT);	
 
end if;

COMMIT;
EXCEPTION
WHEN OTHERS THEN
	dbms_output.put_line('Error: '||SQLERRM);  
END;
/
