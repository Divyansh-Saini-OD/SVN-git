create or replace 
PROCEDURE xx_ap_supp_rms_update_telex(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2,
    v_vendor_site_id IN NUMBER)
AS
BEGIN
  IF v_vendor_site_id IS NOT NULL THEN
    UPDATE ap_supplier_sites_all
    SET telex            = 'INTFXXCD'
    WHERE vendor_site_id = v_vendor_site_id ;
    COMMIT;
    fnd_file.PUT_LINE(fnd_file.LOG,'Table updated successfully for vendor site id: '||v_vendor_site_id);
    dbms_output.put_line('Table updated successfully for vendor site id: '||v_vendor_site_id);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  errbuf :='Error updating ap_supplier_sites_all for vendor_site_id: '||v_vendor_site_id;
  retcode:=2;
  fnd_file.PUT_LINE(fnd_file.LOG,'Error is :'||errbuf);
END;        