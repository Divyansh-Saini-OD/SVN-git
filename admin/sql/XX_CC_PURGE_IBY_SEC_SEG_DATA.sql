SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_IBY_SEC_SEG_DATA.sql                                |
-- | Description : Script to purge the Credit Card data for few CreditCardTypes |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | 1.0     27-APR-2016 Madhu Bolli        Created to delete iby sec segments data |
-- | 2.0     06-MAY-2016 Avinash Baddam	    Changes made to do direct delete
-- +=======================================================================+
ALTER SESSION ENABLE PARALLEL DML;


DELETE /*+ parallel(16) full(iss_o)*/
 FROM iby_security_segments iss_o 
WHERE exists (SELECT /*+ parallel(16) full(cc) */ cc.cc_num_sec_segment_id 
                FROM iby_creditcard cc 
               WHERE iss_o.sec_segment_id = cc.cc_num_sec_segment_id
-- exclude if any one CC is active  
                 AND NOT EXISTS ( SELECT /*+ parallel(16) full(icc) */ 1 
                                    FROM iby_creditcard icc
                  WHERE icc.cc_num_sec_segment_id = cc.cc_num_sec_segment_id
    AND NVL(cc.inactive_date, SYSDATE+1) >= SYSDATE)	
                 AND NOT EXISTS ( SELECT /*+ parallel(16) full(aca) */ 1 
                                    FROM ap_cards_all aca 
                                   WHERE aca.card_reference_id =  cc.instrid) 
                 AND NOT EXISTS ( SELECT /*+ parallel(16) full(piua) full( ifte)   */ 1 
                                    FROM iby_pmt_instr_uses_all   piua,
                                         iby_fndcpt_tx_extensions      ifte  
                                   WHERE piua.instrument_id        = cc.instrid
                                     AND ifte.instr_assignment_id  = piua.instrument_payment_use_id
                                     AND ifte.payment_channel_code = 'CREDIT_CARD'
                                     AND (ifte.order_id like 'ARI%' or ifte.payment_system_order_number like 'ARI%')
				)
                );

				
COMMIT;

                