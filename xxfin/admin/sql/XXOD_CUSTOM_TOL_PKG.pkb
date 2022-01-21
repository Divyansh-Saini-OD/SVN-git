create or replace package BODY XXOD_CUSTOM_TOL_PKG as
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XXOD_CUSTOM_TOL_PKG.pkb                             	 |
-- | Description :  Package for updating Tolerance Information in the custom |
-- |                table													 |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       01-AUG-2017 Sridhar G.	     Initial version                 |
-- +=========================================================================+
PROCEDURE UPDATE_TOLERANCE_DATA(P_VENDOR_ID IN NUMBER) AS

cursor CUST_SITE_DATA iS
  select assa.VENDOR_ID, assa.vendor_site_id, assa.ORG_ID
  from AP_SUPPLIER_SITES_ALL ASSA
  WHERE VENDOR_ID = P_VENDOR_ID
  MINUS
  select act.supplier_ID as Vendor_id, act.supplier_site_id as vendor_site_id, act.ORG_ID
  from xx_ap_custom_tolerances act
  WHERE act.supplier_ID = P_VENDOR_ID;
  
begin  
 
  FOR c1 in CUST_SITE_DATA LOOP
    INSERT INTO xx_ap_custom_tolerances (SUPPLIER_ID, SUPPLIER_SITE_ID, ORG_ID)
    VALUES (c1.VENDOR_ID, c1.VENDOR_SITE_ID, c1.ORG_ID);
    DBMS_OUTPUT.PUT_LINE('The following Supplier Site updated: '||c1.VENDOR_ID||' : '|| c1.VENDOR_SITE_ID||' : '||c1.ORG_ID);
    FND_FILE.PUT_LINE(FND_FILE.log,'The following Supplier Site updated: '||c1.VENDOR_ID||' : '|| c1.VENDOR_SITE_ID||' : '||c1.ORG_ID);
  END LOOP;
  commit;

EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error: '||SQLERRM);
  fnd_file.put_line(fnd_file.log,'Error: '||SQLERRM);
end UPDATE_TOLERANCE_DATA;
end XXOD_CUSTOM_TOL_PKG;
/
