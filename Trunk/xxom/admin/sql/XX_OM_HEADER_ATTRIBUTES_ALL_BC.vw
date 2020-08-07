SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_OM_HEADER_ATTRIBUTES_ALL.vw                                              |
-- | Description : Scripts to create Editioned Views for the hdr iface all                      |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        20-NOV-2018    Arun G             Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_OM_HEADER_ATTRIBUTES_ALL .....
PROMPT

exec ad_zd_table.upgrade('XXOM','XX_OM_HEADER_ATTRIBUTES_ALL');

SHOW ERRORS;
EXIT;