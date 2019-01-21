CREATE OR REPLACE PACKAGE XX_LEAD_ADDR_DATA_FIX_PKG
AS

PROCEDURE XX_LEAD_ADDR_DATA_FIX_PROC (   x_errbuf  OUT VARCHAR2
                                        ,x_retcode OUT NUMBER
                                        ,p_commit_flag IN VARCHAR2 
                                        ,p_process_status IN VARCHAR2);
END XX_LEAD_ADDR_DATA_FIX_PKG;
/
SHOW ERRORS;