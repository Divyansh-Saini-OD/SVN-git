create or replace 
PACKAGE xx_purge_comn_errlog_wrap_pkg AUTHID CURRENT_USER
  -- +===============================================================================+
  -- |                  Office Depot - Project Simplify                              |
  -- |                Oracle GSD Consulting Organization                             |
  -- +===============================================================================+
  -- | Name        :  XX_PURGE_COMN_ERRLOG_WRAP_PKG.pks                              |
  -- | Description :  This package is wrapper for purge common error log             |
  -- | Subversion Info:                                                              |
  -- |                                                                               |
  -- |   $HeadURL: $
  -- |       $Rev: $
  -- |      $Date: $
  -- |                                                                               |
  -- |                                                                               |
  -- |Change Record:                                                                 |
  -- |===============                                                                |
  -- |Version   Date           Author                      Remarks                   |
  -- |========  =========== ================== ======================================|
  -- |1.0       7-NOV-2014   Sridevi K               Initial Version                 |
  -- +===============================================================================+
AS
  PROCEDURE main(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY VARCHAR2 ,    
    p_module_name  IN VARCHAR2,
    p_program_name IN VARCHAR2,
    p_run_day      IN VARCHAR2);

END xx_purge_comn_errlog_wrap_pkg;
/

SHOW ERRORS;

