-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | 		Name  :   XX_PO_POM_MISSED_IN_INT.gtr                             |
-- |                      Script to create Grant on the table for             |
-- |                      POM Missed PO's sending to interface                |
-- | 	     RICE ID  :   I2193_PO to EBS Interface                           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     01-04-2018   Madhu Bolli          Initial version               |
-- +==========================================================================+
GRANT SELECT ON XXFIN.XX_PO_POM_MISSED_IN_INT_S TO APPS WITH GRANT OPTION;
GRANT SELECT ON XXFIN.XX_PO_POM_MISSED_IN_INT TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT ALL 	 ON XXFIN.XX_PO_POM_MISSED_IN_INT TO APPS WITH GRANT OPTION;



