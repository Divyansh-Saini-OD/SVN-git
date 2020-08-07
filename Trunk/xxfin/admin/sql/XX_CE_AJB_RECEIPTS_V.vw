-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- |                       Providge Consulting                                                  |
-- +============================================================================================+
-- | Name : XX_CE_AJB_RECEIPTS_V                                                            |
-- | Description : Create the Cash Management (CE) Reconciliation                               |
-- |               view to combine AR_CASH_RECEIPTS,                                            |
-- |               XX_CE_RECON_GLACT_HDR, OM lookups, and AR transaction,                       |
-- |               memo line, and receipt method id values to provide                           |
-- |               card type, provider id (code) and the AR id values                         |
-- |               for AJB detail records to create debit memos and                             |
-- |               new receipts.                                                                |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version   Date         Author               Remarks                                         |
-- |=======   ==========   =============        ================================================|
-- | V1.0     28-Nov-2007  D. Gowda T Banks     Initial version                                 |
-- |          14-May-2008  D. Gowda             Defect 6182 and CR 382 	                        |
-- |						                    Added pay_from_customer     |
-- |          25-Jun-2008  D. Gowda             removed Upper(itc.instrname)                    |
-- |          25-Jun-2008  D. Gowda             removed Upper(itc.instrname)                    |
-- |          28-Jun-2008  D. Gowda             Use effective_from_date-0 to force index use    |  
-- |          29-JuL-2008  D. Gowda             Use start-date and end date on lookups          |
-- |          09-JUL-2009  Pradeep Krishnan     Removed the use of IBY_TRANS_CORE table         |
-- |                                            and fetched the card type from the IBY          |
-- |                                            Summaries Table. Defect 582.                    |
-- |          04-Jan-2017  Avinash Baddam       R12.2 GSCC Changes
-- +============================================================================================+

CREATE OR REPLACE VIEW xx_ce_ajb_receipts_v (cash_receipt_id
                                           , receipt_number
                                           , customer_receipt_reference
                                           , receipt_method_id
                                           , receipt_date
                                           , pay_from_customer
                                           , currency_code
                                           , amount
                                           , om_card_type_code
                                           , om_card_type_meaning
                                           , ajb_card_type
                                           , provider_code
                                           , header_id
                                           , org_id
                                            )
AS                                                                                                                                              
   (SELECT acr.cash_receipt_id, acr.receipt_number
         , acr.customer_receipt_reference, acr.receipt_method_id
         , acr.receipt_date receipt_date, acr.pay_from_customer
         , acr.currency_code currency_code, acr.amount amount
         , hdr.om_card_type om_card_type_code
         , acr.attribute14 om_card_type_meaning, hdr.ajb_card_type
         , hdr.provider_code, hdr.header_id, acr.org_id org_id
      FROM ar_cash_receipts_all acr
         , fnd_lookup_values lv
         , xx_ce_recon_glact_hdr hdr
     WHERE acr.attribute14 IS NOT NULL
       AND acr.receipt_method_id NOT IN (
              SELECT receipt_method_id
                FROM ar_receipt_methods
               WHERE NAME IN
                           ('US_CC IRECEIVABLES_OD', 'CA_CC IRECEIVABLES_OD'))
       AND lv.lookup_type = 'OD_PAYMENT_TYPES' 
       AND lv.enabled_flag = 'Y'
       AND acr.attribute14 = lv.meaning
       AND lv.lookup_code = hdr.om_card_type        
       AND acr.receipt_date BETWEEN lv.start_date_active-0
                                AND NVL (lv.end_date_active
                                       , acr.receipt_date + 1
                                        )    
       AND acr.org_id = hdr.org_id
       AND acr.receipt_date BETWEEN hdr.effective_from_date-0
                                AND NVL (hdr.effective_to_date
                                       , acr.receipt_date + 1
                                        ))
   UNION ALL
   (SELECT acr.cash_receipt_id, acr.receipt_number
         , acr.customer_receipt_reference, acr.receipt_method_id
         , acr.receipt_date receipt_date, acr.pay_from_customer
         , acr.currency_code currency_code, acr.amount amount
         , lv2.lookup_code om_card_type_code, lv.tag om_card_type_meaning
         , hdr.ajb_card_type, hdr.provider_code, hdr.header_id, acr.org_id
      FROM iby_trxn_summaries_all its
         , ar_cash_receipts_all acr
         , xx_ce_recon_glact_hdr hdr
         --, iby_trxn_core itc
         , fnd_lookup_values lv
         , fnd_lookup_values lv2
     WHERE its.tangibleid = acr.payment_server_order_num
       AND acr.receipt_method_id IN (
              SELECT receipt_method_id
                FROM ar_receipt_methods
               WHERE NAME IN
                           ('US_CC IRECEIVABLES_OD', 'CA_CC IRECEIVABLES_OD'))
       --AND itc.trxnmid = its.trxnmid   
       --AND itc.instrname IS NOT NULL
       --AND lv.lookup_code = itc.instrname
	   AND its.instrsubtype IS NOT NULL
       AND lv.lookup_code = its.instrsubtype
       AND lv.lookup_type = 'OD_CE_AJB_AUTH_TO_OM_CARD_TYPE'
       AND lv.enabled_flag = 'Y'
       AND lv2.lookup_type = 'OD_PAYMENT_TYPES'
       AND lv2.meaning = lv.tag
       AND lv2.lookup_code = hdr.om_card_type
       AND lv2.enabled_flag = 'Y'    
       AND acr.receipt_date BETWEEN lv2.start_date_active-0
                                AND NVL (lv2.end_date_active
                                       , acr.receipt_date + 1
                                        )        
       AND acr.receipt_date BETWEEN lv.start_date_active-0
                                AND NVL (lv.end_date_active
                                       , acr.receipt_date + 1
                                        )
       AND acr.org_id = hdr.org_id
       AND acr.receipt_date BETWEEN hdr.effective_from_date-0
                                AND NVL (hdr.effective_to_date
                                       , acr.receipt_date + 1
                                        ))
;