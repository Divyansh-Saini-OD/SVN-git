-- +=============================================================================================+
-- |                  Office Depot - Project Simplify                                            |
-- |                       Providge Consulting                                                   |
-- +=============================================================================================+
-- | Name :APPS.XX_CE_AJB998_AR_V                                                                |
-- | Description : Create the Cash Management (CE) Reconciliation                                |
-- |               view XX_CE_AJB998_AR_V                                                        |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version   Date         Author               Remarks                                          |
-- |=======   ==========   =============        =================================================+
-- | V1.0     28-Nov-2007  D. Gowda T Banks     Initial version                                  |
-- | v1.1     19-Dec-2007  T. Banks             Corrected test for receipt                       |
-- |                                            number for "CREDIT"                              |
-- | v1.2     16-Jan-2008  T. Banks             Added reject code test                           |
-- | v1.3     21-Jan-2008  T. Banks             Added row_id                                     |
-- | v1.4     12-Jun-2008  D Gowda              Defect 8023. Added Recon_date                    |
-- |          28-Jun-2008  D Gowda              Remove NVL on ORG_ID                             |
-- |          30-Jun-2008  D Gowda              Replace provider_type!='CREDIT'                  |
-- |                                             with IN 'CHECK', 'DEBIT'                        |
-- |          01-Jul-2008  D Gowda              Added AND xca8.processor_id = xcarv.provider_code|
-- |          11-Jul-2008  D Gowda              Use TRX_DATE and AMOUNT to link receipts other   |
-- |                                             than $0.                                        | 
-- | v1.5     23-Jul-2008  D. Gowda             Defect 7926 - Performance updates- Preprocess    |
-- |                                            join to fnd_currencies, fnd_territories, AR and  |   
-- |                                            iPayments                                        |
-- | v1.6     07-Apr-2011  J Klein              E2077, CR 898, added new column order_payment_id |
-- |                                            which was also added to table xx_ce_ajb998.      |
-- |                                                                                             |
-- |                                                                                             |
-- +=============================================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE FORCE VIEW xx_ce_ajb998_ar_v (row_id
                                              , sequence_id_998
                                              , org_id
                                              , vset_file
                                              , sdate
                                              , action_code
                                              , attribute1
                                              , provider_type
                                              , attribute2
                                              , store_num
                                              , terminal_num
                                              , trx_type
                                              , attribute3
                                              , attribute4
                                              , card_num
                                              , attribute5
                                              , attribute6
                                              , trx_amount
                                              , invoice_num
                                              , country_code
                                              , country
                                              , currency_code
                                              , currency
                                              , attribute7
                                              , attribute8
                                              , attribute9
                                              , attribute10
                                              , attribute11
                                              , attribute12
                                              , attribute13
                                              , attribute14
                                              , attribute15
                                              , attribute16
                                              , attribute17
                                              , attribute18
                                              , attribute19
                                              , attribute20
                                              , receipt_num
                                              , attribute21
                                              , attribute22
                                              , auth_num
                                              , attribute23
                                              , attribute24
                                              , attribute25
                                              , attribute26
                                              , attribute27
                                              , attribute28
                                              , attribute29
                                              , attribute30
                                              , bank_rec_id
                                              , ipay_batch_num
                                              , attribute31
                                              , attribute32
                                              , trx_date
                                              , attribute33
                                              , attribute34
                                              , attribute35
                                              , processor_id
                                              , network_fee
                                              , adj_fee
                                              , adj_date
                                              , adj_reason_code
                                              , adj_reason_desc
                                              , rej_reason_code
                                              , rej_reason_desc
                                              , other_fee1
                                              , other_fee2
                                              , fund_percent
                                              , ref_num
                                              , dis_amt
                                              , dis_rate
                                              , service_rate
                                              , other_rate1
                                              , other_rate2
                                              , creation_date
                                              , created_by
                                              , last_update_date
                                              , last_updated_by
                                              , attribute36
                                              , attribute37
                                              , attribute38
                                              , attribute39
                                              , attribute40
                                              , attribute41
                                              , attribute42
                                              , attribute43
                                              , status
                                              , status_1310
                                              , status_1295
                                              , recon_date
                                              , ajb_file_name
                                              , ar_cash_receipt_id
                                              , ar_receipt_number
                                              , ar_customer_receipt_reference
                                              , ar_receipt_method_id
                                              , ar_receipt_date
                                              , ar_currency_code
                                              , ar_amount
                                              , ar_org_id
                                              , ar_om_card_type_meaning
                                              , recon_om_card_type
                                              , recon_ajb_card_type
                                              , recon_provider_code
                                              , recon_header_id
					      , order_payment_id
                                               )
AS
   SELECT xca8.ROWID row_id, xca8.sequence_id_998, xca8.org_id, xca8.vset_file
        , xca8.sdate, xca8.action_code, xca8.attribute1, xca8.provider_type
        , xca8.attribute2, xca8.store_num, xca8.terminal_num, xca8.trx_type
        , xca8.attribute3, xca8.attribute4, xca8.card_num, xca8.attribute5
        , xca8.attribute6, xca8.trx_amount, xca8.invoice_num, xca8.country_code
        , xca8.country, xca8.currency_code, xca8.currency, xca8.attribute7
        , xca8.attribute8, xca8.attribute9, xca8.attribute10, xca8.attribute11
        , xca8.attribute12, xca8.attribute13, xca8.attribute14
        , xca8.attribute15, xca8.attribute16, xca8.attribute17
        , xca8.attribute18, xca8.attribute19, xca8.attribute20
        , xca8.receipt_num, xca8.attribute21, xca8.attribute22, xca8.auth_num
        , xca8.attribute23, xca8.attribute24, xca8.attribute25
        , xca8.attribute26, xca8.attribute27, xca8.attribute28
        , xca8.attribute29, xca8.attribute30, xca8.bank_rec_id
        , xca8.ipay_batch_num, xca8.attribute31, xca8.attribute32
        , xca8.trx_date, xca8.attribute33, xca8.attribute34, xca8.attribute35
        , xca8.processor_id, xca8.network_fee, xca8.adj_fee, xca8.adj_date
        , xca8.adj_reason_code, xca8.adj_reason_desc, xca8.rej_reason_code
        , xca8.rej_reason_desc, xca8.other_fee1, xca8.other_fee2
        , xca8.fund_percent, xca8.ref_num, xca8.dis_amt, xca8.dis_rate
        , xca8.service_rate, xca8.other_rate1, xca8.other_rate2
        , xca8.creation_date, xca8.created_by, xca8.last_update_date
        , xca8.last_updated_by, xca8.attribute36, xca8.attribute37
        , xca8.attribute38, xca8.attribute39, xca8.attribute40
        , xca8.attribute41, xca8.attribute42, xca8.attribute43, xca8.status
        , xca8.status_1310, xca8.status_1295, xca8.recon_date
        , xca8.ajb_file_name, acr.cash_receipt_id ar_cash_receipt_id
        , acr.receipt_number ar_receipt_number
        , acr.customer_receipt_reference ar_customer_receipt_reference
        , acr.receipt_method_id ar_receipt_method_id
        , acr.receipt_date ar_receipt_date, acr.currency_code ar_currency_code
        , acr.amount ar_amount, acr.org_id ar_org_id
        , acr.attribute14 ar_om_card_type_meaning
        , xcrgh.om_card_type recon_om_card_type
        , xcrgh.ajb_card_type recon_ajb_card_type
        , xcrgh.provider_code recon_provider_code
        , xcrgh.header_id recon_header_id
	, xca8.order_payment_id
     FROM xx_ce_ajb998_v xca8
        , ar_cash_receipts acr
        , xx_ce_recon_glact_hdr_v xcrgh
    WHERE 1 = 1
      AND xca8.ar_cash_receipt_id = acr.cash_receipt_id
      AND xca8.recon_header_id = xcrgh.header_id;