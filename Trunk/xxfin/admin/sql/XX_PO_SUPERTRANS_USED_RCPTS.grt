-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | 		Name  	  :   XX_PO_SUPERTRANS_USED_RCPTS.grt                     |
-- |                      Script to create grants on the table for            |
-- |                      PO outbound Supertrans used receipts after matching |
-- |                      to store the matched and unmatched amount           |
-- | 	     RICE ID  :   E3522_PO Supertrans outbound from EBS Interface     |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     11-17-2017   Madhu Bolli       	Initial version               |
-- +==========================================================================+
GRANT SELECT ON XXFIN.XX_PO_SUPERTRANS_USED_RCPTS TO ERP_SYSTEM_TABLE_SELECT_ROLE;
GRANT ALL ON XXFIN.XX_PO_SUPERTRANS_USED_RCPTS TO APPS WITH GRANT OPTION;
