
/* Formatted on 2008/07/25 15:01 (Formatter Plus v4.8.8) */
-- +=============================================================================================+
-- |                  Office Depot - Project Simplify                                            |
-- |                       Providge Consulting                                                   |
-- +=============================================================================================+
-- | Name :APPS.XX_CE_RECON_GLACT_HDR_V                                                          |
-- | Description : Create the Cash Management (CE) Reconciliation                                |
-- |               view XX_CE_AJB998_AR_V                                                        |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version   Date         Author               Remarks                                          |
-- |=======   ===========  ==================   =================================================+
-- | V1.0     25-Jul-2008  D. Gowda             Initial version                                  |
-- |          03-Mar-2008  Pradeep Krishnan     Added the header and added the -1 in the amount  |
-- |                                            for the defect 13074. Please refer the defect    |
-- |                                            for further information on the logic.            |
-- | 1.2     02-Aug-2013   Rishabh Chhajer      E2079 - Changed for R12 Upgrade retrofit.        |  
-- | 1.3     20-Sep-2013   Rishabh Chhajer      E2079 - Modified where clause, mapping trx_Code  |
-- |                                            for defect no.#25372                             |
-- |                                                                                             |
-- +=============================================================================================+

CREATE OR REPLACE FORCE VIEW XX_CE_STMT_CC_DEPOSITS_V
(
   ROW_ID,
   BANK_ACCOUNT_ID,
   BANK_ACCOUNT_NAME,
   BANK_ACCOUNT_NUM,
   STATEMENT_HEADER_ID,
   STATEMENT_NUMBER,
   STATEMENT_DATE,
   CURRENCY_CODE,
   STATEMENT_LINE_ID,
   LINE_NUMBER,
   TRX_DATE,
   TRX_TYPE,
   AMOUNT,
   STATUS,
   TRX_CODE_ID,
   EFFECTIVE_DATE,
   BANK_TRX_NUMBER,
   ATTRIBUTE14,
   ATTRIBUTE15,
   TRX_TEXT,
   CUSTOMER_TEXT,
   INVOICE_TEXT,
   BANK_ACCOUNT_TEXT,
   REFERENCE_TXT,
   CE_STATEMENT_LINES,
   JE_STATUS_FLAG,
   ACCOUNTING_DATE,
   GL_ACCOUNT_CCID,
   BANK_ACCOUNT_TYPE,
   INACTIVE_DATE,
   TRX_CODE,
   DESCRIPTION,
   BANK_DEPOSIT_LINE_DESCR,
   PROVIDER_CODE,
   DEPOSIT_OFFSET_DAYS,
   TOT_CARD_TYPES
)
AS
     SELECT   csl.ROWID row_id,
              csh.bank_account_id,
              aba.bank_account_name,
              aba.bank_account_num,
              csh.statement_header_id,
              csh.statement_number,
              csh.statement_date,
              NVL (csh.currency_code, aba.currency_code) currency_code,
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
              csl.bank_account_text,
              csl.reference_txt,
              csl.ce_statement_lines,
              csl.je_status_flag,
              csl.accounting_date,
              csl.gl_account_ccid,
              aba.bank_account_type,
              aba.end_Date,
              ctc.trx_code,
              ctc.description,
              xcgh.bank_deposit_line_descr,
              xcgh.provider_code,
              NVL (xcgh.deposit_offset_days, 0) deposit_offset_days,
              COUNT (xcgh.ajb_card_type) tot_card_types
       FROM   ce_statement_headers csh,
              ce_statement_lines csl,
              ce_bank_accounts aba,
              ce_transaction_codes ctc,
              xx_ce_recon_glact_hdr xcgh
      WHERE       csh.statement_header_id = csl.statement_header_id
              AND csh.bank_account_id = aba.bank_account_id
              AND csh.bank_account_id = xcgh.bank_account_id
              AND ctc.bank_account_id = csh.bank_account_id
              AND csl.trx_code = ctc.trx_code				-- Added by Rishabh Chhajer as per R12 Retrofit defect no.#25372
              AND ctc.trx_type LIKE '%CREDIT%'
              AND NVL (aba.end_date, SYSDATE + 1) > SYSDATE
              AND csl.trx_date BETWEEN xcgh.effective_from_date
                                   AND  NVL (xcgh.effective_to_date,
                                             SYSDATE + 1)
              AND csl.trx_text LIKE '%' || xcgh.bank_deposit_line_descr || '%'
   GROUP BY   csl.ROWID,
              csh.statement_header_id,
              csh.bank_account_id,
              csh.statement_number,
              csh.statement_date,
              NVL (csh.currency_code, aba.currency_code),
              csl.attribute14,
              csl.attribute15,
              csl.statement_line_id,
              csl.line_number,
              csl.trx_date,
              csl.trx_type,
              csl.amount,
              csl.status,
              csl.trx_code_id,
              csl.effective_date,
              csl.bank_trx_number,
              aba.bank_account_name,
              aba.bank_account_num,
              csl.trx_text,
              xcgh.bank_deposit_line_descr,
              xcgh.provider_code,
              xcgh.deposit_offset_days,
              csl.customer_text,
              csl.invoice_text,
              csl.bank_account_text,
              csl.reference_txt,
              csl.ce_statement_lines,
              csl.je_status_flag,
              csl.accounting_date,
              csl.gl_account_ccid,
              aba.bank_account_type,
              aba.end_date,
              ctc.trx_code,
              ctc.description
   UNION ALL
     SELECT   csl.ROWID row_id,
              csh.bank_account_id,
              aba.bank_account_name,
              aba.bank_account_num,
              csh.statement_header_id,
              csh.statement_number,
              csh.statement_date,
              NVL (csh.currency_code, aba.currency_code) currency_code,
              csl.statement_line_id,
              csl.line_number,
              csl.trx_date,
              csl.trx_type,
              csl.amount * -1,
              csl.status,
              csl.trx_code_id,
              csl.effective_date,
              csl.bank_trx_number,
              csl.attribute14,
              csl.attribute15,
              csl.trx_text,
              csl.customer_text,
              csl.invoice_text,
              csl.bank_account_text,
              csl.reference_txt,
              csl.ce_statement_lines,
              csl.je_status_flag,
              csl.accounting_date,
              csl.gl_account_ccid,
              aba.bank_account_type,
              aba.end_date,
              ctc.trx_code,
              ctc.description,
              xcgh.bank_deposit_line_descr,
              xcgh.provider_code,
              NVL (xcgh.deposit_offset_days, 0) deposit_offset_days,
              COUNT (xcgh.ajb_card_type) tot_card_types
       FROM   ce_statement_headers csh,
              ce_statement_lines csl,
              ce_bank_accounts aba,
              ce_transaction_codes ctc,
              xx_ce_recon_glact_hdr xcgh
      WHERE       csh.statement_header_id = csl.statement_header_id
              AND csh.bank_account_id = aba.bank_account_id
              AND csh.bank_account_id = xcgh.bank_account_id
              AND ctc.bank_account_id = csh.bank_account_id
              AND csl.trx_code = ctc.trx_code					-- Added by Rishabh Chhajer as per R12 Retrofit defect no.#25372
              AND ctc.trx_code IN
                       (SELECT   DISTINCT XFT.target_value1
                          FROM   xx_fin_translatedefinition XFTD,
                                 xx_fin_translatevalues XFT
                         WHERE   XFTD.translate_id = XFT.translate_id
                                 AND XFTD.translation_name =
                                       'XX_CE_TRX_CODE_DEBIT'
                                 AND XFT.enabled_flag = 'Y'
                                 AND XFT.source_value1 = aba.bank_account_num)
              AND NVL (aba.end_Date, SYSDATE + 1) > SYSDATE
              AND csl.trx_date BETWEEN xcgh.effective_from_date
                                   AND  NVL (xcgh.effective_to_date,
                                             SYSDATE + 1)
              AND csl.trx_text LIKE '%' || xcgh.bank_deposit_line_descr || '%'
   GROUP BY   csl.ROWID,
              csh.statement_header_id,
              csh.bank_account_id,
              csh.statement_number,
              csh.statement_date,
              NVL (csh.currency_code, aba.currency_code),
              csl.attribute14,
              csl.attribute15,
              csl.statement_line_id,
              csl.line_number,
              csl.trx_date,
              csl.trx_type,
              csl.amount,
              csl.status,
              csl.trx_code_id,
              csl.effective_date,
              csl.bank_trx_number,
              aba.bank_account_name,
              aba.bank_account_num,
              csl.trx_text,
              xcgh.bank_deposit_line_descr,
              xcgh.provider_code,
              xcgh.deposit_offset_days,
              csl.customer_text,
              csl.invoice_text,
              csl.bank_account_text,
              csl.reference_txt,
              csl.ce_statement_lines,
              csl.je_status_flag,
              csl.accounting_date,
              csl.gl_account_ccid,
              aba.bank_account_type,
              aba.end_Date,
              ctc.trx_code,
              ctc.description;
