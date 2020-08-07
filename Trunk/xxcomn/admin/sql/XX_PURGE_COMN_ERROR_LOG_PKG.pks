SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PURGE_COMN_ERROR_LOG_PKG AUTHID CURRENT_USER
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Oracle NAIO Consulting Organization                            |
-- +===============================================================================+
-- | Name        :  XX_PURGE_COMN_ERROR_LOG_PKG.pks                                |
-- | Description :  This package will purge the records from the common            |
-- |                error log table                                                |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date           Author                      Remarks                   |
-- |========  =========== ================== ======================================|
-- |Draft 1A  12-SEP-2007  Ritu Shukla               Initial Draft                 |
-- |Draft 1B  13-SEP-2007  Ritu Shukla               Updated after Review          |
-- |Draft 1C  19-MAR-2008  Jeevan Babu                  Removed the error flag     |
-- |                                                    Parameter refers from      |
-- |                                                    purge_common_error_log api |
-- |1.0       28-Apr-2008  Rajeev Kamath     Removed commented lines               |
-- |                                         Added procedure to delete by module   |
-- |                                         and optional program name             |
-- +===============================================================================+
AS
PROCEDURE purge_common_error_log ( x_errbuf               OUT NOCOPY VARCHAR2
                                  ,x_retcode              OUT NOCOPY VARCHAR2
                                  ,p_age                  IN         NUMBER
                                 );
PROCEDURE purge_common_error_module_log ( x_errbuf               OUT NOCOPY VARCHAR2
                                         ,x_retcode              OUT NOCOPY VARCHAR2
                                         ,p_module               IN         VARCHAR2
                                         ,p_program              IN         VARCHAR2
                                         ,p_age                  IN         NUMBER
                                        );
END XX_PURGE_COMN_ERROR_LOG_PKG;
/

SHOW ERRORS

EXIT;