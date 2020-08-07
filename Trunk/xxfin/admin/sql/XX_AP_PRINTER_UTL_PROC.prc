create or replace
PROCEDURE XX_AP_PRINTER_UTL_PROC(  errbuf OUT     VARCHAR2
                                  ,retcode OUT    NUMBER
                                  ,p_printer_name VARCHAR2  DEFAULT NULL
                                  ,p_activate_flg VARCHAR2  DEFAULT 'N'  
                                                  ) 
IS                                 
-- +============================================================================+
-- |                   Office Depot Project Simplify                            |
-- |                                                                            |
-- +============================================================================+
-- |Name        : AP Check Printer activate printer types                       |
-- |Rice Id     : I0228                                                         |  
-- |Change record                                                               |
-- |================                                                            |
-- |version       Date            Author                Remarks                 |
-- |========      ======         ==========             =======                 |
-- | Draft        28-JUL_2009    Peter Marco            Initial Version         |
-- | 1.1          05-NOV-2015    Harvinder Rakhra       Retrofit R12.2          |
-- +============================================================================+
-- +============================================================================+
-- | Parameters:  x_err_buf, x_ret_code,p_printer_name                          | 
-- |              ,p_path,p_scot_filename,p_wach_filename,                      |
-- |               p_activate_flg                                               |
-- |                                                                            |
-- | Returns   : Error Message,Error Code                                       |
-- +============================================================================+


    lc_db_name  VARCHAR2(10);
 

BEGIN


   SELECT name 
     INTO lc_db_name
     FROM V$database;

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AP_PRINTER_UTL_PROC submitted in ' || lc_db_name);


   IF lc_db_name <> 'GSIPRDGB' THEN

       IF p_printer_name IS NULL  THEN

          IF   p_activate_flg  = 'N'  THEN
 
              UPDATE FND_PRINTER set PRINTER_TYPE = 'XXDUMMY'
               WHERE PRINTER_NAME IN ('qNUVERA2US','qNUVERA2OVFL','qNUVERA2CAN','qNUVERA2CANUSD',
                                      'PRB999','PRB999OVFLW');
              COMMIT;

          ELSE
            
            
              UPDATE FND_PRINTER set PRINTER_TYPE = '--PASTA Universal Printer Type'
              WHERE PRINTER_NAME IN ('qNUVERA2US','qNUVERA2OVFL','qNUVERA2CAN','qNUVERA2CANUSD',
                                     'PRB999','PRB999OVFLW');
              COMMIT;   

          END IF;

        ELSE

            IF   p_activate_flg  = 'N'  THEN
 
               UPDATE FND_PRINTER set PRINTER_TYPE = 'XXDUMMY'
                WHERE PRINTER_NAME = p_printer_name;

                COMMIT;

            ELSE
            
            
               UPDATE FND_PRINTER set PRINTER_TYPE = '--PASTA Universal Printer Type'
               WHERE PRINTER_NAME = p_printer_name;

               COMMIT;   
   
           END IF;                


        END IF;

    ELSE

             FND_FILE.PUT_LINE(FND_FILE.LOG, 'XX_AP_PRINTER_UTL_PROC cannot be submitted in ' || lc_db_name);

    END IF; 


EXCEPTION
  WHEN OTHERS THEN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception' || SQLERRM ());

    retcode := 1;
   
END XX_AP_PRINTER_UTL_PROC;


/
