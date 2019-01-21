SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET SERVEROUTPUT ON;

declare
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  l_attr_group_id                 number;
  l_old_attr_group_id             number;

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

  --Remove Old billdocs for contract non-ab customers
    SELECT attr_group_id
     into  l_old_attr_group_id
      FROM ego_attr_groups_v
     WHERE application_id = 222
       AND attr_group_name = 'OLD_BILLDOCS'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

    SELECT attr_group_id
     into  l_attr_group_id
      FROM ego_attr_groups_v
     WHERE application_id = 222
       AND attr_group_name = 'BILLDOCS'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

      UPDATE  XX_CDH_CUST_ACCT_EXT_B
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
                               FROM  HZ_CUST_ACCOUNTS acct,
                                     HZ_CUSTOMER_PROFILES prof
                                WHERE acct.cust_account_id = prof.cust_account_id
                                AND   prof.site_use_id is null
                                AND   acct.attribute18 = 'CONTRACT'
                                AND   nvl(prof.attribute3,'N') = 'N'
                               )
      and  attr_group_id=l_attr_group_id;

      dbms_output.put_line('No. of Rows Updated in XX_CDH_CUST_ACCT_EXT_B' || SQL%ROWCOUNT);

      UPDATE   XX_CDH_CUST_ACCT_EXT_TL
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
                               FROM  HZ_CUST_ACCOUNTS acct,
                                     HZ_CUSTOMER_PROFILES prof
                                WHERE acct.cust_account_id = prof.cust_account_id
                                AND   prof.site_use_id is null
                                AND   acct.attribute18 = 'CONTRACT'
                                AND   nvl(prof.attribute3,'N') = 'N'
                               )
      and  attr_group_id=l_attr_group_id;

      dbms_output.put_line('No. of Rows Updated in XX_CDH_CUST_ACCT_EXT_TL' || SQL%ROWCOUNT);

      COMMIT;

  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);
  end;
