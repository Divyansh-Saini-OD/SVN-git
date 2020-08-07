SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

WHENEVER SQLERROR CONTINUE

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | SQL Script to alter the table for xx_ar_interim_cust_acct_id            |
-- |                                                                          |
-- |                      R1.2 E2033                                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     30-Nov-2009  Bushrod Thomas       Initial version               |
-- +==========================================================================+



alter table XXFIN.xx_ar_interim_cust_acct_id add (cycle_name varchar2(100));


alter table XXFIN.xx_ar_interim_cust_acct_id add (billing_cycle_id number);


SHOW ERROR
