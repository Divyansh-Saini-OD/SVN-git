SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Spec XX_AR_LOCKBOX_INTERIM

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_ar_lockbox_interim_pkg
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name : populate_lockbox_interim                                         |
-- | Description : Procedure to insert the values in interim tables          |
-- |                                                                  .      |
-- |                                                                         |
-- | Parameters :    Errbuf and retcode                                      |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============   ==================================|
-- |   1      28-OCT-11   P.Sankaran   Initial version                       |
-- +==========================================================================+
   PROCEDURE populate_lockbox_interim (
      errbuf OUT VARCHAR2
    , retcode OUT NUMBER
   );
END xx_ar_lockbox_interim_pkg;
/

SHOW ERROR
   
