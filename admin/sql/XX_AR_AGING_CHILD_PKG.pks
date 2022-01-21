SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE SPECIFICATION XX_AR_AGING_CHILD_PKG
PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE  XX_AR_AGING_CHILD_PKG AS
 -- +=======================================================================================+
 -- |  NAME:      XX_AR_AGING_CHILD_PKG                                                     |
 -- | PURPOSE:    This package contains procedures to insert total aging bucket amount into |
 -- |             XX_AR_CUST_PAYMENT_TEMP table                                             |
 -- | REVISIONS:                                                                            |
 -- | Ver        Date        Author           Description                                   |
 -- | ---------  ----------  ---------------  ------------------------------------          |
 -- | 1.0        15/09/2010  Ganga Devi R     Initial version                               |
 -- ========================================================================================+

   PROCEDURE INSERT_INTO_TEMP ( x_errbuf                       OUT NOCOPY  VARCHAR2
                               ,x_retcode                      OUT NOCOPY  NUMBER
                               ,p_payment_schedule_id_low      IN          NUMBER
                               ,p_payment_schedule_id_high     IN          NUMBER
                               ,p_run_at_customer_level        IN          VARCHAR2
                               ,p_batch_size                   IN          NUMBER
                              );

END XX_AR_AGING_CHILD_PKG;
/
SHO ERROR
