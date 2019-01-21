SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
	
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       PROVIDGE Consulting                                |
-- +==========================================================================+
-- | SQL Script to create the Sequences                                       |
-- | xx_ap_invoices_cnv_stg_bt_s - BATCH_ID of xx_ap_invoice_interface_stg    |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      20-FEB-2007  Sarat Uppalapati     Initial version               |
-- |                                                                          |
-- +==========================================================================+

DROP SEQUENCE xxcnv.xx_ap_invoices_cnv_stg_bt_s ; 
CREATE SEQUENCE xxcnv.xx_ap_invoices_cnv_stg_bt_s START WITH 1 INCREMENT BY 1 NOCACHE;

SHOW ERROR
