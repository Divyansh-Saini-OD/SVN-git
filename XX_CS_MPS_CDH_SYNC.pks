SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CS_MPS_CDH_SYNC AS 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_MPS_CDH_SYNC                                                            |
-- |                                                                                         |
-- | Description      : Customer SHIP TO updates                                             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       20-MAR-13        Raj Jagarlamudi        Initial draft version                  |
-- +=========================================================================================+
  PROCEDURE ADD_SHIP_TO;
  
  PROCEDURE UPDATE_SHIP_TO;

END XX_CS_MPS_CDH_SYNC;
/
SHOW ERRORS;
