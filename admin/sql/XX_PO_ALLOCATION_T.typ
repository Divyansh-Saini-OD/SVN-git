-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  : APPS.XX_PO_ALLOCATION_T                                   |
-- | Description: CUSTOM TYPE FOR USE WITH AQ AND BPEL                 |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      06-21-2007   K.CRAWFORD       INITAL CODE                 |
-- +===================================================================+

CREATE OR REPLACE
type XX_PO_ALLOCATION_T
as object (PO varchar2(50), SKU NUMBER,SHIP_TO NUMBER,ALLOC_LOC NUMBER,QTY NUMBER,LOCKED_ID CHAR, ALLOCATION_TYPE CHAR) ;