-- Created by B.Looman Date:2008/06/24 to address defect 8298 (broke out the OM source)
-- Modified by B.Looman Date:2008/07/09 to address defects 7743 and 8298 (for performance)
-- Modified by B.Looman Date:2008/09/12 - defect 11109 - add store_customer_name
-- Modified by Usha Date :2009/10/21  --Defect 3085 ---Modified where condition as WHERE name LIKE 'US_MAILCHECK_OD%' OR name LIKE 'CA_MAILCHECK_OD%'
-- Modified by Jay Gupta Date:2011/03/21, Changes for SDR Project
-- Modified by Gaurav Agarwal  Date:2011/05/04, Changes for SDR Project
CREATE OR REPLACE FORCE VIEW APPS.XX_AR_REFUND_TRX_OM_ID_V
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
  last_updated_by,
  ref_mailcheck_id )
AS
  ( SELECT 'OM' source,
           aps.customer_id,
           aps.cash_receipt_id,
           NULL customer_trx_id,
           aps.class,
           aps.cash_receipt_id trx_id,
           aps.trx_number,
           aps.trx_date,
           aps.invoice_currency_code,
           xort.credit_amount * -1 amount_due_remaining,
           aps.last_update_date aps_last_update_date,
           'N' pre_selected_flag,
           acr.attribute9 refund_request,
           acr.attribute10 refund_status,
           xort.org_id,
           NULL bill_to_site_use_id,
           acr.customer_site_use_id,
           NULL location_id,
           xamch.address_line_1,
           xamch.address_line_2,
           xamch.address_line_3,
           xamch.city,
           CASE WHEN xamch.country = 'US' THEN xamch.state_province ELSE NULL END state,
           CASE WHEN xamch.country = 'CA' THEN xamch.state_province ELSE NULL END province,
           xamch.postal_code,
           xamch.country,
           acr.status cash_receipt_status,
           xamch.hold_status om_hold_status,
           xamch.delete_status om_delete_status,
           NVL(acr.attribute1,acr.attribute2) om_store_number,
           xamch.store_customer_name,
           acr.last_updated_by last_updated_by,
           xamch.ref_mailcheck_id
     FROM ar_payment_schedules_all aps,
          ar_cash_receipts_all acr,
          xx_ar_mail_check_holds xamch,
          xx_om_return_tenders_all xort
    WHERE acr.cash_receipt_id = xort.cash_receipt_id
      AND aps.cash_receipt_id = acr.cash_receipt_id
      AND acr.receipt_method_id IN 
          (SELECT receipt_method_id
             FROM ar_receipt_methods                            
            WHERE name LIKE 'US_MAILCHECK_OD%' OR name LIKE 'CA_MAILCHECK_OD%')
      AND aps.class = 'PMT'
      AND NOT EXISTS 
          (SELECT 1
             FROM xx_ar_refund_trx_tmp
            WHERE trx_id = xort.cash_receipt_id
              AND trx_type = 'R'
              AND status != 'D')
    --  AND aps.amount_due_remaining < 0   -- Commented by Gaurav Agarwal
      AND NVL(xamch.aops_order_number,xamch.pos_transaction_number) = xort.orig_sys_document_ref
      AND xamch.process_code = 'PENDING'
      AND xort.I1025_status = 'MAILCHECK_HOLD'
      AND xamch.ar_cash_receipt_id IS NULL -- Added for SDR Project
   UNION ALL   
   SELECT 'OM' source,
           aps.customer_id,
           aps.cash_receipt_id,
           NULL customer_trx_id,
           aps.class,
           aps.cash_receipt_id trx_id,
           aps.trx_number,
           aps.trx_date,
           aps.invoice_currency_code,
           xold.prepaid_amount amount_due_remaining,
           aps.last_update_date aps_last_update_date,
           'N' pre_selected_flag,
           acr.attribute9 refund_request,
           acr.attribute10 refund_status,
           xold.org_id,
           NULL bill_to_site_use_id,
           acr.customer_site_use_id,
           NULL location_id,
           xamch.address_line_1,
           xamch.address_line_2,
           xamch.address_line_3,
           xamch.city,
           CASE WHEN xamch.country = 'US' THEN xamch.state_province ELSE NULL END state,
           CASE WHEN xamch.country = 'CA' THEN xamch.state_province ELSE NULL END province,
           xamch.postal_code,
           xamch.country,
           acr.status cash_receipt_status,
           xamch.hold_status om_hold_status,
           xamch.delete_status om_delete_status,
           NVL(acr.attribute1,acr.attribute2) om_store_number,
           xamch.store_customer_name,
           acr.last_updated_by last_updated_by,
            xamch.ref_mailcheck_id
      FROM ar_payment_schedules_all aps,
           ar_cash_receipts_all acr,
           xx_ar_mail_check_holds xamch,
           xx_om_legacy_deposits xold,
                      xx_om_legacy_dep_dtls xoldd 
     WHERE acr.cash_receipt_id = xold.cash_receipt_id
       AND aps.cash_receipt_id = acr.cash_receipt_id
       AND aps.class = 'PMT'
       AND NOT EXISTS 
           (SELECT 1
              FROM xx_ar_refund_trx_tmp
             WHERE trx_id = xold.cash_receipt_id
               AND trx_type = 'R'
               AND status != 'D') 
      --  AND aps.amount_due_remaining < 0   -- Commented by Gaurav Agarwal
              AND xoldd.transaction_number(+) = xold.transaction_number
       AND NVL(xamch.aops_order_number, xamch.pos_transaction_number) = NVL(
                xold.orig_sys_document_ref,xoldd.orig_sys_document_ref)
       AND xamch.process_code = 'PENDING'
       AND xold.I1025_status = 'MAILCHECK_HOLD'
       AND xold.prepaid_amount < 0 
       AND xamch.ar_cash_receipt_id IS NULL -- Added for SDR Project
       )
/