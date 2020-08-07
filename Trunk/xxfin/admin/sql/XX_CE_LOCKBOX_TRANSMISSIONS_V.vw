CREATE OR REPLACE VIEW XX_CE_LOCKBOX_TRANSMISSIONS_V
(BANK_ACCOUNT_ID, BANK_ACCOUNT_NAME, BANK_ACCOUNT_NUM, LOCKBOX_NUMBER, RECEIPT_METHOD_ID, 
 RECEIPT_METHOD, DEPOSIT_DATE, TRANSMISSION_ID, TRANSMISSION_NAME, AMOUNT)
AS 
--Commented and added by Darshini for R12 Upgrade Retrofit
--SELECT abv.remittance_bank_account_id bank_account_id,
SELECT cba.bank_account_id,
--end of addition
       cba.bank_account_name,
       cba.bank_account_num,
       abv.lockbox_number,
       abv.receipt_method_id,
       arm.name receipt_method,
       abv.deposit_date,
       ata.transmission_id,
       ata.transmission_name,
       SUM(abv.control_amount) amount
  FROM ar_batches_v abv,
       --Commented and added by Darshini for R12 Upgrade Retrofit
       --ap_bank_accounts aba,
	   ce_bank_accounts cba,
	   ce_bank_acct_uses_all cbau,
	   --end of addition
       ar_transmissions ata,
       ar_receipt_methods arm
 WHERE abv.transmission_id = ata.transmission_id
 --Commented and added by Darshini for R12 Upgrade Retrofit
   --AND abv.remittance_bank_account_id = cba.bank_account_id
   AND abv.remit_bank_acct_use_id = cbau.bank_acct_use_id
   AND cba.bank_account_id = cbau.bank_account_id
   AND abv.receipt_method_id = arm.receipt_method_id(+)
   AND ata.status = 'CL'
 --Commented and added by Darshini for R12 Upgrade Retrofit
 --GROUP BY abv.remittance_bank_account_id,
 GROUP BY cba.bank_account_id,
 --end of addition
       cba.bank_account_name,
       cba.bank_account_num,
       abv.lockbox_number,
       abv.receipt_method_id,
       arm.name,
       abv.deposit_date,
       ata.transmission_id,
       ata.transmission_name
/


