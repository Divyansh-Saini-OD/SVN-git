CREATE OR REPLACE PROCEDURE XXOD_DELETE_AP_CC_DATA(
                                 p_start_id IN NUMBER,
                                 p_end_id   IN NUMBER)
AS

TYPE bank_acct_id_t
IS
  TABLE OF AP_BANK_ACCOUNTS_ALL.BANK_ACCOUNT_ID%TYPE;
  bank_acct_ids bank_acct_id_t;
  
BEGIN

  DELETE AP_BANK_ACCOUNTS_ALL ABA
  WHERE aba.ACCOUNT_TYPE = 'EXTERNAL'
  AND aba.BANK_BRANCH_ID = 1 -- CREDIT CARD ONLY
  AND aba.BANK_ACCOUNT_ID BETWEEN p_start_id AND p_end_id
  AND EXISTS
    (SELECT
      /*+ USE_HASH(CC XAIO) */
      1
    FROM AP_BANK_ACCOUNT_USES_ALL CC,
         XX_AR_INTSTORE_R12_TEMP XAIO
    WHERE cc.OWNING_PARTY_ID        = xaio.PARTY_ID
    AND cc.EXTERNAL_BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
    AND cc.EXTERNAL_BANK_ACCOUNT_ID BETWEEN p_start_id AND p_end_id
    ) RETURNING BANK_ACCOUNT_ID 
    BULK COLLECT INTO bank_acct_ids;
	
	
  IF bank_acct_ids.count > 0 THEN -- Added by Madhu Bolli
    FOR i IN bank_acct_ids.FIRST .. bank_acct_ids.LAST
    LOOP
      DELETE ap_bank_account_uses_all cc
      WHERE cc.EXTERNAL_BANK_ACCOUNT_ID = bank_acct_ids(i);
    END LOOP;
  END IF;
  
  COMMIT;
END XXOD_DELETE_AP_CC_DATA;
/
