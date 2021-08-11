-- +=====================================================================+
-- |                   Office Depot - SAS Modernization                  |
-- +=====================================================================+
-- | Name :  XXOM_ORDER_HEADERS_INT.tbl                            |
-- | Description :   Alters XXOM_ORDER_HEADERS_INT                       |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ========================|
-- |1.0      11-Aug-2021     Shreyas Thorat       Alter table XXOM_ORDER_HEADERS_INT     | 
-- | 	                                          To Change column to VARCHAR2 |
-- +=====================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


alter table XXOM_ORDER_HEADERS_INT
modify  ACCOUNTID VARCHAR2(240);


show errors;
/