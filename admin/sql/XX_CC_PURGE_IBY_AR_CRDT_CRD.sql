SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                        |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_IBY_AR_CRDT_CRD.sql                         |
-- | Description : Script to purge the Credit Card data for few CreditCardTypes |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | DraftA  25-Feb-2015  Rajeev            Created by Rajeev              |
-- | 1.0     25-Feb-2015  Madhu Bolli       Edited to create normal script |
-- | 2.0     04-May-2016  Avinash Baddam    Changes made for direct delete |
-- +=======================================================================+

ALTER SESSION ENABLE PARALLEL DML;

DELETE /*+ parallel(16) */ iby_creditcard CC
 WHERE EXISTS 
            (
             SELECT /*+ parallel (16) */ 1 
	       FROM xxfin.xx_ar_intstore_r12_temp XAIO
              WHERE CC.card_owner_id  = XAIO.party_id)
   AND NOT EXISTS (SELECT /*+ parallel(16) full(aca) */ 1 
                    FROM ap_cards_all aca 
                    WHERE aca.card_reference_id =  cc.instrid);
			  

COMMIT;			  
