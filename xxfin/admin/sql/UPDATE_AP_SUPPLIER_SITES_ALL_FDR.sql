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
-- | V1.0     05-SEP-2017  Sridhar G.       	Initial version                     |
-- +================================================================================+

update ap_supplier_sites_all
set attribute8 = 'TR-FDR'
where NVL(attribute9,NVL(vendor_site_code_alt,vendor_site_id)) in ('467454',
'1069426',
'678020',
'710555',
'710555',
'1001452',
'1001772',
'1002965',
'980821',
'1069868',
'723874');


COMMIT;
/
