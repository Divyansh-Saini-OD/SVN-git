 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Procedure XX_AP_UPD_SUPP_SITE_DUNS_ATTR5
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PROCEDURE XX_AP_UPD_SUPP_SITE_DUNS_ATTR5(x_error_buff  OUT  VARCHAR2
                                                           ,x_ret_code   OUT  NUMBER)
IS

-- +===================================================================+
-- |                  Office Depot - EBS Upgrade                       |
-- |                  Oracle GSD, Bangalore                            |
-- +===================================================================+
-- | Name        :  XX_AP_UPD_SUPP_SITE_DUNS_ATTR5.prc                 |
-- | Description :  Procedure for C0265 DUNS Conversion                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |  1.0     22-Nov-2013 Darshini           Initial Version           |
-- |  1.1     03-Feb-2014 Veronica           Modified for Defect 27860 |
-- |  1.2     04-Nov-2015 Harvinder Rakhra   Retroffit R12.2           |
-- +===================================================================+

--ln_count  NUMBER;
ln_count  NUMBER:=0;     --Added for Defect 27860


-- added for defect 27860 START
CURSOR lcu_po_ven_duns
IS
SELECT * 
FROM po_vendor_sites_all pvs 
WHERE duns_number is not null;    

TYPE po_vendor_sites_tbl IS TABLE OF po_vendor_sites_all%ROWTYPE;
l_po_vendor_sites_tbl                  po_vendor_sites_tbl;
-- added for defect 27860 END

BEGIN
  FND_FILE.PUT_LINE (FND_FILE.LOG,'OD: Update AP Supplier Sites with DUNS Number');
  FND_FILE.PUT_LINE (FND_FILE.LOG,' ');
  FND_FILE.PUT_LINE (FND_FILE.LOG,'Updating Attribute5 of AP_SUPPLIER_SITES_ALL with the DUNS Number');               

-- Added for Defect 27860 START

OPEN lcu_po_ven_duns;
LOOP
FETCH lcu_po_ven_duns  BULK COLLECT INTO l_po_vendor_sites_tbl LIMIT 1000;
       FORALL i IN 1..l_po_vendor_sites_tbl.COUNT
	   UPDATE ap_supplier_sites_all assa 
	      SET attribute5          = l_po_vendor_sites_tbl(i).duns_number
		WHERE assa.vendor_site_id = l_po_vendor_sites_tbl(i).vendor_site_id;
	   COMMIT;
	   
	   ln_count := ln_count + l_po_vendor_sites_tbl.COUNT;
       EXIT WHEN lcu_po_ven_duns%NOTFOUND;
END LOOP;

-- Added for Defect 27860 END

  /*UPDATE ap_supplier_sites_all ASSA
     SET attribute5 = (SELECT duns_number
		         FROM po_vendor_sites_all PVS
	                WHERE ASSA.vendor_site_id = PVS.vendor_site_id);*/    --Commented for Defect 27860

  FND_FILE.PUT_LINE (FND_FILE.LOG,' ');

  FND_FILE.PUT_LINE (FND_FILE.LOG,'Attribute5 Updated with the DUNS Number');

 -- ln_count :=sql%rowcount;    --Commented for Defect 27860
 -- COMMIT;  

  FND_FILE.PUT_LINE (FND_FILE.LOG,'Number of rows updated with DUNS Number in AP_SUPPLIER_SITES_ALL: '||ln_count);

  EXCEPTION
  WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '||SQLERRM);
  x_ret_code := 2;
  ROLLBACK;
  
END;
/
SHOW ERRORS;
