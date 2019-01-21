BEGIN

UPDATE hz_party_sites SET status = 'A'
WHERE party_id=5244255;

UPDATE hz_party_sites SET identifying_address_flag='Y'
WHERE party_id=5244255 and orig_system_reference='29255232-00001-A0';

UPDATE hz_party_site_uses SET status = 'A'
WHERE party_site_id IN
(SELECT party_site_id FROM hz_party_sites WHERE party_id=5244255);

UPDATE hz_party_site_uses SET primary_per_type = 'Y'
WHERE party_site_use_id IN (1111549,1111605);

UPDATE hz_cust_site_uses_all SET primary_flag='Y'
WHERE cust_acct_site_id =945617;

COMMIT;

EXCEPTION WHEN OTHERS THEN
 DBMS_OUTPUT.PUT_LINE ('Unexpected Error : ' || SQLERRM);
END;