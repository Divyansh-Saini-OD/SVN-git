SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CONV_LOAD_INT_STG4_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CONV_LOAD_INT_STG4_PKG.pkb                  |
-- | Description :  New CDH Customer Conversion Seamless Package Spec  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  10-Aug-2011 Sreedhar Mohan     Initial draft version     |
-- +===================================================================+
AS
gt_request_id                 fnd_concurrent_requests.request_id%TYPE
                              := fnd_global.conc_request_id();
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
-- | Name        :                                                     |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE load_main
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_batch_id            IN  NUMBER
      )
IS
lv_request_data                VARCHAR2(100);
lv_error_message               VARCHAR2(4000);
ln_return_status               NUMBER;
le_error                       EXCEPTION;
le_error                       EXCEPTION;

lv_phase              VARCHAR2(50);
lv_status             VARCHAR2(50);
lv_dev_phase          VARCHAR2(15);
lv_dev_status         VARCHAR2(15);
lb_wait               BOOLEAN;
lv_message            VARCHAR2(4000);
lv_error_exist        VARCHAR2(1);
lv_warning            VARCHAR2(1);
lt_conc_request_id    fnd_concurrent_requests.request_id%TYPE;

  request_desc          varchar2(240); /* Description for submit_request  */
  lb_success            boolean;
  req_id                number;
  req_data              varchar2(10);
  errbuf                varchar2(2000) := x_errbuf;
  retcode               varchar2(1) := x_retcode;
  l_request_set_name    varchar2(30);
  srs_failed            exception;
  submitprog_failed     exception;
  submitset_failed      exception;
  le_submit_failed      exception;
BEGIN

   x_retcode := 0;
   x_errbuf  := ' ';
   lv_request_data   := NULL;



   WRITE_LOG('Calling submit program first time...');

     ---------------------------------------------------------------------------
     -- Submit program 'XX_CDH_CONV_LOAD_ACCT_CONTACTS' which is in First stage
     ---------------------------------------------------------------------------

      lt_conc_request_id := 0;
      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONV_LOAD_ACCT_CONTACTS',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_ACCT_CONTACTS Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'XX_CDH_CONV_LOAD_ACCT_CONTACTS Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_ACCT_CONTACTS Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

      -- Wait for XX_CDH_CONV_LOAD_ACCT_CONTACTS Program to Complete

      lv_phase       := NULL;
      lv_status      := NULL;
      lv_dev_phase   := NULL;
      lv_dev_status  := NULL;
      lv_message     := NULL;
      lv_error_exist := NULL;
      lv_warning     := NULL;


      lb_wait := FND_CONCURRENT.wait_for_request
                    (   request_id      => lt_conc_request_id,
                        interval        => 10,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );
	--------------------
	--END Submit Program
	--------------------

     ---------------------------------------------------------------------------
     -- Submit program 'XX_CDH_CONV_LOAD_ADDRESSUSES' which is in Second stage
     ---------------------------------------------------------------------------

      lt_conc_request_id := 0;
      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONV_LOAD_ADDRESSUSES',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_ADDRESSUSES Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'XX_CDH_CONV_LOAD_ACCOUNTS Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_ADDRESSUSES Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

      -- Wait for XX_CDH_CONV_LOAD_ADDRESSUSES Program to Complete

      lv_phase       := NULL;
      lv_status      := NULL;
      lv_dev_phase   := NULL;
      lv_dev_status  := NULL;
      lv_message     := NULL;
      lv_error_exist := NULL;
      lv_warning     := NULL;


      lb_wait := FND_CONCURRENT.wait_for_request
                    (   request_id      => lt_conc_request_id,
                        interval        => 10,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );
	--------------------
	--END Submit Program
	--------------------

     ---------------------------------------------------------------------------
     -- Submit program 'XX_CDH_CONV_LOAD_CREDITRATINGS' which is in Second stage
     ---------------------------------------------------------------------------

      lt_conc_request_id := 0;
      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONV_LOAD_CREDITRATINGS',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_CREDITRATINGS Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'XX_CDH_CONV_LOAD_CREDITRATINGS Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_CREDITRATINGS Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

      -- Wait for XX_CDH_CONV_LOAD_CREDITRATINGS Program to Complete

      lv_phase       := NULL;
      lv_status      := NULL;
      lv_dev_phase   := NULL;
      lv_dev_status  := NULL;
      lv_message     := NULL;
      lv_error_exist := NULL;
      lv_warning     := NULL;


      lb_wait := FND_CONCURRENT.wait_for_request
                    (   request_id      => lt_conc_request_id,
                        interval        => 10,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );
	--------------------
	--END Submit Program
	--------------------

     ---------------------------------------------------------------------------
     -- Submit program 'XX_CDH_CONV_LOAD_RELSHIPS' which is in Second stage
     ---------------------------------------------------------------------------

      lt_conc_request_id := 0;
      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONV_LOAD_RELSHIPS',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_RELSHIPS Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'XX_CDH_CONV_LOAD_RELSHIPS Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_RELSHIPS Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

      -- Wait for XX_CDH_CONV_LOAD_RELSHIPS Program to Complete

      lv_phase       := NULL;
      lv_status      := NULL;
      lv_dev_phase   := NULL;
      lv_dev_status  := NULL;
      lv_message     := NULL;
      lv_error_exist := NULL;
      lv_warning     := NULL;


      lb_wait := FND_CONCURRENT.wait_for_request
                    (   request_id      => lt_conc_request_id,
                        interval        => 10,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );
	--------------------
	--END Submit Program
	--------------------

       ---------------------------------------------------------------------------
     -- Submit program 'XX_CDH_CONV_LOAD_PARTIES' which is in Second stage
     ---------------------------------------------------------------------------

      lt_conc_request_id := 0;
      lt_conc_request_id := FND_REQUEST.submit_request
                                    (   application => 'XXCNV',
                                        program     => 'XX_CDH_CONV_LOAD_PARTIES',
                                        description => NULL,
                                        start_time  => NULL,
                                        sub_request => FALSE,
                                        argument1   => p_batch_id
                                    );
      IF lt_conc_request_id = 0 THEN
         x_errbuf  := fnd_message.get;
         x_retcode := 2;
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_PARTIES Program failed to submit: ' || x_errbuf);
         x_errbuf  := 'XX_CDH_CONV_LOAD_PARTIES Program failed to submit: ' || x_errbuf;
      ELSE
         fnd_file.put_line (fnd_file.log, ' ');
         fnd_file.put_line (fnd_file.log, 'XX_CDH_CONV_LOAD_PARTIES Program submitted with request id: '|| TO_CHAR( lt_conc_request_id ));
         COMMIT;
      END IF;

      -- Wait for XX_CDH_CONV_LOAD_PARTIES Program to Complete

      lv_phase       := NULL;
      lv_status      := NULL;
      lv_dev_phase   := NULL;
      lv_dev_status  := NULL;
      lv_message     := NULL;
      lv_error_exist := NULL;
      lv_warning     := NULL;


      lb_wait := FND_CONCURRENT.wait_for_request
                    (   request_id      => lt_conc_request_id,
                        interval        => 10,
                        phase           => lv_phase,
                        status          => lv_status,
                        dev_phase       => lv_dev_phase,
                        dev_status      => lv_dev_status,
                        message         => lv_message
                    );
	--------------------
	--END Submit Program
	--------------------


    WRITE_LOG('Finished.');

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
END load_main;


END XX_CDH_CONV_LOAD_INT_STG4_PKG;
/
SHOW ERRORS;
