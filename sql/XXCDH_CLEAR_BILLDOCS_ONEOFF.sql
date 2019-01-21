SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET SERVEROUTPUT ON;

declare
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;

  begin
    select user_id,
           responsibility_id,
           responsibility_application_id
    into   l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      from apps.fnd_user_resp_groups 
     where user_id=(select user_id 
                      from apps.fnd_user 
                     where user_name='ODCDH')
     and   responsibility_id=(select responsibility_id 
                                from apps.FND_RESPONSIBILITY 
                               where responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );

	--Clear BILLDOCS at customer level
	DELETE FROM
	XX_CDH_CUST_ACCT_EXT_B
	WHERE ATTR_GROUP_ID = (SELECT ATTR_GROUP_ID
				 FROM APPS.EGO_ATTR_GROUPS_V
				WHERE APPLICATION_ID = 222
				  AND ATTR_GROUP_NAME = 'BILLDOCS'
				  AND ATTR_GROUP_TYPE = 'XX_CDH_CUST_ACCOUNT'
			      );

	COMMIT;

	DELETE FROM
	XX_CDH_CUST_ACCT_EXT_TL
	WHERE ATTR_GROUP_ID = (SELECT ATTR_GROUP_ID
				 FROM APPS.EGO_ATTR_GROUPS_V
				WHERE APPLICATION_ID = 222
				  AND ATTR_GROUP_NAME = 'BILLDOCS'
				  AND ATTR_GROUP_TYPE = 'XX_CDH_CUST_ACCOUNT'
			      );

	COMMIT;

	--Clear BILLDOCS (Billing Exceptions) at Site level

	DELETE FROM
	XX_CDH_ACCT_SITE_EXT_B
	WHERE ATTR_GROUP_ID = (SELECT ATTR_GROUP_ID
				 FROM APPS.EGO_ATTR_GROUPS_V
				WHERE APPLICATION_ID = 222
				  AND ATTR_GROUP_NAME = 'BILLDOCS'
				  AND ATTR_GROUP_TYPE = 'XX_CDH_CUST_ACCT_SITE'
			      );

	COMMIT;

	DELETE FROM
	XX_CDH_ACCT_SITE_EXT_TL
	WHERE ATTR_GROUP_ID = (SELECT ATTR_GROUP_ID
				 FROM APPS.EGO_ATTR_GROUPS_V
				WHERE APPLICATION_ID = 222
				  AND ATTR_GROUP_NAME = 'BILLDOCS'
				  AND ATTR_GROUP_TYPE = 'XX_CDH_CUST_ACCT_SITE'
			      );

	COMMIT;

  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);
  end;
