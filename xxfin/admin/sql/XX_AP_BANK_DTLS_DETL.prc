SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT DELETE PROCEDURE for bank account details

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PROCEDURE XX_AP_BANK_DTLS_DETL
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
-- |1.0      20-NOV-2008  Rama Krishna K        Initial version        |
-- |1.1      21-NOV-2008  Rama Krishna K        To delete all data     |
-- |1.2      05-DEC-2008  Rama Krishna K        added more filter cond |
-- |1.3      11-DEC-2008  Rama Krishna K        added log msgs for     |
-- |                                            count, remove hard code|
-- +===================================================================+
IS
ln_cnt1 NUMBER := 0;
BEGIN

  apps.fnd_global.apps_initialize(1150,51263,660);

	DELETE FROM ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) <> ' '
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9');

	dbms_output.put_line('1 => Rows Deleted : ' || SQL%ROWCOUNT);

	DELETE FROM ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) <> ' '
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('2 => Rows Deleted : ' || SQL%ROWCOUNT);	
	
	DELETE FROM ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) = ' '
        AND    SUBSTR(BANK_ACCOUNT_NAME, 7, 1) = ':'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 1, 6) < '999999'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9');

	dbms_output.put_line('3 => Rows Deleted : ' || SQL%ROWCOUNT);

	DELETE FROM ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) = ' '
        AND    SUBSTR(BANK_ACCOUNT_NAME, 7, 1) = ':'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 1, 6) < '999999'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('4 => Rows Deleted : ' || SQL%ROWCOUNT);	

	DELETE FROM ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9'
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID);

	dbms_output.put_line('5 => Rows Deleted : ' || SQL%ROWCOUNT);

        -- New Statements added below on 5-DEC-2008
	DELETE FROM ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('6 => Rows Deleted : ' || SQL%ROWCOUNT);	
	

	COMMIT;

	-- Added below statement on 11-DEC-2008 for displaying logs
	dbms_output.put_line('Please see count below,post deletion and commit execution');	

	SELECT Count(1)
        INTO   ln_cnt1
        FROM   ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) <> ' '
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9');

	dbms_output.put_line('1 => Pending Rows for Deletion : ' || ln_cnt1);
        ln_cnt1:=0;

	SELECT Count(1)
        INTO   ln_cnt1
        FROM   ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) <> ' '
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('2 => Pending Rows for Deletion : ' || ln_cnt1);
        ln_cnt1:=0;
	
	SELECT Count(1)
        INTO   ln_cnt1
        FROM   ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) = ' '
        AND    SUBSTR(BANK_ACCOUNT_NAME, 7, 1) = ':'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 1, 6) < '999999'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9');

	dbms_output.put_line('3 => Pending Rows for Deletion : ' || ln_cnt1);
        ln_cnt1:=0;

	SELECT Count(1)
        INTO   ln_cnt1
        FROM   ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 10, 1) = ' '
        AND    SUBSTR(BANK_ACCOUNT_NAME, 7, 1) = ':'
        AND    SUBSTR(BANK_ACCOUNT_NAME, 1, 6) < '999999'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('4 => Pending Rows for Deletion : ' || ln_cnt1);
        ln_cnt1:=0;

	SELECT Count(1)
        INTO   ln_cnt1
        FROM   ap_bank_account_uses_all ABCU
        WHERE  EXISTS (SELECT BANK_ACCOUNT_ID FROM AP_BANK_ACCOUNTS_ALL ABA
        WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9'
        AND    ABA.BANK_ACCOUNT_ID = ABCU.EXTERNAL_BANK_ACCOUNT_ID);

	dbms_output.put_line('5 => Pending Rows for Deletion : ' || ln_cnt1);
        ln_cnt1:=0;

        -- New Statements added below on 5-DEC-2008
	DELETE FROM ap_bank_accounts_all ABA
	WHERE  ACCOUNT_TYPE = 'EXTERNAL'
        AND    LENGTH(BANK_ACCOUNT_NUM) = 25
        AND    substr(BANK_ACCOUNT_NUM, 1, 1) = '9';

	dbms_output.put_line('6 => Pending Rows for Deletion : ' || ln_cnt1);	
        ln_cnt1:=0;

END XX_AP_BANK_DTLS_DETL;
/
SHOW ERR