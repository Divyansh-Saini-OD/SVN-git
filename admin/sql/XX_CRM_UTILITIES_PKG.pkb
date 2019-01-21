SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_UTILITIES_PKG
-- +=========================================================================================+
-- |                           Office Depot - Project Simplify                               |
-- |                                Oracle Consulting                                        |
-- +=========================================================================================+
-- | Name        : XX_CRM_UTILITIES_PKG                                                      |
-- | Description : Custom package for data corrections                                       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ===========     ==================   =========================================|
-- |1.0        23-Jun-2008     Ambarish Mukherjee   Initial version                          |
-- |2.0        21-Oct-2008     Rajeev Kamath        Added Email Notification                 |
-- +=========================================================================================+

AS

-- +===================================================================+
-- | Name        : refresh_mat_view                                    |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_view_name                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE refresh_mat_view
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_view_name         IN  VARCHAR2
)
AS
BEGIN

  fnd_file.put_line(fnd_file.log, 'View Name: '||p_view_name);

  fnd_file.put_line(fnd_file.log, 'Start Refresh....... ' || to_char(sysdate, 'HH24:MI:SS'));

  dbms_refresh.refresh(p_view_name);

  fnd_file.put_line(fnd_file.log, 'Refresh Completed... ' || to_char(sysdate, 'HH24:MI:SS'));

END refresh_mat_view;

-- +===================================================================+
-- | Name        : gather_group_stats                                  |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_translation_name                                  |
-- |               p_group_name                                        |
-- +===================================================================+
PROCEDURE gather_group_stats
(   x_errbuf            OUT VARCHAR2
   ,x_retcode           OUT VARCHAR2
   ,p_group_name        IN  VARCHAR2
   ,p_estimate_percent  IN  VARCHAR2
   ,p_parallel_degree   IN  VARCHAR2
   ,p_backup            IN  VARCHAR2
   ,p_granularity       IN  VARCHAR2
   ,p_history_mode      IN  VARCHAR2
   ,p_invalidate_cur    IN  VARCHAR2
)
AS

CURSOR lc_fetch_objects_cur
   ( p_in_group_name               IN VARCHAR2
   )
IS
SELECT xval.source_value2             run_order,
       xval.target_value1             object_type,
       xval.target_value2             object_owner,
       xval.target_value3             object_name,
       xval.target_value4             estimate_percentage,
       xval.target_value5             parallel_degree,
       xval.target_value6             partition_name,
       xval.target_value7             backup,
       xval.target_value8             granularity,
       xval.target_value9             history_mode,
       xval.target_value10            invalidate_cursors
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XX_CRM_DB_STATS'
AND    xdef.translate_id              = xval.translate_id
AND    xval.target_value3             IS NOT NULL
AND    xval.source_value1             = p_in_group_name
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
ORDER  BY source_value2;

lt_conc_request_id                    NUMBER;

BEGIN

  fnd_file.put_line(fnd_file.log, 'Start Program....... ' || to_char(sysdate, 'HH24:MI:SS'));

  FOR lc_fetch_objects_rec IN lc_fetch_objects_cur (p_group_name)
  LOOP

     fnd_file.put_line(fnd_file.log,'-----------------------------------------------------------------');

     IF UPPER(lc_fetch_objects_rec.object_type) = 'TABLE' THEN

        lt_conc_request_id := FND_REQUEST.submit_request
                                 (   application => 'FND'
                                    ,program     => 'FNDGTST'
                                    ,start_time  => NULL
                                    ,argument1   => lc_fetch_objects_rec.object_owner
                                    ,argument2   => lc_fetch_objects_rec.object_name
                                    ,argument3   => NVL(p_estimate_percent, NVL(lc_fetch_objects_rec.estimate_percentage,10))
                                    ,argument4   => NVL(p_parallel_degree, lc_fetch_objects_rec.parallel_degree)
                                    ,argument5   => lc_fetch_objects_rec.partition_name
                                    ,argument6   => NVL(p_backup, NVL(lc_fetch_objects_rec.backup,'NOBACKUP'))
                                    ,argument7   => NVL(p_granularity, NVL(lc_fetch_objects_rec.granularity,'DEFAULT'))
                                    ,argument8   => NVL(p_history_mode, NVL(lc_fetch_objects_rec.history_mode,'LASTRUN'))
                                    ,argument9   => NVL(p_invalidate_cur, NVL(lc_fetch_objects_rec.invalidate_cursors,'Y'))
                                 );

        IF lt_conc_request_id = 0 THEN
           x_errbuf  := fnd_message.get;
           x_retcode := 1;
           fnd_file.put_line (fnd_file.log, 'Gather stats for table: '||lc_fetch_objects_rec.object_name||' failed to submit: ' || x_errbuf);
        ELSE
           fnd_file.put_line (fnd_file.log, ' ');
           fnd_file.put_line (fnd_file.log, 'Submitted Child Request : '|| TO_CHAR( lt_conc_request_id ));
           fnd_file.put_line (fnd_file.log, 'Table                   : '|| lc_fetch_objects_rec.object_name);
           COMMIT;
        END IF;
     ELSIF UPPER(lc_fetch_objects_rec.object_type) = 'INDEX' THEN

        BEGIN
           fnd_file.put_line(fnd_file.log, 'Gather stats for index: '||lc_fetch_objects_rec.object_name || ' started: '||to_char(sysdate, 'HH24:MI:SS'));


           FND_STATS.gather_index_stats
                    (   ownname      => lc_fetch_objects_rec.object_owner
                       ,indname      => lc_fetch_objects_rec.object_name
                       ,percent      => NVL(p_estimate_percent, NVL(lc_fetch_objects_rec.estimate_percentage,10))
                       ,partname     => lc_fetch_objects_rec.partition_name
                       ,backup_flag  => NVL(p_backup, NVL(lc_fetch_objects_rec.backup,'NOBACKUP'))
                       ,hmode        => NVL(p_history_mode, NVL(lc_fetch_objects_rec.history_mode,'LASTRUN'))
                       ,invalidate   => NVL(p_invalidate_cur, NVL(lc_fetch_objects_rec.invalidate_cursors,'Y'))
                     );
           fnd_file.put_line(fnd_file.log, 'Gather stats for index: '||lc_fetch_objects_rec.object_name || ' completed: '||to_char(sysdate, 'HH24:MI:SS'));
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Unexpected Error for index: '||lc_fetch_objects_rec.object_name || SQLERRM);
            x_retcode := 1;
        END;

     END IF;
  END LOOP;

  fnd_file.put_line(fnd_file.log,'-----------------------------------------------------------------');
  fnd_file.put_line(fnd_file.log, 'Program Completed... ' || to_char(sysdate, 'HH24:MI:SS'));

END gather_group_stats;

-- +===================================================================+
-- | Name        : gen_vpd_report_sql                                  |
-- |                                                                   |
-- | Description : This function will be used to generate the sql      |
-- |               for the VPD report                                  |
-- |                                                                   |
-- | Parameters  : p_profile_name                                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION gen_vpd_report_sql
   (   p_profile_name     IN VARCHAR2)
RETURN BOOLEAN
IS
   l_stmt              VARCHAR2(4000);
   l_exists            NUMBER := 0;
BEGIN

   l_stmt := ' MAX(fpo.user_profile_option_name) "Profile Option Name" ';

   FOR x IN ( SELECT frv.responsibility_name
              FROM   fnd_profile_options_vl     fpo,
                     fnd_profile_option_values  fpov,
                     fnd_responsibility_vl      frv
              WHERE  fpo.profile_option_id      = fpov.profile_option_id
              AND    fpov.level_id              = 10003
              AND    fpov.level_value           = frv.responsibility_id
              AND    fpo.profile_option_name    = p_profile_name
           )
   LOOP
      l_exists := 1;
      l_stmt := l_stmt ||
                ' , MAX(decode(frv.responsibility_name, ''' || x.responsibility_name ||
                ''' , fpov.profile_option_value)) "' || SUBSTR(x.responsibility_name,1,30) ||'"';

   END LOOP;
   /*
   l_stmt := l_stmt || ' from   fnd_profile_options_vl     fpo,  '
                    || '        fnd_profile_option_values  fpov, '
                    || '        fnd_responsibility_vl      frv   '
                    || ' where  fpo.profile_option_id      = fpov.profile_option_id  '
                    || ' and    fpov.level_id              = 10003                   '
                    || ' and    fpov.level_value           = frv.responsibility_id   '
                    || ' and    fpo.profile_option_name    = '''||p_profile_name||'''';
   */
   IF l_exists = 0 THEN
      l_stmt := ' 1';
      --l_stmt := 'select ''No Values'' "Profile Option Name" from dual';
   END IF;
   p_select := l_stmt;

   RETURN TRUE;
END gen_vpd_report_sql;

-- +===================================================================+
-- | Name        : get_prof_option_lookup                              |
-- |                                                                   |
-- | Description : This function will be used to get the lookup type   |
-- |               name for a profile option                           |
-- |                                                                   |
-- | Parameters  : p_profile_option_id                                 |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_prof_option_lookup
   (   p_profile_option_id     IN NUMBER)
RETURN VARCHAR2
IS
   ln_quote            NUMBER;
   ln_unquote          NUMBER;
   ln_diff             NUMBER;
   lv_lookup_type      fnd_lookup_values.lookup_type%TYPE;
BEGIN

   SELECT INSTR(sql_validation,'''',1,1) quote,
          INSTR(sql_validation,'''',2,2) unquote
   INTO   ln_quote,
          ln_unquote
   FROM   fnd_profile_options        fpo
   WHERE  fpo.profile_option_id      = p_profile_option_id;

   ln_diff := ln_unquote-(ln_quote+1);

   SELECT SUBSTR(sql_validation,ln_quote+1,ln_diff)
   INTO   lv_lookup_type
   FROM   fnd_profile_options        fpo
   WHERE  fpo.profile_option_id      = p_profile_option_id;

   RETURN lv_lookup_type;

EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL;
END get_prof_option_lookup;

-- +===================================================================+
-- | Name        : send_email                                          |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE send_email_notif(
                           x_errbuf            OUT NOCOPY VARCHAR2
                           , x_retcode         OUT NOCOPY NUMBER
                           , p_module          IN         VARCHAR2
                           , p_send_mail_lkp   IN         VARCHAR2
                           , p_sender_lkp      IN         VARCHAR2
                           , p_recipients_lkp  IN         VARCHAR2
                           , p_subject_lkp     IN         VARCHAR2
                           , p_body            IN         VARCHAR2
                          )
IS
lc_return_status   VARCHAR2(03);
ln_msg_count       NUMBER;
lc_msg_data        VARCHAR2(2000);

BEGIN

send_email_notif(
                 p_module            => p_module
                 , p_send_mail_lkp   => p_send_mail_lkp
                 , p_sender_lkp      => p_sender_lkp
                 , p_recipients_lkp  => p_recipients_lkp
                 , p_subject_lkp     => p_subject_lkp
                 , p_body            => p_body
                 , x_return_status   => lc_return_status
                 , x_msg_count       => ln_msg_count
                 , x_msg_data        => lc_msg_data
                );


IF lc_return_status <> FND_API.G_RET_STS_SUCCESS THEN

  IF ln_msg_count >1 THEN
    FOR I IN 1..ln_msg_count
    LOOP
        fnd_file.put_line(fnd_file.log,I||'. '||SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255));
    END LOOP;
  ELSE
      fnd_file.put_line(fnd_file.log,'1.'||SubStr(lc_msg_data,1,255));
  END IF;

END IF;
END send_email_notif;

-- +===================================================================+
-- | Name        : send_email                                          |
-- |                                                                   |
-- | Description : The main procedure to be invoked from other         |
-- |               programs                                            |
-- |                                                                   |
-- +===================================================================+
PROCEDURE send_email_notif(
                           p_module            IN         VARCHAR2
                           , p_send_mail_lkp   IN         VARCHAR2
                           , p_sender_lkp      IN         VARCHAR2
                           , p_recipients_lkp  IN         VARCHAR2
                           , p_subject_lkp     IN         VARCHAR2
                           , p_body            IN         VARCHAR2
                           , x_return_status   OUT NOCOPY VARCHAR2
                           , x_msg_count       OUT NOCOPY NUMBER
                           , x_msg_data        OUT NOCOPY VARCHAR2
                          )
IS
lc_hour                 VARCHAR2(30);
lc_subject              VARCHAR2(1000);
lc_recipient            VARCHAR2(1000);
lc_valid_module         VARCHAR2(01);
lc_proceed              BOOLEAN;
ln_msg_count            PLS_INTEGER := 0;

CURSOR lcu_get_module
IS
SELECT xval.source_value1            module_name
       , substr(xval.target_value1,1,(instr(xval.target_value1,'-')-1)) alert_exclusion_time_from
       , substr(xval.target_value1,(instr(xval.target_value1,'-')+1),length(xval.target_value1)) alert_exclusion_time_to
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XXOD_CDH_EXCLUSION_TIMES'
AND    xdef.translate_id              = xval.translate_id
AND    xval.source_value1             like p_module||'%'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xdef.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xdef.end_date_active, SYSDATE + 1))
AND    xdef.enabled_flag = 'Y'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
AND    xval.enabled_flag = 'Y';

CURSOR lcu_send_mail
IS
SELECT xval.source_value1             send_email,
       xval.target_value1             yes_or_no_to_send
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XXOD_CDH_SEND_EMAIL'
AND    xdef.translate_id              = xval.translate_id
AND    xval.source_value1             = p_send_mail_lkp
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xdef.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xdef.end_date_active, SYSDATE + 1))
AND    xdef.enabled_flag = 'Y'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
AND    xval.enabled_flag = 'Y';

CURSOR lcu_get_sender
IS
SELECT xval.source_value1            email_sender,
       xval.target_value1             from_address
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XXOD_CDH_EMAIL_SENDER'
AND    xdef.translate_id              = xval.translate_id
AND    xval.source_value1             = p_sender_lkp
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xdef.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xdef.end_date_active, SYSDATE + 1))
AND    xdef.enabled_flag = 'Y'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
AND    xval.enabled_flag = 'Y';

CURSOR lcu_get_email_list
IS
SELECT xval.source_value1             email_list,
       xval.target_value1             to_email_address
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XXOD_CDH_EMAIL_LIST'
AND    xdef.translate_id              = xval.translate_id
AND    xval.source_value1             like p_recipients_lkp||'%'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xdef.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xdef.end_date_active, SYSDATE + 1))
AND    xdef.enabled_flag = 'Y'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
AND    xval.enabled_flag = 'Y';

CURSOR lcu_get_subject
IS
SELECT xval.source_value1             email_sub,
       xval.target_value1             email_subject
FROM   xx_fin_translatedefinition     xdef,
       xx_fin_translatevalues         xval
WHERE  xdef.translation_name          = 'XXOD_CDH_EMAIL_SUBJECT'
AND    xdef.translate_id              = xval.translate_id
AND    xval.source_value1             = p_subject_lkp
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xdef.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xdef.end_date_active, SYSDATE + 1))
AND    xdef.enabled_flag = 'Y'
AND    TRUNC (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
AND    xval.enabled_flag = 'Y';

BEGIN

     x_return_status  := FND_API.G_RET_STS_SUCCESS;
     FND_MSG_PUB.initialize;

     lc_valid_module := 'N';
     lc_hour := to_char(sysdate, 'HH24:MI');

     FOR lrec_get_module IN lcu_get_module
     LOOP

         lc_valid_module  := 'Y';
         x_msg_data       := NULL;
         x_return_status  := NULL;
         lc_proceed       := TRUE;

         IF (lrec_get_module.alert_exclusion_time_from IS NULL OR lrec_get_module.alert_exclusion_time_to IS NULL) THEN

            x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' : The exclusion time for the module is NULL';
            ln_msg_count    := ln_msg_count + 1;
            FND_MSG_PUB.Add_Exc_Msg(
                                    p_pkg_name       => G_PACKAGE_NAME,
                                    p_procedure_name => G_PROCEDURE_NAME,
                                    p_error_text     => x_msg_data
                                   );
            lc_proceed := FALSE;

         END IF;

         IF (lc_proceed) THEN

           IF lc_hour NOT BETWEEN lrec_get_module.alert_exclusion_time_from AND lrec_get_module.alert_exclusion_time_to THEN

             -- Check whether mail can be send
             lc_proceed := FALSE;

             FOR lrec_send_mail IN lcu_send_mail
             LOOP

                 lc_proceed        := TRUE;
                 x_msg_data        := NULL;
                 x_return_status   := NULL;

                 IF (lrec_send_mail.yes_or_no_to_send IS NULL) THEN

                   x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' : The send email yes or no option for '||p_send_mail_lkp||' is NULL';
                   ln_msg_count    := ln_msg_count + 1;
                   FND_MSG_PUB.Add_Exc_Msg(
                                           p_pkg_name       => G_PACKAGE_NAME,
                                           p_procedure_name => G_PROCEDURE_NAME,
                                           p_error_text     => x_msg_data
                                          );
                   lc_proceed := FALSE;

                 END IF;

                 IF (lc_proceed) THEN

                   IF lrec_send_mail.yes_or_no_to_send = 'Yes' THEN

                     -- Derive the sender
                     lc_proceed := FALSE;

                     FOR lrec_get_sender IN lcu_get_sender
                     LOOP

                         lc_proceed        := TRUE;
                         x_msg_data        := NULL;
                         x_return_status   := NULL;
                         

                         IF (lrec_get_sender.from_address IS NULL) THEN

                           x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' : The sender email address for '||p_sender_lkp||' is NULL';
                           ln_msg_count    := ln_msg_count + 1;
                           FND_MSG_PUB.Add_Exc_Msg(
                                                   p_pkg_name       => G_PACKAGE_NAME,
                                                   p_procedure_name => G_PROCEDURE_NAME,
                                                   p_error_text     => x_msg_data
                                                  );
                           lc_proceed := FALSE;

                         END IF;

                         IF (lc_proceed) THEN

                           lc_proceed := FALSE;

                           -- Derive the email list to be send
                           FOR lrec_get_email_list IN lcu_get_email_list
                           LOOP

                               lc_proceed        := TRUE;
                               x_msg_data        := NULL;
                               x_return_status   := NULL;

                               IF (lrec_get_email_list.to_email_address IS NULL) THEN

                                 x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' : The recipent email address for '||lrec_get_email_list.email_list||' is NULL';
                                 ln_msg_count    := ln_msg_count + 1;
                                 FND_MSG_PUB.Add_Exc_Msg(
                                                         p_pkg_name       => G_PACKAGE_NAME,
                                                         p_procedure_name => G_PROCEDURE_NAME,
                                                         p_error_text     => x_msg_data
                                                        );
                                 lc_proceed := FALSE;

                               END IF;

                               IF (lc_proceed) THEN

                                 lc_proceed := FALSE;

                                 FOR lrec_get_subject IN lcu_get_subject
                                 LOOP

                                     x_msg_data       := NULL;
                                     x_return_status  := NULL;
                                     lc_proceed       := TRUE;
                                     lc_subject       := NULL;

                                     IF (lrec_get_subject.email_subject IS NULL) THEN

                                       x_return_status := FND_API.G_RET_STS_ERROR;
                                       x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' to the recipent email address '||lrec_get_email_list.to_email_address||' : The subject for '||p_subject_lkp||' is NULL';
                                       FND_MSG_PUB.Add_Exc_Msg(
                                                               p_pkg_name       => G_PACKAGE_NAME,
                                                               p_procedure_name => G_PROCEDURE_NAME,
                                                               p_error_text     => x_msg_data
                                                              );
                                       lc_proceed := FALSE;

                                     END IF;

                                     IF (lc_proceed) THEN

                                       IF (instr(lrec_get_email_list.to_email_address,'***page***')> 0) THEN

                                         lc_subject := '***page***'||lrec_get_subject.email_subject;
                                         lc_recipient := substr(lrec_get_email_list.to_email_address, 11, length(lrec_get_email_list.to_email_address));

                                       ELSE

                                           lc_subject := lrec_get_subject.email_subject;
                                           lc_recipient := lrec_get_email_list.to_email_address;

                                       END IF;

                                       mail(
                                            sender     => lrec_get_sender.from_address,
                                            recipients => lc_recipient,
                                            subject    => lc_subject,
                                            message    => p_body
                                           );

                                       x_return_status := FND_API.G_RET_STS_SUCCESS;

                                     END IF;
                                     lc_proceed := TRUE;

                                 END LOOP;

                                 IF NOT(lc_proceed) THEN

                                   x_msg_data     := 'Mail cannot be send for module '||lrec_get_module.module_name||' to the recipent email address '||lrec_get_email_list.to_email_address||' : Either the Subject Lookup '||p_subject_lkp||' is not setup or is inactivated';
                                   ln_msg_count    := ln_msg_count + 1;
                                   FND_MSG_PUB.Add_Exc_Msg(
                                                           p_pkg_name       => G_PACKAGE_NAME,
                                                           p_procedure_name => G_PROCEDURE_NAME,
                                                           p_error_text     => x_msg_data
                                                          );


                                 END IF;
                                 lc_proceed := TRUE;

                               END IF;

                           END LOOP;

                           IF NOT(lc_proceed) THEN

                             x_msg_data      := 'Mail cannot be send for module '||lrec_get_module.module_name||' : Either the Recipient Lookup '||p_recipients_lkp||' is not setup or is inactivated';
                             ln_msg_count    := ln_msg_count + 1;
                             FND_MSG_PUB.Add_Exc_Msg(
                                                     p_pkg_name       => G_PACKAGE_NAME,
                                                     p_procedure_name => G_PROCEDURE_NAME,
                                                     p_error_text     => x_msg_data
                                                    );


                           END IF;

                         END IF;
                         lc_proceed := TRUE;

                     END LOOP;

                     IF NOT(lc_proceed) THEN

                       x_msg_data     := 'Mail cannot be send for module '||lrec_get_module.module_name||' : Either the Sender Lookup '||p_sender_lkp||' is not setup or is inactivated';
                       ln_msg_count    := ln_msg_count + 1;
                       FND_MSG_PUB.Add_Exc_Msg(
                                               p_pkg_name       => G_PACKAGE_NAME,
                                               p_procedure_name => G_PROCEDURE_NAME,
                                               p_error_text     => x_msg_data
                                              );


                     END IF;
                     lc_proceed := TRUE;

                   ELSE

                       x_msg_data     := 'Mail cannot be send for module '||lrec_get_module.module_name||' : The Send Email Option for Lookup '||p_send_mail_lkp||' is set to No';
                       ln_msg_count    := ln_msg_count + 1;
                       FND_MSG_PUB.Add_Exc_Msg(
                                               p_pkg_name       => G_PACKAGE_NAME,
                                               p_procedure_name => G_PROCEDURE_NAME,
                                               p_error_text     => x_msg_data
                                              );

                   END IF;

                 END IF;

                 lc_proceed := TRUE;

             END LOOP;

             IF NOT(lc_proceed) THEN

                x_msg_data     := 'Mail cannot be send for module '||lrec_get_module.module_name||' : Either the Send Email Lookup '||p_send_mail_lkp||' is not setup or the lookup is inactivated';
                ln_msg_count    := ln_msg_count + 1;
                FND_MSG_PUB.Add_Exc_Msg(
                                        p_pkg_name       => G_PACKAGE_NAME,
                                        p_procedure_name => G_PROCEDURE_NAME,
                                        p_error_text     => x_msg_data
                                       );

             END IF;

           ELSE

                x_msg_data     := 'Mail cannot be send for module '||lrec_get_module.module_name||' : Between '||lrec_get_module.alert_exclusion_time_from||' AND '||lrec_get_module.alert_exclusion_time_to;
                ln_msg_count    := ln_msg_count + 1;
                FND_MSG_PUB.Add_Exc_Msg(
                                        p_pkg_name       => G_PACKAGE_NAME,
                                        p_procedure_name => G_PROCEDURE_NAME,
                                        p_error_text     => x_msg_data
                                       );

           END IF;

         END IF;

     END LOOP;

     IF lc_valid_module = 'N' THEN

       x_msg_data     := 'Mail cannot be send: Either the module '||p_module||' is not setup or is inactivated';
       ln_msg_count    := ln_msg_count + 1;
       FND_MSG_PUB.Add_Exc_Msg(
                               p_pkg_name       => G_PACKAGE_NAME,
                               p_procedure_name => G_PROCEDURE_NAME,
                               p_error_text     => x_msg_data
                              );

     END IF;

     FND_MSG_PUB.count_and_get(
                               p_encoded => fnd_api.g_false,
                               p_count   => x_msg_count,
                               p_data    => x_msg_data
                              );


     IF ln_msg_count > 0 THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

     END IF;

EXCEPTION
   WHEN OTHERS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       x_msg_data     := 'Mail cannot be send: '||SQLERRM;
       FND_MSG_PUB.Add_Exc_Msg(
                               p_pkg_name       => G_PACKAGE_NAME,
                               p_procedure_name => G_PROCEDURE_NAME,
                               p_error_text     => x_msg_data
                              );
       FND_MSG_PUB.count_and_get(
                                 p_encoded => fnd_api.g_false,
                                 p_count   => x_msg_count,
                                 p_data    => x_msg_data
                                );
END send_email_notif;

-- +===================================================================+
-- | Name        : get_address                                         |
-- |                                                                   |
-- | Description : This is a private function to get address           |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_address(
                     addr_list IN OUT VARCHAR2
                    )
RETURN VARCHAR2
IS
addr VARCHAR2(256);
i    pls_integer;

FUNCTION lookup_unquoted_char(
                              str  IN VARCHAR2,
                              chrs IN VARCHAR2
                             )
RETURN pls_integer AS
c            VARCHAR2(5);
i            pls_integer;
len          pls_integer;
inside_quote BOOLEAN;

BEGIN

   inside_quote := false;
   i := 1;
   len := length(str);

   WHILE (i <= len)
   LOOP

       c := substr(str, i, 1);

       IF (inside_quote) THEN
         IF (c = '"') THEN
           inside_quote := false;
         ELSIF (c = '\') THEN
              i := i + 1; -- Skip the quote character
         END IF;
         GOTO next_char;
       END IF;

       IF (c = '"') THEN
         inside_quote := true;
         GOTO next_char;
       END IF;

       IF (instr(chrs, c) >= 1) THEN
         RETURN i;
       END IF;

       <<next_char>>
       i := i + 1;

   END LOOP;
   RETURN 0;

END lookup_unquoted_char;

BEGIN

    addr_list := ltrim(addr_list);

    i := lookup_unquoted_char(addr_list, ',;');

    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
        addr := addr_list;
        addr_list := '';
    END IF;

    i := lookup_unquoted_char(addr, '<');

    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
        addr := substr(addr, 1, i - 1);
      END IF;
    END IF;

RETURN addr;
END get_address;

-- Write a MIME header
PROCEDURE write_mime_header(
                            conn  IN OUT NOCOPY utl_smtp.connection,
                            name  IN VARCHAR2,
                            value IN VARCHAR2
                           )
IS
BEGIN
    utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
END write_mime_header;

-- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
PROCEDURE write_boundary(
                         conn  IN OUT NOCOPY utl_smtp.connection,
                         last  IN            BOOLEAN DEFAULT FALSE
                        )
IS
BEGIN

    IF (last) THEN
      utl_smtp.write_data(conn, G_LAST_BOUNDARY);
    ELSE
        utl_smtp.write_data(conn, G_FIRST_BOUNDARY);
    END IF;
END write_boundary;

-- +===================================================================+
-- | Name        : mail                                                |
-- |                                                                   |
-- | Description : The procedure to send email in plain text           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE mail(
               sender     IN VARCHAR2,
               recipients IN VARCHAR2,
               subject    IN VARCHAR2,
               message    IN VARCHAR2
              )
IS
conn utl_smtp.connection;
lmessage varchar2(32000);
BEGIN

    conn := begin_mail(sender, recipients, subject);
    write_text(conn,message);
    end_mail(conn);
END mail;

-- +===================================================================+
-- | Name        : begin_mail                                          |
-- |                                                                   |
-- | Description : The function  used to begin mail                    |
-- |                                                                   |
-- +===================================================================+
FUNCTION begin_mail(
                    sender     IN VARCHAR2,
                    recipients IN VARCHAR2,
                    subject    IN VARCHAR2,
                    mime_type  IN VARCHAR2    DEFAULT 'text/plain',
                    priority   IN PLS_INTEGER DEFAULT NULL
                   )
RETURN utl_smtp.connection
IS
conn utl_smtp.connection;
BEGIN

    conn := begin_session;
    begin_mail_in_session(
                          conn, sender, recipients, subject, mime_type,priority);
    RETURN conn;
END begin_mail;

-- +===================================================================+
-- | Name        : write_text                                          |
-- |                                                                   |
-- | Description : The procedure to write email body in ASCII          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_text(conn    IN OUT NOCOPY utl_smtp.connection,
                     message IN VARCHAR2
                    )
IS
BEGIN
    utl_smtp.write_data(conn, message);
END write_text;

-- +===================================================================+
-- | Name        : end_mail                                            |
-- |                                                                   |
-- | Description : The procedure to end the email                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_mail(conn IN OUT NOCOPY utl_smtp.connection)
IS
BEGIN
    end_mail_in_session(conn);
    end_session(conn);
END end_mail;

-- +===================================================================+
-- | Name        : begin_session                                       |
-- |                                                                   |
-- | Description : The function to begin a session                     |
-- |                                                                   |
-- +===================================================================+
FUNCTION begin_session
RETURN   utl_smtp.connection
IS
conn utl_smtp.connection;
BEGIN
    -- open SMTP connection
    conn := utl_smtp.open_connection(G_SMTP_HOST, G_SMTP_PORT);
    utl_smtp.helo(conn, G_SMTP_DOMAIN);
    RETURN conn;
END begin_session;

-- +===================================================================+
-- | Name        : begin_mail_in_session                               |
-- |                                                                   |
-- | Description : The procedure to begin an email in a session        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE begin_mail_in_session(conn       IN OUT NOCOPY utl_smtp.connection,
                                sender     IN VARCHAR2,
                                recipients IN VARCHAR2,
                                subject    IN VARCHAR2,
                                mime_type  IN VARCHAR2  DEFAULT 'text/plain',
                                priority   IN PLS_INTEGER DEFAULT NULL
                               )
IS
my_recipients VARCHAR2(32767) := recipients;
my_sender     VARCHAR2(32767) := sender;

BEGIN

    -- Specify sender's address (our server allows bogus address
    -- as long as it is a full email address (xxx@yyy.com).
    utl_smtp.mail(conn, get_address(my_sender));

    -- Specify recipient(s) of the email.
    WHILE (my_recipients IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(my_recipients));
    END LOOP;

    -- Start body of email
    utl_smtp.open_data(conn);

    -- Set "From" MIME header
    write_mime_header(conn, 'From', sender);

    -- Set "To" MIME header
    write_mime_header(conn, 'To', recipients);

    -- Set "Subject" MIME header
    write_mime_header(conn, 'Subject', subject);

    -- Set "Content-Type" MIME header
    write_mime_header(conn, 'Content-Type', mime_type);

    -- Set "X-Mailer" MIME header
    write_mime_header(conn, 'X-Mailer', G_MAILER_ID);

    -- Set priority:
    --   High      Normal       Low
    --   1     2     3     4     5
    IF (priority IS NOT NULL) THEN
      write_mime_header(conn, 'X-Priority', priority);
    END IF;

    -- Send an empty line to denotes end of MIME headers and
    -- beginning of message body.
    utl_smtp.write_data(conn, utl_tcp.CRLF);

    IF (mime_type LIKE 'multipart/mixed%') THEN
      write_text(conn, 'This is a multi-part message in MIME format.' ||utl_tcp.crlf);
    END IF;

END begin_mail_in_session;

-- +===================================================================+
-- | Name        : end_mail_in_session                                 |
-- |                                                                   |
-- | Description : The procedure to end an email in a session          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_mail_in_session(conn IN OUT NOCOPY utl_smtp.connection)
IS
BEGIN
    utl_smtp.close_data(conn);
END end_mail_in_session;

-- +===================================================================+
-- | Name        : end_session                                         |
-- |                                                                   |
-- | Description : The procedure to end an email session               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE end_session(conn IN OUT NOCOPY utl_smtp.connection)
IS
BEGIN
    utl_smtp.quit(conn);
END end_session;


END XX_CRM_UTILITIES_PKG;
/
SHOW ERRORS;