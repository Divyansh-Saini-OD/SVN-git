-- +===========================================================================+
-- |                  Office Depot                                             |
-- +===========================================================================+
-- |Description : Create index for table  XX_AP_TRADE_INV_LINES                |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author                  Remarks                |
-- |=======    ==========     =============             ====================== |
-- | 1.0       18-APR-18      Antonio Morales           Initial draft version  |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE


CREATE INDEX XXFIN.XX_AP_TRADE_INV_LINES_N_15 ON XXFIN.XX_AP_TRADE_INV_LINES
(AP_VENDOR, SKU, LOCATION_NUMBER, RECORD_STATUS, SOURCE, 
CREATION_DATE, CONSIGN_FLAG, MISC_ISSUE_FLAG)
LOGGING
NOPARALLEL;

