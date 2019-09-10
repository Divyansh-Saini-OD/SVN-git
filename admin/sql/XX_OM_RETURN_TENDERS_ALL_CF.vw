SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : xx_om_return_tenders_all.vw                                              |
-- | Description : Scripts to create Editioned Views for the hdr iface all                      |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        05-SEP-2019   Arun G             Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for xx_om_return_tenders_all .....
PROMPT

exec ad_zd_table.upgrade('XXOM','XX_OM_RETURN_TENDERS_ALL');

SHOW ERRORS;
EXIT;