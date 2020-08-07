/* Formatted on 2008/09/23 17:15 (Formatter Plus v4.8.8) */
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- |                       Providge Consulting                                        |
-- +==================================================================================+
-- | Name :APPS.XX_CE_AJB_NET_AMOUNTS_V                                               |
-- | Description : Returns the Net amount of transactions, chargebacks and fees       |
-- |               by provider, card type, store and currency.                        |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     28-Nov-2007  D. Gowda T Banks     Initial version                       |
-- |          14-May-2008  D. Gowda             Round the net amount to 2             |
-- |          12-Jun-2008  D. Gowda             Defect 8023-Switched Recon date       |
-- |                                             from function to field               |
-- |          01-Jul-2008  D. Gowda             Remove Group by in query at           |
-- |                                            998/996/999 level                     |
-- |          23-Sep-2008  D. Gowda             Performance updates-Remove            |
-- |                                             XX_CE_AJB99x_AR_V-since preprocessor | 
-- |                                             has already checked and populates    |
-- |                                             ar_cash_receipt_id                   |
-- | V1.1     05-Jan-2010  Vinaykumar S         Defect 2610 Performance changes       |
-- |                                            Added status_1310 column              |
-- | V1.2     27-Jul-2010  Rani Asaithambi      Added attribute1 column               |
-- +==================================================================================+

CREATE OR REPLACE FORCE VIEW apps.xx_ce_ajb_net_amounts_v (org_id
                                                         , bank_rec_id
                                                         , processor_id
                                                         , card_type
                                                         , store_num
                                                         , recon_date
                                                         , currency
                                                         , net_amount
                                                         ,status_1310              --Added for Defect 2610
							 ,attribute1               --Added for Defect 6138
                                                         )
AS
SELECT   org_id, bank_rec_id, processor_id, card_type, store_num, recon_date
          , currency, ROUND (SUM (amount), 2) net_amount, status_1310,attribute1
       FROM (SELECT e.org_id, e.bank_rec_id, e.processor_id
                  , xcrgh.ajb_card_type card_type, e.store_num
                  , e.recon_date recon_date, e.currency
                  , NVL (e.trx_amount, 0) amount
                  , e.status_1310 status_1310                                     --Added for Defect 2610
		  ,e.attribute1                                                   --Added for Defect 6138
               FROM xx_ce_ajb998_v e, xx_ce_recon_glact_hdr xcrgh
              WHERE e.recon_header_id = xcrgh.header_id
             UNION ALL
             SELECT s.org_id, s.bank_rec_id, s.processor_id
                  , xcrgh.ajb_card_type card_type, s.store_num
                  , s.recon_date recon_date, s.currency
                  , NVL (s.chbk_amt, 0) * -1 amount
                  , s.status_1310 status_1310                                     --Added for Defect 2610
		  ,s.attribute1                                                   --Added for Defect 6138              
               FROM xx_ce_ajb996_v s, xx_ce_recon_glact_hdr xcrgh
              WHERE s.recon_header_id = xcrgh.header_id(+)
             UNION ALL
             SELECT n.org_id, n.bank_rec_id, n.processor_id
                  , n.cardtype card_type, n.store_num, n.recon_date recon_date
                  , n.currency
                  ,   NVL (  NVL (n.adj_fee, 0)
                           + NVL (n.cost_funds_amt, 0)
                           + NVL (n.deposit_hold_amt, 0)
                           + NVL (n.deposit_release_amt, 0)
                           + NVL (n.discount_amt, 0)
                           + NVL (n.monthly_assessment_fee, 0)
                           + NVL (n.monthly_discount_amt, 0)
                           + NVL (n.reserved_amt, 0)
                           + NVL (n.service_fee, 0)
                         , 0
                          )
                    * -1 amount
                 , n.status_1310 status_1310                                           --Added for Defect 2610
		 ,n.attribute1                                                         --Added for Defect 6138    
               FROM xx_ce_ajb999_v n) xnet
   GROUP BY org_id
          , bank_rec_id
          , processor_id
          , card_type
          , store_num
          , recon_date
          , currency  
          ,status_1310                                                                 --Added for Defect 2610
	  ,attribute1                                                                  --Added for Defect 6138    
         

/
SHOW ERR