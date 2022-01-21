/* Formatted on 2008/05/11 09:55 (Formatter Plus v4.8.8) */
CREATE OR REPLACE VIEW xx_ar_cons_inv_total_amounts_v (cons_inv_id,
                                                       total_amount,
                                                       tax_amount
                                                      )
AS
   SELECT   cons_inv_id, SUM (amount_original) total_amount,
            SUM (tax_original) tax_amount
       FROM ar_cons_inv_trx
      WHERE 1 = 1
        AND transaction_type IN
                       (
                         'INVOICE'
                        ,'CREDIT_MEMO'
                        --,'ADJUSTMENT'                        
                       )
   GROUP BY cons_inv_id
/