-- +==================================================================================+
-- | Office Depot - Project Simplify                                                  |
-- | Providge Consulting                                                              |
-- +==================================================================================+
-- | SQL Script to create the view:   XX_CE_STMT_LOCKBOX_V                            |
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
CREATE OR REPLACE VIEW XX_CE_STMT_LOCKBOX_V
(BANK_ACCOUNT_ID, BANK_ACCOUNT_NAME, BANK_ACCOUNT_NUM, STATEMENT_HEADER_ID, STATEMENT_NUMBER, 
 STATEMENT_DATE, CURRENCY_CODE, AMOUNT, LOCKBOX_NUMBER, BANK_ACCOUNT_TYPE, 
 TRX_CODE, DESCRIPTION, LINE_COUNT, CREATED_INTERFACE_FLAG, MATCHED_INTERFACE_FLAG, 
 RECONCILED_STMT_FLAG, FIRST_STMT_LINE_ID)
AS 
SELECT csh.bank_account_id,
       cba.bank_account_name,
       cba.bank_account_num,
       csh.statement_header_id,
       csh.statement_number,
       csh.statement_date,
       NVL(csh.currency_code,cba.currency_code) currency_code,
       SUM(csl.amount) amount,
       al.lockbox_number,
       cba.bank_account_type,
       ctc.trx_code,
       ctc.description,
       COUNT(DISTINCT csl.statement_line_id) line_count,
       (SELECT CASE WHEN COUNT(1) > 0
               THEN 'Y' ELSE 'N' END
          FROM xx_ce_999_interface
         WHERE statement_header_id = csh.statement_header_id
           AND lockbox_number = al.lockbox_number
           AND record_type = 'LOCKBOX_DAY') created_interface_flag,
       (SELECT CASE WHEN COUNT(1) > 0
               THEN 'Y' ELSE 'N' END
          FROM xx_ce_999_interface
         WHERE statement_header_id = csh.statement_header_id
           AND lockbox_number = al.lockbox_number
           AND record_type = 'LOCKBOX_DAY'
           AND deposits_matched = 'Y') matched_interface_flag,
       CASE WHEN SUM((SELECT COUNT(1)
                        FROM ce_statement_lines
                       WHERE statement_header_id = csh.statement_header_id
                         AND statement_line_id = csl.statement_line_id
                         AND status = 'RECONCILED') ) > 0
           THEN 'Y' ELSE 'N' END reconciled_stmt_flag,
       MIN(statement_line_id) first_stmt_line_id
  FROM ce_statement_headers csh,
       ce_statement_lines csl,
       --Commented and added by Darshini for R12 Upgrade Retrofit
       --ap_bank_accounts aba,
       ce_bank_accounts cba,
       --end of addition
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
       ( cba.bank_account_num, csl.invoice_text ,ctc.trx_code) = al.lockbox_number
   -- Commented and added by Darshini for R12 Upgrade Retrofit
   --AND NVL(aba.inactive_date, SYSDATE + 1) > SYSDATE
   AND NVL(cba.end_date, SYSDATE + 1) > SYSDATE
   --end of addition
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
   --AND aba.bank_account_type LIKE 'Corporate%Lockbox'              -- commented for defect 11634
 GROUP BY csh.bank_account_id,
       cba.bank_account_name,
       cba.bank_account_num,
       csh.statement_header_id,
       csh.statement_number,
       csh.statement_date,
       NVL(csh.currency_code,cba.currency_code),
       al.lockbox_number,
       cba.bank_account_type,
       ctc.trx_code,
       ctc.description
/

