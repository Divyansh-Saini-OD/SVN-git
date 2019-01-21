GRANT SELECT ON ap_suppliers_int TO XXCNV;

GRANT SELECT ON ap_supplier_sites_int TO XXCNV;

GRANT SELECT ON ap_sup_site_contact_int TO XXCNV;
--
-- 11/20/2007: Commented by Anamitra Banerjee
--
/*
GRANT ALL ON po_vendors TO APPS_RW;

GRANT ALL ON po_vendor_sites_all TO APPS_RW;

GRANT ALL ON po_vendor_contacts TO APPS_RW;

GRANT ALL ON ap_suppliers_int TO APPS_RW;

GRANT ALL ON ap_supplier_sites_int TO APPS_RW;

GRANT ALL ON ap_sup_site_contact_int TO APPS_RW;

GRANT ALL ON xx_fin_translate_pkg to APPS_RW;

GRANT ALL ON xx_fin_translatedefinition to APPS_RW;

GRANT ALL ON xx_fin_translatevalues to APPS_RW;
*/
GRANT SELECT ON po_vendors TO xxcnv;

GRANT SELECT ON po_vendor_sites_all TO xxcnv;
--
-- 11/20/2007: Added by Anamitra Banerjee
--
GRANT SELECT ON ap_suppliers_int TO xxfin;

GRANT SELECT ON ap_supplier_sites_int TO xxfin;

GRANT SELECT ON ap_sup_site_contact_int TO xxfin;

GRANT SELECT ON po_vendors TO xxfin;

GRANT SELECT ON po_vendor_sites_all TO xxfin;