SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_COPY_CUST_PROFILES
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_COPY_CUST_PROFILES                                  |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Copies the Customer Profile values from account level      |
-- |               to site level if the dunning_letters='Y' for 'Bill_TO' use |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      05-Nov-2007 Sreedhar Mohan         Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  PROCEDURE MAIN(
                  p_errbuf   OUT NOCOPY VARCHAR2,
                  p_retcode  OUT NOCOPY VARCHAR2
                );

END XX_CDH_COPY_CUST_PROFILES;
/

SHOW ERRORS;
