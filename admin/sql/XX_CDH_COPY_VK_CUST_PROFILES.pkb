SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_CDH_COPY_VK_CUST_PROFILES
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_COPY_VK_CUST_PROFILES                                  |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies the Customer Profile values from account level      |
-- |               to site level if the dunning_letters='Y' for 'Bill_TO' use |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      05-Nov-2007 Sreedhar Mohan         Initial Version               |
-- |1.1      12-Apr-2012 Dheeraj V              Updated cursors to include    |
-- |                                            AB flag and account/site/use  |
-- |                                            status                        |
-- |                                                                          |
-- +==========================================================================+
AS
  --specification for the local procedure
  PROCEDURE DO_COPY_CUST_PROFILES (
                                    p_errbuf   OUT NOCOPY VARCHAR2,
                                    p_retcode  OUT NOCOPY VARCHAR2,
                                    p_cust_account_profile_id  IN  VARCHAR2,
                                    p_cust_account_id IN NUMBER
                                  );
  PROCEDURE MAIN(
                  p_errbuf   OUT NOCOPY VARCHAR2,
                  p_retcode  OUT NOCOPY VARCHAR2,
                  p_batch_id IN  NUMBER
                )
  AS
  --
    --pick up all the profiles related to accounts
    CURSOR c1 
    is
    select prof.cust_account_profile_id,
           prof.cust_account_id,
           prof.site_use_id
    from hz_customer_profiles prof,
         hz_cust_accounts acc,
         XXOD_HZ_IMP_ACCOUNTS_STG int1
    where int1.batch_id = p_batch_id
      and acc.orig_system_reference=int1.account_orig_system_reference
      and prof.cust_account_id = acc.cust_account_id
      and prof.site_use_id is null
      and acc.status = 'A'
      and prof.attribute3='Y';

/*   commented below  for V1.1
    CURSOR c1 
    is
    select cust_account_profile_id,
           cust_account_id,
           site_use_id
    from hz_customer_profiles 
    where site_use_id is null;
*/    
  --
  BEGIN
    for c1_rec in c1
    loop
      DO_COPY_CUST_PROFILES(
                            p_errbuf,
                            p_retcode,
                            c1_rec.cust_account_profile_id,
                            c1_rec.cust_account_id
                           );
    end loop;
    
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
  END MAIN;


  PROCEDURE DO_COPY_CUST_PROFILES (
                                    p_errbuf   OUT NOCOPY VARCHAR2,
                                    p_retcode  OUT NOCOPY VARCHAR2,
                                    p_cust_account_profile_id  IN  VARCHAR2,
                                    p_cust_account_id IN NUMBER
                                  )
  AS
  --
    prof_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
    l_check         varchar2(1);
    l_count         number;

    l_return_status            varchar2(1)     := null;
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_cust_account_profile_id  number          := 0;
    l_object_version_number    number;

    --pick all the 'BILL_TO' site uses for the given cust_account_id
    CURSOR c_site_uses (p_cust_account_id number)
    is
    select csu.site_use_id 
    from   hz_cust_accounts_all   ca,
           hz_cust_acct_sites_all cas,
           hz_cust_site_uses_all  csu
   where   ca.cust_account_id=cas.cust_account_id and
           cas.cust_acct_site_id=csu.cust_acct_site_id and
           csu.site_use_code='BILL_TO' and      
           ca.cust_account_id = p_cust_account_id
   --added below for v1.1
           and csu.status='A';
           
    cursor c_is_site_use_exist (p_cust_account_id in number, 
                              p_site_use_id in number)
    is
    select 'Y',
           cust_account_profile_id
    from   hz_customer_profiles
    where  cust_account_id = p_cust_account_id and
           site_use_id = p_site_use_id
   --added below for v1.1
           and status='A';

  --
  BEGIN
    --fnd_file.put_line(FND_FILE.LOG,'Cust_account_id: ' || p_cust_account_id);
    --fnd_file.put_line(FND_FILE.OUTPUT,'Cust_account_id: ' || p_cust_account_id);

    l_count := 0;
    for c_rec in c_site_uses(p_cust_account_id)
    loop
       --
       l_count := l_count + 1;
       l_check := null;
       l_cust_account_profile_id := null;

       --fnd_file.put_line(FND_FILE.LOG,'  site_use_id' || l_count ||': ' || c_rec.site_use_id);
       prof_rec  := NULL;
       HZ_CUSTOMER_PROFILE_V2PUB.get_customer_profile_rec (
            p_init_msg_list                         => 'T',
            p_cust_account_profile_id               => p_cust_account_profile_id,
            x_customer_profile_rec                  => prof_rec,
            x_return_status                         => l_return_status,
            x_msg_count                             => l_msg_count,
            x_msg_data                              => l_msg_data
          );
       
          if( l_return_status = 'S') then
             --fnd_file.put_line(FND_FILE.OUTPUT,'    new rec, site_use_id: ' || c_rec.site_use_id);
             --fnd_file.put_line(FND_FILE.LOG,'    new rec, site_use_id: ' || c_rec.site_use_id);

             --check if profile exist at site level
            open c_is_site_use_exist(p_cust_account_id, c_rec.site_use_id);
            fetch c_is_site_use_exist into l_check, l_cust_account_profile_id;
     
            if (c_is_site_use_exist%ROWCOUNT <1) then
              --site_use_id do not exist create profile at site level
              --
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
              --fnd_file.put_line(FND_FILE.LOG,'      create_customer_profile, x_return_status: ' || l_return_status);
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
            end if; 
          end if;    
          close c_is_site_use_exist;
    end loop;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
  END DO_COPY_CUST_PROFILES;

END XX_CDH_COPY_VK_CUST_PROFILES;
/

SHOW ERRORS;
