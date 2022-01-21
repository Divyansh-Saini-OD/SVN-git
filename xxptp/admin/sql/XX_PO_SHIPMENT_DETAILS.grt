-- +============================================================================+
-- |                  Office Depot                                              |
-- +============================================================================+
-- | Name        : XX_PO_SHIPMENT_DETAILS.grt                                   |
-- | Rice ID     :                                                              |
-- | Description : This grant script is created for                             |
-- |                Table XX_PO_SHIPMENT_DETAILS                                |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author           Remarks                              |
-- |=======  ===========  =============    =====================================|
-- |1.0      7-JUL-2017   Suresh Naragam   Initial Version                      |
-- +============================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

GRANT ALL ON XXPTP.XX_PO_SHIPMENT_DETAILS TO APPS;

GRANT SELECT, INSERT, UPDATE, DELETE ON XXPTP.XX_PO_SHIPMENT_DETAILS TO APPSRW_ROLE;

GRANT SELECT ON XXPTP.XX_PO_SHIPMENT_DETAILS TO XX_FIN_SELECT_FINDEV_R;

GRANT SELECT ON XXPTP.XX_PO_SHIPMENT_DETAILS TO ERP_SYSTEM_TABLE_SELECT_ROLE;

SHOW ERROR



