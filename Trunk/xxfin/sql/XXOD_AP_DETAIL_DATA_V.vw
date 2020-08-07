/* Formatted on 2007/11/14 16:12 (Formatter Plus v4.8.6) */
 --+=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                      Oracle/Office Depot                            |
-- +=====================================================================+
-- | Name  : XXOD_AP_DETAIL_DATA_V                                       |
-- | Description: This view is used in AP Data For Reverse Audit Report. |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version      Date               Author                       Remarks |
-- |=======   ==========          =============           ===============|
-- |1.0       18-AUG-2007      Gokila Tamilselvam         Initial version|
--|1.1        14-NOV-2007      Michelle Gautier Modifed view per Def#2625|
--                             Added Segment3 to the GL Account column   |
--							   and new columns Period Date               ?
-- +=====================================================================+
CREATE OR REPLACE VIEW XXOD_AP_DETAIL_DATA_V (ap_co
                                            , supplier_id
                                            , voucher_id
                                            , legal_entity
                                            , operating_unit_id
                                            , od_department
                                            , line_of_business_sales_channel
                                            , gl_account
                                            , period_date
                                            , supplier_invoice_id
                                            , supplier_invoice_date
                                            , payment_check_description
                                            , supplier_name
                                            , supplier_address_1
                                            , supplier_address_2
                                            , supplier_address_3
                                            , supplier_address_4
                                            , supplier_city
                                            , supplier_state
                                            , supplier_zip_code
                                            , ap_reference_id
                                            , payment_date
                                            , gross_amount_paid
                                            , tax_amount_paid
                                            , invoice_amount
                                            , tax_amount
                                            , accrued_tax
                                            , segment1
                                            , segment3
                                            , segment4
                                             ) AS
   (SELECT apt.ap_co ap_co
         , apt.supplier_id supplier_id
         , apt.voucher_id voucher_id
         , (SELECT ffvv.description
              FROM FND_FLEX_VALUES_VL ffvv, fnd_flex_value_sets ffvs
             WHERE gcc.segment1 = ffvv.flex_value
               AND ffvv.flex_value_set_id = ffvs.flex_value_set_id
               AND ffvs.flex_value_set_name LIKE '%OD_GL_GLOBAL_COMPANY%')
                                                                 legal_entity
         , (SELECT ffvv.description
              FROM FND_FLEX_VALUES_VL ffvv, fnd_flex_value_sets ffvs
             WHERE gcc.segment4 = ffvv.flex_value
               AND ffvv.flex_value_set_id = ffvs.flex_value_set_id
               AND ffvs.flex_value_set_name LIKE '%OD_GL_GLOBAL_LOCATION%')
                                                            operating_unit_id
         , (SELECT ffvv.description
              FROM FND_FLEX_VALUES_VL ffvv, fnd_flex_value_sets ffvs
             WHERE gcc.segment2 = ffvv.flex_value
               AND ffvv.flex_value_set_id = ffvs.flex_value_set_id
               AND ffvs.flex_value_set_name LIKE '%OD_GL_GLOBAL_COST_CENTER%')
                                                                      od_dept
         , (SELECT ffvv.description
              FROM FND_FLEX_VALUES_VL ffvv, fnd_flex_value_sets ffvs
             WHERE gcc.segment6 = ffvv.flex_value
               AND ffvv.flex_value_set_id = ffvs.flex_value_set_id
               AND ffvs.flex_value_set_name LIKE '%OD_GL_GLOBAL_LOB%')
                                                      gl_sales_channel_coding
         , (SELECT gcc.segment3 || ' ' || ffvv.description
              FROM FND_FLEX_VALUES_VL ffvv, fnd_flex_value_sets ffvs
             WHERE gcc.segment3 = ffvv.flex_value
               AND ffvv.flex_value_set_id = ffvs.flex_value_set_id
               AND ffvs.flex_value_set_name LIKE '%OD_GL_GLOBAL_ACCOUNT%')
                                                                   gl_account
         , aid.accounting_date period_date
         , apt.invoice_num invoice_num
         , apt.invoice_date invoice_date
         , apt.payment_check_describition payment_check_describition
         , apt.supplier_name supplier_name
         , apt.first_line first_line
         , apt.second_line second_line
         , apt.third_line third_line
         , apt.fourth_line fourth_line
         , apt.supplier_city supplier_city
         , apt.supplier_state supplier_state
         , apt.supplier_zip_code supplier_zip_code
         , apt.ap_reference_id ap_reference_id
         , apt.payment_date payment_date
         , apt.gross_amount_paid gross_amount_paid
         , apt.tax_amount_paid tax_amount_paid
         , apt.invocie_amount invocie_amount
         , apt.tax_amount tax_amount
         , apt.accrued_tax accrued_tax
         , gcc.segment1 segment1
         , gcc.segment3 segment3
         , gcc.segment4 segment4
      FROM ((SELECT ai.SOURCE ap_co
                  , pv.segment1 supplier_id
                  , ai.voucher_num voucher_id
                  , ai.invoice_num invoice_num
                  , ai.invoice_date invoice_date
                  , ai.description payment_check_describition
                  , pv.vendor_name supplier_name
                  , pvs.address_line1 first_line
                  , pvs.address_line2 second_line
                  , pvs.address_line3 third_line
                  , pvs.address_line4 fourth_line
                  , pvs.city supplier_city
                  , pvs.state supplier_state
                  , pvs.zip supplier_zip_code
                  , DECODE (aip.invoice_payment_type
                          , 'PREPAY', ai.invoice_num
                          , ac.check_number
                           ) ap_reference_id
                  , ac.check_date payment_date
                  , NVL (ai.amount_paid, 0) gross_amount_paid
                  , 0 tax_amount_paid
                  , NVL (ai.invoice_amount, 0) invocie_amount
                  , NVL ((SELECT   SUM (aid.amount)
                              FROM AP_INVOICE_DISTRIBUTIONS aid
                             WHERE aid.line_type_lookup_code = 'TAX'
                               AND aid.invoice_id = ai.invoice_id
                          GROUP BY aid.invoice_id)
                       , 0
                        ) tax_amount
                  , NVL
                       ((SELECT tax
                           FROM (SELECT   main1.inv_id inv_id
                                        , SUM (aid.amount) tax
                                     FROM (SELECT aid.invoice_id inv_id
                                             FROM AP_INVOICE_DISTRIBUTIONS aid
                                                , AP_INVOICES api
                                            WHERE aid.invoice_id =
                                                                api.invoice_id
                                              AND api.invoice_type_lookup_code =
                                                                      'CREDIT'
                                              AND aid.parent_invoice_id IS NOT NULL) main1
                                        , AP_INVOICE_DISTRIBUTIONS aid
                                        , AP_TAX_CODES atc
                                    WHERE aid.line_type_lookup_code = 'TAX'
                                      AND aid.tax_code_id = atc.tax_id
                                      AND UPPER (atc.tax_type) = 'USE'
                                      AND aid.amount >= 0
                                      AND aid.invoice_id = main1.inv_id
                                 GROUP BY main1.inv_id) main2
                              , AP_INVOICES api
                          WHERE main2.inv_id = api.invoice_id
                            AND api.invoice_type_lookup_code = 'CREDIT'
                            AND api.invoice_num LIKE '%_TAX'
                            AND ai.invoice_id IN (
                                   SELECT parent_invoice_id
                                     FROM AP_INVOICE_DISTRIBUTIONS
                                    WHERE invoice_id = main2.inv_id
                                      AND parent_invoice_id IS NOT NULL))
                      , 0
                       ) accrued_tax
               FROM AP_INVOICES ai
                  , po_vendors pv
                  , PO_VENDOR_SITES pvs
                  , AP_CHECKS ac
                  , AP_INVOICE_PAYMENTS aip
              WHERE ai.payment_status_flag IN ('Y', 'P')
                AND ai.vendor_id = pv.vendor_id
                AND ai.vendor_site_id = pvs.vendor_site_id
                AND pvs.vendor_id = pv.vendor_id
                AND ac.vendor_id = pv.vendor_id
                AND ac.vendor_site_id = pvs.vendor_site_id
                AND aip.check_id = ac.check_id
                AND aip.invoice_id = ai.invoice_id
                AND UPPER (ac.status_lookup_code) NOT IN
                       ('OVERFLOW'
                      , 'SET UP'
                      , 'SPOILED'
                      , 'STOP INITIATED'
                      , 'UNCONFIRMED SET UP'
                      , 'VOIDED'
                       )
                AND ai.invoice_id IN (
                       SELECT parent_invoice_id
                         FROM AP_INVOICE_DISTRIBUTIONS aid, AP_INVOICES api
                        WHERE aid.invoice_id = api.invoice_id
                          AND api.invoice_type_lookup_code = 'CREDIT'
                          AND aid.parent_invoice_id IS NOT NULL
                          AND api.invoice_num LIKE '%_TAX'))
            UNION
            (SELECT ai.SOURCE ap_co
                  , pv.segment1 supplier_id
                  , ai.voucher_num voucher_id
                  , ai.invoice_num invoice_num
                  , ai.invoice_date invoice_date
                  , ai.description payment_check_describition
                  , pv.vendor_name supplier_name
                  , pvs.address_line1 first_line
                  , pvs.address_line2 second_line
                  , pvs.address_line3 third_line
                  , pvs.address_line4 fourth_line
                  , pvs.city supplier_city
                  , pvs.state supplier_state
                  , pvs.zip supplier_zip_code
                  , DECODE (aip.invoice_payment_type
                          , 'PREPAY', ai.invoice_num
                          , ac.check_number
                           ) ap_reference_id
                  , ac.check_date payment_date
                  , NVL (ai.amount_paid, 0) gross_amount_paid
                  , NVL ((SELECT   SUM (aid.amount)
                              FROM AP_INVOICE_DISTRIBUTIONS aid
                             WHERE aid.line_type_lookup_code = 'TAX'
                               AND aid.invoice_id = ai.invoice_id
                          GROUP BY aid.invoice_id)
                       , 0
                        ) tax_amount_paid
                  , NVL (ai.invoice_amount, 0) invocie_amount
                  , NVL ((SELECT   SUM (aid.amount)
                              FROM AP_INVOICE_DISTRIBUTIONS aid
                             WHERE aid.line_type_lookup_code = 'TAX'
                               AND aid.invoice_id = ai.invoice_id
                          GROUP BY aid.invoice_id)
                       , 0
                        ) tax_amount
                  , 0 accrued_tax
               FROM AP_INVOICES ai
                  , po_vendors pv
                  , PO_VENDOR_SITES pvs
                  , AP_CHECKS ac
                  , AP_INVOICE_PAYMENTS aip
              WHERE ai.payment_status_flag IN ('Y')
                AND ai.vendor_id = pv.vendor_id
                AND ai.vendor_site_id = pvs.vendor_site_id
                AND pvs.vendor_id = pv.vendor_id
                AND ac.vendor_id = pv.vendor_id
                AND ac.vendor_site_id = pvs.vendor_site_id
                AND aip.check_id = ac.check_id
                AND aip.invoice_id = ai.invoice_id
                AND UPPER (ac.status_lookup_code) NOT IN
                       ('OVERFLOW'
                      , 'SET UP'
                      , 'SPOILED'
                      , 'STOP INITIATED'
                      , 'UNCONFIRMED SET UP'
                      , 'VOIDED'
                       )
                AND ai.invoice_id NOT IN (
                       SELECT parent_invoice_id
                         FROM AP_INVOICE_DISTRIBUTIONS aid, AP_INVOICES api
                        WHERE aid.invoice_id = api.invoice_id
                          AND api.invoice_type_lookup_code = 'CREDIT'
                          AND aid.parent_invoice_id IS NOT NULL
                          AND api.invoice_num LIKE '%_TAX'))
            UNION
            (SELECT ai.SOURCE ap_co
                  , pv.segment1 supplier_id
                  , ai.voucher_num voucher_id
                  , ai.invoice_num invoice_num
                  , ai.invoice_date invoice_date
                  , ai.description payment_check_describition
                  , pv.vendor_name supplier_name
                  , pvs.address_line1 first_line
                  , pvs.address_line2 second_line
                  , pvs.address_line3 third_line
                  , pvs.address_line4 fourth_line
                  , pvs.city supplier_city
                  , pvs.state supplier_state
                  , pvs.zip supplier_zip_code
                  , DECODE (aip.invoice_payment_type
                          , 'PREPAY', ai.invoice_num
                          , ac.check_number
                           ) ap_reference_id
                  , ac.check_date payment_date
                  , NVL (ai.amount_paid, 0) gross_amount_paid
                  , 0 tax_amount_paid
                  , NVL (ai.invoice_amount, 0) invocie_amount
                  , NVL ((SELECT   SUM (aid.amount)
                              FROM AP_INVOICE_DISTRIBUTIONS aid
                             WHERE aid.line_type_lookup_code = 'TAX'
                               AND aid.invoice_id = ai.invoice_id
                          GROUP BY aid.invoice_id)
                       , 0
                        ) tax_amount
                  , 0 accrued_tax
               FROM AP_INVOICES ai
                  , po_vendors pv
                  , PO_VENDOR_SITES pvs
                  , AP_CHECKS ac
                  , AP_INVOICE_PAYMENTS aip
              WHERE ai.payment_status_flag IN ('P')
                AND ai.vendor_id = pv.vendor_id
                AND ai.vendor_site_id = pvs.vendor_site_id
                AND pvs.vendor_id = pv.vendor_id
                AND ac.vendor_id = pv.vendor_id
                AND ac.vendor_site_id = pvs.vendor_site_id
                AND aip.check_id = ac.check_id
                AND aip.invoice_id = ai.invoice_id
                AND UPPER (ac.status_lookup_code) NOT IN
                       ('OVERFLOW'
                      , 'SET UP'
                      , 'SPOILED'
                      , 'STOP INITIATED'
                      , 'UNCONFIRMED SET UP'
                      , 'VOIDED'
                       )
                AND ai.invoice_id NOT IN (
                       SELECT parent_invoice_id
                         FROM AP_INVOICE_DISTRIBUTIONS aid, AP_INVOICES api
                        WHERE aid.invoice_id = api.invoice_id
                          AND api.invoice_type_lookup_code = 'CREDIT'
                          AND aid.parent_invoice_id IS NOT NULL
                          AND api.invoice_num LIKE '%_TAX'))) apt
         , gl_code_combinations gcc
         , AP_INVOICE_DISTRIBUTIONS aid
         , AP_INVOICES apis
     WHERE aid.dist_code_combination_id = gcc.code_combination_id
       AND aid.invoice_id = apis.invoice_id
       AND apis.invoice_num = apt.invoice_num
       AND apis.invoice_num NOT IN (
              SELECT invoice_num
                FROM AP_INVOICES
               WHERE invoice_num LIKE '%_TAX'
                 AND invoice_type_lookup_code = 'CREDIT')
       AND apis.vendor_id IN (SELECT vendor_id
                                FROM po_vendors
                               WHERE segment1 = apt.supplier_id))
/