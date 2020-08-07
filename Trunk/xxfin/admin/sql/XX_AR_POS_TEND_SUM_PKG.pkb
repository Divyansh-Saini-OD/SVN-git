create or replace
PACKAGE BODY      XX_AR_POS_TEND_SUM_PKG 
AS
procedure main (x_errbuf            OUT NOCOPY      VARCHAR2
                ,x_retcode           OUT NOCOPY      VARCHAR2
                ,P_TRX_DATE_FROM    IN              varchar2
                ,P_TRX_DATE_TO      IN              varchar2
                ,P_GL_DATE_FROM        IN              varchar2
                ,P_GL_DATE_TO       IN              varchar2
                ,P_STORE            IN              varchar2) 
               IS
-- Main Procedure 
-- --------------
ln_request_id NUMBER ;
lb_layout BOOLEAN ;
lb_print_option BOOLEAN ; 
BEGIN
    -- Set the Printer Option
    -- ----------------------

   lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                     printer  => 'XPTR'
                                                    ,copies   => 1
                                                   );
  
     -- Set the Output File Format
    -- --------------------------
  
   lb_layout := FND_REQUEST.ADD_LAYOUT(
                                      'XXFIN'
                                     ,'XXARPOSTEND'
                                     ,'en'
                                     ,'US'
                                     ,'EXCEL'
                                     );
 
    -- Submit the program ¿ OD: AR POS Tender Summary by Store Report
    -- -------------------------------------------------------------

   ln_request_id := FND_REQUEST.SUBMIT_REQUEST(application => 'XXFIN'
                                              ,program => 'XXARPOSTEND'
                                              ,argument1=> to_date (P_TRX_DATE_FROM, 'RRRR/MM/DD HH24:MI:SS')
                                              ,argument2 => to_date (P_TRX_DATE_TO, 'RRRR/MM/DD HH24:MI:SS')
                                              ,argument3 => to_date (P_GL_DATE_FROM, 'RRRR/MM/DD HH24:MI:SS')
                                              ,argument4 => to_date (P_GL_DATE_TO, 'RRRR/MM/DD HH24:MI:SS')
                                              ,argument5 => P_STORE 
                                              );

  COMMIT;    
    
END main;
END ;
/ 