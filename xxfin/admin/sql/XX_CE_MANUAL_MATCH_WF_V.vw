  CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."XX_CE_MANUAL_MATCH_WF_V" ("ROW_ID", "BANK_ACCOUNT_ID", "STORE_BANK_ACCOUNT_ID", "BANK_ACCOUNT_NAME", "BANK_NAME", "AGENCY_LOCATION_CODE", "BANK_ACCOUNT_NAME_ALT", "DESCRIPTION", "BANK_ACCOUNT_NUM", "STATEMENT_HEADER_ID", "STATEMENT_NUMBER", "STATEMENT_DATE", "CURRENCY_CODE", "STATEMENT_LINE_ID", "LINE_NUMBER", "TRX_DATE", "TRX_CODE", "TRX_TYPE", "AMOUNT", "STATUS", "TRX_CODE_ID", "EFFECTIVE_DATE", "BANK_TRX_NUMBER", "INVOICE_TEXT", "ACCOUNTING_DATE", "BANK_ACCOUNT_TYPE", "CUSTOMER_TEXT") AS 
  SELECT CSL.ROWID "ROW_ID" ,
  CSH.bank_account_id "BANK_ACCOUNT_ID" ,
  CTC.bank_account_id "STORE_BANK_ACCOUNT_ID",
  cba1.bank_account_name "BANK_ACCOUNT_NAME" ,
  cbb.bank_name "BANK_NAME" ,
  cba1.agency_location_code "AGENCY_LOCATION_CODE" ,
  cba1.bank_account_name_alt "BANK_ACCOUNT_NAME_ALT" ,
  cba1.description "DESCRIPTION" ,
  cba1.bank_account_num "BANK_ACCOUNT_NUM" ,
  CSH.statement_header_id "STATEMENT_HEADER_ID" ,
  CSH.statement_number "STATEMENT_NUMBER" ,
  CSH.statement_date "STATEMENT_DATE" ,
  CBA.currency_code "CURRENCY_CODE" ,
  CSL.statement_line_id "STATEMENT_LINE_ID" ,
  CSL.line_number "LINE_NUMBER" ,
  CSL.trx_date "TRX_DATE" ,
  CTC.trx_code "TRX_CODE" ,
  CSL.trx_type "TRX_TYPE" ,
  CSL.amount "AMOUNT" ,
  CSL.status "STATUS" ,
  CSL.trx_code_id "TRX_CODE_ID" ,
  CSL.effective_date "EFFECTIVE_DATE" ,
  CSL.bank_trx_number "BANK_TRX_NUMBER" ,
  CSL.invoice_text "INVOICE_TEXT" ,
  CSL.accounting_date "ACCOUNTING_DATE" ,
  CBA1.bank_account_type "BANK_ACCOUNT_TYPE",
  SUBSTR (csl.CUSTOMER_TEXT,3) "CUSTOMER_TEXT"
FROM ce_statement_headers CSH ,
  ce_bank_branches_v cbb,
  ce_bank_accounts cba1,
  ce_statement_lines CSL ,
  ce_bank_accounts cba ,
  ce_transaction_codes CTC,
  hz_parties hp
WHERE CSH.statement_header_id = CSL.statement_header_id
AND CSH.bank_account_id       in
  (SELECT bank_Account_id
	FROM ce_bank_accounts cba,
	  ce_bank_branches_v cbb
	WHERE cba.bank_branch_id                                       =cbb.branch_party_id
	AND cbb.bank_name                                              = 'WELLS FARGO BANK'
	AND upper(cbb.bank_branch_name)                                ='STORE DEPOSITORY'
	AND regexp_replace(cba.bank_account_name, '[^[:digit:]]', '') IS NULL
  )
AND csh.bank_Account_id                                        = cba1.bank_Account_id
AND cba1.bank_branch_id                                        = cbb.branch_party_id
AND CSL.trx_code                                               = CTC.trx_code
AND ctc.bank_Account_id                                        =cba.bank_Account_id
AND SUBSTR (csl.CUSTOMER_TEXT,3)                               =lpad(SUBSTR (cba.agency_location_code, 3), 9,'0')
AND NVL (cba.end_date, SYSDATE      + 1)                       > TRUNC (SYSDATE)
AND cba.bank_account_type                                     IN ('Deposit','DEPOSIT')
AND CTC.RECONCILE_FLAG                                         ='OI'
AND hp.party_id                                                = cba.bank_id
--Changes for NAIT-140412 <START>
--AND hp.party_name                                              ='WELLS FARGO BANK'
AND hp.party_name                                              IN 
	(SELECT xftv.source_value2
		FROM XX_FIN_TRANSLATEDEFINITION XFTD, XX_FIN_TRANSLATEVALUES XFTV
		WHERE 1=1
		AND xftd.translate_id = xftv.translate_id
		AND xftd.translation_name = 'XX_CM_E1319_STORE_OS_CC'
		AND xftv.source_value1 = 'BANK'
		AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
		AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
		AND XFTV.enabled_flag = 'Y'
		AND XFTD.enabled_flag = 'Y'
		)
--Changes for NAIT-140412 <END>
AND hp.party_type                                              ='ORGANIZATION'
AND regexp_replace(cba.bank_account_name, '[^[:digit:]]', '') IS NOT NULL;
