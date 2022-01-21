create or replace
PACKAGE BODY  XX_AP_EFT_ALERT_PKG AS
-- +=====================================================================================================+
-- |  Office Depot - Project Simplify                                                                    |
-- |  Providge Consulting                                                                                |
-- +=====================================================================================================+
-- |  RICE:                                                                                              |
-- |                                                                                                     |
-- |  Name:  XX_AP_EFT_ALERT_PKG                                                                         |
-- |                                                                                                     |
-- |  Description:  This package will examine the AP batch confirmation status and send email alert      |
-- |                if batches are not confirmed by execution time                                       |
-- |                                                                                                     |
-- |  Change Record:                                                                                     |
-- +=====================================================================================================+
-- | Version     Date         Author               Remarks                                               |
-- | =========   ===========  =============        ======================================================|
-- | 1.0         16-DEC-2011  R.Strauss            Initial version                                       |
-- | 1.1         27-OCT-2015  Harvinder Rakhra     R12.2 Retrofit                                        |
-- +=====================================================================================================+
PROCEDURE CHECK_EFT_CONFIRM(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER,
                            p_days       IN  NUMBER,
                            p_email_addr IN  VARCHAR2)
IS

x_error_message		VARCHAR2(2000)	DEFAULT NULL;
x_return_status		VARCHAR2(20)	DEFAULT NULL;
x_msg_count			NUMBER		DEFAULT NULL;
x_msg_data			VARCHAR2(4000)	DEFAULT NULL;
x_return_flag		VARCHAR2(1)		DEFAULT NULL;

ln_conc_id			NUMBER            :=0;
lc_days                 NUMBER            :=1;
lc_email_addr           VARCHAR2(50)      := 'rstrauss@officedepot.com';
lc_msg                  VARCHAR2(4000)    DEFAULT NULL;
lc_subject              VARCHAR2(100)     := 'AP EFT Alert - Batch(s) not formatted';
lc_body                 VARCHAR2(50)      := 'Following Batches were not formatted:'||chr(10);

-- ==========================================================================
-- primary cursor 
-- ==========================================================================
CURSOR eft_unconfirm_cur IS
       SELECT S.checkrun_name
       FROM   AP_INV_SELECTION_CRITERIA_ALL S,
              AP_PAYMENT_TEMPLATES          T
       WHERE  S.template_id        = T.template_id
       AND    T.TEMPLATE_NAME      LIKE 'EFT%'
       AND    S.status             = 'SELECTED'
       AND    S.checkrun_id        NOT IN (SELECT C.checkrun_id
                                           FROM   AP_CHECKS_ALL    C,
                                                  IBY_PAYMENTS_ALL P
                                           WHERE  C.payment_instruction_id = P.payment_instruction_id
                                           AND    C.checkrun_id            = S.checkrun_id 
                                           AND    P.payment_status         = 'FORMATTED')
       AND    S.creation_date > sysdate - lc_days;

-- ==========================================================================
-- Main process
-- ==========================================================================
BEGIN

	FND_FILE.PUT_LINE(fnd_file.log,'XX_AP_EFT_ALERT_PKG.CHECK_EFT_CONFIRM - parameters:      ');

      IF LENGTH(p_email_addr) > 0 THEN
         lc_email_addr := p_email_addr; 
      END IF;

      IF LENGTH(p_days) > 0 THEN
         lc_days := p_days; 
      END IF;

	FND_FILE.PUT_LINE(fnd_file.log,'                                        Lookback days: '||lc_days);
	FND_FILE.PUT_LINE(fnd_file.log,'                                        EMAIL ADDRESS: '||lc_email_addr);
	FND_FILE.PUT_LINE(fnd_file.log,' ');

 
	FND_FILE.PUT_LINE(fnd_file.log,'Checking AP_INV_SELECTION_CRITERIA_ALL for EFT not confirmed');
	FND_FILE.PUT_LINE(fnd_file.log,' ');

	FOR eft_rec IN eft_unconfirm_cur
	LOOP

         lc_msg := lc_msg||eft_rec.checkrun_name||'     '||chr(10);

      END LOOP;

	FND_FILE.PUT_LINE(fnd_file.log,'Found the following not confirmed: ');
	FND_FILE.PUT_LINE(fnd_file.log,' ');
	FND_FILE.PUT_LINE(fnd_file.log,'Checkrun_name = '||lc_msg);
	FND_FILE.PUT_LINE(fnd_file.log,' ');

      IF LENGTH(lc_msg) > 0 THEN
         FND_FILE.PUT_LINE(fnd_file.log,'Sending email notification of unconfirmed');
         FND_FILE.PUT_LINE(fnd_file.log,' ');

         lc_msg  := lc_body||lc_msg;

         ln_conc_id := fnd_request.submit_request(
                                                  application => 'XXFIN'
                                                 ,program     => 'XXODEMAILER'
                                                 ,description =>  NULL
                                                 ,start_time  =>  SYSDATE
                                                 ,sub_request =>  FALSE
                                                 ,argument1   =>  lc_email_addr
                                                 ,argument2   =>  lc_subject
                                                 ,argument3   =>  lc_msg
                                                 );
      END IF;

   EXCEPTION
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(fnd_file.log,'Error - 999 SQLCODE = '||SQLCODE||' SQLERRM = '||SQLERRM); 

END CHECK_EFT_CONFIRM;	

END XX_AP_EFT_ALERT_PKG ;
/