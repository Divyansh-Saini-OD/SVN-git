--------------------------------------------------------
--  DDL for Type XX_CRM_CREDIT_LIMTS_OBJ
-------------------------------------------------------
  CREATE OR REPLACE TYPE XX_CRM_CREDIT_LIMTS_OBJ AS OBJECT(
    CURRENCY_CODE                VARCHAR2(15),
    OVERALL_CREDIT_LIMIT         NUMBER,
    TRX_CREDIT_LIMIT             NUMBER,
  STATIC FUNCTION create_object(
    P_CURRENCY_CODE              IN VARCHAR2 := NULL,
    P_OVERALL_CREDIT_LIMIT       IN NUMBER := NULL,
    P_TRX_CREDIT_LIMIT           IN NUMBER := NULL
  ) RETURN XX_CRM_CREDIT_LIMTS_OBJ
);
/
