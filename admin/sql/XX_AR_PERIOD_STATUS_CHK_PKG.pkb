create or replace PACKAGE BODY XX_AR_PERIOD_STATUS_CHK_PKG
AS
---+============================================================================================+
---|                              Office Depot - Project Simplify                               |
---|                                   Wipro Technologies                                       |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_PERIOD_STATUS_CHK_PKG.pkb                                       |
---|                                                                                            |
---|    Description     : Current,Next,Prior Period Status Extract                              |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             30-APR-2009       RamyaPriya M       Initial Version - Defect# 14073    |
---|    1.1             04-JAN-2009       Sundaram S         Updated for the Defect# 3851       |
---|    1.2             14-JUN-2013       Divya Sidhaiyan    Updated for QC Defect # 23956      |
---|    1.3             10-OCT-2013       Sathish Danda      Updated to include R12 Upgrade     |
---|                                                         retrofit  changes                  |
---|    1.4             11-NOV-2015       Vasu Raparla       Removed Schema References for R12.2|
-- |    1.5             23-JAN-2019       BIAS               INSTANCE_NAME is replaced with     |
-- |                                                         DB_NAME for OCI Migration          |
---+============================================================================================+

   FUNCTION XX_CLOSING_STATUS (p_application_id IN  NUMBER
                              ,p_closing_status IN  VARCHAR2)
                               RETURN VARCHAR2 IS

           lc_closing_status   fnd_lookup_values.meaning%TYPE;

   BEGIN
           SELECT meaning
             INTO lc_closing_status
             FROM fnd_lookup_values
            WHERE lookup_type IN ('CLOSING_STATUS','CLOSING STATUS')
              AND view_application_id = p_application_id
              AND lookup_code = p_closing_status;
           RETURN(lc_closing_status);

   EXCEPTION
           WHEN NO_DATA_FOUND THEN
             CASE p_closing_status
                 WHEN  'O'  THEN
                     RETURN ('Open');
                 WHEN  'C'  THEN
                     RETURN ('Close');
                 WHEN  'F'  THEN
                     RETURN ('Future');
                 WHEN  'P'  THEN
                     RETURN ('Permanently Closed');
                 WHEN  'N'  THEN
                     RETURN ('Never Opened');
                 WHEN  'W'  THEN
                     RETURN ('Closed Pending');
              END CASE;
           WHEN OTHERS THEN
             RETURN ('XXX');
   END  XX_CLOSING_STATUS;


   -- Added for QC Defect # 23956 - Start
   FUNCTION XX_PA_PERIOD_NAME (p_period_type IN VARCHAR2,
                               p_date        IN DATE)
    RETURN VARCHAR2 IS

        ln_current_period   NUMBER;
        lc_period_name      VARCHAR2(30);

    BEGIN

        ln_current_period   := 0;
        lc_period_name      := NULL;

        SELECT row_num
          INTO ln_current_period
          FROM (SELECT ROWNUM row_num,
                       papl.period_name,
                       papl.start_date,
                       papl.end_date,
                       papl.status
                  FROM pa_periods_all papl
                 WHERE p_date BETWEEN papl.start_date - 32 AND papl.end_date + 31
                  AND papl.org_id = 404
                ORDER BY papl.start_date)
        WHERE p_date BETWEEN start_date AND end_date
        ;


        IF p_period_type = 'PRIOR' THEN

            SELECT period_name
              INTO lc_period_name
              FROM (SELECT ROWNUM row_num,
                           papl.period_name,
                           papl.start_date,
                           papl.end_date,
                           papl.status
                      FROM pa_periods_all papl
                     WHERE p_date BETWEEN papl.start_date - 32 AND papl.end_date + 31
                      AND papl.org_id = 404
                    ORDER BY papl.start_date)
            WHERE row_num = ln_current_period - 1;

        ELSIF p_period_type = 'CURR' THEN

            SELECT period_name
              INTO lc_period_name
              FROM (SELECT ROWNUM row_num,
                           papl.period_name,
                           papl.start_date,
                           papl.end_date,
                           papl.status
                      FROM pa_periods_all papl
                     WHERE p_date BETWEEN papl.start_date - 32 AND papl.end_date + 31
                      AND papl.org_id = 404
                    ORDER BY papl.start_date)
            WHERE row_num = ln_current_period;

        ELSE

            SELECT period_name
              INTO lc_period_name
              FROM (SELECT ROWNUM row_num,
                           papl.period_name,
                           papl.start_date,
                           papl.end_date,
                           papl.status
                      FROM pa_periods_all papl
                     WHERE p_date BETWEEN papl.start_date - 32 AND papl.end_date + 31
                      AND papl.org_id = 404
                    ORDER BY papl.start_date)
            WHERE row_num = ln_current_period + 1;

        END IF;

        RETURN lc_period_name;

    EXCEPTION
        WHEN OTHERS THEN

        BEGIN
            SELECT papl.period_name
              INTO lc_period_name
              FROM pa_periods_all papl
             WHERE p_date BETWEEN papl.start_date AND papl.end_date
               AND papl.org_id = 404;

            IF p_period_type = 'PRIOR' THEN

                SELECT to_char (add_months (to_date (p_date, 'DD-MON-RR HH24:MI:SS'), -1), 'MON-YY') --Added DD-MON-RR HH24:MI:SS for Defect# 25112 by Divya Sidhaiyan
                  INTO lc_period_name
                  FROM dual;

            ELSIF p_period_type = 'CURR' THEN

                lc_period_name := lc_period_name;

            ELSE

                SELECT to_char (add_months (to_date (p_date, 'DD-MON-RR HH24:MI:SS'), +1), 'MON-YY') --Added DD-MON-RR HH24:MI:SS for Defect# 25112 by Divya Sidhaiyan
                  INTO lc_period_name
                  FROM dual;

            END IF;

            RETURN lc_period_name;
        END;

    END XX_PA_PERIOD_NAME;
   -- Added for QC Defect # 23956 - End


   PROCEDURE MAIN ( x_errbuf                   OUT NOCOPY      VARCHAR2
                   ,x_retcode                  OUT NOCOPY      NUMBER
                   ,p_run_date                 IN              VARCHAR2
                   )
                   IS

   CURSOR lcu_gl_period_status(p_date            DATE ,
                               p_fa_period_count NUMBER, -- Added for QC Defect # 23956
                               p_fa_next_count   NUMBER  -- Added for QC Defect # 23956
                              )
   IS
      SELECT  gps_pre.period_name   PRIOR_PERIOD_NAME
              ,gps_cur.period_name   CURRENT_PERIOD_NAME
              ,gps_post.period_name  POST_PERIOD_NAME
              ,fnd.application_name  APPLICATION
            --,GL_SOB.short_name     SOB                          --Commented/Added by Sathish on 10th OCT'13 for R12 Retrofit Upgrade
              ,GL.short_name     SOB
              ,xx_closing_status(gps_pre.application_id,gps_pre.closing_status)     PRIOR_PERIOD
              ,xx_closing_status(gps_cur.application_id,gps_cur.closing_status)     CURRENT_PERIOD
              ,xx_closing_status(gps_post.application_id,gps_post.closing_status)   NEXT_PERIOD
       FROM   gl_period_statuses GPS_PRE
             ,gl_period_statuses GPS_CUR
             ,gl_period_statuses GPS_POST
            --,gl_sets_of_books   GL_SOB    --Commented/Added by Sathish on 10th OCT'13 for R12 Retrofit Upgrade
              ,gl_ledgers         GL
             ,fnd_application_vl FND
       WHERE p_date BETWEEN GPS_CUR.start_date AND GPS_CUR.end_date
         AND GPS_CUR.application_id = FND.application_id
        --AND GPS_CUR.set_of_books_id = GL_SOB.set_of_books_id     --Commented/Added by Sathish on 10th OCT'13 for R12 Retrofit Upgrade
         AND GPS_CUR.ledger_id = GL.ledger_id
         AND GPS_PRE.application_id = GPS_CUR.application_id
       --AND GPS_PRE.set_of_books_id = GPS_CUR.set_of_books_id    --Commented/Added by Sathish on 10th OCT'13  for R12 Retrofit Upgrade
         AND GPS_PRE.ledger_id = GPS_CUR.ledger_id
         AND GPS_PRE.effective_period_num = DECODE(SUBSTR(GPS_CUR.effective_period_num,-2),
                                                         '01', (gps_cur.effective_period_num- 9989),
                                                         (gps_cur.effective_period_num-1)) --Updated for the defect# 3851
         AND GPS_POST.application_id = GPS_CUR.application_id
       --AND GPS_POST.set_of_books_id = GPS_CUR.set_of_books_id   --Commented/Added by Sathish on 10th Oct'13 for R12 Retrofit Upgrade
         AND GPS_POST.ledger_id = GPS_CUR.ledger_id
         AND GPS_POST.effective_period_num = DECODE(SUBSTR(GPS_CUR.effective_period_num,-2),
                                                   '12',(gps_cur.effective_period_num + 9989),
                                                   (gps_cur.effective_period_num +1))  --Updated for the defect# 3851
         AND FND.application_short_name IN (SELECT XFTV.target_value1
                                            FROM   xx_fin_translatevalues XFTV
                                                  ,xx_fin_translatedefinition XFTD
                                            WHERE  XFTD.translate_id       = XFTV.translate_id
                                              AND  XFTD.translation_name   = 'OD_AR_PERIOD_CHK_TRANSLTN'
                                              AND  XFTV.source_value1      = 'APPL_SHORT_NAME'
                                              AND  XFTD.enabled_flag       = 'Y'
                                              AND  XFTV.enabled_flag       = 'Y'
                                            )
       -- Added for QC Defect # 23956 - Start
       UNION
       SELECT prior_period_name,
              current_period_name,
              post_period_name ,
              application,
              sob,
              prior_period,
              current_period,
              next_period
        FROM
          (SELECT DISTINCT fdp_prior.period_name PRIOR_PERIOD_NAME,
                  fdp_curr.period_name CURRENT_PERIOD_NAME,
                  (
                  CASE
                    WHEN p_fa_next_count = p_fa_period_count
                    THEN to_char (add_months (to_date (fdp_curr.period_name, 'MON-YY'), +1), 'MON-YY')
                    WHEN p_fa_next_count <> p_fa_period_count
                    THEN fdp_next.period_name
                  END ) POST_PERIOD_NAME,
                  fnd.application_name APPLICATION,
                  DECODE (fdp_curr.book_type_code, 'OD US CORP', 'US_USD_P', 'OD CA CORP', 'CA_CAD_P' ) SOB,
                  DECODE (fdp_prior.period_close_date, NULL, 'Open', 'Closed' ) PRIOR_PERIOD,
                  DECODE (fdp_curr.period_close_date, NULL, 'Open', 'Closed' ) CURRENT_PERIOD,
                  (
                  CASE
                    WHEN p_fa_next_count = p_fa_period_count
                    THEN 'Never Opened'
                    WHEN p_fa_next_count <> p_fa_period_count
                    THEN  (
                          CASE
                            WHEN fdp_next.period_open_date IS NULL
                            THEN 'Never Opened'
                            WHEN fdp_next.period_close_date IS NULL
                            THEN 'Open'
                            WHEN fdp_next.period_close_date IS NOT NULL
                            THEN 'Closed'
                          END )
                  END ) NEXT_PERIOD
                FROM fa_deprn_periods fdp_prior,
                  fa_deprn_periods fdp_curr,
                  fa_deprn_periods fdp_next,
                  fa_book_controls fbc,
                  fnd_application_vl fnd
                WHERE 1                         = 1
                AND fbc.book_type_code          = fdp_prior.book_type_code
                AND fbc.book_type_code          = fdp_curr.book_type_code
                AND fbc.book_type_code          = fdp_next.book_type_code
                AND fbc.book_class              = 'CORPORATE'
                AND fbc.gl_posting_allowed_flag = 'YES'
                AND fdp_prior.book_type_code   IN ('OD US CORP', 'OD CA CORP')
                AND fdp_curr.book_type_code    IN ('OD US CORP', 'OD CA CORP')
                AND fdp_next.book_type_code    IN ('OD US CORP', 'OD CA CORP')
                AND fdp_prior.period_counter    = p_fa_period_count - 1
                AND fdp_curr.period_counter     = p_fa_period_count
                AND fdp_next.period_counter     = p_fa_next_count
                AND fnd.application_short_name IN
                  (SELECT xftv.target_value1
                     FROM xx_fin_translatevalues xftv,
                          xx_fin_translatedefinition xftd
                    WHERE xftd.translate_id   = xftv.translate_id
                      AND xftd.translation_name = 'OD_AR_PERIOD_CHK_TRANSLTN'
                      AND xftv.target_value1    = 'OFA'
                      AND xftd.enabled_flag     = 'Y'
                      AND xftv.enabled_flag     = 'Y'
                  )
          )
        UNION
        SELECT prior_period_name
              ,current_period_name
              ,post_period_name
              ,application
              ,sob
              ,prior_period
              ,current_period
              ,next_period
         FROM
              (SELECT DISTINCT papl_prior.period_name PRIOR_PERIOD_NAME,
                      papl_curr.period_name CURRENT_PERIOD_NAME,
                      papl_next.period_name POST_PERIOD_NAME,
                      fnd.application_name aPPLICATION,
                      DECODE (papl_curr.org_id, 404, 'US_USD_P', 403, 'CA_CAD_P' ) SOB,
                      xx_closing_status (fnd.application_id, papl_prior.status ) PRIOR_PERIOD,
                      xx_closing_status (fnd.application_id, papl_curr.status ) CURRENT_PERIOD,
                      xx_closing_status (fnd.application_id, papl_next.status ) NEXT_PERIOD
                    FROM pa_periods_all papl_prior,
                      pa_periods_all papl_curr,
                      pa_periods_all papl_next,
                      fnd_application_vl fnd
                    WHERE papl_prior.period_name    = xx_pa_period_name ('PRIOR', p_date)
                    AND papl_curr.period_name       = xx_pa_period_name ('CURR', p_date)
                    AND papl_next.period_name       = xx_pa_period_name ('NEXT', p_date)
					AND papl_prior.ORG_ID = papl_curr.ORG_ID   --Added for defect# 24690 by Divya Sidhaiyan
					AND papl_prior.ORG_ID = papl_next.ORG_ID   --Added for defect# 24690 by Divya Sidhaiyan
                    AND fnd.application_short_name IN
                      (SELECT xftv.target_value1
                         FROM xx_fin_translatevalues xftv,
                             xx_fin_translatedefinition xftd
                        WHERE xftd.translate_id   = xftv.translate_id
                          AND xftd.translation_name = 'OD_AR_PERIOD_CHK_TRANSLTN'
                          AND xftv.target_value1    = 'PA'
                          AND xftd.enabled_flag     = 'Y'
                          AND xftv.enabled_flag     = 'Y'
                      )
              )
       -- Added for QC Defect # 23956 - End
      ORDER BY SOB,Application;

   ln_req_id           NUMBER;
   lc_error_loc        VARCHAR2(1000);
   lc_debug            VARCHAR2(1000);
   ld_run_date         DATE;
   ln_org_id           NUMBER;
   lc_org_name         HR_OPERATING_UNITS.name%TYPE;
   lc_email_subject    VARCHAR2(250) := 'Period Open Close Check Extract';
   ln_request_id       NUMBER        := FND_GLOBAL.CONC_REQUEST_ID;
   lc_email_address    VARCHAR2(240);
   lc_instance_name    VARCHAR2(30); -- Added for QC Defect # 23956
   ln_fa_period_count  NUMBER; -- Added for QC Defect # 23956
   ln_fa_next_count    NUMBER; -- Added for QC Defect # 23956
   lcu_gl_rec          lcu_gl_period_status%ROWTYPE;

   BEGIN

      ln_org_id   := FND_PROFILE.VALUE('ORG_ID');
      ld_run_date := TRUNC(FND_CONC_DATE.STRING_TO_DATE (p_run_date));

      FND_FILE.PUT_LINE (FND_FILE.LOG,'Inside Main Procedure for the run date:' || ld_run_date);

      BEGIN

         lc_error_loc  := 'Get the Operating Unit Name';
         lc_debug      := 'Org ID: '|| ln_org_id;

         SELECT SUBSTR(name,-2)
         INTO   lc_org_name
         FROM   hr_operating_units
         WHERE  organization_id = ln_org_id;

      EXCEPTION WHEN NO_DATA_FOUND THEN

         lc_org_name := NULL;
         FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found for the Org ID : '||ln_org_id);

      END;

      -- Added for QC Defect # 23956 - Start
      BEGIN

         lc_error_loc  := 'Get the Instance Name';
         lc_debug      := 'Date of Run: '|| ld_run_date;

         SELECT SYS_CONTEXT('USERENV','DB_NAME')
         INTO   lc_instance_name
         FROM   dual;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         lc_instance_name := NULL;
         FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found while getting the Instance Name : '||lc_instance_name);

         WHEN OTHERS THEN
         lc_instance_name := NULL;
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception while getting the Instance Name : '||lc_instance_name);

      END;
      lc_email_subject := lc_instance_name || ' ' || lc_email_subject;

      BEGIN

         lc_error_loc  := 'Get the FA Period Counter';
         lc_debug      := 'Date of Run: '|| ld_run_date;

         ln_fa_period_count := 0;
         ln_fa_next_count   := 0;

         SELECT DISTINCT fadp.period_counter
           INTO ln_fa_period_count
           FROM fa_deprn_periods fadp
          WHERE fadp.book_type_code IN ('OD US CORP','OD CA CORP')
            AND ld_run_date BETWEEN fadp.calendar_period_open_date AND fadp.calendar_period_close_date;

         BEGIN

             SELECT DISTINCT fadp.period_counter
               INTO ln_fa_next_count
               FROM fa_deprn_periods fadp
              WHERE fadp.book_type_code IN ('OD US CORP','OD CA CORP')
                AND fadp.period_counter = ln_fa_period_count + 1;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
            ln_fa_next_count := ln_fa_period_count;

            WHEN OTHERS THEN
            ln_fa_next_count := -1;

         END;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
         ln_fa_period_count := NULL;
         FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found while getting the FA Period Counter : '||ln_fa_period_count);

         WHEN OTHERS THEN
         ln_fa_period_count := NULL;
         FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception while getting the FA Period Counter : '||ln_fa_period_count);
      END;
      -- Added for QC Defect # 23956 - End

      BEGIN
         lc_error_loc  := 'Get the Email Addresses';
         lc_debug      := 'Date of Run: '|| ld_run_date;

         SELECT XFTV.target_value1
         INTO   lc_email_address
         FROM   xx_fin_translatevalues XFTV
               ,xx_fin_translatedefinition XFTD
         WHERE  XFTD.translate_id       = XFTV.translate_id
         AND    XFTD.translation_name   = 'OD_AR_PERIOD_CHK_TRANSLTN'
         AND    XFTV.source_value1      = 'EMAIL_ADDRESS'
         AND    XFTD.enabled_flag       = 'Y'
         AND    XFTV.enabled_flag       = 'Y';

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Email ID'||lc_email_address);
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
             lc_email_address := NULL;
             FND_FILE.PUT_LINE (FND_FILE.LOG,'No data found in Email Address for the run date: '||ld_run_date);
             RAISE;
         WHEN OTHERS THEN
             lc_email_address := NULL;
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Error @ Others - Email Address for the run date: '||ld_run_date);
             RAISE;
      END;

         OPEN  lcu_gl_period_status(ld_run_date, ln_fa_period_count, ln_fa_next_count); -- Added ln_fa_period_count and ln_fa_next_countfor QC Defect # 23956
         FETCH lcu_gl_period_status INTO lcu_gl_rec;
         CLOSE lcu_gl_period_status;

         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Office Depot',50,' ')||LPAD('Date : '||SYSDATE,52,' '));
        -- FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'Operating Unit Name : '||lc_org_name);
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,LPAD('Period Open Close Check Program',69,' '));
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         --FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Current Period Name :',25,' ')||LPAD(lcu_gl_rec.current_period_name,8,' ')); -- Commented for QC Defect # 23956
         --FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Date of Run         :',25,' ')||LPAD(TO_CHAR(TO_DATE(p_run_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-RR HH24:MI:SS'),20,' ')); -- Commented for QC Defect # 23956
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Current Period Name :',25,' ')|| lcu_gl_rec.current_period_name); -- Added for QC Defect # 23956
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Date of Run         :',25,' ')|| TO_CHAR(TO_DATE(p_run_date,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-RR HH24:MI:SS')); -- Added for QC Defect # 23956
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Instance            :',25,' ')|| lc_instance_name); -- Added for QC Defect # 23956
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('Application',20,' ')
                                          ||LPAD('SOB',13,' ')
                                          ||LPAD('Prior Period',23,' ')
                                          ||LPAD('Current Period',23,' ')
                                          ||LPAD('Next Period',23,' ')
                                          );
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD(' ',20,' ')
                                          ||LPAD(' ',13,' ')
                                          ||LPAD('('||lcu_gl_rec.prior_period_name||')',23,' ')
                                          ||LPAD('('||lcu_gl_rec.current_period_name||')',23,' ')
                                          ||LPAD('('||lcu_gl_rec.post_period_name||')',23,' ')
                                          );

         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD('-----------',20,' ')
                                          ||LPAD('---',13,' ')
                                          ||LPAD('------------',23,' ')
                                          ||LPAD('--------------',23,' ')
                                          ||LPAD('-----------',23,' ')
                                          );
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         lc_error_loc  := 'Calling LCU_GL_PERIOD_STATUS to print Data in Output File';
         lc_debug      := ' ';

         FOR lcu_count IN lcu_gl_period_status(ld_run_date, ln_fa_period_count, ln_fa_next_count) -- Added ln_fa_period_count and ln_fa_next_countfor QC Defect # 23956
         LOOP
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,RPAD(lcu_count.Application,20,' ')
                                          ||LPAD(lcu_count.SOB,13,' ')
                                          ||LPAD(lcu_count.Prior_Period,23,' ')
                                          ||LPAD(lcu_count.Current_Period,23,' ')
                                          ||LPAD(lcu_count.Next_Period,23,' ')
                                          );
         END LOOP;

         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE (FND_FILE.OUTPUT,LPAD('*** End Of Report - Period Open Close Check Program ***',82,' '));

         lc_error_loc  := 'Calling FND_REQUEST.SUBMIT_REQUEST for XXODROEMAILER';
         lc_debug      := ' ';

         ln_req_id :=  FND_REQUEST.SUBMIT_REQUEST ( 'XXFIN'
                                                   ,'XXODROEMAILER'
                                                   ,NULL
                                                   ,NULL
                                                   ,FALSE
                                                   ,'XXARPERIODCHK'
                                                   ,lc_email_address
                                                   ,lc_email_subject
                                                   ,NULL
                                                   ,'Y'
                                                   ,ln_request_id
                                                   );
         COMMIT;

         FND_FILE.PUT_LINE (FND_FILE.LOG,'Request ID of XXODROEMAILER :'||ln_req_id);

   EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error While : ' || lc_error_loc );
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Debug : ' || lc_debug || ' Error Msg : ' || SQLERRM );
      x_retcode :=2;
   END MAIN;

END XX_AR_PERIOD_STATUS_CHK_PKG;
