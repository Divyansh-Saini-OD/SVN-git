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
-- |1.0      19-May-2021     Shreyas Thorat       Created alter for       |
-- |                                             UAT.            |

-- +=====================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON


alter table XXOM_IMPORT_INT
add ( OrderTotal NUMBER ,  TotalTax NUMBER );

show errors;
/