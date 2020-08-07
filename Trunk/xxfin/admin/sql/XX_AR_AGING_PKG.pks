CREATE OR REPLACE
PACKAGE XX_AR_AGING_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_AGING_PKG                                              |
-- | RICE ID :  R0426                                                    |
-- | Description : This package contains the function that would return  |
-- |               balance amount for any transaction for any customer   |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |DRAFT 1A 12-NOV-08      Manovinayak A        Initial Version         |
-- +=====================================================================+
-- +=====================================================================+
-- | Name :  XX_AR_BAL_AMT_FUNC                                          |
-- | Description :This Function will return the outstanding balance for  |
-- |              every transaction excluding On Account receipts and    |
-- |              un-identified receipts                                 |
-- | Parameters :p_payment_schedule_id,p_as_of_date                      |
-- | Returns    :ln_actual_amount                                        |
-- +=====================================================================+
FUNCTION XX_AR_BAL_AMT_FUNC (
                             p_payment_schedule_id IN NUMBER
                            ,p_class               IN VARCHAR
                            ,p_as_of_date          IN DATE
                            )
RETURN NUMBER;

END XX_AR_AGING_PKG; 
/
