-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | 		Name  :   XX_PO_POM_HDR_INT_STG.grt                           |
-- | 	RICE ID       :   I2193_PO to EBS Interface                           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     01-09-2017   Avinash Baddam       Initial version               |
-- +==========================================================================+
GRANT SELECT ON XXFIN.XX_PO_POM_INT_BATCH_S TO APPS WITH GRANT OPTION;
GRANT ALL ON XXFIN.XX_PO_POM_HDR_INT_STG TO APPS WITH GRANT OPTION;
GRANT SELECT ON XXFIN.XX_PO_POM_HDR_INT_STG TO ERP_SYSTEM_TABLE_SELECT_ROLE;


