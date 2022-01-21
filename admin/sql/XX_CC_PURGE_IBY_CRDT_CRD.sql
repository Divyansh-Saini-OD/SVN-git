SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_IBY_DATA.sql                                |
-- | Description : Script to purge the Credit Card data for few CreditCardTypes |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | DraftA  25-Feb-2015  Rajeev            Created by Rajeev              |
-- | 1.0     25-Feb-2015  Madhu Bolli       Edited to create normal script |
-- | 1.1     27-Apr-2016  Madhu Bolli       Deletion of iby_security_segments execute|
-- |                                   in separate script due to row lock possibility|
-- | 1.2     09-May-2016  Avinash Baddam    Changes made for direct delete.|
-- +=======================================================================+

ALTER SESSION ENABLE PARALLEL DML;

DELETE /*+ parallel(16) full(cc) */
  FROM iby_creditcard cc
 WHERE inactive_date < SYSDATE
   AND NOT EXISTS (SELECT /*+ parallel(16) full(aca) */ 1 
                     FROM ap_cards_all aca 
                    WHERE aca.card_reference_id =  cc.instrid)
   AND NOT EXISTS (SELECT /*+ parallel(16) full(piua) full(ifte) */ 1 
                     FROM iby_pmt_instr_uses_all   piua,
                          iby_fndcpt_tx_extensions ifte  
                    WHERE piua.instrument_id         = cc.instrid
                      AND ifte.instr_assignment_id  = piua.instrument_payment_use_id
                      AND ifte.payment_channel_code = 'CREDIT_CARD'
                      AND (ifte.order_id like 'ARI%' or ifte.payment_system_order_number like 'ARI%'));

COMMIT;