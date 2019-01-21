DECLARE
-- Not including site_use_code in the cursor query because of performance issues.
CURSOR site_uses_cur IS
SELECT cust_acct_site_id,site_use_id,site_use_code
FROM HZ_CUST_SITE_USES_ALL
WHERE status = 'I';


TYPE site_uses_cur_tbl_type IS TABLE OF site_uses_cur%ROWTYPE INDEX BY BINARY_INTEGER;

site_uses_cur_tbl    site_uses_cur_tbl_type;
l_cust_account_id    NUMBER;
l_bulk_limit         NUMBER := 200;
l_records_updated    NUMBER := 0;
l_commit_flag        VARCHAR2(1);

BEGIN

 l_commit_flag := '&COMMIT_Y_N';

 OPEN site_uses_cur;

 LOOP

  FETCH site_uses_cur BULK COLLECT INTO site_uses_cur_tbl LIMIT l_bulk_limit;
    IF site_uses_cur_tbl.COUNT = 0 THEN
      EXIT;
    END IF;

  FOR ln_counter IN site_uses_cur_tbl.FIRST .. site_uses_cur_tbl.LAST 
  LOOP
   IF site_uses_cur_tbl(ln_counter).site_use_code = 'BILL_TO' THEN
    BEGIN  
      SELECT cust_account_id INTO l_cust_account_id
      FROM hz_cust_acct_sites_all
      WHERE cust_acct_site_id = site_uses_cur_tbl(ln_counter).cust_acct_site_id;

      UPDATE hz_cust_site_uses_all SET bill_to_site_use_id = NULL
      WHERE bill_to_site_use_id = site_uses_cur_tbl(ln_counter).site_use_id
      AND cust_acct_site_id IN (SELECT cust_acct_site_id 
                                FROM HZ_CUST_ACCT_SITES_aLL
                                WHERE cust_account_id = l_cust_account_id);

      l_records_updated := l_records_updated + SQL%ROWCOUNT;   

     EXCEPTION WHEN NO_DATA_FOUND THEN
       DBMS_OUTPUT.PUT_LINE ('No Cust Site Record Found For Site Id:' || site_uses_cur_tbl(ln_counter).cust_acct_site_id);
     END;
    END IF; 
   END LOOP;
  
  IF NVL(l_commit_flag,'N') = 'Y' THEN 
    COMMIT;
  END IF;
 END LOOP;
    DBMS_OUTPUT.PUT_LINE ('Total Records Updated:' || l_records_updated); 
    DBMS_OUTPUT.PUT_LINE ('Commit Executed?:' || NVL(l_commit_flag,'N'));     
END;