SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  | 
-- |                  Oracle Office Depot Development                  |
-- +===================================================================+
-- | Name          :  XX_OM_FRAUD_CHECK_PKG                            |
-- | Description   :  This package will process all the procedures     |
-- |                  for Fraud checking.                              |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 08-OCT-2007  GREG.CHU         Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
create or replace
PACKAGE "XX_OM_FRAUD_CHECK_PKG" AS

PROCEDURE IP_ADDRESS_CHECK (
	P_Ip_Address IN VARCHAR2
	,X_Hold_Id OUT NOCOPY NUMBER
	,X_Hold_Comments OUT NOCOPY VARCHAR2
	,X_Fraud_Status OUT NOCOPY VARCHAR2
	
    )	;









END;

