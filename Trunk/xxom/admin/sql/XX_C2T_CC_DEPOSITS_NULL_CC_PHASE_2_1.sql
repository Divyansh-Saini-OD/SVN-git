SET SERVEROUTPUT ON
DECLARE
-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Script Name :  XX_C2T_CC_DEPOSITS_NULL_CC_PHASE_2_1.sql           |
-- | Description :  Script to NULL credit cards in History table for   |
-- |                Deposits                                           |
-- | Rice Id     :  C0705                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       13-Jan-2016  Manikant Kasu      Initial draft version    |
-- +===================================================================+

ln_count NUMBER :=  0;

BEGIN
			
		DBMS_OUTPUT.PUT_LINE('XX_C2T_NULL_CC_DEPOSITS has script began - '||SYSDATE); 
		
     SELECT COUNT(*)
       INTO ln_count
       FROM xx_om_legacy_deposits
      WHERE 1 = 1 
        AND payment_type_code =  'CREDIT_CARD'
        AND (token_flag = 'N' OR token_flag IS NULL)
        AND credit_card_number IS NOT NULL
        AND TRUNC(creation_date) <= to_date('03-MAY-2014', 'DD-MON-YYYY');
        
    DBMS_OUTPUT.PUT_LINE ('Total number of records to be nulled out...:' ||ln_count);  

    UPDATE xx_om_legacy_deposits 
       SET credit_card_number = NULL
          ,identifier         = NULL
     WHERE 1 = 1 
       AND payment_type_code =  'CREDIT_CARD'
       AND (token_flag = 'N' OR token_flag IS NULL)
       AND credit_card_number IS NOT NULL
       AND TRUNC(creation_date) <= to_date('03-MAY-2014', 'DD-MON-YYYY');

    DBMS_OUTPUT.PUT_LINE('Effected records: '||SQL%rowcount);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('XX_C2T_NULL_CC_DEPOSITS has been completed - '||SYSDATE);
			                             
EXCEPTION
		WHEN OTHERS THEN
			 DBMS_OUTPUT.PUT_LINE('WHEN OTHERS Exception raised at '|| sqlerrm);
       ROLLBACK;
END;
/