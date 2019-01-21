WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- QC Defect # 15308
-- Index created to improve performance of CE Accrue CreditCard Fees program  

CREATE TABLE XX_DAILY_ACCRUAL_TBL AS
    SELECT   /*+ parallel (xcar) full(xcar) */
             xcar.org_id, hdr.provider_code, hdr.ajb_card_type,xcar.store_number, xcar.order_payment_id,
             hdr.om_card_type, xcar.currency_code, hdr.header_id,
             hdr.accrual_liability_account,
             hdr.accrual_liability_costcenter,
             hdr.accrual_liability_location,
             NVL (xcar.payment_amount, 0) amount
        FROM xx_ar_order_receipt_dtl xcar,
             xx_ce_recon_glact_hdr hdr,
             xx_ce_accrual_glact_dtl xcag,
             fnd_lookup_values lv
       WHERE lv.lookup_type = 'OD_PAYMENT_TYPES'
         AND xcar.credit_card_code = lv.meaning
         AND lv.lookup_code = hdr.om_card_type
         AND lv.enabled_flag = 'Y'
         AND xcar.receipt_date BETWEEN lv.start_date_active - 0 AND NVL (lv.end_date_active , xcar.receipt_date + 1 )
         AND xcar.org_id = hdr.org_id
         AND NVL (xcar.payment_amount, 0) != 0
         AND xcar.receipt_status = 'OPEN'
         AND hdr.org_id = 404
         AND xcag.header_id = hdr.header_id
         AND xcar.receipt_date BETWEEN xcag.effective_from_date
                                   AND NVL (xcag.effective_to_date,
                                            xcar.receipt_date + 1
                                           )
         AND xcag.accrual_frequency = 'DAILY'
         AND NOT EXISTS (
                SELECT 1
                  FROM xx_ce_cc_fee_accrual_log
                 WHERE order_payment_id = xcar.order_payment_id
                   AND accrual_frequency = 'DAILY')
         AND 1 = 2;


CREATE TABLE XX_MONTHLY_ACCRUAL_TBL AS
    SELECT   /*+ parallel (xcar) full(xcar) */
             xcar.org_id, hdr.provider_code, hdr.ajb_card_type,xcar.store_number, xcar.order_payment_id,
             hdr.om_card_type, xcar.currency_code, hdr.header_id,
             hdr.accrual_liability_account,
             hdr.accrual_liability_costcenter,
             hdr.accrual_liability_location,
             NVL (xcar.payment_amount, 0) amount
        FROM xx_ar_order_receipt_dtl xcar,
             xx_ce_recon_glact_hdr hdr,
             xx_ce_accrual_glact_dtl xcag,
             fnd_lookup_values lv
       WHERE lv.lookup_type = 'OD_PAYMENT_TYPES'
         AND xcar.credit_card_code = lv.meaning
         AND lv.lookup_code = hdr.om_card_type
         AND lv.enabled_flag = 'Y'
         AND xcar.receipt_date BETWEEN lv.start_date_active - 0 AND NVL (lv.end_date_active , xcar.receipt_date + 1 )
         AND xcar.org_id = hdr.org_id
         AND NVL (xcar.payment_amount, 0) != 0
         AND xcar.receipt_status = 'OPEN'
         AND hdr.org_id = 404
         AND xcag.header_id = hdr.header_id
         AND xcar.receipt_date BETWEEN xcag.effective_from_date
                                   AND NVL (xcag.effective_to_date,
                                            xcar.receipt_date + 1
                                           )
         AND xcag.accrual_frequency = 'MONTHLY'
         AND NOT EXISTS (
                SELECT 1
                  FROM xx_ce_cc_fee_accrual_log
                 WHERE order_payment_id = xcar.order_payment_id
                   AND accrual_frequency = 'MONTHLY')
                   AND 1 = 2;
 
                                                             
EXIT;

SHO ERR;
