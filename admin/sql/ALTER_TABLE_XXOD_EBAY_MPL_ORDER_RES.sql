SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT ALTERING TABLE XXFIN.XXOD_EBAY_MPL_ORDER_RES

PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- +===============================================================================+
-- | Name        : XXOD_EBAY_MPL_ORDER_RES.tbl                                     |
-- | Description : Altering the table XXOD_EBAY_MPL_ORDER_RES                      |
-- |                                                                               |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- | Version      Date           Author                   Remarks                  |
-- |=========   =========      =============          ======================       |
-- | V1.0        02-Dec-20     Mayur Palsokar          NAIT-162646                 |
-- +===============================================================================+

ALTER TABLE XXOD_EBAY_MPL_ORDER_RES
ADD (
	  ORDERID VARCHAR2(250) ,
      LEGACYORDERID VARCHAR2(250) ,
      PAYSUM_PAYMETHOD VARCHAR2(250) ,
      PAYSUM_PAYMENTSTATUS VARCHAR2(250) ,
      LINEITEMS_SKU VARCHAR2(250) ,
      LINEITEMS_TITLE VARCHAR2(250) ,
      LINEITEMS_LINEITEMCOST_VALUE VARCHAR2(250) ,
      LINEITEMS_QUANTITY VARCHAR2(250) ,
      LINEITEMS_DELIVERYCOST_VALUE VARCHAR2(250) ,
      LINEITEMS_TAXTYPE VARCHAR2(250) ,
      LINEITEMS_EBAYREMITTAXES_VALUE VARCHAR2(250) ,
	  CREATION_DATE DATE,
      STATUS VARCHAR2(5),
      ATTRIBUTE1         VARCHAR2(250) ,
ATTRIBUTE2         VARCHAR2(250) ,
ATTRIBUTE3         VARCHAR2(250) ,
ATTRIBUTE4         VARCHAR2(250) ,
ATTRIBUTE5         VARCHAR2(250) ,
ATTRIBUTE6         VARCHAR2(250) ,
ATTRIBUTE7         VARCHAR2(250) ,
ATTRIBUTE8         VARCHAR2(250) ,
ATTRIBUTE9         VARCHAR2(250) ,
ATTRIBUTE10        VARCHAR2(250) ,
ATTRIBUTE11        VARCHAR2(250) ,
ATTRIBUTE12        VARCHAR2(250) ,
ATTRIBUTE13        VARCHAR2(250) ,
ATTRIBUTE14        VARCHAR2(250) ,
ATTRIBUTE15        VARCHAR2(250)  	  
);

SHOW ERROR;