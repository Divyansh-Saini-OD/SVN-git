-- +=========================================================================================+
-- | Name        : XXOD_CDH_UPLOAD_REMITTO_PKG                                               |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.1        04-Oct-2013     Pratesh              Updated Size of varible l_file_name in   |
-- |                                                in procedure "upload"                    |
-- |1.2        12-Nov-2015     Havish Kasina        Removed the Schema Referneces as per     |
-- |                                                R12.2 Retrofit Changes                   |
-- +=========================================================================================+

CREATE OR REPLACE package body XXOD_CDH_UPLOAD_REMITTO_PKG
as
----------------------------
--Declaring Global Variables
----------------------------
g_header VARCHAR2(2000) := RPAD('SOURCE_SYSTEM_REF',40,' ');
g_line   VARCHAR2(2000) := RPAD('-',40,'-');


  function get_account_number (p_osr in varchar2)
  return varchar2
  as

    l_account_number    varchar2 (240) := null;

  begin

    select account_number
    into   l_account_number
    from   hz_cust_accounts
    where  orig_system_reference = p_osr;

    return l_account_number;

  exception
   when others then
     return null;
  end get_account_number;


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
  l_file_name           varchar2(240) := p_file_name;
  l_request_set_name    varchar2(100);
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
  l_user_id             number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  l_apps_org_id         number;
  l_responsibility_key  varchar2(120);
  l_app_dev_view_resp_id number;
  l_prof_val             VARCHAR2(30);
  l_prof_upd_status      BOOLEAN;

begin

   WRITE_LOG('User_Id: ' || fnd_global.user_id);
   WRITE_LOG('resp_id: ' || fnd_global.resp_id);
   WRITE_LOG('resp_appl_id: ' || fnd_global.resp_appl_id);
   WRITE_LOG('p_file_name: ' || p_file_name);
   l_responsibility_id := fnd_global.resp_id;

   --Set the profile option for the user rsep. to updte site use
   l_prof_val := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USE_UPDT_ACCESS'),'R');

   l_prof_upd_status := FND_PROFILE.SAVE(
                                          X_NAME                => 'XX_CDH_SEC_ACCT_SITE_USE_UPDT_ACCESS',
                                          X_VALUE               => 'U',
                                          X_LEVEL_NAME          => 'RESP',
                                          X_LEVEL_VALUE         => l_responsibility_id,
                                          X_LEVEL_VALUE_APP_ID  => fnd_global.resp_appl_id,
                                          X_LEVEL_VALUE2        => null);

   req_data := fnd_conc_global.request_data;

   WRITE_LOG('req_data: ' || req_data);
   WRITE_LOG('Calling set_request_set...');

   --delete the records that are stuck with temp batch_id
   delete from XXOD_HZ_TMP_REMITTO_SCHANNEL
   where  batch_id = 99999999999999;

   --delete the records that are stuck with temp batch_id
   delete from XXOD_HZ_IMP_ACCT_SITE_USES_STG
   where  batch_id = 99999999999999;

   commit;

   select request_set_name
   into l_request_set_name
   from fnd_request_sets_vl
   where user_request_set_name='XXOD: CDH Load Remitto';

   lb_success := fnd_submit.set_request_set('XXCNV', l_request_set_name);
   errbuf := substr(fnd_message.get,1, 240);

   if ( not lb_success ) then
     WRITE_LOG('set_request_set: success!');
     raise srs_failed;
   end if;

   WRITE_LOG('Calling submit program first time...');

   if ( lb_success ) then

     ---------------------------------------------------------------------------
     -- Submit program 'OD: CDH Upload RemitTo' which is in 1st stage
     ---------------------------------------------------------------------------


     lb_success := fnd_submit.submit_program
                         (  application => 'XXCNV',
                            program     => 'XXOD_CDH_UPLOAD_REMITTO',
                            stage       => 'XXOD_CDH_UPLOAD_REMITTO',
                            argument1   => l_file_name
                         );
     errbuf := substr(fnd_message.get,1, 240);

     WRITE_LOG('submit_program XXOD_CDH_UPLOAD_REMITTO: success!');
     if ( not lb_success ) then
        raise submitprog_failed;
     end if;
     ----------------------------------------------------------
     --End Submit program 'OD: CDH Upload RemitTo'
     ----------------------------------------------------------
     --------------------
     ---Generate batch_id
     --------------------

     HZ_IMP_BATCH_SUMMARY_V2PUB.create_import_batch
        (  p_batch_name        => 'Custom Upload RemitTos ' || sysdate,
           p_description       => 'Batch for RemitTos Load',
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
     -- Submit program 'OD: CDH Activate Bulk Batch Program' which is in 2nd stage
     -----------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_UPDATE_REMITTO_BATCH',
                         stage       => 'XX_CDH_UPDATE_REMITTO_BATCH',
                         argument1   => ln_batch_id
                      );
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ----------------------------------------------------------
     --End Submit program 'OD: CDH Activate Bulk Batch Program'
     ----------------------------------------------------------

     -------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Customer Account Site Uses Conversion Program' which is in 4th stage
     -------------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_CUST_ACCT_SITE_USE_CONV',
                         stage       => 'XX_CDH_CUST_ACCT_SITE_USE_CONV',
                         argument1   => ln_batch_id ,
                         argument2   => 'Y'
                      );
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ----------------------------------------------------------------------------
     --End Submit program 'OD: CDH Customer Account Site Uses Conversion Program'
     ----------------------------------------------------------------------------

     -------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Print Upload RemitTo Status' which is in 6th stage
     -------------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XXOD_UPLOAD_REMITTO_STATUS',
                         stage       => 'XXOD_UPLOAD_REMITTO_STATUS',
                         argument1   => ln_batch_id
                      );
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;

     ------------------------------------------------------------------
     --End Submit program 'OD: CDH Print Upload RemitTo Status'
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

   --Change to "OD Application Developer(View)" so that the user can see the requests

   --Set the profile option back for the user rsep. to previous value
   l_prof_upd_status := FND_PROFILE.SAVE('XX_CDH_SEC_ACCT_SITE_USE_UPDT_ACCESS',l_prof_val,'RESP',l_responsibility_id);

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
  select acct_suse_stg.acct_site_orig_sys_reference,
       decode(acct_suse_stg.interface_status, 7, 'Success', 6, 'Error', 'Error') status,
       exc.staging_column_name,
       exc.staging_column_value,
       decode(acct_suse_stg.interface_status, 7, null, 6, exc.exception_log, exc.exception_log) exception_log
from   XXOD_HZ_IMP_ACCT_SITE_USES_STG acct_suse_stg,
       XX_COM_EXCEPTIONS_LOG_CONV exc
where  acct_suse_stg.batch_id=exc.batch_id (+)
and    acct_suse_stg.record_id = exc.record_control_id (+)
and    acct_suse_stg.batch_id=p_batch_id;


  begin

    fnd_file.put_line (fnd_file.output, '<html><title>Uploaded RemitTo Sales Channel Verification Report</title><body><font size="-1" face="Verdana, Arial, Helvetica"><h2>Uploaded RemitTo Sales Channel Verification Report</h1>');
    fnd_file.put_line (fnd_file.output,'<table border=1><tr><td bgcolor=CCFF99><b>Account Site OSR</b></td><td bgcolor=CCFF99><b>Upload Status</b></td><td bgcolor=CCFF99><b>Input Column Name</b></td><td bgcolor=CCFF99><b>Input Value</b></td><td bgcolor=CCFF99><b>Error Message</b></td></tr>');

    for i in c1
    loop
      fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=FFFF99><font size=2>' || i.acct_site_orig_sys_reference  ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.status                                                ||
                                  '</font></td><td bgcolor=FFFF99><font size=2>' || i.exception_log                                        ||
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

  l_count number;
  CURSOR c1
  IS
      SELECT hsu.site_use_code,
           hsu.site_use_id,
           hsu.orig_system_reference SITEUSE_ORIG_SYS_REFERENCE,
         has.orig_system_reference ACCT_SITE_ORIG_SYS_REFERENCE,
         hca.orig_system_reference ACCT_ORIG_SYS_REFERENCE,
           hsu.primary_flag,
           hsu.ATTRIBUTE25,
           hsu.org_id,
           hsu.location,
         trs.remitto_sales_channel
    FROM   hz_cust_acct_sites_all has
          ,hz_cust_site_uses_all  hsu
            ,XXOD_HZ_TMP_REMITTO_SCHANNEL trs
        ,hz_cust_accounts hca
    WHERE trs.account_number = has.orig_system_reference
    AND   has.cust_acct_site_id = hsu.cust_acct_site_id
  AND   has.cust_account_id = hca.cust_account_id
    AND   has.status='A'
    AND   hsu.status='A'
    AND   hsu.site_use_code='BILL_TO'
  and   trs.batch_id=99999999999999;

  BEGIN

   FOR j IN c1
        LOOP

                INSERT INTO XXOD_HZ_IMP_ACCT_SITE_USES_STG (BATCH_ID, RECORD_ID, CREATED_BY, CREATED_BY_MODULE,
                    CREATION_DATE, INSERT_UPDATE_FLAG, LAST_UPDATE_DATE, LAST_UPDATE_LOGIN,
                    LAST_UPDATED_BY, PARTY_ORIG_SYSTEM, PARTY_ORIG_SYSTEM_REFERENCE, ACCOUNT_ORIG_SYSTEM,
                    ACCOUNT_ORIG_SYSTEM_REFERENCE, ACCT_SITE_ORIG_SYSTEM,
                    ACCT_SITE_ORIG_SYS_REFERENCE, PRIMARY_FLAG, SITE_USE_ATTRIBUTE_CATEGORY, SITE_USE_ATTRIBUTE25,
                    ORG_ID, LOCATION, BILL_TO_ORIG_SYSTEM, BILL_TO_ACCT_SITE_REF, INTERFACE_STATUS, SITE_USE_CODE )
                   VALUES (p_batch_id, XXOD_HZ_IMP_ACCT_SITE_USES_S.NEXTVAL, NULL, 'XXCONV',
                       NULL,  1, NULL, NULL,
                       NULL, 'A0', j.ACCT_ORIG_SYS_REFERENCE, 'A0',
                       j.ACCT_ORIG_SYS_REFERENCE, 'A0',
                       j.ACCT_SITE_ORIG_SYS_REFERENCE, j.primary_flag, j.site_use_code,  nvl(j.REMITTO_SALES_CHANNEL, FND_PROFILE.VALUE('HZ_IMP_G_MISS_CHAR')),
                       j.org_id, j.location, 'A0', j.SITEUSE_ORIG_SYS_REFERENCE, 1, j.SITE_USE_CODE
                   );

       COMMIT;

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      WRITE_LOG('Error in update_batch: ' || SQLERRM);
      ROLLBACK;
  END update_batch;

end XXOD_CDH_UPLOAD_REMITTO_PKG;
/
