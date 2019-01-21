SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
 
create or replace
PACKAGE XX_CDH_SEAMLESS_CONV_DUMMY
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_SEAMLESS_CONV_DUMMY                                 |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Dummy process to synchronize the Seamless Run              | 
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      29-May-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS
  PROCEDURE DUMMY_MAIN(
                  p_errbuf   OUT NOCOPY VARCHAR2,
                  p_retcode  OUT NOCOPY VARCHAR2,
                  p_source_system IN VARCHAR2
                );
                
END XX_CDH_SEAMLESS_CONV_DUMMY;
/
SHOW ERRORS;
