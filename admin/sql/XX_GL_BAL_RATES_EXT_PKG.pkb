SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_GL_BAL_RATES_EXT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_GL_BAL_RATES_EXT_PKG
AS

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name   :      Ledger balances and Exchange rates extract program   |
-- | Rice ID:      I1360                                                |
-- | Description : extracts Ledger balances and Exchange rates from     |
-- |               Oracle General Ledger  based on the input parameters |
-- |               and writes it into a  data file                      |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   ===============      ========================|
-- |  1.0   17-Aug-2007   Nandini Bhimana     Initial version           |
-- |                      Boina                                         |
-- |                                                                    |
-- |  1.1   24-Oct-2007   Nandini Bhimana     Added to get  SOB Name    |
-- |                      Boina               from Translation          |
-- |                                          OD_COUNTRY_DEFAULTS       |
-- |                                                                    |                                                  
-- |  1.2   07-Feb-08     Manovinayak         Fix for the defect#4335   |
-- +====================================================================+
-- +====================================================================+
-- | Name : GL_BAL_EXTRACT                                              |
-- | Description : extracts the ledger balances and COA segments  on a  |
-- |               monthly basis from Oracle General Ledger and copies  |
-- |               on to a data file                                    |
-- | Parameters :  x_error_buff, x_ret_code,p_period_name,p_sob_name    |
-- | Returns :     Returns Code                                         |
-- |               Error Message                                        |
-- +====================================================================+

   PROCEDURE GL_BAL_EXTRACT(
                           x_err_buff         OUT NOCOPY VARCHAR2
                           ,x_ret_code        OUT NOCOPY VARCHAR2
                           ,p_sob_name        IN  VARCHAR2
                           ,p_period_name     IN  VARCHAR2
                           )
   AS

      -------------------------- Declaring local variables -----------------------------------

      lc_short_name        gl_sets_of_books.short_name%TYPE;
      ln_coa_id            gl_sets_of_books.chart_of_accounts_id%TYPE;
      lc_actual_flag       gl_balances.actual_flag%TYPE;
      lc_period_name       gl_balances.period_name%TYPE;
      lc_period_year       gl_balances.period_year%TYPE;
      lc_company           gl_code_combinations.segment1%TYPE;
      lc_costcenter        gl_code_combinations.segment2%TYPE;
      lc_account           gl_code_combinations.segment3%TYPE;
      lc_location          gl_code_combinations.segment4%TYPE;
      lc_intercompany      gl_code_combinations.segment5%TYPE;
      lc_lob               gl_code_combinations.segment6%TYPE;
      lc_future            gl_code_combinations.segment7%TYPE;
      lc_account_desc      fnd_flex_values_tl.description%TYPE;
      lc_period_type       gl_balances.period_type%TYPE;
      ln_set_of_book_id    gl_sets_of_books.set_of_books_id%TYPE;
      lc_currency_code     fnd_currencies.currency_code%TYPE;
      --lc_exclude_currency  fnd_currencies.currency_code%TYPE; --commented for the defect#4335
      ln_sob_id            gl_sets_of_books.set_of_books_id%TYPE;
      lc_leg_balance       gl_balances.quarter_to_date_dr%TYPE;
      lc_error_msg         VARCHAR2(4000);
      lc_error_loc         VARCHAR2(2000);
      ln_msg_cnt           NUMBER := 0;
      ln_req_id            NUMBER(10);
      lc_email_address     VARCHAR2(500);
      lc_act_desc          VARCHAR2(10000);
      lc_file_name         VARCHAR2(50);
      lc_file_path         VARCHAR2(500) := 'XXFIN_OUTBOUND';
      lc_source_file_path  VARCHAR2(500) ;
      lc_dest_file_path    VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
      lc_archive_file_path VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
      lc_source_file_name  VARCHAR2(1000);
      lc_dest_file_name    VARCHAR2(1000);
      lt_file              UTL_FILE.FILE_TYPE;
      ln_buffer            BINARY_INTEGER := 32767;
      lc_appl_id           fnd_application_vl.application_id%TYPE;
      lc_phase             VARCHAR2(50); 
      lc_status            VARCHAR2(50);
      lc_devphase          VARCHAR2(50);
      lc_devstatus         VARCHAR2(50);
      lc_message           VARCHAR2(50);
      lb_req_status        BOOLEAN;
      lc_seg3_desc        VARCHAR2(2000);

   -----------------------------Cursor to fetch ledger balances ---------------------------------

      CURSOR c_ledger_balances(p_sob_id             NUMBER
                              ,p_currency_code      VARCHAR2
                              --,p_exclude_currency   VARCHAR2
                              )
      IS
      SELECT  GLB.period_name
              ,GLB.actual_flag
              ,GLB.period_year
             -- ,GLB.period_net_dr --commented for the defect#4335
             -- ,GLB.period_net_cr --commented for the defect#4335
              ,GCC.segment1
              ,GCC.segment2
              ,GCC.segment3
              ,GCC.segment4
              ,GCC.segment5
              ,GCC.segment6
              ,GCC.segment7
             -- ,SUM(GLB.period_net_dr - GLB.period_net_cr) gl_bal --commented for the defect#4335
	      ,(begin_balance_dr-begin_balance_cr + period_net_dr-period_net_cr) YTD_BAL              
      FROM    gl_balances GLB
              ,gl_code_combinations GCC
      WHERE   GLB.set_of_books_id               = p_sob_id
      AND     GLB.code_combination_id           = GCC.code_combination_id
      AND     GLB.currency_code                 = p_currency_code
     -- AND   GLB.currency_code                <> p_exclude_currency  --commented for the defect#4335
      AND     TO_DATE(GLB.period_name,'MON-YY') = TO_DATE(p_period_name,'MON-YY')
     /*BETWEEN TO_DATE('JAN-' || SUBSTR(p_period_name,5,2),'MON-YY')
      AND TO_DATE(p_period_name,'MON-YY')*/ --commented for the defect#4335
      AND GLB.actual_flag = 'A'
      AND GCC.template_id IS NULL; -- modification for the defect#4335          
      /*GROUP BY  GLB.period_name
                ,GLB.actual_flag
                ,GLB.period_year
                ,GLB.period_net_dr
                ,GLB.period_net_cr
                ,GCC.segment1
                ,GCC.segment2
                ,GCC.segment3
                ,GCC.segment4
                ,GCC.segment5
                ,GCC.segment6
                ,GCC.segment7;*/ --commented for the defect#4335

      BEGIN
         BEGIN

               ------------------------- Getting SOB id and currency code -------------------------

            SELECT set_of_books_id
                   ,currency_code
                   ,chart_of_accounts_id
            INTO   ln_sob_id
                   ,lc_currency_code
                   ,ln_coa_id
            FROM   gl_sets_of_books_v
            WHERE  short_name = p_sob_name;
                

            SELECT application_id
            INTO lc_appl_id
            FROM fnd_application_vl
            WHERE application_short_name = 'SQLGL';

               FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
               FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Name     : ' || p_sob_name);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Currency     : ' || lc_currency_code);
               --FND_FILE.PUT_LINE(FND_FILE.LOG,'From Period  : ' || 'JAN-' || SUBSTR(p_period_name,5,2)); --commented for the defect#4335
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Period Name  : ' || p_period_name);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------');

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'SOB Name      : ' || p_sob_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Currency      : ' || lc_currency_code);
               --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'From Period   : ' || 'JAN-' || SUBSTR(p_period_name,5,2)); --commented for the defect#4335
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Period Name   : ' || p_period_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-------------------------------------------------------------');

               --Commented after the changes for defect#4335

             /*----------------- Validating if the GL Period is closed --------------------------

            SELECT GPS.closing_status
            INTO   lc_closing_status
            FROM   gl_period_statuses GPS
            WHERE  set_of_books_id = ln_sob_id
            AND    period_name     = p_period_name
            AND    application_id  = lc_appl_id;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0005_BAL_EXT_NO_DATA');
            FND_MESSAGE.SET_TOKEN('COL','GL Balance');
            lc_error_msg := FND_MESSAGE.GET;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => 'OD: GL Balance and Segment Extract Program'
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'GL'
                                           ,p_error_location          => 'Oracle Error :'||SQLERRM
                                           ,p_error_message_count     => ln_msg_cnt + 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_error_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'GL Balance Extract'
                                           );
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
            FND_MESSAGE.SET_TOKEN('COL','GL Balance');
            lc_error_msg := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => 'OD: GL Balance and Segment Extract Program'
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'GL'
                                           ,p_error_location          => 'Oracle Error :'||SQLERRM
                                           ,p_error_message_count     => ln_msg_cnt + 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_error_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'GL Balance Extract'
                                           );*/
         END;
          
               --Commented after the changes for defect#4335

         /* IF lc_closing_status = 'C' THEN
----------------------select the sob short names from translation-------------------------------

            SELECT target_value1 
            INTO lc_usd_sob_name
            FROM xx_fin_translatedefinition  XFTD
                , xx_fin_translatevalues     XFTV
            WHERE translation_name = 'OD_COUNTRY_DEFAULTS'
            AND XFTV.translate_id = XFTD.translate_id
            AND XFTV.source_value1  = 'US'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

                SELECT target_value1 
            INTO lc_cad_sob_name
            FROM xx_fin_translatedefinition  XFTD
                , xx_fin_translatevalues XFTV
            WHERE translation_name = 'OD_COUNTRY_DEFAULTS'
            AND XFTV.translate_id = XFTD.translate_id
            AND XFTV.source_value1  = 'CA'
            AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
            AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
            AND XFTV.enabled_flag = 'Y'
            AND XFTD.enabled_flag = 'Y';

    ----------------- Defining the currency NOT included in the GL Balance Extract--------------------
             ----------------- Removed the hardcoding for SOB Name -----------------------------
            IF p_sob_name = lc_usd_sob_name THEN
               lc_exclude_currency := 'CAD';
            ELSIF p_sob_name = lc_cad_sob_name THEN
               lc_exclude_currency := 'USD';
            END IF;*/ --commented for the defect#4335

          --- Fetching the XXFIN_OUTBOUND Directory Path from the table
            BEGIN
               SELECT directory_path
               INTO lc_source_file_path
               FROM dba_directories
               WHERE directory_name = lc_file_path;
            EXCEPTION
             WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                                  || SQLERRM);
            END;
 
              
               lc_file_name := 'ORAGL_' || p_sob_name || '_' 
                                        || TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'YYYYMM') || '.TXT';

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balance Extract File Name : ' || lc_file_name);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || lc_file_path);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || lc_dest_file_path);
               FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');

            BEGIN
               lt_file := UTL_FILE.fopen(lc_file_path, lc_file_name,'w',ln_buffer);
            EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the file. '|| SQLERRM);
            END;

            FOR lcu_ledger_balances IN c_ledger_balances(ln_sob_id,lc_currency_code/*,lc_exclude_currency*/)
            LOOP

               BEGIN
                  BEGIN
                     SELECT FFVL.description
                     INTO lc_seg3_desc
                     FROM  fnd_flex_values_vl FFVL
                           ,fnd_id_flex_segments_vl FIFS
                     WHERE flex_value                 = lcu_ledger_balances.segment3
                     AND FIFS.flex_value_set_id       = FFVL.flex_value_set_id
                     AND FIFS.id_flex_num             = ln_coa_id
                     AND FIFS.application_id          = lc_appl_id
                     AND FIFS.application_column_name = 'SEGMENT3';
                  EXCEPTION
                  WHEN OTHERS THEN
                     lc_seg3_desc := 'N/A';
                  END;

               EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching Account Description'
                                   || SQLERRM);
               END;

         -------------------------- Writing GL Balances into text file ---------------------------

               BEGIN
                  UTL_FILE.PUT_LINE(lt_file, p_sob_name
                                   || '|'   ||lcu_ledger_balances.actual_flag
                                   || '|'   ||lcu_ledger_balances.period_name
                                   || '|'   ||lcu_ledger_balances.period_year
                                   || '|'   ||lc_currency_code
                                   || '|'   ||lcu_ledger_balances.segment1 -- Company
                                   || '|'   ||lcu_ledger_balances.segment2 -- Cost Center
                                   || '|'   ||lcu_ledger_balances.segment3 -- Account
                                   || '|'   ||lc_seg3_desc -- Account Description
                                   || '|'   ||lcu_ledger_balances.segment4 -- Location
                                   || '|'   ||lcu_ledger_balances.segment5 -- Intercompany
                                   || '|'   ||lcu_ledger_balances.segment6 -- LOB
                                   || '|'   ||lcu_ledger_balances.YTD_BAL  -- NET YTD Balance
                                   );

               EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while writing into Text file'|| SQLERRM);
               END;

            END LOOP;

            UTL_FILE.fclose(lt_file);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Balances have been written into the file successfully.');

         --------------- Call the Common file copy Program Copy to $XXFIN_DATA/ftp/out/hyperion-----------------------------

               lc_source_file_name  := lc_source_file_path || '/' || lc_file_name;
               lc_dest_file_name    := lc_dest_file_path   || '/' || lc_file_name;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copied  Path     : ' || lc_dest_file_name);

            ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                    'xxfin'
                                                    ,'XXCOMFILCOPY'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,lc_source_file_name
                                                    ,lc_dest_file_name
                                                    ,NULL
                                                    ,NULL
                                                    );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File was Copied into ' ||  lc_dest_file_path
                                         || '. Request id : ' || ln_req_id);

        --------------- Call the Common file copy Program Archive to $XXFIN_ARCHIVE/outbound ----------------

               lc_dest_file_name    := lc_archive_file_path || '/' || lc_file_name;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Arichived File Path   : ' || lc_dest_file_name);

            ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                    'xxfin'
                                                    ,'XXCOMFILCOPY'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,lc_source_file_name
                                                    ,lc_dest_file_name
                                                    ,NULL
                                                    ,NULL
                                                    );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File was Archived into ' ||  lc_archive_file_path
                                         || '. Request id : ' || ln_req_id);
            COMMIT;

            ------------------- Wait till the the Common file copy Program to Complete ---------------------

            lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                            request_id  => ln_req_id
                                                            ,interval    => '2'
                                                            ,max_wait    => ''
                                                            ,phase       => lc_phase 
                                                            ,status      => lc_status
                                                            ,dev_phase   => lc_devphase
                                                            ,dev_status  => lc_devstatus
                                                            ,message     => lc_message
                                                            );

            ------------------------- Remove the File from  XXFIN_OUTBOUND ---------------------------

               BEGIN
                  UTL_FILE.FREMOVE(lc_file_path, lc_file_name);
               EXCEPTION
               WHEN OTHERS THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Removing the file '
                                                        || lc_file_path || lc_file_name || SQLERRM);
               END;

          --Commented after the changes for defect#4335

         /*ELSE

            ----------------------------- Display the Error Message -----------------------------

            FND_FILE.PUT_LINE(FND_FILE.LOG,   'The GL Period ' ||  p_period_name  || ' is not closed ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,   '*************************************************************');

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The GL Period ' ||  p_period_name  || ' is not closed ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');

            FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
            FND_MESSAGE.SET_TOKEN('COL','GL Balance');
            lc_error_msg := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                           p_program_type             => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => 'OD: GL Balance and Segment Extract Program'
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'GL'
                                           ,p_error_location          => 'Oracle Error '||SQLERRM
                                           ,p_error_message_count     => ln_msg_cnt + 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_error_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'GL Balance Extract'
                                           );
         END IF;*/

        ----------------------------- Sending Output file to the concerned Person --------------------

         lc_email_address := FND_PROFILE.VALUE('GL_ERROR_OUTPUT_EMAIL_ID');

         ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                 'xxfin'
                                                 ,'XXODROEMAILER'
                                                 ,'OD: Concurrent Request Output Emailer Program'
                                                 ,''
                                                 ,FALSE
                                                 ,'OD: GL Exchange Rates Extract Program'
                                                 ,lc_email_address
                                                 ,'GL Exchange Rate Error Records Output File'
                                                 ,'GL Exchange Rate Error Records Output File'
                                                 ,'Y'
                                                 ,FND_GLOBAL.CONC_REQUEST_ID
                                                 );

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Output File was sent to ' || lc_email_address
                                           || '. Request id : ' || ln_req_id);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'******************************************************');

      EXCEPTION
      WHEN OTHERS THEN
      IF UTL_FILE.is_open(lt_file) THEN
         UTL_FILE.fclose(lt_file);
      END IF;

         FND_MESSAGE.SET_NAME('XXFIN','XX_GL_0006_BAL_EXT_OTHERS');
         FND_MESSAGE.SET_TOKEN('COL','GL Balance');
         lc_error_msg := FND_MESSAGE.GET;
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                        p_program_type             => 'CONCURRENT PROGRAM'
                                        ,p_program_name            => 'OD: GL Balance and Segment Extract Program'
                                        ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                        ,p_module_name             => 'GL'
                                        ,p_error_location          => 'Oracle Error '||SQLERRM
                                        ,p_error_message_count     => ln_msg_cnt + 1
                                        ,p_error_message_code      => 'E'
                                        ,p_error_message           => lc_error_msg
                                        ,p_error_message_severity  => 'Major'
                                        ,p_notify_flag             => 'N'
                                        ,p_object_type             => 'GL Balance Extract'
                                        );
      END GL_BAL_EXTRACT;

-- +===================================================================+
-- | Name : GL_AVG_END_RATES_EXT                                       |
-- | Description : extract the period exchange rates on a              |
-- |               daily basis from Oracle General Ledger and copies   |
-- |               on to a data file                                   |
-- | Parameters :  x_error_buff, x_ret_code,p_run_date                 |
-- | Returns :     Returns Code                                        |
-- |               Error Message                                       |
-- +===================================================================+

   PROCEDURE GL_AVG_END_RATES_EXT(
                                  x_err_buff    OUT NOCOPY       VARCHAR2
                                 ,x_ret_code    OUT NOCOPY       VARCHAR2
                                 ,p_period_name    IN            VARCHAR2
                                 )
   AS

      ------------------------ Cursor to fetch the exchange rates --------------------------

      CURSOR c_exchange_rates
      IS
      SELECT GTR.avg_rate
            ,GTR.eop_rate
            ,GTR.to_currency_code
            ,GTR.set_of_books_id
            ,GTR.period_name
      FROM  gl_translation_rates GTR
           ,gl_sets_of_books GSB
      WHERE GTR.period_name     = p_period_name
      AND   GTR.set_of_books_id = GSB.set_of_books_id 
      AND   GSB.period_set_name = 'OD 445 CALENDAR'
      AND GTR.to_currency_code IN (
                                  SELECT FDC.currency_code
                                  FROM fnd_currencies FDC
                                  WHERE FDC.enabled_flag = 'Y'
                                  );

       --------------------------- Declaring local variables --------------------------------

      lc_conversion_type      gl_daily_conversion_types.user_conversion_type%TYPE;
      lc_from_currency_code   gl_translation_rates.to_currency_code%TYPE ;
      lc_to_currency_code     gl_translation_rates.to_currency_code%TYPE;
      lc_avg_rate             VARCHAR2(20);
      lc_end_rate             VARCHAR2(20);
      lc_error_message        VARCHAR2(4000);
      lc_error_loc            VARCHAR2(2000);
      ln_req_id               NUMBER(10);
      lc_rec_status           VARCHAR2(1) DEFAULT 'Y';
      lc_sob_name             gl_sets_of_books.short_name%TYPE;
      lc_actual_flag          gl_translation_rates.actual_flag%TYPE;
      lc_file_name            VARCHAR2(50);
      lc_file_path            VARCHAR2(500) := 'XXFIN_OUTBOUND';
      lc_source_file_path     VARCHAR2(500) ;
      lc_dest_file_path       VARCHAR2(500) := '$XXFIN_DATA/ftp/out/hyperion';
      lc_archive_file_path    VARCHAR2(500) := '$XXFIN_ARCHIVE/outbound';
      lc_rec_exist            BOOLEAN := FALSE;

      lt_file                 UTL_FILE.FILE_TYPE;
      ln_buffer               BINARY_INTEGER := 32767;

      lc_email_address        VARCHAR2(500);
      lc_source_file_name     VARCHAR2(500);
      lc_dest_file_name       VARCHAR2(500);

      lc_phase             VARCHAR2(50); 
      lc_status            VARCHAR2(50);
      lc_devphase          VARCHAR2(50);
      lc_devstatus         VARCHAR2(50);
      lc_message           VARCHAR2(50);
      lb_req_status        BOOLEAN;

      -------------------------- Extracting Exchange Rate ------------------------------

      BEGIN

         lc_avg_rate  := 'Average Rate';
         lc_end_rate  := 'Ending Rate';
       
         lc_file_name := 'ORAGL_PERIOD_XRATES_' || TO_CHAR(TO_DATE(p_period_name,'MON-YY'),'YYYYMM')|| '.TXT';

         FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'The Period Name       : ' || p_period_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Name : ' || lc_file_name);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Period Name       : ' || p_period_name);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name : ' || lc_file_name);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');

          --- Fetching the XXFIN_OUTBOUND Directory Path from the table
         BEGIN
            SELECT directory_path
            INTO   lc_source_file_path
            FROM   dba_directories
            WHERE  directory_name = lc_file_path;
         EXCEPTION
         WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the File Path XXFIN_OUTBOUND. '
                                                  || SQLERRM);
         END;
 
       -------------------- Writing into text file for Hyperion Feed-------------------------

            FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path     : ' || lc_file_path);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path : ' || lc_dest_file_path);

         FOR lcu_avg_end_exchange_rates IN c_exchange_rates
         LOOP

     ----------------------- Added for from currency code based on SOB ID ---------------------

            BEGIN
               SELECT currency_code
               INTO lc_from_currency_code
               FROM gl_sets_of_books
               WHERE set_of_books_id = lcu_avg_end_exchange_rates.set_of_books_id;
            EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the Currency for SOB '
                                                    || lcu_avg_end_exchange_rates.set_of_books_id);
            END;

            
            IF lc_rec_exist  = FALSE THEN
               lt_file      := UTL_FILE.fopen(lc_file_path, lc_file_name,'w',ln_buffer);
               lc_rec_exist := TRUE;
            END IF;

          -------------------------- Writing AVERAGE RATE into text file --------------------------

            BEGIN
               UTL_FILE.PUT_LINE(lt_file, lc_avg_rate
                                || '|'  || lcu_avg_end_exchange_rates.period_name
                                || '|'  || lc_from_currency_code
                                || '|'  || lcu_avg_end_exchange_rates.to_currency_code
                                || '|'  || lcu_avg_end_exchange_rates.avg_rate
                                );

          ---------------------------- Writing ENDING RATE into text file ------------------------

               UTL_FILE.PUT_LINE(lt_file, lc_end_rate
                                 || '|'   || lcu_avg_end_exchange_rates.period_name
                                || '|'   || lc_from_currency_code
                                || '|'   || lcu_avg_end_exchange_rates.to_currency_code
                                || '|'   || lcu_avg_end_exchange_rates.eop_rate
                                );

            EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while writing into Text file');
            END;
         END LOOP;

         IF lc_rec_exist = TRUE THEN
            UTL_FILE.fclose(lt_file);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Exchange Rates have been successsfully written into the file ' 
                              || lc_file_name);

        -------------------- Call the Common file copy Program Copy to $XXFIN_DATA/ftp/out/hyperion --------------

               lc_source_file_name  := lc_source_file_path || '/' || lc_file_name;
               lc_dest_file_name    := lc_dest_file_path || '/' || lc_file_name;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copied  Path     : ' || lc_dest_file_name);

            ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                    'xxfin'
                                                    ,'XXCOMFILCOPY'
                                                    ,'OD: Common File Copy'
                                                    ,''
                                                    ,FALSE
                                                    ,lc_source_file_name
                                                    ,lc_dest_file_name
                                                    ,NULL
                                                    ,NULL
                                                    );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File was Copied into ' ||  lc_dest_file_path
                                         || '. Request id : ' || ln_req_id);

          -------------- Call the Common file copy Program Archive to $XXFIN_ARCHIVE/outbound-----------------

               lc_dest_file_name    := lc_archive_file_path || '/' || lc_file_name;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Arichived File Path   : ' || lc_dest_file_name);

            ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                    'xxfin'
                                                    ,'XXCOMFILCOPY'
                                                    ,'OD: Common File Copy'
                                                    ,''
                                                    ,FALSE
                                                    ,lc_source_file_name
                                                    ,lc_dest_file_name
                                                    ,NULL
                                                    ,NULL
                                                    );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File was Archived into ' ||  lc_archive_file_path
                                         || '. Request id : ' || ln_req_id);
            COMMIT;

        ------------------- Wait till the the Common file copy Program to Complete -----------------

            lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                            request_id  => ln_req_id
                                                            ,interval    => '2'
                                                            ,max_wait    => ''
                                                            ,phase       => lc_phase 
                                                            ,status      => lc_status
                                                            ,dev_phase   => lc_devphase
                                                            ,dev_status  => lc_devstatus
                                                            ,message     => lc_message
                                                            );


            BEGIN
               UTL_FILE.FREMOVE(lc_file_path, lc_file_name);
            EXCEPTION
            WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Removing the file '
                                                        || lc_file_path || lc_file_name || SQLERRM);
            END;


         ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Average Rates and Ending Rate present for Period : ' || p_period_name );
            FND_FILE.PUT_LINE(FND_FILE.LOG,   'No Average Rates and Ending Rate present for Period : ' || p_period_name );

         END IF;

        --------------------- Sending Output file to the concerned Person -------------------------

         lc_email_address := FND_PROFILE.VALUE('GL_ERROR_OUTPUT_EMAIL_ID');

         ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                 'xxfin'
                                                 ,'XXODROEMAILER'
                                                 ,'OD: Concurrent Request Output Emailer Program'
                                                 ,''
                                                 ,FALSE
                                                 ,'OD: GL Exchange Rates Extract Program'
                                                 ,lc_email_address
                                                 ,'GL Exchange Rate Error Records Output File'
                                                 ,'GL Exchange Rate Error Records Output File'
                                                 ,'Y'
                                                 ,FND_GLOBAL.CONC_REQUEST_ID
                                                 );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Output File was sent to ' || lc_email_address
                                           || '. Request id : ' || ln_req_id);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'*************************************************************');

      END GL_AVG_END_RATES_EXT;
END XX_GL_BAL_RATES_EXT_PKG;
/
SHOW ERROR
