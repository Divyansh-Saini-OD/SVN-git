CREATE OR REPLACE package XX_ARCHIVE_POC
AS
PROCEDURE xxra2( x_err_buff  OUT VARCHAR2
                ,x_ret_code  OUT NUMBER);
END xx_archive_POC;
/

show errors
