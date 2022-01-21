
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- | Name :      XX_AR_FREQUENCY_FIX.SQL                                                |
-- | Description : ONE TIME FIX TO UPDATE exclude_from_cons_bill_flag = NULL FOR IND INVOICES IN SIT01|
-- |                documents                                                           |
-- |                                                                                    |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       10-FEB-2009  Mohanakrishnan        Initial version                         |
-- +====================================================================================+

SET FEED ON;

UPDATE  ar_payment_schedules_all arps
                       SET     arps.exclude_from_cons_bill_flag = NULL
                       WHERE   1 = 1
                       AND arps.customer_trx_id IN (
SELECT invoice_id FROM APPS.XX_AR_INVOICE_FREQ_HISTORY WHERE TRUNC(CREATION_DATE) = TRUNC(SYSDATE)
GROUP BY invoice_id ) ;

COMMIT;