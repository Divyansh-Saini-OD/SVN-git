SET SERVEROUTPUT ON
DECLARE
-- +=====================================================================================+
-- |                        Office Depot Inc.                                            |
-- +=====================================================================================+
-- | Script Name :  XX_C2T_CC_DEPOSITS_HISTORY.sql                                       |
-- | Description :  Script to NULL credit cards in History table for Deposits            |
-- | Rice Id     :  C0705                                                                |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date         Author             Remarks                                    |
-- |=======   ===========  =================  ===========================================|
-- |1.0       16-Feb-2016  Havish Kasina      Initial draft version                      |
-- +=====================================================================================+
ln_count NUMBER :=  0;
BEGIN
   	DBMS_OUTPUT.PUT_LINE('Start Time - XX_C2T_CC_DEPOSITS_HISTORY :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS')); 
	
	 SELECT /*+ parallel(a,32) full(a)*/ COUNT(1)
       INTO ln_count
       FROM gsi_history.xx_om_legacy_deposits a
      WHERE 1 = 1 
        AND a.payment_type_code =  'CREDIT_CARD'
        AND a.credit_card_number IS NOT NULL;
        
    DBMS_OUTPUT.PUT_LINE ('Total number of records to update: ' ||ln_count); 
    DBMS_OUTPUT.PUT_LINE(' Updating the xx_om_legacy_deposits Table');
   
     UPDATE /*+parallel(b,32) full(b)*/ gsi_history.xx_om_legacy_deposits b
        SET b.credit_card_number = NULL
           ,b.identifier         = NULL
      WHERE 1 = 1
        AND b.payment_type_code =  'CREDIT_CARD'
        AND b.credit_card_number IS NOT NULL;
    
    DBMS_OUTPUT.PUT_LINE('Number of Records Updated :'||SQL%ROWCOUNT);
    COMMIT;
   	DBMS_OUTPUT.PUT_LINE('End Time - XX_C2T_CC_DEPOSITS_HISTORY :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS')); 
 
EXCEPTION
    WHEN OTHERS THEN
	  ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Exception Message :'||SQLERRM);
	
END;
/