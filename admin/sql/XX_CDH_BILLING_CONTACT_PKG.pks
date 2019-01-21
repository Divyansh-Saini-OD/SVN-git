SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OF
SET TERM ON
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_CDH_BILLING_CONTACT_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                                                                        |
-- +========================================================================+
-- | Name        : XX_CDH_BILLING_CONTACTS_PKG                              |
-- | Description : 1) To import Billing contacts and contact points into    |
-- |                  Oracle.                                               |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      07-Jul-2012  Devendra Petkar       Initial version             |
-- +========================================================================+


   PROCEDURE xx_cdh_billing_contact_main (
       x_errbuf       OUT NOCOPY      VARCHAR2
      ,x_retcode      OUT NOCOPY      VARCHAR2
      ,p_debug_flag   IN              VARCHAR2
      ,p_batch_id     IN              NUMBER
   );

END XX_CDH_BILLING_CONTACT_PKG;
/
SHOW ERROR

