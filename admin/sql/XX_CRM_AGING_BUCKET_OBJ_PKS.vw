--------------------------------------------------------
--  DDL for Type XX_CRM_AGING_BUCKET_OBJ
-------------------------------------------------------
  CREATE OR REPLACE TYPE XX_CRM_AGING_BUCKET_OBJ AS OBJECT(
    CURRENT_BAL                  NUMBER,
    DAYS_1_30                    NUMBER,
    DAYS_31_60                   NUMBER,
    DAYS_61_90                   NUMBER,
    DAYS_91_180                  NUMBER,
    DAYS_181_365                 NUMBER,
    DAYS_366_PLUS                NUMBER,
  STATIC FUNCTION create_object(
    P_CURRENT_BAL          IN NUMBER := NULL,
    P_DAYS_1_30            IN NUMBER := NULL,
    P_DAYS_31_60           IN NUMBER := NULL,
    P_DAYS_61_90           IN NUMBER := NULL,
    P_DAYS_91_180          IN NUMBER := NULL,
    P_DAYS_181_365         IN NUMBER := NULL,
    P_DAYS_366_PLUS        IN NUMBER := NULL
  ) RETURN XX_CRM_AGING_BUCKET_OBJ
);
/
