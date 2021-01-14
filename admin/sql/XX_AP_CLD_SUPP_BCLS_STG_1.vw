--+==========================================================================+|
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | RICE ID     :                                                            |
-- | Name        :  Alter View for BCLS table                                 |
-- |                                                                          |
-- | SQL Script to alter the following object                                 |
-- | View       : XX_AP_CLD_SUPP_BCLS_STG#                                    |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | 1.0      11-JAN-2020  Gitanjali Singh      Added new columns in view     |
-- +==========================================================================+
	
	SET SHOW         OFF
	SET VERIFY       OFF
	SET ECHO         OFF
	SET TAB          OFF
	SET FEEDBACK     ON
	
	CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXFIN"."XX_AP_CLD_SUPP_BCLS_STG#" ("SUPPLIER_NAME", "SUPPLIER_NUMBER", "CLASSIFICATION", "SUBCLASSIFICATION", "START_DATE", "CONFIRMED_ON", "PROCESS_FLAG", "BCLS_PROCESS_FLAG", "CREATE_FLAG", "ERROR_FLAG", "ERROR_MSG", "REQUEST_ID", "CREATED_BY", "CREATION_DATE", "LAST_UPDATED_BY", "LAST_UPDATE_DATE", "VENDOR_ID", "STATUS", "END_DATE_ACTIVE") AS
	 select SUPPLIER_NAME SUPPLIER_NAME, SUPPLIER_NUMBER SUPPLIER_NUMBER, CLASSIFICATION CLASSIFICATION,
	 SUBCLASSIFICATION SUBCLASSIFICATION, START_DATE START_DATE, CONFIRMED_ON CONFIRMED_ON, PROCESS_FLAG PROCESS_FLAG,
	 BCLS_PROCESS_FLAG BCLS_PROCESS_FLAG, CREATE_FLAG CREATE_FLAG, ERROR_FLAG ERROR_FLAG, ERROR_MSG ERROR_MSG, REQUEST_ID REQUEST_ID,
	 CREATED_BY CREATED_BY, CREATION_DATE CREATION_DATE, LAST_UPDATED_BY LAST_UPDATED_BY, LAST_UPDATE_DATE LAST_UPDATE_DATE, VENDOR_ID VENDOR_ID,
	 STATUS STATUS, END_DATE_ACTIVE END_DATE_ACTIVE
	 from XXFIN.XX_AP_CLD_SUPP_BCLS_STG;
	  
  SHOW ERROR;