-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- |  Name  	:   XX_PO_WMS_SUPERTRANS_OB.grt                               |
-- |  RICE ID  	:   E3522_PO Supertrans outbound from EBS Interface     	  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     10-10-2017   Madhu Bolli       	Initial version               |
-- +==========================================================================+
GRANT SELECT ON XXFIN.XX_PO_WMS_SUPERTRANS_OB_S TO APPS WITH GRANT OPTION;
GRANT SELECT ON XXFIN.XX_PO_WMS_SUPERTRANS_OB TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT ALL ON XXFIN.XX_PO_WMS_SUPERTRANS_OB TO APPS WITH GRANT OPTION;
