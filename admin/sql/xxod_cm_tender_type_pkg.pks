CREATE OR REPLACE PACKAGE xxod_cm_tender_type_pkg
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  XXOD_CM_TENDER_TYPE_PKG                       |
-- | RICE ID          :  R0471                                         | 
-- | Description      :  This Package is used for CM Tender Type Report|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-AUG-2007  DorairajR       Initial draft version        |
-- +===================================================================+
AS
PROCEDURE cm_tender_type(
			  P_PERIOD_FROM  		VARCHAR2
			  ,P_PERIOD_TO   		VARCHAR2
			  ,P_TENDER_TYPE_FROM 		VARCHAR2
 			  ,P_TENDER_TYPE_TO		VARCHAR2
			  ,P_SOB_ID                     NUMBER );
		      --  ,P_CHARGE_ACCOUNT		VARCHAR2 DEFAULT NULL); --Removed for the defect 10216 by Sangeetha R
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Wipro/Office Depot                             |
-- +===================================================================+
-- | Name             :  CM_TENDER_TYPE                                |
-- | RICE ID          :  R0471	        			       |
-- | Description      :  This procedure is used to get all sales and   |
-- |                     expense details for receipts wit different    |
-- |                     tender type                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-AUG-2007  Dorairaj R       Initial draft version       |
-- |	     24-SEP-2008  Sangeetha R	   Modified for the            |
-- |	                                    Defect 10216               |
-- +===================================================================+
END xxod_cm_tender_type_pkg;

/
