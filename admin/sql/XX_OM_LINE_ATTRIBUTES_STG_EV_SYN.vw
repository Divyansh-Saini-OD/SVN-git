SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===========================================================================+
-- |                  Office Depot - SCM Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_OM_LINE_ATTRIBUTES_STG_EV_SYN.vw                         |
-- | Description : Scripts to create Editioned Views  for object               |
-- |               XX_OM_LINE_ATTRIBUTES_STG                                   |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |DRAFT 1  21-MAR-2018 JAI_CG           Initial draft version                |
-- +===========================================================================+

PROMPT
PROMPT Creating Editioning View for XX_OM_LINE_ATTRIBUTES_STG .....
PROMPT **Edition View creates as XX_OM_LINE_ATTRIBUTES_STG# in XXOM schema**
PROMPT **Synonym creates as XX_OM_LINE_ATTRIBUTES_STG in APPS schema**
PROMPT

EXEC ad_zd_table.upgrade('XXOM','XX_OM_LINE_ATTRIBUTES_STG');

SHOW ERRORS;
EXIT;