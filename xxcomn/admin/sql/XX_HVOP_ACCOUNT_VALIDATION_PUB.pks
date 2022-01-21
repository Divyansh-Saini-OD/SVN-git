create or replace
PACKAGE XX_HVOP_ACCOUNT_VALIDATION_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_HVOP_ACCOUNT_VALIDATION_PUB                                                       |
-- | Description : Package body for inserting status into custom table to identify if account and       |
-- |               account site exist or not                                                            |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       11-Jun-2008 Yusuf Ali          Initial draft version.      			 	|
-- |2.0       06-Oct-2008 Yusuf Ali          Added functionality for performing lookup and insert into  |                                                                                                    |
-- |                                         audit table.                                               |
-- +====================================================================================================+
*/

	PROCEDURE check_entity        ( P_CHECK_ENTITY             IN 		    HVOP_CHECK_ACCT_OBJ_TBL
				      , X_MESSAGES		   OUT NOCOPY       HVOP_ACCT_RESULT_OBJ_TBL
                                      , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
                                      , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                                      );  
   
END XX_HVOP_ACCOUNT_VALIDATION_PUB;

/

SHOW ERRORS;
