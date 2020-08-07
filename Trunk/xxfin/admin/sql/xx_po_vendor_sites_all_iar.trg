CREATE OR REPLACE TRIGGER xx_po_vendor_sites_all_iar
   BEFORE INSERT
   ON apps.po_vendor_sites_all
   FOR EACH ROW
DECLARE
BEGIN
  :NEW.attribute7 := :NEW.vendor_site_id; 
END;
/
