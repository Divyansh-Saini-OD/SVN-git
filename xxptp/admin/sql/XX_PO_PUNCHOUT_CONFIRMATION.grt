-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XX_PO_PUNCHOUT_CONFIRMATION.grt                              |
-- | Rice ID     :                                                              |
-- | Description : This grant script is created for                             |
-- |                Table XX_PO_PUNCHOUT_CONFIRMATION                           |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======  ===========  =============    =====================================|
-- |1.0      14-JUN-2017  Suresh Naragam   Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT ALL ON XXPTP.XX_PO_PUNCHOUT_CONFIRMATION TO APPS;

GRANT SELECT, INSERT, UPDATE, DELETE ON XXPTP.XX_PO_PUNCHOUT_CONFIRMATION TO APPSRW_ROLE;

GRANT SELECT ON XXPTP.XX_PO_PUNCHOUT_CONFIRMATION TO XX_FIN_SELECT_FINDEV_R;

GRANT SELECT ON XXPTP.XX_PO_PUNCHOUT_CONFIRMATION TO ERP_SYSTEM_TABLE_SELECT_ROLE;

SHOW ERROR



