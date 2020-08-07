SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_FIN_MISSING_AP_CONTACT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_FIN_MISSING_AP_CONTACT_PKG                                                    |
  -- |                                                                                            |
  -- |  Description:  Package created for Customer sites missing AP contacts Report               |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         09/10/2018   Havish Kasina    Initial version                                  |
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
P_MAIL_FROM             VARCHAR2(500);
P_MAIL_TO               VARCHAR2(500);

END XX_FIN_MISSING_AP_CONTACT_PKG;
/

SHOW ERRORS;