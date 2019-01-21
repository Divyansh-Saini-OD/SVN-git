SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_CDH_WC_COPY_SITE_PROFS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                  Web Collect Integrations                                               |
-- +=========================================================================================+
-- | Name        : XX_CDH_CREATE_SITE_PROFS.pks                                              |
-- | Description : This package is developed to copy customer profiles  from customer level  |
-- |               site level for the customers that were become eligible in WC Deltas.      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        14-Apr-2012     Sreedhar Mohan       Draft                                    |
-- +=========================================================================================+
as
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug_flag      IN       VARCHAR2
     );
end XX_CDH_WC_COPY_SITE_PROFS;
/
SHOW ERR;