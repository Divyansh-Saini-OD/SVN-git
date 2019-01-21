-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to create                                                     |
-- |                                                                          |
-- |                      INDEXES: XX_AP_INVOICES_ALL_N1                      |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     06-Oct-2007   Sambasiva Reddy D    Initial version              |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

--DROP INDEX XX_AP_INVOICES_ALL_N1;

CREATE INDEX XXFIN.XX_AP_INVOICES_ALL_N1 ON AP.AP_INVOICES_ALL(SUBSTR(invoice_num,4,length(invoice_num)));

SHOW ERROR




