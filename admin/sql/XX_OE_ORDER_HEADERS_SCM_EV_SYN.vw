SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - SCM Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_OE_ORDER_HEADERS_SCM_EV_SYN.vw                           |
-- | Description : Scripts to create Editioned Views  for object               |
-- |               XX_OE_ORDER_HEADERS_SCM                                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |DRAFT 1  20-MAR-2018 PUNIT_CG           Initial draft version              |
-- +===========================================================================+

PROMPT
PROMPT Creating Editioning View for XX_OE_ORDER_HEADERS_SCM .....
PROMPT **Edition View creates as XX_OE_ORDER_HEADERS_SCM# in XXOM schema**
PROMPT **Synonym creates as XX_OE_ORDER_HEADERS_SCM in APPS schema**
PROMPT

EXEC ad_zd_table.upgrade('XXOM','XX_OE_ORDER_HEADERS_SCM');

SHOW ERRORS;
EXIT;