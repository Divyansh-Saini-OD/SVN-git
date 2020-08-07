SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE SPECIFICATION XX_AR_AGING_WRAP_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE  XX_AR_AGING_WRAP_PKG AS
-- +=======================================================================================+
-- |  NAME:      XX_AR_AGING_WRAP_PKG                                                      |
-- | PURPOSE:    This package contains procedures to calculate total aging bucket amount   |
-- | REVISIONS:                                                                            |
-- | Ver        Date        Author           Description                                   |
-- | ---------  ----------  ---------------  ------------------------------------          |
-- | 1.0        15/09/2010  Ganga Devi R     Initial version                               |
-- ========================================================================================+

   PROCEDURE AR_AGING_BUCKETS  ( x_errbuf                  OUT NOCOPY  VARCHAR2
                                ,x_retcode                 OUT NOCOPY  NUMBER
                                ,p_thread_count            IN          NUMBER
                                ,p_run_at_customer_level   IN          VARCHAR2
                                ,p_batch_size              IN          NUMBER
                                ,p_run_interim_pgm         IN          VARCHAR2
                               );

END XX_AR_AGING_WRAP_PKG;
/
SHO ERROR
