SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

REATE OR REPLACE PACKAGE XX_WFL_PO_TRANSMITTED_PKG AUTHID CURRENT_USER
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_WFL_PO_TRANSMITTED_PKG.pkb                        |
-- | Description: This is to prevent email/Fax PO communication to     |
-- | Supplier.  PO outbound interface should cover the logic to prevent|
-- | EDI/XML communications for purchase price change. 'Trade Import'  |
-- | PO type will be communicated to supplier                          |
-- | for purchase price change                                         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 23-Jul-2007  Sriramdas S      Initial draft version       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE set_transmitted_data
(
  itemtype  IN            VARCHAR2
 ,itemkey   IN            VARCHAR2
 ,actid     IN            PLS_INTEGER
 ,funcmode  IN            VARCHAR2
 ,resultout IN OUT NOCOPY VARCHAR2
);

END XX_WFL_PO_TRANSMITTED_PKG;
/

SHOW ERRORS;

EXIT;
REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
