-------------------------------------------------------
--  DDL for Type XX_FIN_VPS_OA_RECEIPTS_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE XXFIN.XX_FIN_VPS_OA_RECEIPTS_OBJ FORCE AS OBJECT (
  receipts_sum    number(15,2),
  receipts_objs   XX_FIN_VPS_OA_RECEIPT_OBJ_TBL
  );
/
