--------------------------------------------------------
--  DDL for Type XX_CRM_GRAND_PARENT_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE BODY XX_CRM_GRAND_PARENT_OBJ AS
  STATIC FUNCTION create_object(
    P_GP_ID                       IN NUMBER := NULL,
    P_GP_NAME                     IN VARCHAR2 := NULL,
    P_ORIG_SYSTEM_REFERENCE       IN VARCHAR2 := NULL
  ) RETURN XX_CRM_GRAND_PARENT_OBJ AS
  BEGIN
    RETURN XX_CRM_GRAND_PARENT_OBJ(
      GP_ID                    => P_GP_ID,                    
      GP_NAME                  => P_GP_NAME,                  
      ORIG_SYSTEM_REFERENCE    => P_ORIG_SYSTEM_REFERENCE
    );
  END create_object;
END; 
/
