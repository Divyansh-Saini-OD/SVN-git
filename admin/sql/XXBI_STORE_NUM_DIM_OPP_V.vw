SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                            Office Depot                            |
-- +====================================================================+
-- | Name  : XXBI_STORE_NUM_DIM_OPP_V                                   |
-- | Description: Custom view for the DBI Dimension.                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date         Author             Remarks                   |
-- |=======   ==========   =============      ==========================|
-- |1.0       28-Dec-2010  Gokila Tamilselvam Initial version           |
-- +===================================================================+|

 CREATE OR REPLACE VIEW XXBI_STORE_NUM_DIM_OPP_V AS 
 (
 SELECT  DISTINCT store_number_filter_id   id
        ,store_number_filter_id            value
 FROM    apps.XXBI_SALES_OPPTY_FCT_V
 WHERE   store_number_filter_id            IS NOT NULL
 )

/