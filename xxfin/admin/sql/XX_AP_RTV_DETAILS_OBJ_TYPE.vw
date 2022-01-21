WHENEVER SQLERROR EXIT FAILURE
-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_RTV_DETAILS_OBJ_TYPE.vw                                 |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        19-JAN-2018    Uday Jadhav         	Initial Version           |
-- +==========================================================================+  
create or replace TYPE "XX_AP_RTV_DETAILS_REC_TYPE"  AS OBJECT (dept 				 VARCHAR2(100),
															 sku  				 VARCHAR2(100),
															 vendor_product_code VARCHAR2(100),
															 item_desc			 VARCHAR2(100),
															 qty				 VARCHAR2(100),
															 cost				 VARCHAR2(100),
															 ext_cost			 VARCHAR2(100),
															 allow_qty			 VARCHAR2(100),
															 allow_cost			 VARCHAR2(100),
															 allow_ext_cost		 VARCHAR2(100),
															 worksheet_nbr		 VARCHAR2(100),
															 RGA_nbr			      VARCHAR2(100),
															 carrier_name		 VARCHAR2(100),
															 freight_bill_nbr1	 VARCHAR2(100),
															 freight_bill_nbr2	 VARCHAR2(100),
															 freight_bill_nbr3	 VARCHAR2(100),
															 freight_bill_nbr4	 VARCHAR2(100),
															 freight_bill_nbr5	 VARCHAR2(100) 
															 ); 
/                               
CREATE OR REPLACE TYPE "XX_AP_RTV_DETAILS_OBJ_TYPE" AS TABLE OF XX_AP_RTV_DETAILS_REC_TYPE;
/