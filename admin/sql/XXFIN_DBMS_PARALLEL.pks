SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XXFIN_DBMS_PARALLEL
AS
-- +============================================================================================|
-- |  Office Depot                                            |
-- +============================================================================================|
-- |  Name:  XXFIN_DBMS_PARALLEL                                                                |
-- |                                                                                            |
-- |  Description: This package is created to perform the Parallel Execution for Purging        |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================|
-- | Version     Date         Author               Remarks                                      |
-- | =========   ===========  =============        =============================================|
-- | 1.0         02/12/2021   Ankit Jaiswal        Initial version                              |
-- +============================================================================================+


  /* **************************************************
          MAIN Procedure for Parallel Execution
     *************************************************** */	

  PROCEDURE XXFIN_PARALLEL_EXECUTION(x_errbuff OUT VARCHAR2,
                                     x_retcode OUT NUMBER,
                                     p_module_name IN  VARCHAR2
                                    );
END;
/
show error;