declare

l_site_demo_attr_group_id number;
l_source_aud_attr_group_id number;

cursor c_attr_group_id (p_attr_group_name in varchar2, p_attr_group_type in varchar2)
is
     SELECT attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = p_attr_group_name -- 'SITE_DEMOGRAPHICS'
        AND attr_group_type = p_attr_group_type; --'HZ_PARTY_SITES_GROUP';
		
cursor c1 (p_attr_group_id in NUMBER)
is
select /*+ full (a) parallel (a,4) */ party_site_id,
       min(extension_id) extension_id
from   apps.hz_party_sites_ext_b a     
  where   attr_group_id  = p_attr_group_id 
group by  party_site_id 
having count(1)>1;

begin

open c_attr_group_id ( 'SOURCE_AUDIT', 'HZ_PARTY_SITES_GROUP');
fetch c_attr_group_id into l_source_aud_attr_group_id;
close c_attr_group_id;

open c_attr_group_id ( 'SITE_DEMOGRAPHICS', 'HZ_PARTY_SITES_GROUP');
fetch c_attr_group_id into l_site_demo_attr_group_id;
close c_attr_group_id;

--remove duplicates in source audit => attr_group_id=168
for i in c1 (l_source_aud_attr_group_id)
loop
  delete 
  from   apps.hz_party_sites_ext_b
  where  extension_id = i.extension_id;
  commit;
end loop;  

--remove duplicates in site demographics => attr_group_id=161
for j in c1 (l_site_demo_attr_group_id)
loop
  delete 
  from   apps.hz_party_sites_ext_b
  where  extension_id = j.extension_id;
  commit;
end loop; 

exception
  when others then
    dbms_output.put_line('Exception: ' || SQLERRM);
end;	