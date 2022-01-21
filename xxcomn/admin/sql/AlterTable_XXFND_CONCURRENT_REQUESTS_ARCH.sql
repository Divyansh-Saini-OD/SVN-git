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
-- |1.0      2015-12-12     Rma Goyal            12.2.4 Upgrade          |
-- +=====================================================================+

alter table XXFND_CONCURRENT_REQUESTS_ARCH
add (NODE_NAME1 varchar2(30 byte), 
	NODE_NAME2 varchar2(30 byte), 
	CONNSTR1 varchar2(255 byte),
	CONNSTR2 VARCHAR2(255 BYTE));
/