---+========================================================================================================+        
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_print_summbill.pkb                                      |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                     |
---|    ------------    ----------------- ---------------    ---------------------                           |
---|    1.0             02-AUG-2007       Balaguru Seshadri  Initial Version                                 |
---|                                                                                                        |
---+========================================================================================================+
create or replace view APPS.xx_ar_cons_billsites_v as 
SELECT NVL(SU.location||': '||party.party_name, 'NONE') cons_billing_site_name
      ,SU.site_use_id  cons_billing_site_id
      ,C.account_number cons_billing_cust_num
from  hz_cust_site_uses SU
     ,hz_cust_acct_sites A
     ,hz_cust_accounts C
     ,hz_parties party
     ,hz_customer_profiles P
     ,hz_customer_profiles SP      
where C.party_id = party.party_id
and SU.site_use_code = 'BILL_TO'
and SP.site_use_id(+) = SU.site_use_id
and A.cust_acct_site_id = SU.cust_acct_site_id
and C.cust_account_id = A.cust_account_id
and P.cust_account_id = C.cust_account_id
and P.site_use_id is NULL
and nvl(SP.cons_inv_flag,P.cons_inv_flag) = 'Y'
union all
select 'ALL', 0, 'Dummy' from dual
/