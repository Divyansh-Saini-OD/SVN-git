create or replace 
package body XXCDH_POPULATE_AB_FLAG_PKG
as
procedure MAIN (
                 p_errbuf            OUT NOCOPY varchar2,
                 p_retcode           OUT NOCOPY varchar2,
                 p_summary_batch_id             number
               )
as
  l_cust_account_id               number;
  n_tot                           number;
  
  cursor c1(p_sum_batch_id number)
  is
  select substr(acct_site_orig_sys_reference,1,17) osr
  from   xxod_hz_summary
  where  batch_id=p_sum_batch_id;

  cursor c2 (p_osr varchar2)
  is
  select cust_account_id
  from   hz_cust_accounts
  where  orig_system_reference=p_osr;

begin

  n_tot := 0;
  for i_summ in c1(p_summary_batch_id)
  LOOP
  
    open c2(i_summ.osr);
    fetch c2 into l_cust_account_id;
  
    update hz_customer_profiles
    set    attribute3 = 'Y'
    where  cust_account_id = l_cust_account_id
    and    site_use_id is null
    and    status = 'A';

    n_tot := n_tot + 1;

    close c2;

  COMMIT;

  END LOOP;

  fnd_file.put_line (fnd_file.log,'No. of rows updated: ' || n_tot);

exception
  when others then
  fnd_file.put_line(fnd_file.log, 'Exception: ' || SQLERRM);
  rollback;
end main;
end XXCDH_POPULATE_AB_FLAG_PKG;
/
SHOW ERRORS;
