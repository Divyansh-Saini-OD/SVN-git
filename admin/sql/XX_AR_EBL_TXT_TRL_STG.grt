-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XX_AR_EBL_TXT_TRL_STG.grt                                    |
-- | Rice ID     : E2059                                                        |
-- | Description : This grant script is created for                             |
-- |                Table XX_AR_EBL_TXT_TRL_STG                                 |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======  ===========  =============    =====================================|
-- |1.0      04-MAR-2016  Suresh Naragam   Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT ALL ON XXFIN.XX_AR_EBL_TXT_TRL_STG TO APPS;

GRANT SELECT, INSERT, UPDATE, DELETE ON XXFIN.XX_AR_EBL_TXT_TRL_STG TO APPSRW_ROLE;

GRANT SELECT ON XXFIN.XX_AR_EBL_TXT_TRL_STG TO XX_FIN_SELECT_FINDEV_R;

GRANT SELECT ON XXFIN.XX_AR_EBL_TXT_TRL_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;

SHOW ERROR



