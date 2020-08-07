-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XX_AR_EBL_XL_TAB_SPLIT_DTL.grt                               |
-- | Rice ID     : E2059                                                        |
-- | Description : This grant script is created for                             |
-- |                Table XX_AR_EBL_XL_TAB_SPLIT_DTL                            |
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

GRANT ALL ON  XX_AR_EBL_XL_TAB_SPLIT_DTL TO APPS;

GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_DTL TO APPSRW_ROLE;

GRANT SELECT ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_DTL TO XX_FIN_SELECT_FINDEV_R;

GRANT SELECT ON XXFIN.XX_AR_EBL_XL_TAB_SPLIT_DTL TO ERP_SYSTEM_TABLE_SELECT_ROLE;

SHOW ERROR



