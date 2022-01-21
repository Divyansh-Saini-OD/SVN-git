-- +========================================================================+
-- |                  Office Depot                                          |
-- +========================================================================+
-- | Name        : ALTER_COL_XX_AR_SUBSCRIPTIONS.tbl                        |
-- | Description : Added new fields to XX_AR_SUBSCRIPTIONS table            |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date        Author           Remarks                          |
-- |=======  ===========  =============    =================================|
-- |1.0      17-July-2020 Kayeed A         Initial Version                 |
-- +========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

exec ad_zd_table.upgrade('XXFIN','XX_AR_SUBSCRIPTIONS');
show errors;
exit;