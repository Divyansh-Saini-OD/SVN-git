DECLARE
-- +===================================================================+
-- |                        Office Depot Inc.                          |
-- +===================================================================+
-- | Script Name :  XX_C2T_CC_RETURNS_NULL_CC_PHASE_2_2.sql            |
-- | Description :  Returns - Validation Query                         |
-- | Rice Id     :  C0705                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author             Remarks                  |
-- |=======   ===========  =================  =========================|
-- |1.0       16-Sep-2015  Manikant Kasu      Initial draft version    |
-- +===================================================================+

ln_count  NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('   ');
  DBMS_OUTPUT.PUT_LINE(' Start Time  :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS'));
  SELECT /*+ full(XORTA) parallel(XORTA) */  
         COUNT(1)
    INTO ln_count
    FROM xx_om_return_tenders_all XORTA
   WHERE XORTA.payment_type_code =  'CREDIT_CARD'
     AND (XORTA.token_flag = 'N' OR XORTA.token_flag IS NULL)
     AND (XORTA.credit_card_number IS NOT NULL)
     AND trunc(XORTA.creation_date) < add_months(trunc(SYSDATE),-9);
  DBMS_OUTPUT.PUT_LINE('Number of rows :'||ln_count);
  DBMS_OUTPUT.PUT_LINE(' End Time  :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS')); 
EXCEPTION
  WHEN OTHERS 
  THEN
   DBMS_OUTPUT.PUT_LINE('Exception Message is :'||SQLERRM);
END;
/