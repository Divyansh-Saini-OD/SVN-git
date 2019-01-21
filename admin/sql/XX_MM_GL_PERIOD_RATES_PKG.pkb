SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM ON
PROMPT Creating Package Body XX_MM_GL_PERIOD_RATES_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
create or replace
PACKAGE BODY XX_MM_GL_PERIOD_RATES_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name   :      Exchange Rates Calculation Program  for MidMonth    |
-- | Rice ID:                                                          |
-- | Description : To calculate average rates and ending rate for      |
-- |               the currencies.  For Midmonth, copied the package   |
-- |               XX_GL_PERIOD_RATES_PKG(Subversion) and adjusted to  |
-- |               run if thePeriodEndDate is on any day(Sun-Sat)      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       19-AUG-2015  Madhu Bolli          Initial version        |
-- +===================================================================+


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
    
    ln_period_end_day          NUMBER; -- 2.0   
    
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



       -- Clear errored daily ending rates from interface table (will be viewable in XPRTR)
       DELETE FROM GL_DAILY_RATES_INTERFACE WHERE mode_flag = lc_error_mode_flag;
       COMMIT;
	   
       ln_period_end_day := to_char(ld_period_end_date, 'D');   -- 2.0 
       
       

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
                     ,AVERAGE_DATES.conversion_date + (CASE WHEN TO_CHAR(AVERAGE_DATES.conversion_date,'D')=lc_Friday THEN (CASE WHEN AVERAGE_DATES.conversion_date=ld_period_end_date THEN 0 WHEN AVERAGE_DATES.conversion_date=ld_period_end_date-1 THEN 1 ELSE 2 END)  -- 2.0 
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


            -- 2.0 insert Friday end rate as Saturday and Sunday avg at end of period and if PeriodEnd is on Friday/Saturday
          IF (ld_rundate = ld_period_end_date-1 and ln_period_end_day in (lc_Saturday)      -- If it is Saturday of Month End
              or ld_rundate = ld_period_end_date and ln_period_end_day in (lc_Friday) ) THEN --   If it is Friday of Month End then we need both Saturday and Sunday   -- 2.0
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
                     ,ld_rundate+decode(ln_period_end_day, lc_Friday, 1, 2) from_conversion_date -- If the period End is on Friday, then do for both Saturday and Sunday    --2.0
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

       COMMIT;
       FND_FILE.PUT_LINE(FND_FILE.LOG, 'AVERAGE RATE and ENDING RATE for CAD SOB updated successfully');


        -- Roll rates forward to next period for defect 8694
       IF ((ln_period_end_day = lc_saturday and ld_rundate = ld_period_end_date-1)       -- Period End is on Saturday and if we run this on Friday -- 2.0
          or (ln_period_end_day = lc_sunday and ld_rundate = ld_period_end_date-2)     -- Period End is on Sunday and if we run this on Friday   -- 2.0
          or (ld_rundate = ld_period_end_date)                                 -- Period End is any other day and if we run on that day  -- 2.0
          )  THEN
         BEGIN
           SELECT period_name
				, start_date --Added part of R12 Upgrade Change
				, end_date --Added part of R12 Upgrade Change
           INTO   lc_period_name 
				, ld_period_start_date --Added part of R12 Upgrade Change
				, ld_period_end_date --Added part of R12 Upgrade Change
           FROM   GL_PERIODS
           WHERE  ld_rundate+3 BETWEEN start_date AND end_date
           --AND    period_set_name = (SELECT period_set_name FROM GL_SETS_OF_BOOKS WHERE short_name = lc_short_name); Commented as part of R12 Retrofit Changes
		   AND    period_set_name = (SELECT period_set_name FROM GL_LEDGERS WHERE short_name = lc_short_name); --Added as part of R12 Retrofit Changes
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

 END XX_MM_GL_PERIOD_RATES_PKG;
/
SHOW ERROR