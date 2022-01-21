-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- +=====================================================================+
-- | Name :  XXDBA.XXFND_CONCURRENT_REQUESTS_ARCH.tbl                    |
-- | Description :   Alters XXDBA.XXFND_CONCURRENT_REQUESTS_ARCH         |
-- |                                                                     |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ========================|
-- |1.0      02-Dec-2016     Madhu Bolli          12.2.5 Upgrade         |
-- +=====================================================================+

alter table XXDBA.XXFND_CONCURRENT_REQUESTS_ARCH
add (EDITION_NAME varchar2(30), 
	RECALC_PARAMETERS varchar2(1), 
	NLS_SORT varchar2(30)); 	
/