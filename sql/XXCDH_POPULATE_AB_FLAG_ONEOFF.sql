SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
SET SERVEROUTPUT ON;

declare
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  l_cust_account_id               number;
  l_counter                       number;

  cursor c1 (p_orig_system_reference varchar2)
  is
  select cust_account_id
  from   apps.hz_cust_accounts
  where  orig_system_reference=p_orig_system_reference;

  cursor c2
  is
  select acct_site_orig_sys_reference
  from   apps.xxod_hz_summary
  where  batch_id=24092009;

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

    update apps.xxod_hz_summary
    set    acct_site_orig_sys_reference = trim(substr(acct_site_orig_sys_reference,1,17))
    where  batch_id=24092009;

    l_counter := 0;
    for i_rec in c2
      loop
        
        open c1(i_rec.acct_site_orig_sys_reference);
	fetch c1 into l_cust_account_id;

	update apps.hz_customer_profiles
	set    attribute3 = 'Y'
	where  cust_account_id = l_cust_account_id
	and    site_use_id is null;
    
        commit;

	l_counter := l_counter + 1;

	dbms_output.put_line('No. of rows updated: ' + l_counter);
    end loop;

  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);
  end;
/
