-- +==================================================================================+
-- | Office Depot - Project Simplify                                                  |
-- | Providge Consulting                                                              |
-- +==================================================================================+
-- | SQL Script to create the view:   XX_CE_STMT_LOCKBOX_LINES_V                      |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author             Remarks                                |
-- |=======   ===========   =============      =======================================|
-- |1.0       04-MAR-2008   BLooman            Initial version                        |
-- |1.1       30-OCT-2008   Raghu              Modified to include other trx codes    |
-- |                                           changes for Defect 11634               |
-- |1.2       06-JUL-2013   Darshini           E1297 - Modified for R12 Upgrade       |
-- |                                           Retrofit                               |
-- |1.3       19-SEP-2013   Darshini           E1297 - Modified to change trx_code_id | 
-- |                                           to trx_code                            |
-- +==================================================================================+
CREATE OR REPLACE VIEW XX_CE_STMT_LOCKBOX_LINES_V
(BANK_ACCOUNT_ID, BANK_ACCOUNT_NAME, BANK_ACCOUNT_NUM, STATEMENT_HEADER_ID, STATEMENT_NUMBER, 
 STATEMENT_DATE, CURRENCY_CODE, STATEMENT_LINE_ID, LINE_NUMBER, TRX_DATE, 
 TRX_TYPE, AMOUNT, STATUS, TRX_CODE_ID, 
 EFFECTIVE_DATE, 
 BANK_TRX_NUMBER, ATTRIBUTE14, ATTRIBUTE15, TRX_TEXT, CUSTOMER_TEXT, 
 INVOICE_TEXT, LOCKBOX_NUMBER, BANK_ACCOUNT_TEXT, REFERENCE_TXT, CE_STATEMENT_LINES, 
 JE_STATUS_FLAG, ACCOUNTING_DATE, GL_ACCOUNT_CCID, BANK_ACCOUNT_TYPE, INACTIVE_DATE, 
 TRX_CODE, DESCRIPTION, PROVIDER_CODE)
AS 
SELECT csh.bank_account_id,
       cba.bank_account_name,
       cba.bank_account_num,
       csh.statement_header_id,
       csh.statement_number,
       csh.statement_date,
       NVL(csh.currency_code,cba.currency_code) currency_code,
       csl.statement_line_id,
       csl.line_number,
       csl.trx_date,
       csl.trx_type,
       csl.amount,
       csl.status,
       csl.trx_code_id,
       csl.effective_date,
       csl.bank_trx_number,
       csl.attribute14,
       csl.attribute15,
       csl.trx_text,
       csl.customer_text,
       csl.invoice_text,
       al.lockbox_number,
       csl.bank_account_text,
       csl.reference_txt,
       csl.ce_statement_lines,
       csl.je_status_flag,
       csl.accounting_date,
       csl.gl_account_ccid,
       cba.bank_account_type,
       --Commented and added by Darshini for R12 Upgrade Retrofit
       --aba.inactive_date,
       cba.end_date,
       --end of addition
       ctc.trx_code,
       ctc.description,
       'LOCKBOX_DAY' provider_code
  FROM ce_statement_headers csh,
       ce_statement_lines csl,
       -- Commented and added by Darshini for R12 Upgrade Retrofit
       --ap_bank_accounts aba,
	ce_bank_accounts cba,
	-- end of addition
       ar_lockboxes al,
       ce_transaction_codes ctc
 WHERE csh.statement_header_id = csl.statement_header_id
   AND csh.bank_account_id = cba.bank_account_id
   AND ctc.bank_account_id = csh.bank_account_id
  -- Commented and added for R12 Upgrade Retrofit 
   --AND csl.trx_code_id = ctc.transaction_code_id
   AND csl.trx_code = ctc.trx_code
   -- end of addition
   AND XX_CE_LOCKBOX_RECON_PKG.get_lockbox_num
       ( cba.bank_account_num, csl.invoice_text, ctc.trx_code ) = al.lockbox_number
   --Commented and added by Darshini for R12 Upgrade Retrofit
   --AND NVL(aba.inactive_date, SYSDATE + 1) > SYSDATE
   AND NVL(cba.end_date, SYSDATE + 1) > SYSDATE
   -- end of addition
   AND ( ( ctc.trx_code = '001')
        OR ( ctc.trx_code IN (SELECT DISTINCT XFT.source_value2           -- Added this select statement for defect # - 11634
                                   FROM   xx_fin_translatedefinition XFTD
                                         ,xx_fin_translatevalues XFT
                                   WHERE  XFTD.translate_id = XFT.translate_id
                                   AND    XFTD.translation_name = 'OD_CE_GET_STMT_LOCKBOX'
                                   AND    XFT.enabled_flag = 'Y'
                                   AND    XFT.source_value1 = cba.bank_account_num
                                   AND    XFT.source_value2 IS NOT NULL)
	    )
        )
   AND ctc.bank_account_id = cba.bank_account_id
   --AND (csl.status IS NULL OR csl.status = 'UNRECONCILED')
   --AND (csl.attribute15 IS NULL OR csl.attribute15 <> 'PROCESSED-E1297')
   --AND aba.bank_account_type LIKE 'Corporate%Lockbox'   -- commented for defect 11634
/