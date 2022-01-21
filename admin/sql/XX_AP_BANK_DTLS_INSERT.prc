SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT RECOVER PROCEDURE for bank account details

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PROCEDURE XX_AP_BANK_DTLS_INSERT
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Delete Script for Bank Account Dtls                 |
-- | Description : To delete from ap bank accounts and bank uses       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      22-NOV-2008  Prakash Sankaran      Initial version        |
-- +===================================================================+
IS
BEGIN

  apps.fnd_global.apps_initialize(1150,51263,660);
  

  INSERT INTO AP.AP_BANK_ACCOUNTS_ALL
  SELECT *
  FROM APPS_RO.XX_AP_BANK_ACCOUNTS;
  
	DBMS_OUTPUT.PUT_LINE('ROWS INSERTED INTO AP_BANK_ACCOUNTS_ALL : ' || SQL%ROWCOUNT);
  

  
  INSERT INTO AP.AP_BANK_ACCOUNT_USES_ALL
  SELECT *
  FROM APPS_RO.XX_AP_BANK_ACCOUNT_USES;
  
 	DBMS_OUTPUT.PUT_LINE('ROWS INSERTED INTO AP_BANK_ACCOUNT_USES_ALL : ' || SQL%ROWCOUNT);


	COMMIT;

END XX_AP_BANK_DTLS_INSERT;

/
SHOW ERROR;

EXEC XX_AP_BANK_DTLS_INSERT;
