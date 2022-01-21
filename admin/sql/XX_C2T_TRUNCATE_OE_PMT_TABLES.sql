-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +================================================================================+
-- | Name        :    XX_C2T_TRUNCATE_OE_PMT_TABLES.sql                             |
-- | Description :    Truncating the tables to reuse for AMEX Credit card conversion|
-- | Rice ID     :    C0705                                                         |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version  Date         Author                Remarks                             |
-- |=======  ===========  ==================    ====================================|
-- | 1.0     11-29-2016   Havish Kasina         Initial Version                     |
-- +================================================================================+
DECLARE
  lc_truncate_table   VARCHAR2(32000); 
BEGIN
   lc_truncate_table:= NULL;
   DBMS_OUTPUT.PUT_LINE('Truncating the table XX_C2T_PREP_THREADS_OE_PMT');
   lc_truncate_table := 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_OE_PMT';   
   DBMS_OUTPUT.PUT_LINE(substr(lc_truncate_table,1,255));   
   EXECUTE IMMEDIATE lc_truncate_table;
   
   lc_truncate_table:= NULL;
   DBMS_OUTPUT.PUT_LINE('Truncating the table XX_C2T_CONV_THREADS_OE_PMT');
   lc_truncate_table := 'TRUNCATE TABLE XXOM.XX_C2T_CONV_THREADS_OE_PMT';   
   DBMS_OUTPUT.PUT_LINE(substr(lc_truncate_table,1,255));   
   EXECUTE IMMEDIATE lc_truncate_table;
   
   lc_truncate_table:= NULL;
   DBMS_OUTPUT.PUT_LINE('Truncating the table XX_C2T_CC_TOKEN_STG_OE_PMT');
   lc_truncate_table := 'TRUNCATE TABLE XXOM.XX_C2T_CC_TOKEN_STG_OE_PMT';   
   DBMS_OUTPUT.PUT_LINE(substr(lc_truncate_table,1,255));   
   EXECUTE IMMEDIATE lc_truncate_table;
   
EXCEPTION
  WHEN OTHERS
  THEN
    DBMS_OUTPUT.PUT_LINE('Exception Message :'||SQLERRM);
    DBMS_OUTPUT.PUT_LINE(substr(lc_truncate_table,1,255));
END;
