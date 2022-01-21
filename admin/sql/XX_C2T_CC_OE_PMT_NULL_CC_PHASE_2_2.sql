-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- | Name        :    XX_C2T_CC_OE_PMT_NULL_CC_PHASE_2_2.sql                   |
-- | Description :    OE Payments - Validation Query                           |
-- | Rice ID     :    C0705                                                    |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date         Author                Remarks                        |
-- |=======  ===========  ==================    ===============================|
-- | 1.0     09-21-2015   Havish Kasina         Initial Version                |
-- +===========================================================================+
DECLARE
ln_count  NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('   ');
  DBMS_OUTPUT.PUT_LINE(' Start Time  :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS'));
  SELECT /*+ full(OE_PMT) parallel(OE_PMT) */  COUNT(1)
    INTO ln_count
    FROM oe_payments OE_PMT
   WHERE OE_PMT.payment_type_code =  'CREDIT_CARD'
     AND (OE_PMT.attribute3 = 'N' OR OE_PMT.attribute3 IS NULL)
     AND (OE_PMT.credit_card_number IS NOT NULL OR OE_PMT.attribute4 IS NOT NULL OR OE_PMT.attribute5 IS NOT NULL)
     AND TRUNC(OE_PMT.creation_date) < add_months(TRUNC(SYSDATE),-9);
  DBMS_OUTPUT.PUT_LINE('Number of rows :'||ln_count);
  DBMS_OUTPUT.PUT_LINE(' End Time  :'||TO_CHAR(SYSDATE , 'DD-MON-RRRR HH24:MI:SS')); 
EXCEPTION
  WHEN OTHERS 
  THEN
   DBMS_OUTPUT.PUT_LINE('Exception Message is :'||SQLERRM);
END;