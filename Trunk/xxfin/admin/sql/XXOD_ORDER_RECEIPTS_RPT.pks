create or replace
PACKAGE      XXOD_ORDER_RECEIPTS_RPT
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD                                    |
-- +=====================================================================+
-- | Name : XXOD_ORDER_RECEIPTS_RPT                                      |
-- | Defect# : 15034                                                     |
-- | Description : This package houses the report submission procedure   |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  31-JAN-12     Saikumar Reddy       Initial version         |
-- |      1B  02-JUN-14     Pravendra Lohiya     Defect 29050            |
-- |      1C  02-Feb-16     Avinash  Baddam      Defect#37204–Masterpass | 
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  ORDER_RECEPTS_PRC                                           |
-- | Description : This procedure will submit the detail and summary     |
-- |               reports for defect# 15034                             |
-- | Parameters  :           											 |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE ORDER_RECEPTS_PRC (
                             x_err_buff    OUT VARCHAR2
                            ,x_ret_code    OUT NUMBER
                            ,P_MODE        IN  VARCHAR2
							,P_HIDDEN	   IN  VARCHAR2            
              ,P_SEARCH_TYPE IN VARCHAR2         -- Added by P Lohiya For Defect 29050
              ,P_DUMMY1      IN VARCHAR2         -- Added by P Lohiya For Defect 29050
              ,P_DUMMY2      IN VARCHAR2         -- Added by P Lohiya For Defect 29050
							,P_RECEIPT_DATE_FROM IN  VARCHAR2
							,P_RECEIPT_DATE_TO IN  VARCHAR2
              ,P_CREATION_DATE_FROM IN  VARCHAR2  -- Added by P Lohiya For Defect 29050
              ,P_CREATION_DATE_TO IN  VARCHAR2    -- Added by P Lohiya For Defect 29050
							,P_CARD_TYPE IN  VARCHAR2
							,P_RECEIPT_STATUS IN  VARCHAR2
							,P_MATCHED_STATUS IN  VARCHAR2
							,P_REMITTED_STATUS IN  VARCHAR2
							,P_STORE_NUMBER_FROM IN  VARCHAR2
							,P_STORE_NUMBER_TO IN  VARCHAR2
							,P_WALLET_TYPE     IN  VARCHAR2
                            );
END XXOD_ORDER_RECEIPTS_RPT;
/