CREATE OR REPLACE VIEW "APPS"."XX_CE_MANUAL_MATCH_V"

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                            Office Depot                           |
-- +===================================================================+
-- | Name  : XX_CE_MANUAL_MATCH_V                                      |
-- | Description: Custom view for the bank account details for the     |
-- |              Available Transactions zone in the Manual Match form |
-- |             "OD Store Deposits Manual Match"                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- | Version     Date           Author             Remarks             |
-- |=======   ==========   =============     ==========================|
-- |1.0       15-JAN-2010  Priyanka Nagesh    Initial version          |
-- |                                          Created for CR 559       |
-- +==================================================================+|

  AS
  SELECT    CSL.ROWID                                            "ROW_ID"
           ,CSH.bank_account_id                                  "BANK_ACCOUNT_ID"
           ,ABA.bank_account_name                                "BANK_ACCOUNT_NAME"
           ,ABB.bank_name                                        "BANK_NAME"
           ,ABA.agency_location_code                             "AGENCY_LOCATION_CODE"
           ,ABA.bank_account_name_alt                            "BANK_ACCOUNT_NAME_ALT"
           ,ABA.description                                      "DESCRIPTION"
           ,ABA.bank_account_num                                 "BANK_ACCOUNT_NUM"
           ,CSH.statement_header_id                              "STATEMENT_HEADER_ID"
           ,CSH.statement_number                                 "STATEMENT_NUMBER"
           ,CSH.statement_date                                   "STATEMENT_DATE"
           ,NVL (CSH.currency_code, ABA.currency_code)           "CURRENCY_CODE"
           ,CSL.statement_line_id                                "STATEMENT_LINE_ID"
           ,CSL.line_number                                      "LINE_NUMBER"
           ,CSL.trx_date                                         "TRX_DATE"
           ,CTC.trx_code                                         "TRX_CODE"
           ,CSL.trx_type                                         "TRX_TYPE"
           ,CSL.amount                                           "AMOUNT"
           ,CSL.status                                           "STATUS"
           ,CSL.trx_code_id                                      "TRX_CODE_ID"
           ,CSL.effective_date                                   "EFFECTIVE_DATE"
           ,CSL.bank_trx_number                                  "BANK_TRX_NUMBER"
           ,CSL.invoice_text                                     "INVOICE_TEXT"
           ,CSL.accounting_date                                  "ACCOUNTING_DATE"
           ,ABA.bank_account_type                                "BANK_ACCOUNT_TYPE"



  FROM     ce_statement_headers CSH
          ,ce_statement_lines CSL
          ,ap_bank_accounts ABA
          ,ce_transaction_codes CTC
          ,ap_bank_branches ABB


  WHERE CSH.statement_header_id = CSL.statement_header_id
  AND   CSH.bank_account_id = ABA.bank_account_id
  AND   CTC.bank_account_id = CSH.bank_account_id
  AND   CSL.trx_code_id = CTC.transaction_code_id
  AND   ABA.bank_branch_id=ABB.bank_branch_id

/






























