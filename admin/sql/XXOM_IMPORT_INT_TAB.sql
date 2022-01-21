
-- +===========================================================================+
-- |                  Office Depot - SAS Modernization                         |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XXOM_IMPORT_INT.tbl                                 |
-- | Description : create Table for XXOM_IMPORT_INT                    |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author           Remarks                              |
-- |======== =========== ================ =====================================|
-- |1.0      28-Apr-2021 Shreyas Thorat   Initial Version                      |
-- +===========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE 

  CREATE TABLE XXOM_IMPORT_INT 
   (	REQUEST_ID NUMBER, 
	SEQUENCE_NUM NUMBER, 
	ORDER_NUMBER VARCHAR2(30), 
	SUB_ORDER_NUMBER VARCHAR2(30), 
	PROCESS_FLAG VARCHAR2(1), 
	STATUS VARCHAR2(10), 
	JSON_ORD_DATA CLOB, 
	ERROR_DESCRIPTION VARCHAR2(200), 
	CREATION_DATE DATE, 
	CREATED_BY NUMBER, 
	LAST_UPDATED_BY NUMBER, 
	LAST_UPDATE_DATE DATE, 
	FILE_NAME VARCHAR2(150)
   ) ;