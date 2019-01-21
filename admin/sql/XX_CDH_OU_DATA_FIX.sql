DECLARE

l_orig_system_ref  VARCHAR2(60);
l_site_ca          NUMBER;

CURSOR sites_cur IS
SELECT cust_acct_site_id,ORIG_SYSTEM_REFERENCE
FROM APPS.HZ_CUST_ACCT_SITES_ALL
WHERE ORIG_SYSTEM_REFERENCE LIKE '29255232-%-A0'
AND ORG_ID=404;

CURSOR site_uses (site_id NUMBER) IS
SELECT site_use_id,orig_system_reference
FROM APPS.HZ_CUST_SITE_USES_ALL
WHERE cust_acct_site_id=site_id;

CURSOR site_uses_ca (site_id NUMBER) IS
SELECT site_use_id,orig_system_reference
FROM APPS.HZ_CUST_SITE_USES_ALL
WHERE cust_acct_site_id=site_id;


BEGIN

FOR I in sites_cur LOOP

-- Activate for US
 
  UPDATE APPS.HZ_CUST_ACCT_SITES_ALL
  SET STATUS = 'A'
  WHERE CUST_ACCT_SITE_ID=I.cust_acct_site_id;


  UPDATE APPS.HZ_ORIG_SYS_REFERENCES
  SET STATUS='A',END_DATE_ACTIVE=NULL
  WHERE ORIG_SYSTEM_REFERENCE = I.orig_system_reference
  AND orig_system = 'A0'
  AND OWNER_TABLE_ID = I.cust_acct_site_id
  AND Owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';

  UPDATE APPS.HZ_CUST_SITE_USES_ALL
  SET status='A'
  WHERE CUST_ACCT_SITE_ID = I.cust_acct_site_id;

  FOR J in site_uses(I.cust_acct_site_id) LOOP
     UPDATE APPS.HZ_ORIG_SYS_REFERENCES
     SET STATUS='A',END_DATE_ACTIVE=NULL
     WHERE ORIG_SYSTEM_REFERENCE = J.orig_system_reference
     AND orig_system = 'A0'
     AND OWNER_TABLE_ID = J.site_use_id
     AND Owner_table_name = 'HZ_CUST_SITE_USES_ALL';
  END LOOP;


-- Inactivate For CA

   BEGIN

   SELECT cust_acct_site_id INTO l_site_ca FROM APPS.HZ_CUST_ACCT_SITES_ALL
   WHERE ORIG_SYSTEM_REFERENCE = I.orig_system_reference
   AND ORG_ID=403;

   UPDATE APPS.HZ_CUST_ACCT_SITES_ALL
   SET STATUS = 'I'
   WHERE CUST_ACCT_SITE_ID=l_site_ca;

   UPDATE APPS.HZ_ORIG_SYS_REFERENCES
   SET STATUS='I',END_DATE_ACTIVE=SYSDATE-1
   WHERE ORIG_SYSTEM_REFERENCE = I.orig_system_reference
   AND orig_system = 'A0'
   AND OWNER_TABLE_ID = l_site_ca
   AND Owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';

   UPDATE APPS.HZ_CUST_SITE_USES_ALL
   SET status='I'
   WHERE CUST_ACCT_SITE_ID = l_site_ca;

   FOR K in site_uses(l_site_ca) LOOP
     UPDATE APPS.HZ_ORIG_SYS_REFERENCES
     SET STATUS='I',END_DATE_ACTIVE=SYSDATE-1
     WHERE ORIG_SYSTEM_REFERENCE = K.orig_system_reference
     AND orig_system = 'A0'
     AND OWNER_TABLE_ID = K.site_use_id
     AND Owner_table_name = 'HZ_CUST_SITE_USES_ALL';
   END LOOP;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    NULL;
  END;

 

END LOOP;

COMMIT;

EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line('Unexpected Error:' || SQLERRM);
END;
/