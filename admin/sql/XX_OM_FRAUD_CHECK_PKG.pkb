SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



create or replace
PACKAGE BODY XX_OM_FRAUD_CHECK_PKG
AS
 

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

GN_Default_Fraud_Check_Msg_Num CONSTANT NUMBER   := 1;
GC_Default_Fraud_Check_Msg CONSTANT VARCHAR2(40) := 'Fraud Pending Credit Review';
GC_Fraud_Check_Error      CONSTANT VARCHAR2(1)                           := 'Y';
GC_Fraud_Check_NoError  CONSTANT VARCHAR2(1)				     := 'N';



-- +===================================================================+
-- | Name  : IP_ADDRESS_CHECK                                          |
-- | Description      : This Function will be used to for IP Address   |
-- |                    Fraud of a sales order.                        |
-- |                                                                   |
-- | Parameters :       IP_ADDRESS                                     |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          HOLD_ID                                        |
-- |                    HOLD_COMMENTS                                  |
-- |                    FRAUD_STATUS                                   |
-- +===================================================================+
PROCEDURE IP_ADDRESS_CHECK (
	P_Ip_Address IN VARCHAR2
	,X_Hold_Id OUT NOCOPY NUMBER
	,X_Hold_Comments OUT NOCOPY VARCHAR2
	,X_Fraud_Status OUT NOCOPY VARCHAR2
	
    )	IS


Cursor FRAUD_RULES_CUR IS  
	Select Condition_Id, null Condition_Name,Ip_Address FROM XX_OM_FRAUD_RULES WHERE
		IP_Address = P_Ip_Address and Del_Flag = 'N';

BEGIN

	X_Hold_Id       := null;
	X_Hold_Comments := null;
	X_Fraud_Status  := 'N';

	

FOR FRAUD_RULES_REC IN FRAUD_RULES_CUR
LOOP

		X_Hold_Id          := FRAUD_RULES_REC.Condition_Id;
		X_Hold_Comments    := FRAUD_RULES_REC.Condition_Name;
		X_Fraud_Status     := 'Y';

EXIT;
END LOOP;

EXCEPTION
	WHEN OTHERS THEN
	X_Hold_Id       := null;
	X_Hold_Comments := null;
	X_Fraud_Status  := 'N';


END IP_ADDRESS_CHECK;


END XX_OM_FRAUD_CHECK_PKG;
