--truncate table xx_fin_site_use_locations
--select * from xx_fin_site_use_locations;
/*
select *
--site_use_id, count(1) 
from xx_fin_site_use_locations
--from   hz_cust_accounts
--where  account_number='51101'; --xx_fin_site_use_locations
where    cust_account_id = 58541
group by site_use_id
having count(1) > 1
;
*/
declare
  cursor c_site_use_locations (p_cust_account_id in number)
  is
  select hcas.cust_account_id
        ,hcsu.cust_acct_site_id
        ,hcsu.site_use_id
        ,hcas.party_site_id
        ,hps.location_id
        ,hcas.org_id
        ,hcsu.site_use_code
        ,hcsu.location
        ,hcas.bill_to_flag
  from  hz_cust_acct_sites_all hcas
       ,hz_cust_site_uses_all  hcsu
       ,hz_party_sites         hps
  where hcas.cust_acct_site_id = hcsu.cust_acct_site_id
   and  hcas.party_site_id = hps.party_site_id
   and  hcas.cust_account_id = p_cust_account_id
   ;
   
   cursor c_large_customers
   is
   select *
   from   xx_fin_irec_large_customers
   --select cust_account_id
   --from   xx_fin_irec_large_customers
   --minus
   --select distinct cust_account_id
   --from   xx_fin_site_use_locations
   ;
   
begin
   for j_record in c_large_customers
   loop
     for i_record in c_site_use_locations (j_record.cust_account_id)
     loop
       begin
         insert into xx_fin_site_use_locations( site_use_id
                                              , location_id
                                              , cust_acct_site_id
                                              , party_site_id
                                              , cust_account_id
                                              , org_id
                                              , site_use_code
                                              , location
                                              , bill_to_flag
                                              )
                                              values (
                                              i_record.site_use_id
                                            , i_record.location_id
                                            , i_record.cust_acct_site_id
                                            , i_record.party_site_id
                                            , i_record.cust_account_id
                                            , i_record.org_id
                                            , i_record.site_use_code
                                            , i_record.location
                                            , i_record.bill_to_flag
                                            );
         commit;                                        
       exception
         when others then
           dbms_output.put_line('Exception in inserting - ' || i_record.site_use_id 
                                       || ' , ' || i_record.location_id 
                                       || ' , ' || i_record.cust_acct_site_id
                                       || ' , ' || i_record.party_site_id
                                       || ' , ' || i_record.cust_account_id
                                       || ' , ' || i_record.org_id
                                       || ' , ' || i_record.site_use_code
                                       || ' , ' || i_record.location
                                       || ' , ' || i_record.bill_to_flag || '-' || SQLERRM);
       end;
         
     end loop;
   end loop;
   
 exception
   when others then
     dbms_output.put_line('Exception: ' || SQLERRM);
end;     

--5159 seconds