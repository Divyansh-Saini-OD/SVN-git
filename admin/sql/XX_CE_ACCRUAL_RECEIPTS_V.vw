/* Formatted on 2008/07/29 15:24 (Formatter Plus v4.8.8) */
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         | 
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name : XX_CE_ACCRUAL_RECEIPTS_V                                          |
-- | Description : Create the Cash Management (CE) Reconciliation             |
-- |               view XX_CE_ACCRUAL_RECEIPTS_V                              |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ==========   =============       ===============================|
-- | V1.0     28-Nov-2007  D. Gowda  T Banks   Initial version                |  
-- |          28-Jun-2008  D. Gowda            Use effective_from_date-0      |
-- |                                             to force index use           |    
-- |          29-Jul-2008  D. Gowda            Use start-date and end date on |
-- |                                             lookups                      |
-- |          22-APR-2011  Gaurav Agarwal      View Defination Changed for SDR|
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE FORCE VIEW "XX_CE_ACCRUAL_RECEIPTS_V" ("CASH_RECEIPT_ID", "RECEIPT_NUMBER", "STORE_NUMBER","ORDER_PAYMENT_ID","RECEIPT_METHOD_ID", "RECEIPT_DATE", "CURRENCY_CODE", "RECEIPT_STATUS", "AMOUNT", "OM_CARD_TYPE", "OM_CARD_TYPE_MEANING", "AJB_CARD_TYPE", "PROVIDER_CODE", "HEADER_ID", "ORG_ID", "REMITTED")
AS
  (SELECT xaor.cash_receipt_id,
    xaor.receipt_number,
    xaor.store_number,
    xaor.order_payment_id,
    xaor.receipt_method_id ,
    xaor.receipt_date receipt_date,
    xaor.currency_code currency_code,
    xaor.receipt_status receipt_status,
    xaor.payment_amount amount,
    hdr.om_card_type ,
    xaor.credit_card_code om_card_type_meaning,
    hdr.ajb_card_type ,
    hdr.provider_code,
    hdr.header_id,
    xaor.org_id org_id,
    XAOR.REMITTED
  FROM xx_ar_order_receipt_dtl xaor,
    fnd_lookup_values lv ,
    xx_ce_recon_glact_hdr hdr
  WHERE xaor.credit_card_code IS NOT NULL
  AND lv.lookup_type           = 'OD_PAYMENT_TYPES'
  AND xaor.credit_card_code    = lv.meaning
  AND lv.lookup_code           = hdr.om_card_type
  AND lv.enabled_flag          = 'Y'
  AND xaor.org_id              = hdr.org_id
  AND xaor.receipt_date BETWEEN hdr.effective_from_date                                                                                          - 0 AND NVL (hdr.effective_to_date , xaor.receipt_date + 1 )
  AND xaor.receipt_date BETWEEN lv.start_date_active                                                                                             - 0 AND NVL (lv.end_date_active , xaor.receipt_date + 1 )
  AND xaor.org_id = NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1) , ' ', NULL , SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10) ) ) , -99 )
  AND EXISTS
    (SELECT 1
    FROM xx_ce_accrual_glact_dtl dtl
    WHERE header_id = hdr.header_id
    )
  );

EXIT;