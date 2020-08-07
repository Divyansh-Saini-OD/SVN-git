/* Formatted on 2008/07/29 18:14 (Formatter Plus v4.8.8) */
-- +=============================================================================================+
-- |                              Office Depot - Project Simplify                                |
-- |                                    Providge Consulting                                      |
-- +=============================================================================================+
-- | Name :APPS.XX_CE_AJB996_V                                                                   |
-- | Description : Create the Cash Management (CE) Reconciliation view XX_CE_AJB996_V            |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version   Date         Author               Remarks                                          |
-- |=======   ==========   =============        ==============================                   |
-- | V1.0     28-Nov-2007  D. Gowda  T Banks    Initial version                                  |
-- | v1.1     19-Dec-2007  T. Banks             Added chargeback type test                       |
-- | v1.2     10-Jan-2008  T. Banks             Made it a UNION ALL                              |
-- | v1.3     21-Jan-2008  T. Banks             Added org_id                                     |
-- | v1.4     21-Jan-2008  T. Banks             Added row_id                                     |
-- | v1.5     24-Mar-2008  D. Gowda             Defect 5653 - Add chargeback types for Citi      |
-- |          27-Mar-2008  D. Gowda             Process all codes for AMEX, Discover, First Data |
-- |                                              and Telecheck                                  |
-- |          07-Apr-2008  D. Gowda             Updated to retrieve chargebacks to process from  |
-- |                                               OD translations.                              |
-- | v1.4     12-Jun-2008  D Gowda              Defect 8023. Added Recon_date                    | 
-- |          23-Jul-2008  D Gowda              Defect 7926 - Performance updates- Pre-Process   |
-- |                                            join to fnd_currencies, fnd_territories, AR and  |   
-- |                                            iPayments                                        | 
-- |          28-Jul-2008  D Gowda              Defect 9377- Currency is showing 840 for USD     |
-- |          07-Apr-2011  J Klein              E2079, CR 898, Remove check of CHBK CODES. This  |
-- |                                            check was also removed from package              |
-- |                                            xx_ce_cc_stmt_match_pkg.                         |
-- |                                            E2077, CR 898, Add new column order_payment_id   |
-- |                                            which was added to table xx_ce_ajb996.           |
-- |                                            E2080, CR 898, Add new column customer_id        |
-- |                                            which is populated during E2077 pre-process.     |
-- |          27-Apr-2011  J Klein              E2082, CR 898, added new column card_type        |
-- |                                            which was also added to table xx_ce_ajb996.      |
-- +=============================================================================================+
CREATE OR REPLACE FORCE VIEW xx_ce_ajb996_v (row_id
                                           , sequence_id_996
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
                                           , master_noauth_fee
                                           , chbk_rate
                                           , chbk_amt
                                           , chbk_action_code
                                           , chbk_action_date
                                           , chbk_ref_num
                                           , ret_ref_num
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
                                           , chbk_alpha_code
                                           , chbk_numeric_code
                                           , ajb_file_name
                                           , recon_date
                                           , ar_cash_receipt_id
                                           , recon_header_id
                                           , order_payment_id
					   , customer_id
					   , card_type
					    )
AS
   SELECT xca6.ROWID row_id, xca6.sequence_id_996, xca6.org_id, xca6.vset_file
        , xca6.sdate, xca6.action_code, xca6.attribute1, xca6.provider_type
        , xca6.attribute2, xca6.store_num, xca6.terminal_num, xca6.trx_type
        , xca6.attribute3, xca6.attribute4, xca6.card_num, xca6.attribute5
        , xca6.attribute6, xca6.trx_amount, xca6.invoice_num, xca6.country_code
        , xca6.territory_code country, xca6.currency_code
        , xca6.currency currency, xca6.attribute7, xca6.attribute8
        , xca6.attribute9, xca6.attribute10, xca6.attribute11, xca6.attribute12
        , xca6.attribute13, xca6.attribute14, xca6.attribute15
        , xca6.attribute16, xca6.attribute17, xca6.attribute18
        , xca6.attribute19, xca6.attribute20, xca6.receipt_num
        , xca6.attribute21, xca6.attribute22, xca6.auth_num, xca6.attribute23
        , xca6.attribute24, xca6.attribute25, xca6.attribute26
        , xca6.attribute27, xca6.attribute28, xca6.attribute29
        , xca6.attribute30, xca6.bank_rec_id, xca6.ipay_batch_num
        , xca6.attribute31, xca6.attribute32, xca6.trx_date, xca6.attribute33
        , xca6.attribute34, xca6.attribute35, xca6.processor_id
        , xca6.master_noauth_fee, xca6.chbk_rate, xca6.chbk_amt
        , xca6.chbk_action_code, xca6.chbk_action_date, xca6.chbk_ref_num
        , xca6.ret_ref_num, xca6.other_rate1, xca6.other_rate2
        , xca6.creation_date, xca6.created_by, xca6.last_update_date
        , xca6.last_updated_by, xca6.attribute36, xca6.attribute37
        , xca6.attribute38, xca6.attribute39, xca6.attribute40
        , xca6.attribute41, xca6.attribute42, xca6.attribute43, xca6.status
        , xca6.status_1310, xca6.status_1295, xca6.chbk_alpha_code
        , xca6.chbk_numeric_code, xca6.ajb_file_name, xca6.recon_date
        , ar_cash_receipt_id, recon_header_id
	, xca6.order_payment_id  --added for E2079, CR898
        , xca6.customer_id       --added for E2079, CR898
	, xca6.card_type         --added for E2082, CR898
     FROM xx_ce_ajb996 xca6
    WHERE 1 = 1
      AND xca6.status IN ('PREPROCESSED', 'MATCHED_AR')
      /*AND EXISTS (      -- TEST FOR CHARGEBACK TYPE AND PROVIDER --commented AND block for E2079, CR 898
            SELECT 1
              FROM xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
             WHERE xftv.translate_id = xftd.translate_id
               AND xftd.translation_name = 'OD_CE_AJB_CHBK_CODES'
               AND NVL (xftv.enabled_flag, 'N') = 'Y'
               AND NVL (xca6.sdate, SYSDATE) BETWEEN xftv.start_date_active
                                                 AND NVL (xftv.end_date_active
                                                        , SYSDATE + 1
                                                         )
               AND ((xca6.processor_id = xftv.source_value1
                     AND (xftv.target_value1 IS NULL
                          OR xca6.chbk_action_code = xftv.target_value1
                         )
                     AND (xftv.target_value2 IS NULL
                          OR xca6.chbk_alpha_code = xftv.target_value2
                         )
                     AND (xftv.target_value3 IS NULL
                          OR xca6.chbk_numeric_code = xftv.target_value3
                         )
                    )
                   ))                     --  END OF CHBK TYPE AND PROVIDER TEST*/
      AND xca6.org_id =
            NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1)
                                  , ' ', NULL
                                  , SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                   )
                           )
               , -99
                );