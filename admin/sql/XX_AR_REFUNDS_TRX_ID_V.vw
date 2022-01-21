-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |                       WIPRO Technologies                                                  |
-- +===========================================================================================+
-- | Name        : XX_AR_REFUND_TRX_ID_V                                                       |
-- | Description : View to select receipts,credit memos and Invoices that                      |
-- |               are eligible for refund.                                                    |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author              Remarks                                        |
-- |=======   ==========   ===========      ===================================================|
-- |   1     2007/11/14     D.Gowda         Modified to address                                |
-- |                                        defects 2640 and 267                               |
-- |   2     2007/12/18     D.Gowda         Modified to address defect                         |
-- |                                        2640 and performance tuning                        |
-- |   3     2008/02/20     B.Looman        Modified to address defect 4381 (CR 341)           |
-- |                                        for deposit refunds-                               |
-- |   4     2008/06/24     B.Looman        Modified  to address defect 8298 and               |
-- |                                        performance tuning,also broke out the OM           |
-- |                                        query to be separate view XX_AR_REFUNDS_TRX_OM_ID_V|
-- |   5     2008/07/09     B.Looman        Modified to address defects 7743 and 8298          |
-- |                                        (for performance)                                  |
-- |   6     2008/09/12     B.Looman        Modified for defect 11109 and added                |
-- |                                        store_customer_name                                |
-- |   7     2009/10/21     Usha            Modified where condition as WHERE name LIKE        |
-- |                                        'US_MAILCHECK_OD%' OR name LIKE 'CA_MAILCHECK_OD%' |
-- |                                        for Defect 3085                                    |
-- |   8     2010/01/21     Bhuvaneswary S  Modified to fetch invoices for CR 697/698 R1.2     |
-- +===========================================================================================+
CREATE OR REPLACE FORCE VIEW APPS.XX_AR_REFUND_TRX_ID_V
( source,
  customer_id,
  cash_receipt_id,
  customer_trx_id,
  class,
  trx_id,
  trx_number,
  trx_date,
  invoice_currency_code,
  amount_due_remaining,
  aps_last_update_date,
  pre_selected_flag,
  refund_request,
  refund_status,
  org_id,
  bill_to_site_use_id,
  customer_site_use_id,
  location_id,
  address1,
  address2,
  address3,
  city,
  state,
  province,
  postal_code,
  country,
  cash_receipt_status,
  om_hold_status,
  om_delete_status,
  om_store_number,
  store_customer_name,
  last_updated_by )
AS
  (SELECT /*+ INDEX(aps AR_PAYMENT_SCHEDULES_N19) */ 'NON-OM' source,
          aps.customer_id,
          aps.cash_receipt_id, 
          aps.customer_trx_id,
          aps.class,
          acr.cash_receipt_id trx_id,
          aps.trx_number, 
          aps.trx_date, 
          aps.invoice_currency_code,
          aps.amount_due_remaining,
          aps.last_update_date aps_last_update_date,
          CASE WHEN acr.attribute9 IN ('Send Refund','Send Refund Alt')
           THEN 'Y' ELSE 'N' END pre_selected_flag,
          acr.attribute9 refund_request,
          acr.attribute10 refund_status,
          aps.org_id,
          NULL bill_to_site_use_id, 
          acr.customer_site_use_id,
          NULL location_id, 
          NULL address1, 
          NULL address2, 
          NULL address3, 
          NULL city,
          NULL state, 
          NULL province, 
          NULL postal_code, 
          NULL country,
          acr.status cash_receipt_status, 
          NULL om_hold_status,
          NULL om_delete_status, 
          NULL om_store_number,
          NULL store_customer_name,
          acr.last_updated_by
     FROM apps.ar_payment_schedules_all aps,
          apps.ar_cash_receipts_all acr      
    WHERE acr.cash_receipt_id = aps.cash_receipt_id
      AND aps.class = 'PMT'
      AND acr.receipt_method_id NOT IN 
          (SELECT receipt_method_id
             FROM apps.ar_receipt_methods ARM                           
             --WHERE name LIKE 'US_MAILCHECK_OD%' OR name LIKE 'CA_MAILCHECK_OD%') -- Commented for CR 697/698
             WHERE EXISTS  (SELECT 1
                           FROM   apps.fnd_lookup_values FLV
                            WHERE  lookup_type = 'XX_OD_AR_REFUND_RECEIPT_METHOD'
                            AND    SYSDATE BETWEEN FLV.start_date_active AND NVL(FLV.end_date_active,sysdate+1)
                            AND    FLV.enabled_flag = 'Y'
                            AND    FLV.meaning = ARM.name    )) --Added for CR 697/698 R1.2
      AND NOT EXISTS
          (SELECT 1
             FROM apps.xx_ar_refund_trx_tmp
            WHERE trx_id = aps.cash_receipt_id
              AND trx_type = 'R'
              AND status != 'D'
              )
      AND NOT EXISTS
          (SELECT 1
             FROM apps.hz_cust_accounts
            WHERE cust_account_id = aps.customer_id
              AND customer_type = 'I')
      AND aps.amount_due_remaining < 0 
      AND aps.status='OP'
  UNION ALL   
   SELECT /*+ INDEX(aps AR_PAYMENT_SCHEDULES_N19) */ 'NON-OM' source,
        aps.customer_id,
        aps.cash_receipt_id, 
        aps.customer_trx_id,
        aps.class,
        rct.customer_trx_id trx_id,
        aps.trx_number, 
        aps.trx_date, 
        aps.invoice_currency_code,
        aps.amount_due_remaining,
        aps.last_update_date aps_last_update_date,
        CASE WHEN rct.attribute9 IN ('Send Refund','Send Refund Alt')
          THEN 'Y' ELSE 'N' END pre_selected_flag,
        rct.attribute9 refund_request,
        rct.attribute10 refund_status,
        aps.org_id,
        rct.bill_to_site_use_id, 
        NULL customer_site_use_id,
        NULL location_id, 
        NULL address1, 
        NULL address2, 
        NULL address3, 
        NULL city,
        NULL state, 
        NULL province, 
        NULL postal_code, 
        NULL country,
        'UNAPP' cash_receipt_status, 
        NULL om_hold_status,
      NULL om_delete_status, 
       NULL om_store_number,
       NULL store_customer_name,
        rct.last_updated_by
    FROM apps.ar_payment_schedules_all aps,
          apps.ra_customer_trx_all rct
    WHERE aps.customer_trx_id = rct.customer_trx_id
  --AND aps.class = 'CM'  -- Commented for CR 697/698
    AND aps.class IN ('CM', 'INV')  -- Added for CR 697/698 for including overpaid invoices also
    AND NOT EXISTS 
          (SELECT 1
           FROM apps.xx_ar_refund_trx_tmp
           WHERE trx_id = rct.customer_trx_id
         --AND trx_type = 'C' Commented for CR 697/698
           AND trx_type IN ('C','I') -- Added for CR 697/698 
          AND status != 'D'  
           )
    AND NOT EXISTS
          (SELECT 1
           FROM apps.hz_cust_accounts
           WHERE cust_account_id = aps.customer_id
           AND customer_type = 'I')
    AND aps.amount_due_remaining < 0 
    AND aps.status='OP');