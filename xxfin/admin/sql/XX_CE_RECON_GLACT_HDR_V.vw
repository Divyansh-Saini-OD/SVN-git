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
-- |                                                                                             |
-- |                                                                                             |  
-- +=============================================================================================+

CREATE OR REPLACE FORCE VIEW apps.xx_ce_recon_glact_hdr_v (header_id
                                                         , provider_code
                                                         , om_card_type
                                                         , ajb_card_type
                                                         , effective_from_date
                                                         , effective_to_date
                                                         , attribute1
                                                         , attribute2
                                                         , attribute3
                                                         , attribute4
                                                         , attribute5
                                                         , status
                                                         , object_version_number
                                                         , creation_date
                                                         , created_by
                                                         , last_update_login
                                                         , last_update_date
                                                         , last_updated_by
                                                         , recon_credit_costcenter
                                                         , recon_credit_account
                                                         , accrual_liability_costcenter
                                                         , accrual_liability_account
                                                         , accrual_liability_location
                                                         , auto_reversal_days
                                                         , recon_card_type_costcenter
                                                         , recon_card_type_account
                                                         , bank_clearing_location
                                                         , bank_clearing_costcenter
                                                         , bank_clearing_account
                                                         , org_id
                                                         , dm_cust_trx_type_id
                                                         , dm_memo_line_id
                                                         , receipt_method_id
                                                         , bank_account_id
                                                         , bank_deposit_line_descr
                                                         , deposit_offset_days
                                                         , default_dm_cust_trx_type_id
                                                         , default_dm_memo_line_id
                                                         , default_receipt_method_id
                                                         , default_customer_id
                                                          )
AS
   SELECT header_id, provider_code, om_card_type, ajb_card_type
        , effective_from_date, effective_to_date, attribute1, attribute2
        , attribute3, attribute4, attribute5, status, object_version_number
        , creation_date, created_by, last_update_login, last_update_date
        , last_updated_by, recon_credit_costcenter, recon_credit_account
        , accrual_liability_costcenter, accrual_liability_account
        , accrual_liability_location, auto_reversal_days
        , recon_card_type_costcenter, recon_card_type_account
        , bank_clearing_location, bank_clearing_costcenter
        , bank_clearing_account, org_id, dm_cust_trx_type_id, dm_memo_line_id
        , receipt_method_id, bank_account_id, bank_deposit_line_descr
        , deposit_offset_days, default_dm_cust_trx_type_id
        , default_dm_memo_line_id, default_receipt_method_id
        , default_customer_id
     FROM xx_ce_recon_glact_hdr
    WHERE org_id =
             NVL (TO_NUMBER (DECODE (SUBSTRB (USERENV ('CLIENT_INFO'), 1, 1)
                                   , ' ', NULL
                                   , SUBSTRB (USERENV ('CLIENT_INFO'), 1, 10)
                                    )
                            )
                , -99
                 );