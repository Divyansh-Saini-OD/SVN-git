--------------------------------------------------------
--  DDL for Type XX_FIN_VPS_OA_RECEIPT_OBJ
--------------------------------------------------------

  CREATE OR REPLACE TYPE XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ FORCE  AS OBJECT
  (
    Receipt_Number     VARCHAR2(30),
    Receipt_Date       VARCHAR2(30),
    Last_Update_Date   VARCHAR2(30),
    Program_Id         VARCHAR2(30),
    Applied_Amount     VARCHAR2(15),
    STATIC FUNCTION create_object(
      Receipt_Number    IN     VARCHAR2 := NULL,
      Receipt_Date      IN     VARCHAR2 := NULL,
      Last_Update_Date  IN     VARCHAR2 := NULL,
      Program_Id        IN     VARCHAR2 := NULL,
      Applied_Amount    IN     VARCHAR2 := NULL
    ) RETURN XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ
  );
  /
CREATE OR REPLACE TYPE BODY XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ AS 

  STATIC FUNCTION create_object(
    Receipt_Number    IN     VARCHAR2 := NULL,
    Receipt_Date      IN     VARCHAR2 := NULL,
    Last_Update_Date  IN     VARCHAR2 := NULL,
    Program_Id        IN     VARCHAR2 := NULL,
    Applied_Amount    IN     VARCHAR2 := NULL
  ) RETURN XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ 
  AS
  BEGIN
    RETURN XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ(
                                 Receipt_Number   => Receipt_Number,
                                 Receipt_Date     => Receipt_Date,
                                 Last_Update_Date => Last_Update_Date,
                                 Program_Id       => Program_Id,
                                 Applied_Amount   => Applied_Amount
    );
  END create_object;
END;
/
