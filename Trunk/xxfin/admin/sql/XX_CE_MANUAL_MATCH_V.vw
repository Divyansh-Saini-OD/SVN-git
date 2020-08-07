-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                            Providge Consulting                                  |
-- +=================================================================================+
-- | Name       : XX_CE_MANUAL_MATCH_V                                               |
-- | Description: Manual Match view                                                  |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version  Date         Authors            Remarks                                 |
-- |=======  ===========  ===============    ============================            |
-- |1.1      8-JUL-2013  Aradhna Sharma    E1318-Changed for R12 Retrofit            |
-- |1.2      16-Sep-2013  Aradhna Sharma   Made changes for R12 retrofit Removed     |
-- |                                       trx_id used trx_code in ce_stamements_lines|
--------------------------------------------------------------------------------------

CREATE OR REPLACE FORCE VIEW "APPS"."XX_CE_MANUAL_MATCH_V"
 ("ROW_ID", "BANK_ACCOUNT_ID", "BANK_ACCOUNT_NAME", "BANK_NAME", "AGENCY_LOCATION_CODE", 
  "BANK_ACCOUNT_NAME_ALT", "DESCRIPTION", "BANK_ACCOUNT_NUM", "STATEMENT_HEADER_ID",
  "STATEMENT_NUMBER", "STATEMENT_DATE", "CURRENCY_CODE", "STATEMENT_LINE_ID", "LINE_NUMBER",
  "TRX_DATE", "TRX_CODE", "TRX_TYPE", "AMOUNT", "STATUS", "TRX_CODE_ID",
  "EFFECTIVE_DATE", "BANK_TRX_NUMBER", "INVOICE_TEXT", "ACCOUNTING_DATE", "BANK_ACCOUNT_TYPE")
AS
 SELECT CSL.ROWID "ROW_ID"
    ,CSH.bank_account_id "BANK_ACCOUNT_ID"     ,ABA.bank_account_name "BANK_ACCOUNT_NAME"
    ,ABB.bank_name "BANK_NAME"                 ,ABA.agency_location_code "AGENCY_LOCATION_CODE" ,ABA.bank_account_name_alt "BANK_ACCOUNT_NAME_ALT"
    ,ABA.description "DESCRIPTION"             ,ABA.bank_account_num "BANK_ACCOUNT_NUM"         ,CSH.statement_header_id "STATEMENT_HEADER_ID"
    ,CSH.statement_number "STATEMENT_NUMBER"   ,CSH.statement_date "STATEMENT_DATE"             ,NVL (CSH.currency_code, ABA.currency_code) "CURRENCY_CODE"
    ,CSL.statement_line_id "STATEMENT_LINE_ID" ,CSL.line_number "LINE_NUMBER"                   ,CSL.trx_date "TRX_DATE"
    ,CTC.trx_code "TRX_CODE"                   ,CSL.trx_type "TRX_TYPE"                         ,CSL.amount "AMOUNT"
    ,CSL.status "STATUS"                       ,CSL.trx_code_id "TRX_CODE_ID"                   ,CSL.effective_date "EFFECTIVE_DATE"
    ,CSL.bank_trx_number "BANK_TRX_NUMBER"     ,CSL.invoice_text "INVOICE_TEXT"                 ,CSL.accounting_date "ACCOUNTING_DATE"
    ,ABA.bank_account_type "BANK_ACCOUNT_TYPE"
      FROM ce_statement_headers CSH 
      ,ce_statement_lines CSL 
     -------- ,ap_bank_accounts ABA     ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
      ,ce_bank_accounts ABA              ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
      ,ce_transaction_codes CTC       
     -------- ,ap_bank_branches ABB     ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
      ,ce_bank_branches_v ABB          ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
     WHERE CSH.statement_header_id = CSL.statement_header_id
      AND CSH.bank_account_id      = ABA.bank_account_id
      AND CTC.bank_account_id      = CSH.bank_account_id
    ------  AND CSL.trx_code_id          = CTC.transaction_code_id  ----Commented for R12 retrofit by Aradhna Sharma on 16-Sep-2013
      AND CSL.trx_code         = CTC.trx_code   ----Added for R12 retrofit by Aradhna Sharma on 16-Sep-2013
     --------  AND ABA.bank_branch_id       = ABB.bank_branch_id   ----Commented for R12 retrofit by Aradhna Sharma on 8-July-2013
      AND ABA.bank_branch_id       = ABB.branch_party_id   ----Added for R12 retrofit by Aradhna Sharma on 8-July-2013
      AND CTC.RECONCILE_FLAG       ='OI'
/