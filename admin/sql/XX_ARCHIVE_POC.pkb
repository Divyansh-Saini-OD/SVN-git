create or replace
PACKAGE BODY XX_ARCHIVE_POC 
AS
   PROCEDURE xxra2 ( x_err_buff  OUT  VARCHAR2
                    ,x_ret_code  OUT  NUMBER)
   IS
     ln_count number;
   BEGIN
     select count(1) 
       into ln_count
       from XXAPPS_HISTORY_QUERY.gl_je_lines
      where period_name = 'DEC-05' 
        and je_header_id = 1022;
    
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'count: '||ln_count);
   END;

END XX_ARCHIVE_POC;
/
SHOW ERRORS
