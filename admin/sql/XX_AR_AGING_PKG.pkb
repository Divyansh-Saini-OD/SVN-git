CREATE OR REPLACE
PACKAGE BODY XX_AR_AGING_PKG
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
-- |      1B 10-JUN-13      Bapuji Nanapaneni    Modifed for 12i UPGRADE |
-- |                                             Rename views to tbls    |
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
RETURN NUMBER
IS

 p_amount_applied     number;
 p_adj_amount_applied number;
 p_actual_amount      number;
 p_amt_due_original   number;
 p_cm_amount_applied  number;
 ln_amount_applied    number;
 BEGIN
  SELECT NVL(SUM(NVL(NVL(acctd_amount_applied_to,acctd_amount_applied_from),0) + NVL(acctd_earned_discount_taken,0) + NVL(acctd_unearned_discount_taken,0)), 0)
  INTO   p_amount_applied
  FROM   ar_receivable_applications_all ARA
  WHERE  applied_payment_schedule_id = p_payment_schedule_id
  AND	status = 'APP'
  AND	nvl(confirmed_flag,'Y') = 'Y'
  AND ARA.gl_date <= p_as_of_date;

 IF p_class IN ('PMT','CM') THEN
     SELECT NVL(
                SUM(
                      NVL(acctd_amount_applied_from,0)
--                    + NVL(acctd_earned_discount_taken,0)   -- Commented by Ganesan for excluding the discount
--                    + NVL(acctd_unearned_discount_taken,0) -- Commented by Ganesan for excluding the discount
                   )
               , 0
               )
     INTO   ln_amount_applied
     FROM   ar_receivable_applications_all ARA
            ,ar_payment_schedules_all APS
            ,ar_lookups AL
     WHERE  ARA.payment_schedule_id = p_payment_schedule_id
     AND    APS.payment_schedule_id = ARA.applied_payment_schedule_id
     AND    ARA.status = AL.lookup_code
     AND    AL.lookup_type = 'PAYMENT_TYPE'
     AND    AL.lookup_code <> 'UNAPP'
     AND    NVL(ARA.applied_customer_trx_id,0) <> -1
     AND    NVL(ARA.confirmed_flag,'Y') = 'Y'
     AND    ARA.gl_date <= p_as_of_date
     AND    APS.gl_date <= p_as_of_date;
 END IF;
  /* Added the query to retrieve the Adjustment
     Amount applied to the Invoice */
  SELECT NVL(SUM(acctd_amount),0)
  INTO   p_adj_amount_applied
  FROM   ar_adjustments_all
  WHERE  payment_schedule_id = p_payment_schedule_id
         AND        status   = 'A'
         AND     gl_date <= p_as_of_date;

  SELECT (amount_due_original * NVL(exchange_rate,1))
  INTO   p_amt_due_original
  FROM   ar_payment_schedules_all
  WHERE  payment_schedule_id = p_payment_schedule_id;
   /*Added p_adj_amount_applied so that
    Adjustment amount is also taken into account while
    computing the Balance */
 /*Added nvl for p_cm_amount_applied */
   p_actual_amount := p_amt_due_original
                      + p_adj_amount_applied
                      - p_amount_applied + NVL(ln_amount_applied,0);
   RETURN(ROUND(p_actual_amount,2));
 EXCEPTION
   /*added NO_DATA_FOUND */
   WHEN NO_DATA_FOUND THEN
     RETURN(null);
   WHEN OTHERS THEN
     RETURN(NULL);
END XX_AR_BAL_AMT_FUNC;

END XX_AR_AGING_PKG;
/