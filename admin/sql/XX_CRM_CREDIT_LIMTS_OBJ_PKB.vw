--------------------------------------------------------
--  DDL for Type XX_CRM_CREDIT_LIMTS_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE BODY XX_CRM_CREDIT_LIMTS_OBJ AS
  STATIC FUNCTION create_object(
    P_CURRENCY_CODE              IN VARCHAR2 := NULL,
    P_OVERALL_CREDIT_LIMIT       IN NUMBER := NULL,
    P_TRX_CREDIT_LIMIT           IN NUMBER := NULL
  ) RETURN XX_CRM_CREDIT_LIMTS_OBJ AS
  BEGIN
    RETURN XX_CRM_CREDIT_LIMTS_OBJ(
      CURRENCY_CODE           => P_CURRENCY_CODE,           
      OVERALL_CREDIT_LIMIT    => P_OVERALL_CREDIT_LIMIT,   
      TRX_CREDIT_LIMIT        => P_TRX_CREDIT_LIMIT    
    );
  END create_object;
END; 
/
