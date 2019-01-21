set serveroutput on;

--Script to inactivate non-primary bill_to site_uses
declare

l_user_id                       NUMBER;
l_responsibility_id             NUMBER;
l_responsibility_appl_id        NUMBER;

l_object_version_number         NUMBER;
l_counter                       NUMBER;
l_return_status                 VARCHAR2(1); 
l_msg_count                     NUMBER; 
l_msg_data                      VARCHAR2(2000);
l_cust_site_use_rec             HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;

--Get all ELEC customers' non-primary BILL_TO site_use_ids associated to pay_docs
cursor c1
is
select  acct.account_number, 
        substr(acct.orig_system_reference,1,8) aops_acct_num, 
        substr(asit.orig_system_reference,1,14) site_seq_num, 
        asu.location, 
        asu.primary_flag,
        asu.site_use_id,
        asu.object_version_number,
        asu.orig_system_reference
from    apps.hz_cust_accounts acct, 
        apps.hz_cust_acct_sites_all asit, 
        apps.hz_cust_site_uses_all  asu,
        apps.xx_cdh_cust_acct_ext_b bills
where   acct.cust_account_id = asit.cust_account_id 
and     acct.cust_account_id = bills.cust_account_id
and     bills.attr_group_id = 166
and     bills.c_ext_attr3 = 'ELEC'
and     bills.c_ext_attr2 = 'Y'
and     asit.cust_acct_site_id = asu.cust_acct_site_id 
and     asu.site_use_code='BILL_TO'
and     asu.bill_to_site_use_id is null
and     asu.primary_flag = 'N';


begin

--set the context
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
    dbms_output.put_line('Exception in Apps initializing : ' || SQLERRM);
  end;

  --inactivate non primary bill_tos
  l_cust_site_use_rec := null;

  l_counter := 0;
  for i in C1
  loop

    l_object_version_number := null;
    
    select object_version_number
    into   l_object_version_number
    from   apps.HZ_CUST_SITE_USES_ALL
    where  site_use_id = i.site_use_id;
    
    l_cust_site_use_rec.site_use_id := i.site_use_id;
    l_cust_site_use_rec.status      := 'I';

    HZ_CUST_ACCOUNT_SITE_V2PUB.update_cust_site_use (
      p_init_msg_list                      => 'T',                      --IN     VARCHAR2 := FND_API.G_FALSE,
      p_cust_site_use_rec                  => l_cust_site_use_rec,      --IN     CUST_SITE_USE_REC_TYPE,
      p_object_version_number              => l_object_version_number,  --IN OUT NOCOPY NUMBER,
      x_return_status                      => l_return_status,          --OUT NOCOPY    VARCHAR2,
      x_msg_count                          => l_msg_count,              --OUT NOCOPY    NUMBER,
      x_msg_data                           => l_msg_data);              --OUT NOCOPY    VARCHAR2

    -- Standard call to get message count and if count is 1, get message info.
    FND_MSG_PUB.Count_And_Get(
        p_encoded => FND_API.G_FALSE,
        p_count => l_msg_count,
        p_data  => l_msg_data );

    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
        --dbms_output.put_line('S : ' || i.site_use_id);
        l_counter := l_counter + 1;
    ELSIF l_return_status = FND_API.G_RET_STS_ERROR THEN
        dbms_output.put_line('E : ' || i.site_use_id || ', x_msg_data: ' || l_msg_data);
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
        dbms_output.put_line('U : ' || i.site_use_id || ', x_msg_data: ' || l_msg_data);
    END IF;

  end loop;
  dbms_output.put_line('No of rows successfully updated: ' || l_counter);
  --commit the updates
  commit;

exception
  when others then
    dbms_output.put_line('Exception: ' || sqlerrm);

end;
/
