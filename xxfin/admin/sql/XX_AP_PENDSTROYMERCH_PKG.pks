SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_PENDSTROYMERCH_PKG
AS
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name             :    XX_AP_PENDSTROYMERCH_PKG                           |
-- | Description      :    Package for Pending Destroyed Merchandised Report  |
-- | RICE ID          :    R7033                                              |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      27-Sep-2017  Prabeethsoy Nair      Initial                      |
-- | 1.1	  10-Nov-2017  Jitendra Atale		Added Email bursting          |
-- +==========================================================================+

FUNCTION beforeReport 	RETURN BOOLEAN;
FUNCTION afterReport  	RETURN BOOLEAN;
G_SMTP_SERVER 		  	VARCHAR2(250);
G_DISTRIBUTION_LIST 	VARCHAR2(500);
G_EMAIL_SUBJECT     	VARCHAR2(250);
g_EMAIL_CONTENT     	VARCHAR2(500);
P_CONC_REQUEST_ID  		NUMBER;
P_FREQUENCY         	VARCHAR2(10);
P_RUN_DATE           date;
P_INSTANCE          	VARCHAR2(30);
G_where_clause      	VARCHAR2(2000);
G_REC_COUNT           	NUMBER;
G_INSTANCE				VARCHAR2(25);
END;
/

SHOW ERROR;