set serveroutput on;
set timing on;

declare
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  l_object_version_number         number;
  
    prof_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
    l_check         varchar2(1);
    l_count         number;

    l_return_status            varchar2(1)     := null;
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_cust_account_profile_id  number          := 0;
  
  cursor c1
  is
  select acct.account_number, acct.account_name, substr(acct.orig_system_reference, 1,8) AOPS_ACCT_ID, 
       prof.attribute3, prof.cons_inv_flag, prof.cons_bill_level, prof.cust_account_profile_id
from   apps.hz_customer_profiles prof,
       apps.hz_cust_accounts     acct
where  acct.cust_account_id = prof.cust_account_id
--and    prof.site_use_id is null
--and    prof.standard_terms <> 5
--and    prof.attribute3 = 'Y'
and    acct.status='A'
and    prof.status='A'
and    prof.cons_inv_flag='Y'
and    nvl(prof.cons_bill_level, 'NOTSITE') = 'SITE';
--and    acct.account_number in (
--'268127');
--'16635905',
--'15004181',
--'336575',
--'336564',
--'328998'
--); 
  
begin
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
  exception
    when others then
    dbms_output.put_line('Exception in initializing : ' || SQLERRM);
  end;

--Update the customer profiles
    l_count := 0;
    for i_rec in c1
    loop
       
       --fnd_file.put_line(FND_FILE.LOG,'  site_use_id' || l_count ||': ' || c_rec.site_use_id);
       prof_rec  := NULL;
	   l_object_version_number := null;
       HZ_CUSTOMER_PROFILE_V2PUB.get_customer_profile_rec (
            p_init_msg_list                         => 'T',
            p_cust_account_profile_id               => i_rec.cust_account_profile_id,
            x_customer_profile_rec                  => prof_rec,
            x_return_status                         => l_return_status,
            x_msg_count                             => l_msg_count,
            x_msg_data                              => l_msg_data
          );
      if( l_return_status = 'S') then
              
        select object_version_number
        into   l_object_version_number
        from   hz_customer_profiles
        where  cust_account_profile_id = i_rec.cust_account_profile_id;

			  --prof_rec.cons_bill_level := 'SITE';
			  prof_rec.override_terms  := 'Y';
	  			  
              l_return_status  := null;
              l_msg_count      := 0;
              l_msg_data       := null; 
              --
              HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
               p_init_msg_list                      => 'T',
               p_customer_profile_rec               => prof_rec,
               p_object_version_number              => l_object_version_number,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );
              --
              --fnd_file.put_line(FND_FILE.LOG,'      update_customer_profile, x_return_status: ' || l_return_status);
              --fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
              -- 
              if l_msg_count > 0 THEN  
                begin
                  FOR I IN 1..l_msg_count
                  LOOP
                     l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                  END LOOP;
                end;        
              --fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
              end if;
              --
              commit;
			  l_count := l_count + 1;
	  end if;	  
	end loop;

commit;

dbms_output.put_line('l_count: ' || l_count); 

exception
  when others then
  dbms_output.put_line('Exception: ' || SQLERRM);
  rollback;
end;
/