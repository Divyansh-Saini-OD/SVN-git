SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_EXT_GUID_SYNC_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :  XX_EXT_GUID_SYNC_PKG.pkb                           |
-- | Description :  CDH External User GUID sync Package                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1   11-OCT-2014 Sreedhar Mohan     Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
    procedure sync_guid (
                           x_errbuf              OUT VARCHAR2
                          ,x_retcode             OUT VARCHAR2
                         );
END XX_EXT_GUID_SYNC_PKG;
/
