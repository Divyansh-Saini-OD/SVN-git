SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Oracle                                                   |
-- +================================================================================+
-- | Name :UPDATE_AP_SUPPLIER_SITES_ALL_CONSIGN                                     |
-- | Description :   SQL Script to update ap_supplier_sites_all with proper     	| 
-- |                  Consignment Frequency                                         |
-- | Rice ID     :  E3522 															|
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     30-AUG-2017  Sridhar G.       	Initial version                     |
-- +================================================================================+

update ap_supplier_sites_all set attribute4 = 'WKLY'
where vendor_site_code like 'TCN%' and vendor_site_code != 'TCN1000634';

update ap_supplier_sites_all set attribute4 = 'DLY'
where vendor_site_code = 'TCN1000634';


COMMIT;
/
