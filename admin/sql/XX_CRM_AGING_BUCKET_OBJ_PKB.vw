--------------------------------------------------------
--  DDL for Type XX_CRM_AGING_BUCKET_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE BODY XX_CRM_AGING_BUCKET_OBJ AS
  STATIC FUNCTION create_object(
    P_CURRENT_BAL          IN NUMBER := NULL,
    P_DAYS_1_30            IN NUMBER := NULL,
    P_DAYS_31_60           IN NUMBER := NULL,
    P_DAYS_61_90           IN NUMBER := NULL,
    P_DAYS_91_180          IN NUMBER := NULL,
    P_DAYS_181_365         IN NUMBER := NULL,
    P_DAYS_366_PLUS        IN NUMBER := NULL
  ) RETURN XX_CRM_AGING_BUCKET_OBJ AS
  BEGIN
    RETURN XX_CRM_AGING_BUCKET_OBJ(
      CURRENT_BAL      => P_CURRENT_BAL,      
      DAYS_1_30        => P_DAYS_1_30,       
      DAYS_31_60       => P_DAYS_31_60,   
      DAYS_61_90       => P_DAYS_61_90,   
      DAYS_91_180      => P_DAYS_91_180,  
      DAYS_181_365     => P_DAYS_181_365, 
      DAYS_366_PLUS    => P_DAYS_366_PLUS
    );
  END create_object;
END; 
/
