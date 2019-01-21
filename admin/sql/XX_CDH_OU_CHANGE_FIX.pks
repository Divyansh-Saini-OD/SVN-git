SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_OU_CHANGE_FIX 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_OU_CHANGE_FIX                                       |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Code to Correct Existing DIRECT CUSTOMER OU Data           |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      20-Oct-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+

AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
PROCEDURE ou_fix_main (
                  x_errbuf              OUT NOCOPY VARCHAR2,
                  x_retcode             OUT NOCOPY VARCHAR2,
                  p_process_billto_dup  IN VARCHAR2,
                  p_commit              IN VARCHAR2
                 );
END XX_CDH_OU_CHANGE_FIX;
/
SHOW ERRORS;