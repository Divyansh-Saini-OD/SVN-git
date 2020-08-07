-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Oracle			                      |
-- +==========================================================================+
-- | SQL Script to create the following objects                               |
-- |             Table       : XX_OM_LINE_ATTRIBUTES_ALL                      |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | v1.0     25-Jun-2014  Vivek.S              Added upc_code,price_type and |
-- |                                            omx_sku for RCC changes       |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

ALTER TABLE XXOM.XX_OM_LINE_ATTRIBUTES_ALL ADD (UPC_CODE VARCHAR2(15),PRICE_TYPE VARCHAR2(1),EXTERNAL_SKU VARCHAR2(8));

COMMIT;
