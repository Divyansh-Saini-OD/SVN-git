SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Procedure XX_IBY_CNTRY_COD_UPD_PROC
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PROCEDURE XX_IBY_CNTRY_COD_UPD_PROC
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                       WIPRO Technologies                                |
-- +=========================================================================+
-- | Name :      XX_IBY_CNTRY_COD_UPD_PROC                                   |
-- | Description : Update country code in history table                      |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date          Author              Remarks                      |
-- |=======   ==========   =============        =============================|
-- |1.0       23-JUL-2007  Aravind A.           Initial version              |
-- +=========================================================================+

AS

CURSOR lcu_cntry_code
IS
   SELECT XIBTH.attribute7   cash_rec_id
          ,XIBTH.attribute8  country_code
          ,DECODE(
                  ACRA.org_id
                  ,404
                  ,'US'
                  ,403
                  ,'CA'
                  )         cntry_code
   FROM  xx_iby_batch_trxns_history XIBTH
        ,ar_cash_receipts_all ACRA
   WHERE XIBTH.attribute7 = ACRA.cash_receipt_id
   FOR UPDATE OF XIBTH.attribute8;

BEGIN

   FOR cntry_code_rec IN lcu_cntry_code
   LOOP

   UPDATE xx_iby_batch_trxns_history
   SET attribute8 = cntry_code_rec.cntry_code
   WHERE CURRENT OF lcu_cntry_code;

   END LOOP;

	COMMIT;

	DBMS_OUTPUT.PUT_LINE('Successfully updated the records');

EXCEPTION

   WHEN OTHERS THEN
	   DBMS_OUTPUT.PUT_LINE('Error occured in XX_IBY_CNTRY_COD_UPD_PROC procedure');
		DBMS_OUTPUT.PUT_LINE('The error is...'||SQLERRM||' and error code is...'||SQLCODE);
		ROLLBACK;

END XX_IBY_CNTRY_COD_UPD_PROC;

/

SHOW ERROR