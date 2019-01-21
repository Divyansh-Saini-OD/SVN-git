SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_ESP_JOB_SCHEDULER 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_ESP_JOB_SCHEDULER                                   |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Program used to control ESP Scheduling                     |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      12-Dec-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS

PROCEDURE MAIN (
      x_errbuf                OUT   VARCHAR2
     ,x_retcode               OUT   VARCHAR2 
    );

END XX_CDH_ESP_JOB_SCHEDULER;
/
SHOW ERRORS;