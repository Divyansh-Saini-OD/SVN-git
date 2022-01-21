-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XX_AR_EBL_XL_TAB_SPLIT_HDR.grt                               |
-- | Rice ID     : E2059                                                        |
-- | Description : This grant script is created for                             |
-- |                Table XX_AR_EBL_XL_TAB_SPLIT_HDR                            |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======  ===========  =============    =====================================|
-- |1.0      17-AUG-2015  Suresh Naragam   Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT ALL ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_HDR TO APPS;

GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_HDR TO APPSRW_ROLE;

GRANT SELECT ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_HDR TO XX_FIN_SELECT_FINDEV_R;

GRANT SELECT ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_HDR TO ERP_SYSTEM_TABLE_SELECT_ROLE;

SHOW ERROR



