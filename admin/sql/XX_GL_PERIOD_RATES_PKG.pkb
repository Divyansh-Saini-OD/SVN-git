SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package Body XX_GL_PERIOD_RATES_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE BODY XX_GL_PERIOD_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        Exchange Rates Calculation Program                  |
-- | Rice ID:      I0105                                               |
-- | Description : To calculate average rates and ending rate for      |
-- |               the currencies.                                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date              Author              Remarks            |
-- |=======   ==========        ===============     ===================|
-- |1.0       10-JULY-2007      Samitha U M         Initial version    |
-- |1.1       09-OCT-2007       Samitha U M         Changes for defect |
-- |                                                 ID 2343           |
-- |1.2       24-OCT-2007       Samitha U M         Added to get  SOB  |
-- |                                                from Translation   |
-- |                                                OD_COUNTRY_DEFAULTS|
-- |1.3       24-FEB-2010       Subbu Pillai        R 1.2 Changes for  |
-- |                                                Defect 4272.       |
-- |1.4       31-AUG-2010       Bushrod Thomas      R 1.5 CR 759       |
-- |1.5       26-MAY-2011  Ritch Hartman            R11.3 CR912        |
-- | 1.6      16-JUL-2013      Gayathri              Defect#24312      |
-- |1.7       16-Sep-2013       Sheetal	            I2122 - R12 Upgrade|
-- |                                                changes.           |
-- |                                                Changed the logic  for End and Average rates as|
-- |                                                GL_TRANSLATION_RATES is now replaced in R12.   |
-- |1.8       06-Feb-2014       Deepak	            Corrected the version to include the retrofit changes done earlier.|
-- |1.9       18-Jun-2014       Veronica	        Modified for defects #30268 and #30025 :Calculation|
-- |                                                of end rates and N.A values + round off rates to 6 decimal places|
-- |2.0       17-Nov-15         Avinash Baddam      R12.2 Compliance Changes|
-- |2.1       12-Jan-15         Madhu Bolli        Removed the gl. for 122 retrofit GSCC changes|
-- |2.2       04-Apr-17         Paddy Sanjeevi     Modified for UK GBP Defect 41257 |
-- |2.3       01-AUG-2021       Rupali G           NAIT-190438- GDW Rate issue for JUL-21 |
-- +============================================================================+

-- +===================================================================+
-- | Name :  SUBMIT_CONCURRENT                                         |
-- | Description : Submits the standard concurrent program             |
-- |               to load the daily rates into GL_DAILY_RATES         |
-- | Returns :  Number                                                 |
-- +===================================================================+
   FUNCTION SUBMIT_GLDRICCP
   RETURN NUMBER AS
     lc_phase                    VARCHAR2(50);
     lc_status                   VARCHAR2(50);
     lc_devphase                 VARCHAR2(50);
     lc_devstatus                VARCHAR2(50);
     lc_message                  VARCHAR2(250);
     lb_req_status               BOOLEAN;
     ln_user_id                  NUMBER := NVL(fnd_global.user_id,-1);
     ln_resp_id                  NUMBER := NVL(fnd_global.resp_id,20434);
     ln_resp_appl_id             NUMBER := NVL(fnd_global.resp_appl_id,101);
     ln_request_id               fnd_concurrent_requests.request_id%TYPE;
   BEGIN
     FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);

     ln_request_id := FND_REQUEST.SUBMIT_REQUEST(application => 'SQLGL'
                                                ,program     => 'GLDRICCP'
                                                ,description => 'General Ledger Daily Rates Import and Calculation Concurrent Program'
                                                ,start_time  => NULL
                                                ,sub_request => FALSE);
     COMMIT;
        
     IF ln_request_id = 0   THEN
       FND_FILE.PUT_LINE (FND_FILE.LOG,'Error : Unable to submit Standard Daily Rates Import and Calculation Program ');
     ELSE
       FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitted request '|| TO_CHAR (ln_request_id)||' for Daily Rates Import');
       lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (request_id => ln_request_id
                                                        ,interval   => '10'
                                                        ,max_wait   => ''
                                                        ,phase      => lc_phase
                                                        ,status     => lc_status
                                                        ,dev_phase  => lc_devphase
                                                        ,dev_status => lc_devstatus
                                                        ,message    => lc_message);
       IF lc_devstatus='NORMAL' AND lc_devphase='COMPLETE' THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,' Daily Rates Import and Calculation Program completed normally');
         RETURN  0;
       ELSIF lc_devstatus='WARNING' AND lc_devphase='COMPLETE' THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,' Daily Rates Import and Calculation Program completed with Warning');
         RETURN  1;
       ELSIF lc_devstatus='ERROR' AND lc_devphase='COMPLETE' THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG,' Daily Rates Import and Calculation Program completed with Error');
         RETURN  2;
       END IF;
     END IF;
     
     EXCEPTION WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Exception Raised in the Function that calls the Standard Program' || SQLERRM);
   END SUBMIT_GLDRICCP;


-- +====================================================================+
-- | Name : LAST_CONVERSION_RATE                                        |
-- | Description : The function adds returns the last available rate of |
-- |               (of the requested type) that exists in               |
-- |               gl_daily_rates withing the specified conversion      |
-- |               date range.                                          |
-- | Parameters :  p_from_currency                                      |
-- |               p_to_currency                                        |
-- |               p_conversion_type                                    |
-- |               p_from_date                                          |
-- |               p_to_date                                            |
-- | Parameters :  x_error_buff, x_ret_code,p_rundate                   |
-- | Returns :     Returns rate                                         |
-- +====================================================================+
  FUNCTION LAST_CONVERSION_RATE (
      p_from_currency   IN VARCHAR2
     ,p_to_currency     IN VARCHAR2
     ,p_conversion_type IN VARCHAR2
     ,p_from_date       IN DATE
     ,p_to_date         IN DATE)
   RETURN NUMBER
   IS
     ln_conversion_rate NUMBER;
   BEGIN
      SELECT ROUND(conversion_rate,6)
        INTO ln_conversion_rate
        FROM GL_DAILY_RATES GDR
       WHERE from_currency=p_from_currency
         AND to_currency=p_to_currency
         AND conversion_type=p_conversion_type
         AND GDR.conversion_date = (SELECT MAX(conversion_date)
                                      FROM GL_DAILY_RATES
                                     WHERE from_currency=p_from_currency
                                       AND to_currency=p_to_currency
                                       AND conversion_type=p_conversion_type
                                       AND conversion_date BETWEEN p_from_date AND p_to_date);
      RETURN ln_conversion_rate;
   END LAST_CONVERSION_RATE;



-- +====================================================================+
-- | Name : GL_AVG_END_RATES                                            |
-- | Description : The procedure adds period cumulative average rates   |
-- |               TO and FROM USD in gl_daily_rates (via _interface),  |
-- |               and inserts the period average rate and ending rate  |
-- |               for CAD in gl_translation_rates                      |
-- | Parameters :  x_error_buff, x_ret_code,p_rundate                   |
-- | Returns :     Returns Code                                         |
-- |               Error Message                                        |
-- +====================================================================+
  PROCEDURE GL_AVG_END_RATES (x_error_buff OUT NOCOPY VARCHAR2
                             ,x_ret_code   OUT NOCOPY VARCHAR2
                             ,p_rundate    IN  VARCHAR2 := TO_CHAR(SYSDATE,'MM-DD-RRRR')
  ) AS
    ln_created_by              NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_updated_by         NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_login              NUMBER := NVL(FND_GLOBAL.login_id,-1);
    lc_error_msg               VARCHAR2(4000);
    ln_end_rate                NUMBER := 0;
    ln_avg_rate                NUMBER := 0;
    ln_daily_rates_int_count   NUMBER;
    --lc_set_of_books_id         GL_SETS_OF_BOOKS.set_of_books_id%TYPE; Commented as part of R12 Retrofit Changes
    lc_set_of_books_id         GL_LEDGERS.ledger_id%TYPE; --Added as part of R12 Retrofit Changes
    lc_period_name             VARCHAR2(10);
    lc_short_name              VARCHAR2(10);
    lc_status_code             VARCHAR(1)   := 'O';
    lc_usd_currency            VARCHAR2(10) := 'USD';
    lc_cad_currency            VARCHAR2(10) := 'CAD';
    lc_actual_flag             VARCHAR2(1)  := 'A';
    lc_mode_flag               VARCHAR2(1)  := 'I';
    lc_error_mode_flag         VARCHAR2(1)  := 'X';
    lc_update_flag             VARCHAR2(1)  := 'N';
    ln_status                  NUMBER;
    EX_USER_EXCEPTION          EXCEPTION;
    ld_rundate                 DATE := TO_DATE(p_rundate,'MM-DD-RRRR');
    ld_period_start_date       DATE;
    ld_period_end_date         DATE;
    lc_user_conv_type_end_rate GL_DAILY_RATES_INTERFACE.user_conversion_type%TYPE  := 'Ending Rate';
    lc_user_conv_type_avg_rate GL_DAILY_RATES_INTERFACE.user_conversion_type%TYPE  := 'Average Rate';
	lc_trans_conv_type_end_rate GL_DAILY_RATES_INTERFACE.user_conversion_type%TYPE  := 'Period End'; --Added as part of R12 Upgrade
    lc_trans_conv_type_avg_rate GL_DAILY_RATES_INTERFACE.user_conversion_type%TYPE  := 'Period Average'; --Added as part of R12 Upgrade
    lc_conv_type_end_rate      GL_DAILY_RATES.conversion_type%TYPE;
    lc_conv_type_avg_rate      GL_DAILY_RATES.conversion_type%TYPE;
    lc_Friday                  VARCHAR2(1) := to_char(to_date('20000107','RRRRMMDD'),'D');
    lc_Saturday                VARCHAR2(1) := to_char(to_date('20000101','RRRRMMDD'),'D');
    lc_Sunday                  VARCHAR2(1) := to_char(to_date('20000102','RRRRMMDD'),'D');

    -- Begin Defect 41257

    lc_short_name_gbp		     VARCHAR2(10);   -- Defect 41257
    ln_end_rate_gbp	          NUMBER :=0;
    ln_avg_rate_gbp		     NUMBER :=0;
    lc_gbp_currency            VARCHAR2(10) := 'GBP';  -- Defect 41257
    lc_set_of_books_id_gbp     GL_LEDGERS.ledger_id%TYPE; --Added as part of R12 Retrofit Changes  Defect 41257

    -- End Defect 41257

  BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'Rundate: "' || p_rundate || '"  ->  ' || ld_rundate );


       -- fetch working data (e.g., conversion type codes, period name and date range, etc.)
       BEGIN
          SELECT conversion_type INTO lc_conv_type_end_rate FROM gl_daily_conversion_types WHERE user_conversion_type=lc_user_conv_type_end_rate;
          SELECT conversion_type INTO lc_conv_type_avg_rate FROM gl_daily_conversion_types WHERE user_conversion_type=lc_user_conv_type_avg_rate;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the ending and average rate conversion types' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;

       BEGIN
          SELECT target_value1
          INTO   lc_short_name                    -- CA SOB name
          FROM   XX_FIN_TRANSLATEDEFINITION XFTD
                ,XX_FIN_TRANSLATEVALUES     XFTV
          WHERE  translation_name   = 'OD_COUNTRY_DEFAULTS'
          AND    XFTV.translate_id  = XFTD.translate_id
          AND    XFTV.source_value1 = 'CA'
          AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
          AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
          AND    XFTV.enabled_flag = 'Y'
          AND    XFTD.enabled_flag = 'Y';
       EXCEPTION 
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the value for CAD SOB: ' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;

       -- Begin Defect 41257
	
       BEGIN
          SELECT target_value1
          INTO   lc_short_name_gbp                    -- UK SOB name
          FROM   XX_FIN_TRANSLATEDEFINITION XFTD
                ,XX_FIN_TRANSLATEVALUES     XFTV
          WHERE  translation_name   = 'OD_COUNTRY_DEFAULTS'
          AND    XFTV.translate_id  = XFTD.translate_id
          AND    XFTV.source_value1 = 'UK'
          AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
          AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
          AND    XFTV.enabled_flag = 'Y'
          AND    XFTD.enabled_flag = 'Y';
       EXCEPTION 
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the value for GBP SOB: ' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;

       -- End Defect 41257

       BEGIN
          SELECT period_name, start_date, end_date
          INTO   lc_period_name, ld_period_start_date, ld_period_end_date
          FROM   GL_PERIODS
          WHERE  ld_rundate BETWEEN start_date AND end_date
          --AND    period_set_name = (SELECT period_set_name FROM GL_SETS_OF_BOOKS WHERE short_name = lc_short_name); Commented as part of R12 Changes
		      AND    period_set_name = (SELECT period_set_name FROM GL_LEDGERS WHERE short_name = lc_short_name); --Added as part of R12 Changes
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching period name, start, and end: ' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;

       BEGIN
          --SELECT set_of_books_id Commented as part of R12 Retrofit Changes
          SELECT ledger_id --Added as part of R12 Retrofit Changes
          INTO   lc_set_of_books_id
          --FROM   GL_SETS_OF_BOOKS Commented as part of R12 Changes
		  FROM GL_LEDGERS --Added as part of R12 Changes
          WHERE  currency_code = lc_cad_currency
          AND    short_name    = lc_short_name;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the set of books id for CAD: ' || SQLERRM);
          x_ret_code := 2;
          RETURN;
       END;
 
       -- Begin Defect 41257
       BEGIN
          SELECT ledger_id 
            INTO lc_set_of_books_id_gbp
   	       FROM GL_LEDGERS 
           WHERE currency_code = lc_gbp_currency
             AND short_name    = lc_short_name_gbp;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the set of books id for CAD: ' || SQLERRM);
          x_ret_code := 2;
          RETURN;
       END;

       -- End Defect 41257

       -- Clear errored daily ending rates from interface table (will be viewable in XPRTR)
       DELETE FROM GL_DAILY_RATES_INTERFACE WHERE mode_flag = lc_error_mode_flag;
       COMMIT;

       --Insert fiscal period cumulative average rates into interface table
       BEGIN
          FOR AVERAGE_DATES IN (SELECT conversion_date 
                                  FROM (SELECT ld_rundate+LEVEL-1 conversion_date
                                          FROM SYS.DUAL 
                                         CONNECT BY LEVEL <= (SELECT LEAST(TRUNC(SYSDATE),ld_period_end_date-1)-ld_rundate+1
                                                                FROM SYS.DUAL))
                                 WHERE to_char(conversion_date,'D') NOT IN (lc_Saturday, lc_Sunday)) LOOP --For each date that needs average rates inserted/updated (i.e., from rundate to lesser of current date and period end)

             INSERT INTO GL_DAILY_RATES_INTERFACE(from_currency
                                                 ,to_currency
                                                 ,from_conversion_date
                                                 ,to_conversion_date
                                                 ,user_conversion_type
                                                 ,conversion_rate
                                                 ,inverse_conversion_rate
                                                 ,mode_flag)
             SELECT   from_currency
                     ,lc_usd_currency to_currency
                     ,AVERAGE_DATES.conversion_date from_conversion_date
                     ,AVERAGE_DATES.conversion_date + (CASE WHEN TO_CHAR(AVERAGE_DATES.conversion_date,'D')=lc_Friday THEN (CASE WHEN AVERAGE_DATES.conversion_date=ld_period_end_date-1 THEN 1 ELSE 2 END)
                                                            ELSE 0 END) to_conversion_date -- for Fridays, extend rate over weekend except at period end when Sunday avg rates should be Friday end rates
                     ,lc_user_conv_type_avg_rate user_conversion_type
                     ,ROUND(SUM(GDR.conversion_rate)/COUNT(1),6) conversion_rate -- average of available weekday ending rates for to_currency from start of period to AVERAGE_DATES.conversion_date
                     ,ROUND(1/ROUND(SUM(GDR.conversion_rate)/COUNT(1),6),6) inverse_conversion_rate
                     ,lc_mode_flag mode_flag
             FROM     GL_DAILY_RATES GDR
             WHERE    GDR.conversion_date BETWEEN ld_period_start_date AND AVERAGE_DATES.conversion_date
             AND      GDR.conversion_type = lc_conv_type_end_rate
             AND      GDR.from_currency  <> lc_usd_currency
             AND      GDR.to_currency     = lc_usd_currency
             AND      TO_CHAR(GDR.conversion_date,'D') NOT IN (lc_Saturday, lc_Sunday)
             GROUP BY from_currency;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of average rate records inserted for ' || TO_CHAR(AVERAGE_DATES.conversion_date,'DD-MON-RRRR') || ' : ' || SQL%ROWCOUNT);

          END LOOP;


          IF ld_rundate = ld_period_end_date-1 THEN -- insert Friday end rate as Sunday avg at end of period
             INSERT INTO GL_DAILY_RATES_INTERFACE(from_currency
                                                 ,to_currency
                                                 ,from_conversion_date
                                                 ,to_conversion_date
                                                 ,user_conversion_type
                                                 ,conversion_rate
                                                 ,inverse_conversion_rate
                                                 ,mode_flag)
             SELECT   lc_usd_currency from_currency
                     ,RATES_FROM_USD.to_currency to_currency
                     ,ld_rundate+2 from_conversion_date -- Sunday
                     ,ld_rundate+2 to_conversion_date
                     ,lc_user_conv_type_avg_rate user_conversion_type
                     --,RATES_FROM_USD.conversion_rate conversion_rate              --Commented/Added for defect #30268
                     --,RATES_TO_USD.conversion_rate inverse_conversion_rate        --Commented/Added for defect #30268	
                     ,ROUND(RATES_FROM_USD.conversion_rate,6) conversion_rate    
                     ,ROUND(RATES_TO_USD.conversion_rate,6) inverse_conversion_rate				 
                     ,lc_mode_flag mode_flag
             FROM    (SELECT to_currency,conversion_rate FROM GL_DAILY_RATES WHERE from_currency=lc_usd_currency AND conversion_date=ld_rundate AND conversion_type=lc_conv_type_end_rate) RATES_FROM_USD
             JOIN    (SELECT from_currency,conversion_rate FROM GL_DAILY_RATES WHERE to_currency=lc_usd_currency AND conversion_date=ld_rundate AND conversion_type=lc_conv_type_end_rate) RATES_TO_USD
               ON     RATES_FROM_USD.to_currency=RATES_TO_USD.from_currency;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of average rate records equaling end rate of previous period final Friday inserted for first Sunday of new period : ' || SQL%ROWCOUNT);
          END IF;

          COMMIT;

       EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting average rates for US SOB into interface table: ' || SQLERRM);
          FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0002_AVERAGE_RATE');
          lc_error_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_error_msg || ': ' || SQLERRM);
          XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type            => 'GL Daily Rates Calculation'
                                         ,p_program_name            => 'GLDRICCP'
                                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                         ,p_module_name             => 'GL'
                                         ,p_error_location          => 'Exception : Average Rate : USD'
                                         ,p_error_message_count     => 1
                                         ,p_error_message_code      => 'E'
                                         ,p_error_message           => lc_error_msg
                                         ,p_error_message_severity  => 'Major'
                                         ,p_notify_flag             => 'N'
                                         ,p_object_type             => 'GL_Exchange_Rate');
       END;
 --Added as part of Defect #30268
	BEGIN
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting the request for standard daily rates import and calculation program for cumulative average rate');
          ln_status := XX_GL_PERIOD_RATES_PKG.SUBMIT_GLDRICCP;
          IF ln_status=0 THEN 
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with normal status ');
          ELSIF ln_status=1 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with warning status');
             RAISE EX_USER_EXCEPTION;
          ELSIF ln_status=2 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with error status');
             RAISE EX_USER_EXCEPTION;
          END IF;
       EXCEPTION
          WHEN EX_USER_EXCEPTION THEN
             x_ret_code := ln_status;
             RETURN;
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting standard concurrent program: ' || SQLERRM);
             x_ret_code := 2;
             RETURN;
       END;
-- End of Addition for Defect #30268
	/* Commented as part of R12 Upgrade Changes on 16-Sep-2013 by Sheetal
       -- Call standard import program to load (i.e., insert or update) daily cumulative average rates from gl_daily_rates_interface into gl_daily_rates
       BEGIN
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting the request for standard daily rates import and calculation program for cumulative average rate');
          ln_status := XX_GL_PERIOD_RATES_PKG.SUBMIT_GLDRICCP;
          IF ln_status=0 THEN 
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with normal status ');
          ELSIF ln_status=1 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with warning status');
             RAISE EX_USER_EXCEPTION;
          ELSIF ln_status=2 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with error status');
             RAISE EX_USER_EXCEPTION;
          END IF;
       EXCEPTION
          WHEN EX_USER_EXCEPTION THEN
             x_ret_code := ln_status;
             RETURN;
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting standard concurrent program: ' || SQLERRM);
             x_ret_code := 2;
             RETURN;
       END;
	End of Comment on 16-Sep-2013 by Sheetal*/
	   
       -- Insert/update period average and period ending rates for CAD SOB to USD
       BEGIN
          ln_end_rate := LAST_CONVERSION_RATE(lc_cad_currency,lc_usd_currency,lc_conv_type_end_rate,ld_period_start_date,ld_period_end_date);
          ln_avg_rate := LAST_CONVERSION_RATE(lc_cad_currency,lc_usd_currency,lc_conv_type_avg_rate,ld_period_start_date,ld_period_end_date);
		  
       EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the period end/avg conversion rates: '|| SQLERRM );
          x_ret_code := 2;
          RETURN;
       END;

       -- Begin Defect 41257

       BEGIN
          ln_end_rate_gbp := LAST_CONVERSION_RATE(lc_gbp_currency,lc_usd_currency,lc_conv_type_end_rate,ld_period_start_date,ld_period_end_date);
          ln_avg_rate_gbp := LAST_CONVERSION_RATE(lc_gbp_currency,lc_usd_currency,lc_conv_type_avg_rate,ld_period_start_date,ld_period_end_date);
		  
       EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the period end/avg conversion rates: '|| SQLERRM );
          x_ret_code := 2;
          RETURN;
       END;

       -- End Defect 41257

       BEGIN
         /* Commented as part of R12 Upgrade on 16-Sep-2013 by Sheetal
		 UPDATE GL_TRANSLATION_RATES
          SET    set_of_books_id      = lc_set_of_books_id
                ,period_name          = lc_period_name
                ,to_currency_code     = lc_usd_currency
                ,actual_flag          = lc_actual_flag
                ,avg_rate             = ln_avg_rate
                ,eop_rate_numerator   = ln_end_rate
                ,eop_rate_denominator = 1
                ,avg_rate_numerator   = ln_avg_rate
                ,avg_rate_denominator = 1
                ,eop_rate             = ln_end_rate
                ,update_flag          = lc_update_flag
                ,last_update_date     = SYSDATE
                ,last_updated_by      = ln_last_login
          WHERE period_name           = lc_period_name
          AND   set_of_books_id       = lc_set_of_books_id
          AND   to_currency_code      = lc_usd_currency
          AND   actual_flag           = lc_actual_flag;
		 
          IF SQL%NOTFOUND THEN
             INSERT INTO GL_TRANSLATION_RATES(set_of_books_id
                                             ,period_name
                                             ,to_currency_code
                                             ,actual_flag
                                             ,avg_rate
                                             ,eop_rate_numerator
                                             ,eop_rate_denominator
                                             ,avg_rate_numerator
                                             ,avg_rate_denominator
                                             ,eop_rate
                                             ,update_flag
                                             ,last_update_date
                                             ,last_updated_by)
             VALUES (lc_set_of_books_id
                    ,lc_period_name
                    ,lc_usd_currency
                    ,lc_actual_flag
                    ,ln_avg_rate
                    ,ln_end_rate
                    ,1
                    ,ln_avg_rate
                    ,1
                    ,ln_end_rate
                    ,lc_update_flag
                    ,SYSDATE
                    ,ln_last_updated_by);
                 End of Comment on 16-Sep-2013 by Sheetal */

			--Added as part of R12 Upgrade on 16-Sep-2013 by Sheetal	
			--Insertion for Average Rates
			INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
                , inverse_conversion_rate   --Added for defect #30268
				, mode_flag 
				, user_id)
			VALUES
				(lc_cad_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_avg_rate
				, ln_avg_rate
				, ROUND(1/ln_avg_rate,6)    --Added for defect #30268  
				, lc_mode_flag
				, ln_created_by 
				); 
				--End of Insert Statement Added

				--Insertion for Ending Rates
				INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
                , inverse_conversion_rate   --Added for defect #30268
				, mode_flag) 
			VALUES
				(lc_cad_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_end_rate
				, ln_end_rate
				, ROUND(1/ln_end_rate,6)    --Added for defect #30268  
				, lc_mode_flag
				);
				--End of Insert Statement Added on 16-Sep-2013 by Sheetal

          --END IF; Commented as part of R12 Upgrade on 16-Sep-2013 by Sheetal
       EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting Average/Ending Rates for CAD SOB into GL_TRANSLATION_RATES: ' || SQLERRM);
          FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0003_PERIOD_RATES');
          lc_error_msg := FND_MESSAGE.GET;
          FND_FILE.PUT_LINE(FND_FILE.LOG, lc_error_msg || ': ' || SQLERRM);
          XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type           => 'GL Daily Rates Calculation'
                                        ,p_program_name           => 'GLDRICCP'
                                        ,p_program_id             => FND_GLOBAL.CONC_PROGRAM_ID
                                        ,p_module_name            => 'GL'
                                        ,p_error_location         => 'Exception : Averge Rate/Ending Rate  : CAD'
                                        ,p_error_message_count    => 1
                                        ,p_error_message_code     => 'E'
                                        ,p_error_message          => lc_error_msg
                                        ,p_error_message_severity => 'Major'
                                        ,p_notify_flag            => 'N'
                                        ,p_object_type            => 'GL_Exchange_Rate');
          x_ret_code := 2;
          RETURN;                                        
       END;
	
       -- Begin Defect 41257

	  BEGIN
			--Insertion for Average Rates
			INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
	                , inverse_conversion_rate  
				, mode_flag 
				, user_id)
			VALUES
				( lc_gbp_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_avg_rate
				, ln_avg_rate_gbp
				, ROUND(1/ln_avg_rate_gbp,6)    
				, lc_mode_flag
				, ln_created_by 
				); 
				--End of Insert Statement Added

				--Insertion for Ending Rates
				INSERT INTO GL_DAILY_RATES_INTERFACE
				( from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
                     , inverse_conversion_rate  
				, mode_flag) 
			VALUES
				( lc_gbp_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_end_rate
				, ln_end_rate_gbp
				, ROUND(1/ln_end_rate_gbp,6)    
				, lc_mode_flag
				);

       EXCEPTION 
	    WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting Average/Ending Rates for GBP SOB into GL_TRANSLATION_RATES: ' || SQLERRM);
         FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0003_PERIOD_RATES');
         lc_error_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE(FND_FILE.LOG, lc_error_msg || ': ' || SQLERRM);
         XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type           => 'GL Daily Rates Calculation'
                                        ,p_program_name           => 'GLDRICCP'
                                        ,p_program_id             => FND_GLOBAL.CONC_PROGRAM_ID
                                        ,p_module_name            => 'GL'
                                        ,p_error_location         => 'Exception : Averge Rate/Ending Rate  : GBP'
                                        ,p_error_message_count    => 1
                                        ,p_error_message_code     => 'E'
                                        ,p_error_message          => lc_error_msg
                                        ,p_error_message_severity => 'Major'
                                        ,p_notify_flag            => 'N'
                                        ,p_object_type            => 'GL_Exchange_Rate');
          x_ret_code := 2;
          RETURN;                                        
	  END;
       COMMIT;
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'AVERAGE RATE and ENDING RATE for CAD SOB updated successfully');

       -- End Defect 41257

       IF ld_rundate = ld_period_end_date-1 THEN -- Roll rates forward to next period for defect 8694
         BEGIN
           SELECT period_name
			 ,start_date --Added part of R12 Upgrade Change
			 ,end_date --Added part of R12 Upgrade Change
             INTO lc_period_name 
			 ,ld_period_start_date --Added part of R12 Upgrade Change
			 ,ld_period_end_date --Added part of R12 Upgrade Change
             FROM GL_PERIODS
            WHERE ld_rundate+3 BETWEEN start_date AND end_date
          --AND  period_set_name = (SELECT period_set_name
	     --					      FROM GL_SETS_OF_BOOKS 
		--					WHERE short_name = lc_short_name); Commented as part of R12 Retrofit Changes
		   AND period_set_name = (SELECT period_set_name 
							 FROM GL_LEDGERS 
                                     WHERE short_name = lc_short_name
						    ); --Added as part of R12 Retrofit Changes
         EXCEPTION
           WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching next period name: ' || SQLERRM);
           x_ret_code := 2;
           RETURN;
         END;

         BEGIN
		 /* Commented as part of R12 Upgrade
           INSERT INTO GL_TRANSLATION_RATES(set_of_books_id
                                           ,period_name
                                           ,to_currency_code
                                           ,actual_flag
                                           ,avg_rate
                                           ,eop_rate_numerator
                                           ,eop_rate_denominator
                                           ,avg_rate_numerator
                                           ,avg_rate_denominator
                                           ,eop_rate
                                           ,update_flag
                                           ,last_update_date
                                           ,last_updated_by)
           VALUES (lc_set_of_books_id
                  ,lc_period_name
                  ,lc_usd_currency
                  ,lc_actual_flag
                  ,ln_end_rate -- period avg of next period == end rate of last period
                  ,ln_end_rate
                  ,1
                  ,ln_end_rate -- period avg of next period == end rate of last period
                  ,1
                  ,ln_end_rate
                  ,lc_update_flag
                  ,SYSDATE
                  ,ln_last_updated_by);
               End of Comment*/

			--Added as part of R12 Upgrade on 16-Sep-2013 by Sheetal
			--Insertion for Period End Rates
			INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate
                , inverse_conversion_rate   --Added for defect #30268				
				, mode_flag 
				)
			VALUES
				(lc_cad_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_avg_rate
				, ln_avg_rate
				, ROUND(1/ln_avg_rate,6)    --Added for defect #30268 
				, lc_mode_flag
				); 
			--End of Insert Statement Added

			--Added as part of R12 Upgrade Change
			--Insertion for Period Average Rates
				INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
                , inverse_conversion_rate   --Added for defect #30268	
				, mode_flag) 
			VALUES
				(lc_cad_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_end_rate
				, ln_end_rate
				, ROUND(1/ln_end_rate,6)    --Added for defect #30268 
				, lc_mode_flag
				);
				--End of Insert Statement Added on 16-Sep-2013 by Sheetal
          COMMIT;
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'AVERAGE RATE and ENDING RATE for CAD SOB successfully inserted for next period (' || lc_period_name || ')');

         EXCEPTION WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Next period (' || lc_period_name || ') ending/average rates already exist in GL_TRANSLATION_RATES'); -- Not a problem
         END;

	   -- Begin Defect 41257
	    BEGIN
		 --Insertion for Period Average Rates
		 INSERT 
		   INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate
                     , inverse_conversion_rate   
				, mode_flag 
				)
		 VALUES
				( lc_gbp_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_avg_rate
				, ln_avg_rate_gbp
				, ROUND(1/ln_avg_rate_gbp,6)    
				, lc_mode_flag
				); 
			--End of Insert Statement Added

			--Insertion for Period End Rates
				INSERT INTO GL_DAILY_RATES_INTERFACE
				(from_currency 
				, to_currency 
				, from_conversion_date 
				, to_conversion_date 
				, user_conversion_type 
				, conversion_rate 
                     , inverse_conversion_rate   
				, mode_flag) 
			VALUES
				( lc_gbp_currency
				, lc_usd_currency
				, ld_period_end_date
				, ld_period_end_date
				, lc_trans_conv_type_end_rate
				, ln_end_rate_gbp
				, ROUND(1/ln_end_rate_gbp,6)    
				, lc_mode_flag
				);
            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'AVG RATE and ENDING RATE for GBP SOB successfully inserted for next period (' || lc_period_name ||')'); 
	  EXCEPTION
	    WHEN others THEN
	      FND_FILE.PUT_LINE(FND_FILE.LOG,'Next period (' || lc_period_name || ') ending/average rates already exist in GL_TRANSLATION_RATES'); 
	  END;

       END IF;

 --Added as part of R12 Upgrade Changes
	BEGIN
          FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting the request for standard daily rates import and calculation program for cumulative average rate');
          ln_status := XX_GL_PERIOD_RATES_PKG.SUBMIT_GLDRICCP;
          IF ln_status=0 THEN 
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with normal status ');
          ELSIF ln_status=1 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with warning status');
             RAISE EX_USER_EXCEPTION;
          ELSIF ln_status=2 THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The standard concurrent program inserting the daily fiscal period cumulative average rates for USD SOB completed with error status');
             RAISE EX_USER_EXCEPTION;
          END IF;
       EXCEPTION
          WHEN EX_USER_EXCEPTION THEN
             x_ret_code := ln_status;
             RETURN;
          WHEN OTHERS THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while submitting standard concurrent program: ' || SQLERRM);
             x_ret_code := 2;
             RETURN;
       END;
-- End of Addition

  EXCEPTION WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised in Main Procedure GL_AVG_END_RATES'|| SQLERRM );
       FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0004_PERIOD_RATES');
       lc_error_msg := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG, lc_error_msg || ': ' || SQLERRM);
       XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type           => 'XX GL Daily Rates Calculation'
                                     ,p_program_name           => 'XXGLDAILYRATES'
                                     ,p_program_id             => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name            => 'GL'
                                     ,p_error_location         => 'Exception : Main Procedure Exception'
                                     ,p_error_message_count    => 1
                                     ,p_error_message_code     => 'E'
                                     ,p_error_message          => lc_error_msg
                                     ,p_error_message_severity => 'Major'
                                     ,p_notify_flag            => 'N'
                                     ,p_object_type            => 'GL_Exchange_Rate');
       x_ret_code := 2;
  END GL_AVG_END_RATES;
  
  
PROCEDURE GL_FX_RATES_FORMULA (x_error_buff OUT NOCOPY VARCHAR2
                             ,x_ret_code   OUT NOCOPY VARCHAR2
                             ,p_period_year    IN  VARCHAR2
                             ,p_rate_type  IN  VARCHAR2
  ) AS
    ln_created_by              NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_updated_by         NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_login              NUMBER := NVL(FND_GLOBAL.login_id,-1);
    lc_error_msg               VARCHAR2(4000);
    --ld_rundate                 DATE := TO_DATE(p_rundate,'MM-DD-RRRR');
    ld_period_year             DATE := TO_DATE(p_period_year,'RRRR');
    lc_conv_type_rate          GL_DAILY_RATES.conversion_type%TYPE;
    lc_conv_rate_prev          GL_DAILY_RATES.conversion_rate%TYPE;
    ld_conv_date_prev          GL_DAILY_RATES.conversion_date%TYPE;
    lc_value1                  VARCHAR2(240);
    lc_value2                  VARCHAR2(50);
    lc_value3                  VARCHAR2(50);
    lc_value4                  VARCHAR2(50);
    lc_value5                  VARCHAR2(50);
    lc_value6                  VARCHAR2(50);
    lc_value7                  VARCHAR2(50);
    lc_value8                  VARCHAR2(50);
    lc_value9                  VARCHAR2(50);
    lc_value10                 VARCHAR2(50);
    lc_value11                 VARCHAR2(50);
    lc_value12                 VARCHAR2(50);
    lc_rate_type               VARCHAR2(100) := replace(p_rate_type,'_',' ');
    ln_conversion_rate         NUMBER;
    ln_inverse_conversion_rate NUMBER;
    lc_beg_cal                 VARCHAR2(50) := ('01-JAN-' || p_period_year);
    lc_end_cal                 VARCHAR2(50) := ('01-DEC-' || p_period_year);
    ld_beg_cal                 DATE := TO_DATE(lc_beg_cal, 'DD-MON-YYYY');
    ld_end_cal                 DATE := TO_DATE(lc_end_cal, 'DD-MON-YYYY');
    lc_insert_flag             NUMBER:=0;  -- Added for defect #30025 START
    lc_new1 VARCHAR2(50);
    lc_new2 VARCHAR2(50);
    lc_new3 VARCHAR2(50);
    lc_new4 NUMBER;
    lc_new5 NUMBER;
    lc_new6 GL_DAILY_RATES.conversion_date%TYPE;  -- Added for defect #30025 END
    
    cursor c_name is 
    select to_currency as value1, conversion_date as value2, attribute9 as value3 from gl_daily_rates where conversion_type = lc_conv_type_rate and conversion_rate = 1 and from_currency  = 'USD'
    order by to_currency, conversion_date;
    /*
    SELECT distinct XFTV.source_value1 as value1,XFTV.source_value2 as value2 , fx1.conversion_rate as value3, XFTV.source_value3 as value4, fx2.conversion_rate as value5 ,XFTV.source_value4 as value6,XFTV.source_value5 as value7, XFTV.source_value6  as value8, fx2.conversion_rate as value9
          FROM   XX_FIN_TRANSLATEDEFINITION XFTD
                ,XX_FIN_TRANSLATEVALUES     XFTV
                ,gl_daily_rates             FX1
                ,gl_daily_rates             FX2
                ,gl_daily_rates             FX3
          WHERE  translation_name   = 'XX_GL_FX_RATES_FORMULA'
          AND    XFTV.translate_id  = XFTD.translate_id
          AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
          AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
          AND    XFTV.enabled_flag = 'Y'
          AND    XFTD.enabled_flag = 'Y'
          AND   fx1.conversion_type = lc_conv_type_rate
          and    xftv.source_value2 = trim(fx1.attribute9) 
          --and   fx1.conversion_date BETWEEN ld_beg_cal AND ld_end_cal 
          AND   fx2.conversion_type = lc_conv_type_rate
          and    xftv.source_value3 = trim(fx2.attribute9) 
          --and   fx2.conversion_date BETWEEN ld_beg_cal AND ld_end_cal
           AND   fx3.conversion_type = lc_conv_type_rate
          and    xftv.source_value6 = trim(fx3.attribute9)     
          --and   fx3.conversion_date BETWEEN ld_beg_cal AND ld_end_cal
          and   fx1.from_currency = 'USD'
          and   fx2.from_currency = 'USD'
          and   fx3.from_currency = 'USD'
           and exists (select 1 from gl_daily_rates fx  where 1 = 1 
          and fx.conversion_rate = 1 and trim(fx.attribute9) = xftv.source_value1
          and fx.conversion_type = lc_conv_type_rate); --and fx.conversion_date between ld_beg_cal AND ld_end_cal);
        /*  
       cursor d_name is
       select FROM_CURRENCY, CONVERSION_DATE, conversion_rate  
              from gl_daily_rates 
              where conversion_type = lc_conv_type_rate
              and conversion_rate = 1
              and conversion_date between ld_beg_cal AND ld_end_cal;
        */
  BEGIN
    
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Beg Date: ' || lc_beg_cal );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'End Date: ' || lc_end_cal );

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Rate Type: ' || lc_rate_type );

       -- fetch working data (e.g., conversion type codes, period name and date range, etc.)
       BEGIN
          SELECT conversion_type INTO lc_conv_type_rate FROM gl_daily_conversion_types WHERE user_conversion_type=lc_rate_type;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the rate conversion types' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Conversion Type: ' || lc_conv_type_rate );

       
        --Insert currency values required to use business formula into interface table
       BEGIN
       for r_name in c_name loop
       lc_value1 := r_name.value1;
       lc_value2 := r_name.value2;
       lc_value3 := r_name.value3;
       --lc_value4 := r_name.value4;
       
       
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Values: ' ||'lc_value1: ' || lc_value1 || 'lc_value2: ' || lc_value2 ); 
      FND_FILE.PUT_LINE(FND_FILE.LOG,'SQL Count is: ' || SQL%ROWCOUNT);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'9 Value: ' ||'lc_value3: ' || lc_value3);
      
      BEGIN
      --business provided formula to calculate N.A. values from Bloomberg.  Stored in table with a value of 1 until computed.
      --ln_conversion_rate := ROUND((((lc_value3 - lc_value5) / lc_value6 * lc_value7 )) + lc_value9,6);
      --calculate inverse value
      --ln_inverse_conversion_rate := ROUND(1/ROUND((((lc_value3 - lc_value5) / lc_value6 * lc_value7 )) + lc_value9,6),6);
      
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'conversion_rate: ' || ln_conversion_rate);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'inverse_conversion_rate: ' || ln_inverse_conversion_rate);
      
      --if a 12M lookback for a valid rate
      IF lc_value3 = '12M' THEN
      
    BEGIN
      SELECT gdr.conversion_rate, gdr.conversion_date into lc_conv_rate_prev, ld_conv_date_prev FROM GL_DAILY_RATES gdr  WHERE to_currency = lc_value1 AND gdr.conversion_type = lc_conv_type_rate
      AND  gdr.from_currency  = 'USD' and conversion_rate <> 1 and conversion_date < lc_value2
      and rownum = 1
      order by conversion_date desc;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the previous rate for 12M' || SQLERRM);   
          lc_insert_flag := 1; --Added for defect #30025, flag set to 1 when there is no data to insert	  
       END;
       IF lc_insert_flag = 0 --Added for defect #30025 
	   THEN
        INSERT INTO GL_DAILY_RATES_INTERFACE(from_currency
                                                 ,to_currency
                                                 ,from_conversion_date
                                                 ,to_conversion_date
                                                 ,user_conversion_type
                                                 ,conversion_rate
                                                 ,inverse_conversion_rate
                                                 ,mode_flag
                                                 ,CONTEXT
                                                 ,attribute6
                                                 ,attribute10)
                (SELECT gdr.from_currency from_currency
                     ,gdr.to_currency to_currency
                     ,lc_value2
                     ,lc_value2
                     ,lc_rate_type user_conversion_type
                     --,lc_conv_rate_prev conversion_rate
                     ,ROUND(lc_conv_rate_prev,6) conversion_rate    --Added/Commented for Defect #30268 					 
                     ,ROUND(1/lc_conv_rate_prev,6) inverse_conversion_rate
                     ,'I' mode_flag
                     ,'Bloomberg Value'
                     ,'N.A.'
                     ,ld_conv_date_prev
                FROM GL_DAILY_RATES gdr  WHERE to_currency = lc_value1 AND gdr.conversion_type = lc_conv_type_rate 
                AND  gdr.from_currency  = 'USD' and conversion_date = lc_value2);
        ELSE   
			FND_FILE.PUT_LINE(FND_FILE.LOG,'insert failed for to_currency: '||lc_value1||' and conversion date: '||LC_VALUE2 );
        END IF;
      ELSE
      --else look forward for a valid rate
	  --Added for defect #30025 START
	  lc_insert_flag := 0;
			BEGIN
			SELECT gdr.from_currency from_currency
                     ,gdr.to_currency to_currency
                     ,lc_rate_type user_conversion_type
                     ,gdr.conversion_rate conversion_rate 
                     ,ROUND(1/gdr.conversion_rate,6) inverse_conversion_rate
                     ,gdr.conversion_date
					 into lc_new1,lc_new2,lc_new3,lc_new4,lc_new5,lc_new6               
					 FROM GL_DAILY_RATES gdr  WHERE to_currency = lc_value1 AND gdr.conversion_type = lc_conv_type_rate 
                AND  gdr.from_currency  = 'USD' and conversion_rate <> 1 and conversion_date > lc_value2 AND rownum = 1;
			EXCEPTION
			 WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the previous rate for to_currency :'||lc_value1 ||' conversion_date: '||lc_value2|| SQLERRM); 
            lc_insert_flag := 1;
			  END;
			IF lc_insert_flag = 0
			THEN  
	  --Added for defect #30025 END			
            INSERT INTO GL_DAILY_RATES_INTERFACE(from_currency
                                                 ,to_currency
                                                 ,from_conversion_date
                                                 ,to_conversion_date
                                                 ,user_conversion_type
                                                 ,conversion_rate
                                                 ,inverse_conversion_rate
                                                 ,mode_flag
                                                 ,CONTEXT
                                                 ,attribute6
                                                 ,attribute10)
                (SELECT gdr.from_currency from_currency
                     ,gdr.to_currency to_currency
                     ,lc_value2
                     ,lc_value2
                     ,lc_rate_type user_conversion_type
                     --,gdr.conversion_rate conversion_rate   
                     ,ROUND(gdr.conversion_rate,6) conversion_rate	  --Added/Commented for Defect #30268 				 
                     ,ROUND(1/gdr.conversion_rate,6) inverse_conversion_rate
                     ,'I' mode_flag
                     ,'Bloomberg Value'
                     ,'N.A.'
                     ,gdr.conversion_date
                FROM GL_DAILY_RATES gdr  WHERE to_currency = lc_value1 AND gdr.conversion_type = lc_conv_type_rate 
                AND  gdr.from_currency  = 'USD' and conversion_rate <> 1 and conversion_date > lc_value2 and rownum = 1);
	  --Added for defect #30025 START
               ELSE
          FND_FILE.PUT_LINE(FND_FILE.LOG,'insert failed for to_currency: '||lc_value1||' and conversion date: '||LC_VALUE2 );  
            END IF;
	  --Added for defect #30025 END
            END IF; 
            
            EXCEPTION
           WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting into staging table: ' || SQLERRM);
           x_ret_code := 2;
           RETURN;
          END;

        lc_insert_flag := 0;   

          END LOOP;
        
    COMMIT;

       EXCEPTION WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting rates into interface: ' || SQLERRM);
        

       END;
       
     
END GL_FX_RATES_FORMULA;

-- +===================================================================+
-- | Name :  GL_FX_RATES_AVG                                           |
-- | Description:This procedure fetches currency values for OD Forecast|
-- |          ,OD Board Forecast, OD Internal Plan, OD Board Plan      |
-- |          calculates avgerage, and inserts with an Avg rate type   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : x_error_buff, x_ret_code,p_rundate,p_rate_type       |
-- | Returns :    Returns Code                                         |
-- |              Error Message                                        |
-- +===================================================================+
   PROCEDURE GL_FX_RATES_AVG(
      x_error_buff  OUT NOCOPY VARCHAR2
     ,x_ret_code    OUT NOCOPY VARCHAR2
     ,p_period_year     IN  VARCHAR2
     ,p_rate_type   IN  VARCHAR2
   )
   AS
    ln_created_by              NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_updated_by         NUMBER := NVL(FND_GLOBAL.user_id,-1);
    ln_last_login              NUMBER := NVL(FND_GLOBAL.login_id,-1);
    lc_error_msg               VARCHAR2(4000);
    lc_min_period              VARCHAR2(50);
    lc_max_period              VARCHAR2(50);
    lc_rate_type               VARCHAR2(100) := replace(p_rate_type,'_',' ');
    lc_conv_type_rate          GL_DAILY_RATES.conversion_type%TYPE;
    lc_beg_cal                 VARCHAR2(50);
    lc_end_cal                 VARCHAR2(50);
    ld_beg_cal                 DATE;
    ld_end_cal                 DATE;
    lc_to_currency             VARCHAR2(50);
    ld_conversion_date         DATE;
    
     cursor c_name is select to_currency as value1, conversion_date as value2
                              from gl_daily_rates 
                              where conversion_type = lc_conv_type_rate 
                              and to_currency <> 'USD'
                            and conversion_date between ld_beg_cal and ld_end_cal order by to_currency, conversion_date;
    
  BEGIN
  
    BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Rate Type: ' || lc_rate_type );
          SELECT conversion_type INTO lc_conv_type_rate FROM gl_daily_conversion_types WHERE user_conversion_type=lc_rate_type;
       EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the rate conversion types' || SQLERRM);
          x_ret_code := 2;
          RETURN;          
       END;
  
    BEGIN
    SELECT  b.period_name as min_period, c.period_name as max_period
    into  lc_min_period, lc_max_period
    FROM  gl_periods b, gl_periods c,
    (Select period_year, min(period_num) min_period, max(period_num) max_period from gl_periods where end_date >= trunc(sysdate) group by period_year) x
    WHERE  b.period_year = p_period_year
    and b.period_year = x.period_year
    and b.end_date >= trunc(sysdate)
    and b.period_num = x.min_period
    and c.period_year = p_period_year
    and c.period_year = x.period_year
    and c.end_date >= trunc(sysdate)
    and c.period_num = x.max_period;
    
      --concat returned values to make beg cal date
         lc_beg_cal :=  ('01-' || lc_min_period);
         lc_end_cal :=  ('01-' || lc_max_period);
         --convert to date
        ld_beg_cal     := TO_CHAR(TO_DATE(lc_beg_cal, 'DD-MON-YY'),'DD-MON-YYYY');
        ld_end_cal     := TO_CHAR(TO_DATE(lc_end_cal, 'DD-MON-YY'), 'DD-MON-YYYY');
        
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Values: ' ||'ld_beg_cal: ' || ld_beg_cal || 'ld_end_cal: ' || ld_end_cal );
           
    
    EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the GL period min and max period name' || SQLERRM);
          x_ret_code := 2;
          RETURN;  
          
        
          
    END;
    
    BEGIN
    
        for r_name in c_name loop
        lc_to_currency := r_name.value1;
        ld_conversion_date := r_name.value2;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Values: ' ||'lc_to_currency ' || lc_to_currency || 'ld_conversion_date ' || ld_conversion_date );
           

             INSERT INTO GL_DAILY_RATES_INTERFACE(from_currency
                                                 ,to_currency
                                                 ,from_conversion_date
                                                 ,to_conversion_date
                                                 ,user_conversion_type
                                                 ,conversion_rate
                                                 ,inverse_conversion_rate
                                                 ,mode_flag)
             SELECT   from_currency
                     ,to_currency
                     ,ld_conversion_date
                     ,ld_conversion_date
                     ,lc_rate_type || ' Avg'  --concat Avg since we are creating average rate types
                     ,round(sum(gdr.conversion_rate) / count(1),6) 
                     --,round(1/sum(conversion_rate) / count(*),6)
                     ,ROUND(1/ROUND(SUM(GDR.conversion_rate)/COUNT(1),6),6) inverse_conversion_rate
                     ,'I'
             FROM     GL_DAILY_RATES GDR
             WHERE    GDR.conversion_date BETWEEN ld_beg_cal AND ld_end_cal 
             AND      GDR.conversion_type = lc_conv_type_rate
             and      GDR.to_currency <> 'USD' 
             AND      GDR.to_currency     = lc_to_currency
                    group by from_currency,to_currency;
                    
              
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Month Range for Average Calculation ' || 'ld_beg_cal -'|| 'ld_end_cal');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of average rate records inserted for ' || SQL%ROWCOUNT);

          END LOOP;
          
           EXCEPTION
          WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while inserting into rates interface' || SQLERRM);
          x_ret_code := 2;
          RETURN;    
    
  END;

 END GL_FX_RATES_AVG;


-- +=======================================================================+
-- | Name : CREATE_AND_SEND_OUTBOUND_FILES                                 |
-- | Description : Generate files for delivery to partner systems          |
-- |                                                                       |
-- | Parameters : x_error_buff, x_ret_code                                 |
-- |             ,p_rundate     -- rate date                               |
-- |             ,p_request_key -- source1 in GL_RATE_REQUESTS translation |
-- |             ,p_create      -- Y/N to create file(s)                   |
-- |             ,p_send        -- Y/N to spawn jobs to FTP file(s)        |
-- | Returns :    Returns Code                                             |
-- |              Error Message                                            |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version   Date          Author        Remarks                          |
-- |=======   ==========    ======== ======================================|
-- | 1.0      16-JUL-2013   Gayathri Made changes if any FTP child program |
-- |                                   fails then parent program           |
-- |                                 "OD: GL Create and Send Rate Files"   |
-- |                                 also should fail as                   |
-- |                                part of the Defect#24312.              |
-- | 1.1      01-AUG-2021  Rupali G NAIT-190438- GDW Rate issue for JUL-21 |
-- +=======================================================================+
  PROCEDURE CREATE_AND_SEND_OUTBOUND_FILES (
    x_error_buff  OUT NOCOPY VARCHAR2
   ,x_ret_code    OUT NOCOPY VARCHAR2
   ,p_rundate     IN  VARCHAR2 := TO_CHAR(SYSDATE,'MM-DD-RRRR')
   ,p_request_key IN  VARCHAR2 := '%'
   ,p_create      IN  VARCHAR2 := 'Y'
   ,p_send        IN  VARCHAR2 := 'Y'
   ,p_request_type IN  VARCHAR2 DEFAULT 'FX'
  )
  AS
    ld_rundate                 DATE := TO_DATE(p_rundate,'MM-DD-RRRR');
    lf_output_file             UTL_FILE.file_type;
    lc_yes_flag                VARCHAR2(1) := 'Y';
    lc_us_currency_code        VARCHAR2(3) := 'USD';
    ld_to_date                 DATE;
    ld_export_date             DATE;
    lc_period_name             VARCHAR2(10);
    lc_short_name              VARCHAR2(10);
    ld_period_start_date       DATE;
    ld_period_end_date         DATE;
    lc_Friday                  VARCHAR2(1) := TO_CHAR(TO_DATE('20000107','RRRRMMDD'),'D');
    lc_Saturday                VARCHAR2(1) := TO_CHAR(TO_DATE('20000101','RRRRMMDD'),'D');
    lc_Sunday                  VARCHAR2(1) := TO_CHAR(TO_DATE('20000102','RRRRMMDD'),'D');
    lc_runday                  VARCHAR2(1) := TO_CHAR(ld_rundate,'D');
    lc_line                    VARCHAR2(4000);
    ln_request_id              FND_CONCURRENT_REQUESTS.request_id%TYPE;
    lb_result                  boolean;
    lc_file_name               VARCHAR2(100);
    lc_gen_file_name           VARCHAR2(100);
    ld_num_days_to_export      NUMBER;
    lc_period_name_file        VARCHAR2(10);
    l_request_type             VARCHAR2(10);  -- added for version-1.1
    
      lb_r_status                  BOOLEAN;
      lv_r_phase                   VARCHAR2 (2000) := '';
      lv_r_status                  VARCHAR2 (2000) := '';
      lv_r_d_phase                 VARCHAR2 (2000) := '';
      lv_r_d_status                VARCHAR2 (2000) := '';
      lv_r_msg                     VARCHAR2 (2000) := '';
	  
	TYPE t_child_req_id_tab IS TABLE OF NUMBER
	INDEX BY PLS_INTEGER;
	l_child_req_id_tab              t_child_req_id_tab;

      ln_recnumber PLS_INTEGER := 0;  
    
  BEGIN

     FND_GLOBAL.APPS_INITIALIZE (NVL(FND_GLOBAL.user_id,-1), NVL(FND_GLOBAL.resp_id,20434), NVL(FND_GLOBAL.resp_appl_id,101));

     -- fetch working data (e.g., conversion type codes, period name and date range, etc.)
     BEGIN
        SELECT target_value1
        INTO   lc_short_name                    -- CA SOB name (using this to get period_set_name for period start and end dates... may need revision)
        FROM   XX_FIN_TRANSLATEDEFINITION XFTD
              ,XX_FIN_TRANSLATEVALUES     XFTV
        WHERE  translation_name   = 'OD_COUNTRY_DEFAULTS'
        AND    XFTV.translate_id  = XFTD.translate_id
        AND    XFTV.source_value1 = 'CA'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';
     EXCEPTION 
        WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting the short_name for CAD SOB: ' || SQLERRM);
        x_ret_code := 2;
        RETURN;
     END;
     BEGIN
        SELECT period_name, start_date, end_date
        INTO   lc_period_name, ld_period_start_date, ld_period_end_date
        FROM   GL_PERIODS
        WHERE  ld_rundate BETWEEN start_date AND end_date
        --AND    period_set_name = (SELECT period_set_name FROM GL_SETS_OF_BOOKS WHERE short_name = lc_short_name); Commented as part of R12 Retrofit Changes
		AND    period_set_name = (SELECT period_set_name FROM GL_LEDGERS WHERE short_name = lc_short_name); --Added as part of R12 Retrofit Changes
     EXCEPTION
        WHEN OTHERS THEN FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching period name, start, and end: ' || SQLERRM);
        x_ret_code := 2;
        RETURN;
    END;

   
	--Added for version-1.1 NAIT-190438--
	IF p_request_type is NULL THEN
     l_request_type := 'FX';   
   else 	
     l_request_type := p_request_type;
	END IF;
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Request type is  : ' || l_request_type);
    --Changed for version 1.1 NAIT-190438--
    FOR r_request IN (SELECT   XFTV.source_value1 request_key
                              ,XFTV.target_value1 name_in_od_ftp_process
                              ,XFTV.target_value2 generated_file_name
                              ,XFTV.target_value3 deliver_file_name
                              ,XFTV.target_value8 include_weekends_on_friday
                              ,XFTV.target_value9 file_header
                              ,NVL(XFTV.target_value10,'XXFIN_OUTBOUND') output_directory_name
                              ,XFTV.target_value11 sftp_file_rename
                          FROM XX_FIN_TRANSLATEDEFINITION XFTD
                              ,XX_FIN_TRANSLATEVALUES     XFTV
                         WHERE XFTD.translation_name = 'GL_RATE_REQUESTS'
                           AND XFTV.translate_id = XFTD.translate_id
						   --   Changed to l_request_type for  version-1.1
                           AND (XFTV.source_value2 = TRIM(l_request_type))        -- we may support other rate types in future, but those files would likely be generated by a separate procedure    
                           AND XFTV.source_value1 LIKE p_request_key
                           AND ((XFTV.target_value4='Y' AND lc_runday NOT IN (lc_Saturday, lc_Sunday))       -- Send on weekdays
                                OR
                                (XFTV.target_value5='Y' AND lc_runday IN (lc_Saturday, lc_Sunday))           -- Send on weekends
                                OR
                                (XFTV.target_value6='Y' AND ld_rundate=ld_period_end_date-1)                 -- Send at end of period (end of period is always Saturday in gl_periods, but for this purpose send on Friday)
                                OR
                                (XFTV.target_value7='Y' AND ld_rundate=ld_period_end_date)
                                OR (XFTV.source_value2='FXX'))                  -- Send at end of period (Saturday)
                           AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                           AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                           AND XFTV.enabled_flag = lc_yes_flag
                           AND XFTD.enabled_flag = lc_yes_flag) LOOP
						   

      IF p_create='Y' AND r_request.generated_file_name IS NOT NULL THEN
      
           

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Creating file for request ' || r_request.request_key);
        
      lc_period_name_file :=  TO_CHAR(TO_DATE(lc_period_name, 'MON-YY'),'Mon-YYYY');
        
         lc_gen_file_name := r_request.generated_file_name;
            IF INSTR(lc_gen_file_name,'<date_mask>') <> 0  THEN
              r_request.generated_file_name := REPLACE(r_request.generated_file_name,'<date_mask>',lc_period_name_file);
            END IF;

        lf_output_file := UTL_FILE.FOPEN(r_request.output_directory_name,r_request.generated_file_name,'W');
        IF r_request.file_header IS NOT NULL THEN
          UTL_FILE.PUT(lf_output_file, REPLACE(REPLACE(r_request.file_header,'\r',CHR(13)),'\n',CHR(10)));
        END IF;

        --ld_to_date := CASE WHEN lc_runday=lc_Friday AND r_request.include_weekends_on_friday='Y' THEN ld_rundate+2 ELSE ld_rundate END;
      
         IF trim(p_request_type)='FXX' THEN
          ld_num_days_to_export := 11; -- one day per month, starting with 0 index for jan
          ld_rundate := TRUNC(ld_rundate,'YEAR');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_num_days_to_export ' || ld_num_days_to_export);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'ld_rundate ' || ld_rundate);
        ELSE 
          ld_to_date := CASE WHEN lc_runday=lc_Friday AND r_request.include_weekends_on_friday='Y' THEN ld_rundate+2 ELSE ld_rundate END;
          ld_num_days_to_export := ld_to_date-ld_rundate;
        END IF;

        --FOR i IN 0..ld_to_date-ld_rundate LOOP
         FOR i IN 0..ld_num_days_to_export LOOP
          --ld_export_date := ld_rundate+i;
          
          IF p_request_type='FXX' THEN
            ld_export_date := add_months(ld_rundate,i);
          ELSE
            ld_export_date := ld_rundate+i;
          END IF;

          FOR r_fx IN (SELECT CT.conversion_type conversion_type
                             ,XFTV.target_value2 from_currency
                             ,XFTV.target_value3 to_currency
                             ,XFTV.target_value4 include_where_from_equals_to
                             ,XFTV.target_value5 line_format
                             ,XFTV.target_value6 date_format_mask
                             ,XFTV.target_value7 rate_format_mask
                         FROM XX_FIN_TRANSLATEDEFINITION XFTD
                             ,XX_FIN_TRANSLATEVALUES     XFTV
                             ,GL_DAILY_CONVERSION_TYPES  CT
                        WHERE XFTD.translation_name = 'GL_RATE_REQUESTS_FX'
                          AND XFTV.translate_id = XFTD.translate_id
                          AND XFTV.source_value1 = r_request.request_key
                          AND CT.user_conversion_type = XFTV.target_value1
                          AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
                          AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
                          AND XFTV.enabled_flag = lc_yes_flag
                          AND XFTD.enabled_flag = lc_yes_flag
                        ORDER BY XFTV.source_value2) LOOP

            IF r_fx.line_format IS NOT NULL THEN

              FOR r_rate IN (SELECT from_currency
                                   ,to_currency
                                   ,NVL(TRIM(TO_CHAR(ROUND(conversion_rate,6),r_fx.rate_format_mask)),ROUND(conversion_rate,6)) conversion_rate
                                   ,NVL(TRIM(TO_CHAR(ROUND(inverse_conversion_rate,6),r_fx.rate_format_mask)),ROUND(conversion_rate,6)) inverse_conversion_rate
                                   ,NVL(TO_CHAR(ld_export_date,r_fx.date_format_mask),ld_export_date) conversion_date
                                   
                                  
                                   

                              FROM (SELECT rates.from_currency,rates.to_currency,rates.conversion_rate,inverses.conversion_rate inverse_conversion_rate  FROM
                              
                                    -- Rates from and to USD
                                   (SELECT DR.from_currency,DR.to_currency,DR.conversion_rate  FROM GL_DAILY_RATES DR JOIN FND_CURRENCIES FC ON DR.from_currency=FC.currency_code JOIN FND_CURRENCIES TC ON DR.to_currency=TC.currency_code
                                     WHERE DR.conversion_date=ld_export_date AND DR.conversion_type=r_fx.conversion_type 
                                       AND DR.from_currency LIKE r_fx.from_currency AND DR.to_currency LIKE r_fx.to_currency AND (DR.from_currency=lc_us_currency_code OR DR.to_currency=lc_us_currency_code)
                                       AND TC.enabled_flag=lc_yes_flag and TC.currency_flag=lc_yes_flag AND FC.enabled_flag=lc_yes_flag AND FC.currency_flag=lc_yes_flag
                                    UNION
                                    -- Rates from X to X
                                    SELECT currency_code from_currency, currency_code to_currency, 1.0 conversion_rate FROM FND_CURRENCIES WHERE currency_code LIKE r_fx.from_currency AND currency_code LIKE r_fx.to_currency AND enabled_flag=lc_yes_flag AND currency_flag=lc_yes_flag AND r_fx.include_where_from_equals_to=lc_yes_flag
                                    UNION
                                    -- All other triangulated rates
                                    SELECT TRI.from_currency,TRI.to_currency,TO_USD.conversion_rate * FROM_USD.conversion_rate conversion_rate
                                      FROM (SELECT F.currency_code from_currency, T.currency_code to_currency
                                              FROM FND_CURRENCIES F, FND_CURRENCIES T
                                             WHERE F.enabled_flag =lc_yes_flag AND T.enabled_flag =lc_yes_flag
                                               AND F.currency_flag=lc_yes_flag AND T.currency_flag=lc_yes_flag
                                               AND F.currency_code<>lc_us_currency_code
                                               AND T.currency_code<>lc_us_currency_code
                                               AND T.currency_code LIKE r_fx.to_currency
                                               AND F.currency_code LIKE r_fx.from_currency
                                               AND F.currency_code<>T.currency_code) TRI
                                      JOIN (SELECT from_currency,conversion_rate FROM GL_DAILY_RATES WHERE conversion_date=ld_export_date AND to_currency=lc_us_currency_code AND from_currency LIKE r_fx.from_currency AND conversion_type=r_fx.conversion_type) TO_USD
                                        ON TRI.from_currency=TO_USD.from_currency
                                      JOIN (SELECT to_currency,conversion_rate FROM GL_DAILY_RATES WHERE conversion_date=ld_export_date  AND from_currency=lc_us_currency_code AND to_currency LIKE r_fx.to_currency AND conversion_type=r_fx.conversion_type) FROM_USD
                                        ON TRI.to_currency=FROM_USD.to_currency) rates
                                        
                                     JOIN -- lookup inverses  

                                    -- Rates from and to USD
                                     -- RHartman change defect xxxxx
                                   (SELECT DR.from_currency,DR.to_currency,DR.conversion_rate FROM GL_DAILY_RATES DR JOIN FND_CURRENCIES FC ON DR.from_currency=FC.currency_code JOIN FND_CURRENCIES TC ON DR.to_currency=TC.currency_code
                                     WHERE DR.conversion_date=ld_export_date AND DR.conversion_type=r_fx.conversion_type 
                                       AND DR.from_currency LIKE r_fx.to_currency  AND DR.to_currency LIKE r_fx.from_currency AND (DR.from_currency=lc_us_currency_code OR DR.to_currency=lc_us_currency_code)
                                       AND TC.enabled_flag=lc_yes_flag and TC.currency_flag=lc_yes_flag AND FC.enabled_flag=lc_yes_flag AND FC.currency_flag=lc_yes_flag
                                    UNION
                                    -- Rates from X to X
                                    SELECT currency_code from_currency, currency_code to_currency, 1.0 conversion_rate FROM FND_CURRENCIES WHERE currency_code LIKE r_fx.from_currency AND currency_code LIKE r_fx.to_currency AND enabled_flag=lc_yes_flag AND currency_flag=lc_yes_flag AND r_fx.include_where_from_equals_to=lc_yes_flag
                                    UNION
                                    -- All other triangulated rates
                                    SELECT TRI.from_currency,TRI.to_currency,TO_USD.conversion_rate * FROM_USD.conversion_rate conversion_rate
                                      FROM (SELECT F.currency_code from_currency, T.currency_code to_currency
                                              FROM FND_CURRENCIES F, FND_CURRENCIES T
                                             WHERE F.enabled_flag =lc_yes_flag AND T.enabled_flag =lc_yes_flag
                                               AND F.currency_flag=lc_yes_flag AND T.currency_flag=lc_yes_flag
                                               AND F.currency_code<>lc_us_currency_code
                                               AND T.currency_code<>lc_us_currency_code
                                               AND T.currency_code LIKE r_fx.from_currency
                                               AND F.currency_code LIKE r_fx.to_currency
                                               AND F.currency_code<>T.currency_code) TRI
                                      JOIN (SELECT from_currency,conversion_rate FROM GL_DAILY_RATES WHERE conversion_date=ld_export_date AND to_currency=lc_us_currency_code AND from_currency LIKE r_fx.to_currency AND conversion_type=r_fx.conversion_type) TO_USD
                                        ON TRI.from_currency=TO_USD.from_currency
                                      JOIN (SELECT to_currency,conversion_rate FROM GL_DAILY_RATES WHERE conversion_date=ld_export_date AND from_currency=lc_us_currency_code AND to_currency LIKE r_fx.from_currency AND conversion_type=r_fx.conversion_type) FROM_USD
                                        ON TRI.to_currency=FROM_USD.to_currency) inverses

                                    ON rates.from_currency=inverses.to_currency AND rates.to_currency=inverses.from_currency)

                              ORDER BY from_currency,to_currency) LOOP

                lc_line := REPLACE(r_fx.line_format,'<from_currency>',r_rate.from_currency);
                lc_line := REPLACE(lc_line,'<to_currency>',r_rate.to_currency);
                lc_line := REPLACE(lc_line,'<conversion_date>',r_rate.conversion_date);
                lc_line := REPLACE(lc_line,'<conversion_rate>',r_rate.conversion_rate);
                lc_line := REPLACE(lc_line,'<inverse_conversion_rate>',r_rate.inverse_conversion_rate);
                lc_line := REPLACE(REPLACE(lc_line,'\r',CHR(13)),'\n',CHR(10));

              --DBMS_OUTPUT.PUT_LINE(lc_line);
                UTL_FILE.PUT_LINE(lf_output_file,lc_line);
              END LOOP; -- FOR r_rate

            END IF; -- IF r_fx.line_format IS NOT NULL

          END LOOP; -- FOR r_fx

        END LOOP; -- FOR i IN 0..ld_to_date-ld_rundate

        UTL_FILE.FCLOSE(lf_output_file);
      END IF; -- end of file creation

      IF p_send='Y' AND r_request.name_in_od_ftp_process IS NOT NULL THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting request to FTP file ' || r_request.generated_file_name);
        
         -- replace value to create dynamic file name
            lc_file_name := r_request.deliver_file_name;
            IF INSTR(lc_file_name,'<date_mask>') <> 0  THEN
              r_request.deliver_file_name := REPLACE(r_request.deliver_file_name,'<date_mask>',lc_period_name_file);
              r_request.sftp_file_rename := REPLACE(r_request.sftp_file_rename,'<date_mask>',lc_period_name_file);
            END IF;

        lb_result := FND_REQUEST.set_print_options(copies=>0); -- otherwise get no output warning when run from ESP
        ln_request_id := FND_REQUEST.SUBMIT_REQUEST(application => 'XXFIN'
                                                   ,program     => 'XXCOMFTP'
                                                   ,description => 'GL Rate File FTP PUT'
                                                   ,sub_request => FALSE
                                                   ,argument1   => r_request.name_in_od_ftp_process
                                                   ,argument2   => r_request.generated_file_name
                                                   ,argument3   => r_request.deliver_file_name
                                                   ,argument4   => 'Y' -- delete source file
                                                   ,argument5   => r_request.sftp_file_rename
                                                   );
        COMMIT;
        IF ln_request_id = 0 THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Error : Unable to submit program to send rate request ' || r_request.request_key || ' file "' || r_request.generated_file_name || '"  as  "' || r_request.deliver_file_name || '"');
        ELSE
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Request id ' || TO_CHAR (ln_request_id) || ' spawned to ftp rate file "' || r_request.generated_file_name || '"  as  "' || r_request.deliver_file_name || '"');
		   ln_recnumber :=ln_recnumber+1;
           l_child_req_id_tab(ln_recnumber) := ln_request_id ; --added as part of the Defect # 24312
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Request IDs ========>  ' || l_child_req_id_tab(ln_recnumber));

        END IF;
		
		END IF; -- end of file send

    END LOOP; -- FOR r_request
        
        -- added as part of the Defect # 24312
        -- wait for the request to complete
    -- Starting of QC#24312 changes
            --added as part of the Defect # 24312
            -- wait for the request to complete

	FOR i IN 1 .. l_child_req_id_tab.COUNT LOOP

	   lb_r_status :=
			fnd_concurrent.wait_for_request (l_child_req_id_tab(i),
											 10,--interval default 60
											 1000, -- max wait default 0
											 lv_r_phase,
											 lv_r_status,
											 lv_r_d_phase,
											 lv_r_d_status,
											 lv_r_msg);


	 IF (    lb_r_status = TRUE
		 AND lv_r_phase = 'Completed'
		 AND lv_r_status <> 'Normal')
	 THEN
		fnd_file.put_line (fnd_file.LOG, ' Child Request ' || l_child_req_id_tab(i) || ' NOT Completed Successfully ');
		 x_ret_code := 2;
	 ELSIF (    lb_r_status = TRUE
			AND lv_r_phase = 'Completed'
			AND lv_r_status = 'Normal')
	 THEN
		fnd_file.put_line (fnd_file.LOG, '  Child Request ID ' || l_child_req_id_tab(i) || ' Completed Successfully');
	 END IF;
	  lb_r_status := NULL;
	  lv_r_phase := NULL;
	  lv_r_status := NULL;

	END LOOP;

          -- Ending of QC#24312 changes     

    

  EXCEPTION WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised in Main Procedure CREATE_AND_SEND_OUTBOUND_FILES'|| SQLERRM);
    XX_COM_ERROR_LOG_PUB.LOG_ERROR(p_program_type           => ' '
                                  ,p_program_name           => 'XX_GL_CREATE_AND_SEND_OUTBOUND_FILES'
                                  ,p_program_id             => FND_GLOBAL.CONC_PROGRAM_ID
                                  ,p_module_name            => 'GL'
                                  ,p_error_location         => 'Exception : Main Procedure Exception'
                                  ,p_error_message_count    => 1
                                  ,p_error_message_code     => 'E'
                                  ,p_error_message          => SQLERRM
                                  ,p_error_message_severity => 'Major'
                                  ,p_notify_flag            => 'N'
                                  ,p_object_type            => 'GL_Exchange_Rate');
     x_ret_code := 2;
  END CREATE_AND_SEND_OUTBOUND_FILES;

  

-- +=======================================================================+
-- | Name : TO_CONVERSION_DATE                                             |
-- | Description : Returns the ending date for a conversion rate           |
-- |               imported into gl_daily_rate_interface via host sqlldr   |
-- |               concurrent program XXGLRATELOAD.prog                    |
-- |               based on the starting date, taking into consideration   |
-- |               the need to have Friday rates valid through weekends    |
-- |               and rates requested after 5pm available for use during  |
-- |               the next working day prior to 5pm, as well as the 2nd   |
-- |               working day as a buffer in case of process delay.       | 
-- | Parameters : p_from_conversion_date                                   |
-- |             ,p_date_format                                            |
-- | Returns :    date                                                     |
-- +=======================================================================+
  FUNCTION TO_CONVERSION_DATE (
                             p_from_conversion_date VARCHAR2
                            ,p_date_format          VARCHAR2
  ) RETURN DATE
  IS
    ld_from_conversion_date DATE := TO_DATE(p_from_conversion_date,p_date_format); -- date of requested rates
  BEGIN
    RETURN ld_from_conversion_date
           + (CASE WHEN to_char(ld_from_conversion_date,'D')=to_char(to_date('20000107','RRRRMMDD'),'D') THEN 2 ELSE 0 END) -- requested rates are for a Friday
           + (CASE WHEN         ld_from_conversion_date=TRUNC(SYSDATE)  -- rates are for today
              OR (              ld_from_conversion_date=TRUNC(SYSDATE-1) AND SYSDATE<(TRUNC(SYSDATE)+17/24)) -- rates are for yesterday and it is now before 5pm
              OR (      to_char(ld_from_conversion_date,'D')=to_char(to_date('20000107','RRRRMMDD'),'D')         -- rates are for a Friday
                  AND (         ld_from_conversion_date+2>=TRUNC(SYSDATE)                                        -- today is Saturday or Sunday
                      OR (      ld_from_conversion_date+3>=TRUNC(SYSDATE) AND SYSDATE<(TRUNC(SYSDATE)+17/24))))  -- today is Monday before 5pm
              THEN 2 ELSE 0 END); -- load couple extra days to have working rate values;
  END TO_CONVERSION_DATE;
  

-- +=======================================================================+
-- | Name : PREVIOUS_RATE                                                  |
-- | Description : Returns the most recent ending rate for a conversion    |
-- |               prior to a specified date.  Used to populate a rate     |
-- |               when Bloomberg returns N.A. (because of holiday, etc)   |
-- |               If none found, return 0.                                |
-- | Parameters : p_from_conversion_date                                   |
-- | Returns :    conversion_rate                                          |
-- +=======================================================================+
   FUNCTION PREVIOUS_RATE (
      p_from_currency   VARCHAR2
     ,p_to_currency     VARCHAR2
     ,p_conversion_date VARCHAR2
     ,p_date_format     VARCHAR2
   ) RETURN NUMBER
   IS
     ln_conversion_rate GL_DAILY_RATES.conversion_rate%TYPE;
   BEGIN
     BEGIN
       SELECT conversion_rate 
         INTO ln_conversion_rate 
         FROM GL_DAILY_RATES 
        WHERE from_currency=p_from_currency 
          AND to_currency=p_to_currency 
          AND conversion_type='1001' 
          AND conversion_date= (SELECT MAX(conversion_date) 
                                  FROM GL_DAILY_RATES 
                                 WHERE from_currency=p_from_currency 
                                   AND to_currency=p_to_currency 
                                   AND conversion_type='1001' 
                                   AND conversion_date<SYSDATE);
     EXCEPTION WHEN NO_DATA_FOUND THEN
       ln_conversion_rate := 0;
     END;
     
     RETURN ln_conversion_rate;
   END PREVIOUS_RATE;


 END XX_GL_PERIOD_RATES_PKG;
/
