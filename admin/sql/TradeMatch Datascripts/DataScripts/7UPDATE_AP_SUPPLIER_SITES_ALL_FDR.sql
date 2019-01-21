SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Oracle                                                   |
-- +================================================================================+
-- | Name :UPDATE_AP_SUPPLIER_SITES_ALL_FDR                                     	|
-- | Description :   SQL Script to update ap_supplier_sites_all with 'TR-FDR'     	| 
-- |                                                                                |
-- | Rice ID     :  E3522 															|
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     30-AUG-2017  Sridhar G.       	Initial version                     |
-- +================================================================================+

Declare
CURSOR C1 IS
SELECT vendor_site_id
  FROM ap_supplier_sites_all b ,
	   ap_suppliers a
 WHERE a.segment1 in ('11128','11442','11479','23342','27885','186761','210587',
					  '247939','247973','248503','258622','286322','289307','290172'
					 )	   
   AND b.vendor_id=a.vendor_id					 
   AND vendor_site_code in 
(
'TST0000000583PY',
'TST0000000583PR',
'TST0000008502PY',
'TST0000008502PR',
'TST1069426',
'TST678020',
'TST710555',
'TST1001452',
'TST1001772',
'TST1002965',
'TST0000478406',
'TST980821PY',
'TST980821PR',
'TST0000008902PY',
'TST0000008902PR',
'TST1069868',
'TST723874',
'TST0000467454PY',
'TST0000467454PR'
);

BEGIN
  FOR cur IN C1 LOOP

    update ap_supplier_sites_all
       set attribute8 = 'TR-FRONTDOOR'
     where vendor_site_id=cur.vendor_site_id;
  END LOOP;
  COMMIT;
END;
/
