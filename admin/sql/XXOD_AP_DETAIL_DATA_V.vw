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
-- +=====================================================================+
 CREATE OR REPLACE VIEW XXOD_AP_DETAIL_DATA_V
 (AP_Co
  ,Supplier_ID
  ,Voucher_ID
  ,Legal_Entity
  ,Operating_Unit_ID
  ,OD_Department
  ,Line_of_Business_Sales_Channel
  ,GL_Account
  ,Supplier_Invoice_ID
  ,Supplier_Invoice_Date
  ,Payment_Check_Description
  ,Supplier_Name
  ,Supplier_Address_1
  ,Supplier_Address_2
  ,Supplier_Address_3
  ,Supplier_Address_4
  ,Supplier_City
  ,Supplier_State
  ,Supplier_Zip_code
  ,AP_Reference_ID
  ,Payment_Date
  ,Gross_Amount_Paid
  ,Tax_Amount_Paid
  ,Invoice_Amount
  ,Tax_Amount
  ,Accrued_Tax
  ,Segment1
  ,segment3
  ,segment4
  )
   AS
     (
      SELECT APT.AP_CO                            AP_Co
             ,APT.SUPPLIER_ID                     SUPPLIER_ID
             ,APT.VOUCHER_ID                      VOUCHER_ID
             ,(
               SELECT FFVV.description 
               FROM fnd_flex_values_vl     FFVV
                    ,fnd_flex_value_sets   FFVS
               WHERE GCC.segment1             = FFVV.flex_value
               AND   FFVV.flex_value_set_id   = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name LIKE '%OD_GL_GLOBAL_COMPANY%'
              )                                   LEGAL_ENTITY
             ,(
               SELECT FFVV.description 
               FROM fnd_flex_values_vl     FFVV
                    ,fnd_flex_value_sets   FFVS
               WHERE GCC.segment4             = FFVV.flex_value
               AND   FFVV.flex_value_set_id   = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name LIKE '%OD_GL_GLOBAL_LOCATION%'
              )                                   OPERATING_UNIT_ID
             ,(
               SELECT FFVV.description 
               FROM fnd_flex_values_vl     FFVV
                    ,fnd_flex_value_sets   FFVS
               WHERE GCC.segment2             = FFVV.flex_value
               AND   FFVV.flex_value_set_id   = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name LIKE '%OD_GL_GLOBAL_COST_CENTER%'
              )                                   OD_DEPT
             ,(
               SELECT FFVV.description 
               FROM fnd_flex_values_vl     FFVV
                    ,fnd_flex_value_sets   FFVS
               WHERE GCC.segment6             = FFVV.flex_value
               AND   FFVV.flex_value_set_id   = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name LIKE '%OD_GL_GLOBAL_LOB%'
              )                                   GL_SALES_CHANNEL_CODING
             ,(
               SELECT FFVV.description 
               FROM fnd_flex_values_vl     FFVV
                    ,fnd_flex_value_sets   FFVS
               WHERE GCC.segment3             = FFVV.flex_value
               AND   FFVV.flex_value_set_id   = FFVS.flex_value_set_id
               AND   FFVS.flex_value_set_name LIKE '%OD_GL_GLOBAL_ACCOUNT%'
              )                                   GL_ACCOUNT
             ,APT.INVOICE_NUM                     INVOICE_NUM
             ,APT.INVOICE_DATE                    INVOICE_DATE
             ,APT.PAYMENT_CHECK_DESCRIBITION      PAYMENT_CHECK_DESCRIBITION
             ,APT.SUPPLIER_NAME                   SUPPLIER_NAME
             ,APT.FIRST_LINE                      FIRST_LINE        
             ,APT.SECOND_LINE                     SECOND_LINE       
             ,APT.THIRD_LINE                      THIRD_LINE
             ,APT.FOURTH_LINE                     FOURTH_LINE
             ,APT.SUPPLIER_CITY                   SUPPLIER_CITY     
             ,APT.SUPPLIER_STATE                  SUPPLIER_STATE    
             ,APT.SUPPLIER_ZIP_CODE               SUPPLIER_ZIP_CODE 
             ,APT.AP_REFERENCE_ID                 AP_REFERENCE_ID   
             ,APT.PAYMENT_DATE                    PAYMENT_DATE      
             ,APT.GROSS_AMOUNT_PAID               GROSS_AMOUNT_PAID
             ,APT.TAX_AMOUNT_PAID                 TAX_AMOUNT_PAID
             ,APT.INVOCIE_AMOUNT                  INVOCIE_AMOUNT    
             ,APT.TAX_AMOUNT                      TAX_AMOUNT
             ,APT.ACCRUED_TAX                     ACCRUED_TAX
             ,GCC.segment1                        segment1
             ,GCC.segment3                        segment3
             ,GCC.segment4                        segment4
      FROM (
            (
             SELECT AI.source                 AP_CO
                    ,PV.segment1              SUPPLIER_ID
                    ,AI.voucher_num           VOUCHER_ID
                    ,AI.invoice_num           INVOICE_NUM
                    ,AI.invoice_date          INVOICE_DATE
                    ,AI.description           PAYMENT_CHECK_DESCRIBITION
                    ,PV.vendor_name           SUPPLIER_NAME
                    ,PVS.address_line1        FIRST_LINE
                    ,PVS.address_line2        SECOND_LINE
                    ,PVS.address_line3        THIRD_LINE
                    ,PVS.address_line4        FOURTH_LINE
                    ,PVS.city                 SUPPLIER_CITY
                    ,PVS.state                SUPPLIER_STATE
                    ,PVS.zip                  SUPPLIER_ZIP_CODE
                    ,DECODE(AIP.INVOICE_PAYMENT_TYPE
                            ,'PREPAY',AI.INVOICE_NUM
                            ,AC.CHECK_NUMBER) AP_REFERENCE_ID
                    ,AC.check_date            PAYMENT_DATE
                    ,NVL(AI.amount_paid,0)    GROSS_AMOUNT_PAID
                    ,0                        TAX_AMOUNT_PAID
                    ,NVL(AI.invoice_amount,0) INVOCIE_AMOUNT
                    ,NVL(
                         (
                          SELECT SUM(AID.AMOUNT) 
                          FROM ap_invoice_distributions  AID 
                          WHERE AID.line_type_lookup_code = 'TAX'
                          AND   AID.invoice_id            = AI.invoice_id
                          GROUP BY AID.invoice_id
                          )
                         ,0
                         )                    TAX_AMOUNT
                    ,NVL(
                         (
                          SELECT TAX
                          FROM(
                               SELECT MAIN1.inv_id  inv_id,SUM(AID.amount)   TAX
                               FROM(
                                    SELECT AID.invoice_id   inv_id
                                    FROM ap_invoice_distributions AID
                                         ,ap_invoices             API
                                    WHERE AID.invoice_id              = API.invoice_id
                                    AND  API.invoice_type_lookup_code = 'CREDIT'
                                    AND AID.parent_invoice_id IS NOT NULL
                                    )   MAIN1
                                    ,ap_invoice_distributions    AID
                                    ,ap_tax_codes                ATC
                               WHERE AID.line_type_lookup_code = 'TAX'
                               AND   AID.tax_code_id           = ATC.tax_id
                               AND   UPPER(ATC.tax_type)       = 'USE'
                               AND   AID.amount                >= 0
                               AND   AID.invoice_id             = MAIN1.inv_id
                               GROUP BY MAIN1.inv_id
                               )                             MAIN2
                               ,ap_invoices                  API
                          WHERE  MAIN2.inv_id = API.invoice_id
                          AND   API.invoice_type_lookup_code = 'CREDIT'
                          AND   API.invoice_num              LIKE '%_TAX' 
                          AND   AI.invoice_id         IN (
                                                          SELECT parent_invoice_id 
                                                          FROM ap_invoice_distributions 
                                                          WHERE invoice_id = MAIN2.inv_id
                                                          AND parent_invoice_id IS NOT NULL
                                                          )
                          )
                         ,0
                         )                    ACCRUED_TAX
             FROM ap_invoices                AI
                  ,po_vendors                PV
                  ,po_vendor_sites           PVS
                  ,ap_checks                 AC
                  ,ap_invoice_payments       AIP
             WHERE AI.payment_status_flag        IN ('Y','P')
             AND   AI.vendor_id                  = PV.vendor_id
             AND   AI.vendor_site_id             = PVS.vendor_site_id
             AND   PVS.vendor_id                 = PV.vendor_id
             AND   AC.vendor_id                  = PV.vendor_id
             AND   AC.vendor_site_id             = PVS.vendor_site_id
             AND   AIP.check_id                  = AC.check_id
             AND   AIP.invoice_id                = AI.invoice_id
             AND   UPPER(AC.status_lookup_code)  NOT IN ('OVERFLOW'
                                                         ,'SET UP'
                                                         ,'SPOILED'
                                                         ,'STOP INITIATED'
                                                         ,'UNCONFIRMED SET UP'
                                                         ,'VOIDED'
                                                         )
             AND   AI.invoice_id                 IN (
                                                     SELECT parent_invoice_id
                                                     FROM ap_invoice_distributions  AID
                                                          ,ap_invoices              API
                                                     WHERE AID.invoice_id = API.invoice_id
                                                     AND   API.invoice_type_lookup_code = 'CREDIT'
                                                     AND   AID.parent_invoice_id IS NOT NULL
                                                     AND   API.invoice_num  LIKE '%_TAX'
                                                     )
             )
             UNION
             (
              SELECT AI.source                AP_CO
                    ,PV.segment1              SUPPLIER_ID
                    ,AI.voucher_num           VOUCHER_ID
                    ,AI.invoice_num           INVOICE_NUM
                    ,AI.invoice_date          INVOICE_DATE
                    ,AI.description           PAYMENT_CHECK_DESCRIBITION
                    ,PV.vendor_name           SUPPLIER_NAME
                    ,PVS.address_line1        FIRST_LINE
                    ,PVS.address_line2        SECOND_LINE
                    ,PVS.address_line3        THIRD_LINE
                    ,PVS.address_line4        FOURTH_LINE
                    ,PVS.city                 SUPPLIER_CITY
                    ,PVS.state                SUPPLIER_STATE
                    ,PVS.zip                  SUPPLIER_ZIP_CODE
                    ,DECODE(AIP.INVOICE_PAYMENT_TYPE
                            ,'PREPAY',AI.INVOICE_NUM
                            ,AC.CHECK_NUMBER) AP_REFERENCE_ID
                    ,AC.check_date            PAYMENT_DATE
                    ,NVL(AI.amount_paid,0)    GROSS_AMOUNT_PAID
                    ,NVL(
                         (
                          SELECT SUM(AID.AMOUNT) 
                          FROM ap_invoice_distributions  AID 
                          WHERE AID.line_type_lookup_code = 'TAX'
                          AND   AID.invoice_id            = AI.invoice_id
                          GROUP BY AID.invoice_id
                          )
                         ,0
                         )                    TAX_AMOUNT_PAID
                    ,NVL(AI.invoice_amount,0) INVOCIE_AMOUNT
                    ,NVL(
                         (
                          SELECT SUM(AID.AMOUNT) 
                          FROM ap_invoice_distributions  AID 
                          WHERE AID.line_type_lookup_code = 'TAX'
                          AND   AID.invoice_id            = AI.invoice_id
                          GROUP BY AID.invoice_id
                          )
                         ,0
                         )                     TAX_AMOUNT
                    ,0                         ACCRUED_TAX
              FROM ap_invoices                AI
                   ,po_vendors                PV
                   ,po_vendor_sites           PVS
                   ,ap_checks                 AC
                   ,ap_invoice_payments       AIP
              WHERE AI.payment_status_flag        IN ('Y')
              AND   AI.vendor_id                  = PV.vendor_id
              AND   AI.vendor_site_id             = PVS.vendor_site_id
              AND   PVS.vendor_id                 = PV.vendor_id
              AND   AC.vendor_id                  = PV.vendor_id
              AND   AC.vendor_site_id             = PVS.vendor_site_id
              AND   AIP.check_id                  = AC.check_id
              AND   AIP.invoice_id                = AI.invoice_id
              AND   UPPER(AC.status_lookup_code)  NOT IN ('OVERFLOW'
                                                          ,'SET UP'
                                                          ,'SPOILED'
                                                          ,'STOP INITIATED'
                                                          ,'UNCONFIRMED SET UP'
                                                          ,'VOIDED'
                                                         )
              AND   AI.invoice_id                 NOT IN (
                                                          SELECT parent_invoice_id
                                                          FROM ap_invoice_distributions  AID
                                                               ,ap_invoices              API
                                                          WHERE AID.invoice_id = API.invoice_id
                                                          AND   API.invoice_type_lookup_code = 'CREDIT'
                                                          AND   AID.parent_invoice_id IS NOT NULL
                                                          AND   API.invoice_num  LIKE '%_TAX'
                                                          )
              )
              UNION
              (
               SELECT AI.source                 AP_CO
                      ,PV.segment1              SUPPLIER_ID
                      ,AI.voucher_num           VOUCHER_ID
                      ,AI.invoice_num           INVOICE_NUM
                      ,AI.invoice_date          INVOICE_DATE
                      ,AI.description           PAYMENT_CHECK_DESCRIBITION
                      ,PV.vendor_name           SUPPLIER_NAME
                      ,PVS.address_line1        FIRST_LINE
                      ,PVS.address_line2        SECOND_LINE
                      ,PVS.address_line3        THIRD_LINE
                      ,PVS.address_line4        FOURTH_LINE
                      ,PVS.city                 SUPPLIER_CITY
                      ,PVS.state                SUPPLIER_STATE
                      ,PVS.zip                  SUPPLIER_ZIP_CODE
                      ,DECODE(AIP.INVOICE_PAYMENT_TYPE
                              ,'PREPAY',AI.INVOICE_NUM
                              ,AC.CHECK_NUMBER) AP_REFERENCE_ID
                      ,AC.check_date            PAYMENT_DATE
                      ,NVL(AI.amount_paid,0)    GROSS_AMOUNT_PAID
                      ,0                        TAX_AMOUNT_PAID
                      ,NVL(AI.invoice_amount,0) INVOCIE_AMOUNT
                      ,NVL(
                           (
                            SELECT SUM(AID.AMOUNT) 
                            FROM ap_invoice_distributions  AID 
                            WHERE AID.line_type_lookup_code = 'TAX'
                            AND   AID.invoice_id            = AI.invoice_id
                            GROUP BY AID.invoice_id
                            )
                           ,0
                           )                     TAX_AMOUNT
                      ,0                         ACCRUED_TAX
               FROM ap_invoices                AI
                    ,po_vendors                PV
                    ,po_vendor_sites           PVS
                    ,ap_checks                 AC
                    ,ap_invoice_payments       AIP
               WHERE AI.payment_status_flag        IN ('P')
               AND   AI.vendor_id                  = PV.vendor_id
               AND   AI.vendor_site_id             = PVS.vendor_site_id
               AND   PVS.vendor_id                 = PV.vendor_id
               AND   AC.vendor_id                  = PV.vendor_id
               AND   AC.vendor_site_id             = PVS.vendor_site_id
               AND   AIP.check_id                  = AC.check_id
               AND   AIP.invoice_id                = AI.invoice_id
               AND   UPPER(AC.status_lookup_code)  NOT IN ('OVERFLOW'
                                                           ,'SET UP'
                                                           ,'SPOILED'
                                                           ,'STOP INITIATED'
                                                           ,'UNCONFIRMED SET UP'
                                                           ,'VOIDED'
                                                           )
               AND   AI.invoice_id                 NOT IN (
                                                           SELECT parent_invoice_id
                                                           FROM ap_invoice_distributions  AID
                                                                ,ap_invoices              API
                                                           WHERE AID.invoice_id = API.invoice_id
                                                           AND   API.invoice_type_lookup_code = 'CREDIT'
                                                           AND   AID.parent_invoice_id IS NOT NULL
                                                           AND   API.invoice_num  LIKE '%_TAX'
                                                           )
               )
            )                          APT
            ,gl_code_combinations      GCC
            ,ap_invoice_distributions  AID
            ,ap_invoices               APIS
      WHERE AID.dist_code_combination_id   = GCC.code_combination_id
      AND   AID.invoice_id                 = APIS.invoice_id
      AND   APIS.invoice_num               = APT.invoice_num
      AND   APIS.invoice_num               NOT IN (
                                                   SELECT invoice_num
                                                   FROM ap_invoices
                                                   WHERE invoice_num LIKE '%_TAX'
                                                   AND   invoice_type_lookup_code = 'CREDIT'
                                                   )
      AND   APIS.vendor_id                 IN(
                                              SELECT vendor_id
                                              FROM po_vendors
                                              WHERE segment1 = APT.SUPPLIER_ID
                                              )
      );