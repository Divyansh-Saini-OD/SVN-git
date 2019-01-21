CREATE OR REPLACE VIEW xx_ar_refund_trx_v
AS
   SELECT 'NON-OM' SOURCE, aps.customer_id customer_id
        , cust.account_number customer_number
        , aps.cash_receipt_id cash_receipt_id, rct.customer_trx_id
        , aps.CLASS CLASS
        , DECODE (CLASS
                , 'PMT', aps.cash_receipt_id
                , rct.customer_trx_id
                 ) trx_id
        , aps.trx_number, aps.trx_date, aps.invoice_currency_code
        , aps.amount_due_remaining amount_due_remaining
        , aps.last_update_date aps_last_update_date
        , DECODE (UPPER (DECODE (CLASS
                               , 'PMT', acr.attribute9
                               , 'CM', rct.attribute9
                               , rct.attribute9
                                )
                        )
                , 'SEND REFUND', 'Y'
                , 'SEND REFUND ALT', 'Y'
                , 'N'
                 ) pre_selected_flag
        , acr.attribute9 pmt_dff1, acr.attribute10 pmt_dff2
        , rct.attribute9 cm_dff1, rct.attribute10 cm_dff2, aps.org_id
        , rct.bill_to_site_use_id, acr.customer_site_use_id, party.party_name
        , hl.location_id, hl.address1, hl.address2, hl.address3, hl.city
        , hl.state, hl.province, hl.postal_code, hl.country
        , acr.status cash_receipt_status, NULL om_hold_status
        , NULL om_delete_status, NULL om_store_number
     FROM ar_payment_schedules_all aps
        , ar_cash_receipts_all acr
        , ra_customer_trx_all rct
        , hz_cust_accounts cust
        , hz_parties party
        , hz_cust_accounts_all hca
        , hz_cust_acct_sites_all hcas
        , hz_cust_site_uses_all hcsu
        , hz_party_sites hps
        , hz_locations hl
    WHERE 1 = 1
      AND party.party_id = hca.party_id(+)
      AND hca.cust_account_id = hcas.cust_account_id(+)
      AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id(+)
      AND hcas.party_site_id = hps.party_site_id
      AND hl.location_id = hps.location_id
      AND hcas.org_id = aps.org_id
      AND NVL (hcsu.primary_flag, 'N') = 'Y'
      AND hcsu.site_use_code = 'BILL_TO'
      AND NVL (acr.receipt_method_id, -99999) NOT IN (
                                                SELECT receipt_method_id
                                                  FROM ar_receipt_methods
                                                 WHERE NAME =
                                                             'US_MAILCHECK_OD')
      AND aps.customer_id = cust.cust_account_id
      AND cust.party_id = party.party_id
      AND (   (    aps.CLASS = 'PMT'
               AND NVL (aps.customer_id, 0) = acr.pay_from_customer
              )
           OR (    aps.CLASS = 'CM'
               AND NVL (aps.customer_id, 0) = rct.bill_to_customer_id
              )
          )
      AND aps.CLASS IN ('PMT', 'CM')
      AND NOT EXISTS (
             SELECT 1
               FROM xx_ar_refund_trx_tmp
              WHERE trx_id =
                       DECODE (CLASS
                             , 'PMT', aps.cash_receipt_id
                             , rct.customer_trx_id
                              )
                AND NVL (status, 'I') != 'D')
      AND aps.cash_receipt_id = acr.cash_receipt_id(+)
      AND aps.customer_trx_id = rct.customer_trx_id(+)
      AND NVL (cust.customer_type, 'X') != 'I'
      AND NVL (aps.amount_due_remaining, 0) < 0
   UNION ALL
   SELECT 'OM' SOURCE, aps.customer_id customer_id
        , cust.account_number customer_number
        , aps.cash_receipt_id cash_receipt_id, 0, aps.CLASS CLASS
        , aps.cash_receipt_id trx_id, aps.trx_number, aps.trx_date
        , aps.invoice_currency_code
        , aps.amount_due_remaining amount_due_remaining
        , aps.last_update_date aps_last_update_date, 'N' pre_selected_flag
        , acr.attribute9 pmt_dff1, acr.attribute10 pmt_dff2, NULL cm_dff1
        , NULL cm_dff2, aps.org_id, NULL, acr.customer_site_use_id
        , xamch.store_customer_name party_name, NULL, xamch.address_line_1
        , xamch.address_line_2, xamch.address_line_3, xamch.city
        , DECODE (xamch.country, 'CA', NULL, xamch.state_province) state
        , DECODE (xamch.country, 'CA', xamch.state_province, NULL) province
        , xamch.postal_code, xamch.country, acr.status cash_receipt_status
        , xamch.hold_status om_hold_status
        , xamch.delete_status om_delete_status
        , (SELECT LPAD (haou.attribute1, 6, '0')
                                                store_number
             FROM xx_om_return_tenders_all xort
                , xx_om_header_attributes_all xoha
                , hr_all_organization_units haou
            WHERE xort.header_id = xoha.header_id
              AND xoha.paid_at_store_id = haou.organization_id
              AND xort.cash_receipt_id = acr.cash_receipt_id) om_store_number
     FROM ar_payment_schedules_all aps
        , ar_cash_receipts_all acr
        , hz_cust_accounts cust
        , hz_parties party
        , xx_ar_mail_check_holds xamch
    WHERE 1 = 1
      AND acr.receipt_method_id = (SELECT receipt_method_id
                                     FROM ar_receipt_methods
                                    WHERE NAME = 'US_MAILCHECK_OD')
      AND aps.customer_id = acr.pay_from_customer
      AND aps.customer_id = cust.cust_account_id
      AND cust.party_id = party.party_id
      AND aps.CLASS = 'PMT'
      AND NOT EXISTS (
                SELECT 1
                  FROM xx_ar_refund_trx_tmp
                 WHERE trx_id = aps.cash_receipt_id
                       AND NVL (status, 'I') != 'D')
      AND aps.cash_receipt_id = acr.cash_receipt_id
      AND NVL (aps.amount_due_remaining, 0) < 0
      AND NVL (xamch.aops_order_number, xamch.pos_transaction_number) =
                                                                acr.attribute7
      AND xamch.process_code = 'PENDING'
      AND xamch.hold_status IN ('P', 'N')
      AND acr.attribute11 = 'REFUND'
      AND acr.attribute13 LIKE ('ON_HOLD|%')
/

