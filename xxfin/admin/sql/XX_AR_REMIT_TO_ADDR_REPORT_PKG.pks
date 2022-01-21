create or replace
PACKAGE XX_AR_REMIT_TO_ADDR_REPORT_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :      AR Remit-to Address Exception Reporting                 |
-- | Description :   Program that creates a report that by customers that| 
-- |                 shows the remit-to address based on the DFF value,  |
-- |                 the desired remit-to based on the customer's bill-to|
-- |                 state, and the acutal remit-to                      |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date          Author          Remarks        Description   |
-- |=======   ==========   =============    ============== ===========   |
-- |1.0       18-SEP-2011  Sinon Perlas     Initial version              |
-- |2.0       15-OCT-2012  Oracle AMS Team  Defect # 20429  Adding       |
-- |                                                        New Parameter|
-- |                                            p_locbox_number_from_date|
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  Name : XX_AR_REMIT_TO_ADDR_REPORT_PROC                      |
-- | Description :                                                       |
-- | Parameters : P_country, p_customer_Num, P_mismatch_only,            |
-- |              p_locbox_number  ,p_locbox_number_from_date            |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

Procedure Xx_Ar_Remit_To_Addr_Rpt_Proc(X_Err_Buff      Out Varchar2
                                      ,X_Ret_Code      Out Number
                 ,P_Country           In Varchar2
				         ,P_Customer_Num      In Number
                 ,P_Mismatch_Match    In Varchar2
				         ,p_lockbox_number    IN VARCHAR2
                 ,p_lockbox_number_from_date IN VARCHAR2 DEFAULT NULL
                                          );
END XX_AR_REMIT_TO_ADDR_REPORT_PKG ;
/