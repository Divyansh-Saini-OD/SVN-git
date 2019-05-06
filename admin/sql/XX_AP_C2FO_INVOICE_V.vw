---+========================================================================================================+        
---|                                        Office Depot - C2FO                                             |
---+========================================================================================================+
---|    Application             :       AP                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AP_C2FO_INVOICE.vw                                               |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             31-AUG-2018       Antonio Morales    Initial Version                                |
---|    1.1             06-SEP-2018       Madhu Bolli        Added Business Requirement Changes             |
---|                                                                                                        |
---+========================================================================================================+


/************************************************************************************************************************
   NAME:       XXFIN.XX_AP_C2FO_INVOICE
   PURPOSE:  This view displays transactions to send to C2FO
   REVISIONS:
   Ver        Date        	Author            			Company     Description
   ---------  -----------  	---------------   			--------    ----------------------------------
   1.0        02/24/15    	Joshua Wilson     			C2FO        1. Created this view.
   1.0        08/29/2018  	Nageswara Rao Chennupati	C2FO		1. Updated as per the new requirements.
   1.1        09/05/2018  	Paddy Sanjeevi              OD   		Modified for performance
   1.2        09/12/2018    Antonio Morales             OD          Modified this for performance
   1.3        09/19/2018    Madhu Bolli            		OD          Modified to allow invoices if it contains item,misc, freight
   1.4        09/24/2018    Madhu Bolli            		OD          Modified to restrict invoices if the supplier site is inactive
   1.5        01/31/2019    Vivek Kumar                 OD          Modified for NAIT-81968 to include Organization Type = null  
   1.6        05/06/2019    Arun Dsouza                 OD          Modifed of FP testing to fetch data for a single day  

*************************************************************************************************************************/





-- Unable to render VIEW DDL for object APPS.XX_AP_C2FO_INVOICE_V with DBMS_METADATA attempting internal generator.
CREATE or replace VIEW APPS.XX_AP_C2FO_INVOICE_V AS SELECT "COMPANY_ID", "DIVISION_ID", "INVOICE_ID", "AMOUNT", "CURRENCY", "PAYMENT_DUE_DATE", "TRANSACTION_TYPE", "TRANSACTION_DATE", "VOUCHER_ID",
         "PAYMENT_TERM", "PAYMENT_METHOD", "ADJ_INVOICE_ID", "ADJUSTMENT_REASON_CODE", "DESCRIPTION", "VAT_AMOUNT", "AMOUNT_GROSSVAT", "AMOUNT_NETVAT",
         "VAT_TO_BE_DISCOUNTED", "BUYER_NAME", "BUYER_ADDRESS", "BUYER_TAX_ID", "LOCAL_CURRENCY_KEY", "LOCAL_CURRENCY_RATE", "LOCAL_CURRENCY_ORG_INV_AMT",
         "LOCAL_CURRENCY_ORIGINAL_VAT", "MARKET_TYPE", "PO_ID", "EBS_ORG_ID", "EBS_VENDOR_ID", "EBS_SUPPLIER_NUMBER", "EBS_VENDOR_SITE_ID", "EBS_VENDOR_SITE_CODE",
         "EBS_INVOICE_ID", "EBS_INVOICE_NUM", "EBS_PAY_GROUP", "EBS_PAY_PRIORITY", "EBS_SUP_PAY_PRIORITY", "EBS_SITE_PAY_PRIORITY", "EBS_VOUCHER_NUM",
         "EBS_CASH_DISCOUNT_AMOUNT", "EBS_INV_AMT_BEFORE_CASH_DISC"
  FROM  (
   SELECT /*+ leading(apsa)  index(apsa,AP_PAYMENT_SCHEDULES_N2) index(aia,AP_INVOICES_U1) */
          REPLACE (REPLACE (assa.org_id || '|' || sup.vendor_id || '|' || assa.vendor_site_id, ',', '')
                 , '"'
                 , ''
                  ) AS company_id
        , NULL AS division_id
        , REPLACE (REPLACE (aia.org_id || '|' || aia.invoice_id || '|' || aia.invoice_num, ',', ''), '"', '') AS invoice_id
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.amt_or_amt_netvat_after_disc (aia.org_id, aia.invoice_id)) AS amount
		,(aia.invoice_amount-NVL(aia.total_tax_amount,0)-NVL(apsa.discount_amount_available,0)) AS amount
        , aia.invoice_currency_code AS currency
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.pay_term_early_due_date (aia.org_id, aia.invoice_id)) AS payment_due_date
		,TO_CHAR(NVL(apsa.discount_date, apsa.due_date),'YYYY-MM-DD')  AS payment_due_date
        , CASE
             WHEN aia.invoice_type_lookup_code = 'STANDARD' THEN '1'
             ELSE '2'
          END AS transaction_type
        , TO_CHAR (aia.invoice_date, 'YYYY-MM-DD') AS transaction_date
        , aia.invoice_id AS voucher_id
        , REPLACE (REPLACE (aia.terms_id || '|' || att.NAME, ',', ''), '"', '') AS payment_term
        , aia.payment_method_code AS payment_method
        , decode(aia.invoice_type_lookup_code, 'DEBIT',
                         decode(substr(aia.invoice_num,length(aia.invoice_num) -1),'DM'
                               ,REPLACE(REPLACE (
                               (select aiaOrig.org_id || '|' || aiaOrig.invoice_id || '|' || aiaOrig.invoice_num from ap_invoices_all aiaOrig where aiaOrig.invoice_num = substr(aia.invoice_num,1,length(aia.invoice_num) -2) and aiaOrig.vendor_site_id = aia.vendor_site_id)
                               ,',', ''), '"', '')
                               ,null),null) adj_invoice_id
        , REPLACE (REPLACE (DECODE (aia.invoice_type_lookup_code
                                  , 'CREDIT', aia.description
                                  , 'DEBIT', aia.description
                                  , NULL
                                   )
                          , ','
                          , ''
                           )
                 , '"'
                 , ''
                  ) AS adjustment_reason_code
        , REPLACE (REPLACE (DECODE (aia.invoice_type_lookup_code
                                  , 'CREDIT', NULL
                                  , 'DEBIT', NULL
                                  , aia.description
                                   )
                          , ','
                          , ''
                           )
                 , '"'
                 , ''
                  ) AS description
        , 0 vat_amount --aia.total_tax_amount AS vat_amount changed by C2FO request
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.amount_grossvat_after_disc (aia.org_id, aia.invoice_id)) AS amount_grossvat
		,(aia.invoice_amount-NVL(apsa.discount_amount_available,0)) AS amount_grossvat
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.amt_or_amt_netvat_after_disc (aia.org_id, aia.invoice_id)) AS amount_netvat
		,(aia.invoice_amount-NVL(aia.total_tax_amount,0)-NVL(apsa.discount_amount_available,0))  AS amount_netvat
        , 0 vat_to_be_discounted
        , REPLACE (REPLACE (haou.NAME, ',', ''), '"', '') AS buyer_name
        , REPLACE (REPLACE ((SELECT    hla.address_line_1
                                    || ' '
                                    || hla.address_line_2
                                    || ' '
                                    || hla.address_line_3
                                    || ' '
                                    || hla.town_or_city
                                    || ' '
                                    || hla.region_2
                                    || ' '
                                    || hla.postal_code
                                    || ' '
                                    || (   hla.country
                                        || '|'
                                        || (SELECT hg.geography_name
                                            FROM   hz_geographies hg
                                            WHERE  hg.geography_type = 'COUNTRY'
                                            AND    hg.country_code = hla.country)
                                       )
                             FROM   hr_locations_all hla
                             WHERE  hla.location_id = haou.location_id)
                          , ','
                          , ''
                           )
                 , '"'
                 , ''
                  ) AS buyer_address
        , (SELECT xle_reg.registration_number
           FROM   xle_entity_profiles xle_ep
                , xle_registrations xle_reg
                , hr_all_organization_units hr_aou
                , hr_all_organization_units_tl hr_aoutl
                , hr_locations_all hr_la
                , hr_organization_information hr_oi
           WHERE  1 = 1
           AND    xle_ep.transacting_entity_flag = 'Y'
           AND    xle_ep.legal_entity_id = xle_reg.source_id
           AND    xle_reg.source_table = 'XLE_ENTITY_PROFILES'
           AND    xle_reg.identifying_flag = 'Y'
           AND    xle_ep.legal_entity_id = hr_oi.org_information2
           AND    xle_reg.location_id = hr_la.location_id
           AND    hr_oi.org_information_context = 'Operating Unit Information'
           AND    hr_aoutl.organization_id = hr_aou.organization_id
           AND    hr_oi.organization_id = hr_aoutl.organization_id
           AND    hr_aou.organization_id = aia.org_id
           AND    hr_la.location_id = haou.location_id) AS buyer_tax_id
        , aia.payment_currency_code AS local_currency_key
        , NVL (aia.payment_cross_rate, 1) AS local_currency_rate
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.local_currency_org_inv_amount (aia.org_id, aia.invoice_id)) AS local_currency_org_inv_amt
		, (NVL(aia.pay_curr_invoice_amount,0) - (NVL(apsa.discount_amount_available,0) * NVL(aia.payment_cross_rate,1))) AS local_currency_org_inv_amt
        , (NVL (aia.total_tax_amount, 0) * NVL (aia.payment_cross_rate, 1)) AS local_currency_original_vat
        , (SELECT val.target_value1
             FROM xx_fin_translatedefinition def
                 ,xx_fin_translatevalues VAL
            WHERE 1=1
              AND def.translate_id = VAL.translate_id
              AND def.translation_name = 'XX_AP_C2FO_PAYGROUPS_MT'
              AND source_value1 = aia.pay_group_lookup_code) AS market_type
        , NVL2 (aia.po_header_id,(aia.org_id || '|' || aia.vendor_id || '|' || aia.vendor_site_id || '|' || aia.po_header_id),NULL) AS po_id
        , aia.org_id AS ebs_org_id
        , sup.vendor_id AS ebs_vendor_id
        , sup.segment1 AS ebs_supplier_number
        , assa.vendor_site_id AS ebs_vendor_site_id
        , assa.vendor_site_code AS ebs_vendor_site_code
        , aia.invoice_id AS ebs_invoice_id
        , aia.invoice_num AS ebs_invoice_num
        , aia.pay_group_lookup_code AS ebs_pay_group
        , apsa.payment_priority AS ebs_pay_priority
        , sup.payment_priority AS ebs_sup_pay_priority
        , assa.payment_priority AS ebs_site_pay_priority
        , aia.voucher_num AS ebs_voucher_num
        --, (xx_ap_c2fo_int_ebs_ap_pay_pkg.ebs_cash_discount_amt (aia.org_id, aia.invoice_id)) AS ebs_cash_discount_amount
		, NVL(apsa.discount_amount_available,0) AS ebs_cash_discount_amount
        , NVL (NVL (aia.invoice_amount, 0) - NVL (aia.total_tax_amount, 0), 0) AS ebs_inv_amt_before_cash_disc
        , (SELECT /*+ index(ail,AP_INVOICE_LINES_U1) */
                  SUM (ail.amount)
             FROM ap_invoice_lines_all ail
            WHERE ail.invoice_id = aia.invoice_id
              AND line_type_lookup_code <> 'TAX'
          )  AS line_amount
        , max(xev.event_id) OVER (PARTITION BY xte.source_id_int_1) max_event_id
        , xev.event_id
   FROM   hr_all_organization_units haou
        , gl_code_combinations gcc
        , ap_terms_tl att
        , ap_suppliers sup
        , ap_supplier_sites_all assa
        , ap_invoices_all aia
        , ap_payment_schedules_all apsa
        , xla_events xev
        , xla_transaction_entities xte
   WHERE  apsa.payment_status_flag = 'N'
   AND    apsa.payment_num = 1
   and    aia.invoice_id = apsa.invoice_id
-- inv date range added by arun for uat test data gen for one day
   and    aia.invoice_date > to_date('10-dec-2018','dd-mon-yyyy')
   and    aia.invoice_date < TO_DATE('12-dec-2018','dd-mon-yyyy')  
   AND    aia.org_id = apsa.org_id
   AND    aia.approval_ready_flag = 'Y'
   AND    NVL (aia.prepay_flag, 'N') = 'N'
   AND    aia.source NOT IN ('US_OD_C2FO', 'US_OD_AR_REFUND', 'US_OD_PCARD','US_OD_RETAIL_REFUND')
   AND    assa.attribute8 NOT IN ('EX-ESC','EX-REB','EX-RNT','TR-IMP','TR-OMXREGIMP','TR-OMXVSIIMP','TR-RTV-ADDR')
   AND    sup.vendor_type_lookup_code NOT IN ('GARNISHMENT','TAX AUTHORITY')
-- AND    sup.organization_type_lookup_code <> 'GOVERNMENT AGENCY' -- Commented For NAIT-81968
   AND     NVL (sup.organization_type_lookup_code, 'N') <> 'GOVERNMENT AGENCY' -- Added for NAIT-81968
   AND    aia.invoice_type_lookup_code NOT IN ('EXPENSE REPORT', 'PREPAYMENT')
   AND    NVL (aia.amount_paid, 0) = 0
   AND    aia.wfapproval_status IN ('MANUALLY APPROVED', 'NOT REQUIRED', 'WFAPPROVED')
   AND    assa.vendor_site_id = aia.vendor_site_id
   AND    assa.org_id = aia.org_id
   AND    assa.hold_all_payments_flag = 'N'
   AND    (assa.inactive_date IS NULL OR assa.inactive_date > SYSDATE)
   AND    SYSDATE BETWEEN nvl(sup.start_date_active,SYSDATE - 1) AND nvl(sup.end_date_active,SYSDATE + 1)
   AND    sup.enabled_flag = 'Y'
   AND    sup.vendor_id = aia.vendor_id
   AND    sup.hold_all_payments_flag = 'N'
   AND    NVL (sup.hold_flag, 'N') = 'N'
   AND    att.term_id = aia.terms_id
   AND    gcc.code_combination_id = aia.accts_pay_code_combination_id
   AND    haou.organization_id = assa.org_id
   AND    NOT EXISTS (SELECT 1
                        FROM ap_holds_all aha
                       WHERE aha.invoice_id = aia.invoice_id
                         AND aha.release_lookup_code IS NULL
                      )
   AND    xte.source_id_int_1  = aia.invoice_id
   AND    xte.application_id   = 200
   AND    xte.entity_code      = 'AP_INVOICES'
   AND    xev.entity_id        = xte.entity_id
   AND    xev.application_id   = 200
   AND    xev.event_type_code  LIKE '%VALIDATED%'
   and    aia.payment_method_code <> 'CLEARING'  -- new Madhu
   -- staging vendor sub query added by arun for UAT test data generation
--   and (ASSA.VENDOR_ID,ASSA.VENDOR_SITE_ID)  in
--       (select   distinct     EBS_VENDOR_ID		
--                             ,EBS_VENDOR_SITE_ID
--from XX_AP_C2FO_AWARD_DATA_STAGING S)
  )
   WHERE line_amount != 0
     AND event_id = max_event_id
;

show error