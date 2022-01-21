CREATE OR REPLACE VIEW XXOD_FA_SALES_TAX_AUDIT_V AS 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name  : XXOD_FA_SALES_TAX_AUDIT_V                                 |
-- | Description: Custom view used for sales tax audit report          |
-- |                                                                   |                
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       10-AUG-2007  Thilak Daniel     Initial version           |
-- +===================================================================+|
  SELECT  GCC.segment1                                        COMPANY
         ,GCC.segment4                                        LOCATION_NUMBER
         ,FL.segment5                                         LOCATION_CODE   
         ,FA.asset_number                                     ASSET_ID
         ,FB.date_effective                                   ACCTG_DATE
         ,FB.date_placed_in_service                           DATE_PLACED_IN_SERVICE
         ,FCB.segment1                                        MAJOR_CATEGORY
         ,FCB.segment2                                        MINOR_CATEGORY
         ,FA.description                                      DESCRIPTION
         ,FDH.location_id                                     LOCATION_ID
         ,DECODE(FTH.TRANSACTION_HEADER_ID,
		FDH.TRANSACTION_HEADER_ID_IN,TRUNC((FB.cost /FA.current_units * FDH.units_assigned),2) ,
		FDH.TRANSACTION_HEADER_ID_OUT,TRUNC ((FB.cost /FA.current_units *-1* FDH.units_assigned),2) )    COST
         ,FAI.invoice_id                                      INVOICE_ID
         ,to_number(AIDA.attribute8)                          USE_TAX_AMT
         ,DECODE(ATCA.tax_type, 'SALES', AIDA.amount , NULL)  SALES_TAX_AMT
         ,AIA.Invoice_Date                                    INVOICE_DATE
         ,FAI.invoice_number                                  INVOICE_NUMBER
         ,AIA.Invoice_Amount                                  INVOICE_AMOUNT
         ,AIA.voucher_num                                     VOUCHER_ID
         ,PHA.segment1                                        PO_NUM
         ,PV.vendor_name                                      VENDOR_NAME
         ,PHA.vendor_id                                       VENDOR_ID
         ,GCC1.segment3                                       GL_ACCT_PO_LINE
         ,FFVV.description                                    GL_ACCT_DESC_PO_LINE
         ,DECODE(FTH.TRANSACTION_HEADER_ID,
		FDH.TRANSACTION_HEADER_ID_IN,'TRANSFER IN',
		FDH.TRANSACTION_HEADER_ID_OUT, 'TRANSFER OUT')   
                         TRANS_TYPE
         ,FL.segment1||'.'||FL.segment2||'.'||FL.segment3||'.'||FL.segment4||'.'||
          FL.segment5||'.'||FL.segment6                       TRANSFER_LOCATION_NUMBER
         ,FCB.segment1||'.'||FCB.segment2                     TRANSFER_IN_OUT_CATEGORY
         ,FB.book_type_code                                   BOOK_TYPE_CODE
         ,FDP.period_name 
         ,FTH.date_effective   trans_eff
         ,FB.date_effective    books_eff
         ,FDH.date_effective  dist_eff  
         FROM      fa_additions                  FA
         ,fa_books                      FB 
         ,fa_categories                 FCB
         ,fa_asset_invoices             FAI
         ,ap_invoices               AIA 
         ,ap_invoice_distributions  AIDA 
         ,po_distributions          PDA 
         ,po_headers                PHA
         ,gl_code_combinations          GCC
         ,gl_code_combinations          GCC1
         ,po_vendors                    PV
         ,fa_transaction_headers        FTH
         ,fa_distribution_history       FDH
         ,fa_locations                  FL
         ,fnd_flex_values_vl            FFVV
         ,fnd_flex_value_sets           FFVS
         ,ap_tax_codes              ATCA
	 ,fa_asset_history FAH
	 ,fa_deprn_periods  FDP
WHERE    FB.asset_id                  = FA.asset_id
 AND  FAH.asset_id =FA.asset_id
AND FTH.transaction_header_id >= FAH.transaction_header_id_in
 AND FTH.transaction_header_id < NVL(FAH.transaction_header_id_out,
					FTH.transaction_header_id + 1)
 AND FCB.category_id =FAH.category_id
 AND      FAI.asset_id(+)              = FA.asset_id
AND      FAI.parent_mass_addition_id IS NULL 
AND      AIA.invoice_id(+)            = FAI.invoice_id
AND      AIA.invoice_id               = AIDA.invoice_id(+)
AND      NVL(AIDA.assets_tracking_flag,'Y') = 'Y'
AND      AIDA.po_distribution_id      =  PDA.po_distribution_id(+)
AND      PHA.po_header_id(+)          = PDA.po_header_id
AND      GCC1.code_combination_id(+)  = PDA.code_combination_id 
AND      PV.vendor_id(+)              = PHA.vendor_id
AND      FDH.code_combination_id      = GCC.code_combination_id
AND      FTH.book_type_code           = FB.book_type_code
AND      FDH.book_type_code           = FB.book_type_code
AND      FA.asset_id                  = FTH.asset_id
AND FA.ASSET_ID =FDH.asset_id
AND      FL.location_id               = FDH.location_id
AND      FFVV.flex_value_set_id       = FFVS.flex_value_set_id(+) 
AND      FFVS.flex_value_set_name(+)  = 'OD_GL_GLOBAL_ACCOUNT'
AND      FFVV.flex_value(+)           = GCC1.segment3
AND      ATCA.tax_id(+)               = AIDA.tax_code_id
AND      FAI.feeder_system_name  (+)     <> 'PEOPLESOFT'
AND      FTH.transaction_type_code  = 'TRANSFER'
AND     (FTH.TRANSACTION_HEADER_ID	=  FDH.TRANSACTION_HEADER_ID_IN	OR
	     FTH.TRANSACTION_HEADER_ID	=  FDH.TRANSACTION_HEADER_ID_OUT)
AND fdp.book_type_code = fb.book_type_code
union all
SELECT    GCC.segment1                                        COMPANY
         ,GCC.segment4                                        LOCATION_NUMBER
         ,FL.segment5                                         LOCATION_CODE   
         ,FA.asset_number                                     ASSET_ID
         ,FB.date_effective                                   ACCTG_DATE
         ,FB.date_placed_in_service                           DATE_PLACED_IN_SERVICE
         ,FCB.segment1                                        MAJOR_CATEGORY
         ,FCB.segment2                                        MINOR_CATEGORY
         ,FA.description                                      DESCRIPTION
         ,FDH.location_id                                     LOCATION_ID
         ,TRUNC((FB.cost /FA.current_units) * FDH.units_assigned,2)  COST
         ,FAI.invoice_id                                      INVOICE_ID
         ,to_number(AIDA.attribute8)                          USE_TAX_AMT
         ,DECODE(ATCA.tax_type, 'SALES', AIDA.amount , NULL)  SALES_TAX_AMT
         ,AIA.Invoice_Date                                    INVOICE_DATE
         ,FAI.invoice_number                                  INVOICE_NUMBER
         ,AIA.Invoice_Amount                                  INVOICE_AMOUNT
         ,AIA.voucher_num                                     VOUCHER_ID
         ,PHA.segment1                                        PO_NUM
         ,PV.vendor_name                                      VENDOR_NAME
         ,PHA.vendor_id                                       VENDOR_ID
         ,GCC1.segment3                                       GL_ACCT_PO_LINE
         ,FFVV.description                                    GL_ACCT_DESC_PO_LINE
         ,FTH.transaction_type_code                           TRANS_TYPE
         ,FL.segment1||'.'||FL.segment2||'.'||FL.segment3||'.'||FL.segment4||'.'||
          FL.segment5||'.'||FL.segment6                       TRANSFER_LOCATION_NUMBER
         ,FCB.segment1||'.'||FCB.segment2                     TRANSFER_IN_OUT_CATEGORY
         ,FB.book_type_code                                   BOOK_TYPE_CODE
         ,FDP.period_name
         ,FTH.date_effective   trans_eff
         ,FB.date_effective    books_eff
         ,FDH.date_effective  dist_eff  
 FROM     fa_additions                        FA
        ,fa_books                                      FB 
        ,fa_categories                               FCB
        ,fa_distribution_history             FDH
        ,fa_transaction_headers             FTH
        ,gl_code_combinations              GCC
        ,fa_asset_invoices                       FAI
        ,ap_invoices                          AIA 
        ,ap_invoice_distributions   AIDA 
        ,po_distributions                  PDA 
        ,po_headers                           PHA
        ,po_vendors                                 PV
        ,fa_locations                                 FL
        ,gl_code_combinations              GCC1
        ,fnd_flex_values_vl                    FFVV
        ,fnd_flex_value_sets                  FFVS
        ,ap_tax_codes                       ATCA
        ,fa_deprn_periods                      FDP
        ,fa_asset_history                         FAH
        ,fa_transaction_headers              fth1 
WHERE FB.asset_id                                    = FA.asset_id
AND   FTH.asset_id                                    = FA.asset_id
AND   FTH1.asset_id=FA.asset_id
AND   FTH1.book_type_code =FDH.book_type_code
AND   FTH1.transaction_type_code ='TRANSFER IN'
AND   FTH1.asset_id =FTH.asset_id
AND   FTH1.date_effective >=FDH.date_effective
AND   FTH1.date_effective <  NVL(FDH.date_ineffective,sysdate) 
AND   FDH.code_combination_id            = GCC.code_combination_id
AND   FB.transaction_header_id_in =FTH.transaction_header_id
AND   FCB.category_id                              =  FAH.category_id 
AND   FTH.book_type_code                      = FB.book_type_code
AND   FDH.book_type_code                     = FB.book_type_code
AND   FAI.asset_id(+)                                = FA.asset_id
AND   FAI.parent_mass_addition_id IS NULL 
AND   AIA.invoice_id(+)                           =  FAI.invoice_id
AND   AIA.invoice_id                                =  AIDA.invoice_id(+)
AND   AIDA.po_distribution_id              =  PDA.po_distribution_id(+)
AND   PHA.po_header_id(+)                   =  PDA.po_header_id
AND   PV.vendor_id(+)                             =  PHA.vendor_id
AND   FL.location_id                                 =  FDH.location_id
AND   GCC1.code_combination_id(+)    =  PDA.code_combination_id 
AND   FFVV.flex_value_set_id                 =  FFVS.flex_value_set_id(+) 
AND   FFVS.flex_value_set_name(+)      =  'OD_GL_GLOBAL_ACCOUNT'
AND   FFVV.flex_value(+)                        =  GCC1.segment3
AND   ATCA.tax_id(+)                             =  AIDA.tax_code_id
AND   FTH.transaction_type_code         IN ('ADDITION', 'CIP ADDITION') 
AND FA.ASSET_ID =FDH.asset_id
AND   FAH.ASSET_ID                              =  FA.ASSET_ID
AND FTH.transaction_header_id >= FAH.transaction_header_id_in
 AND FTH.transaction_header_id < NVL(FAH.transaction_header_id_out,
					FTH.transaction_header_id + 1)
AND   FDP.BOOK_TYPE_CODE                                       =  FB.book_type_code
AND FAI.feeder_system_name   (+)                                      <> 'PEOPLESOFT'
AND NVL(AIDA.assets_tracking_flag,'Y')                       = 'Y'
AND FDP.book_type_code =FB.book_type_code
ORDER BY LOCATION_CODE,ACCTG_DATE
/
