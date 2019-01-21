SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_TENDER_AMT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AR_TENDER_AMT_PKG  
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        :XX_AR_TENDER_AMT_PKG                                      |
-- | RICE ID     :E1022                                                    |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: AR Payment Extraction    |
 --|              Report and the default format is XML                      |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  06-JUN-09     Ganga Devi R        Initial version             |
-- |                                                                        |
-- +========================================================================+

-- +=====================================================================+  |
-- | Name        : XX_AR_TENDER_AMT_PROC                                    |
-- | Description : The procedure will submit the OD: AR Payment Extraction  |
 --|               Report                                                   |
-- | Parameters  : P_TRXN_DATE_FROM,P_TRXN_DATE_TO                          |
-- | Returns     : x_err_buff,x_ret_code                                    |
-- +========================================================================+

PROCEDURE XX_AR_TENDER_AMT_PROC(
                                x_err_buff           OUT VARCHAR2
                               ,x_ret_code           OUT NUMBER
	                       ,P_TRXN_DATE_FROM     IN  VARCHAR2
                               ,P_TRXN_DATE_TO       IN  VARCHAR2
                               );


END  XX_AR_TENDER_AMT_PKG;
/

SHO ERR;