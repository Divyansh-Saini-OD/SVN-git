/* Formatted on 2008/07/25 15:05 (Formatter Plus v4.8.8) */
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                       Providge Consulting                                 |
-- +===========================================================================+
-- | Name :APPS.XX_CE_AJB999_V                                                 |
-- | Description : Create the Cash Management (CE) Reconciliation              |
-- |               view XX_CE_AJB999_V                                         |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date         Author            Remarks                           |
-- |=======   ==========   =============     ==================================+
-- | V1.0     28-Nov-2007  D. Gowda T Banks  Initial version                   |
-- | v1.1     21-Jan-2008  T. Banks          Made multi-org.                   |
-- | v1.2     21-Jan-2008  T. Banks          Added row_id                      |
-- | v1.3     12-Jun-2008  D. Gowda          Defect 8023. Added Recon_date     |   
-- |          23-Jul-2008  D. Gowda          Defect 7926 - Performance updates |
-- |                                         Preprocess join to fnd_currencies |  
-- |                                          and fnd_territories              |
-- |                                                                           |
-- +===========================================================================+
CREATE OR REPLACE VIEW xx_ce_ajb999_v (row_id
                                     , record_type
                                     , store_num
                                     , provider_type
                                     , submission_date
                                     , country_code
                                     , territory_code
                                     , currency_code
                                     , currency
                                     , processor_id
                                     , bank_rec_id
                                     , cardtype
                                     , net_sales
                                     , net_reject_amt
                                     , chargeback_amt
                                     , discount_amt
                                     , net_deposit_amt
                                     , creation_date
                                     , created_by
                                     , last_update_date
                                     , last_updated_by
                                     , attribute1
                                     , attribute2
                                     , attribute3
                                     , attribute4
                                     , attribute5
                                     , attribute6
                                     , attribute7
                                     , attribute8
                                     , attribute9
                                     , attribute10
                                     , attribute11
                                     , attribute12
                                     , attribute13
                                     , attribute14
                                     , attribute15
                                     , status
                                     , status_1310
                                     , status_1295
                                     , monthly_discount_amt
                                     , monthly_assessment_fee
                                     , deposit_hold_amt
                                     , deposit_release_amt
                                     , service_fee
                                     , adj_fee
                                     , cost_funds_amt
                                     , cost_funds_alpha_code
                                     , cost_funds_num_code
                                     , reserved_amt
                                     , reserved_amt_alpha_code
                                     , reserved_amt_num_code
                                     , sequence_id_999
                                     , org_id
                                     , recon_date
                                     , ajb_file_name
                                      )
AS
   SELECT xca9.ROWID row_id, xca9.record_type, xca9.store_num
        , xca9.provider_type, xca9.submission_date, xca9.country_code
        , xca9.territory_code, xca9.currency_code, xca9.currency
        , xca9.processor_id, xca9.bank_rec_id, xca9.cardtype, xca9.net_sales
        , xca9.net_reject_amt, xca9.chargeback_amt, xca9.discount_amt
        , xca9.net_deposit_amt, xca9.creation_date, xca9.created_by
        , xca9.last_update_date, xca9.last_updated_by, xca9.attribute1
        , xca9.attribute2, xca9.attribute3, xca9.attribute4, xca9.attribute5
        , xca9.attribute6, xca9.attribute7, xca9.attribute8, xca9.attribute9
        , xca9.attribute10, xca9.attribute11, xca9.attribute12
        , xca9.attribute13, xca9.attribute14, xca9.attribute15, xca9.status
        , xca9.status_1310, xca9.status_1295, xca9.monthly_discount_amt
        , xca9.monthly_assessment_fee, xca9.deposit_hold_amt
        , xca9.deposit_release_amt, xca9.service_fee, xca9.adj_fee
        , xca9.cost_funds_amt, xca9.cost_funds_alpha_code
        , xca9.cost_funds_num_code, xca9.reserved_amt
        , xca9.reserved_amt_alpha_code, xca9.reserved_amt_num_code
        , xca9.sequence_id_999, xca9.org_id, xca9.recon_date
        , xca9.ajb_file_name
     FROM xx_ce_ajb999 xca9
    WHERE xca9.org_id =
             NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1)
                                   , ' ', NULL
                                   , SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                    )
                            )
                , -99
                 );