 --+=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                      Oracle/Office Depot                            |
-- +=====================================================================+
-- | Name     : XXOD_AP_DATA_CONV_V                                      |
-- | RICE ID  : R1090                                                    |
-- | Description: This view is used in AP Data Conversion Report.        |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version      Date               Author                       Remarks |
-- |=======   ==========          =============           ===============|
-- |1.0       24-AUG-2007         Madankumar J            Initial version|
-- +=====================================================================+
 CREATE OR REPLACE VIEW XXOD_AP_DATA_CONV_V
 (INVOICE_NUMBER
  ,INVOICE_ID
  ,ENTITY        
  ,ACCT#         
  ,LINE_TYPE
  ,LINE_LEVEL_AMT
  ,INVOICE_AMT   
  ,PAYMENT_DATE  
  ,STATE         
  ,LOCATION      
  ,ACCRUED_TAX   
  ,AMT_PAID      
  ,TAX_PAID
  )
   AS
     (
      SELECT APT1.INVOICE_NUMBER                      INVOICE_NUMBER
       ,APT1.INVOICE_ID                               INVOICE_ID
       ,APT1.ENTITY                                   ENTITY
       ,APT1.ACCT#                                    ACCT#
       ,DECODE(APT1.LINE_TYPE
               ,'Accrued Use Tax','Use Tax Accrued'
               ,'ZITEM','ITEM'
               ,APT1.LINE_TYPE)                       LINE_TYPE
       ,APT1.LINE_LEVEL_AMT                           LINE_LEVEL_AMT
       ,APT1.INVOICE_AMT                              INVOICE_AMT
       ,APT1.PAYMENT_DATE                             PAYMENT_DATE
       ,APT1.STATE                                    STATE
       ,APT1.LOCATION                                 LOCATION
       ,APT1.ACCRUED_TAX                              ACCRUED_TAX
       ,APT1.AMT_PAID                                 AMT_PAID
       ,APT1.TAX_PAID                                 TAX_PAID
      FROM (
            SELECT APT.INVOICE_NUMBER
                   ,APT.INVOICE_ID
                   ,APT.ENTITY
                   ,APT.ACCT#
                   ,DECODE(APT.LINE_TYPE
                           ,'ITEM','ZITEM'
                           ,'TAX','TAX'
                           ,APT.LINE_TYPE) LINE_TYPE
                   ,APT.LINE_LEVEL_AMT
                   ,APT.INVOICE_AMT
                   ,APT.PAYMENT_DATE
                   ,APT.STATE
                   ,APT.LOCATION
                   ,APT.ACCRUED_TAX
                   ,APT.AMT_PAID
                   ,APT.TAX_PAID
             FROM (
                   (
                    SELECT AI.invoice_num             INVOICE_NUMBER
                    ,AI.invoice_id                    INVOICE_ID
                    ,GCC.segment1                     ENTITY
                    ,GCC.segment3                     ACCT#
                    ,AID.line_type_lookup_code        LINE_TYPE
                    ,AID.amount                       LINE_LEVEL_AMT
                    ,AI.invoice_amount                INVOICE_AMT
                    ,AC.check_date                    PAYMENT_DATE
                    ,PVS.state                        STATE
                    ,GCC.segment4                     LOCATION
                    ,NVL(
                         (
                          SELECT TAX
                          FROM(
                               SELECT MAIN1.inv_id       inv_id
                                      ,SUM(AID.amount)   TAX
                               FROM(
                                    SELECT AID.invoice_id   inv_id
                                    FROM   ap_invoice_distributions AID
                                           ,ap_invoices             API
                                    WHERE AID.invoice_id               = API.invoice_id
                                    AND   API.invoice_type_lookup_code = 'CREDIT'
                                    AND   AID.parent_invoice_id IS NOT NULL
                                   ) MAIN1
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
                    WHERE  MAIN2.inv_id                = API.invoice_id
                    AND   API.invoice_type_lookup_code = 'CREDIT'
                    AND   API.invoice_num           LIKE '%_TAX' 
                    AND   AI.invoice_id         IN (
                                                    SELECT parent_invoice_id 
                                                    FROM ap_invoice_distributions 
                                                    WHERE invoice_id = MAIN2.inv_id
                                                    AND parent_invoice_id IS NOT NULL
                                                    )
                    )
                   ,0
                   )                                  ACCRUED_TAX
              ,AI.amount_paid                         AMT_PAID
              ,0                                      TAX_PAID
       FROM ap_invoices                AI
            ,ap_invoice_distributions  AID
            ,ap_checks                 AC
            ,ap_invoice_payments       AIP
            ,po_vendor_sites           PVS
            ,gl_code_combinations      GCC
       WHERE AI.invoice_id                 = AID.invoice_id
       AND   AI.payment_status_flag        IN ('Y','P')
       AND   AI.invoice_id                 = AIP.invoice_id
       AND   AIP.check_id                  = AC.check_id
       AND   AI.vendor_site_id             = PVS.vendor_site_id
       AND   AID.dist_code_combination_id  = GCC.code_combination_id
       AND   UPPER(AC.status_lookup_code)  NOT IN (
                                                   'OVERFLOW'
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
                                               WHERE AID.invoice_id               = API.invoice_id
                                               AND   API.invoice_type_lookup_code = 'CREDIT'
                                               AND   AID.parent_invoice_id IS NOT NULL
                                               AND   API.invoice_num  LIKE '%_TAX'
                                               )
       )
       UNION
       (
        SELECT AI.invoice_num                    INVOICE_NUMBER
               ,AI.invoice_id                    INVOICE_ID
               ,GCC.segment1                     ENTITY
               ,GCC.segment3                     ACCT#
               ,AID.line_type_lookup_code        LINE_TYPE
               ,AID.amount                       LINE_LEVEL_AMT
               ,AI.invoice_amount                INVOICE_AMT
               ,AC.check_date                    PAYMENT_DATE
               ,PVS.state                        STATE
               ,GCC.segment4                     LOCATION
               ,0                                ACCRUED_TAX
               ,AI.amount_paid                   AMT_PAID
               ,(AI.amount_paid * (
                                   SELECT SUM(amount)
                                   FROM ap_invoice_distributions
                                   WHERE invoice_id          = AI.invoice_id
                                   AND line_type_lookup_code = 'TAX'
                                   GROUP BY invoice_id
                                   )
                 )/AI.invoice_amount             TAX_PAID
        FROM ap_invoices                AI
             ,ap_invoice_distributions  AID
             ,ap_checks                 AC
             ,ap_invoice_payments       AIP
             ,po_vendor_sites           PVS
             ,gl_code_combinations      GCC
        WHERE AI.invoice_id                 = AID.invoice_id
        AND   AI.payment_status_flag        IN ('Y')
        AND   AI.invoice_id                 = AIP.invoice_id
        AND   AIP.check_id                  = AC.check_id
        AND   AI.vendor_site_id             = PVS.vendor_site_id
        AND   AID.dist_code_combination_id  = GCC.code_combination_id
        AND   UPPER(AC.status_lookup_code)  NOT IN (
                                                     'OVERFLOW'
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
                                                    WHERE AID.invoice_id               = API.invoice_id
                                                    AND   API.invoice_type_lookup_code = 'CREDIT'
                                                    AND   AID.parent_invoice_id IS NOT NULL
                                                    AND   API.invoice_num  LIKE '%_TAX'
                                                    )
        )
        UNION
        (
         SELECT AI.invoice_num                    INVOICE_NUMBER
                ,AI.invoice_id                    INVOICE_ID
                ,GCC.segment1                     ENTITY
                ,GCC.segment3                     ACCT#
                ,AID.line_type_lookup_code        LINE_TYPE
                ,AID.amount                       LINE_LEVEL_AMT
                ,AI.invoice_amount                INVOICE_AMT
                ,AC.check_date                    PAYMENT_DATE
                ,PVS.state                        STATE
                ,GCC.segment4                     LOCATION
                ,0                                ACCRUED_TAX
                ,AI.amount_paid                   AMT_PAID
                ,0                                TAX_PAID
         FROM ap_invoices                AI
              ,ap_invoice_distributions  AID
              ,ap_checks                 Ac
              ,ap_invoice_payments       AIP
              ,po_vendor_sites           PVS
              ,gl_code_combinations      GCC
         WHERE AI.invoice_id                 = AID.invoice_id
         AND   AI.payment_status_flag        IN ('P')
         AND   AI.invoice_id                 = AIP.invoice_id
         AND   AIP.check_id                  = AC.check_id
         AND   AI.vendor_site_id             = PVS.vendor_site_id
         AND   AID.dist_code_combination_id  = GCC.code_combination_id
         AND   UPPER(AC.status_lookup_code)  NOT IN (
                                                      'OVERFLOW'
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
          SELECT AI.invoice_num                    INVOICE_NUMBER
                 ,AI.invoice_id                    INVOICE_ID
                 ,GCC.segment1                     ENTITY
                 ,GCC.segment3                     ACCT#
                 ,'CR/DR Memo'                     LINE_TYPE
                 ,((
                   SELECT SUM(amount)
                   FROM ap_invoice_distributions
                   WHERE invoice_id = AI.invoice_id
                   AND   line_type_lookup_code = 'TAX'
                   ) * -1)                         LINE_LEVEL_AMT
                 ,AI.invoice_amount                INVOICE_AMT
                 ,AC.check_date                    PAYMENT_DATE
                 ,PVS.state                        STATE
                 ,GCC.segment4                     LOCATION
                 ,NULL                             ACCRUED_TAX
                 ,NULL                             AMT_PAID
                 ,0                                TAX_PAID
          FROM ap_invoices                AI
               ,ap_invoice_distributions  AID
               ,ap_checks                 AC
               ,ap_invoice_payments       AIP
               ,po_vendor_sites           PVS
               ,gl_code_combinations      GCC
          WHERE AI.invoice_id                 = AID.invoice_id
          AND   AI.payment_status_flag        IN ('Y','P')
          AND   AI.invoice_id                 = AIP.invoice_id
          AND   AIP.check_id                  = AC.check_id
          AND   AI.vendor_site_id             = PVS.vendor_site_id
          AND   AID.dist_code_combination_id  = GCC.code_combination_id
          AND   AID.line_type_lookup_code     = 'TAX'
          AND   UPPER(AC.status_lookup_code)  NOT IN (
                                                       'OVERFLOW'
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
           SELECT AI.invoice_num                    INVOICE_NUMBER
                  ,AI.invoice_id                    INVOICE_ID
                  ,GCC.segment1                     ENTITY
                  ,GCC.segment3                     ACCT#
                  ,'Accrued Use Tax'                LINE_TYPE
                  ,NULL                             LINE_LEVEL_AMT
                  ,AI.invoice_amount                INVOICE_AMT
                  ,AC.check_date                    PAYMENT_DATE
                  ,PVS.state                        STATE
                  ,GCC.segment4                     LOCATION
                  ,(
                    NVL(
                        (
                          SELECT TAX
                          FROM(
                               SELECT MAIN1.inv_id  inv_id
                               ,SUM(AID.amount)   TAX
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
                          WHERE  MAIN2.inv_id                = API.invoice_id
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
                         )*-1)                      ACCRUED_TAX
                  ,NULL                             AMT_PAID
                  ,0                                TAX_PAID
           FROM ap_invoices                AI
                ,ap_invoice_distributions  AID
                ,ap_checks                 AC
                ,ap_invoice_payments       AIP
                ,po_vendor_sites           PVS
                ,gl_code_combinations      GCC
           WHERE AI.invoice_id                 = AID.invoice_id
           AND   AI.payment_status_flag        IN ('Y','P')
           AND   AI.invoice_id                 = AIP.invoice_id
           AND   AIP.check_id                  = AC.check_id
           AND   AI.vendor_site_id             = PVS.vendor_site_id
           AND   AID.dist_code_combination_id  = GCC.code_combination_id
           AND   AID.line_type_lookup_code     = 'TAX'
           AND   UPPER(AC.status_lookup_code)  NOT IN (
                                                        'OVERFLOW'
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
         )               APT
ORDER BY APT.INVOICE_NUMBER , LINE_TYPE DESC) APT1
WHERE APT1.invoice_id NOT IN (
                                     SELECT invoice_id
                                     FROM   ap_invoices 
                                     WHERE  invoice_num LIKE '%_TAX'
                                     AND    invoice_type_lookup_code = 'CREDIT'
                              ))
/