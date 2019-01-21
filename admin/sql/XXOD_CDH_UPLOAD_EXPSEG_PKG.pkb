/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_EXPSEG_PKG.pkb                            |
 |Description                                                             |
 |              Package specification and body for submitting the         |
 |              request set programmatically                              |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  16-Feb-09   Anirban Chaudhuri   Initial version                       |
 |  12-Nov-15   Havish Kasina       Removed the Schema References as per  |
 |                                  R12.2 Retrofit Changes                |
 |======================================================================= */

CREATE OR REPLACE package body XXOD_CDH_UPLOAD_EXPSEG_PKG
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

-- +===================================================================+
-- | Name  : update_expseg_batch_id                                    |
-- |                                                                   |
-- | Description:       This Procedure is for 2nd CP in the stage.     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_expseg_batch_id(
                                  p_errbuf           OUT NOCOPY VARCHAR2
                                 ,p_retcode          OUT NOCOPY varchar2
				 ,p_batch_id         IN NUMBER
                                 ) IS

    l_chr_err_message   VARCHAR2(2000);
    p_id number;

    cursor c1
    is
	  select a.PARTY_ORIG_SYSTEM_REFERENCE
	  from HZ_IMP_CLASSIFICS_INT a
          where  a.batch_id=p_batch_id;


  BEGIN

      WRITE_LOG('Anirban calling update_expseg_batch_id...');

      update HZ_IMP_CLASSIFICS_INT
      set    batch_id = p_batch_id,
            INSERT_UPDATE_FLAG = null
      where  batch_id = 99999999999999;
      commit;

      for i in c1
      loop

          SELECT party_id into p_id from HZ_PARTIES where orig_system_reference = i.PARTY_ORIG_SYSTEM_REFERENCE;
          WRITE_LOG('Anirban evaluating values of party IDs...'||p_id||'...END OF LINE');

	  update HZ_IMP_CLASSIFICS_INT
          set    party_id = (SELECT party_id from HZ_PARTIES where orig_system_reference = i.PARTY_ORIG_SYSTEM_REFERENCE and rownum=1)
          where  batch_id = p_batch_id
	  and    PARTY_ORIG_SYSTEM_REFERENCE = i.PARTY_ORIG_SYSTEM_REFERENCE;

      end loop;

      commit;

  EXCEPTION
     WHEN OTHERS THEN
       l_chr_err_message := SUBSTR(SQLERRM,1,1000);
       p_retcode := 2;
       p_errbuf  := l_chr_err_message;
END update_expseg_batch_id ;




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
  l_file_name           varchar2(100) := p_file_name;
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
  lv_anirban_data       varchar2(200);

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
   where user_request_set_name='OD: CDH Upload Exposure Segments';

   lb_success := fnd_submit.set_request_set('XXCNV', l_request_set_name);
   errbuf := substr(fnd_message.get,1, 240);

   if ( not lb_success ) then
     WRITE_LOG('set_request_set: success!');
     raise srs_failed;
   end if;

   WRITE_LOG('Calling submit program first time...');

   if ( lb_success ) then

     ----------------------------------------------------------------------------------
     ---Generate batch_id
     ----------------------------------------------------------------------------------

     HZ_IMP_BATCH_SUMMARY_V2PUB.create_import_batch
        (  p_batch_name        => 'Custom Upload for Exposure Segments ' || sysdate,
           p_description       => 'Batch for Exposure Segments',
           p_original_system   => 'GDW',
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
     ----------------------------------------------------------------------------------
     ----end genarate batch_id
     ----------------------------------------------------------------------------------

     ---------------------------------------------------------------------------------------------
     -- Submit the request set 'OD: CDH Upload Exposure Segments SQL loader' which is in 1st stage
     ---------------------------------------------------------------------------------------------


     lb_success := fnd_submit.submit_program
                         (  application => 'XXCNV',
                            program     => 'XXOD_CDH_UPLOAD_EXP_SEGMENTS_T',
                            stage       => 'STAGE10',
                            argument1   => l_file_name
                         );
     errbuf := substr(fnd_message.get,1, 240);

     WRITE_LOG('submit_program XXOD_CDH_UPLOAD_EXP_SEGMENTS: success!');
     if ( not lb_success ) then
        raise submitprog_failed;
     end if;
     ----------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Upload Exposure Segments SQL loader'
     ----------------------------------------------------------------------------------

     -----------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Update Exposure Segments Batch Id' which is in 2nd stage
     -----------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_UPDATE_EXPSEG_BATCH_ID',
                         stage       => 'STAGE20',
                         argument1   => ln_batch_id
                      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ---------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Update Exposure Segments Batch Id'
     ---------------------------------------------------------------------------------


     ----------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Activate Bulk Batch Program' which is in 3rd stage
     ----------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_ACTIVATE_BULK_BATCH',
                         stage       => 'STAGE30',
                         argument1   => ln_batch_id
                      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ---------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Activate Bulk Batch Program'
     ---------------------------------------------------------------------------------


     ----------------------------------------------------------------------------------
     -- Submit program 'Import Batch to TCA Registry' which is in 4th stage
     ----------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'Receivables',
                         program     => 'ARHIMAIN',
                         stage       => 'STAGE40',
                         argument1   => ln_batch_id ,
                         argument2   => 'COMPLETE',
                         argument3   => 'N',
                         argument4   => NULL,
			 argument5   => NULL,
			 argument6   => NULL,
			 argument7   => NULL,
			 argument8   => NULL,
			 argument9   => NULL
                      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ----------------------------------------------------------------------------------
     --End Submit program 'Import Batch to TCA Registry'
     ----------------------------------------------------------------------------------

     ----------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Upload Exposure Segments Status' which is in 5th stage
     ----------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XXOD_UPLOAD_EXPSEG_STATUS',
                         stage       => 'STAGE50',
                         argument1   => ln_batch_id
                      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ----------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Upload Exposure Segments Status'
     ----------------------------------------------------------------------------------
     
     --- Code to Run Exposure Segment Generation Program Begins  -- IVARADA -- 
     
     ----------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Class Code Correction' which is in 6th stage
     ----------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_CLASS_CODE_CORRECTION',
                         stage       => 'Stage60',
                         argument1   => TO_CHAR(SYSDATE-1,'YYYY/MM/DD HH24:MI:SS'),
                         argument2   => TO_CHAR(SYSDATE+1,'YYYY/MM/DD HH24:MI:SS')
                      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ----------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Class Code Correction'
     ----------------------------------------------------------------------------------
     
     -----------------------------------------------------------------------------------------------
     -- Submit program 'OD: CDH Conversion Generate Exposure Segment Analysis' which is in 7th stage
     ------------------------------------------------------------------------------------------------

     lb_success := fnd_submit.submit_program
                      (  application => 'XXCNV',
                         program     => 'XX_CDH_GEN_EXP_SEGMENT_PROG',
                         stage       => 'STAGE70',
                         argument1   => TO_CHAR(SYSDATE-1,'YYYY/MM/DD HH24:MI:SS'),
                         argument2   => TO_CHAR(SYSDATE+1,'YYYY/MM/DD HH24:MI:SS'),
                         argument3   => 'N'
		      );
     IF ( NOT lb_success ) THEN
        RAISE submitprog_failed;
     END IF;
     ----------------------------------------------------------------------------------
     --End Submit program 'OD: CDH Conversion Generate Exposure Segment Analysis'
     ----------------------------------------------------------------------------------
     
      --- Code to Run Exposure Segment Generation Program Ends  -- IVARADA -- 
     
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
  select distinct acct_prof_stg.PARTY_ORIG_SYSTEM_REFERENCE,
       decode(acct_prof_stg.interface_status, 'E', 'Error', 'Success') status,
       decode(acct_prof_stg.interface_status, 'E', exc.MESSAGE_NAME, '') message_name,
       exc.TOKEN1_NAME,
       exc.TOKEN1_VALUE,
       exc.TOKEN2_NAME,
       exc.TOKEN2_VALUE
from   HZ_IMP_CLASSIFICS_INT acct_prof_stg,
       HZ_IMP_ERRORS exc
where  acct_prof_stg.batch_id=exc.batch_id (+)
and    acct_prof_stg.batch_id=p_batch_id;


  begin

    fnd_file.put_line (fnd_file.output, '<html><title>Uploaded Exposure Segments Verification Report</title><body><font size="-1" face="Verdana, Arial, Helvetica"><h2>Uploaded Exposure Segments Verification Report</h1>');
    fnd_file.put_line (fnd_file.output,'<table border=1><tr><td bgcolor=CCFF99><b>Party OSR</b></td><td bgcolor=CCFF99><b>Upload Status</b></td><td bgcolor=CCFF99><b>Error Message Name</b></td><td bgcolor=CCFF99><b>Token 1 Name</b></td><td bgcolor=CCFF99><b>Token 1 Value</b></td><td bgcolor=CCFF99><b>Token 2 Name</b></td><td bgcolor=CCFF99><b>Token 2 Value</b></td></tr>');

    for i in c1
    loop
      fnd_file.put_line (fnd_file.output,'<tr><td bgcolor=FFFF99><font size=2>' || i.PARTY_ORIG_SYSTEM_REFERENCE                                  ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.status
				       ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.MESSAGE_NAME
				       ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.TOKEN1_NAME
				       ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.TOKEN1_VALUE
				       ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.TOKEN2_NAME
				       ||
                                 '</font></td><td bgcolor=FFFF99><font size=2>' || i.TOKEN2_VALUE
				       ||
				 '</font></td></tr>');

    end loop;
    fnd_file.put_line (fnd_file.output,'</table></font></body></html>');

  exception
    when others then
      rollback;
end print_upload_report;

end XXOD_CDH_UPLOAD_EXPSEG_PKG;
/
