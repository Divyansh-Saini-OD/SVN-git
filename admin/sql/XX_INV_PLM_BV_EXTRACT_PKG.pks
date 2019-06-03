SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_PLM_BV_EXTRACT_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- +============================================================================================+ 
-- |  Name:  XX_INV_PLM_BV_EXTRACT_PKG                                                          | 
-- |  Description:                                                                              |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author             Remarks                                        | 
-- | =========   ===========  =============      =============================================  | 
-- | 1.0         13-JAN-2011  Bapuji Nanapaneni  Initial version                                |
-- |                                                                                            |
-- +============================================================================================+

PROCEDURE BV_EXTRACT;

END XX_INV_PLM_BV_EXTRACT_PKG;
/
SHOW ERRORS PACKAGE BODY XX_INV_PLM_BV_EXTRACT_PKG;
EXIT;
