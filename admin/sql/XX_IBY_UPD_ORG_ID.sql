-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | RICE ID     :  R1053                                                     |
-- | Name        :  CC Settlement Report                                      |
-- |                                                                          |
-- | SQL Script to update the follwing object                                 |
-- |             Table       : XX_IBY_BATCH_TRXNS_HISTORY                     |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     24-JUL-2008  Aravind A.           Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

UPDATE (SELECT XIBTH.attribute7 cash_rec_id
              ,XIBTH.org_id cus_org
              ,XIBTH.attribute8 cntry_code
              ,ACRA.org_id bas_org
        FROM xx_iby_batch_trxns_history XIBTH
             ,ar_cash_receipts_all ACRA
        WHERE XIBTH.attribute7 = ACRA.cash_receipt_id)
SET cus_org = bas_org
    ,cntry_code = NULL; 

COMMIT;

SHOW ERROR;