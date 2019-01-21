--------------------------------------------------------
--  DDL for Type XX_CRM_EBILL_CONTACT_OBJ
-------------------------------------------------------
  CREATE OR REPLACE TYPE XX_CRM_EBILL_CONTACT_OBJ AS OBJECT(
    RESP_TYPE                    VARCHAR2(30),
    CONTACT_POINT_ID             NUMBER(15),
    SALUTATION                   VARCHAR2(60),
    PARTY_ID                     NUMBER(15),
    FIRST_NAME                   VARCHAR2(150),
    LAST_NAME                    VARCHAR2(150),
    JOB_TITLE                    VARCHAR2(100),
    CONTACT_POINT_TYPE           VARCHAR2(30),
    EMAIL_ADDRESS                VARCHAR2(2000),
    PHONE_LN_TYPE                VARCHAR2(30),
    PHONE_LN_TYPE_DESC           VARCHAR2(80),
    PHONE_COUNTRY_CODE           VARCHAR2(10),
    PHONE_AREA_CODE              VARCHAR2(10),
    PHONE_NUMBER                 VARCHAR2(40),
    EXTENSION                    VARCHAR2(20),
    PRIMARY_CONTACT_POINT        VARCHAR2(1),
    PREFERRED_FLAG               VARCHAR2(1),
  STATIC FUNCTION create_object(
    P_RESP_TYPE                    VARCHAR2 := NULL,
    P_CONTACT_POINT_ID             NUMBER   := NULL,
    P_SALUTATION                   VARCHAR2 := NULL,
    P_PARTY_ID                     NUMBER   := NULL,
    P_FIRST_NAME                   VARCHAR2 := NULL,
    P_LAST_NAME                    VARCHAR2 := NULL,
    P_JOB_TITLE                    VARCHAR2 := NULL,
    P_CONTACT_POINT_TYPE           VARCHAR2 := NULL,
    P_EMAIL_ADDRESS                VARCHAR2 := NULL,
    P_PHONE_LN_TYPE                VARCHAR2 := NULL,
    P_PHONE_LN_TYPE_DESC           VARCHAR2 := NULL,
    P_PHONE_COUNTRY_CODE           VARCHAR2 := NULL,
    P_PHONE_AREA_CODE              VARCHAR2 := NULL,
    P_PHONE_NUMBER                 VARCHAR2 := NULL,
    P_EXTENSION                    VARCHAR2 := NULL,
    P_PRIMARY_CONTACT_POINT        VARCHAR2 := NULL,
    P_PREFERRED_FLAG               VARCHAR2 := NULL
  ) RETURN XX_CRM_EBILL_CONTACT_OBJ
);
/
