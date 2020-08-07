SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                                     Office Depot                                           |
-- +============================================================================================+
-- | Name        : XX_PO_PUNCHOUT_EDITIONED_VIEWS.vw                                            |
-- | Description : Scripts to create Editioned Views for the PO Punchout Objects                |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        17-JUL-2017     Suresh N             Initial version                             |
-- +============================================================================================+

PROMPT
PROMPT Creating Editioning View for XX_PO_PUNCH_HEADER_INFO .....
PROMPT

exec ad_zd_table.upgrade('XXPTP','XX_PO_PUNCH_HEADER_INFO');

PROMPT
PROMPT Creating Editioning View for XX_PO_PUNCH_LINES_INFO .....
PROMPT

exec ad_zd_table.upgrade('XXPTP','XX_PO_PUNCH_LINES_INFO');

PROMPT
PROMPT Creating Editioning View for XX_PO_PUNCHOUT_CONFIRMATION .....
PROMPT

exec ad_zd_table.upgrade('XXPTP','XX_PO_PUNCHOUT_CONFIRMATION');

PROMPT
PROMPT Creating Editioning View for XX_PO_SHIPMENT_DETAILS .....
PROMPT

exec ad_zd_table.upgrade('XXPTP','XX_PO_SHIPMENT_DETAILS');

SHOW ERRORS;
EXIT;