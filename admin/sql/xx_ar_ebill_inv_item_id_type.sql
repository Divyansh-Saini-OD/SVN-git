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
-- | Name        :  xx_ar_ebill_inv_item_id_type.sql                     |
-- | Description :   Creates XX_AR_EBILL_INV_ITEM_ID_TYPE                |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       21-AUG-2009   Tamil Vendhan L,     Created Base version    |
-- |                        Wipro Technologies                           |
-- +=====================================================================+

CREATE OR REPLACE TYPE xxfin.xx_ar_ebill_inv_item_id_type AS TABLE OF NUMBER;
/
SHOW ERROR
