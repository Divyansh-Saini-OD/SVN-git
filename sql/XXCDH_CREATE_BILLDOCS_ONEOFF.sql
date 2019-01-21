SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET SERVEROUTPUT ON;

declare
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  ln_batch_id                     number := &batch_id;

cursor c_direct_ab_customers 
is
select acct.orig_system_reference,
       acct.attribute18
from   hz_cust_accounts acct,
       hz_customer_profiles prof
where  acct.cust_account_id = prof.cust_account_id
and    prof.site_use_id is null
and    prof.attribute3 = 'Y'
and    acct.attribute18 = 'DIRECT';

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

    FOR i_rec in c_direct_ab_customers
    LOOP
      XXCDH_BILLDOCS_PKG.create_billdocs(
                                          ln_batch_id,
                                          'A0',
                                          i_rec.orig_system_reference,
                                          i_rec.attribute18
                                         );
    END LOOP;

  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);
  end;
/
