SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_VPS_TRX_DUE_DT_DISCREPANCY
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_VPS_TRX_DUE_DT_DISCREPANCY                                                    |
  -- |                                                                                            |
  -- |  Description:  Package created ofr VPS Transactions Due Date Discrepancy Report            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         06/12/2018   Havish Kasina    Initial version                                  |
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

P_FROM_DATE             VARCHAR2(15);
P_TO_DATE               VARCHAR2(15);
P_SMTP_SERVER           VARCHAR2(30);
P_CONC_REQUEST_ID  		NUMBER;

END XX_VPS_TRX_DUE_DT_DISCREPANCY;
/

SHOW ERRORS;