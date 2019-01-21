SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_ABL_CUSTOMERS_PKG
-- +===================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.1                         |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  PRINT_CUSTOMER_DETAILS                                        |
-- |                                                                                   |
-- | Description      : Reporting package for all AB Customers                         |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1.0 12-Oct-09   Sreedhar Mohan               Draft version                   |
-- +===================================================================================+
AS

PROCEDURE PRINT_CUSTOMER_DETAILS ( p_errbuf            OUT NOCOPY VARCHAR2
                                   , p_retcode         OUT NOCOPY VARCHAR2               
                                 );
END XX_CDH_ABL_CUSTOMERS_PKG;
/
SHOW ERRORS;
