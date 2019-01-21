--------------------------------------------------------
--  DDL for Type XX_CRM_GRAND_PARENT_OBJ
-------------------------------------------------------
  CREATE OR REPLACE TYPE XX_CRM_GRAND_PARENT_OBJ AS OBJECT(
    GP_ID                         NUMBER,
    GP_NAME                       VARCHAR2(360),
    ORIG_SYSTEM_REFERENCE         VARCHAR2(255),
  STATIC FUNCTION create_object(
    P_GP_ID                       IN NUMBER := NULL,
    P_GP_NAME                     IN VARCHAR2 := NULL,
    P_ORIG_SYSTEM_REFERENCE       IN VARCHAR2 := NULL
  ) RETURN XX_CRM_GRAND_PARENT_OBJ
);
/
