SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | SQL Script to insert into the following object                           |
-- |             Table    : XX_IBY_BATCH_TRXNS_HISTORY                        |
-- |                        Insert records from backup table                  |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date              Author               Remarks               |
-- |=======      ==========        =============        ===================== |
-- | V1.0        28-FEB-2009       Aravind A.           Initial version       |
-- |                                                    Defect 11482          |
-- +==========================================================================+

INSERT INTO XX_IBY_BATCH_TRXNS_201_HISTORY
SELECT * FROM XXFIN.XX_IBY_BAT_TRX_201_HIST_11482
WHERE ixipaymentbatchnumber = '&payment_batch_number';

COMMIT;

SHOW ERROR