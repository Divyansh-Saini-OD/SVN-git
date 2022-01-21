SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | RICE ID     :  E0062                                                |
-- | Name        :  E0062 CustomAutocashRules_and_PartialInvoiceMatch    |
-- | Description :                                                       |
-- | Name        :  XX_AR_CUSTID_TAB_T                                   |
-- | Description :  Creates XX_AR_CUSTID_TAB_T                           |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0       28-OCT-2009   RamyaPriya M         Created Base version    |
-- |                                             For CR#684 -- Defect 976|
-- |                        Wipro Technologies                           |
-- +=====================================================================+

CREATE OR REPLACE TYPE XXFIN.XX_AR_CUSTID_TAB_T AS TABLE OF NUMBER;
/
SHOW ERROR
