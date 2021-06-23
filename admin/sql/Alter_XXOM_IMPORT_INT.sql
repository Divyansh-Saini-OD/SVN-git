-- +=====================================================================+
-- |                   Office Depot - SAS Modernization                  |
-- +=====================================================================+
-- | Name :  Alter_XXOM_IMPORT_INT.tbl                            |
-- | Description :   Alters XXOM_IMPORT_INT                       |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ========================|
-- |1.0      22-Jun-2021     Shreyas Thorat       Alter table to add     | 
-- | 	                                          more column in table XXOM_IMPORT_INT |
-- +=====================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


alter table XXFIN.XXOM_IMPORT_INT
add ( OrderTotal NUMBER ,  TotalTax NUMBER );
show errors;