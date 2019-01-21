SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_COMN_GSCC_VIOLATIONS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_COMN_GSCC_VIOLATIONS_PKG                                                      |
  -- |                                                                                            |
  -- |  Description:  Package created to provide GSCC Violations in Database Objects              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         10/02/2018   Havish Kasina    Initial version                                  |
  -- +============================================================================================+
  
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  afterReport                                                                      |
  -- |                                                                                            |
  -- |  Description:  Common Report for XML bursting                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  
FUNCTION beforeReport RETURN BOOLEAN;

FUNCTION afterReport RETURN BOOLEAN;

P_CONC_REQUEST_ID  		NUMBER;

END XX_COMN_GSCC_VIOLATIONS_PKG;
/

SHOW ERRORS;