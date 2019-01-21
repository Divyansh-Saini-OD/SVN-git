SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AR_LATE_LBOX_ALERT_PKG AS

-- +===================================================================+
-- | Name  : XX_AR_LATE_LBOX_ALERT_PKG.CHECK_LBOX_STATUS               |
-- | Description      : This Procedure will send an email if any       |
-- |                    lockbox due today, has yet to be received      |
-- |                                                                   |
-- | Parameters      email distribution list                           |
-- +===================================================================+

PROCEDURE CHECK_LBOX_STATUS(errbuf       OUT NOCOPY VARCHAR2,
                            retcode      OUT NOCOPY NUMBER,
                            p_email_dl   IN         VARCHAR2)
IS
lc_message_subject      VARCHAR2(20) := 'Late Lockbox Alert  ';
lc_late_lockboxes       VARCHAR2(2000);
lc_email_msg            VARCHAR2(230);
lc_return_status        VARCHAR2(100);
lc_email_dl             VARCHAR2(100);
lc_error_msg            VARCHAR2(1000);
ln_conc_id              NUMBER       :=0;

CURSOR late_lockbox IS
       SELECT X.LBOX AS LBOX
       FROM  (SELECT DISTINCT SUBSTR(r.argument1,50,LENGTH(r.argument1)-49) AS LBOX
              FROM   fnd_concurrent_requests    R,
                     FND_CONCURRENT_PROGRAMS_VL P
              WHERE  R.concurrent_program_id             = P.concurrent_program_id
              AND    P.user_concurrent_program_name      = 'OD: AR Lockbox Process - Mains'
              AND    TO_CHAR(R.ACTUAL_START_DATE, 'DAY') = TO_CHAR(SYSDATE, 'DAY')) X
       WHERE  X.LBOX NOT IN (SELECT DISTINCT SUBSTR(r.argument1,50,LENGTH(r.argument1)-49) AS LBOX1
                             FROM   fnd_concurrent_requests    R,
                                    FND_CONCURRENT_PROGRAMS_VL P
                             WHERE  R.concurrent_program_id             = P.concurrent_program_id
                             AND    P.user_concurrent_program_name      = 'OD: AR Lockbox Process - Mains'
                             AND    TRUNC(R.ACTUAL_START_DATE)          = TRUNC(SYSDATE))
       order by 1;

BEGIN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_LATE_LBOX_ALERT_PKG Begin:');
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parameter: '||p_email_dl);
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

    lc_late_lockboxes := '';
    lc_email_dl       := p_email_dl;

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Email Distribution list: '||lc_email_dl);

    FOR lockbox_rec IN late_lockbox
        LOOP
            lc_late_lockboxes := lc_late_lockboxes || lockbox_rec.LBOX || CHR(13);
        END LOOP;

    IF lc_late_lockboxes = '' THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'No late lockboxes found ');
    ELSE
       IF LENGTH(lc_late_lockboxes) < 230 THEN
          lc_email_msg := lc_late_lockboxes;
       ELSE
          lc_email_msg := substr(lc_late_lockboxes,1,220)||CHR(10)||'more...';
       END IF;

       ln_conc_id := fnd_request.submit_request(application => 'XXFIN'
                                               ,program     => 'XXODEMAILER'
                                               ,description =>  NULL
                                               ,start_time  =>  SYSDATE
                                               ,sub_request =>  FALSE
                                               ,argument1   =>  lc_email_dl
                                               ,argument2   =>  lc_message_subject
                                               ,argument3   =>  lc_email_msg);
       IF ln_conc_id = 0 THEN
          lc_error_msg := fnd_message.get;
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error submitting XXODEMAILER: '||lc_error_msg);
       ELSE
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitted email RID:'||ln_conc_id);
       END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AR_LATE_LBOX_ALERT_PKG OTHERS ERROR'||SQLERRM);
         RETCODE := 2;

END CHECK_LBOX_STATUS;

END XX_AR_LATE_LBOX_ALERT_PKG;
/
