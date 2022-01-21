SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_AP_RTVCONS_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_RTVCONS_PKG                                  |
  -- | Description      :    Package for Chargeback RTV Consignment             |
  -- | RICE ID          :    R7040                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      15-Jan-2018  Phani Teja R          Initial                      |
  -- | 1.1      06-Feb-2018  Phani Teja R          Added date parameters        | 
  -- +==========================================================================+
FUNCTION findDispCode(P_INVOICE_NBR VARCHAR2) RETURN VARCHAR2;
FUNCTION beforeReport RETURN BOOLEAN;
FUNCTION afterReport RETURN BOOLEAN;
P_FREQUENCY         	VARCHAR2(10);
P_START_DATE            DATE;
P_END_DATE              DATE;
G_SMTP_SERVER 		  	VARCHAR2(250);
G_DISTRIBUTION_LIST 	VARCHAR2(500);
G_EMAIL_SUBJECT     	VARCHAR2(250);
g_EMAIL_CONTENT     	VARCHAR2(500);
G_INSTANCE				VARCHAR2(25);
G_WHERE_CLAUSE      	VARCHAR2(2000);
END XX_AP_RTVCONS_PKG;

/

SHOW ERRORS;