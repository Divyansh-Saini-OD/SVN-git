-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_ACCT_ROLERESP_CLEANUP.sql                         |
-- | Description :  Due the problem in iRec code, self service and revoked   |
-- |                self service responsibilities were created in accout     |
-- |                level role responsibility. This script will delete the   | 
-- |                revoked self service responsibility.                     |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   25-Sep-2008 Kathirvel          Initial draft version           |
-- +=========================================================================+

DECLARE

   CURSOR l_duplicate_roles IS
      SELECT  /* parallel (a,8) */ a.cust_account_role_id
      FROM    hz_cust_account_roles a 
      WHERE   a.cust_acct_site_id IS NULL
      AND     a.cust_account_role_id IN ( 
         SELECT  b.cust_account_role_id 
         FROM    hz_role_responsibility b
         WHERE   b.cust_account_role_id = a.cust_account_role_id 
         AND     b.responsibility_type  = 'SELF_SERVICE_USER')
      AND     a.cust_account_role_id IN ( 
         SELECT  c.cust_account_role_id 
         FROM    hz_role_responsibility c
         WHERE   c.cust_account_role_id = a.cust_account_role_id 
         AND     c.responsibility_type  = 'REVOKED_SELF_SERVICE_ROLE');



BEGIN

FOR I IN l_duplicate_roles
LOOP

    DELETE FROM HZ_ROLE_RESPONSIBILITY
    WHERE  cust_account_role_id   =  I.cust_account_role_id
    AND    responsibility_type  = 'REVOKED_SELF_SERVICE_ROLE';


END LOOP;

COMMIT;

dbms_output.put_line('Cleaned Successfully');

EXCEPTION
	WHEN OTHERS
	THEN
	    dbms_output.put_line('Error Message : '||SQLERRM);
END;

