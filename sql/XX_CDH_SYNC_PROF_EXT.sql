SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- +======================================================================================|
-- | Name       : XX_CDH_SYNC_PROF_EXT.sql                                                |
-- | Description: This script will sync ext attribs related to cust profiles              |
-- |              with cust_profiles                                                      |
-- |                                                                                      | 
-- |                                                                                      |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |1.0       11-Jul-2008  Sreedhar Mohan   Initial Version                               |
-- +======================================================================================+

declare
  l_user_id             number;
  l_responsibility_id   number;
  l_resp_application_id number;
  l_count               number;
  
  cursor c1
  is
  select cust_account_id 
  from apps.XX_CDH_A_EXT_BILLDOCS_V
  where billdocs_paydoc_ind='Y'
  and billdocs_doc_type_disp='Consolidated Bill';
begin
  begin
    select user_id,
           responsibility_id,
           responsibility_application_id
    into   l_user_id,                      
           l_responsibility_id,            
           l_resp_application_id
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
                         l_resp_application_id
                       );
  exception
    when others then    
    dbms_output.put_line('Exception in initializing : ' || SQLERRM);
  end;

  l_count := 0;
  for i in c1
  loop
    update apps.hz_customer_profiles
       set cons_inv_flag='Y',
           cons_inv_type='DETAIL',
           last_updated_by=(select user_id 
                              from fnd_user 
                             where user_name='ODCDH'),
           last_update_date=sysdate
     where cust_account_id = i.cust_account_id; 
     l_count := l_count + 1;
  end loop;
     dbms_output.put_line('No. of Rows Updated : ' || l_count );
  commit;
exception
  when others then
  dbms_output.put_line('Exception: ' || SQLERRM);
  rollback;
end;
/
