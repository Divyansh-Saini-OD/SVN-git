SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | RICE ID     :  E0286                                                |
-- | Name        :  E0286 Consolidated Billing Format and Distribution   |
-- | Description :                                                       |
-- | Name        :  XX_AR_REPRINT_CONS_BILL_T.typ                        |
-- | Description :   Creates XX_AR_REPRINT_CONS_BILL_T                   |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      17-DEC-2009    Gokila Tamilselvam,  Created Base version    |
-- |                        Wipro Technologies                           |
-- +=====================================================================+

CREATE OR REPLACE TYPE xxfin.xx_ar_reprint_cons_bill_t AS TABLE OF NUMBER;
/
SHOW ERROR
