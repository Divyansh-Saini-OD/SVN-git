SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY XX_CDH_WC_COPY_SITE_PROFS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                  Web Collect Integrations                                               |
-- +=========================================================================================+
-- | Name        : XX_CDH_WC_COPY_SITE_PROFS.pkb                                           |
-- | Description : This package is developed to copy customer profiles  from customer level  |
-- |               site level for the customers that were become eligible in WC Deltas.      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        14-Apr-2012     Sreedhar Mohan       Draft                                    |
-- +=========================================================================================+
AS

   PROCEDURE write_log (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      END IF;
   END write_log;

   PROCEDURE write_out (
      p_debug_flag   IN   VARCHAR2
     ,p_msg          IN   VARCHAR2
   )
   IS
   BEGIN
      IF p_debug_flag = 'Y'
      THEN
         fnd_file.put_line (fnd_file.OUTPUT, p_msg);
      END IF;
   END write_out;
   
   FUNCTION Is_SiteUse_Exist( p_cust_account_id number 
                            ,p_site_use_id in  number 
                           )
   RETURN varchar2
   is
   l_exist  varchar2(1) := 'N';
   BEGIN
    select 'Y'
    INTO   l_exist           
    from   hz_customer_profiles
    where  cust_account_id = p_cust_account_id 
    and    site_use_id = p_site_use_id
    and    status='A';  

    RETURN l_exist;

   EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG, 'No ' || p_cust_account_id || ':' || p_site_use_id);
      RETURN 'N';
   END Is_SiteUse_Exist;
   
PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug_flag      IN       VARCHAR2
   ) is

    prof_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
    l_check         varchar2(1);
    l_acct_count    number;
    l_siteuse_count number;

    l_return_status            varchar2(1)     := null;
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_cust_account_profile_id  number          := 0;
    l_object_version_number    number;
    ln_num_days_old            number := 1;
    
    --pick up all the profiles related to accounts
    CURSOR c1 (p_num_days number)
    is
    select prof.cust_account_profile_id,
           prof.cust_account_id,
           prof.site_use_id
    from hz_customer_profiles prof,
         hz_cust_accounts acc,
         xx_crm_wcelg_cust EC
    where EC.cust_account_id = acc.cust_account_id
      and prof.cust_account_id = acc.cust_account_id
      and prof.site_use_id is null;

    --pick all the 'BILL_TO' site uses for the given cust_account_id
    CURSOR c_site_uses (p_cust_account_id number)
    is
    select csu.site_use_id 
    from   hz_cust_accounts   ca,
           hz_cust_acct_sites cas,
           hz_cust_site_uses  csu
   where   ca.cust_account_id=cas.cust_account_id and
           cas.cust_acct_site_id=csu.cust_acct_site_id and
           csu.site_use_code='BILL_TO' and      
           ca.cust_account_id = p_cust_account_id;

BEGIN 
  
  l_acct_count := 0;
  l_siteuse_count := 0;  
  for c1_rec in c1 (ln_num_days_old)
   loop

    l_acct_count := l_acct_count + 1;
    for c_rec in c_site_uses(c1_rec.cust_account_id)
    loop
       --
	   l_siteuse_count := l_siteuse_count +1;
       l_check := null;
       l_cust_account_profile_id := null;

       --check if profile exist at site level
       l_check := Is_SiteUse_Exist (c1_rec.cust_account_id, c_rec.site_use_id);
     
       if (l_check = 'N') then
         --site_use_id do not exist create profile at site level
         write_out (p_debug_flag,  c1_rec.cust_account_id || ':' || c_rec.site_use_id);

         --
         prof_rec  := NULL;
         HZ_CUSTOMER_PROFILE_V2PUB.get_customer_profile_rec (
            p_init_msg_list                         => 'T',
            p_cust_account_profile_id               => c1_rec.cust_account_profile_id,
            x_customer_profile_rec                  => prof_rec,
            x_return_status                         => l_return_status,
            x_msg_count                             => l_msg_count,
            x_msg_data                              => l_msg_data
         );
       
          if( l_return_status = 'S') then

              -- we are sending p_create_profile_amt as null, as we indend to copy
              -- customer profile from account level to site level only.
              --
              prof_rec.cust_account_profile_id := null;
              prof_rec.site_use_id := c_rec.site_use_id;
              l_return_status  := null;
              l_msg_count      := 0;
              l_msg_data       := null; 
              --
              HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile (
               p_init_msg_list                      => 'T',
               p_customer_profile_rec               => prof_rec,
               x_cust_account_profile_id            => l_cust_account_profile_id,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );
              --
              -- 
              if l_msg_count > 0 THEN  
                begin
                  FOR I IN 1..l_msg_count
                  LOOP
                     l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                  END LOOP;
                end;        
              write_log (p_debug_flag,  c1_rec.cust_account_id || ':' || c_rec.site_use_id || ':' || l_msg_data);
              end if;
              --
              commit; 
          else
            write_log (p_debug_flag,  'Error in getting Customer Profile for cust_acount_id: ' || c1_rec.cust_account_id);
          end if; --'end if' for 'if( l_return_status = 'S''
       end if;--'end if' for if (Is_SiteUse_Exist)    

    end loop; --c_rec loop
   end loop; --c1_rec loop
   fnd_file.put_line(FND_FILE.OUTPUT,'No. of accounts checked in this run: ' ||l_acct_count);
   fnd_file.put_line(FND_FILE.OUTPUT,'No. of SiteUses checked in this run: ' ||l_siteuse_count);

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.LOG, 'Exception in Main: ' || SQLERRM);
  END Main;      
END XX_CDH_WC_COPY_SITE_PROFS;
/
SHOW ERR;
