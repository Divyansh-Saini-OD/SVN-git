SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_POACK_DATE_TBL_TYPE                              |
-- | Description      : This scipt creates table types of              |
-- |                    Datatype Date	 		                          |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 20-Jun-2007  Aravind A        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  CREATE or REPLACE TYPE XX_OM_POACK_DATE_TBL_TYPE 
  AS TABLE 
  OF DATE;
  
  /
  SHOW ERROR
