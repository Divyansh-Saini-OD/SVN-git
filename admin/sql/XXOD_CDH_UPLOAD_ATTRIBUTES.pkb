create or replace package body XXOD_CDH_UPLOAD_ATTRIBUTES
/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_ATTRIBUTES.pkb                            |
 |Description                                                             |
 |              Package specification and body for submitting the         |
 |              request set programmatically                              |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  29-Dec-08   Sreedhar Mohan      Initial version                       |
 |  06-Apr-09   Indra Varada        1.1 - Status Upload added             |
 |  10-Jan-14   Darshini            I2180 - Changes for defect 26167.     |
 |  14-Jan-14   Avinash Baddam      1.2 - Changes for defect 26167        |
 |  12-Nov-15   Havish Kasina       1.3 - Removed the Schema References as|
 |                                  per R12.2 Retrofit Changes            |
 |======================================================================= */

as
----------------------------
--Declaring Global Variables
----------------------------
g_header VARCHAR2(2000) := RPAD('SOURCE_SYSTEM_REF',40,' ');
g_line   VARCHAR2(2000) := RPAD('-',40,'-');

 --specification for the local procedure
 PROCEDURE DO_COPY_CUST_PROFILES (
                                    p_errbuf   OUT NOCOPY VARCHAR2,
                                    p_retcode  OUT NOCOPY VARCHAR2,
                                    p_cust_account_profile_id  IN  VARCHAR2,
                                    p_cust_account_id IN NUMBER
                                  );
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

END write_out;

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

END write_log;



 procedure upload(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN   varchar2   
                  ) is 
   
  lb_success            boolean; 
  req_id                number; 
  req_data              varchar2(10); 
  errbuf                varchar2(2000) := p_errbuf;
  retcode               varchar2(1) := p_retcode;
-- Changes for defect 26167. Increased the variable length.
--  l_file_name           varchar2(100) := p_file_name;
  l_file_name           varchar2(4000) := p_file_name;
-- End of changes for defect 26167
  l_request_set_name    varchar2(30);
  srs_failed            exception; 
  submitprog_failed     exception; 
  submitset_failed      exception; 
  le_submit_failed      exception;
  request_desc          varchar2(240); /* Description for submit_request  */
  x_user_id             fnd_user.user_id%type; 
  x_resp_id             fnd_responsibility.responsibility_id%type; 
  x_resp_appl_id        fnd_responsibility.application_id%type;    
  b_complete            boolean := true;
  l_count               number;
  l_request_id          number;
  ln_batch_id           number;
  lv_return_status      varchar2(1);
  ln_msg_count          number;
  lv_msg_data           varchar2(2000);
  l_osr                 varchar2(240);
begin 

   WRITE_LOG('User_Id: ' || fnd_global.user_id);
   WRITE_LOG('resp_id: ' || fnd_global.resp_id);
   WRITE_LOG('resp_appl_id: ' || fnd_global.resp_appl_id);
   WRITE_LOG('p_file_name: ' || p_file_name);

   req_data := fnd_conc_global.request_data; 

   WRITE_LOG('req_data: ' || req_data);
   WRITE_LOG('Calling set_request_set...');

   --delete the records that are stuck with temp batch_id
   delete from XXOD_HZ_IMP_ACCOUNT_PROF_STG
   where  batch_id = 99999999999999;

   commit;
   
   select request_set_name
   into l_request_set_name 
   from fnd_request_sets_vl 
   where user_request_set_name='XXOD: CDH Load Collectors';
   
   lb_success := fnd_submit.set_request_set('XXCNV', l_request_set_name);  
   errbuf := substr(fnd_message.get,1, 240);

   if ( not lb_success ) then  
     WRITE_LOG('set_request_set: success!');
     raise srs_failed; 
   end if; 
            
   WRITE_LOG('Calling submit program first time...');  
   
   if ( lb_success ) then
     
     ---------------------------------------------------------------------------
     -- Submit program 'OD: CDH Upload Collectors' which is in 1st stage
     ---------------------------------------------------------------------------   
      
     
     lb_success := fnd_submit.submit_program
                         (  application => 'XXCNV',
                            program     => 'XXOD_CDH_UPLOAD_CUST_COLLECTOR',
                            stage       => 'XXOD_CDH_UPLOAD_CUST_COLLECTOR', 
                            argument1   => l_file_name                          
                         );
     errbuf := substr(fnd_message.get,1, 240);
     
     WRITE_LOG('submit_program XXOD_CDH_UPLOAD_CUST_COLLECTOR: success!');
     if ( not lb_success ) then  
        raise submitprog_failed;     
     end if;
     ----------------------------------------------------------    
     --End Submit program 'OD: CDH Upload Collectors'
     ----------------------------------------------------------          
     --------------------
     ---Generate batch_id
     --------------------
     
     HZ_IMP_BATCH_SUMMARY_V2PUB.create_import_batch 
        (  p_batch_name        => 'Custom Upload Collectors ' || sysdate, 
           p_description       => 'Batch for Collectors Load', 
           p_original_system   => 'A0', 
           p_load_type         => '', 
           p_est_no_of_records => 75000, 
           x_batch_id          => ln_batch_id, 
           x_return_status     => lv_return_status, 
           x_msg_count         => ln_msg_count, 
           x_msg_data          => lv_msg_data
        ); 
     IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF ln_msg_count > 0 THEN
           WRITE_LOG('Error while generating batch_id - ');
           FOR ln_counter IN 1..ln_msg_count
           LOOP
              WRITE_LOG('Error ->'||fnd_msg_pub.get(ln_counter, FND_API.G_FALSE));
           END LOOP;
           fnd_msg_pub.delete_msg;
        END IF;
     ELSE
        WRITE_LOG('Batch ID - '||ln_batch_id||' Successfully generated!!');
     END IF;
     -------------------------
     ----end genarate batch_id
     -------------------------

     -----------------------------------------------------------------------------
     -- Submit program 'OD: CDH Activate Bulk Batch Program' which is in 2nd stage
     -----------------------------------------------------------------------------
     
     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_ACTIVATE_BULK_BATCH',
                         stage       => 'XX_CDH_ACTIVATE_BULK_BATCH', 
                         argument1   => ln_batch_id                          
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ----------------------------------------------------------    
     --End Submit program 'OD: CDH Activate Bulk Batch Program'
     ----------------------------------------------------------    
     
     -----------------------------------------------------------------------------
     -- Submit program 'OD: CDH Upload Tool: Set correct batch id' which is in 3rd stage
     -----------------------------------------------------------------------------
     
     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_SET_CORRECT_BATCH',
                         stage       => 'XX_CDH_SET_CORRECT_BATCH', 
                         argument1   => ln_batch_id                          
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ----------------------------------------------------------    
     --End Submit program 'OD: CDH Upload Tool: Set correct batch id'
     ----------------------------------------------------------      

     -------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Customer Profile Conversion Program' which is in 4th stage 
     -------------------------------------------------------------------------------------
     
     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_CUST_PROFILE_CONV',
                         stage       => 'XX_CDH_CUST_PROFILE_CONV', 
                         argument1   => ln_batch_id ,
                         argument2   => 'Y'
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ------------------------------------------------------------------    
     --End Submit program 'OD: CDH Customer Profile Conversion Program' 
     ------------------------------------------------------------------  

     -------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Copy Customer Profiles for the Batch' which is in 5th stage 
     -------------------------------------------------------------------------------------
     
     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XXOD_COPY_CUST_PROF_BATCH',
                         stage       => 'XXOD_COPY_CUST_PROF_BATCH', 
                         argument1   => ln_batch_id 
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;

     ------------------------------------------------------------------    
     --End Submit program 'OD: CDH Copy Customer Profiles for the Batch' 
     ------------------------------------------------------------------ 
        
     -------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Upload Customer Profiles Status' which is in 6th stage 
     -------------------------------------------------------------------------------------
     
     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XXOD_UPLOAD_CUST_PROF_STATUS',
                         stage       => 'XXOD_UPLOAD_CUST_PROF_STATUS', 
                         argument1   => ln_batch_id 
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;

     ------------------------------------------------------------------    
     --End Submit program 'OD: CDH Upload Customer Profiles Status' 
     ------------------------------------------------------------------  

     WRITE_LOG('Calling submit_set...'); 
      
     req_id := fnd_submit.submit_set(null,FALSE); 

   end if; 
   --end of if lb_success of submit request set

   commit;
   
   WRITE_LOG('2 req_id:' || req_id);

   if (req_id = 0 ) then 
      raise submitset_failed; 
   end if; 
         
   WRITE_LOG('Finished.'); 
         
    
   fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => '1') ; 
     fnd_message.set_name('FND','CONC-Stage Submitted');
     fnd_message.set_token('STAGE', request_desc);
     errbuf := substr(fnd_message.get,1, 240);
     retcode := 0;         
   WRITE_LOG('errbuf: ' || errbuf); 
   p_errbuf := errbuf;

   retcode := 0; 
   p_retcode := retcode;

   p_request_set_id := req_id; 
 
exception 
   when srs_failed then 
      errbuf := 'Call to set_request_set failed: ' || fnd_message.get; 
      retcode := 2; 
      WRITE_LOG(errbuf); 
   when submitprog_failed then      
      errbuf := 'Call to submit_program failed: ' || fnd_message.get; 
      retcode := 2; 
      WRITE_LOG(errbuf); 
   when submitset_failed then      
      errbuf := 'Call to submit_set failed: ' || fnd_message.get; 
      retcode := 2; 
      WRITE_LOG(errbuf); 
   when others then 
      errbuf := 'Request set submission failed - unknown error: ' || sqlerrm; 
      retcode := 2; 
      WRITE_LOG(errbuf); 
  end upload;
  
  procedure print_upload_report(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    )
  is

  cursor c1
  is
  select acct_prof_stg.account_orig_system_reference,
       decode(acct_prof_stg.interface_status, 7, 'Success', 6, 'Error', 'Error') status,
       exc.staging_column_name,
       exc.staging_column_value,
       exc.exception_log 
from   XXOD_HZ_IMP_ACCOUNT_PROF_STG acct_prof_stg,
       XX_COM_EXCEPTIONS_LOG_CONV exc
where  acct_prof_stg.batch_id=exc.batch_id (+)
and    acct_prof_stg.record_id = exc.record_control_id (+)
and    acct_prof_stg.batch_id=p_batch_id;

  
  begin

    fnd_file.put_line (fnd_file.output, '<html><title>Uploaded Customer Profiles Verification Report</title><body><font size="-1" face="Verdana, Arial, Helvetica"><h2>Uploaded Customer Profiles Verification Report</h1>');
    fnd_file.put_line (fnd_file.output,'<table border=1><tr><td bgcolor=CCFF99><b>Account OSR</b></td><td bgcolor=CCFF99><b>Upload Status</b></td><td bgcolor=CCFF99><b>Input Column Name</b></td><td bgcolor=CCFF99><b>Input Value</b></td><td bgcolor=CCFF99><b>Error Message</b></td></tr>');
   
    for i in c1
    loop
      fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=FFFF99><font size=2>' || i.account_orig_system_reference  || 
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.status	       || 
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.staging_column_name	       || 
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.staging_column_value	       || 
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.exception_log		       || 
				 '</font></td></tr>');
                        
    end loop;
    fnd_file.put_line (fnd_file.output,'</table></font></body></html>');

  exception
    when others then
      rollback;
  end print_upload_report;
  
  function get_osr (p_account_number in varchar2)
  return varchar2
  as

    l_osr    varchar2 (240) := null;

  begin
    
    select orig_system_reference
    into   l_osr
    from   hz_cust_accounts
    where  account_number = p_account_number;

    return l_osr;

  exception
   when others then
     return null;
  end get_osr;

  procedure update_batch(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    )
  is
  begin
     update XXOD_HZ_IMP_ACCOUNT_PROF_STG
     set    batch_id = p_batch_id,
            org_id   = fnd_global.org_id,	    
            account_orig_system_reference =  get_osr(account_orig_system_reference),
            party_orig_system_reference =  get_osr(account_orig_system_reference)
     where  batch_id = 99999999999999;

     COMMIT;
  exception
    when others then
      WRITE_LOG('Error in update_batch: ' || SQLERRM);
      rollback;
  end update_batch;
      

-- +===================================================================+
-- | Name  : copy_customer_profiles                                    |
-- |                                                                   |
-- | Description:       This Procedure copies customer profiles        |
-- |                    created/updated by the upload tool             |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  procedure copy_customer_profiles(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    )
  is
  --
  cursor c1
  is
  select prof.cust_account_profile_id,
         prof.cust_account_id
  from XXOD_HZ_IMP_ACCOUNT_PROF_STG stg,
       hz_cust_accounts             acct,
       hz_customer_profiles         prof
  where  stg.batch_id=p_batch_id
  and    stg.account_orig_system_reference = acct.orig_system_reference
  and    acct.cust_account_id = prof.cust_account_id
  and    prof.site_use_id is null;
  --
  begin
    --
    for c1_rec in c1
    loop
      DO_COPY_CUST_PROFILES(
                            p_errbuf,
                            p_retcode,
                            c1_rec.cust_account_profile_id,
                            c1_rec.cust_account_id
                           );
    end loop;
    --
  exception
    when others then
      WRITE_LOG('Error in copy_customer_profiles: ' || SQLERRM);
      rollback;
      --
  end copy_customer_profiles;

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
    l_standard_terms           number          := null;

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
           ca.cust_account_id = p_cust_account_id;
           
    cursor c_is_site_use_exist (p_cust_account_id in number, 
                              p_site_use_id in number)
    is
    select 'Y',
           cust_account_profile_id
    from   hz_customer_profiles
    where  cust_account_id = p_cust_account_id and
           site_use_id = p_site_use_id;

  --
  BEGIN
    fnd_file.put_line(FND_FILE.LOG,'Cust_account_id: ' || p_cust_account_id);
    fnd_file.put_line(FND_FILE.OUTPUT,'Cust_account_id: ' || p_cust_account_id);

    l_count := 0;
    for c_rec in c_site_uses(p_cust_account_id)
    loop
       --
       l_count := l_count + 1;
       l_check := null;
       l_cust_account_profile_id := null;

       fnd_file.put_line(FND_FILE.LOG,'  site_use_id' || l_count ||': ' || c_rec.site_use_id);
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
             fnd_file.put_line(FND_FILE.OUTPUT,'    new rec, site_use_id: ' || c_rec.site_use_id);
             fnd_file.put_line(FND_FILE.LOG,'    new rec, site_use_id: ' || c_rec.site_use_id);

            --v1.1 defect 26167
            if prof_rec.standard_terms is not null then
               l_standard_terms := prof_rec.standard_terms;
            end if;
            
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
              fnd_file.put_line(FND_FILE.LOG,'      create_customer_profile, x_return_status: ' || l_return_status);
              fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
              -- 
              if l_msg_count > 0 THEN  
                begin
                  FOR I IN 1..l_msg_count
                  LOOP
                     l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                  END LOOP;
                end;        
              fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
              end if;
              --
              commit; 
      else
        --customer profile at site exist. Now go for updating the profile
        select object_version_number
        into   l_object_version_number
        from   hz_customer_profiles
        where  cust_account_profile_id = l_cust_account_profile_id;

              prof_rec.cust_account_profile_id := l_cust_account_profile_id;
              prof_rec.site_use_id := null;
              prof_rec.created_by_module := null;
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
              fnd_file.put_line(FND_FILE.LOG,'      update_customer_profile, x_return_status: ' || l_return_status);
              fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
              -- 
              
              ----v1.1 defect 26167
              if l_return_status = 'S' then
                 if l_standard_terms is not null then
                     prof_rec.standard_terms := l_standard_terms;
                     HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
		                   p_init_msg_list                      => 'T',
		                   p_customer_profile_rec               => prof_rec,
		                   p_object_version_number              => l_object_version_number,
		                   x_return_status                      => l_return_status,
		                   x_msg_count                          => l_msg_count,
		                   x_msg_data                           => l_msg_data
                     );
                     fnd_file.put_line(FND_FILE.LOG,'      update_customer_profile for standard terms, x_return_status: ' || l_return_status);
                     fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
                     if l_msg_count > 0 THEN  
		        begin
		            FOR I IN 1..l_msg_count
		            LOOP
		               l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
		            END LOOP;
		        end;        
		        fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
                     end if;
                 end if;
              else    
                if l_msg_count > 0 THEN  
                   begin
                      FOR I IN 1..l_msg_count
                      LOOP
                        l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                      END LOOP;
                   end;        
                   fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
                end if;
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

procedure uploadCustStatus(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN   varchar2  
                  ) 
IS 
   
l_conc_request_id                   number;

BEGIN 


   fnd_file.put_line(fnd_file.log,'Uploading Customer OR Site Status to HZ Summary Table  ........');  
   
    l_conc_request_id := 0;
    l_conc_request_id := FND_REQUEST.submit_request 
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_PROCESS_ACC_STATUS',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE, 
                                        argument1   => p_file_name
                                    );
    IF l_conc_request_id = 0 THEN
       fnd_file.put_line(fnd_file.log,' Failed to Submit the Concurrent Porgram - XX_CDH_PROCESS_ACC_STATUS');
       p_retcode := 2;
    ELSE
      fnd_file.put_line(fnd_file.log,' Request Successfully Submitted - ' || l_conc_request_id);
      p_request_set_id  := l_conc_request_id;
    END IF;

    COMMIT;
       
EXCEPTION WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Unexpected Error In Procedure - ' || SQLERRM);
      p_retcode := 2;
      ROLLBACK;
end uploadCustStatus;

procedure processCustStatus(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_file_name       IN   varchar2  
                  ) 
IS 
   
l_conc_request_id     NUMBER;
user_excp             EXCEPTION;
lv_phase              VARCHAR2(50);
lv_status             VARCHAR2(50);
lv_dev_phase          VARCHAR2(15);
lv_dev_status         VARCHAR2(15);
lb_wait               BOOLEAN;
lv_message            VARCHAR2(4000);
lv_error_exist        VARCHAR2(1);
lv_warning            VARCHAR2(1);
l_summ_id             NUMBER;
l_batch_id            NUMBER;
l_acct_orig_sys_ref   VARCHAR2(100);
l_site_orig_sys_ref   VARCHAR2(100);
l_entity_type         VARCHAR2(30);
l_summary_batch_id    NUMBER;
l_activation_flag     VARCHAR2(2);
l_db_link_name        VARCHAR2(100);
l_commit_flag         VARCHAR2(2);

BEGIN 


   fnd_file.put_line(fnd_file.log,'Uploading Customer and Site Status to HZ Summary Table  ........');  
   
   -- Submit Program to Upload (SQL Loader Script)

    l_conc_request_id := 0;
    l_conc_request_id := FND_REQUEST.submit_request 
                                    (   application => 'XXCNV',
                                        program     => 'XXOD_HZ_SUMMARY',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE, 
                                        argument1   => p_file_name
                                    );
    IF l_conc_request_id = 0 THEN
       fnd_file.put_line(fnd_file.log,' Failed to Submit the Concurrent Porgram - XXOD_HZ_SUMMARY');
       RAISE user_excp;
    
    ELSE
    
       lv_phase       := NULL;
       lv_status      := NULL;
       lv_dev_phase   := NULL;
       lv_dev_status  := NULL;
       lv_message     := NULL;
       lv_error_exist := NULL;
       lv_warning     := NULL;

       COMMIT;
      
       lb_wait := FND_CONCURRENT.wait_for_request 
                    (   request_id      => l_conc_request_id,
                        interval        => 1,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );

       IF lb_wait and lv_status = 'Normal' THEN
           
           select XXOD_HZ_SUMMARY_S.nextval INTO l_summ_id from dual;
           
           UPDATE XXOD_HZ_SUMMARY
           SET summary_id = l_summ_id
           WHERE summary_id = 99999999999999;
       ELSE
           fnd_file.put_line(fnd_file.log,'Error during Processing Of Concurrent Program - ' || lv_message);
           RAISE user_excp;
       END IF;
    END IF;

    SELECT batch_id,account_orig_system_reference,acct_site_orig_sys_reference
    INTO  l_batch_id,l_acct_orig_sys_ref,l_site_orig_sys_ref
    FROM  XXOD_HZ_SUMMARY
    WHERE summary_id = l_summ_id
    AND ROWNUM = 1;

    IF l_batch_id IS NOT NULL THEN
        
       fnd_file.put_line(fnd_file.log,'Batch ID values Successfully Loaded into XXOD_HZ_SUMMARY Table');
       fnd_file.put_line(fnd_file.log,'Summary ID - ' || l_summ_id);
       fnd_file.put_line(fnd_file.log, 'Use the Generated Summary ID to run the Program : OD: CDH Post Conversion Account Status Update');
    ELSE

        IF l_acct_orig_sys_ref IS NOT NULL THEN
          l_entity_type       := 'ACCOUNT';
        ELSE
          l_entity_type       := 'SITE';
        END IF;

          l_summary_batch_id  := l_summ_id;
          l_activation_flag   := 'A';
          l_db_link_name      := fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME'  );
          l_commit_flag       := 'Y';
          
          l_conc_request_id := 0;
          l_conc_request_id := FND_REQUEST.submit_request 
                                    (   application       => 'XXCNV',
                                        program           => 'XX_CDH_ACTIVATE_SITES_ACCOUNTS',
                                        description       => NULL,
                                        start_time        => NULL,
                                        sub_request       => FALSE, 
                                        argument1         => l_entity_type,
                                        argument2         => l_summary_batch_id,
                                        argument3         => l_activation_flag,
                                        argument4         => l_db_link_name,
                                        argument5         => l_commit_flag
                                    );

          IF l_conc_request_id = 0 THEN
                  
               fnd_file.put_line(fnd_file.log,' Failed to Submit the Concurrent Program - XX_CDH_ACTIVATE_SITES_ACCOUNTS');
               RAISE user_excp;
          ELSE
              
              fnd_file.put_line(fnd_file.log,'Successfully Submitted Concurrent Program - XX_CDH_ACTIVATE_SITES_ACCOUNTS');
    
          END IF;
      END IF;

      COMMIT; 

EXCEPTION 

WHEN user_excp THEN
      p_errbuf  := fnd_message.get;
      p_retcode := 2;
      ROLLBACK;

WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Unexpected Error In Procedure - ' || SQLERRM);
      p_retcode := 2;
      ROLLBACK;
end processCustStatus;


end XXOD_CDH_UPLOAD_ATTRIBUTES;
/
