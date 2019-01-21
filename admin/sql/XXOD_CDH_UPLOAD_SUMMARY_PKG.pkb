SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_SUMMARY_PKG.pkb                           |
 |Description                                                             |
 |              Package body for uploading into xxod_hz_sammary           |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  08-May-09   Sreedhar Mohan      Initial version                       |
 |  13-Mar-14   Shubhashree R       Increased the length of l_file_name   |
 |                                  as it was giving error in R12.        |
 |======================================================================= */

create or replace
package body XXOD_CDH_UPLOAD_SUMMARY_PKG
as
----------------------------
--Declaring Global Variables
----------------------------
g_header VARCHAR2(2000) := RPAD('SOURCE_SYSTEM_REF',40,' ');
g_line   VARCHAR2(2000) := RPAD('-',40,'-');

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
  l_file_name           varchar2(1000) := p_file_name;
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
 
begin

   WRITE_LOG('User_Id: ' || fnd_global.user_id);
   WRITE_LOG('resp_id: ' || fnd_global.resp_id);
   WRITE_LOG('resp_appl_id: ' || fnd_global.resp_appl_id);
   WRITE_LOG('p_file_name: ' || p_file_name);

   req_data := fnd_conc_global.request_data;

   WRITE_LOG('req_data: ' || req_data);
   WRITE_LOG('Calling set_request_set...');

   select request_set_name
   into l_request_set_name
   from fnd_request_sets_vl
   where user_request_set_name='OD: CDH Upload Summary';

   lb_success := fnd_submit.set_request_set('XXCNV', l_request_set_name);
   errbuf := substr(fnd_message.get,1, 240);

   if ( not lb_success ) then
     WRITE_LOG('set_request_set: UNsuccess!');
     raise srs_failed;
   end if;

   WRITE_LOG('Calling submit program first time...');

   if ( lb_success ) then

     ---------------------------------------------------------------------------------------------
     -- Submit the request set 'OD: CDH Upload Summary SQL loader ' which is in 1st stage
     ---------------------------------------------------------------------------------------------


     lb_success := fnd_submit.submit_program
                         (  application => 'XXCNV',
                            program     => 'XXOD_CDH_UPLOAD_HZ_SUMM_SQLL',
                            stage       => 'STAGE10',
                            argument1   => l_file_name
                         );
     errbuf := substr(fnd_message.get,1, 240);

     WRITE_LOG('submit_program XXOD_CDH_UPLOAD_HZ_SUMMARY_SQLL: success!');
     if ( not lb_success ) then
        raise submitprog_failed;
     end if;
     ----------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Upload Summary SQL loader'
     ----------------------------------------------------------------------------------

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

end XXOD_CDH_UPLOAD_SUMMARY_PKG;
/
