WHENEVER SQLERROR EXIT FAILURE
-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_CHRGBK_DETAILS_OBJ_TYPE.vw                          |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        10-OCT-2017    Uday Jadhav         	Initial Version           |
-- +==========================================================================+

create or replace TYPE "XX_AP_CHRGBK_DETAILS_REC_TYPE"  AS OBJECT (chargeback_type 		VARCHAR2(100),
																 dept 			 		VARCHAR2(100),
																 sku 			 		VARCHAR2(100),
																 vendor_product_code 	VARCHAR2(100),
																 item_desc			 	VARCHAR2(100),
																 units_received		 	NUMBER,
																 units_invoiced		 	NUMBER,
																 order_unit_price       NUMBER,
																 inv_unit_price		 	NUMBER,
																 inv_adj_amt		 	NUMBER,
																 po_number				VARCHAR2(100),
																 check_number			VARCHAR2(100) 
																);
/

CREATE OR REPLACE TYPE "XX_AP_CHRGBK_DETAILS_OBJ_TYPE" AS TABLE OF XX_AP_CHRGBK_DETAILS_REC_TYPE;
/