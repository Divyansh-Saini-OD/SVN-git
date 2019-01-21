DECLARE
  v_vendor_site_id NUMBER := 0;
BEGIN
  WHILE v_vendor_site_id < 650000 LOOP
    SELECT po_vendor_sites_s.NEXTVAL
    INTO v_vendor_site_id
    FROM dual;
  END LOOP;
END;
/
