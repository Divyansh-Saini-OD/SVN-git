SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - SCM Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_OE_HEADER_ATTRIBUTES_ALL.vw                                    |
-- | Description : Scripts to create Editioned Views  for object               |
-- |               XX_OE_HEADER_ATTRIBUTES_ALL                                              |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      28-Apr-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

PROMPT
PROMPT Creating Editioning View for XX_OE_HEADER_ATTRIBUTES_ALL .....
PROMPT **Edition View creates as XX_OE_HEADER_ATTRIBUTES_ALL# in XXOM schema**
PROMPT **Synonym creates as XX_OE_HEADER_ATTRIBUTES_ALL in APPS schema**
PROMPT

EXEC ad_zd_table.upgrade('XXOM','XX_OE_HEADER_ATTRIBUTES_ALL');

SHOW ERRORS;
EXIT;