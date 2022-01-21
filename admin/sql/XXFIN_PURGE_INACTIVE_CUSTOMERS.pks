SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XXFIN_PURGE_INACTIVE_CUSTOMERS
AS
-- +============================================================================================|
-- |  Office Depot                                            |
-- +============================================================================================|
-- |  Name:  XXFIN_DBMS_PARALLEL                                                                |
-- |                                                                                            |
-- |  Description: This package is created for Purging the inactive Customers                |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================|
-- | Version     Date         Author               Remarks                                      |
-- | =========   ===========  =============        =============================================|
-- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
-- +============================================================================================+

  /* **************************************************
          MAIN Procedure for Purging Inactive Customers
     *************************************************** */	

  PROCEDURE PURGE_INACTIVE_CUSTOMERS(P_START_ROW_ID IN  VARCHAR2
                                    ,P_END_ROW_ID IN VARCHAR2 
                                    );
END;
/
show error;